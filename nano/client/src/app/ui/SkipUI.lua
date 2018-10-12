local waitUI = require "app.ui.WaitUi"
local gameAssistant = require "app.logic.gameAssistant"

local SkipUI = class("SkipUI", cc.load("mvc").ViewBase)
SkipUI.RESOURCE_FILENAME = "layout/skip.csb"

SkipUI.RESOURCE_BINDING = {
    m_background = { id = "background" },
    m_logo = { id = "logo" },
}

function SkipUI:onCreate()
    self:addABlockLayer(true, 0)
    local gbgSize = self.m_background:getContentSize()
    local scaleW = display.width / gbgSize.width
    local scaleH = display.height / gbgSize.height
    self.m_background:setScale(scaleW, scaleH)
    self.m_background:setPosition(cc.p(display.width / 2, display.height / 2))
    self.m_logo:setPosition(cc.p(display.width/2,display.height*2/3))
    self:addChild(waitUI:create("", "", "游戏正在努力的加载..."))
end

return SkipUI