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

悲观锁就是狭义上的锁了，根据加锁失败后的处理方式，可分为两大类型：blocking 和 spinning。   

blocking 类型的，加锁失败时，线程挂起，等待操作系统在加锁成功时将自己唤醒。互斥锁、信号量、条件变量、读写锁都属于此类型。  

spinning 类型的，加锁失败时，不挂起，会忙等待（busy waiting），不断尝试重新加锁，直到成功。自旋锁（spin lock）就属于此类型。     

<br/>  

自旋锁使用的场景主要是明确等待锁的时间会非常短，短到 cpu 空转的代价比线程切换的代价都要低很多。   

---

## 1.2 一些相关概念  

参考自：[《高并发编程--线程同步》](https://zhuanlan.zhihu.com/p/51813695) [1]。   

<br/>

* critical section   

访问共享资源的代码片段就是临界区。    


* race condition  

多个执行体（线程或进程）进入临界区，修改共享的资源的场景就叫 race condition。    


* indeterminate

多个执行体同时进入临界区操作共享资源，其执行结果是不可预料的。   


* mutual exclusive

mutex 的来源，代表一种互斥机制，用来保证只有一个线程可以进入临界区，这种情况下不会出现 race condition，并且结果是 deterministic。  

<br/>   

所以，锁的基本任务就是实现 mutual exclusive。[2]   

---

## 1.3 锁的底层实现

各种锁的底层实现基本上都是操作系统提供的某种原子操作，而操作系统也是依赖 cpu 提供的原子机制。   

这些原子操作一般是：CAS（compare and swap），TAS（test and set），CAE（compare and exchange）。这些原子操作在执行的时候只有成功和失败两种结果，保证了多个线程同时执行时，只有一个获得成功。   

---

## 1.4 blocking 类型的锁 

阻塞型的锁可以分为好几种，多个操作系统大同小异，以 linux 系统为例。包括信号量、互斥锁、条件变量、读写锁。  

---

### 1.4.1 信号量

信号量可以在多进程间使用，它是 linux 提供的一种机制。比如在使用共享内存进行 IPC 的时候，信号量可以实现对共享内存的互斥访问。  

pthread 的





---

### 1.4.2 互斥锁

mutex，或者称互斥量，是多线程最常用的锁。pthread 的 mutex 实现，支持进程内和进程间的互斥。   

**一、进程内使用互斥锁**    

进程内互斥很简单，调用 api 即可。   

pthread_mutex 的 api 大致如下：   

```c
// 初始化 mutex
// mutexattr 可以为 NULL，表示使用默认设置，大部分情况下也是这样使用的
int pthread_mutex_init(pthread_mutex_t *mutex, const pthread_mutexattr_t *mutexattr);  

// 销毁 mutex
int pthread_mutex_destroy(pthread_mutex_t *mutex);

// 获取锁，如果失败则挂起，阻塞则到成功
int pthread_mutex_lock(pthread_mutex_t *mutex);

// 释放锁
int pthread_mutex_unlock(pthread_mutex_t *mutex);

// 尝试加锁，如果失败不挂起，直接返回失败
int pthread_mutex_trylock(pthread_mutex_t *mutex);

```

有时候需要设置 mutexattr，可以使用以下的 api：  

https://zhuanlan.zhihu.com/p/653864005

```c


```

<br/>

**二、进程间使用互斥锁**    

https://www.zhihu.com/question/66733477/answer/2167257604


进程间大体实现是把 pthread_mutex 放到一块共享内存上，大家都可以访问得到。具体做法可以参考这篇文章：[《多进程共享的pthread_mutex_t》](https://blog.csdn.net/ld_long/article/details/135732039) [3]。    

大致过程如下：  



不过，这里又分两种情况，父子进程和不相干进程。   

父子进程很简单，不需要考虑谁负责创建互斥锁的问题。而不相干进程就复杂了，需要处理好谁负责创建的问题，如果任一进程都要能创建，那么这里又存在互斥的问题了，有点套娃。  

这篇文章 [《用pthread进行进程间同步》](https://www.cnblogs.com/my_life/articles/4538461.html) [4] 介绍了一种不相干进程间互斥的创建互斥锁的做法。大意是利用 link 这个系统调用，原子的把 shm_open 创建出来的共享内存 link 到 `/dev/shm` 中。  

link 系统调用是 linux 原子操作文件的最底层指令，可以保证原子，并且处于 link 操作的进程被中途 kill 掉，linux 内核也会保证完成这次调用。 关键代码：  

```c

```





---

## 1.5 spinning 类型的锁

spinning 类型的只有 spin lock 了。  

---

### 1.5.1 自旋锁


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

[3] ?-ldl. 多进程共享的pthread_mutex_t. Available at https://blog.csdn.net/ld_long/article/details/135732039, 2024-1-21.     

[4] bw_0927. 用pthread进行进程间同步. Available at https://www.cnblogs.com/my_life/articles/4538461.html, 2015-5-29.  