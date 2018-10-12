local PushWindow = class("PushWindow", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
PushWindow.RESOURCE_FILENAME = "layout/alert.csb"
PushWindow.RESOURCE_BINDING = {
    m_noBtn = { id = "no", onClick = "onNoClicked" },
    m_yesBtn = { id = "yes", onClick = "onYesClicked" },
    m_text = { id = "text" },
}

function PushWindow:onYesClicked(sender, eventType)
    self.m_table.yes.fun()
end

function PushWindow:onNoClicked(sender)
    self.m_table.no.fun()
    UIStack.popUI()
end

function PushWindow:onCreate(windowTable)
    self.root:ignoreAnchorPointForPosition(true)
    self.root:setAnchorPoint(cc.p(0.5, 0.5))
    self.root:setScale(0.2)
    local action1 = cc.ScaleTo:create(0.15, 1.1)
    local action2 = cc.ScaleTo:create(0.08, 1)
    self.root:runAction(cc.Sequence:create(action1, action2))

    self.m_table = windowTable
    self.m_type = 0
    self:setTexts(windowTable.title)
    self:addABlockLayer(true, 130)

    if windowTable.yes then
        self:setYes(windowTable.yes.title)
    end

    if windowTable.no then
        self:setNo(windowTable.no.title)
    end

    if self.m_type == 0 then
        self.m_noBtn:setPositionX(0)
        self.m_yesBtn:setPositionX(10000)
        self.m_yesBtn:hide()
    elseif self.m_type == 1 then
        self.m_yesBtn:setPositionX(0)
        self.m_noBtn:setPositionX(10000)
        self.m_noBtn:hide()
    end

    self.root:setPosition(display.center)
end

function PushWindow:setTexts(t)
    self.m_text:setString(t)
end

function PushWindow:setYes(t)
    self.m_type = 1
    --    self.m_noT:setString(t)
end

function PushWindow:setNo(t)
    if self.m_type == 1 then
        self.m_type = 2
    end
end

return PushWindow