---
layout: post
title: "现代 c++ 二：若干重要概念"
date: 2024-04-02
last_modified_at: 2024-04-02
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

可能有多年 c++ 编程经验，但回过头来发现，对一些基础概念却并不怎么熟悉，比如表达式、语句这些。   

要精确的掌握 c++ 的概念：  

* 最好直接看 specification，比如 cppreference：[https://en.cppreference.com/w/](https://en.cppreference.com/w/) ；    

* 其次是 c++ 标准委员会最接近标准的 working draft: [https://www.open-std.org/jtc1/sc22/wg21/docs/standards](https://www.open-std.org/jtc1/sc22/wg21/docs/standards) ；    

* 再次是看一些权威的书；        

最不推荐的是看博客文章。本文除外，笔者是比较认真的考究之后才写出来的，当然由于个人认知有限，出错在所难免，敬请指正。   

---

# 表达式 (expression)

表达式是由一个或多个运算对象（operand）组成，对表达式求值将得到一个结果。字面值和变量是最简单的表达式（expression），其结果就是字面值和变量的值。把一个运算符（operator）和一个或多个运算对象组合起来可以生成较复杂的表达式 (expression)。[1]   

---

# 语句 (statement)

C++语言中的大多数语句都以分号结束，一个表达式，比如 ival + 5，末尾加上分号就变成了表达式语句（expression statement）。表达式语句的作用是执行表达式并丢弃掉求值结果。[1]   

空语句是最简单的语句，空语句中只含有一个单独的分号：`;`。空语句的作用是，如果语法上需要一条语句但逻辑上不需要，此时应该使用空语句，比如：  

```cpp
while (cin >> s && s != sought)
    ;
```

复合语句（compound statement）是指用花括号括起来的（可能为空的）语句和声明的序列，复合语句也被称作块（block）。复合语句的作用是，如果在程序的某个地方，语法上需要一条件语句，但逻辑上需要多条语句，比如：  

```cpp
while (val <= 10) {
    sum += val;
    ++val;
}
```

注意：块不以分号作为结束。  

---

# 容易搞错的赋值表达式

* 什么是赋值表达式       

`int a = 100` 是赋值表达式吗？   
不是的，这是**定义时初始化**，赋值表达式不能以类型名开头，`a = 100` 这才是赋值表达式。   

* 赋值表达式的结果    

赋值表达式本身是有结果的，它的结果就是 = 号左侧的运算对象，是一个左值。比如 `a = 100`，它的结果就是 a，可以这样验证：   

```cpp
int a;
printf("%d\n", (a = 5));    // 输出 5
printf("0x%x\n", &a);       // 在我本机上输出 0x500d58
printf("0x%x\n", &(a=5));   // 在我本机上输出 0x500d58
```

* 赋值表达式的运算顺序   

右结合的，从右到左，所以这样的一个语句：`a = b = c = 5;`，会把 a、b、c 都赋值为 5，它相当于这样：`a = (b = (c = 5))`。     
先是 5 赋值给 c，然后 c = 5 的值是 5，5 赋值给 b，然后 b = 5 的值是 5，5 再赋给 a。    

---

# 定义时初始化 vs 赋值

上面讲赋值表达式的时候已经提及了，定义时初始化与赋值是不同的，不能混为一谈。这个很重要，因为不同场景调用的函数是不同的，定义时初始化调用的是拷贝构造函数，而赋值调用的是赋值运算符函数。    

```cpp
class Dt {
private:
    int a;
public:

    Dt() {a=100;}
    Dt(int v) {a = v;}
    Dt(const Dt& other) {cout << "copy constuct" << endl; this->a = other.a;}  // 拷贝构造函数
    Dt& operator = (const Dt& other) {cout << "operator = " << endl; this->a = other.a;} // 赋值运算符函数
};

int main() {
    Dt b(1);
    Dt c(2);
    Dt a = b;  // 定义时初始化，调用的是拷贝构造函数
    a = c;     // 赋值，调用的是赋值运算符函数，如果有重载则使用重载的，否则使用系统默认生成的（只会做浅拷贝）
    return 0;
}
```

如果我们没有显式的重载赋值运算符函数，那么编译器会生成一个默认的赋值运算符函数，而默认的只能完成浅拷贝，是比较危险的！   
 
---

# 函数 (function)

函数是一个**命名了的代码块**，我们通过调用函数执行相应的代码。函数可以有 0 个或多个参数，而且（通常）会产生一个结果。可以重载函数，也就是说，同一个名字可以对应几个不同的函数。[1]     

---

# 无参数构造函数

假设一个类 A，它的构造函数是无参数的，那么要这样写来定义一个实例：`A a;`，不能写成这样：`A a();`，因为后者会被编译器当成是函数声明。   

---

# 实参与形参

例子：

```cpp
int a = 100;     
void f(int b);   // b 是形参
f(a);            // a 是实参
```

---

# trivial

---

# non-trivail

---

# cv-qualified

---

# POD

---

# FCD

FCD 是 Final Committee Draft 的缩写，它是草案（draft）的一个阶段（ Document stage ）。

比如 C++0x Final Committee Draft :  https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2010/n3092.pdf 。  

C++0x 是 C++11 标准正为正式标准前的草案临时名字。   

---

# 参考

[1] [美] Stanley B. Lippman, Josée Lajoie, Barbara E. Moo. C++ Primer 中文版（第 5 版）. 王刚, 杨巨峰. 北京: 电子工业出版社, 2013-9: 120, 154, 182.   
