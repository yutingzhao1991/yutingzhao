---
layout: post
title: Nodejs 脚本从点点网导出博客为 Markdown 文件
tags:
- other
- nodejs
---

最近发现点点网的博客服务不给力了，所以迁移到了 github 用 kekyll 来写博客。但是老的博客还是需要迁移过来吧。所以就在想怎么才能将数据导过来。

点点网的博客是可以导出为 XML 文件的。所以可以解析 XML 然后获取到里面的数据自动生成 md 文件。代码放到了gist上面：
[点我](https://gist.github.com/yutingzhao1991/86238c8a61e5620bdcfe "NodeJS脚本导出点点博客为Markdown文件")

里面用到了几个 NodeJS 的库：

1. cheerio 解析 XML（HTML）的库，JQuery的语法
2. fs 读取文件和写文件
3. moment 时间处理库
5. upndown HTML转Markdown文件


