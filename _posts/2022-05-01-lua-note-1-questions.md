---
layout: post
title: "lua 笔记一：常识、用法"
date: 2022-05-01
last_modified_at: 2022-05-01
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>

**持续更新**   

记录 lua 相关的常识，以及使用过程中遇到的问题。    

---

# 1. 常识

--- 

## 1.1 lua table 

以下分析使用 lua-5.3.6。   

---

### 1.1.1 table 的基本信息

1、包含了数组和哈希表两部分。    

2、可支持两大功能：容器，面向对象（通过 metatable）。   

---
 
### 1.1.2 table 的底层实现

---

#### 1.1.2.1 数据结构

关于 Table 如何存储的，如何解决哈希冲突的，都在下面的代码注释中写明了。  

table 相关的结构体在 lobject.h 中定义。  

```c

// 注意，key 是一个 union 类型的
typedef union TKey {
  struct {
    TValuefields;
    int next;  // nk 与 tvk 相比，只是多了一个 next 字段，此字段用于哈希冲突时，计算冲突节点的所在位置。
               // lua 也是用开链表来解决哈希冲突，但并不是额外创建新的链表来存储冲突的节点，而是把
               // 所有节点都存储在哈希数组上。冲突时就在哈希数组上找一个空闲的位置存放冲突节点，
               // next 实际上就是哈希数组上相对于当前节点的偏移值，要注意，是偏移值，而不是实际下标。  
  } nk;
  TValue tvk;
} TKey;

typedef struct Node {
  TValue i_val;
  TKey i_key;
} Node;

typedef struct Table {
  CommonHeader;
  lu_byte flags;  /* 1<<p means tagmethod(p) is not present */
  lu_byte lsizenode;  // 哈希部分的长度为 2 的 lsizenode
  unsigned int sizearray;  // 数组部分的长度
  TValue *array;  // 数组部分，实际上就是一个类型为 TValue*，长度为 sizearray 的 c 数组
  Node *node;     // 哈希部分，实际上就是一个类型为 Node*，长度为 2 的 lsizenode 次方的 c 数组
  Node *lastfree;  // 哈希部分空闲位置的指针，在此之前的才是空闲的，寻找时从此往前找
  struct Table *metatable;
  GCObject *gclist;
} Table;
``` 

---

#### 1.1.2.2 新建表  

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

#### 1.1.2.3 查询

主要执行查询的是 `ltable.c` 里面 `luaH_get` 函数，根据 key 的类型，使用对应的函数进行查询。   

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

1、key 为 nil 的，直接返回空对象。    

<br/>

2、key 为整型或可转为整型的浮点型的，使用 `luaH_getint` 查找。   

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

`luaH_getint` 涉及两部分的查找，如果 key 在 sizearray 范围内，则返回数组部分的。否则，通过 `hashint` 取得 key 的哈希值，从哈希部分查找。上文讲数据结构的时候已经说过，哈希部分是把所有的 node 都放到哈希数组里的，所以在哈希部分查找时，就是先定位到一个位置，如果 key 不相同，就“链式”查找，`n += nx`，此处的 nx 是偏移量。   

<br/>

3、key 为短字符的，使用 `luaH_getshortstr` 查找。   

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

`luaH_getshortstr` 的实现其实与 `getgeneric` 是差不多的，只不过当了一些判断，可能性能上会高一些。  

逻辑上只涉及哈希部分的查找。先计算哈希值，如果没命中，就链式查找。   

<br/>

4、其他的，都使用 `getgeneric` 查找。  

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

`mainposition` 就是计算哈希值。先计算哈希值，如果没命中，就链式查找。   

---

#### 1.1.2.4 设置或新增键值

像这样的语句：  

```lua
local t = {}
t[1] = 1
t[2.0] = 2
t["hello"] = 3
```

翻译成字节码 ( 使用 [https://www.luac.nl/](https://www.luac.nl/) ) 是这样：   

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

`settableProtected` 的逻辑是这样的： 

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

`luaV_fastset` 就是先尝试 `luaH_get`，如果数组部分存在这样一个位置（key 值是正数且在数组部分的范围内），或者哈希部分已经有这个 key 了，那么就直接 `setobj2t` 即可。否则，就需要在哈希部分创建一个新 key 出来存储，这也就是 `luaV_finishset` 的逻辑。   

`luaV_finishset` 涉及到一些元表操作，比较复杂，简单来说就是通过 `luaH_newkey` 插入一个新 key，然后 `setobj2t` 给这个位置赋上 value。  

所以，重点逻辑就是看 `luaH_newkey`。  



---

#### 1.1.2.5 遍历

1、遍历使用的函数是 `luaH_next`，整体逻辑是先从头到尾遍历数组部分，之后再遍历哈希部分，`luaH_next` 需要传入一个 key 值，然后计算出下一个 key 和 value。  

这其实就是跟 pairs 相关的，第一次调用 pairs 时，传入的是 table 和一个空的 key 值，即 `k1, v1 = pairs(t, nil)`，第二次就是 `k2, v2 = pairs(t, k1)`，依此类推。 pairs 调用的是 `luaB_next`，最终会调用到 `luaH_next`。   

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
```

2、实际上，最关键的逻辑在 `findindex` 里面。  

```c
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

#### 1.1.2.6 rehash    

1、rehash 的时机    

`luaH_newkey` 时，找不到空闲的位置来创建新 key 时，就会执行 rehash，对表执行扩容操作。扩容的时候，需要申请新的内存，然后把原有的数据都拷贝过去。   

下面的代码展示了 rehash 被执行的时机，取自 ltable.c 。  

```c
TValue *luaH_newkey (lua_State *L, Table *t, const TValue *key) {
  ...
  if (!ttisnil(gval(mp)) || isdummy(t)) {  /* main position is taken? */
    Node *othern;
    Node *f = getfreepos(t);  /* get a free place */
    if (f == NULL) {  /* cannot find a free place? */
      rehash(L, t, key);  /* grow table */
      /* whatever called 'newkey' takes care of TM cache */
      return luaH_set(L, t, key);  /* insert key into grown table */
    }
    ...
}
```

以上可以看出，table 除非空间不够用了，否则不会触发 rehash，所以即使很多元素设置为 nil，也不会触发 “缩容”。

<br/>

2、rehash 的算法  





---

### 1.1.3 table 的拓展阅读

[《深入Lua：Table的实现 - 知乎》](https://zhuanlan.zhihu.com/p/97830462)     

[《Lua设计与实现--Table篇 - 知乎》](https://zhuanlan.zhihu.com/p/87400150)    


---

## 1.2 lua table 取长度的问题

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

在源码（lua5.3.6）中，是通过 ltable.c 的 luaH_getn 函数获取 table 的长度的。  

---

## 1.3 lua pairs / ipairs 的底层实现


---

## 1.4 lua for 的底层实现

---

## 1.5 lua for 循环的目标计算

1、对于这样的，只计算一次。      

```lua
local x = {1,2,3,4}
for i = 1, #x do
    x[2] = nil
    x[3] = nil
    x[4] = nil
    print(x[i])
end
```

输出：   

```
1
nil
nil
nil
```

2、对于这样的，则是动态计算的。    

```lua
local x = {1,2,3,4}
for k, v in ipairs(x) do
    x[2] = nil
    x[3] = nil
    x[4] = nil
    print(k, v)
end
```

输出： 

```
1    1
```

---

# 2. 参考

[1] lua.org. The Length Operator. Available at https://lua.org/manual/5.3/manual.html#3.4.7.     