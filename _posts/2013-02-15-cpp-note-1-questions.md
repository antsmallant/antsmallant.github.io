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

不可以，memcmp 是逐字节比较的，而 struct 存在字节对齐，字节对齐时，补的字节内容是垃圾，不能比较。   

---

## 1.7 rvo、nrvo、copy elision  

copy elision，即 “复制省略”，是编译器的优化技术，包含两个场景：  

* 纯右值参数复制构造时的 copy elision。   
* 函数返回值优化（rvo）。   


1、纯右值参数复制构造时的 copy elision 的例子

```cpp

```





参考文章：  
[Copy/move elision: C++ 17 vs C++ 11](https://zhuanlan.zhihu.com/p/379566824)     
[理解C++编译器中的 Copy elision 和 RVO 优化](https://zhuanlan.zhihu.com/p/703789055)       

---

## 1.8 什么是运行时多态？是怎么实现的？  

c++ 的运行时多态是使用虚函数表实现的，有一篇文章总结得不错：[《C++中虚函数、虚继承内存模型》](https://zhuanlan.zhihu.com/p/41309205) [2]。   

---

## 关于继承的一些常识

---

## 什么是虚函数？什么是纯虚函数？

---

## 什么是编译时多态？  

参考自：[编译期多态](https://xie.infoq.cn/article/829d74dcd8d19aa613f8da059) [1]。  

编译时多态又称静态多态或类型安全多态，是指在编译期就可以确定函数的实际类型的多态。  

实现手段包括函数重载和函数模板：  

* 函数重载，是指同一作用域中，函数名相同，但参数列表不同的函数，编译时可以根据传入的参数类型确定要调用哪个函数。  

* 函数模板，是一种特殊函数，可以接受一个或多个模板参数作为函数的参数，编译时会将类型参数替换为实际类型。     


---

## auto 对于运行速度有影响吗？ 

不会有影响，auto 是编译时推导的。auto 依赖于值的类型进行类型推导，所以使用 auto 声明时必须同时进行初始化。  


---

## 字节对齐的意义是什么？如何做到字节对齐？    


---

## extern 的作用是什么？  

参考：[c++全局变量extern](https://zhuanlan.zhihu.com/p/658392228)    

---

## static 的作用是什么？

参考：[C/C++ 中的static关键字](https://zhuanlan.zhihu.com/p/37439983)    

---

## volatile 的作用是什么？  

---

## template 中 typename 与 class 的区别？  

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

## constexpr 与 const 的区别是什么？


---

## const 相对于 define 有何好处？

---

## c99 支持 VLA，那么 c++ 支持吗？ 

[Why aren't variable-length arrays part of the C++ standard?](https://stackoverflow.com/questions/1887097/why-arent-variable-length-arrays-part-of-the-c-standard)   


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

[2] Holy Chen. C++中虚函数、虚继承内存模型. Available at https://zhuanlan.zhihu.com/p/41309205, 2018-08-07.   