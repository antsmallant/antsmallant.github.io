---
layout: post
title: "操作系统笔记一：常识、用法"
date: 2018-03-15
last_modified_at: 2024-04-01
categories: [操作系统]
tags: [操作系统]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录操作系统相关的常识。    

---

# 1. 常识

---

## 1.1 cache 与 buffer

以下参考自：[《Cache 和 Buffer 都是缓存，主要区别是什么？》](https://www.zhihu.com/question/26190832/answer/32387918) [1]。  

cache 用于处理系统两端的速度不匹配，比如 cpu 和 memory 的速度差距越来越大，所以就利用局部性原理，通过 memory hierarchy （分级存储）的策略减少这种差距造成的影响。   

buffer 用于处理系统两端的速度不平衡，减少短时间内突发 I/O 的影响，起到流量整型的作用。   

---

# 2. 参考  

[1] Quokka. Cache 和 Buffer 都是缓存，主要区别是什么. Available at https://www.zhihu.com/question/26190832/answer/32387918. 2017-02-15.   