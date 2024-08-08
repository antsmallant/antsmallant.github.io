---
layout: post
title: "c++ 笔记五：memory order"
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

[《Furion W 如何理解 C++11 的六种 memory order？》](https://www.zhihu.com/question/24301047/answer/83422523)       

[《文礼 如何理解 C++11 的六种 memory order？》](https://www.zhihu.com/question/24301047/answer/1193956492)     

[《高并发编程--多处理器编程中的一致性问题(上)》](https://zhuanlan.zhihu.com/p/48157076)     

[《高并发编程--多处理器编程中的一致性问题(下)》](https://zhuanlan.zhihu.com/p/48161056)   

[《深入理解volatile》（比较仔细的讲了 MESI) ](https://zhuanlan.zhihu.com/p/397640787)      

[《为什么程序员需要关心顺序一致性（Sequential Consistency）而不是Cache一致性（Cache Coherence？）》](https://www.parallellabs.com/2010/03/06/why-should-programmer-care-about-sequential-consistency-rather-than-cache-coherence/)

---

# 参考