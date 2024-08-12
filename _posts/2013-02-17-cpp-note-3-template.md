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

## 1.4 类模板的优先级

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

万能引用 (universal reference) 是 c++11 才引入的，现在又叫转发引用 (forwarding reference)。它的写法形式类似这样： 

```cpp
template<typename T>
SomeType f(T&& param);
``

跟右值引用的 `&&` 雷同了，虽然不是完全没关系，但为了好理解，应该把它当成两件事。  


https://zhuanlan.zhihu.com/p/99524127 

万能引用，即 Universal References。 

在 c++17 的标准里面已经将这种用法标准化为 “转发引用” (forwarding reference) 了。    

参考 [https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4164.pdf](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2014/n4164.pdf)。  

>In the absence of our giving this construct a distinct name, the community has been trying to make one. 
The one that is becoming popular is “universal reference.” [1] Unfortunately, as discussed in §3.1 below, 
this is not an ideal name, and we need to give better guidance to a suitable name.   
>    
>The name that has the most support in informal discussions among committee members, including the 
authors, is “forwarding reference.” Interestingly, Meyers himself initially introduced the term “forward
ing reference” in his original “Universal References” talk, [2] but decided to go with “universal references” 
because at the time he did not think that “forwarding references” reflected the fact that auto&& was also 
included; however, in §3.3 below we argue why auto&& is also a forwarding case and so is rightly included. 


---

# 2. 参考

[1] 五车书管. 函数模板的重载，偏特化，和全特化. Available at https://zhuanlan.zhihu.com/p/314340244, 2020-11-26.   