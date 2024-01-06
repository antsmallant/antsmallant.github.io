---
layout: post
title:  "c++ 对象内存模型探究"
date:   2022-11-13
last_modified_at: 2022-11-13
categories: [c++]
tags: [performance, c++]
---

* 目录  
{:toc}
<br/>

## 查看汇编代码
* 方法一  
这个网站 [compiler explorer](https://gcc.godbolt.org/) 可以方便的展示源代码与汇编代码的对应关系，特别方便，比自己用 `gcc -S <文件名>` 来生成汇编代码看更方便很多，当然也比 `objdump -d <binary文件名>` 更方便。    

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

作为对比，abc.s 一般是这样的：    
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

而 abc_demangle.s 是这样的：    
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