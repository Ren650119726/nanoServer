local HelpUI = class("HelpUI", cc.load("mvc").ViewBase)
local RuleUI = class("RuleXY", cc.load("mvc").ViewBase) -- 襄阳
local UIStack = require "packages.mvc.UIStack"
local gameAssistant = require "app.logic.gameAssistant"

RuleUI.RESOURCE_FILENAME = "layout/rule.csb"
function RuleUI:onCreate() self:setContentSize(940, 4380) end

HelpUI.RESOURCE_FILENAME = "layout/help.csb"
HelpUI.RESOURCE_BINDING = {
    listview = { id = "bg,listview" },
    _close = { id = "close", onClick = "onCloseWindow" },
}

function HelpUI:onCloseWindow()
    gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function HelpUI:onCreate()
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)

    local item = RuleUI:create()
    local layout = ccui.Layout:create()
    layout:addChild(item)
    layout:setContentSize(item:getContentSize())
    self.listview:pushBackCustomItem(layout)
end

return HelpUI