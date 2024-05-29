---
layout: post
title: "lua vm 常识二: 查看字节码、看懂字节码"
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

如果是对于一份经过 luac 编译的字节码文件，则直接 `luac -l <文件名>` 或 `luac -l -l <文件名>` 就行了，直接显示。比如这样： 

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

最直接的方式是看源码，所有指令的定义在这个代码文件：lopcodes.h ，不同指令的具体实现在 lvm.c 的 `luaV_execute` 函数里。  

<br/>

**方法二：一些文档或文章**    

lua5.2 :  http://files.catwell.info/misc/mirror/lua-5.2-bytecode-vm-dirk-laurie/lua52vm.html     

lua5.3 :  https://the-ravi-programming-language.readthedocs.io/en/latest/lua_bytecode_reference.html   

lua5.4 :  https://zhuanlan.zhihu.com/p/277452733    

<br/>

---

## 2.2 指令的基本格式

lua5.4 指令的基本信息：  

* 使用一个 32 位的无符整数来表示一个指令，包含两大部分：指令码和操作数

* 其中前 7 位用于表示指令码，其余的根据指令码使用不同的编码格式去解析

* 有 5 种格式编码格式：iABC, iABx, iAsBx, iAx, isJ，每个指令只属于其中之一   

下图取自 lua 源码中的 lopcode.h，它精确的标明了不同编码格式用到了哪些 bit 位。  

<br/>

<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-lua5.4-opcode.png"/>
</div>
<center>图2：lua5.4 opcode 格式</center>

<br/>

举例说明一下，

---

## 2.3 几个特别的指令说明

---

## 2.4 举个例子

---

## 3. 参考
