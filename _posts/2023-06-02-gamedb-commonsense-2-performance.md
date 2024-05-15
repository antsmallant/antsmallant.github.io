---
layout: post
title: "游戏数据库常识二：常见数据库的 QPS，兼谈云数据库选型"
date: 2023-06-02
last_modified_at: 2023-06-02
categories: [数据库]
tags: [game, db, mysql, mongodb, redis]
---

* 目录  
{:toc}
<br/>


做架构设计的时候，对于数据库的基本性能，需要有一个比较清晰的把握：
* 知道它的性能上限。 
* 知道在特定硬件条件下的大致性能表现。 
* 能根据自己的业务特点估算出数据库的的大致性能消耗情况。 

# 架构设计时的性能估算

分区分服类型的游戏在数据库选型的时候没有什么特别需要注意的，单服的注册用户都不大，一般运营都会控制的。即使所谓的万人同服，导致单服注册量有 50万（很夸张了，实际上有些流行的小服生态，单服注册量就 5000 左右），也没啥问题，随便的 mysql 或 mongo 都支撑得了，完全不需要 sharding。  

但是全区全服就不一样了，这个的量可能很巨，跟大的互联网应用相当了，不说 1 亿注册量，就 1000 万好了，平均每人 10 个道具，那么道具表就上亿条数据了。数据量只是一方面，更重要的是 QPS，这里不谈 TPS，因为游戏的数据库使用是偏简单的，不怎么会使用复杂事务，基本上都是裸的执行 SQL 语句，所以用 QPS 考量就行了。  

这里
  

# 常见数据库的 QPS

---

## mysql 

阿里云上面只会展示 iops 这种比较纯粹的硬件性能指标，不会展示 qps、tps 这种与具体业务有关的性能指标。官网的原话是 “QPS和TPS需要RDS上面部署相关对象测试。同一个规格的实例在不同业务系统中，根据实现方法不同，QPS和TPS也会有较大的差距”[1]。   

公有云的云盘的 IOPS，不一定是按 mysql 的 innodb 默认页大小 16KB 计算的，像阿里云是 4 KB，所以 mysql 的一次读写要消耗 4 次 IO。  

但实际上，受限于 mysql 的工作方式，它的 qps 或 tps 始终是有一个相对明确的上限。特别是写性能，直接跟磁盘相关，以 innodb 为例，默认情况下（innodb_flush_log_at_trx_commit 参数为 1），每一次事务提交都要调用 fsync 把 redolog 刷到磁盘。  

这篇文章《数据库性能评测：整体性能对比》[2] 做了一次 mysql / mongodb / redis 的数据性能测试。  


mysql 官方 MySQL Benchmarks 推荐的几篇文章。  

https://www.mysql.com/cn/why-mysql/benchmarks/mysql/

## mysql 参考

* 阿里云官方 rds MySQL版 性能白皮书 
https://www.alibabacloud.com/help/zh/rds/apsaradb-rds-for-mysql/rds-for-mysql/
[阿里云官方：MySQL 8.0测试结果](https://help.aliyun.com/zh/rds/support/test-results-of-apsaradb-rds-instances-that-run-mysql-8?spm=a2c4g.11186623.0.0.218c4450qJquTB)

从这个测试结果来看，写 QPS 与 IOPS 的相关性很大，如果是纯写，那写 QPS 大致相当于 IOPS，而读 QPS 很难计算与 IOPS 的关系，因为它与 cache 有很大关系，如果 cache 命中率高（要么就是内存很大，要么就是数据局部性很好，索引建得很合理），那么读 QPS 要远远大于 IOPS，甚至几乎就是内存读。  

* 腾讯云官方 云数据库 MySQL 性能白皮书 性能测试报告 

https://cloud.tencent.com/document/product/236/68808


* [实测：云RDS MySQL性能是自建的1.6倍](https://www.cnblogs.com/zhoujinyi/p/16392223.html)

* [云厂商 RDS MySQL 怎么选](https://mp.weixin.qq.com/s?__biz=MzkxODMzMjk1Ng==&mid=2247483961&idx=1&sn=272534340ba46ddf4171611129c2b5f8&chksm=c1b3b14af6c4385c9c835d5a3de9cfe93ba8d2c95664f06404e6a91bcdc76efb20c3ef4c51ac&scene=21#wechat_redirect)


* [mysql QPS 过高问题处理](https://www.modb.pro/db/31741) 

* [MariaDB 10.1 can do 1 million queries per second](https://mariadb.org/10-1-mio-qps/)

QPS：Queries / Seconds 
Queries 是系统状态值--总查询次数
TPS：(Com_commit + Com_rollback) Seconds
每秒数据库执行的查询量即为QPS，它是衡量MySQL数据库性能的一个主要指标，但此查询量不仅包括select、DML语句，还包括其它如set类的操作，如果set类操作占比比较大的话，它很可能会影响到数据库的性能


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

---

## mongodb



---

## redis

* 阿里云 Redis社区版性能白皮书
https://www.alibabacloud.com/help/zh/redis/support/performance-whitepaper-of-community-edition-instances?spm=a2c63.p38356.0.0.60ef2601Y0TNXQ




---

# 参考

[1] 阿里云. 云数据库 RDS: 主实例规格列表#FAQ. Available at https://help.aliyun.com/zh/rds/product-overview/primary-apsaradb-rds-instance-types, 2023-05-22.   

[2] 李俊飞. 数据库性能评测：整体性能对比. https://cloud.tencent.com/developer/article/1005399, 2017-07-04.   