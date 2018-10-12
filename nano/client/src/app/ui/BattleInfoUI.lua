---------------------------------------------------------------------
--- 战绩主界面
--- @author : chrislonng
--- @date : 2017-03-10
--- @version : 0.1
--- @detail : none
---------------------------------------------------------------------
local scheduler = require("app.core.scheduler")
local BattleInfoUI = class("BattleInfoUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local gameAssistant = require "app.logic.gameAssistant"
local BattleItemUI = class("BattleItem", cc.load("mvc").ViewBase)
local BattleItemUI4 = class("BattleItem4", cc.load("mvc").ViewBase)
local BattleDetailUI = require "app.ui.BattleDetailUI"
local BattleDetailUI4 = require "app.ui.BattleDetailUI4"
local HttpRequest = require "app.network.HttpRequest"
local WaitUI = require "app.ui.WaitUi"
local configManager = require "app.config.configManager"

BattleInfoUI.RESOURCE_FILENAME = "layout/history.csb"
BattleInfoUI.RESOURCE_BINDING = {
    m_bg = { id = "container" },
    m_list = { id = "container,listview" },
    m_emtpy_logo = { id = "container,emtpy_logo" },
    bClose = { id = "container,close", onClick = "onCloseWindow" },
    bShare = { id = "container,share", onClick = "onShare" },
}

-- 三人模式
BattleItemUI.RESOURCE_FILENAME = "layout/history_item.csb"
BattleItemUI.RESOURCE_BINDING = {
    m_bg = { id = "container" },
    m_time = { id = "container,time" },
    m_id = { id = "container,id" },
    m_round = { id = "container,round" },
    m_number = { id = "container,number" },
    m_mine = { id = "container,mine" },
    m_zhanji_other1 = { id = "container,zhanji_other1" },
    m_zhanji_other2 = { id = "container,zhanji_other2" },
    m_name_other1 = { id = "container,name_other1" },
    m_name_other2 = { id = "container,name_other2" },
    m_detail = { id = "container,detail", onClick = "onDetail" },
}

-- 四人模式
BattleItemUI4.RESOURCE_FILENAME = "layout/history_item4.csb"
BattleItemUI4.RESOURCE_BINDING = {
    m_bg = { id = "container" },
    m_time = { id = "container,time" },
    m_id = { id = "container,id" },
    m_round = { id = "container,round" },
    m_number = { id = "container,number" },
    m_mine = { id = "container,mine" },
    m_zhanji_other1 = { id = "container,zhanji_other1" },
    m_zhanji_other2 = { id = "container,zhanji_other2" },
    m_zhanji_other3 = { id = "container,zhanji_other3" },
    m_name_other1 = { id = "container,name_other1" },
    m_name_other2 = { id = "container,name_other2" },
    m_name_other3 = { id = "container,name_other3" },
    m_detail = { id = "container,detail", onClick = "onDetail" },
}

local function parseRecvStr(str)
    if string.len(str) < 2 then
        return { code = 1000002, error = "json decode error" }
    end
    return json.decode(str, 1)
end

local function httpRequest(url, callback, data, method)
    local function onResponse(ok, str)
        local resp = {}
        if not ok then
            resp.code = 1000001
            resp.error = "network failed"
        else
            resp = parseRecvStr(str, 1)
        end
        callback(resp)
    end

    method = method or "POST"
    HttpRequest.send(url, onResponse, data, method)
end

local function battleListUrl()
    return string.format("%s/v1/desk/player/%d", appConfig.webService, dataManager.playerData:getAcId())
end

function BattleItemUI:onCreate(item)
    self.deskId = item.id
    local selfId = dataManager.playerData:getAcId()
    local mineScore = 0
    local others = {}
    local index = 0
    for i = 0, 2 do
        local idKey = string.format("player%d", i)
        local scoreKey = string.format("score_change%d", i)
        local id = item[idKey]
        if id == selfId then
            mineScore = item[scoreKey]
            index = i
        else
            local nameKey = string.format("player_name%d", i)
            table.push(others, { name = item[nameKey], score = item[scoreKey] })
        end
    end

    for i = 1, 2 do
        local nameNode = self[string.format("m_name_other%d", i)]
        local zhanjiNode = self[string.format("m_zhanji_other%d", i)]
        nameNode:setString(others[i].name)
        zhanjiNode:setString(string.format("战绩: %d", others[i].score))
    end
    self.m_time:setString(item.created_at_str)
    self.m_id:setString(item.no)
    self.m_round:setString(string.format("局数: %d", item.round))
    self.m_number:setString(string.format("房号: %s", item.desk_no))
    self.m_mine:setString(string.format("我的战绩: %d", mineScore))
    self.m_size = self.m_bg:getContentSize()
end

function BattleItemUI:getSize()
    return self.m_size
end

function BattleItemUI:onDetail(sender)
    gameAssistant.playBtnClickedSound()
    local ui = BattleDetailUI:create("", "", self.deskId)
    UIStack.pushUI(ui)
end

------------------------------------------
function BattleItemUI4:onCreate(item)
    self.deskId = item.id
    local selfId = dataManager.playerData:getAcId()
    local mineScore = 0
    local others = {}
    local index = 0
    for i = 0, 3 do
        local idKey = string.format("player%d", i)
        local scoreKey = string.format("score_change%d", i)
        local id = item[idKey]
        if id == selfId then
            mineScore = item[scoreKey]
            index = i
        else
            local nameKey = string.format("player_name%d", i)
            table.push(others, { name = item[nameKey], score = item[scoreKey] })
        end
    end

    for i = 1, 3 do
        local nameNode = self[string.format("m_name_other%d", i)]
        local zhanjiNode = self[string.format("m_zhanji_other%d", i)]
        nameNode:setString(others[i].name)
        zhanjiNode:setString(string.format("战绩: %d", others[i].score))
    end
    self.m_time:setString(item.created_at_str)
    self.m_id:setString(item.no)
    self.m_round:setString(string.format("局数: %d", item.round))
    self.m_number:setString(string.format("房号: %s", item.desk_no))
    self.m_mine:setString(string.format("我的战绩: %d", mineScore))
    self.m_size = self.m_bg:getContentSize()
end

function BattleItemUI4:getSize()
    return self.m_size
end

function BattleItemUI4:onDetail(sender)
    gameAssistant.playBtnClickedSound()
    local ui = BattleDetailUI4:create("", "", self.deskId)
    UIStack.pushUI(ui)
end

------------------------------------------
function BattleInfoUI:onCloseWindow(sender)
    gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function BattleInfoUI:init()
end

function BattleInfoUI:addInfo(item)
    if item.mode == MODE_FOURS then
        local item = BattleItemUI4:create("", "", item)
        local layout = ccui.Layout:create()
        layout:addChild(item)
        layout:setContentSize(item:getSize())
        self.m_list:pushBackCustomItem(layout)
    else
        local item = BattleItemUI:create("", "", item)
        local layout = ccui.Layout:create()
        layout:addChild(item)
        layout:setContentSize(item:getSize())
        self.m_list:pushBackCustomItem(layout)
    end
end

function BattleInfoUI:clear()
    self.m_list:removeAllItems()
end

--截屏回调方法
local function afterCaptured(succeed, outputFile)
    if succeed then
        local title = configManager.systemConfig.title
        local desc = configManager.systemConfig.desc
        printInfo("capture screen succeed: %s, %s, %s", outputFile, title, desc)
        thirdsdk.share("session", outputFile, title, desc)
    else
        cclog("capture screen failed.")
    end
end

function BattleInfoUI:onShare(sender)
    gameAssistant.playCloseUISound()
    local fileName = "CaptureScreen.png"
    cc.utils:captureScreen(afterCaptured, fileName)
end

function BattleInfoUI:onCreate()
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
                    --printInfo("%s",vardump(resp.data[i]))
                    ui:addInfo(item)
                end
            end
        end
        httpRequest(battleListUrl(), onResponse, "", "GET")
    end, 0)
end

return BattleInfoUI