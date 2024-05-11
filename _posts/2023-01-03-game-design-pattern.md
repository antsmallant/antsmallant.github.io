---
layout: post
title: "游戏开发之设计模式"
date: 2024-01-05
last_modified_at: 2024-01-05
categories: [游戏开发]
tags: [设计模式]
---

* 目录  
{:toc}
<br/>

游戏开发是一个快速迭代的过程，代码复杂度也很高，借助于设计模式，可以帮助我们降低复杂度，降低系统间的耦合，从而高效高质的做出交付。  

最近读了这本书：《游戏编程模式》[1]，很受启发，所以结合书本知识，以及自己的理解，写一写游戏中常用的设计模式。   

---

# 单例模式
使用频率：五颗星。  
是否推荐：否。    

随便问十个人，最熟悉的设计模式是什么，估计有八个人会脱口而出单例模式。  

尽管这个模式出现在了 GoF 的书中，但是它弊大于利，并不是一个好的模式。因为它制造了全局变量，而全局变量是有害的。  

《游戏编程模式》对此提出了批评[1]：   
* 它是一个全局变量，它们令代码晦涩难懂，全局变量促进了耦合，它对并发不友好。  
* 它是个画蛇添足的解决方案，比如把 Log 类做成单例，当到处都有 log 写入，log 文件变成垃圾场时，我们又需要把 Log 改为多实例的，但此时修改起来已经特别麻烦了。  
* 延迟初始化剥离了你的控制，实际上游戏开发中并不需要延迟初始化，反而是在一开始就做好了初始化，避免运行过程中初始化带来卡顿。  

针对单例模式的两大特性：1）限制全局单一实例；2）便于访问，书中[1]也给出了单例的替代方案：   
* 将类限制为单一实例，可以实现单例模式的单例特性，比如这样： 

```cpp
class FileSystem
{
public:
    FileSystem()
    {
    assert(! instantiated_);
    instantiated_ = true;
    }

    ～FileSystem() { instantiated_ = false; }

private:
    static bool instantiated_;
};

bool FileSystem::instantiated_ = false;
```

* 为实例提供便捷的访问方式，可以实现单例模式便于访问的特性，比如这样：   
    * 把对象作为参数传递进去。
    * 在基类中获取它，比如把 Log 作为基类的内部对象，那么相应的继承类都可以获得访问这个 Log 对象。
    * 通过其他全局对象访问它；这是一种折衷的策略，通过减少全局变量来减少耦合，但也不失为一种好的做法；比如游戏开发中，我们始终会有一个变量来表示整个游戏或整个世界的 world 对象，那么我们可以把那些单例实例都放到这个 world 对象里面，最终我们只通过 world 对象去访问它们。  
    * 通过服务定位器来访问。 

<br/>

对于有静态变量的编译型语言如 C++，实现 “将类限制为单一实例” 是容易的，但是像 lua 这种动态语言，要如何实现这种特性呢？依然没问题的，用 C/C++ 封装后给 lua 使用就行。  

服务定位器是一种设计模式，

考虑一个实际的问题，项目中要如何合理的设计 Log 呢？既然单例不好，具体怎么做才好呢？  


---

# 观察者模式
使用频率：五颗星。  
是否推荐：是。  

GOF 对它意图的定义是： “定义对象间的一种一对多的依赖关系，当一个对象的状态发生状态时，所有依赖于它的对象都得到通知并被自动更新”[2]。  

---

# 状态机模式
使用频率：五颗星。  
是否推荐：是。  

状态机出现很频繁，游戏里面的 AI 大多都是用状态机实现的，计算机网络中的 TCP 协议，其实现也是典型的状态机。  

以前我觉得状态机平平无奇，没有什么特别的。直到看到这本书[1]里介绍的例子，才惊觉状态机真是化繁为简，helps a lot。  

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

准确的说，我们这里需要的是 DFA（有限自动机），如果是 NFA，肯定会超过我们脑子负载的：）。有限状态机（FSM）可以分为 DFA 和 NFA[4]：   
>FSM is further distinguished by Deterministic Finite Automata (DFA) and Nondeterministic Finite Automata (NFA). In DFA, for each pair of state and input symbol there is only one transition to a next state whereas, in NFA, there may be several possible next states. Often NFA refers to NFA‐epsilon which allows a transition to a next state without consuming any input symbol. That is, the transition function of NFA is usually defined as T: Q x (ΣU{ε}) → P(Q) where P means power set.Theoretically, DFA and NFA are equivalent as there is an algorithm to transform NFA into DFA.


以上，画出的状态机如下：  
![gamedesignpattern-hero-state-machine](https://blog.antsmallant.top/media/blog/2023-01-03-game-design-pattern/gamedesignpattern-hero-state-machine.png)  
<center>图1：状态机</center>

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

# 更新方法
使用频率：五颗星。  
是否推荐：是。  

“通过对所有对象实例同时进行帧更新来模拟一系列相互独立的游戏对象。”[1]

这个再平常不过了，主游戏循环里的 update 函数，各个系统里的 update 函数，就是用了这种【更新方法】模式。 

---

# 黑板模式
使用频率：二颗星。  
是否推荐：是。  

想不到这也是一种模式吧，unity 里的行为树，就使用了 blackboard 来记录数据。  

它本质上就是一个提供数据共享的 key value store，实现了解耦。但也是有缺点[5]，比如：  
* 读写比较随意，容易造成数据损坏，或子系统竞争。 
* 可能会产生非法的数据。  
* 出问题的时候，如果是多个子系统共用，会比较难调试。  

游戏开发中，行为树通常结合黑板来实现，黑板实现了行为树的节点间“通信”，就是共享数据而已。  

黑板模式在《设计模式: 可复用面向对象软件的基础》[2] 和《游戏编程模式》[1] 都没有介绍，但在《面向模式的软件架构卷1模式系统》[6] 有详细介绍，具体可以看一下。  

---

# ECS
使用频率：一颗星。  
是否推荐：看情况。  

自从守望先锋的在 GDC2017 的分享[3]出来之后，ECS 又再次火了。简单的讲，ECS 就是一种把行为与状态分离的模式，对于守望先锋来说，它的好处在于。  

ECS 是这三个单词的缩写：Entity, Component, System，典型的结构是这样的[3]：  


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