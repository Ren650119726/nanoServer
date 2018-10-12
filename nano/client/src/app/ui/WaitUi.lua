local WaitUi = class("WaitUi", cc.load("mvc").ViewBase)
WaitUi.RESOURCE_FILENAME = "layout/loading.csb"

local director = cc.Director:getInstance()
local winSize = director:getWinSize()
local center = { x = winSize.width * 0.5, y = winSize.height * 0.5 }
local UIStack = require "packages.mvc.UIStack"

WaitUi.RESOURCE_BINDING = {
    m_text = { id = "text" },
}

local s_ui
local s_stack = stack:create()

function WaitUi:onCreate(text)
    self:showAction()
    self:setPosition(center)
    self.m_text:setOpacity(255)
    self:setText(text)
    self:addABlockLayer(true, 0)
end

function WaitUi:showAction()
    local action = cc.CSLoader:createTimeline("layout/loading.csb")
    self:runAction(action)
    action:gotoFrameAndPlay(0)
end

function WaitUi:setText(text)
    if text then
        self.m_text:setString(text)
        self.m_text:show()
    else
        self.m_text:hide()
    end
end

function WaitUi.show(text)
    if not s_ui then
        s_ui = WaitUi:create(text)
        s_ui:retain()
    end
    if s_ui:getParent() then
        return
    end
    UIStack.pushUI(s_ui)
    s_ui:setText(text)
    s_ui:showAction()
    if text then
        s_stack:push(text)
    end
end

function WaitUi.hide()
    if not s_ui:getParent() then
        return
    end
    UIStack.popUI()
    if not s_stack:isEmpty() then s_stack:pop() end
end

return WaitUi
