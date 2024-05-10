---
layout: post
title: "现代 C++"
date: 2024-04-15
last_modified_at: 2024-04-15
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

关于现代 C++ 的书和文章遍地都是，但无论如何，每个人都应该自己归纳总结一下，故有此文。  

所谓现代 C++，指的是从 C++11 开始的 C++，从 C++11 开始，加入一些比较现代的语言特性和改进了的库实现，使得用 C++ 开发少了很多心智负担，程序也更加健壮，“看起来像一门新语言”。    

从 C++11 开始，每 3 年发布一个新版本，到今年（2024）已经有 5 个版本了，分别是 C++11、C++14、C++17、C++20、C++23，这 5 个版本引入了上百个新的语言特性和新的标准库特性。       

---

# 若干重要概念与坑
可能有多年 c++ 编程经验，但回过头来发现，对于一些基础概念却并不怎么熟悉，比如表达式、语句这些。   

## 类型转换
TODO

参考：https://weread.qq.com/web/reader/55f32d30813ab6ea1g017832k3c5327902153c59dc0488e1?


## 列表初始化
是 c++11 引入的一种新的初始化方式，使用花括号 {} 来初始化变量，其目的是为了实现一种通用的初始化方式。   

这两个语句 `int c = {100};`，`int c {100};` 在多数时候被编译器同等处理。 

这种初始化形式的一个重要特点：当初始值存在丢失信息的风险时，编译器会报错，比如用 double 初始化 int 变量：`int c {200.45};`。  

---

## copy elision, RVO, NRVO
这是一种编译器优化

参考：编译器优化之 Copy Elison、RVO

## 智能指针
指针太危险了，要写出安全的代码，我们必须花时间好好总结一下，有哪些特性可以帮助我们规避指针的危险。  

---

## const vs constexpr

const 在各个位置的意义？
成员函数末尾的 const
开头的 const

为何 constexpr 重要？ 

---

## 模板

---

## noexcept

---

# 常用优化手段

## Pimpl
Pimpl 惯用法通过降低类的客户和类实现者之间的依赖性，减少了构建的遍数。[2]  

## 减少临时对象
这是一个比较庞大的话题，前面介绍过的右值引用，移动语义，其目的都是为了减少临时对象。


---

# 内存安全的代码
TODO

---

# 内存越界、内存泄漏的解决方法

一方面我们要尽可能写出内存安全的方法，另一方面我们也要有手段来解决内存问题。有时候不是我们自己写的代码有内存问题，而是一些历史遗留代码或是粗心同事的代码。   

## 洞察的方法


---

# todo
* const / constexpr
* 写一写智能指针
* 写一写thread / future / 协程 
详细阅读《modern effective c++》条款7的列表初始化



---

# 拓展阅读

* Bjarne Stroustrup 的 HOPL4 论文原文： BJARNE STROUSTRUP. Thriving in a Crowded and Changing World: C++ 2006–2020. Available at: https://www.stroustrup.com/hopl20main-p5-p-bfc9cd4--final.pdf, 2021.       

* Bjarne Stroustrup 的 HOPL4 论文中文翻译：BJARNE STROUSTRUP. 在纷繁多变的世界里茁壮成长：C++ 2006–2020. Cpp-Club. Available at: https://github.com/Cpp-Club/Cxx_HOPL4_zh, 2021.    


---

# 总结
* c++ 太复杂了，好多人因为这个原因放弃了它，但依然很多人在使用它，说明它有独特的价值。   

* 在我看来，c++ 存在的价值在于弹性：它既有原始的部分，也有高级的部分；它能比其他语言让你更靠近机器去编程，去榨干机器的性能，也能让你在高一层的抽象维度去编程，忽略机器的细节。  

* c++ 的内存、指针都是危险的，所以我们很有必要花时间归纳总结如何写出安全的代码。  

* c++ 跟其他语言一样，完成一件事有好几种写法，但有些写法效率是很高的，所以我们也有必要花时间归纳总结如何写出高效的代码。  

* 要真正掌握 c++ 的精髓，必然是要了解它的底层实现（比如看透这本书《inside the c++ object model》），要能读懂一段代码翻译成汇编是什么样子的，是怎么工作起来的，了解了这些，也就差不多了解了计算机是怎么工作的。  

* 不清楚一个特性的时候先不要使用它，否则反而坑到自己，但也不要固步自封，要积极去学习和掌握 c++ 新版本的新特性，这些都可能带来生产力的提升。   



---

# 参考

[1] 王健伟. C++新经典. 北京: 清华大学出版社, 2020-08-01.   

[2] [美]Scott Meyers. Effective Modern C++(中文版). 高博. 北京: 中国电力出版社, 2018-4: 149, 151.  

[3] [美] Stanley B. Lippman, Josée Lajoie, Barbara E. Moo. C++ Primer 中文版（第 5 版）. 王刚, 杨巨峰. 北京: 电子工业出版社, 2013-9: 120, 154, 182.   

[4] Bjarne Stroustrup. C++11：感觉像是门新语言. Cpp-Club. Available at : https://github.com/Cpp-Club/Cxx_HOPL4_zh/blob/main/04.md, 2023-6-11.    

[5] Wikipedia. C++14. Available at: https://zh.wikipedia.org/wiki/C++14.   

[6] 玩转Linux内核. 快速入门C++17：了解最新的语言特性和功能. Available at: https://zhuanlan.zhihu.com/p/664746128, 2023-11-06.    

[7] AnthonyCalandra. modern-cpp-features:CPP20. Available at: https://github.com/AnthonyCalandra/modern-cpp-features/blob/master/CPP20.md, 2023-3-19.   

[8] cppreference. C++23. Available at: https://zh.cppreference.com/w/cpp/23, 2024-3-3.   