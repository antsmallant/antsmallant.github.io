---
layout: post
title: "c++ 笔记一：常识问题合集"
date: 2024-04-15
last_modified_at: 2024-04-15
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

---

# 问题

---

## 为什么需要引入 nullptr？

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

## 什么情况下编译器会对参数进行隐式类型转换以保证函数调用成功？   

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

## 当实参是一个临时对象时，by value 方式传参的情况下，还会产生新的临时对象吗？ 

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

## 为什么 c++11 之后，`char* s = "hello, world";` 编译时会有 warning ？  

因为在 c++11 中，string literal 即这里的 "hello, world" 是 const char 数组类型的，不允许把 const char 数组转换成 char* 类型。   

要避免 warning，需要这样使用，`const char* = "hello, world";`。  

---

## 一个空类占用的空间是多少？ 

一个不继承自其他类的纯净的空类，占用的空间大小是 1 字节。  

这样做的目的是使得任何变量都有一个唯一的地址，假设占用 0 字节，这个空类就不会有一个唯一地址了。   


---

## c++ 比较两个结构体，可以使用 `memcmp(void*, void*)` 吗？  

不可以，memcmp 是逐字节对齐的，而 struct 存在字节对齐，字节对齐时，补的字节内容是垃圾，不能比较。   

---

## c with class 要怎么实现？即 c 如何模拟面向对象？  

---

## 什么是编译期多态？  


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

## 什么是 emplace_back？它的作用是什么？ 


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

# 参考