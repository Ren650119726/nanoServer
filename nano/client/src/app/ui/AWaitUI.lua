local AWaitUI = class("AWaitUI", cc.load("mvc").ViewBase)
AWaitUI.RESOURCE_FILENAME = "layout/await.csb"

local director = cc.Director:getInstance()
local winSize = director:getWinSize()

AWaitUI.RESOURCE_BINDING = {
    tMessage = { id = "text" },
    sCircle = { id = "circle" },
    sBackground = { id = "background" },
}

function AWaitUI:onCreate(idx, text)
    if idx == 1 then
        local action = cc.CSLoader:createTimeline("layout/await.csb")
        self:runAction(action)
        action:gotoFrameAndPlay(0)
    else
        if text then
            self.tMessage:setString(text)
            self.tMessage:setOpacity(255)
        else
            self.tMessage:setOpacity(0)
        end
        self.sCircle:hide()
        local action = cc.FadeOut:create(2)
        self.root:runAction(cc.Sequence:create(action, cc.CallFunc:create(function() self:removeFromParent() end)))
    end

    self.root:setPosition(display.center)
end

return AWaitUI