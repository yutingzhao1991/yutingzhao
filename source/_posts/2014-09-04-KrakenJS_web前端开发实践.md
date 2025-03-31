---
title: KrakenJS web前端开发实践
date: 19:46 2014/09/04
layout: post
tags:
- framwork
---
新的一个项目算是告一段落了，因为是全新的项目，所以我对项目的前端架构选型进行了深入的思考。没有任何历史包袱，也可以由我去自由发挥，所以可以随意的选择任何技术架构去开发。

这个一个数据可视化的项目，涉及到一些表格，图表，地图等数据形式的展示，但是我对前端架构的选型并没有太多的参考业务上面的情况，只是希望通过一个好的框架让前端有一个比较好扩展，快速迭代开发的能力。最后我选择了 [krakenjs](http://krakenjs.com/ "krakenjs") ，至于是什么原因可以先看看我之前写的一篇博客 [关于新的前端开发模式的探索](http://blog.yutingzhao.com/post/2014-03-15/40061259150 "关于新的前端开发模式的探索") 。

关于 KrakenJS， 可以把它看做是对 Express 进行了简单封装，从工程的角度进行了优化。也可以看做是一个 Express 的中间价。 也可以看做是一套web前端规范。一句话来说：KrakenJS 是一个以 Express 中间件的方式从工程的角度封装了 Express 的前端开发与构建框架。KrakenJS 将 Express，Lusca，Dust，Makara，Grunt 集合在了一起，它是一个框架，但是更像是一个规范，一个解决方案。  


**基本结构：**  


KrakenJS 基于 Express，也就是 Express 的一个中间件，所以他的一切也是那么的和 Express 接近，Router， Request， Response 就能够解决一切，只是 KrakenJS 将 MVC 的设计模式封装到了它里面，controller 文件夹下面是 Router ，然后对应有 Model，View 就是在下面一个要点要说的模板。除 此之外还有 config ， test 等。这一部分看官方文档也说得比较清楚。**  
**

**模板和代码复用：**  


KarakenJS 默认集成了 Dust 模板，当然你也可以使用其他模板。然后还集成了 Dust 模板的国际化解决方案 Makara。其实用什么模板都还OK，但是有一点可能就是老生常谈的了，那就是前后端模板复用。KrakenJS 是将模板放在了 public/templates 下面，所以前端也能够使用。不过我用的时候没有找到能够在前端异步去加载模板的方法，也很疑惑为什么 Dust 官方没有提供，或者还是我没有找到。不过最终我还是自己找到了解决方案。Dust 是将模板编译为 JS 的方法然后调用的，所以可以直接通过在页面中导入 对于的模板的JS来实现在页面中去使用模板。当然你也可以通过 Ajax 去异步请求渲染，不过这一多一层回调函数搞得很不爽。当然这也是有办法解决的。不过我最后还是选择了一个比较简单清晰的方法，就是扩展了一Dust的helper，想下面这个样子就可以在页面中插入对于的模板的JS。

{@template name="cashability/table"/}  


这个helper的实现也比较简单：

> 
> 
> helpers.template = function(chunk, context, bodies, params) {
> 
> var language = context.stack.head._locals.context.locality.language;
> 
> var country = context.stack.head._locals.context.locality.country;
> 
> return chunk.write('<script src="/templates/' + country + '/' + language + '/' + params.name + '.js" type="text/javascript"></script>');
> 
> };

另外说到 Helper，其实dust的helper也是需要做到前后端复用的，方法也很简单，Dust 的 helper 的定义其实就是一段JS代码的执行，所以只要将这部分代码做成前后端可以复用的模块也就好了。其他需要复用的模板也是同样的方法。  


构建以及发布：

正常情况下启动 KrakenJS 应用的时候应该是处于一个 debug 的模式，代码没有压缩，template 修改后可以立刻生效。如果要发布的话需要运行 grunt build 预处理模板和压缩JS代码。最后运行的时候还需要设置 process.env.NODE_ENV = 'production';

我在我的代码中加了一段初始化判断，使得可以通过启动命令的flag来选择运行方式：

> var DEBUG_FLAG = function() {
> 
> var flag = false;
> 
> process.argv.forEach(function(val, index, array) {
> 
> if (val == '--fedebug') {
> 
> require('dustjs-linkedin').optimizers.format = function (ctx, node) { return node };
> 
> console.info('fe debug start.');
> 
> flag = true;
> 
> } else if(val == '--release') {
> 
> process.env.NODE_ENV = 'production';
> 
> console.log('release start');
> 
> } else if(val == '--debug') {
> 
> API_SERVER_HOST = 'http://10.11.133.4:8080/bimetrics-web';
> 
> console.log('aat debug start');
> 
> }
> 
> });
> 
> return flag;
> 
> }();


浏览器端架构：

在浏览器端，我并没有做太多的组件化和 MVC 的架构，就是用了 requireJS 做模块的管理，其实也没几个模块，JS也都很简单。其实我的想法是如果能够在前端少写JS，那没必要去写那么多的JS逻辑，其实模板拼接数据挺好的，没必要非要用webAPP的模式，毕竟当年的web其实就等于html。更多的讨论可以参考我在之前写的那篇前端开放模式探讨的文章。