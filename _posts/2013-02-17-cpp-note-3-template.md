---
layout: post
title: "c++ 笔记三：模板"
date: 2013-02-17
last_modified_at: 2023-04-01
categories: [c++]
tags: [c++ cpp]
---

* 目录  
{:toc}
<br/>

记录 c++ 关于模板相关的要点。  

---

# 1. 模板

## 1.1 资料

《C++ Templates (第2版·英文版)》: [https://book.douban.com/subject/30226708/](https://book.douban.com/subject/30226708/)   

《c++ Templates 第2版的中文翻译》：[https://github.com/Walton1128/CPP-Templates-2nd--](https://github.com/Walton1128/CPP-Templates-2nd--)

---

## 1.2 模板特化 (template specilization)

或者叫模板特例化，是指为某个模板类或函数定义专门的实现，以处理特定类型参数的情况。  

特化的本质是实例化一个模板。   

<br/>

1、函数模板特化  

```cpp
#include <iostream>
using namespace std;

template<typename T>
void p(T t) {
    cout << "this is general type " << t << endl;
}

template<>
void p<int>(int i) {
    cout << "This is a int type " << i << endl;
}

int main() {
    p(10.0);
    p(20);
    return 0;
}
```

<br/>

2、类模板特化

写法与函数模板特化类似：    

```cpp
template<typename T> class A {};

template<> class A<SomeType> {};
```

---

## 1.3 模板偏特化 (partial specilization)

模板偏特化是模板特化的一种特殊情况，也叫模板部分特化。只对部分模板参数进行特化。  

<br/>

1、函数模板没有偏特化   

c++ 暂时不支持函数模板的偏特化。  

<br/>

2、类模板有偏特化    

比如这样：  


---

## 1.4 类模板的优先级

全特化版本 > 偏特化版本 > 正常版本

---

## 1.5 typename 与 class 关键字的区别

---

## 1.6 万能引用与完美转发


---

# 2. 参考