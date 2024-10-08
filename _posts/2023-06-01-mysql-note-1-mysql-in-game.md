---
layout: post
title: "MySQL 笔记：MySQL 在游戏中的使用"
date: 2023-06-01
last_modified_at: 2023-06-01
categories: [数据库]
tags: [game db MySQL]
---

* 目录  
{:toc}
<br/>


数据库在游戏后端开发中，是一个比较重要的部分，如果缺乏基本的常识，将导致灾难性的后果。所以，本文将写一写游戏开发中需要知道的数据库常识。  

游戏行业，用得多的数据库无非就这几种：mysql, mongodb, redis。恰好这几种都用过，可以讲一讲。  

从更大的角度讲就是存储了，还包括 etcd，运行日志，流水日志等等，但本文不打算外延，到时再另写一篇讲一讲广义上的存储。日志类存储很值得讲一讲，因为日志数据非常重要，需要规划好怎么存储，想好怎么利用。  

本文先讲一讲 mysql。   

---

# 1. mysql

mysql 可能是用得最多的吧，无论是分区分服游戏，或是全区全服游戏，都能使用。   

分区分服的游戏，用 mysql 完全是够的，一般是一个服对应一个db，而一个服活跃的用户一般不会很多，最高同时在线通常是几百上千人，也有比较厉害的所谓万人同服，问题也不大。  

实际部署的时候有一些选择，比如:   

* 部署一个 mysql 进程，只服务于本机上开的各个区服，这种情况下假定一个物理机上会开多组区服，并且相对固定；

* N 个物理机部署一个 mysql 进程，服务多个物理机上运行的多个区服；


全区全服的游戏，用 mysql 就需要一些技巧以及规范了，否则会遇到比较严重的容量问题。这种情况下，同时在线人数可多可少，好的游戏几百万人，上千万人同时在线都很正常，我做过的一款上线的游戏，最高在线有30多万人，这时 db 的压力已经是挺大的了。  

在早期，人们通常是使用原始的分库分表策略来解决大数据量的负载问题，通常的做法是这样的，在代码层面增加数据访问的 proxy 模块，这个 proxy 模块屏蔽了分库分表的细节。proxy 一般会选取某些特定的键来进行 hash，通常是使用 uid，如果总共分4个库，那么 uid%4 就决定了数据要路由到哪个库。  

这种做法要扩容的时候是很麻烦的，如果要从 4 个库扩容成 8 个库，或 16 个库，都需要把每个库的数据按照新的 hash 结果分拆出来。为了避免这种麻烦，有一种做法是这样的，先假定一个总容量上限，然后一开始就固定分成足够多的库，比如说 16 个库。一开始的时候，这 16 个库可以先部署在同个物理机上。需要扩容的时候，比如说扩容一倍性能，就把这 16 个库中的一半，分拆到另一个物理机上，这时候只需要简单的把其中的 8 个库原样拷贝过去，不需要依据 hash 结果分拆。之后就依此法扩容，最终结果就是 16 个库分别部署到 16 个物理机。  

上面做法的一个小小的进阶版本是，由一个数据库中间件来负责负载均衡。   


要注意一些什么问题呢？下面列一列。  

---

## 1.1 引擎

使用 innodb 应该是一个共识了吧，绝大部分情况下都应该使用 innodb，因为它支持事务，支持行级锁。innodb 在故障后通常可以自动恢复正常，不会有文件损坏，因为它的 redo log 确保了事务的持久性，undo log 确保了事务的原子性，总之，支持事务的引擎会有故障恢复能力（在硬盘没有损坏的前提下）。而像 myisam 这样的不支持事务的引擎，在崩溃的时候，容易丢数据，并且大部分情况下需要手动修复数据。  

简单介绍一下 innodb，它默认是使用 B+ 树作为索引，为何使用 B+ 树呢？很多文章都要论述到，通常就是拿 B-树 跟 B+ 树作比较。  

首先一个前提，要选用一种硬盘友好型的算法，B-树、B+树都是硬盘友好型，但其中 B+ 树更胜一筹，它规定只有叶子节点能存数据，那么非叶节点可以存更多的键，所以 B+ 树的高度会更矮，读写性能也就更高。  

其次，B+ 树适合做范围搜索，B+ 树最底层的叶子节点有指针相连，可以在指定的范围内按索引顺序遍历数据。  

![Bplustree](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/game-db-Bplustree.png)  
<center>图1：B+树[1]</center>

---

## 1.2 索引

索引永远是最重要的问题，不能多，也不能少，刚刚好，性能就最好。否则动不动在那里扫描一张大表，mysql 工作起来好难受的，除非有好几个 T 的内存给你折腾。即使有这么多内存，效率也是不高。  

索引需要记住的原则主要包括：  

* 联合索引最左侧匹配原则；

* 限制索引的条数，并不是越多越少，一定要按需加索引；  

* 选择区分度高的列来作为索引，区分度的公式是count(distinct col)/count(*)，表示字段不重复的比例，如果一个列的值的范围就很有限的若干值，那就没有加索引的必要；

---

## 1.3 好的实践

云数据库是不错的选择，现在的云数据库可以方便的做主从热备、故障切换、异地灾备，还有非常完善的性能监控、性能告警。阿某云还有更高级的特性：SQL 洞察，这个功能可以从很多维度查看 db 的性能消耗，比如不走索引的 SQL、特定 SQL 的总时间占据，非常合适作为数据库优化的参考，也适合每次新版本上线后发现 SQL 性能问题。  

---

## 1.4 分区分服的粗暴做法

分区分服的并发读写量都不高，怎么折腾都问题不大。有一种对于开发来说比较省力的办法，就是用 text 或 blob 类型来存储序列化后的数据，比如一个玩家 role 有几百个属性，那么直接用一种序列化的方法把它们序列化成一串二进制或是字符串，然后直接以 kv 的方式写入，role 表结构就两个字段：uid、value。  

这种做法对于读来说比较友好，不需要读多张表，减少了 IO 次数；对于写就比较不友好，修改一个字段也需要序列几百个字段，对数据库 IO 吞吐的压力会比较大。  

序列化可以直接使用 protobuf，如果用 skynet 的话，可以使用 sproto（有些游戏的确是这么做的，比如某著名 slg：rok）。  

---

# 2. 参考

[1] GeeksforGeeks. Introduction of B+ Tree. Available at https://www.geeksforgeeks.org/introduction-of-b-tree/, 2024-3-8.   