local ShareUI = class("ShareUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local configManager = require "app.config.configManager"

ShareUI.RESOURCE_FILENAME = "layout/share.csb"
ShareUI.RESOURCE_BINDING = {
    bClose = { id = "close", onClick = "onClose" },
    bShareFrient = { id = "friend", onClick = "onShareFriend" },
    bShareCircle = { id = "circle", onClick = "onShareCircle" },
}

function ShareUI:onClose()
    self.gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function ShareUI:share(scope)
    self.gameAssistant.playBtnClickedSound()
    local url = configManager.systemConfig[device.platform]
    local title = configManager.systemConfig.title
    local desc = configManager.systemConfig.desc
    thirdsdk.share(scope, url, title, desc)
end

function ShareUI:onShareFriend()
    self:share("session")
end

function ShareUI:onShareCircle()
    self:share("circle")
end

function ShareUI:onCreate(gameAssistant)
    self.gameAssistant = gameAssistant
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    self.root:ignoreAnchorPointForPosition(true)
    self.root:setAnchorPoint(cc.p(0.5, 0.5))
    self.root:setScale(0.5)
    local action1 = cc.ScaleTo:create(0.15, 1.1)
    local action2 = cc.ScaleTo:create(0.1, 1)
    self.root:runAction(cc.Sequence:create(action1, action2))
end

return ShareUI