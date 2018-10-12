local eventManager = require "app.core.EventManager"
local scheduler = require("app.core.scheduler")
local DeskHeadUI = class("DeskHeadUI", cc.load("mvc").ViewBase)

event_name.DESK_HEADUI_DETAIL_INFOMATION = "DESK_HEADUI_DETAIL_INFOMATION"
event_name.DESK_HEADUI_OFFLINE_STATUS_CHANGE = "DESK_HEADUI_OFFLINE_STATUS_CHANGE"
event_name.DESK_MAKER_CHANGED = "DESK_MAKER_CHANGED"

DeskHeadUI.RESOURCE_FILENAME = "layout/desk_head.csb"
DeskHeadUI.RESOURCE_BINDING = {
    m_head = { id = "head" },
    m_ready = { id = "ready" },
    m_statusIcon = { id = "dingque" },
    m_queBg = { id = "queBG" },
    m_que = { id = "que" },
    m_frame = { id = "frame", onClick = "onDetail" },
    m_name = { id = "name" },
    m_offline = { id = "offline" },
    m_score = { id = "score" },
    m_maker = { id = "maker" },
    m_message = { id = "message" },
    m_messageBackground = { id = "message,background" },
    m_messageText = { id = "message,text" },
    m_info = { id = "info" },
    m_infoIp = { id = "info,ip" },
    m_infoId = { id = "info,id" },
}

function DeskHeadUI:onCreate(dir)
    self:setScale(0.75)
    self.direction = dir
    self.m_acid = 0
    self.m_info:setVisible(false)
    self.m_message:setVisible(false)
    self.m_offline:setVisible(false)
    self.m_maker:setVisible(false)
    self.m_statusIcon:setVisible(false)
    self.m_queBg:setVisible(false)
    self.m_que:setVisible(false)

    if dir == 2 then
        self.m_info:setPosition(cc.p(-250, 55))
        self.m_message:setPosition(cc.p(-390, -200))
        self.m_messageText:setPosition(cc.p(-19, 22))
        self.m_messageBackground:setFlipX(true)
        self.m_messageBackground:setFlipY(true)
    elseif dir == 3 then
        self.m_message:setPosition(cc.p(-390, -200))
        self.m_messageText:setPosition(cc.p(-19, 22))
        self.m_messageBackground:setFlipX(true)
        self.m_messageBackground:setFlipY(true)
    elseif dir == 4 then
        self.m_message:setPosition(cc.p(-10, -200))
        self.m_messageText:setPosition(cc.p(-19, 22))
        self.m_messageBackground:setFlipY(true)
    end
end

function DeskHeadUI:setUid(uid)
    self.m_acid = uid
    self.m_infoId:setString(string.format("ID:%s", uid))
end

function DeskHeadUI:setIp(ip)
    self.m_infoIp:setString(string.format("IP:%s", ip))
end

function DeskHeadUI:setNickname(name)
    if utfstrlen(name) > 8 then
        name = string.format("%s...", subUTF8String(name, 1, 6))
    end
    self.m_name:setString(name)
end

function DeskHeadUI:setScore(score)
    self.m_score:setString(tostring(score))
end

function DeskHeadUI:setDir(idx)
    self.m_dir = idx
end

function DeskHeadUI:refreshNodePosX(node, isNeg)
    local x = node:getPosition()
    x = math.abs(x)
    if isNeg then
        node:setPositionX(-x)
    else
        node:setPositionX(x)
    end
end

function DeskHeadUI:setHeadIcon(head)
    self.m_head:setTexture(head)
    self.m_head:setScale(100 / self.m_head:getContentSize().width)
end

function DeskHeadUI:onDetail()
    eventManager:dispatchEvent({ name = event_name.DESK_HEADUI_DETAIL_INFOMATION })
end

function DeskHeadUI:onDetailShow()
    if not self.m_info then
        return
    end
    self.m_info:setVisible(true)
    scheduler.performWithDelayGlobal(function()
        -- fixed: 可能时间到了, 已经退出了
        if self.m_info and self.m_info.setVisible then
            self.m_info:setVisible(false)
        end
    end, 3)
end

function DeskHeadUI:onOfflineStatusChange(event)
    if self.m_acid == event.acId then
        self.m_offline:setVisible(event.offline)
    end
end

function DeskHeadUI:setMessage(message)
    self.m_message:setVisible(true)
    local text = self.m_message:getChildByName("text")
    text:setString(message)
    scheduler.performWithDelayGlobal(function()
        self.m_message:setVisible(false)
    end, 3)
end

function DeskHeadUI:onHeadChanged(event)
    if tostring(event.id) == tostring(self.m_acid) then
        self:setHeadIcon(event.head)
    end
end

function DeskHeadUI:onScoreChanged(event)
    if event.acid == self.m_acid then
        self:setScore(event.score)
    end
end

function DeskHeadUI:onMakerChange(event)
    if not self.m_maker then
        return
    end
    self.m_maker:setVisible(event.acid == self.m_acid)
end

function DeskHeadUI:showReady()
    self.m_ready:setVisible(true)
end

function DeskHeadUI:hideReady()
    self.m_ready:setVisible(false)
end

function DeskHeadUI:hideQue()
    self.m_queBg:setVisible(false)
    self.m_que:setVisible(false)
end

function DeskHeadUI:showQueStatus()
    self.m_statusIcon:setVisible(true)
end

function DeskHeadUI:hideQueStatus()
    self.m_statusIcon:setVisible(false)
end

function DeskHeadUI:getIconWp()
    return self:convertToWorldSpace(cc.p(self.m_que:getPosition()))
end

function DeskHeadUI:setHuaSe(icon)
    self.m_queBg:show()
    self.m_que:show()
    self.m_que:setTexture(icon)
    self.m_statusIcon:hide()
end

function DeskHeadUI:registerEvent()
    self._, self.headChangedHandler = eventManager:addEventListener(event_name.PLAYERDATA_HEADICON_CHANGED, handler(self, self.onHeadChanged))
    self._, self.scoreChangedHandler = eventManager:addEventListener(event_name.PLAYERDATA_SCORE_CHANGED, handler(self, self.onScoreChanged))
    self._, self.detailShowHandler = eventManager:addEventListener(event_name.DESK_HEADUI_DETAIL_INFOMATION, handler(self, self.onDetailShow))
    self._, self.offlineStatusChangeHandler = eventManager:addEventListener(event_name.DESK_HEADUI_OFFLINE_STATUS_CHANGE, handler(self, self.onOfflineStatusChange))
    self._, self.makerChangeHandler = eventManager:addEventListener(event_name.DESK_MAKER_CHANGED, handler(self, self.onMakerChange))
end

--unregist event
function DeskHeadUI:unregistEvent()
    eventManager:removeEventListener(self.headChangedHandler)
    eventManager:removeEventListener(self.scoreChangedHandler)
    eventManager:removeEventListener(self.detailShowHandler)
    eventManager:removeEventListener(self.offlineStatusChangeHandler)
    eventManager:removeEventListener(self.makerChangeHandler)
end

return DeskHeadUI