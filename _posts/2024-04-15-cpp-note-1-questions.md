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

# 题目

---

## 为什么需要引入 nullptr？

nullptr 是 c++11 引入的，用于代替 NULL，它也是有类型的，是 std::nullptr_t。  

在此之前，c++ 用 NULL 表示空，但它实际上就是 0，即是用 0 表示空，那么有些场合分不清楚意图了，是想传 NULL 还是数字 0？
比如这样： 

```cpp
void f(Widget* w);
void f(int num);

f(0); // 搞不清要匹配哪个函数
```

---

# 什么情况下编译器会对参数进行隐式类型转换以保证函数调用成功？   

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

## 什么是编译期多态？  


---