
local _M = { _VERSION = '0.01' }

_M.shm_key = "dmk"
_M.shared = {}

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

_M.new_tab = new_tab

function _M.random_str(l, seed)
    local s = 'abcdefghijklmnhopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
 
    local ret ='' 
        -- os.time() is precise to second
        math.randomseed(ngx.now() * 1000 + ngx.crc32_short(seed or ""))
    for i=1 ,l do
        local pos = math.random(1, string.len(s))
        ret = ret .. string.sub(s, pos, pos)
    end 
 
    return ret 
end

function _M.get_broadcaster(liveid)
    -- ngx.log(ngx.ERR, "get_bro ->", liveid, "<-", tostring(_M.shared['broadcaster_' .. liveid]))
    return _M.shared['broadcaster_' .. liveid]
end

function _M.set_broadcaster(liveid, tb)
    _M.shared['broadcaster_' .. liveid] = tb
end

function _M.get_broadcaster_gid(liveid)
    local rds = _M.get_redis()
    local rt = rds:get("broadcaster_gid_" .. liveid)
    _M.close_redis(rds)
    return rt
end

function _M.set_broadcaster_gid(liveid, v)
    local rds = _M.get_redis()
    local rt = rds:set("broadcaster_gid_" .. liveid, v)
    _M.close_redis(rds)
    return rt
    
end

function _M.get_subscriber(uid)
    return _M.shared['subscriber_' .. uid]
end

function _M.set_subscriber(uid, tb)
    _M.shared['subscriber_' .. uid] = tb
end

function _M.get_redis()
        local redis = require "resty.redis"
        local rds, err = redis:new()
        if not rds then
            ngx.log(ngx.ERR, "[LI] failed to instantiate redis: ", err)
            return nil
        end
        rds:set_timeout(1000) -- 1 sec
        local ok, err = rds:connect("127.0.0.1", 6379)
        if not ok then
            ngx.log(ngx.ERR, "[LI] failed to connect: ", err)
            return nil
        end
        return rds
end

function _M.close_redis(rds)
    local ok, err = rds:set_keepalive(10000, 10)
    if ok == nil then
        rds:close()
    end
end

return _M
