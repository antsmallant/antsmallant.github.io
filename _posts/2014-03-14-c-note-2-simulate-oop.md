---
layout: post
title: "c 笔记：c 语言模拟面向对象"
date: 2014-03-14
last_modified_at: 2023-05-01
categories: [c]
tags: [c]
---

* 目录  
{:toc}
<br/>


c 语言要模拟面向对象，即要模拟这几个特性：封装、继承、多态。    

---

# 1. 模拟 oo 的三大特性

---

## 1.1 封装    

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

---

## 1.2 继承

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

--- 

## 1.3 多态

c++ 的多态有编译时多态，有运行时多态，显然这里我们也不可能实现编译时多态，但运行时多态还是可以进行一定程度的模拟的。c++ 的运行时多态，是使用虚函数表的机制来实现的。  

关于 c++ 虚函数表的内部实现细节，可以参考这篇文章：[《C++中虚函数、虚继承内存模型》](https://zhuanlan.zhihu.com/p/41309205) [2]，总结得比较到位。简单来说，当一个类包含虚函数时，不论是继承来的，还是自己定义的，编译器就会为此类自动的新增一个隐藏的成员变量，即虚函数表的指针。虚函数表是类级别的，它在编译时被确定，存储在只读数据段 (.rodata) 中。  

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

# 2. 拓展阅读 

* [The C Object System: Using C as a High-Level Object-Oriented Language](https://arxiv.org/abs/1003.2547)

* [我所偏爱的 C 语言面向对象编程范式（by 云风）](https://blog.codingnow.com/2010/03/object_oriented_programming_in_c.html)  

* [《C语言实现虚函数/继承/封装》](https://zhuanlan.zhihu.com/p/566782733)  

* [《C 语言实现面向对象（一）：初步实现三个基本特征》](https://schaepher.github.io/2020/03/12/c-oop/)

* [《使用C语言实现面相对对象三大特性》](https://www.cnblogs.com/Kroner/p/16456733.html)


---

# 3. 参考