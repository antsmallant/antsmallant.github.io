---
layout: post
title: "lua 笔记四：userdata 与 lightuserdata"
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

userdata 是完全由 lua gc 管理的一块内存，而 lightuserdata 只保存了一个 c 指针，这块内存的寿命由 c 模块自己管理。   

---

# 2. userdata 的例子

参考： 

[Lua中的userdata](https://blog.csdn.net/qq826364410/article/details/88672091)      

[lua源码编译及与C/C++交互调用细节剖析](https://zhuanlan.zhihu.com/p/395277828)    

[细说lua的userdata与C++的交互](https://zhuanlan.zhihu.com/p/396407350)    



---

# 3. lightuserdata 的例子


---

# 4. 参考