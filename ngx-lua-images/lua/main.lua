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

local common = require "common"
local cache = require "cache"
local createimg = require "createimg"

local allowed_type = {
    "JPG",
    "JPEG",
    "PNG",
    "GIF",
    "BMP"
}

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

local function response_and_recache(md5, path_prefix, cut_name)
    ngx.log(ngx.INFO, "cut img exists and recache...: ",cut_name)
    local file, err = io.open(path_prefix .. cut_name, "r")
    if not file then
        ngx.log(ngx.ERR, "open file error:", err)
        ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
    end

    local data
    ngx.header["Content-Type"] = "image/jpeg"
    while true do
        data = file:read(1024)
        if nil == data then
            break
        end
        ngx.print(data)
        ngx.flush(true)

    end
    ngx.eof() -- 即时关闭连接，把数据返回给终端，后面的操作还会运行
    -- 重新从文件缓存到redis
    file:seek("set", 0)
    data = file:read("*all")
    cache.save_img(md5, data)

    file:close()
end

local function response_from_file(md5, path_prefix, file_path, cut_name, w, h, g, x, y, r, p, q, f)
    -- 原始文件存在
    if common.file_exists(file_path) then
        ngx.log(ngx.INFO, "the orgin file exists: ", md5)
        if is_orgin then
            response_and_recache(md5, path_prefix, 'default')
        end
        local cut_file = path_prefix .. cut_name

        if not common.file_exists(cut_file) then
            -- 切图文件不存在，重新生成
            createimg.create_cut_image(md5, path_prefix, cut_name, w, h, g, x, y, r, p, q, f)

            -- 重写请求参数，再次访问
            ngx.exec(ngx.var.request_uri);
        else
            -- 切图文件存在,返回给 client ，并缓存到redis
            response_and_recache(md5, path_prefix, cut_name)
        end
    else
        -- 原始文件不存在
        common.not_found()
    end
    -- body
end

function _M.run()

    local w = tonumber(ngx.var.arg_w)
    local h = tonumber(ngx.var.arg_h)
    local g = tonumber(ngx.var.arg_g)
    local x = tonumber(ngx.var.arg_x)
    local y = tonumber(ngx.var.arg_y)
    local r = tonumber(ngx.var.arg_r)
    local p = tonumber(ngx.var.arg_p)
    local q = tonumber(ngx.var.arg_q)
    local f = ngx.var.arg_f

    local cut_name = string.format("w%s_h%s_g%s_x%s_y%s_r%s_p%s_q%s_f%s", w, h, g, x, y, r, p, q, f)

    -- ngx.log(ngx.INFO, "cut_name: ", cut_name)

    local is_orgin = not common.is_null_table(ngx.req.get_uri_args())

    local requesturi = string.gsub(ngx.var.request_uri,"?.*","")
    local md5 =  string.gsub(requesturi,"/","")
    local path_prefix = common.get_full_dir(md5)
    local file_path =  string.format("%sdefault", path_prefix)

    -- 简单判断md5是否合法
    if type(md5) ~= "string" or #md5 ~= 32 then
        common.not_found()
    end

    -- 判断是否请求要原图
    local key  =  ''
    if is_orgin then
        key = md5
    else
        key = md5 .. '_' .. cut_name
    end

    -- 判断f是否非法
    if f then
        if not common.in_array(f:upper(), allowed_type) then
            common.forbidden("format is incorrect. ")
        end
    end

    -- 判断参数是否超范围
    if over_range(w) or over_range(h) or over_range(x) or over_range(y) then
        common.forbidden("args over range.")
    end

    local data = cache.get_img(key)
    if data then
        ngx.header["Content-Type"] = "image/jpeg"
        ngx.print(data)
    else
        response_from_file(md5, path_prefix, file_path, cut_name, w, h, g, x, y, r, p, q, f)
    end

end

return _M