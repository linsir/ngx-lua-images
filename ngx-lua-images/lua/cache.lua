local redis = require "redis"
local common = require "common"
local _M = {}
_M._VERSION = '0.01'


function _M.save_img(key, data)
    local red = redis:new()

    local ok, err = red:set(key, data)
    if not ok then
        ngx.log(ngx.ERR, "failed to set key: ", key, " ", err)
        if err == 'connection refused' then
            common.error("can not connect redis-server ..")
        end
        return false
    end

    local ok, err = red:expire(key, config.timeout)
    if not ok then
        ngx.log(ngx.ERR, "failed to set expire: ", key, " ", err)
        return false
    end
    ngx.log(ngx.INFO, "stor image ", key, " into redis..")
    return true
end

function _M.get_img(key)
    local red = redis:new()
    local ok, err = red:get(key)
    if not ok then
        ngx.log(ngx.INFO, "failed to get key: ", key, " ", err)
        if err == 'connection refused' then
            common.error("can not connect redis-server ..")
        end
        return false
    end
    ngx.log(ngx.INFO, "get image ", key, " from redis..")
    return ok

end


return _M