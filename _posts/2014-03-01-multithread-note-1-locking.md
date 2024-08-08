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

# 1. 资料

pthread 的官方文档：[https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/pthread.h.html](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/pthread.h.html)    



---

# 2. 锁 

---

## 2.1 锁的分类

整体上可以分为悲观锁与乐观锁，悲观锁假定冲突很频繁，在访问前必须先加上锁，乐观锁假定冲突概率很低，可以先访问，等出现冲突了再做处理。  

严格来说，乐观锁并不是传统意义上的锁，它只是利用了比如版本号的机制，可以在冲突出现的时候识别出来并做相应的处理，算是一种“无锁编程”。    

<br/>

悲观锁就是狭义上的锁了，根据加锁失败后的处理方式，可分为两大类型：blocking 和 spinning。   

blocking 类型的，加锁失败时，线程挂起，等待操作系统在加锁成功时将自己唤醒。互斥锁、信号量、条件变量、读写锁都属于此类型。  

spinning 类型的，加锁失败时，不挂起，会忙等待（busy waiting），不断尝试重新加锁，直到成功。自旋锁（spin lock）就属于此类型。     

<br/>  

自旋锁使用的场景主要是明确等待锁的时间会非常短，短到 cpu 空转的代价比线程切换的代价都要低很多。   

---

## 2.2 一些相关概念  

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

## 2.3 锁的底层实现

各种锁的底层实现基本上都是操作系统提供的某种原子操作，而操作系统也是依赖 cpu 提供的原子机制。   

这些原子操作一般是：CAS（compare and swap），TAS（test and set），CAE（compare and exchange）。这些原子操作在执行的时候只有成功和失败两种结果，保证了多个线程同时执行时，只有一个获得成功。   

---

## 2.4 blocking 类型的锁 

阻塞型的锁可以分为好几种，多个操作系统大同小异，以 linux 系统为例，包括：信号量、互斥锁、条件变量、读写锁。  

---

### 2.4.1 信号量 (semaphore)

信号量可以跨进程使用，POSIX 定义了相关的接口，并不是 pthread 的一部分，但是多数的 unix 系统在 pthread 的实现中包含了信号量。[3]    






---

### 2.4.2 互斥锁 (mutex)

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

// 初始化
int pthread_mutexattr_init(pthread_mutexattr_t *attr);

// 销毁
int pthread_mutexattr_destroy(pthread_mutexattr_t *attr);

// get/set shared 参数，用于控制是否可跨进程使用，选项包括：
//   PTHREAD_PROCESS_PRIVATE  只能进程内使用（默认情况）
//   PTHREAD_PROCESS_SHARED   可以跨进程使用
int pthread_mutexattr_getshared(const pthread_mutexattr_t *attr, int *pshared);
int pthread_mutexattr_setshared(pthread_mutexattr_t *attr, int *pshared);

// get/set type 参数，用于死锁检测相关，选项包括：  
//    PTHREAD_MUTEX_NORMAL     标准，第1次加锁成功后，再次加锁会失败并阻塞（即死锁了）   
//    PTHREAD_MUTEX_RECURSIVE  递归，第1次加锁成功后，再次加锁会成功（每加1次锁，计数器加1，此时计数器变为2了）
//    PTHREAD_MUTEX_ERRORCHECK 检错，第1次加锁成功后，再次加锁会失败并返回错误信息 
//      
// 默认值是 PTHREAD_MUTEX_DEFAULT，不同系统可能会使用以上的不同值，需要具体测试一下   
int pthread_mutexattr_gettype(const pthread_mutexattr_t *attr, int *type);
int pthread_mutexattr_settype(pthread_mutexattr_t *attr, int *type);

```

`pthread_mutexattr_gettype` 与 `pthread_mutexattr_settype` 的具体信息可参照以下文档：  
[《pthread_mutexattr_gettype(3) - Linux man page》](https://linux.die.net/man/3/pthread_mutexattr_gettype)     
[《pthread_mutexattr_settype(3) - Linux man page》](https://linux.die.net/man/3/pthread_mutexattr_settype)      

要测试当前系统 `PTHREAD_MUTEX_DEFAULT` 是什么值，可以使用这段代码：   

```cpp
// test_attr.cpp
#include <pthread.h>
#include <iostream>

int main() {
    std::cout << "PTHREAD_MUTEX_NORMAL     = " << PTHREAD_MUTEX_NORMAL << std::endl;
    std::cout << "PTHREAD_MUTEX_RECURSIVE  = " << PTHREAD_MUTEX_RECURSIVE << std::endl;
    std::cout << "PTHREAD_MUTEX_ERRORCHECK = " << PTHREAD_MUTEX_ERRORCHECK << std::endl;
    std::cout << "PTHREAD_MUTEX_DEFAULT    = " << PTHREAD_MUTEX_DEFAULT << std::endl;
    return 0;
}
```

编译&运行： `g++ test_attr.cpp && ./a.out`。在我的系统（win10 + wsl2 + ubuntu22.04）上运行结果如下：   

```
PTHREAD_MUTEX_NORMAL     = 0
PTHREAD_MUTEX_RECURSIVE  = 1
PTHREAD_MUTEX_ERRORCHECK = 2
PTHREAD_MUTEX_DEFAULT    = 0
```

即我的系统上，PTHREAD_MUTEX_DEFAULT 相当于 PTHREAD_MUTEX_NORMAL 。  

<br/>

**二、进程间使用互斥锁**    

https://www.zhihu.com/question/66733477/answer/2167257604


进程间大体实现是把 pthread_mutex 放到一块共享内存上，大家都可以访问得到。具体做法可以参考这篇文章：[《多进程共享的pthread_mutex_t》](https://blog.csdn.net/ld_long/article/details/135732039) [4]。    

大致过程如下：  



不过，这里又分两种情况，父子进程和不相干进程。   

父子进程很简单，不需要考虑谁负责创建互斥锁的问题。而不相干进程就复杂了，需要处理好谁负责创建的问题，如果任一进程都要能创建，那么这里又存在互斥的问题了，有点套娃。  

这篇文章 [《用pthread进行进程间同步》](https://www.cnblogs.com/my_life/articles/4538461.html) [5] 介绍了一种不相干进程间互斥的创建互斥锁的做法。大意是利用 link 这个系统调用，原子的把 shm_open 创建出来的共享内存 link 到 `/dev/shm` 中。  

link 系统调用是 linux 原子操作文件的最底层指令，可以保证原子，并且处于 link 操作的进程被中途 kill 掉，linux 内核也会保证完成这次调用。 关键代码：  

```c

```





---

## 2.5 spinning 类型的锁

spinning 类型的只有 spin lock 了。  

---

### 2.5.1 自旋锁

pthread 提供的 spin lock 的 api 包括如下：  

```c

// 初始化锁，pshared 有两个选项：
// PTHREAD_PROCESS_PRIVATE 允许进程内使用
// PTHREAD_PROCESS_SHARE   允许跨进程使用
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

与 pthread_mutex 类似，如果要让 pthread_spin 跨进程使用，即使用 PTHREAD_PROCESS_SHARE 模式，`pthread_spinlock_t` 需要分配在共享内存上，具体做法参照上文的 pthread_mutex 。  

---

# 3. 死锁

---

## 3.1 产生死锁的原因


---

## 3.2 避免死锁 



---

# 4. 参考

[1] 三四. 高并发编程--线程同步. Available at https://zhuanlan.zhihu.com/p/51813695, 2019-01-04.    

[2] Arpaci Dusseau. Operating-Systems: Three-Easy-Pieces. Available at https://pages.cs.wisc.edu/~remzi/OSTEP/threads-locks.pdf.   

[3] Allen B. Downey. POSIX Semaphores. Available at https://eng.libretexts.org/Bookshelves/Computer_Science/Operating_Systems/Think_OS_-_A_Brief_Introduction_to_Operating_Systems_(Downey)/11%3A_Semaphores_in_C/11.01%3A_POSIX_Semaphores.   

[4] ?-ldl. 多进程共享的pthread_mutex_t. Available at https://blog.csdn.net/ld_long/article/details/135732039, 2024-1-21.     

[5] bw_0927. 用pthread进行进程间同步. Available at https://www.cnblogs.com/my_life/articles/4538461.html, 2015-5-29.   

 