local xxteakey = "7AEC4MA152BQE9HWQ7KB"
local function encrypt(data)
    return crypto.encryptXXTEA(data, xxteakey)
end

local function decrypt(data)
    return crypto.decryptXXTEA(data, xxteakey)
end

local Protocol = {};

local PKG_HEAD_BYTES = 4;
local MSG_FLAG_BYTES = 1;
local MSG_ROUTE_CODE_BYTES = 2;
local MSG_ID_MAX_BYTES = 5;
local MSG_ROUTE_LEN_BYTES = 1;

local MSG_ROUTE_CODE_MAX = 0xffff;

local MSG_COMPRESS_ROUTE_MASK = 0x1;
local MSG_TYPE_MASK = 0x7;

Protocol.Package = {};
Protocol.Message = {};

local Package = Protocol.Package
local Message = Protocol.Message

Package.TYPE_HANDSHAKE = 1;
Package.TYPE_HANDSHAKE_ACK = 2;
Package.TYPE_HEARTBEAT = 3;
Package.TYPE_DATA = 4;
Package.TYPE_KICK = 5;

Message.TYPE_REQUEST = 0;
Message.TYPE_NOTIFY = 1;
Message.TYPE_RESPONSE = 2;
Message.TYPE_PUSH = 3;

Message.encode = function(msgType, route, data, id)
    if data == nil then
        data = {}
    end

    local stream = ccluaext.BinaryStream:create(1024)
    stream:reset()
    -- TODO: route compressing does not implement so far
    stream:writeUInt8(msgType * 2)

    if msgType == Message.TYPE_REQUEST then
        local n = id
        repeat
            local m = math.fmod(n, 128)
            n = math.floor(n / 128)

            if n == 0 then
                stream:writeUInt8(m)
            else
                stream:writeUInt8(m + 128)
            end
        until n == 0
    end

    -- write route
    stream:writeUInt8(string.len(route))
    for i = 1, string.len(route) do
        stream:writeUInt8(string.byte(route, i))
    end
    -- write message
    local obj = json.encode(data)
    local enc = encrypt(obj)
    for i = 1, string.len(enc) do
        stream:writeUInt8(string.byte(enc, i))
    end

    return string.sub(stream:getTotalBuff(), 5)
end

Message.decode = function(msg)
    local message = {}
    local offset = 1
    local typ = string.byte(msg, offset)

    offset = offset + 1

    -- TODO: route compressing does not implement so far
    message.type = typ / 2
    local id = 0
    if message.type == Message.TYPE_RESPONSE then
        for i = offset, string.len(msg) do
            local b = string.byte(msg, i)

            -- 倍数
            local muti = 0
            if i > offset then
                muti = math.pow(128, i - offset)
            end

            local n = b
            if b > 128 then
                n = b - 128
            end

            id = n + id * muti

            if b < 128 then
                offset = i + 1
                break
            end
        end
        message.id = id
    else
        local rl = string.byte(msg, offset)
        local route = string.sub(msg, offset + 1, offset + rl)
        offset = offset + 1
        offset = offset + rl
        message.route = route
    end

    local payload = string.sub(msg, offset)
    if string.len(payload) == 0 then
        message.data = {}
    else
        local dec = decrypt(payload)
        message.data = json.decode(dec)
    end

    return message
end

return Protocol