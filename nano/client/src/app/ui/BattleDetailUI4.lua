local deskEnterHelper = require "app.logic.deskEnterHelper"
local scheduler = require("app.core.scheduler")
local BattleDetailUI4 = class("BattleDetailUI", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local gameAssistant = require "app.logic.gameAssistant"
local BattleDetailItemUI4 = class("BattleDetailItemUI4", cc.load("mvc").ViewBase)
local HttpRequest = require "app.network.HttpRequest"
local WaitUI = require "app.ui.WaitUi"
local typeDefine = require "app.data.typeDefine"
local configManager = require "app.config.configManager"

BattleDetailUI4.RESOURCE_FILENAME = "layout/history_detail4.csb"
BattleDetailUI4.RESOURCE_BINDING = {
    nContainer = { id = "container" },
    lHistory = { id = "container,listview" },
    tPlayerName0 = { id = "container,player_0_title" },
    tPlayerName1 = { id = "container,player_1_title" },
    tPlayerName2 = { id = "container,player_2_title" },
    tPlayerName3 = { id = "container,player_3_title" },
    bExit = { id = "container,close", onClick = "onCloseWindow" },
    bShare = { id = "container,share", onClick = "onShare" },
}

BattleDetailItemUI4.RESOURCE_FILENAME = "layout/history_detail_item4.csb"
BattleDetailItemUI4.RESOURCE_BINDING = {
    nContainer = { id = "container" },
    tId = { id = "id" },
    tTime = { id = "time" },
    tScore0 = { id = "score0" },
    tScore1 = { id = "score1" },
    tScore2 = { id = "score2" },
    tScore3 = { id = "score3" },
    bPlatback = { id = "playback", onClick = "onPlayback" },
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

local function battleHistoryUrl(historyId)
    return string.format("%s/v1/history/%d", appConfig.webService, historyId)
end

local function battleDetailUrl(deskId)
    return string.format("%s/v1/history/lite/%d", appConfig.webService, deskId)
end

function BattleDetailItemUI4:onCreate(showBg, item)
    self.item = item
    printInfo("%s", vardump(item))
    self.tId:setString(item.no)
    self.tTime:setString(item.begin_at_str)
    self.tScore0:setString(item.score_change0)
    self.tScore1:setString(item.score_change1)
    self.tScore2:setString(item.score_change2)
    self.tScore3:setString(item.score_change3)
    self.size = self.nContainer:getContentSize()
    self.nContainer:setVisible(showBg)
end

function BattleDetailItemUI4:getSize()
    return self.size
end

function BattleDetailItemUI4:onPlayback(sender)
    WaitUI.show("正在获取数据")
    local onResponse = function(resp)
        WaitUI.hide()
        if resp.code ~= 0 then
            gameAssistant.showHintAlertUI(resp.error)
        else
            local payload = resp.data
            local snapshot = json.decode(payload.snapshot)
            local tableInfo = {
                deskId = snapshot.basicInfo.deskId,
                createdAt = payload.begin_at,
                --creator = snapshot,
                title = snapshot.basicInfo.title,
                desc = snapshot.basicInfo.desc,
                status = typeDefine.sDeskStatus.lookback,
                snapshot = snapshot,
                mode = snapshot.basicInfo.mode or 3, -- 兼容三人模式
            }
            deskEnterHelper.enterLookback(tableInfo)
        end
    end
    httpRequest(battleHistoryUrl(self.item.id), onResponse, "", "GET")
end

------------------------------------------
function BattleDetailUI4:onCloseWindow(sender)
    gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function BattleDetailUI4:init()
end


function BattleDetailUI4:addInfo(item)
    if #self.historyDetail < 1 then
        for i = 0, 3 do
            local nameKey = string.format("tPlayerName%d", i)
            local nameNode = self[nameKey]
            nameNode:setString(item[string.format("player_name%d", i)])
        end
    end
    table.push(self.historyDetail, {});
    local item = BattleDetailItemUI4:create("", "", #self.historyDetail % 2 == 0, item)
    local layout = ccui.Layout:create()
    layout:addChild(item)
    layout:setContentSize(item:getSize())
    self.lHistory:pushBackCustomItem(layout)
end

function BattleDetailUI4:clear()
    self.lHistory:removeAllItems()
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

function BattleDetailUI4:onShare()
    gameAssistant.playCloseUISound()
    local fileName = "CaptureScreen.png"
    cc.utils:captureScreen(afterCaptured, fileName)
end

function BattleDetailUI4:onCreate(deskId)
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    self.historyDetail = {}
    local ui = self
    scheduler.performWithDelayGlobal(function()
        WaitUI.show("正在获取数据")
        local onResponse = function(resp)
            WaitUI.hide()
            if resp.code ~= 0 then
                gameAssistant.showHintAlertUI(resp.error)
            else
                for i = 1, #resp.data do
                    local item = resp.data[i]
                    item.no = i
                    ui:addInfo(item)
                end
            end
        end
        httpRequest(battleDetailUrl(deskId), onResponse, "", "GET")
    end, 0)
end

return BattleDetailUI4