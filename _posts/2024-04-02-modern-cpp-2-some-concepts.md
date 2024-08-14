---
layout: post
title: "现代 c++ 二：概念、机制、用法"
date: 2024-04-02
last_modified_at: 2024-04-02
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

可能有多年 c++ 编程经验，但回过头来发现，对一些基础概念却并不怎么熟悉，比如表达式、语句这些。有些概念，可能自以为知道，当要用文字把它表达出来的时候，又发现掌握得似乎不是很牢固。   

这是一篇总结性的文章，涉及一些最 basic 的常识，如有错误，请指出，谢谢。   

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

    Dt() { a=100; }
    Dt(int v) { a = v; } 
    Dt(const Dt& other) { std::cout << "copy constuct" << std::endl; this->a = other.a;}  // 拷贝构造函数
    Dt& operator = (const Dt& other) { std::cout << "operator = " << std::endl; this->a = other.a;} // 赋值运算符函数
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

比如一个类 `S` 有个成员变量 `mi`，那么可以用一个指针把这个成员变量保存起来，之后用这个指针来指代这个成员变量。成员函数也是同理。  

```cpp
struct S {
    int a;
};

int S::* pa = &S::a;
S s;
std::cout << s.*pa;
```

完整例子参考自 cppreference ： [https://en.cppreference.com/w/cpp/language/operator_member_access#Built-in_pointer-to-member_access_operators](https://en.cppreference.com/w/cpp/language/operator_member_access#Built-in_pointer-to-member_access_operators)     

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

<br/>

尽管可以这样用，但存在的意义是什么？很少看到这方面的使用。直到在 stackoverflow 看到这个 answer ：[What is a pointer to class data member "::*" and what is its use?](https://stackoverflow.com/a/4078006/8530163)。  

作者举了一个例子，假设一个结构体里面有好几个数值类型的变量，那么可以写一个函数，任意对各个成员变量取平均数。  

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

---

## 2.1 RAII 与异常

RAII 即 Resource acquisition is initialization，资源获取即初始化。它是利用局部对象自动销毁的特性来控制资源的生命期，即分配在栈上的类对象，在栈空间被回收的时候，这些类对象的析构函数会被自动调用。  

**问题一：为什么析构函数会被自动调用？**     

答：编译器在编译的时候自动加进去的。  

举个例子，完整的 code 在此： [https://gcc.godbolt.org/z/6G9azzae6](https://gcc.godbolt.org/z/6G9azzae6)。   

像这样的代码：    
```cpp
struct S {
    S() {}
    ~S() {}
};
struct S1 {
    S1() {}
    ~S1() {}
};
void f() {
    S s;
    S1 s1;
}
```

在 x86-64 gcc 14.1，函数 f 会被编译成如下的汇编码，可以看到编译器自动插入了析构函数的调用代码。    

```nasm
f():
        pushq   %rbp
        movq    %rsp, %rbp
        subq    $16, %rsp
        leaq    -1(%rbp), %rax
        movq    %rax, %rdi
        call    S::S() [complete object constructor]
        leaq    -2(%rbp), %rax
        movq    %rax, %rdi
        call    S1::S1() [complete object constructor]
        leaq    -2(%rbp), %rax
        movq    %rax, %rdi
        call    S1::~S1() [complete object destructor]
        leaq    -1(%rbp), %rax
        movq    %rax, %rdi
        call    S::~S() [complete object destructor]
        leave
        ret
```

<br/>

**问题二：如果发生了异常怎么办？RAII 机制会否失效？**     

这个要取决于异常是否被捕捉，如果异常直接导致整个程序 abort 了，那么栈空间也无所谓回收了，自然就不会调用析构函数。如果捕捉了异常，程序不会 abort，那么栈空间可以保证被回收，此时分配在上面的类对象都会被调用析构。  

所以，只要程序不死，RAII 总是有效的。  

---

## 2.2 各种 cast

c-style cast 在 c++ 这里，按不同场景拆成了 static_cast、reinterpret_cast、const_cast。而 dynamic_cast 是 c++ 特有的，它用于多态类型（即包含虚函数的）从父类到子类的转换。  

|类型|作用|底层|操作对象|可移植|
|:--|:--|:--|:--|:--|
|static_cast|低风险的静态转换：1）相关类型的指针或引用转换；2）整型、浮点型、字符型的互相转换|可能改变内存数据|无限制|是|
|reinterpret_cast|高风险的静态转换：1）不相关的类型间的指针或引用的转换；2）指针与整型间的互转换|可能改变内存数据|无限制|否|
|dynamic_cast|安全的动态转换：多态类型的父转子情形|不改变内存数据，只改变对内存数据的解释|类类型的指针或引用|是|
|const_cast|移除表达式的 const 或 valatile 性质|不改变内存数据，只改变对内存数据的解释|指针或引用|是|

<br/>

cast 如果很全面的列举所有的情形，就很复杂了，这里只抓住主线逻辑，完整的可以参考 cppreference 上面的 specification：  

* static_cast: [cppreference-static_cast](https://en.cppreference.com/w/cpp/language/static_cast)    
* reinterpret_cast: [cppreference-reinterpret_cast](https://en.cppreference.com/w/cpp/language/reinterpret_cast)     
* dynamic_cast: [cppreference-dynamic_cast](https://en.cppreference.com/w/cpp/language/dynamic_cast)
* const_cast: [cppreference-const_cast](https://en.cppreference.com/w/cpp/language/const_cast)
* c-style cast：[cppreference-explicit_cast](https://en.cppreference.com/w/cpp/language/explicit_cast)

<br/>

**1、static_cast 与 reinterpret_cast**   

static_cast 主要用于一些 “低风险” 的转换，比如：  
1）整型与浮点型、字符型的转换，比如 `double` 转成 `int`，`int` 转成 `char`。  
2）相关类型的指针或引用的转换，相关指的是这些类在继承层次上是有关系的，比如 A 和 B 要有继承关系才能转换。    

reinterpret_cast 主要用于一些 “高风险” 的转换，比如：  
1）不同类型的指针或引用之间，比如可以把 `int*` 转换成 `string*`。  
2）指针与整型间，比如可以把 `string*` 转换成 `int`，也可以把 `int` 转换成 `string*`。      

注：reinterpret_cast 在指针与整型互转换时，要求整型能够容纳得下指针。  

<br/>

**2、dynamic_cast 与 static_cast**  

dynamic_cast 可以看成 static_cast 的补充，当把子类转换为父类 (up cast) 的时候，用 static_cast 或 dynamic_cast 都没问题，效果是一样的。  

但是父类转子类的时候就说不准了，一个父类可能有多个子，如果父实际上是子 A，但要转成子 B，显然是不行的。这也没法在编译时判断，因为运行时，父可以指向子 A，也可以指向子 B，这正是多态的意义。而 static_cast 的要义正是**静态**转换，只在编译期起作用，无法在运行时做判断。  

要解决问题，只能是新增一个能够在运行时判断的 cast，即 dynamic_cast。工作原理是利用虚表里面额外存储的类型信息（RTTI），这些类型信息被利用来在运行时进行判断。   

dynamic_cast 可以作用于指针或引用。当转换失败时，如果是指针，则返回空指针；如果是引用，则抛出 std::bad_cast 异常。   

<br/>

**3、几篇不错的参考**    

* [四种强制类型转换](https://github.com/YKitty/Notes/blob/master/notes/C++/%E5%9B%9B%E7%A7%8D%E5%BC%BA%E5%88%B6%E7%B1%BB%E5%9E%8B%E8%BD%AC%E6%8D%A2.md)
* [dynamic_cast背着你偷偷做了什么](https://blog.csdn.net/D_Guco/article/details/106033180)
* [(C++ 成长记录) —— C++强制类型转换运算符（static_cast、reinterpret_cast、const_cast和dynamic_cast）](https://zhuanlan.zhihu.com/p/368267441)

---

## 2.3 const

const 大意是指所指之物为常量，不可改变，如若改变，则编译会报错。  

1、const 作用于指针    

在 `*` 号左边表示被指之物为常量，在 `*` 号右边表示指针本身为常量。       

const 作用于 stl 的 iterator 时，`const std::vector<string>::iterator iter` 与 `std::vector<string>::const_iterator` 是不同的。  
前者相当于 `T * const iter；`，表示 iter 本身是常量，`*iter = xx;` 是 ok 的，而 `++iter;` 是错误的。    
后者相当于 `const T* iter;`，表示 iter 所指之物是常量，`*iter = xx;` 是错误的，而 `++iter;` 是 ok 的。    

2、const 放在类型前后   

比较 trick 的是，const 可以写在类型之前或之后，但这都无妨，认准 `*` 号这一边界即可。  

也就是说 `const int * p;` 与 `int const * p;` 是一样的， `const int i;` 与 `int const i;` 是一样的。  

特别的，可以在 `*` 号的左右可放一个 const，分别表示所指之物以及指针变量本身都是 const 的，比如这样 `int const * const pa = &a;`。  

3、const 作用于类成员函数   

表明此成员函数不会改变类成员的值。 此时 const 是放在成员函数参数的末尾，并且声明处跟定义处都要写上。    

```cpp
class S {
    int a;
public:
    void f() const;   // 声明处要写上 const
};

void S::f() const {   // 定义处也要写上 const
    std::cout << a << std::endl;
}
```

4、const 作用于函数返回值    

表明返回的是 const 类型。需要赋值给同样的 const 类型。   

```cpp
const char* f() {}

char* = f();       // not ok
const char* = f(); // ok
```

---

## 2.4 const reference   

**参考文章**   

* [c++中函数参数里，是否能用 const reference 的地方尽量都用？](https://www.zhihu.com/question/594059514/answer/2973611125)  

* [Back to the Basics! Essentials of Modern C++ Style - Herb Sutter - CppCon 2014.pdf](https://github.com/CppCon/CppCon2014/blob/master/Presentations/Back%20to%20the%20Basics!%20Essentials%20of%20Modern%20C%2B%2B%20Style/Back%20to%20the%20Basics!%20Essentials%20of%20Modern%20C%2B%2B%20Style%20-%20Herb%20Sutter%20-%20CppCon%202014.pdf)

---

# 3. 用法

---

## 3.1 以 by reference 方式捕捉 exceptions

这是 “旧书” 《More Effective C++》的条款13。  

catch by pointer 的方式容易发生两个问题：1、指向不复存在的对象；2、捕获者不确定是否需要 delete，容易内存泄漏。  

catch by value 的方式可能会发生切割，当抛出的是派生类，而用基类类型捕捉的时候，对象就被切割成基类了，调用虚函数的时候，也只是调用到基类的虚函数版本。  

---

## 3.2 当参数是不需要被改变的时候，就顺手打上 const  

可以避免偶尔把 `==` 误打成 `=` 的情况。  


---

# 4. 相关术语

---

## 4.1 FCD

FCD 是 Final Committee Draft 的缩写，即最终委员会草案，它是草案（draft）的一个阶段（ Document stage ）。   

比如 C++0x Final Committee Draft :  https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2010/n3094.pdf 。  

C++0x 是 C++11 标准正为正式标准前的草案临时名字。   

经常出现的是 CD (Committee Draft)，即委员会草案。  

---

## 4.2 DR

Defect Report 的缩写，即缺陷报告。   

---

# 5. 参考  

[1] cppreference. Expressions. Available at https://en.cppreference.com/w/cpp/language/expressions.   

[2] [美] Stanley B. Lippman, Josée Lajoie, Barbara E. Moo. C++ Primer 中文版（第 5 版）. 王刚, 杨巨峰. 北京: 电子工业出版社, 2013-9: 120, 144, 154, 182, 730.     

[3] [美]Scott Meyers. More Effective C++(中文版). 侯捷. 北京: 电子工业出版社, 2011-1: 68.    