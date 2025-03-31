---
title: 【翻译】JavaScript内存管理
date: 00:01 2013/03/15
layout: post
tags:
- js
---
<span class="edui-filter-align-right">原文：</span>[Memory Management](https://developer.mozilla.org/en-US/docs/JavaScript/Memory_Management "Memory Management")  


**介绍：**

低级语言，例如C。会提供类似malloc()和free()这样的内存管理原语操作。但是在javascript中则会在对象或者字符串等声明时自动分配内存，并且当他不在被使用的时候释放掉。这便是内存回收。这个“自动”便是使得很多高级语言的开发者产生疑惑的源头，他们认为这样则不必关心内存管理。这是一个误区！


**内存的生命周期：**

无论是任何语言，内存的生命周期基本都是下面几个部分

1.分配你所需要的内存

2.使用它

3.当你不许要再用它的时候释放掉

前面两部基本在所有的语言中都是很明确的，但是第三步就不相同了。在C语言这样的低级语言中是很明确的，不过在javascript这样的高级语言中就显得有些模糊了。


**javascript的内存分配**

**变量初始化**

为了不让程序员因为内存分配而困扰，javascript的内存分配是在变量声明的时候进行的。

    var n = 123; // allocates memory for a number
    var s = "azerty"; // allocates memory for a string

    var o = {
      a: 1,
      b: null
    }; // allocates memory for an object and contained values

    var a = [1, null, "abra"]; // (like object) allocates memory for the array and contained values

    function f(a){
      return a + 2;
    } // allocates a function (which is a callable object)

    // function expressions also allocate an object
    someElement.addEventListener('click', function(){
      someElement.style.backgroundColor = 'blue';
    }, false);

通过方法调用分配

通过方法构造新的对象

    var d = new Date();
    var e = document.createElement('div'); // allocates an DOM element


通过方法产生新的值

    var s = "azerty";
    var s2 = s.substr(0, 3); // s2 is a new string
    // Since strings are immutable value, JavaScript may decide to not allocate memory, but just store the [0, 3] range.

    var a = ["ouais ouais", "nan nan"];
    var a2 = ["generation", "nan nan"];
    var a3 = a.concat(a2); // new array with 4 elements being the concatenation of a and a2 elements


**变量的使用**

变量的使用则意味着对内存的读写操作，通常是在读写对象的变量，或者传递参数时操作的。


**当内存不再需要的时候释放掉**

大部分的内存管理的问题都在这一部分产生。其中zui最困难的就是找出什么时候才是：“内存不再需要被使用”，这通常需要程序员来做出判断。

高级语言则嵌入了一段程序叫做：“垃圾回收员”，它的工作就是跟踪内存的分配并且找出什么时候不再需要它的，然后将其释放掉。这个程序所遇到的普遍问题是很多内存的需要是逻辑上的，是不可通过算法判定的。


**垃圾回收：**

上面说了找到内存什么时候才是不再被使用是不可判定的，这使得垃圾回收这个问题构成了一定的局限性。这一部分将会解释一些关于垃圾回收的一些主要的概念帮助理解一些主要的垃圾回收算法以及它们的局限性。**  
**


<span class="edui-filter-line-through">引言：</span>

<span class="edui-filter-line-through">这些垃圾回收的主要概念基于参考文献中的一些概念。</span>

<span class="edui-filter-line-through"></span>

### 引用

垃圾回收中一个主要的概念是引用。在内存管理中，当一个对象无论是显式的还是隐式的使用了另外一个对象，我们就说他引用了另外一个对象。例如，javascript对象存在一个隐式的指向原型的引用，还有显式指向他的属性值的引用。

在这里，对象的概念超出了javascript传统意义上对象的概念，他还包括函数作用域和全局作用域。

（看了昨天的翻译，我自己都汗了，我说怎么看着这么别扭呢，其实别人已经有更好的翻译了，请移步[这里](http://www.cnblogs.com/softlover/archive/2012/12/14/2811718.html "这里")）


引用计数垃圾回收法

这是最主要的一种垃圾回收算法，这个算法将“一个对象不再需要”降级为“一个对象不再存在引用”。当一个对象的引用数为0的时候它将会被回收。

例子：

    var o = { 
      a: {
        b:2
      }
    }; // 2 objects are created. One is referenced by the other as one of its property.
    // The other is referenced by virtue of being assigned to the 'o' variable.
    // Obviously, none can be garbage-collected


    var o2 = o; // the 'o2' variable is the second thing that has a reference to the object
    o = 1; // now, the object that was originally in 'o' has a unique reference embodied by the 'o2' variable

    var oa = o2.a; // reference to 'a' property of the object.
    // This object has now 2 references: one as a property, the other as the 'oa' variable

    o2 = "yo"; // The object that was originally in 'o' has now zero references to it.
    // It can be garbage-collected.
    // However what was its 'a' property is still referenced by the 'oa' variable, so it cannot be free'd

    oa = null; // what was the 'a' property of the object originally in o has zero references to it.
    // it can be garbage collected.


局限性：循环

这个很低级的算法带来的局限性就是当两个对象互相引用形成一个环的时候其实已经是“不在需要”，但是它并不会被回收。

    function f(){
      var o = {};
      var o2 = {};
      o.a = o2; // o references o2
      o2.a = o; // o2 references o

      return "azerty";
    }

    f();
    // Two objects are created and reference one another thus creating a cycle.
    // They will not get out of the function scope after the function call, so they
    // are effectively useless and could be free'd.
    // However, the reference-counting algorithm considers that since each of both object is referenced
    // at least once, none can be garbage-collected

实例：

IE6，7就是一个典型的通过引用计数法处理DOM对象的垃圾回收。所以一种普遍存在的会导致它们内存泄露的方法就是：

    var div = document.createElement("div");

    div.onclick = function(){

      doSomething();

    }; // The div has a reference to the event handler via its 'onclick' property

    // The handler also has a reference to the div since the 'div' variable can be accessed within the function scope

    // This cycle will cause both objects not to be garbage-collected and thus a memory leak.


标记和清扫算法

这个算法将“不再需要”降级为“无法访问”。这个算法假设有一个根集合，一开始垃圾回收程序会从这些节点开始遍历，查找所有能够通过这些节点引用的对象。能够到达的对象将其标记，最后就能找到所有的可以访问的对象并且回收掉那些不可访问的对象。

这个算法比上面那个通过0引用来判断是否可回收的算法要更好一些，再也不会出现循环引用所产生的垃圾了。

截至到2012年，所有的现代浏览器都实现了标记和清扫的垃圾回收算法，提升了javascript的垃圾回收能力。但是这几年来都是在提升这个算法本身的性能，并没有去超越这个算法实现更精确的找到“不再需要”。


循环已经不再是问题

在标记和清扫算法中，循环被很好的解决了，它不再成为垃圾回收中的问题。

局限：对象需要被明确的定义无法访问

虽然这被视为一个局限性，但是在实际中很少出现这样的情形，所以在垃圾回收机制中也没有大多对这个问题的关注。


其他参考

*   [IBM article on "Memory leak patterns in JavaScript" (2007)](http://www.ibm.com/developerworks/web/library/wa-memleak/)

*   [Kangax article on how to register event handler and avoid memory leaks (2010)](http://msdn.microsoft.com/en-us/magazine/ff728624.aspx)