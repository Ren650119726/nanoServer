local DeskUI = class("DeskUI", cc.load("mvc").ViewBase)
local Desk3DUIClass = require "app.ui.Desk3DUI"
local DeskBackground = require "app.ui.DeskBackground"
local DeskHeadUIClass = require "app.ui.DeskHeadUI"
local DissolveUI = require "app.ui.DissolveUI"
local DissolveUI4 = require "app.ui.DissolveUI4"
local BattleOverUI = require "app.ui.BattleOverUI"
local BattleOverUI4 = require "app.ui.BattleOverUI4"
local dataManager = require "app.data.dataManager"
local deskManager = require "app.logic.deskManager"
local scheduler = require("app.core.scheduler")
local PGChooseUIClass = require "app.ui.PGChooseUI"
local MJDataClass = require "app.core.MJData"
local UIStack = cc.load("mvc").UIStack
local networkManager = require "app.network.NetworkManager"
local eventManager = require "app.core.EventManager"
local TimeCount = require "app.core.TimeCount"
local HelpUI = require "app.ui.HelpUI"
local SettingUI = require "app.ui.SettingUi"
local configManager = require "app.config.configManager"
local stringDefine = require "app.data.stringDefine"
local RoundOver = require "app.ui.RoundOver"
local RoundOver4 = require "app.ui.RoundOver4"
local gameAssistant = require "app.logic.gameAssistant"
local LocalRecord = require "app.core.LocalRecord"
local typeDefine = require "app.data.typeDefine"
local HttpRequest = require "app.network.HttpRequest"

local NORMAL_MESSAGE_HINT_TAG = 1001
local DDD_ACTION_TAG = 1002
local SELF_DIRECTION = 1
local voiceRecodingPath = string.format("%srecording.mp3", cc.FileUtils:getInstance():getWritablePath())

local voiceMessageText = {
    "你太牛了",
    "哈哈，手气真好",
    "快点出牌哟",
    "今天真高兴",
    "你放炮，我不胡",
    "你家里是开银行的吧",
    "不好意思，我有事要先走一步了",
    "你的牌打得太好了",
    "大家好，很高兴见到各位",
    "怎么又断线了，网络怎么这么差呀",
}

--- 提示图标路径
local iconTipsType = {
    wujiao = "desk_ui/game_icon_wujiao.png",
    hukou = "desk_ui/hukou_notify-hd.png",
    koupai = "desk_ui/koucard_notify-hd.png",
}

--- 头像位置
local headIconPositioin = {
    cc.p(55, 180),
    cc.p(1225, 480),
    cc.p(960, 605),
    cc.p(55, 480),
}

local NORMAL_MESSAGE_HINT_TAG = 1001
local DDD_ACTION_TAG = 1002
local QUE_TIAO = 1
local QUE_TONG = 2
local QUE_WAN = 3
--------------------------- que----------------------------------
local QueChooseUI = class("QueChooseUI", cc.load("mvc").ViewBase)
QueChooseUI.RESOURCE_FILENAME = "layout/que_choose.csb"
QueChooseUI.RESOURCE_BINDING = {
    m_tiao = { id = "tiao", onClick = "onTiaoClicked" },
    m_tong = { id = "tong", onClick = "onTongClicked" },
    m_wan = { id = "wan", onClick = "onWanClicked" },
    m_tiaobg = { id = "tiaobg", onClick = "onTiaoClicked" },
    m_tongbg = { id = "tongbg", onClick = "onTongClicked" },
    m_wanbg = { id = "wanbg", onClick = "onWanClicked" },
}

local HUASE_ICON = { "images/desk/game_icon_tiao.png", "images/desk/game_icon_tong.png", "images/desk/game_icon_wan.png" }
function QueChooseUI:onTiaoClicked(sender, uievent)
    if self.m_isCanClicked then
        self:onChoose(QUE_TIAO)
    end
end

function QueChooseUI:onTongClicked(sender, uievent)
    if self.m_isCanClicked then
        self:onChoose(QUE_TONG)
    end
end

function QueChooseUI:onWanClicked(sender, uievent)
    if self.m_isCanClicked then
        self:onChoose(QUE_WAN)
    end
end

function QueChooseUI:onChoose(idx)
    self.m_isCanClicked = false
    self.m_manager:onQueChoose(idx)
end

function QueChooseUI:getIconWp(idx)
    local pos = cc.p(self.m_btns[idx]:getPosition())
    return self:convertToWorldSpace(pos)
end

function QueChooseUI:showUI(default)
    print("===>QueChooseUI:showUI", default)
    self:show()
    self.m_isCanClicked = true
    default = default or 1
    self.m_light:show()
    self.m_light:setPosition(self.m_btns[default]:getPosition())
    if default == QUE_TIAO then
        self.m_light:getAnimation():play("tiao")
    elseif default == QUE_TONG then
        self.m_light:getAnimation():play("tong")
    elseif default == QUE_WAN then
        self.m_light:getAnimation():play("wan")
    end
end

function QueChooseUI:onCreate(manager, default)
    self.m_manager = manager
    self.m_btns = {}
    self.m_btns[1] = self.m_tiao
    self.m_btns[2] = self.m_tong
    self.m_btns[3] = self.m_wan
    self.m_isCanClicked = false
    self:hide()

    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/tiaoGX/tiaoGX.csb")
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/queDefaultHint/queDefaultHint.csb")
    self.m_light = ccs.Armature:create("tiaoGX")
    self:addChild(self.m_light)
    self.m_light:hide()
end

--------------------------- end-----------------------------------

--------------------------- operate-------------------------------
local MJOperateUI = class("MJOperateUI", cc.Node)

local OPERATECHOOSE_GAP = 150
function MJOperateUI:hidePChooseUI()
    if self.m_pChooseUI then
        self.m_pChooseUI:removeSelf()
        self.m_pChooseUI = nil
    end
end

function MJOperateUI:onPDataChoose(mjData)
    self.m_manager:onGangChoose(mjData:getNetValue())
    self.m_isChoosed = true
end

function MJOperateUI:changeToPChooseUI(vec)
    self:hideAllBtn()
    self.m_qx:show()
    self.m_qx:setPositionX(0)
    self.m_qx:setLocalZOrder(1)
    local ui = PGChooseUIClass:create("", "", vec, handler(self, MJOperateUI.onPDataChoose))
    ui:setPositionX(-OPERATECHOOSE_GAP)
    ui:setPositionY(self.m_qx:getPositionY())
    self:addChild(ui)
    self.m_pChooseUI = ui
end

function MJOperateUI:onGangClicked()
    if self.m_isChoosed then
        return
    end
    self.m_isChoosed = true
    --self.m_manager:onGangChoose()
    --self:changeToPChooseUI()
    local vec = self.m_manager:getGangVec()
    if #vec == 1 then
        self.m_manager:onGangChoose(vec[1].mjData:getNetValue())
    else
        self:changeToPChooseUI(vec)
    end
end

function MJOperateUI:onPengClicked()
    if self.m_isChoosed then
        return
    end
    self.m_isChoosed = true
    self.m_manager:onPengChoose()
end

function MJOperateUI:onHuClicked()
    if self.m_isChoosed then
        return
    end
    self.m_isChoosed = true
    self.m_manager:onHuChoose()
end

function MJOperateUI:onGuoClicked()
    if self.m_isChoosed then
        return
    end
    self.m_isChoosed = true
    self.m_manager:onGuoChoose()
end

function MJOperateUI:onQxClicked()
    self.m_isChoosed = false
    if self.m_pChooseUI then
        self:hidePChooseUI()
        self.m_qx:hide()
        self:showChoose(nil)
    end
end

function MJOperateUI:ctor(manager)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/pengGX/pengGX.csb")
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/gangGX/gangGX.csb")
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/huGX/huGX.csb")

    self.m_isChoosed = false
    self.isLookback = false
    self.m_manager = manager
    --gang
    self.m_gang = ccui.Button:create("desk_ui/game_btn_pt_gang.png")
    self.m_gang:addClickEventListener(handler(self, MJOperateUI.onGangClicked))
    self:addChild(self.m_gang)
    self.m_gangGX = ccs.Armature:create("gangGX")
    self.m_gangGX:setPosition(cc.p(70, 70))
    self.m_gang:addChild(self.m_gangGX)
    self.m_gang.ani = self.m_gangGX
    --peng
    self.m_peng = ccui.Button:create("desk_ui/game_btn_pt_peng.png")
    self.m_peng:addClickEventListener(handler(self, MJOperateUI.onPengClicked))
    self:addChild(self.m_peng)
    self.m_pengGX = ccs.Armature:create("pengGX")
    self.m_pengGX:setPosition(cc.p(70, 70))
    self.m_peng:addChild(self.m_pengGX)
    self.m_peng.ani = self.m_pengGX

    --hu
    self.m_hu = ccui.Button:create("desk_ui/game_btn_pt_hu.png")
    self.m_hu:addClickEventListener(handler(self, MJOperateUI.onHuClicked))
    self:addChild(self.m_hu)
    self.m_huGX = ccs.Armature:create("huGX")
    self.m_huGX:setPosition(cc.p(70, 70))
    self.m_hu:addChild(self.m_huGX)
    self.m_hu.ani = self.m_huGX
    --guo
    self.m_guo = ccui.Button:create("desk_ui/game_btn_pt_guo.png")
    self.m_guo:addClickEventListener(handler(self, MJOperateUI.onGuoClicked))
    self:addChild(self.m_guo)
    --quxiao
    self.m_qx = ccui.Button:create("desk_ui/game_btn_pt_quxiao.png")
    self.m_qx:addClickEventListener(handler(self, MJOperateUI.onQxClicked))
    self:addChild(self.m_qx)

    self.m_paixu = { "peng", "gang", "hu", "guo" }
    self.m_btnPaiXu = { self.m_peng, self.m_gang, self.m_hu, self.m_guo }
    self.m_chooseVec = nil

    self:hideAllBtn()
end

function MJOperateUI:hide()
    self:setVisible(false)
    self:hideAllBtn()
end

function MJOperateUI:hideAllBtn()
    self.m_gang:hide()
    self.m_peng:hide()
    self.m_hu:hide()
    self.m_guo:hide()
    self.m_qx:hide()
    self:hidePChooseUI()
end

function MJOperateUI:showChoose(vec)
    if not vec and not self.m_chooseVec then return end
    if vec then self.m_chooseVec = vec end
    self.m_isChoosed = false
    self:_showChoose(self.m_chooseVec)
end

function MJOperateUI:_showChoose(vec)
    self:hideAllBtn()
    local idx = 0
    local count = #self.m_paixu
    for i = count, 1, -1 do
        local tmp = self.m_paixu[i]
        local isIn = table.indexof(vec, tmp)
        if isIn then
            local pos = -idx * OPERATECHOOSE_GAP
            local btn = self.m_btnPaiXu[i]
            btn:setPositionX(pos)
            btn:show()
            if btn.ani then
                btn.ani:getAnimation():playWithIndex(0)
            end
            idx = idx + 1
        end
    end
    self:show()
end

DeskUI.RESOURCE_FILENAME = "layout/desk_ui.csb"
DeskUI.RESOURCE_BINDING = {
    m_micRecording = { id = "micRecording" },
    m_microphoneIcon = { id = "micRecording,microphone" },
    m_battery = { id = "time,batteryTxt" },
    m_delay = { id = "time,delay" },
    m_network = { id = "time,wifi" },
    uiRestTileInfo = { id = "rest_tile" },
    uiRestTileCount = { id = "rest_tile,count" },
    m_posCoinChange1 = { id = "score,p1" },
    m_posCoinChange2 = { id = "score,p2" },
    m_posCoinChange3 = { id = "score,p3" },
    m_posCoinChange4 = { id = "score,p4" },
    m_negCoinChange1 = { id = "score,n1" },
    m_negCoinChange2 = { id = "score,n2" },
    m_negCoinChange3 = { id = "score,n3" },
    m_negCoinChange4 = { id = "score,n4" },
    m_top_right = { id = "top_right" },
    m_exitBtn = { id = "top_right,exit", onClick = "onExitDesk" },
    m_voiceBtn = { id = "top_right,voice", onUITouch = "onVoice" },
    m_voiceMessage = { id = "top_right,voiceMessage", onClick = "onVoiceMessage" },
    m_settingBtn = { id = "top_right,setting", onClick = "onSetting" },
    m_timeLabel = { id = "time,timeLabel" },
    m_dir1Start = { id = "anim,dir1Start" },
    m_dir2Start = { id = "anim,dir2Start" },
    m_dir3Start = { id = "anim,dir3Start" },
    m_dir4Start = { id = "anim,dir4Start" },
    m_dir1Hu = { id = "anim,dir1Hu" },
    m_dir2Hu = { id = "anim,dir2Hu" },
    m_dir3Hu = { id = "anim,dir3Hu" },
    m_dir4Hu = { id = "anim,dir4Hu" },
    m_gangEffect1 = { id = "anim,gangEffect1" },
    m_gangEffect2 = { id = "anim,gangEffect2" },
    m_gangEffect3 = { id = "anim,gangEffect3" },
    m_gangEffect4 = { id = "anim,gangEffect4" },
    m_fontAnimationLayer = { id = "anim" },
    m_iconTips1 = { id = "iconTipsPosition,iconTips1" },
    m_iconTips2 = { id = "iconTipsPosition,iconTips2" },
    m_iconTips3 = { id = "iconTipsPosition,iconTips3" },
    m_iconTips4 = { id = "iconTipsPosition,iconTips4" },
    m_normalMessageHint = { id = "normalMessageHint" },
    m_voiceListView = { id = "message" },
    m_voiceListItem1 = { id = "message,listview,message1", onClick = "onVoiceMessageSelected" },
    m_voiceListItem2 = { id = "message,listview,message2", onClick = "onVoiceMessageSelected" },
    m_voiceListItem3 = { id = "message,listview,message3", onClick = "onVoiceMessageSelected" },
    m_voiceListItem4 = { id = "message,listview,message4", onClick = "onVoiceMessageSelected" },
    m_voiceListItem5 = { id = "message,listview,message5", onClick = "onVoiceMessageSelected" },
    m_voiceListItem6 = { id = "message,listview,message6", onClick = "onVoiceMessageSelected" },
    m_voiceListItem7 = { id = "message,listview,message7", onClick = "onVoiceMessageSelected" },
    m_voiceListItem8 = { id = "message,listview,message8", onClick = "onVoiceMessageSelected" },
    m_voiceListItem9 = { id = "message,listview,message9", onClick = "onVoiceMessageSelected" },
    m_voiceListItem10 = { id = "message,listview,message10", onClick = "onVoiceMessageSelected" },
    m_deskId = { id = "deskId,label" },
    m_deskRule = { id = "deskId,rule" },
    m_shareOp = { id = "action" },
    m_shareOpWechat = { id = "action,wechat", onClick = "onWechatShare" },
    m_shareOpDeskNo = { id = "action,share_no", onClick = "onShareDeskNo" },
    uiHuHint = { id = "hu" },
    m_version = { id = "version" },
    mClipboard = { id = "broadcast,clipboard" },
    mBroadcast = { id = "broadcast,clipboard,text" },
}
function DeskUI:onExitDesk()
    self:clearUIWhenClickNone(true, true)
    gameAssistant.playBtnClickedSound()

    -- 回放退出
    if self.isLookback then
        deskManager.exit()
        return
    end

    if deskManager.getTotalPeopleCnt() < self.mode then
        local isCreator = deskManager.getCreator() == dataManager.playerData:getAcId()
        local msg = isCreator and "是否解散房间" or "是否退出房间"
        gameAssistant.showConfirmUI(msg, function()
            LocalRecord.instance():setProperty(stringDefine.LAST_JOIN_DESK_NO, nil)
            networkManager.notify("DeskManager.Exit", { isDestroy = isCreator })
        end)
    else
        local msg = "是否发起解散房间请求?"
        gameAssistant.showConfirmUI(msg, function()
            networkManager.notify("DeskManager.Dissolve", {})
        end)
    end
end

function DeskUI:onDissolveAgreement(data)
    -- 创建新的解散界面
    if self.mode == MODE_FOURS then
        local ui = DissolveUI4:create("", "", data.dissolveStatus, dataManager.playerData:getAcId() == data.dissolveUid, data.restTime)
        self.isDissolveDialogShow = true
        UIStack.pushUI(ui)
    else
        local ui = DissolveUI:create("", "", data.dissolveStatus, dataManager.playerData:getAcId() == data.dissolveUid, data.restTime)
        self.isDissolveDialogShow = true
        UIStack.pushUI(ui)
    end
end

--- 关闭解散对话框
-- @param queList
--
function DeskUI:onDissolveFailure(data)
    if not self.isDissolveDialogShow then
        return
    end
    eventManager:dispatchEvent({ name = event_name.CLOSE_DISSOLVE_UI })
    self.isDissolveDialogShow = false

    if not data then
        return
    end
    local player = deskManager.getPlayerData(data.deskPos)
    gameAssistant.showHintAlertUI(player:getNickname() .. "拒绝解散房间")
end

function DeskUI:onVoice(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        audioEngine.pause()
        --cloudvoice.openMic()
        cloudvoice.startRecording(voiceRecodingPath)
        local action = cc.Blink:create(100, 100)
        self.m_micRecording:setVisible(true)
        self.m_microphoneIcon:runAction(action)
    elseif eventType == ccui.TouchEventType.ended or eventType == ccui.TouchEventType.canceled then
        --cloudvoice.closeMic()
        cloudvoice.stopRecording()
        audioEngine.resume()
        cloudvoice.uploadRecordedFile(voiceRecodingPath, 60000)
        self.m_microphoneIcon:stopAllActions()
        self.m_micRecording:setVisible(false)
    end
end

function DeskUI:initVoiceMessageText()
    for i = 1, 10 do
        local name = string.format("m_voiceListItem%d", i)
        local node = self[name]
        local text = node:getChildByName("text")
        text:setString(voiceMessageText[i])
    end
end

function DeskUI:onVoiceMessage(sender)
    if self.isVoiceMessageListVisible then
        self.m_voiceListView:setVisible(false)
        self.isVoiceMessageListVisible = false
    else
        self.m_voiceListView:setVisible(true)
        self.isVoiceMessageListVisible = true
    end
end

function DeskUI:onVoiceMessageSelected(sender)
    self.m_voiceListView:setVisible(false)
    self.isVoiceMessageListVisible = false
    local name = sender:getName()
    local index = 1
    for i = 1, 10 do
        if name == string.format("message%s", i) then
            index = i
            break
        end
    end
    networkManager.notify("DeskManager.VoiceMessage", { index = index, uid = dataManager.playerData:getAcId() })
end

function DeskUI:onSetting()
    self:clearUIWhenClickNone(true, true)
    self:clearUIWhenClickNone(true, true)
    local ui = SettingUI:create()
    UIStack.pushUI(ui)
    gameAssistant.playBtnClickedSound()
end

function DeskUI:onStart(sender, eventType)
    gameAssistant.playBtnClickedSound()
    self:clearUIWhenClickNone(true, true)
    deskManager.onStartChoose()
end

function DeskUI:_addHeadInfoUI(idx)
    local ui = DeskHeadUIClass:create("", "", idx)
    if idx == 1 or idx == 4 then
        ui:setAnchorPoint(cc.p(0, 0))
    else
        ui:setAnchorPoint(cc.p(1, 0))
    end
    ui:registerEvent()
    local pos = headIconPositioin[idx]
    ui:setPosition(pos)
    self.m_headUIs[idx] = ui
    self:addChild(ui)
    ui:setDir(idx)
    if idx ~= 1 then ui:hide() end
    return ui
end

function DeskUI:updateTime()
    local curTime = os.date("*t")
    local hourStr = string.format("%02d", curTime.hour)
    local minStr = string.format("%02d", curTime.min)
    local str = hourStr .. ":" .. minStr
    self.m_timeLabel:setString(str)
end

local delayGreen = cc.c3b(35, 193, 59)
local delayYellow = cc.c3b(244, 211, 79)
local delayRed = cc.c3b(206, 28, 28)
local pingUrl = string.format("%s/ping", appConfig.webService)
function DeskUI:updateNetInfo()
    local battery = ccextplatform.getBatteryInfo() .. "%"
    local netinfo = string.split(ccextplatform.getNetInfo())
    local network = string.format("signal/%s.png", ccextplatform.getNetInfo())
    self.m_battery:setString(battery)
    self.m_network:setTexture(network)

    -- 测试延迟
    local start = usertime.getmillisecond()
    local function onResponse(ok, str)
        -- 如果响应的时候, 房间已经结束了, 直接返回
        if self.m_delay == nil or not self.m_delay.setTextColor or not self.m_delay.setString then
            return
        end

        -- 当前时间
        local current = usertime.getmillisecond()
        local diff = math.floor((current - start) / 2)
        local color = (diff < 100 and delayGreen) or (diff < 200 and delayYellow) or delayRed
        self.m_delay:setTextColor(color)
        self.m_delay:setString(string.format("%dms", diff))
    end

    HttpRequest.send(pingUrl, onResponse, "PING", "GET")
end

function DeskUI:scrolling(dt)
    local clipWidth = self.mClipboard:getContentSize().width
    local broaWidth = self.mBroadcast:getContentSize().width
    local newX = self.mBroadcast:getPositionX() - 4
    if newX <= -broaWidth / 2 then
        self.mBroadcast:setString(dataManager.broadcast.next())
        broaWidth = self.mBroadcast:getContentSize().width
        newX = clipWidth + broaWidth / 2
    end

    self.mBroadcast:setPositionX(newX);
end

function DeskUI:update(dt)
    self:updateNetInfo()
    self:updateTime()
end

function DeskUI:hideShareOp()
    self.m_shareOp:setVisible(false)
end

function DeskUI:showShareOp()
    self.m_shareOp:setVisible(true)
end

function DeskUI:initAsync()
    -- 控制调试开关(连续点击屏幕)
    self.comboCount = 0;
    self.lastClickAt = 0;

    self.m_version:setString(string.format("v%s", appConfig.version))
    self.m_hasScoreGainShow = false
    self.root:setLocalZOrder(3)

    self.m_manager = manager
    self.uiRestTileInfo:setVisible(false)
    --3d desk
    coroutine.yield()

    local tt = TimeCount:create("onCreate:")
    tt:start("create 3ddesk")
    self.m_desk3d = Desk3DUIClass:create(nil, nil, manager, true)
    self:addChild(self.m_desk3d)
    self.m_desk3d:initAsync()
    tt:stop()
    coroutine.yield()

    local visibleSize = cc.Director:getInstance():getWinSize()
    local _camera = cc.Camera:createOrthographic(visibleSize.width, visibleSize.height, 0, 1)
    _camera:setCameraFlag(cc.CameraFlag.USER2)
    _camera:setCameraMask(cc.CameraFlag.USER2)
    _camera:setDepth(-1); --设置为最底部
    self.root:addChild(_camera);

    self.globalBakcground = DeskBackground:create(nil, nil)
    self:addChild(self.globalBakcground)
    self.globalBakcground:setGlobalZOrder(100)
    self.globalBakcground:setCameraMask(cc.CameraFlag.USER2)
    local gbgSize = self.globalBakcground:getSize()
    local scaleW = display.width / gbgSize.width
    local scaleH = display.height / gbgSize.height
    self.globalBakcground:setScale(scaleW, scaleH)

    -- 头像位置调整
    for i = 1, 4 do
        headIconPositioin[i].y = headIconPositioin[i].y * scaleH
    end

    --head icon pos
    tt:start("create head icon")
    self.m_headUIs = {}

    local ui = self:_addHeadInfoUI(1)
    self:setHeadInfoByPlayerData(ui, dataManager.playerData)
    coroutine.yield()

    self:_addHeadInfoUI(2)
    self:_addHeadInfoUI(3)
    coroutine.yield()
    self:_addHeadInfoUI(4)
    tt:stop()

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(function(touch, event)
        return self:onTouchBegin(touch, event)
    end, cc.Handler.EVENT_TOUCH_BEGAN)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

    coroutine.yield()

    local size = display.size
    --exit arrow

    --ding que choose ui
    tt:start("create QueChooseUI")
    self.m_queChooseUI = QueChooseUI:create(self.m_manager)
    self.m_queChooseUI:setPosition(display.center.x, display.center.y - 140)
    self:addChild(self.m_queChooseUI)
    tt:stop()
    coroutine.yield()

    --peng gang hu operate choose ui
    tt:start("create MJOperateUI")
    self.m_operateUI = MJOperateUI:create(self.m_manager)
    self.root:addChild(self.m_operateUI)
    self.m_operateUI:setPosition(display.center.x + 380, display.center.y - 190)
    self.m_operateUI:showChoose({ "hu", "peng", "gang", "guo" })
    self:hideOperateUI()
    self.m_operateUI:setLocalZOrder(1)

    self.m_totalSeatCount = 4
    tt:stop()
    coroutine.yield()

    tt:start("create left")
    self:updateTime()
    coroutine.yield()

    --test for show error message.
    self.m_msgLabel = createLabel("", 30, cc.TEXT_ALIGNMENT_CENTER)
    self.m_msgLabel:setAnchorPoint(display.CENTER)
    self.m_msgLabel:setPosition(display.center)
    self.m_msgLabel:setColor(cc.c3b(255, 0, 0))
    self.m_msgLabel:hide()
    self:addChild(self.m_msgLabel)
    coroutine.yield()

    local layer = cc.Layer:create()
    self:addChild(layer)
    layer:setLocalZOrder(2)
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(function(touch, event)
        local hasMj = self.m_desk3d:onTouchBegin(touch, event)
        self:clearUIWhenClickNone(true, true, not hasMj)
        return false
    end, cc.Handler.EVENT_TOUCH_BEGAN)
    local eventDispatcher = self:getEventDispatcher()

    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)
    coroutine.yield()

    --test for show gang pai coin change
    self.m_posScoreChanges = {}
    self.m_posScoreChanges[1] = self.m_posCoinChange1
    self.m_posScoreChanges[2] = self.m_posCoinChange2
    self.m_posScoreChanges[3] = self.m_posCoinChange3
    self.m_posScoreChanges[4] = self.m_posCoinChange4
    self.m_negScoreChanges = {}
    self.m_negScoreChanges[1] = self.m_negCoinChange1
    self.m_negScoreChanges[2] = self.m_negCoinChange2
    self.m_negScoreChanges[3] = self.m_negCoinChange3
    self.m_negScoreChanges[4] = self.m_negCoinChange4
    coroutine.yield()

    --font start pos
    self.m_fontAnimationStartPos = {}
    self.m_fontAnimationStartPos[1] = cc.p(self.m_dir1Start:getPosition())
    self.m_fontAnimationStartPos[2] = cc.p(self.m_dir2Start:getPosition())
    self.m_fontAnimationStartPos[3] = cc.p(self.m_dir3Start:getPosition())
    self.m_fontAnimationStartPos[4] = cc.p(self.m_dir4Start:getPosition())
    self.m_huAnimationStopPos = {}
    self.m_huAnimationStopPos[1] = cc.p(self.m_dir1Hu:getPosition())
    self.m_huAnimationStopPos[2] = cc.p(self.m_dir2Hu:getPosition())
    self.m_huAnimationStopPos[3] = cc.p(self.m_dir3Hu:getPosition())
    self.m_huAnimationStopPos[4] = cc.p(self.m_dir4Hu:getPosition())
    self.m_gangEffectPos = {}
    self.m_gangEffectPos[1] = cc.p(self.m_gangEffect1:getPosition())
    self.m_gangEffectPos[2] = cc.p(self.m_gangEffect2:getPosition())
    self.m_gangEffectPos[3] = cc.p(self.m_gangEffect3:getPosition())
    self.m_gangEffectPos[4] = cc.p(self.m_gangEffect4:getPosition())
    coroutine.yield()

    self.m_huFonts = {}
    self.m_ziMoFonts = {}
    self.m_gangShangHuaFonts = {}

    self:initIconTips()
    self:hideStatusIcon()
    --for test
    self.m_errorMsgStack = stack:create()

    -- 初始化语音消息文本
    self:initVoiceMessageText()
    coroutine.yield()

    for i = 1, 4 do
        local icon = self.m_posScoreChanges[i]
        icon:hide()
        icon = self.m_negScoreChanges[i]
        icon:hide()
    end
    tt:stop()

    --- 设置语音消息
    self.mBroadcast:setString(dataManager.broadcast.next())
    self:hideHuUI()
    self:hideNormalMessageHint()
    self:updateNetInfo()
    self:hideShareOp()
    self.m_updateHandler = scheduler.scheduleGlobal(handler(self, DeskUI.update), 10)
    -- 暂时屏蔽跑马灯功能
    --self.scrollingHandler = scheduler.scheduleGlobal(handler(self, DeskUI.scrolling), 0.1)
end

function DeskUI:onCreate(manager, async)
    self.deskTitle = configManager.systemConfig.title
    self.deskDesc = configManager.systemConfig.desc
    if async then
        return
    end
end

--- 初始化Icon提示节点
--
function DeskUI:initIconTips()
    self.m_iconTipsNode = {}
    self.m_iconTipsNode[1] = self.m_iconTips1
    self.m_iconTipsNode[2] = self.m_iconTips2
    self.m_iconTipsNode[3] = self.m_iconTips3
    self.m_iconTipsNode[4] = self.m_iconTips4
    self.m_iconTipsSprites = {}
end

function DeskUI:hideStatusIcon()
    for _, head in ipairs(self.m_headUIs) do
        head:hideReady()
    end
end

function DeskUI:setReady(turn, isReady)
    local head = self:getHeadUIByTurn(turn)
    if head and isReady then
        head:showReady()
    end
end

function DeskUI:exit()
    UIStack.popAllUI()
    self.m_manager:exit()
    self.m_desk3d:exit()
    scheduler.unscheduleGlobal(self.m_updateHandler)
    --scheduler.unscheduleGlobal(self.scrollingHandler)
    DeskUI:popScene()
end

function DeskUI:setSelfIdx(idx)
    self.m_selfIdx = idx
    self.m_desk3d:setPlayerTurnIdx(idx)
end

function DeskUI:getHeadUIByTurn(turn)
    local side = self.m_desk3d:playerDeskSide(turn)
    local ui = self.m_headUIs[side]
    return ui
end

function DeskUI:onPeopleInOut(turn, isenter, info)
    local ui = self:getHeadUIByTurn(turn)
    local dir = self.m_desk3d:playerDeskSide(turn)
    if not isenter or info.isExit then
        ui:hide()
        self:setReady(turn, false)
        return
    end
    ui:show()
    self:setHeadInfoByPlayerData(ui, info)

    if isenter then
        self:setReady(turn, info.isReady)
    end
end

function DeskUI:setHeadInfoByPlayerData(ui, data)
    ui:setNickname(data:getNickname())
    ui:setUid(data:getAcId())
    ui:setHeadIcon(data:getHeadIcon())
    ui:setIp(data:getIp())
end

function DeskUI:updateHeadInfoByStatus()
    for i = 1, 3 do
        local data = deskManager.getPlayerData(i)
        local dir = self.m_desk3d:playerDeskSide(i)
        local ui = self.m_headUIs[dir]
        if data and not data.isExit then
            ui:setNickname(data:getNickname())
        end
    end
end

function DeskUI:showReadyHeadAction(handler)
    local sectime = 0.3
    deskManager.clearReady()
    local args = {}
    args.delay = sectime
    args.onComplete = function()
        self:updateHeadInfoByStatus()
        handler()
    end
    transition.execute(self, nil, args)
    return sectime
end

function DeskUI:setDeskInfo(title, desc)
    self.deskTitle = title
    self.deskDesc = desc
    self.m_deskId:setString(string.format("%s %s", title, self:modeDesc()))
    self.m_deskRule:setString(desc)
end

function DeskUI:showOperateUI(ops)
    self.m_hasOPChoose = true
    self.m_hasHu = table.indexof(ops, "hu")
    self.m_operateUI:showChoose(ops)
end

function DeskUI:hideOperateUI()
    self.m_hasOPChoose = false
    self.m_operateUI:hide()
end

--- 隐藏胡牌UI
function DeskUI:hideHuUI()
    local node = self.uiHuHint
    node:setVisible(false)
    for i = 1, 9 do
        local child = node:getChildByName(string.format("mj%d", i))
        if child then
            child:setVisible(false)
        end
    end
end

local huaSeMap = { "tiao", "tong", "wan" }
local valueMap = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
local function huaseImage(huase, value)
    return string.format("huase/%s_%s.png", huaSeMap[huase], valueMap[value])
end

--- 设置胡牌提示
function DeskUI:showHuTilesHint(tiles)
    self:hideHuUI()
    if #tiles < 1 then
        return
    end
    local node = self.uiHuHint
    local logic = self.m_manager.m_logic
    node:setVisible(true)
    for i = 1, #tiles do
        local idx = tiles[i]
        local child = node:getChildByName(string.format("mj%d", i))
        child:setVisible(true)
        local mj = MJDataClass:create(idx, false)
        local image = huaseImage(mj:getHuaSe(), mj:getValue())
        local value = child:getChildByName("value")
        value:setTexture(image)
    end
end

function DeskUI:getIdxByData(data)
    return self.m_desk3d:getIdxByData(data)
end

function DeskUI:chuPai(turn, mjdata)
    self:enableShowChuPaiHint(false, nil)
    self:disableChuPai()
    self.m_desk3d:chuPai(turn, mjdata)
    local dir = self.m_desk3d:playerDeskSide(turn)
    if 1 == dir and self.m_chuPaiHintParam then
        self.m_huHintParam = self.m_chuPaiHintParam[mjdata:getIdx()]
        self.m_chuPaiHintParam = {}
    end
end

function DeskUI:setPlayerTurn(turn)
    self:setSelfIdx(turn)
end

function DeskUI:setDice(dice1, dice2)
    self.m_desk3d:setDice(dice1, dice2)
end

function DeskUI:setMakerByTurnIdx(turn)
    self.m_desk3d:setMakerByTurnIdx(turn)
end

function DeskUI:qiPai(im)
    self.m_desk3d:qiPai(math.random(1, 4), im)
end

function DeskUI:moPai(turn, data, hasOffset, handler)
    local delay = self.m_desk3d:moPai(turn, data, hasOffset)
    local args = {}
    args.delay = delay + 0.1
    args.onComplete = handler(args.delay)
    transition.execute(self, nil, args)
end

function DeskUI:updateRestTileCount(count)
    self.uiRestTileInfo:setVisible(true)
    local count = count or self.m_desk3d.curRestTileCount
    self.uiRestTileCount:setString(string.format("%02d", count))
end

function DeskUI:duanPai(turn, datas)
    -- 隐藏UI元素
    for i = 1, 4 do
        self:hideIconTips(i)
    end

    self:hideStatusIcon()
    self:updateRestTileCount(84)
    return self.m_desk3d:duanPai(turn, datas)
end

function DeskUI:setManager(manager)
    self.m_manager = manager
    self.m_desk3d.m_manager = manager
    self.m_operateUI.m_manager = manager
    self.m_queChooseUI.m_manager = manager
end

function DeskUI:showDingQueUI(default)
    self.m_queChooseUI:showUI(default)
    self:showDQZStatusIcon()
end

function DeskUI:setOperateTime(time)
    self.m_desk3d:setOperateTime(time)
end

function DeskUI:setCurOperateDirByTurn(turn)
    self.m_desk3d:setCurOperateDirByTurn(turn)
end

function DeskUI:liPai(handler)
    local delay
    for i = 1, 4 do
        delay = self.m_desk3d:liPai(i)
    end
    local args = {}
    args.delay = delay
    args.onComplete = handler
    transition.execute(self, nil, args)
end

function DeskUI:makeLastMJOffset(dir)
    self.m_desk3d:makeLastMJOffset(dir)
end

function DeskUI:enableChuPai()
    self.m_desk3d:enableChuPai(true)
    self:showChuPaiHint()
end

function DeskUI:disableChuPai()
    self.m_desk3d:enableChuPai(false)
end

function DeskUI:makeLastMJOffset(turn)
    local dir = self.m_desk3d:playerDeskSide(turn)
    self:makeLastMJOffset(dir)
end

function DeskUI:isEnableChuPai()
    return self.m_desk3d:isEnableChuPai()
end

function DeskUI:getLeftMJCount(turn)
    return self.m_desk3d:getLeftMJCount(turn)
end

function DeskUI:pengPai(turn, beturn, datas)
    self.m_desk3d:pengPai(turn, beturn, datas)
    self:playPengFontAnimation(self.m_desk3d:playerDeskSide(turn))
end

function DeskUI:mingGang(turn, beturn, datas)
    self.m_desk3d:mingGang(turn, beturn, datas)
    local dir = self.m_desk3d:playerDeskSide(turn)
    self:playGangFontAnimation(dir)
    self:playXiaYuAnimation(dir)
end

function DeskUI:anGang(turn, datas)
    self.m_desk3d:anGang(turn, datas)
    local dir = self.m_desk3d:playerDeskSide(turn)
    self:playGangFontAnimation(dir)
    self:playXiaYuAnimation(dir)
end

function DeskUI:baGang(turn, data)
    self.m_desk3d:baGang(turn, data)
    local dir = self.m_desk3d:playerDeskSide(turn)
    self:playGangFontAnimation(dir)
    self:playGuaFengAnimation(dir)
end

function DeskUI:qiangGang(turn, beturn, data, isDouble)
    self.m_desk3d:qiangGang(turn, beturn, data)
    local dir = self.m_desk3d:playerDeskSide(turn)
    self:playHuPaiFontAnimation(dir)
    self:playDianPaoAnimation(dir, pos)
end

function DeskUI:huOther(turn, beturn, data, isDouble)
    local pos = self.m_desk3d:huOther(turn, beturn, data)
    local dir = self.m_desk3d:playerDeskSide(turn)
    self:playHuPaiFontAnimation(dir)
    self:playDianPaoAnimation(dir, pos)
end

function DeskUI:ziMo(turn, data, isGSH)
    self.m_desk3d:ziMo(turn, data)
    local dir = self.m_desk3d:playerDeskSide(turn)
    if isGSH then
        self:playGSHFontAnimation(turn)
    else
        self:playZiMoFontAnimation(dir)
    end
    self:enableShowChuPaiHint(false, nil)
end

function DeskUI:showAllHandTiles(handTiles, stats, title, round, isLookback, gameOverTitle, gameOverStats, isNormalFinished)
    -- 隐藏所有的定缺
    for i = 1, 4 do
        local head = self.m_headUIs[i]
        head:hideQue()
    end

    UIStack.popAllUI()
    -- 是否是最后一轮
    local isGameOver = gameOverStats ~= nil

    local args = {}
    if isGameOver and not isNormalFinished then
        args.delay = 0.5
    else
        args.delay = 2
    end
    args.onComplete = function()
        self.m_desk3d:showAllHandTiles(handTiles)
        self:hideHuFont()
        for _, v in pairs(handTiles) do
            local dir = self.m_desk3d:playerDeskSide(v.turn)
            if not v.isTing then
                self:showIconTips(dir, iconTipsType.wujiao)
            end
        end

        local roundOverUI
        local gameOverUI
        if self.mode == MODE_FOURS then
            roundOverUI = RoundOver4
            gameOverUI = BattleOverUI4
        else
            roundOverUI = RoundOver
            gameOverUI = BattleOverUI
        end

        --- 结果
        local result = {}
        local cnt = self.mode == MODE_FOURS and 4 or 3
        for i = 1, cnt do
            local playerTable = { total = "", idx = "", nickName = "" }
            local data = deskManager.getPlayerData(i)
            local stat = stats[i]
            if data and stat then
                playerTable.nickName = data.nickname
                playerTable.totalScore = stat.total
                playerTable.yuScore = stat.yu
                playerTable.fengScore = stat.feng
                playerTable.fanScore = stat.fanshu
                playerTable.bannerType = stat.bannerType
                playerTable.desc = stat.desc
                playerTable.uid = data:getAcId()
                table.insert(result, playerTable)
            end
        end

        local battleOverUI
        if isGameOver then
            battleOverUI = gameOverUI:create("", "", gameOverTitle, title, gameOverStats)
            UIStack.pushUI(battleOverUI)
            battleOverUI:setVisible(false)
        end
        local callback = function()
            if isLookback then
                deskManager.exit()
                eventManager:dispatchEvent({ name = event_name.SHOW_BATTLE_INFO })
            elseif isGameOver then
                if battleOverUI ~= nil then
                    battleOverUI:setVisible(true)
                end
            else
                self:onStart()
            end
        end

        if self.isDissolveDialogShow then
            self.isDissolveDialogShow = false
            UIStack.popUI()
        end

        printInfo("isGameOver: %s, isLookback:%s, isNormalFinished:%s", vardump(isGameOver), vardump(isLookback), vardump(isNormalFinished))

        if isGameOver and not isNormalFinished then
            local battleOverUI = gameOverUI:create("", "", gameOverTitle, title, gameOverStats)
            UIStack.pushUI(battleOverUI)
        else
            local ui = roundOverUI:create("", "", callback, result, title, round, isLookback, isGameOver)
            UIStack.pushUI(ui)
        end
    end
    transition.execute(self, nil, args)
end

function DeskUI:showGangScoreChang(changes, isXiaYu)
    for _, v in pairs(changes) do
        local dir = self.m_desk3d:playerDeskSide(v.turn)
        self:showScoreChange(dir, v.score)
    end
end

-- TODO: 重构显示积分变化
function DeskUI:huScoreChange(changes)
    local tmp = {}

    local totalCoin = 0
    local acId
    local size = #changes

    local isZiMo = false
    local beZiMoCnt
    local zimoDir
    local zimoTurn

    for _, info in pairs(changes) do
        if 1 == info.huPaiType then
            isZiMo = true
            beZiMoCnt = #info.scoreChange
            local turn = deskManager.playerDeskTurn(info.acId)
            local dir = self.m_desk3d:playerDeskSide(turn)
            zimoTurn = turn
            zimoDir = dir
        end
        if size == 1 then
            for _, v in pairs(info.scoreChange) do
                table.push(tmp, { acId = v.acId, score = v.score })
            end
        elseif size > 1 then
            totalCoin = totalCoin + info.scoreChange[1].score
            acId = info.scoreChange[1].acId
        end
        table.push(tmp, { acId = info.acId, score = info.totalWinScore })
    end
    if acId then
        table.push(tmp, { acId = acId, score = totalCoin })
    end

    if not isZiMo then
        for _, v in pairs(tmp) do
            v.turn = deskManager.playerDeskTurn(v.acId)
            v.dir = self.m_desk3d:playerDeskSide(v.turn)
            self:showScoreChange(v.dir, v.score)
        end
    else
        self:callFunctionAfterTime(1.0, function()
            for _, v in pairs(tmp) do
                v.turn = deskManager.playerDeskTurn(v.acId)
                v.dir = self.m_desk3d:playerDeskSide(v.turn)
                self:showScoreChange(v.dir, v.score)
            end
        end)
    end
end

function DeskUI:onRoundEnd()
    self:enableShowChuPaiHint(false, nil)
end

function DeskUI:hideHuFont()
    for i = 1, 4 do
        local ar = self.m_ziMoFonts[i]
        if ar then ar:hide() end

        ar = self.m_huFonts[i]
        if ar then ar:hide() end

        ar = self.m_gangShangHuaFonts[i]
        if ar then ar:hide() end
    end
end

function DeskUI:clearDesk()
    self.m_hasScoreGainShow = false
    self.m_desk3d:clearDeskMj()
    self:updateHeadInfoByStatus()
    self:hideHuFont()
    self:hideShareOp()
    for i = 1, 4 do
        local icon = self.m_posScoreChanges[i]
        if icon then icon:hide() end
        icon = self.m_negScoreChanges[i]
        if icon then icon:hide() end

        icon = self.m_iconTipsSprites[i]
        if icon then icon:hide() end
    end

    self:hideHuUI()
    local normalMessageAction = self:getActionByTag(NORMAL_MESSAGE_HINT_TAG)
    if normalMessageAction then
        self:hideNormalMessageHint()
    end
    self:stopAllActions()

    self.m_huHintParam = nil
    self.m_isCanShowChuPaiHint = nil
    self:clearUIWhenClickNone(true, true, false)
    self:enableShowChuPaiHint(false, nil)
end

function DeskUI:onZhuanYu(beAcId, beCoin, acIds, isZhiGang)
    local turn = deskManager.playerDeskTurn(beAcId)
    self:playHJZYFontAnimation(turn)
    self:callFunctionAfterTime(0.8, function()
        local tmp = {}
        for _, v in pairs(acIds) do
            table.push(tmp, { acId = v.acId, coin = v.coin, turn = v.turn })
        end
        table.push(tmp, { acId = beAcId, coin = beCoin, turn = turn })
        self:callFunctionAfterTime(1, function()
            for _, v in pairs(tmp) do
                v.dir = self.m_desk3d:playerDeskSide(v.turn)
                self:showScoreChange(v.dir, v.coin)
            end
        end)
    end)

    local info = {}
    info.coinChanges = acIds
    table.push(info.coinChanges, { acId = beAcId, coin = beCoin, turn = deskManager.playerDeskTurn(beAcId) })
    info.bei = 1
    if isZhiGang then
        info.bei = 2
    end
end

function DeskUI:callFunctionAfterTime(time, handler)
    local args = {}
    args.delay = time
    args.onComplete = function()
        handler()
    end
    return transition.execute(self, nil, args)
end

--- 同步房间
function DeskUI:syncDesk(info)
    self:clearDesk()
    self:updateRestTileCount(info.restCnt)
    self:updateHeadInfoByStatus()
    if info.status > 0 then
        self:hideStatusIcon()
    end
    self:qiPai(true)
    self.m_desk3d:syncDesk(info)

    local isAllDingQue = true -- 所有人已经定缺
    local isSelfDingQue = false -- 自己是否已经定缺
    local selfQueAdvice = 1

    local HuTypeZimo = 1 -- 自摸
    local HuTypePao = 2 -- 点炮
    -- 初始化麻将
    for _, player in ipairs(info.players) do
        player.dir = self.m_desk3d:playerDeskSide(player.turn)
        -- 处理已经和牌的玩家
        if player.isHu then
            if player.huType == HuTypeZimo then
                self:playZiMoFontAnimation(player.dir)
            elseif player.huType == HuTypePao then
                self:playHuPaiFontAnimation(player.dir)
            end
        end

        if self.mode == MODE_FOURS then
            --print("====>", player.que, player.dir)
            if player.que < 1 then
                self.m_headUIs[player.dir]:showQueStatus()
                isAllDingQue = false
            end

            -- 处理定缺
            if player.dir == 1 then
                if player.que < 1 then
                    -- que小于0表示没有定缺，建议定缺选项使用负数表示
                    isSelfDingQue = true
                    selfQueAdvice = -player.que
                else
                    selfQueAdvice = player.que
                end
            end
        end
    end

    if self.mode == MODE_FOURS then
        --print("======>", isSelfDingQue, selfQueAdvice)
        if isSelfDingQue then
            self:showDingQueUI(selfQueAdvice)
        end

        if isAllDingQue then
            for _, player in ipairs(info.players) do
                local ui = self.m_headUIs[player.dir]
                ui:setHuaSe(HUASE_ICON[player.que])
                if player.dir == 1 then
                    self.m_desk3d:setDingQue(player.que)
                    self.m_desk3d:sortTilesBySide(1)
                    self.m_desk3d:resetHandTilePosition(1, true)
                end
            end
        elseif not isSelfDingQue then
            self.m_desk3d:setDingQue(selfQueAdvice)
            self.m_desk3d:sortTilesBySide(1)
            self.m_desk3d:resetHandTilePosition(1, true)
        end
    end
end

function DeskUI:getSelfHandTiles()
    return self.m_desk3d:getSelfHandTiles()
end

--[[ movement event callback
 local function animationEvent(armatureBack,movementType,movementID)
    local id = movementID
    if movementType == ccs.MovementEventType.loopComplete then
        if id == "Fire" then
            local actionToRight = cc.MoveTo:create(2, cc.p(VisibleRect:right().x - 50, VisibleRect:right().y))
            armatureBack:stopAllActions()
            armatureBack:runAction(cc.Sequence:create(actionToRight,cc.CallFunc:create(callback1)))
            armatureBack:getAnimation():play("Walk")
        elseif id == "FireMax" then
            local actionToLeft = cc.MoveTo:create(2, cc.p(VisibleRect:left().x + 50, VisibleRect:left().y))
            armatureBack:stopAllActions()
            armatureBack:runAction(cc.Sequence:create(actionToLeft, cc.CallFunc:create(callback2)))
            armatureBack:getAnimation():play("Walk")
        end
    end
end
armature:getAnimation():setMovementEventCallFunc(animationEvent)
--]]
--[[  frame event
local function onFrameEvent( bone,evt,originFrameIndex,currentFrameIndex)
    if (not gridNode:getActionByTag(frameEventActionTag)) or (not gridNode:getActionByTag(frameEventActionTag):isDone()) then
        gridNode:stopAllActions()

        local action =  cc.ShatteredTiles3D:create(0.2, cc.size(16,12), 5, false)
        action:setTag(frameEventActionTag)
        gridNode:runAction(action)
    end
end
armature:getAnimation():setFrameEventCallFunc(onFrameEvent)
--]]
function DeskUI:showScoreChange(dir, score)
    local ui
    if score >= 0 then
        ui = self.m_posScoreChanges[dir]
        ui:setText("+" .. scoreToString(score))
    else
        ui = self.m_negScoreChanges[dir]
        ui:setText(scoreToString(score))
    end
    ui:show()
    self:callFunctionAfterTime(3, function()
        ui:hide()
    end)
end

function DeskUI:showIconTips(dir, path)
    if not path then return end
    local icon = self.m_iconTipsSprites[dir]
    if not icon then
        icon = cc.Sprite:create(path)
        self.m_iconTipsSprites[dir] = icon
        self.m_iconTipsNode[dir]:addChild(icon)
    end
    icon:setTexture(path)
    icon:show()
end

function DeskUI:hideIconTips(dir)
    local icon = self.m_iconTipsSprites[dir]
    if icon then icon:hide() end
end

function DeskUI:playAnimationAndThenDisappear(ar)
    ar:getAnimation():playWithIndex(0, -1, 0)
    local function animationEvent(ar, movementType, id)
        if movementType == ccs.MovementEventType.complete then
            ar:runAction(cc.Sequence:create({ cc.DelayTime:create(0.001), cc.RemoveSelf:create() }))
        end
    end

    ar:getAnimation():setMovementEventCallFunc(animationEvent)
end

function DeskUI:playAnimationAndMove(ar, pos)
    ar:getAnimation():playWithIndex(0, -1, 0)
    local function onFrameEvent(bone, evt, oriIdx, curIdx)
        if evt == "move" then
            ar:runAction(cc.MoveTo:create(0.5, pos))
        end
    end

    ar:getAnimation():setFrameEventCallFunc(onFrameEvent)
end

function DeskUI:showFontAnimation(ar, dir, pos, node)
    pos = pos or self.m_fontAnimationStartPos[dir]
    ar:show()
    ar:setPosition(pos)
    node = node or self.m_fontAnimationLayer
    node:addChild(ar)
    self:playAnimationAndThenDisappear(ar)
end

function DeskUI:playHuPaiFontAnimation(dir)
    local ar = self.m_huFonts[dir]
    if not ar then
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/huPaiFont/huPaiFont.csb")
        ar = ccs.Armature:create("huPaiFont")
        ar:setScale(0.6)
        self.m_fontAnimationLayer:addChild(ar)
        self.m_huFonts[dir] = ar
    end
    ar:show()
    ar:setPosition(self.m_fontAnimationStartPos[dir])
    self:playAnimationAndMove(ar, self.m_huAnimationStopPos[dir])
end

function DeskUI:playZiMoFontAnimation(dir)
    local ar = self.m_ziMoFonts[dir]
    if not ar then
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/ziMoFont/ziMoFont.csb")
        ar = ccs.Armature:create("ziMoFont")
        ar:setScale(0.6)
        self.m_fontAnimationLayer:addChild(ar)
        self.m_ziMoFonts[dir] = ar
    end
    ar:show()
    ar:setPosition(self.m_fontAnimationStartPos[dir])
    self:playAnimationAndMove(ar, self.m_huAnimationStopPos[dir])
end

function DeskUI:playPengFontAnimation(dir)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/pengFont/pengFont.csb")
    local ar = ccs.Armature:create("pengFont")
    ar:setScale(0.6)
    self:showFontAnimation(ar, dir)
end

function DeskUI:playGangFontAnimation(dir)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/gangFont/gangFont.csb")
    local ar = ccs.Armature:create("gangFont")
    ar:setScale(0.6)
    self:showFontAnimation(ar, dir)
end

function DeskUI:playXiaYuAnimation(dir)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/baoyu/baoyu.csb")
    local ar = ccs.Armature:create("baoyu")
    ar:setScale(2)
    self:showFontAnimation(ar, dir, self.m_gangEffectPos[dir], self)
end

function DeskUI:playGuaFengAnimation(dir)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/guafeng/guafeng.csb")
    local ar = ccs.Armature:create("guafeng")
    ar:setScale(2)
    self:showFontAnimation(ar, dir, self.m_gangEffectPos[dir], self)
end

function DeskUI:playDianPaoAnimation(dir, pos)
    if not pos then
        return
    end
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/dianpao/dianpao.csb")
    local ar = ccs.Armature:create("dianpao")
    ar:setScale(2)
    self:showFontAnimation(ar, dir, pos, self)
end

-- 屏蔽杠上花特效
function DeskUI:playGSHFontAnimation(turn)
    --[[local dir = self.m_desk3d:playerDeskSide(turn)
    local ar = self.m_gangShangHuaFonts[dir]
    if not ar then
        ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/gangShangHuaFont/gangShangHuaFont.csb")
        ar = ccs.Armature:create("gangShangHuaFont")
        self.m_fontAnimationLayer:addChild(ar)
        self.m_gangShangHuaFonts[dir] = ar
    end
    ar:show()
    ar:setPosition(self.m_fontAnimationStartPos[dir])
    self:playAnimationAndMove(ar, self.m_huAnimationStopPos[dir])]]
end

-- 屏蔽杠上炮特效
function DeskUI:playGSPFontAnimation(turn)
    --[[local dir = self.m_desk3d:playerDeskSide(turn)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/gangShangPaoFont/gangShangPaoFont.csb")
    local ar = ccs.Armature:create("gangShangPaoFont")
    self:showFontAnimation(ar, dir)]]
end

-- 屏蔽一炮多响特效
function DeskUI:playYPDXFontAnimation(turn)
    --[[local dir = self.m_desk3d:playerDeskSide(turn)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/yiPaoDuoXiang/yiPaoDuoXiang.csb")
    local ar = ccs.Armature:create("yiPaoDuoXiang")
    self:showFontAnimation(ar, dir)]]
end

-- 屏蔽转雨特效
function DeskUI:playHJZYFontAnimation(turn)
    --[[local dir = self.m_desk3d:playerDeskSide(turn)
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/huJiaoZhuanYiFont/huJiaoZhuanYiFont.csb")
    local ar = ccs.Armature:create("huJiaoZhuanYiFont")
    self:showFontAnimation(ar, dir)]]
end

function DeskUI:onMJCheckTingOrHuOK(id, param)
    if nil ~= self.m_checkTingId then
        if self.m_checkTingId == id then
            self.m_chuPaiHintParam = param
            if self.m_desk3d:isEnableChuPai() then
                self:showChuPaiHint()
            end
        end
    end
end

local arrowPosY = 110
function DeskUI:getArrow(idx, pos)
    if idx > #self.m_hintArrow then
        local sprite = cc.Sprite:create("desk/game_icon_jiantou.png")
        self.root:addChild(sprite)
        sprite:setAnchorPoint(cc.p(0.5, 0))
        self.m_hintArrow[idx] = sprite
    end
    local sprite = self.m_hintArrow[idx]
    sprite:setPosition(pos.x, pos.y)
    sprite:show()
    return sprite
end

function DeskUI:onTileFirstChosen(mj)
    if nil == self.m_mjArrowVec then return end
    if nil == mj then
        for _, v in pairs(self.m_mjArrowVec) do
            v[3]:setPosition(v[2])
        end
        return
    end
    for _, v in pairs(self.m_mjArrowVec) do
        if v[1] == mj then
            local x = display.cx
            v[3]:setPosition(cc.p(v[2].x, v[2].y + 20))
        else
            v[3]:setPosition(v[2])
        end
    end
end

function DeskUI:showChuPaiHint()
    if not self.m_isCanShowChuPaiHint then return end
    if nil == self.m_chuPaiHintParam then return end
    if 0 == #self.m_chuPaiHintParam then return end
    if nil == self.m_hintArrow then self.m_hintArrow = {} end
    self.m_mjArrowVec = {}
    local arrowIdx = 1
    for i = 1, #self.m_chuPaiHintParam do
        local idx = self.m_chuPaiHintParam[i].chu
        local poses = self.m_desk3d:getShouPaiMJPosByIdx(idx)
        for j = 1, #poses do
            local pos = poses[j][2]
            pos.y = pos.y + 10
            local sp = self:getArrow(arrowIdx, pos)
            table.push(poses[j], sp)
            table.push(self.m_mjArrowVec, poses[j])
            arrowIdx = arrowIdx + 1
        end
    end
end

function DeskUI:hideChuPaiHint()
    if nil == self.m_hintArrow then return end
    for _, v in pairs(self.m_hintArrow) do
        v:hide()
    end
end

function DeskUI:enableShowChuPaiHint(enable, id)
    self.m_isCanShowChuPaiHint = enable
    self.m_checkTingId = id
    if not enable then
        self.m_isCanShowChuPaiHint = nil
        self:hideChuPaiHint()
    end
end

function DeskUI:setCheckHuId(id)
    self.m_checkHuId = id
end

function DeskUI:clearUIWhenClickNone(hasHeart, hasTingPaiHint, hasMj)
    --[[for i = 1, 4 do
        self:hideIconTips(i)
    end]]

    if nil == hasMj then hasMj = true end
    if hasMj then
        self:onTileFirstChosen(nil)
        self.m_desk3d:clearChoosedMj()
    end
end

function DeskUI:showNormalMessageHint(text, time)
    self.m_normalMessageHint:show()
    local textNode = self.m_normalMessageHint:getChildByName("text")
    textNode:setString(text)
    self:stopActionByTag(NORMAL_MESSAGE_HINT_TAG)
    if time then
        local action = self:callFunctionAfterTime(time, function()
            self:hideNormalMessageHint()
        end)
        action:setTag(NORMAL_MESSAGE_HINT_TAG)
    end
end

function DeskUI:hideNormalMessageHint()
    self.m_normalMessageHint:hide()
end

function DeskUI:modeDesc()
    return self.mode == MODE_FOURS and "<血战到底>" or "<三人两房>"
end

function DeskUI:onShareDeskNo()
    local content = string.format("%s%s\n%s%s\n下载:%s\n(复制此信息快捷加入房间)",
        appConfig.prefix, self.deskTitle, self:modeDesc(), self.deskDesc, configManager.systemConfig[device.platform])
    gameAssistant.playBtnClickedSound()
    clipboard.copy(content)
    gameAssistant.showHintAlertUI("房间号已复制")
end

function DeskUI:onWechatShare()
    local title = string.format("%s%s", self.deskTitle, self:modeDesc())
    thirdsdk.share("session", configManager.systemConfig[device.platform], title, self.deskDesc)
    gameAssistant.playBtnClickedSound()
end

function DeskUI:onDissolveSuccess()
    self.isDissolveDialogShow = false
    UIStack:popUI()
    deskManager.exit()
end

function DeskUI:onPlayerVoiceMessage(data)
    printInfo("%s", vardump(data))
    local turn = deskManager.playerDeskTurn(data.uid)
    local player = deskManager.getPlayerData(turn)
    local head = self:getHeadUIByTurn(turn)
    head:setMessage(voiceMessageText[data.index])
    local voicePath = configManager.soundConfig.voiceFilePath(player:getUserSex(), data.index)
    printInfo(voicePath)
    audioEngine.playEffect(voicePath)
end

function DeskUI:enableLookback()
    self.m_voiceBtn:setVisible(false)
    self.m_voiceMessage:setVisible(false)
    self.isLookback = true
    self.m_desk3d:enableLookback()
end

function DeskUI:onTouchBegin(touch, event)
    if self.isVoiceMessageListVisible then
        self.m_voiceListView:setVisible(false)
        self.isVoiceMessageListVisible = false
    end

    -- 调试连击屏幕开启调试
    if not configManager.debug.permission then
        return
    end

    local current = usertime.getmillisecond();
    if current - self.lastClickAt > 500 then
        self.comboCount = 0
    else
        self.comboCount = self.comboCount + 1
        if self.comboCount >= 5 then
            self.comboCount = 0
            configManager.debug.enable = not configManager.debug.enable
            local message = configManager.debug.enable and "调试功能已开启" or "调试功能已关闭"
            gameAssistant.showHintAlertUI(message)
        end
    end
    self.lastClickAt = current
end

function DeskUI:refreshTing(tings)
    self.m_desk3d:refreshTing(tings)
end

function DeskUI:showSelfDingQueAction(que)
    -- 定缺动画
    for i = 1, 3 do
        local sp = display.newSprite(HUASE_ICON[que])
        self:addChild(sp)
        sp:setPosition(self:convertToNodeSpace(self.m_queChooseUI:getIconWp(que)))
        if i == que then
            local ui = self.m_headUIs[1]
            local tp = self:convertToNodeSpace(ui:getIconWp())
            local actions = {}
            local mvAction = cc.MoveTo:create(0.3, tp)
            actions[1] = mvAction
            actions[2] = cc.RemoveSelf:create()
            actions[3] = cc.CallFunc:create(function()
                ui:setHuaSe(HUASE_ICON[que])
                ui:hideQueStatus()
            end)
            local scaleAction = cc.ScaleTo:create(0.3, 0.24)
            sp:runAction(cc.Sequence:create(actions))
            sp:runAction(scaleAction)
        else
            local actions = {}
            actions[1] = cc.ScaleTo:create(0.3, 0.1)
            actions[2] = cc.RemoveSelf:create()
            sp:runAction(cc.Sequence:create(actions))
        end
    end

    -- 已经扣牌的牌不能出
    self.m_desk3d:setDingQue(que)
    self.m_desk3d:sortTilesBySide(1)
    self.m_desk3d:resetHandTilePosition(1, true)
    self.m_queChooseUI:hide()
end

function DeskUI:showAllDingQueAction(queList)
    for i = 1, #queList do
        local dir = self.m_desk3d:playerDeskSide(queList[i].turn)
        -- 自己的定缺已经显示
        if dir ~= 1 then
            local pos = self.m_fontAnimationStartPos[dir]
            local sp = display.newSprite(HUASE_ICON[queList[i].que])
            local hui = self.m_headUIs[dir]
            hui:hideQueStatus()

            local targetPos = self:convertToNodeSpace(hui:getIconWp())
            self:addChild(sp)
            sp:setPosition(pos)
            local actions = {}
            local mvAction = cc.MoveTo:create(0.3, targetPos)
            actions[1] = mvAction
            actions[2] = cc.RemoveSelf:create()
            actions[3] = cc.CallFunc:create(function()
                hui:setHuaSe(HUASE_ICON[queList[i].que])
            end)
            local scaleAction = cc.ScaleTo:create(0.3, 0.24)
            sp:runAction(cc.Sequence:create(actions))
            sp:runAction(scaleAction)
        end
    end
end

function DeskUI:showDQZStatusIcon()
    for i = 1, 4 do
        local ui = self.m_headUIs[i]
        ui:showQueStatus()
    end
end

function DeskUI:setMode(mode)
    self.mode = mode
    self.m_desk3d:setMode(mode)
end

return DeskUI