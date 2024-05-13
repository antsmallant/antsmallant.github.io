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


这篇文章 ( https://www.quora.com/What-are-B*trees ) 讲了
>B*trees are a special case (of mostly historical interest) of B+trees which guarantee that nodes are at least 2/3 full.

>They do this by requiring the root node to be 2 disk pages in size, and by using a node splitting algorithm that splits two full nodes into three nodes 2/3 full, and a node merging algorithm that combines three nodes 2/3 full into two full nodes. The splitting algorithm also shifts items to adjacent nodes when a node is full but its neighbors aren’t. The merging algorithm borrows items from neighboring nodes when it is less than 2/3 full but its neighbors aren’t. The extra work involved in these algorithms means that they have not been implemented in practice.

>B+trees are still the most relevant secondary storage tree structure, so they are worth knowing about in more detail. They guarantee that nodes are at least 1/2 full, and that all data is stored in a sequential linked set of leaf nodes that can be accessed without traversing the tree structure, so sequential access is very efficient. The deletion algorithm also borrows data from neighbor nodes when the node that deleted an item is less than half full, but this is rarely properly implemented, despite only incurring a modest performance penalty.

>B trees don’t have the efficient sequential access or node content guarantees, so in the pathological case you will access as many nodes as data items.

>TL;DR B*trees are a special case of B+trees which were interesting to consider when disk storage was at a great premium, but have performance and synchronization penalties that limit their practical implementation.


---

# 参考

[1] Wikipedia. B-tree. Available at https://en.wikipedia.org/wiki/B-tree.   