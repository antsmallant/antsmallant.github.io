---
layout: post
title: "现代 c++ 二：一些概念和机制"
date: 2024-04-02
last_modified_at: 2024-04-02
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

可能有多年 c++ 编程经验，但回过头来发现，对一些基础概念却并不怎么熟悉，比如表达式、语句这些。有些概念，可能自以为知道，当要用文字把它表达出来的时候，又发现掌握得似乎不是很牢固。有些概念，大家都知道，唯独自己不知道，很尴尬。  

这只是一篇总结性的文章，涉及一些最 basic 的常识，如有错误，请指出，谢谢。   

---

# 1. 概念

要精确的掌握 c++ 的概念，可以看以下材料：   

* specification，比如 cppreference：[https://en.cppreference.com/w/](https://en.cppreference.com/w/) 。   

* c++ 标准委员会最接近标准的 working draft: [https://www.open-std.org/jtc1/sc22/wg21/docs/standards](https://www.open-std.org/jtc1/sc22/wg21/docs/standards) 。       

* 一些权威的书，比如《c++之旅》，《Effective Modern C++》。     

---

## 1.1 表达式 (expression)

表达式是运算符和它们的操作数的序列，它指定一项计算。[1]   

---

## 1.2 语句 (statement)

C++语言中的大多数语句都以分号结束，一个表达式，比如 ival + 5，末尾加上分号就变成了表达式语句（expression statement）。表达式语句的作用是执行表达式并丢弃掉求值结果。[2]   

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

## 1.3 容易搞错的赋值表达式

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

## 1.4 定义时初始化 vs 赋值

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

## 1.5 函数 (function)

函数是一个**命名了的代码块**，我们通过调用函数执行相应的代码。函数可以有 0 个或多个参数，而且（通常）会产生一个结果。可以重载函数，也就是说，同一个名字可以对应几个不同的函数。[2]     

---

## 1.6 无参数构造函数

假设一个类 A，它的构造函数是无参数的，那么要这样写来定义一个实例：`A a;`，不能写成这样：`A a();`，因为后者会被编译器当成是函数声明。   

---

## 1.7 实参与形参

例子：

```cpp
int a = 100;     
void f(int b);   // b 是形参
f(a);            // a 是实参
```

---

## 1.8 pointer to member

类成员变量指针或类成员函数指针。   

以下例子参考自： [https://en.cppreference.com/w/cpp/language/operator_member_access#Built-in_pointer-to-member_access_operators](https://en.cppreference.com/w/cpp/language/operator_member_access#Built-in_pointer-to-member_access_operators)     

```cpp
#include <iostream>
 
struct S
{
    S(int n) : mi(n) {}
    mutable int mi;
    int f(int n) { return mi + n; }
};
 
struct D : public S
{
    D(int n) : S(n) {}
};
 
int main()
{
    int S::* pmi = &S::mi;
    int (S::* pf)(int) = &S::f;
 
    const S s(7);
//  s.*pmi = 10; // error: cannot modify through mutable
    std::cout << s.*pmi << '\n';
 
    D d(7); // base pointers work with derived object
    D* pd = &d;
    std::cout << (d.*pf)(7) << ' '
              << (pd->*pf)(8) << '\n';
}
```

`int S::* pmi = &S::mi;`，pmi 就是一个指向类成员变量 mi 的指针，`s.*pmi` 就相当于 `s.mi`。    
`int (S::* pf)(int) = &S::f;`，pf 就是一个指向类成员函数 f 的指针，`d.*pf` 就相当于 `d.f`。    

尽管可以这样用，但存在的意义是什么？很少看到这方面的使用。直到在 stackoverflow 看到这个 answer：[What is a pointer to class data member "::*" and what is its use?](https://stackoverflow.com/a/4078006/8530163)。  

作者举了一个例子，假设一个结构体里面有好几个数值类型的变量，可以写一个函数，任意对这里面的成员变量取平均数。  

**版本一**    

```cpp
struct Sample {
    time_t time;
    double value1;
    double value2;
    double value3;
};

std::vector<Sample> samples;
//... fill the vector ...

double Mean(std::vector<Sample>::const_iterator begin, 
    std::vector<Sample>::const_iterator end,
    double Sample::* var)
{
    float mean = 0;
    int samples = 0;
    for(; begin != end; begin++) {
        const Sample& s = *begin;
        mean += s.*var;
        samples++;
    }
    mean /= samples;
    return mean;
}

//...
double mean = Mean(samples.begin(), samples.end(), &Sample::value2);
```

这个 Mean 函数支持传入任意一个成员变量的指针，求得一组这样的成员变量的平均数。比如上面对 samples 数组里面的所有对象的 value2 字段取平均数。也可以求 value1，value3 取平均数，只要传入它们的指针即可。  

但这么写有个局限，就是无法对 `time` 这个变量取平均数，因为它不是 double 类型的。所以，老哥又写了另一个版本，通过模板支持任意数值类型的。  

<br/>

**版本二**   

注：下面我做了点小修改，以表示可以支持任意数值类型。  

```cpp
template<typename Titer, typename S>
S mean(Titer begin, const Titer& end, S std::iterator_traits<Titer>::value_type::* var) {
    using T = typename std::iterator_traits<Titer>::value_type;
    S sum = 0;
    size_t samples = 0;
    for( ; begin != end ; ++begin ) {
        const T& s = *begin;
        sum += s.*var;
        samples++;
    }
    return sum / samples;
}

struct Sample {
    double x;
    int y;
};

std::vector<Sample> samples { {1.0, 100}, {2.0, 200}, {3.0, 300} };
double m1 = mean(samples.begin(), samples.end(), &Sample::x);  
double m2 = mean(samples.begin(), samples.end(), &Sample::y);
```

无论是 int 类型，还是 double 类型的成员变量，都支持传参进去求平均数了。  


---

# 2. 机制

## 2.1 RAII 与异常

RAII 即 Resource acquisition is initialization，资源获取即初始化。它是利用局部对象自动销毁的特性来控制资源的生命期，即分配在栈上的类对象，在栈空间被回收的时候，这些类对象的析构函数会被自动调用。  

但是如果发生了异常怎么办？RAII 机制会否失效？  

这个要取决于异常是否被捕捉，如果异常直接导致整个程序 abort 了，那么栈空间也无所谓回收了，自然就不会调用析构函数。如果捕捉了异常，程序不会 abort，那么栈空间可以保证被回收，此时分配在上面的类对象都会被调用析构。  

所以，只要程序不死，RAII 总是有效的。  

---

## 2.2 各种 cast


---

## 2.3 漂泊不定的 const


---

# 3. 术语

---

## 3.1 FCD

FCD 是 Final Committee Draft 的缩写，即最终委员会草案，它是草案（draft）的一个阶段（ Document stage ）。

比如 C++0x Final Committee Draft :  https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2010/n3093.pdf 。  

C++0x 是 C++11 标准正为正式标准前的草案临时名字。   

经常出现的是 CD (Committee Draft)，即委员会草案。  

---

## 3.2 DR

Defect Report 的缩写，即缺陷报告。   

---

# 4. 参考
[1] cppreference. 表达式. Available at https://zh.cppreference.com/w/cpp/language/expressions.  

[2] [美] Stanley B. Lippman, Josée Lajoie, Barbara E. Moo. C++ Primer 中文版（第 5 版）. 王刚, 杨巨峰. 北京: 电子工业出版社, 2013-9: 120, 154, 182.   
