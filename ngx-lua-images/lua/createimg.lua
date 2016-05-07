-- url: ?w=300&h=300&g=1&x=0&y=0&r=45&q=85&f=jpeg
-- （? + 长 + 宽 + 灰白化 + x + y + 旋转角度 + 压缩比 + 转换格式
-- w: 宽
-- h: 高
-- g: 黑白
-- r: 旋转
-- q: 压缩比
-- f: 格式
local _M = {}
_M._VERSION = '0.01'

local gm = require 'graphicsmagick'
local cache = require "cache"
local common = require "common"

local function over_range(x)
    if not x then
        return false
    end
    if (x > 3000) or (x < 0) then
        return true
    else
        return false
    end
end

function _M.create_cut_image(md5, path_prefix, cut_name, w, h, g, x, y, r, p, q, f)
    local file_path = path_prefix .. cut_name
    img = gm.Image()
    img:load(path_prefix .. "default")
    ngx.log(ngx.INFO, "Loading the default image: ", md5)

    -- size
    if not (x or y) then
        if over_range(w) or over_range(h) then
            common.forbidden("over range.")
        else
            ngx.log(ngx.INFO, "img change: size ", w, 'x', h)
            img:size(w, h)
        end
    else
        -- x or y not nil ,crop image, and must be given both width and height.

        if not (w and h) then
            common.forbidden("you must be give both width and height.")
        end
        local x = x or 0
        local y = y or 0
        if over_range(w) or over_range(h) or over_range(x) or over_range(y) then
            common.forbidden("over range.")
        else
            ngx.log(ngx.INFO, "img change: crop (", x, ", ", y, ") ", w, "x", h)
            img:crop(w, h, x, y)
        end
    end

    -- gray
    if g == 1 then
        img:colorspace('GRAY')
            ngx.log(ngx.INFO, "img change: GRAY ")
    end

    -- rotate
    if r then
        if (-360 < r) and (r < 360) then
            img:rotate(r)
            ngx.log(ngx.INFO, "img change: rotate ", r)
        end
    end

    -- format
    -- if not f then
    --     f = 'jpg'
    -- end

    if f then
        local format = f
        if format == 'JPG' then
            format = 'JPEG'
        end
        ngx.log(ngx.INFO, "img change: format ", format)
        img:format(format)
        -- if  not pcall(format_image, img, format) then
        --     common.forbidden("image format error.")
        -- end
        
    end

    -- quality
    if q then
        if (0 < q) and (q < 100) then
          img:save(file_path, q)
          local key = md5 .. '_' .. cut_name
          local data = img:toString(q)
          cache.save_img(key, data)
        else
          img:save(file_path, 95)
          local key = md5 .. '_' .. cut_name
          local data = img:toString(95)
          cache.save_img(key, data)
        end
    else
        img:save(file_path, 95)
        local key = md5 .. '_' .. cut_name
        local data = img:toString(95)
        ngx.log(ngx.INFO, "create and save new img: ",cut_name)
        cache.save_img(key, data)
    end
end

-- _M['create_cut_image'] = create_cut_image

return _M