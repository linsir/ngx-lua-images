
local _M = {}
_M._VERSION = '0.01'

local gm = require 'graphicsmagick'
local cjson = require 'json'
local common = require "common"

local function get_info(file)

    info = gm.info(file)
    local x = cjson.encode(info)
    -- ngx.log(ngx.INFO, "info: ", info)
    return x
end

function _M.run()

    local md5 =  tostring(ngx.var.arg_md5)
    local path_prefix = common.get_full_dir(md5)
    local default_file =  string.format("%sdefault", path_prefix)

    ngx.log(ngx.INFO, "md5: ", md5)
    if common.file_exists(default_file) then
        local data = get_info(default_file)
        ngx.header["Content-Type"] = "application/json"
        ngx.print(data)

    else
        common.not_found(default_file)
    end

end



return _M