---
layout: post
title: "lua vm 五: upvalue"
date: 2024-04-12
last_modified_at: 2024-04-10
categories: [lua]
tags: [lua]
---

* 目录  
{:toc}
<br/>

lua vm 运行过程中，upvalue 是一个重要的数据结构。   

upvalue 以一种高效的方式实现了词法作用域，使得函数能成为 lua 中的第一类值；而其高效也导致在实现上有点复杂。   


# 1. upvalue

---

## 1.1 upvalue 要解决的问题

upvalue 就是外部函数的局部变量，比如下面的函数定义中，base 就是 inner 这个函数的一个 upvalue。  

```lua
local function getf(delta)
    local base = 100
    local function inner()
        return base+delta
    end
    return inner
end

local f1 = getf(10)
```

upvalue 复杂的地方在于，在离开了 upvalue 的作用域之后，还要能够访问得到。比如上面调用了 `local f1 = getf(10)` ，getf 返回后它的栈空间已经被抹掉了，但 inner 还要能访问 base 这个变量，所以需要想办法把它捕捉下来。  

---

## 1.2 upvalue 的实现


---

# 2. 参考