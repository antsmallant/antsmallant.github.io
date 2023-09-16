---
layout: post
title:  "python2 python3 print 在底层实现上的区别是什么？"
date:   2022-12-17
last_modified_at: 2022-12-17
categories: [lang]
tags: [python]
---

* awsl  
{:toc}

今天在看 python2 与 python3 的区别的时候，发现：print 在 python2 中是语句，而在 python3 中是函数，那底层上的区别是什么？通过查看生成出来的字节码找到了答案：python2 直接用指令来支持的，而 python3 调用了函数。  
查看字节码除了下面展示的用 python 自带的 dis 模块，也可以用这个网站：[compiler explorer](https://gcc.godbolt.org/)，当前它只支持 python3，btw，也不支持 lua，不过它对 c++ 的支持是特别完善的，支持各种类型的编译器。lua 可以通过 `luac -l -p <文件名>` 来查看，或者使用这个网站：[Lua Bytecode Explorer](https://www.luac.nl/)。  


python2:

```
def hello():
    print 200

import dis
dis.dis(hello)
```
显示的结果是：
```
  2           0 LOAD_CONST               1 (200)
              3 PRINT_ITEM
              4 PRINT_NEWLINE
              5 LOAD_CONST               0 (None)
              8 RETURN_VALUE
```
<br>
<br>
python3:

```
def hello():
    print(200)

import dis
dis.dis(hello)
```
显示的结果是：
```
  2           0 LOAD_GLOBAL              0 (print)
              2 LOAD_CONST               1 (200)
              4 CALL_FUNCTION            1
              6 POP_TOP
              8 LOAD_CONST               0 (None)
             10 RETURN_VALUE
```

<br>
<br>
<br>
<br>
<br>