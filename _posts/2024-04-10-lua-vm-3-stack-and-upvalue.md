---
layout: post
title: "lua vm 三: stack 与 upvalue"
date: 2024-04-10
last_modified_at: 2024-04-10
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>

整个 lua 源码看下来，个人觉得栈的实现是最美妙的，它跟 callinfo 一起，完美的实现了 lua 函数调用，以及 c 函数调用。  

本文就讲一讲中 lua 中的栈。以下分析使用 lua-5.4.6 版本。  

---



---

# 1. 简要说明

lua vm (virtual machine，虚拟机) 跟进程有点像，一个 lua vm 内部可以有多个 lua 线程（thread），这种线程又被称为协程 (coroutine)。   

<br/>

<div align="center">  
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-threads.png" />

图1：lua vm threads
</div>

<br/>

理解 vm 的工作机制，只需要了解几个关键点：  

* lua thread 内部是怎么组织函数调用的

* 函数会怎么操作数据？

* 数据是怎么组织的，lua 栈是什么？寄存器又是什么？

至于字节码是怎么被编译出来的，字节码是怎么执行的，这些都是简单问题。  

lua 的协程实现上是一种非对称协程。所谓对称，即是这样的，A 可以 resume B，B 可以 yield 到 

---

# 2. 数据结构

lua vm 使用结构体 `global_State` 来表示，lua thread 使用结构体 `lua_State` 来表示。  

```c
typedef struct global_State {
  // gc 相关的字段
  // ...

  struct lua_State *mainthread;
  
  // 其他 vm 字段 
  // ...
} global_State;
```

---

# 3. 函数调用

这是能真正感受到 lua 和谐的地方，它与 c 融合得特别好。可以在 lua 中调用 c 函数，也可以在 c 中调用 lua 函数。lua 函数只操作 lua 数据栈，而 c 函数也可以通过接口操作 lua 数据栈。   


---

# 4. upvalue

upvalue 即函数引用到的外部变量，像这样

```lua
local x = 10
local function f(y)
    return x + y
end
```

变量 x 就是函数 f 的一个 upvalue。   


---

# 参考
