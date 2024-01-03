---
layout: post
title:  "lua: attempt to yield across a C-call boundary 的原因分析"
date:   2024-01-02
last_modified_at: 2024-01-02
categories: [lang]
tags: [lua]
---

* 目录  
{:toc}

<br>
<br>
<br>

## 问题背景
使用 lua 的时候有时候会遇到这样的报错："attempt to yield across a C-call boundary"。  

比如这个 issue [一个关于 yield across a C-call boundary 的问题](https://github.com/cloudwu/skynet/issues/394) 提到的。云风的解释是：
>`C (skynet framework)->lua (skynet service) -> C -> lua`
>最后这个 lua 里如果调用了 yield 就会产生。

有一些文章对这个问题做出解释。  

比如这个文章 [lua中并不能随意yield](https://radiotail.github.io/2016/05/18/lua%E4%B8%AD%E5%B9%B6%E4%B8%8D%E8%83%BD%E9%9A%8F%E6%84%8Fyield/) 提到：  
>流程：`coroutine --> c --> coroutine --> yield  ===> 报错`   
>为什么这种情况下lua会给出这种报错呢？主要是因为在从c函数调回到coroutine中yield时，coroutine当前的堆栈情况会被保存在lua_State中，因此在调用resume时，lua可以恢复yield时的场景，并继续执行下去。但c函数不会因为coroutine的yield被挂起，它会继续执行下去，函数执行完后堆栈就被销毁了，所以无法再次恢复现场。而且因为c函数不会被yield函数挂起，导致c和lua的行为也不一致了，一个被挂起，一个继续执行完，代码逻辑很可能因此出错。

读完反而更困惑了。“c函数不会因为 coroutine 的 yield 被挂起，它会继续执行下去，函数执行完后堆栈就被销毁了”，这里的 c 函数是指哪个呢？是调用了含有 yield 的 lua 代码的 testc 函数，还是 main 函数？如果是 testc 函数，那显然是错的。因为 yield 的内部是通过 longjmp 跳回了上一层的 coroutine，testc 的后续是没有继续执行下去的。

再比如这个文章 [深入Lua：在C代码中处理协程Yield](https://zhuanlan.zhihu.com/p/337850564) 提到：
>原因是Lua使用longjmp来实现协程的挂起，longjmp会跳到其他地方去执行，使得后面的C代码被中断。l_foreach函数执行到lua_call，由于longjmp会使得后面的指令没机会再执行，就像这个函数突然消失了一样，这肯定会引起不可预知的后果，所以Lua不允许这种情况发生，它在调用coroutine.yield时抛出上面的错误。

这个作者大致是理解这个问题的，并且点出了问题的根源:“由于longjmp会使得后面的指令没机会再执行”。但是，讲得不够细，不够精确，对于问题产生的条件没有讲清楚。  

所以，本文将尝试更清楚的剖析这个问题。


## 问题复现
首先，什么情况下才会出现这个错误？   
上面文章提到的 `C (skynet framework)->lua (skynet service) -> C -> lua` 或 `coroutine --> c --> coroutine --> yield  ===> 报错`，都说得太笼统了。  
其实，看一下 lua 源码里面的 `lua_yieldk` 函数（在 ldo.c 中）的实现，就可以知道，只要满足这样的条件就会报错：在同一个协程的调用链中，出现一个 c 调用，之后再 yield。大致是这样：`... -> c -> ... -> yield`。并且，不管这个 yield 是在 c 中还是 lua 中，都会引起报错。此处的关键是：同一个协程的调用链中。   
下面举正反两个例子来说明。 

<br>

例1：会报错的  
bad_1.lua
```
local co = require "coroutine"
local ok, err = co.resume(co.create(function()
    print("enter co func")
    require "bad_2"
    print("leave co func")
end))
print(ok, err)
```

bad_2.lua
```
local co = require "coroutine"
co.yield()
```

执行：
```
lua bad_1.lua
```

输出：
```
enter co func
false   attempt to yield across a C-call boundary
```

<br>

例2：不会报错的  
good_1.lua
```
local co = require "coroutine"
local ok, err = co.resume(co.create(function()
    print("enter co func")
    co.yield()
    print("leave co func")
end))
print(ok, err)
```

执行：
```
lua good_1.lua
```

输出：
```
enter co func
true    nil
```

## 问题分析



## 总结
