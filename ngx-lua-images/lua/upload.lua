local upload = require "resty.upload"
local cjson = require "cjson"
local resty_md5 = require "resty.md5"
local common = require "common"


local chunk_size = 8192 -- should be set to 4096 or 8192
                     -- for real-world settings

local form = upload:new(chunk_size)
local data = ""

form:set_timeout(1000) -- 1 sec

local md5 = resty_md5:new()

if not md5 then
    ngx.say("failed to create md5 object")
    return
end

local flag = nil
local hash_path = nil
while true do
    local typ, res, err = form:read()
    if not typ then
        ngx.say("failed to read: ", err)
        return
    end

    -- local typ, res, err = form:read()

    if typ == "header" then
        -- ngx.say("header: ", #res, res[1], cjson.encode(res))

        if res[2] == 'form-data; name="md5"' then
            flag = 'md5'
            -- ngx.say("md5_header")
            -- ngx.say(flag)

        end

        if res[1] == 'Content-Type' then
            flag = 'data'
            local path = hash_path .. "default"
            file = io.open(path, "w+")
            -- ngx.say(cjson.encode(res))
            -- ngx.say("img_header")
        end

    elseif typ == "body" then
        -- ngx.say("body: ", cjson.encode(res))
        -- ngx.say("flag: ", flag)
        if flag == "md5" then
            md5_key = res
            ngx.say("md5_key: ", md5_key)
            hash_path = common.get_full_dir(md5_key)
            if common.dir_exists(hash_path) then
                ngx.say(hash_path, ' is exsit..')
            else
                common.mk_dirs(hash_path)
                ngx.say("create ",hash_path, " ok ..")
            end
            flag = nil
        elseif flag == "data" then
            -- ngx.say("update img data..")
            local ok = md5:update(res)
            if file then
                file:write(res)
            end

        else

        end
    elseif typ == "part_end" then
        if flag == 'data' then
            local digest = md5:final()

            local str = require "resty.string"
            local md5str = str.to_hex(digest)
            ngx.say("md5str: ", md5str)
            if file then
                file:close()
                file = nil
            end
            file = nil
            md5:reset()
        end
    else
        if typ == "eof" then
            break
        end

    end
    if typ == "eof" then
        break
    end
end




