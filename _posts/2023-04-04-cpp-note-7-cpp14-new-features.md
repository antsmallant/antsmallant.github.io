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

---

## 1.1 decltype(auto)

`decltype(auto)` 是一个类型标识符，它会像 `auto` 那样进行类型的推导，不同之处在于，`decltype(auto)` 返回的结果类型会保留引用以及cv标记 (cv-qualifiers)，而 `auto` 不会。   

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

在 c++11 中，`constexpr` 函数只能包含一些很有限的语法，比如 `typedef`、`using`，以及只能有一个 return 表达式。但在 c++14，大大放松了限制，支持的语法范围扩大到 `if` 语句，多个 `return` 表达式，循环等。  

示例[1]：   

```cpp

constexpr int fac(int n) {
    if (n <= 1) {
        return 1;
    } else {
        return n * fac(n-1);
    }
}

constexpr int a = fac(5); // ok，不会报错，a == 120

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

---

# 3. 参考

[1] AnthonyCalandra. C++14. Available at https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP14.md.     