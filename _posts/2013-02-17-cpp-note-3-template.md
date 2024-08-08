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

## 1.1 模板特化 (template specilization)

是指为某个模板类或函数定义专门的实现，以处理特定类型参数的情况。  

比如函数模板特化： 

```cpp
#include <iostream>
using namespace std;

template<typename T>
void p(T t) {
    cout << "this is general type" << endl;
}

template<>
void p<int>(int i) {
    cout << "This is a int " << i << endl;
}

int main() {
    p<float>(10.0);
    p<int>(20);
    return 0;
}
```

<br/>

类模板特化的写法也类似：   

```cpp
template<typename T> class A {};

template<> class A<SomeType> {};
```

---

## 1.2 模板偏特化 (partial specilization)

是模板特化的一种特殊情况，也叫模板部分特化。只对部分模板参数进行特化。  

比如函数模板偏特化：  

```cpp

#include <iostream>
using namespace std;

template<typename T1, typename T2>
void p(T1 t1, T2 t2) {
    cout << "This is a general template " << t1 << " " << t2 <<  endl;
}

template<typename T2>
void p(int t1, T2 t2) {
    cout << "This is a partial template " << t1 << " " << t2 <<  endl;
}

int main() {
    p(10, 20);
    p(10, 20.1);
    p(10.1, 20);
    return 0;
}

```

输出： 

```
This is a partial template 10 20
This is a partial template 10 20.1
This is a general template 10.1 20
```

类模板偏特化也是类似的，不举例了。  

---

## 1.3 typename 与 class 关键字的区别


---

# 2. 参考