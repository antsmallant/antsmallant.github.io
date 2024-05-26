---
layout: post
title: "lua: attempt to yield across a C-call boundary 的原因分析"
date: 2023-10-08
last_modified_at: 2023-10-08
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>


使用 lua 的时候有时候会遇到这样的报错："attempt to yield across a C-call boundary"。   

---

# 1. 网络上的解释

可以在网上找到一些关于这个问题的解释。  

---

## 1.1 解释一

这个 issue：[一个关于 yield across a C-call boundary 的问题](https://github.com/cloudwu/skynet/issues/394)，云风的解释是：   

>`C (skynet framework)->lua (skynet service) -> C -> lua`
>最后这个 lua 里如果调用了 yield 就会产生。   

<br/>

---

## 1.2 解释二

这篇文章 [lua中并不能随意yield](https://radiotail.github.io/2016/05/18/lua%E4%B8%AD%E5%B9%B6%E4%B8%8D%E8%83%BD%E9%9A%8F%E6%84%8Fyield/) 提到：    

>流程：`coroutine --> c --> coroutine --> yield  ===> 报错`   
>为什么这种情况下lua会给出这种报错呢？主要是因为在从c函数调回到coroutine中yield时，coroutine当前的堆栈情况会被保存在lua_State中，因此在调用resume时，lua可以恢复yield时的场景，并继续执行下去。但c函数不会因为coroutine的yield被挂起，它会继续执行下去，函数执行完后堆栈就被销毁了，所以无法再次恢复现场。而且因为c函数不会被yield函数挂起，导致c和lua的行为也不一致了，一个被挂起，一个继续执行完，代码逻辑很可能因此出错。    

读完反而更困惑了。“c函数不会因为 coroutine 的 yield 被挂起，它会继续执行下去，函数执行完后堆栈就被销毁了”，这里的 c 函数是指哪个呢？是调用了含有 yield 的 lua 代码的 testc 函数，还是 main 函数？如果是 testc 函数，那显然是错的。因为 yield 的内部是通过 longjmp 跳回了上一层的 coroutine，testc 的后续是没有继续执行下去的。   

---

## 1.3 解释三

这篇文章 [深入Lua：在C代码中处理协程Yield](https://zhuanlan.zhihu.com/p/337850564) 提到： 

>原因是Lua使用longjmp来实现协程的挂起，longjmp会跳到其他地方去执行，使得后面的C代码被中断。l_foreach函数执行到lua_call，由于longjmp会使得后面的指令没机会再执行，就像这个函数突然消失了一样，这肯定会引起不可预知的后果，所以Lua不允许这种情况发生，它在调用coroutine.yield时抛出上面的错误。    

作者大致是理解这个问题的，并且点出了问题的关键: “由于longjmp会使得后面的指令没机会再执行”。但讲得不够细，对于问题产生的条件没有讲清楚。     

---

## 1.4 小结

以上解释，感觉都没有把这个问题说清楚，所以有了这篇文章。  

这个问题其实并不复杂，但需要有这些背景知识：c 代码是如何运行的，函数调用时栈帧是如何变化的，lua vm 是如何工作的，setjmp/longjmp 是怎么工作的。   

---

# 2. 问题分析

---

# 2.1 简单概括

实际上问题的关键在于：  

* 一条系统线程只有一个公共的栈（这里称 c 栈）；   

* 每个 lua 协程都有一个独立的 lua 栈；    

* 在 lua 协程中调用一个函数，如果是 lua 函数，则只操作和影响 lua 栈数据；如果是 c 函数，则会操作和影响 lua 栈数据以及 c 栈数据；   

* resume 对应 setjmp，yield 对应 longjmp；   

* 如下图，co2 longjmp 之后 c 栈指针回退到 co1 setjmp 之处；而 yield 出去的协程 co2 的 c 函数就是依赖着 setjmp 到 longjmp 之间的这段 c 栈空间的；既然 c 栈指针被回退了，那么随着 co1 恢复执行，它就会把这段 c 栈空间覆盖掉，所以 co2 里的 c 函数是无法恢复执行的；   

```
      c 栈
      栈底
    |     |
    |     |
    |-----| co1 setjmp (resume) <-
    |     |                      | 
    |     |                      |
    |     |                      |
    |-----| co2 longjmp (yield) ->
      栈顶
```


---

# 3. 代码解析

---

## 3.1 环境说明

以下分析使用的 lua 版本是 5.3.6，下载链接: [https://lua.org/ftp/lua-5.3.6.tar.gz](https://lua.org/ftp/lua-5.3.6.tar.gz)，本人的 github 也有对应源码: [https://github.com/antsmallant/antsmallant_blog_demo/tree/main/3rd/lua-5.3.6](https://github.com/antsmallant/antsmallant_blog_demo/tree/main/3rd/lua-5.3.6) 。    

下文展示的 demo 代码都在此：[https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary](https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary) 。 

## 3.2 源码上分析

首先，什么情况下才会出现这个错误？上面文章提到的 `C (skynet framework)->lua (skynet service) -> C -> lua` 或 `coroutine --> c --> coroutine --> yield  ===> 报错`，都说得太笼统了，不够精确。    

看一下 lua 源码里面的 lua_yieldk（ [ldo.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/3rd/lua-5.3.6/src/ldo.c) ）的实现，就可以知道，在一个协程的调用链中，出现一个 luaD_callnoyield 调用之后再 yield 就会报错，大致是这样：`... -> luaD_callnoyield -> ... -> yield`。并且，不管这个 yield 是在 c 中调用 `lua_yield` 还是在 lua 中调用 `coroutine.yield`。   

那 luaD_callnoyield 具体是如何限制后续逻辑调用 yield 的呢？  

先看一下 luaD_callnoyield ( [ldo.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/3rd/lua-5.3.6/src/ldo.c) ) 的实现：   

```c
void luaD_callnoyield (lua_State *L, StkId func, int nResults) {
  L->nny++;
  luaD_call(L, func, nResults);
  L->nny--;
}
```    

再看下 lua_yieldk ( [ldo.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/3rd/lua-5.3.6/src/ldo.c) ) 的实现:   

```c
LUA_API int lua_yieldk (lua_State *L, int nresults, lua_KContext ctx,
                        lua_KFunction k) {
  ...
  if (L->nny > 0) {
    if (L != G(L)->mainthread)
      luaG_runerror(L, "attempt to yield across a C-call boundary");
    else
      luaG_runerror(L, "attempt to yield from outside a coroutine");
  }
  L->status = LUA_YIELD;
  ci->extra = savestack(L, ci->func);  /* save current 'func' */
  ...
}
```     

从源码可以看出，luaD_callnoyield 是通过设置 `L->nny` 这个变量来控制的。    

那什么情况下会调用 luaD_callnoyield 呢？从源码上看有好几处，但跟日常开发关系密切的只有 lua_callk 及 lua_pcallk，这两个函数大同小异，就先看一下 lua_callk ( [lapi.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/3rd/lua-5.3.6/src/lapi.c) ) 的实现：  

```c
LUA_API void lua_callk (lua_State *L, int nargs, int nresults,
                        lua_KContext ctx, lua_KFunction k) {
  ...
  func = L->top - (nargs+1);
  if (k != NULL && L->nny == 0) {  /* need to prepare continuation? */
    L->ci->u.c.k = k;  /* save continuation */
    L->ci->u.c.ctx = ctx;  /* save context */
    luaD_call(L, func, nresults);  /* do the call */
  }
  else  /* no continuation or no yieldable */
    luaD_callnoyield(L, func, nresults);  /* just do the call */
  ...
}
```     

lua_callk 在 `L->nny > 0` 或者参数 k 为 NULL 的时候，都会调用 luaD_callnoyield。`L->nny > 0` 的情况不用说了，肯定是要调用 luaD_callnoyield 的。但 k 是什么呢？k 是 continuation function，就是执行完要调用的函数之后，后续要执行的函数。这里 ( [https://lua.org/manual/5.3/manual.html#4.7](https://lua.org/manual/5.3/manual.html#4.7) ) 有解释，后文也会解释。    

但是通常使用的函数是 lua_call/lua_pcall ( [lua.h](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/3rd/lua-5.3.6/src/lua.h) )，这两个函数的定义是这样的：

```c
#define lua_call(L,n,r)		lua_callk(L, (n), (r), 0, NULL)
#define lua_pcall(L,n,r,f)	lua_pcallk(L, (n), (r), (f), 0, NULL)
```  

它们传递的参数 k 都为 NULL，所以这两个绝对会调用 luaD_callnoyield。   

ok，现在知道，一个协程的调用链中如果先出现 lua_call 或 lua_pcall，之后就不能有 yield 了。但为什么要这样限制呢？   

这个跟 lua 协程的实现有关，它是通过 setjmp 和 longjmp 实现的，resume 对应 setjmp，yield 对应 longjmp。longjmp 对于协程内部纯 lua 的栈没啥影响，因为每个协程都有一块内存来保存自己的栈，但对于 C 栈就有影响了，一个线程只有一个 C 栈，longjmp 的时候，直接改掉了 C 栈的栈顶指针。如下图所示，longjmp 之后，逻辑回到了 A，那么 B 对应的整个栈帧都会被覆盖掉（相当于被抹除了）。即 B 协程 yield 之后需要执行的 C 代码就不执行了。           

![](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-co-yield-across-c-call-boundary.png)  
<center>图1：yield 示意图</center>  

解释得七七八八了，但还是有些抽象。先举个简单的例子来验证一下上面的说法吧。以下 demo 代码在这里可以找到： [https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary](https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary) 。      

[clib.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/blog_demo/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary/clib.c)  

```c
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

[test_co_1.lua](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/blog_demo/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary/test_co_1.lua)  

```lua
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

编译&执行：    

```bash
gcc -fPIC -shared -g -o clib.so clib.c -I "../../3rd/lua-5.3.6/install/include" -L "../../3rd/lua-5.3.6/install/lib"

../../3rd/lua-5.3.6/install/bin/lua test_co_1.lua
```      

输出：   

```
enter f1
enter lua_yield
false   attempt to yield across a C-call boundary
```   

解释一下上面的代码，在 test_co_1.lua，创建了一个协程 co_b，co_b 里面调用了 c 函数 f1，而 f1 又通过 lua_call 调用了 test_co_1.lua 里面定义的 lua 函数 lua_yield，而 lua_yield 含有 yield 逻辑，所以就报错了：attempt to yield across a C-call boundary 。符合上文说的，只要这样就会报错： `... -> lua_call -> ... -> yield `。    

那如果 lua_call 不报错，允许 co_b 去 yield，当再次 resume co_b 的时候，f1 的那句 `printf("leave f1\n");` 会执行吗？不会的，因为栈帧已经完全被破坏了，不会执行 yield 之后的 C 代码了。    

---

# 4. 深入讨论

## 4.1 lua 调用 C 函数是使用 lua_call/lua_pcall 吗？   

答案：不是。   
上面的例子中，如果把 clib 的 f1 改成这样，还会报错吗？   

```c
static int f1(lua_State* L) {
    printf("enter f1\n");
    lua_yield(L, 0);
    printf("leave f1\n");
    return 0;
}
```      

它的输出是这样的，没有报错了：   

```
enter co_b
enter f1
true    nil
```    

为什么不会报错了呢？因为 co_b 里面调用 clib.f1，其底层实现并不是使用 lua_call/lua_pcall。那具体是什么呢？可以在 test_co_1.lua 对应的 lua 字节码中寻找答案。    

生成 lua 字节码可以使用这样的命令: `luac -l -l -p <文件名>`，对于上文的 test_co_1.lua，命令是： `luac -l -l -p test_co_1.lua`。也可以使用这个在线的 lua bytecode explorer: [https://www.luac.nl/](https://www.luac.nl/) 进行查看，这个网站厉害的地方在于它有好多个 lua 版本可选，很方便。       

test_co_1.lua 用 lua bytecode explorer 生成出来的字节码是这样的：  
![lua-coroutine-yield-bytecode](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary/lua-coroutine-yield-bytecode.png)   
<center>图2：test_co_1.lua 的字节码</center>    

关于字节码的具体含义，可以参考这个文章：[Lua 5.3 Bytecode Reference](https://the-ravi-programming-language.readthedocs.io/en/latest/lua_bytecode_reference.html)，或是这个文章：[深入理解 Lua 虚拟机](https://cloud.tencent.com/developer/article/1648925)。       

说回 co_b，调用 clib.f1 实际上是使用了 lua 的 CALL 指令，如下图所示：  
![lua-coroutine-yield-bytecode-co-func](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary/lua-coroutine-yield-bytecode-co-func.png)   
<center>图3：co_b 的字节码</center>    

CALL 指令是如何实现的呢？可以看一下源码 ( [lvm.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/3rd/lua-5.3.6/src/lvm.c) 的 luaV_execute ) ：  

```c
void luaV_execute (lua_State *L) {
    ...
      vmcase(OP_CALL) {
        int b = GETARG_B(i);
        int nresults = GETARG_C(i) - 1;
        if (b != 0) L->top = ra+b;  /* else previous instruction set top */
        if (luaD_precall(L, ra, nresults)) {  /* C function? */
          if (nresults >= 0)
            L->top = ci->top;  /* adjust results */
          Protect((void)0);  /* update 'base' */
        }
        else {  /* Lua function */
          ci = L->ci;
          goto newframe;  /* restart luaV_execute over new Lua function */
        }
        vmbreak;
      }
    ...
}
```   

可以看到 OP_CALL 只是调用了 luaD_precall ( [lvm.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/3rd/lua-5.3.6/src/lvm.c) )，而 luaD_precall 的内部并没有调用到 lua_call/lua_pcall 或 luaD_callnoyield 。    

---

## 4.2 怎么才能随心所欲的 yield 呢？

上面的例子中把 clib 的 f1 改成这样就可以 yield 了：  

```c
static int f1(lua_State* L) {
    printf("enter f1\n");
    lua_yield(L, 0);
    printf("leave f1\n");
    return 0;
}
```      
 
但是 yield 之后再次 resume，这句 `printf("leave f1\n");` 却没有被执行了。原因在上文也解释了。那要怎么做才能让它在 resume 之后被执行呢？这就得用到 lua_callk/lua_pcallk/lua_yieldk 了，这也是上文中提到的解决方案 [https://lua.org/manual/5.3/manual.html#4.7](https://lua.org/manual/5.3/manual.html#4.7) 。    

举个例子说明一下怎么使用，这里是在 C 代码中直接 yield 的，所以使用 lua_yieldk 就够了。    

[clib.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/blog_demo/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary/clib.c)   

```c
static int f1_v2_continue (lua_State *L, int d1, lua_KContext d2) {
  printf("leave f1_v2\n");
  return 0;
}

static int f1_v2(lua_State* L) {
    printf("enter f1_v2\n");
    lua_yieldk(L, 0, 0, f1_v2_continue);
    return 0;
}
```  

[test_co_2.lua](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/blog_demo/2023-10-08-lua-coroutine-yield-across-a-c-call-boundary/test_co_2.lua)   

```lua
local co = require "coroutine"
local clib = require "clib"

local co_b = co.create(function()
    print("enter co_b")
    clib.f1_v2()
    print("leave co_b")
end)

local ok, err = co.resume(co_b)
print(ok, err)

local ok, err = co.resume(co_b)
print(ok, err)
```   

编译&执行：    

```bash
gcc -fPIC -shared -g -o clib.so clib.c -I "../../3rd/lua-5.3.6/install/include" -L "../../3rd/lua-5.3.6/install/lib"

../../3rd/lua-5.3.6/install/bin/lua test_co_2.lua
```       

输出：

```
enter co_b
enter f1_v2
true    nil
leave f1_v2
leave co_b
true    nil
```   

通过把 `printf("leave f1_v2\n");` 放到 f1_v2_continue 里面去执行，在第二次 resume 的时候成功输出了 `leave f1_v2`。     

---

## 4.3 lua 提供的函数里面，哪些容易导致这个报错？  

skynet ([https://github.com/cloudwu/skynet](https://github.com/cloudwu/skynet)) 里面调用 require 的时候很容易就报这个错： "attempt to yield across a C-call boundary"。看一下 require 是不是调用了 lua_call/lua_pcall，它对应的实现是 ll_require ( [loadlib.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/3rd/lua-5.3.6/src/loadlib.c) )，从源码上看，确实使用了 lua_call。

```c
static int ll_require (lua_State *L) {
  ...
  findloader(L, name);
  lua_pushstring(L, name);  /* pass name as argument to module loader */
  lua_insert(L, -2);  /* name is 1st argument (before search data) */
  lua_call(L, 2, 1);  /* run loader to load module */
  ...
}
```   

再翻看其他源码，可以发现，常用的这两个函数：luaL_dostring、luaL_dofile 也会调用 lua_call/lua_pcall，所以也是容易报错的。  

那有没有使用 lua_callk/lua_pcallk 来避免报错的呢？有的，比如 lua 函数: dofile，它对应的实现是 luaB_dofile ( [lbaselib.c](https://github.com/antsmallant/antsmallant_blog_demo/blob/main/3rd/lua-5.3.6/src/lbaselib.c) )，使用了 lua_callk。  

```c
static int dofilecont (lua_State *L, int d1, lua_KContext d2) {
  (void)d1;  (void)d2;  /* only to match 'lua_Kfunction' prototype */
  return lua_gettop(L) - 1;
}
static int luaB_dofile (lua_State *L) {
  const char *fname = luaL_optstring(L, 1, NULL);
  lua_settop(L, 1);
  if (luaL_loadfile(L, fname) != LUA_OK)
    return lua_error(L);
  lua_callk(L, 0, LUA_MULTRET, 0, dofilecont);
  return dofilecont(L, 0, 0);
}
```   

<br/>     
     
---

# 5. 总结
* 一般情况下，lua_call/lua_pcall 之后如果跟着 yield，就会报这个错：attempt to yield across a C-call boundary。问题的根本原因是 lua 协程的 yield 是通过 longjmp 实现的，longjmp 直接回退了 C 栈的指针，使得执行了 yield 的协程的 C 栈被抹掉了，那么执行到一半的 C 逻辑就不会在下次 resume 的时候继续执行。  

* 要规避这个问题，可以使用 lua_callk/lua_pcallk/lua_yieldk，显式的指定一个函数作为 yield 回来后要执行的内容。  

* lua 提供的函数中，有些使用了 lua_call/lua_pcall，很容易触发这个问题，比如 lua 函数：require，c 函数：luaL_dostring、luaL_dofile；而有些使用了 lua_callk/lua_pcallk 规避这个问题，比如 lua 函数：dofile。    

* 使用这个网站 [https://www.luac.nl/](https://www.luac.nl/)，或者使用 `luac -l -l -p <文件名>` 可以查看 lua 字节码。    
