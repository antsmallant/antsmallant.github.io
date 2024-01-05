---
layout: post
title:  "lua: attempt to yield across a C-call boundary 的原因分析"
date:   2023-10-08
last_modified_at: 2023-10-08
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}

<br>
<br>
<br>

## 问题背景
使用 lua 的时候有时候会遇到这样的报错："attempt to yield across a C-call boundary"。   
<br>
比如这个 issue [一个关于 yield across a C-call boundary 的问题](https://github.com/cloudwu/skynet/issues/394)，云风的解释是：
>`C (skynet framework)->lua (skynet service) -> C -> lua`
>最后这个 lua 里如果调用了 yield 就会产生。   

<br>  

另一些文章也对这个问题做出解释，比如 [lua中并不能随意yield](https://radiotail.github.io/2016/05/18/lua%E4%B8%AD%E5%B9%B6%E4%B8%8D%E8%83%BD%E9%9A%8F%E6%84%8Fyield/) 提到：   
>流程：`coroutine --> c --> coroutine --> yield  ===> 报错`   
>为什么这种情况下lua会给出这种报错呢？主要是因为在从c函数调回到coroutine中yield时，coroutine当前的堆栈情况会被保存在lua_State中，因此在调用resume时，lua可以恢复yield时的场景，并继续执行下去。但c函数不会因为coroutine的yield被挂起，它会继续执行下去，函数执行完后堆栈就被销毁了，所以无法再次恢复现场。而且因为c函数不会被yield函数挂起，导致c和lua的行为也不一致了，一个被挂起，一个继续执行完，代码逻辑很可能因此出错。    
<br>

读完反而更困惑了。“c函数不会因为 coroutine 的 yield 被挂起，它会继续执行下去，函数执行完后堆栈就被销毁了”，这里的 c 函数是指哪个呢？是调用了含有 yield 的 lua 代码的 testc 函数，还是 main 函数？如果是 testc 函数，那显然是错的。因为 yield 的内部是通过 longjmp 跳回了上一层的 coroutine，testc 的后续是没有继续执行下去的。    
<br>

再比如这个 [深入Lua：在C代码中处理协程Yield](https://zhuanlan.zhihu.com/p/337850564) 提到：
>原因是Lua使用longjmp来实现协程的挂起，longjmp会跳到其他地方去执行，使得后面的C代码被中断。l_foreach函数执行到lua_call，由于longjmp会使得后面的指令没机会再执行，就像这个函数突然消失了一样，这肯定会引起不可预知的后果，所以Lua不允许这种情况发生，它在调用coroutine.yield时抛出上面的错误。    
<br>

这个作者大致是理解这个问题的，并且点出了问题的关键: “由于longjmp会使得后面的指令没机会再执行”。但是讲得不够细，对于问题产生的条件没有讲清楚。     
<br>

所以，本文将尝试更清楚的剖析这个问题。   
以下分析使用的 lua 版本是 5.3.6，下载链接是 [https://lua.org/ftp/lua-5.3.6.tar.gz](https://lua.org/ftp/lua-5.3.6.tar.gz)，文档链接是 [https://lua.org/manual/5.3/](https://lua.org/manual/5.3/)。   
<br>

## 问题剖析
首先，什么情况下才会出现这个错误？上面文章提到的 `C (skynet framework)->lua (skynet service) -> C -> lua` 或 `coroutine --> c --> coroutine --> yield  ===> 报错`，都说得太笼统了，不够精确。    
<br>

看一下 lua 源码里面的 `lua_yieldk` 函数（在 ldo.c 中）的实现，就可以知道，在一个协程的调用链中，出现一个 `luaD_callnoyield` 调用之后再 yield 就会报错，大致是这样：`... -> luaD_callnoyield -> ... -> yield`。并且，不管这个 yield 是在 c 中调用 `lua_yield` 还是在 lua 中调用 `coroutine.yield`。   
<br>

那 `luaD_callnoyield` 具体是如何限制后续逻辑调用 `yield` 的呢？  
<br>

先看一下 `luaD_callnoyield` 的实现：   
```
void luaD_callnoyield (lua_State *L, StkId func, int nResults) {
  L->nny++;
  luaD_call(L, func, nResults);
  L->nny--;
}
```    
<br>

再看下 `lua_yieldk` 的实现:   
```
LUA_API int lua_yieldk (lua_State *L, int nresults, lua_KContext ctx,
                        lua_KFunction k) {
  CallInfo *ci = L->ci;
  luai_userstateyield(L, nresults);
  lua_lock(L);
  api_checknelems(L, nresults);
  if (L->nny > 0) {
    if (L != G(L)->mainthread)
      luaG_runerror(L, "attempt to yield across a C-call boundary");
    else
      luaG_runerror(L, "attempt to yield from outside a coroutine");
  }
  L->status = LUA_YIELD;
  ci->extra = savestack(L, ci->func);  /* save current 'func' */

  ...
```   
<br>

从源码可以看出 `luaD_callnoyield` 是通过设置 `L->nny` 这个变量来控制的。    
<br>

那什么情况下会调用 `luaD_callnoyield` 呢？从源码上看有好几处，但跟我们日常开发关系密切的只有 `lua_callk` 及 `lua_pcallk`。而这两个一般就是 c 调用 lua 的时候才会使用。    
<br>

ok，我们现在知道如果一个协程的调用链中，如果先出现 `lua_callk` 或 `lua_pcallk`，之后就不能有 `yield` 了。但为什么要做这样的限制呢？   
<br>

这个跟 lua 协程的实现有关，它是通过 `setjmp` 和 `longjmp` 实现的，`resume` 对应 `setjmp`，`yield` 对应 `longjmp`。`longjmp` 对于协程内部纯 lua 的栈没啥影响，因为每个协程都有一块内存来保存自己的栈，但对于 C 栈就有影响了，一个线程只有一个 C 栈，`longjmp` 的时候，直接改掉了 C 栈的栈顶指针。如下图所示，`longjmp` 之后，逻辑回到了 A，那么 B 对应的整个栈帧都会被覆盖掉（相当于被抹除了）。     
<br>

![lua-coroutine-yield](https://blog.antsmallant.top/media/blog/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary/lua-coroutine-yield.png)  
<center>图1：yield 示意图</center>  
<br>

解释得七七八八了，但还是有些抽象。先举个简单的例子来验证一下上面的说法吧。   
<br>

clib.c
```
#include <stdlib.h>
#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>

static int f1(lua_State* L) {
    printf("enter f1\n");
    lua_getglobal(L, "lua_yield");
    lua_call(L, 0, 0);
    printf("leave f1\n");
    return 0;
}

LUAMOD_API int luaopen_clib(lua_State* L) {
    luaL_Reg funcs[] = {
        {"f1", f1},
        {NULL, NULL}
    };
    luaL_newlib(L, funcs);
    return 1;
}
```   
<br>

test_co_1.lua
```
local co = require "coroutine"
local clib = require "clib"

function lua_yield()
    print("enter lua_yield")
    co.yield()
    print("leave lua_yield")
end

local co_b = co.create(function()
    print("enter co_b")
    clib.f1()
    print("leave co_b")
end)

local ok, err = co.resume(co_b)
print(ok, err)
```  
<br>

编译&执行：    
（install/include 和 install/lib 是把 lua 源码先 make，然后再 make local 得到的）
```
gcc -fPIC -shared -g -o clib.so clib.c -I "/home/ant/code/lua/lua-5.3.6/install/include" -L "/home/ant/code/lua/lua-5.3.6/install/lib"

/home/ant/code/lua/lua-5.3.6/install/bin/lua test_co_1.lua
```   
<br>

输出：   
```
enter f1
enter lua_yield
false   attempt to yield across a C-call boundary
```   
<br>

解释一下上面的代码，在 test_co_1.lua，我们创建了一个协程 co_b，co_b 里面调用了 c 函数 f1，而 f1 又通过 lua_call 调用了 test_co_1.lua 里面定义的 lua 函数 lua_yield，而 lua_yield 含有 yield 逻辑，所以就报错了：attempt to yield across a C-call boundary 。符合上文说的，只要这样就会报错： `... -> lua_call -> ... -> yield `。    
<br>

那如果 lua_call 不报错，允许 co_b 去 yield，当我们再次 resume co_b 的时候，f1 的那句 `printf("leave f1\n");` 会执行吗？不会的，因为栈帧已经完全被破坏，回不来了。  
<br>

## 深入讨论
上文的例子中，如果把 clib 的 f1 改成这样，会报错吗？
```
static int f1(lua_State* L) {
    printf("enter f1\n");
    lua_yield()
    printf("leave f1\n");
    return 0;
}
```  

不会的，它的输出是这样的：   
```
enter co_b
enter f1_v2
true    nil
```

为什么不会报错呢？在 co_b 中这样调用 clib.f1()，看起来就是调用一个 c 函数，这个地方难道不是用 lua_call 来调 c 函数的吗？还真的不是，这个我们可以通过生成 lua 的字节码来看一下。  
<br>

生成 lua 字节码可以使用这样的命令: `luac -l -l -p <文件名>`，对于上文的 test_co_1.lua，命令是这样 `luac -l -l -p test_co_1.lua`。也可以通过这个网站  lua bytecode explorer: [https://www.luac.nl/)](https://www.luac.nl/)，这个网站厉害的地方在于它有好多个 lua 版本可选，特别方便。   

上文 test_co_1.lua 用 lua bytecode explorer 生成出来的字节码是这样的：  
![lua-coroutine-yield-bytecode](https://blog.antsmallant.top/media/blog/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary/lua-coroutine-yield-bytecode.png)   
<center>图2：test_co_1.lua 的字节码</center>
<br>

关于字节码的具体含义，可以参考这个文章：[Lua 5.3 Bytecode Reference](https://the-ravi-programming-language.readthedocs.io/en/latest/lua_bytecode_reference.html)，或是这个文章：[深入理解 Lua 虚拟机](https://cloud.tencent.com/developer/article/1648925)。     
<br>  

说回 co_b，调用 clib.f1()，实际上是使用了 lua 的指令 CALL，如下图所示：  
![lua-coroutine-yield-bytecode-co-func](https://blog.antsmallant.top/media/blog/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary/lua-coroutine-yield-bytecode-co-func.png)   
<center>图3：co_b 的字节码</center>

<br>
<br>
<br>
