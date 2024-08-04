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

假设 t 是 table，在 for 循环中调用 `ipairs(t)` 的工作过程大致如下：      
1）调用 pairs(t) 返回 next, t, 0；      
2）调用 next 进行迭代，直到返回空的 key；     
```
k1, v1 = next(t, 0)   
k2, v2 = next(t, k1)    
...
直到 kn 为 nil。   
```

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

## 1.3 for statement 的两种模式

lua manual 关于 for statement 的描述[3]：   

>The for statement has two forms: one numerical and one generic.

The numerical for loop repeats a block of code while a control variable runs through an arithmetic progression. It has the following syntax:

	stat ::= for Name ‘=’ exp ‘,’ exp [‘,’ exp] do block end
The block is repeated for name starting at the value of the first exp, until it passes the second exp by steps of the third exp. More precisely, a for statement like

     for v = e1, e2, e3 do block end
is equivalent to the code:

     do
       local var, limit, step = tonumber(e1), tonumber(e2), tonumber(e3)
       if not (var and limit and step) then error() end
       var = var - step
       while true do
         var = var + step
         if (step >= 0 and var > limit) or (step < 0 and var < limit) then
           break
         end
         local v = var
         block
       end
     end
Note the following:

All three control expressions are evaluated only once, before the loop starts. They must all result in numbers.
var, limit, and step are invisible variables. The names shown here are for explanatory purposes only.
If the third expression (the step) is absent, then a step of 1 is used.
You can use break and goto to exit a for loop.
The loop variable v is local to the loop body. If you need its value after the loop, assign it to another variable before exiting the loop.
The generic for statement works over functions, called iterators. On each iteration, the iterator function is called to produce a new value, stopping when this new value is nil. The generic for loop has the following syntax:

	stat ::= for namelist in explist do block end
	namelist ::= Name {‘,’ Name}
A for statement like

     for var_1, ···, var_n in explist do block end
is equivalent to the code:

     do
       local f, s, var = explist
       while true do
         local var_1, ···, var_n = f(s, var)
         if var_1 == nil then break end
         var = var_1
         block
       end
     end
Note the following:

explist is evaluated only once. Its results are an iterator function, a state, and an initial value for the first iterator variable.
f, s, and var are invisible variables. The names are here for explanatory purposes only.
You can use break to exit a for loop.
The loop variables var_i are local to the loop; you cannot use their values after the for ends. If you need these values, then assign them to other variables before breaking or exiting the loop.

---

# 2. 参考

[1] lua.org. pairs (t). Available at https://lua.org/manual/5.3/manual.html#pdf-pairs.   

[2] lua.org. ipairs (t). Available at https://lua.org/manual/5.3/manual.html#pdf-ipairs.   