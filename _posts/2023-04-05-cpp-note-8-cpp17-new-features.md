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

参考自：《C++之旅（第3版）》[1]。   

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

示例：  

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

示例[2]：  

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

示例[2]:  

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

示例[2]:  

```cpp
void f(int a, [[maybe_unused]] std::string b) {
    // 函数内不使用 b 也不会告警
    std::cout << a << std::endl;
}
```

---

# 2. c++17 新的库特性

**概览**    

参考自：《C++之旅（第3版）》[1]。    

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

类似于 union，但类型安全，且支持更多的类型。约束：不允许持有引用、array、以及 void 类型。    

`std::variant` 的实例，在任何时候要么有一个可选值，要么处于 “无值” 的错误状态。   

示例[2]：    

```cpp
std::variant<int, double> v { 100 };
std::get<int>(v);  // == 100
std::get<0>(v);    // == 100
v.index();         // == 0，当前持有的是第1个类型的值
std::get<1>(v);    // 会报错：std::get: wrong index for variant

v = 100.01;        
std::get<double>(v); // == 100.01
std::get<1>(v);      // == 100.01
v.index();           // == 1，当前持有的是第2个类型的值
std::get<0>(v);      // 会报错
std::get<int>(v);    // 会报错

std::variant<int, char> w; 
std::get<int>(w);    // ok，== 0
```

一般情况下，`std::variant` 的第一个类型要有对应的构造函数，否则编译报错：   

```cpp
struct X {
    X(int v){}
};
int main() {
    std::variant<A, int> a;  // 编译报错
}
```

这种情况下，可以使用 `std::monostate` 占个位，避免报错：    

```cpp
std::variant<std::monostate, A, int> a;  // ok 了
```

---

## std::optional

头文件：`<optional>`。    

Manual: [cppreference - std::optional](https://en.cppreference.com/w/cpp/utility/optional) 。   

标准库模板类，提供了一种表示可选值的方式，也就是值可能存在，也可能不存在。主要目的是避免使用特殊的标志值（比如 空指针或者特殊值）来表示缺少值。    

```cpp
std::optional<double> f(int x, int y) {
    if (y == 0)
        return std::nullopt;  // 表示值缺失
    return x/y;
}

int main() {
    auto ret = f(100, 0);
    if (ret) {
        std::cout << "call suc, ret = " << *ret << std::endl; // 如果调用成功，可以通过 * 号解引用获取值
    } else {
        std::cout << "call fail" << std::endl;
    }
}
```

一些用法：   

* 可选值的创建
    1. 通过构造函数创建：`std::optional<int> opt_val(1000);`
    2. 通过 `std::make_optional` 创建，比如：`auto opt = std::make_optional<int>(100);`
    3. 使用 `std::nullopt` 表示空值，`std::optional<int> x = std::nullopt;`    

* 可选值的访问   
    1. `has_value()` 或 `operator bool` 判断值是否存在。     
    2. 如果值存在，可以用 `value()` 方法获取，但是如果不存在，则行为未定义。     
    3. 使用 `value_or` 在对象为空时提供一个备用值，比如 `std::optional<int> opt_value; opt_value.value_or(200);`      

* 可选值的修改     
    1. 通过 `reset()` 清除值。     
    2. 用赋值操作符，比如 `std::optional<int> opt_val; opt_val = 300;`。   

---

# 3. 参考

[1] [美] Bjarne Stroustrup. C++之旅（第3版）. pansz. 北京: 电子工业出版社, 2023-10(1).   

[2] AnthonyCalandra. C++17. Available at https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP17.md.   