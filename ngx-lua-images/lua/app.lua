local _M = {}

function _M.s3run()

    -- Hashing functions
    local access_key = 'HXKJ2FLL7BAWENBMP0HF'
    local secret_key = 'DEeFyCPlBKK2vS7DPJDeeozNiF5WAjL7pVMNpDlO'
    local encode_base64 = ngx.encode_base64
    local hmac_sha1     = ngx.hmac_sha1
    local md5           = ngx.md5

    local method = 'POST'
    local destination = '/'
    local content_type = ''
    local timestamp = os.date("!%a, %d %b %Y %H:%M:%S +0000")

    local StringToSign = method..string.char(10)..string.char(10)..content_type..string.char(10)..timestamp..string.char(10)..destination

    local signature = encode_base64(hmac_sha1(secret_key, StringToSign))
    signature = 'AWS' .. ' ' .. access_key .. ':' .. signature
    -- ngx.say(signature)
    local hmac = require "resty.hmac"
    local hm, err = hmac:new(secret_key)
    headerstr, err = hm:generate_headers("AWS", access_key, "sha1", StringToSign)
    signed = headerstr["auth"]
    -- ngx.say(signed)

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