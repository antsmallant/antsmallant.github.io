---
layout: post
title: "c 笔记一：常识、用法"
date: 2009-03-13
last_modified_at: 2009-03-13
categories: [c]
tags: [c]
---

* 目录  
{:toc}
<br/>

# 1. 常识

## 1.1 struct 与 typedef

1、不使用 `typedef`，那么后续每次都要加上 `struct`，比如这样：    

```c
#include "stdio.h"
#include "stdlib.h"

struct S {
    int x;
};

int main() {
    struct S s = {10};
    printf("%d\n", s.x);
}

2、使用 `typedef` ，后续就可以不需要加上 `struct`，typedef 有有好几种写法，

```

---

# 2. 参考