---
layout: post
title: "现代 c++ 五：指针与内存泄漏"
date: 2024-04-05
last_modified_at: 2024-04-05
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

**还没写完 ...**   


---

本文是一篇总结文章，内容包括：1、现代 c++ 应该怎么合理的使用指针；2、发生内存泄漏如何定位。  

都是一些比较 basic 的常识，如有错误，请指出，谢谢。  

---

# 1. 智能指针

c++11 中共有四种智能指针，std::auto_ptr, std::unique_ptr, std::shared_ptr, std::weak_ptr。    

std::auto_ptr 是 c++98 时代的产物，其他几个都是 c++11 新引入的。  

---

## 1.1 std::auto_ptr

std::auto_ptr 是 c++98 残留的特性，在 c++11 被弃用 (deprecated ) 了，在 c++17 被移除了[1] 。  

可以使用 c++11 新引入的 std::unique_ptr 代替 std::auto_ptr。  

---

## 1.2 std::unique_ptr   

它用于管理具备专属所有权的资源，意思是 std::unique_ptr 独享它指向的对象，不允许多个 std::unique_ptr 指向同个资源。   

在条件合适的场景下，智能指针首选 std::unique_ptr，原因是它开销小，不像 std::shared_ptr 那样需要原子的维护引用计数。std::unique_ptr 的开销几乎与裸指针相当，在离开作用域的时候能自动释放内存，避免内存泄漏，所以能用 std::unique_ptr 就尽量使用。  

---

### 1.2.1 构造和移动   

std::unique_ptr 的构造往往是伴随着资源占有权的转移的，所以放在一起讲。  

std::unique_ptr 是不允许复制的，像这样复制是不行的： 

```cpp
std::unique_ptr<int> p1 = std::make_unique<int>(10);
std::unique_ptr<int> p2 = p1;  // 不行的，禁止这样做
```

<br/>

**单纯的构造**   

如果单纯的创建资源并占有资源，有两种方式：  

1、使用 make_unique
```cpp
auto p1 = std::make_unique<int>(10);
```

2、使用 new

```cpp
std::unique_ptr<int> p1(new int(10));
```

<br/>

**移动**    

虽然不能复制，但可以被移动，有好几种移动方式。   

1、用 release 释放控制并返回裸指针     
```cpp
    auto p1 = std::make_unique<int>(10);
    auto p2(p1.release());   
```

2、用 std::move 触发移动构造或移动拷贝     
```cpp
    auto p1 = std::make_unique<int>(10);
    auto p2(std::move(p1));  // 触发移动构造
    // auto p2 = std::move(p1); // 也可以这样触发移动拷贝
```

3、用 release 释放控制，后者用 reset 重置      
```cpp
    auto p1 = std::make_unique<int>(10);
    std::unique_ptr<int> p2;
    p2.reset(p1.release());
```

---

### 1.2.2 销毁和释放

**销毁的方式**    
 
1、直接置空，这种情况下，会直接销毁资源。    
```cpp
auto p1 = std::make_unique<int>(10);
p1 = nullptr;
```

2、调用 reset，这种情况下，会直接销毁资源。        
```cpp
auto p1 = std::make_unique<int>(10);
p1.reset();
```

**释放的方式**    

1、调用 release，这种情况下，不是销毁资源，是放弃占有资源，返回一个裸指针。 
这种要特别注意了，应该是结合资源转移来使用，而不是把 release 当成销毁资源的方式。         
```cpp
auto p1 = std::make_unique<int>(10);
auto rawptr = p1.release();
```

---

### 1.2.3 使用场景

**作为参数**   

多数情况下，函数传参并不涉及所有权管理，所以并不太需要使用 std::unique_ptr 来作为参数，使用引用或者裸指针会更合理一些。  


但也有些情况下是可以使用的，比如生产和消费的场景。  


---

## 1.3 std::shared_ptr

**注意事项** 

1、优先使用 std::make_shared，而非直接使用 new   

2、不要用裸指针初始化多个 shared_ptr   
比如这样：  

```cpp
    auto sp = new std::string{"abc"};
    std::shared_ptr<std::string> a {sp};
    std::shared_ptr<std::string> b {sp};  // not ok, do not do this
```  

3、容器中的 shared_ptr 要及时 erase   
这个挺容易漏掉的，如果没有及时 erase，就会一直引用着，不会释放。    


---

## 1.4 std::weak_ptr

---

# 2. 指针的原则

这一部分属于个人观点，不代表共识。  

---

## 2.1 引用、裸指针、智能指针的使用时机

智能指针的核心是所有权管理，无关所有权的时候首选引用或裸指针，在需要所有权管理的时候使用智能指针。  

---

## 2.2 作为参数的时候

传参在大部分情况下与所有权管理无关，所以应该首选引用或者裸指针，这样更灵活。  

---

## 2.3 什么时候使用引用、裸指针、智能指针

少用裸指针，智能指针几乎可以做到裸指针能做到的任何事情，但犯错的机会大大减少了。    

---

## 2.4 优先使用 `make_` 函数初始化智能指针

以上例子刻意用 std::make_unique 来构造 p1，而不是像这样：   
```cpp
std::unique_ptr<int> p1(new int(10));
```

因为 std::make_unique 是一种更佳的初始化方式，原因有二，以下原因同时适用于 std::make_unique 和 std::make_shared [3]：   

1、使用 new 版本的，需要把类型写两次，比如上面就写了两次 int。  

2、避免潜在的内存泄漏，《Effective Modern C++》[3] 里举了一个例子，类似这样的一种调用，`process(std::shared_ptr<Widget>(new Widget), compute());`，如果编译器生成出来的操作时序是：  
a） 实施 new Widget    
b） 执行 compute    
c） 运行 std::shared_ptr 构造函数     

如果 compute 执行异常，那么 new 出来的 Widget 也就内存泄漏了。  

第 2 点归结起来就是说，函数的参数求值允许交错，如果在 new 和构造 unique_ptr 之间插入了另一个参数的求值，并且这个参数的求值过程抛异常了，那么 new 出来的东西就内存泄漏了。 

<br/>

make 系列函数还包括 std::allocate_shared，它与 std::make_shared 类似，只不过它的第一个实参是个动态内存分配器 [3]。 

btw，std::make_unique 是在 c++14 才被引入的，c++11 时只有 std::make_shared。 

---

# 3. 内存泄漏的检测

以下列举一些定位内存泄漏的方法和工具。   

---

## 3.1 静态计数    

这篇文章 [《C++极简内存泄露检测工具（34行代码实现）》](https://zhuanlan.zhihu.com/p/663858656) [2] 介绍的这种静态方法很简单，虽然只适用于类类型，但已经足够用于很多场景了。  

它的原理很简单，给类增加一个静态成员，这个成员在类构造的时候增加计数，类析构的时候减少计数，最后如果计数不为 0，则说明使用这个类的地方发生内存泄漏了。  

优点是：1、可靠；2、很简单，只包含一个头文件就够了。缺点是：1、侵入式的；2、只适用于类类型，不能用于基础类型；3、只适用于开发（或测试）环境，不能用于生产环境。第 3 点也不能算缺点吧，平常也都是在测试环境跑代码来定位泄漏的。    

这里摘抄一下头文件[2]，免得作者回头把文章删除了。    

```cpp
#ifndef MEMORY_LEAK_CHECKER_H
#define MEMORY_LEAK_CHECKER_H
 
//memory checke library begin
#include <assert.h>
#include <iostream>
#include <atomic>
#include <string>
class object_usage_counter {
public:
    object_usage_counter(const char* name) :m_name(name), m_counter(0) {};
    ~object_usage_counter() { std::cout << "class " << m_name << " memory leak num = " << m_counter << std::endl; };
    void inc() { ++m_counter; }
    void dec() { --m_counter;	assert(m_counter >= 0); }
private:
    std::atomic<long long> m_counter;
    std::string m_name;
};
template<typename T>
class counter_by_copy {
public:
    counter_by_copy() { m_the_only_object_for_one_class.inc(); }
    ~counter_by_copy() { m_the_only_object_for_one_class.dec(); }
    counter_by_copy(const counter_by_copy&) { m_the_only_object_for_one_class.inc(); }
private:
    //the only object to count usage.
    static object_usage_counter m_the_only_object_for_one_class;
};
//TIPS:template class's static member object can be define at the .h file
template<typename T>
object_usage_counter counter_by_copy<T>::m_the_only_object_for_one_class(typeid(T).name());
//memory checke library end
 
#endif // !MEMORY_LEAK_CHECKER_H
 
 
//example usage
/*
class A
{
public:
    //A's copy control member functions call counter increasing or decreasing usage.
    counter_by_copy<A> m_checker;
};
*/
```

---

## 3.2 A Cross-Platform Memory Leak Detector

[A Cross-Platform Memory Leak Detector](http://wyw.dcweb.cn/leakage.htm)

---

# 4. 材料

* [unique_ptr作为函数参数时，应该以值还是右值引用类型传递？](https://www.zhihu.com/question/534389744/answer/2500052393)

* [C++ 原始指针、shared_ptr、unique_ptr分别在什么场景下使用？](https://www.zhihu.com/question/648170767/answer/3428590625)

* [GotW #91 Solution: Smart Pointer Parameters](https://herbsutter.com/2013/06/05/gotw-91-solution-smart-pointer-parameters/)


---

# 5. 参考

[1] cppreference. auto_ptr. Available at https://en.cppreference.com/w/cpp/memory/auto_ptr.   

[2] Carea​. C++极简内存泄露检测工具（34行代码实现）. Available at https://zhuanlan.zhihu.com/p/663858656, 2023-10-28.     

[3] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4: 134.  