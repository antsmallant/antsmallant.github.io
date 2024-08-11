---
layout: post
title: "并发笔记一：同步及同步原语"
date: 2014-03-01
last_modified_at: 2024-04-01
categories: [并发与多线程]
tags: [并发 同步 同步原语 锁 多线程]
---

* 目录  
{:toc}
<br/>

记录同步相关的知识，包括同步的概念，同步要解决的问题，同步原语。   

---

# 1. 资料

* pthread 的官方文档：[https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/pthread.h.html](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/pthread.h.html)    

* pthread linux api 文档：[https://man7.org/linux/man-pages/man0/pthread.h.0p.html](https://man7.org/linux/man-pages/man0/pthread.h.0p.html)    

* [高并发编程--线程同步](https://zhuanlan.zhihu.com/p/51813695)     

* [mit6.005 — Software Construction Reading 20: Thread Safety](https://web.mit.edu/6.005/www/fa15/classes/20-thread-safety/)    

* [mit6.005 — Software Construction Reading 23: Locks and Synchronization](https://web.mit.edu/6.005/www/fa15/classes/23-locks/)    

---

# 2. 同步

---

## 2.1 同步的概念

同步，即 synchronization，在 wikipedia 上，[synchronization](https://en.wikipedia.org/wiki/Synchronization_(computer_science)) 词条 [7] 的解释是：

>synchronization is the task of coordinating multiple processes to join up or handshake at a certain point, in order to reach an agreement or commit to a certain sequence of action.   

翻译过来就是：同步是通过协调多个进程的行为，使得它们按某种约定的顺序进行执行。  

当谈到同步的时候，不必拘泥于进程或线程，在并发的情况下，进程或线程都可以称为执行体，它们都是相对独立的执行逻辑。  

<br/>  

与同步相关的基本概念还包括（参考自：[《高并发编程--线程同步》](https://zhuanlan.zhihu.com/p/51813695) [1]）以下：  

1）critical section ：访问共享资源的代码片段就是临界区（critical section）。     

2）race condition ：多个执行体（线程或进程）进入临界区，修改共享的资源的场景就叫 race condition。    

3）indeterminate ：多个执行体同时进入临界区操作共享资源，其执行结果是不可预料的（indeterminate）。   

4）mutual exclusive ：mutex 的来源，代表一种互斥机制，用来保证只有一个线程可以进入临界区，这种情况下不会出现 race condition，并且结果是 deterministic。  

---

## 2.2 同步要解决的问题

同步需要解决的问题，可以分为两大类：竞争 (competition) 与协同 (cooperation)：   

1）竞争，指的是多个执行体都要操作共享资源，但同时只允许一个执行体进行操作。  

2）协同，指的是一些执行体需要依赖另一些执行体的执行结果，典型的如生产者-消费者问题，就是需要协同的场景。   

可以看得出来，这两个问题与上文中同步的概念关系密切，只有让多个执行体按特定的顺序执行，才能避免竞争问题，才能实现协同。  

<br/>

国内有不少文章会把这两类问题写成 “互斥” 和 “同步”，我觉得这种叫法很糟糕，太容易引起混淆了，本来就有 “互斥锁”、“synchronization” 这些术语了。所以，我觉得用竞争和协同来描述会更好很多。    

---

## 2.2 同步原语

同步原语就是操作系统提供的用于解决同步问题的技术手段。  

1）competition 问题可使用的原语一般是锁，锁包含了二元信号量、互斥锁、共享/排他锁。   

2）cooperation 问题可使用的原语包括条件变量、多元信号量。   

---

# 3. 同步原语--锁

锁是同步原语的一种，它一个很宽泛的概念，它要解决的主要就是竞争问题，实现 mutual exclusive [2]。  

有各种各样的锁，用于解决各种细分问题。本文主要讲操作系统提供的锁，但除此之外，数据库的底层实现中，也有不少锁的概念。   

比如 innnodb 中，就有这些锁 [8]：  

共享锁（Shared Locks）和排它锁（Exclusive Locks）  
意向锁（Intention Locks）   
记录锁（Record Locks）   
间隙锁（Gap Locks）   
临界锁（Next-Key Locks）   
插入单身锁（Insert Intension Locks）   
自增锁（AUTO-INC Locks）   

---

## 3.1 锁的分类及应用场景

整体上可以分为悲观锁与乐观锁，悲观锁假定冲突很频繁，在访问前必须先加上锁，乐观锁假定冲突概率很低，可以先访问，等出现冲突了再做处理。  

严格来说，乐观锁并不是传统意义上的锁，它只是利用了诸如版本号之类的机制，可以在冲突出现的时候识别出来并做相应的处理，算是一种“无锁编程”。    

<br/>

悲观锁就是狭义上的锁了，根据加锁失败后的处理方式可分为两大类：blocking 和 spinning。   

1) blocking，加锁失败时，线程挂起，会阻塞直到加锁成功被唤醒。信号量、互斥锁、读写锁都属于此类型。  

2) spinning，加锁失败时，不挂起，会进入忙等待（busy waiting），不断尝试重新加锁，直到成功。自旋锁（spin lock）就属于此类型，使用的场景主要是明确等待锁的时间会非常短，短到 cpu 空转的代价比线程切换的代价都要低很多。       

---

## 3.2 锁的底层实现

各种锁的底层实现基本上都是操作系统提供的某种原子操作，而操作系统也是依赖 cpu 提供的原子机制。   

这些原子操作一般是：CAS（compare and swap），TAS（test and set），CAE（compare and exchange）。这些原子操作在执行的时候只有成功和失败两种结果，保证了多个线程同时执行时，只有一个获得成功。   

---

## 3.3 blocking 类型的锁 

阻塞型的锁可以分为好几种，不同操作系统大同小异，以 linux 系统为例，包括：信号量、互斥锁、读写锁。  

---

### 3.3.1 信号量 (semaphore)

---

#### 3.3.1.1 信号量的基本信息   

信号量是由 POSIX 定义的，并不是 pthread 的一部分，但是多数的类 unix 系统在 pthread 的实现中包含了信号量。[3]    

信号量是一个大于等于 0 的值，sem_post 时，此量加 1；sem_wait 时，此量大于 0 则减 1，此量等于 0 则阻塞等待。   

信号量的这种机制，可以用来解决竞争问题，也可以用来解决协同问题：   

1）限定取值范围为 0 和 1 的时候，称之为二元信号量，表现上类似于互斥锁，可以解决竞争问题。       
2）不限定取值范围，称之为多元信号量，它可以对资源进行计数，表现上类似于条件变量，可以解决像生产者-消费者的之类的协同问题。   


在实现上，信号量分两种，一种未命名信号量，另一种是命名信号量。   

信号量相关的 overview 文档： [https://man7.org/linux/man-pages/man7/sem_overview.7.html](https://man7.org/linux/man-pages/man7/sem_overview.7.html) 。   

---

#### 3.3.1.2 未命名信号量（unnamed semaphore）

通过以下 api 可以创建并使用未命名信号量，它的接口大致如下[9]：   

```c
#include <semaphore.h>

// 初始化信号量
// 参数：
//   pshared，0 表示进程内使用；非 0 表示跨进程使用
//   value，信号量的初值
// return: 0 for success, -1 for error
// 文档： https://man7.org/linux/man-pages/man3/sem_init.3.html
int sem_init(sem_t *sem, int pshared, unsigned int value); 

// 销毁信号量
// 文档： https://man7.org/linux/man-pages/man3/sem_destroy.3.html
int sem_destroy(sem_t *sem);  

// 释放信号量，信号量值加 1
// return: 0 for success, -1 for error
// 文档： https://man7.org/linux/man-pages/man3/sem_post.3.html
int sem_post(sem_t *sem);  

// 获取信号量，信号量 0 时阻塞，大于 0 时减 1
// return: 0 for success, -1 for error
// 文档： https://man7.org/linux/man-pages/man3/sem_wait.3.html
int sem_wait(sem_t *sem);
```

未命名信号量可以用于进程内，也可以用于跨进程（fork出来的进程），这取决于 init 时的 pshared 参数。  

当要将它用于跨进程时，这些进程需要都能访问到 sem_t 变量，所以，一般是把这个变量放到共享内存上，这样一来，fork 出来的进程或不相干的进程都可以透过共享内存访问到这个变量。  

示例代码，参考自此文 [《Linux系统编程学习笔记——进程间的同步：信号量、互斥锁、信号》](https://zhuanlan.zhihu.com/p/649647971) [10]。  

```c
#include <stdio.h>
#include <semaphore.h>
#include <unistd.h>
#include <stdlib.h>
#include <sys/mman.h>

int main() {
    sem_t *sem_id = NULL;
    pid_t pid;
    sem_id = mmap(NULL, sizeof(sem_t), PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);
    sem_init(sem_id, 1, 1);
    pid = fork();
    if (pid > 0) {
        while (1) {
            sem_wait(sem_id);
            printf("This is parent process\n");
            sleep(1);
        }
    } else if (0 == pid) {
        while (1) {
            printf("This is child process\n");
            sleep(5);
            sem_post(sem_id);
        }
    }
    return 0;
}
```

mmap 的函数原型大致如下：   

```c
#include <sys/mman.h>

// 参数：
//    addr，指定了映射起始地址；如果为NULL，内核会选择一个合适的地址来创建映射，这是最可移植的做法
//    length，指定了映射的字节数
//    prot，位掩码，指定了映射内存的保护空间属性，可读写即为 PROT_READ|PROT_WRITE
//    flags，控制映射操作各个方面选项的位掩码，共享映射且没有对应文件的匿名映射即 MAP_SHARED|MAP_ANONYMOUS
//    fd，用于文件映射的，匿名映射可以填 -1
//    offset，用于文件映射的，匿名映射可以填 0
// Return: 成功时，返回映射地址的指针；失败时，返回 MAP_FAILED，即((void*)-1)  
// 文档： https://man7.org/linux/man-pages/man2/mmap.2.html
void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
```

<br/>

在父子进程间或不相干进程间使用未命名信号量，其做法与互斥锁都是相似的，更具体的做法可以参照的互斥锁。但实际上，如果要跨进程使用信号量，使用下面的命名信号量更方便。  

---

#### 3.3.1.3 命名信号量（named semaphore）

这种信号量拥有一个名字，通过 `sem_open` 创建，不相关的进程能够访问同一个信号量。  

相关的 api 如下： 

```c
#include <semaphore.h>

// 创建或打开一个信号量
// 参数：
//    name，信号量的名称
//    oflag，位掩码，O_CREAT 打开信号量，如果不存在则创建；O_CREAT|O_EXCL 创建新信号量，如果已经存在则失败；
//    mode，信号量的权限
//    value，信号量的初值
// Return: 成功则返回信号量的指针，否则返回 SEM_FAILED
// 文档：  https://man7.org/linux/man-pages/man3/sem_open.3.html
sem_t* sem_open(const char *name, int oflag, /*mode_t mode, unsigned int value*/);

// 关闭信号量，一个进程打开信号量时，系统会记录这种关联，close 则是删除这种关联，但并不是删除信号量
// Return：成则返回 0，失败返回 -1
// 文档：  https://man7.org/linux/man-pages/man3/sem_close.3.html
int sem_close(sem_t *sem);

// 删除信号量与这个 name 的关联，系统此时会把信号量标记为待 destroy 的，当所有打开的进程都关闭此信号量时，则会 destroy 掉
// 文档：  https://man7.org/linux/man-pages/man3/sem_unlink.3.html
int sem_unlink(const char* name);
```

其他的 `sem_post` 和 `sem_wait` 与无命名信号量是一样的用法。  

有名信号量是随内核存在的，如果我们不调用 `sem_unlink` 删除它，它将一直存在，直到内核重启。  

---

#### 3.3.1.4 信号量拓展阅读

* [《Semaphores in Process Synchronization》](https://www.geeksforgeeks.org/semaphores-in-process-synchronization/) 
* [《How to use POSIX semaphores in C language》](https://www.geeksforgeeks.org/use-posix-semaphores-c/)

---

### 3.3.2 互斥锁 (mutex)

mutex，或者称互斥量，是多线程最常用的锁。pthread 的 mutex 实现，支持进程内和跨进程使用。看起来，它就像只有 0, 1 两个值的信号量。  

进程内使用很简单，照着 api 实现就行了。  

跨进程使用会有些复杂，需要把 `pthread_mutex_t` 创建在一块共享内存上，使得多个进程都可以访问它。而这里又分两种情况，父子进程和不相干进程。父子进程相对简单些，不需要考虑谁负责创建互斥锁的问题。而不相干进程就复杂了，需要处理好谁负责创建的问题，如果任一进程都要能创建，那么这里又存在互斥的问题了。具体的做法下文详细展开。   

---

#### 3.3.2.1 单进程内使用互斥锁

进程内互斥很简单，调用 api 即可。   

pthread_mutex 的 api 大致如下：   

```c
#include <pthread.h>

// 以下几个 api 的文档都在： https://man7.org/linux/man-pages/man3/pthread_mutex_init.3.html

// 初始化 mutex
// 参数：
//     mutexattr，指定 mutex 的属性，为 NULL 时使用默认设置，大部分情况下也是这样使用的
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

```c
#include <pthread.h>

// 初始化
// 文档： https://man7.org/linux/man-pages/man3/pthread_mutexattr_init.3.html
int pthread_mutexattr_init(pthread_mutexattr_t *attr);

// 销毁
// 文档： https://man7.org/linux/man-pages/man3/pthread_mutexattr_init.3.html
int pthread_mutexattr_destroy(pthread_mutexattr_t *attr);

// get/set shared 参数，用于控制是否可跨进程使用，选项包括：
//   PTHREAD_PROCESS_PRIVATE  只能进程内使用（默认情况）
//   PTHREAD_PROCESS_SHARED   可以跨进程使用
// 
// 文档： https://man7.org/linux/man-pages/man3/pthread_mutexattr_getpshared.3.html
int pthread_mutexattr_getpshared(const pthread_mutexattr_t *restrict attr, int *restrict pshared);
int pthread_mutexattr_setpshared(pthread_mutexattr_t *attr, int pshared);

// get/set type 参数，用于死锁检测相关，选项包括：  
//    PTHREAD_MUTEX_NORMAL     标准，第1次加锁成功后，再次加锁会失败并阻塞（即死锁了）   
//    PTHREAD_MUTEX_RECURSIVE  递归，第1次加锁成功后，再次加锁会成功（每加1次锁，计数器加1，此时计数器变为2了）
//    PTHREAD_MUTEX_ERRORCHECK 检错，第1次加锁成功后，再次加锁会失败并返回错误信息 
//      
// 默认值是 PTHREAD_MUTEX_DEFAULT，不同系统可能会使用以上的不同值，需要具体测试一下   
//
// 文档： https://man7.org/linux/man-pages/man3/pthread_mutexattr_settype.3p.html
//        https://man7.org/linux/man-pages/man3/pthread_mutexattr_gettype.3p.html
int pthread_mutexattr_gettype(const pthread_mutexattr_t *restrict attr, int *restrict type);
int pthread_mutexattr_settype(pthread_mutexattr_t *attr, int type);

// get/set robust 参数，用于处理持有锁的线程死掉的情况，选项包括： 
//    PTHREAD_MUTEX_STALLED    默认，不作特别处理，持有锁的线程死掉后，如果没其他线程可以解锁，将导致死锁
//    PTHREAD_MUTEX_ROBUST     健壮，持有锁的线程死掉后，第二个阻塞在 acquire 或尝试 acquire 的线程将收到 EOWNERDEAD 的通知。此时它可以做一些处理：调用 
//                                  pthread_mutex_consistent 设置 mutex 为 consistent 的，然后调用 pthread_mutex_unlock 使这个锁可以恢复正常使用。 
//                             
// 文档： https://man7.org/linux/man-pages/man3/pthread_mutexattr_getrobust.3.html  
int pthread_mutexattr_getrobust(const pthread_mutexattr_t *attr, int *robustness);
int pthread_mutexattr_setrobust(pthread_mutexattr_t *attr, int robustness);

// ... 
// 还有一些其他的 api，具体看 pthread 的文档

```

<br/>

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

代码保存为：`test_attr.cpp`，编译&运行： `g++ test_attr.cpp && ./a.out`。  

在我的系统（win10 + wsl2 + ubuntu22.04）上运行结果如下：   

```
PTHREAD_MUTEX_NORMAL     = 0
PTHREAD_MUTEX_RECURSIVE  = 1
PTHREAD_MUTEX_ERRORCHECK = 2
PTHREAD_MUTEX_DEFAULT    = 0
```

可见，在我的系统上 PTHREAD_MUTEX_DEFAULT 相当于 PTHREAD_MUTEX_NORMAL 。  

---

#### 3.3.2.2 父子进程间使用互斥锁   

进程间大体实现是把 `pthread_mutex_t` 放到一块共享内存上，并且要把 mutex 的 shared 属性设置为 `PTHREAD_PROCESS_SHARED`。   

具体做法参考这篇文章：[《多进程共享的pthread_mutex_t》](https://blog.csdn.net/ld_long/article/details/135732039) [4]。大致过程如下：   

1、要有一块多进程可以访问的共享内存。   

2、共享内存划出一段大小刚好可容纳 `pthread_mutex_t` 的内存区域，记为 `mutex_reserve`，这块内存初始化为全 0（必须的，`pthread_mutex_init` 要求 init 的那块内存为 全 0）。   

3、用一个 `pthread_mutex_t` 指针类型的变量 `pmutex` 指向这块内存。    

4、构造并初始化一个 `pthread_mutexattr_t` 类型的属性结构体 `attr`，这个变量不需要放在共享内存中；调用 `pthread_mutexattr_setshared` 将 attr 的 shared 属性设置为 `PTHREAD_PROCESS_SHARED` 。    

5、调用 `pthread_mutex_init`，以 `attr` 初始化 `pmutex`，即 `pthread_mutex_init(pmutex, &attr)`。    

<br/>

示例代码1，参考自此文 [《多进程共享的pthread_mutex_t》](https://blog.csdn.net/ld_long/article/details/135732039) [4]，这段代码并不是直接用 shm* 那套 api 创建共享内存，而是直接创建一个文件，然后用 mmap 把文件映射到内存，以此实现共享内存。   

```c
// pthread_mutex_in_father_son_process.c

#include <pthread.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>  //open
#include <sys/mman.h>
#include <string.h>

int id;

int main()
{
    int fd=open("test_shared_lock_a",O_RDWR|O_CREAT,0777);
    int result=ftruncate(fd,sizeof(pthread_mutex_t)+sizeof(pthread_mutexattr_t)+sizeof(int)*40);

    pthread_mutex_t *mutex=(pthread_mutex_t *)mmap(NULL,sizeof(pthread_mutex_t)+sizeof(pthread_mutexattr_t)+sizeof(int)*40,PROT_READ|PROT_WRITE,MAP_SHARED,fd,0);
    memset(mutex,0,sizeof(pthread_mutex_t)+sizeof(pthread_mutexattr_t)+sizeof(int)*40);

    int* num=(int*)((char*)mutex+sizeof(pthread_mutex_t)+sizeof(pthread_mutexattr_t));
    for(int i=0;i<40;i++)
    {
        num[i]=0;
    }

    /* 下面四行，pthread_mutexattr_t没有放在共享内存中。*/
    pthread_mutexattr_t* attr=NULL;
    pthread_mutexattr_t s;
    attr=&s;
    pthread_mutexattr_init(attr);
    pthread_mutexattr_setpshared(attr, PTHREAD_PROCESS_SHARED);

	// 上面7行如果都注释，则为不使用attr初始化mutex。
    pthread_mutex_init(mutex,attr);

	//创建39个子进程。并且每个进程获得一个id。
    for(int i=0;i<39;i++)
    {
        id=i+1;
        int pid=fork();
        if(pid==0)
        {
            break;
        }
        else
        {
            if(id==39)
            {
                id=0;
            }
        }
    }

    //每个进程报告自己的pid。
    printf("%d report!\n",getpid());

    //if(id!=0)
    {
        //开始检测是否有多个进程同时进入临界区。
        int j=1;
        while(j-->0)
        {
            printf("%d try to lock!\n",getpid());
            pthread_mutex_lock(mutex);
            printf("%d get lock\n",getpid());
            //拿到锁后，在对应位置做标记，表示自己进入临界区。
            num[id]=1;
            int sum=0;
            for(int i=0;i<40;i++)
            {
                sum+=num[i];
            }
            if(sum>1)
            {
                printf("%d lock_failed!\n",getpid()); //如果有两个进程同时进入临界区,sum必定大于0。
            }
            else
            {
                printf("%d test_ok\n",getpid());  //如果sum为1,说明只有一个进程进入临界区。
            }
            num[id]=0;
            sleep(1);
            pthread_mutex_unlock(mutex);
        }
    }

    return 0;
}
```

代码保存为：`pthread_mutex_in_father_son_process.c`。   
编译&运行：`gcc pthread_mutex_in_father_son_process.c && ./a.out` 。     

<br/>

示例代码2，参考自此文：[《使用mutex同步多进程》](https://www.cnblogs.com/xiaoshiwang/p/12582531.html) [6]，这段代码使用 shm* 的 api 创建共享内存。      

```c
// save as : pthread_mutex_in_father_son_process2.c
// compile and run: gcc pthread_mutex_in_father_son_process2.c && ./a.out

#include <stdio.h>
#include <pthread.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/shm.h>
#include <sys/wait.h>
#include <string.h>

int main()
{
    pid_t pid;
    int shmid;
    int* shmptr;
    int* tmp;

    int err;
    pthread_mutexattr_t mattr;
    //创建mutex的属性
    if((err = pthread_mutexattr_init(&mattr)) < 0)
    {
        printf("mutex addr init error:%s\n", strerror(err));
        exit(1);
    }

    //让mutex可以同步多个进程
    //mutex的默认属性是同步线程的，所有必须要有此行代码
    if((err = pthread_mutexattr_setpshared(&mattr, PTHREAD_PROCESS_SHARED)) < 0)
    {
        printf("mutex addr get shared error:%s\n", strerror(err));
        exit(1);
    }

    //注意：这里是个大坑，这里的mutex必须是用共享内存的方式创建，目的是父进程和子进程可以共用此mutex。
    //否则，父进程的mutex就是父进程的，子进程的mutex就是子进程的，不能达到同步的作用。
    pthread_mutex_t* m;
    int mid = shmget(IPC_PRIVATE, sizeof(pthread_mutex_t), 0600);
    m = (pthread_mutex_t*)shmat(mid, NULL, 0);

    //使用mutex的属性，创建mutex
    if((err = pthread_mutex_init(m, &mattr)) < 0)
    {
        printf("mutex mutex init error:%s\n", strerror(err));
        exit(1);
    }

    //创建一个共享内存区域，让父进程和子进程往里写数据。
    if((shmid = shmget(IPC_PRIVATE, 1000, IPC_CREAT | 0600)) < 0)
    {
        perror("shmget error");
        exit(1);
    }

    //取得指向共享内存的指针
    if((shmptr = shmat(shmid, 0, 0)) == (void*)-1)
    {
        perror("shmat error");
        exit(1);
    }

    tmp = shmptr;

    //创建一个共享内存，保存上面共享内存的指针
    int shmid2;
    int** shmptr2;
    if((shmid2 = shmget(IPC_PRIVATE, 20, IPC_CREAT | 0600)) < 0)
    {
        perror("shmget2 error");
        exit(1);
    }

    //取得指向共享内存的指针
    if((shmptr2 = shmat(shmid2, 0, 0)) == (void*)-1)
    {
        perror("shmat2 error");
        exit(1);
    }
    //让shmptr2指向共享内存id为shmid的首地址。
    *shmptr2 = shmptr;

    if((pid = fork()) < 0)
    {
        perror("fork error");
        exit(1);
    }

    if(pid == 0)
    {
        //从此处开始给mutex加锁，如果加锁成功，则此期间，父进程无法取得锁
        if((err = pthread_mutex_lock(m)) < 0)
        {
            printf("lock error:%s\n", strerror(err));
            exit(1);
        }
        for(int i = 0; i < 30; ++i)
        {
            **shmptr2 = i;
            (*shmptr2)++;
        }

        if((err = pthread_mutex_unlock(m)) < 0)
        {
            printf("unlock error:%s\n", strerror(err));
            exit(1);
        }
        exit(0);

    }
    else
    {
        //从此处开始给mutex加锁，如果加锁成功，则此期间，子进程无法取得锁
        if((err = pthread_mutex_lock(m)) < 0)
        {
            printf("lock error:%s\n", strerror(err));
            exit(1);
        }
        for(int i = 10; i < 42; ++i)
        {
            **shmptr2 = i;
            (*shmptr2)++;
        }
        if((err = pthread_mutex_unlock(m)) < 0)
        {
            printf("unlock error:%s\n", strerror(err));
            exit(1);
        }
    }

    //销毁子进程
    wait(NULL);

    //查看共享内存的值
    for(int i = 0; i < 62; ++i)
    {
        printf("%d ", tmp[i]);
    }

    printf("\n");

    //销毁mutex的属性
    pthread_mutexattr_destroy(&mattr);
    //销毁mutex
    pthread_mutex_destroy(m);

    exit(0);

    return 0;
}
```

代码保存为：`pthread_mutex_in_father_son_process2.c`。    
编译&运行：`gcc pthread_mutex_in_father_son_process2.c && ./a.out` 。     

<br/>

关于 mmap 和 shm* 创建共享内存的具体做法，可参照此文章： [《共享内存进阶指南：深入学习mmap和shm*的用法与技巧》](https://zhuanlan.zhihu.com/p/659036359)。  

---

#### 3.3.2.3 不相干的进程间使用互斥锁

不相干的进程间使用互斥锁，也像父子进程那样，需要把 `pthread_mutex_t` 放在共享内存上，但不相干进程需要额外解决互斥锁的创建问题：谁创建？如何原子的创建？

这篇文章 [《用pthread进行进程间同步》](https://www.cnblogs.com/my_life/articles/4538461.html) [5] 介绍了一种不相干进程间安全的创建互斥锁的做法。大意是利用 `link` 系统调用，原子的把 `shm_open` 创建出来的共享内存 `link` 到 `/dev/shm` 中。   

`/dev/shm` 是一个 mount 了的文件系统，里面放了一堆通过 `shm_open` 新建的共享内存。   

`link` 是 linux 原子操作文件的最底层指令，可以保证原子性，并且正在执行 `link` 的进程如果意外退出，linux 内核也会保证完成此次调用。 

`link` 参考文档： https://man7.org/linux/man-pages/man2/link.2.html 。     

关键代码：  

```c
// 1、创建共享内存的副本
shm_open("ourshm_tmp");

// 2、尝试原子的把副本 link 为正式的
if (0 == link("/dev/shm/ourshm_tmp", "/dev/shm/ourshm")) {
    // 2.1、创建成功
} else {
    // 2.2、创建失败，因为别人已经创建了
}

// 3、无论成功与否，都要删除副本
shm_unlink("/dev/shm/ourshm_tmp");  
```

其他的就跟上面的在父子进程间创建互斥锁是同样的操作了。    

---

#### 3.3.2.4 关于互斥锁使用的原则 

本节参考自陈硕的《Linux 多线程服务端编程（使用 muduo C++ 网络库）》[11]。   

主要原则：   

* 用 RAII 手法封装 mutex 的创建、销毁、加锁、解锁。   
* 只使用非递归的 mutex。  
* 不手工调用 lock 和 unlock，一切交给栈上的 guard 对象（即用 RAII 手法封装的）。  
* 每次构造 Guard 对象上，思考调用栈上已经持有的锁，防止因加锁顺序不同导致死锁。   

次要原则：   

* 不使用跨进程的 mutex，进程间只使用 tcp sockets。  
* 加锁、解锁在同一个线程，线程 a 不要去 unlock 线程 b 加锁的 mutex（RAII 自动保证）。
* 别忘了解锁（RAII 自动保证）。  
* 不重复解锁（RAII 自动保证）。  
* 必要的时候可以考虑用 PTHREAD_MUTEX_ERRORCHECK 来排错。  

---

#### 3.3.2.5 为何建议只使用非递归的 mutex

本节参考自陈硕的《Linux 多线程服务端编程（使用 muduo C++ 网络库）》[11]。    

recursive mutex 与 non-recursive mutex 的区别在于同一个线程可以对 non-recursive mutex 重复加锁。如果对 recursive mutex 重复加锁，会立即导致死锁。  

虽然 recursive mutex 用起来更方便，不用考虑一个线程把自己锁死了。但是它可能会隐藏代码里的一些问题，典型的你以为拿到一个锁就能修改共享对象，谁知外层逻辑也已经拿到了锁，也正在修改同个对象。  

死锁问题比偶然的 crash 更容易调试，比如： 1）把线程的调用栈打印出来看；2）使用 PTHREAD_MUTEX_ERRORCHECK 选项进行排错。  

Pthreads 的权威专家，《Programming with POSIX Threads》的作者 David Butenhof 也排斥使用 recursive mutex，他说[13]： 

>Fist, implementation of efficient and reliable threaded code resolves around one simple and basic principle: follow your design. That implies, of course, that you have a design, and that you understand it.    
>A correct and well understood design does not require recursive mutexes.  

---

### 3.3.3 读写锁 (rwlock)

---

### 3.3.4 信号量与互斥锁的对比   

参考：[Semaphores vs. mutexes](https://en.wikipedia.org/wiki/Semaphore_(programming)#Semaphores_vs._mutexes)    

>A mutex is a locking mechanism that sometimes uses the same basic implementation as the binary semaphore. However, they differ in how they are used. While a binary semaphore may be colloquially referred to as a mutex, a true mutex has a more specific use-case and definition, in that only the task that locked the mutex is supposed to unlock it. This constraint aims to handle some potential problems of using semaphores:
>
>1. Priority inversion: If the mutex knows who locked it and is supposed to unlock it, it is possible to promote the priority of that task whenever a higher-priority task starts waiting on the mutex.
>2. Premature task termination: Mutexes may also provide deletion safety, where the task holding the mutex cannot be accidentally deleted. [citation needed]
>3. Termination deadlock: If a mutex-holding task terminates for any reason, the OS can release the mutex and signal waiting tasks of this condition.
>4. Recursion deadlock: a task is allowed to lock a reentrant mutex multiple times as it unlocks it an equal number of times.
>5. Accidental release: An error is raised on the release of the mutex if the releasing task is not its owner.   

---

## 3.4 spinning 类型的锁

spinning 类型的只有 spin lock 了。  

---

### 3.4.1 自旋锁 (spin lock)

pthread 提供的 spin lock 的 api 如下：  

```c
#include <pthread.h>

// 初始化锁，pshared 有两个选项：
// PTHREAD_PROCESS_PRIVATE 允许进程内使用
// PTHREAD_PROCESS_SHARE   允许跨进程使用
// 文档： https://man7.org/linux/man-pages/man3/pthread_spin_init.3.html
int pthread_spin_init(pthread_spinlock_t *lock, int pshared); 
                                                              
// 销毁锁        
// 文档： https://man7.org/linux/man-pages/man3/pthread_spin_init.3.html
int pthread_spin_destroy(pthread_spinlock_t *lock); 

// 加锁，如果失败，则自旋直到成功
// 文档： https://man7.org/linux/man-pages/man3/pthread_spin_lock.3.html
int pthread_spin_lock(pthread_spinlock_t *lock);    

// 尝试加锁，成功或失败都立即返回，根据返回值判断结果  
// 文档： https://man7.org/linux/man-pages/man3/pthread_spin_lock.3.html
int pthread_spin_trylock(pthread_spinlock_t *lock); 

// 释放锁
// 文档： https://man7.org/linux/man-pages/man3/pthread_spin_unlock.3.html
int pthread_spin_unlock(pthread_spinlock_t *lock);  
```  

与互斥锁类似，如果要让自旋锁跨进程使用，则 `pthread_spinlock_t` 也需要分配在共享内存上，具体做法参照上文的互斥锁 。  

---

# 4. 同步原语--条件变量

条件变量用于实现协同的逻辑，其同步语义是等待。  

pthread 提供了条件变量，但要注意，`pthread_cond_wait` 本身不是原子操作，所以它需要配合互斥锁来使用，即 `pthread_mutex`。  

pthread_cond 相关的 api 如下：  

```c
#include <pthread.h>

// 文档都在： https://man7.org/linux/man-pages/man3/pthread_cond_init.3.html  

// 初始化
int pthread_cond_init(pthread_cond_t *cond);  

// 销毁
int pthread_cond_destroy(pthread_cond_t *cond);


```

spurious wakeups 是指


---

# 5. 一些底层问题

---

## 5.1 关于 futex

Linux 的 pthread mutex 采用 futex [12] 实现，不必每次加锁、解锁都陷入系统调用，效率较高。  

---

# 6. 死锁

[死锁与死锁避免算法](https://blog.csdn.net/K346K346/article/details/136306132?spm=1001.2014.3001.5501)   

[mit6.005 Software Construction Reading 23: Locks and Synchronization](https://web.mit.edu/6.005/www/fa15/classes/23-locks/)

[https://web.mit.edu/6.005/www/fa15/classes/20-thread-safety/](https://web.mit.edu/6.005/www/fa15/classes/20-thread-safety/)   

[https://web.mit.edu/6.005/www/fa15/classes/19-concurrency/](https://web.mit.edu/6.005/www/fa15/classes/19-concurrency/)

---

## 6.1 产生死锁的原因


---

## 6.2 避免死锁 

---

# 7. 经典同步问题的解法

---

## 7.1 哲学家就餐问题

---

## 7.2 生产者消费者问题

---

# 8. 参考

[1] 三四. 高并发编程--线程同步. Available at https://zhuanlan.zhihu.com/p/51813695, 2019-01-04.    

[2] Arpaci Dusseau. Operating-Systems: Three-Easy-Pieces. Available at https://pages.cs.wisc.edu/~remzi/OSTEP/threads-locks.pdf.   

[3] Allen B. Downey. POSIX Semaphores. Available at https://eng.libretexts.org/Bookshelves/Computer_Science/Operating_Systems/Think_OS_-_A_Brief_Introduction_to_Operating_Systems_(Downey)/11%3A_Semaphores_in_C/11.01%3A_POSIX_Semaphores.   

[4] ?-ldl. 多进程共享的pthread_mutex_t. Available at https://blog.csdn.net/ld_long/article/details/135732039, 2024-1-21.     

[5] bw_0927. 用pthread进行进程间同步. Available at https://www.cnblogs.com/my_life/articles/4538461.html, 2015-5-29.   

[6] 小石王. 使用mutex同步多进程. Available at https://www.cnblogs.com/xiaoshiwang/p/12582531.html, 2020-3-27.   

[7] Wikipedia. Synchronization (computer science). Available at https://en.wikipedia.org/wiki/Synchronization_(computer_science).   

[8] 勇敢的菜鸡. Mysql锁机制 - 锁类型. Available at https://blog.csdn.net/qq_39679639/article/details/127351187, 2022-10-16.    

[9] geeksforgeeks. How to use POSIX semaphores in C language. Available at https://www.geeksforgeeks.org/use-posix-semaphores-c/, 2020-12-11.    

[10] 若影​. Linux系统编程学习笔记——进程间的同步：信号量、互斥锁、信号. Available at https://zhuanlan.zhihu.com/p/649647971, 2023-8-12.     

[11] 陈硕. Linux 多线程服务端编程. 北京: 电子工业出版社, 2013-3(2):32,33.   

[12] Ulrich Drepper. Ulrich Drepper. Available at https://www.akkadia.org/drepper/futex.pdf, 2011-11-5.   

[13] David Butenhof. Recursive mutexes by David Butenhof. Available at http://zaval.org/resources/library/butenhof1.html, 2005-5-17.  

---

# 9. todo

* pthread mutex，未挂有锁的线程 unlock 了被其他线程持有的锁，会发生什么事情？   

* spurious wakeup，条件变量需要使用 while 循环进行 wait。  《Linux 多线程服务端编程》p41

* what is monitor?  https://en.wikipedia.org/wiki/Monitor_(synchronization)#

* named semaphore 如何保证被 unlink 掉？  