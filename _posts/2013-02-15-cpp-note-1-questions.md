---
layout: post
title: "c++ 笔记一：常识、用法"
date: 2013-02-15
last_modified_at: 2023-04-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 c++ 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

---

## 1.1 为什么需要引入 nullptr？

nullptr 是 c++11 引入的，用于代替 NULL，它也是有类型的，是 std::nullptr_t。  

在此之前，c++ 用 NULL 表示空值，但它实际上就是 0 。那么有些场合分不清楚是想传 空值 还是 数字0。   

比如这样：   

```cpp
void f(int* i) {}
void f(int i) {}

f(NULL);      // 编译报错，有歧义，不确定要调用哪个版本的 f
f(nullptr);   // ok
```

---

## 1.2 什么情况下编译器会对参数进行隐式类型转换以保证函数调用成功？   

编译器进行隐式类型转换，即是要生成一个临时对象，有两个前提：    
1、实参是可以隐式转换成目标类型的；   
2、参数是通过 by const reference 或 by value 的方式传递的；    

归结起来就是，函数调用时，编译器会为 by const reference 或 by value 这两种形式生成临时变量，但不会为 by reference 生成临时变量。     

比如 

```cpp
void f1(string s) {}
void f2(const string& s) {}
void f3(string& s) {}

int main() {
    const char* str = "hello, world";
    f1(str);  // ok
    f2(str);  // ok
    f3(str);  // not ok, compile error occurs
    return 0;
}

```

---

## 1.3 当实参是一个临时对象时，by value 方式传参的情况下，还会产生新的临时对象吗？ 

比如这样： 

```cpp
struct S {
    int a;
    S() { cout << "S 构造" << endl; }
    S(const S& other) { cout << "S 拷贝构造" << endl; this->a = other.a; }
    ~S() { cout << "S 析构" << endl; }
};

void f(S s) {(void)s;}

int main() {
    f(S());  // 这里会使用构造函数生成一个 S 对象，再通过拷贝构造生成另一个临时对象吗？
    return 0;
}
```

不会的，当实参本身就是临时对象时，不需要再生成临时对象。只有这样才需要：  

```cpp
S s;     // 构造一次，得到 s
f(s);    // 拷贝构造一次，得到临时对象
```

---

## 1.4 为什么 c++11 之后，`char* s = "hello, world";` 编译时会有 warning ？  

因为在 c++11 中，string literal 即这里的 "hello, world" 是 const char 数组类型的，不允许把 const char 数组转换成 char* 类型。   

要避免 warning，需要这样使用，`const char* = "hello, world";`。  

---

## 1.5 一个空类占用的空间是多少？ 

一个不继承自其他类的纯净的空类，占用的空间大小是 1 字节。  

这样做的目的是使得任何变量都有一个唯一的地址，假设占用 0 字节，这个空类就不会有一个唯一地址了。   


---

## 1.6 c++ 比较两个结构体，可以使用 `memcmp(void*, void*)` 吗？  

不可以，memcmp 是逐字节对齐的，而 struct 存在字节对齐，字节对齐时，补的字节内容是垃圾，不能比较。   

---

## 1.7 c 如何模拟面向对象？  

要模拟面向对象，即要实现封装、继承、多态。  

**一、封装**    

封装就是把属性和对属性的操作封装在一个独立的实体中，这种实体在 c++ 称为类。  

1、c 语言模拟封装，可以用 struct 来模拟类，struct 中可以使用函数指针变量来保存类的成员函数。   
2、c 函数要访问类里面的成员，需要有类对象的指针，那么这些成员函数的第一个变量可以统一为指向对象指向的指针，这个相当于模拟 c++ 的 this 指针。   
3、但是 c++ 的 public, protected, private 这几种对成员的访问限制，在 c 中模拟不了。   

举个例子： 

```c
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

struct Point {
    int x;
    int y;
    void (*scale) (struct Point*, int);
};

void point_scale(struct Point* self, int factor) {
    self->x *= factor;
    self->y *= factor;
}

void point_init(struct Point* pt) {
    pt->x = 10;
    pt->y = 20;
    pt->scale = point_scale;
}

void point_destroy(struct Point* pt) {
    printf("point destroy\n");
    // do not free here
}

int main() {
    struct Point* pt = (struct Point*)malloc(sizeof(struct Point));
    point_init(pt);
    printf("before scale: %d, %d\n", pt->x, pt->y);
    pt->scale(pt, 30);
    printf("after scale: %d, %d\n", pt->x, pt->y);
    point_destroy(pt);
    free(pt);
    return 0;
}
```

说明：    
1、在这种模拟中，使用函数指针来保存函数，相比于 C++，是一种内存上的额外开销，C++ 对象的内存里不需要保存成员函数指针，它在编译时就能确定。     

<br/>

**二、继承**   

可以在子类里定义一个基类的对象作为变量，并且在重载函数的时候，在重载函数里，选择性的调用基类的函数。  

举个例子：   

```c
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

struct Base {
    int x;
    void (*print) (struct Base*);
};

void base_print(struct Base* self) {
    printf("base, x: %d\n", self->x);
}

void base_init(struct Base* base) {
    base->x = 10;
    base->print = base_print;
}

void base_destroy(struct Base* base) {
    printf("base destroy\n");
}

struct Derived {
    struct Base base;
    int y;
    void (*derivedPrint) (struct Derived*);
};

void derived_print(struct Derived* self) {
    self->base.print(&self->base);
    printf("derived, y: %d\n", self->y);
}

void derived_init(struct Derived* d) {
    base_init((struct Base*)d);
    d->y = 20;
    d->derivedPrint = derived_print;
}

void derived_destroy(struct Derived* d) {
    printf("derived_destroy\n");
    base_destroy((struct Base*)d);
}

int main() {
    struct Derived* d = (struct Derived*)malloc(sizeof(struct Derived));
    derived_init(d);
    d->derivedPrint(d);
    derived_destroy(d);
    free(d);
    return 0;
}
```

</br>

**三、多态**   





---

## 1.8 什么是编译时多态？  

参考自：[编译期多态](https://xie.infoq.cn/article/829d74dcd8d19aa613f8da059) [1]。  

编译时多态又称静态多态或类型安全多态，是指在编译期就可以确定函数的实际类型的多态。  

实现手段包括函数重载和函数模板：  

* 函数重载，是指同一作用域中，函数名相同，但参数列表不同的函数，编译时可以根据传入的参数类型确定要调用哪个函数。  

* 函数模板，是一种特殊函数，可以接受一个或多个模板参数作为函数的参数，编译时会将类型参数替换为实际类型。     


---

## 1.9 auto 对于运行速度有影响吗？ 

不会有影响，auto 是编译时推导的。auto 依赖于值的类型进行类型推导，所以使用 auto 声明时必须同时进行初始化。  


---

## 1.10 extern 的作用是什么？  

---

## 1.11 volatile 的作用是什么？  

---

## 1.12 template 中 typename 与 class 的区别？  

---

## 什么是完美转发？std::forward 是怎么起作用的？

---

## xvalue 具体是怎么形成的？

---

## 什么情况下会用到右值引用？返回右值引用意味着什么？

---

## 为什么 string literal 是一种 lvalue？

---

## 初始化列表是什么意思？   

---

## 什么是结构化绑定？有性能损耗吗？  

---

## 什么是 emplace_back ？它的作用是什么？ 


---

## type_traits 的作用是什么？  


---

## `auto&` 是一种好的写法吗？

* [C++ auto& vs auto - Stack Overflow](https://stackoverflow.com/questions/29859796/c-auto-vs-auto)

---

## 什么是万能引用？  

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

## 什么是别名声明？  

---

# 2. 用法

---

# 3. 参考

[1] SkyFire. 编译期多态. Available at https://xie.infoq.cn/article/829d74dcd8d19aa613f8da059, 2023-01-28.    