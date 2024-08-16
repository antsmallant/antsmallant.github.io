---
layout: post
title: "lua vm 五: upvalue"
date: 2024-04-12
last_modified_at: 2024-04-12
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>

# 前言

在 lua vm 中，upvalue 是一个重要的数据结构。upvalue 以一种高效的方式实现了词法作用域，使得函数能成为 lua 中的第一类值，也因其高效的设计，导致在实现上有点复杂。   

函数 (proto) + upvalue 构成了闭包（closure），在 lua 中调用一个函数，实际上是调用一个闭包。upvalue 就相当于函数的上下文。  

这种带 “上下文” 的函数，也导致了热更新的麻烦，可以说是麻烦透顶了。没法简单的通过替换新的函数代码来更新一个旧闭包，因为旧闭包上可能带着几个 upvalue，这几个 upvalue 的值可能已经发生改变，或者也被其他的函数引用着。  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-upvalue-function-share-upvalue.drawio.png"/>
</div>
<center>图1：函数与upvalue</center>
<br/>

所以，要更新一个旧闭包，得把旧闭包上的所有 upvalue 都找出来，绑定到新函数上，形成一个新闭包，再用这个新闭包替换旧闭包。    

本文主要讲 upvalue 在 lua vm 中的实现，下篇文章再讲如何解决带有 upvalue 的闭包的热更新问题。   

下文分析基于 lua5.4.6。 

---


# 1. upvalue

---

## 1.1 upvalue 实现上要解决的问题

upvalue 就是外部函数的局部变量，比如下面的函数定义中，var1 就是 inner 的一个 upvalue。  

```lua
local function getf(delta)
    local var1 = 100
    local function inner()
        return var1+delta
    end
    return inner
end

local f1 = getf(10)
```

upvalue 复杂的地方在于，在离开了 upvalue 的作用域之后，还要能够访问得到。比如上面调用了 `local f1 = getf(10)` ，`var1` 是在 `getf` 的栈上分配的，`getf` 返回后，栈空间被抹掉，但 `inner` 还要能访问 `var1`，所以要想办法把它捕捉下来。  

---

## 1.2 upvalue 的实现

下面先讲 lua 闭包的 upvalue，最后再讲 c 闭包的，因为复杂性几乎都在 lua 闭包这里面了。  

---

### 1.2.1 upvalue 相关的结构体

与 upvalue 相关的结构体有：  

1、UpVal，可以说是 upvalue 的本体了，很巧妙的结构，运行时用到的变量。    

```c
typedef struct UpVal {
  CommonHeader;
  union {
    TValue *p;  /* points to stack or to its own value */
    ptrdiff_t offset;  /* used while the stack is being reallocated */
  } v;
  union {
    struct {  /* (when open) */
      struct UpVal *next;  /* linked list */
      struct UpVal **previous;
    } open;
    TValue value;  /* the value (when closed) */
  } u;
} UpVal;
```

2、Upvaldesc，这个是编译时产生的信息，Proto 结构体就包含 `Upvaldesc*` 类型的数组：upvalues，用于描述当前函数用到的 upvalue 信息。   

```c

typedef struct Upvaldesc {
  TString *name;  /* upvalue name (for debug information) */
  lu_byte instack;  /* whether it is in stack (register) */
  lu_byte idx;  /* index of upvalue (in stack or in outer function's list) */
  lu_byte kind;  /* kind of corresponding variable */
} Upvaldesc;

typedef struct Proto {
  ...
  Upvaldesc *upvalues;  /* upvalue information */
  ...
} Proto;

```

3、lua_State 中的 openupval 字段，它是 UpVal* 类型的链表，它相当于一个 cache，保存当前栈上还存活着的被引用到的 upvalue。   

```c

struct lua_State {
  ...
  UpVal *openupval;  /* list of open upvalues in this stack */
  ...
};

```

4、LClosure 中的 upvals 数组。  

```c

typedef struct LClosure {
  ClosureHeader;
  struct Proto *p;
  UpVal *upvals[1];  /* list of upvalues */
} LClosure;

```

---

### 1.2.2 upvalue 的访问

upvalue 是间接访问的，LClosure 结构体的 upvals 字段是 UpVal* 类型的数组。访问的时候先通过 upvals 获得到 UpVal 指针，再通过 UpVal 里面的 v.p 去访问具体的变量，伪码如下：  

```c

UpVal* UpValPtr = closure->upvals[upidx];
TValue* p = UpValPtr->v.p;

```

需要这样间接访问，主要是因为 UpVal 本身会随着函数调用的返回发生状态的变化：从 open 改为 close，这时它的值也从栈上被拷贝到了 "自己身上"，所以指针（v.p）是变化的，不能写死。  

至于为什么会发生 open 到 close 的变化，后面会讲。  

---

### 1.2.3 upvalue 的创建

upvalue 是在编译的时候计算好一个 Proto 需要什么 upvalue，相关信息存放在 Proto 的 upvalues 数组（ `Upvaldesc *upvalues;  /* upvalue information */`）中的。   

举个例子，对于这样一个脚本，内部的函数 f1、f2 既引用了 getf 之外的变量 var1，也引用了 getf 之内的变量 var2、var3，并且在 `local f1, f2 = getf()` 调用完成后，f1 还要能访问到 var1、var2，f2 还要能访问到 var1、var3。  

```lua

local var1 = 1

local function getf()
    local var2 = 2
    local var3 = 3

    local function f1()
        return var1 + var2
    end

    local function f2()
        return var1 + var3
    end

    return f1, f2
end

local retf1, retf2 = getf()

```

编译结果是：  

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-upvalue-instack.png"/>
</div>
<center>图2：upvalue 编译信息</center>
<br/>


从编译结果可以看到，每个 Proto 都会生成 UpvalueDesc 数组，用于描述这个函数（proto）会用到的 upvalue。   

* index 表示在 LClosure 的 upvals 数组中是第几个。  
* name 表示变量名。  
* instack 表示这个 upvalue 是否刚好是上一层函数的局部变量，比如 var2 是 f1 的上一层的，所以 instack 为 true，而 var1 是上两层的，所以为 false。  
* idx 表示 instack 为 false 的情况下，可以在上一层函数的 upvals 数组的第几个找到这个 upvalue。  
* kind 表示 upvalue 类型，一般都是 VDKREG，即普通类型。 

<br/>

补充说明，kind 是 lua5.4 才整出来的，lua5.3 及之前都只有 VDKREG。5.4 新增了 RDKCONST，RDKTOCLOSE，RDKCTC。    

* RDKCONST 是对应到 `<const>`，指定变量为常量。   
* RDKTOCLOSE 是对应到 `<close>`，指定变量为 to be closed 的（类似于 RAII 特性，超出作用域后执行 `__close` 元函数）。   
* RDKCTC 我也闹不清楚。  

<br/>

从例子上可以看到，f1 引用了上一层函数 getf 的局部变量 var2，所以它的 instack 值是 true，而引用了上两层的局部变量 var1，则它的 instack 是 false。  

instack 主要就是在创建 Closure 的时候帮助初始化 Closure 的 upvals 数组，对于 instack 为 true 的 upvalue，直接搜索上一层函数的栈空间即可，对于 instack 为 false 的 upvalue，就不能这样了，为什么呢？因为上两层的有可能已经不在栈上了。能想象得到吗？举个例子：   

```lua

local function f1()
    local var1 = 1

    local function f2()
        local var2 = 2

        local function f3()
            return var1+var2+3
        end

        return f3
    end

    return f2
end

local ret_f2 = f1()

local ret_f3 = ret_f2()

```

调用 `f1` 的时候，得到了 `f2`，这时候 `f1` 已经返回了，它的栈已经回收了，这时候再调用 `f2`，在创建 `f3` 这个闭包的时候，是不可能再找到 `f1` 的栈去搜索 `var1` 这个变量的。  

所以，要解决这个问题，就需要让 `f2` 在创建的时候，先帮忙把 `var1` 捕捉下来保存到自己的 `upvals` 数组中，等 `f3` 创建的时候，就可以从 `f2` 的 `upvals` 数组中找到了。  

这正是 `pushclosure` 干的活：  

```c

static void pushclosure (lua_State *L, Proto *p, UpVal **encup, StkId base,
                         StkId ra) {
  int nup = p->sizeupvalues;
  Upvaldesc *uv = p->upvalues;
  int i;
  LClosure *ncl = luaF_newLclosure(L, nup);
  ncl->p = p;
  setclLvalue2s(L, ra, ncl);  /* anchor new closure in stack */
  for (i = 0; i < nup; i++) {  /* fill in its upvalues */
    if (uv[i].instack)  /* upvalue refers to local variable? */
      ncl->upvals[i] = luaF_findupval(L, base + uv[i].idx);
    else  /* get upvalue from enclosing function */
      ncl->upvals[i] = encup[uv[i].idx];
    luaC_objbarrier(L, ncl, ncl->upvals[i]);
  }
}

```

函数实现可以看到，instack 为 true 时，调用 `luaF_findupval` 去上一层函数的栈上搜索，instack 为 false 时，上一层函数已经帮忙捕捉好了，直接从它的 upvals 数组（即这里的 encup 变量中）索引。  

这里 `uv[i].idx` 就是上面 upvaldesc 的 idx 列，即当 instack 为 false 时，它对应于上一层函数的 upvals 数组的第几项。    

---

### 1.2.4 upvalue 的变化：从 open 到 close 

分两个阶段讲，getf 调用时以及 getf 调用后。  

1、getf 调用时，var2、var3 这两个变量作为 f1, f2 的 upvalue，它们还处在 getf 的栈上，这时候它们会被放在 lua_State 的 openupval 链表中。   

2、getf 调用后，它的栈要被收回的，这时候 lua vm 会调用 luaF_close 来关闭 `getf` 栈上被引用的 upvalue，最终是 luaF_closeupval 这个函数执行：  

```lua
void luaF_closeupval (lua_State *L, StkId level) {
  UpVal *uv;
  StkId upl;  /* stack index pointed by 'uv' */
  while ((uv = L->openupval) != NULL && (upl = uplevel(uv)) >= level) {
    TValue *slot = &uv->u.value;  /* new position for value */
    lua_assert(uplevel(uv) < L->top.p);
    luaF_unlinkupval(uv);  /* remove upvalue from 'openupval' list */
    setobj(L, slot, uv->v.p);  /* move value to upvalue slot */
    uv->v.p = slot;  /* now current value lives here */
    if (!iswhite(uv)) {  /* neither white nor dead? */
      nw2black(uv);  /* closed upvalues cannot be gray */
      luaC_barrier(L, uv, slot);
    }
  }
}
```

要理解这个函数，就要知道 `StkId level` 这个参数的意义，它在这里是 `getf` 的 `base` 指针，即它的栈底。同个 lua_State 的函数调用链上的所有函数共用一个栈，按顺序各占一段栈空间，栈是一个数组，所以后调用的函数的变量在栈上的索引是更大的，表现上就是指针值更大。而 openupval 链表里面 Upval 里的 p 就是指向这指针，所以遍历 openupval 的时候，遇到 p 比 base 大的，就表明这个是 `getf` 栈上的变量，要把它 close 掉。 

close 的操作就是把 upval 从 openupval 链表移掉，同时把 upval 的 p 指向的值拷贝到它自身上。    

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-stack-upvalue-close.png"/>
</div>
<center>图3：upvalue close 时的拷贝</center>
<br/>

---

### 1.2.5 C 闭包中的 upvalue

C 闭包（CClosure）也是有 upvalue 的，是在 lua_pushcclosure 时设置的，但用的是值拷贝，所以多个 C 闭包不能共享 upvalue。如果要在多个 C 闭包，只能是各自的upvalue 指向同一个 table 这样的变量。  

CClosure 的 upvalue 直接用的是 TValue 类型的数组（不是指针），在创建的时候用的值拷贝。  

```c
typedef struct CClosure {
  ClosureHeader;
  lua_CFunction f;
  TValue upvalue[1];  /* list of upvalues */
} CClosure;
```

---

正文完。  
