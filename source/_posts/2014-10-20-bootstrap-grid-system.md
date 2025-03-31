---
title: 探索 Bootstrap CSS 网格系统
date: 21:02 2014/10/20
layout: post
tags:
- css
---

几天前面试了一人，毕竟是搞前端。虽然说CSS有些生疏了，但是多少还是要问问的。虽然我自己不知道答案，但是提问还是可以的嘛。毕竟也没说就一定得会自己出的题目。说到这来又要顺便扯一句之前在《X嫌疑人的献身》里面看到的一句话：

> 对于数学问题，自己想出答案和确认别人的答案是否正确，哪一个更简单，或者困难到何种程度，拟一个别人无法解答的问题和解开那个问题，何者更困难？

不知道对于程序问题而言如何？或者程序问题本身也都是数学问题？

闲话还是少扯点，先说说我的问题，其实很简单。就是：**如何实现一个div包含三个div，里面三个div分别占用外面div的 1/3 宽度，最好里面三个div直接有固定宽度空隙，而且对于外层是响应式的**
这个问题其实 boostrap 的 Grid System 已经几乎完美的解决了，平时也经常用 Bootstrap 但是确没有仔细研究过这里，说来也是惭愧。


也就是说补充下面的 row 和 col 的实现。当然也可以用 javascript 实现。

```html
<div class="row">
    <div class="col"> col 1 </div>
    <div class="col"> col 2 </div>
    <div class="col"> col 3 </div>
</div>
```

给出的最基础的解决方案就是

```css
.row {
    width: 100%;
}
.col {
    width: 33.333%;
    float: left;
}
```

本来我还想试试看看 float 改为 display:inline-block 看看行不行。最后发现div直接会有空隙。原来是因为 div 直接的换行其实是占用空间的。这个问题在 [stackoverflow](http://stackoverflow.com/questions/1833734/display-inline-block-extra-margin) 上面也有讨论。

但是麻烦的是如果需要在几个div中间插入缝隙的话（div增加padding）那么三个 33..% 再加上padding就会超出row的范围了。不过Bootstrap解决了这个问题。那就是用 [box-sizing](http://www.w3schools.com/cssref/css3_pr_box-sizing.asp)，是一个 CSS3 的属性。IE6神马的应该不支持，这种情况应该就是用JS了吧，我也没去多想。

解决了padding的问题，那么还有一个细节就是除了div中间有了缝隙，但是两侧也会有一个padding。这个怎么处理呢？同样也是直接看了Bootstrap的做法，是将外层的div设置一个负的margin值来定位，使得它的时间宽度比100%要大。大的这部分正好通过margin到外层边界外，抵消掉内部div的padding。最后的实现就是：


```css
.row {
    margin-right: -15px;
    margin-left: -15px;
}
.col {
    width: 33.333%;
    float: left;
    display: inline-block;
    padding: 15px;
    box-sizing: border-box;
}
```

完整的html，见 [gist](https://gist.github.com/yutingzhao1991/8622548d0516c4509bc2)