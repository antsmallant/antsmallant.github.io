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

记录并发中同步相关的知识，包括同步的概念，同步要解决的问题，同步原语。   

---

# 1. 资料

pthread 的官方文档：[https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/pthread.h.html](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/pthread.h.html)    

pthread linux api 文档：[https://man7.org/linux/man-pages/man0/pthread.h.0p.html](https://man7.org/linux/man-pages/man0/pthread.h.0p.html)    


备用文档：  

https://www.zhihu.com/question/66733477/answer/1267625567  

https://zhuanlan.zhihu.com/p/653864005   

https://man7.org/linux/man-pages/man3/pthread_mutex_lock.3p.html  


**todo**  

* pthread mutex，未挂有锁的线程 unlock 了被其他线程持有的锁，会发生什么事情？   

* spurious wakeup，条件变量需要使用 while 循环进行 wait。  

* what is monitor?  

---

# 2. 同步

---

## 2.1 同步的概念

同步，即 synchronization，在 wikipedia 上，[synchronization](https://en.wikipedia.org/wiki/Synchronization_(computer_science)) 词条 [7] 的解释是：

>synchronization is the task of coordinating multiple processes to join up or handshake at a certain point, in order to reach an agreement or commit to a certain sequence of action.   

翻译过来就是：同步是通过协调多个进程的行为，使得它们按某种约定的顺序进行执行。  

当谈到同步的时候，不必拘泥于进程或线程，在并发的情况下，进程或线程都可以称为执行体，用执行体来称呼各个相对独立的执行逻辑就行。   

<br/>  

与同步相关的基本概念包括（参考自：[《高并发编程--线程同步》](https://zhuanlan.zhihu.com/p/51813695) [1]）：  

* critical section   

访问共享资源的代码片段就是临界区（critical section）。    


* race condition  

多个执行体（线程或进程）进入临界区，修改共享的资源的场景就叫 race condition。    


* indeterminate

多个执行体同时进入临界区操作共享资源，其执行结果是不可预料的（indeterminate）。   


* mutual exclusive

mutex 的来源，代表一种互斥机制，用来保证只有一个线程可以进入临界区，这种情况下不会出现 race condition，并且结果是 deterministic。  

---

## 2.2 同步要解决的问题

同步需要解决的问题，可以分为两大类：竞争 (competition) 与协同 (cooperation)：   

1）竞争，指的就是多个执行体都要操作共享资源，但同时只允许一个执行体进行操作。  

2）协同，指的就是一些执行体需要依赖另一些执行体的执行结果，典型的如生产者-消费者问题，就是需要协同的场景。   

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

[mit6.005 — Software Construction Reading 20: Thread Safety](https://web.mit.edu/6.005/www/fa15/classes/20-thread-safety/)    
[mit6.005 Software Construction Reading 23: Locks and Synchronization](https://web.mit.edu/6.005/www/fa15/classes/23-locks/)    

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

信号量是由 POSIX 定义的，并不是 pthread 的一部分，但是多数的类 unix 系统在 pthread 的实现中包含了信号量。[3]    

信号量的本质是原子的对一个整数进行加减，当这个整数的取值限定为 0 和 1 的时候，就相当于一个互斥锁。   

它的接口大致如下[9]：   

```c

```


---

### 3.3.2 互斥锁 (mutex)

mutex，或者称互斥量，是多线程最常用的锁。pthread 的 mutex 实现，支持进程内和进程间的互斥。看起来，它就像只有 0, 1 两个值的信号量。  

单进程内使用很简单，照着 api 实现就行了。  

跨进程使用会有些复杂，需要把 `pthread_mutex_t` 创建在一块共享内存上，使得多个进程都可以访问它。而这里又分两种情况，父子进程和不相干进程。父子进程相对简单些，不需要考虑谁负责创建互斥锁的问题。而不相干进程就复杂了，需要处理好谁负责创建的问题，如果任一进程都要能创建，那么这里又存在互斥的问题了。具体的做法下文详细展开。   

---

#### 3.3.2.1 单进程内使用互斥锁

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
// 可参考文档： https://linux.die.net/man/3/pthread_mutexattr_gettype
//             https://linux.die.net/man/3/pthread_mutexattr_settype
int pthread_mutexattr_gettype(const pthread_mutexattr_t *attr, int *type);
int pthread_mutexattr_settype(pthread_mutexattr_t *attr, int *type);

// get/set robust 参数，用于处理持有锁的线程死掉的情况，选项包括： 
//    PTHREAD_MUTEX_STALLED    默认，不作特别处理，持有锁的线程死掉后，如果没其他线程可以解锁，将导致死锁
//    PTHREAD_MUTEX_ROBUST     健壮，持有锁的线程死掉后，第二个阻塞在 acquire 或尝试 acquire 的线程将收到 EOWNERDEAD 的通知。此时它可以做一些处理：调用 
//                                  pthread_mutex_consistent 设置 mutex 为 consistent 的，然后调用 pthread_mutex_unlock 使这个锁可以恢复正常使用。 
//                             
// 可参考文档： https://pubs.opengroup.org/onlinepubs/9699919799/functions/pthread_mutexattr_setrobust.html  
int pthread_mutexattr_getrobust(const pthread_mutexattr_t *attr, int *robust);
int pthread_mutexattr_setrobust(pthread_mutexattr_t *attr, int *robust);

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

参考代码1 [4]： 

这段代码并不是直接用 shm* 那套 api 创建共享内存，而是直接创建一个文件，然后用 mmap 把文件映射到内存，以此实现共享内存。   

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

参考代码2 [6]:  

这段代码使用 shm* 的 api 创建共享内存。  

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

### 3.3.3 读写锁 (rwlock)

---

## 3.4 spinning 类型的锁

spinning 类型的只有 spin lock 了。  

---

### 3.4.1 自旋锁 (spin lock)

pthread 提供的 spin lock 的 api 如下：  

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

# 4. 同步原语--条件变量


---

# 5. 一些底层问题

---

## 5.1 关于 futex

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

# 7. 参考

[1] 三四. 高并发编程--线程同步. Available at https://zhuanlan.zhihu.com/p/51813695, 2019-01-04.    

[2] Arpaci Dusseau. Operating-Systems: Three-Easy-Pieces. Available at https://pages.cs.wisc.edu/~remzi/OSTEP/threads-locks.pdf.   

[3] Allen B. Downey. POSIX Semaphores. Available at https://eng.libretexts.org/Bookshelves/Computer_Science/Operating_Systems/Think_OS_-_A_Brief_Introduction_to_Operating_Systems_(Downey)/11%3A_Semaphores_in_C/11.01%3A_POSIX_Semaphores.   

[4] ?-ldl. 多进程共享的pthread_mutex_t. Available at https://blog.csdn.net/ld_long/article/details/135732039, 2024-1-21.     

[5] bw_0927. 用pthread进行进程间同步. Available at https://www.cnblogs.com/my_life/articles/4538461.html, 2015-5-29.   

[6] 小石王. 使用mutex同步多进程. Available at https://www.cnblogs.com/xiaoshiwang/p/12582531.html, 2020-3-27.   

[7] Wikipedia. Synchronization (computer science). Available at https://en.wikipedia.org/wiki/Synchronization_(computer_science).   

[8] 勇敢的菜鸡. Mysql锁机制 - 锁类型. Available at https://blog.csdn.net/qq_39679639/article/details/127351187, 2022-10-16.    

[9] geeksforgeeks. How to use POSIX semaphores in C language. Available at https://www.geeksforgeeks.org/use-posix-semaphores-c/, 2020-12-11.    