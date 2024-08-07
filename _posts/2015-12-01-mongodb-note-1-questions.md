---
layout: post
title: "mongodb 笔记一：常识"
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



# 2. 参考

[1] sevenll07. MongoDB 概念及基础CRUD. Available at https://blog.csdn.net/weixin_38980638/article/details/136994894, 2024-3-24.    