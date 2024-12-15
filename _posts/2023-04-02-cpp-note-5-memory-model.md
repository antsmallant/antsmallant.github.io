---
layout: post
title: "C++ 笔记：Memory Model"
date: 2023-04-02
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

本文记录 Memory Model 相关的要点。这一块的内容挺复杂的，它有两个层面上的定义：编程语言和计算机体系结构，要搞清楚并不容易。   

对于理解复杂事物或概念，我的经验是，尽量找权威的、体系化论述的材料来看，不要随便找到一些博客文章就开始研究，它们只能作为索引，帮你找到真正权威的材料。很多博客文章的作者其实没有理解到位或理解全面，往往只会误导人，或者使概念更难以理解。  

权威的材料有时候也未必靠谱，比如 《C++ 并发编程实战（第2版）》这本书，挺不错的，但第 5 章里面关于 memory order 的论述，很不好理解，越看越头大。  

尽管如此，还是要以权威材料为主去研究。  

**TODO：本文还没写完。**

---

# Memory Model 

---

## 概述

时间充裕的情况，可以读这本书：《C++ 并发编程实战（第2版）》。时间不充裕，可以读 Russ Cox 的这两篇文章，建立起基本的概念。  

而 《C++ 并发编程实战（第2版）》的第 5 章中关于 C++ memory order 的内容，是我见过最糟糕的论述了。这本书的其他内容尚可，但这一章太糟糕了，完全没有讲清楚，很让人费解。   



---

## 概念与作用

Memory Model，实际上应该是 Memory Consistency Model，即内存连贯性模型。它描述了使用共享内存 (shared memory) 执行多线程程序所需要的规范，定义了在并发环境下，程序的内存操作如何被序列化和执行的规则。   

Russ Cox 在 [《Programming Language Memory Models》](https://research.swtch.com/plmm) 写道："Programming language memory model answers the question of what behaviors parrallel programs can rely on to share memory between their threads" 。   

而 wikipedia 上 [《Memory Model(programming)》](https://en.wikipedia.org/wiki/Memory_model_(programming)) 词条的描述是 "In computing, a memory model describes the interactions of threads through memory and their shared use of the data"。   

---

## 为什么要引入 Memory Model ？  

使用操作系统提供的同步原语就可以基于共享内存进行多线程编程了，为什么还需要 Memory Model？   

简单来说，是为了使用无锁编程以提高多线程编程的性能。  

操作系统提供的同步原语（互斥锁、条件变量之类），其消耗往往很大，当涉及到内核态与用户态的切换时，耗时往往是毫秒级的。而无锁编程的核心是原子操作，原子操作可以粗糙的理解为 cpu 指令级别实现的 "锁"，除了内存栅栏（fence）带来的流水线损失之外，几乎没有额外消耗。    

无锁编程并不能完全代替基于普通同步原语的多线程编程，但是基于原子操作的一些特性，经过精心设计，可以实现出一些高性能的无锁数据结构，这种数据结构可以在性能攸关的场景下发挥重要作用。   

要定义清楚原子操作，就必须先定义清楚 Memory Model。至于 C++ 里面的六种 memory order，其实都属于整个 C++ Memory Model 规范的一部分。    

必须指出的是，无锁编程特别难，很容易就写成 busy wait 的逻辑，反而性能更糟糕。所以一般人并不需要折腾无锁编程。    

---

# 术语

原子操作：不可分割的操作，在系统的任一线程内，都不会观察到这种操作处于半完成状态，它或者完全做好，或者完全没做。     

原子操作不能天然的使操作强制服从预定次序，它不能预防数据竞争本身，但它可以在发生数据竞争的时候，避免未定义行为。   

并发，两个或多个同时独立进行的活动。[3]      

并行和并发有很大程度的重叠，都是指使用可调配的硬件资源同时运行多个任务，但并行更强调性能。谈到并行时，主要关心是利用可调配的资源提升大规模数据处理的性能；当谈及并发时，主要关心的是分离关注点或响应能力。[3]     

C++ 多线程特性的意义：以标准化形式借助多线程支持并发。  

---

# memory model 的分类

参考：[《一文读懂Memory consistency model (内存模型)》](https://blog.csdn.net/W1Z1Q/article/details/137478525)      

* Memory model
    * Strong model
        * SC
        * TSO
        * RVTSO
        * zTSO
    * Relaxed model
        * RVVMO
        * Power Memory Model
        * RMO
        * Alpha
        * Other-multi-copy-atomic

---

# C++ 的几种 memory order 组合 

虽然内存次序有 6 种，但归类起来只有 3 种模式 [3]：   
1. 先后一致次序： memory_order_seq_cst     
2. 获取-释放次序：memory_order_release、memory_order_acquire、memory_order_consume    
3. 宽松次序：memory_order_relaxed    

具体的组合，可以有 4 种（ 参考：[《原子操作 线程通信- Linux系统编程-(pthread)》](https://blog.csdn.net/u012294613/article/details/126485586) ）：   

1、memory_order_relaxed    

宽松操作，没有同步或顺序    

<br/>

2、memory_order_release & memory_order_acquire   

两个线程 A与B，A release 后，B acquire 保证一定读到的是最新被修改过的值，并且，保证发生在 A release 前的所有写操作，在 B acquire 后都能读到最新值。   

<br/>

3、memory_order_release & memory_order_consume    

相较于 "memory_order_release & memory_order_acquire" 有所放松，只确保指定的对象在 A release 前，B acquire 之后读到最新值，不确保 A release 前的所有写操作对象。   

C++17 标准暂时不鼓励使用 memory_order_consume: "The specification of release-consume ordering is being revised, and the use of memory_order_consume is temporarily descouraged."[4]。    

<br/>

4、memory_order_seq_cst    

顺序一致性模型，相当于对每个变量都进行 release-acquire 操作。   

<br/>

---

# 问题引入

简单的理解，atomic 是在 cpu 指令级实现的"锁"，除了内存栅栏带来的流水线效率损失外，几乎没有额外开销。而 mutex 这种级别的锁，单单是内核调用，睡眠和唤醒，就已经是毫秒级的了。    

可使用原子库替代互斥库实现线程同步。    

无锁编程是基于原子操作的。   

基于 atomic，可以用乐观锁的方式来实现一些数据结构，比如这个： [《C++使用std::atomic实现并发无锁同步》](https://blog.yanjingang.com/?p=6687)。   

---

# futex

futex 的性能是否与 atomic 相当？  

[《flaneur - 为什么atomic比mutex性能更高？》](https://www.zhihu.com/question/302472384/answer/719726236)   
 
>atomic 做的事情：原子指令修改内存，内存栅栏保障修改可见，必要时锁总线。    
>mutex 大致做的事情：      
>短暂原子 compare and set 自旋如果未成功上锁，futex(&lock, FUTEX_WAIT... ) 退避进入阻塞等待直到 lock 值变化时唤醒。futex 在设计上期望做到如果无争用，则可以不进内核态，不进内核态的 fast path 的开销等价于 atomic 判断。    
>内核里维护按地址维护一张 wait queue 的哈希表，发现锁变量值的变化（解锁）时，唤醒对应的 wait queue 中的一个 task。wait queue 这个哈希表的槽在更新时也会遭遇争用，这时继续通过 spin lock 保护。     



---

# 拓展阅读

* [Shared Memory Consistency Models: A Tutorial](https://rsim.cs.illinois.edu/arch/qual_papers/arch/adve_shared.pdf)   

* [A Primer on Memory Consistency and Cache Coherence Second Edition](https://pages.cs.wisc.edu/~markhill/papers/primer2020_2nd_edition.pdf)

对应的中文翻译：[https://github.com/kaitoukito/A-Primer-on-Memory-Consistency-and-Cache-Coherence](https://github.com/kaitoukito/A-Primer-on-Memory-Consistency-and-Cache-Coherence)

* [A Tutorial Introduction to the ARM and POWER Relaxed Memory Models](https://www.cl.cam.ac.uk/~pes20/ppc-supplemental/test7.pdf)

* [Russ Cox - Hardware Memory Models (Memory Models, Part 1)](https://research.swtch.com/hwmm)

* [Russ Cox - Programming Language Memory Models(Memory Models, Part 2)](https://research.swtch.com/plmm)

* [Russ Cox - Updating the Go Memory Model (Memory Models, Part 3)](https://research.swtch.com/gomm)

* 《计算机体系结构：量化研究方法（第6版）》第 5 章

---

# 参考

[1] [美]John L. Hennessy, David A. Patterson. 计算机体系结构：量化研究方法（第5版）. 贾洪峰. 北京:人民邮件出版社, 2013-1(1):263.      

[2] Furion W. 如何理解 C++11 的六种 memory order. Available at https://www.zhihu.com/question/24301047/answer/83422523, 2016-2-11.   

[3] [英] Anthony Williams. C++ 并发编程实战（第2版）. 吴天明. 北京: 人民邮电出版社, 2021-12(2).   

[4] cppreference. memory_order. Available at https://en.cppreference.com/w/cpp/atomic/memory_order.    