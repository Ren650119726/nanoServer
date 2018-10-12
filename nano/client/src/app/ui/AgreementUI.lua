local AgreementUI = class("AgreementUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local gameAssistant = require "app.logic.gameAssistant"

AgreementUI.RESOURCE_FILENAME = "layout/agreement.csb"

AgreementUI.RESOURCE_BINDING = {
    bExit = { id = "confirm", onClick = "onCloseWindow" },
}

function AgreementUI:onCloseWindow()
    gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function AgreementUI:onCreate()
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    --[[self.m_bg:setScale(0.5)
    local action1 = cc.ScaleTo:create(0.15, 1.1)
    local action2 = cc.ScaleTo:create(0.10, 1)
    self.m_bg:runAction(cc.Sequence:create(action1, action2))]]
end

return AgreementUI
