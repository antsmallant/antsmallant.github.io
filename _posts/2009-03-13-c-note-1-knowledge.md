---
layout: post
title: "c 笔记一：常识"
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

## 1.3 struct 使用 typedef 定义别名是否是好的做法？  

在多数情况下不推荐使用 typedef 给 struct 定义别名，参照 linux 内核的: [kernel coding-style](https://www.kernel.org/doc/html/latest/process/coding-style.html#typedefs)，里面提到了一些关于 typedef 的 rule。   

对于 struct，当它是一个透明的类型，别人可以访问里面的成员时，那么不要用 typedef 来取别名。这样的好处是，使用这样的方式定义变量 `struct SomeType somevar;`，当别人看到 `struct` 时，一下子就知道 `somevar` 是一个 `struct` 类型的，这样更清晰。  

---

## 1.4 c 函数支持重载吗？

不支持，c 编译的时候，函数名符号不会像 c++ 那样结合参数进行 mangling，所以同名函数在编译后也是相同的符号，故无法重载。  

---

## 1.5 c 语言 enum 最后多个逗号

c99 开始是合法的，在此之前不合法。  

---

## 1.6 `#include <>` 与 `#include ""` 的区别

下表参考自： [《Difference between #include and #include” ” in C/C++ with Examples》](https://www.geeksforgeeks.org/difference-between-include-and-include-in-c-c-with-examples/) [1]。  

<br/>

|No.	| `#include<filename>`	| `#include”filename”` |
|:--|:--|:--|
|1 |	The preprocessor searches in the search directories pre-designated by the compiler/ IDE.	| The preprocessor searches in the same directory as the file containing the directive.|
|2 |	The header files can be found at default locations like /usr/include or /usr/local/include.	| The header files can be found in -I defined folders.|
|3 |	This method is normally used for standard library header files.	| This method is normally used for programmer-defined header files.|
|4 |	<> It indicates that file is system header file	| ” ” It indicates that file is user-defined header file|

<br/>  

翻译过来：
* `<>` 用于包含标准库头文件，`""` 用于包含用户自定义头文件；  
* `<>` 从编译器或IDE指定的目录搜索，比如 `/usr/include`，`/usr/local/include`；`""` 从当前目录搜索，或者从 `-I` 指定的目录搜索。  

---

## 1.7 c99 的 VLA 具体是什么？  

VLA 即 variable length array，允许在运行时才确定数组的长度。在 c99 之前，数组的长度需要在编译时确定。在 c99 之后，可以这样定义数组：   

```c
void func(int n) {
    int arr[n];
}
```  

但要注意：    

1、长度确定后，数组长度也是不可变的。     

2、作用域有要求，file scope 不允许，block scope 或 proto scope 允许，有点细碎，具体可参考 [《c99-draft.html#6.7.5.2》](https://busybox.net/~landley/c99-draft.html#6.7.5.2) 给出的例子：   

>#8 EXAMPLE 4 All declarations of variably modified (VM) types have to be at either block scope or function prototype scope. Array objects declared with the static or extern storage class specifier cannot have a variable length array (VLA) type. However, an object declared with the static storage class specifier can have a VM type (that is, a pointer to a VLA type). Finally, all identifiers declared with a VM type have to be ordinary identifiers and cannot, therefore, be members of structures or unions.

```c
extern int n;
int A[n];                                       // Error - file scope VLA.
extern int (*p2)[n];            // Error - file scope VM.
int B[100];                             // OK - file scope but not VM.

void fvla(int m, int C[m][m])   // OK - VLA with prototype scope.
{
        typedef int VLA[m][m]   // OK - block scope typedef VLA.

        struct tag {
                int (*y)[n];            // Error - y not ordinary identifier.
                int z[n];                       // Error - z not ordinary identifier.
        };
        int D[m];                               // OK - auto VLA.
        static int E[m];                // Error - static block scope VLA.
        extern int F[m];                // Error - F has linkage and is VLA.
        int (*s)[m];                    // OK - auto pointer to VLA.
        extern int (*r)[m];             // Error - r had linkage and is
                                                // a pointer to VLA.
        static int (*q)[m] = &B; // OK - q is a static block
                                        // pointer to VLA.
}
```

<br/>

参考文章：[《GCC 中零长数组与变长数组》](https://www.cnblogs.com/hazir/p/variable_length_array.html)   

---

## 1.8 位域 (bit field)

redis 中有这样的写法： 

```c
typedef struct redisObject {
    unsigned type:4;
    unsigned encoding:4;
    unsigned lru:LRU_BITS; /* LRU time (relative to global lru_clock) or
                            * LFU data (least significant 8 bits frequency
                            * and most significant 16 bits access time). */
    int refcount;
    void *ptr;
} robj;
```

redisObject 结构体中的 type, encoding, lru 实际上是一种位域定义。位域是一种特殊的结构体成员，它限定了使用的位数，不需要一整个字节，语法是 `type fieldname : width`。只有整型或枚举可以用于定义位域。位域可以单独使用，也可以跟其他成员一起组成结构体。[3]     

参考文章：[《C 位域》](https://www.runoob.com/cprogramming/c-bit-fields.html)。   

---

## 1.9 restrict

---

## 1.10 宏实现 sizeof 

只是尝试一下模拟，并无实际意义。    

可以利用指针的运算来实现。如果不使用 `typeof` 关键字，则需要分别处理变量跟类型两种情况；如果使用，则可以统一起来。   

示例：

```c

#include <stdio.h>
#include <stdlib.h>

// 不使用 typeof 关键字
#define my_sizeof_var(v)    ( (size_t)(&v+1) - (size_t)(&v) )
#define my_sizeof_type(T)   ( (size_t)( (T*)0 + 1 ) )

// 使用 typeof 关键字
#define my_sizeof(X)        ( (size_t)( (typeof(X)*)0 + 1 ) )

int main() {
    int a = 10;
    
    printf( "%ld\n", my_sizeof_var(a) );
    printf( "%ld\n", my_sizeof_type(int) );

    printf( "%ld\n", my_sizeof(a) );
    printf( "%ld\n", my_sizeof(int) );

    return 0;
}

```

输出：

```
4
4
4
4
```

---

# 2. 参考

[1] geeksforgeeks. Difference between #include and #include” ” in C/C++ with Examples. Available at https://www.geeksforgeeks.org/difference-between-include-and-include-in-c-c-with-examples/, 2023-4-22.   

[2] Holy Chen. C++中虚函数、虚继承内存模型. Available at https://zhuanlan.zhihu.com/p/41309205, 2018-08-07.     

[3] runoob. C 位域. Available at https://www.runoob.com/cprogramming/c-bit-fields.html.   