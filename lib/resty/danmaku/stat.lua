local util = require "resty.danmaku.util"
local _M = {}

function _M._get_stat()
    local rds = util.get_redis()
    local ret = '[Total subscriber]\n' ..
    'Create: '.. tostring(rds:get('sub_cnt_create')) .. '\n' ..
    'Destory: '.. tostring(rds:get('sub_cnt_destory')) .. '\n' ..
    '[Total broadcaster]\n' ..
    'Create: '.. tostring(rds:get('brd_cnt_create')) .. '\n' ..
    'Destory: '.. tostring(rds:get('brd_cnt_destory')) .. '\n' ..
    '[Total danmaku]\n' ..
    'Total: ' .. tostring(rds:get('dm_cnt_all')) .. '\n' ..
    '[Live rooms]\n'
    util.close_redis(rds)

    if util.shared == nil then
        ret = ret .. "-- no rooms"
        return ret
    end

    for k, _ in pairs(util.shared) do
        local m, err = ngx.re.match(k, "broadcaster_(\\d+)")
        if m then
            local liveid = m[1]
            local b = util.get_broadcaster(liveid)
            ret = ret .. "Room=" .. tostring(liveid) .. " Subscribers=" .. tostring(b.subs_count)
            if b.dying > 0 then
               ret = ret .. " Dying=" .. tostring(b.dying) ..
                "(" .. tostring(b.dying - os.time())
            end
        end
     end
     return ret
end

function _M._sub_create()
    local rds = util.get_redis()
    if rds:get('sub_cnt_create') == nil then
        rds:set('sub_cnt_create', 1)
    else
        rds:incr('sub_cnt_create', 1)
    end
    util.close_redis(rds)
end

function _M._sub_destory()
    local rds = util.get_redis()
    if rds:get('sub_cnt_destory') == nil then
        rds:set('sub_cnt_destory', 1 )
    else
        rds:incr('sub_cnt_destory', 1)
    end 
    util.close_redis(rds)
end


function _M._brd_create()
    local rds = util.get_redis()
    if rds:get('brd_cnt_create') == nil then
        rds:set('brd_cnt_create', 1)
    else
        rds:incr('brd_cnt_create', 1)
    end
    util.close_redis(rds)
end

function _M._brd_destory()
    local rds = util.get_redis()
    if rds:get('brd_cnt_destory') == nil then
        rds:set('brd_cnt_destory', 1)
    else
        rds:incr('brd_cnt_destory', 1)
    end 
    util.close_redis(rds)
end

function _M._sent_dm()
    local rds = util.get_redis()
    if rds:get('dm_cnt_all') == nil then
        rds:set('dm_cnt_all', 1) 
    else
        rds:incr('dm_cnt_all', 1) 
    end
    util.close_redis(rds)
end   

return _M
