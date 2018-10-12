local EventManager = require "app.core.EventManager"
local HelpUI = require "app.ui.HelpUI"
local BattleInfoUI = require "app.ui.BattleInfoUI"
local UIStack = require "packages.mvc.UIStack"
local LobbyUI = class("CenterMainLobby", cc.load("mvc").ViewBase)
local gameAssistant = require "app.logic.gameAssistant"
local JoinRoomUI = require "app.ui.JoinRoomUI"
local ClubUI = require "app.ui.ClubUI"
local SettingDetailUi = require "app.ui.SettingDetailUi"
local ShareUI = require "app.ui.ShareUI"
local CreateRoomUI = require "app.ui.CreateRoomUI"
local networkManager = require "app.network.NetworkManager"
local deskEnterHelper = require "app.logic.deskEnterHelper"
local scheduler = require("app.core.scheduler")
local basic = require "app.core.basic"
local configManager = require "app.config.configManager"
local dataManager = require "app.data.dataManager"
local WaitUI = require "app.ui.WaitUi"
local LocalRecord = require "app.core.LocalRecord"
local stringDefine = require "app.data.stringDefine"
local deskManager = require "app.logic.deskManager"

event_name.BROADCAST_SYSTEM_MESSAGE = "BROADCAST_SYSTEM_MESSAGE"
event_name.SHOW_BATTLE_INFO = "SHOW_BATTLE_INFO"

LobbyUI.RESOURCE_FILENAME = "layout/lobby_center.csb"
LobbyUI.RESOURCE_BINDING = {
    bCreateRoom = { id = "create_room", onClick = "onCreateRoom" },
    bJoinRoom = { id = "join_room", onClick = "onJoinRoom" },
    bHelp = { id = "buttons,rule", onClick = "onHelp" },
    bShop = { id = "buttons,,buy", onClick = "onShop" },
    bHistory = { id = "buttons,history", onClick = "onHistory" },
    sBackground = { id = "background" },
    mClipboard = { id = "broadcast,clipboard" },
    mBroadcast = { id = "broadcast,clipboard,text" },
    bSetting = { id = "header,setting", onClick = "onSetting" },
    bBuy = { id = "header,buy", onClick = "onBuyCard" },
    bPromotion = { id = "header,promotion", onClick = "onPromotion" },
    bShare = { id = "header,share", onClick = "onShare" },
    sHeadIcon = { id = "header,head_icon" },
    tNickname = { id = "header,nickname" },
    tUid = { id = "header,uid" },
    tCardCount = { id = "header,card_count" },
}

function LobbyUI:checkVersion()
    if not configManager or not configManager.systemConfig then
        return false
    end

    if not configManager.systemConfig.forceUpdate then
        return false
    end

    printInfo("version infomation: %s", vardump(configManager.systemConfig))

    local config = configManager.systemConfig

    local localVersion = appConfig.version
    local remoteVersion = config.version
    if localVersion ~= remoteVersion then
        local platform = device.platform
        local hasNewVersion = false
        local url = ""
        if platform == "android" and config.android then
            url = config.android
            hasNewVersion = true
        elseif platform == "ios" and config.ios then
            url = config.ios
            hasNewVersion = true
        end

        if hasNewVersion then
            gameAssistant.showHintAlertUI("发现新版本，为了保证你的游戏体验，请下载新版本", function()
                basic.openExplore(url)
            end)
            return true
        end
    end
    return false
end

-- 创建房间
function LobbyUI:onCreateRoom()
    if self:checkVersion() then
        return
    end
    gameAssistant.playBtnClickedSound()
    local ui = CreateRoomUI:create("", "", gameAssistant, -1)
    UIStack.pushUI(ui)
end

function LobbyUI:onJoinRoom()
    if self:checkVersion() then
        return
    end

    local ui = JoinRoomUI:create("", "", gameAssistant)
    UIStack.pushUI(ui)
    gameAssistant.playBtnClickedSound()
end

function LobbyUI:onHistory()
    local ui = BattleInfoUI:create()
    UIStack.pushUI(ui)
    gameAssistant.playBtnClickedSound()
end

function LobbyUI:onShop()
    gameAssistant.playBtnClickedSound()
    --gameAssistant:openShop()
    local ui = ClubUI:create()
    UIStack.pushUI(ui)
end

function LobbyUI:onHelp()
    local ui = HelpUI:create()
    UIStack.pushUI(ui)
    gameAssistant.playBtnClickedSound()
end

--- cloudvoice code枚举值
local GV_ON_JOINROOM_SUCC = 1 --join room succ
local GV_ON_JOINROOM_TIMEOUT = 2 --join room timeout
local GV_ON_JOINROOM_SVR_ERR = 3 --communication with svr occur some err, such as err data recv from svr
local GV_ON_JOINROOM_UNKNOWN = 4 --reserved, our internal unknow err
local GV_ON_NET_ERR = 5 --net err,may be can't connect to network
local GV_ON_QUITROOM_SUCC = 6 --quitroom succ, if you have join room succ first, quit room will alway return succ
local GV_ON_MESSAGE_KEY_APPLIED_SUCC = 7 --apply message authkey succ
local GV_ON_MESSAGE_KEY_APPLIED_TIMEOUT = 8 --apply message authkey timeout
local GV_ON_MESSAGE_KEY_APPLIED_SVR_ERR = 9 --communication with svr occur some err, such as err data recv from svr
local GV_ON_MESSAGE_KEY_APPLIED_UNKNOWN = 10 --reserved,  our internal unknow err
local GV_ON_UPLOAD_RECORD_DONE = 11 --upload record file succ
local GV_ON_UPLOAD_RECORD_ERROR = 12 --upload record file occur error
local GV_ON_DOWNLOAD_RECORD_DONE = 13 --download record file succ
local GV_ON_DOWNLOAD_RECORD_ERROR = 14 --download record file occur error
local GV_ON_STT_SUCC = 15 -- speech to text successful
local GV_ON_STT_TIMEOUT = 16 -- speech to text with timeout
local GV_ON_STT_APIERR = 17 -- server's error
local GV_ON_PLAYFILE_DONE = 18 --the record file played end

local function handleRecord(code, filepath, fileId)
    if code == GV_ON_DOWNLOAD_RECORD_DONE then
        audioEngine.pause()
        cloudvoice.playRecordedFile(filepath)
    elseif code == GV_ON_PLAYFILE_DONE then
        audioEngine.resume()
    elseif code == GV_ON_UPLOAD_RECORD_DONE and fileId then
        networkManager.notify("DeskManager.RecordingVoice", { fileId = fileId })
    end
end

local function onApplyMessageKey(code)
    if code == GV_ON_MESSAGE_KEY_APPLIED_SUCC then
        cloudvoice.isReady = true
        printInfo("cloudvoice system initialize successfully")
    else
        printInfo("cloudvoice system apply message key, code=%d", code)
    end
end

local function onRecording()
    printInfo("cloudvoice:onRecording")
end

function LobbyUI:delayTask()
    -- 延迟腾讯实时语音初始化
    scheduler.performWithDelayGlobal(function()
        cloudvoice.isReady = false
        local appId = configManager.systemConfig.appId
        local appKey = configManager.systemConfig.appKey
        local openid = dataManager.loginData:getUid()
        printInfo("cloudVoiceAppId: %s, cloudVoiceAppKey: %s, openId: %s", appId, appKey, openid)
        local cloudVoiceInited = cloudvoice.init(appId, appKey, openid)
        printInfo("cloudvoice init result: %s", vardump(cloudVoiceInited))
        if cloudVoiceInited then
            cloudvoice.on("onUploadFile", handleRecord)
            cloudvoice.on("onDownloadFile", handleRecord)
            cloudvoice.on("onPlayRecordedFile", handleRecord)
            cloudvoice.on("onApplyMessageKey", onApplyMessageKey)
            cloudvoice.on("onRecording", onRecording)
        end
        self.cloudvoiceHandler = scheduler.scheduleGlobal(function() cloudvoice.update() end, 1)
    end, 5)
end

function LobbyUI:scrolling(dt)
    local clipWidth = self.mClipboard:getContentSize().width
    local broaWidth = self.mBroadcast:getContentSize().width
    local newX = self.mBroadcast:getPositionX() - 4
    if newX <= -broaWidth / 2 then
        -- swich broadcast message
        self.mBroadcast:setString(dataManager.broadcast.next())
        broaWidth = self.mBroadcast:getContentSize().width
        newX = clipWidth + broaWidth / 2
    end

    self.mBroadcast:setPositionX(newX);
end

function LobbyUI:detectClipboard()
    -- 查看剪切板是否包含房号
    local text = clipboard.read()
    if not text then
        return
    end
    local header = utfstrlen(appConfig.prefix)
    if not text or utfstrlen(text) < header or (appConfig.prefix) ~= subUTF8String(text, 1, header) then
        return
    end

    local number = subUTF8String(text, header + 1)
    local deskNo = string.match(number, "%d+")
    -- 房号是6位数字，如果不是6位，则不识别
    if utfstrlen(deskNo) ~= 6 then
        return
    end

    -- 加入房间
    local hint = string.format("您确定要进入房间 %s 吗?", deskNo)
    -- 检测到房号后，清空剪切板
    clipboard.copy("")

    local comfirm = function()
        LocalRecord.instance():setProperty(stringDefine.LAST_JOIN_DESK_NO, nil)
        local payload = {
            version = appConfig.version,
            deskId = deskNo,
        }
        WaitUI.show()
        networkManager.request("DeskManager.Join", payload, function(resp)
            WaitUI.hide()
            if resp.code ~= 0 then
                gameAssistant.showHintAlertUI(resp.error)
            else
                deskEnterHelper.enterClassicMatch(resp.tableInfo)
            end
        end)
    end
    gameAssistant.showConfirmUI(hint, comfirm)
end

function LobbyUI:onCreate(lobby)
    gameAssistant.changeScale(self.sBackground)
    gameAssistant.playSwitchUISound()
    self.lobby = lobby

    networkManager.request("DeskManager.UnCompleteDesk", {}, function(resp)
        self:delayTask()
        --是否存在未完成的房间, 如果之前没有房间，则检查是否进入剪切板中的房间
        if resp.exist then
            deskEnterHelper.enterClassicMatch(resp.tableInfo)
        else
            self:detectClipboard()
        end
    end)

    local ar = cc.ParticleSystemQuad:create("particle/lobby/lobby.plist")
    self.root:addChild(ar)

    -- 数据绑定
    local name = dataManager.playerData:getNickname()
    if utfstrlen(name) > 8 then
        name = string.format("%s...", subUTF8String(name, 1, 6))
    end
    self:updateNickname(name)
    self:updateUid(dataManager.playerData:getId())
    self:updateCardCount(dataManager.playerData:getCardCount())

    if dataManager.playerData:getHeadIcon() and dataManager.playerData:getHeadIcon() ~= "" then
        self:updateHeadIcon(dataManager.playerData:getHeadIcon())
    end

    self.mBroadcast:setString(dataManager.broadcast.next())
end

function LobbyUI:updateNickname(name)
    self.tNickname:setText(name)
end

function LobbyUI:updateUid(id)
    self.tUid:setText(id)
end

function LobbyUI:updateCardCount(count)
    self.tCardCount:setText(count)
end

function LobbyUI:updateHeadIcon(icon)
    self.sHeadIcon:setScale(1)
    self.sHeadIcon:setTexture(icon)
    self.sHeadIcon:setScale(67 / self.sHeadIcon:getContentSize().width)
end

function LobbyUI:onBroadcast(event)
    dataManager.broadcast.append(event.message)
end

function LobbyUI:onSetting()
    local ui = SettingDetailUi:create("", "", self.lobby)
    UIStack.pushUI(ui)
    gameAssistant.playBtnClickedSound()
end

function LobbyUI:onBuyCard()
    gameAssistant.playBtnClickedSound()
    gameAssistant:openShop()
end

function LobbyUI:onPromotion()
    gameAssistant.playBtnClickedSound()
    gameAssistant.showHintAlertUI("即将开放，敬请期待")
end

function LobbyUI:onShare()
    gameAssistant.playBtnClickedSound()
    local ui = ShareUI:create("", "", gameAssistant)
    UIStack.pushUI(ui)
end

---------------------------------------------------------------------------------
--- EVENT HANDLER
---------------------------------------------------------------------------------
function LobbyUI:onHeadIconChanged(event)
    if tostring(event.id) == tostring(dataManager.playerData:getAcId()) then
        self:updateHeadIcon(event.head)
    end
end

function LobbyUI:onCardCountChanged(event)
    self:updateCardCount(event.newValue)
end

function LobbyUI:onNicknameChanged(event)
    self:updateNickname(event.newValue)
end

function LobbyUI:applicationStatusChange(event)
    if not event.resume or deskManager.isJoinedDesk then
        return
    else
        self:detectClipboard()
    end
end

function LobbyUI:registEvent()
    print("LobbyUI:registEvent")
    self._, self.updateBroadcastHandler = EventManager:addEventListener(event_name.BROADCAST_SYSTEM_MESSAGE, handler(self, self.onBroadcast))
    self._, self.showBattleInfoHandler = EventManager:addEventListener(event_name.SHOW_BATTLE_INFO, handler(self, self.onHistory))
    self.scrollingHandler = scheduler.scheduleGlobal(handler(self, LobbyUI.scrolling), 0.1)

    self._, self.nicknameChangedHandler = EventManager:addEventListener(event_name.PLAYERDATA_NICKNAME_CHANGED, handler(self, self.onNicknameChanged))
    self._, self.headChangedHandler = EventManager:addEventListener(event_name.PLAYERDATA_HEADICON_CHANGED, handler(self, self.onHeadIconChanged))
    self._, self.cardCountChangedHandler = EventManager:addEventListener(event_name.PLAYERDATA_CARD_COUNT_CHANGED, handler(self, self.onCardCountChanged))

    self._, self.applicationStatusChangeHandler = EventManager:addEventListener("APPLICATION_STATUS_CHANGE", handler(self, self.applicationStatusChange))
end

function LobbyUI:unregistEvent()
    print("LobbyUI:unregistEvent")
    scheduler.unscheduleGlobal(self.scrollingHandler)
    scheduler.unscheduleGlobal(self.cloudvoiceHandler)
    scheduler.unscheduleGlobal(self.heartbeatHandler)
    EventManager:removeEventListener(self.updateBroadcastHandler)
    EventManager:removeEventListener(self.showBattleInfoHandler)

    EventManager:removeEventListener(self.nicknameChangedHandler)
    EventManager:removeEventListener(self.headChangedHandler)
    EventManager:removeEventListener(self.cardCountChangedHandler)
    EventManager:removeEventListener(self.applicationStatusChangeHandler)
end

return LobbyUI