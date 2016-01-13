-- broadcaster implementaion
local util = require "resty.danmaku.util"
local ws_server = require "resty.websocket.server"

local _M = util.new_tab(0, 13)
local mt = { __index = _M }


function _M.new(self, opts)
	local subscribers = {}
	local message_queue = {}
	local semaphore = require "ngx.semaphore"
        local queue_sema = semaphore.new()
	
	local _ = setmetatable({
        subscribers = subscribers,
		liveid = opts.liveid,
		message_queue = message_queue,
		queue_sema = queue_sema,
		dying = 0
    }, mt)
	
	util.set_broadcaster(opts.liveid, _)
	
	return _
end

function _M.run(self)
	self.dying = 0
	while #self.subscribers > 0 or self.dying == 0 or self.dying > os.time() do
		if #self.subscribers == 0 and self.dying == 0 then
			-- set up countdown in 60s
			self.dying = os.time() + 60
			ngx.log(ngx.ERR, "broadcaster will exit in 60s if no one enters, liveid ", self.liveid)
			--elseif dying < os.time() then
			--	break
		end
		-- wait on semaphore with at least 1s
		self.queue_sema:wait(5)
		--time.sleep(1)
		for msgid, msg in pairs(self.message_queue) do
			for uid, _ in pairs(self.subscribers) do
                                 -- if uid == msg.uid then continue end
				 ngx.log(ngx.ERR, "send ", msg, " to ", uid, _, "---", tostring(util.get_subscriber(uid)))
				 util.get_subscriber(uid):push(msgid, msg)
			end
			self.message_queue[msgid] = nil
		end
	end
	ngx.log(ngx.ERR, "nooo ", #self.subscribers, ", ", dying)
	_M.cleanup(self)
end

function _M.queue_msg(self, dt)
	local _ = util.random_str(32)
	self.message_queue[_] = dt
	self.queue_sema:post()
end


function _M.add_subscriber(self, uid)
	ngx.log(ngx.ERR, "added new subscriber ", uid)
	if self.subscribers ~= nil then
		self.dying = 0
		self.subscribers[uid] = 1
	end
end


function _M.del_subscriber(self, uid)
	ngx.log(ngx.ERR, "del subscriber ", uid)
	if self.subscribers ~= nil then
		self.subscribers[uid] = nil
	end
end


function _M.cleanup(self)
	util.set_broadcaster(self.liveid, nil)
	self.semaphore = nil
	self.message_queue = nil
	self.subscribers = nil
	ngx.log(ngx.ERR, "broadcaster auto exit, id", self.liveid)
end

return _M
