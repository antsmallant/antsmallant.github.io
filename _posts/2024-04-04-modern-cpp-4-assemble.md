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

本文记录一下 c++ 如何查看生成出来的汇编代码，以及如何看懂代码，部分内容参考自《深入理解计算机系统》[1]。  

---

# 1. 先不看汇编

汇编的可读性挺差的，如果有得选，还是先用 cpp insights，看一看编译器角度生成的源码。cpp insights 的地址是 https://cppinsights.io/ ，官网对它的介绍[2]：  

>C++ Insights is a clang-based tool which does a source to source transformation. Its goal is to make things visible, which normally and intentionally happen behind the scenes. It's about the magic the compiler does for us to make things work.   

翻译过来就是：c++ insights 是一个基于 clang 的工具，用于执行源码到源码的转换。它的目标是让幕后的事情变得可见。关于编译器为了使事情正常工作所做的魔术。   

直接看一下它能帮你洞察什么。 

<br/>

<center>

![cpp-insights-cpp-lambda](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/modern-cpp-cpp-insights-cpp-lambda.png)      
图1：cpp-insights-cpp-lambda

</center>

<br/>

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

<br/>

<center>

![compiler-explorer-cpp-helloworld](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/modern-cpp-compiler-explorer-cpp-helloworld.png)      
图2：compiler explorer c++ hello world

</center>

<br/>

python 的 hello world，代码链接：https://gcc.godbolt.org/z/8jM3d37dE 。  

<br/>

<center>

![compiler-explorer-python3-helloworld](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/modern-cpp-compiler-explorer-python3-helloworld.png)    
图3：compiler explorer python hello world

</center>

<br/>

遗憾的是，compiler explorer 不支持 lua。不过，这个网站【lua Bytecode Explorer】支持，地址是：https://www.luac.nl/ 。功能很强大，支持从 lua4.0 到 lua5.4 的各个版本。并且，它也支持分享代码片段，在页面底下有个 "generate link" 的按钮，比较不显眼。    

<br/>

<center>

![luac-lua-helloworld](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/modern-cpp-luac-lua-helloworld.png)     
图4：luac lua hello world

</center>

<br/>

---

## 2.2 使用 g++ 生成汇编代码

使用 `g++ -S` 编译成汇编代码，然后再用 c++filt demangling 里面那些被 mangling 的 c++ 符号。    

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

```nasm
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
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	leaq	.LC0(%rip), %rax
	movq	%rax, %rsi
	leaq	_ZSt4cout(%rip), %rax
	movq	%rax, %rdi
	call	_ZStlsISt11char_traitsIcEERSt13basic_ostreamIcT_ES5_PKc@PLT
	movq	_ZSt4endlIcSt11char_traitsIcEERSt13basic_ostreamIT_T0_ES6_@GOTPCREL(%rip), %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	_ZNSolsEPFRSoS_E@PLT
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1731:
	.size	_ZN2C04c0f1Ev, .-_ZN2C04c0f1Ev
	.section	.rodata
.LC1:
	.string	"c0 c0f2"
	.section	.text._ZN2C04c0f2Ev,"axG",@progbits,_ZN2C04c0f2Ev,comdat
	.align 2
	.weak	_ZN2C04c0f2Ev
	.type	_ZN2C04c0f2Ev, @function


; 以下省略 ...

```

<br/>

读起来有点费劲，因为它把我们的函数名都 mangling 了，比如 `C0::c0f1` 被编成这样了：`_ZN2C04c0f1Ev` 。   

为了好看一些，需要 demangling，可以使用 c++filt 这个工具来做，它有两种用法，都是一样的效果。  

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

c++filt 转换过后的汇编代码 abc_demangle.s 是这样的：    

```nasm
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
	.cfi_offset 6, -16
	movq	%rsp, %rbp
	.cfi_def_cfa_register 6
	subq	$16, %rsp
	movq	%rdi, -8(%rbp)
	leaq	.LC0(%rip), %rax
	movq	%rax, %rsi
	leaq	std::cout(%rip), %rax
	movq	%rax, %rdi
	call	std::basic_ostream<char, std::char_traits<char> >& std::operator<< <std::char_traits<char> >(std::basic_ostream<char, std::char_traits<char> >&, char const*)@PLT
	movq	std::basic_ostream<char, std::char_traits<char> >& std::endl<char, std::char_traits<char> >(std::basic_ostream<char, std::char_traits<char> >&)@GOTPCREL(%rip), %rdx
	movq	%rdx, %rsi
	movq	%rax, %rdi
	call	std::basic_ostream<char, std::char_traits<char> >::operator<<(std::basic_ostream<char, std::char_traits<char> >& (*)(std::basic_ostream<char, std::char_traits<char> >&))@PLT
	nop
	leave
	.cfi_def_cfa 7, 8
	ret
	.cfi_endproc
.LFE1731:
	.size	C0::c0f1(), .-C0::c0f1()
	.section	.rodata
.LC1:
	.string	"c0 c0f2"
	.section	.text._ZN2C04c0f2Ev,"axG",@progbits,C0::c0f2(),comdat
	.align 2
	.weak	C0::c0f2()
	.type	C0::c0f2(), @function


; 以下省略 ...

```

---

# 3. 看懂汇编代码

大学的时候多少都学一点汇编，但估计都忘得差不多了。要重拾汇编，可以看一下《深入理解计算机系统（原书第3版）》[1] 的第 3 章：程序的机器级表示，写得非常好。    

以下是一些我觉得比较重要的东西。    

---

## 3.1 看 ATT 风格的汇编，不要看 intel 风格的

因为 intel 风格的可读性不强。ATT 即 AT&T，gcc、objdump 和其他的一些工具，生成的汇编都是 ATT 风格，intel 风格的多见于 intel 和微软。如果想让 gcc 生成 intel 风格的汇编，可以这样：`gcc -Og -S -masm=intel 源文件名` 。    

ATT 和 intel 的区别是[1]： 

* intel 省略了指示大小的后缀，ATT 中的 pushq 和 movq，在 intel 中是 push 和 mov。
* intel 省略了寄存器名字前面的 '%' 符号，用的是 rbx，而不是 %rbx。  
* intel 用不同的方式描述内存中的变量，例如：`QWORD PTR [rbx]` 而不是 `(%rbx)`
* 在带有多个操作数的指令情况下，列出操作数的顺序相反，比如 ATT 中 `moveq %rbx, %rax`，在 intel 是写成 `mov rax, rbx`

---

## 3.2 牢记通用目的寄存器用途

一个 x86-64 的 cpu 拥有一组 16 个存储 64 位值的【通用目的寄存器】，这些寄存器用来存储整数数据和指针[1]，用途大致如下：   

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

<br/>

除了上面讲的通用目的寄存器，x86-64 架构还有好几种寄存器，具体可以参考以下这几篇文章：   

* 《CPU_Registers_x86-64#Segment_Registers》：[https://wiki.osdev.org/CPU_Registers_x86-64#Segment_Registers](https://wiki.osdev.org/CPU_Registers_x86-64#Segment_Registers)

* 《how many registers does an x86-64 CPU have?》: [https://blog.yossarian.net/2020/11/30/How-many-registers-does-an-x86-64-cpu-have](https://blog.yossarian.net/2020/11/30/How-many-registers-does-an-x86-64-cpu-have)

* 《X86_64 机器上一共有多少个寄存器》: [https://www.owalle.com/2021/12/26/all-registers-x86-64/](https://www.owalle.com/2021/12/26/all-registers-x86-64/)
 

---

## 3.3 牢记栈帧结构

下图参照自《深入理解计算机系统》[1]。  

<br/>

<center>

![stack-frame](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/modern-cpp-stack-frame.png)     
图5：stack frame

</center>

<br/>

知道了栈帧的构造，那么就可以推算一下一次函数调用大概占用多少栈空间。一次函数调用，大致的栈消耗如下：    

* 被调用者保存的寄存器，有 6 个（%rbp，%rbx，%r12，%r13，%r14，%r15），共占 48 Bytes

* 调用者保存的寄存器，有 2 个（%r10，%r11），共占 16 Bytes

* 返回地址，占 8 Bytes

* 参数构造区，视具体情况而定，可以通过寄存器（%rdi，%rsi，%rdx，%rcx，%r8，%r9）传递 6 个的整型（整数或指针）参数，多数情况下寄存器已经足够传参了

* 局部变量，视具体情况而定

那么一个栈帧的大小就是 (48 + 16 + 8 + x) Bytes，即 (72 + x) Bytes，其中 x 代表参数构造和局部变量的可能占用。   

知道了单次调用的栈空间消耗，以及操作系统默认的单线程栈空间大小限制（以 linux 64 位版本为例，单条线程栈空间大小限制默认值是 8MB，可以通过 ulimit -a 查看 stack size 项），就可以推算出递归写法是否会 stack overflow，这个在刷题的时候还是很重要的。   

---

## 3.4 牢记操作数格式

以下图片取自《深入理解计算机系统》[1]。 

<br/>

<center>

![assemble-operand-format](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/modern-cpp-assemble-operand-format.png)     
图6：操作数格式

</center>

<br/>

---

## 3.5 一些常见概念

---

### 3.5.1 栈指针与帧指针

`%rsp` 通常用作栈指针，而 %rbp 通常用作帧指针，在函数一开始，通常是这样 `pushq %rbp ;  mov %rsp, %rbp; `，也就是先保存 `%rbp` 的值，再把 `%rsp` 保存到 `%rbp` 中，之后，`%rbp` 这个的值就不变了，而 `%rsp` 会一直变的，所以通过 `%rbp` 去访问参数是很方便的。  

---

### 3.5.2 leave 的作用

64 位下相当于：`movq %rbp, %rsp ; popq %rbp`， 是恢复栈帧的一种做法。通常在函数的开头是这样：`pushq %rbp ; mov %rsp, %rbp;`。即先把 `%rbp` 入栈，再用 `%rbp` 来保存 `%rsp` 的值。  

所以，恢复栈帧实际上就是恢复 `%rsp` 寄存器的值而已。  

还有另一种做法，比如一开始先分配 32 bytes 的栈帧，这么写： `subq $32, %rsp`，如果中间不修改 `%rsp`，那在最后 ret 之前可以直接把 `%rsp` 加回去：`addq $32, $rsp`，这样也是达到了恢复 `%rsp` 寄存器的目的。   

---

### 3.5.3 push / pop / call

push / pop / call 这几个命令都会自己改变 `%rsp` 的值。64位系统下，`pushq / call` 都会 `%rsp = %rsp - 8`，然后把 8 字节写入 `%rsp` 处，`popq` 正相反，会把 `%rsp` 的 8 字节取出，然后 `%rsp = %rsp+8`。  

call 指令更特殊一点，它的语法是这样：`call Label` 或者 `call *Operand`，无论哪个形式，实际上就 call 后面跟一个跳转地址。它会做两件事情：  
1、返回地址入栈： 把 call 指令之下的一条指令的地址写入 `$rsp - 8` 的位置，并把 $rsp 设置为 `$rsp-8`。  
2、改变程序程序计数器 `%rip`： 把寄存器 `$rip` 的值设置为跳转地址值。   

<br/>

说到 call，必须说说 ret。ret 做的事情更简单，把返回地址弹出来恢复 `$rip`，相当于只做类似这样的事情：  

```
movq ($rsp), %rip  ; 用 %rsp 这个位置存的值（即返回地址）恢复 %rip
addq $8, $rsp      ; 把返回地址从栈上弹出
```

要注意，恢复栈帧不是 ret 做的，是 leave 或其他自动生成的代码完成的。   

---

### 3.5.4 `%fs:40` 的作用

有时候用 gcc 生成出来的汇编代码里，在函数的开头有这样的代码：  

```nasm
	movq	%fs:40, %rax
	movq	%rax, -8(%rbp)
```

而在函数的结尾，有这样的代码：   

```nasm
	movq	-8(%rbp), %rax
	subq	%fs:40, %rax
	je	.L4
	call	__stack_chk_fail@PLT
```

它的作用是什么呢？ 

* 栈保护功能，将这个内存位置 `%fs:0x28` 存储的值写到栈底 `-8(%rbp)`，函数运行结束时，再把取出栈底 `-8(%rbp)` 保存的值和内存位置 `%fs:0x28` 的值作比较，如果有改变就说明栈被破坏了，调用函数 `__stack_chk_fail@plt` 来处理。   

* `fs` 是段寄存器之一。  

* 有时候 `%fs:40` 会显示成 `%fs:0x28`，其实是一样的，`0x28` 的十进制即是 40。   

* gcc 可以通过设置 `-fno-stack-protector` 选项来禁用编译器生成栈保护代码。  


可参考文章： 

* 《解读Linux安全机制之栈溢出保护》 ： [https://www.cnblogs.com/pengdonglin137/articles/17821763.html](https://www.cnblogs.com/pengdonglin137/articles/17821763.html)  

---

# 4. 参考

[1] [美]Randal E. Bryant, David R. O'Hallaron. 深入理解计算机系统(原书第3版). 龚奕利, 贺莲. 北京: 机械工业出版社, 2022-6(1): 119, 121, 164.   

[2] cppinsights. About. Available at https://cppinsights.io/about.html.   