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

## 保证拷贝省略

我在这篇文章 [《c++ 笔记：copy elision、rvo、nrvo》](https://blog.antsmallant.top/2023/04/01/cpp-note-4-copy-elision-rvo-nrvo) 做了相关的论述了。  

---

## 超对齐类型的动态分配（over-aligned allocation）

参考：   

* [Dynamic memory allocation for over-aligned data](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2016/p0035r4.html)

* [`/Zc:alignedNew (C++17 over-aligned allocation)`](https://learn.microsoft.com/en-us/cpp/build/reference/zc-alignednew?view=msvc-170)   
* [cppreference - std::aligned_alloc](https://en.cppreference.com/w/cpp/memory/c/aligned_alloc)
* [C++ over-aligned memory allocation](https://www.cnblogs.com/thomas76/p/8618175.html)


不太明白是什么特性，暂时没空深究。  

TODO.  

---

## 严格指定运算顺序

比较难以说清。但带来的效果是很好的，在 c++17 之前，这样使用 `f(std::shared_ptr<A>(new A()), get_some_param());` 是不安全的，可能会内存泄漏。 

因为编译器的求值顺序可能是这样的： 
1. new A();
2. get_some_param();
3. 构造 shared_ptr;  

假如第2步抛出异常，那么第3步就来不及执行了，第1步new出来的对象就内存泄漏了。  

而在 c++17 之后，求值顺序明确了，要么是 (2,1,3)，要么是 (1,3,2)，2 不会再插到 1,3 的中间了。   


一些参考文章：  

* [Refining Expression Evaluation Order for Idiomatic C++](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2016/p0145r3.pdf)
* [Trip report: Summer ISO C++ standards meeting (Oulu)](https://herbsutter.com/2016/06/30/trip-report-summer-iso-c-standards-meeting-oulu/)   
* [GotW #56](http://gotw.ca/gotw/056.htm)
* [What are the evaluation order guarantees introduced by C++17?](https://stackoverflow.com/questions/38501587/what-are-the-evaluation-order-guarantees-introduced-by-c17)
* [C++求值顺序](https://cloud.tencent.com/developer/article/1394034)
* [C++避坑---函数参数求值顺序和使用独立语句将newed对象存储于智能指针中](https://cloud.tencent.com/developer/article/2288023)
* [《C++17之定义表达式求值顺序》](https://blog.csdn.net/janeqi1987/article/details/100181769) 

---

## utf-8 字面量

以 u8 开头修饰一个字符，它的值与 ISO 10646 的 code point 值相等。  

```cpp
char x = u8'x';
```

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

<br/>

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

## 文件系统 (std::filesystem)

提供了关于文件的大多数功能，可以操作文件、目录、路径。功能比较庞杂，使用的时候具体看 cppreference 上的 specification 就行了。  

头文件：`<filesystem>`。  

Manual: [cppreference - Filesystem library](https://en.cppreference.com/w/cpp/filesystem) 。   

示例[2]：  

```cpp
// 如果临时空间足够大，则把一个大文件拷贝进去 
const auto bigFilePath {"bigFileToCopy"};
if (std::filesystem::exists(bigFilePath)) {
    const auto sz {std::filesystem::file_size(bigFilePath)};
    std::filesystem::path tmpPath {"/tmp"};
    if (std::filesystem::space(tmpPath).available > sz) {
        std::filesystem::create_directory(tmpPath.append("example"));
        std::filesystem::copy_file(bigFilePath, tmpPath.append("newfile"));
    }
}
```

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

标准库模板类，管理一个可选的值，既可以存在，也可以不存在。主要目的是避免使用特殊的标志值（比如 空指针或者特殊值）来表示缺少值。    

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

## std::any

用于任何可拷贝构造的单个值的类型安全容器。`std::any` 不是模板类，而是一种特殊的容器，只能容纳一个元素，这个元素可以是任意类型。  

`std::any` 可以用于实现非虚多态，参考这个文章： [《A Journey Into Non-Virtual Polymorphism in C++ - Rudyard Merriam - CppCon 2023》](https://github.com/CppCon/CppCon2023/blob/main/Presentations/A_Journey_into_Non_Virtual_Polymorphism_Rud_Merriam.pdf) 。   

头文件：`<any>`。   

Manual: [cppreference - std::any](https://en.cppreference.com/w/cpp/utility/any)    

一些成员函数：    

|函数|作用|
|:--|:--|
|has_value|检查是否持有一个值|
|type|返回持有值的 typeid|

一些可使用的非成员函数：   

|函数|作用|
|:--|:--|
|any_cast|类型安全的访问持有的对象|
|make_any|创建一个any对象|


示例：  

```cpp
// 构造时不需要指定类型
std::any a;            // ok，初始值可以为空
std::any b = 100;      // ok，保存 int 
std::any c = "hello,world"; // ok，保存 const char*


// 使用 any_cast 访问包含的值
// std::any_cast<int>(a);  // 会报错，bad_cast
std::cout << std::any_cast<int>(b);  // 100
std::cout << std::any_cast<const char*>(c);  // "hello, world"


// 或者使用 make_any 构造，必须显式指定类型 T，参数会传递给 T 的构造函数
struct A {
    int x, y, z;
    A(int _x, int _y, int _z):x(_x), y(_y), z(_z) {}
};
auto m = std::make_any<A>(10, 20, 30);
auto n = std::any_cast<A>(m);     // n == A{10,20,30}


// 要保存的类型与初始值不符时，使用 in_place_type 指定
std::any h {std::in_place_type<int>, 30.33};   // == 30
std::any i {std::in_place_type<std::string>, "hello, world"}; // == std::string("hello, world")

```

示例2：  

```cpp
std::any d = 1;
std::cout << d.type().name() << ": " << std::any_cast<int>(d) << std::endl;
d = 3.14;
std::cout << d.type().name() << ": " << std::any_cast<double>(d) << std::endl;
d = true;
std::cout << d.type().name() << ": " << std::any_cast<bool>(d) << std::endl;
```

输出（gcc-13.2.0 版本）：  

```
i: 1
d: 3.14
b: 1
```

示例3：  

```cpp
// 可以使用 std::any 接收函数的返回值
int f() {
    return 100;
}

std::any x = f();
std::cout<< std::any_cast<int>(x);  // 100
```

---

## std::string_view

---

## std::invoke

用一组参数调用一个可调用（Callable）对象。可调用对象可以是 `std::function` 或者 lambda。   

头文件：`<functional>` 。    

```cpp
auto f = [](int x, int y) {
    return x+y;
};
auto x = std::invoke(f, 3, 7);  // x == 10
```

---

## std::apply

用一个包含着参数的 `std::tuple` 来调用一个可调用对象。    

头文件：`<tuple>`。   

```cpp
auto f = [](int x, int y) {
    return x+y;
};

auto ret = std::apply(f, std::make_tuple(10, 20));  // ret == 30;
```

---

# 3. 参考

[1] [美] Bjarne Stroustrup. C++之旅（第3版）. pansz. 北京: 电子工业出版社, 2023-10(1).   

[2] AnthonyCalandra. C++17. Available at https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP17.md.   