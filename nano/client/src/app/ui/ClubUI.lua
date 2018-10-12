---------------------------------------------------------------------
--- 俱乐部主界面
--- @author : chrislonng
--- @date : 2017-03-10
--- @version : 0.1
--- @detail : none
---------------------------------------------------------------------
local scheduler = require("app.core.scheduler")
local ClubUI = class("ClubUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local gameAssistant = require "app.logic.gameAssistant"
local ClubItemUI = class("ClubItemUI", cc.load("mvc").ViewBase)
local HttpRequest = require "app.network.HttpRequest"
local WaitUI = require "app.ui.WaitUi"
local JoinClubUI = require "app.ui.JoinClubUI"
local CreateRoomUI = require "app.ui.CreateRoomUI"

ClubUI.RESOURCE_FILENAME = "layout/club.csb"
ClubUI.RESOURCE_BINDING = {
    m_bg = { id = "background" },
    m_list = { id = "listview" },
    m_emtpy_logo = { id = "empty" },
    m_closeBtn = { id = "close", onClick = "onCloseWindow" },
    m_applyBtn = { id = "apply", onClick = "onApply" },
}

ClubItemUI.RESOURCE_FILENAME = "layout/club_item.csb"
ClubItemUI.RESOURCE_BINDING = {
    m_bg = { id = "container" },
    m_nameLabel = { id = "container,name" },
    m_memberCount = { id = "member_count" },
    m_description = { id = "desc" },
    m_clubIdLabel = { id = "club_id" },
    m_createRoom = { id = "container,create", onClick = "onCreateRoom" },
}

local function clubListUrl()
    return string.format("%s/v1/user/club?uid=%d", appConfig.webService, dataManager.playerData:getAcId())
end

function ClubItemUI:onCreate(item)
    self.clubId = item.id
    self.m_nameLabel:setString(item.name)
    self.m_description:setString(item.desc)
    self.m_clubIdLabel:setString(string.format("俱乐部ID: %d", item.id))
    self.m_memberCount:setString(string.format("人数: %d/%s", item.member, item.maxMember))
    self.m_size = self.m_bg:getContentSize()
end

function ClubItemUI:getSize()
    return self.m_size
end

function ClubItemUI:onCreateRoom(sender)
    gameAssistant.playBtnClickedSound()
    local ui = CreateRoomUI:create("", "", gameAssistant, self.clubId)
    UIStack.pushUI(ui)
end

------------------------------------------
function ClubUI:onCloseWindow(sender)
    gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function ClubUI:onApply(sender)
    gameAssistant.playCloseUISound()
    local ui = JoinClubUI:create("", "", gameAssistant)
    UIStack.pushUI(ui)
end

function ClubUI:addInfo(item)
    local item = ClubItemUI:create("", "", item)
    local layout = ccui.Layout:create()
    layout:addChild(item)
    layout:setContentSize(item:getSize())
    self.m_list:pushBackCustomItem(layout)
end

function ClubUI:clear()
    self.m_list:removeAllItems()
end

function ClubUI:onCreate()
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    self.m_type = 1
    local ui = self
    scheduler.performWithDelayGlobal(function()
        WaitUI.show("正在获取数据")
        local onResponse = function(resp)
            WaitUI.hide()
            if ui == nil or ui.m_emtpy_logo == nil or ui.addInfo == nil then
                return
            end

            if resp.code ~= 0 then
                gameAssistant.showHintAlertUI(resp.error)
            else
                if #resp.data > 0 then
                    ui.m_emtpy_logo:setVisible(false)
                end
                for i = 1, #resp.data do
                    local item = resp.data[i]
                    item.no = i
                    ui:addInfo(item)
                end
            end
        end

        HttpRequest.Get(clubListUrl(), onResponse, "")
    end, 0)
end

return ClubUI