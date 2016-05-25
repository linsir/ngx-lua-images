local _M = {}



function _M.go()
    local main = require "main"
    main.run()
end

function _M.run()

    bucket = ngx.var.arg_b
    file = ngx.var.arg_f
    content = ngx.var.arg_c
    del = ngx.var.arg_d

    app = cephswift:new(config.swift_user, config.swift_secret_key)
    -- app:create_bucket(bucket)
    -- app:get_all_objs(bucket)
    if content then
        local url = app:create_obj(bucket, file, content)
        ngx.say(url)
    end

    if file then
        local data = app:get_obj(bucket, file)
        ngx.say(data)
        -- app:del_obj(bucket, file)
    end

    if del == "y" then
        local res = app:del_bucket(bucket)

    end
end

function _M.s3run()

    bucket = ngx.var.arg_b
    file = ngx.var.arg_f
    content = ngx.var.arg_c
    del = ngx.var.arg_d
    create = ngx.var.arg_cr

    local cephs3 = require("cephs3")
    local app = cephs3:new(config.access_key, config.secret_key)

    if (bucket and create ) then
        local data = app:create_bucket(bucket)
        ngx.say(data)
    elseif ((not file) and (not del) and bucket) then
        app:get_all_objs(bucket)

    elseif (file and bucket and content) then
        local url = app:create_obj(bucket, file, content)
        ngx.say(url)
    elseif (bucket and file and del) then
        local data = app:del_obj(bucket, file)
        ngx.say(data)
    elseif ((not file) and bucket and del) then
        local data = app:del_bucket(bucket)
        ngx.say(data)
    elseif (not del and bucket and file) then
        -- local exsite = app:check_for_existance(bucket, file)
        -- ngx.say(exsite)
        local data = app:get_obj(bucket, file)
        ngx.say(data)
    else
        app:get_all_buckets()
    end

end

return _M
