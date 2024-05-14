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


# 收集

* 《万字详解常用存储结构：B+树、B-Link树、LSM树一网打尽》
https://it.sohu.com/a/616437236_411876


* 论文：《The Ubiquitous B-Tree》by DOUGLAS COMER 
https://dl.acm.org/doi/pdf/10.1145/356770.356776


* taocp vol3 p451 (6.2.4多路树)
讲到 b* 树的时候说
>重要的改动是条件(ii),它断言,我们至少利用了每个节点中三分之二的可用空间。这个改动不仅更有效地使用了空间,而且也使查找过程加快,因为在(6)和(7)中我们可以用[(2m-1)/3]代替[m/2]。然而插入过程就变慢了,因为随着节点变满它们要更加注意;关于个中涉及的折衷的分析,请参见张斌和许玖君, Acta Informatica 26(1989),421--438


* Zhang, B., Hsu, M. Unsafe operations in B-trees. Acta Informatica 26, 421–438 (1989). https://doi.org/10.1007/BF00289145
https://link.springer.com/article/10.1007/BF00289145
Bin Zhang & Meichun Hsu

>AB  - A simple mathematical model for analyzing the dynamics of a B-tree node is presented. From the solution of the model, it is shown that the simple technique of allowing a B-tree node to be slightly less than half full can significantly reduce the rate of split, merge and borrow operations. We call split, merge, borrow and balance operations unsafe operations in this paper. In a multi-user environment, a lower unsafe operation rate implies less blocking and higher throughput, even when tailored concurrency control algorithms (e.g., that proposed by Lehman and Yao [10]) are used. A lower unsafe operation rate also means a longer life time of an optimally initialized B-tree (e.g., compact B-tree). It is in general useful to have an analytical model which can predict the rate of unsafe operations in a dynamic data structure, not only for comparing the behavior of variations of B-trees, but also for characterizing workload for performance evaluation of different concurrency control algorithms for such data structures. The model presented in this paper represents a starting point in this direction.


* 这篇文章 ( https://www.quora.com/What-are-B*trees ) 讲了
>TL;DR B*trees are a special case of B+trees which were interesting to consider when disk storage was at a great premium, but have performance and synchronization penalties that limit their practical implementation.  


* 论文：关于 B*+tree《SQLite RDBMS Extension for Data Indexing Using B-tree Modifications》
https://ispranproceedings.elpub.ru/jour/article/view/1188/948
讲了 b-tree, b*-tree, b+-tree, `b*+-tree`  


* innodb 大神 Jeremy Cole 的博客
https://blog.jcole.us/


* wikipedia B-tree
https://en.wikipedia.org/wiki/B-tree


* wikipedia B+ tree
https://en.wikipedia.org/wiki/B%2B_tree


* 百度百科 B*树
https://baike.baidu.com/item/B*%E6%A0%91/2684963


* MySQL十五：InnoDB为什么不使用跳表而是B+Tree
https://www.modb.pro/db/411170


* B*-Trees implementation in C++
https://www.geeksforgeeks.org/b-trees-implementation-in-c/


* 扇出
扇出：是每个索引节点（non-leafPage）指向每个叶子节点（LeafPage）的指针
扇出数 = 索引节点（Non-LeafPage）可存储的最大关键字个数+1


* M-ary 类似于 binary，用 M 代替了 bin，表示 M 路

---

# 参考

[1] Wikipedia. B-tree. Available at https://en.wikipedia.org/wiki/B-tree.   