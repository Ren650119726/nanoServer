local dataManager = require "app.data.dataManager"
local configManager = require "app.config.configManager"
local typeDefine = require "app.data.typeDefine"
local UIStack = require "packages.mvc.UIStack"
local PushWindow = require "app.ui.PushWindow"
local WaitUI = require "app.ui.WaitUi"
local ContactUI = require "app.ui.ContactUI"
local director = cc.Director:getInstance()
local winSize = director:getWinSize()
local scheduler = require "app.core.scheduler"
local networkManager = require "app.network.NetworkManager"

local gameAssistant = {}

function gameAssistant.changeScale(node)
    local nodeSize = node:getContentSize()
    local scaleW = winSize.width / nodeSize.width
    local scaleH = winSize.height / nodeSize.height
    if scaleW >= scaleH then
        node:setScale(scaleW)
    else
        node:setScale(scaleH)
    end
end

function gameAssistant.getUrlFileName(strurl, strchar)
    local ts = string.reverse(strurl)
    local param1, param2 = string.find(ts, strchar)
    local m = string.len(strurl) - param2 + 1
    local result = string.sub(strurl, m + 1, string.len(strurl))
    return result
end

function gameAssistant.openShop()
    local ui = ContactUI:create("", "", gameAssistant)
    UIStack.pushUI(ui)
end

function gameAssistant.showTimeoutAlert(callback)
    gameAssistant.showHintAlertUI("网络超时")
end

function gameAssistant.showHintAlertUI(text, callback)
    local windowTable = {
        title = text,
        yes = {
            title = "确定",
            fun = function()
                if callback then callback() end
                UIStack.popUI()
            end
        }
    }
    local ui = PushWindow:create("", "", windowTable)
    UIStack.pushUI(ui)
end


function gameAssistant.showConfirmUI(text, confirm, cancel)
    local windowTable = {
        title = text,
        yes = {
            title = "确定",
            fun = function()
                UIStack.popUI()
                if confirm then confirm() end
            end
        },
        no = {
            title = "取消",
            fun = function()
                UIStack.popUI()
                if cancel then cancel() end
            end
        }
    }
    local ui = PushWindow:create("", "", windowTable)
    UIStack.pushUI(ui)
end

function gameAssistant.onSessionError()
    gameAssistant.showHintAlertUI("登录已经失效,请重新登录", function()
        local MainLobby = require "app.ui.MainLobby"
        local deskManager = require "app.logic.deskManager"
        if deskManager.getLogicManager() then
            deskManager.onExitTable(typeDefine.sExitType.exitDeskUI)
        end
        MainLobby.exit()
    end)
end

local fxString = {}
fxString[1] = "清一色"
fxString[2] = "清七对"
fxString[3] = "清大对"
fxString[4] = "清带幺"
fxString[5] = "清将对"
fxString[6] = "素番"
fxString[7] = "七对"
fxString[8] = "大对子"
fxString[9] = "全带幺"
fxString[10] = "将对"
fxString[11] = "幺九七对"
fxString[12] = "清龙七对"
fxString[13] = "龙七对"

local fxIcon = {}
function gameAssistant.getFanXingDesc(isQYS,  isIcon)
    local fxDesc
    if isQYS then
        if fanXingType == 0 then
            fxDesc = 1
        elseif fanXingType == 1 then
            fxDesc = 2
        elseif fanXingType == 2 then
            fxDesc = 3
        elseif fanXingType == 3 then
            fxDesc = 4
        elseif fanXingType == 4 then
            fxDesc = 5
        end
    else
        if fanXingType == 0 then
            fxDesc = 6
        elseif fanXingType == 1 then
            fxDesc = 7
        elseif fanXingType == 2 then
            fxDesc = 8
        elseif fanXingType == 3 then
            fxDesc = 9
        elseif fanXingType == 4 then
            fxDesc = 10
        elseif fanXingType == 5 then
            fxDesc = 11
        end
    end

    if isIcon then
        return gameAssistant.getIconDesc(fxDesc)
    end
    fxDesc = gameAssistant.getStringDesc(fxDesc)
    return fxDesc
end

function gameAssistant.getStringDesc(fx)
    return fxString[fx]
end

function gameAssistant.getIconDesc(fx)
    return configManager.fxIconConfig.getFXIcon(fx)
end

function gameAssistant.playBtnClickedSound()
    audioEngine.playEffect(configManager.soundConfig.effectFilePath("click"))
end

function gameAssistant.playCloseUISound()
    audioEngine.playEffect(configManager.soundConfig.effectFilePath("closeWindow"))
end

function gameAssistant.playSwitchUISound()
    audioEngine.playEffect(configManager.soundConfig.effectFilePath("switchui"))
end

function gameAssistant.playSwitchTabSound()
    audioEngine.playEffect(configManager.soundConfig.effectFilePath("switchtab"))
end

function gameAssistant.playErrorSound()
    audioEngine.playEffect(configManager.soundConfig.effectFilePath("error"))
end

function gameAssistant.vibrate()
    ccextplatform.vibrate({ 5, 400 }, -1)
end

function gameAssistant.pay(count, cb)
    -- 暂时屏蔽微信支付
    if true then
        return cb(false)
    end
    thirdsdk.registerScriptPayHandler(function(pluginType, retCode, retContent)
        printInfo("third pay ret: pluginType:%d, retCode:%d, retContent:%s", pluginType, retCode, vardump(retContent))
        if retCode == 0 then
            cb(true, retContent["orderid"])
        else
            cb(false)
        end
        thirdsdk.unregisterScriptPayHandler()
    end)
    local acId = dataManager.playerData:getAcId()
    local count = count or 1
    local param = {
        name = "test production",
        appId = appConfig.appId,
        channelId = appConfig.channelId,
        platform = "wechat",
        extra = "testtesttest",
        url = appConfig.paymentWeb,
        uid = acId,
        count = tostring(count),
    }
    thirdsdk.pay(0, param)
end

local timequeue = { 0, 10, 10, 20, 30, 60 }
function gameAssistant.buy(count)
    WaitUI.show()
    gameAssistant.pay(count, function(ok, orderid)
        if not ok then
            WaitUI.hide()
            gameAssistant.showHintAlertUI("购买失败, 请联系客服微信youxian8806")
        else
            local times = 1
            printInfo(orderid)
            gameAssistant.checkGameserver(orderid, times, function(ok, data)
                WaitUI.hide()
                if ok then
                    gameAssistant.showHintAlertUI(string.format("购买成功"))
                    dataManager.playerData:setCardCount(data.fangka)
                else
                    gameAssistant.showHintAlertUI("购买失败, 请联系客服微信youxian8806")
                end
            end)
        end
    end)
end

function gameAssistant.checkGameserver(orderid, times, callback)
    if times > #timequeue then
        callback(false)
        return
    end
    local waittime = timequeue[times]
    scheduler.performWithDelayGlobal(function()
        networkManager.request("Manager.CheckOrder", { orderid = orderid }, function(data)
            if data.code ~= 0 then
                printInfo("checkGameserver failed:%d, orderid:%s", times, orderid)
                return gameAssistant.checkGameserver(orderid, times + 1, callback)
            else
                callback(true, data)
            end
        end)
    end, waittime)
end

return gameAssistant
