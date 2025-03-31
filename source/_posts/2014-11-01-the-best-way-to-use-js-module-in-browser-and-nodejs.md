---
title: 同时在浏览器和服务端使用一个JS模块的最好方法
date: 11:02 2014/11/01
layout: post
tags:
- js
---

JS代码的模块化到现在基本也已经是普及了，大量的代码如果不做模块化划分那么将很难维护。

NodeJS使得Javascript在服务器端也有了应用，它在NodeJS中的模块化更不用说，已经就是NodeJS自身的一部分了。

要说到NodeJS的模块化就不得不说到AMD和CMD。这里有一个知乎上面的提问：[AMD 和 CMD 的区别有哪些？](http://www.zhihu.com/question/20351507/answer/14859415)。

AMD和CMD的定义：[CMD](https://github.com/cmdjs/specification/blob/master/draft/module.md)
[AMD](https://github.com/amdjs/amdjs-api/wiki/AMD)

seajs和requirejs分别也就是在这种规范在浏览器端的实现。NodeJS的模块机制也是认为是CMD的一种实现，虽然它会通过包上一层匿名函数来封装模块，使得没有了 define 这个方法，但是模块的基本书写规则也还是遵循了CMD的规范。可以参考文章[深入浅出Node.js（三）：深入Node.js的模块机制](http://www.infoq.com/cn/articles/nodejs-module-mechanism)

无论什么方式去定义模块，在浏览器端要解决的就是防止全局空间的冲突，必须要使用一个方法作为 factory 去构造闭包封装住一个模块。但是在NodeJS的环境中因为NodeJS会将一个文件封装为一个模块，所以也就省去了外面一层包裹，所以要实现浏览器端和NodeJS端共用一个模块其实要做的就是对模块的封装实现兼容。从大体上讲有两种方案：

1.模块文件直接复用，编写代码过程中直接实现兼容

2.按照NodeJS的方式编写模块代码，然后通过工具生成浏览器版本的模块

第一种方案的实现上按照细节的不同应该能有很多方案，比如Jquery的实现：


```javascript

(function(window){


var jQuery = 'blah';

if ( typeof module === "object" && module && typeof module.exports === "object" ) {
    // Expose jQuery as module.exports in loaders that implement the Node
    // module pattern (including browserify). Do not create the global, since
    // the user will be storing it themselves locally, and globals are frowned
    // upon in the Node module world.
    module.exports = jQuery;
} else {
    // Otherwise expose jQuery to the global object as usual
    window.jQuery = window.$ = jQuery;

    // Register as a named AMD module, since jQuery can be concatenated with other
    // files that may use define, but not via a proper concatenation script that
    // understands anonymous AMD modules. A named AMD is safest and most robust
    // way to register. Lowercase jquery is used because AMD module names are
    // derived from file names, and jQuery is normally delivered in a lowercase
    // file name. Do this after creating the global so that if an AMD module wants
    // to call noConflict to hide this version of jQuery, it will work.
    if ( typeof define === "function" && define.amd ) {
        define( "jquery", [], function () { return jQuery; } );
    }
}

})(this)

```

如果在浏览器端只是使用命名空间来作为模块划分的话可以用：


```javascript

(function(exports){

    // your code goes here

   exports.test = function(){
        return 'hello world'
    };

})(typeof exports === 'undefined'? this['mymodule']={}: exports);
```

第二种方案的话就需要借助工具了，NodeJS的模块自然是要用NodeJS下的工具来处理，见[browserify](http://browserify.org/)。这种方法的好处是不用每个模块都去加一堆兼容的代码，在NodeJS下面运行的时候也少一层嵌套（这对性能有提升吗？）。坏处就是修改之后需要去重新生成浏览器用的模块。还有就是实际上browserify是一个打包工具，它只是去解析NodeJS的模块依赖然后将模块打包到一起供浏览器调用，但是并不能直接转化为requirejs的模块，所以只有你全部的模块代码都用这个方式书写是才能使用，并不能同requirejs一起使用。当然也能写一个简单的脚本就搞定，分别在代码的头部尾部加上封装就可以，但是如果还要考虑依赖关系可能要复杂一些。有空再继续自己搞搞写一个，顺便深入研究下browserify的源代码。另外还有一个[duojs](http://duojs.org/)的打包工具可以看看。

先简单写写，慢慢再实践研究下什么方案最好用。