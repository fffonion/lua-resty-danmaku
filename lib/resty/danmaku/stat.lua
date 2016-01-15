local _M = {}

function _M._get_stat()
    local ret = '[Total subscriber]\n' ..
    'Create: '.. tostring(ngx.shared.dmk:get('sub_cnt_create')) .. '\n' ..
    'Destory: '.. tostring(ngx.shared.dmk:get('sub_cnt_destory')) .. '\n' ..
    '[Total broadcaster]\n' ..
    'Create: '.. tostring(ngx.shared.dmk:get('brd_cnt_create')) .. '\n' ..
    'Destory: '.. tostring(ngx.shared.dmk:get('brd_cnt_destory')) .. '\n' ..
    '[Total danmaku]\n' ..
    'Total: ' .. tostring(ngx.shared.dmk:get('dm_cnt_all')) .. '\n' ..
    '[Live rooms]\n'
    
    if ngx.shared['dmk_instances'] == nil then
        ret = ret .. "-- no rooms"
        -- return ret
    end

    for k, _ in pairs(ngx.shared['dmk_instances']) do
       local iterator, err = ngx.re.gmatch(k, "broadcaster_(%d+)")
       if iterator then
           local liveid, err = iterator()
           if liveid then
               ret = ret .. "Room=" .. tostring(liveid) .. " Subscribers=" .. 
                tostring(#ngx.shared.dmk:get('broadcaster_' .. tostring(liveid)).subscribers)
               if v.dying > 0 then
                   ret = ret .. " Dying=" .. tostring(v.dying) ..
                    "(" .. tostring(v.dying - os.time())
               end
           end
        end
     end
     return ret
end

function _M._sub_create()
    if ngx.shared.dmk:get('sub_cnt_create') == nil then
        ngx.shared.dmk:set('sub_cnt_create', 1)
    else
        ngx.shared.dmk:incr('sub_cnt_create', 1)
    end
end

function _M._sub_destory()
    if ngx.shared.dmk:get('sub_cnt_destory') == nil then
        ngx.shared.dmk:set('sub_cnt_destory', 1 )
    else
        ngx.shared.dmk:incr('sub_cnt_destory', 1)
    end 
end


function _M._brd_create()
    if ngx.shared.dmk:get('brd_cnt_create') == nil then
        ngx.shared.dmk:set('brd_cnt_create', 1)
    else
        ngx.shared.dmk:incr('brd_cnt_create', 1)
    end 
end

function _M._brd_destory()
    if ngx.shared.dmk:get('brd_cnt_destory') == nil then
        ngx.shared.dmk:set('brd_cnt_destory', 1)
    else
        ngx.shared.dmk:incr('brd_cnt_destory', -1)
    end 
end

function _M._sent_dm()
    if ngx.shared.dmk:get('dm_cnt_all') == nil then
        ngx.shared.dmk:set('dm_cnt_all', 1) 
    else
        ngx.shared.dmk:incr('dm_cnt_all', 1) 
    end 
end   

return _M
