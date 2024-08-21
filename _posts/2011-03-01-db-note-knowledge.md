---
layout: post
title: "数据库笔记：常识"
date: 2011-03-01
last_modified_at: 2023-05-01
categories: [数据库]
tags: [db 数据库]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 db 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

---

## 1.1 倒排索引 

正排索引是类似这样的：  

```
id1 -> 文档1
id2 -> 文档2
id3 -> 文档3
...
idn -> 文档n
```

而倒排索引（Inverted Index）是类似这样的： 

```
word1 -> id1,id2,..idx
word2 -> id2,id3,..idy
...
wordn -> idm,idn,..idz
```

倒排索引通常用于全文搜索，一般由三个部分组成：词项索引（term index）、词项字典（term dictionary）、倒排表（posting list）。  

词项索引可以是一个 trie 树，用于快速定位到词项在词项字典中的位置。  
词项字典就建立了词项到倒排表中的id列表的映射。  
倒排表本身就是一行行的记录，每行记录包含着同个字项出现的文档的id，以及位置，频次等信息。    

如下图所示 (引用自：[《倒排索引原理》](https://blog.csdn.net/meser88/article/details/131135522))：   

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/db-inverted-index-inside.png"/>
</div>
<center>倒排索引的内部构造示意[1]</center>
<br/>


---

# 2. 参考  

[1] 码上得天上. 倒排索引原理. Available at https://blog.csdn.net/meser88/article/details/131135522, 2023-6-10.   