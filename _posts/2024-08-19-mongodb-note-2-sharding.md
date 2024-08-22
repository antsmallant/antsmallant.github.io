---
layout: post
title: "mongodb 笔记：分片集群"
date: 2024-08-19
last_modified_at: 2024-08-22
categories: [数据库]
tags: [mongodb 数据库]
---

* 目录  
{:toc}
<br/>

本文记录 MongoDB 分片集群相关的一些信息，包括如何使用，注意事项，底层实现等。   

持续更新，暂时有点零散，待资料收集完整后再一并整理。    

---

# 基本信息

MongoDB 从 1.6 版本开始支持 sharding；从 3.6 版本开始，要求 shard 以副本集部署；从 5.0 版本开始，支持修改 sharding key。   

**todo**   

单机性能的参照。      
分片集群性能的参照。   

---

## 架构

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/mongodb-sharding-architecture.jpg"/>
</div>
<center>图：mongodb sharding 的基本架构[1]</center>
<br/>    

---

## 构成要素

参考： [《腾讯云-云数据库MongoDB-系统架构》](https://cloud.tencent.com/document/product/240/64126)   

mongos 节点：负责接收所有客户端的连接查询请求，并将请求路由到集群内部对应的分片上，同时会把接收到的响应拼装起来返回到客户端。   

config server 节点：负责存储集群和 shard 节点的元数据信息，如集群的节点信息、分片数据的路由信息等。   

shard 节点：负责将数据分片存储在多个服务器上。  

<br/>

shard 的高可用是通过副本集架构保证的，从 MongoDB 3.6 版本开始，每个 shard 都必须部署成副本集，所以公有云上的都是副本集部署的。   

副本集架构是通过部署多个服务器存储数据副本来达到高可用的能力，每一个副本集实例由一个 Primary 节点和一个或多个 Secondary 节点组成。在 Primary 节点故障时，多个 Secondary 节点通过选举成为新的 Primary 节点，保障高可用。  

---

## 基本的分片策略

MongoDB 支持的分片策略如下：  

1. 范围分片，好处是支持基于 shard key 的范围查询。     
2. 哈希分片，好处是能够将写入均衡分布到各个 shard。    
3. Tag aware sharding，可以自定义一些 chunk 的分布规则（基本规则：给 shard 打标签 A，给集合的某些 chunk range 打标签 A，那么 balancer 最近会将标签为 A 的 chunk 都迁移到标签为 A 的 shard 上）。     

---

# 实际使用

--- 

## 使用时机  

参考这篇文章： [《MongoDB: Why Avoid Sharding, it should be kept as the last option.》](https://medium.com/geekculture/mongodb-why-avoid-sharding-it-should-be-kept-as-the-last-option-cb8fdc693b66) 。  

这篇文章说的是尽量不要选择 sharding，除非不得不。   

如果综合考虑后，一定要做 sharding，必须特别关注 shard key 的选择，这个是最重要的，否则负载的不均衡会是个特别的麻烦。  

除此之外，还需要注意 "Scatter Gather Query" 问题，即细碎收集式的查询：需要从多个 shard 取数据再聚合起来返回，这样会大大降低查询的性能。   

关于 shard key 是否可以改变的问题：   

MongoDB 4.2 及之前，shard key 是不能变的；  
MongoDB 4.4 开始，可以通过增加后缀字段的方式来改善 shard key； （todo：？这个仍然需要搞清楚）    
MongoDB 5.0 开始，可以改变一个集合的 shard key 来 reshard。  

然而，虽然能改变或更新 shard key，但 reshard 可能会导致负载过重，而严重影响正常业务。   

---

## 分片键的选择 

参考： [《腾讯云-云数据库 MongoDB-分片集群使用注意事项》](https://cloud.tencent.com/document/product/240/44611)     

* 取值基数  

如果用小基数的片键，因为备选值有限，那么 chunk 的总数量就有限，随着数据增多，chunk 大小会越来越大，导致水平扩展时，移动块会很困难。  

* 取值分布  

取值分布要尽量均匀，分布不均匀的片键会造成某些 chunk 的数据量非常大，同样会出现数据分布不均匀，性能瓶颈的问题。  

* 查询带分片

查询时建议带上分片，使用分片键做条件查询时，mongos 可以直接定义到具体分片，否则 mongos 需要将查询分发到所有分片，再等待响应返回。  

* 如果是范围分片，要避免单调递增或递减

虽然单调递增的 sharding key，数据文件挪动小，但是写入会集中，导致最后一片的数据量持续增大，不断发生迁移。递减也是一样的问题。  

---

## MongoDB 5.0 之后的 reshard

Manual: [《对集合重新分片》](https://www.mongodb.com/zh-cn/docs/manual/core/sharding-reshard-a-collection/)    

参考： [《Scale Out Without Fear or Friction: Live Resharding in MongoDB》](https://www.mongodb.com/blog/post/scale-out-without-fear-friction-live-resharding-mongodb)   


reshard 操作命令：   

```
reshardCollection: "<database>.<collection>", key: <shardkey>
```

注意事项：  

---

## 分片的操作与查看

参考： [《阿里云 - 云数据库 MongoDB - 设置数据分片以充分利用Shard性能》](https://help.aliyun.com/zh/mongodb/use-cases/configure-sharding-to-maximize-the-performance-of-shards)     

---

# 公有云上的 MongoDB

---

## 版本情况

截至 2024-8-21。  

|厂商|版本|
|--|--|
|腾讯云| MongoDB 6.0 |
|阿里云| MongoDB 7.0 |
|华为云| 没有 MongoDB，只有兼容 MongoDB 的文档数据库，叫 DDS，兼容 MongoDB 4.4 |

---

## 分片集群的支持情况

分片集群的构成：mongos 节点、Config Server、分片节点。每个分片是分片数据的一个子集，云数据库的分片都作为一个副本集部署。下文中 shard 节点，实际上指的是分片服务器，一般是由三节点的副本集构成。    

以下数据截至 2024-8-21。   

1、腾讯云    

以 MongoDB 6.0 为例。  

Mongos 节点： 3 ~ 32 个。    
Config 节点：默认3副本集群，1核2G配置，不可变更。  
Shard 节点： 2 ~ 36 个。   

这个文档里 [《腾讯云-云数据库MongoDB-系统架构》](https://cloud.tencent.com/document/product/240/64126) 写着 shard 数量是 2 ~ 20，但实际可选范围是 2 ~ 36。   

<br/>

2、阿里云   

以 MongoDB 7.0 为例。  

Mongos 节点： 3 ~ 32 个。    
Config 节点：副本集架构，配置可选。   
Shard 节点： 2 ~ 32 个。    


---

## 分片集群的扩容操作

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

注意点：   

增加 Mongos 数量，可提升数据库实例访问的最大连接数。  
系统会自动为新增的 Mongos 节点绑定 ip 地址，开通访问 Mongos 的连接串。  
如果是通过负载均衡的地址访问，系统将自动的将新增的 Mongos 节点绑定到负载均衡中。   

<br/>

2、阿里云    

---

# 底层实现

---

## chunk

参考：  

* [《mongodb 数据块的迁移流程介绍》](https://www.cnblogs.com/xinghebuluo/p/16154158.html)     

* [《mongodb 数据块迁移的源码分析》](https://www.cnblogs.com/xinghebuluo/p/16461068.html)   

---

### chunk 的概念

chunk 是一个逻辑上的概念，它是 shard 做负载均衡的最小单位。一个 chunk 会存储同个集合的若个干文档，分片集群的 collection，里面的文档会根据 sharding key 拆分到多个 chunk 去保存，每个 chunk 有大小控制（默认是 64 MB），但如果是多个文档的 sharding key 都相同，chunk 也会突破大小限制的，形成所谓的 jumbo chunk，这是一种很不好的现象，需要极力避免。  

每个 chunk 会有一个 shard key 的范围 (minkey，maxkey)，无论是 range based 还是 hash based，最终都会算出整数类型的 shard key，mongos 就根据 shard key 进行路由，找到对应的 chunk 。   

每个 shard 上都会有若干个 chunk，chunk 与 shard 的映射关系是一种元数据，被存储在 config server 上。当 shard 上的 chunk 数量不均衡时，config server 就会发起 movechunk 的操作，在不同的 shard 之间迁移 chunk，使得 chunk 的分布尽量均衡。  

---

### chunk 的创建及分裂

参考： 

* [《MongoDB--chunk的分裂和迁移》](https://blog.csdn.net/ITgagaga/article/details/103474910)     

* [《MongoDB Sharding Chunk分裂与迁移详解》](https://blog.csdn.net/joy0921/article/details/80131276)     

<br/>

1、chunk 的基本信息   

chunk size 默认是 64 MB。初始的 chunk，它的 minkey、maxkey 分别是无限小和无限大。随着数据增长，达到 chunk 的上限，则进行分裂。    

修改 chunk size 的方法：     
a. 连接到 mongos；    
b. 执行以下命令    

```sh
use config
db.settings.save({_id: "chunksize", value: 64})  // 单位是 MB
```

<br/>

2、chunk 的分裂逻辑    

当 chunk size 是 64MB 时，根据 chunk 数量不同，具体的分裂阈值如下 [3]：     

|集合 chunk 数量|分裂阈值|
|:--|:--|
|`1`|1024B|
|`[2,3)`|0.5MB|
|`[3,10)`|16MB|
|`[10,20)`|32MB|
|`[20,max)`|64MB|

一些要注意的点 [3]：   

* 自动分裂只在插入或更新时发生。  
* 如果降低了块的大小，可能需要一段时间才能将所有块分割为新的大小。   
* 分裂不能被取消。   
* chunk 只会分裂，不会合并，所以即使将 chunksize 改大，chunk 数量也不会减少。   
* chunk size 的范围是 1MB ~ 1024 MB。   

---

### chunk 的迁移逻辑    

chunk 分裂之后，shard 上 chunk 分布不均衡时，就会触发 chunk 迁移。  

config server 上的 balancer 负责数据的迁移，它会周期性的检查分片间是否存在不均衡，如果存在就会执行迁移。  

以下是触发迁移的一些场景 [3]：     

（todo：以下这几条似乎有些老旧了，针对的应该是 MongoDB 3.x 的老版本，需要看看最新版本的一些规则。）

1、根据 shard tag 迁移   

可以给 shard 打上标签，然后给集合的某个 range 打上标签，balancer 在迁移的时候就会保证：拥有相同 tag 的 range 会分配到拥有相同 tag 的 shard 上。  

这其实就是 MongoDB 提供的手动的控制数据在 shard 上分布的手段。  

2、根据 shard 之间的 chunk 数量迁移     

如果 shard 之间的 chunk 数量存在差距，达到阈值时，就会触发迁移，具体的阈值如下：  

|集合 chunk 数量|迁移阈值|
|:--|:--|
|`[1,20)`|2|
|`[20,80)`|4|
|`[80,max)`|8|

3、removeShard 触发迁移   

当用户执行 removeShard 命令从集群中移除 shard 时，balancer 会自动将此 shard 的 chunk 迁移到其他 shard 。   

4、手动移动块    

```bash
use config
sh.moveChunk("<collection>", {"key":value}, <shardname>)
```

chunk 的大小超出了系统指定的值时，系统会拒绝移动这个 chunk，可以手动执行 `splitAt` 命令进行拆分。   


### chunk 的分裂和迁移的管理    

一些要注意的点：   

1、chunk size 应该尽量保持默认值 [2]    

a. 较小的 chunk size，会使数据分布更均匀，但迁移会较频繁，导致查询路由开销增加，如果调小了 chunk size，mongodb 会耗费一些时间从原有 chunk 拆分到新 chunk，且此操作不可逆。要特别注意，chunk 只会分裂，不会合并，所以这个操作要慎重再慎重。  

b. 较大的 chunk size，迁移会较少，查询路由和网络负载也较低，但可能会导致数据分布不均匀，限制分片优势。如果调大 chunk size，已存在的 chunk 只会等到插入或更新的时候扩充至新大小，不会执行合并操作。   

<br/>

2、如果使用 hash 分片，在合适的场景下可以考虑【预分片】[3]   

即提前创建出指定数量的 chunk，并打散分布到后端的各个 shard，通过 numInitialChunks 参数指定，该值不能超过 8192。   

<br/>

3、balancer 能动态的开启和关闭 [3]        

balancer 能针对指定的集合开启或关闭，并且支持配置时间窗口，只在指定的时间段内进行迁移操作。    


### jumbo chunk 问题

jumbo 即是巨大的意思。MongoDB 默认的 chunk size 是 64 MB，如果 chunk 超过 64 MB 且不能分裂（比如该 chunk 中所有文档的 shard key 都相同），则会被标记为 jumbo chunk，balancer 不会迁移这样的 chunk，从而导致负载不均衡 [4]。    

当出现 jumbo chunk 时，如果对于负载均衡的要求不高，并不会影响数据的读写。如果需要处理，可以使用以下方法 [4]：  

* 对 jumbo chunk 进行 split，split 成功后 mongos 会自动清除 jumbo 标记。   
* 对于不可再分的 chunk，如果该 chunk 已不是 jumbo chunk，可以尝试手动清除 jumbo 标记。（最好先备份 config 数据库）   
* 调大 chunk size，当 chunk 大小不超过 chunk size 时，jumbo 标记最终会被清理。但随着数据的写入，仍可能会再出现 jumbo chunk。   

要解决 jumbo chunk，根本办法还是合理规划好 shard key。   

---

# 一些问题

---

## 分片集群 batch insert 的性能问题

参考：[《MongoDB sharding 集合不分片性能更高？》](https://mongoing.com/archives/26859)     

batch insert 的情况下，分片集群单个 shard 的性能，相对于非分片集群的会有所下降。对于非分片集群（副本集），batch insert 直接就到达 Primary shard 了。而分片集群，mongos 收到请求后，还要做二次分发，如果 batch 里面的 key 是打得很散的，那么分发的时候基本上就丧失 batch 的优势了。  

---

# 一些文章   

以下文章都是参考过的，笔记里有些直接就照抄了这些文章的，由于太多了，就不给出具体的引用参考了。   

* [《mongodb manual 分片》](https://www.mongodb.com/zh-cn/docs/manual/sharding/)  

* [《Mongo进阶 - DB核心：分片Sharding》](https://pdai.tech/md/db/nosql-mongo/mongo-z-sharding.html)    

* [《火山引擎 - MongoDB 分片集群使用指南》](https://www.volcengine.com/docs/6447/1185247)    

* [《mongodb的底层是怎么实现的？》](https://www.zhihu.com/question/316097977/answer/2432202296)    

* [《MongoDB分片迁移原理与源码（1）》](https://cloud.tencent.com/developer/article/1608372)   

* [《杨亚洲 - 一些源码注释和文章链接》](https://github.com/y123456yz/reading-and-annotate-mongodb-5.0)   

* [《杨亚洲 - 万亿级数据库MongoDB集群性能优化及机房多活容灾实践》](https://zhuanlan.zhihu.com/p/343524817)   

* [《一文读懂MongoDB chunk 迁移》](https://cloud.tencent.com/developer/article/1794766)     

---

# 参考

[1] MongoDB. 分片. Available at https://www.mongodb.com/zh-cn/docs/manual/sharding/.     

[2] 火山引擎. MongoDB 分片集群使用指南. Available at https://www.volcengine.com/docs/6447/1185247.     

[3] Keep hunger. MongoDB--chunk的分裂和迁移. Available at https://blog.csdn.net/ITgagaga/article/details/103474910, 2019-12-10.    

[4] 阿里云. MongoDB 分片集群介绍. Available at https://help.aliyun.com/zh/mongodb/use-cases/introduction-to-apsaradb-for-mongodb-sharded-cluster-instances, 2023-11-21.    