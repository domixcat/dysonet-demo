local tcp = require "svr.c.tcp"
local skynet = require "skynet"

skynet.start(function()
	skynet.error("Client start")

	tcp.start("127.0.0.1", 12345)
	--skynet.exit()
end)
