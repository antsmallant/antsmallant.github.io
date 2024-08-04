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


## 1.1 pairs 的底层实现 

lua manual 关于 pairs 的描述[1] ：   

>If t has a metamethod __pairs, calls it with t as argument and returns the first three results from the call.     
>          
>Otherwise, returns three values: the next function, the table t, and nil, so that the construction     
>     
>     for k,v in pairs(t) do body end     
>    
>will iterate over all key–value pairs of table t.       
 
<br/>   

`pairs` 对应的 api 是 `luaB_pairs`，它要求传入一个 table 类型的参数 t，逻辑如下：    
1）如果 t 的元表包括 `__pairs` 元方法，则调用此元方法，元方法同样要求返回三个值。        
2）否则，返回的是三个值：next 函数（`luaB_next`），t，nil。     

<br/>   

假设 t 是 table，在 for 循环中调用 pairs(t) 的工作过程大致如下：      
1）调用 pairs(t) 返回 next, t, nil；      
2）调用 next 进行迭代，直到返回空的 key；     
```
k1, v1 = next(t, nil)   
k2, v2 = next(t, k1)    
...
直到 kn 为 nil。   
```

<br/>

`luaB_pairs` 的源码：  

```c
static int luaB_pairs (lua_State *L) {
  return pairsmeta(L, "__pairs", 0, luaB_next);
}

static int pairsmeta (lua_State *L, const char *method, int iszero,
                      lua_CFunction iter) {
  luaL_checkany(L, 1);
  if (luaL_getmetafield(L, 1, method) == LUA_TNIL) {  /* no metamethod? */
    lua_pushcfunction(L, iter);  /* will return generator, */
    lua_pushvalue(L, 1);  /* state, */
    if (iszero) lua_pushinteger(L, 0);  /* and initial value */
    else lua_pushnil(L);
  }
  else {
    lua_pushvalue(L, 1);  /* argument 'self' to metamethod */
    lua_call(L, 1, 3);  /* get 3 values from metamethod */
  }
  return 3;
}
```

---

## 1.2 ipairs 的底层实现

lua manual 关于 ipairs 的描述 [2]：   

>Returns three values (an iterator function, the table t, and 0) so that the construction      
>    
>     for i,v in ipairs(t) do body end
>    
>will iterate over the key–value pairs (1,t[1]), (2,t[2]), ..., up to the first nil value.     

<br/>

与 pairs 不同，1）ipairs 没有对应的元方法 `__ipairs`；2）ipairs 只遍历正整数键，从 1 开始遍历，直到遇到第一个 nil 键。  

与 pairs 相似的，ipairs 也是返回三个值：next, t, 0。它对应的 api 是 `luaB_ipairs`，它的 next 函数对应的是 `ipairsaux`。   

<br/>

for 循环下 ipairs 的工作过程与 pairs 类似。  

<br/>

`luaB_ipairs` 的源码：  

```c
static int ipairsaux (lua_State *L) {
  lua_Integer i = luaL_checkinteger(L, 2) + 1;
  lua_pushinteger(L, i);
  return (lua_geti(L, 1, i) == LUA_TNIL) ? 1 : 2;
}

static int luaB_ipairs (lua_State *L) {
#if defined(LUA_COMPAT_IPAIRS)
  return pairsmeta(L, "__ipairs", 1, ipairsaux);
#else
  luaL_checkany(L, 1);
  lua_pushcfunction(L, ipairsaux);  /* iteration function */
  lua_pushvalue(L, 1);  /* state */
  lua_pushinteger(L, 0);  /* initial value */
  return 3;
#endif
}
```

---

## 1.3 for 的两种模式

---

## 1.4 for 循环的目标计算

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

[1] lua.org. pairs (t). Available at https://lua.org/manual/5.3/manual.html#pdf-pairs.   

[2] lua.org. ipairs (t). Available at https://lua.org/manual/5.3/manual.html#pdf-ipairs.   