
local SubPubHelper = class("SubPubHelper")

local EXPORTED_METHODS = {
    "addListener",
    "dispatchEvent",
    "removeListener",
    "removeAllListener",
}

function SubPubHelper:init_()
    self.m_target = nil
    self.m_listeners = {}
    setmetatable(self.m_listeners, {__mode = "k"})
end

function SubPubHelper:bind(target)
    self:init_()
    cc.setmethods(target, self, EXPORTED_METHODS)
    self.m_target = target
end

function SubPubHelper:unbind(target)
    cc.unsetmethods(target, EXPORTED_METHODS)
    self:init_()
end

function SubPubHelper:addListener(listener, tag)
    assert(type(listener) == "table" or type(listener) == "userdata",
        "Event:addEventListener() - invalid eventName")
    self.m_listeners[listener] = true

    if DEBUG > 1 then
        printInfo("addListener: %s, tag: %s", listener, tag)
    end
end

function SubPubHelper:dispatchEvent(_event)
    local name = _event.name
    collectgarbage()
    collectgarbage()
    for l, tag in pairs(self.m_listeners) do
        print("SubPubHelper:dispatchEvent %s, listener: %s, function: %s", tostring(tag), tolua.isnull(l), l["name"])
        if tag and l[name] then
            l[name](l, _event)
            printInfo("%s [SubPubHelper] dispatchEvent() - event %s", tostring(l), name)
        end
    end
    return self.m_target
end

function SubPubHelper:removeListener(listener)
    self.m_listeners[listener] = nil
    return self.m_target
end

function SubPubHelper:removeAllListener()
    self.m_listeners = {}
    return self.m_target
end
return SubPubHelper
