---
layout: post
title: "mongodb 笔记一：常识、用法"
date: 2015-12-01
last_modified_at: 2021-7-10
categories: [mongodb]
tags: [mongodb]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 mongodb 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

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

### 1.4.1 数据库管理 

有3个默认的数据库: admin, local, config。   

查看所有数据库    
`show dbs;` 或 `show databases;`   

查看当前数据库     
`db;`    

切换数据库   
`use <dbname>;`   

删除当前数据库       
`db.dropDatabase();`     

---

### 1.4.2 集合管理  

查看所有集合   
`show collections;`     

创建集合
`db.createCollection("<collectionName>");`  

删除集合    
`db.<collectionName>.drop();`      

---

### 1.4.3 索引管理




### 1.4.4 CRUD   

插入      

`db.<collectionName>.insertOne(<document>)`
`db.<collectionName>.insertMany([<document>, ..., <document>])`  

`<document>` 是 kv 结构的 table: `{k1:v1, k2:v2, ...}`    


查询     

`db.<collectionName>.find({key:value or conditions})`    


更新     

`db.<collectionName>.update({key:value}, {$set, {newkey:newvalue}})`


删除        
`db.<collectionName>.deleteOne({key:value or conditons})`   

`db.<collectionName>.deleteMany({key:value or conditons})`    


---



# 2. 参考

