
local _M = { _VERSION = '0.01' }
local shm_key = "dmk"
local shm_ins_key = 'dmk_instance'

_M.shm_key = shm_key
_M.shm_ins_key = shm_ins_key

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

function _init_shared_pool()
    if ngx.shared[shm_ins_key] == nil then
        ngx.shared[shm_ins_key] = {}
    end
end

function _M.get_broadcaster(liveid)
    _init_shared_pool()
    return ngx.shared[shm_ins_key]['broadcaster_' .. liveid]
end

function _M.set_broadcaster(liveid, tb)
    _init_shared_pool()
    ngx.shared[shm_ins_key]['broadcaster_' .. liveid] = tb
end

function _M.get_broadcaster_gid(liveid)
    return ngx.shared[shm_key]:get("broadcaster_gid_" .. liveid)
end

function _M.set_broadcaster_gid(liveid, v)
    return ngx.shared[shm_key]:set("broadcaster_gid_" .. liveid, v)
end

function _M.get_subscriber(uid)
    _init_shared_pool()
    return ngx.shared[shm_ins_key]['subscriber_' .. uid]
end

function _M.set_subscriber(uid, tb)
    _init_shared_pool()
    ngx.shared[shm_ins_key]['subscriber_' .. uid] = tb
end

return _M
