    openresty/ngx_img_server/vendor/graphicsmagick/Image.lua:304: libGraphicsMagickWand.so: cannot open shared object file: No such file or directory

    sudo apt-get install libgraphicsmagick1-dev

    convert.lua:3: module 'sys' not found:
    
    yum install GraphicsMagick GraphicsMagick-devel -y

https://github.com/torch/luajit-rocks
http://wuzhiwei.net/lua_style_guide/


图片存储路径的规划方案。
上文曾经提到，现阶段zimg服务于存储量在TB级别的单机图片服务器，所以存储路径采用2级子目录的方案。由于Linux同目录下的子目录数最好不要超过2000个，再加上MD5的值本身就是32位十六进制数，zimg就采取了一种非常取巧的方式：根据MD5的前六位进行哈希，1-3位转换为十六进制数后除以4，范围正好落在1024以内，以这个数作为第一级子目录；4-6位同样处理，作为第二级子目录；二级子目录下是以MD5命名的文件夹，每个MD5文件夹内存储图片的原图和其他根据需要存储的版本，假设一个图片平均占用空间200KB，一台zimg服务器支持的总容量就可以计算出来了：
1024 * 1024 * 1024 * 200KB = 200TB
这样的数量应该已经算很大了，在200TB的范围内可以采用加硬盘的方式来拓容，当然如果有更大的需求，请期待zimg后续版本的分布式集群存储支持。
除了路径规划，zimg另一大功能就是压缩图片。从用户角度来说，zimg返回来的图片只要看起来跟原图差不多就行了，如果确实需要原图，也可以通过将所有参数置空的方式来获得。


https://github.com/xiangpaopao/blog/issues/7
移动端Web上传图片实践

所有的文件 IO 操作，都是同步阻塞的，他们都会破坏 OpenResty 的事件循环机制。所以要尽量避免。

如果每次读取的文件是同一个，完全可以把文件内容缓存到内存中。

更推荐的玩法是把文件内容，解析到redis这类 KV 数据库中，这样后期就可以通过网络方式解决，并且可以简化问题处理。

    nginx 中并不擅长有关 CPU、磁盘 I/O 这类资源消耗场景，应尽量把这些功能拆分到其他服务，通过网络 API 的方式暴露给 nginx，让 nginx 可以更高效完成高并发网络处理

    这里还是一个度的问题，如果单次 CPU 密集型计算和硬盘 IO 操作的延时控制在毫秒级别乃至以下，则并不是什么问题。 
    YuanSheng Wang

如果这类阻塞操作的延时要高得多，同时在总流量中的占比不高，则可以放在某个“后端 nginx”里面，然后让前端 nginx 与之通信。（后端 
nginx 可以直接使用 ngx_stream_lua_module 暴露 TCP 服务，而前端 nginx 直接在 Lua 里面挑 
cosocket 与之交互）。 

无论如何，需要提醒的是，无论 CPU 资源还是文件 I/O 的吞吐力都是一个常量，所以尽量减少资源浪费才是提升性能的关键（拆分过多的服务或 
OS 线程只会加剧系统资源的浪费性消耗）。 

Regards, 
-agentzh 

1、可以用NGINX较新的版本，引入aio thread支持，可以缓解（并非根治）File I/O调用的阻塞。 

2、自己用FFI+LUA协程+异步文件读写IO去封装实现无阻塞文件访问LUA文件访问函数库。


> 如果是同步的话，如何将它与后面的语句搞成异步的关系呢？ 

可以使用 ngx.timer.at() API. 不过我觉得意义不大，因为文件写操作无论如何都是阻塞 IO，这受限于 Linux 
操作系统（除非使用 AIO，但那又须使用 Direct IO，得不尝失）. 

> 另外，如果ffi 封装的module有segment 
> default，应该如何调试呢？ 
> 

可以使用 valgrind 进行调试，配合下面这一行 Lua 代码（放在被测试的 Lua 代码开头）： 

    debug.sethook(function () collectgarbage() end, 'l') jit.off() 

Regards, 
-agentzh 