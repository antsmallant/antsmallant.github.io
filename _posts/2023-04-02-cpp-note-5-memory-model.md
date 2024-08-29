---
layout: post
title: "c++ 笔记：memory model"
date: 2023-04-02
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

本文记录 c++ memory model 相关的要点。  

---

# 什么是 memory model，它的作用是什么？  

Russ Cox 在 [《Programming Language Memory Models》](https://research.swtch.com/plmm) 写道："Programming language memory model answers the question of what behaviors parrallel programs can rely on to share memory between their threads" 。   

而 wikipedia 上 [《Memory Model(programming)》](https://en.wikipedia.org/wiki/Memory_model_(programming)) 词条的描述是 "In computing, a memory model describes the interactions of threads through memory and their shared use of the data"。   

简单的说，内存模型描述了使用共享内存 (shared memory) 执行多线程程序所需要的规范。   

原子操作：不可分割的操作，在系统的任一线程内，都不会观察到这种操作处于半完成状态，它或者完全做好，或者完全没做。    

原子操作不能天然的使操作强制服从预定次序，它不能预防数据竞争本身，但它可以在发生数据竞争的时候，避免未定义行为。   

并发，两个或多个同时独立进行的活动。[3]      

并行和并发有很大程度的重叠，都是指使用可调配的硬件资源同时运行多个任务，但并行更强调性能。谈到并行时，主要关心是利用可调配的资源提升大规模数据处理的性能；当谈及并发时，主要关心的是分离关注点或响应能力。[3]     

c++ 多线程特性的意义：以标准化形式借助多线程支持并发。  

---

# 几种 memory model

## Sequential Consistency 

## Total Store Order

---

# 无锁编程可以完全替代锁吗？可以支持哪些逻辑范式？  

---

# 术语

谈论存储的时候，在《计算机体系结构：量化研究方法（第5版）》[1] 这本书的 5.2.1 节，Coherence 译作一致性，而 Consistency 译作连贯性。  

* Cache Coherence：缓存一致性。    

* Coherence： 一致性，它确定了读取操作可能返回什么值。[1]    

* Consistency: 连贯性，它确定了一个写入值什么时候被读取操作返回。[1]     

而 Sequential Consistency 译作顺序连贯性，但也有人译作顺序一致性。     

Cache Coherence 保证对单个地址读写的正确性，Sequential Consistency 保证对多个地址读写的正确性。    

---

# 问题引入

简单的理解，atomic 是在 cpu 指令级实现的"锁"，除了内存栅栏带来的流水线效率损失外，几乎没有额外开销。而 mutex 这种级别的锁，单单是内核调用，睡眠和唤醒，就已经是毫秒级的了。    

可使用原子库替代互斥库实现线程同步。    

无锁编程是基于原子操作的。   

基于 atomic，可以用乐观锁的方式来实现一些数据结构，比如这个： [《C++使用std::atomic实现并发无锁同步》](https://blog.yanjingang.com/?p=6687)。   

---

# 内存一致性模型 (memory consistency model)

本质上，内存一致性模型限制了读操作的返回值。  

---

## 分类

内存一致性模型可以分为两类： 

1. 顺序一致性模型 (sequential consistency model)    
2. 松弛一致性模型 (relaxed consistency model)    


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

* [Russ Cox - Hardware Memory Models (Memory Models, Part 1)](https://research.swtch.com/hwmm)

* [Russ Cox - Programming Language Memory Models(Memory Models, Part 2)](https://research.swtch.com/plmm)

* [Russ Cox - Updating the Go Memory Model (Memory Models, Part 3)](https://research.swtch.com/gomm)

* 《计算机体系结构：量化研究方法（第6版）》第5章

* 《c++ 并发编程实战（第2版）》第5章

---

# 感受与吐槽

## 《c++ 并发编程实战（第2版）》

这本书的豆瓣评分 9.4 (截至 2024-8-29)，但仔细读过之后就会发现：1、英文原版唠唠叨叨，没能简要的把问题说清楚，反而大量增加理解负担；2、中文翻译特别稀烂，经常偏离原文。总之，这本书被过誉了，它只会增加你的理解负担。不信，读一读第 5 章。   


---

# 参考

[1] [美]John L. Hennessy, David A. Patterson. 计算机体系结构：量化研究方法（第5版）. 贾洪峰. 北京:人民邮件出版社, 2013-1(1):263.      

[2] Furion W. 如何理解 C++11 的六种 memory order. Available at https://www.zhihu.com/question/24301047/answer/83422523, 2016-2-11.   

[3] [英] Anthony Williams. C++ 并发编程实战（第2版）. 吴天明. 北京: 人民邮电出版社, 2021-12(2).   