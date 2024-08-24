---
layout: post
title: "游戏中的设计模式一"
date: 2024-01-05
last_modified_at: 2024-01-05
categories: [设计模式]
tags: [设计模式]
---

* 目录  
{:toc}
<br/>

游戏开发是一个快速迭代的过程，代码复杂度也很高，借助于设计模式，可以帮助我们降低复杂度，降低系统间的耦合，从而高效高质的做出交付。  

最近读了这本书：《游戏编程模式》[1]，很受启发，所以结合书本知识以及自己的理解，写一写游戏中常用的设计模式。   

---

# 1. 模式

---

## 1.1 单例模式

先说要点：这是唯一一个不推荐使用的模式，因为它害处多于好处。  

尽管这个模式出现在了 GoF 的书[2]中，但是它弊大于利，并不是一个好的模式。因为它制造了全局变量，而全局变量是有害的。不推荐全局变量的理由也差不多构成了不推荐单例模式的理由。  

CppCoreGuidelines[7] 也提到了避免使用单例模式，并指出 Reason 是 "Singletons are basically complicated global objects in disguise"，翻译过来就是：单例本质上就是一些复杂的全局对象。  

全局变量会导致这几件事情变得很困难：可测试性、重构、优化、并发。     

除了全局变量的原因，在游戏中，还有一个特别的点：游戏对延迟是很敏感的，而单例支持 “延迟初始化”，这反而可能带来卡顿，对游戏是不利的，所以游戏基本上不需要延迟初始化，反而是在一开始就把一些初始化耗时高的模块都先初始化了。  

既然不推荐单例，但有些时候也不得不使用全局变量，怎么办？  

没办法，该用全局变量的地方还继续用着吧。但是，尽量通过一些办法减少全局变量的数量。比如游戏客户端中，往往不得不定义一个全局变量 world 来表示整个游戏世界的，这个全局变量会被用得到处是，基于这一基本现实，我们可以把一些其他的需要全局访问的变量也放在这个 world 变量里。   

---

## 1.2 状态机模式

状态机出现很频繁，游戏里面的 AI 大多都是用状态机实现的，计算机网络中的 TCP 协议，其实现也是典型的状态机。  

以前我觉得状态机平平无奇，没有什么特别的。直到看到《游戏编程模式》[1]里介绍的例子，才惊觉状态机模式真是神奇，化繁为简，使一切变得很有秩序。  

如果不使用状态机，要根据输入控制一个英雄的行为，可能会写出这样复杂的，不好维护的代码：  

```cpp
void Heroine::handleInput(Input input)
{
    if (input == PRESS_B)
    {
        if (! isJumping_ && ! isDucking_)
        {
            // Jump...
        }
    }
    else if (input == PRESS_DOWN)
    {
        if (! isJumping_)
        {
            isDucking_ = true;
            setGraphics(IMAGE_DUCK);
        }
        else
        {
            isJumping_ = false;
            setGraphics(IMAGE_DIVE);
        }
    }
    else if (input == RELEASE_DOWN)
    {
        if (isDucking_)
        {
            // Stand...
        }
    }
}
```

上面的代码，不单复杂难维护，而且还容易出 bug，比如会有很多这类逻辑约束：“主角在跳跃状态的时候不能再跳，但是在俯冲攻击的时候却可以跳跃”，为了实现这类约束，需要加更多的状态变量，更多的判断。  

但是如果引入状态机，一切都将变得简单有序。首先，要先写出一个状态机，之后再把它实现出来。状态机有以下几个特征：  

* 你拥有一组状态，并且可以在这组状态之间进行切换
* 状态机同一时刻只能处于一种状态
* 状态机会接收一组输入或者事件
* 每一个状态有一组转换，每一个转换都关联着一个输入并指向另一个状态


准确的说，我们这里需要的是 DFA（有限自动机），如果是 NFA，肯定会超过我们脑子负载的。有限状态机（FSM）可以分为 DFA 和 NFA[4]：   

>FSM is further distinguished by Deterministic Finite Automata (DFA) and Nondeterministic Finite Automata (NFA). In DFA, for each pair of state and input symbol there is only one transition to a next state whereas, in NFA, there may be several possible next states. Often NFA refers to NFA‐epsilon which allows a transition to a next state without consuming any input symbol. That is, the transition function of NFA is usually defined as T: Q x (ΣU{ε}) → P(Q) where P means power set.Theoretically, DFA and NFA are equivalent as there is an algorithm to transform NFA into DFA.


以上英雄行为的例子画出的状态机如下：  

![gamedesignpattern-hero-state-machine](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/design-pattern-gamedesignpattern-hero-state-machine.png)  
<center>图1：英雄行为状态机</center>

依据状态机，实现的代码如下：    

```cpp
enum State
{
    STATE_STANDING,
    STATE_JUMPING,
    STATE_DUCKING,
    STATE_DIVING
};

void Heroine::handleInput(Input input)
{
    switch (state_)
    {
    case STATE_STANDING:
        if (input == PRESS_B)
        {
            state_ = STATE_JUMPING;
            yVelocity_ = JUMP_VELOCITY;
            setGraphics(IMAGE_JUMP);
        }
        else if (input == PRESS_DOWN)
        {
            state_ = STATE_DUCKING;
            setGraphics(IMAGE_DUCK);
        }
        break;

    case STATE_JUMPING:
        if (input == PRESS_DOWN)
        {
            state_ = STATE_DIVING;
            setGraphics(IMAGE_DIVE);
        }
        break;

    case STATE_DUCKING:
        if (input == RELEASE_DOWN)
        {
            state_ = STATE_STANDING;
            setGraphics(IMAGE_STAND);
        }
        break;
    }
}
```

看起来仍然是普普通通的代码，但是却让一切井井有条。这里面最重要的是我们明确了英雄的状态，确定英雄只能处于某种确定的状态，这让逻辑变得有序。   

---

## 1.3 黑板模式

想不到这也是一种模式吧，unity 里的行为树，就使用了 blackboard 来记录数据。  

它本质上就是一个提供数据共享的 key value store，实现了解耦。但也是有缺点[5]，比如：  

* 读写比较随意，容易造成数据损坏，或子系统竞争。 
* 可能会产生非法的数据。  
* 出问题的时候，如果是多个子系统共用，会比较难调试。  

游戏开发中，行为树通常结合黑板来实现，黑板实现了行为树的节点间“通信”，就是共享数据而已。  

黑板模式在《设计模式: 可复用面向对象软件的基础》[2] 和《游戏编程模式》[1] 都没有介绍，但在《面向模式的软件架构卷1模式系统》[6] 有详细介绍，具体可以看一下。   

---

## 1.4 观察者模式

GOF 对它意图的定义是： “定义对象间的一种一对多的依赖关系，当一个对象的状态发生状态时，所有依赖于它的对象都得到通知并被自动更新”[2]。  

在游戏中太常见了，对于解耦有特别大的帮助。比如成就系统，如果不使用观察者模式，那么几乎所有的子系统都要直接调用成就系统，这样一来对于业务的侵入性太强了。  

通常的实现是这样的：  

```cpp

// 事件
class Event {
    EventType t;
};

// 观察者基类
class Observer {
public:
    void onNotify(Event e);
};

// 被观察者基类
class Subject {
public:
    void addObserver(Observer* o);
    void removeObserver(Observer* o);
protected:
    void notify(EventType et);
};

```

观察者模式的基本实现：   
1. 观察者继承 Observer 类，被观察者继承 Subject 类。   
2. Subject 类内部会维护一个观察者列表，在事情发生的时候 notify，会直接遍历观察者列表，调用它们的 onNotify 函数。  
3. 通常来说，是一种同步的实现，即被观察者是直接调用观察者的函数的。    


需要注意的是，观察者模式跟发布订阅模式是有区别的，虽然它们的思路相似，但也有明显的不同：  
1. 观察者模式中观察者跟被观察者是互相知道彼此存在的；而发布订阅模式中订阅者跟发布者往往是不知道对方存在的，它们通过一个 broker 来通讯。  
2. 观察者模式往往是一对多的，而发布订阅可以是一对多，也可以是多对多。  
3. 观察者模式往往是同步调用，而发布订阅是异步调用。  

直接看图比较容易知道它们的区别。  

观察者模式：  

![observer-pattern](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/design-pattern-observer-pattern.png)  
<center>图2：观察者模式</center>

发布订阅模式：   

![publish-subscribe-pattern](https://antsmallant-blog-1251470010.cos.ap-guangzhou.myqcloud.com/media/blog/design-pattern-publish-subscribe-pattern.png)  
<center>图3：发布订阅模式[8]</center>


---

# 2. 参考
[1] [美]Robert Nystrom. 游戏编程模式[M]. GPP翻译组. 北京: 人民邮电出版社, 2016-09-01: 61, 125.   

[2] [美]Erich Gramma, Richard Helm, Ralph Johnson, John Vlissides. 设计模式: 可复用面向对象软件的基础[M]. 李英军, 马晓星, 蔡敏, 刘建中, 等. 北京: 机械工业出版社, 2010(1)：194.     

[3] kevinan. 暴雪Tim Ford：《守望先锋》架构设计与网络同步. Available at https://www.sohu.com/a/148848770_466876, 2017-6.        

[4] N.R. Satish. Finite State Machine. Available at https://patterns.eecs.berkeley.edu/?page_id=470.   

[5] KillerAery. 游戏设计模式：黑板模式. Available at https://www.cnblogs.com/KillerAery/p/10054558.html, 2019-01-17.    

[6] [德]Frank Buschmann, Regine Meunier, Hans Rohnert, et al. 面向模式的软件架构卷1模式系统. 袁国忠. 北京: 人民邮件出版社, 2013.11: 46.   

[7] Bjarne Stroustrup, Herb Sutter. CppCoreGuidelines. Available at https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines#Ri-singleton.   

[8] Microsoft. Publisher-Subscriber pattern. Available at https://learn.microsoft.com/en-us/azure/architecture/patterns/publisher-subscriber.  