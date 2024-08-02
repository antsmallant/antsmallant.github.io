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

## 1.1 lua table 的底层实现 

参考：   
[深入Lua：Table的实现 - 知乎](https://zhuanlan.zhihu.com/p/97830462)   
[Lua设计与实现--Table篇 - 知乎](https://zhuanlan.zhihu.com/p/87400150)


---

## 1.2 lua pairs / ipairs 的底层实现


---

# 1.3 lua for 的底层实现

---

## 1.4 lua for 循环的目标计算

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

