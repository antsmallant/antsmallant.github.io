---
layout: post
title: "lua vm 五: upvalue 与游戏服务器热更新"
date: 2024-04-12
last_modified_at: 2024-04-10
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>

# 前言

在 lua vm 中，upvalue 是一个重要的数据结构。upvalue 以一种高效的方式实现了词法作用域，使得函数能成为 lua 中的第一类值，也因其高效的设计，导致在实现上有点复杂。   

函数+upvalue 构成了闭包（closure），在 lua 中调用一个函数，实际上是调用一个闭包。即它的函数，总是带有若干个 upvalue 构造的上下文的，虽然有时候 upvalue 个数可能为 0。  

这种带 “上下文” 的函数，也导致了热更新的麻烦，可以说是麻烦透顶了。没法简单的通过替换新的函数代码来更新一个旧闭包，因为旧闭包上可能带着几个 upvalue，这几个 upvalue 的值可能已经发生改变，或者正被其他的函数使用着。所以，要更新一个旧闭包，得把旧闭包上的所有 upvalue 都找出来，绑定到新函数上，形成一个新闭包，再用这个新闭包替换旧闭包。   

<br/>
<div align="center">
<img src="https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/lua-vm-upvalue-function-share-upvalue.drawio.png"/>
</div>
<center>图1：函数与upvalue</center>
<br/>

本文主要讲 upvalue 在 lua vm 中的实现，之后以 skynet 为例讲一下游戏服务器如何解决 upvalue 的绑定问题，实现热更新。    

---


# 1. upvalue

---

## 1.1 upvalue 要解决的问题

upvalue 就是外部函数的局部变量，比如下面的函数定义中，base 就是 inner 这个函数的一个 upvalue。  

```lua
local function getf(delta)
    local fvar1 = 100
    local function inner()
        return fvar1+delta
    end
    return inner
end

local f1 = getf(10)
```

upvalue 复杂的地方在于，在离开了 upvalue 的作用域之后，还要能够访问得到。比如上面调用了 `local f1 = getf(10)` ，`fvar1` 这个变量是在 `getf` 的栈上分配的，`getf` 返回后，它的栈空间已经被抹掉了，但 `inner` 还要能访问 `fvar1` 这个变量，所以要想办法把它捕捉下来。  

---

## 1.2 upvalue 的实现

与 upvalue 相关的结构体有：  

1、

2、lua_State 中的 openupval 字段，它是 UpVal 类型的链表，它相当于一个 cache，cache 了当前栈上还存活着的，被引用到的 upvalue。  
```c
struct lua_State {
  ...
  UpVal *openupval;  /* list of open upvalues in this stack */
  ...
};
```

3、LClosure 中的 upvalue 数组，

typedef struct CClosure {
  ClosureHeader;
  lua_CFunction f;
  TValue upvalue[1];  /* list of upvalues */
} CClosure;


typedef struct LClosure {
  ClosureHeader;
  struct Proto *p;
  UpVal *upvals[1];  /* list of upvalues */
} LClosure;


举个例子，对于这样一个脚本，内部的函数 f1、f2 既引用了 getf 之外的变量 var1，也引用了 getf 之内的变量 var2、var3，并且在 `local f1, f2 = getf()` 调用完成后，f1 还要能访问到 var1、var2，f2 还要能访问到 var1、var3。  

```lua

local var1 = 1

local funtion getf()
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


从编译结果可以看到，每个 Proto 都会生成 UpvalueDesc 数组，用于描述这个函数（proto）会用到的 upvalue，index 就是它们是第几个 upvalue，instack 是一个辅助变量，用于说明这个 upvalue 是否刚好是上一层函数的局部变量。  

从例子上可以看到，f1 引用了上一层函数 getf 的局部变量 var2，所以它的 instack 值是 1，而引用了上两层的局部变量 var1，则它的 instack 是 0。  

instack 主要就是在创建 Closure 的时候帮助初始化 Closure 的 upvals 数组，对于 instack 为 1 的 upvalue，直接搜索上一层函数的栈空间即可，对于 instack 为 0 的 upvalue，就不能这样了，为什么呢？因为上两层的有可能已经不在栈上了。能想象得到吗？举个例子： 

```lua
local function l1()
    local var1 = 1
    local function l2()
        local var2 = 2
        local function l3()
            return var1+var2+3
        end
        return l3
    end
    return l2
end

local ret_l2 = l1()
local ret_l3 = ret_l2()
```

调用 l1 的时候，得到了 l2，这时候 l1 已经返回了，它的栈已经回收了，这时候再调用 l2，在创建 l3 这个闭包的时候，是不可能再找到 l1 的栈去搜索 var1 这个变量的。  

所以，要解决这个问题，就需要让 l2 在创建的时候，先帮忙把 var1 捕捉下来保存到自己的 upvals 数组中，等 l3 创建的时候，就可以从 l2 的 upvals 数组中找到了。  

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

函数实现可以看到，instack 为 1 时，调用 `luaF_findupval` 去上一层函数的栈上搜索，instack 为 0 时，上一层函数已经帮忙捕捉好了，直接从它的 upvals 数组（即这里的 encup 变量中）索引。  

这里补充说明一下 `uv[i].idx`，这个就是 upvaldesc 的其中一列，就表明如果 instack 为 0，那么它对应于上一层函数的 upvals 数组的第几项。   

---


分两个阶段讲，getf 调用时以及 getf 调用后。  

1、getf 调用时，var2、var3 这两个变量作为 f1, f2 的 upvalue，它们还处在 getf 的栈上，这时候它们会被放在 lua_State 的 openupval 链表中。  

2、getf 调用后，它的栈要被收回的，这时候 lua vm 会调用 luaF_close 来关闭 (close) `getf` 栈上被引用的 upvalue，最终是 luaF_closeupval 这个函数执行：  

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

要理解这个函数，就要知道 StkId level 这个参数的意义，它是 getf 的 base 指针，即它的栈底。同个 lua_State 的函数调用链上的所有函数共用一个栈，按顺序各占一段栈空间，栈是一个数组，所以后调用的函数的变量在栈上的索引是更大的，表现上就是指针值更大。而 openupval 链表里面 Upval 里的 p 就是指向这指针。openupval 是 根据变量在栈上出现的先后排序的，链头是最先出现的，链尾是最后出现的，所以从链头开始，只要它里面的 p 值大于等于 getf 的 base 值，就说明这是 getf 栈上的变量，要 close 掉。  

close 的操作就是把 upval 从 openupval 链表移掉，同时把 upval 的 p 指向的值拷贝到它自身上。  

这里也就大概这么一讲，文字表达反而啰嗦，实际看一下代码就清晰了，就几个要点：  

1、栈是一个数组，每个函数各占一段空间，按调用顺序先后排列的； 
2、每个函数里的本地变量就是一个指针，即 StkId，它的定义是 `typedef StackValue *StkId;`，即一个 `StackValue *` 类型的指针，指向栈数组上的一个元素；
3、StkId 是可以比较大小的，在栈上越靠后，它的值越大；  


---

# 2. lua 热更新

前言已经提到 upvalue 给热更新带来的麻烦，我日常开发中，使用的比较多的是 skynet。在实际使用中，我们并不真正的做热更新，即不做功能上的热更新；而是做一些 “热修复”，即修复一些 bug。  

功能上的热更新，应该是通过架构层面上的设计来实现，因为它要考虑的问题会更多，并且搞不好，玩家就数据状态不一致了，得不偿失，这个话题暂且不说。   

热修复，就是用新代码替换旧代码，前言也提到了，没法简单的替换，要把旧函数上的 upvalue 找出来，绑定到新函数上。   

这篇文章 （ [Lua 服务端热更新](https://yuerer.com/Lua%E6%9C%8D%E5%8A%A1%E7%AB%AF%E7%83%AD%E6%9B%B4%E6%96%B0/) ）的作者提到了一种比较 “通用” 的办法，但在实际生产环境中，这种遍历的方式，可能非常耗时，以至服务端会出现不小的卡顿，导致帧率跑不满。所以，这种遍历的做法，比较适合轻负载的，对帧率要求不高的游戏。    

在 skynet 下，我们生产上使用的 hotfix 方式是点对点的，即只修复特定的需要修复的函数。skynet 暴露了 inject 接口，可以在一个服务中执行一份代码文件，这份代码文件我们可以写上新函数，然后利用 lua 的 debug 库完全 upvalue 的重新绑定。  

大体实现差不多是这样：  

```lua

```

不过，这里面有些状况是需要特别考虑的，就是新函数可能依赖了旧函数（闭包）上没有的 upvalue，这种情况可能会被我们忽略掉。  



---

# 2. 参考