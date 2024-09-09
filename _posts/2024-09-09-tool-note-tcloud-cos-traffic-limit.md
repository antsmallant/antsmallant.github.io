---
layout: post
title: "腾讯云 cos 流量防刷"
date: 2024-09-09
last_modified_at: 2024-09-09
categories: [工具]
---

* 目录  
{:toc}
<br/>

# 概述

博客的图床用的是腾讯云的 cos，我的桶设置为了公有读私有写，因为私有读写太麻烦了，用起来不方便。而公有读私有写又有盗刷问题，我的 cos 是后付费的，而腾讯云又没法实际消费金额上限，那么当盗刷发生的时候，系统会把我的账户扣费成负数，除非我以后都不用腾讯云了，总需要把欠费补上的。   

于是，为了防止被盗刷流量，做了一些研究。    

方法一：设置防盗链   

这种方式是设置 referer，防不住真正要盗刷流量的。   

所以，这种方法行不通。  

<br/>

方法二：cdn + cos   

通过给 cdn 配置流量阈值，来达到限制。太麻烦了，我的博客几乎没啥流量，犯不着另外配置 cdn。   

所以，这种方法对我没用。  

<br/>

方法三：云函数监测流量，超过阈值自动把cos桶的权限改为私有读写      

这个方法参考自这篇文章 [《使用腾讯云SCF实现COS费用封顶的最佳实践》](https://cloud.tencent.com/developer/article/2258668) [1]，查了一下，作者本人就是腾讯云的员工。   

按照文章的指引，成功的对 cos 桶进行了流量控制，目前设置是 5 分钟内（采样10分钟前的数据）流量超过 30MB 就关闭桶的公有读。   

所以，这种方法对我是有效的。   

---

# 大概做法

简单描述一下做法。    

1、购买云函数服务     

链接：[https://console.cloud.tencent.com/scf/list?rid=1&ns=default](https://console.cloud.tencent.com/scf/list?rid=1&ns=default) 。  

<br/>

2、新建一个云函数    

第一步    

选择 "模板创建"；      
搜索 "timer"；    
选择 Python3.6 的定时拨测。  

第二步      

地域，选择跟cos一个地域（据说这样更好些，因为同园区与 cos 互访不产生外网流量）；    
日志投递，选择启用，默认投递，默认格式（follow 指引，如果需要新开通则开通，有日志查看还是方便些，也不贵的）；       
触发器配置，选择自定义创建，触发周期改为一分钟；      

搞完就点完成，等待创建。   

<br/>

3、修改函数代码    

1） 点进创建好的函数，点到函数管理，把这段代码：[https://github.com/colasun/serverless-demo/blob/master/Python3.6-COSLimitSpendingDemo/src/index.py](https://github.com/colasun/serverless-demo/blob/master/Python3.6-COSLimitSpendingDemo/src/index.py) 拷贝到函数编辑器里。    

2）修改代码中的几个变量     

```
secret_id 
secret_key 
region 
bucket 
```

secret_id 和 secret_key 是在 cam 里的 "API 密钥设置" 设置的，链接是：[https://console.cloud.tencent.com/cam/capi](https://console.cloud.tencent.com/cam/capi)。    

3）修改代码中的流量阈值     

下面的这里改一下，目前代码逻辑是 5 分钟内的流量总和超过 5GB 就修改桶的权限为私有读写，根据自己的需要作调整。  

```python
if _flow > 5000*1024*1024:   #超过5GB流量阈值
```

<br/>

4、测试     

先把阈值调小一点，然后选择几个大一些的文件测一下。要注意，代码是判断的 10 ~ 15 分钟前这一段时间内的（文章中说这样的监控采集更准确）。  

---

# 参考

[1] wainsun. 使用腾讯云SCF实现COS费用封顶的最佳实践. Available at https://cloud.tencent.com/developer/article/2258668, 2023-04-13.   