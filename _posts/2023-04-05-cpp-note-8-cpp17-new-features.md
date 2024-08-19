---
layout: post
title: "c++ 笔记：c++17 的新特性"
date: 2023-04-05
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

本文记录 c++17 的新特性。  

c++17 是一个 "中" 版本，它本来应该是一个 major 版本的，不过它也有不少的新变化。  

---

# 1. c++17 新的语言特性

---

## 结构化绑定 (Structured binding)

允许一种简单直观的方式从复合结构中提取成员变量，并绑定到命名变量上。能够处理元组（tuple）、pair、数组、结构体。  

形式如：`auto [x,y,z] = expr`。  

示例 [1]：

```cpp
// 数组
int arr[] = {3,5,7};
auto [a, b, c] = arr; // a == 3; b == 5; c == 7;

// 结构体
struct S {
    int age;
    std::string name;
    double height;
};
S s {10,"Mike",150.0};
auto [a, b, c] = s; // a == 10; b == "Mike"; c == 150.0

// pair
std::pair<int, std::string> p(100, "cc");
auto [a, b] = p;  // a == 100; b == "cc";

// tuple
auto tp = std::make_tuple(100, "hello", 3.14);
auto [a, b, c] = tp;  // a == 100; b == "hello";  c == 3.14

// array
std::array<int, 3> arr {1, 3, 5};
auto [a, b, c] = arr;  // a == 1; b == 3; c == 5;

```

可以与 const 和引用结合起来使用，避免内存拷贝。  

```cpp
// const 引用
std::array<int, 3> arr {1, 3, 5};
const auto& [a, b, c] = arr; 
a = 100;  // not ok，会报错，因为 a 是 const int&，不能修改。

// 单纯引用，可以修改引用对象的值
std::map<int, std::string> m { {1, "hello"}, {2, "world"}};
for (auto& [k, v] : m) {
    v += "_abc";
}
// m 变成了 { {1, "hello_abc"}, {2, "world_abc"} }
```

详细参考：[C++17中的结构化绑定详解](https://blog.csdn.net/haokan123456789/article/details/137613251)。   

---

## 构造函数模板推导

c++17 之前用模板类实例化一个对象，需要指明类型，比如： 

```cpp
std::pair<int, double> p {10, 3.14};
std::vector<int> vec {1,2,3};
```

c++17 之后可以不指标类型，在编译期进行推导：  

```cpp
std::pair p {10, 3.14};
std::vector vec {1,2,3};
```

---

## 嵌套的命名空间 (nested namespace)

```cpp
namespace A {
    namespace B {
        namespace C {
            void func();
        }
    }
}

// c++17 可以这样写

namespace A::B::C {
    void func();
}
```

---

# 2. c++17 新的库特性

---

# 3. 参考

[1] 流星雨爱编程. C++17中的结构化绑定详解. Available at https://blog.csdn.net/haokan123456789/article/details/137613251, 2024-6-2.    