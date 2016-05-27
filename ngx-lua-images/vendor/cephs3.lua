-- A simple Lua wrapper for ceph with s3.


-- local http = require"resty.http"
local cjson = require "cjson"
local hmac = require "resty.hmac"
local os = require "os"

config = {
    host = 'http://192.168.2.99',
    access_key = 'HXKJ2FLL7BAWENBMP0HF',
    secret_key = 'DEeFyCPlBKK2vS7DPJDeeozNiF5WAjL7pVMNpDlO',

}

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end


local _M = new_tab(0, 155)
_M._VERSION = '0.01'


local mt = { __index = _M }

function _M.new(self, id, key)
    local id, key = id, key

    if not id then
        return nil, "must provide id"
    end
    if not key then
        return nil, "must provide key"
    end
    local url = "/proxy"
    local res = ngx.location.capture("/proxy/",
            { method = ngx.HTTP_GET,
            })
    -- ngx.log(ngx.ERR, "connect to ceph gateway： ", res.status)
    if res.status == 504 then
        ngx.status = 504
        ngx.header["Content-Type"] = "text/plain"
        ngx.say("Opps, can not connect to ceph gateway.")
        ngx.exit(504)
    end
    return setmetatable({ id = id, key = key, base_url = url }, mt)
end

function _M.generate_auth_headers(self, method, destination, content_type)

    if not self.id or not self.key then
        return nil, "not initialized"
    end

    if content_type == nil then
        content_type = ''
    end

    local timestamp = os.date("!%a, %d %b %Y %H:%M:%S +0000")

    local hm, err = hmac:new(self.key)
    local StringToSign = method..string.char(10)..string.char(10)..content_type..string.char(10)..timestamp..string.char(10)..destination

    headerstr, err = hm:generate_headers("AWS", self.id, "sha1", StringToSign)
    signed = headerstr["auth"]

    -- headers = {}
    -- headers['Authorization'] = signed
    -- headers['Content-Type'] = content_type
    -- headers['Date'] = timestamp

    -- ngx.say(timestamp, cjson.encode(headers))
    return headerstr
end

function _M.get_all_buckets(self)
    local destination = "/"
    local url = self.base_url .. destination
    -- local url = "http://httpbin.org/get"
    headers = self:generate_auth_headers("GET", destination)
    -- ngx.say(headers)
    local retry = 0
    while (not res or res.status ~= 200) and retry < 2 do
        res = ngx.location.capture(url,
            { method = ngx.HTTP_GET,
              -- body = content,
              args = {date=headers.date, auth=headers.auth, file=destination}}
        )
        retry = retry + 1
    end
    if not res then
      ngx.log(ngx.ERR, "failed to get_all_objs: ", destination, ": ", err)
      return
    end

    ngx.header["Content-Type"] = "application/xml; charset=UTF-8"
    ngx.say(res.body)
    return res.body
end
function _M.get_all_objs(self, bucket)

    local destination = "/" .. bucket
    local url = self.base_url .. destination
    -- local url = "http://httpbin.org/get"
    headers = self:generate_auth_headers("GET", destination)
    local res = ngx.location.capture(url,
            { method = ngx.HTTP_GET,
              -- body = content,
              args = {date=headers.date, auth=headers.auth, file=destination}}
        )
    if not res then
      ngx.log(ngx.ERR, "failed to get_all_objs: ", destination, ": ", err)
      return
    end

    ngx.header["Content-Type"] = "application/xml; charset=UTF-8"
    ngx.say(res.body)
    return res.body

end
function _M.create_obj(self, bucket, file, content)
    local destination = "/" .. bucket .. "/" .. file
    local url = self.base_url .. destination
    -- ngx.say(url)
    -- local url ="http://httpbin.org/put"
    headers = self:generate_auth_headers("PUT", destination)
    local res = ngx.location.capture(url,
            { method = ngx.HTTP_PUT,
              body = content,
              args = {date=headers.date, auth=headers.auth, file=destination}}
        )
    if not res then
      ngx.log(ngx.ERR, "failed to create_obj: ", destination, ": ", err)
      return
    end
    -- ngx.say(res.body)
    return ngx.var.host .. destination
end

function _M.get_obj(self, bucket, file)
    local destination = "/" .. bucket .. "/" .. file
    local url = self.base_url .. destination
    headers = self:generate_auth_headers("GET", destination)

    local res = ngx.location.capture(url,
            { method = ngx.HTTP_GET,
              body = content,
              args = {date=headers.date, auth=headers.auth, file=destination}}
        )
    if not res then
      ngx.log(ngx.ERR, "failed to get_obj: ", destination, ": ", err)
      return
    end
    if res.status == 404 then
        ngx.status = 404
        ngx.header["Content-Type"] = "text/plain"
        ngx.say("Opps, file not found.")
        ngx.exit(404)
    end
    return res.body
end

function _M.check_for_existance(self, bucket, file)
    local destination = "/" .. bucket .. "/" .. file
    local url = self.base_url .. destination
    headers = self:generate_auth_headers("HEAD", destination)

    local res = ngx.location.capture(url,
            { method = ngx.HTTP_HEAD,
              body = content,
              args = {date=headers.date, auth=headers.auth, file=destination}}
        )
    if not res then
      ngx.log(ngx.ERR, "failed to check_for_existance: ", destination, ": ", err)
      return false
    end
    if res.status == 200 then
        return true
    else
        ngx.log(ngx.ERR, "failed to connet to ceph gateway : ", res.body)
        return false
    end
end

function _M.del_obj(self, bucket, file)
    local destination = "/" .. bucket .. "/" .. file
    local url = self.base_url .. destination
    headers = self:generate_auth_headers("DELETE", destination)
    local res = ngx.location.capture(url,
            { method = ngx.HTTP_DELETE,
              body = content,
              args = {date=headers.date, auth=headers.auth, file=destination}}
        )
    if not res then
      ngx.log(ngx.ERR, "failed to del_obj: ", destination, ": ", err)
      return
    end

    return "Delete Sucess."
end

function _M.create_bucket(self, bucket)
    local destination = "/" .. bucket
    local url = self.base_url .. destination
    -- local url = "http://httpbin.org/put"
    headers = self:generate_auth_headers("PUT", destination)
    -- headers['x-amz-acl'] = 'public-read'
    local res = ngx.location.capture(url,
            { method = ngx.HTTP_PUT,
              body = content,
              args = {date=headers.date, auth=headers.auth, file=destination}}
        )
    if not res then
      ngx.log(ngx.ERR, "failed to create_bucket: ", destination, ": ", err)
      return
    end
    return "Create bucket Sucess."


end

function _M.del_bucket(self, bucket)
    local destination = "/" .. bucket
    local url = self.base_url .. destination
    headers = self:generate_auth_headers("DELETE", destination)
    local res = ngx.location.capture(url,
            { method = ngx.HTTP_DELETE,
              body = content,
              args = {date=headers.date, auth=headers.auth, file=destination}}
        )
    if not res then
      ngx.log(ngx.ERR, "failed to del_bucket: ", destination, ": ", err)
      return
    end
    if res.status == 404 then
        ngx.status = 404
        ngx.header["Content-Type"] = "text/plain"
        ngx.say("Opps, bucket not found.")
        ngx.exit(404)
    end
    return "Delete Sucess."
end

return _M
