---
layout: post
title: "mongodb 笔记：常识"
date: 2015-12-01
last_modified_at: 2024-7-10
categories: [数据库]
tags: [mongodb 数据库]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 mongodb 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

---

## 1.0 mongodb 资料  

MongoDB manual: [https://www.mongodb.com/zh-cn/docs/manual/](https://www.mongodb.com/zh-cn/docs/manual/)   


---

## 1.1 mongodb 支持外键吗？  

mongodb 没有类似于关系数据库的外键机制。   

只能是通过引用或嵌套文档，建立起文档间的关系，然后在应用层去做完整性的判断。   

---

## 1.2 ObjectID 的构成 

是一个 12 字节的 bson 类型，构成如下：  
4 字节时间戳，单位是秒；  
3 字节机器标识；
2 字节进程 id；
3 字节计数器；  

用 16 进制表示就是一个 24 个字符的字符串。ObjectID 几乎是唯一的，但不能保证百分百唯一，计数器可能会溢出。   

在 python 中，可以这样生成一个 ObjectID：  

```python
from bson.objectid import ObjectId
ObjectId()
```

---

## 1.3 默认情况下，MongoDB 为每个集合创建什么索引？  

默认创建一个名为 `_id` 的索引，它是一个 ObjectID。   

---

## 1.4 MongoDB 的管理与命令

---

### 1.4.1 数据库管理 

有3个默认的数据库: admin, local, config。   


1、查看所有数据库    

`show dbs;` 或 `show databases;`   


2、查看当前数据库    

`db;`    


3、切换数据库   

`use <dbname>;`   


4、删除当前数据库     

`db.dropDatabase();`     


---

### 1.4.2 集合管理  

1、查看所有集合   

`show collections;`     


2、创建集合   

`db.createCollection("<collection>");`  


3、删除集合    

`db.<collection>.drop();`      


---

### 1.4.3 索引管理   

官方文档：[https://www.mongodb.com/zh-cn/docs/manual/indexes/](https://www.mongodb.com/zh-cn/docs/manual/indexes/)   

<br/>

1、创建索引     

`db.<collection>.createIndex(<keys>, <options>)`     

比如：      
创建复合索引 `db.abc.createIndex({userid: 1, grade: -1})`，userid 是升序，grade 是降序。  

创建单字段索引 `db.abc.createIndex({score:1})`, 创建了 score 字段的索引，升序。  

创建 text 索引 `db.abc.createIndex({address:"text"})`。  


2、查询索引    

`db.<collection>.getIndexes();`   


3、删除索引    

`db.<collection>.dropIndex(<keys>)`     

比如： `db.abc.dropIndex({userid: 1,})`    


4、删除所有索引

`db.<collection>.dropIndexes()`    

---

### 1.4.4 CRUD   

官方文档： [https://www.mongodb.com/zh-cn/docs/manual/crud/](https://www.mongodb.com/zh-cn/docs/manual/crud/)    

<br/>   

1、插入      

`db.<collection>.insertOne(<document>)`   

`db.<collection>.insertMany([<document>, ..., <document>])`   

`<document>` 是 kv 结构的 table: `{k1:v1, k2:v2, ...}`    


2、查询     

`db.<collection>.find({key:value or conditions})`    


3、更新     

`db.<collection>.update({key:value}, {$set, {newkey:newvalue}})`    


4、删除        

`db.<collection>.deleteOne({key:value or conditons})`   

`db.<collection>.deleteMany({key:value or conditons})`    

比如 `db.abc.deleteOne({num:{$lt:50}})`, 删除 abc 集合中，num 字段小于 50 的一个文档。  


---

## 1.5 MongoDB 的索引 

参考自： [《MongoDB 概念及基础CRUD》](https://blog.csdn.net/weixin_38980638/article/details/136994894) [1]

|索引名称|简介|
|--|--|
|Single Field	      |单字段的 升序/降序 索引|
|Compound Index	      |复合索引|
|Multikey Index	      |数组值索引，可以给一个字段值为数组的字段中的一个或多个字段进行索引|
|Geospatial Index	  |地理坐标索引，提供了2d indexes(平面几何) 和2dsphere indexes(球面几何)|
|Text Search Indexes  |支持文本搜索的索引,类似于elasticsearch|
|Hashed Indexes	      |HASH索引，提供最快的值查询，但不支持范围查询|
|Clustered Indexes	  |clustered collections支持的index|


---

## 1.6 MongoDB 的持久化

MongoDB 的日志叫 journal。   

---

### write concern

`write concern` 是用于控制数据持久化的保证级别。   

要注意公有云的性能测试使用的测试方法，比如腾讯云的这个测试方法： https://cloud.tencent.com/document/product/240/106644 ， "w = 0表示写操作不需要确认，即不需要等待写操作的响应"，也就是说，测试时都是不确认是否写成功就返回的。     

基本格式：  

```
{w: <value>, j: <boolean>, wtimeout: <number>}
```

`write concern` 大致可以分为下面几种类别 [2]：   

1、`{w: 0}` 表示写不确认，不确认写操作是否完成，可能发生数据的丢失。  

2、`{w: 1}` 表示写确认，为 MongoDB 5.0 以前的默认行为。默认写操作在内存中完成，但由于还没有持久化，依然可能发生数据丢失。  

3、`{j: true}` 表示日志 (journal) 确认。确认写操作已完成并刷到持久化存储的 WAL 中，写操作不会丢失。  

4、`{w: "majority"}` 表示大多数（majority），为 MongoDB 5.0 及以上版本的默认行为。等待写操作被复制到副本集大多数节点上后才确认，数据不会被回滚。   


关于 write concern 的一些注意点 [2]：    

* 可以设置服务器的默认的 write concern，操作的 write concern 的优先级高于服务端设置的 write concern。    

* 因果一致性会话里，必须使用 "majority" 的 write concern。   

* 副本集中的隐藏节点、延迟节点、或其他优先级为0的可投票节点均可视为 "majority" 中的一员。   

* 当写入 local 库时，write concern 会被忽略。    


参考： 

* [《阿里云-云数据库MongoDB版-事务与Read/Write Concern》](https://help.aliyun.com/zh/mongodb/use-cases/transactions-and-read-write-concern)   

* [《MongoDB Manual write concern》](https://www.mongodb.com/zh-cn/docs/manual/reference/write-concern/)


---

## 1.7 MongoDB 分片集群 (sharding cluster)

---

### 一些参考文章 

* [《mongodb manual 分片》](https://www.mongodb.com/zh-cn/docs/manual/sharding/)  

* [《Mongo进阶 - DB核心：分片Sharding》](https://pdai.tech/md/db/nosql-mongo/mongo-z-sharding.html)    

* [《火山引擎 - MongoDB 分片集群使用指南》](https://www.volcengine.com/docs/6447/1185247)    

* [《mongodb的底层是怎么实现的？》](https://www.zhihu.com/question/316097977/answer/2432202296)    

* [《MongoDB分片迁移原理与源码（1）》](https://cloud.tencent.com/developer/article/1608372)   

* [《MongoDB分片迁移原理与源码（2）》](https://cloud.tencent.com/developer/article/1609526)    

* [《杨亚洲的源码注释及一些文章链接》](https://github.com/y123456yz/reading-and-annotate-mongodb-5.0)   

* [《杨亚洲 - 万亿级数据库MongoDB集群性能优化及机房多活容灾实践》](https://zhuanlan.zhihu.com/p/343524817)   

---

### todo

单机性能的参照。      
分片集群性能的参照。       
分片集群会有什么瓶颈？    
分片集群实际使用过程会遇到什么问题？       

---

### 分片集群的构成 




---

### sharding 的源码实现

参考：  

* [mongodb 数据块的迁移流程介绍](https://www.cnblogs.com/xinghebuluo/p/16154158.html)     
* [mongodb 数据块迁移的源码分析](https://www.cnblogs.com/xinghebuluo/p/16461068.html)     


---

### 分片集群的使用时机  

参考这篇文章： [MongoDB: Why Avoid Sharding, it should be kept as the last option.](https://medium.com/geekculture/mongodb-why-avoid-sharding-it-should-be-kept-as-the-last-option-cb8fdc693b66) 。  

这篇文章说的是尽量不要选择 sharding，除非不得不。   

如果综合考虑后，一定要做 sharding，必须特别关注 shard key 的选择，这个是最重要的，否则负载的不均衡会是个特别的麻烦。  

除此之外，还需要注意 "Scatter Gather Query" 问题，即细碎收集式的查询：需要从多个 shard 取数据再聚合起来返回，这样会大大降低查询的性能。   

关于 shard key 是否可以改变的问题：   

MongoDB 4.2 及之前，shard key 是不能变的；  
MongoDB 4.4 开始，可以通过增加后缀字段的方式来改善 shard key； （todo：？这个仍然需要搞清楚）
MongoDB 5.0 开始，可以改变一个集合的 shard key 来 reshard。  

然而，虽然能改变或更新 shard key，但 reshard 可能会导致负载过重，而严重影响正常业务。   


### MongoDB 5.0 之后的 reshard

Manual: 

reshard 操作命令：  

```
reshardCollection: "<database>.<collection>", key: <shardkey>
```

---

### 分片键的选择 

参考： [《腾讯云-云数据库 MongoDB-分片集群使用注意事项》](https://cloud.tencent.com/document/product/240/44611)     

* 取值基数  

* 取值分布  

* 查询带分片

* 如果是范围分片，要避免单调递增或递减


---

### 哈希分片具体是怎么工作的？新增分片后，会如何处理？ 


---

### 分片集群如何保证数据安全

每个 shard 都做成副本集架构。  

副本集架构是通过部署多个服务器存储数据副本来达到高可用的能力，每一个副本集实例由一个 Primary 节点和一个或多个 Secondary 节点组成。在 Primary 节点故障时，多个 Secondary 节点通过选举成为新的 Primary 节点，保障高可用。  

---

### 公有云 MongoDB 的版本情况

截至 2024-8-21。  

|厂商|版本|
|--|--|
|腾讯云| MongoDB 6.0 |
|阿里云| MongoDB 7.0 |
|华为云| 没有 MongoDB，只有兼容 MongoDB 的文档数据库，叫 DDS，兼容 MongoDB 4.4 |

---

### 公有云 MongoDB 分片集群的支持情况

分片集群的构成：mongos 节点、Config Server、分片节点。每个分片是分片数据的一个子集，云数据库的分片都作为一个副本集部署。下文中 shard 节点，实际上指的是分片服务器，一般是由三节点的副本集构成。    

以下数据截至 2024-8-21。   

1、腾讯云    

以 MongoDB 6.0 为例。  

Mongos 节点： 3 ~ 32 个。    
Config 节点：默认3副本集群，1核2G配置，不可变更。  
Shard 节点： 2 ~ 36 个。   

这个文档里 [《腾讯云-云数据库MongoDB-系统架构》](https://cloud.tencent.com/document/product/240/64126) 写着 shard 数量是 2 ~ 20，但实际可选范围是 2 ~ 36。   


2、阿里云   

以 MongoDB 7.0 为例。  

Mongos 节点： 3 ~ 32 个。    
Config 节点：副本集架构，配置可选。   
Shard 节点： 2 ~ 32 个。    


---

### 公有云的分片集群扩容

1、腾讯云   

(1) 调整分片数量     

参考：[《腾讯云-云数据库 MongoDB-调整分片数量》](https://cloud.tencent.com/document/product/240/76799)

注意点：  
只能增，不能减。    
新增节点加入集群开始同步数据，业务不受影响。    
切勿同时发起调整节点数、调整节点计算规格与存储的任务。    
调整节点数量后实例的名称、内网地址和端口均不发生变化。     


(2) 变更 Mongos 节点配置规格    

参考：[《腾讯云-云数据库 MongoDB-调整分片数量》](https://cloud.tencent.com/document/product/240/76799)     

注意点：   
可能会涉及到跨机房迁移数据，会引起连接闪断的现象，要确保业务层有自动重连的机制，建议在业务低峰期维护。    

(3) 新增 Mongos 节点   

参考：[《腾讯云-云数据库 MongoDB-新增 Mongos 节点》](https://cloud.tencent.com/document/product/240/76801)     


2、阿里云    


---

### 分片的操作与查看

参考： https://help.aliyun.com/zh/mongodb/use-cases/configure-sharding-to-maximize-the-performance-of-shards

---

### 分片集群 batch insert 的性能问题

参考：[《MongoDB sharding 集合不分片性能更高？》](https://mongoing.com/archives/26859)     

batch insert 的情况下，分片集群单个 shard 的性能，相对于未分片的会有所下降，因为未分片的时候，batch insert 直接就到达 Primary shard 了，而分片的情况下，mongos 收到请求后，还要做二次分发，如果 batch 里面的 key 是打得很散的，那么分发的时候基本上就没 batch 的优势了。  


---

## 1.8 MongoDB wiredtiger 引擎

参考文档：  

* [《MongoDB Wiredtiger存储引擎实现原理》](https://mongoing.com/archives/2540)     
* [《Mongo进阶 - WT引擎：缓存机制》](https://pdai.tech/md/db/nosql-mongo/mongo-y-cache.html)    
* [《Mongo进阶 - WT引擎：事务实现》](https://pdai.tech/md/db/nosql-mongo/mongo-y-trans.html)    

从 MongoDB 3.2 开始，WiredTiger 成为默认的存储引擎。   

---

## 1.9 MongoDB Oplog



---



# 2. 参考

[1] sevenll07. MongoDB 概念及基础CRUD. Available at https://blog.csdn.net/weixin_38980638/article/details/136994894, 2024-3-24.    

[2] 阿里云. 事务与Read/Write Concern. Available at https://help.aliyun.com/zh/mongodb/use-cases/transactions-and-read-write-concern, 2024-6-4.    