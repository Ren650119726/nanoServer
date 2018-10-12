local RealNameUI = class("RealNameUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"

RealNameUI.RESOURCE_FILENAME = "layout/realNameUI.csb"
RealNameUI.RESOURCE_BINDING = {
    m_name = { id = "name" },
    m_id = { id = "ID" },
    m_exitBtn = { id = "exitBtn", onClick = "OnClose" },
    m_pushBtn = { id = "pushBtn", onClick = "OnPush" },
}

function RealNameUI:OnClose(sender, eventType)
    UIStack.popUI()
end

function RealNameUI:OnPush(sender, eventType)
end

function RealNameUI:onCreate()
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
end

return RealNameUI


