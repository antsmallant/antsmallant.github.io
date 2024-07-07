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

```

---

# 2. 参考