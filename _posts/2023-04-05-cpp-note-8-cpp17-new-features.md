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

**概览**  

参考自：《C++之旅（第3版）》[2]。   

* 保证拷贝省略。  
* 超对齐类型的动态分配。
* 严格指定运算顺序。
* UTF-8 字面量。
* 十六进制浮点字面量。
* 折叠表达式。
* 泛型值模板参数（auto模板参数）。
* 类模板参数的类型推导。
* 编译时 if。 
* 带有初始值设定项的选择语句。
* constexpr 匿名函数。
* inline 变量。
* 结构化绑定。
* 新的标准属性：`[[maybe_unused]]、[[nodiscard]] 和 [[fallthrough]]`。 
* std::byte 类型。 
* 用底层类型的值来初始化 enum 类型。 
* 一些小的扩展。

---

## 结构化绑定 (Structured binding)

允许一种简单直观的方式从复合结构中提取成员变量，并绑定到命名变量上。能够处理元组（tuple）、pair、数组、结构体。  

形式如：`auto [x,y,z] = expr`。  

specification: [《cppreference - Structured binding declaration》](https://en.cppreference.com/w/cpp/language/structured_binding) 。    

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

详细参考：[《C++17中的结构化绑定详解》](https://blog.csdn.net/haokan123456789/article/details/137613251)。   

---

## 构造函数模板推导

c++17 之前用模板类实例化一个对象，需要指明类型，比如： 

```cpp
std::pair<int, double> p {10, 3.14};
std::vector<int> vec {1,2,3};
```

c++17 之后可以不指定类型，在编译期进行推导：  

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

## 新的属性（attributes）: `[[fallthrough]]`, `[[nodiscard]]`, `[[maybe_unused]]`

1、`[[fallthrough]]`    

告诉编译器，switch 语句里面，case 不加 break 是有意为之的，不需要给出 warning。只能用于 switch 语句中，且需要放置在下一个 `case/default` 标签的前面。  

示例[3]：  

```cpp
switch(x) {
    case 1: 
    // ...
    [[fallthrough]];
    case 2:
    // ...
    break;
    case 3:
    // ...
    [[fallthrough]];
    default:
    //...
}
```

<br/>

2、`[[nodiscard]]`    

用于修饰一个函数或类，但返回值被抛弃（不处理）时，会给出一个警告。  

示例[3]:  

```cpp
[[nodiscard]] bool f() {
    // ...
    return ok; 
}

f();  // 会给出警告，因为忽略了返回值
```

```cpp
struct [[nodiscard]] X {
    //...
};

X f() {
    X x;
    return x;
}

f();  // 会给出警告，因为 X 这种类型有 nodiscard 属性，它作为返回值的时候，
      // 如果被抛弃就会告警
```

<br/>

3、`[[maybe_unused]]`    

告诉编译器，一个变量或参数可能不会被使用，是有意为之的。   

示例[3]:  

```cpp
void f(int a, [[maybe_unused]] std::string b) {
    // 函数内不使用 b 也不会告警
    std::cout << a << std::endl;
}
```

---

# 2. c++17 新的库特性

**概览**    

参考自：《C++之旅（第3版）》[2]。    

* 文件系统。
* 并行算法。
* 数学特殊函数。
* string_view。
* any。
* variant。
* optional。 
* 调用任何可以为给定参数集调用的方法：invoke()。 
* 基本字符串转换：to_chars() 和 from_chars()。 
* 多态分配器。
* scoped_lock。
* 一些小的扩展。

---

## std::variant

头文件：`<variant>`。   

表示一种类型安全的 union。`std::variant` 的实例，在任何

---

# 3. 参考

[1] 流星雨爱编程. C++17中的结构化绑定详解. Available at https://blog.csdn.net/haokan123456789/article/details/137613251, 2024-6-2.    

[2] [美] Bjarne Stroustrup. C++之旅（第3版）. pansz. 北京: 电子工业出版社, 2023-10(1).   

[3] AnthonyCalandra. C++17. Available at https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP17.md.   
