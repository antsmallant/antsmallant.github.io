---
layout: post
title: "c++ 笔记：copy elision、rvo、nrvo"
date: 2023-04-01
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>


本文总结 copy elision、rvo、nvro 的概念及关系。   

---

# 1. copy elision 与 rvo 

copy elision，即 “复制省略”，是编译器的优化技术，包含两个场景：  

* 纯右值参数复制构造时的 copy elision。   
* 函数返回值优化（ rvo，即 return value optimization ）。   

从 c++17 开始，强制要求编译器实现 copy elision。在 c++17 之前（c++11 / c++14），copy elision 依赖于编译器的具体实现，gcc 是默认支持 copy elision 的。   

---

## 1.1 纯右值参数复制构造时的 copy elision

以下使用 gcc 13.2.0 。 

```cpp
#include <iostream>

struct A {
    int x;
    A(int _x) { x = _x; std::cout << "Call A(int)" << std::endl; }
    A(const A& a) { x = a.x; std::cout << "Call A(const A&)" << std::endl; }
};

int main() {
    [[maybe_unused]] A a = A(1); // 纯右值复制构造
    return 0;
}
```

1、对于 c++11 或 c++14    
如果关闭编译器的 copy elision 优化，即加上 `-fno-elide-constructors` 选项，则输出是：   

```
Call A(int)
Call A(const A&)
```

如果不关闭编译器的 copy elision 优化，则输出是：   

```
Call A(int)
```

2、对于 c++17    
无论是否关闭编译器的 copy elision 优化，输出都是：     

```
Call A(int)
```

---

## 1.2 函数返回值优化（rvo）

以下使用 gcc 13.2.0 。   

```cpp
#include <iostream>

struct A {
    int x;
    A(int _x) { x = _x; std::cout << "Call A(int)" << std::endl; }
    A(const A& a) { x = a.x; std::cout << "Call A(const A&)" << std::endl; }
    A(A&& a) { x = a.x; std::cout << "Call A(A&&)" << std::endl; }
};

A getA() {
    return A(10);
}

int main() {
    [[maybe_unused]] A a = getA();
    return 0;
}
```

1、对于 c++11 或 c++14   
如果关闭编译器的 copy elision 优化，即加上 `-fno-elide-constructors` 选项，则输出是：  

```
Call A(int)
Call A(A&&)
Call A(A&&)
```

如果不关闭编译器的 copy elision 优化，则输出是： 

```
Call A(int)
```

如果没有定义移动构造函数，则调用拷贝构造函数，可以编译器的 copy elision 可以优先掉移动构造或者拷贝构造。   

2、对于 c++17    
无论是否关闭编译器的 copy elision 优化，输出都是：    

```
Call A(int)
```

---

# 2. 关于 nrvo

rvo 中有一种特殊的场景，叫 nrvo，即 name return value optimization，返回函数中已经命名的局部变量。c++17 标准对于 nrvo 没有强制规定，具体优化要看编译器的实现。    

比如这样：    

```cpp
SomeType return_some_type() {
    SomeType x;   // x 就是一个 name return value
    return x;
}
```  

这种情况下，编译器可以这样优化，在调用者的栈上构造出 x 这个局部变量，作为参数传为 `return_some_type` 使用，避免需要实际的 return x。  

<br/>   
  
nrvo 比较复杂，需要分情况讨论。参考自此文章：[《理解C++编译器中的 Copy elision 和 RVO 优化》](https://zhuanlan.zhihu.com/p/703789055)  [1]：  

1、返回局部变量，如果存在运行时依赖，则不一定会优化，具体要看编译器的实现。  

比如这样： 

```cpp
SomeType get(bool flag) {
    if (flag) {
        SomeType x;
        // do some change
        return x;
    } else {
        SomeType y;
        return y;
    }
}
```

2、返回函数参数，不会优化。  

3、返回全局变量，不会优化。  

4、返回值使用 move 转换，不会优化。  

比如这样：  

```cpp
SomeType get() {
    SomeType x;
    return std::move(x);
}
```

---

# 3. 问题探讨

---

## 3.1 有了 copy elision，移动构造还有意义吗？ 

还有意义，因为 copy elision 并不总是有效，特别 nrvo 的场景。  

比如这样，编译器也做不出优化，编译器版本是： g++ (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0，默认采用的 c++ 版本是 `#define __cplusplus 201703L`。  

```cpp
#include <iostream>

struct A {
    int x;
    A(int _x) : x(_x) { std::cout << "A() " << _x << std::endl; }
    A(const A& other) : x(other.x) { std::cout << "A(A&) " << other.x << std::endl; }
    A(A&& other) : x(other.x) { std::cout << "A(A&&) " << other.x << std::endl; }
    ~A() { std::cout << "~A() " << x << std::endl; }
};

A f(int x) {
    A a(x);
    if (x == 0)
        return A(0);
    else if (x == 1)
        return A(1);
    else {
        return a;
    }
}

int main() {
    A a = f(300);
    return 0;
}
```

输出： 

```
A() 300
A(A&&) 300
~A() 300
~A() 300
```

---

# 4. 拓展阅读  

[《Copy/move elision: C++ 17 vs C++ 11》](https://zhuanlan.zhihu.com/p/379566824)     

[《理解C++编译器中的 Copy elision 和 RVO 优化》](https://zhuanlan.zhihu.com/p/703789055)    

---

# 5. 参考

[1] jiannanya​. 理解C++编译器中的 Copy elision 和 RVO 优化. Available at https://zhuanlan.zhihu.com/p/703789055, 2024-6-17.  