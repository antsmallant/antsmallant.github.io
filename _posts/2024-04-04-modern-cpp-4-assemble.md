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


很多时候，要真正理解 c++ 一些特性的实现原理，最快的方式是自己亲自查看 c++ 代码对应的汇编代码。  

本文记录一下 c++ 如何查看生成出来的汇编代码，以及如何看懂代码。   

---

# 1. 先不看汇编

汇编的可读性挺差的，如果有得选，还是先用 cpp insights，看一看编译器角度生成的源码。cpp insights 的地址是 https://cppinsights.io/ ，官网对它的介绍[2]：  

>C++ Insights is a clang-based tool which does a source to source transformation. Its goal is to make things visible, which normally and intentionally happen behind the scenes. It's about the magic the compiler does for us to make things work.   

翻译过来就是：c++ insights 是一个基于 clang 的工具，用于执行源码到源码的转换。它的目标是让幕后的事情变得可见。关于编译器为了使事情正常工作所做的魔术。   

直接看一下它能帮你洞察什么。 

![cpp-insights-cpp-lambda](https://blog.antsmallant.top/media/blog/modern-cpp/cpp-insights-cpp-lambda.png)   
<center>图0：cpp-insights-cpp-lambda</center>

上面写了一小段 lambda 代码，c++ insights 帮忙生成出来了编译器视角的源码，从中我们可以清晰的看到 c++ 内部是如何实现 lambda 的。    

用户的源码：   

```cpp
#include <iostream>

int main() {
  	auto x = [](int a, int b) { return a + b; };
  	int a = x(10, 20);
    return 0;
}
```

<br/>

cpp insights 翻译的源码：  

```cpp
#include <iostream>

int main()
{
    
  class __lambda_4_13
  {
    public: 
    inline /*constexpr */ int operator()(int a, int b) const
    {
      return a + b;
    }
    
    using retType_4_13 = int (*)(int, int);
    inline constexpr operator retType_4_13 () const noexcept
    {
      return __invoke;
    };
    
    private: 
    static inline /*constexpr */ int __invoke(int a, int b)
    {
      return __lambda_4_13{}.operator()(a, b);
    }
    
    
    public:
    // /*constexpr */ __lambda_4_13() = default;
    
  };
  
  __lambda_4_13 x = __lambda_4_13{};
  int a = x.operator()(10, 20);
  return 0;
}
```


---

# 2. 查看汇编代码

---

## 2.1 使用 compiler explorer 在线查看

compiler explorer 是一个网站，地址是： https://gcc.godbolt.org/ 。它的功能非常非常强大:   

* 支持各种编译器： gcc, clang, msvc ... 并且编译器还可选不同平台或架构的：x86-64, arm, powerpc, sparc, s390x, vax ...   
* 支持汇编选项，比如指定 c++20 版本，只要在编译选项加上 `-std=c++20` 即可
* 支持分享代码片段，可以生成一条短链接，比如我写的 hello world 代码： https://gcc.godbolt.org/z/87xT8scqn  
* 除了 c++，还支持另外几十种语言，比如 c, c#, python, golang, java, erlang 等等，要么生成汇编代码，要么生成字节码   

<br/>

c++ 的 hello world，代码链接： https://gcc.godbolt.org/z/87xT8scqn 。    

![compiler-explorer-cpp-helloworld](https://blog.antsmallant.top/media/blog/modern-cpp/compiler-explorer-cpp-helloworld.png)   
<center>图1：compiler explorer c++ hello world</center>

python 的 hello world，代码链接：https://gcc.godbolt.org/z/8jM3d37dE 。  

![compiler-explorer-python3-helloworld](https://blog.antsmallant.top/media/blog/modern-cpp/compiler-explorer-python3-helloworld.png)   
<center>图2：compiler explorer python hello world</center>

<br/>

遗憾的是，compiler explorer 不支持 lua。不过，这个网站【lua Bytecode Explorer】支持，地址是：https://www.luac.nl/ 。功能很强大，支持从 lua4.0 到 lua5.4 的各个版本。  

![luac-lua-helloworld](https://blog.antsmallant.top/media/blog/modern-cpp/luac-lua-helloworld.png)   
<center>图3：luac lua hello world</center>


---

## 2.2 使用 gcc 生成汇编代码

使用 `gcc -S` 编译成汇编代码，然后再用 c++filt demangling 里面那些被 mangling 的 c++ 符号。    

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

<br/>

读起来有点费劲，因为它把我们的函数名都 mangling 了，比如 C0::c0f1 被编成这样了：_ZN2C04c0f1Ev，为了好看一些，需要 demangling，可以使用 c++filt 这个工具来做。它有两种用法，都是一样的效果。  

c++filt 用法一：   
（要注意，不要有空格！）

```bash
c++filt<abc.s>abc_demangle.s
```

c++filt 用法二：   

```bash
cat abc.s | c++filt > abc_demangle.s
```

<br/>

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

# 3. 看懂汇编代码

大学的时候多少都学一点汇编，但估计都忘得差不多了。要重拾汇编，可以看一下《深入理解计算机系统（原书第3版）》[1] 的第 3 章：程序的机器级表示，写得非常好。    

虽然要看懂汇编，系统的看一看上面说的书就够了。但我还是有几个心得可以分享一下。   

---

## 3.1 看 ATT 风格的汇编，不要看 intel 风格的

因为 intel 风格的可读性不强。ATT 即 AT&T，gcc、objdump 和其他的一些工具，生成的汇编都是 ATT 风格，intel 风格的多见于 intel 和微软。如果想让 gcc 生成 intel 风格的汇编，可以这样：`gcc -Og -S -masm=intel 源文件名` 。    

ATT 和 intel 的区别是[1]： 

* intel 省略了指示大小的后缀，ATT 中的 pushq 和 movq，在 intel 中是 push 和 mov。
* intel 省略了寄存器名字前面的 '%' 符号，用的是 rbx，而不是 %rbx。  
* intel 用不同的方式描述内存中的变量，例如：`QWORD PTR [rbx]` 而不是 `(%rbx)`
* 在带有多个操作数的指令情况下，列出操作数的顺序相反，比如 ATT 中 `moveq %rbx, %rax`，在 intel 是写成 `mov rax, rbx`


## 3.2 牢记寄存器用途

x86-64 架构共有用于参数传递的 16 个寄存器，用途大致如下：   

* 用于参数传递的 6 个：%rdi, %rsi, %rdx, %rcx, %r8, %r9
* 用于返回值的 1 个：%rax
* 栈指针 1 个：%rsp
* 调用者负责保存的 2 个：%r10, %r11
* 被调用者负责保存的 6 个：%rbx, %rbp, %r12, %r13, %r14, %r15

具体如下： 
（数字 64、32、16、8 表示位数）

|64|32|16|8|作用|
|--|--|--|--|--|
|`%rax`|`%eax`|`%ax`|`%al`|返回值|
|`%rbx`|`%ebx`|`%bx`|`%bl`|被调用者保存|
|`%rcx`|`%ecx`|`%cx`|`%cl`|第四个参数|
|`%rdx`|`%edx`|`%dx`|`%dl`|第三个参数|
|`%rsi`|`%esi`|`%si`|`%sil`|第二个参数|
|`%rdi`|`%edi`|`%di`|`%dil`|第一个参数|
|`%rbp`|`%ebp`|`%bp`|`%bpl`|被调用者保存|
|`%rsp`|`%esp`|`%sp`|`%spl`|栈指针|
|`%r8`|`%r8d`|`%r8w`|`%r8b`|第五个参数|
|`%r9`|`%r9d`|`%r9w`|`%r9b`|第六个参数|
|`%r10`|`%r10d`|`%r10w`|`%r10b`|调用者保存|
|`%r11`|`%r11d`|`%r11w`|`%r11b`|调用者保存|
|`%r12`|`%r12d`|`%r12w`|`%r12b`|被调用者保存|
|`%r13`|`%r13d`|`%r13w`|`%r13b`|被调用者保存|
|`%r14`|`%r14d`|`%r14w`|`%r14b`|被调用者保存|
|`%r15`|`%r15d`|`%r15w`|`%r15b`|被调用者保存|


## 3.3 牢记栈帧结构

TODO linux 的栈大小，以及 leet 计算栈是否会溢出。  

下图参照自《深入理解计算机系统》[1]。  

![stack-frame](https://blog.antsmallant.top/media/blog/modern-cpp/stack-frame.png)   
<center>图4：stack frame</center>


## 3.4 一些常见做法


---

# 4. 参考

[1] [美]Randal E. Bryant, David R. O'Hallaron. 深入理解计算机系统(原书第3版). 龚奕利, 贺莲. 北京: 机械工业出版社, 2022-6(1): 164.   

[2] cppinsights. About. https://cppinsights.io/about.html.   