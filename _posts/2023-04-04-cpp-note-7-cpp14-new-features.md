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

## lambda 支持初始化捕获

可以在 `[]` 里面初始化捕获任意的表达式。  

比如这样：  

```cpp
// 在 [] 中初始化捕获了 x
auto func = [x = 3](auto y) { return x + y; };
```

如果想将初始化捕获的跟原本的捕获方式一起使用，则需要将初始化捕获的放在 `[]` 的最后面，像这样：  

```cpp
int a = 10;
int b = 20;

auto func = [a,b,x=30,y=50]() { return a + b + x + y; };
```

初始化捕获的好处是可以支持移动捕获，否则就只能像 c++11 那样只支持值捕获和拷贝捕获。  

示例：  

```cpp
std::unique_ptr<X> obj = std::make_unique_ptr<X>();
auto func = [o = std::move(obj)]() { 
    // do something
};
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

3、如果函数是虚函数，不能使用返回值类型推导。       

```cpp
struct X {
    // 编译报错
    virtual  auto f() { return 0; }  
}
```

4、返回值类型推导可以用在前向声明中，但是在使用之前，需要有该函数的定义。       

```cpp
auto f();  // 声明，但还未定义
auto f() { return 10; }  // 定义，返回值类型是 int

int main() {
    std::cout << f();
}
```  

5、返回值类型推导可以用在递归函数中，但递归调用必须至少以一个返回语句为先导，以便编译器推导出返回类型。        

```cpp
auto f(int i) {
    if (i == 1)
        return i;  // return int
    else
        return f(i-1) + 1;  // ok
}
```


---

## decltype(auto)

`decltype(auto)` 是一个类型标识符，它会像 `auto` 那样进行类型的推导，不同之处在于，`decltype(auto)` 返回的结果类型会保留引用以及 cv 标记 (cv-qualifiers)，而 `auto` 不会。   

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

## 放松 constexpr 函数的约束

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

c++14 引入了 `[[deprecated]]` 属性用于表明一个单元（函数、类等）不再推荐使用了，并且会在编译的时候报一个 warning。支持一个可选的 warning 信息。   

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

## std::integer_sequence

Manual: [cppreference-std::integer_sequence](https://en.cppreference.com/w/cpp/utility/integer_sequence) 。  

表示一个编译时的整型序列，主要用于模板元编程和泛型编程。有一些帮助函数用于构造：   

* `std::make_integer_sequence<T, N>` 创建一串 0, ..., N-1 的类型为 T 的序列。  
* `std::index_sequence_for<T...>` 将一组模板参数打包成一个整型序列。  

示例[1]：    

```cpp
// 将一个 array 转换成 tuple

template<typename Array, std::size_t... I>
decltype(auto) a2t_impl(const Array& a, std::integer_sequence<std::size_t, I...>) {
    return std::make_tuple(a[I]...);
}

template<typename T, std::size_t N, typename Indices = std::make_index_sequence<N>>
decltype(auto) a2t(const std::array<T, N>& a) {
    return a2t_impl(a, Indices());
}

```

---

## User-defined literals for standard library types （标准库的一些用户定义字面量）

用户定义字面量在 c++11 就引入，详见这篇笔记：[《c++ 笔记：c++11 的新特性 - 用户定义字面量》](https://blog.antsmallant.top/2023/04/03/cpp-note-6-cpp11-new-features#%E7%94%A8%E6%88%B7%E5%AE%9A%E4%B9%89%E5%AD%97%E9%9D%A2%E9%87%8F-user-defined-literals)。   

主要是 `chrono` 和 `basic_string` 这两个库。  

示例[1]：  

```cpp
using namespace std::chrono_literals;
auto day = 24h;
day.count();  // == 24
std::chrono::duration_cast<std::chrono::minutes>(day).count();  // == 1440
```

---

## std::exchange

Manual：[cppreference - std::exchange](https://en.cppreference.com/w/cpp/utility/exchange)。    

原型：  

```cpp
// 参数说明
//   obj ： 需要被替换值的对象
//   new_value ：用于赋值给 obj 的新值
// 返回值
//   obj 的旧值
template< class T, class U = T >
T exchange( T& obj, U&& new_value );
```

`T` 需要满足可移动构造，同时也需要满足从类型 U 到类型 T 的移动赋值。  

它与 `std::swap` 的区别：单向的移动赋值，不是交换。  

它的一个可能实现：   

```cpp
template<class T, class U = T>
T exchange(T& obj, U&& new_value) {
    T old_value = std::move(obj);
    obj = std::forward<U>(new_value);
    return old_value; 
}
```

示例：  

```cpp
int main() {
    std::vector<int> v;
    std::exchange(v, {1,3,5,7});
    std::cout << v.size() << std::endl;  // 4
    for (auto x : v) std::cout << x << " ";  // 1 3 5 7
}
```

---

## std::shared_timed_mutex

Manual：[cppreferecne - std::shared_timed_mutex](https://en.cppreference.com/w/cpp/thread/shared_lock) 。  
头文件：`<shared_mutex>`。  

c++14 引入的新同步原语，可以用于实现读写锁。它符合 `SharedTimedMutex` 要求，而 `SharedTimedMutex` 符合 `TimedMutex` 和 `SharedMutex` 要求，所以 `std::shared_timed_mutex` 可以配合 `std::shared_lock` 使用。  

它有两种访问方式：  

1. 独占的(exclusive)，只有一条线程可以占有这个 mutex。   
2. 共享的(shared)，多条线程可以分享同个 mutex。   

当需要“读锁”时，可配合 `std::shared_lock` 使用；当需要“写锁”时，可配合 `std::lock_guard` 或 `std::unique_lock` 使用。   

独占锁定 (exclusive locking) 的 api：   

```
lock
try_lock
try_lock_for
try_lock_until
unlock
```

共享锁定 (shared locking) 的 api:    

```
lock_shared
try_lock_shared
try_lock_shared_for
try_lock_shared_until
unlock_shared
```

---

## std::shared_lock

Manual: [cppreference - std::shared_lock](https://en.cppreference.com/w/cpp/thread/shared_lock) 。  

头文件：`<shared_mutex>`。  

与 `std::unique_lock` 类似，是一种通用的 mutex 包装器。`std::shared_lock` 对应的 mutex 的类型 L 是要符合 `SharedLockable` 要求的，相当于一种接口规范吧，即对于一个 L 类型的对象 m，要支持以下几种调用：  

```cpp
m.lock_shared();
m.try_lock_shared();
m.unlock_shared();
```

示例[4]：   

```cpp
#include <iostream>
#include <mutex>
#include <shared_mutex>
#include <string>
#include <thread>

std::string file = "Original content";   // 模拟一个文件
std::mutex output_mutex;  // 保护输出操作的 mutex
std::shared_mutex file_mutex; // reader/writer mutex

void read_content(int id) {
    std::string content;
    {
        std::shared_lock lock(file_mutex, std::defer_lock); // 暂时不加锁
        lock.lock();  // 加锁
        content = file;
    }
    std::lock_guard lock(output_mutex);
    std::cout << "Contents read by reader #" << id << ": " << content << '\n';
}

void write_content() {
    {
        std::lock_guard file_lock(file_mutex);
        file = "New content";
    }
    std::lock_guard output_lock(output_mutex);
    std::cout << "New content saved.\n";
}

int main() {
    std::cout << "Two readers reading from file.\n"
              << "A writer competes with them.\n";
    std::thread reader1{read_content, 1};
    std::thread reader2{read_content, 2};
    std::thread writer{write_content};
    reader1.join();
    reader2.join();
    writer.join();
    std::cout << "The first few operations to file are done.\n";
    reader1 = std::std::thread{read_content, 3};
    reader1.join();
}

```

一个可能的输出是：   

```
Two readers reading from file.
A writer competes with them.
Contents read by reader #1: Original content
Contents read by reader #2: Original content
New content saved.
The first few operations to file are done.
Contents read by reader #3: New content
```

---

# 3. 参考

[1] AnthonyCalandra. C++14. Available at https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP14.md.     

[2] Wikipedia. c++14. Available at: https://zh.wikipedia.org/wiki/c++14.    

[3] 程序喵大人. C++14新特性的所有知识点全在这儿啦. Available at https://zhuanlan.zhihu.com/p/165389083, 2021-03-24.   

[4] cppreference. std::shared_lock. Available at https://en.cppreference.com/w/cpp/thread/shared_lock/lock.   