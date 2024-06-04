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

一个操作系统线程中，可以运行多个 lua vm，lua vm 用 global_State 这个结构体来表示。  

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
      0    1        n   n+1           n+m
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

图2 中的有个细节要纠正一下，CallInfo 的 top 字段指向了栈数组中的 argn(R[n]) 项，在一些情况下，并不准确，要分情况讨论。      

**1、lua 函数**

上图部分准确。在代码中，CallInfo 的 top 指向的是 `func + 1 + maxstacksize` 这个位置，maxstacksize 是在编译期确定的这个函数需要的 “寄存器” 总数量。一个普通的 lua 函数，需要的寄存器往往不止要用于存放形参，还有一些本地变量，一些运算过程的中间结果，所以 maxstacksize 往往是比形参个数大的。      

比如这样一个函数:

```lua
local function f1(x, y)
	local a = x + y
end
```

编译出来成这样：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-f1-compile.png"/>
</div>
<center>图3：编译结果</center>
<br/>

locals 那项显示，它至少需要 3 个寄存器，2 个用于存放形参 x 和 y，1 个用于存放本地变量 a。    

<br/>

**2、c 函数**    

上图完全不准确。CallInfo 的 top 指向的应该是 `func + 1 + LUA_MINSTACK` 这个位置，LUA_MINSTACK 大小为 20，是初始时给 c 函数额外分配的栈空间（除了参数之外的）。   

c 函数是通过 lua api 操作 lua 数据栈的，初始的时候，lua_State 的 top 和 callinfo 的 top 都是指向 argn 的位置的。随着 c 函数的运行，比如通过 lua_push 开头的 api 往栈里面压 n 个数据，top 就相应的增长 n 个位置。   

这也是 lua 数据栈的巧妙之处：    

* 当一个 lua 函数调用一个 c 函数，就先把参数放到栈上，而 c 函数被 op_call 的时候，它又可以通过 lua_to 开头的 api 把栈上保存的参数转换成 c 函数自己的变量。  

* 当一个 c 函数调用一个 lua 函数时，先通过 lua_push 开头的 api 往栈里压 n 个参数以及 lua 函数，然后再调用 lua_call 完成调用，而调用完成后，lua 函数的返回结果又都保存在栈上，这时候 c 函数又可以通过 lua_to 开头的命令获取这些返回结果。    

<br/>

值得注意的是，写 c 函数的时候，要时刻注意栈空间的大小是否足够。这种情况下 lua 不会惯着你了，初始时只提供了额外的 LUA_MINSTACK 个元素的栈空间。当栈空间不够的时候，要使用 luaL_checkstack 来扩容。     


---

## 1.4 固定参数的函数调用

固定参数的函数调用比较简单，比如这样一个简单的打印函数：  

```lua
local function f1(x, y, z)
    print(x, y, z)
end

f1(10, 20, 30)
```

编译出来是这样的： 

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-stack-simple-print-func.png"/>
</div>
<center>图4：简单打印函数的编译结果</center>
<br/>

f1 调用 print 的过程中，栈空间布局是这样的：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-stack-simple-print.drawio.png"/>
</div>
<center>图5：简单打印函数的栈空间布局</center>
<br/>

f1 调用 print 的过程，可以归结为三步：   

第一、把 print 这个函数入栈。   

```
1	GETTABUP	3 0 0	; _ENV "print"
```

通过 GETTABUP 指令，从 `_ENV` 中把 print 这个函数 (实际上是closure) 复制到 R[3] 寄存器上。  

<br/>

第二、把三个参数入栈。  

```
2	MOVE	4 0	
3	MOVE	5 1	
4	MOVE	6 2
```

x，y，z 分别是在 R[0]，R[1]，R[2]，通过 MOVE 指令，把它们复制到 R[4]，R[5]，R[6] 这几个寄存器上。 

<br/>

第三、调用 print 函数。    

```
5	CALL	3 4 1	; 3 in 0 out
```

OP_CALL 的格式是 `OP_CALL,/*	A B C	R[A], ... ,R[A+C-2] := R[A](R[A+1], ... ,R[A+B-1]) */`

A 表示函数的位置，即 R[3]；    
B 表示参数的个数，此处参数个数是确定的，B-1 等于参数个数，这里 B 是 4，刚好对应 3 个参数；     
C 表示返回值的个数，1 表示没有返回值；    

<br/>
<br/>

以上也可以看出，函数占用的栈空间是堆叠在一起的。f1 函数调用 print 函数的时候，要在自己的栈空间上先放入 print 函数的 closure，再放入参数。而当 print 函数开始执行，从 print 函数开始的这段空间又被 print 函数当成自己的栈空间。  

---

## 1.5 不定参数的函数调用

不定参数调用的时候，比较复杂，上面讲 OP_CALL

---

# 2. upvalue

---

## 2.1 upvalue 要解决的问题

upvalue 就是外部函数的局部变量，比如下面的函数定义中，base 就是 inner 这个函数的一个 upvalue。  

```lua
local function getf(delta)
    local base = 100
    local function inner()
        return base+delta
    end
    return inner
end

local f1 = getf(10)
```

upvalue 复杂的地方在于，在离开了 upvalue 的作用域之后，还要能够访问得到。比如上面调用了 `local f1 = getf(10)` ，getf 返回后它的栈空间已经被抹掉了，但 inner 还要能访问 base 这个变量，所以需要想办法把它捕捉下来。  

---

## 2.2 upvalue 的实现


---

# 3. 参考

[1] codedump. Lua 设计与实现. 北京: 人民邮电出版社, 2017.8: 45.   