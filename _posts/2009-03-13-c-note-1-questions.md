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

## 1.3 struct 使用 typedef 定义别名是否是好的做法？  

在多数情况下并不适合，参照 linux 内核的: [kernel coding-style](https://www.kernel.org/doc/html/latest/process/coding-style.html#typedefs)，里面提到了一些关于 typedef 的 rule。   

对于 struct，当它是一个透明的类型，别人可以访问里面的成员时，那么不要用 typedef 来取别名。这样的好处是，使用这样的方式定义变量 `struct SomeType somevar;`，当别人看到 `struct` 时，一下子就知道 `somevar` 是一个 `struct` 类型的，这样更清晰。  

---

## 1.4 c 函数支持重载吗？

不支持，c 编译的时候，函数名符号不会像 c++ 那样结合参数进行 mangling，所以同名函数在编译后也是相同的符号，故无法重载。  

---

## 1.5 c 语言 enum 最后多个逗号

c99 开始是合法的，在此之前不合法。  

---

## 1.6 `#include <>` 与 `#include ""` 的区别

`#include<> vs #include””` [1]

|No.	| `#include<filename>`	| `#include”filename”` |
|:--|:--|:--|
|1 |	The preprocessor searches in the search directories pre-designated by the compiler/ IDE.	| The preprocessor searches in the same directory as the file containing the directive.|
|2 |	The header files can be found at default locations like /usr/include or /usr/local/include.	| The header files can be found in -I defined folders.|
|3 |	This method is normally used for standard library header files.	| This method is normally used for programmer-defined header files.|
|4 |	<> It indicates that file is system header file	| ” ” It indicates that file is user-defined header file|

<br/>  

翻译过来：
* `<>` 用于包含标准库头文件，`""` 用于包含用户自定义头文件；  
* `<>` 从编译器或IDC指定的目录搜索，比如 `/usr/include`，`/usr/local/include`；`""` 从当前目录搜索，或者从 `-I` 指定的目录搜索。  

---

## 1.6 c 如何模拟面向对象？  

要模拟面向对象，即要实现封装、继承、多态。  

**一、封装**    

封装就是把属性和对属性的操作封装在一个独立的实体中，这种实体在 c++ 称为类。  

1、c 语言模拟封装，可以用 struct 来模拟类，struct 中可以使用函数指针变量来保存类的成员函数。   
2、c 函数要访问类里面的成员，需要有类对象的指针，那么这些成员函数的第一个变量可以统一为指向对象指向的指针，这个相当于模拟 c++ 的 this 指针。   
3、但是 c++ 的 public, protected, private 这几种对成员的访问限制，在 c 中模拟不了。   

举个例子： 

```c
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

struct Point {
    int x;
    int y;
    void (*scale) (struct Point*, int);
};

void point_scale(struct Point* self, int factor) {
    self->x *= factor;
    self->y *= factor;
}

void point_init(struct Point* pt) {
    pt->x = 10;
    pt->y = 20;
    pt->scale = point_scale;
}

void point_destroy(struct Point* pt) {
    printf("point destroy\n");
    // do not free here
}

int main() {
    struct Point* pt = (struct Point*)malloc(sizeof(struct Point));
    point_init(pt);
    printf("before scale: %d, %d\n", pt->x, pt->y);
    pt->scale(pt, 30);
    printf("after scale: %d, %d\n", pt->x, pt->y);
    point_destroy(pt);
    free(pt);
    return 0;
}
```

说明：    
1、在这种模拟中，使用函数指针来保存函数，相比于 C++，是一种内存上的额外开销，C++ 对象的内存里不需要保存成员函数指针，它在编译时就能确定。     

<br/>

**二、继承**   

可以在子类里定义一个基类的对象作为变量，并且在重载函数的时候，在重载函数里，选择性的调用基类的函数。  

举个例子：   

```c
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

struct Base {
    int x;
    void (*print) (struct Base*);
};

void base_print(struct Base* self) {
    printf("base, x: %d\n", self->x);
}

void base_init(struct Base* base) {
    base->x = 10;
    base->print = base_print;
}

void base_destroy(struct Base* base) {
    printf("base destroy\n");
}

struct Derived {
    struct Base base;
    int y;
    void (*derivedPrint) (struct Derived*);
};

void derived_print(struct Derived* self) {
    self->base.print(&self->base);
    printf("derived, y: %d\n", self->y);
}

void derived_init(struct Derived* d) {
    base_init((struct Base*)d);
    d->y = 20;
    d->derivedPrint = derived_print;
}

void derived_destroy(struct Derived* d) {
    printf("derived_destroy\n");
    base_destroy((struct Base*)d);
}

int main() {
    struct Derived* d = (struct Derived*)malloc(sizeof(struct Derived));
    derived_init(d);
    d->derivedPrint(d);
    derived_destroy(d);
    free(d);
    return 0;
}
```

</br>

**三、多态**   

c++ 的多态有编译时多态，有运行时多态，显然这里我们也不可能实现编译时多态，但运行时多态还是可以进行一定程度的模拟的。c++ 的运行时多态，是使用虚函数表的机制来实现的。  

关于 c++ 虚函数表的内部实现细节，可以参考这篇文章：[C++中虚函数、虚继承内存模型](https://zhuanlan.zhihu.com/p/41309205?utm_psn=1706095557872001024)，总结得比较到位。简单来说，当一个类包含虚函数时，不论是继承来的，还是自己定义的，编译器就会为此类自动的新增一个隐藏的成员变量，即虚函数表的指针。虚函数表是类级别的，它在编译时被确定，存储在只读数据段 (.rodata) 中。  

一般情况，c++ 中一个类只有一个虚函数表指针，复杂的情况下，一个类会有好几个虚函数表指针。为了简单起见，这里只模拟一个类只有一个虚函数指针的情形。  

c 在模拟多态时，可以在定义类的同时，也定义好一个函数指针数组，来充当虚函数表。  

举个例子：  

```c
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

struct Animal {
    void** virtable;
    char name[64];
    void (*fly)(void*);
    void (*walk)(void*);
};

void animal_fly(void* self) {
    struct Animal* p = (struct Animal*)self;
    printf("animal %s fly\n", p->name);
}

void animal_walk(void* self) {
    struct Animal* p = (struct Animal*)self;
    printf("animal %s walk\n", p->name);
}

void* animal_virt[2] = {
    animal_fly,
    animal_walk
};

void virt_fly(void* self) {
    struct Animal* ani = (struct Animal*)self;
    void(*impl_fly)(void*) = ani->virtable[0];
    impl_fly (self);
}

void virt_walk(void* self) {
    struct Animal* ani = (struct Animal*)self;
    void(*impl_walk)(void*) = ani->virtable[1];
    impl_walk (self);
}

void animal_init(struct Animal* animal) {
    animal->virtable = animal_virt;
    animal->fly = virt_fly;
    animal->walk = virt_walk;
    snprintf(animal->name, 64, "aa");
}

void animal_destroy(struct Animal* animal) {
    printf("animal_destroy\n");
}

struct Duck {
    struct Animal base;
    int head_color;
};

void duck_fly(struct Duck* self) {
    printf("duck %s fly\n", self->base.name);
}

void duck_walk(struct Duck* self) {
    printf("duck %s walk\n", self->base.name);
}

void* duck_virt[2] = {
    duck_fly,
    duck_walk    
};

void duck_init(struct Duck* duck) {
    animal_init((struct Animal*)duck);
    duck->base.virtable = duck_virt;
    snprintf(duck->base.name, 64, "bb");
}

void duck_destroy(struct Duck* duck) {
    printf("duck_destroy\n");
    animal_destroy((struct Animal*)duck);
}

int main() {
    struct Duck* d = (struct Duck*)malloc(sizeof(struct Duck));
    duck_init(d);

    struct Animal* ani = (struct Animal*)d;
    ani->fly(ani);
    ani->walk(ani);
    
    duck_destroy(d);
    free(d);
    return 0;
}
```

输出：   

```
duck bb fly
duck bb walk
duck_destroy
animal_destroy
```


---

# 2. 参考

[1] geeksforgeeks. Difference between #include and #include” ” in C/C++ with Examples. Available at https://www.geeksforgeeks.org/difference-between-include-and-include-in-c-c-with-examples/, 2023-4-22.   