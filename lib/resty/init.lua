local subscriber = require "resty.danmaku.subscriber"
local boradcaster = require "resty.danmaku.broadcaster"
local util = require "resty.danmaku.util"

local _M = util.new_tab(0, 3)
local mt = { __index = _M }

function _M.run()
	ngx.log(ngx.ERR, "new!!!!")

	local liveid = tonumber(ngx.var.liveid)
	if not liveid then
		ngx.exit(444)
	end
	-- check if broadcast is running
	local br = util.get_broadcaster(liveid)
	if not br then
		-- initialize new broadcaster instance
		ngx.log(ngx.ERR, "initializing new broadcaster ", liveid)
		br = boradcaster:new({liveid = liveid})
		ngx.thread.spawn(br.run, br)
	end
        
        local sb = subscriber:new({liveid = liveid})
	-- run subscriber, this will not exit until connection closed
	ngx.thread.spawn(sb.send_loop, sb)
        ngx.thread.spawn(sb.recv_loop, sb)
	-- connection closed here, remove from subscriber list

end

return _M
