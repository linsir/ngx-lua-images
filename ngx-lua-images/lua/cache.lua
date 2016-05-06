local redis = require "redis"

local _M = {}
_M._VERSION = '0.01'


function _M.save_img(key, data)
    local red = redis:new()

    local ok, err = red:set(key, data)
    if not ok then
        ngx.log(ngx.ERR, "failed to set key: ", key, " ", err)
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
        ngx.log(ngx.ERR, "failed to get key: ", key, " ", err)
        return false
    end
    ngx.log(ngx.INFO, "get image ", key, " from redis..")
    return ok

end

-- _M['save_img'] = save_img
-- _M['get_img'] = get_img

return _M