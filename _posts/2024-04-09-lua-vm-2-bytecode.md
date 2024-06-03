---
layout: post
title: "lua vm 二: 查看字节码、看懂字节码"
date: 2024-04-09
last_modified_at: 2024-04-09
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>

本文讲一讲如何查看 lua 的字节码（bytecode），以及如何看懂字节码。   

以下分析基于 lua-5.4.6，下载地址：[https://lua.org/ftp/](https://lua.org/ftp/) 。 

---

# 1. 查看字节码

## 1.1 方法一：使用 luac

luac 是 lua 自带的编译程序，用法是：`luac -l -p <文件名>` ，如果要完整展示，则用 `-l -l`，比如 `luac -l -l -p <文件名>`。  

有 lua 脚本 a.lua:  

```lua
print("hello, world")
```

用 `luac -l -l -p a.lua` 生成出来是这样的：  

```
main <a.lua:0,0> (5 instructions at 0x55a732d64cc0)
0+ params, 2 slots, 1 upvalue, 0 locals, 2 constants, 0 functions
        1       [1]     VARARGPREP      0
        2       [1]     GETTABUP        0 0 0   ; _ENV "print"
        3       [1]     LOADK           1 1     ; "hello, world"
        4       [1]     CALL            0 2 1   ; 1 in 0 out
        5       [1]     RETURN          0 1 1   ; 0 out
constants (2) for 0x55a732d64cc0:
        0       S       "print"
        1       S       "hello, world"
locals (0) for 0x55a732d64cc0:
upvalues (1) for 0x55a732d64cc0:
        0       _ENV    1       0
```

<br/>

如果是一份由 luac 编译生成出来的字节码文件，则直接 `luac -l <文件名>` 或 `luac -l -l <文件名>` 就行了。比如这样： 

```bash
luac -o a.lua.out a.lua

luac -l -l a.lua.out
```

---

## 1.2 方法二：使用在线工具：luac.nl - Lua Bytecode Explorer

Lua Bytecode Explorer 的完整网址是： [https://www.luac.nl/](https://www.luac.nl/)。   

它支持从 4.0 到 5.4.6 的所有版本(截至 2024.4)。它还支持生成代码分享链接，在页面底下有 Generate Link 按钮，比如我写的 hello world 脚本： https://luac.nl/s/f79aff49f5fd7746b4e3ae2a65 。  

**大部分情况下，用这个在线网站是最方便的，推荐使用。**  

效果是这样的：  

<br/>

<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-bytecodeexplorer.png"/>
</div>
<center>图1：lua bytecode explorer 生成字节码</center>

<br/>

---

# 2. 看懂字节码

## 2.1 指令集的说明文档

**方法一：lua 源码**   

最直接的方式是看源码，所有指令的定义在这个代码文件：lopcodes.h ( [https://lua.org/source/5.4/lopcodes.h.html](https://lua.org/source/5.4/lopcodes.h.html) )，不同指令的具体实现在 lvm.c ( [https://lua.org/source/5.4/lvm.c.html](https://lua.org/source/5.4/lvm.c.html) ) 的 `luaV_execute` 函数里。  

<br/>

**方法二：一些文档或文章**    

lua5.2 :  http://files.catwell.info/misc/mirror/lua-5.2-bytecode-vm-dirk-laurie/lua52vm.html     

lua5.3 :  https://the-ravi-programming-language.readthedocs.io/en/latest/lua_bytecode_reference.html   

lua5.4 :  https://zhuanlan.zhihu.com/p/277452733    

<br/>

---

## 2.2 指令的基本格式

lua5.4 指令的基本信息：  

* 使用一个 32 位的无符整数来表示一个指令，包含两大部分：操作码和操作数

* 其中前 7 位用于表示操作码，其余的是操作数，操作数要根据操作码使用不同的编码格式去解析

* 有 5 种格式编码格式：iABC, iABx, iAsBx, iAx, isJ，每个指令只属于其中之一   

下图取自 lua 源码中的 lopcode.h，它精确的标明了不同编码格式用到了哪些 bit 位。  

<br/>

<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-lua5.4-opcode.png"/>
</div>
<center>图2：lua5.4 opcode 格式</center>

<br/>

---

## 2.3 指令编码格式

有 5 种指令编码格式，比如 iABC，i 表示 instruction，ABC 分别是三个操作数。  

举个具体的例子说明一下吧，对于这样一个脚本：

```lua
local function my_add(x, y)
	local z = x + y
    return z
end
```

用 lua bytecode explorer 生成的，代码片段的 link 是 https://luac.nl/s/fac2949499991b83b0e3ae2a65 ，编译结果如下图：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-lua5.4-opcode-add-example.png"/>
</div>
<center>图3：简单加法例子</center>
<br/>

`local z = x + y` 这个语句被编译成这两句：   

```
1	ADD	2 0 1	
2	MMBIN	0 1 6	; __add
```

MMBIN 这句可以不用管，是元表相关的，这里不会用到，只关注 ADD 这一句就好了。  

加法指令 OP_ADD 就是 iABC 格式的：   

```c
OP_ADD,/*	A B C	R[A] := R[B] + R[C]				*/
```

`ADD 2 0 1` 中 A 对应 2，B 对应 0，C 对应 1。R[0] 存的是形参 x 的值，R[1] 存的是形参 y 的值，R[2] 存的是局部变量 z 的值。  

所以 `local z = x + y` 就翻译成 `R[2] = R[0] + R[1]`。   


看到这里可能会有点晕，R[0] 是什么东西？这就是 lua 的 “寄存器”，但它是虚拟出来的，代表的实际上是 lua 数据栈的一个位置，而 lua 数据栈是一个数组结构，每个函数都会在这个数组上占据一段空间。   

可以理解为，每个函数都有一个自己的栈，它是一个数组。数组的最前面放的是参数 (在 lua 中，函数参数也被当成局部变量)，之后放的是函数内的局部变量。在我们的例子中，数据是这样放的：     

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-lua5.4-opcode-add-example-array.png"/>
</div>
<center>图4：简单加法的数据结构</center>
<br/>

实际上，编译结果的 locals 项已经清楚表明了各个变量在 lua 数据栈中的位置了，index 列就表示在数据栈数组中的索引。

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-lua5.4-opcode-add-example-locals.png"/>
</div>
<center>图5：locals 信息</center>
<br/>

---

## 2.4 为什么一个函数生成了两个 return 的 opcode

上图中，可以看到 my_add 函数，我们只写了一个 return 语句，但却有两个 return opcode，而 main 函数，我们没有 return，也有一个 return opcode。下面具体解释一下。  

my_add 的两个分别对应 OP_RETURN1 和 OP_RETURN0。第一个 return1 对应的是 `return c` 这个语句。第二个 return0 是 lua 编译器自动生成的，每个函数的末尾都会补充一个 "final return"。   

具体源码可以在 lparser.c 找到，里面分别处理 main 函数和普通函数，lua 会把一个 script 脚本处理成一个函数，叫 main 函数，即上图中的 `function main`。  

我们显式写的 return 语句，是在 lparser.c 的 `retstat` 函数处理的，它内部调用 `luaK_ret` 生成一个 return 的 opcode。  

main 函数，是在 lparser.c 的 `mainfunc` 函数处理的，末尾调用 `close_func` 处理收尾工作，`close_func` 内部会调用 `luaK_ret` 生成一个 return 的 opcode。  

普通函数，是在 lparser.c 的 `body` 函数处理的，末尾也调用 `close_func` 处理收尾工作，同上。  

---

# 3. 参考
