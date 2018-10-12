--region *.lua
--Date
--此文件由[BabeLua]插件自动生成



--endregion

local LuaCustomEventManager = {}

LuaCustomEventManager.eventHandle = {}

--[[
eventHandle[9] = function (proto)
    print('===============ontaskerror====================')
    print(proto:readString());
    print(proto:readString());
    print(proto:readString());
    print(proto:readInt())
    print(proto:readInt())
    print(proto:readString());
end
eventHandle[10] = function (proto)
    print('===============ontaskprocess==================')
    print(proto:readInt())
    print(proto:readInt())
    print(proto:readString())
end
eventHandle[11] = function (proto)
    print('===============ontasksuccess==================')
    print(proto:readString())
    print(proto:readString())
    print(proto:readString())
end
--]]

function LuaCustomEventManager.registerEventHandle(id, callback)
    LuaCustomEventManager.eventHandle[id] = callback
end

function LuaCustomEventManager.removeEventHandle(id)
    LuaCustomEventManager.eventHandle[id] = nil
end

local am = ccluaext.LuaCustomEventManager:getInstance()
local proto = ccluaext.BinaryStream:create(1024)
proto:retain()
local function onLuaEvent(str)
    proto:setBuff(str)
    local eventId = proto:readInt()
    print('LuaEvent =====>' .. eventId)
    local func = LuaCustomEventManager.eventHandle[eventId]
    if func then
        func(proto)
    end
end
local listener = ccluaext.LuaCustomEventListener:create(am, onLuaEvent)
cc.Director:getInstance():getEventDispatcher():addEventListenerWithFixedPriority(listener, 1)

return LuaCustomEventManager
