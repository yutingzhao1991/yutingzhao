---
title: ECharts 的痛点和解决方案 EChartsPlus
date: 2017-05-10
categories: 技术
tags:
- 前端
- 数据可视化
---

先附上链接：[echarts-plus](https://github.com/yutingzhao1991/echarts-plus)！

想必大部分前端开发者尤其是接触过数据可视化的开发者对[ECharts](http://echarts.baidu.com/index.html)并不陌生，它是百度出品的一个强大的交互式的浏览器端的可视化图表库（A powerful, interactive charting and visualization library for browser ）。

ECharts支持丰富的可视化形式，通过`option`来表达图表，比如下面的[例子](http://echarts.baidu.com/demo.html#bar-tick-align)
```js
option = {
    color: ['#3398DB'],
    tooltip : {
        trigger: 'axis',
        axisPointer : {            // 坐标轴指示器，坐标轴触发有效
            type : 'shadow'        // 默认为直线，可选为：'line' | 'shadow'
        }
    },
    grid: {
        left: '3%',
        right: '4%',
        bottom: '3%',
        containLabel: true
    },
    xAxis : [
        {
            type : 'category',
            data : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
            axisTick: {
                alignWithLabel: true
            }
        }
    ],
    yAxis : [
        {
            type : 'value'
        }
    ],
    series : [
        {
            name:'直接访问',
            type:'bar',
            barWidth: '60%',
            data:[10, 52, 200, 334, 390, 330, 220]
        }
    ]
};
```

看上去很好用对不对，但是如果真正在开发中大量使用过ECharts的同学就知道，构建xAxis中的data以及series中的data是一个让人烦躁的过程。

ECharts的配置很强大，你可以通过option描述出图表中的任何细节，实现灵活而强大的可视化效果。但是echarts的option是用来描述图表中的视觉元素的，构建这样的配置真的很简单吗？要知道数据可视化的本质是处理数据，而我们拿到的数据往往是下面这个样子的：
```
[{
   dt: 'xxx',
   revenue: 323,
   platform: xxx
}, ...]
```
这样的数据要转化为echarts的配置简单吗？其实没这么复杂，但是会让你抓狂，看这段代码：
```js
var myChart = echarts.init(document.getElementById('main'))
// 指定图表的配置项和数据
var series = _.chain(data).groupBy('platform').map((group, platform) => {
  var d = _.chain(group).sortBy('dt').map('revenue').value()
  return {
    name: platform,
    type: 'bar',
    data: d
  }
}).value()
var option = {
  tooltip: {},
  legend: {
    data: _.map(series, 'name')
  },
  xAxis: {
    data: _.chain(data).sortBy('dt').map('dt').uniq('dt').value() // 这里不严谨，其他数据项有可能出错
  },
  yAxis: {},
  series: series
}
myChart.setOption(option)
```

[实例](http://yutingzhao.com/echarts-plus/examples/getstart/echarts.html)

我们用了lodash的groupBy等函数才勉强（xAxis有漏洞）才构建出了一个多个series的柱状图。

有没有更好的办法呢？首先我们需要从数据可视化的本质出发。

> 数据可视化本质上是将数据通过视觉的方式呈现出来让人类可以感知，也就是可视化编码。
> 
> 可视化编码是信息可视化的核心内容，是将数据映射成可视化元素的技术，其通常具有表达直观，易于理解和记忆等特性。数据通常包含了属性和值。因此，类似的，可视化编码由两方面组成：（图像元素）标记和用于控制标记的视觉特征的视觉通道。前者是数据属性到可视化元素的映射，用于客观地代表数据的性质分类；后者是数据的值到标记的视觉表现属性的映射，用于展现数据属性的定量信息，两者的结合可以完整地对数据信息进行可视化表达。

简单点说就是**可视化其实就是样数据的属性（值）映射到图表的属性（视觉通道）中**。

我们再来看看echarts的series的data：
```
series: [{
  name: platform,
  data: [dt, revenue]
}]
```
实际上就是把数据中的每一项映射到了series的data中，所以在echarts-plus中我们通过映射的配置得到series的data：
```js
series: [{
  generator: 'platform',
  visions: [{
    channel: 'x',
    field: 'dt'
  }, {
    channel: 'y',
    field: 'revenue'
  }]
}]
```
并通过generator自动生成多个series以及自动构建出xAixs和legend，最后看看我们用echarts-plus实现的代码：
```js
new EChartsPlus(data, {
  coord: 'rect',
  series: [{
    visions: [{
      channel: 'y',
      field: 'revenue'
    }, {
      channel: 'x',
      field: 'dt'
    }],
    generator: 'platform'
  }],
  legendTarget: 'series'
}).renderTo('main')
```

是不是清晰了很多。你可以查看这个[实例](http://yutingzhao.com/echarts-plus/examples/getstart/echarts-plus.html)。

用过Highcharts的同学可能能感受到echarts的配置和highcharts很接近，他们通过强大的配置描述出图表，但是确对数据本身不是那么友好。数据和可视化的配置糅杂在了一起导致很难抽象出数据可视化的本质逻辑，所以我们搞了这echarts-plus用于将数据和可视化配置分离出来，并且进一步抽象可视化这一过程，使得数据到图表这一过程变得更抽象，也变得真正意义上的可配置。

阿里的[G2](https://antv.alipay.com/g2/doc/)和[vege](https://github.com/vega/vega)也是类似的从可视化语法出发面向数据可视化本身构建的一套可视化图表库，觉得echarts可以借鉴一下。

最后附带上[echarts-plus](http://yutingzhao.com/echarts-plus/)！





