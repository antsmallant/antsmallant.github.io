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

---

## 1.1 资料

《C++ Templates (第2版·英文版)》: [https://book.douban.com/subject/30226708/](https://book.douban.com/subject/30226708/)   

《c++ Templates 第2版的中文翻译》：[https://github.com/Walton1128/CPP-Templates-2nd--](https://github.com/Walton1128/CPP-Templates-2nd--)

---

## 1.2 模板特化 (template specialization)

或者叫模板特例化，是指为某个模板类或函数定义专门的实现，以处理特定类型参数的情况。  

特化的本质是实例化一个模板。   

<br/>

1、函数模板特化  

```cpp
#include <iostream>
using namespace std;

template<typename T>
void p(T t) {
    cout << "This is general type " << t << endl;
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

输出： 

```
This is general type 10
This is a int type 20
```

<br/>

2、类模板特化

写法与函数模板特化类似：    

```cpp
#include <iostream>
using namespace std;

template<typename T1, typename T2>
class A {
    T1 t1;
    T2 t2;
public:
    A(T1 _t1, T2 _t2) : t1(_t1), t2(_t2) { cout << "This is a normal template " << t1 << " " << t2 << endl; }
};

template<>
class A<int, int> {
    int t1;
    int t2;
public:
    A(int _t1, int _t2) : t1(_t1), t2(_t2) { cout << "This is a specialization template " << t1 << " " << t2 << endl; }
};

int main() {
    A<char, int> a('a', 10);
    A<int, int> b(1, 2);
    return 0;
}
```

输出： 

```
This is a normal template a 10
This is a specialization template 1 2
```

---

## 1.3 模板偏特化 (partial specialization)

模板偏特化是模板特化的一种特殊情况，也叫模板部分特化。是只对部分模板参数进行特化。  

<br/>

1、函数模板没有偏特化   

c++ 暂时不支持函数模板的偏特化。[1]   

大部分情况下，可以用重载解决问题。  

<br/>

2、类模板有偏特化    

例子：    

```cpp
#include <iostream>
using namespace std;

template<typename T1, typename T2>
class A {
    T1 t1;
    T2 t2;
public:
    A(T1 _t1, T2 _t2) : t1(_t1), t2(_t2) { cout << "This is a normal template " << t1 << " " << t2 << endl; }
};

template<typename T2>
class A<int, T2> {
    int t1;
    T2 t2;
public:
    A(int _t1, T2 _t2) : t1(_t1), t2(_t2) { cout << "This is a partial template " << t1 << " " << t2 << endl; }
};

int main() {
    A<char, int> a('a', 10);
    A<int, int> b(1, 2);
    return 0;
}
```

输出：  

```
This is a normal template a 10
This is a partial template 1 2
```


---

## 1.4 类模板的优先级

全特化版本 > 偏特化版本 > 正常版本

---

## 1.5 typename 与 class 关键字的区别

1、作为模板参数时，二者的含义是相当的。  

`template<typename T>` 与 `template<class T>` 是等价的。   

2、typename 的额外用途  

用于声明它后面的一串字符串是类型，而不是其他的。  

比如这样： 

```cpp
#include <iostream>
using namespace std;

class A {
    typedef int LType;
public:
    A() {
        A::LType a = 100;
        cout << a << endl;
    }
};

int main() {
    A();
    return 0;
}
```

像上面的代码，可能在有些编译器编译得过，有些编译不过。`A::LType` 是有歧义的，它可以指代 A 的下属类型，也可以指代 A 的静态变量。如果我们要明确的告诉编译器，`A::LType` 是一个类型，就需要这样写： `typename A::LType a = 100;`。  

类似的，经常在一些库里面看到函数的入参前加了 `typename` 关键字，它的作用就是表面后面跟着的是类型，而不是其他的。   

另外，还有这样的写法：`typedef typename vector<T>::size_type size_type;`，这里的含义就是 `typedef` 定义了一个名为 `size_type` 的别名，它指代 `typename vector<T>::size_type`。`typename` 的作用就是声明 `vector<T>::size_type` 是类型，而不是其他的。  

---

## 1.6 万能引用与完美转发


---

# 2. 参考

[1] 五车书管. 函数模板的重载，偏特化，和全特化. Available at https://zhuanlan.zhihu.com/p/314340244, 2020-11-26.   