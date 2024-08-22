---
layout: post
title: "c++ 笔记：《C++ Core Guidelines》"
date: 2023-04-10
last_modified_at: 2024-07-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

本文是阅读 [《C++ Core Guidelines》](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines) 做的一些笔记。   

---

# 1. 函数返回值、出参

[F.48: Don't return `std::move(local)`](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#f48-dont-return-stdmovelocal)     

会影响 RVO、NRVO 的实施。  

<br/>

[F.49: Don't return `const T`](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#f49-dont-return-const-t)    

会干扰 `move` 语义。  

<br/>

[F.20: For "out" output values, prefer return values to output parameters](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#f20-for-out-output-values-prefer-return-values-to-output-parameters)   

如果要出参，首选返回值，尽量不要用出参。因为返回值总是 "self-documenting" （自说明的），而一个 `&` 的参数可能是入参也可能是出参，容易误用。  

这个规则适用于支持 `move` 语义的标准容器，以及一些大的对象。  

<br/>

[F.21: To return multiple "out" values, prefer returning a struct](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#f21-to-return-multiple-out-values-prefer-returning-a-struct)    

因为返回值总是 "self-documenting" （自说明的）。首选 `struct`，其次是 `tuple`。   

不过 `tuple` 有个问题，如果有人不慎调整了参数顺序，就悲剧了。    

"The overly generic `pair` and `tuple` should be used only when the value returned reprents indepent entities rather than an abstraction"。  
大概翻译一下，`std::pair` 和 `std::tuple` 的通用规则是，应该用于返回一组不相关的独立值，而不是一组可以被抽象（成一个类）的值。  

---

# 2. 函数入参

[F.15: Prefer simple and conventional ways of passing information](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#f15-prefer-simple-and-conventional-ways-of-passing-information)    

<br/>

[F.16 For "in" parameters, pass cheaply-copied types by value and others by referenc to const](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#f16-for-in-parameters-pass-cheaply-copied-types-by-value-and-others-by-reference-to-const)    

<br/>

[F.17 For "in-out" parameters, pass by reference to non-const](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#f17-for-in-out-parameters-pass-by-reference-to-non-const)


---

# 参考