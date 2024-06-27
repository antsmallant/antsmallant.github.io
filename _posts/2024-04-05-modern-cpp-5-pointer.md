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

---

本文是一篇总结文章，内容包括：1、现代 c++ 应该怎么合理的使用指针；2、发生内存泄漏如何定位。  

都是一些比较 basic 的常识，如有错误，请指出，谢谢。  

---

# 指针的原则

* 优先使用智能指针，少用裸指针，智能指针几乎可以做到裸指针能做到的任何事情，但犯错的机会大大减少了。    

---

# 智能指针

c++11 中共有四种智能指针，std::auto_ptr, std::unique_ptr, std::shared_ptr, std::weak_ptr。std::auto_ptr 是 c++98 时代的产物，其他几个都是 c++11 新引入的。  

---

## std::auto_ptr

std::auto_ptr 是 c++98 残留的特性，在 c++11 被弃用 (deprecated ) 了，在 c++17 被移除了[1] 。  

可以使用 c++11 新引入的 std::unique_ptr 代替 std::auto_ptr。  

---

## std::unique_ptr   

用智能指针时，首选 std::unique_ptr，

---

## std::shared_ptr

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

4、

---

# 内存泄漏

以下列举一些定位内存泄漏的方法和工具。   

---

## 静态计数    

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

## A Cross-Platform Memory Leak Detector

[A Cross-Platform Memory Leak Detector](http://wyw.dcweb.cn/leakage.htm)


---

## valgrind





---

# 参考

[1] cppreference. auto_ptr. Available at https://en.cppreference.com/w/cpp/memory/auto_ptr.   

[2] Carea​. C++极简内存泄露检测工具（34行代码实现）. Available at https://zhuanlan.zhihu.com/p/663858656, 2023-10-28.   