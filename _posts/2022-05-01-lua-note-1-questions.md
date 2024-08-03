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

lua 官方 manual 关于 pairs 的描述：   

>If t has a metamethod __pairs, calls it with t as argument and returns the first three results from the call.     

>Otherwise, returns three values: the next function, the table t, and nil, so that the construction     

>    for k,v in pairs(t) do body end    

>will iterate over all key–value pairs of table t.    
 
<br/>   

`pairs` 对应的 api 是 `luaB_pairs`，它要求传入一个 table 类型的参数 t，逻辑如下：    

1）如果 t 的元表包括 `__pairs` 元方法，则调用此元方法，元方法同样要求返回三个值。        
2）否则，返回的是三个值：next 函数（`luaB_next`），t，nil。     

<br/>   

在 for 循环中调用 pairs 的工作过程大致如下：  

假设 t 是 table，以 pairs(t) 调用的时候，返回了 next, t, nil。之后的过程：  

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



---

## 1.3 for 的底层实现

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

