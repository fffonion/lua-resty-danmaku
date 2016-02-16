-- broadcaster implementaion
local util = require "resty.danmaku.util"
local stat = require "resty.danmaku.stat"
local ws_server = require "resty.websocket.server"

local _M = util.new_tab(0, 13)
local mt = { __index = _M }

-- wake in local wake_time = 5
local WAKE_TIME = 5

function _M.new(self, opts)
    local semaphore = require "ngx.semaphore"

    local _ = setmetatable({
        subscribers = {},
        liveid = opts.liveid,
        message_queue = {},
        queue_sema = semaphore.new(),
        dying = 0,
        subs_count = 0,
        gid = util.random_str(16),
        last_sent_meta = 0
    }, mt)
    
    util.set_broadcaster(opts.liveid, _)
    util.set_broadcaster_gid(opts.liveid, _.gid)
    stat._brd_create()
    
    return _
end

function _M.run(self)
    self.dying = 0
    self.last_sent_meta = ngx.time()
    while self.subs_count > 0 or self.dying == 0 or self.dying > os.time() do
        if self.subs_count == 0 and self.dying == 0 then
            -- set up countdown in 60s
            self.dying = os.time() + 60
            ngx.log(ngx.NOTICE, "broadcaster will exit in 60s if no one enters, liveid ", self.liveid)
            --elseif dying < os.time() then
            --    break
        end
        -- wait on semaphore with at least 1s
        self.queue_sema:wait(WAKE_TIME)
        -- time.sleep(1)
        -- copy to temp table 
        local deleted = {}
        for msgid, msg in pairs(self.message_queue) do
            deleted[msgid] = msg
            self.message_queue[msgid] = nil
        end
        -- determine if should send meta
        local meta, metaid
        if ngx.time() - self.last_sent_meta > WAKE_TIME * 3 then
            meta, meta_id = _M.get_meta(self)
            ngx.log(ngx.NOTICE, "will send meta, room ", self.liveid, ", msg ", meta, ", msgid ", meta_id)
            self.last_sent_meta = ngx.time()
        end
        for uid, _ in pairs(self.subscribers) do
            local _sb = util.get_subscriber(uid)
            for msgid, msg in pairs(deleted) do
                -- if uid == msg.uid then continue end
                ngx.log(ngx.NOTICE, "send ", msg, " to ", uid, _, "---", tostring(_sb))
                _sb:push(msgid, msg)
            end
            if meta_id then
                _sb:push(meta_id, meta)
            end

        end
    end
    stat._brd_destory()
    _M.cleanup(self)
end

function _M.queue_msg(self, dt)
    local _ = util.random_str(32)
    self.message_queue[_] = dt
    self.queue_sema:post()
end


function _M.get_meta(self, pure)
     local json = require("cjson")
     local msgid = util.random_str(16)
     local rds = util.get_redis()
     local _r1, err = rds:get("onair_" .. self.liveid)
     local _r2, err = rds:hmget("live_" .. self.liveid, "title", "owner")
     local tb = {
        ["type"] = "meta",
        ["msgid"] = msgid,
        ["meta"] = {
            ["audience"] = self.subs_count,
            ["title"] = _r2[1],
            ["onair"] = _r1,
            ["owner"] = _r2[2]
        }
        }
     util.close_redis(rds)
     if pure then
         return json.encode(tb.meta)
     else
         return json.encode(tb), msgid
     end
end

function _M.add_subscriber(self, uid)
    if self.subscribers ~= nil then
        self.dying = 0
        self.subscribers[uid] = 1
    end
    self.subs_count = self.subs_count + 1
    ngx.log(ngx.NOTICE, "added new subscriber ", uid, " now total ", self.subs_count)
    -- self.last_sent_meta = time.time()
    self.queue_sema:post()
end


function _M.del_subscriber(self, uid)
    if self.subscribers ~= nil then
        self.subscribers[uid] = nil
    end
    self.subs_count = self.subs_count - 1
    ngx.log(ngx.NOTICE, "del subscriber ", uid, " now total ", self.subs_count)
    -- self.last_sent_meta = 0
    self.queue_sema:post()
end


function _M.cleanup(self)
    util.set_broadcaster(self.liveid, nil)
    self.semaphore = nil
    self.message_queue = nil
    self.subscribers = nil
    ngx.log(ngx.WARN, "broadcaster auto exit, id", self.liveid)
end

return _M
