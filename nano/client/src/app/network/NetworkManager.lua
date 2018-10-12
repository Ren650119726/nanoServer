local WaitUI = require "app.ui.WaitUi"
local NetworkManager = {}
local SocketTCP = require "app.network.SocketTCP"
local scheduler = require("app.core.scheduler")
local TimerSchedulerClass = require "app.core.TimerScheduler"
local Protocol = require("app.starx.Protocol")

-- starx callbacks
local starxRequestCallbacks = {}
local starxPushCallbacks = {}
local connector
local heartbeatInternal = 10
local lastHeartbeatTime = os.time()

--network data encode
local buffer = ccluaext.BinaryStream:create(2048)
buffer:retain()

-- buffer operation
local function writeString(t)
    for i = 1, string.len(t) do
        buffer:writeUInt8(string.byte(t, i))
    end
end

local function writeUInt8(t)
    buffer:writeUInt8(t)
end

local function writeUInt16(t)
    buffer:writeUInt16(t)
end

local function writeMessage(msg)
    local x = string.len(msg)
    local y3 = x % 256
    local x2 = math.floor(x / 256)
    local y2 = x2 % 256
    local x3 = math.floor(x2 / 256)
    local y1 = x3 % 256

    writeUInt8(y1)
    writeUInt8(y2)
    writeUInt8(y3)
    writeString(msg)
end

local function startPacket(pkgType)
    buffer:reset()
    buffer:writeUInt8(pkgType or Protocol.Package.TYPE_DATA)
end

local function sendPacket()
    local str = string.sub(buffer:getTotalBuff(), 5)
    if not connector then
        printInfo("can not found tcp connection")
        return
    end
    connector:send(str)
end

local Transport = class("Transport")
function Transport:ctor(__host, __port)
    self.interupted = false
    self.reconnectScheduler = nil
    self.isHandshaked = false
    self.tcp = nil
    self.recvBuffer = {}
    self.recvLength = 0
    self.sendBuffer = {}
    self.timeoutCallbacks = {}
    __host = __host or "127.0.0.1"
    __port = __port or 33250
    self:setHost(__host, __port)
    self.m_updateHandler = scheduler.scheduleGlobal(handler(self, Transport.update), 0.1)
    self.m_closeTime = -1
    self.m_pauseParseData = false
    self.m_pauseTime = -1
end

function Transport:checkHasMergeString(len)
    local tmp = self.recvBuffer[1]
    if string.len(tmp) < len then
        tmp = table.concat(self.recvBuffer, "")
        self.recvBuffer = {}
        self.recvBuffer[1] = tmp
    end
    return tmp
end

function Transport:pause(time)
    time = time or -1
    self.m_pauseParseData = true
    self.m_pauseTime = time
end

function Transport:resume()
    self.m_pauseParseData = false
    self.m_pauseTime = -1
end

function Transport:process()
    local packageHeaderLength = 4
    -- process all received packet
    while self.recvLength >= 4 do
        local package = {}
        local tmp = self:checkHasMergeString(packageHeaderLength)
        package.type = string.byte(tmp, 1)
        local packageLen = string.byte(tmp, 2) * 256 * 256 + string.byte(tmp, 3) * 256 + string.byte(tmp, 4)

        local pkgLengthWithHeader = packageLen + packageHeaderLength

        -- buffer length less than packet length
        if pkgLengthWithHeader > self.recvLength then
            break
        end

        -- parse packet
        local tmp = self:checkHasMergeString(pkgLengthWithHeader)
        local packageStr = string.sub(tmp, packageHeaderLength + 1, pkgLengthWithHeader) --split a package data
        self.recvBuffer[1] = string.sub(tmp, pkgLengthWithHeader + 1)
        self.recvLength = self.recvLength - pkgLengthWithHeader

        package.data = packageStr
        --print("package.data = packageStr", json.encode(package))

        if package.type == Protocol.Package.TYPE_HANDSHAKE then
            printInfo("TYPE_HANDSHAKE")
            self.isHandshaked = true
            startPacket(Protocol.Package.TYPE_HANDSHAKE_ACK)
            writeUInt8(0)
            writeUInt16(0)
            sendPacket()
        elseif package.type == Protocol.Package.TYPE_HEARTBEAT then
            --[[printInfo("TYPE_HEARTBEAT")
            deskManager.heartbeat()]]
        elseif package.type == Protocol.Package.TYPE_DATA then
            local message = Protocol.Message.decode(package.data)
            printInfo("S===>C: %s", json.encode(message))
            if message.type == Protocol.Message.TYPE_RESPONSE then
                local callback = starxRequestCallbacks[message.id]
                if callback then
                    starxRequestCallbacks[message.id] = nil
                    callback(message.data)
                end
            else
                local callback = starxPushCallbacks[message.route]
                if callback then
                    callback(message.data)
                end
            end
        elseif package.type == Protocol.Package.TYPE_KICK then
            --printInfo("TYPE_KICK")
        end
    end
end

function Transport:onData(event)
    table.insert(self.recvBuffer, event.data)
    self.recvLength = self.recvLength + string.len(event.data)
end

function Transport:clearRecvBuffer()
    self.recvBuffer = {}
    self.recvLength = 0
end

function Transport:onClose(event)
    if self.closeListener then self.closeListener(event) end
end

function Transport:onClosed(event)
    self.interupted = true
    self.isHandshaked = false
    WaitUI.show("网络已断开, 正在重连...")
    if NetworkManager.disconnectHandler ~= nil then
        NetworkManager.disconnectHandler()
    end

    local reconnect = function()
        connector:connect()
    end
    self.reconnectScheduler = scheduler.scheduleGlobal(reconnect, 0.1)
end

function Transport:onConnected(event)
    NetworkManager.handShake()

    -- 初始化心跳时间
    if configManager and configManager.systemConfig and type(configManager.systemConfig.heartbeat) == "number" then
        heartbeatInternal = configManager.systemConfig.heartbeat
    end
    if self.interupted then
        if self.reconnectScheduler then
            scheduler.unscheduleGlobal(self.reconnectScheduler)
            self.reconnectScheduler = nil
        end

        WaitUI.hide()
        NetworkManager.notify("DeskManager.ReConnect", {
            uid = dataManager.playerData:getAcId(),
            name = dataManager.playerData:getNickname(),
            headUrl = dataManager.playerData:getHeadUrl(),
            sex = dataManager.playerData:getUserSex(),
        })
        if NetworkManager.reconnectHandler ~= nil then
            NetworkManager.reconnectHandler()
        end
    end
    if #(self.sendBuffer) > 0 then
        for _, val in ipairs(self.sendBuffer) do
            self.tcp:send(val)
        end
    end
    self.sendBuffer = {}
    if #(self.timeoutCallbacks) > 0 then
        for _, func in ipairs(self.timeoutCallbacks) do
            if func then func(false) end
        end
    end
    self.timeoutCallbacks = {}
end

function Transport:onConnectFailed(event)
    if #(self.timeoutCallbacks) > 0 then
        for _, func in ipairs(self.timeoutCallbacks) do
            if func then func(true) end
        end
    end
    self.sendBuffer = {}
    self.timeoutCallbacks = {}
end

function Transport:setHost(__host, __port)
    if __host then self.host = __host end
    if __port then self.port = __port end
    if not self.tcp then
        self:newTcp()
    else
        self.tcp:close()
        --self.tcp:connect(_host, _port)
    end
end

function Transport:newTcp()
    self.tcp = SocketTCP.new(self.host, self.port)
    self.tcp:addEventListener(SocketTCP.EVENT_DATA, handler(self, self.onData))
    self.tcp:addEventListener(SocketTCP.EVENT_CLOSE, handler(self, self.onClose))
    self.tcp:addEventListener(SocketTCP.EVENT_CLOSED, handler(self, self.onClosed))
    self.tcp:addEventListener(SocketTCP.EVENT_CONNECTED, handler(self, self.onConnected))
    self.tcp:addEventListener(SocketTCP.EVENT_CONNECT_FAILURE, handler(self, self.onConnectFailed))
end

function Transport:isConnected()
    return self.tcp and self.tcp.isConnected
end

function Transport:send(data, timeoutCallback)
    if self.tcp.isConnected then
        self.tcp:send(data)
    else
        table.insert(self.sendBuffer, data)
        if timeoutCallback then
            table.insert(self.timeoutCallbacks, timeoutCallback)
        end
    end
end

function Transport:connect()
    if self.tcp then self.tcp:connect() end
end

function Transport:close()
    if self.tcp then self.tcp:close() end
    self:clearRecvBuffer()
end

function Transport:setCloseListener(listener)
    self.closeListener = listener
end

function Transport:update(dt)
    self:updateConnection(dt)
    if not self.m_pauseParseData then
        self:process(1)
    else
        if self.m_pauseTime > 0 then
            self.m_pauseTime = self.m_pauseTime - dt
            if self.m_pauseTime <= 0 then
                self.m_pauseTime = -1
                self.m_pauseParseData = false
            end
        end
    end
end

function Transport:updateConnection(dt)
    if not self.tcp.isConnected then return end
    if self.m_closeTime > 0 then
        self.m_closeTime = self.m_closeTime - dt
        if self.m_closeTime <= 0 then
            self.tcp:close()
            self.m_closeTime = -1.0
        end
    end
end

------------------------ network manager---------------------------
NetworkManager.reconnectHandler = nil
NetworkManager.disconnectHandler = nil
NetworkManager.heartbeatHandler = nil

function NetworkManager.init(_host, _port)
    --注册心跳定时器(scheduler会在应用切入后台时, 暂停, 切入后台后, 使用系统定时器)
    if NetworkManager.heartbeatHandler == nil then
        NetworkManager.heartbeatHandler = scheduler.scheduleGlobal(function() NetworkManager.heartbeat() end, 1)
    end
    if not connector then
        connector = Transport:create(_host, _port)
    else
        connector:setHost(_host, _port)
    end
    connector:connect()
end

local timerScheduler = TimerSchedulerClass:create()
scheduler.scheduleGlobal(handler(timerScheduler, TimerSchedulerClass.update), 1.0)

local requestId = 0
local function nextMessageID()
    requestId = requestId + 1
    return requestId
end

local handshakeBuffer = { sys = { ["type"] = "cocos2dx-lua-client", version = "0.0.1", rsa = {} }, user = {} }
function NetworkManager.handShake()
    startPacket(Protocol.Package.TYPE_HANDSHAKE)
    local msg = json.encode(handshakeBuffer)
    writeMessage(msg)
    sendPacket()

    -- skip valide process
    startPacket(Protocol.Package.TYPE_HANDSHAKE_ACK)
    writeUInt8(0)
    writeUInt16(0)
    sendPacket()
end

function NetworkManager.request(route, data, callback)
    if not data then
        data = {}
    end

    local id = nextMessageID()
    starxRequestCallbacks[id] = callback

    startPacket(Protocol.Package.TYPE_DATA)
    local msg = Protocol.Message.encode(Protocol.Message.TYPE_REQUEST, route, data, id)
    writeMessage(msg)
    sendPacket()
end

function NetworkManager.notify(route, data)
    if not data then
        data = {}
    end

    printInfo("C====>S: Route=%s, Data=%s", route, json.encode(data, "data"))

    startPacket(Protocol.Package.TYPE_DATA)
    local msg = Protocol.Message.encode(Protocol.Message.TYPE_NOTIFY, route, data)
    writeMessage(msg)
    sendPacket()
end

function NetworkManager.on(route, callback)
    starxPushCallbacks[route] = callback
end

function NetworkManager.setReconnectHandler(callback)
    NetworkManager.reconnectHandler = callback
end

function NetworkManager.setDisconnectHandler(callback)
    NetworkManager.disconnectHandler = callback
end

function NetworkManager.heartbeat()
    if not connector or not connector.isHandshaked then
        return
    end

    local now = os.time()
    local delta = now - lastHeartbeatTime
    if delta < heartbeatInternal then
        return
    end

    startPacket(Protocol.Package.TYPE_HEARTBEAT)
    writeUInt8(0)
    writeUInt16(0)
    sendPacket()

    lastHeartbeatTime = now
end

return NetworkManager