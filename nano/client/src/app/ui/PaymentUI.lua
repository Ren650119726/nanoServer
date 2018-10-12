local PaymentUI = class("PaymentUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"

PaymentUI.RESOURCE_FILENAME = "layout/paymentUI.csb"
PaymentUI.RESOURCE_BINDING = {
    m_exitBtn = { id = "exitBtn", onClick = "OnClose" },
    m_exitBtn = { id = "weChat", onClick = "OnWeChat" },
    m_exitBtn = { id = "aliPay", onClick = "OnALiPay" },
}

function PaymentUI:OnClose(sender)
    self.gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function PaymentUI:OnWeChat(sender)
    self.gameAssistant.playCloseUISound()
    self.gameAssistant.buy()
    UIStack.popUI()
end

function PaymentUI:OnALiPay(sender)
    self.gameAssistant.playCloseUISound()
    self.gameAssistant.buy()
    UIStack.popUI()
end

function PaymentUI:onCreate(money, gameAssistant)
    self.gameAssistant = gameAssistant
    self.money = money
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    self.root:ignoreAnchorPointForPosition(true)
    self.root:setAnchorPoint(cc.p(0.5, 0.5))
    self.root:setScale(0.2)
    local action1 = cc.ScaleTo:create(0.2, 1.1)
    local action2 = cc.ScaleTo:create(0.15, 1)
    self.root:runAction(cc.Sequence:create(action1, action2))
end

return PaymentUI