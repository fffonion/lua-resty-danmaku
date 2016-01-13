
local _M = { _VERSION = '0.01' }

local ok, new_tab = pcall(require, "table.new")
if not ok then
    new_tab = function (narr, nrec) return {} end
end

_M.new_tab = new_tab

function _M.random_str(l, seed)
    local s = 'abcdefghijklmnhopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
 
    local ret ='' 
        -- os.time() is precise to second
        math.randomseed(ngx.time() * 1000 + ngx.crc32_short(seed or ""))
    for i=1 ,l do
        local pos = math.random(1, string.len(s))
        ret = ret .. string.sub(s, pos, pos)
    end 
 
    return ret 
end

function _M.get_broadcaster(liveid)
    return ngx.shared["dmk_broadcaster_" .. liveid]
end

function _M.set_broadcaster(liveid, tb)
    ngx.shared["dmk_broadcaster_" .. liveid] = tb
end

function _M.get_subscriber(uid)
    return ngx.shared["dmk_subscriber_" .. uid]
end

function _M.set_subscriber(uid, tb)
    ngx.shared["dmk_subscriber_" .. uid] = tb
end

return _M
