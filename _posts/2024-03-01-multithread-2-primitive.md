---
layout: post
title: "多线程编程二：同步原语"
date: 2024-03-01
last_modified_at: 2024-03-01
categories: [并发与多线程]
tags: [并发 同步 多线程]
---

* 目录  
{:toc}
<br/>

下面介绍一些常用的同步机制，实际上都可以称为锁。锁是一种非强制机制，线程在访问前尝试获取锁，在访问结束后释放锁。下面各种锁的介绍参考自《程序员的自我修养：链接、装载与库》[1]。  

---

# 同步机制

---

## 二元信号量 (binary semaphore)
是一种最简单的锁，它只有两种状态：占用与非占用，适合于只能被唯一一条线程独占访问的资源。  

访问资源前：  
尝试获取信号量，如果信号量处于非占用状态，则获取成功，信号量变为占用状态，线程继续执行；否则线程进入等待。  

访问资源后：  
释放信号量，信号量变为非占用状态，如果此时有线程在等待，则唤醒等待中的一条线程。  

---

## 多元信号量 (semaphore)
简称信号量，一个初始值为 N 的信号量，允许 N 个线程并发访问。  

访问资源前：  
尝试获取信号量，将信号量减 1，如果信号量的值小于 0，则进入等待状态，否则继续执行。  

访问资源后：  
释放信号量，信号量加 1，如果信号量的值小于 1，唤醒一条等待中的线程。  

---

## 互斥量 (mutex)
类似于二元信号量，仅允许同时被一条线程访问。  

不同之处在于，信号量可以在线程1获取但交给线程2去释放；而互斥量则要求哪个线程获取，哪个线程就要负责释放，其他线程不能帮忙。  

不过，pthread 的 mutex 实现是只能单进程的，而 windows 的 mutex 是可以跨进程的

---

## 临界区 (critical section)
是比互斥量更严格的同步手段。  

把临界区的锁的获取称为进入临界区，而把锁的释放称为离开临界区。  

临界区与信号量、互斥量的区别在于：信号量、互斥量在系统的任何进程里都是可见的，即一个进程创建了信号量或互斥量，在另一个进程试图去获取是合法的。而临界区的作用范围仅限于本进程，其他进程无法获取。  

linux 没有提供临界区，可以使用互斥量（pthread_mutex_t）模拟，不过意义不大。   

windows 提供了临界区，大致用法如下：    

```cpp

CRITICAL_SECTION  g_cs;

DWORD WINAPI tfunc(PVOID pParam)
{
	EnterCriticalSection(&g_cs);
	// do something
    // ...
	LeaveCriticalSection(&g_cs);
	return 0;
}

int main()
{
	InitializeCriticalSection(&g_cs);
	HANDLE hTH1 = CreateThread(NULL, 0, tf, NULL, 0, NULL);
	HANDLE TH[1] = { hTH1 };
	WaitForMultipleObjects(1, TH, FALSE, INFINITE);
	DeleteCriticalSection(&g_cs);
	return 0;
}
```

---

## 读写锁 (read-write lock)
用于特定场合的一种同步手段。对于一段数据，多线程同时读取是没问题的，但多线程边读边写可能就会出问题。这种情况虽然用信号量、互斥量、临界区都可以做到同步。但是对于那种读多写少的场景，效率就比较差了，而这种情况，用读写锁就很合适。  

读写锁一般会有三种状态：自由、共享、独占，对应两种获取方式：共享的（shared）、独占的（Exclusive）。  

当处于自由状态时，试图以任一种方式获取都会成功，并将锁置为对应状态。  
当处于共享状态时，以共享方式获取会成功，以独占方式获取会进入等待。  
当处于独占状态时，试图以任一种方式获取都会进入等待。  

归类如下：  

|读写锁状态|以共享方式获取|以独占方式获取|
|---------|-------------|------------|
|  自由   |   成功       |    成功    |
|  共享   |   成功       |    等待    |
|  独占   |   等待       |    等待    |


btw，在数据库里，这种锁很常见，并且会更复杂一些。   

---

## 条件变量 (condition variable)
首先，这不是一种锁，它的作用类似于栅栏。对于条件变量，线程可以有两种操作：  
* 线程可以等待条件变量，一个条件变量可以被多条线程等待。 
* 线程可以唤醒条件变量，此时某个或所有等待此条件变量的线程会被唤醒并继续执行。 

在 linux（pthread） 和 windows 都有此实现。  

pthread 的条件变量：  
* pthread_cond_t 是数据类型
* pthread_cond_init 负责初始化
* pthread_cond_destroy 负责销毁（deinitialize）
* pthread_cond_wait 等待条件变为真
* pthread_cond_timedwait 等待条件变为真（允许指定等待的时间）
* pthread_cond_signal 唤醒等待该条件的某个线程
* pthread_cond_broadcast 唤醒等待该条件的所有线程

---

## 自旋锁 (spin lock)
自旋锁用于处理器之间的互斥，适合保护很短的临界区，并且不允许在临界区睡眠。申请自旋锁的时候，如果自旋锁被其他处理器占有，本处理器自旋等待（也称为忙等待）。[2]   

忙等待实际上就是处理器在空跑。为何会需要自旋锁呢？因为与忙等待相比，有时候线程切换的成本更高，让线程短暂的忙等待更有助于提高并发度。  

pthread 提供了自旋锁：    

```cpp
// 初始化
int pthread_spin_init(pthread_spinlock_t *lock, int pshared);
// 销毁
int pthread_spin_destroy(pthread_spinlock_t *lock);
// 申请自旋锁，在获得之前保持自旋状态
int pthread_spin_lock(pthread_spinlock_t *lock);
// 尝试申请自旋锁，如果失败立即返回一个错误码，不进入自旋状态
int pthread_spin_trylock(pthread_spinlock_t *lock);
// 释放自旋锁
int pthread_spin_unlock(pthread_spinlock_t *lock);
```

---

## 使用范围小结

* windows

|锁|范围|
|--|--|
|信号量|多进程间|
|互斥量|多进程间|
|临界区|单进程内|
|读写锁|单进程内|
|条件变量|单进程内|
|自旋锁|单进程内|

* linux (pthread)

|锁|范围|
|--|--|
|信号量|多进程间|
|互斥量|单进程内|
|临界区|无对应实现，用互斥量代替|
|读写锁|单进程内|
|条件变量|单进程内|
|自旋锁|单进程内|

---

# 参考

[1] 俞甲子, 石凡, 潘爱民. 程序员的自我修养：链接、装载与库. 北京: 电子工业出版社, 2009-4.    

[2] Microsoft. volatile (C++). Available at https://learn.microsoft.com/en-us/cpp/cpp/volatile-cpp?view=msvc-170&viewFallbackFrom=vs-2019, 2021-9-21.  