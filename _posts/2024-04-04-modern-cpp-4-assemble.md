---
layout: post
title: "现代 c++ 四：查看汇编代码、看懂汇编代码"
date: 2024-04-04
last_modified_at: 2024-04-04
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>


本文记录一下 c++ 如何查看生成出来的汇编代码，以及如何看懂代码。   

---

# 1. 查看汇编代码

---

## 1.1 使用 compiler explorer 在线查看

compiler explorer 是一个网站，地址是： https://gcc.godbolt.org/ 。它的功能非常非常强大:   

* 支持各种编译器： gcc, clang, msvc ... 并且编译器还可选不同平台或架构的：x86-64, arm, powerpc, sparc, s390x, vax ...   
* 支持汇编选项，比如指定 c++20 版本，只要在编译选项加上 `-std=c++20` 即可
* 支持分享代码片段，可以生成一条短链接，比如我写的 hello world 代码： https://gcc.godbolt.org/z/87xT8scqn  
* 除了 c++，还支持另外几十种语言，比如 c, c#, python, golang, java, erlang 等等，要么生成汇编代码，要么生成字节码   

![compiler-explorer-cpp-helloworld](https://blog.antsmallant.top/media/blog/modern-cpp/compiler-explorer-cpp-helloworld.png)   
<center>图1：compiler explorer c++ hello world</center>

![compiler-explorer-python3-helloworld](https://blog.antsmallant.top/media/blog/modern-cpp/compiler-explorer-python3-helloworld.png)   
<center>图2：compiler explorer python hello world</center>


遗憾的是，compiler explorer 不支持 lua。不过，这个网站【lua Bytecode Explorer】支持，地址是：https://www.luac.nl/ 。功能很强大，支持从 lua4.0 到 lua5.4 的各个版本。  

![luac-lua-helloworld](https://blog.antsmallant.top/media/blog/modern-cpp/luac-lua-helloworld.png)   
<center>图3：luac lua hello world</center>


---

## 1.2 使用 gcc 生成汇编代码

使用 `gcc -S` 编译成汇编代码，然后再用 c++filt demangling 里面那些被 mangling 的 C++ 符号。    

假设你的文件叫 abc.cpp   

```cpp
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

```bash
g++ -S abc.cpp -o abc.s
```

生成出来的汇编代码 abc.s 是这样的:   

```
	.file	"abc.cpp"
	.text
	.local	_ZStL8__ioinit
	.comm	_ZStL8__ioinit,1,1
	.section	.rodata
.LC0:
	.string	"c0 c0f1"
	.section	.text._ZN2C04c0f1Ev,"axG",@progbits,_ZN2C04c0f1Ev,comdat
	.align 2
	.weak	_ZN2C04c0f1Ev
	.type	_ZN2C04c0f1Ev, @function
_ZN2C04c0f1Ev:
.LFB1731:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16

    ...
```

读起来有点费劲，因为它把我们的函数名都 mangling 了，比如 C0::c0f1 被编成这样了：_ZN2C04c0f1Ev，为了好看一些，需要 demangling，可以使用 c++filt 这个工具来做。它有两种用法，都是一样的效果。  

c++filt 用法一：  

```bash
c++filt<abc.s>abc_demangle.s
```

c++filt 用法二：  

```bash
cat abc.s | c++filt > abc_demangle.s
```

c++filt demangling 之后生成出来的汇编代码 abc_demangle.s 是这样的：    

```
	.file	"abc.cpp"
	.text
	.local	std::__ioinit
	.comm	std::__ioinit,1,1
	.section	.rodata
.LC0:
	.string	"c0 c0f1"
	.section	.text._ZN2C04c0f1Ev,"axG",@progbits,C0::c0f1(),comdat
	.align 2
	.weak	C0::c0f1()
	.type	C0::c0f1(), @function
C0::c0f1():
.LFB1731:
	.cfi_startproc
	endbr64
	pushq	%rbp
	.cfi_def_cfa_offset 16
```

---

# 看懂汇编代码

大学的时候多少都学一点汇编，但估计都忘得差不多了。

---

# 参考