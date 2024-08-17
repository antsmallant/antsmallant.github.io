---
layout: post
title: "lua 笔记：userdata 与 lightuserdata"
date: 2022-05-04
last_modified_at: 2023-01-01
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>  

本文简单记录一下 userdata 与 lightuserdata 如何使用。  

由于包含示例代码，会有些冗长。      

---

# 1. userdata 与 lightuserdata 的区别

1、userdata 也可以称为 full userdata，它是完全由 lua gc 管理的一块内存；而 lightuserdata 只保存了一个 c 指针，这块内存的寿命由 c 模块自己管理。    

2、userdata 可以有元表，能够模拟出面向对象式的操作；而 lightuserdata 没有元表，类似于一个整数而已，只能作为一个参数传递给一些函数。   

3、userdata 通过 `void *lua_newuserdata(lua_State *L, size_t size);` 创建；而 lightuserdata 通过 `void lua_pushlightuserdata(lua_State *L, void *p);` 创建。   

4、userdata 是一个对象，它只与自身相等；而 lightuserdata 是一个 c 指针值，它与所有表示相同指针值的 lightuserdata 都相等，这也是它的一个重要用法，用于相等性判断，通过 lightuserdata 查找 lua 中的 c 对象。    

---

# 2. userdata 

---

## 2.1 关于 userdata  

---

## 2.2 userdata 的例子

参考： 

[Lua 之 userdata](https://www.cnblogs.com/chenny7/p/4077364.html)   

[Lua中的userdata](https://blog.csdn.net/qq826364410/article/details/88672091)      

[lua源码编译及与C/C++交互调用细节剖析](https://zhuanlan.zhihu.com/p/395277828)    

[细说lua的userdata与C++的交互](https://zhuanlan.zhihu.com/p/396407350)    



---

# 3. lightuserdata 

## 3.1 关于 lightuserdata


---

## 3.2 lightuserdata 的例子


---

# 4. 参考