---
title: 通过URL请求图片并存储到浏览器的HTML5 FileSystem
date: 16:02 2012/08/11
layout: post
tags:
- js
- html5
---
这两天研究了一下HTML5的FileSystem。FileSystem使得网页和web应用可以通过浏览器获取比cookie，storage大得多的存储空间。这样使得可以在支持HTML5的浏览器中更容易的实现以前只有桌面应用能够实现的功能。比如在线的图片编辑功能就能够达到更好的用户体验，可以将未编辑完成的图片存放在本地。如果在配合离线缓存的话就可以完美的实现一个web离线应用了。  


web应用要使用浏览器的本地文件系统需要获得用户的允许，在chrome中顶部会出现小黄条提示用户。所以要在chrome中使用FileSystem首先要向用户提出申请：  


    var FILE_SYSTEM_SIZE = 10 * 1024 * 1024; //默认空间大小10M

    var FILE_SYSTEM_TYPE = window.PERSISTENT || 1;//默认为持久性的存储空间

    window.webkitStorageInfo.requestQuota(FILE_SYSTEM_TYPE, FILE_SYSTEM_SIZE, function(grantedBytes) {

            }, function(e) {
                console.log('Error', e);
            });

得到用户的许可后就可以在成功的回调函数中获取到一个可用的本地存储文件系统：

    var fs = null;
    var readyFlag = false;
    (window.requestFileSystem || window.webkitRequestFileSystem)(FILE_SYSTEM_TYPE, FILE_SYSTEM_SIZE, onInitFs, errorHandler);

        function onInitFs(f){
            fs = f;
            readyFlag = true;
        }

如果要向文件系统中写入一个txt的文本文档很简单，通过创建一个文件并获取到这个文件入口，通过入口建立一个写文件的Writer。最后通过Blob创建比特流写入文件中：  


    function onInitFs(fs) {

      fs.root.getFile('log.txt', {create: true}, function(fileEntry) {

        // Create a FileWriter object for our FileEntry (log.txt).
        fileEntry.createWriter(function(fileWriter) {

          fileWriter.onwriteend = function(e) {
            console.log('Write completed.');
          };

          fileWriter.onerror = function(e) {
            console.log('Write failed: ' + e.toString());
          };

          // Create a new Blob and write it to log.txt.
          var bb = new BlobBuilder(); // Note: window.WebKitBlobBuilder in Chrome 12.
          bb.append('Lorem Ipsum');
          fileWriter.write(bb.getBlob('text/plain'));

        }, errorHandler);

      }, errorHandler);

    }

这段代码来自[HTML5 ROCKS TUTORIALS](http://www.html5rocks.com/en/tutorials/file/filesystem/ "HTML5 ROCKS TUTORIALS")。上面说得很详细，不过是英文的。

同样读取文件也很简单：  


    function onInitFs(fs) {

      fs.root.getFile('log.txt', {}, function(fileEntry) {

        // Get a File object representing the file,
        // then use FileReader to read its contents.
        fileEntry.file(function(file) {
           var reader = new FileReader();

           reader.onloadend = function(e) {
             var txtArea = document.createElement('textarea');
             txtArea.value = this.result;
             document.body.appendChild(txtArea);
           };

           reader.readAsText(file);
        }, errorHandler);

      }, errorHandler);

    }


之后让我比较纠结的是如何将一个线上的资源保存到本地，如果是文本还比较简单，可以通过AJAX请求将数据写入到本地:  


    var fileType = {
            jpg: "image",
            png: "image",
            gif: "image",
            txt: "text"
        };

        var contentType = {
            jpg: "image/jpeg",
            png: "image/png",
            gif: "image/gif",
            txt: "text/plain"
        };

    lib.ajax.get(file, function(xhr, msg){
                            if(xhr.status == 200){
                                var bb = new BlobBuilder();
                                bb.append(msg);
                                fs.root.getFile(path, {create: true}, function(fileEntry) {
                                    // Create a FileWriter object for our FileEntry (log.txt).
                                    fileEntry.createWriter(function(fileWriter) {
                                        fileWriter.onwriteend = function(e) {
                                            console.log('Write completed.');
                                            callback && callback(path);
                                        };

                                        fileWriter.onerror = function(e) {
                                            console.log('Write failed: ' + e.toString());
                                        };

                                        fileWriter.write(bb.getBlob(contentType[extname]));
                                    });
                                });
                            }else{
                                console.log("文件加载失败");
                            }
                        });

但是如果资源是图片就麻烦了，AJAX请求过来完全是一对乱码，不知道有没有高人指点下能不能通过AJAX请求到图片的Base64编码或者buffer流。既然不能用AJAX请求，那么就只有用image标签来加载数据了。但是用image标签加载完图片之后怎么获取到图片的Base64编码呢？在这又用到了HTML5的Canvas标签，可以将图片写入到Canvas中，然后在通过Canvas导出Base64编码或者buffer流了。  


    //canvas helper to save image
        var cvs = document.createElement('canvas');
        var ctx  = cvs.getContext("2d");


    var img = new Image();
                        img.src = file;
                        img.onload = function(){
                            cvs.width = img.width;
                            cvs.height = img.height;
                            ctx.drawImage(img, 0, 0);
                            var imd = cvs.toDataURL(contentType[extname]);
                            var ui8a = convertDataURIToBinary(imd);
                            var bb = new BlobBuilder();
                            bb.append(ui8a.buffer);
                            fs.root.getFile(path, {create: true}, function(fileEntry) {
                                // Create a FileWriter object for our FileEntry (log.txt).
                                fileEntry.createWriter(function(fileWriter) {
                                    fileWriter.onwriteend = function(e) {
                                        console.log('Write completed.');
                                        callback && callback(path);
                                    };

                                    fileWriter.onerror = function(e) {
                                        console.log('Write failed: ' + e.toString());
                                    };

                                    fileWriter.write(bb.getBlob(contentType[extname]));
                                });
                            });
                        };

通过Canvas的2d上下文的toDataURL得到Base64编码，然后再通过下面这个函数转化为buffer：  


    //convert base64 date to binary so that you can write it in file
        function convertDataURIToBinary(dataURI) {
            var BASE64_MARKER = ';base64,';
            var base64Index = dataURI.indexOf(BASE64_MARKER) + BASE64_MARKER.length;
            var base64 = dataURI.substring(base64Index);
            var raw = window.atob(base64);
            var rawLength = raw.length;
            var array = new Uint8Array(new ArrayBuffer(rawLength));

            for (i = 0; i < rawLength; i++) {
                array[i] = raw.charCodeAt(i);
            }
            return array;
        }

这个函数也是在网上找的。到此图片就写入FileSystem中了，然后很简单的就可以通过fileEntry.toURL()获取到一个本地的url地址。

    fs.root.getFile(path, {}, function(fileEntry) {

                        // Get a File object representing the file,
                        // then use FileReader to read its contents.
                        fileEntry.file(function(file) {
                            var reader = new FileReader();

                            reader.onloadend = function(e) {
                                callback && callback(this.result);
                            };

                            reader.readAsText(file);
                        }, errorHandler);

                    }, errorHandler);

这样就可以将一个服务端的图片拉取到本地存储到本地的文件系统中，在离线的时候也可以使用了。另外还需要注意的是本地文件系统是以域名为一个单位的，每一个域名会请求到一个完全独立的存储空间，所以要在本地测试也还需要简单的搭建一个服务器，这样在127.0.0.1下就会有一个独立的文件系统。