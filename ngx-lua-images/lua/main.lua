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

local function response_and_recache_ceph(bucket, file)
    local cephs3 = require("cephs3")
    local app = cephs3:new(config.access_key, config.secret_key)
    local data = app:get_obj(bucket, file)
    ngx.header["Content-Type"] = "image/jpeg"
    ngx.print(data)
    ngx.flush(true)
    ngx.eof() -- 即时关闭连接，把数据返回给终端，后面的操作还会运行
    key = bucket .. file
    cache.save_img(key, data)

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

end

local function response_from_ceph(bucket, file, cut_name, w, h, g, x, y, r, p, q, f)
    local cephs3 = require("cephs3")
    local app = cephs3:new(config.access_key, config.secret_key)
    if app:check_for_existance(bucket, file) then
        local data = app:get_obj(bucket, file)
        if not data then
            common.forbidden("orgin image is not found...")
        end

        if is_orgin then
            response_and_recache_ceph(bucket, file)
        else
            -- 生成切图文件
            local data = createimg.create_cut_image_ceph(data, bucket, file, cut_name, w, h, g, x, y, r, p, q, f)
            -- if pcall(createimg.create_cut_image_ceph,data, bucket, file, cut_name, w, h, g, x, y, r, p, q, f) then
            --     -- ngx.print("error")
            --     ngx.exec(ngx.var.request_uri)
            -- else
            --     common.error("maybe is not a image file..")
            -- end
            if data then
                ngx.print(data)
            else
                common.forbidden("maybe is not a image file..")
            end
        end
    else
        -- 原始文件不存在
        common.not_found()
    end
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


    local is_orgin = not common.is_null_table(ngx.req.get_uri_args())

    local requesturi = string.gsub(ngx.var.request_uri,"?.*","")

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

    if config.ceph_mode then

        local start = string.find(requesturi, "/",2)
        if not start then
            common.not_found()
        end

        local bucket = string.sub(requesturi, 2, start - 1)
        local file = string.sub(requesturi, start + 1)
        local key = bucket .. '_' .. file .. '_' .. cut_name
        ngx.log(ngx.INFO, "cut_name: ", key)
        local data = cache.get_img(key)
        if data then
            ngx.status = 304
            ngx.header["Content-Type"] = "image/jpeg"
            ngx.print(data)
            ngx.exit(304)
        else
            response_from_ceph(bucket, file, cut_name, w, h, g, x, y, r, p, q, f)
        end
    else
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

        local data = cache.get_img(key)
        if data then
            ngx.header["Content-Type"] = "image/jpeg"
            ngx.print(data)
            -- ngx.status = 304
            -- ngx.exit(304)
        else
            response_from_file(md5, path_prefix, file_path, cut_name, w, h, g, x, y, r, p, q, f)
        end
    end



end

return _M