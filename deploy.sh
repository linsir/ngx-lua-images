#!/bin/bash

sudo cp -r ngx-lua-images /usr/local/openresty/
# scp -r ngx-lua-images master:/usr/local/openresty/

cd /usr/local/openresty/nginx/conf/conf.d/
if [[ ! -f "ngx-lua-images.conf"  ]]; then
    sudo ln -s  /usr/local/openresty/ngx-lua-images/ngx-lua-images.conf ngx-lua-images.conf

else
    echo -e " [\033[32;1m ngx-lua-images.conf has exsit....\033[0m]"


fi
echo -e " [\033[32;1m auto restart nginx now...\033[0m]"
sudo systemctl restart nginx
echo -e " [\033[32;1m all done...\033[0m]"