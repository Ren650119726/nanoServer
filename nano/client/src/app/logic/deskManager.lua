local deskManager = {}
local LocalRecord = require "app.core.LocalRecord"
local stringDefine = require "app.data.stringDefine"
local dataManager = require "app.data.dataManager"
local networkManager = require "app.network.NetworkManager"
local typeDefine = require "app.data.typeDefine"
local configManager = require "app.config.configManager"
local scheduler = require("app.core.scheduler")
local gameAssistant = require "app.logic.gameAssistant"
local WaitUI = require "app.ui.WaitUi"
local eventManager = require "app.core.EventManager"
local Protocol = require "app.starx.Protocol"
--local variable
local DeskUIClass
local deskUI
local GameLogicClass
local logicManager
local curTableInfo
local selfIdx
local players = { nil, nil, nil, nil, nil, nil }
local isCanAutoExit = true
local matchType
local isBeKicked = false
local isSelfReady = false
local cloudVoiceRoomName = ""
local cloudVoiceSpeakerOpened = false
local creator
local ManagerClass
local applicationStatusHandler
deskManager.isCanReady = true

--- 当前是否在房间中
deskManager.isJoinedDesk = false

function deskManager.clear()
    DeskUIClass = nil
    deskUI = nil
    GameLogicClass = nil
    logicManager = nil
    curTableInfo = nil
    selfIdx = nil
    players = { nil, nil, nil, nil, nil, nil }
    isCanAutoExit = true
    matchType = nil
    isBeKicked = false
    isSelfReady = false
    ManagerClass = nil
    cloudVoiceRoomName = ""
    cloudVoiceSpeakerOpened = false
    creator = nil

    if applicationStatusHandler ~= nil then
        eventManager:removeEventListener(applicationStatusHandler)
        applicationStatusHandler = nil
    end

    deskManager.isCanReady = true
    deskManager.isJoinedDesk = false
end

function deskManager.isCanAutoExit()
    return isCanAutoExit
end

function deskManager.setIsCanAutoExit(is)
    isCanAutoExit = is
end

function deskManager.getMatchType()
    return matchType
end

local function doUIFunction(name, ...)
    if deskUI == nil then return end
    local method = deskUI[name]
    method(deskUI, ...)
end

function deskManager.onEnterTable(idx, isReady)
    isBeKicked = false
    isCanAutoExit = true
    deskManager.setSelfIdx(idx, isReady)
    printInfo("deskManager.onEnterTable: %s", vardump(idx))
    isSelfReady = isReady
end

function deskManager.isReEnter()
    -- 保存最后一次进入的房间房号
    local lastDeskId = LocalRecord.instance():getProperty(stringDefine.LAST_JOIN_DESK_NO)
    return lastDeskId == curTableInfo.deskId
end

local routine -- 加载资源协程
function deskManager.enterAsync(uiClass, logicClass, managerClass, tableInfo, mType)
    -- 注册房间处理消息
    local packetHandler = require "app.network.packetHandler"
    packetHandler.register()

    if uiClass then
        deskManager.heartbeatHanlder = scheduler.scheduleGlobal(function() deskManager.enterAsync() end, 0.1)
        WaitUI.show("正在进入房间")
        matchType = mType
        DeskUIClass = uiClass
        GameLogicClass = logicClass
        isCanAutoExit = true
        curTableInfo = tableInfo
        isBeKicked = false
        isSelfReady = true
        creator = tableInfo.creator
        ManagerClass = managerClass
        -- 腾讯语音房间名
        cloudVoiceRoomName = "__kawuxing_room_" .. tableInfo.deskId

        deskUI = DeskUIClass:create("", "", nil, true)
        deskUI:retain()
        if nil == routine then
            routine = coroutine.create(function()
                deskUI:initAsync()
            end)
        end
    end
    printInfo("deskManager.enterAsync")
    if nil == routine then
        return
    end
    local status = coroutine.status(routine)
    if "suspended" == status then
        local ret, errorMSG = coroutine.resume(routine)
        if not ret then
            __G__TRACKBACK__(errorMSG)
        end
        return false
    end
    if "dead" == status then
        -- 进入腾讯实时语言房间
        --[[if cloudVoiceRoomName ~= "" then
            printInfo("cloudVoiceRoomName: %s", cloudVoiceRoomName)
            cloudvoice.joinTeamRoom(cloudVoiceRoomName, 10000)
        end]]

        WaitUI.hide()
        deskUI:pushScene()
        deskUI:release()
        local logic = GameLogicClass:create(curTableInfo.mode)
        logicManager = ManagerClass:create(deskUI, logic)
        deskUI:setManager(logicManager)
        deskUI:setMode(curTableInfo.mode)
        deskUI:setDeskInfo(curTableInfo.title, curTableInfo.desc)

        -- 监听应用程序切换到后台
        if applicationStatusHandler == nil then
            local ignore, handler = eventManager:addEventListener("APPLICATION_STATUS_CHANGE", deskManager.applicationStatusChange)
            applicationStatusHandler = handler
        end
        scheduler.unscheduleGlobal(deskManager.heartbeatHanlder)
        networkManager.setReconnectHandler(deskManager.reConnect)
        networkManager.setDisconnectHandler(deskManager.disconnect)
        audioEngine.playBackgroundMusic(configManager.soundConfig.musicFilePath("table"))
        routine = nil

        --根据模式初始化
        print("=====mode=======", curTableInfo.mode)

        --回放
        if curTableInfo.status == typeDefine.sDeskStatus.lookback then
            deskUI:hideStatusIcon()
            deskUI:enableLookback()
            --printInfo("%s", vardump(curTableInfo.snapshot))
            scheduler.performWithDelayGlobal(function()
                deskManager.lookbackPlayerEnter()
            end, 1)
            return true
        end

        --是否是断线重新进入
        local isReEnter = deskManager.isReEnter()

        --通知服务器, 客户端初始化完成
        deskManager.clientInitCompleted(isReEnter)

        --新的一局开始
        if not isReEnter then
            deskManager.ready()

            deskUI:showShareOp()
            -- 保存最后一次进入的房间房号
            LocalRecord.instance():setProperty(stringDefine.LAST_JOIN_DESK_NO, curTableInfo.deskId)
            LocalRecord.instance():save()
        else
            if typeDefine.sDeskStatus.create == curTableInfo.status then
                deskUI:showShareOp()
            end
            deskUI:hideStatusIcon()
            networkManager.notify("DeskManager.ReEnter", { deskId = curTableInfo.deskId })
        end

        return true
    end
end

---------------------------- 回放 ---------------------------------------
function deskManager.lookbackPlayerEnter()
    if not curTableInfo or not curTableInfo.snapshot then
        return
    end
    -- 回放玩家设置
    local msg = curTableInfo.snapshot.enter
    local selfAcId = dataManager.loginData:getUid()
    for _, v in ipairs(msg.data) do
        if v.acId == selfAcId then
            deskManager.onEnterTable(v.deskPos, v.isReady)
        end
    end
    for _, v in ipairs(msg.data) do
        if v.acId ~= selfAcId then
            deskManager.onPeopleEnter(v)
        end
    end

    -- 回放桌面基本信息
    logicManager:setDeskBasicInfo(curTableInfo.snapshot.basicInfo)

    -- 回放断牌
    logicManager:startDuanPai(curTableInfo.snapshot.duanPai)
    deskManager.onStartPlaying()

    -- 开始打牌
    local actions = curTableInfo.snapshot["do"]
    local snapshotProgress = {
        curentStep = 1,
        maxStep = #actions,
    }
    local roundEnd = curTableInfo.snapshot["end"]
    curTableInfo.snapshotProgress = snapshotProgress
    printInfo("%s", vardump(snapshotProgress))
    snapshotProgress.handler = scheduler.scheduleGlobal(function()
        if not logicManager.qiPaiFinished then
            return
        end
        if snapshotProgress.curentStep <= snapshotProgress.maxStep then
            local action = actions[snapshotProgress.curentStep]
            printInfo("%s", vardump(action))
            -- optype==500 表示摸牌
            if action.optype == 500 then
                logicManager:moPai(action.uid[1], action.mjs[1])
            else
                logicManager:action(action.optype, action.uid, action.mjs, action.hutype)
            end
            snapshotProgress.curentStep = snapshotProgress.curentStep + 1
        else
            if snapshotProgress.handler then
                scheduler.unscheduleGlobal(snapshotProgress.handler)
                snapshotProgress.handler = nil
            end
            logicManager:roundEnd(roundEnd.tiles, roundEnd.stats, roundEnd.scoreChange, roundEnd.title, roundEnd.round, true)
        end
    end, 1)
end

---------------------------- 逻辑 ---------------------------------------

--- ready
-- @param multiple
--
function deskManager.ready()
    networkManager.notify("DeskManager.Ready", {})
end

function deskManager.clientInitCompleted(isReEnter)
    networkManager.notify("DeskManager.ClientInitCompleted", { isReenter = isReEnter })
end

function deskManager.reStart()
    local function callback(timeout)
        if timeout then
            deskManager.onExitTable(typeDefine.sExitType.exitDeskUI)
            return false
        end
        return true
    end

    networkManager.notify("DeskManager.ReStart", { deskId = curTableInfo.deskId })
end

function deskManager.applicationStatusChange(event)
    if not event.resume then
        crossevent.on("heartbeat", function()
            networkManager.heartbeat()
        end)
        cc.exports.backgroundHeartbeat = nil
        networkManager.notify("DeskManager.Pause", {})
    else
        crossevent.remove("heartbeat")
        networkManager.notify("DeskManager.Resume", {})
    end
end

function deskManager.getDeskUI()
    return deskUI
end

function deskManager.onExitTable(exitType)
    --if not isCanAutoExit then return end
    if not deskUI then return end
    isBeKicked = true
    if exitType == typeDefine.sExitType.dailyMatchEnd then
        return
    elseif exitType == typeDefine.sExitType.notReadyForStart then
        deskManager.kickAllOtherPeople()
        deskUI:showNormalMessageHint("桌子已经解散，请重新开始")
        return
    elseif exitType == typeDefine.sExitType.changeDesk then
        return
    elseif exitType == typeDefine.sExitType.classicCoinNotEnough then
        --may need to show a nitify alert ui.
        gameAssistant.showHintAlertUI("金币不足", function()
            deskManager.exitDeskUI()
        end)
        return
    elseif exitType == typeDefine.sExitType.repeatLogin then
        gameAssistant.showHintAlertUI("该账号已在其他地方登录", function()
            deskManager.exitDeskUI()
            eventManager:dispatchEvent({ name = event_name.EXIT_GAME })
        end)
        return
    end
    deskManager.exitDeskUI()
end

function deskManager.getCreator()
    return creator
end

function deskManager.exitDeskUI()
    scheduler.unscheduleGlobal(deskManager.heartbeatHanlder)
    networkManager.setReconnectHandler(nil)
    networkManager.setDisconnectHandler(nil)
    DeskUIClass = nil
    GameLogicClass = nil

    curTableInfo = nil
    deskUI:exit()
    matchType = nil
    deskUI = nil
    logicManager = nil
    deskManager.clear()
    audioEngine.playBackgroundMusic(configManager.soundConfig.musicFilePath())
end

function deskManager.exit()
    if curTableInfo.status == typeDefine.sDeskStatus.lookback then
        if curTableInfo.snapshotProgress and curTableInfo.snapshotProgress.handler then
            if curTableInfo.snapshotProgress.handler then
                scheduler.unscheduleGlobal(curTableInfo.snapshotProgress.handler)
                curTableInfo.snapshotProgress.handler = nil
            end
        end
    end

    -- 重置分数和漂数
    dataManager.playerData:setScore(1000)
    for _, p in ipairs(players) do
        if p ~= nil then
            p:setScore(1000)
        end
    end
    deskManager.onExitTable(typeDefine.sExitType.exitDeskUI)

    -- 清空剪切板内容
    clipboard.copy("")

    -- 取消注册房间处理消息
    local packetHandler = require "app.network.packetHandler"
    packetHandler.unregister()
end

function deskManager.kickAllOtherPeople()
    deskManager.onPeopleExit(0)
    deskManager.onPeopleExit(1)
    deskManager.onPeopleExit(2)
    deskManager.onPeopleExit(3)
end

function deskManager.onPeopleEnter(v)
    --[[if not cloudVoiceSpeakerOpened then
        cloudvoice.openSpeaker()
        cloudVoiceSpeakerOpened = true
    end]]
    local data = dataManager.PlayerDataClass:create(v.acId)
    data:setNickname(v.nickname)
    data:setHeadIcon(v.headURL, v.acId)
    data:setUserSex(v.sex)
    data:setScore(v.score)
    data:setIp(v.ip)
    data.isReady = v.isReady
    data.isExit = v.isExit
    local idx = v.deskPos

    idx = idx + 1
    assert(idx ~= selfIdx, "desk position must not equal position.")
    deskManager.setPlayerData(idx, data)
    deskUI:onPeopleInOut(idx, true, data)
end

function deskManager.onPeopleExit(idx)
    idx = idx + 1
    if idx == selfIdx then
        return
    end
    deskManager.setPlayerData(idx, nil)
    deskUI:onPeopleInOut(idx, false)
end

function deskManager.onPlayerScoreChange(turn, score)
    local playerData = deskManager.getPlayerData(turn)
    playerData:setScore(playerData:getScore() + score)
end

function deskManager.setPlayerTotalScore(acid, score)
    local turn = deskManager.playerDeskTurn(acid)
    local playerData = deskManager.getPlayerData(turn)
    playerData:setScore(score)
end

function deskManager.setSelfIdx(idx, isReady)
    selfIdx = idx + 1
    deskManager.setPlayerData(selfIdx, dataManager.playerData)
    dataManager.playerData.isReady = isReady
    deskUI:setSelfIdx(selfIdx)
    logicManager:setPlayerTurn(selfIdx)
    deskUI:onPeopleInOut(selfIdx, true, dataManager.playerData)
end

function deskManager.setPlayerData(idx, data)
    printInfo("setPlayerData: %d", idx)
    if nil == data then
        if players[idx] then
            players[idx].isExit = true
            return
        end
    end
    players[idx] = data
end

function deskManager.getPlayerData(idx)
    return players[idx]
end

function deskManager.playerDeskTurn(id)
    for i = 1, 4 do
        local n = deskManager.getPlayerData(i)
        if n then
            if id == n:getAcId() then
                return i
            end
        end
    end
    return nil
end

function deskManager.getTotalPeopleCnt()
    local cnt = 0
    for i = 1, curTableInfo.mode do
        local n = deskManager.getPlayerData(i)
        if n and not n.isExit then
            cnt = cnt + 1
        end
    end
    return cnt
end

function deskManager.getNextDuanPaiTurn(id)
    local max = 4
    for i = 1, max do
        local nextid = id + i
        if nextid > max then nextid = nextid - max end
        local playerData = deskManager.getPlayerData(nextid)
        if playerData and not playerData.isExit then return nextid end
    end
end

function deskManager.getLogicManager()
    return logicManager
end

function deskManager.onStartChoose()
    deskUI:hideNormalMessageHint()
    if isBeKicked then
        deskUI:clearDesk()
        deskUI:updateHeadInfoByStatus()
        deskManager.reStart()
    else
        deskManager.ready()
    end
end

function deskManager.onReady(acId)
    local selfAcId = dataManager.playerData:getAcId()
    if selfAcId == acId then
        isSelfReady = true
    end
    if deskManager.isCanReady then
        local turn = deskManager.playerDeskTurn(acId)
        deskUI:setReady(turn, true)
        local data = deskManager.getPlayerData(turn)
        data.isReady = true
    end
end

function deskManager.onStartPlaying()
    isSelfReady = false
    deskUI:hideNormalMessageHint()
end

function deskManager.isSelfReady()
    return isSelfReady
end

function deskManager.clearReady()
    isSelfReady = false
    for i = 1, 4 do
        local n = deskManager.getPlayerData(i)
        if n then
            n.isReady = false
        end
    end
    deskManager.isCanReady = false
    deskUI:hideStatusIcon()
end

function deskManager.deskStatus(status)
    if status == typeDefine.sDeskStatus.duanpai then
        --self.m_ui:showZBBtn()
        if not deskManager.isSelfReady() then
            deskUI:showStartBtn()
        end
    elseif status == typeDefine.sDeskStatus.qipai then
        --deskManager.clearReady()
    elseif status == typeDefine.sDeskStatus.playing then
        deskManager.isCanReady = true
    end
    logicManager:deskStatus(status)
end

function deskManager.reConnect()
    WaitUI:hide()
    networkManager.request("DeskManager.ReJoin", { deskId = curTableInfo.deskId }, function(data)
        if data.code ~= 0 then
            gameAssistant.showHintAlertUI(data.error, function()
                deskManager.exit()
            end)
        end
    end)
end

function deskManager.tileCount()
    return curTableInfo.mode == MODE_FOURS and 108 or 72
end

function deskManager.disconnect()
    deskUI:onDissolveFailure()
end

return deskManager
