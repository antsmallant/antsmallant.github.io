---
layout: post
title: "游戏数据库常识三：为何 innodb 不使用 B*Tree"
date: 2023-06-03
last_modified_at: 2023-06-03
categories: [数据库]
tags: [game, db, mysql]
---

* 目录  
{:toc}
<br/>

关于 `B-Tree`，`B+Tree`，`B*Tree` 的区别网上到处都有。关于 innodb 为何使用 `B+Tree` 而不使用 `B-Tree` 也到处都有。但是我发现，似乎找不到一篇文章讲为何 innodb 不使用 `B*Tree`，无论是用百度还是 google，都找不到。   

于是我决定自己研究一下，故有此文。  

---

# `B-Tree`、`B+Tree`、`B*Tree` 的区别

实际上还有一种树，叫 `B*+Tree`[1]。


---

# 参考

[1] Wikipedia. B-tree. Available at https://en.wikipedia.org/wiki/B-tree.   