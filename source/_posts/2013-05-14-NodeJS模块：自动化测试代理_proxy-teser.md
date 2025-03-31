---
title: NodeJS模块：自动化测试代理 proxy-teser
date: 22:19 2013/05/14
layout: post
tags:
- nodejs
---
这段时间弄了一个半自动化的测试服务。把其中的核心模块剥离出来放到了npm上面：[proxy-tester](https://npmjs.org/package/proxy-tester "proxy-tester")。

可以用来搭建简单的http代理服务器，里面集成了类似与Qunit这样的单元测试接口。适用于一些web http请求比较多的前端代码测试。

核心思想是把一组测试样例作为一个单元，每个单元运行的时候会启动一个代理服务。每个这样的单元包含许多小的代理服务。这样就可以得到一个map了多个http请求的代理服务器。

当然这只是一个核心模块，可以在这个上面再扩展可视化的界面，或者是全自动化的测试服务。


文档：<http://yutingzhao.com/ProxyTester/doc/index.html> 

GIT： [ProxyTester](https://github.com/yutingzhao1991/ProxyTester "ProxyTester")