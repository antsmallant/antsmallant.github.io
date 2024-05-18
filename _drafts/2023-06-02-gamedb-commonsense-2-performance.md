---
layout: post
title: "游戏数据库常识二：常见数据库的 qps，兼谈云数据库选型"
date: 2023-06-02
last_modified_at: 2023-06-02
categories: [数据库]
tags: [game, db, mysql, mongodb, redis]
---

* 目录  
{:toc}
<br/>


做架构设计的时候，对于数据库的基本性能，需要有一个比较清晰的把握，比如：  

* 数据库的性能上限是多少？数据库能怎么扩容？是 scale up 还是 scale out？
* 数据库在特定硬件下的大致性能表现？
* 自己的业务特点：是读多写少，还是读少写多，读写比例大致是多少？数据量会是什么规模？

---

# 常见数据库的 qps

---

## 几个关键概念

先说下几个关键概念：  

|缩写|完整|意义|
|:---|:---|:---|
|tps|Transactions Per Second|数据库指标，每秒执行的事务数|
|qps|Queries Per Second|数据库指标，每秒执行的查询数（即 SQL 语句条数）|
|iops|Input/Output Operations Per Second|磁盘指标，每秒执行的 io 读写次数|


说明：  

* tps 跟 qps 这两个指标没有一个很明确的标准，跟测试数据集、测试方式有巨大的关系。   

* tps 通常是低于 qps 的，因为一个事务往往是包含好几条 sql 语句的。   

* sql 语句不止 select/insert/delete/update 这些，像 `set autocommit = 1;` 这种语句也会统计到 qps 中。  

* 下面都用 qps 描述 mysql / mongodb / redis 的性能，意为每秒执行的读写命令次数。  

---

## 数据来源

网上会有一些自建自测的文章，但实际上这个挺难测的，测试结果跟测试方法有很大关系，比如点数据读写，区间数据读写，索引读写，非索引读写。   

所以我直接上各大公有云参考上面的性能白皮书，虽然都有各自的立场，但数据应该不至于离谱，有一定参考价值。   

---

## mysql

基本上都是用 innodb 引擎的，所以下面论述都是使用 innodb 来讲。  

innodb 的读写 qps 差异很大。如果内存足够大，数据局部性足够好，那么读基本上都会命中 cache，读磁盘比较少，读 qps 会特别高。而写的话，如果按默认设置（innodb_flush_log_at_trx_commit 设为 1），则每次写，都是要至少刷一次磁盘的（fsync），那么写 qps 就跟磁盘的 iops 强相关了。   


**阿里云**

从阿里云的这份性能白皮书《MySQL 8.0测试结果》[4] 来看（要注意，表格展示的读写次数是 60 秒的总值，要除以 60 才能得到 qps），读 qps 确实很难跟磁盘 iops 计算出某种比例关系，但是写 qps 跟磁盘 iops 的关系很显著，按阿里云的测试，基本上写 qps 约为 iops 的 95% 左右。

![aliyun-mysql8-qps](https://blog.antsmallant.top/media/blog/2023-06-11-game-db/aliyun-mysql8-qps.jpeg)  
<center>图 aliyun-mysql8.0-qps</center>

**腾讯云**



**华为云**

华为云的 RDS 性能白皮书，比如这份《RDS for MySQL 8.0测试数据 独享型测试数据》[5]，我个人觉得写得不太好，它没有明确把磁盘 iops 列出来，这个对于写 qps 影响很大，所以它的测试数据对我来说参考意义很小。   


小结： 

* mysql 的写 qps 与 iops 关系很大，可以估算为 iops 的 80% ~ 95% 左右，公有云提供的产品大致 iops 范围是 ，上限差不多是 5 万左右。  

* mysql 的读 qps 与 iops 有关系，但与内存的关系更大，上限差不多是 25 万左右。  

---

## mongodb


小结：  

* mongodb 的单机性能大

---

## redis

从阿里云的这份《Redis社区版性能白皮书》[3]来看，redis（6.0）的读写性能在 10 万 ~ 20 万之间，大致在 10 万左右。如果 value 比较大（超过 2KB）或者一些特别的命令如 MSET，可能性能会打折扣，比如降到 5~6 万左右。  

![aliyun redis6 qps](https://blog.antsmallant.top/media/blog/2023-06-11-game-db/aliyun-redis6-qps.jpeg)  
<center>图 aliyun redis6 qps</center>

从 redis 官网的 benchmark [6] 来看，redis 的读写 qps 大致也是在 10 万这个量级的。  

小结：  

* redis 单机读写 qps 大致均在 10 万左右。   

---

# 架构设计时估算数据库的性能需求

说一下游戏行业在做架构设计时，数据库这块需要考虑的点。   

---

## 分区分服的游戏

在数据库选型的时候没什么特别需要注意的，因为单服的注册用户都不大，一般运营都会刻意控制单服注册量的。即使所谓的万人同服，单服注册量也不会多于 50 万（50 万已经很夸张了，实际上有些做小服生态的游戏，单服注册量就 2000 左右）。50 万注册量没啥问题，随便的 mysql 或 mongo 都支撑得了，不需要做任何 sharding。当然，合服会导致一个库的数据量越来越大，但也没问题，因为 dau 也不会多高的，qps 要求并不高。    

---

## 全区全服的游戏

在数据库造型的时候就要特别小心了，这个量可能会很巨，跟大的互联网应用相当。不说 1 亿注册量，就 1000 万好了，平均每人 10 个道具，那么道具表就上亿条数据了。数据量只是一方面，更重要的是 qps，这里不谈 tps，因为游戏服务器对数据库的使用是偏简单的，基本不会使用复杂事务，就是些基本的 SQL 语句，所以用 qps 考量就行了。  

做架构设计的时候，需要仔细估算，要精细到每个玩家在每个场景会有多少次数据库读写，比如：账号注册，创角，登录验证，加载角色数据，回写数据 ...

再结合这些数据：每秒登录用户数峰值，每秒新增用户数峰值，最高同时在线人数，数据定时回写的间隔，就可以大致估算出数据库的读写 qps 峰值。  

注意，读写要分开计算。为啥呢？因为一般数据库，比如 mysql (用 innodb 引擎) ，读和写的 qps 会有很大差异。  

如果内存够大，它可以有很大的 cache，cache 命中率会很高，不怎么需要读磁盘，读 qps 就特别高。而写呢，如果按默认配置，`innodb_flush_log_at_trx_commit` 设置为 1，即每次事务提交都要 fsync，那么就会受限于磁盘的 iops，按照经验，如果只是做一些在普通小数据量的 insert、update、delete 情况下，写 qps 大致是磁盘 iops 的 80% ~ 90% 左右。   

---

小结：  

* 分区分服的，不需要太关注数据库性能问题，写代码时候不要太离谱就行。  

* 全区全服的，要精细计算，结合用户规模，做出估算。  

---

# 总结

1、常见数据库qps归纳如下

声明：以下只是大略估计，算是某种大致印象，因为性能情况跟测试数据跟测试方法的关系非常紧密，具体做架构设计的时候要结合自己的业务情况做计算。  

|数据库|读qps上限|写qps上限|说明|
|:---|:---|:---|:---|
|mysql5.7|10万|5万|写与iops强相关，约为80%~95%左右；读与内存关系更大，cache命中差时才与iops强相关|
|mongodb||||
|redis6.0|10万|10万|get相对高些，在value小的时候可以达到20万，但普遍来看，大都在10万左右，一些特别的命令如mset，在5万左右|

2、可以直接到公有云具体产品的文档中找“性能白皮书”，里面的性能测试还是比较正规的，有一定参考价值。  

---

# 参考

[2] 李俊飞. 数据库性能评测：整体性能对比. https://cloud.tencent.com/developer/article/1005399, 2017-07-04.   

[3] 阿里云. Redis社区版性能白皮书. Available at https://help.aliyun.com/zh/redis/support/performance-whitepaper-of-community-edition-instances, 2023-10-20.  

[4] 阿里云. MySQL 8.0测试结果. Available at https://help.aliyun.com/zh/rds/apsaradb-rds-for-mysql/test-results-of-apsaradb-rds-instances-that-run-mysql-8, 2023-11-24.  

[5] 华为云. RDS for MySQL 8.0测试数据：独享型测试数据. Available at https://support.huaweicloud.com/pwp-rds/rds_swp_mysql_12.html, 2022-12-22.  

[6] redis. Redis benchmark. Available at https://redis.io/docs/latest/operate/oss_and_stack/management/optimization/benchmarks/.

---


# 资料收集
这篇文章《数据库性能评测：整体性能对比》[2] 做了一次 mysql / mongodb / redis 的数据性能测试。  


mysql 官方 MySQL Benchmarks 推荐的几篇文章。  

https://www.mysql.com/cn/why-mysql/benchmarks/mysql/

* 阿里云官方 rds MySQL版 性能白皮书 
https://www.alibabacloud.com/help/zh/rds/apsaradb-rds-for-mysql/rds-for-mysql/
[阿里云官方：MySQL 8.0测试结果](https://help.aliyun.com/zh/rds/support/test-results-of-apsaradb-rds-instances-that-run-mysql-8?spm=a2c4g.11186623.0.0.218c4450qJquTB)

从这个测试结果来看，写 qps 与 iops 的相关性很大，如果是纯写，那写 qps 大致相当于 iops，而读 qps 很难计算与 iops 的关系，因为它与 cache 有很大关系，如果 cache 命中率高（要么就是内存很大，要么就是数据局部性很好，索引建得很合理），那么读 qps 要远远大于 iops，甚至几乎就是内存读。  

* 腾讯云官方 云数据库 MySQL 性能白皮书 性能测试报告 

https://cloud.tencent.com/document/product/236/68808


* [实测：云RDS MySQL性能是自建的1.6倍](https://www.cnblogs.com/zhoujinyi/p/16392223.html)

* [云厂商 RDS MySQL 怎么选](https://mp.weixin.qq.com/s?__biz=MzkxODMzMjk1Ng==&mid=2247483961&idx=1&sn=272534340ba46ddf4171611129c2b5f8&chksm=c1b3b14af6c4385c9c835d5a3de9cfe93ba8d2c95664f06404e6a91bcdc76efb20c3ef4c51ac&scene=21#wechat_redirect)


* [mysql qps 过高问题处理](https://www.modb.pro/db/31741) 

* [MariaDB 10.1 can do 1 million queries per second](https://mariadb.org/10-1-mio-qps/)


* mysql 自动开启事务默认提交模式，每条语句都会被当成一个独立的事务自动执行。  

* [数据库性能评测：整体性能对比](https://cloud.tencent.com/developer/article/1005399)

* innodb_flush_log_at_trx_commit
0: 由mysql的main_thread每秒将存储引擎log buffer中的redo日志写入到log file，并调用文件系统的sync操作，将日志刷新到磁盘。

1：每次事务提交时，将存储引擎log buffer中的redo日志写入到log file，并调用文件系统的sync操作，将日志刷新到磁盘。

2：每次事务提交时，将存储引擎log buffer中的redo日志写入到log file，并由存储引擎的main_thread 每秒将日志刷新到磁盘。

|参数值|mysqld crash|宿主机 crash|
|--|--|--|
|0|可能丢|可能丢|
|1|不会丢|不会丢|
|2|不会丢|可能丢|

0 < 2 < 1