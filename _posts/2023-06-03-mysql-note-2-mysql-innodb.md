---
layout: post
title: "mysql 笔记：innodb"
date: 2023-06-03
last_modified_at: 2023-06-03
categories: [数据库]
tags: [db, mysql]
---

* 目录  
{:toc}
<br/>

记录 innodb 的一些底层实现。  

---

# 1. innodb

# 1.1 既然有了 buffer poll，为何 innodb 的性能远低于 redis ?

参考：   
姜承尧 《MySQL技术内幕 InnoDB存储引擎（第2版）》    
[说说你对MySQL InnoDB Buffer Pool的理解](https://zhuanlan.zhihu.com/p/712657254)     

---

## 1.2 innodb 的页大小为何是 16 kb ? 


---

## 1.3 从 iops 推算 innodb 的qps

---

## 1.4 为什么 innodb 不使用 B* Tree ?

---

# 2. 参考