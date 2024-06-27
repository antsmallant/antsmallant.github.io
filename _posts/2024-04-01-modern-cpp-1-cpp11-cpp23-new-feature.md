---
layout: post
title: "现代 c++ 一：c++11 ~ c++23 新特性汇总"
date: 2024-04-01
last_modified_at: 2024-04-01
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

所谓现代 c++，指的是从 c++11 开始的 c++，从 c++11 开始，加入一些比较现代的语言特性和改进了的库实现，使得用 c++ 开发少了很多心智负担，程序也更加健壮，“看起来像一门新语言”。    

从 c++11 开始，每 3 年发布一个新版本，到今年（2024）已经有 5 个版本了，分别是 c++11、c++14、c++17、c++20、c++23，这 5 个版本引入了上百个新的语言特性和新的标准库特性。       

---

# 1. 新特性

## 1.1 c++11 新特性

c++11 是一个 major 版本，现代 c++ 开天辟地的版本，有特别多新东西。     

新的语言特性[1]：  

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


新的标准库特性[1]：  

* unique_ptr 和 shared_ptr——依赖 RAII 的资源管理指针
* 内存模型和 atomic 变量
* thread、mutex、condition_variable 等——为基本的系统层级的并发提供了类型安全、可移植的支持
* future、promise 和 packaged_task，等——稍稍更高级的并发
* tuple——匿名的简单复合类型
* 类型特征（type trait）——类型的可测试属性，用于元编程
* 正则表达式匹配
* 随机数——带有许多生成器（引擎）和多种分布
* 时间——`time_point` 和 duration
* unordered_map 等——哈希表
* forward_list——单向链表
* array——具有固定常量大小的数组，并且会记住自己的大小
* emplace 运算——在容器内直接构建对象，避免拷贝
* exception_ptr——允许在线程之间传递异常

---

# 1.2 c++14 新特性

c++14 是一个 minor 版本，没什么重要的新特性，主要是在给 c++11 打补丁，为使用者 “带来极大方便”，实现 “对新手更为友好” 这一目标。  

新的语言特性[2]：  

* 泛型的lambda
* Lambda捕获部分中使用表达式
* 函数返回类型推导
* 另一种类型推断:decltype(auto)
* 放松的constexpr函数限制
* 变量模板
* 聚合类成员初始化
* 二进制字面量： 0b或0B 前缀
* 数字分位符
* deprecated 属性

新的标准库特性[2]：  

* 共享的互斥体和锁: `std::shared_timed_mutex`
* 元函数的别名
* 关联容器中的异构查找
* 标准自定义字面量
* 通过类型寻址多元组
* 较小的标准库特性: `std::make_unique`, `std::is_final` 等

---

# 1.3 c++17 新特性

c++17 是一个 “中” 版本（它本来应该是一个 major 版本）。  

新的语言特性[3]：  

* 构造函数模板参数推导——简化对象定义
* 推导指引——解决构造函数模板参数推导歧义的显式标注
* 结构化绑定——简化标注，并消除一种未初始化变量的来源
* inline 变量——简化了那些仅有头文件的库实现中的静态分配变量的使用
* 折叠表达式——简化变参模板的一些用法
* 条件中的显式测试——有点像 for 语句中的条件
* 保证的复制消除——去除了很多不必要的拷贝操作
* 更严格的表达式求值顺序——防止了一些细微的求值顺序错误
* auto 当作模板参数类型——值模板参数的类型推导
* 捕捉常见错误的标准属性——`[[maybe_unused]]、[[nodiscard]] 和 [[fallthrough]]`
* 十六进制浮点字面量
* 常量表达式 if——简化编译期求值的代码

新的标准库特性[3]：  

* optional、any 和 variant——用于表达“可选”的标准库类型
* shared_mutex 和 shared_lock（读写锁）和 scoped_lock
* 并行 STL——标准库算法的多线程及矢量化版本
* 文件系统——可移植地操作文件系统路径和目录的能力
* string_view——对不可变字符序列的非所有权引用
* 数学特殊函数——包括拉盖尔和勒让德多项式、贝塔函数、黎曼泽塔函数

---

# 1.4 c++20 新特性

c++20 是一个 major 版本，有很重要的更新，"The Big Four"，即四个重要的特性，分别是：模块、概念、协程、和范围。    

新的语言特性[4]：  

* 模块
* 概念
* 协程
* 可指定的初始值设定项(C99功能的略微受限版本)
* `<=>`(“宇宙飞船操作符”)三向比较操作符
* `[*this]`按值捕获当前对象
* 标准属性 `[[no_unique address]]`、`[[likely]]` 和 `[[unlikely]]`
* 在 constexpr 函数中允许使用更多功能，包括 new、union、try-catch、dynamic_cast 和 typeid
* 保证编译时求值的 consteval 函数
* 保证静态(非运行时)初始化的 constinit 变量
* using 可用于带作用域的 enum
* 还有一些小的扩展

新的标准库特性[4]：  

* 范围、视图和管道
* `printf()` 风格的格式化: `format()` 和 `vformat()`
* 日历和时区
* `span`，用于对连续数组进行读写访问
* `source_location`
* 数学常数，例如 pi 和 1n10e
* 对 atomic 的许多扩展
* 等待多个 thread 的方法: barrier 和 latch
* 特性测试宏
* `bit cast<>`
* 位操作
* 更多的标准库函数成为 constexpr
* 在标准库中更多地使用 `<=>` 操作符
* 更多的小扩展

---

# 1.5 c++23 新特性

c++23 是一个 minor 版本。  

新的语言特性[5]：  

* 新语言功能特性测试宏
* 显式对象形参，显式对象成员函数（推导 this）
* if consteval / if not consteval
* 多维下标运算符（例如 `v[1, 3, 7] = 42;`）
* static operator()
* static operator[]
* auto(x)：语言中的衰退复制
* lambda 表达式上的属性
* 可选的扩展浮点类型：std::float{16|32|64|128}_t 和 std::bfloat16_t。
* （有符号）std::size_t 字面量的字面量后缀 'Z'/'z'
* 后缀
* #elifdef、#elifndef 与 #warning
* 通过新属性 [[assume(表达式)]] 进行假设
* 具名通用字符转义
* 可移植源文件编码为 UTF-8
* 行拼合之前修剪空白

新的标准库特性[5]：  

* 新的库功能特性测试宏
* 新的范围折叠算法
* 字符串格式化改进
* “平铺（flat）”容器适配器：std::flat_map、std::flat_multimap、std::flat_set、std::flat_multiset
* std::mdspan
* std::generator
* std::basic_string::contains, std::basic_string_view::contains
* 禁止从 nullptr 构造 std::string_view
* std::basic_string::resize_and_overwrite
* std::optional 的单子式操作：or_else、and_then、transform
* 栈踪迹（stacktrace）库
* 新的范围算法
* 新的范围适配器（视图）
* 对范围库的修改
* 对视图的修改
* 标记不可达代码：std::unreachable
* 新的词汇类型 std::expected
* std::move_only_function
* 新的带有程序提供的固定大小缓冲区的 `I/O` 流 std::spanstream
* std::byteswap
* std::to_underlying
* 关联容器的异质擦除

---

# 2. 编译器支持情况

---

## 2.1 按版本区分

|版本|支持|
|:--|:--|
|c++11|[Compiler support for C++11](https://en.cppreference.com/w/cpp/compiler_support/11)|
|c++14|[Compiler support for C++14](https://en.cppreference.com/w/cpp/compiler_support/14)|
|c++17|[Compiler support for C++17](https://en.cppreference.com/w/cpp/compiler_support/17)|
|c++20|[C++ compiler support](https://en.cppreference.com/w/cpp/compiler_support)|
|c++23|[C++ compiler support](https://en.cppreference.com/w/cpp/compiler_support)|

---

## 2.2 按编译器区分

|编译器|支持|
|:--|:--|
|gcc|[C++ Standards Support in GCC](https://gcc.gnu.org/projects/cxx-status.html)|
|clang|[C++ Support in Clang](https://clang.llvm.org/cxx_status.html)|
|汇总|[cpp/compiler support/vendors](https://en.cppreference.com/w/cpp/compiler_support/vendors)|

---

# 3. 参考

[1] Bjarne Stroustrup. c++11：感觉像是门新语言. Cpp-Club. Available at : https://github.com/Cpp-Club/Cxx_HOPL4_zh/blob/main/04.md, 2023-6-11.    

[2] Wikipedia. c++14. Available at: https://zh.wikipedia.org/wiki/c++14.   

[3] 玩转Linux内核. 快速入门c++17：了解最新的语言特性和功能. Available at: https://zhuanlan.zhihu.com/p/664746128, 2023-11-06.    

[4] [美] Bjarne Stroustrup. C++之旅（第3版）. pansz. 北京: 电子工业出版社, 2023-10(1).   

[5] cppreference. c++23. Available at: https://zh.cppreference.com/w/cpp/23, 2024-3-3.   