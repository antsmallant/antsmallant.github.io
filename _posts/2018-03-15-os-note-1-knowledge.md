---
layout: post
title: "操作系统笔记一：常识"
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

## 1.2 XSI

XSI 是 X/Open 组织对 unix 接口定义的一套标准 (X/OPEN System Interface)。   

但目前使用得比较多的是 POSIX（Portable Operating System Interface），它并不局限于 Unix，其他的一些操作系统也支持 Posix，包括 Windows，Dec。  

另外还有一个 SUS，即 Single UNIX Specification，它相当于 POSIX 的超集，定义了一些额外附加的接口。   

---

## 1.3 linux 下的共享内存

创建共享内存有几种方式。  

参考： 
[两种Linux共享内存](https://blog.jqian.net/post/linux-shm.html)      
[Linux: shm_xx系列函数使用详解](https://blog.csdn.net/weixin_45842280/article/details/136384000)    
[shmget和shm_open的区别，分别写一个示例代码](https://www.5axxw.com/questions/simple/o2t5lg)    
[C语言之共享内存之shmget进程间通信(二十三)](https://blog.csdn.net/u010164190/article/details/120401169)    

---

### 1.3.1 mmap   
 

---

### 1.3.2 shmget    

---

### 1.3.3 shm_open

---

### 1.3.4 shmget 与 shm_open 的区别  


---

# 2. 参考  

[1] Quokka. Cache 和 Buffer 都是缓存，主要区别是什么. Available at https://www.zhihu.com/question/26190832/answer/32387918, 2017-02-15.   
