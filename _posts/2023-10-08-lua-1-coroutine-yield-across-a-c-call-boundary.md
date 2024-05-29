---
layout: post
title: "lua vm 常识一: attempt to yield across a C-call boundary 的原因分析"
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

云风这样解释没问题，但太简了，只说了这样会导致报错，但没具体说为什么会报错。  

---

## 1.2 解释二

这篇文章 [lua中并不能随意yield](https://radiotail.github.io/2016/05/18/lua%E4%B8%AD%E5%B9%B6%E4%B8%8D%E8%83%BD%E9%9A%8F%E6%84%8Fyield/) 提到：    

>流程：`coroutine --> c --> coroutine --> yield  ===> 报错`   
>为什么这种情况下lua会给出这种报错呢？主要是因为在从c函数调回到coroutine中yield时，coroutine当前的堆栈情况会被保存在lua_State中，因此在调用resume时，lua可以恢复yield时的场景，并继续执行下去。但c函数不会因为coroutine的yield被挂起，它会继续执行下去，函数执行完后堆栈就被销毁了，所以无法再次恢复现场。而且因为c函数不会被yield函数挂起，导致c和lua的行为也不一致了，一个被挂起，一个继续执行完，代码逻辑很可能因此出错。    

<br/>

这个接近于胡说了。  

---

## 1.3 解释三

这篇文章 [深入Lua：在C代码中处理协程Yield](https://zhuanlan.zhihu.com/p/337850564) 提到： 

>原因是Lua使用longjmp来实现协程的挂起，longjmp会跳到其他地方去执行，使得后面的C代码被中断。l_foreach函数执行到lua_call，由于longjmp会使得后面的指令没机会再执行，就像这个函数突然消失了一样，这肯定会引起不可预知的后果，所以Lua不允许这种情况发生，它在调用coroutine.yield时抛出上面的错误。    

<br/>

作者点出了问题的关键: “由于longjmp会使得后面的指令没机会再执行”，但讲得不够细，对于问题产生的条件没有讲清楚。     

---

## 1.4 小结

以上解释，感觉都没有把这个问题说清楚，需要深入到 lua vm 的工作机制才能解释清楚，所以有了这篇文章。   

---

# 2. 从原理上分析问题

问题的关键就在于： 

* lua 是通过 setjmp/longjmp 实现 resume/yield 的。  

* lua 函数只操作 lua 数据栈，而 c 函数不止操作 lua 数据栈，还会操作 c 栈（即操作系统线程的栈）。   

* 每个 lua 协程都有一个独立的 lua 数据栈，但每个系统线程只有一个公共的 c 栈。  

* 在协程的函数调用链中，会有 lua 函数也会有 c 函数，如果调用链中有 c 函数，并且在更后续的调用中出现 yield，就会 longjmp 回到 resume (setjmp) 之处，从而导致 c 函数依赖的 c 栈被其他协程的 c 函数调用给覆盖掉。  

setjmp/longjmp 示意图：  

```
c 栈从栈底向栈顶生长 

      c 栈
      栈底
    |     |
    |     |
    |-----| co1 resume (setjmp) <-
    |     |                      | 
    | co2 |                      |
    |stack|                      |
    |-----| co2 yield (longjmp) ->
      栈顶
```    

不懂 setjmp / longjmp 怎么工作的，可以参考这篇文章，讲得很细了： [setjmp是怎么工作的](https://zhuanlan.zhihu.com/p/82492121) 。  


<br/>

<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-co-yield-across-c-call-boundary.png" />
</div>
<center>图1：lua yield 示意图</center>  

<br/>

上图中：   

1、co1 resume 了 co2，co2 开始执行，co2 的 callinfo 调用链中有 lua 也有 c 函数，其中的 c 函数会操作 lua 数据栈和 c 栈，c 栈在图中就是 "co2 c stack" 那一块内存。   

2、co2 yield 的时候，co2 停止执行，co1 从上次 resume 处恢复。 

3、co1 继续往下执行，必然会有 c 函数调用，co1 的 c 函数会把 "co2 c stack" 这块内存覆盖掉，这意味着 co2 那些还没执行完成的 c 函数的 c 栈被破坏了，即使 co2 再次被 resume，也无法正常运行了。   

---

# 3. 从代码上分析问题

其实讲完原理就够了，但是 lua 在 yield 这个问题上会选择性不报错，所以还是有必要从源码上讲一讲。   

以下分析使用的 lua 版本是 5.3.6（lua-5.2 跟 lua-5.4 也是差不多的）。    

lua-5.3.6 官方下载链接: [https://lua.org/ftp/lua-5.3.6.tar.gz](https://lua.org/ftp/lua-5.3.6.tar.gz) 。  

笔者的 github 也有 lua-5.3.6 源码的 copy: [https://github.com/antsmallant/antsmallant_blog_demo/tree/main/3rd/lua-5.3.6](https://github.com/antsmallant/antsmallant_blog_demo/tree/main/3rd/lua-5.3.6) 。     

<br/>
  
下文展示的 demo 代码都在此（有 makefile，可以直接跑起来）：[https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/lua-co-yield](https://github.com/antsmallant/antsmallant_blog_demo/tree/main/blog_demo/lua-co-yield) 。   


---

## 3.1 情况一：lua 调用 c，在 c 中直接 yield

**结果**   
yield 时不会报错，但实际上也没能正常工作。   

**不报错的原因**   
这是 lua 官方的设定，lua 调用 c 函数或者其他什么函数，都是被编译成 OP_CALL 指令，而 OP_CALL 并不会设一个标志位导致后面有 yield 的时候报错；而 c 调用 lua 是用 lua_call 这个 api，它会设置一个标志位，后面 yield 时判断到标志位就报错： "attempt to yield across a C-call boundary"。   

**没能正常工作的原因**  
上面分析过了，yield 之后，协程的 c 栈被恢复执行的协程覆盖掉了。       

<br/>

上代码吧。  

```lua
-- test_co_1.lua

local co = require "coroutine"
local clib = require "clib"

local co2 = co.create(function()
    clib.f1()
end)

-- 第一次 resume
local ok1, ret1 = co.resume(co2)
print("in lua:", ok1, ret1)

-- 第二次 resume
local ok2, ret2 = co.resume(co2)
print("in lua:", ok2, ret2)
```

```c
// clib.c

#include <stdlib.h>
#include <stdio.h>
#include <lua.h>
#include <lauxlib.h>

static int f1(lua_State* L) {
    printf("clib.f1: before yield\n");

    lua_pushstring(L, "yield from clib.f1");
    lua_yield(L, 1);
    
    printf("clib.f1: after yield\n");

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

输出是：   

```
clib.f1: before yield
first time return:      true    yield from clib.f1
second time return:     true    nil
```

clib.f1 的这句代码 `printf("clib.f1: after yield\n");` 在第二次 resume 的时候没有被执行，但代码也没报错，跟开头说的结果一样。lua 大概是认为没有人会这样写代码吧。   

这种情况，如果要让 clib.f1 能执行 yield 之后的，需要把 lua_yield 换成 lua_yieldk，然后把 yield 之后要执行的逻辑放到另一个函数里，类似这样：   

```c

int f2_after_yield(lua_State* L, int status, lua_KContext ctx) {
    printf("clib.f2: after yield\n");
    return 0;
}

static int f2(lua_State* L) {
    printf("clib.f2: before yield\n");

    lua_pushstring(L, "yield from clib.f2");
    lua_yieldk(L, 1, 0, f2_after_yield);
    
    return 0;
}

```

---

## 3.2 情况二：c 调用 lua，lua 后续调用出现 yield

结果：yield 时会报错 "attempt to yield across a C-call boundary"。   

原因：上面原理的时候分析过了，源码实现上，c 调用 lua 是用的 lua_call 这个 api，它会设置一个标志位，在后续调用链中（无论隔了多少层，无论是 c 还是 lua）只要执行了 yield，都会判断标志位，然后触发报错。   

<br/>   

上代码吧：    




---

## 3.3 lua_call 是如何阻止后续 yield 的？

直接看 lua 源码，lua_callk 会调用到 luaD_callnoyield，而 luaD_callnoyield 设置了标志位：  

```c
L->nny++;
```

而在 lua_yieldk 中，判断了标志位：  

```c
  if (L->nny > 0) {
    if (L != G(L)->mainthread)
      luaG_runerror(L, "attempt to yield across a C-call boundary");
    else
      luaG_runerror(L, "attempt to yield from outside a coroutine");
  }
```

---

# 4. 问题总结 & 解决办法

## 4.1 问题总结

经过上面分析，可以看到，问题的核心在于 lua 的多个协程共用一个 c 栈，而协程里面 c 函数调用又会依赖 c 栈，如果在它返回之前就 yield 了，则它依赖的 c 栈会被其他协程覆盖掉，也就无法恢复运行了。按照 luajit 的说法，lua 官方实现不是一种 "fully resumable vm"。   

这里面 yield 又分两种情况：  

|情况|症状|原因|
|:--|:--|:--|
|lua调c|不报错，但也不正常工作|lua 里调用函数（无论 lua 或 c），都是编译成 OP_CALL 指令，这个指令的实现不会设置让 yield 报错的标志位|
|c调lua|报错|用的是 lua_call，它会设置让 yield 报错的标志位| 

---

## 4.2 解决办法

## 4.2.1 lua-5.2 及以上

lua 对于此问题的解决方案是引入 lua_callk / lua_pcallk / lua_yieldk，要求使用者把 yield 之后要执行的东西放到一个单独的函数 (类型为 lua_KFunction) 里，k 意为 continue，把这个 k 函数作为参数传给 lua_callk / lua_pcallk / lua_yieldk，这个 k 函数会被记录起来，等 yield 返回的时候调用它。   

显然，lua 官方的这种方案有点操蛋，但也不失为一种办法。   

不过悲催的是，lua 5.2 才引入 kfunction 的，所以 lua-5.1 要用其他的办法。  

---

## 4.2.2 lua-5.1

lua-5.1 有两个办法，都与 luajit 相关。  

**方法一：使用 luajit**

直接使用 luajit ( [https://luajit.org/luajit.html](https://luajit.org/luajit.html) )，luajit 支持 "Fully Resumable VM"[1]:   

>The LuaJIT VM is fully resumable. This means you can yield from a coroutine even across contexts, where this would not possible with the standard Lua 5.1 VM: e.g. you can yield across pcall() and xpcall(), across iterators and across metamethods.    



**方法二：使用 lua-5.1.5 + coco 库**

coco 库是 luajit 下面的一个子项目 （ [https://coco.luajit.org/index.html](https://coco.luajit.org/index.html) ），它可以独立于 luajit 之外使用的，但它只能用于 lua-5.1.5 版本。  

它的介绍[2]：
>Coco is a small extension to get True C Coroutine semantics for Lua 5.1. Coco is available as a patch set against the standard Lua 5.1.5 source distribution.
>   
>Coco is also integrated into LuaJIT 1.x to allow yielding for JIT compiled functions. But note that Coco does not depend on LuaJIT and works fine with plain Lua.    

coco 库能做到从 c 调用中恢复，是因为它为每个协程准备了专用的 c 栈："Coco allows you to use a dedicated C stack for each coroutine"[2]。  

所以，如果不使用 luajit，就使用官方的 lua-5.1.5，再 patch 上这个 coco 库就可以了。  


---

# 5. 总结

* lua 官方实现的 vm 不是 "fully Resumable" 的，原因在于多个协程共用 c 栈，会导致协程的函数调用链中有 c 函数的情况下，yield 报错或工作不正常。   

* lua 提供的函数中，有些使用了 lua_call/lua_pcall，很容易触发这个问题，比如 lua 函数：require，c 函数：luaL_dostring、luaL_dofile；而有些使用了 lua_callk/lua_pcallk 规避这个问题，比如 lua 函数：dofile。    

* lua-5.2 及以上的，可以使用 lua_callk / lua_pcallk / lua_yieldk 来规避 yield 报错问题。   

* lua-5.1 可以使用 luajit 或 lua-5.1.5+coco库的方法解决 yield 报错。  

---

# 6. 参考

[1] luajit. extensions. Available at https://luajit.org/extensions.html.    

[2] luajit. Coco — True C Coroutines for Lua. Available at https://coco.luajit.org/index.html.   
