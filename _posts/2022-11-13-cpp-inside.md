---
layout: post
title:  "c++ 对象内存模型探究"
date:   2022-11-13
last_modified_at: 2022-11-13
categories: [lang]
tags: [performance, c++]
---

* 目录  
{:toc}

<br>
<br>
<br>

## 查看汇编代码
* 方法一
  
这个网站 [compiler explorer](https://gcc.godbolt.org/) 可以方便的展示源代码与汇编代码的对应关系，特别方便，比自己用 gcc -S <文件名> 来生成汇编代码看更方便很多，当然也比 objdump -d <binary文件名> 更方便

* 方法二

使用 gcc -S 编译成汇编代码，然后再用 c++filt demangling 里面那些被 mangling 的 C++ 符号。

假设你的文件叫 abc.cpp
```
#include <iostream>
using namespace std;

class C0 {
public:
    void c0f1() {cout << "c0 c0f1" << endl;}
    virtual void c0f2() {cout << "c0 c0f2" << endl;}
    int c0a {10};
};

void test1() {
    C0 c0;
    c0.c0f1();
}

int main() {
    test1();
    return 0;
}
```
运行以下命令
```
g++ -S abc.cpp -o abc.s
c++filt<abc.s>abc_demangle.s
```
这样看 abc_demangle.s 就顺眼多了。

也可以这样来使用 c++filt:
```
cat abc.s | c++filt > abc_demangle.s
```

<br>
<br>
<br>