---
layout: post
title: "redis 笔记一：常识、用法"
date: 2016-1-1
last_modified_at: 2024-7-10
categories: [redis]
tags: [redis]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 redis 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

---

## 1.1 bigkey 的删除

这篇文章： [《redis之bigkey（看这一篇就够）》](https://www.cnblogs.com/szq95716/p/14271108.html) [1] 总结得很好。    

### 1.1.1 redis4.0 以前    

在 redis4.0 以前，bigkey 的删除，如果直接使用 del 命令，会阻塞主线程比较久，导致实例响应不了其他命令，大致的估算是每 100w 个 value item，耗时是 1 秒左右（不同设备不现配置性能是不同的）。  

所以，稳妥的做法是根据不同的数据结构，使用不同的方式进行分段删除。   

|key类型|删除方法|
|:--|:--|
|sortedset| zremrangebyrank，每次删除 top n 个|
|hash| 通过 hscan 取出 n 个 item，然后用 hdel 分别删除这 n 个item|
|set| 通过 sscan 取出 n 个 item，然后用 srem 分别删除这 n 个item|
|list| 通过 ltrim 每次删除 n 个元素|

<br/>

### 1.1.2 redis4.0 以后 

在 redis4.0 以后，bigkey 的删除，可以使用 unlink 命令代替 del，unlink 一个 bigkey 的时候，redis 根据一定的规则评估释放 value 的耗时，当耗时可能超过阈值时，就会把 value 的释放安排到单纯的线程（bio）中去执行，从而避免阻塞主线程。  

具体的，在异步释放的时候，会使用一个评估函数 `lazyfreeGetFreeEffort`，评估得出的值大于阈值（`#define LAZYFREE_THRESHOLD 64`）时，就真正使用异步释放。  

大致可以理解为 hash/set/sortedset/list 这些的元素个数超过 64 个时，就会异步删除。   

`lazyfreeGetFreeEffort` 的源码在 [https://github.com/redis/redis/blob/unstable/src/lazyfree.c](https://github.com/redis/redis/blob/unstable/src/lazyfree.c)：   

```c
size_t lazyfreeGetFreeEffort(robj *key, robj *obj, int dbid) {
    if (obj->type == OBJ_LIST && obj->encoding == OBJ_ENCODING_QUICKLIST) {
        quicklist *ql = obj->ptr;
        return ql->len;
    } else if (obj->type == OBJ_SET && obj->encoding == OBJ_ENCODING_HT) {
        dict *ht = obj->ptr;
        return dictSize(ht);
    } else if (obj->type == OBJ_ZSET && obj->encoding == OBJ_ENCODING_SKIPLIST){
        zset *zs = obj->ptr;
        return zs->zsl->length;
    } else if (obj->type == OBJ_HASH && obj->encoding == OBJ_ENCODING_HT) {
        dict *ht = obj->ptr;
        return dictSize(ht);
    } else if (obj->type == OBJ_STREAM) {
        size_t effort = 0;
        stream *s = obj->ptr;

        /* Make a best effort estimate to maintain constant runtime. Every macro
         * node in the Stream is one allocation. */
        effort += s->rax->numnodes;

        /* Every consumer group is an allocation and so are the entries in its
         * PEL. We use size of the first group's PEL as an estimate for all
         * others. */
        if (s->cgroups && raxSize(s->cgroups)) {
            raxIterator ri;
            streamCG *cg;
            raxStart(&ri,s->cgroups);
            raxSeek(&ri,"^",NULL,0);
            /* There must be at least one group so the following should always
             * work. */
            serverAssert(raxNext(&ri));
            cg = ri.data;
            effort += raxSize(s->cgroups)*(1+raxSize(cg->pel));
            raxStop(&ri);
        }
        return effort;
    } else if (obj->type == OBJ_MODULE) {
        size_t effort = moduleGetFreeEffort(key, obj, dbid);
        /* If the module's free_effort returns 0, we will use asynchronous free
         * memory by default. */
        return effort == 0 ? ULONG_MAX : effort;
    } else {
        return 1; /* Everything else is a single allocation. */
    }
}
```

---

## 1.2 redis 各个数据类型的用途及底层实现

参考自：[《Redis 常见数据类型和应用场景》](https://xiaolincoding.com/redis/data_struct/command.html)    

redis 常用的数据类型有 5 种：String，List，Hash，Set，Zset。还有另外 4 种用得不多的：Bitmap（2.2新增），HyperLogLog（2.8新增），Geo（3.2新增），Stream（5.0新增）。   

|数据类型|存储内容|支持的操作|底层实现
|--|--|--|--|
|String|存储字符串、整数、浮点|操纵字符串；加减数字值|long long 或 SDS（简单动态字符串）|
|List|双向链表，长度可达2^32-1，可存储字符串|链表操作|3.2版本之前使用 压缩列表+双向链表；3.2版本之后使用 quicklist|


---

## redis 各个数据类型的底层实现


---

## redis 的代码结构

以 redis-7.0.5 以例。   

几种数据类型的相关实现文件：t_hash.c，t_list.c，t_set.c，t_stream.c，t_string.c，t_zset.c，geo.c，hyperloglog.c。   


---

## redis 的持久化   

---

## redis 的多线程

1、截至 redis-7.0，处理命令的线程始终只有一个，只在其他逻辑支持多线程：后台处理、I/O。     


2、发展历史 

redis-2.6 之前，只有一条主线程。  

redis-2.6 之后，引入 2 个后台线程 bio_close_file、bio_aof_fsync，分别负责关闭文件、aof 刷盘。  

redis-4.0 之后，引入 1 个新的后台线程，负责异步释放内存，即 bio_lazy_free。  

redis-6.0 之后，引入 n 条 I/O 线程，负责分担主线程的 I/O 压力，通过配置（io-threads-do-reads yes ； io-threads n）开启，会额外启动 n-1 条 I/O 线程（主线程也算一条 I/O 线程）。  


3、小结    

从 redis-6.0 开始，默认情况下，redis-server 会创建 7 条线程[2]：   

* 1 条主线程：redis-server，负责处理命令，及部分 I/O；   
* 3 条后台线程：bio_close_file、bio_aof_fsync、bio_lazy_free，分别负责异步关闭文件，异步 aof 刷盘，异步释放内存；     
* 3 条 I/O 线程：io_thd_1、io_thd_2、io_thd_3，负责分担 redis 的网络 I/O 压力；  


---

# 2. 参考

[1] MrSatan. redis之bigkey（看这一篇就够）. Available at https://www.cnblogs.com/szq95716/p/14271108.html, 2021-01-13.    

[2] xiaolincoding. Redis 线程模型. Available at https://xiaolincoding.com/redis/base/redis_interview.html#redis-%E7%BA%BF%E7%A8%8B%E6%A8%A1%E5%9E%8B.   