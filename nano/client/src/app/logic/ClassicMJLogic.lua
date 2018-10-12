local ClassicMJLogic = class("ClassicMJLogic")
local MJDataClass = require "app.core.MJData"
local TimeCount = require "app.core.TimeCount"

local function initVec(tmp, playerCout)
    for i = 1, playerCout do
        tmp[i] = {}
    end
end

function ClassicMJLogic:ctor(playerCount)
    self.m_shouPai = {}
    self.m_chuPai = {}
    self.m_pengPai = {}
    self.m_pgSimpleInfo = {}
    self.m_selfTurn = 1
    self.m_paiDui = {}
    self.m_dingQue = {}

    self.m_totalKnowMj = {}

    self.m_curChuPaiTurn = 0
    self.m_curChuPaiData = nil
    self.m_lastBaGangMj = nil
    self.m_lastMoPaiTurn = nil
    self.m_knowMJIdx = {}
    self.m_isHu = false
    self.m_playerCount = playerCount
    self:reset()
end

function ClassicMJLogic:_copyDataTableTo(vec, tovec)
    for _, v in ipairs(vec) do
        table.push(tovec, v)
        self:addKnowMjByData(v)
    end
end

function ClassicMJLogic:isHu()
    return self.m_isHu
end

function ClassicMJLogic:getPGSimpleInfo()
    return self.m_pgSimpleInfo[self.m_selfTurn]
end

local PGType = {}
PGType.PENG = 0
PGType.AN_GANG = 2
PGType.MING_GANG = 2
PGType.BA_GANG = 1

function ClassicMJLogic:syncDesk(info)
    self:setMarker(info.markerTurn)
    if info.lastMoPaiTurn then
        self.m_lastMoPaiTurn = info.lastMoPaiTurn
    end
    self.m_curChuPaiTurn = info.lastChuPaiTurn
    self.m_curChuPaiData = info.lastChuPaiData
    for _, v in ipairs(info.players) do
        -- 定缺处理
        self.m_dingQue[v.turn] = v.que

        -- 碰杠处理
        self:_copyDataTableTo(v.shouPaiDatas, self.m_shouPai[v.turn])
        self:_copyDataTableTo(v.chuPaiDatas, self.m_chuPai[v.turn])
        self:_copyDataTableTo(v.pengGangDatas, self.m_pengPai[v.turn])
        v.pengGangStats = {}
        for idx, count in pairs(v.pengGangCounter) do
            assert(count == 3 or count == 4, "wrong peng/gang counter")
            idx = tonumber(idx)
            local turnInfo = self.m_pgSimpleInfo[v.turn]
            local pgInfo = {}
            pgInfo.index = idx
            pgInfo.mjs = {}
            if count == 3 then
                turnInfo[idx] = "peng"
                pgInfo.type = PGType.PENG
            elseif count == 4 then
                turnInfo[idx] = "mingGang"
                pgInfo.type = PGType.MING_GANG
            end

            for _, mj in ipairs(v.pengGangDatas) do
                if mj:getIdx() == idx then
                    table.push(pgInfo.mjs, mj)
                end
            end

            table.push(v.pengGangStats, pgInfo)
        end
        --[[for _, gangInfo in ipairs(v.gangInfos) do
            self:_copyDataTableTo(gangInfo.datas, self.m_pengPai[v.turn])
            if gangInfo.type == PGType.PENG then
                local turnInfo = self.m_pgSimpleInfo[v.turn]
                turnInfo[gangInfo.datas[1]:getIdx()] = "peng"
            elseif gangInfo.type == PGType.AN_GANG then
                local turnInfo = self.m_pgSimpleInfo[v.turn]
                turnInfo[gangInfo.datas[1]:getIdx()] = "anGang"
            elseif gangInfo.type == PGType.MING_GANG then
                local turnInfo = self.m_pgSimpleInfo[v.turn]
                turnInfo[gangInfo.datas[1]:getIdx()] = "mingGang"
            elseif gangInfo.type == PGType.BA_GANG then
                local turnInfo = self.m_pgSimpleInfo[v.turn]
                turnInfo[gangInfo.datas[1]:getIdx()] = "baGang"
            end
        end]]
        if self.m_curChuPaiTurn and self.m_curChuPaiTurn == v.turn then
            local lastData = self.m_chuPai[v.turn][#self.m_chuPai[v.turn]]
            if lastData == nil or lastData:getNetValue() ~= info.lastChuPaiId then
                --info.lastChuPaiData = nil
            end
        end
    end

    self.m_lastBaGangMj = info.lastBaGangData
end

function ClassicMJLogic:addKnowMjByData(data)
    local netidx = data:getNetValue()
    if netidx < 0 then return end
    if self.m_knowMJIdx[netidx] == nil then
        self.m_knowMJIdx[netidx] = true
        self:addKnowMj(data:getIdx(), 1)
    end
end

function ClassicMJLogic:setSelfTurn(idx)
    self.m_selfTurn = idx
end

function ClassicMJLogic:reset()
    initVec(self.m_shouPai, self.m_playerCount)
    initVec(self.m_chuPai,self.m_playerCount)
    initVec(self.m_pengPai,self.m_playerCount)
    initVec(self.m_pgSimpleInfo,self.m_playerCount)

    for k, v in pairs(self.m_totalKnowMj) do
        self.m_totalKnowMj[k] = 0
    end
    for k, v in pairs(self.m_knowMJIdx) do
        self.m_knowMJIdx[k] = nil
    end
    self:resetPaiDui()
    self.m_lastBaGangMj = nil
    self.m_lastMoPaiTurn = nil
    self.m_curChuPaiData = nil
    self.m_isHu = false
    self.m_dingQue = {}
end

local function checkMjIsEq(t1, t2)
    return t1:getIdx() == t2:getIdx()
end

function ClassicMJLogic:setMarker(turn)
    self.m_lastMoPaiTurn = turn
end

--public functions
function ClassicMJLogic:getLeftMJCount(turn)
    return #self.m_shouPai[turn]
end

function ClassicMJLogic:setPlayerTurn(playerTurn)
    self.m_selfTurn = playerTurn
end

function ClassicMJLogic:moPaiTable(turn, data)
    if turn == self.m_selfTurn then
        for _, v in pairs(data) do
            table.push(self.m_shouPai[turn], v)
            self:addKnowMj(v:getIdx(), 1)
        end
    end
    return data
end

function ClassicMJLogic:moPai(turn, data)
    if turn == self.m_selfTurn then
        table.push(self.m_shouPai[turn], data)
        self:addKnowMj(data:getIdx(), 1)
    end
    self.m_lastMoPaiTurn = turn
    return data
end

function ClassicMJLogic:isZiMo(turn)
    return self.m_lastMoPaiTurn == turn
end

function ClassicMJLogic:chuPai(turn, data)
    if turn == self.m_selfTurn then
        local ret = self:_findMJByNetIdx(self.m_shouPai[turn], data:getNetValue())
        if not ret then
            local shoupai = self.m_shouPai[turn]
            local allId = {}
            for i = 1, #shoupai do
                table.insert(allId, shoupai[i]:getNetValue())
            end
            assert(ret, "ClassicMJLogic:chuPai: tile not found, shoupai:" .. json.encode(allId) .. "chuPai:" .. json.encode(data:getNetValue()))
        end
        data = ret
    else
        self:addKnowMj(data:getIdx(), 1)
    end
    table.push(self.m_chuPai[turn], data)
    table.removebyvalue(self.m_shouPai[turn], data)
    self.m_curChuPaiTurn = turn
    self.m_curChuPaiData = data
    return data
end

function ClassicMJLogic:getLastChuPaiStatus()
    return self.m_curChuPaiTurn, self.m_curChuPaiData
end

function ClassicMJLogic:pengPai(turn, beTurn, data, d1, d2)
    assert(beTurn == self.m_curChuPaiTurn, "ClassicMJLogic:pengPai: beturn")
    local data = self.m_curChuPaiData
    local ret = {}
    table.push(ret, self.m_curChuPaiData)
    if turn == self.m_selfTurn then
        d1 = self:_findMJByNetIdx(self.m_shouPai[turn], d1:getNetValue())
        d2 = self:_findMJByNetIdx(self.m_shouPai[turn], d2:getNetValue())
        table.push(ret, d1)
        table.push(ret, d2)
        table.removebyvalue(self.m_shouPai[turn], d1)
        table.removebyvalue(self.m_shouPai[turn], d2)
    else
        d1 = d1 or MJDataClass:create(data:getIdx())
        d2 = d2 or MJDataClass:create(data:getIdx())
        table.push(ret, d1)
        table.push(ret, d2)
        self:addKnowMj(data:getIdx(), 2)
    end
    for _, v in pairs(ret) do
        table.push(self.m_pengPai[turn], v)
    end

    local turnInfo = self.m_pgSimpleInfo[turn]
    turnInfo[data:getIdx()] = "peng"
    table.removebyvalue(self.m_chuPai[self.m_curChuPaiTurn], self.m_curChuPaiData)
    return ret
end

function ClassicMJLogic:baGang(turn, data)
    local shoupai = self.m_shouPai[turn]
    assert(shoupai ~= nil, "ClassicMJLogic:anGang: shoupai should not nil")
    if turn == self.m_selfTurn then
        local ret = self:_findMJByNetIdx(shoupai, data:getNetValue(), 1)
        data = ret
        assert(ret, "ClassicMJLogic:baGang: ")
    else
        self:addKnowMj(data:getIdx(), 1)
    end
    assert(#self:_findMJByIdx(self.m_pengPai[turn], data:getIdx(), 3) >= 3, "ClassicMJLogic:baGang:")
    table.removebyvalue(shoupai, data)
    table.push(self.m_pengPai[turn], data)
    printInfo("turn: %d, shoupai: %s", turn, vardump(shoupai))
    printInfo("turn: %d, all shoupai: %s", turn, vardump(self.m_shouPai))
    self.m_lastBaGangMj = data
    local turnInfo = self.m_pgSimpleInfo[turn]
    turnInfo[data:getIdx()] = "baGang"
    return data
end

function ClassicMJLogic:countShouPaiByIdx(turn, idx)
    local datas = self:_findMJByIdx(self.m_shouPai[turn], idx, 5)
    return #datas
end

function ClassicMJLogic:anGang(turn, data, d1, d2, d3)
    local ret = {}
    local shoupai = self.m_shouPai[turn]
    assert(shoupai ~= nil, "ClassicMJLogic:anGang: shoupai should not nil")
    if turn == self.m_selfTurn then
        local tmp = {}
        tmp[1] = self:_findMJByNetIdx(shoupai, data:getNetValue())
        tmp[2] = self:_findMJByNetIdx(shoupai, d1:getNetValue())
        tmp[3] = self:_findMJByNetIdx(shoupai, d2:getNetValue())
        tmp[4] = self:_findMJByNetIdx(shoupai, d3:getNetValue())
        assert(#tmp >= 4, "ClassicMJLogic:anGang:")
        for _, v in pairs(tmp) do
            table.push(ret, v)
        end
    else
        self:addKnowMj(data:getIdx(), 4)
        table.push(ret, data)
        table.push(ret, d1)
        table.push(ret, d2)
        table.push(ret, d3)
    end
    for _, v in pairs(ret) do
        table.removebyvalue(shoupai, v)
        table.push(self.m_pengPai[turn], v)
    end
    printInfo("turn: %d, shoupai: %s", turn, vardump(shoupai))
    local turnInfo = self.m_pgSimpleInfo[turn]
    turnInfo[data:getIdx()] = "anGang"
    return ret
end

function ClassicMJLogic:mingGang(turn, beturn, data, d1, d2, d3)
    local ret = {}
    data = self:_findMJByNetIdx(self.m_chuPai[beturn], data:getNetValue())
    table.push(ret, self.m_curChuPaiData)
    if turn == self.m_selfTurn then
        local my = {}
        my[1] = self:_findMJByNetIdx(self.m_shouPai[turn], d1:getNetValue())
        my[2] = self:_findMJByNetIdx(self.m_shouPai[turn], d2:getNetValue())
        my[3] = self:_findMJByNetIdx(self.m_shouPai[turn], d3:getNetValue())
        assert(#my >= 3, "ClassicMJLogic:mingGang: self ming gang, must hanve three mj in shou pai.")
        for _, v in pairs(my) do
            table.removebyvalue(self.m_shouPai[turn], v)
            table.push(ret, v)
        end
    else
        self:addKnowMj(data:getIdx(), 3)
        table.push(ret, d1)
        table.push(ret, d2)
        table.push(ret, d3)
    end
    table.removebyvalue(self.m_chuPai[self.m_curChuPaiTurn], self.m_curChuPaiData)
    for _, v in pairs(ret) do
        table.push(self.m_pengPai[turn], v)
    end
    local turnInfo = self.m_pgSimpleInfo[turn]
    turnInfo[data:getIdx()] = "mingGang"
    return ret
end

function ClassicMJLogic:isQiangGang(data)
    if not self.m_lastBaGangMj then return false end
    return data == self.m_lastBaGangMj:getNetValue()
end

function ClassicMJLogic:qiangGang(turn, beturn, data)
    if turn == self.m_selfTurn then
        self.m_isHu = true
    end
    return self.m_lastBaGangMj
end

function ClassicMJLogic:huOther(turn, beturn)
    assert(beturn == self.m_curChuPaiTurn, "ClassicMJLogic:huOther: chu pais turn must equal to beturn.")
    if turn == self.m_selfTurn then
        self.m_isHu = true
    end
    return self.m_curChuPaiData
end

function ClassicMJLogic:ziMo(turn, data)
    if turn == self.m_selfTurn then
        data = self:_findMJByNetIdx(self.m_shouPai[turn], data:getNetValue())
    end
    if turn == self.m_selfTurn then
        self.m_isHu = true
    end
    return data
end

function ClassicMJLogic:resetPaiDui()
    for i = 1, 84 do self.m_paiDui[i] = i end
end

function ClassicMJLogic:getOneFromPaiDui()
    assert(#self.m_paiDui >= 1, "pai dui has no ma jiang.")
    local rd = math.random(1, #self.m_paiDui)
    local idx = self.m_paiDui[rd]
    table.remove(self.m_paiDui, rd)
    return MJDataClass:create(idx, true)
end

--private functions
function ClassicMJLogic:addKnowMj(idx, cn)
    local cur = self.m_totalKnowMj[idx] or 0
    cur = cur + cn
    --assert(cur <= 4, "ClassicMJLogic:addKnowMj: knowMjCount:" .. cur .. " mjIdx:" .. idx)
    if cur > 4 then
        printError("ClassicMJLogic:addKnowMj: knowMjCount:" .. cur .. " mjIdx:" .. idx)
    end
    self.m_totalKnowMj[idx] = cur
end

function ClassicMJLogic:getKnowMjCount(idx)
    local cnt = self.m_totalKnowMj[idx]
    return cnt or 0
end

function ClassicMJLogic:_checkHasPeng(mjVec, mjData)
    assert(not table.indexof(mjVec, mjData), "_checkHasPeng: mjdata must not in mjvec")
    local shoupai = mjVec
    local count = table.count(shoupai, mjData, checkMjIsEq)
    if count >= 3 and hasIn then return true end
    if count >= 2 and not hasIn then return true end
    return false
end

function ClassicMJLogic:_checkCount(mjVec)
    local ret = {}
    local shoupai = mjVec
    local idx = 0
    local count = 0
    for i = 1, #shoupai do
        local curIdx = shoupai[i]:getIdx()
        if curIdx ~= idx then
            local tmp = {}
            tmp.value = idx
            tmp.count = count
            table.push(ret, tmp)
            idx = curIdx
            count = 1
        else
            count = count + 1
        end
    end
    if count > 0 then
        local tmp = { value = idx, count = count }
        table.push(ret, tmp)
    end
    return ret
end

function ClassicMJLogic:_checkHasAnGang(mjVec)
    local tmp = self:_checkCount(mjVec)
    local ret = {}
    for i = 1, #tmp do
        if tmp[i].count >= 4 then
            table.push(ret, tmp[i])
        end
    end
    return ret
end

function ClassicMJLogic:_checkHasBaGang(mjVec, mjData)
    assert(not table.indexof(mjVec, mjData), "_checkHasBaGang: mjdata must not in mjvec")
    local pengpai = mjVec
    local count = table.count(pengpai, mjData, checkMjIsEq)
    if count >= 1 then return true end
    return false
end

function ClassicMJLogic:_checkHasMingGang(mjVec, mjData)
    assert(not table.indexof(mjVec, mjData), "_checkHasMingGang: mjdata must not in mjvec")
    local shoupai = mjVec
    local count = table.count(shoupai, mjData, checkMjIsEq)
    if count >= 4 then return true end
    return false
end

local function comp(data1, data2)
    local huase1 = data1:getHuaSe()
    local value1 = data1:getValue()
    local huase2 = data2:getHuaSe()
    local value2 = data2:getValue()
    local kou1 = data1.m_isEnableKou and 2 or 1
    local kou2 = data2.m_isEnableKou and 2 or 1

    return kou1 <= kou2 or huase1 <= huase2 or value1 <= value2

    --[[-- 扣牌放在以便
    if not kou1 and not kou2 then
        if huase1 == huase2 then
            return value1 <= value2
        end
        return huase1 <= huase2
    else
        return kou1 and not kou2
    end]]
end

function ClassicMJLogic:_removeMJByIdx(vec, idx, count)
    local cnt = #vec
    while cnt >= 1 do
        local t = vec[cnt]
        if t:getIdx() == idx then
            table.remove(vec, cnt)
            count = count - 1
            if count <= 0 then
                break
            end
        end
        cnt = cnt - 1
    end
end

function ClassicMJLogic:_findMJByNetIdx(vec, idx)
    for i = 1, #vec do
        if vec[i]:getNetValue() == idx then
            return vec[i]
        end
    end
    return nil
end

function ClassicMJLogic:_findMJByIdx(vec, idx, count)
    count = count or 1
    local ret = {}
    local hasFind = false
    for i = 1, #vec do
        if vec[i]:getIdx() == idx then
            table.push(ret, vec[i])
            hasFind = true
            count = count - 1
            if count <= 0 then
                break
            end
        end
    end
    return ret, hasFind
end

function ClassicMJLogic:_findThree(vec, mj)
    local ret = {}
    local huase = mj:getHuaSe()
    local value = mj:getValue()
    local three = self:_findMJByIdx(vec, mj:getIdx(), 3)
    if #three == 3 then table.push(ret, three) end
    for i = value - 2, value do
        if i >= 1 and i <= 7 then
            local a1, hasA1 = self:_findMJByIdx(vec, MJDataClass.computeIdx(huase, i), 1)
            local a2, hasA2 = self:_findMJByIdx(vec, MJDataClass.computeIdx(huase, i + 1), 1)
            local a3, hasA3 = self:_findMJByIdx(vec, MJDataClass.computeIdx(huase, i + 2), 1)
            if hasA1 and hasA2 and hasA3 then
                local tmp = {}
                table.push(tmp, a1[1])
                table.push(tmp, a2[1])
                table.push(tmp, a3[1])
                table.push(ret, tmp)
            end
        end
    end
    return ret
end

function ClassicMJLogic:_clone(t)
    local ret = {}
    for i = 1, #t do
        ret[i] = t[i]
    end
    return ret
end

function ClassicMJLogic:setDingQue(ques)
    for _, v in pairs(ques) do
        self.m_dingQue[v.turn] = v.que
    end
end

--- 关闭检查听牌
function ClassicMJLogic:_checkHasTing(vec, que)
    return nil, false
end

function ClassicMJLogic:checkHasTing(vec, pgVec, que)
    return nil
end

function ClassicMJLogic:checkHasHu(vec, pgVec, que)
    return nil
end


function ClassicMJLogic:getShouPai(turn)
    return self.m_shouPai[turn]
end

function ClassicMJLogic:getPGPai(turn)
    return self.m_pengPai[turn]
end

return ClassicMJLogic
