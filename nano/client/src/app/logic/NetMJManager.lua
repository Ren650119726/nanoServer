local configManager = require "app.config.configManager"
local stringDefine = require "app.data.stringDefine"
local NetMJManager = class("NetMJManager")
local scheduler = require("app.core.scheduler")
local MJDataClass = require "app.core.MJData"
local deskManager = require "app.logic.deskManager"
local dataManager = require "app.data.dataManager"
local appConfig = require "appConfig"
local networkManager = require "app.network.NetworkManager"
local typeDefine = require "app.data.typeDefine"
local gameAssistant = require "app.logic.gameAssistant"
local EventManager = require "app.core.EventManager"

local OPTYPE = {}
OPTYPE.chupai = 1
OPTYPE.peng = 2
OPTYPE.gang = 3
OPTYPE.hu = 4
OPTYPE.pass = 5
OPTYPE.duoxiang = 8

local OPTYPEString = {}
OPTYPEString.PENG = "peng"
OPTYPEString.GANG = "gang"
OPTYPEString.HU = "hu"
OPTYPEString.GUO = "guo"

local DingQueStatus = {}
DingQueStatus.unStarted = 1
DingQueStatus.started = 2
DingQueStatus.ended = 3

function NetMJManager:ctor(ui, logic)
    self.m_ui = ui
    self.m_logic = logic
    ui:setManager(self)
    self.m_isDuanPai = false
    self.m_duanPaiCount = 0
    self.m_hasPass = false
    self.m_pengVec = nil
    self.m_gangVec = nil
    self.m_huVec = nil
    self.m_isEnd = false
    self.m_localChuPaiParam = {}
    self.qiPaiFinished = false

    self.m_isPlaying = false
    --关闭听牌提示
    --[[threadhelper.checkting_register_callback(function(tings, id)
        for i = 1, #tings do
            local oneChoose = tings[i]
            for j = 1, #oneChoose.hu do
                local huInfo = oneChoose.hu[j]
                local idx = huInfo.idx
                local left = 4 - self.m_logic:getKnowMjCount(idx)
                oneChoose.hu[j] = { idx = huInfo.idx, fan = huInfo.fan, left = left }
            end
        end
        self.m_ui:onMJCheckTingOrHuOK(id, tings)
        printInfo("check ting ret:%d, ret:%s", id, vardump(tings))
    end)]]
end

function NetMJManager:onQueChoose(queType)
    self.m_ui:showSelfDingQueAction(queType)
    networkManager.notify("DeskManager.DingQue", { que = queType })
end

function NetMJManager:onGangChoose(idx)
    self.m_ui:hideOperateUI()
    networkManager.notify("DeskManager.OpChoose", { optype = OPTYPE.gang, idx = idx })
end

function NetMJManager:onPengChoose()
    self.m_ui:hideOperateUI()
    networkManager.notify("DeskManager.OpChoose", { optype = OPTYPE.peng, idx = self.m_pengVec[1] })
end

function NetMJManager:onHuChoose()
    self.m_ui:hideOperateUI()
    networkManager.notify("DeskManager.OpChoose", { optype = OPTYPE.hu, idx = self.m_huVec[1] })
end

function NetMJManager:onGuoChoose()
    self.m_ui:hideOperateUI()
    networkManager.notify("DeskManager.OpChoose", { optype = OPTYPE.pass })
end

function NetMJManager:onQueAction(data)
    for i = 1, #data do
        local t = data[i]
        t.turn = deskManager.playerDeskTurn(t.uid)
        t.que = t.que
    end
    self.m_logic:setDingQue(data)
    self.m_ui:showAllDingQueAction(data)
end

function NetMJManager:onQueHint(que)
    self.m_ui:showDingQueUI(que)
end

function NetMJManager:onChuPaiChoose(idx, data, islast)
    self.m_selfChuPaiData = data
    self.m_ui:refreshTing({})
    networkManager.notify("DeskManager.OpChoose", { optype = OPTYPE.chupai, idx = data:getNetValue() })

    self.m_ui:hideOperateUI()
    self.m_localChuPaiParam.idx = idx
    self.m_localChuPaiParam.data = data
    self.m_localChuPaiParam.islast = islast
end

function NetMJManager:setPlayerTurn(idx)
    self.m_ui:setPlayerTurn(idx)
    self.m_logic:setPlayerTurn(idx)
    self.m_playerTurn = idx
end

function NetMJManager:reset()
    self.m_isDuanPai = true
    self.m_hasOffset = false
    self.m_qiPaiTime = 1
    self.m_isPlaying = false
    self.m_isEnd = false
    self.qiPaiFinished = false
    self.m_scoreSettlementInfo = nil
    self.m_dingQueStatus = DingQueStatus.unStarted
end

function NetMJManager:startDuanPai(info)
    self:clearDesk()
    local dice1 = info.dice1
    local dice2 = info.dice2
    local makerId = info.markerId

    EventManager:dispatchEvent({ name = event_name.DESK_MAKER_CHANGED, acid = makerId })

    self.m_duanPaiUsedTime = self.m_ui:showReadyHeadAction(function()
        local makerTurn = deskManager.playerDeskTurn(makerId)
        self.m_makerTurn = makerTurn
        self.m_ui:setMakerByTurnIdx(makerTurn)
        self.m_logic:setMarker(makerTurn)
        self.m_ui:setDice(dice1, dice2)
        self.m_ui:qiPai()
        self.m_duanPaiCount = makerTurn

        local datas = {}
        self.m_allDatas = {}
        for _, pl in pairs(info.accountInfo) do
            local netIdxs = pl.mjs
            local tmp = {}
            for _, v in pairs(netIdxs) do
                local data = MJDataClass:create(v, true)
                table.push(tmp, data)
            end
            local turn = deskManager.playerDeskTurn(pl.acId)
            self.m_allDatas[turn] = tmp
            if turn == self.m_playerTurn then
                datas = tmp
            end
            printInfo("turn=%d, mjs=%d", turn, #tmp)
        end

        self.m_logic:moPaiTable(self.m_playerTurn, datas)

        self.m_datas = datas
        self:reset()
        self.m_isPlaying = true

        self.m_duanPaiUsedTime = self.m_duanPaiUsedTime
        self.m_updateHandler = scheduler.scheduleGlobal(handler(self, NetMJManager.update), 0.1)
    end)
end

function NetMJManager:exit()
    scheduler.unscheduleGlobal(self.m_updateHandler)
    threadhelper.checkting_unregister_callback()
end

function NetMJManager:duanPai(dt)
    self.m_duanPaiUsedTime = self.m_duanPaiUsedTime + dt
    if not self.m_isDuanPai then
        if not self.m_liPaiWaitTime then
            self.m_liPaiWaitTime = 1
        end

        if self.m_liPaiWaitTime > 0 then
            self.m_liPaiWaitTime = self.m_liPaiWaitTime - dt
            if self.m_liPaiWaitTime < 0 then
                self.m_ui:setCurOperateDirByTurn(self.m_makerTurn)
                self.m_ui:liPai(function()
                    if not self.m_ui.isLookback then
                        networkManager.notify("DeskManager.QiPaiFinished", {})
                    end
                    self.qiPaiFinished = true
                end)
                scheduler.unscheduleGlobal(self.m_updateHandler)
            end
        end
        return
    end
    if self.m_qiPaiTime > 0 then
        self.m_qiPaiTime = self.m_qiPaiTime - dt
        if self.m_qiPaiTime > 0 then
            return
        end
    end
    local datas = self.m_allDatas[self.m_duanPaiCount] --self.m_datas
    local ret = self.m_ui:duanPai(self.m_duanPaiCount, datas)
    if ret > 0 then
        --if self.m_playerTurn == self.m_duanPaiCount then
        for i = 1, ret do
            table.remove(datas, 1)
        end
        --end
        self.m_duanPaiCount = deskManager.getNextDuanPaiTurn(self.m_duanPaiCount)
    else
        local netidx = datas[1]:getNetValue()
        --if self.m_playerTurn == self.m_duanPaiCount then
        --end
        self:moPai(deskManager.getPlayerData(self.m_duanPaiCount):getAcId(), netidx, true)
        self.m_isDuanPai = false
        self.m_hasOffset = true
        if self.m_playerTurn == self.m_duanPaiCount then
            table.remove(datas, 1)
        end
        self.m_liPaiWaitTime = 1
    end
end

function NetMJManager:update(dt)
    self:duanPai(dt)
end

function NetMJManager:moPai(acId, netidx, notToLogic)
    if not self.m_isPlaying then
        return
    end
    local turn = deskManager.playerDeskTurn(acId)
    local data = nil
    if turn == self.m_playerTurn or (netidx and netidx >= 0) then
        data = MJDataClass:create(netidx, true)
    end
    if not notToLogic then
        data = self.m_logic:moPai(turn, data)
        if turn == self.m_playerTurn then
            self:checkhasTing(turn)
        end
    end
    self.m_ui:moPai(turn, data, self.m_hasOffset, function(usedTime)
        if not notToLogic then
            self.m_ui:setCurOperateDirByTurn(turn)
        end
    end)
end

function NetMJManager:getGangVec()
    return self.m_gangVec
end

function NetMJManager:actionHint(actions, uid, tings)
    if not self.m_isPlaying then
        return
    end
    local hints = {}
    local hasChuPai = false
    self.m_hasPass = false
    self.m_gangVec = {}
    self.m_pengVec = {}

    -- 刷新听牌提示
    self.m_ui:refreshTing(tings)
    for _, action in ipairs(actions) do
        if action.op == OPTYPE.chupai then
            hasChuPai = true
        elseif action.op == OPTYPE.peng then
            self.m_pengVec = action.mjidxs
        elseif action.op == OPTYPE.gang then
            for _, netIdx in pairs(action.mjidxs) do
                local data = MJDataClass:create(netIdx, true)
                table.push(self.m_gangVec, { mjData = data, gType = "ming" })
            end
        elseif action.op == OPTYPE.hu then
            table.push(hints, "hu")
            self.m_huVec = action.mjidxs
        elseif action.op == OPTYPE.pass then
            table.push(hints, "guo")
            self.m_hasPass = true
        end
    end

    -- 是否有杠牌提示
    if #self.m_gangVec > 0 then
        table.push(hints, "gang")
    end

    -- 是否有碰牌提示
    if #self.m_pengVec > 0 then
        table.push(hints, "peng")
    end

    if #hints > 0 then
        if not self.m_hasPass then
            table.push(hints, "guo")
            self.m_ui:enableChuPai()
        end
        self.m_ui:showOperateUI(hints)
        self.m_ui:setCurOperateDirByTurn(self.m_playerTurn)
        return
    end

    if hasChuPai then
        self.m_ui:enableChuPai()
    end
end

function NetMJManager:action(optype, uid, mjs, huType)
    if not self.m_isPlaying then
        return
    end
    local acId = uid[1]
    self:onPlayerOfflineStatus(acId, false)

    local doturn = deskManager.playerDeskTurn(acId)
    if optype == OPTYPE.chupai then --chupai
        self:chuPai(doturn, mjs[1])

    elseif optype == OPTYPE.peng then
        local beturn = self.m_logic:getLastChuPaiStatus()
        local turn = deskManager.playerDeskTurn(acId)
        self:pengPai(turn, beturn, mjs)
    elseif optype == OPTYPE.gang then
        local turn = deskManager.playerDeskTurn(uid[1])
        local lastChupaiTurn, lastChuPaiData = self.m_logic:getLastChuPaiStatus()
        --ming gang
        if lastChuPaiData and lastChuPaiData:getNetValue() == mjs[1] then
            self:mingGang(turn, lastChupaiTurn, mjs)
        else
            if #mjs == 1 then
                self:baGang(turn, mjs)
            else
                self:anGang(turn, mjs)
            end
        end
    elseif optype == OPTYPE.hu then
        local tile = mjs[1]
        local beturn, lastChuPaiData = self.m_logic:getLastChuPaiStatus()
        if self.m_logic:isQiangGang(tile) then
            self:qiangGang(doturn, beturn, tile)
        elseif not self.m_ui.m_desk3d:isTileOnHand(doturn, tile) then --hu other
            if typeDefine.sHuType.gangShangPao == huType then
                self.m_ui:playGSPFontAnimation(beturn)
                self.m_ui:callFunctionAfterTime(1, function()
                    self:huOther(doturn, beturn, tile)
                end)
            else
                self:huOther(doturn, beturn, tile)
            end
        else
            --zimo
            self:ziMo(doturn, tile, typeDefine.sHuType.gangShangHua == huType)
        end
    elseif optype == OPTYPE.duoxiang then
        local beturn, lastChuPaiData = self.m_logic:getLastChuPaiStatus()
        if typeDefine.sHuType.gangShangPao == huType then
            self.m_ui:playGSPFontAnimation(beturn)
        else
            self.m_ui:playYPDXFontAnimation(beturn)
        end
        self.m_ui:callFunctionAfterTime(1, function()
            if self.m_logic:isQiangGang(mjs[1]) then
                for i = 1, #uid do
                    local turn = deskManager.playerDeskTurn(uid[i])
                    self:qiangGang(turn, beturn, mjs[1], true)
                end
            elseif not self.m_logic:isZiMo(doturn) then
                for i = 1, #uid do
                    local turn = deskManager.playerDeskTurn(uid[i])
                    self:huOther(turn, beturn, mjs[1], true)
                end
            end
        end)
    end
    if doturn == self.m_playerTurn then
        self.m_ui:hideOperateUI()
    end
end

function NetMJManager:chuPai(turn, netidx)
    if not self.m_isPlaying then
        return
    end
    local data = MJDataClass:create(netidx, true)
    data = self.m_logic:chuPai(turn, data)
    self.m_ui:chuPai(turn, data)
end

-- 暂时不开启出牌提示
function NetMJManager:checkhasTing(turn)
    --[[
    if turn ~= self.m_playerTurn then
        return
    end
    self.m_ui:enableShowChuPaiHint(false, nil)
    local vec = self.m_logic:getShouPai(turn)
    local pgVec = self.m_logic:getPGPai(turn)
    local ret = self.m_logic:checkHasTing(vec, pgVec)
    self.m_ui:enableShowChuPaiHint(true, ret)
    --]]
end

function NetMJManager:checkHasHu(turn)
    --[[if turn == self.m_playerTurn then
        local vec = self.m_logic:getShouPai(self.m_playerTurn)
        local pgVec = self.m_logic:getPGPai(self.m_playerTurn)
        local ret = self.m_logic:checkHasHu(vec, pgVec)
        self.m_ui:setCheckHuId(ret)
    end]]
end

function NetMJManager:pengPai(turn, beturn, netidx)
    local data = MJDataClass:create(netidx[1], true)
    local d1 = MJDataClass:create(netidx[2], true)
    local d2 = MJDataClass:create(netidx[3], true)
    local ret = self.m_logic:pengPai(turn, beturn, data, d1, d2)
    self.m_ui:pengPai(turn, beturn, ret)
    self:checkhasTing(turn)
end

function NetMJManager:mingGang(turn, beturn, netidxs)
    local data = MJDataClass:create(netidxs[1], true)
    local d1 = MJDataClass:create(netidxs[2], true)
    local d2 = MJDataClass:create(netidxs[3], true)
    local d3 = MJDataClass:create(netidxs[4], true)
    local ret = self.m_logic:mingGang(turn, beturn, data, d1, d2, d3)
    self.m_ui:mingGang(turn, beturn, ret)
    self.m_ui:disableChuPai()
    self.m_ui:enableShowChuPaiHint(false, nil)
end

function NetMJManager:anGang(turn, netIdxs)
    local data = MJDataClass:create(netIdxs[1], true)
    local d1 = MJDataClass:create(netIdxs[2], true)
    local d2 = MJDataClass:create(netIdxs[3], true)
    local d3 = MJDataClass:create(netIdxs[4], true)
    local ret = self.m_logic:anGang(turn, data, d1, d2, d3)
    self.m_ui:anGang(turn, ret)
    self.m_ui:disableChuPai()
    self.m_ui:enableShowChuPaiHint(false, nil)
end

function NetMJManager:baGang(turn, netidxs)
    local data = MJDataClass:create(netidxs[1], true)
    local ret = self.m_logic:baGang(turn, data)
    self.m_ui:baGang(turn, ret)
    self:checkhasTing(turn)
    self.m_ui:disableChuPai()
    self.m_ui:enableShowChuPaiHint(false, nil)
end

function NetMJManager:qiangGang(turn, beturn, netidx, isDouble)
    local data = self.m_logic:qiangGang(turn, beturn, MJDataClass:create(netidx, true))
    self.m_ui:qiangGang(turn, beturn, data, isDouble)
end

function NetMJManager:huOther(turn, beturn, netidx, isDouble)
    local data = self.m_logic:huOther(turn, beturn, MJDataClass:create(netidx, true))
    self.m_ui:huOther(turn, beturn, data, isDouble)
end

function NetMJManager:ziMo(turn, netidx, isGSH)
    self.m_logic:ziMo(turn, MJDataClass:create(netidx, true))
    self.m_ui:ziMo(turn, nil, isGSH)
    self.m_ui:disableChuPai()
end

function NetMJManager:setDeskBasicInfo(basicInfo)
    self.m_basicInfo = basicInfo
    self.m_ui:setDeskInfo(basicInfo.title, basicInfo.desc)
    self.m_logic:reset()
end

function NetMJManager:onScoreChange(changes)
    if not changes then return end
    for _, v in pairs(changes) do
        v.turn = deskManager.playerDeskTurn(v.acId)
        deskManager.onPlayerScoreChange(v.turn, v.score)
    end
end

function NetMJManager:gangScoreChange(changes, isXiaYu)
    if not self.m_isPlaying then
        return
    end
    self:onScoreChange(changes)
    self.m_ui:showGangScoreChang(changes, isXiaYu)
end

function NetMJManager:huScoreChange(change)
    if not self.m_isPlaying then
        return
    end

    change.turn = deskManager.playerDeskTurn(change.acId)
    if change.turn == self.m_playerTurn then
        deskManager.onPlayerScoreChange(change.turn, change.totalWinScore)
    end
    self:onScoreChange(change.scoreChange)

    self.m_ui:huScoreChange({ change })
end

function NetMJManager:clearDesk()
    self:reset()
    self.m_ui:clearDesk()
    self.m_logic:reset()
end

--- 一轮游戏结束，分为三种情况
-- 1. 正常一轮结束，显示结算
-- 2. 回放结束显示结算，此时`isLookback`为`true`
-- 3. 最后一轮结算，最后一轮结算最后两个参数为总结算数据，分别为标题和总积分
-- @param tiles
-- @param refunds
-- @param chaJiaos
-- @param stats
-- @param scoreChange
-- @param title
-- @param round
-- @param isLookback 是否是回放
-- @param gameOverTitle 总结算标题
-- @param gameOverStats 总结算统计结果
-- @param isNormalFinished 是否是满场结算，否则为解散
--
function NetMJManager:roundEnd(tiles, stats, scoreChange, title, round, isLookback, gameOverTitle, gameOverStats, isNormalFinished)
    if not self.m_isPlaying then
        EventManager:dispatchEvent({ name = event_name.CLOSE_DISSOLVE_UI })
        --游戏未开局，三个人解散房间，直接退出游戏
        gameAssistant.showHintAlertUI("房间已经解散", function()
            deskManager.exit()
        end)
        return
    end

    for _, v in pairs(scoreChange) do
        deskManager.setPlayerTotalScore(v.acId, v.remain)
    end

    --self.m_isPlaying = false
    for _, v in pairs(tiles) do
        v.turn = deskManager.playerDeskTurn(v.acId)
        for i = 1, #v.shouPai do
            v.shouPai[i] = MJDataClass:create(v.shouPai[i], true)
        end
        if v.huPai >= 0 then
            v.huPai = MJDataClass:create(v.huPai, true)
        else
            v.huPai = nil
        end
    end

    self.m_ui:onRoundEnd()
    self.m_ui:showAllHandTiles(tiles, stats, title, round, isLookback, gameOverTitle, gameOverStats, isNormalFinished)
    self.m_isEnd = true
end

function NetMJManager:onDissolve(data)
    if data.exitType == typeDefine.sExitType.exitTypeDissolve then
        EventManager:dispatchEvent({ name = event_name.CLOSE_DISSOLVE_UI })
    end
    gameAssistant.showHintAlertUI("房间已经解散", function()
        deskManager.exit()
    end)
end

function NetMJManager:onDissolveAgreement(data)
    self.m_ui:onDissolveAgreement(data)
end

function NetMJManager:onDissolveStatus(data)
    EventManager:dispatchEvent({
        name = event_name.DISSOLVE_STATUS_CHANGE,
        dissolveStatus = data.dissolveStatus,
        restTime = data.restTime,
    })
end

function NetMJManager:onDissolveFailure(data)
    self.m_ui:onDissolveFailure(data)
end

function NetMJManager:onDissolveSuccess()
    self.m_ui:onDissolveSuccess()
end

function NetMJManager:isEnd()
    return self.m_isEnd
end

function NetMJManager:zhuanYu(beAcId, beCoin, acIds, isZhiGang)
    if not self.m_isPlaying then
        return
    end
    self:onScoreChange(acIds)
    local turn = deskManager.playerDeskTurn(beAcId)
    deskManager.onPlayerScoreChange(turn, beCoin)
    self.m_ui:onZhuanYu(beAcId, beCoin, acIds, isZhiGang)
end

function NetMJManager:syncDesk(info)
    self:clearDesk()
    self.m_ui:hideNormalMessageHint()
    self.m_isPlaying = true
    -- 还没有断牌
    if info.status == 0 then
        return
    end
    for _, v in ipairs(info.players) do
        v.turn = deskManager.playerDeskTurn(v.acId)
        -- 同步积分
        local playerData = deskManager.getPlayerData(v.turn)
        playerData:setScore(v.score)

        v.shouPaiDatas = {}
        for i, id in ipairs(v.shouPaiIds) do
            v.shouPaiDatas[i] = MJDataClass:create(id, true)
        end

        v.chuPaiDatas = {}
        for i, id in ipairs(v.chuPaiIds) do
            v.chuPaiDatas[i] = MJDataClass:create(id, true)
        end

        v.pengGangDatas = {}
        v.pengGangCounter = {}
        for i, id in ipairs(v.gangInfos) do
            local mj = MJDataClass:create(id, true)
            local idx = tostring(mj:getIdx())
            if not v.pengGangCounter[idx] then
                v.pengGangCounter[idx] = 0
            end
            v.pengGangCounter[idx] = v.pengGangCounter[idx] + 1
            v.pengGangDatas[i] = mj
        end
        if v.hasHuPai and v.huId then
            v.huData = MJDataClass:create(v.huId, true)
        end
    end
    info.markerTurn = deskManager.playerDeskTurn(info.markerAcId)
    info.lastMoPaiTurn = deskManager.playerDeskTurn(info.lastMoPaiAcId)
    info.lastChuPaiTurn = deskManager.playerDeskTurn(info.lastChuPaiUid)
    info.lastChuPaiData = MJDataClass:create(info.lastChuPaiId, true)
    self.m_makerTurn = info.markerTurn
    self.m_isDuanPai = false
    self.m_hasOffset = true

    if not info.lastMoPaiTurn then
        info.lastMoPaiTurn = self.m_makerTurn
    end
    self.m_logic:syncDesk(info)
    self.m_ui:syncDesk(info)

    if not self.m_ui:isEnableChuPai() and not info.lastMoPaiTurn then
        self.m_ui:makeLastMJOffset(info.lastMoPaiTurn)
    end
end

function NetMJManager:getPGSimpleInfo()
    return self.m_logic:getPGSimpleInfo()
end

function NetMJManager:getSelfHandTiles()
    return self.m_ui:getSelfHandTiles()
end

function NetMJManager:onVoiceMessage(info)
    self.m_ui:onPlayerVoiceMessage(info)
end

function NetMJManager:onPlayerOfflineStatus(uid, offline)
    EventManager:dispatchEvent({ name = event_name.DESK_HEADUI_OFFLINE_STATUS_CHANGE, acId = uid, offline = offline })
end

function NetMJManager:onTileFirstChosen(mj)
    self.m_ui:onTileFirstChosen(mj)
end

return NetMJManager
