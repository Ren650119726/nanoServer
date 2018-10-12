local packetHandler = {}
local EventManager = require "app.core.EventManager"
local deskManager = require "app.logic.deskManager"
local dataManager = require "app.data.dataManager"
local networkManager = require "app.network.NetworkManager"

local function onPlayerExit(data)
    local selfAcId = dataManager.loginData:getUid()
    if selfAcId == data.acid then
        deskManager.onExitTable(data.exitType)
    else
        deskManager.onPeopleExit(data.deskPos)
    end
end

local function onPlayerEnter(msg)
    local manager = deskManager.getLogicManager()
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
        manager:onPlayerOfflineStatus(v.acId, v.offline)
    end
end

local function onDeskBasicInfo(data)
    deskManager.getLogicManager():setDeskBasicInfo(data)
end

local function onDuanPai(data)
    deskManager.getLogicManager():startDuanPai(data)
    deskManager.onStartPlaying()
end

local function onMoPai(data)
    deskManager.getLogicManager():moPai(data.acId, data.mjids[1])
end

local function onOpTypeHint(data)
    deskManager.getLogicManager():actionHint(data.ops, data.uid,  data.tings)
end

local function onOpTypeDo(data)
    deskManager.getLogicManager():action(data.optype, data.uid, data.mjs, data.hutype)
end

local function onGangScoreChange(data)
    deskManager.getLogicManager():gangScoreChange(data.changes, data.isXiaYu)
end

local function onHuScoreChange(change)
    deskManager.getLogicManager():huScoreChange(change)
end

local function onDeskStatus(data)
    deskManager.deskStatus(data.state)
end

local function onReady(data)
    deskManager.onReady(data.acId)
end

local function onRoundEnd(data)
    deskManager.getLogicManager():roundEnd(data.tiles,
        data.stats,
        data.scoreChange,
        data.title,
        data.round)
end

local function onGameEnd(data)
    -- 游戏结束, 关闭重连
    networkManager.setReconnectHandler(nil)
    local roundStats = data.roundStats
    deskManager.getLogicManager():roundEnd(roundStats.tiles,
        roundStats.stats,
        roundStats.scoreChange,
        roundStats.title,
        roundStats.round,
        false,
        data.title,
        data.stats,
        data.isNormalFinished)
end

local function onDissolve(data)
    deskManager.getLogicManager():onDissolve(data)
end

local function onDissolveAgreement(data)
    deskManager.getLogicManager():onDissolveAgreement(data)
end

local function onDissolveStatus(data)
    deskManager.getLogicManager():onDissolveStatus(data)
end

local function onDissolveFailure(data)
    deskManager.getLogicManager():onDissolveFailure(data)
end

local function onDissolveSuccess(data)
    deskManager.getLogicManager():onDissolveSuccess(data)
end

local function onSyncDesk(data)
    deskManager.getLogicManager():syncDesk(data)
end

local function onVoiceMessage(data)
    deskManager.getLogicManager():onVoiceMessage(data)
end

--- 语音音频文件下载地址
-- @param uid
--
local function voicePath(uid)
    return string.format("%svoice-%d.mp3", cc.FileUtils:getInstance():getWritablePath(), uid)
end

local function onRecordingVoice(data)
    cloudvoice.downloadRecordedFile(data.fileId, voicePath(data.uid), 60000);
end

local function onPlayerOfflineStatus(data)
    deskManager.getLogicManager():onPlayerOfflineStatus(data.uid, data.offline)
end

local function onQueAction(data)
    deskManager.getLogicManager():onQueAction(data)
end

local function onDingQueHint(data)
    deskManager.getLogicManager():onQueHint(data.que)
end

local function onBroadcast(data)
    EventManager:dispatchEvent({ name = event_name.BROADCAST_SYSTEM_MESSAGE, message = data.message })
end

local function onCoinChange(data)
    dataManager.playerData:setCardCount(data.coin)
end

function packetHandler.globalRegister()
    networkManager.on("onBroadcast", onBroadcast)
    networkManager.on("onCoinChange", onCoinChange)
end

-- 进入房间时注册
function packetHandler.register()
    networkManager.on("onPlayerExit", onPlayerExit) --其他人退出大厅
    networkManager.on("onPlayerEnter", onPlayerEnter) --自己进入大厅(猜测: 退出后重新进入)
    networkManager.on("onDeskBasicInfo", onDeskBasicInfo) --本桌基本信息
    networkManager.on("onDuanPai", onDuanPai) --断牌
    networkManager.on("onMoPai", onMoPai) --摸牌
    networkManager.on("onOpTypeHint", onOpTypeHint) --提示出牌
    networkManager.on("onOpTypeDo", onOpTypeDo) --出牌
    networkManager.on("onGangScoreChange", onGangScoreChange) --@deprecated: 杠牌金币改变
    networkManager.on("onHuScoreChange", onHuScoreChange) --@deprecated: 胡牌金币改变
    networkManager.on("onDeskStatus", onDeskStatus)
    networkManager.on("onReady", onReady) --准备就绪
    networkManager.on("onRoundEnd", onRoundEnd)
    networkManager.on("onGameEnd", onGameEnd)
    networkManager.on("onDissolve", onDissolve)
    networkManager.on("onDissolveAgreement", onDissolveAgreement)
    networkManager.on("onDissolveStatus", onDissolveStatus)
    networkManager.on("onDissolveFailure", onDissolveFailure)
    networkManager.on("onDissolveSuccess", onDissolveSuccess)
    networkManager.on("onSyncDesk", onSyncDesk)
    networkManager.on("onVoiceMessage", onVoiceMessage)
    networkManager.on("onRecordingVoice", onRecordingVoice)
    networkManager.on("onPlayerOfflineStatus", onPlayerOfflineStatus)
    networkManager.on("onDingQue", onQueAction)
    networkManager.on("onDingQueHint", onDingQueHint)
end

-- 退出房间时取消注册
function packetHandler.unregister()
    networkManager.on("onPlayerExit", nil)
    networkManager.on("onPlayerEnter", nil)
    networkManager.on("onDeskBasicInfo", nil)
    networkManager.on("onDuanPai", nil)
    networkManager.on("onMoPai", nil)
    networkManager.on("onOpTypeHint", nil)
    networkManager.on("onOpTypeDo", nil)
    networkManager.on("onGangScoreChange", nil)
    networkManager.on("onHuScoreChange", nil)
    networkManager.on("onDeskStatus", nil)
    networkManager.on("onReady", nil)
    networkManager.on("onRoundEnd", nil)
    networkManager.on("onGameEnd", nil)
    networkManager.on("onDissolve", nil)
    networkManager.on("onDissolveAgreement", nil)
    networkManager.on("onDissolveStatus", nil)
    networkManager.on("onDissolveFailure", nil)
    networkManager.on("onDissolveSuccess", nil)
    networkManager.on("onSyncDesk", nil)
    networkManager.on("onVoiceMessage", nil)
    networkManager.on("onRecordingVoice", nil)
    networkManager.on("onPlayerOfflineStatus", nil)
    networkManager.on("onDingQue", nil)
    networkManager.on("onDingQueHint", nil)
end

return packetHandler
