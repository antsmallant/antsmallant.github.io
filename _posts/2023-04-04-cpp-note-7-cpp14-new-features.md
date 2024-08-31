---
layout: post
title: "c++ 笔记：c++14 的新特性"
date: 2023-04-04
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

本文记录 c++14 的新特性。  

c++14 是一个 minor 版本，主要是对于 c++11 一些不完善之处的补充。  

---

# 1. c++14 新的语言特性

**概览**  

参考自：[《wikipedia c++14》](https://zh.wikipedia.org/wiki/c++14) [2]。   

* 泛型的lambda
* Lambda捕获部分中使用表达式
* 函数返回类型推导
* 另一种类型推断:decltype(auto)
* 放松的constexpr函数限制
* 变量模板
* 聚合类成员初始化
* 二进制字面量： 0b或0B 前缀
* 数字分位符
* deprecated 属性

---

## binary literals (二进制字面值)

提供了一种方便的形式来书写二进制数值，以 `0b` 开头，比如这样：  

```cpp
0b101        // 表示 5
```

---

## 整型字面量分隔符  

支持用 `'` 分隔数值字面量，比如：   

```cpp
int a = 0b1111'1111;       // 二进制，表示 255
double b = 3.14'15'926;    // 3.1415926
```

---

## 变量模板

大致用法：  

```cpp
template<class T>
constexpr T e = T(2.718281828459);

int main() {
    std::cout << e<int> << std::endl;    // 2
    std::cout << e<double> << std::endl; // 2.71828
}

```

---

## lambda 支持使用 auto 作为参数类型声明符

通过这种方式，可以写出支持多态的 lambda 函数。比如：   

```cpp

auto id = [](auto x) { return x; }
int no1 = id(1);   // no1 == 1
std::string name = id("hello"); // name == "hello"

```

---

## Return type deduction (返回值类型推导)

使用 `auto` 作为返回值类型的时候，编译器会尝试进行类型推导。  

1、用于普通函数

```cpp
auto f(int i) {
    return i;
}
```

2、用于模板     

```cpp
template<typename T>
auto f(T t) {
    return t; 
}
```

3、用于 lambda，可以返回类型引用[1]   

```cpp
auto g = [](auto& x) -> auto& { return f(x); };   
```

<br/>

一些注意事项[3]   

1、函数内有多个 return 语句，它们必须返回相同的类型，否则编译会失败。   

2、如果 return 语句返回初始化列表，返回值类型推导也会失败。   

```cpp
auto f() {
    return {1,2,3};   // 编译报错
}
```

3、如果函数是虚函数，不能使用返回值类型推导    

```cpp
struct X {
    // 编译报错
    virtual  auto f() { return 0; }  
}
```

4、返回值类型推导可以用在前向声明中，但在使用前，

---

## decltype(auto)

`decltype(auto)` 是一个类型标识符，它会像 `auto` 那样进行类型的推导，不同之处在于，`decltype(auto)` 返回的结果类型会保留引用以及cv 标记 (cv-qualifiers)，而 `auto` 不会。   

示例[1]:   

```cpp
const int x = 0;
auto x1 = x;           // int
decltype(auto) x2 = x; // const int

int y = 0;
int& y1 = y;
auto y2 = y1;            // int
decltype(auto) y3 = y1;  // int&

int&& z = 0;
auto z1 = std::move(z);           // int
decltype(auto) z2 = std::move(z); // int&&
```

对于范型代码特别方便[1]：  

```cpp
// 返回类型是 `int`
auto f(const int &i) {
    return i;
}

// 返回类型是 `const int&`
decltype(auto) g(const int &i) {
    return i;
}

int x = 234;
static_assert(std::is_same<const int&, decltype(f(x))>::value == 0);
static_assert(std::is_same<int, decltype(f(x))>::value == 1);
static_assert(std::is_same<const int&, decltype(g(x))>::value == 1);
```

---

## 放松 `constexpr` 函数的约束

在 c++11 中，`constexpr` 函数只能包含一些很有限的语法，比如 `typedef`、`using`，以及只能有一个 return 表达式。但在 c++14，大大放松了限制，支持的语法范围扩大到 `if` 语句，局部变量，多个 `return` 表达式，循环等。  

示例[1]：   

```cpp

// c++11 not ok, c++14 ok
constexpr int fac(int n) {  
    if (n <= 1) {
        return 1;
    } else {
        return n * fac(n-1);
    }
}

// c++11 not ok, c++14 ok
constexpr int fac2(int n) {
    int ans = 0;
    for (int i = 0; i < n; ++i) {
        ans += i;
    }
    return ans;
}

constexpr int a = fac(5);  // c++14 ok，不会报错，a == 120

constexpr int b = fac2(5); // c++14 also ok
```

---

## `[[deprecated]]` 属性

c++14 引入了 `[[deprecated]]` 属性用于表明一个单位（函数、类等）不再推荐使用了，并且会在编译的时候报一个 warning。支持一个可选的 warning 信息。   

示例[1]:   

```cpp
[[deprecated]]
void very_old_f();

[[deprecated("use new_method instead")]]
void legacy_method();
```

---

# 2. c++14 新的库特性

**概览**  

参考自：[《wikipedia c++14》](https://zh.wikipedia.org/wiki/c++14) [2]。   

* 共享的互斥体和锁: `std::shared_timed_mutex`
* 元函数的别名
* 关联容器中的异构查找
* 标准自定义字面量
* 通过类型寻址多元组
* 较小的标准库特性: `std::make_unique`, `std::is_final` 等

---

## std::make_unique

c++11 中只有 `std::make_shared`，现在 c++14 把 `std::make_unique` 也补上了。   

这样用：  

```cpp
struct X {};
std::unique_ptr<X> p = std::make_unique<X>();
```

使用 `std::make_unique` 的理由与使用 `std::make_shared` 的一样，见：[c++ 笔记：c++11 的新特性 - std::make_shared](https://blog.antsmallant.top/2023/04/03/cpp-note-6-cpp11-new-features#stdmake_shared)。   

---

## std::quoted

用于给字符串添加双引号，头文件是：`<iomanip>`。    

效果是这样的：    

```cpp
std::string s = "hello, world";
std::cout << s << std::endl;
std::cout << std::quoted(s) << std::endl;
```

输出：  

```
hello, world
"hello, world"
```

---

# 3. 参考

[1] AnthonyCalandra. C++14. Available at https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP14.md.     

[2] Wikipedia. c++14. Available at: https://zh.wikipedia.org/wiki/c++14.    

[3] 程序喵大人. C++14新特性的所有知识点全在这儿啦. Available at https://zhuanlan.zhihu.com/p/165389083, 2021-03-24.   