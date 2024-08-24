---
layout: post
title: "c++ 笔记：memory order"
date: 2023-04-02
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

本文记录 c++ memory order 相关的要点。  

---

# 术语

Cache Coherence：缓存一致性。    

CC 保证对单个地址读写的正确性，SC 保证对多个地址读写的正确性。    

---

# 拓展阅读

* [《Furion W 如何理解 C++11 的六种 memory order？》](https://www.zhihu.com/question/24301047/answer/83422523)       

* [《文礼 如何理解 C++11 的六种 memory order？》](https://www.zhihu.com/question/24301047/answer/1193956492)     

* [《高并发编程--多处理器编程中的一致性问题(上)》](https://zhuanlan.zhihu.com/p/48157076)     

* [《高并发编程--多处理器编程中的一致性问题(下)》](https://zhuanlan.zhihu.com/p/48161056)   

* [《深入理解volatile》（比较仔细的讲了 MESI) ](https://zhuanlan.zhihu.com/p/397640787)      

* [《为什么程序员需要关心顺序一致性（Sequential Consistency）而不是Cache一致性（Cache Coherence？）》](https://www.parallellabs.com/2010/03/06/why-should-programmer-care-about-sequential-consistency-rather-than-cache-coherence/)

* [Memory Model and Synchronization Primitive - Part 1: Memory Barrier](https://www.alibabacloud.com/blog/memory-model-and-synchronization-primitive---part-1-memory-barrier_597460)

* [Memory Model and Synchronization Primitive - Part 2: Memory Model](https://www.alibabacloud.com/blog/memory-model-and-synchronization-primitive---part-2-memory-model_597461)

* [C++ and Beyond 2012: Herb Sutter - atomic Weapons 1 of 2](https://www.youtube.com/watch?v=A8eCGOqgvH4&t=620s)

* [Compiler reordering](https://bajamircea.github.io/coding/cpp/2019/10/23/compiler-reordering.html)

* [CPU流水线与指令重排序](https://cloud.tencent.com/developer/article/2195759)

* [Memory ordering](https://en.wikipedia.org/wiki/Memory_ordering)

* [大白话C++之：一文搞懂C++多线程内存模型(Memory Order)](https://blog.csdn.net/sinat_38293503/article/details/134612152)  

* [What exactly is std::atomic?](https://stackoverflow.com/questions/31978324/what-exactly-is-stdatomic)   

* [C++ and the Perils of Double-Checked Locking](https://www.aristeia.com/Papers/DDJ_Jul_Aug_2004_revised.pdf)   

* [http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2007/n2427.html#DiscussOrder](http://www.open-std.org/jtc1/sc22/wg21/docs/papers/2007/n2427.html#DiscussOrder)

---

# 参考