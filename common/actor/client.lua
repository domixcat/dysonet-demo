--- client actor
-- eg.:
--  skynet.send(addr, "lua", "client", "onMessage", "C2S_Task_Finish", ...)

local skynet = require "skynet"

local Client = Class("Client")
function Client:__ctor()
    self.tcpGate = false
    self.links = {}
    self.closeCallback = nil
    self.apiobj = nil
end

function Client:open(apiobj)
    assert(type(apiobj) == "table")
    self.apiobj = apiobj
    self.apiobj:Init()
    -- gate service
    self.tcpGate = assert(skynet.newservice("gate_tcp"))

    -- open gate
    local gateConf = {
        port = tonumber(skynet.getenv("tcp_port")),
        slaveNum = tonumber(skynet.getenv("gate_slave_num")),
        watchdog = skynet.self()
    }
    skynet.call(self.tcpGate, "lua", "open", gateConf)
end

--- 消息派发处理
function Client:dispatch(session, source, cmd, ...)
    local func = self[cmd]
    assert(func, cmd)
    return func(self, ...)
end

function Client:_sendToLink(fd, cmd, ...)
    local link = self:getLink(fd)
    if link then
        skynet.send(link.gateAddr, "lua", cmd, fd, ...)
    end
end

function Client:newLink(fd, addr, gateNode, gateAddr)
    local linkobj = {
        pid = 0,
        fd = assert(fd),
        addr = assert(addr),
        gateNode = assert(gateNode),
        gateAddr = assert(gateAddr),
    }
    return linkobj
end

function Client:delLink(fd)
    local link = self.links[fd]
    if link then
        self.links[fd] = nil
    end
    return link
end

function Client:closeLink(fd)
    self:_sendToLink(fd, "close")
    self:delLink(fd)
end

--- onXXX
function Client:onConnect(fd, addr, gateNode, gateAddr)
    local link = self:newLink(fd, addr, gateNode, gateAddr)
    self.links[fd] = link
end

function Client:onMessage(fd, opname, args)
    local link = self:getLink(fd)
    if link then
        return
    end

    local opfunc = self.apiobj[opname]
    if opfunc then
        opfunc(self.apiobj, link, args)
    end
end

function Client:onClose(fd, reason)
    local link = self:delLink(fd)
    if link then
        if self.closeCallback then
            self.closeCallback(link, reason)
        end
    end
end

--- 消息发送处理
function Client:send(fd, opname, args)
    self:_sendToLink(fd, "write", opname, args)
end
