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

---

# 内存一致性 (memory coherence) 和内存连贯性 (memory consistency)

## 缓存连贯性问题（cache coherence problem）


---

# 内存一致性模型 (memory consistency model)

本质上，内存一致性模型限制了读操作的返回值。  

---

## 分类

内存一致性模型可以分为两类： 

1. 顺序一致性模型 (sequential consistency model)    
2. 松弛一致性模型 (relaxed consistency model)    

--- 







---

# MESI


---

# 拓展阅读

* 《计算机体系结构：量化研究方法（第6版）》第5章

* 《c++ 并发编程实战（第2版）》第5章

---

# 论文

* [Shared Memory Consistency Models:A Tutorial](https://rsim.cs.illinois.edu/arch/qual_papers/arch/adve_shared.pdf)   

---

# 参考

[1] [美]John L. Hennessy, David A. Patterson. 计算机体系结构：量化研究方法（第5版）. 贾洪峰. 北京:人民邮件出版社, 2013-1(1):263.      

[2] Furion W. 如何理解 C++11 的六种 memory order. Available at https://www.zhihu.com/question/24301047/answer/83422523, 2016-2-11.   