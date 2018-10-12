local ContactUI = class("ContactUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local configManager = require "app.config.configManager"

ContactUI.RESOURCE_FILENAME = "layout/contact.csb"
ContactUI.RESOURCE_BINDING = {
    m_closeBtn = { id = "close", onClick = "onClose" },
    m_copyD1 = { id = "copy_d1", onClick = "onCopyd1" },
    m_copyD2 = { id = "copy_d2", onClick = "onCopyd2" },
    m_copyK1 = { id = "copy_k1", onClick = "onCopyk1" },
    m_daili1 = { id = "daili1" },
    m_daili2 = { id = "daili2" },
    m_kefu1 = { id = "kefu1" },
    mCopy = {id = "copy"},
}

function ContactUI:copy(str)
    self.mCopy:setVisible(true)
    self.mCopy:setString(string.format("已复制%s", str))
    clipboard.copy(str)
end

function ContactUI:onCopyd1()
    self:copy(configManager.systemConfig.daili1)
end

function ContactUI:onCopyd2()
    self:copy(configManager.systemConfig.daili2)
end

function ContactUI:onCopyk1()
    self:copy(configManager.systemConfig.kefu1)
end

function ContactUI:onClose()
    self.gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function ContactUI:onCreate(gameAssistant)
    self.gameAssistant = gameAssistant
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    self.root:ignoreAnchorPointForPosition(true)
    self.root:setAnchorPoint(cc.p(0.5, 0.5))
    self.root:setScale(0.2)
    self.mCopy:setVisible(false)

    -- 联系信息
    local config = configManager.systemConfig
    self.m_daili1:setString(config.daili1)
    self.m_daili2:setString(config.daili2)
    self.m_kefu1:setString(config.kefu1)

    local action1 = cc.ScaleTo:create(0.2, 1.1)
    local action2 = cc.ScaleTo:create(0.15, 1)
    self.root:runAction(cc.Sequence:create(action1, action2))
end

return ContactUI