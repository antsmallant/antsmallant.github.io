---
layout: post
title: "redis 笔记一：常识、用法"
date: 2016-1-1
last_modified_at: 2024-7-10
categories: [数据库]
tags: [redis 数据库]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 redis 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

---

## 1.0 资料    

Redis 官网： [https://redis.io/](https://redis.io/)    

Redis Command 用法查询： [Redis Commands](https://redis.io/docs/latest/commands/)     

Redis Online Playground: [https://onecompiler.com/redis/](https://onecompiler.com/redis/)    

---

## 1.1 bigkey 的删除

这篇文章： [《redis之bigkey（看这一篇就够）》](https://www.cnblogs.com/szq95716/p/14271108.html) [1] 总结得很好。    

---

### 1.1.1 redis4.0 以前    

在 redis4.0 以前，bigkey 的删除，如果直接使用 del 命令，会阻塞主线程比较久，导致实例响应不了其他命令，大致的估算是每 100w 个 value item，耗时是 1 秒左右（不同设备不现配置性能是不同的）。  

所以，稳妥的做法是根据不同的数据结构，使用不同的方式进行分段删除。   

|key类型|删除方法|
|:--|:--|
|sortedset| zremrangebyrank，每次删除 top n 个|
|hash| 通过 hscan 取出 n 个 item，然后用 hdel 分别删除这 n 个item|
|set| 通过 sscan 取出 n 个 item，然后用 srem 分别删除这 n 个item|
|list| 通过 ltrim 每次删除 n 个元素|

---

### 1.1.2 redis4.0 以后 

在 redis4.0 以后，bigkey 的删除，可以使用 unlink 命令代替 del，unlink 一个 bigkey 的时候，redis 根据一定的规则评估释放 value 的耗时，当耗时可能超过阈值时，就会把 value 的释放安排到单纯的线程（bio）中去执行，从而避免阻塞主线程。  

具体的，在异步释放的时候，会使用一个评估函数 `lazyfreeGetFreeEffort`，评估得出的值大于阈值（`#define LAZYFREE_THRESHOLD 64`）时，就真正使用异步释放。  

大致可以理解为 hash/set/sortedset/list 这些的元素个数超过 64 个时，就会异步删除。   

`lazyfreeGetFreeEffort` 的源码在 [https://github.com/redis/redis/blob/unstable/src/lazyfree.c](https://github.com/redis/redis/blob/unstable/src/lazyfree.c) 。  

---

## 1.2 redis 的数据类型

参考自：[《Redis 常见数据类型和应用场景》](https://xiaolincoding.com/redis/data_struct/command.html) [2]。    

---

### 1.2.1 常用数据类型

常用的有 5 种：String，List，Hash，Set，Zset。    

|数据类型|存储内容|支持的操作|底层实现|
|--|--|--|--|
|String|存储字符串、整数、浮点|操纵字符串；加减数字值|long long 或 SDS（简单动态字符串）|
|List|双向链表，长度可达2^32-1，可存储字符串|常规的链表操作|3.2之前: 压缩列表或双向链表；3.2之后： quicklist|
|Hash|键值对的无序散列表|添加、获取、删除元素|7.0之前: 压缩列表或哈希表；7.0之后: listpack或哈希表|
|Set|字符串的无序集合|添加、获取、删除元素；集合操作：交集、差集、并集；随机选取 n 个元素|整数集合或哈希表|
|Zset|又叫 Sorted Set，有序集合，存储字符串与浮点型分数的有序键值对，以分数的大小排序|添加、获取、删除元素；根据分值范围、排名范围、分值获取元素|7.0之前：压缩列表或跳表；7.0之后：listpack 或跳表|

---

### 1.2.2 其他数据类型    

其他的还有 4 种：Bitmap（2.2新增），HyperLogLog（2.8新增），Geo（3.2新增），Stream（5.0新增）。    

|数据类型|存储内容|支持的操作|底层实现|
|--|--|--|--|
|Bitmap|位图，相当于以位级别存储0、1 的数组|设置、获取比特位；获取0或1出现的首个位置；0、1计数；对多个key进行位操作：与、或、非、异或|基于 String 类型|
|HyperLogLog|海量数据的非精确基数统计，误差约为0.81%，可以统计 2^64-1 个元素的基数|添加元素；元素计数；合并多个 HyperLogLog|使用 HyperLogLog 算法，占用空间约 12 KB 左右|
|Geo|地理位置集合，每个位置包含三个项：longitude、latitude、位置名|添加、获取位置；计算位置的距离；获取指定坐标&半径范围内的位置|基于Sortedset实现，利用Geohash算法把经纬度换算成权重分数|
|Stream|相对靠谱的消息队列，支持自动生成全局唯一id|插入、读取、删除、查询单个消息；读取区间消息；按消费组形式读取消息；消息确认|基数树+listpack|

<br/>

**关于 HyperLogLog**   

HyperLogLog 可以做的事情是这样的，比如要统计网页的日 uv，即当天的独立用户访问个数，这种是需要对用户去重的。如果使用 set 也可以实现，但问题在于数据量可能会很大，而 HyperLogLog 是基于概率的，会算出字符串的哈希，再经过一些概率算法操弄，就可以用有限的内存占用，实现这种有损的 “基数统计”，说白了就是去重统计。误差约为0.81%，在海量数据的场景下，这种误差应当是可以接受的。    

<br/>

**关于 Stream**    

Stream 虽然是专门实现的消息队列，但始终谈不上专业。首先，它可能会丢消息，因为 redis 的 aof 本身就做不到可靠的持久化，更不用说它不支持多副本写入，单点挂了就挂了。其次，消息堆积能力受限于内存，内存不足直接 oom 了。    

所以，Stream 只能用于一些不是很追求可靠性的场景，即使崩了也无所谓的那种。正经的消息队列还是用回 RabbitMQ、kafka 之类的。  

---

### 1.2.3 数据类型的使用场景

|数据类型|场景|
|--|--|
|String|缓存对象；计数；分布式锁；共享 session 信息|
|List|简易的消息队列，完全不考虑可靠性的情况下可以使用|
|Hash|缓存带有多个field的对象|
|Set|点赞、共同关注、抽奖|
|Zset|排行榜|
|Bitmap|签到统计；判断用户登录态；连续签到用户总数|
|HyperLogLog|百万级以上的网页uv计数|
|Geo|LBS 类的应用：附近的人，附近的车|
|Stream|专业一点的消息队列，不太严谨的场合下可以使用|


<br/>

Bitmap 统计连续签到用户总数的具体做法：   

假设要统计连续 3 天签到的用户，则分为 3 个 key 来存：sign_day1, sign_day2, sign_day3，这其中每个用户 id 映射到 sign_dayx 中的某个 bit 位，比如 `setbit sign_day1 1001 1` 就设置了第 1 天 id 为 1001 的人签到。    

之后，使用 `bitop and sign_stat sign_day1 sign_day2 sign_day3` 将这3天的统计进行位与的操作并把结果存放到 sign_stat 中。如果一个用户连续 3 天都签到，那么他那个 bit 的位与结果就是 1。  

这时候统计 sign_stat 中 1 的个数即是连续 3 天都签到的用户个数：`bitcount sign_stat`。   

<br/>

---

## 1.3 redis 的底层数据结构  

面向用户的数据类型，其底层往往不止使用一种数据结构，redis 会根据数据量的大小，选择性能上最优的数据结构，上面已经讲到了。   

接下来描述几种数据结构的实现。   

---

## 1.4 redis 源码的代码结构

以 redis-7.0.5 以例。   

几种数据类型的相关实现文件：t_hash.c，t_list.c，t_set.c，t_stream.c，t_string.c，t_zset.c，geo.c，hyperloglog.c。   

要看某个数据类型的命令的具体实现，就看上面的实现文件，比如 String 的 incrby 命令，就可以看 t_string.c 里面的 `incrCommand` 函数。   


---

## 1.5 redis 的持久化   

参考自：[《Redis 持久化》](https://xiaolincoding.com/redis/base/redis_interview.html#redis-%E6%8C%81%E4%B9%85%E5%8C%96)[3]。 

---

### 1.5.1 持久化的机制分类

1、有 2 种持久化机制，组合起来，相当于有 3 种：1、aof 日志；2、rdb（快照）；3、aof + rdb 混合。    

2、无论是 aof 还是 rdb，都无法百分百保证不丢数据，即使 aof 的 `appendfsync` 配置项设置成 `Always`，也可能丢数据，因为 redis 并没有使用类似于 wal 的机制，而是简单的先改内存，再写 aof。   

---

### 1.5.2 aof   

1、aof 的基本实现

每一条写入命令就写一条日志，恢复的时候，顺序重放所有命令即可。执行命令的时候，是先改内存，再写 aof 日志。   


2、aof 重写    

如果一直 append aof 日志，那么 aof 日志文件将无限增大，恢复时间将特别长，所以 redis 支持 aof 重写。即根据当前的一个数据快照，重新生成所有的 aof 日志，比如先前有两次对同个 key 的写入命令，`set name "hello"`，`set name "world"`，重写之后就只剩下最新的一条：`set name "world"`。   

重写的过程：   
1）aof 重写的时候，redis 会 fork 一个子进程出来，也是依赖 cow 机制，子进程可以用父进程的数据副本来完成快照数据的 aof 重写。  

2）重写期间如果有新的 aof 日志产生，主线程会把 aof 日志写两份：一份写到 aof 缓冲区，另一份写到 aof 重写缓冲区。  

3）子进程在完成快照的重写之后，就通知父进程，父进程接着完成两件事情：往这份新的 aof 文件追加 aof 重写缓冲区的内容；然后做 aof 文件的切换。    


3、appendfsync 的三种配置值      

aof 相关的配置是 appendfsync，用于控制 aof 日志刷盘的时机，刷盘在 linux 即是调用 fsync 命令，阻塞的等待数据写入硬盘中。   

|配置值|意义| 
|--|--|
|Always|每次写都立即写回（fsync）|
|Everysec|每秒写（fsync）|
|No|由操作系统控制写回时机|

---

### 1.5.3 rdb    

rdb 每次都是生成全量的快照，是一个比较重的操作。生成 rdb 有两个命令，一个是 save，另一个是 bgsave。  

save 是由主线程完成，这个会阻塞直到写入完成。bgsave 是由 fork 出来的子进程完成的，利用了 linux 的 cow 机制，可以用比较少量的物理内存占用，异步的完成快照的写入。   

rdb 的典型配置：    

```
save 900 1
save 300 10
save 60 10000
```

这里的 save 是 bgsave 的意思，save 900 1 表示 900 秒内有 1 个写入就执行 bgsave；save 300 10 表示 300 秒内有 10 次写入就执行 bgsave，依此类推。  

---

### 1.5.4 混合持久化 aof + rdb   

redis-4.0 开始支持混合持久化，即 aof + rdb。aof 的优点是丢数据少，缺点是恢复很慢；rdb 的优点是恢复快，缺点是备份的代价高、丢数据会比较多。   

混合持久化是在 aof 重写的过程进行的： 

1）fork 出来的子进程会利用 cow 机制，用父进程的数据副本生成 rdb 快照数据并写入新的 aof 文件。

2）rdb 完成后通知主线程追加新增的 aof 命令（存在于 aof 重写缓冲区）。 

3）追加完成后，主线程完成 aof 文件的切换。    

---

## 1.6 redis 的多线程

1、截至 redis-7.0，处理命令的线程始终只有一条，只在其他逻辑支持多线程：后台处理、I/O。     


2、发展历史 

redis-2.6 之前，只有一条主线程。  

redis-2.6 之后，引入 2 条后台线程 bio_close_file、bio_aof_fsync，分别负责关闭文件、aof 刷盘。    

redis-4.0 之后，引入 1 条新的后台线程，负责异步释放内存，即 bio_lazy_free。   

redis-6.0 之后，引入 n 条 I/O 线程，负责分担主线程的 I/O 压力，通过配置（io-threads-do-reads yes ； io-threads n）开启，会额外启动 n-1 条 I/O 线程（主线程也算一条 I/O 线程）。   


3、小结    

从 redis-6.0 开始，默认情况下，redis-server 会创建 7 条线程[4]：   

* 1 条主线程：redis-server，负责处理命令，及部分 I/O；   
* 3 条后台线程：bio_close_file、bio_aof_fsync、bio_lazy_free，分别负责异步关闭文件，异步 aof 刷盘，异步释放内存；     
* 3 条 I/O 线程：io_thd_1、io_thd_2、io_thd_3，负责分担 redis 的网络 I/O 压力；  


---

# 2. 参考

[1] MrSatan. redis之bigkey（看这一篇就够）. Available at https://www.cnblogs.com/szq95716/p/14271108.html, 2021-01-13.    

[2] xiaolincoding. Redis 常见数据类型和应用场景. Available at https://xiaolincoding.com/redis/data_struct/command.html.  

[3] xiaolincoding. Redis 持久化. Available at https://xiaolincoding.com/redis/base/redis_interview.html#redis-%E6%8C%81%E4%B9%85%E5%8C%96.   

[4] xiaolincoding. Redis 线程模型. Available at https://xiaolincoding.com/redis/base/redis_interview.html#redis-%E7%BA%BF%E7%A8%8B%E6%A8%A1%E5%9E%8B.   