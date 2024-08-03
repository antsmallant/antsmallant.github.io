---
layout: post
title: "lua 笔记二：table 的用法及底层实现"
date: 2022-05-02
last_modified_at: 2022-05-02
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>

本文记录 lua table 的用法及底层实现。  

---

# 1. 用法

---

## 1.1 table 取长度的问题

在 lua 中，通过一元前置符 `#` 来求 table 的长度。   

表的长度只有在表是一个序列时有意义，序列是指表的正数键集合是 `{1...n}`，即要求所有的正数键放在一起排序，是一串连续的数据，从 1 到 n。 [1] 

像这样的 `{10, 20, nil, 40}` 就不是序列，因为它的正数键集是 `{1,2,4}`，并不是连续的。这种情况下，表的长度是无定义的。不过，lua 在这种情况下取长度也会给出一个值，只不过这个值会有些随机，它只是符合这种条件的任意一个值：一个整数下标n，满足 t[n] 不是 nil，而 t[n+1] 是 nil。   

比如：   

```
> t = {10,20,nil,40}
> #t
4

> t = {nil,nil,30,nil}
> #t
3

> t = {1,nil,nil,nil,nil,nil,7}
> #t
7

> t[8] = 8
> #t
1
```

在源码（lua5.3.6）中，是通过 ltable.c 的 `luaH_getn` 函数获取 table 的长度的。  

---

# 2. 底层实现 

以下分析使用 lua-5.3.6，使用 [https://www.luac.nl/](https://www.luac.nl/) 翻译字节码。      

table 的基本信息：  

1、包含了数组和哈希表两部分。    
2、可支持两大功能：容器，面向对象（通过 metatable）。   

---

## 2.1 数据结构

关于 Table 如何存储的，如何解决哈希冲突的，都在下面的代码注释中写明了。  

table 相关的结构体在 lobject.h 中定义。  

```c

// 注意，key 是一个 union 类型的
typedef union TKey {
  struct {
    TValuefields;
    int next;  // nk 与 tvk 相比，只是多了一个 next 字段，此字段用于哈希冲突时，计算冲突节点的位置。
               // lua 用开链表法解决哈希冲突，但并不额外创建新的链表来存储冲突节点，而是把所有节点都
               // 存储在哈希数组上。冲突时就在哈希数组上找一个空闲的位置存放冲突节点，next 实际上就是
               // 哈希数组上节点与节点之间的位置偏移量，要注意不是数组下标。  
  } nk;
  TValue tvk;
} TKey;

typedef struct Node {
  TValue i_val;
  TKey i_key;
} Node;

typedef struct Table {
  CommonHeader;
  lu_byte flags; 
  lu_byte lsizenode;       
  unsigned int sizearray;  
  TValue *array;           // 数组部分，类型为 TValue*，长度为 sizearray 的数组
  Node *node;              // 哈希部分，类型为 Node*，长度为 2 ^ lsizenode 的数组
  Node *lastfree;          // 哈希部分空闲位置的指针，在此之前的才是空闲的，寻找时从此往前找
  struct Table *metatable;
  GCObject *gclist;
} Table;
``` 

---

## 2.2 新建表  

通过 ltable.c 的 `luaH_new` 创建一个新表，可以看到，初始时，表的数组部分跟哈希部分都是空的。   

```c
Table *luaH_new (lua_State *L) {
  GCObject *o = luaC_newobj(L, LUA_TTABLE, sizeof(Table));
  Table *t = gco2t(o);
  t->metatable = NULL;
  t->flags = cast_byte(~0);
  t->array = NULL;
  t->sizearray = 0;
  setnodevector(L, t, 0);
  return t;
}

static void setnodevector (lua_State *L, Table *t, unsigned int size) {
  if (size == 0) {  /* no elements to hash part? */
    t->node = cast(Node *, dummynode);  /* use common 'dummynode' */
    t->lsizenode = 0;
    t->lastfree = NULL;  /* signal that it is using dummy node */
  }
  else {
    ...
  }
}
```

---

## 2.3 查询

主要执行查询的是 `ltable.c` 里面 `luaH_get` 函数。     

```c
const TValue *luaH_get (Table *t, const TValue *key) {
  switch (ttype(key)) {
    case LUA_TSHRSTR: return luaH_getshortstr(t, tsvalue(key));
    case LUA_TNUMINT: return luaH_getint(t, ivalue(key));
    case LUA_TNIL: return luaO_nilobject;
    case LUA_TNUMFLT: {
      lua_Integer k;
      if (luaV_tointeger(key, &k, 0)) /* index is int? */
        return luaH_getint(t, k);  /* use specialized version */
      /* else... */
    }  /* FALLTHROUGH */
    default:
      return getgeneric(t, key);
  }
}
```

<br/>

根据 key 的类型，使用对应的函数进行查询：  

1、key 为 nil 的，直接返回空对象。    

<br/>

2、key 为整型或可转为整型的浮点型的，使用 `luaH_getint` 查找。   

`luaH_getint` 涉及两部分的查找，如果 key 在 sizearray 范围内，则返回数组部分的。否则，通过 `hashint` 取得 key 的哈希值，从哈希部分查找。上文讲数据结构的时候已经说过，哈希部分是把所有的 node 都放到哈希数组里的，所以在哈希部分查找时，就是先定位到一个位置，如果 key 不相同，就“链式”查找，`n += nx`，此处的 nx 是偏移量。  

```c
const TValue *luaH_getint (Table *t, lua_Integer key) {
  /* (1 <= key && key <= t->sizearray) */
  if (l_castS2U(key) - 1 < t->sizearray)
    return &t->array[key - 1];
  else {
    Node *n = hashint(t, key);
    for (;;) {  /* check whether 'key' is somewhere in the chain */
      if (ttisinteger(gkey(n)) && ivalue(gkey(n)) == key)
        return gval(n);  /* that's it */
      else {
        int nx = gnext(n);
        if (nx == 0) break;
        n += nx;  // 注意，nx 即是 Key 里的 next 字段，是偏移量
      }
    }
    return luaO_nilobject;
  }
}
``` 

<br/>

3、key 为短字符的，使用 `luaH_getshortstr` 查找。   

`luaH_getshortstr` 的实现其实与 `getgeneric` 是差不多的，只不过当了一些判断，可能性能上会高一些。逻辑上只涉及哈希部分的查找。先计算哈希值，如果没命中，就链式查找。   

```c
const TValue *luaH_getshortstr (Table *t, TString *key) {
  Node *n = hashstr(t, key);
  lua_assert(key->tt == LUA_TSHRSTR);
  for (;;) {  /* check whether 'key' is somewhere in the chain */
    const TValue *k = gkey(n);
    if (ttisshrstring(k) && eqshrstr(tsvalue(k), key))
      return gval(n);  /* that's it */
    else {
      int nx = gnext(n);
      if (nx == 0)
        return luaO_nilobject;  /* not found */
      n += nx;
    }
  }
}
```

<br/>

4、其他的，都使用 `getgeneric` 查找。   

`mainposition` 就是计算哈希值。先计算哈希值，如果没命中，就链式查找。   

```c
static const TValue *getgeneric (Table *t, const TValue *key) {
  Node *n = mainposition(t, key);
  for (;;) {  /* check whether 'key' is somewhere in the chain */
    if (luaV_rawequalobj(gkey(n), key))
      return gval(n);  /* that's it */
    else {
      int nx = gnext(n);
      if (nx == 0)
        return luaO_nilobject;  /* not found */
      n += nx;
    }
  }
}
```

---

## 2.4 设置键值

像这样的语句：  

```lua
local t = {}
t[1] = 1
t[2.0] = 2
t["hello"] = 3
```

翻译成字节码是这样：   

```
main <input-file.lua:0,0> (5 instructions at ea4cbe26_3dbe05d0)
0+ params, 2 slots, 1 upvalue, 1 local, 5 constants, 0 functions
function main(...) --line 1 through 4
1	NEWTABLE	0 0 0	
2	SETTABLE	0 -1 -1	; 1 1
3	SETTABLE	0 -2 -3	; 2.0 2
4	SETTABLE	0 -4 -5	; "hello" 3
5	RETURN	0 1	

locals (1)
index	name	startpc	endpc
0	t	2	6

upvalues (1)
index	name	instack	idx	kind
0	_ENV	true	0	VDKREG (regular)

constants (5)
index	type	value
1	number	1
2	number	2
3	number	2
4	string	"hello"
5	number	3
end
```

`SETTABLE` 对应 lvm.c 里面 `OP_SETTABLE` 的处理逻辑:    

```c
      vmcase(OP_SETTABLE) {
        TValue *rb = RKB(i);
        TValue *rc = RKC(i);
        settableProtected(L, ra, rb, rc);
        vmbreak;
      }
```    

而 `settableProtected` 的逻辑是这样的： 

```c
#define settableProtected(L,t,k,v) { const TValue *slot; \
  if (!luaV_fastset(L,t,k,slot,luaH_get,v)) \
    Protect(luaV_finishset(L,t,k,v,slot)); }

#define luaV_fastset(L,t,k,slot,f,v) \
  (!ttistable(t) \
   ? (slot = NULL, 0) \
   : (slot = f(hvalue(t), k), \
     ttisnil(slot) ? 0 \
     : (luaC_barrierback(L, hvalue(t), v), \
        setobj2t(L, cast(TValue *,slot), v), \
        1)))        
```

<br/>

`settableProtected` 的行为：  

1、尝试 `luaV_fastset`，如果 `luaH_get` 能获得到一个有效位置，那么就直接 `setobj2t` 即可。`luaH_get` 在以下情况能获得到一个有效位置：   
    1）key 是正数且在数组部分范围内；   
    2）哈希部分已经存在这样一个 key。     

2、如果 `luaV_fastset` 失败，就执行 `luaV_finishset`，`luaV_finishset` 涉及到一些元表操作，比较复杂。大体逻辑是：  
    1）通过 `luaH_newkey` 在哈希数组上寻找到一个合适的位置；   
    2）使用 `setobj2t` 给这个位置赋上 value。  

<br/>

`luaH_newkey` 的行为：   

检查 key 的 main position 是否空的      
1. 非空，检查冲突节点的 main position 是否就是这里：    
    1.1 不是：把冲突节点移到一个空闲位置；把自己设置进此 main position。   
    1.2 是：把自己链接到此 main position 之下。         
2. 空的，把自己设置进此 main position。  

<br/>

理解 `luaH_newkey` 行为的关键在于上面讲过的，哈希部分是把所有节点都放到一个数组里的，包括冲突的节点，冲突的节点就是临时找一个空闲位置放，然后用 next 字段连接起来。如果以后这个空闲位置的真正主人找过来了，就再挪一挪。    

`luaH_newkey` 的代码虽然很长，但挺巧妙的，贴一下：   

```c
/*
** inserts a new key into a hash table; first, check whether key's main
** position is free. If not, check whether colliding node is in its main
** position or not: if it is not, move colliding node to an empty place and
** put new key in its main position; otherwise (colliding node is in its main
** position), new key goes to an empty position.
*/
TValue *luaH_newkey (lua_State *L, Table *t, const TValue *key) {
  Node *mp;
  TValue aux;
  if (ttisnil(key)) luaG_runerror(L, "table index is nil");
  else if (ttisfloat(key)) {
    lua_Integer k;
    if (luaV_tointeger(key, &k, 0)) {  /* does index fit in an integer? */
      setivalue(&aux, k);
      key = &aux;  /* insert it as an integer */
    }
    else if (luai_numisnan(fltvalue(key)))
      luaG_runerror(L, "table index is NaN");
  }
  mp = mainposition(t, key);
  if (!ttisnil(gval(mp)) || isdummy(t)) {  /* main position is taken? */
    Node *othern;
    Node *f = getfreepos(t);  /* get a free place */
    if (f == NULL) {  /* cannot find a free place? */
      rehash(L, t, key);  /* grow table */
      /* whatever called 'newkey' takes care of TM cache */
      return luaH_set(L, t, key);  /* insert key into grown table */
    }
    lua_assert(!isdummy(t));
    othern = mainposition(t, gkey(mp));
    if (othern != mp) {  /* is colliding node out of its main position? */
      /* yes; move colliding node into free position */
      // 通过链式查找，找到此冲突节点的上一级，再改变这个上一级的 next 域，修正为 f - othern
      while (othern + gnext(othern) != mp)  /* find previous */
        othern += gnext(othern);
      gnext(othern) = cast_int(f - othern);  /* rechain to point to 'f' */
      *f = *mp;  /* copy colliding node into free pos. (mp->next also goes) */
      if (gnext(mp) != 0) {
        gnext(f) += cast_int(mp - f);  /* correct 'next' */
        gnext(mp) = 0;  /* now 'mp' is free */
      }
      setnilvalue(gval(mp));
    }
    else {  /* colliding node is in its own main position */
      /* new node will go into free position */
      // 此处相当于自己把自己插入到 main position 之下
      // 原来： main position -> colliding1 -> colliding2 -> collidingx
      // 变成： main position -> me -> colliding1 -> colliding2 -> collidingx
      if (gnext(mp) != 0)
        gnext(f) = cast_int((mp + gnext(mp)) - f);  /* chain new position */
      else lua_assert(gnext(f) == 0);
      gnext(mp) = cast_int(f - mp);
      mp = f;
    }
  }
  setnodekey(L, &mp->i_key, key);
  luaC_barrierback(L, t, key);
  lua_assert(ttisnil(gval(mp)));
  return gval(mp);
}
```

---

## 2.5 table 初始化

像这样初始化一个 table:    

```lua
local t = {1,2}
```

它产生的字节码是:   

```
function main(...) --line 1 through 1
1	NEWTABLE	0 2 0	
2	LOADK	1 -1	; 1
3	LOADK	2 -2	; 2
4	SETLIST	0 2 1	; 1
5	RETURN	0 1	

locals (1)
index	name	startpc	endpc
0	t	5	6

upvalues (1)
index	name	instack	idx	kind
0	_ENV	true	0	VDKREG (regular)

constants (2)
index	type	value
1	number	1
2	number	2
end
```

通过 `SETLIST` 往这个 table 插入 1, 2 这两个元素，它对应的是 `lvm.c` 里面 `OP_SETLIST` 的逻辑，代码比较长，就不罗列了。它内部会调用 table 暴露的接口 `luaH_resizearray` 把 table 的数组部分扩张到足够大的容量，之后再调用 `luaH_setint` 往 table 里面设置数据。   

`luaH_setint` 的处理逻辑是：   
1、先尝试从数组部分找一个位置，找得到就设置值；   
2、找不到就通过 `luaH_newkey` 去哈希部分找一个位置，再设置值。    

当然，`OP_SETLIST` 会先扩张数组部分的容量，所以这种情况下 `luaH_setint` 可以把值都设置到数组部分。   

```c
void luaH_resizearray (lua_State *L, Table *t, unsigned int nasize) {
  int nsize = allocsizenode(t);
  luaH_resize(L, t, nasize, nsize);
}

void luaH_setint (lua_State *L, Table *t, lua_Integer key, TValue *value) {
  const TValue *p = luaH_getint(t, key);
  TValue *cell;
  if (p != luaO_nilobject)
    cell = cast(TValue *, p);
  else {
    TValue k;
    setivalue(&k, key);
    cell = luaH_newkey(L, t, &k);
  }
  setobj2t(L, cell, value);
}

```

<br/>

如果以这样的方式初始化 table:  

```lua
local t = {1,2, ["hello"]="world"}
```

则字节码是这样的：  

```
function main(...) --line 1 through 1
1	NEWTABLE	0 2 1	
2	LOADK	1 -1	; 1
3	LOADK	2 -2	; 2
4	SETTABLE	0 -3 -4	; "hello" "world"
5	SETLIST	0 2 1	; 1
6	RETURN	0 1	
end

// 以下省略 ...
```

与上面的相比，只是多了 `SETTABLE` 来设置 "hello" "world" 这一对键值，而 `SETTABLE` 在上一小节已经分析过了，就不赘述了。   

---

## 2.6 遍历

关于遍历：  

1、遍历使用的函数是 `luaH_next`，它需要传入 table 和 key 作为参数。逻辑是：    
    1）通过 `findindex` 计算出此 key 对应的索引值 i。   
    2）尝试在数组部分递增索引值以寻找下一个非空的 key，找到则返回；否则在哈希部分递增索引值，则到寻找到下一个非空的 key。   

2、`findindex` 的逻辑:  
    1）如果 key 是 nil，返回 0。  
    2）如果 key （经过转换）是正整数，且在数组部分范围内，则返回 key 对应的正整数值。   
    3）不是以上两种，则计算出 key 对应于哈希部分的位置 i，返回 `i+1+sizearray` (只是一种技巧，让 `luaH_next` 先遍历数组再遍历哈希)   


<br/>

lua 的 `pairs` 函数，调用的是 `luaB_next`，最终会调用到 `luaH_next`。`pairs` 一般与 `for` 一起工作：第一次调用时，传入 table 和一个空 key，返回一对非空的 key value；第二次调用时，传入的就是 table 和上次返回的 key 了；依此类推。    

而 table 和 key 刚好就是 luah_next 需要的参数。   

<br/>

`luaH_next` 和 `findindex` 的代码如下：  

```c
int luaH_next (lua_State *L, Table *t, StkId key) {
  unsigned int i = findindex(L, t, key);  /* find original element */
  for (; i < t->sizearray; i++) {  /* try first array part */
    if (!ttisnil(&t->array[i])) {  /* a non-nil value? */
      setivalue(key, i + 1);
      setobj2s(L, key+1, &t->array[i]);
      return 1;
    }
  }
  for (i -= t->sizearray; cast_int(i) < sizenode(t); i++) {  /* hash part */
    if (!ttisnil(gval(gnode(t, i)))) {  /* a non-nil value? */
      setobj2s(L, key, gkey(gnode(t, i)));
      setobj2s(L, key+1, gval(gnode(t, i)));
      return 1;
    }
  }
  return 0;  /* no more elements */
}

/*
** returns the index of a 'key' for table traversals. First goes all
** elements in the array part, then elements in the hash part. The
** beginning of a traversal is signaled by 0.
*/
static unsigned int findindex (lua_State *L, Table *t, StkId key) {
  unsigned int i;
  if (ttisnil(key)) return 0;  /* first iteration */
  i = arrayindex(key);
  if (i != 0 && i <= t->sizearray)  /* is 'key' inside array part? */
    return i;  /* yes; that's the index */
  else {
    int nx;
    Node *n = mainposition(t, key);
    for (;;) {  /* check whether 'key' is somewhere in the chain */
      /* key may be dead already, but it is ok to use it in 'next' */
      if (luaV_rawequalobj(gkey(n), key) ||
            (ttisdeadkey(gkey(n)) && iscollectable(key) &&
             deadvalue(gkey(n)) == gcvalue(key))) {
        i = cast_int(n - gnode(t, 0));  /* key index in hash table */
        /* hash elements are numbered after array ones */
        return (i + 1) + t->sizearray;
      }
      nx = gnext(n);
      if (nx == 0)
        luaG_runerror(L, "invalid key to 'next'");  /* key not found */
      else n += nx;
    }
  }
}
```

---

## 2.7 rehash    

**一、rehash 的时机**         

`luaH_newkey` 时，找不到空闲位置来创建新 key 时，就会执行 `rehash`，对存储空间进行扩容。扩容时，申请新内存，然后把旧数据拷贝过去。   

所以，只有 table 空间不够用了才会 rehash。那么，即使有很多元素设置为 nil，占用的存储变小了很多，也不会触发 “缩容”。  

<br/>

**二、rehash 的算法**      

rehash 的逻辑：   

1、统计数组部分跟哈希部分的键值分布情况。   
2、根据分布情况执行扩容策略：申请数组部分和哈希部分的内存。   
3、把旧数据拷贝到新内存中。   

<br/>

最核心的逻辑就是统计分布情况，以及根据分布情况做出的扩容策略。   

统计结果：     

* na，所有整数键的个数
* nums，所有整数键的分布情况，`nums[i] = number of keys 'k' where 2^(i - 1) < k <= 2^i`
* totaluse，所有键的个数

`computesizes` 负责计算一个合适的数组容量来存在整数键，一个原则是：此数组部分存放的整数键的数量要超过一半的容量，这样可以确保数组部分不会过于稀疏。而数组部分放不下的整数键，仍然是放到哈希部分那边。     

`luaH_resize` 负责重新分配内存并移动数据，这里面哈希部分的容量计算公式是：`2 ^ ceil(log2(需要放到哈希部分的键个数))`，举个例子，如果是 8 个，则算出来仍是 8，如果是 6，则算出来也是 8。   


```c
/*
** nums[i] = number of keys 'k' where 2^(i - 1) < k <= 2^i
*/
static void rehash (lua_State *L, Table *t, const TValue *ek) {
  unsigned int asize;  /* optimal size for array part */
  unsigned int na;  /* number of keys in the array part */
  unsigned int nums[MAXABITS + 1];
  int i;
  int totaluse;
  for (i = 0; i <= MAXABITS; i++) nums[i] = 0;  /* reset counts */
  na = numusearray(t, nums);  /* count keys in array part */
  totaluse = na;  /* all those keys are integer keys */
  totaluse += numusehash(t, nums, &na);  /* count keys in hash part */
  /* count extra key */
  na += countint(ek, nums);
  totaluse++;
  /* compute new size for array part */
  asize = computesizes(nums, &na);
  /* resize the table to new computed sizes */
  luaH_resize(L, t, asize, totaluse - na);
}
```

---

# 3. 拓展阅读

[《深入Lua：Table的实现 - 知乎》](https://zhuanlan.zhihu.com/p/97830462)     

[《Lua设计与实现--Table篇 - 知乎》](https://zhuanlan.zhihu.com/p/87400150)    

---

# 4. 参考


[1] lua.org. The Length Operator. Available at https://lua.org/manual/5.3/manual.html#3.4.7.     