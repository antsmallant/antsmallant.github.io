---
layout: post
title: "c++ 笔记六：c++11 的新特性"
date: 2023-04-03
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

本文记录 c++11 的新特性。  

c++11 是一个 major 版本，带来了大量的新变化，在很多年的时间里，它也一直被称为 c++0x。  

---

# 1. 新的语言特性

---

# 1.1 概览[1]

* 内存模型——一个高效的为现代硬件设计的底层抽象，作为描述并发的基础
* auto 和 decltype——避免类型名称的不必要重复
* 范围 for——对范围的简单顺序遍历
* 移动语义和右值引用——减少数据拷贝
* 统一初始化—— 对所有类型都（几乎）完全一致的初始化语法和语义
* nullptr——给空指针一个名字
* constexpr 函数——在编译期进行求值的函数
* 用户定义字面量——为用户自定义类型提供字面量支持
* 原始字符串字面量——不需要转义字符的字面量，主要用在正则表达式中
* 属性——将任意信息同一个名字关联
* lambda 表达式——匿名函数对象
* 变参模板——可以处理任意个任意类型的参数的模板
* 模板别名——能够重命名模板并为新名称绑定一些模板参数
* noexcept——确保函数不会抛出异常的方法
* override 和 final——用于管理大型类层次结构的明确语法
* static_assert——编译期断言
* long long——更长的整数类型
* 默认成员初始化器——给数据成员一个默认值，这个默认值可以被构造函数中的初始化所取代
* enum class——枚举值带有作用域的强类型枚举

---

# 1.2 initializer_list


---

# 1.3 noexcept

有两个用法，一个是作为标识符 (specifier)，一个是作为运算符 (operator)。作为标识符的时候是表明此函数不会抛出异常，作为运算符的时候是判断一个函数是否会抛出异常。

noexcept 作为标识符的 specification: https://en.cppreference.com/w/cpp/language/noexcept_spec 。  
noexcept 作为运算符的 specification: https://en.cppreference.com/w/cpp/language/noexcept 。 

---

# 1.4 auto

---

# 1.5 decltype

---

# 2. 新的库特性

---

## 2.1 概览

---

# 3. 参考

[1] Bjarne Stroustrup. c++11：感觉像是门新语言. Cpp-Club. Available at : https://github.com/Cpp-Club/Cxx_HOPL4_zh/blob/main/04.md, 2023-6-11.   