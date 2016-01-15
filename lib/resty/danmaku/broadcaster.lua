-- broadcaster implementaion
local util = require "resty.danmaku.util"
local stat = require "resty.danmaku.stat"
local ws_server = require "resty.websocket.server"

local _M = util.new_tab(0, 13)
local mt = { __index = _M }


function _M.new(self, opts)
	local semaphore = require "ngx.semaphore"
	
	local _ = setmetatable({
            subscribers = {},
            liveid = opts.liveid,
            message_queue = {},
            queue_sema = semaphore.new(),
            dying = 0,
            subs_count = 0
    }, mt)
	
	util.set_broadcaster(opts.liveid, _)
        stat._brd_create()
	
	return _
end

function _M.run(self)
	self.dying = 0
	while self.subs_count > 0 or self.dying == 0 or self.dying > os.time() do
		if self.subs_count == 0 and self.dying == 0 then
			-- set up countdown in 60s
			self.dying = os.time() + 60
			ngx.log(ngx.NOTICE, "broadcaster will exit in 60s if no one enters, liveid ", self.liveid)
			--elseif dying < os.time() then
			--	break
		end
		-- wait on semaphore with at least 1s
		self.queue_sema:wait(5)
		--time.sleep(1)
		for msgid, msg in pairs(self.message_queue) do
			for uid, _ in pairs(self.subscribers) do
                                 -- if uid == msg.uid then continue end
				 ngx.log(ngx.NOTICE, "send ", msg, " to ", uid, _, "---", tostring(util.get_subscriber(uid)))
				 util.get_subscriber(uid):push(msgid, msg)
			end
			self.message_queue[msgid] = nil
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


function _M.add_subscriber(self, uid)
    if self.subscribers ~= nil then
            self.dying = 0
            self.subscribers[uid] = 1
    end
    self.subs_count = self.subs_count + 1
    ngx.log(ngx.NOTICE, "added new subscriber ", uid, " now total ", self.subs_count)
end


function _M.del_subscriber(self, uid)
    if self.subscribers ~= nil then
        self.subscribers[uid] = nil
    end
    self.subs_count = self.subs_count - 1
    ngx.log(ngx.NOTICE, "del subscriber ", uid, " now total ", self.subs_count)
end


function _M.cleanup(self)
	util.set_broadcaster(self.liveid, nil)
	self.semaphore = nil
	self.message_queue = nil
        self.subscribers = nil
	ngx.log(ngx.WARN, "broadcaster auto exit, id", self.liveid)
end

return _M
