local UIStack = {}

local BaseUIInfo = class("BaseUIInfo")
function BaseUIInfo:ctor(ui)
    self.m_stack = stack:create()
    self.m_baseUI = ui
    self.m_baseLocalZOrder = 0
end

function BaseUIInfo:push(ui)
    self.m_stack:push(ui)
    ui:setLocalZOrder(self.m_baseLocalZOrder)
    self.m_baseUI:addChild(ui)
    if ui.registEvent then
        ui:registEvent()
    end
end

function BaseUIInfo:pop()
    if self.m_stack:isEmpty() then
        return
    end
    local ui = self.m_stack:top()
    if ui.unregistEvent then
        ui:unregistEvent()
    end
    ui:removeFromParent()
    self.m_stack:pop()
end

function BaseUIInfo:popAll()
    if not self.m_stack:isEmpty() then
        self:pop()
    end
end

function BaseUIInfo:change(ui)
    self:pop()
    self:push(ui)
end

function BaseUIInfo:setBaseLocalZOrder(zorder)
    self.m_baseLocalZOrder = zorder
end

local baseUIStack = stack:create()
local curBaseUIInfo = nil

function UIStack.pushBaseUI(ui)
    local info = BaseUIInfo:create(ui)
    baseUIStack:push(info)
    curBaseUIInfo = info
end

function UIStack.popBaseUI()
    baseUIStack:pop()
    if baseUIStack:isEmpty() then
        curBaseUIInfo = nil
    else
        curBaseUIInfo = baseUIStack:top()
    end
end

function UIStack.changeBaseUI(ui)
    if not baseUIStack:isEmpty() then UIStack.popBaseUI() end
    UIStack.pushBaseUI(ui)
end

function UIStack.pushUI(ui)
    curBaseUIInfo:push(ui)
end

function UIStack.popUI()
    curBaseUIInfo:pop()
end

function UIStack.changeUI(ui)
    curBaseUIInfo:change(ui)
end

function UIStack.popAllUI()
    curBaseUIInfo:popAll()
end

function UIStack.setDefaultLocalZOrder(zorder)
    curBaseUIInfo:setBaseLocalZOrder(zorder)
end

return UIStack