local JoinClubUI = class("JoinClubUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local deskEnterHelper = require "app.logic.deskEnterHelper"
local WaitUI = require "app.ui.WaitUi"
local networkManager = require "app.network.NetworkManager"
local stringDefine = require "app.data.stringDefine"
local gameAssistant = require "app.logic.gameAssistant"
local LocalRecord = require "app.core.LocalRecord"
local HttpRequest = require "app.network.HttpRequest"

JoinClubUI.RESOURCE_FILENAME = "layout/join_club.csb"
JoinClubUI.RESOURCE_BINDING = {
    bClose = { id = "close", onClick = "onClose" },
    bNum1 = { id = "num1", onClick = "onNum" },
    bNum2 = { id = "num2", onClick = "onNum" },
    bNum3 = { id = "num3", onClick = "onNum" },
    bNum4 = { id = "num4", onClick = "onNum" },
    bNum5 = { id = "num5", onClick = "onNum" },
    bNum6 = { id = "num6", onClick = "onNum" },
    bNum7 = { id = "num7", onClick = "onNum" },
    bNum8 = { id = "num8", onClick = "onNum" },
    bNum9 = { id = "num9", onClick = "onNum" },
    bNum0 = { id = "num0", onClick = "onNum" },
    bReset = { id = "reset", onClick = "onReset" },
    bDelete = { id = "delete", onClick = "onDelete" },
    tNum1 = { id = "container,num_container,num1bg,text" },
    tNum2 = { id = "container,num_container,num2bg,text" },
    tNum3 = { id = "container,num_container,num3bg,text" },
    tNum4 = { id = "container,num_container,num4bg,text" },
    tNum5 = { id = "container,num_container,num5bg,text" },
    tNum6 = { id = "container,num_container,num6bg,text" },
}

function JoinClubUI:reset()
    for i = 1, 6 do
        local text = "tNum" .. i
        self[text]:setText("")
    end
end

local function applyClubUrl(clubId)
    return string.format("%s/v1/club/apply?uid=%d&club=%d",
        appConfig.webService, dataManager.playerData:getAcId(), clubId)
end

function JoinClubUI:inputNum(num)
    table.push(self.inputs, num)
    local btn = "tNum" .. #self.inputs
    self[btn]:setText(num)
    if #self.inputs == 6 then
        gameAssistant.playBtnClickedSound()
        local clubId = table.concat(self.inputs)
        UIStack.popUI()

        WaitUI.show()
        local response = function(resp)
            WaitUI.hide()
            if resp.code ~= 0 then
                gameAssistant.showHintAlertUI(resp.error)
            else
                gameAssistant.showHintAlertUI("已经发送申请，部长同意后，俱乐部会显示在列表中")
            end
        end
        networkManager.request("ClubManager.ApplyClub", {clubId = tonumber(clubId)}, response)
        --HttpRequest.Get(applyClubUrl(clubId), response, "")
    end
end

function JoinClubUI:onReset()
    self.gameAssistant.playBtnClickedSound()
    self:reset()
    self.inputs = {}
end

function JoinClubUI:onDelete()
    if #self.inputs < 1 then
        return
    end
    self.gameAssistant.playBtnClickedSound()
    local btn = "tNum" .. #self.inputs
    self[btn]:setText("")
    table.remove(self.inputs)
end

function JoinClubUI:onClose()
    self.gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function JoinClubUI:onNum(sender)
    self.gameAssistant.playBtnClickedSound()
    self:inputNum(sender:getTitleText())
end

function JoinClubUI:onCreate(gameAssistant)
    self:reset()
    self.inputs = {}
    self.gameAssistant = gameAssistant
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    self.root:ignoreAnchorPointForPosition(true)
    self.root:setAnchorPoint(cc.p(0.5, 0.5))
    self.root:setScale(0.2)
    local action1 = cc.ScaleTo:create(0.2, 1.1)
    local action2 = cc.ScaleTo:create(0.15, 1)
    self.root:runAction(cc.Sequence:create(action1, action2))
end

return JoinClubUI