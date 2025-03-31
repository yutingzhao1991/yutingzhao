---
title: 任务管理框架 JobManager
date: 16:17 2014/12/14
layout: post
tags:
- nodejs
---

JobManager是什么？
---------------

Code在此： [jobManager](https://github.com/yutingzhao1991/jobManager)

JobManager是一个用来管理定时任务的轻量级框架，这里说的定时任务可以简单的理解为每隔一段时间执行一个Shell命令。这个命令可以是普通的shell脚本，也可以是一个python脚步，nodejs脚步。只要一切能够在linux命令行上运行的命令都可以用JobManager来管理。


JobManager适用于什么样的情景？
-------------------------

- Linux / Unix 下

- 任务可以通过shell脚本运行


JobManager解决什么问题？
--------------------

- 通过JSON配置灵活的构建任务，利用灵活的插件模式可以自动扩展插件，使得能够通过简单的JSON配置就能轻松构建最终任务的shell脚本。

- 管理Job的依赖关系

- 通过web网页可以轻松的启动Job，停止Job，查看日志等。


如何开始使用JobManager并添加一个Job？
-------------------------------

- 首先你需要将代码下载或者通过 git clone 到你的Linux机器上。

- JobManager基于NodeJS实现，所以需要安装[NodeJS](http://nodejs.org/)，NodeJS中自动包含了NodeJS的包管理工具 NPM。另外任务的状态存储是通过mongodb，所以还需要一个mongodb的服务，mongodb用户名密码配置是在 config.json 中。

- 进入到JobManager目录中运行`npm intall`安装一些必要的NodeJS第三方库，另外一些shell脚本命令也是必须的：`date`

- copy config.default.json 到 config.json， 修改一些配置信息，比如web的端口号，报警邮件配置，mongodb配置。

- 在根目录中运行`npm run build`或者`sh build.sh`，这个命令会将 jobs 文件夹里面的Job的json配置编译为shell脚步连同 jobs/src 下面的一些任务文件生成到 _jobs 文件夹中。JobManager默认给出了两个简单的Job实例 demo.a 和 demo.b

- 然后运行`npm run bk`或者`node monitor/bk_index.js`，这个命令会启动一个不断轮训的程序去更新Job的状态（读取日志分析JOB是否失败，判断是否需要启动一个新Partition的JOB等）完成这个一步之后其实任务已经在运行了，Job具体执行的方式在通过执行 _jobs 文件夹中的shell脚本实现，日志会输出到 _jobs 下的 [job_name].log 中，程序会定期去通过分析日志等操作更新JOB状态。

- 接下来运行`npm run fe`或者`node monitor/fe_index.js`就能够启动一个web server。 访问 127.0.0.1:3000 就可以查看并更改job状态了。当然你也可以更改 config.json 修改你的端口号。

- 你可以在monitor中看到 demo.a 和 demo.b 的状态。接下来可以添加你自己的Job，首先要在jobs目录下创建你的job的配置文件，job名称就是文件名称。job的配置参考  [README](https://github.com/yutingzhao1991/jobManager/blob/master/README.md) 。每个任务由多个task组成，每隔task对应由一个插件(plugin)生成。task 中配置的 plugin 对应的就是 plugins 文件夹中的同名文件夹。你也可以添加自己的 plugin，用来维护你的JOB。

- 新的JOB的json配置创建好之后再次在根目录运行 `npm run build` 将新的任务也编译到 _jobs 中。这个时候就可以在 monitor 上点击 start 去启动你的新任务了。


如果编写扩展去更好的管理自己的任务？
----------------------------

任务是由task组成，每个task其实最终编译后都对应的是一个shell命令。每个task对应一个插件（plugin），下面是base插件的代码：

```javascript

//
// A base plugin for demo
// taskConfig: {
//  "command": "your shell command here"
// }

module.exports = function (jobName, jobConfig, taskConfig) {
    return taskConfig.command
}

```

通过`npm run build`去编译job配置的时候实际上就是去运行对应的插件去获取最终的shell命令。比如上面这个base的插件，它会将task配置中的 command 的值 作为最终的shell命令。同样编写自己的扩展也很简单，只要在 index.js 模块中通过job名称，job配置和task配置构建出最终的shell命令即可。比如下面的代码是实现一个 hadoop 中 hive 任务的插件：

```javascript
//
// A plugin for run a hql
// taskConfig: {
//  "hql": "your hql file",
//  "queue": "mapred.job.queue.name",
//  "priority": "mapred.job.priority",
//  "reducers": "mapred.reduce.tasks"
// }
//

var TEMPLATE = 'hive \
    -hiveconf mapred.job.name={JOB_NAME} \
    -hiveconf mapred.job.queue.name={HIVE_QUEUE} \
    -hiveconf mapred.job.priority={HIVE_PRIORITY} \
    -hiveconf mapred.reduce.tasks={NUM_REDUCERS} \
    -hiveconf hive.auto.convert.join=true \
    -hiveconf hive.exec.compress.output=true \
    -hiveconf hive.exec.compress.intermediate=false \
    -hiveconf hive.root.logger=ERROR,console \
    -hiveconf mapred.output.compress=true \
    -hiveconf mapred.output.compression.codec=org.apache.hadoop.io.compress.GzipCodec \
    -hiveconf mapred.job.shuffle.input.buffer.percent=0.2 \
    -hiveconf DATE="\'$DATE\'" \
    -hiveconf HOUR="$HOUR" \
    -hiveconf QUARTER="$QUARTER" '

module.exports = function (jobName, jobConfig, taskConfig) {
    var cmd = TEMPLATE.replace('{JOB_NAME}', jobName)
                      .replace('{HIVE_QUEUE}', taskConfig.queue || 'default')
                      .replace('{HIVE_PRIORITY}', taskConfig.priority || 'NORMAL')
                      .replace('{NUM_REDUCERS}', taskConfig.reducers || 1)
    return cmd + '-f ' + taskConfig.hql
}
```
另外在你最终生成的shell脚步中可以使用一些变量类似`$DATE`，具体参考[README](https://github.com/yutingzhao1991/jobManager/blob/master/README.md)

通过插件能够很方便的将类似的任务归纳在一起，使得新建一个job变得容易。


一些提示：
-------

task的配置中提供 retry 这个属性，当这个属性为 true 的时候，job运行的时候会一直尝试这个task直到成功。这样对那些不在jobManager管理范围内的依赖可以借此通过重试的方式去处理依赖。比如在demo.a中的一个task

```
{
    "plugin": "base",
    "retry": "true",
    "config": {
        "command": "test \"\\`date \"+%M\"\\`\" -gt \"03\""
    }
}
```
这个task会一直尝试当前的分钟，直到大于3的时候算成功。


jobManager运行的时候其实是有两个程序在运行，一个bk 和一个 fe。但是无论kill掉bk还是fe，当前正在运行的job是不会被停掉的，job的partition是通过 nohup 执行job的脚本去运行的，job运行过程中可以通过 `ps aux | grep demo.a` 看到在后台运行的任务。不过如果在monitor中点击stop，那么如果任务正在运行，则该进程也会被kill掉。

新增并编译job后 bk 程序会自动将新的job加入到数据库中，然后在monitor的页面中即可操作该job。


为什么要用 NodeJS？
----------------

其实之前有过一个版本是全部用shell实现的定时任务管理，然后用python通过读取日志的方式实现监控。但是因为shell占了很大比重，任务的编写是直接在写shell，也不太方便实现通过web去直接管理job，所以在jobManager的实现中降低了 shell 代码的比重，shell 只用于具体执行的步骤，监控和定时管理都是通过NodeJS实现。

为什么用NodeJS？其实用Python， Go 什么的都行，这里其实不用太纠结。只是考虑到 Node 的 Npm 包管理不错，有很多优秀的第三方的库，另外我也比较熟悉，开发会比较快。当然对于 bk 程序来所其实 NodeJS 的异步模型是帮了倒忙，不过借助  promise 的帮助也还算可以。另外不得不吐槽一下 python 的版本和包管理，python 3 都发布好久了吧，2.x 还在大行其道，包管理工具也有 easy-install 和 pip，完全被搞晕。其实要是时间充裕我是想用 Go 来写的。哎，怎奈业务太多，大家都忙于业务，所以就这样了。


生命在于折腾！~
-------------


