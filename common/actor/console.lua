--- console actor
-- eg.:
--  skynet.send(addr, "lua", "Console", "gm", "addItem", ...)
--  skynet.send(addr, "lua", "Console", "hotfix", "addItem", ...)

local Console = Class("Console")
function Console:__init(apiobj)
    assert(type(apiobj) == "table")
    self.apiobj = apiobj
    self.apiobj:Init()

    self.addr = false
end

function Console:open()
    local skynet = dysonet.skynet
    local debug_port = skynet.getenv("debug_port")
    if debug_port then
        self.addr = assert(skynet.newservice("debug_console", debug_port))

        -- inject
        local debug_console_inject = require "debug_inject"
        debug_console_inject(self.addr)
    end
end

--- 消息派发处理
function Console:dispatch(session, source, cmd, ...)
    local func = self[cmd]
    assert(func, cmd)
    return func(self, ...)
end

function Console:hotfix(...)
    -- 热更配置

    -- 热更协议

    -- 热更代码
end

-- 处理gm命令
function Console:gm(subcmd, ...)
    local handler = self.apiobj[subcmd]
    assert(handler, subcmd)
    if self.apiobj.filter then
        return handler(self.apiobj:filter(...))
    end
    return handler(self.apiobj, ...)
end
