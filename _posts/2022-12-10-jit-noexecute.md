---
layout: post
title:  "jit 与 nx 技术"
date:   2022-12-10
last_modified_at: 2022-12-10
categories: [lang]
tags: [performance, jit]
---

* 目录  
{:toc}

<br>
---

# 概述
jit 技术是通过将一部分热点的字节码编译成机器码存放于一个被称为 codecache 的内存区域，执行的时候直接跳到这块区域上相对应的指令处。但内核为了安全，大都结合 cpu 的 nx 技术 (no execute) 来禁止执行栈上的指令。那有没有一些内核更进一步，不允许执行程序自己申请出来的内存区域上的代码呢？还真的有，比如 ios，这篇文章就讲了 [用好lua+unity，让性能飞起来——luajit集成篇/平台相关篇](https://www.cnblogs.com/zwywilliam/p/5999980.html)。





<br><br><br><br>

# 参考
* 《深入理解计算机系统（原书第3版）》<https://book.douban.com/subject/26912767/>
* Linux中的保护机制：<https://www.cnblogs.com/ncu-flyingfox/p/11223390.html>
*  用好lua+unity，让性能飞起来——luajit集成篇/平台相关篇： <https://www.cnblogs.com/zwywilliam/p/5999980.html>
*  Java即时编译器原理解析及实践：<https://tech.meituan.com/2020/10/22/java-jit-practice-in-meituan.html>


<br>
<br>
<br>
<br>
<br>