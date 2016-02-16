-- subscriber implementaion
local util = require "resty.danmaku.util"
local stat = require "resty.danmaku.stat"
local ws_server = require "resty.websocket.server"

local _M = util.new_tab(0, 13)
local mt = { __index = _M }

function _M.new(self, opts)
    local uid = util.random_str(16)
    local wb, err = ws_server:new{
        timeout = ngx.var.keep_alive_timeout or 60000,  -- in milliseconds
        max_payload_len = 65535,
    }
    
    local semaphore = require "ngx.semaphore"
    local queue_sema = semaphore.new()

    ngx.log(ngx.NOTICE, "initializing new subscriber ", uid)
    
    if not wb then
        ngx.log(ngx.ERR, "failed to new websocket: ", err)
        return ngx.exit(444)
    end
    
    local _ = setmetatable({
        wb = wb,
        uid = uid,
        msg_queue = {},
        name = opts.name or uid,
        liveid = opts.liveid,
        closed = false,
        queue_sema = queue_sema,
        _broadcaster = util.get_broadcaster(opts.liveid)
    }, mt)
    
    util.set_subscriber(uid, _)
    _._broadcaster:add_subscriber(uid)

    stat._sub_create()
    return _
end

function _M.recv_loop(self)
    while not self.closed do
        -- check broadcast changed or not (after nginx process reload)
        if self._broadcaster.gid ~= util.get_broadcaster_gid(self.liveid) then
            ngx.log(ngx.ERR, self.uid, ": my broadcaster changed!", self._broadcaster.gid, " != ", util.get_broadcaster_gid(self.liveid))
            break
        end

        -- the following is partly based on resty.websocket example    
        local data, typ, err = self.wb:recv_frame()
        
        if not data or err or typ == "close" then
            break
        end

        if typ == "ping" then
            -- send a pong frame back:

            local bytes, err = self.wb:send_pong(data)
            if not bytes then
                    ngx.log(ngx.ERR, "[danmaku] failed to send frame: ", err)
                    return
            end
        elseif typ == "pong" then
            -- just discard the incoming pong frame

        else
            local json = require "cjson"
            data = json.decode(data)
            -- ngx.log(ngx.ERR, "type=", data["type"])
            if data["type"] ~= "heartbeat" then
                _M.broadcast(self, data)
                stat._sent_dm()
            end
            -- ngx.sleep(120)
            -- ngx.log(ngx.ERR, "received a frame of type ", typ, " and payload ", data)
        end

        --[[
        if not bytes then
            ngx.log(ngx.ERR, "failed to send a text frame: ", err)
            return ngx.exit(444)
        end

        bytes, err = self.wb:send_binary("blah blah blah...")
        if not bytes then
            ngx.log(ngx.ERR, "failed to send a binary frame: ", err)
            return ngx.exit(444)
        end
        ]]
    end

    ngx.log(ngx.WARN, "closing ", self.uid, " in room ", self.liveid)
    
    self.closed = true
    self._broadcaster:del_subscriber(self.uid)
    
    stat._sub_destory()

    local bytes, err = self.wb:send_close(1000, "bye")
    if not bytes then
        ngx.log(ngx.ERR, "[danmaku] failed to send the close frame: ", err)
        return
    end

end

function _M.send_loop(self)
    -- send meta on start
    _M.push(self, "0", self._broadcaster:get_meta())
    while not self.closed do
        self.queue_sema:wait(5)
        for k, v in pairs(self.msg_queue) do
            self.wb:send_text(v)
            self.msg_queue[k] = nil
        end
    end
end

function _M.broadcast(self, tb) 
    local br = util.get_broadcaster(self.liveid)
    local json = require("cjson")
    tb.uid = self.uid
    tb.msgid = util.random_str(16)
    tb.name = self.name
    local br = util.get_broadcaster(self.liveid)
    if br then
        return br:queue_msg(json.encode(tb))
    else
        return nil
    end
end

function _M.push(self, msgid, dt)
    if self.queue_sema:count() < 1 then -- leave 1 spare resource
        self.queue_sema:post()
    end
    self.msg_queue[msgid] = dt
end


return _M
