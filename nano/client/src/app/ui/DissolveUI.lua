local scheduler = require("app.core.scheduler")
local DissolveUI = class("DissolveUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local gameAssistant = require "app.logic.gameAssistant"
local networkManager = require "app.network.NetworkManager"
local EventManager = require "app.core.EventManager"
local deskManager = require "app.logic.deskManager"

DissolveUI.RESOURCE_FILENAME = "layout/dissolve.csb"
DissolveUI.RESOURCE_BINDING = {
    m_comfirm = { id = "comfirm", onClick = "onConfirm" },
    m_cancel = { id = "cancel", onClick = "onCancel" },
    m_player1Head = { id = "player1,head" },
    m_player1Name = { id = "player1,name" },
    m_player1Status = { id = "player1,status" },
    m_player2Head = { id = "player2,head" },
    m_player2Name = { id = "player2,name" },
    m_player2Status = { id = "player2,status" },
    m_player3Head = { id = "player3,head" },
    m_player3Name = { id = "player3,name" },
    m_player3Status = { id = "player3,status" },
    m_timer = { id = "timer,text" },
}

event_name.DISSOLVE_STATUS_CHANGE = "dissolve_status_change"
event_name.CLOSE_DISSOLVE_UI = "CLOSE_DISSOLVE_UI"

function DissolveUI:hiddenUI()
    self.m_comfirm:setVisible(false)
    self.m_cancel:setVisible(false)
end

function DissolveUI:showUI()
    self.m_comfirm:setVisible(true)
    self.m_cancel:setVisible(true)
end

function DissolveUI:onConfirm()
    gameAssistant.playBtnClickedSound()
    self:hiddenUI()
    networkManager.notify("DeskManager.DissolveStatus", { result = true })
end

function DissolveUI:onCancel()
    gameAssistant.playBtnClickedSound()
    self:hiddenUI()
    networkManager.notify("DeskManager.DissolveStatus", { result = false })
end

function DissolveUI:refreshStatus(dissolveStatus)
    for i = 1, #dissolveStatus do
        local item = dissolveStatus[i]
        local player = deskManager.getPlayerData(item.deskPos)
        if player then
            local head = self[string.format("m_player%dHead", i)]
            local name = self[string.format("m_player%dName", i)]
            local status = self[string.format("m_player%dStatus", i)]

            head:setTexture(player:getHeadIcon())
            head:setScale(105 / head:getContentSize().width)
            name:setString(player:getNickname())
            status:setString(item.status)
        end
    end
end

function DissolveUI:onCreate(dissolveStatus, isSelf, restTime)
    self.restTime = restTime or 600
    self:update()
    self.isDissolver = false --是不是申请解散的人
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    self.root:ignoreAnchorPointForPosition(true)
    self.root:setAnchorPoint(cc.p(0.5, 0.5))
    self.root:setScale(0.2)
    local action1 = cc.ScaleTo:create(0.2, 1.1)
    local action2 = cc.ScaleTo:create(0.15, 1)
    self.root:runAction(cc.Sequence:create(action1, action2))
    self.m_updateHandler = scheduler.scheduleGlobal(handler(self, DissolveUI.update), 1)
    self:refreshStatus(dissolveStatus)

    if isSelf then
        self.m_comfirm:setEnabled(false)
    end
end

function DissolveUI:onStatusChanged(event)
    if event.restTime > 0 and self.restTime > event.restTime then
        self.restTime = event.restTime
    end
    self:refreshStatus(event.dissolveStatus)
end

function DissolveUI:onDeskDisolved(event)
    UIStack:popUI()
end

local transform = function(time)
    local m = math.floor(time / 60)
    local s = time % 60
    return string.format("%02d:%02d", m, s)
end

function DissolveUI:update()
    self.restTime = self.restTime - 1
    if self.restTime < 0 then
        self.m_timer:setString("房间已解散，等待服务器结算数据")
    else
        self.m_timer:setString(transform(self.restTime) .. " 后解散房间")
    end
end

function DissolveUI:registEvent()
    -- clean previous dissolve ui envent handler
    EventManager:removeEventListenersByEvent(event_name.DISSOLVE_STATUS_CHANGE)
    EventManager:removeEventListenersByEvent(event_name.CLOSE_DISSOLVE_UI)

    self._, self.statusChangedHandler = EventManager:addEventListener(event_name.DISSOLVE_STATUS_CHANGE, handler(self, self.onStatusChanged))
    self._, self.deskDisolvedHandler = EventManager:addEventListener(event_name.CLOSE_DISSOLVE_UI, handler(self, self.onDeskDisolved))
end

--unregist event
function DissolveUI:unregistEvent()
    EventManager:removeEventListener(self.statusChangedHandler)
    EventManager:removeEventListener(self.deskDisolvedHandler)
end

function DissolveUI:onExit()
    scheduler.unscheduleGlobal(self.m_updateHandler)
end

return DissolveUI