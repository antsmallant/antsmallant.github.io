---
layout: post
title: "c++ 笔记三：模板"
date: 2013-02-17
last_modified_at: 2023-04-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

记录 c++ 关于模板相关的要点。  

---

# 1. 模板

---

## 1.1 资料

《C++ Templates (第2版·英文版)》: [https://book.douban.com/subject/30226708/](https://book.douban.com/subject/30226708/)   

《c++ Templates 第2版的中文翻译》：[https://github.com/Walton1128/CPP-Templates-2nd--](https://github.com/Walton1128/CPP-Templates-2nd--)

---

## 1.2 模板特化 (template specialization)

或者叫模板特例化，是指为某个模板类或函数定义专门的实现，以处理特定类型参数的情况。  

特化的本质是实例化一个模板。   

<br/>

1、函数模板特化  

```cpp
#include <iostream>
using namespace std;

template<typename T>
void p(T t) {
    cout << "This is general type " << t << endl;
}

template<>
void p<int>(int i) {
    cout << "This is a int type " << i << endl;
}

int main() {
    p(10.0);
    p(20);
    return 0;
}
```

输出： 

```
This is general type 10
This is a int type 20
```

<br/>

2、类模板特化

写法与函数模板特化类似：    

```cpp
#include <iostream>
using namespace std;

template<typename T1, typename T2>
class A {
    T1 t1;
    T2 t2;
public:
    A(T1 _t1, T2 _t2) : t1(_t1), t2(_t2) { cout << "This is a normal template " << t1 << " " << t2 << endl; }
};

template<>
class A<int, int> {
    int t1;
    int t2;
public:
    A(int _t1, int _t2) : t1(_t1), t2(_t2) { cout << "This is a specialization template " << t1 << " " << t2 << endl; }
};

int main() {
    A<char, int> a('a', 10);
    A<int, int> b(1, 2);
    return 0;
}
```

输出： 

```
This is a normal template a 10
This is a specialization template 1 2
```

3、类模板只特例化成员

可以不特例化整个类，而特例化类中的某些成员，比如这样：  

```cpp
#include <iostream>
#include <string>
using namespace std;

template<typename T>
class A {
    T t;
public:
    A(T _t) : t(_t) {}
    void p() { cout << "normal version of p : " << t << endl; }
};

template<>
void A<int>::p() {
    cout << "int version of p : " << t << endl;
}

int main() {
    A<string> a("hello");
    a.p();

    A<double> b(1.23);
    b.p();

    A<int> c(100);
    c.p();

    return 0;
}
```

输出：  

```
normal version of p : hello
normal version of p : 1.23
int version of p : 100
```

只在模板参数为 `int` 的时候调用特别版本的函数 `p`。   

---

## 1.3 模板偏特化 (partial specialization)

模板偏特化是模板特化的一种特殊情况，也叫模板部分特化。是只对部分模板参数进行特化。  

<br/>

1、函数模板不支持偏特化   

c++ 暂时不支持函数模板的偏特化。[1]   

大部分情况下，可以用重载解决问题。  

比如这样：  

```cpp
template<typename T, typename U>
void f(T t, U u);

// 重载
template<typename T>
void f(T t, int a);
```

关于为什么函数模板没有偏特化的，可以参考：   

* Herb Sutter 的这篇文章：[Why Not Specialize Function Templates?](http://www.gotw.ca/publications/mill17.htm) [5]。   

* [为什么函数模板没有偏特化？](https://blog.csdn.net/feng__shuai/article/details/125426105)   


关于如何让函数模板支持类似偏特化的效果，可以参考：   

* [C++函数模板的偏特化](https://zhuanlan.zhihu.com/p/268600376)   

<br/>

2、类模板支持偏特化    

例子：    

```cpp
#include <iostream>
using namespace std;

template<typename T1, typename T2>
class A {
    T1 t1;
    T2 t2;
public:
    A(T1 _t1, T2 _t2) : t1(_t1), t2(_t2) { cout << "This is a normal template " << t1 << " " << t2 << endl; }
};

template<typename T2>
class A<int, T2> {
    int t1;
    T2 t2;
public:
    A(int _t1, T2 _t2) : t1(_t1), t2(_t2) { cout << "This is a partial template " << t1 << " " << t2 << endl; }
};

int main() {
    A<char, int> a('a', 10);
    A<int, int> b(1, 2);
    return 0;
}
```

输出：  

```
This is a normal template a 10
This is a partial template 1 2
```


---

## 1.4 模板的匹配优先级

1、函数模板的优先级

1）首先，如果有非模板函数，则首选非模板函数；
2）其次，从未特化的模板 (base templates) 中选定最合适的一个    
    2.1）如果这模板刚好有一个特别匹配的特化了的函数模板，则选它    
    2.2）否则，以相应的参数实例化这个函数模板   
3）找不到，报错    

这其中第 2 点是最关键，也最容易搞错的，Herb Sutter 举了个例子来说明问题[5]：

```cpp
template<class T>  // (a) 第一个 base template
void f( T );

template<>
void f<>(int *);   // (c) 模式 a 的全特化（full specialization 或 explicit specialization)

template<class T>  // (b) 第二个 base template，重载了 (a)
void f( T* );

// ...

int *p;
f ( p );           // 调用 (b)！因为重载决议会忽略特化版本，即（c），所以先在（a）和（b）中选择，此时（b）刚好符合
```

他的解释是，特化的版本不会参与重载决议，只有 base template (即未特化) 参与重载决议，所以首先是从 2 个 base template 中选择最合适的，即（b）。  

如果想要让你写的 “特化模板” 确保被使用，那就不要用模板，直接写一个非模板函数，它肯定会被确保首先使用。  

对此，他给出了两个建议[5]：  

1）不要写模板的特化版本，写一个非模板函数，即普通函数。   
2）把函数包在 struct 里面，当成一个 static 函数，可以利用类的特化或偏特化能力，绕开函数模板的重载决议问题。  


<br/>

2、类模板的优先级

全特化版本 > 偏特化版本 > 正常版本

---

## 1.5 typename 与 class 关键字的区别

1、作为模板参数时，二者的含义是相当的。  

`template<typename T>` 与 `template<class T>` 是等价的。   

2、typename 的额外用途  

用于声明它后面的一串字符串是类型，而不是其他的。  

比如这样： 

```cpp
#include <iostream>
using namespace std;

class A {
    typedef int LType;
public:
    A() {
        A::LType a = 100;
        cout << a << endl;
    }
};

int main() {
    A();
    return 0;
}
```

像上面的代码，可能在有些编译器编译得过，有些编译不过。`A::LType` 是有歧义的，它可以指代 A 的下属类型，也可以指代 A 的静态变量。如果我们要明确的告诉编译器，`A::LType` 是一个类型，就需要这样写： `typename A::LType a = 100;`。  

类似的，经常在一些库里面看到函数的入参前加了 `typename` 关键字，它的作用就是表面后面跟着的是类型，而不是其他的。   

另外，还有这样的写法：`typedef typename vector<T>::size_type size_type;`，这里的含义就是 `typedef` 定义了一个名为 `size_type` 的别名，它指代 `typename vector<T>::size_type`。`typename` 的作用就是声明 `vector<T>::size_type` 是类型，而不是其他的。  

---

## 1.6 万能引用与完美转发

---

### 1.6.1 万能引用

万能引用 (universal reference) 是 c++11 才引入的，在 c++17 的标准里面已经将这种用法标准化为 “转发引用” (forwarding reference) [3]，引用如下：    

>In the absence of our giving this construct a distinct name, the community has been trying to make one. 
The one that is becoming popular is “universal reference.” Unfortunately, as discussed in §3.1 below, 
this is not an ideal name, and we need to give better guidance to a suitable name.   
>    
>The name that has the most support in informal discussions among committee members, including the 
authors, is “forwarding reference.” Interestingly, Meyers himself initially introduced the term “forward
ing reference” in his original “Universal References” talk, but decided to go with “universal references” 
because at the time he did not think that “forwarding references” reflected the fact that auto&& was also 
included; however, in §3.3 below we argue why auto&& is also a forwarding case and so is rightly included.   

<br/>

万能引用是一种特别的引用，它能够保留函数参数的 value category，使得可以通过 `std::forward` 转发函数参数的 value category[2]。不要以为 `&&` 只用于右值引用，它也被用于表示万能引用，理解这一点很关键，不然会被搞得很糊涂。   

万能引用目前有两种场景：       

* 场景一：作为函数模板的形参    

精确的定义是：“function parameter of a function template declared as rvalue reference to cv-unqualified type template parameter of that same function template”[2]。  

示例[2]：  

```cpp
template<class T>
int f(T&& x) {                     // x 是万能引用
    return g(std::forward<T>(x));  // 可以被转发
}

int main() {
    int i;
    f(i);    // 参数是左值，调用 f<int&>(int&)，std::forward<int&>(x) 是左值
    f(0);    // 参数是右值，调用 f<int>(int&&)，std::forward<int>(x) 是右值
}

template<class T>
int g(const T&& x);  // x 不是万能引用，因为 const T 不是 cv-unqualified（即无 const/volatile 修饰）的

template<class T>
struct A {
    template<class U>
    A(T&& x, U&& y, int* p);  // x 不是万能引用，因为 T 不是构造函数的模板参数
                              // y 是万能引用
}
```

万能引用的两个判断标准： 
1）必须是类型推导；   
2）形式上必须是 T&&； 

像这样就不是类型推导[4]:   

```cpp
void f(Widget&& param);
```

像这样就是严格的 `T&&` 形式[4]：   

```cpp
template<class T>
void f(std::vector<T>&& param); // param 不是万能引用，是右值引用
```

<br/>

* 场景二：`auto&&`     

`auto&&` 除了花括号初始化的情况之外都是万能引用。 

示例[2]：  

```cpp
auto && vec = foo();      // vec 是万能引用，foo() 可能是左值或右值
auto i = std::begin(vec); // 正常工作，无论 vec 最终是左值引用或是右值引用
(*i)++;                   // 正常工作，无论 vec 最终是左值引用或是右值引用

g(std::forward<decltype(vec)>(vec)); // 转发（保留了 vec 的值类别）

for (auto&& x : f()) {
    // x 是万能引用，这是使用 for range 遍历的通用形式
}

auto&& z = {1, 2, 3}; // 不是万能引用，这是初始值列表的特殊情况
```

<br/> 

**拓展阅读**   

* [《Universal References in C++11 -- Scott Meyers》](https://isocpp.org/blog/2012/11/universal-references-in-c11-scott-meyers)   
  
* [《C++中的万能引用和完美转发》](https://theonegis.github.io/cxx/C-%E4%B8%AD%E7%9A%84%E4%B8%87%E8%83%BD%E5%BC%95%E7%94%A8%E5%92%8C%E5%AE%8C%E7%BE%8E%E8%BD%AC%E5%8F%91/)   

---

### 1.6.2 完美转发 

完美转发是为了帮助撰写接受任意实参的函数模板，并将其转发到其他函数，目标函数会接受到与转发函数所接受的完全相同的实参[4]。也就是说，它能够转发形参的 value category。  

value category 是一个一直存在的概念，任何一个变量都有两大属性：1）basic type ；2）value category。 value category 经过 c++11 规范后，包括左值、右值、将亡值、纯右值、广义左值这些概念。   

实现完美转发依赖于函数 `std::forward`，它的工作逻辑是这样的：如果入参的 value category 是右值，它就强制转换为右值引用并返回，否则，它不做转换。  

理解这一点的前提是要知道，形参总是左值，只不过它的类型是右值引用。比如这样：   

```cpp
template<typename T>
void f(T&& t) {
    g(t);  // 此时调用的是 g(T& t) 版本; 因为 t 作为形参，它本身就是个左值。  
}

void g(T& t) {
    std::cout << "g 左值引用版本" << std::endl;
}

void g(T&& t) {
    std::cout << "g 右值引用版本" << std::endl;
}
```

要能够调用 `g(T&& t)`，需要这样：  

```cpp
template<typename T>
void f(T&& t) {
    g(std::forward(t));   // std::forward 转发了 t 的 value category，如果 t 确实是一个右值
}
```

`std::forward` 与 `std::move` 的行为很像，都是将表达式强制转换为右值引用。但前者是有条件的，只会把原本是右值引用的表达式强制转换为右值引用，而后者是无条件的。  

---

### 1.6.3 引用折叠

其实引用折叠才是最关键的，不知道或不理解引用折叠，永远无法理解 `std::forward` 是怎么工作的。   

实参在传递给函数模板的时候，如果形参是万能引用，那么在推导的时候，就会把实参是左值还是右值的信息编码到推导出来的模板形参中。  

编码的机制也很简单，如果实参是左值，则推导结果是左值引用类型；如果实参是右值，则推导结果是非引用类型。[4]      

比如对于这种形式：  

```cpp
template<class T>
inf f(T&& x) {
    return g(std::forward<T>(x));
}

int i = 10;
f(i);  
```

执行 `f(i)` 的时候，`i` 对应的形参 `x` 是一个万能引用，那么就需要把 `i` 是左值的信息编码到推导出来的 `x` 的推导结果中。此时，T 的推导结果是 `int&`，产生的模板实例是： `f<int&>(int& && x);`。   

但这种 "reference-to-reference" （引用的引用） 有意义吗？ `int& && x` 是合法的存在吗？  

c++ 是禁止这么使用的，不允许用户这么写，但却允许编译器在特定的场合产生这种 “引用的引用”，模板实例化就是这种场合之一。  

c++11 引入了对于 reference-to-reference 的处理，在模板实例化的时候，进行 "reference collasping"（引用折叠）。对 `int& && x` 进行处理后的结果是 `int& x`，即消除掉了 `&&`。   

实际上，左值与右值组合起来共用4种，`& &&`、`& &`、`&& &&`、`&& &`，上面是属于 `& &&`。引用折叠的规则是这样的，只有 `&& &&` 是折叠成 `&&` 的，其他三种都是折叠成 `&`。举例：  

`int& && x`  折叠成 `int & x`；    
`int& & x`   折叠成 `int & x`；   
`int&& & x`  折叠成 `int & x`；   
`int&& && x` 折叠成 `int && x`；      

引用折叠发生的四种情形[4]：模板实例化；auto 类型生成；创建和运用 `typedef` 和别名声明；`decltype`。    

关于 `auto&&` 的类型推导与引用折叠，举例如下[4]：  

```cpp

Widget getWidget();
Widget w;

auto&& w1 = w;    // w1 的类型是 Widget& 。由于 w 是左值，此时 auto 被推导为 Widget&，
                  // 代入得 Widget& && w1 = w;，引用折叠后是 Widget& w1 = w 。

auto&& w2 = getWidget(); // w2 的类型是 Widget&& 。由于 getWidget() 返回了右值，此时 auto 被推导为 Widget，
                         // 代入得 Widget&& w2 = w，不需要引用折叠。  
```

<br/>

**拓展阅读**  

* 《modern effective c++》[4] 的条款 28，此书有纸质版，也有网友翻译的版本，见：[条款二十八：理解引用折叠](https://github.com/CnTransGroup/EffectiveModernCppChinese/blob/master/src/5.RRefMovSemPerfForw/item28.md) 。    

---

# 2. 参考

[1] 五车书管. 函数模板的重载，偏特化，和全特化. Available at https://zhuanlan.zhihu.com/p/314340244, 2020-11-26.   

[2] cppreference. Forwarding references. Available at https://en.cppreference.com/w/cpp/language/reference#Forwarding_references.   

[3] open-std. Forwarding References. https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4164.pdf.   

[4] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4.  

[5] Herb Sutter. Why Not Specialize Function Templates. Available at http://www.gotw.ca/publications/mill17.htm, 2001-7.   