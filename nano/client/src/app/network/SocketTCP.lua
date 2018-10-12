local SOCKET_TICK_TIME = 0.1 -- check socket data interval
local SOCKET_CONNECT_FAIL_TIMEOUT = 36000 -- socket failure timeout

local STATUS_CLOSED = "closed"
local STATUS_NOT_CONNECTED = "Socket is not connected"
local STATUS_ALREADY_CONNECTED = "already connected"

local scheduler = require("app.core.scheduler")
local socket = require("socket.core")
local Event = require("cocos.framework.components.event")

local SocketTCP = class("SocketTCP")

SocketTCP.EVENT_DATA = "SOCKET_TCP_DATA"
SocketTCP.EVENT_CLOSE = "SOCKET_TCP_CLOSE"
SocketTCP.EVENT_CLOSED = "SOCKET_TCP_CLOSED"
SocketTCP.EVENT_CONNECTED = "SOCKET_TCP_CONNECTED"
SocketTCP.EVENT_CONNECT_FAILURE = "SOCKET_TCP_CONNECT_FAILURE"

SocketTCP._VERSION = socket._VERSION
SocketTCP._DEBUG = socket._DEBUG

SocketTCP.STATE_DISCONNECT = "disconnect"
SocketTCP.STATE_CONNECTING = "connecting"
SocketTCP.STATE_CONNECTED = "connected"

function SocketTCP.getTime()
    return socket.gettime()
end

function SocketTCP:ctor(__host, __port)
    --cc(self):addComponent("components.behavior.EventProtocol"):exportMethods()
    self.event = Event.new()
    self.event:bind(self)

    self.host = __host
    self.port = __port
    self.tickScheduler = nil -- timer for data
    self.connectTimeTickScheduler = nil -- timer for connect timeout
    self.name = 'SocketTCP'
    self.tcp = nil
    self.isConnected = false
    self.state = SocketTCP.STATE_DISCONNECT
end

function SocketTCP:setName(__name)
    self.name = __name
    return self
end

function SocketTCP:setTickTime(__time)
    SOCKET_TICK_TIME = __time
    return self
end

function SocketTCP:setConnFailTime(__time)
    SOCKET_CONNECT_FAIL_TIMEOUT = __time
    return self
end

function SocketTCP:isSupportIPV6()
    local ipv6 = false
    local addr, err = socket.dns.getaddrinfo(self.host)
    if addr ~= nil then
        for k, v in pairs(addr) do
            if v.family == "inet6" then
                ipv6 = true
                break
            end
        end
    end

    return ipv6
end

function SocketTCP:connect()
    assert(self.host or self.port, "Host and port are necessary!")
    --printInfo("%s.connect(%s, %d)", self.name, self.host, self.port)
    if self.state == SocketTCP.STATE_CONNECTING or self.isConnected then
        return
    end

    self.tcp = socket.tcp()
    self.tcp:settimeout(0)
    self.state = SocketTCP.STATE_CONNECTING
    local function __checkConnect()
        local __succ = self:_connect()
        if __succ then
            self:_onConnected()
        end
        return __succ
    end

    if not __checkConnect() then
        -- check whether connection is success
        -- the connection is failure if socket isn't connected after SOCKET_CONNECT_FAIL_TIMEOUT seconds
        local __connectTimeTick = function()
            --printInfo("%s.connectTimeTick", self.name)
            if self.isConnected then return end
            self.waitConnect = self.waitConnect or 0
            self.waitConnect = self.waitConnect + SOCKET_TICK_TIME
            if self.waitConnect >= SOCKET_CONNECT_FAIL_TIMEOUT then
                self.waitConnect = nil
                self:close()
                self:_connectFailure()
            end
            __checkConnect()
        end
        self.connectTimeTickScheduler = scheduler.scheduleGlobal(__connectTimeTick, SOCKET_TICK_TIME)
    end
end

function SocketTCP:send(__data)
    assert(self.isConnected, self.name .. " is not connected.")
    --printInfo("%s.send", self.name)
    self.tcp:send(__data)
end

function SocketTCP:close(...)
    printInfo("%s.close", self.name)
    if not self.tcp then
        return
    end
    self.tcp:close();
    self.isConnected = false
    self.state = SocketTCP.STATE_DISCONNECT
    if self.connectTimeTickScheduler then scheduler.unscheduleGlobal(self.connectTimeTickScheduler) end
    if self.tickScheduler then scheduler.unscheduleGlobal(self.tickScheduler) end
    self:dispatchEvent({ name = SocketTCP.EVENT_CLOSE })
end

-- disconnect on user's own initiative.
function SocketTCP:disconnect()
    self:_disconnect()
end

--------------------
-- private
--------------------

--- When connect a connected socket server, it will return "already connected"
-- @see : http://lua-users.org/lists/lua-l/2009-10/msg00584.html
function SocketTCP:_connect()
    local __succ, __status = self.tcp:connect(self.host, self.port)
    --printInfo("SocketTCP._connect:%s, %s, %s, %s", self.host, self.port, __succ, __status)
    return __succ == 1 or __status == STATUS_ALREADY_CONNECTED
end

function SocketTCP:_disconnect()
    self.isConnected = false
    self.state = SocketTCP.STATE_DISCONNECT
    self.tcp:shutdown()
    self:dispatchEvent({ name = SocketTCP.EVENT_CLOSED })
end

function SocketTCP:_onDisconnect()
    self.isConnected = false
    self.state = SocketTCP.STATE_DISCONNECT
    self:dispatchEvent({ name = SocketTCP.EVENT_CLOSED })
end

-- connecte success, cancel the connection timerout timer
function SocketTCP:_onConnected()
    printInfo("%s._onConnectd", self.name)
    if self.isConnected then
        return
    end
    self.isConnected = true
    self.state = SocketTCP.STATE_CONNECTED
    self:dispatchEvent({ name = SocketTCP.EVENT_CONNECTED })
    if self.connectTimeTickScheduler then scheduler.unscheduleGlobal(self.connectTimeTickScheduler) end

    local __tick = function()
        while true do
            -- if use "*l" pattern, some buffer will be discarded, why?
            local __body, __status, __partial = self.tcp:receive("*a") -- read the package body
            --print("body:", __body, "__status:", __status, "__partial:", __partial)
            if __status == STATUS_CLOSED or __status == STATUS_NOT_CONNECTED then
                local preStatus = self.isConnected
                self:close()
                if preStatus then
                    self:_onDisconnect()
                else
                    self:_connectFailure()
                end
                return
            end
            if (__body and string.len(__body) == 0) or
                    (__partial and string.len(__partial) == 0) then return
            end
            if __body and __partial then __body = __body .. __partial end
            self:dispatchEvent({ name = SocketTCP.EVENT_DATA, data = (__partial or __body), partial = __partial, body = __body })
        end
    end

    -- start to read TCP data
    self.tickScheduler = scheduler.scheduleGlobal(__tick, SOCKET_TICK_TIME)
end

function SocketTCP:_connectFailure(status)
    self:dispatchEvent({ name = SocketTCP.EVENT_CONNECT_FAILURE })
end

return SocketTCP
