---
layout: post
title: "c 笔记一：常识、用法"
date: 2009-03-13
last_modified_at: 2023-05-01
categories: [c]
tags: [c]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 c 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

---

## 1.1 struct 与 typedef

1、不使用 `typedef`    

后续定义变量都要加上 `struct`，比如这样：    

```c
#include "stdio.h"
#include "stdlib.h"

struct S {
    int x;
};

int main() {
    struct S s = {10};  // struct S 不能只写 S
    printf("%d\n", s.x);
}
```

<br/>

2、使用 `typedef` 

后续定义变量不需要加上 `struct`，此处有好几种写法。   

**写法一**

标准写法： 

```c
typedef struct structname {
    ...
} aliasname;
```

比如：  

```c
typedef struct S {
    int x;
} S;
```


变化1：`aliasname` 可以换成别的，不需要仍然是 `S`，比如：   

```c
typedef struct S {
    int x;
} AliasOfS;
```

变化2：`structname` 本身也可以省略的，比如:    

```c
typedef struct {
    int x;
} S;  // 此处 S 也可以换成别的，随便一个 aliasname 都行
```

<br/>

**写法二**

标准写法： 

```c
struct structname {
    ...
};
typedef struct structname aliasname;  // aliasname 可以与 structname 相同
```

比如： 

```c
struct S {
    int x;
};

typedef struct S AliasOfS; // ok 的
typedef struct S S; // 也 ok 的，aliasname 也可以使用 S 本身
```

<br/>

3、注意点

当使用 typedef 并且 structname 与 aliasname 一样的情况下，用 `struct structname var;` 与 `structname var;` 都是 ok 的。   

---

## 1.2 struct 中包含自己类型的指针

无论是否 typdef，在 struct 内部，只能用 `struct structname` 来声明自己类型的变量，比如这样： 

```c
struct S {
    int x;
    struct S* next;
};
```

或者这样： 

```c
typedef struct S {
    int x;
    void (*print)(struct S* self);
} S;
```

---

## 1.3 c 函数支持重载吗？

不支持，c 编译的时候，函数名符号不会像 c++ 那样结合参数进行 mangling，所以同名函数在编译后也是相同的符号，故无法重载。  

---

# 2. 参考