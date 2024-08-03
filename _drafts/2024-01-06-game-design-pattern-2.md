---
layout: post
title: "游戏中的设计模式二"
date: 2024-01-06
last_modified_at: 2024-01-06
categories: [设计模式]
tags: [设计模式]
---

* 目录  
{:toc}
<br/>


本文继续讲游戏编程中使用到的设计模式。  

# 模式

---

## ECS
是否推荐：看情况。  

自从守望先锋的在 GDC2017 的分享[3]出来之后，ECS 又再次火了。简单的讲，ECS 就是一种把行为与状态分离的模式，对于守望先锋来说，它的好处在于。  

ECS 是这三个单词的缩写：Entity, Component, System，典型的结构是这样的[3]：  

---

## 更新方法模式

“通过对所有对象实例同时进行帧更新来模拟一系列相互独立的游戏对象。”[1]

这个再平常不过了，主游戏循环里的 update 函数，各个系统里的 update 函数，就是用了这种【更新方法】模式。  

---

# todo
* 展开说一下服务定位器
* AOP 的实例
* lua 相关的设计模式
* 云风关于 lua 设计模式的表述
* 状态模式要补充说明一下具体的实现
* 结合[6]详细说一下黑板模式，以及它属于架构模式

---

# 拓展阅读
* 《游戏编程模式》[1]是一本很好的书，在微信读书有，也可以用这个免费的在线版本( https://gpp.tkchu.me/observer.html )。  
比 GoF 的那本书更有阅读价值，因为此书会先展现代码是如何随着逻辑增多变得复杂而丑陋的，然后再展现通过引入合适的设计模式让逻辑变得有序而漂亮，这样一来你会很直观的感受到设计模式的优雅。     

---

# 总结

* 设计模式并不能简单的套用，使用者需要充分理解自己的需要，做出正确的选择。  
* ECS 虽然看起来解决了守望先锋的很多问题，但是否用到自己的项目中，还得量力而行。  


---

# 参考
[1] [美]Robert Nystrom. 游戏编程模式[M]. GPP翻译组. 北京: 人民邮电出版社, 2016-09-01: 61, 125.   

[2] [美]Erich Gramma, Richard Helm, Ralph Johnson, John Vlissides. 设计模式: 可复用面向对象软件的基础[M]. 李英军, 马晓星, 蔡敏, 刘建中, 等. 北京: 机械工业出版社, 2010(1)：194.     

[3] kevinan. 暴雪Tim Ford：《守望先锋》架构设计与网络同步. Available at https://www.sohu.com/a/148848770_466876, 2017-6.        

[4] N.R. Satish. Finite State Machine. Available at https://patterns.eecs.berkeley.edu/?page_id=470.   

[5] KillerAery. 游戏设计模式：黑板模式. Available at https://www.cnblogs.com/KillerAery/p/10054558.html, 2019-01-17.    

[6] [德]Frank Buschmann, Regine Meunier, Hans Rohnert, et al. 面向模式的软件架构卷1模式系统. 袁国忠. 北京: 人民邮件出版社, 2013.11: 46.   