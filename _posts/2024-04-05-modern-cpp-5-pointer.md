---
layout: post
title: "现代 c++ 五：指针与内存泄漏"
date: 2024-04-05
last_modified_at: 2024-04-05
categories: [c++]
tags: [c++]
---

* 目录  
{:toc}
<br/>

# 指针的原则

1、优先使用智能指针，少用裸指针，智能指针几乎可以做到裸指针能做到的任何事情，但犯错的机会大大减少了。  

2、

---

# std::auto_ptr

是 c++98 残留的特性，在 c++11 已经弃用 (deprecated ) 了，在 c++17 已经移除了。[1]  

可以使用 c++11 新引入的 std::unique_ptr 来代替 std::auto_ptr。  

---

# std::unique_ptr

---

# std::shared_ptr



**注意事项** 

1、优先使用 std::make_shared，而非直接使用 new   




2、不要用裸指针初始化多个 shared_ptr，比如这样：  

```cpp
    auto sp = new std::string{"abc"};
    std::shared_ptr<std::string> a {sp};
    std::shared_ptr<std::string> b {sp};  // not ok, do not do this
```  

2、容器中的 shared_ptr 要及时 erase   

这个挺容易漏掉的，没有及时 erase，就会一直引用着，无法自动释放。   

3、

---

# 内存泄漏

## 内存泄漏的定位

---

# 参考

[1] cppreference. auto_ptr. Available at https://en.cppreference.com/w/cpp/memory/auto_ptr.  