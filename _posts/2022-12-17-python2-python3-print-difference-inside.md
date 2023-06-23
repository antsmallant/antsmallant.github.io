---
layout: post
title:  "python2 python3 print 在底层实现上的区别是什么？"
date:   2023-1-24
last_modified_at: 2023-1-24
categories: [python]
---

今天在看 python2 与 python3 的区别，看到 print 在 python2 中是语句，在 python3 中是函数，那底层上的区别是什么？

于是我通过查看生成出来的字节码找到了答案，不得不说 python2 真是老 6。
python2 直接用指令来支持的，而 python3 调用了函数。

查看字节码除了下面展示的用 python 自带的 dis 模块，也可以用这个网站：[compiler explorer](https://gcc.godbolt.org/)，当前它只支持 python3，略显遗憾：）另一个遗憾是不支持 lua，但 lua 可以通过 `luac -l -p <文件名>` 来查看。不过对于 c++ 它是特别完善的，支持各种各样的编译器。


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