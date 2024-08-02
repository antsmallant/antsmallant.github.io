---
layout: post
title: "lua 笔记一：常识、用法"
date: 2022-05-01
last_modified_at: 2022-05-01
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 lua 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

--- 

## 1.1 lua table 

---

### 1.1.1 table 的基本信息

1、包含了数组和哈希表两部分。    

2、可支持两大功能：容器，面向对象（通过 metatable）。   

---
 
### 1.1.2 table 的底层实现

#### 1.1.2.1 数据结构

#### 1.1.2.2 查找

#### 1.1.2.3 新增元素

#### 1.1.2.4 迭代

#### 1.1.2.5 rehash    

---

### 1.1.3 table 的拓展阅读

[《深入Lua：Table的实现 - 知乎》](https://zhuanlan.zhihu.com/p/97830462)     

[《Lua设计与实现--Table篇 - 知乎》](https://zhuanlan.zhihu.com/p/87400150)    


---

## 1.2 lua table 取长度的问题

在 lua 中，通过一元前置符 `#` 来求 table 的长度。   

表的长度只有在表是一个序列时有意义，序列是指表的正数键集合是 `{1...n}`，即要求所有的正数键放在一起排序，是一串连续的数据，从 1 到 n。 [1] 

像这样的 `{10, 20, nil, 40}` 就不是序列，因为它的正数键集是 `{1,2,4}`，并不是连续的。这种情况下，表的长度是无定义的。不过，lua 在这种情况下取长度也会给出一个值，只不过这个值会有些随机，它只是符合这种条件的任意一个值：一个整数下标n，满足 t[n] 不是 nil，而 t[n+1] 是 nil。   

比如：   

```
> t = {10,20,nil,40}
> #t
4
> t = {nil,nil,30,nil}
> #t
3
> t = {1,nil,nil,nil,nil,nil,7}
> #t
7
> t[8] = 8
> #t
1
```

在源码（lua5.3.6）中，是通过 ltable.c 的 luaH_getn 函数获取 table 的长度的。  

---

## 1.3 lua pairs / ipairs 的底层实现


---

## 1.4 lua for 的底层实现

---

## 1.5 lua for 循环的目标计算

1、对于这样的，只计算一次。      

```lua
local x = {1,2,3,4}
for i = 1, #x do
    x[2] = nil
    x[3] = nil
    x[4] = nil
    print(x[i])
end
```

输出：   

```
1
nil
nil
nil
```

2、对于这样的，则是动态计算的。    

```lua
local x = {1,2,3,4}
for k, v in ipairs(x) do
    x[2] = nil
    x[3] = nil
    x[4] = nil
    print(k, v)
end
```

输出： 

```
1    1
```

---

# 2. 参考

[1] lua.org. The Length Operator. Available at https://lua.org/manual/5.3/manual.html#3.4.7.     