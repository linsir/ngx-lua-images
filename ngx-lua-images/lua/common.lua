
local _M = {}
_M._VERSION = '0.01'

function _M.is_null_table(table)
    if next(table) ~=nil then
        return true
    else
        return false
    end
end

-- 文件是否存在
function _M.file_exists(path)
    local f = io.open(path, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

-- 检测目录是否存在
function _M.dir_exists(path)
    if type(path) ~= "string" then return false end

    local response = os.execute("cd " .. path)
    if response == 0 then
        return true
    end
    return false
end

-- 创建目录
function _M.mk_dirs(path)
    local mkdir_command ="mkdir "..path.." -p >/dev/null 2>&1 "
    os.execute(mkdir_command)

end

local function prefix_addr(str)
    if type(str) ~= "string" or #str ~= 3 then
        return false
    end
    local slot = tonumber(str, 16) + 1
    slot = math.modf(slot / 4)

    return slot
end

function _M.get_full_dir(md5)
    if type(md5) ~= "string" or #md5 ~= 32 then
        return false
    end
    local lvl1 = string.sub(md5, 1, 3)
    local lvl2 = string.sub(md5, 4, 6)
    local first_addr = prefix_addr(lvl1)
    local second_addr = prefix_addr(lvl2)
    local images_dir = config.images_dir
    local full_path = string.format("%s%d/%d/%s/", images_dir, first_addr, second_addr, md5)
    return full_path

end

function _M.not_found(file)
    ngx.status = 404
    ngx.say("Opps, file not found.: ", file)
    ngx.exit(404)
end

function _M.forbidden(info)
    ngx.status = 403
    ngx.say("Opps, ", info)
    ngx.exit(403)
end

-- _M['is_null_table'] = is_null_table
-- _M['get_tag_value'] = get_tag_value
-- _M['file_exists'] = file_exists
-- _M['dir_exists'] = dir_exists
-- _M['mk_dirs'] = mk_dirs
-- _M['get_full_dir'] = get_full_dir
-- _M['prefix_addr'] = prefix_addr

return _M