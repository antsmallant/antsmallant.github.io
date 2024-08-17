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



---

# 2. c++14 新的库特性

---

# 3. 参考

[1] AnthonyCalandra. C++14. Available at https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP14.md.     