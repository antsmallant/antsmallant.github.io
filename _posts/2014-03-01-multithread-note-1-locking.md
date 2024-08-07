---
layout: post
title: "多线程笔记一：锁"
date: 2014-03-01
last_modified_at: 2024-04-01
categories: [并发与多线程]
tags: [并发 同步 多线程]
---

* 目录  
{:toc}
<br/>

记录多线程中锁相关的常识。  

---

# 1. 锁 

---

## 1.1 锁的分类

整体上可以分为悲观锁与乐观锁，悲观锁假定冲突很频繁，在访问前必须先加上锁，乐观锁假定冲突概率很低，可以先访问，等出现冲突了再做处理。  

严格来说，乐观锁并不是传统意义上的锁，它只是利用了比如版本号的机制，可以在冲突出现的时候识别出来并做相应的处理，算是一种“无锁编程”。    

<br/>

悲观锁就是狭义上的锁了，根据加锁失败后的处理方式，可分为两大类型：阻塞型的锁（blocking）锁和自旋锁（spin lock）。  

阻塞型的锁，加锁失败时，线程挂起，等待操作系统在加锁成功时将自己唤醒。  

自旋锁，加锁失败时，不挂起，会忙等待，不断尝试重新加锁，直到成功。   

<br/>  

自旋锁使用的场景主要是明确等待锁的时间会非常短，短到 cpu 空转的代价比线程切换的代价都要低很多。   

---

## 1.2 一些相关概念  

参考自：[《高并发编程--线程同步》](https://zhuanlan.zhihu.com/p/51813695) [1]。   

**critical section**   

访问共享资源的代码片段就是临界区。    


**race condition**   

多个执行体（线程或进程）进入临界区，修改共享的资源的场景就叫 race condition。    


**indeterminate**    

多个执行体同时进入临界区操作共享资源，其执行结果是不可预料的。   


**mutual exclusive**    

mutex 的来源，代表一种互斥机制，用来保证只有一个线程可以进入临界区，这种情况下不会出现 race condition，并且结果是 deterministic。  

<br/>   

所以，锁的基本任务就是实现 mutual exclusive。[2]   

---

## 1.3 锁的底层实现

各种锁的底层实现基本上都是操作系统提供的某种原子操作，而操作系统也是依赖 cpu 提供的原子机制。   

这些原子操作一般是：CAS（compare and swap），TAS（test and set），CAE（compare and exchange）。这些原子操作在执行的时候只有成功和失败两种结果，保证了多个线程同时执行时，只有一个获得成功。   

---

## 1.4 阻塞型的锁 

阻塞型的锁可以分为好几类，在 c++ 中，有：  


---

## 1.5 自旋锁

pthread 提供的 spin lock 的 api 包括如下：  

```c

// 初始化锁，pshared 有两个选项：
// PTHREAD_PROCESS_PRIVATE 只允许同进程内使用此锁；
// PTHREAD_PROCESS_SHARE 允许多进程使用此锁；  
int pthread_spin_init(pthread_spinlock_t *lock, int pshared); 
                                                              
// 销毁锁        
int pthread_spin_destroy(pthread_spinlock_t *lock); 

// 加锁，如果失败，则自旋直到成功
int pthread_spin_lock(pthread_spinlock_t *lock);    

// 尝试加锁，成功或失败都立即返回，根据返回值判断结果  
int pthread_spin_trylock(pthread_spinlock_t *lock); 

// 释放锁
int pthread_spin_unlock(pthread_spinlock_t *lock);  
```

---

# 2. 死锁

---

## 2.1 产生死锁的原因


---

## 2.2 避免死锁 



---

# 3. 参考

[1] 三四. 高并发编程--线程同步. Available at https://zhuanlan.zhihu.com/p/51813695, 2019-01-04.    

[2] Arpaci Dusseau. Operating-Systems: Three-Easy-Pieces. Available at https://pages.cs.wisc.edu/~remzi/OSTEP/threads-locks.pdf.   