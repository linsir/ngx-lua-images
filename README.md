# ngx-lua-images

OpenResty (nginx+lua)+tfs+GraphicsMagick 类似于 zimg, 动态生成处理图片的图片服务器。

## Getting Started

架构类似于zimg,http层加了redis缓存，处理后的保存为文件也算是个缓存，可以写个crontab脚本定期清理不常访问的缓存图片。
后面会支持分布式储存tfs。

图片存储路径的规划方案。


借鉴zimg的方案，存储路径采用2级子目录的方案。由于Linux同目录下的子目录数最好不要超过2000个，再加上MD5的值本身就是32位十六进制数，zimg就采取了一种非常取巧的方式：根据MD5的前六位进行哈希，1-3位转换为十六进制数后除以4，范围正好落在1024以内，以这个数作为第一级子目录；4-6位同样处理，作为第二级子目录；二级子目录下是以MD5命名的文件夹，每个MD5文件夹内存储图片的原图和其他根据需要存储的版本，假设一个图片平均占用空间200KB，一台服务器支持的总容量就可以计算出来了：

    1024 * 1024 * 1024 * 200KB = 200TB

### Installing

GraphicsMagick OpenResty


```bash
sudo apt-get install GraphicsMagick libgraphicsmagick1-dev

or 

yum install GraphicsMagick GraphicsMagick-devel -y

## openresty
tar xvf ngx_openresty-VERSION.tar.gz
cd ngx_openresty-VERSION/
./configure
make
make install


```

And 

```
cd /usr/local/openresty/nginx/conf
mkdir conf.d

add "include conf.d/*.conf;" into nginx.conf

# last, in ngx-lua_images folder.

bash deploy.sh

```

如果没有错误，就可以访问了。

```
http://localhost:8000/fffc929444a9fb7eb754217cfd7b0d58?w=500&h=500&g=1&x=0&y=0&r=45&q=75&f=jpeg
http://localhost:8000/get_info?md5=fffc929444a9fb7eb754217cfd7b0d58
```


## Authors

* **Linsir** - *Initial work* - [Linsir](https://github.com/vi5i0n)

See also the list of [contributors](https://github.com/your/project/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* <http://openresty.org>
* <https://github.com/buaazp/zimg>
* <https://github.com/clementfarabet/graphicsmagick>
* <https://www.gitbook.com/book/moonbingbing/openresty-best-practices>

