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

lua vm 运行过程中，栈和 upvalue 是两个重要的数据结构。   

栈是一个很巧妙的设计，它同时能满足 lua、c 函数运行的需要，也能实现 lua 与 c 函数的互相调用。   

upvalue 以一种高效的方式实现了词法作用域，使得函数能成为 lua 中的第一类值；而其高效也导致在实现上有点复杂。   

---

# 1. 栈

---

## 1.1 栈的数据结构

一个操作线程中，可以运行多个 lua vm，lua vm 用 global_State 这个结构体来表示。  

一个 lua vm 中，可以运行多条 lua thread，即协程，lua thread 用 lua_State 这个结构体来表示。  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-lua_State.png"/>
</div>
<center>图1：lua_state</center>
<br/>

每个 lua thread 都有一个专属的 “栈”，它是一个 StackValue 类型的数组，而 StackValue 内部包含了 TValue，它可以表示 lua vm 中所有类型的变量。  

在 lua_State 中，用 stack 和 stack_last 这个字段来描述栈数组，stack 表示数组开头，stack_last 表示数组结尾（真实情况更复杂一点点，末尾还有 EXTRA_STACK 个元素，但问题不大）。  

为了与操作系统线程的栈区别开来，这里称 lua 的这个栈为 lua 数据栈。  

lua 数据栈的作用是处理函数调用以及存储函数运行时需要的数据。  

栈会随着函数调用而增长，增长是通过 luaD_growstack 实现的，但有大小限制，上限为 LUAI_MAXSTACK，在 32位或以上系统中是 1000000，超过就会报 “stack overflow”。  

---

## 1.2 函数调用与栈的关系

协程执行的过程，就是一个函数调用另一个函数的过程，形成一个函数调用链：`f1->f2->f3->....`。    

函数调用在 lua_State 中用 CallInfo 结构体来表示，由 CallInfo 组成的链表，即是函数调用链。     

每个函数在 lua 数据栈上都占用一块空间，其范围是由 CallInfo 的两个字段表述的，func 表示起始位置，p 表示终止位置。一个函数在栈上的数据分布大概是这样的：  

```
      0    1        n     n+1         n+m
func|arg1|arg2|...|argn|var1|var2|...|varm|
```

func 实际上就是 Closure 类型的数据，TValue 可以表示它，而 arg1 ~ argn 表示函数的 n 个形参，var1 ~ varm 表示函数的 m 个本地变量，形参跟本地变量在 lua 里都称为 local vars。它们是在编译期确定好各自在栈中的位置的，0 到 n+m 这些栈元素，也被称为 “寄存器”，用 R 表示，比如 R[0] 就表示 arg1，而 R[n+1] 表示 var1。   

CallInfo 与 stack 的大致对应关系如下：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-stack-and-callinfo.png"/>
</div>
<center>图2：callinfo 与 stack[1]</center>
<br/>

---

## 1.3 CallInfo 中的 top 字段

图2 中的有个细节要纠一下，CallInfo 的 top 字段指向了栈数组中的 argn(R[n]) 项，在一些情况下，并不准确，要分情况讨论。      

1、lua 函数，CallInfo 的 top 指向的应该是 `func + 1 + maxstacksize` 这个位置，maxstacksize 是在编译期确定的这个函数需要的 “寄存器” 总数量。一个普通的 lua 函数，需要的寄存器往往不止要用于存放形参，还有一些本地变量，一些运算过程的中间结果。    

2、c 函数，上图是准确的，




---

## 1.4 固定参数的函数调用

---

## 1.2 不定参数的函数调用

---

# 2. upvalue

---

# 3. 参考

[1] codedump. Lua 设计与实现. 北京: 人民邮电出版社, 2017.8: 45.   