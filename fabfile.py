#!/usr/bin/env python
# -*- coding: utf-8 -*-
# @Date    : 2016-03-14 15:58:57
# @Author  : Linsir (root@linsir.org)
# @Link    : http://linsir.org
# @Version :

import os
# from fabric.api import local,cd,run,env,put
from fabric.colors import *
from fabric.api import *


import paramiko
paramiko.util.log_to_file('/tmp/paramiko.log')


# 2. using sshd_config
env.hosts = [

        'master',# master

]

env.use_ssh_config = True

prefix = '/usr/local/openresty/'

def put_conf_file():
    print(yellow("copy ngx-lua-images and configure..."))
    # run('sudo rm -rf /usr/local/openresty/ngx-lua-images/')
    # put('ngx-lua-images', '/usr/local/openresty/')

    if os.path.exists("%sngx-lua-images/" %prefix):
        local("sudo rm -rf %sngx-lua-images/" %prefix)

    local("sudo cp -r ngx-lua-images %s" %prefix)
    if os.path.exists("%snginx/conf/conf.d/ngx-lua-images.conf" %prefix):
        local("sudo rm -rf %snginx/conf/conf.d/ngx-lua-images.conf" %prefix)
    local("sudo ln -s  %sngx-lua-images/ngx-lua-images.conf %snginx/conf/conf.d/ngx-lua-images.conf" %(prefix, prefix))

    # with cd('/usr/local/openresty/nginx/conf/conf.d/'):
    #     run('sudo ln -s  /usr/local/openresty/ngx-lua-images/ngx-lua-images.conf ngx-lua-images.conf')


def restart():
    print(green("nginx restarting..."))
    # run('/etc/init.d/nginx restart')
    local('sudo systemctl restart nginx')

def update():
    put_conf_file()

    restart()

    pass
if __name__ == '__main__':
    pass