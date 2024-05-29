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

以下分析基于 lua-5.4.6。  

---

# 1. 查看字节码

## 1.1 方法一：使用 luac

`luac -l -p <文件名>` ，如果要完整展示，则用 -l -l ，比如 `luac -l -l -p <文件名>`。  

比如有 lua 脚本 a.lua:  

```lua
print("hello, world")
```

用 `lua -l -l -p a.lua` 生成出来是这样的：  

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

---

## 1.2 方法二：使用在线工具：luac.nl - Lua Bytecode Explorer

Lua Bytecode Explorer 的完整网址是： [https://www.luac.nl/](https://www.luac.nl/)。   

它支持从 4.0 到 5.4.6 的所有版本(截至2024.4)。它还支持生成代码分享链接，在页面底下有 Generate Link 按钮，比如我写的 hello world 脚本： https://luac.nl/s/f79aff49f5fd7746b4e3ae2a65 。  

效果是这样的：  

<br/>

<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-bytecodeexplorer.png"/>
</div>
<center>图1：lua bytecode explorer 生成字节码</center>

<br/>

**大部分情况下，用这个在线网站是最方便的，推荐使用。**  

---

# 2. 看懂字节码

## 2.1 字节码的说明文档

最直接的方式是看源码，



---


