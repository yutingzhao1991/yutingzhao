---
title: 关于setTimeout在大量dom节点渲染时的优化分析
date: 21:26 2012/07/25
layout: post
tags:
- js
---
<span>1、</span><span>setTimeout<span>传递的函数被执行的时机：</span></span>

<span>当前任何挂起的事件运行完事件句柄并且完成了文档的当前状态更新之后。</span>

<span>当前正在执行的<span>JS</span><span>顺序执行完毕。</span></span>

<span>简单点说：当浏览器没事干的时候。</span>

<span>  
</span>

<span>2、</span><span>用途：</span>

<span>由<span>setTimeout</span><span>执行的时机可以看出它在性能优化方面的用途。</span></span>

<span>分割需要循环处理的数组或者过长的任务，防止过长的<span>JS</span><span>执行使得</span><span>UI</span><span>的更新被中断。</span></span>

<span>通过<span>setTimeout</span><span>间隔执行代码可以留出空白时间使得</span><span>UI</span><span>可以更新，不会产生“假死”的状态。提高用户体验。</span></span>

<span><span>  
</span></span>

<span>3、</span><span>实验对比：</span>

<span>对<span>10000</span><span>个并列的</span><span>dom</span><span>节点进行渲染，使用</span><span>Chrome</span><span>的插件</span><span>Monitor Tab</span><span>测试出的结果如下：</span></span>

<span>未使用<span>setTimeout</span><span>：</span></span>

<span><span>![]()  
</span></span>

<span>页面会停滞很久，然后突然渲染出来。耗时基本都在</span><span>DOM (load)</span><span></span><span>上面：</span>

<span>![]()  
</span>

<span>  
</span>

<span></span>

<span>使用<span>setTimeout</span><span>：</span></span>

![]()  


<span>整体运行事件变长了，但是被分割成了很多块，<span>UI</span><span>不会卡死。其中最大的一块耗时其实是</span><span>Time Fire</span><span>：</span></span>

![]()  


<span>4<span>、需要注意的坑：</span></span>

<span>在<span>IE8</span><span>（其它浏览器未测试）下测试得出</span><span>setTimeout</span><span>过多后会莫名奇妙丢失最后一些：</span></span>

![]()  


<span></span>

<span>setTimeout<span>使用的间隔越小，丢失得越多。</span></span>

<span>另外不要迷恋<span>setTimeout</span><span>的时间，不会绝对精确，虽然在同一个</span><span>for</span><span>循环中使用相同间隔的计时器分割循环，最后执行的顺序会按照原来的顺序执行，但是通过下面这个例子可以知道</span><span>setTimeout</span><span>自身的定义就决定了它不适合用来通过时间做顺序控制。</span></span>

    console.log(0);
        setTimeout(function(){
            console.log(1111111111111);
        }, 10);
        for(var i=0; i<10000;i++){
            setTimeout(function(){
                console.log(1);
            }, 0);
        }

<span>得出的结果是：</span>

![]()  


<span>5、</span><span>使用<span>setTimeout</span><span>做性能优化的一些原则：</span></span>

<span>1<span>：适用与处理过程不必须同步，不必须按顺序处理的任务。</span></span>

<span>2<span>：普遍来说，最好使用至少</span><span>25</span><span>毫秒的延迟，延迟过小对</span><span>UI</span><span>更新来说会不够。</span></span>

<span>3<span>：不要过多的使用</span><span>setTimeout</span><span>，使得片段过小，定时器数量过多。</span></span>

<span><span>  
</span></span>

<span><span>6、</span><span>Web Workers</span></span>


......