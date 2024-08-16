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

template<typename T>
void p(T t) {
    std::cout << "This is general type " << t << std::endl;
}

template<>
void p<int>(int i) {
    std::cout << "This is a int type " << i << std::endl;
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

template<typename T1, typename T2>
class A {
    T1 t1;
    T2 t2;
public:
    A(T1 _t1, T2 _t2) : t1(_t1), t2(_t2) { std::cout << "This is a normal template " << t1 << " " << t2 << std::endl; }
};

template<>
class A<int, int> {
    int t1;
    int t2;
public:
    A(int _t1, int _t2) : t1(_t1), t2(_t2) { std::cout << "This is a specialization template " << t1 << " " << t2 << std::endl; }
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

template<typename T>
class A {
    T t;
public:
    A(T _t) : t(_t) {}
    void p() { std::cout << "normal version of p : " << t << std::endl; }
};

template<>
void A<int>::p() {
    std::cout << "int version of p : " << t << std::endl;
}

int main() {
    A<std::string> a("hello");
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

* Herb Sutter 的这篇文章：[Why Not Specialize Function Templates?](http://www.gotw.ca/publications/mill17.htm) [2]。   

* [为什么函数模板没有偏特化？](https://blog.csdn.net/feng__shuai/article/details/125426105)   


关于如何让函数模板支持类似偏特化的效果，可以参考：   

* [C++函数模板的偏特化](https://zhuanlan.zhihu.com/p/268600376)   

<br/>

2、类模板支持偏特化    

例子：    

```cpp
#include <iostream>

template<typename T1, typename T2>
class A {
    T1 t1;
    T2 t2;
public:
    A(T1 _t1, T2 _t2) : t1(_t1), t2(_t2) { std::cout << "This is a normal template " << t1 << " " << t2 << std::endl; }
};

template<typename T2>
class A<int, T2> {
    int t1;
    T2 t2;
public:
    A(int _t1, T2 _t2) : t1(_t1), t2(_t2) { std::cout << "This is a partial template " << t1 << " " << t2 << std::endl; }
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
f ( p );           // 调用 (b)！因为重载决议会忽略特化版本，即（c）
                   // 所以先在（a）和（b）中选择，此时（b）刚好符合
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

class A {
    typedef int LType;
public:
    A() {
        A::LType a = 100;
        std::cout << a << std::endl;
    }
};

int main() {
    A();
    return 0;
}
```

像上面的代码，可能在有些编译器编译得过，有些编译不过。`A::LType` 是有歧义的，它可以指代 A 的下属类型，也可以指代 A 的静态变量。如果我们要明确的告诉编译器，`A::LType` 是一个类型，就需要这样写： `typename A::LType a = 100;`。  

类似的，经常在一些库里面看到函数的入参前加了 `typename` 关键字，它的作用就是表面后面跟着的是类型，而不是其他的。   

另外，还有这样的写法：`typedef typename std::vector<T>::size_type size_type;`，这里的含义就是 `typedef` 定义了一个名为 `size_type` 的别名，它指代 `typename std::vector<T>::size_type`。`typename` 的作用就是声明 `std::vector<T>::size_type` 是类型，而不是其他的。  

---

## 1.6 万能引用与完美转发

我记录在这篇文章了：[《c++ 笔记六：c++11 的新特性》](https://blog.antsmallant.top/2023/04/03/cpp-note-6-cpp11-new-features) 。    

---

# 2. 参考

[1] 五车书管. 函数模板的重载，偏特化，和全特化. Available at https://zhuanlan.zhihu.com/p/314340244, 2020-11-26.   

[2] Herb Sutter. Why Not Specialize Function Templates. Available at http://www.gotw.ca/publications/mill17.htm, 2001-7.   