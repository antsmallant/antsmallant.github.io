---
layout: post
title: "c++ 笔记一：常识问题合集"
date: 2024-04-15
last_modified_at: 2024-04-15
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

---

# 题目

## 为什么需要引入 nullptr？

nullptr 是 c++11 引入的，用于代替 NULL，它也是有类型的，是 std::nullptr_t。  

在此之前，c++ 用 NULL 表示空，但它实际上就是 0，即是用 0 表示空，那么有些场合分不清楚意图了，是想传 NULL 还是数字 0？
比如这样： 

```cpp
void f(Widget* w);
void f(int num);

f(0); // 搞不清要匹配哪个函数
```

---

## 什么是编译期多态？  


---