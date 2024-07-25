---
layout: post
title: "网络游戏同步技术五：帧同步的实现与优化"
date: 2023-07-05
last_modified_at: 2023-07-05
categories: [网络游戏同步技术]
---

* 目录  
{:toc}
<br/>

本文简单讲一讲 “帧同步” 的实现与优化。  

---

# 1. 实现

帧同步的确定性，要求各种平台之上的客户端计算都是确定的，这些都可能导致不确定计算：浮点数，随机数，执行顺序，排序的稳定性，物理引擎。在实现上，一般有以下的方法：  

* 浮点数可以使用定点数替代。  
* 随机数可以统一随机数种子。  
* 执行顺序，要保持一致，需要所有的逻辑要有一个统一的入口，每次 tick update 进入一个统一的入口，依次调用各个模块的逻辑。   
* 排序的稳定性，可以指定统一的稳定排序算法。  
* 物理引擎，要求确定性的模拟，需要选用保证确定性的物理引擎。   

帧同步的挑战很大，由于误差累积会变大，基本上只要有一次计算不一致，那后续结果就都不一致了，游戏也就玩不下去了，王者荣耀的这个分享[1]就讲了很多这一方面的努力。   

---

# 2. 优化

## 2.1 乐观帧

现在事实意义上的帧同步算法都是用的乐观帧了，即每帧固定时长，超时不等待。  

但这里有个细节问题，客户端发送给服务端的 input 数据包都是带有客户端帧号的，那么服务端是否要抛弃客户端过时的 input 数据包，即客户端帧号小于当前服务端帧号的数据包？   

比如这个 demo 项目（[https://github.com/JiepengTan/Lockstep-Tutorial](https://github.com/JiepengTan/Lockstep-Tutorial)）就是会抛弃客户端 input 数据包的。 [https://github.com/JiepengTan/Lockstep-Tutorial/blob/master/Server/Src/SimpleServer/Src/Server/Game.cs](https://github.com/JiepengTan/Lockstep-Tutorial/blob/master/Server/Src/SimpleServer/Src/Server/Game.cs):    

```cs
void C2G_PlayerInput(Player player, BaseMsg data){
    ...
    if (input.Tick < Tick) {
        return;
    }
    ...
}
```

这样抛弃是否会带来问题？似乎是有问题的，即一个延迟高的客户端，它的 input 永远不会被服务端应用。我认为这样是不妥的，那么如何实现才是好的呢？   

参考另一个 demo ( [https://github.com/Enanyy/Frame](https://github.com/Enanyy/Frame) )，这个实现不会抛弃客户端过时的 input 数据包，代码在此（ [https://github.com/Enanyy/Frame/blob/master/FrameServer/FrameServer/Program.cs](https://github.com/Enanyy/Frame/blob/master/FrameServer/FrameServer/Program.cs) ）：   

```cs
private void OnOptimisticFrame(Session client, GM_Frame recvData)
{

    int roleId = recvData.roleId;

    long frame = recvData.frame;

    Debug.Log(string.Format("Receive roleid={0} serverframe:{1} clientframe:{2} command:{3}", roleId, mCurrentFrame, frame,recvData.command.Count),ConsoleColor.DarkYellow);
    
    if (mFrameDic.ContainsKey(mCurrentFrame) == false)
    {
        mFrameDic[mCurrentFrame] = new Dictionary<int, List<Command>>();
    }
    for (int i = 0; i < recvData.command.Count; ++i)
    {
        //乐观模式以服务器收到的时间为准
        Command frameData = new Command(recvData.command[i].frame, recvData.command[i].type, recvData.command[i].data, mFrameTime);
        if (mFrameDic[mCurrentFrame].ContainsKey(roleId) == false)
        {
            mFrameDic[mCurrentFrame].Add(roleId, new List<Command>());
        }
        mFrameDic[mCurrentFrame][roleId].Add(frameData);
    }
}
```

---

## 2.2 buffering

针对延迟以及网络抖动，可以通过增加缓冲区的方式来对抗：
输入 -> 缓冲区 -> 渲染   
缓冲区的问题在于会增加延迟。  

---

## 2.3 预测回滚

不止是状态同步，帧同步也是可以 “预测回滚” 的，但叫法是 timewarp。大体做法都是记录快照，然后出现冲突的时候回滚到快照点。韦易笑的这篇文章《帧同步游戏中使用 Run-Ahead 隐藏输入延迟》[2]介绍过这种做法。   

---

# 3. 参考

[1] 邓君. 王者技术修炼之路. Available at https://youxiputao.com/articles/11842, 2017-5.   

[2] 韦易笑. 帧同步游戏中使用 Run-Ahead 隐藏输入延迟. Available at https://www.skywind.me/blog/archives/2746, 2023-10.        


