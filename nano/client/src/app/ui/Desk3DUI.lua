local typeDefine = require "app.data.typeDefine"
local scheduler = require("app.core.scheduler")
local networkManager = require "app.network.NetworkManager"
local Desk3DUI = class("Desk3DUI", cc.load("mvc").ViewBase)
local MJDataClass = require "app.core.MJData"
local MJ3DUI = require "app.ui.MJ3DUI"
local Dice = require "app.ui.Dice"
local configManager = require "app.config.configManager"
local stringDefine = require "app.data.stringDefine"
local TimeCount = require "app.core.TimeCount"
local deskManager = require "app.logic.deskManager"
local MJ3DUICreator = require "app.ui.MJ3DUICreator"

Desk3DUI.RESOURCE_FILENAME = "layout/desk3d.csb"
Desk3DUI.RESOURCE_BINDING = {
    camera = { id = "camera" },
}

local function judgeToMinMax(min, max, v)
    if v >= min and v <= max then return v end
    local diff = max - min + 1
    if v < min then v = v + diff end
    if v > max then v = v - diff end
    return judgeToMinMax(min, max, v)
end

local SELF_SIDE = 1 --自己的方位
local R1 = 90 --已出牌牌堆位置
local R2 = R1 + 100 --出牌过渡位置
local R3 = R2 + 110 --手牌位置
local R4 = R3 + 40 --碰杠牌位置
local R5 = R4 + 150 --牌桌边缘
local MJ_HOU = 18.4
local MJ_KUAN = 30
local MJ_GAO = 40
local CAMERA_MASK_3D = 2
local CAMERA_RX = -50
local SELF_MJ_SCALE = 1.53
local center_mark_direction = { 0, -90, 180, 90 }
local MOPAI_OFFSETX = 10
local PGGAP = -5
local PGMOVEX = 50
local PGMOVEZ = 2
local PGMOVE_TIME = 0.15
function Desk3DUI:initAsync()
    --相机初始化
    local mat = {}
    for i = 1, 16 do mat[i] = 0 end
    local mat = mat4_createScale(globalScale)
    self.camera:setAdditionalProjection(mat)
    CAMERA_RX = self.camera:getRotationX()

    local tt = TimeCount:create("Desk3DUI:initAsync")
    tt:start()
    self.m_manager = manager
    local creator = MJ3DUICreator:create("model/majiang.c3t",
        { x = 90, y = 0, z = 90 }, { x = -9.4, y = 0, z = 21.5 }, 0.68, "huase_3d/")
    self.tileCreator = creator
    tt:stop()
    coroutine.yield()

    tt:start()
    self.tings = {} -- 听牌
    self.chuTiles = self:initChuTiles() -- 出牌
    self.handTiles = self:initHandTiles() -- 手牌
    self.handTilePosition = self:initHandTilePosition() -- 手牌坐标
    self.pongKongTiles = self:initPongKongTiles() -- 碰杠牌
    coroutine.yield()

    self.curRestTileCount = deskManager.tileCount() -- 剩余麻将数
    self.isLookback = false -- 是否是回放
    self.isCanChuPai = false -- 是否能出牌
    self.chosenTile = nil -- 已选择的麻将
    self.deskLastTile = nil -- 牌桌当前麻将
    self.deskCurrentSide = 1 -- 牌桌当前麻将信息
    -- 玩家最近摸到的牌
    self.m_lastTiles = {}
    for i = 1, 4 do self.m_lastTiles[i] = -1 end
    tt:stop()

    tt:start()
    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/zhishi/zhishi.csb")
    self.currentDeskTileHint = ccs.Armature:create("zhishi")
    self.currentDeskTileHint:setCameraMask(2)
    self.currentDeskTileHint:setPosition3D(cc.vec3(0, 5, 0))
    self.currentDeskTileHint:setRotationX(CAMERA_RX)
    self:addChild(self.currentDeskTileHint)
    self.currentDeskTileHint:setLocalZOrder(1)
    self.currentDeskTileHint:getAnimation():playWithIndex(0)
    coroutine.yield()
    tt:stop()

    tt:start()
    self.allTiles = self:createAllTiles()

    self.m_redundantMj = {}
    self.m_redundantMjUsed = 0
    tt:stop()
    tt:start()

    self:resetDeskStatus()
    coroutine.yield()
    --registr 3d touch event
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:setSwallowTouches(true)
    listener:registerScriptHandler(function(touch, event)
        return self:onTouchBegin(touch, event)
    end, cc.Handler.EVENT_TOUCH_BEGAN)

    listener:registerScriptHandler(function(touch, event)
        self:onTouchEnded(touch, event)
    end, cc.Handler.EVENT_TOUCH_ENDED)

    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)

    coroutine.yield()
    self:initCenterUI()
    self:scheduleUpdateWithPriorityLua(function(dt)
        self:update(dt)
    end, 0)
    self.isCanClickTile = true
    self.diceUI = Dice:create()
    self:addChild(self.diceUI)
    self.diceUI:setCameraMask(2)
    tt:stop()
    self.camera:projectGL(cc.vec3(0, 0, 0))
end

function Desk3DUI:onCreate(manager, async)
    if async then
        return
    end
end

--- 初始化碰杠牌的位置
function Desk3DUI:initPongKongTiles()
    local pongKongTiles = {}
    -- 四个方位碰杠牌节点的位置
    local nodePosition = {
        cc.vec3(12 * MJ_KUAN, 0, R3 - 10),
        cc.vec3(R3 + 110, 0, -7 * MJ_KUAN),
        cc.vec3(-10 * MJ_KUAN, 0, -(R3 + 110)),
        cc.vec3(-(R3 + 110), 0, 3 * MJ_KUAN),
    }
    -- 每个方位包含{tileNode: Node, nextPongPosition: Int, bagangPosition: Map(tileIndex: Int -> pos: cc.vec3)}
    for i = 1, 4 do
        local data = {
            tileNode = cc.Node:create(),
            nextPongPosition = 0,
            bagangPosition = {}
        }
        data.tileNode:setCameraMask(CAMERA_MASK_3D)
        data.tileNode:setRotationY((i - 1) * 90)
        data.tileNode:setPosition3D(nodePosition[i])
        self:addChild(data.tileNode)
        pongKongTiles[i] = data
    end
    return pongKongTiles
end

--- 已出麻将牌堆初始化
function Desk3DUI:calcSingleSideChuPosition()
    local positions = {}
    local row = 0
    local col = 0
    local startX = -R1
    local startZ = R1
    for i = 1, 18 do
        row = math.floor((i - 1) / 6)
        col = (i - 1) % 6
        local posX = startX + col * MJ_KUAN
        local posZ = startZ + row * MJ_GAO
        positions[i] = cc.vec3(posX, 0, posZ)
    end
    return positions
end

--- 已出麻将摆放位置
function Desk3DUI:initChuTiles()
    local chuTiles = {}
    -- 已出麻将摆放位置
    local chuPosition = self:calcSingleSideChuPosition()
    local allChuPosition = {
        chuPosition,
        self:rotateAGroupByYAxis(chuPosition, 90),
        self:rotateAGroupByYAxis(chuPosition, 180),
        self:rotateAGroupByYAxis(chuPosition, -90),
    }
    -- 每个方位包含{sideCount: Int, overCount: Int, chuPosition: cc.vec3}
    for i = 1, 4 do
        local data = {
            sideCount = 1, -- 已出麻将数量
            overCount = 1, -- 超出范围数量
            chuPosition = allChuPosition[i] -- 出牌牌堆位置
        }
        chuTiles[i] = data
    end
    return chuTiles
end

function Desk3DUI:initHandTilePosition()
    local posVec = {}
    local startX = -7 * MJ_KUAN
    for i = 1, 14 do
        local posX = startX + (i - 1) * MJ_KUAN
        posVec[i] = cc.vec3(posX, 0, 0)
    end
    return posVec
end

--- 计算自己手牌Z坐标
function Desk3DUI:computeSelfHandTileZ()
    local camera = self:get3DCamera()
    local sy = 50
    local scPos = cc.vec3(640, sy, -1)
    local p1 = camera:unprojectGL(scPos)
    local cameraPos = camera:unprojectGL(cc.vec3(640, sy, 1))

    local direction = cc.vec3(p1.x - cameraPos.x, p1.y - cameraPos.y, p1.z - cameraPos.z)
    direction = cc.vec3normalize(direction)

    local t = (MJ_GAO - cameraPos.y) / direction.y
    local z = cameraPos.z + direction.z * t
    local x = cameraPos.x + direction.x * t

    local scP = camera:projectGL(cc.vec3(x, MJ_GAO, z))
    -- 如果z大于400，则返回400
    return z > 400 and 400 or z
end

--- 初始化手牌
function Desk3DUI:initHandTiles()
    local handTiles = {}
    local sidePosition = cc.vec3(0, MJ_GAO, R3)
    local z = self:computeSelfHandTileZ()
    local postitions = {
        cc.vec3(sidePosition.x, sidePosition.y, z),
        self:rotatePosByYAxis(cc.vec3(sidePosition.x, sidePosition.y, sidePosition.z), 90),
        self:rotatePosByYAxis(cc.vec3(sidePosition.x, sidePosition.y, sidePosition.z - 30), 180),
        self:rotatePosByYAxis(cc.vec3(sidePosition.x, sidePosition.y, sidePosition.z), -90),
    }
    -- 每个方位包括{tileNode, tiles, tileOffset}
    for i = 1, 4 do
        local data = {
            tileNode = cc.Node:create(),
            tiles = {},
            tileOffset = 0
        }
        data.tileNode:setCameraMask(CAMERA_MASK_3D)
        data.tileNode:setPosition3D(postitions[i])
        data.tileNode:setRotationY((i - 1) * 90)
        if i == 1 then
            data.tileNode:setRotationX(CAMERA_RX)
            data.tileNode:setScale(SELF_MJ_SCALE)
            self.selfTileSurfaceNode = data.tileNode
            self.selfTileSurfaceNormal = self:getSelfMJSurfaceNormal()
        end
        self:addChild(data.tileNode)
        handTiles[i] = data
    end
    return handTiles
end

--- 初始化骰子及方位UI
function Desk3DUI:initCenterUI()
    local empty3dNode = cc.Sprite3D:create()
    self:addChild(empty3dNode)
    empty3dNode:setRotationX(-90)
    empty3dNode:setPosition3D(cc.vec3(0, 0.2, 0))
    self.centerNode = cc.CSLoader:createNode("layout/desk2d.csb")
    empty3dNode:addChild(self.centerNode)
    self.centerNode:setPosition3D(cc.vec3(0, 0, 0))
    self.centerNode:setScale(0.88)
    self.m_empty3dNode = empty3dNode
    empty3dNode:setCameraMask(2)
    local light = self.centerNode:getChildByName("lightLayer")
    self.m_makerHint = light

    self.centerOrientationHint = {}
    self.centerOrientationHint[1] = light:getChildByName("dong")
    self.centerOrientationHint[2] = light:getChildByName("nan")
    self.centerOrientationHint[3] = light:getChildByName("xi")
    self.centerOrientationHint[4] = light:getChildByName("bei")
    self:hideHintNodes()
    self.center = self.centerNode:getChildByName("center")
end

--- 创建所有麻将
function Desk3DUI:createAllTiles()
    local allTiles = {}
    local cnt = deskManager.tileCount()
    for i = 1, cnt do
        local tile = self.tileCreator:createUI()
        tile:retain()
        allTiles[i] = tile
    end
    return allTiles
end

function Desk3DUI:enableChuPai(enable)
    self.isCanChuPai = enable
    if enable then
        self:makeLastMJOffset(1)
    end
end

function Desk3DUI:isEnableChuPai()
    return self.isCanChuPai
end

function Desk3DUI:update(dt)
    self.diceUI:update(dt)
end

function Desk3DUI:getHintNodeByDir(dir)
    return self.centerOrientationHint[dir]
end

function Desk3DUI:hideHintNodes()
    for i = 1, 4 do
        local node = self.centerOrientationHint[i]
        node:hide()
        node:stopAllActions()
        node:setOpacity(255)
    end
end

function Desk3DUI:setCurOperateDirByTurn(turn)
    local side = self:playerDeskSide(turn)
    self:setCurOperateDir(side)
end

function Desk3DUI:setCurOperateDir(dir)
    local nodeIdx = judgeToMinMax(1, 4, dir - self.m_makerIdx + 1)
    self:hideHintNodes()
    local node = self:getHintNodeByDir(nodeIdx)
    node:show()
    local actions = {}
    actions[1] = cc.FadeTo:create(0.5, 50)
    actions[2] = cc.FadeTo:create(0.5, 255)
    local action = cc.RepeatForever:create(transition.sequence(actions))
    node:runAction(action)
    self.m_curOperateDir = dir
end

function Desk3DUI:resetDeskStatus()
    for i = 1, #self.allTiles do
        local mj = self.allTiles[i]
        mj:enableChuPai(true)
        mj:enableTing(false)
        mj:removeSelf()
    end
    for i = 1, 4 do
        self.chuTiles[i].sideCount = 1
        self.chuTiles[i].overCount = 1
        self.handTiles[i].tileOffset = 0
        self.handTiles[i].tiles = {}
        self.pongKongTiles[i].nextPongPosition = 0
        self.pongKongTiles[i].bagangPosition = {}
    end
    self.currentDeskTileHint:hide()
    self.isCanChuPai = false
    -- 玩家最近摸到的牌
    self.m_lastTiles = {}
    for i = 1, 4 do self.m_lastTiles[i] = -1 end
    self.chosenTile = nil
    self.deskLastTile = nil
    self.curRestTileCount = deskManager.tileCount()
    for _, v in pairs(self.m_redundantMj) do
        v:removeSelf()
    end
    self.m_redundantMjUsed = 0
    self.tings = {}
    self.que = 0
end

function Desk3DUI:getRedundantMj(data)
    if self.m_redundantMjUsed >= #self.m_redundantMj then
        local mj = self.tileCreator:createUI()
        mj:retain()
        table.push(self.m_redundantMj, mj)
    end
    self.m_redundantMjUsed = self.m_redundantMjUsed + 1
    local mj = self.m_redundantMj[self.m_redundantMjUsed]
    mj:setData(data)
    return mj
end

function Desk3DUI:exit()
    for i = 1, #self.allTiles do
        local mj = self.allTiles[i]
        mj:release()
    end
    self.allTiles = {}
    for i = 1, #self.m_redundantMj do
        local mj = self.m_redundantMj[i]
        mj:release()
    end
    self.m_redundantMj = {}
end

--- 对某个方位的牌进行排序
-- @param side
--
function Desk3DUI:sortTilesBySide(side)
    local handInfo = self.handTiles[side]
    local tiles = handInfo.tiles
    local function comp(tile1, tile2)
        local data1 = tile1:getData()
        local data2 = tile2:getData()
        if not data1 or not data2 then
            return true
        end
        local huase1 = data1:getHuaSe()
        local value1 = data1:getValue()
        local huase2 = data2:getHuaSe()
        local value2 = data2:getValue()

        local weight1 = huase1 * 100 + value1
        local weight2 = huase2 * 100 + value2
        if huase1 == self.que then
            weight1 = weight1 + 1000
        end

        if huase2 == self.que then
            weight2 = weight2 + 1000
        end

        return weight1 <= weight2
    end

    table.bubbleSort(tiles, comp)
end

function Desk3DUI:setTileParameter(mj, pos, uitype, light, direction)
    mj:setPosition3D(pos)
    mj:setUIType(uitype)
    mj:setLightMask(light)
    mj:setCameraMask(CAMERA_MASK_3D)
    mj:setRotation3D(cc.vec3(0, 0, 0))
    mj:setDirection(direction)
    mj:setAnchorZ(0)
end

function Desk3DUI:playAnimationAndThenDisappear(ar, node)
    ar:getAnimation():playWithIndex(0, -1, 0)
    local function animationEvent(ar, movementType, id)
        if movementType == ccs.MovementEventType.complete then
            ar:runAction(cc.Sequence:create({ cc.DelayTime:create(0.001), cc.RemoveSelf:create() }))
        end
    end

    ar:getAnimation():setMovementEventCallFunc(animationEvent)
end

function Desk3DUI:runPGSmokeAnimation(pos)
    pos.y = pos.y + MJ_HOU * 0.5

    ccs.ArmatureDataManager:getInstance():addArmatureFileInfo("animation/pgSmoke/pgSmoke.csb")
    local ar = ccs.Armature:create("pgSmoke")
    self:addChild(ar)
    ar:setPosition3D(pos)
    ar:setRotationX(-90)
    ar:setCameraMask(2)
    ar:setScale(0.5)
    self:playAnimationAndThenDisappear(ar, node3d)
end

function Desk3DUI:runPGMoveAction(mj, tPos, hasMove, hasSmoke)
    local hasMove = (hasMove == nil) and true or hasMove
    if not hasMove then return end
    local initPos = cc.vec3(tPos.x - PGMOVEX, tPos.y, tPos.z - PGMOVEZ)
    mj:setPosition3D(initPos)
    mj:runAction(cc.Sequence:create({ cc.DelayTime:create(PGMOVE_TIME * 0.3), cc.MoveTo:create(PGMOVE_TIME, tPos) }))
    if hasSmoke then
        local parent = mj:getParent()
        local mat4 = parent:getNodeToWorldTransform()
        local pos = self:rotatePosByMat(initPos, mat4)
        self:runPGSmokeAnimation(pos)
    end
end

local idxKey = function(idx) return string.format("key%d", idx) end

--- 把手中的碰牌移到碰杠牌堆中
-- @param selfDir 碰牌的方位
-- @param chuDir 出牌的方位
-- @param tiles 麻将
-- @param hasMove
-- @param hasSmoke
--
function Desk3DUI:moveTileToPongKong(selfDir, chuDir, tiles, hasMove, hasSmoke)
    local pongKong = self.pongKongTiles[selfDir]
    local node = pongKong.tileNode
    local nextPos = pongKong.nextPongPosition
    assert(#tiles == 3, "peng pai, mj count must be three.")
    local diff = judgeToMinMax(0, 3, chuDir - selfDir)
    assert(diff ~= 0, "peng pai, could't peng self.")
    for i = 1, 3 do
        local tile = tiles[i]
        tile:enableChuPai(true)
        tile:enableTing(false)
        tile:removeSelf()
        local uitype = MJ3DUI.UIType.ZHENG
        local offx = -MJ_KUAN * 0.5
        local posz = -MJ_GAO * 0.5
        local direction = MJ3DUI.Direction.PLAYER
        local posx = nextPos + offx
        if i == 2 then
            local bagangPosition = cc.vec3(posx, MJ_HOU, posz)
            local index = tile:getData():getIdx()
            pongKong.bagangPosition[index] = bagangPosition
        end
        nextPos = posx + offx
        local pos = cc.vec3(posx, 0, posz)
        self:setTileParameter(tile, pos, uitype, math.pow(2, selfDir), direction)
        tile:setAnchorZ(0.5)
        node:addChild(tile)
        local smoke = false
        if i == 3 then
            smoke = true
        end
        self:runPGMoveAction(tile, pos, hasMove, smoke and hasSmoke)
    end
    nextPos = nextPos + PGGAP
    pongKong.nextPongPosition = nextPos
end

function Desk3DUI:addGangToPengPaiPos(selfDir, chuDir, mjs, hasMove, hasSmoke)
    local diff = judgeToMinMax(0, 3, chuDir - selfDir)
    assert(((diff == 0) and type(mjs) == "userdata") or (#mjs == 4), "gang pai")
    local node = self.pongKongTiles[selfDir].tileNode
    printInfo("self.m_pengPaiSideBaGangPos: %s", vardump(self.m_pengPaiSideBaGangPos))
    if diff == 0 and type(mjs) == "userdata" then --ba gang
        local mj = mjs
        local pos = self.pongKongTiles[selfDir].bagangPosition[mj:getData():getIdx()]
        mj:removeSelf()
        mj:enableChuPai(true)
        mj:enableTing(false)
        self:setTileParameter(mj, pos, MJ3DUI.UIType.ZHENG, math.pow(2, selfDir), MJ3DUI.Direction.PLAYER)
        mj:setAnchorZ(0.5)
        node:addChild(mj)
        local smoke = true
        self:runPGMoveAction(mj, pos, hasMove, smoke and hasSmoke)
        return
    end
    local nextPos = self.pongKongTiles[selfDir].nextPongPosition
    local posVec = {}
    local uitypeVec = {}
    local directionVec = {}
    if diff == 2 or diff == 0 then
        for i = 1, 3 do
            local posx = nextPos - MJ_KUAN * 0.5
            local posz = -MJ_GAO * 0.5
            local posy = 0
            nextPos = posx - MJ_KUAN * 0.5
            table.push(posVec, cc.vec3(posx, posy, posz))
            if i == 3 then
                table.push(posVec, cc.vec3(posx - MJ_KUAN, posy, posz))
                nextPos = nextPos - MJ_KUAN
            end
            table.push(directionVec, MJ3DUI.Direction.PLAYER)
            if diff == 2 then table.push(uitypeVec, MJ3DUI.UIType.ZHENG) end --ming gang 
            if diff == 0 then table.push(uitypeVec, MJ3DUI.UIType.BEI) end --an gang
        end
        table.push(uitypeVec, MJ3DUI.UIType.ZHENG)
        table.push(directionVec, MJ3DUI.Direction.PLAYER)
    else
        if diff == 3 then diff = 4 end
        for i = 1, 4 do
            local uitype = MJ3DUI.UIType.ZHENG
            local offx = -MJ_KUAN * 0.5
            local posz = -MJ_GAO * 0.5
            local direction = MJ3DUI.Direction.PLAYER
            local posx = nextPos + offx
            nextPos = posx + offx
            local pos = cc.vec3(posx, 0, posz)
            table.push(posVec, pos)
            table.push(directionVec, direction)
            table.push(uitypeVec, uitype)
        end
    end
    for i = 1, #mjs do
        local mj = mjs[i]
        mj:removeSelf()
        mj:enableChuPai(true)
        mj:enableTing(false)
        self:setTileParameter(mj, posVec[i], uitypeVec[i], math.pow(2, selfDir), directionVec[i])
        mj:setAnchorZ(0.5)
        node:addChild(mj)
        local smoke = false
        if i == #mjs then
            smoke = true
        end
        self:runPGMoveAction(mj, posVec[i], hasMove, smoke and hasSmoke)
    end
    nextPos = nextPos + PGGAP
    self.pongKongTiles[selfDir].nextPongPosition = nextPos
end

--- 将碰杠的牌从手牌中移除
-- @param side
-- @param datas
-- @param startId
--
function Desk3DUI:removeFromHandTiles(side, datas)
    local ret = {}
    local handInfo = self.handTiles[side]
    local tiles = handInfo.tiles
    --[[if side == 1 then]]
    for i = 1, #datas do
        local tile = self:findTileByNetIndex(tiles, datas[i]:getNetValue())
        if tile then
            table.removebyvalue(tiles, tile)
            table.push(ret, tile)
        end
    end
    --[[else
        for i = startId, #datas do
            local mj = tiles[i - startId + 1]
            local oldData = mj:getData()
            mj:setData(datas[i])
            table.removebyvalue(tiles, mj)
            table.push(ret, mj)

            if oldData then
                local realMj = self:findTileByNetIndex(tiles, datas[i]:getNetValue())
                if realMj and realMj ~= mj then
                    realMj:setData(oldData)
                end
            end
        end
    end]]
    return ret
end

function Desk3DUI:addHuMJToShouPai(dir, tile)
    local uitype = MJ3DUI.UIType.ZHENG
    local handInfo = self.handTiles[dir]
    local node = handInfo.tileNode
    tile:removeSelf()
    node:addChild(tile)
    local idx = #handInfo.tiles + 1
    table.insert(handInfo.tiles, tile)
    local pos = self:getHandTilePosition(idx, dir)
    local npos = cc.vec3(pos.x, pos.y, pos.z)

    npos.x = npos.x + MOPAI_OFFSETX
    if dir == 1 then
        uitype = MJ3DUI.UIType.LI
    else
        npos.y = npos.y - MJ_GAO * 0.5
    end
    self:setTileParameter(tile, npos, uitype, math.pow(2, dir), MJ3DUI.Direction.PLAYER)
    tile:setAnchorZ(0.5)
end

function Desk3DUI:fadeOut(mj, time)
    time = time or 0.4
    mj:runAction(cc.Sequence:create(cc.FadeOut:create(time), cc.CallFunc:create(function()
        mj:removeFromParent()
        mj:setOpacity(255)
    end)))
end

function Desk3DUI:qiangGang(turn, beturn, data)
    audioEngine.playEffect(configManager.soundConfig.effectFilePath(stringDefine.qiangGang, deskManager.getPlayerData(turn):getUserSex()))
    local dir = self:playerDeskSide(turn)
    local mj = nil
    local pos = nil
    if self.m_baGangMj then
        mj = self.m_baGangMj
        self.m_baGangMj = nil
        self:fadeOut(mj)
        local pos3d = mj:getPosition3D()
        local camera = self:get3DCamera()
        local realPos3d = cc.vec3(pos3d.x, pos3d.y + MJ_HOU, pos3d.z)
        pos = camera:projectGL(realPos3d)

        mj = self:getRedundantMj(data)
    else
        mj = self:getRedundantMj(data)
    end
    self:addHuMJToShouPai(dir, mj)
    --self:resetHandTilePosition(dir)
    return pos
end

function Desk3DUI:huOther(turn, beturn, data)
    --local i = 1
    --for _, v in pairs(turns) do
    audioEngine.playEffect(configManager.soundConfig.effectFilePath(stringDefine.hu, deskManager.getPlayerData(turn):getUserSex()))
    local dir = self:playerDeskSide(turn)
    local bedir = self:playerDeskSide(beturn)
    local mj = nil
    local pos = nil
    if self.deskLastTile then
        mj = self.deskLastTile
        self.deskLastTile = nil
        self:_decreaseChuPaiCnt(bedir)
        self.currentDeskTileHint:hide()
        self:fadeOut(mj)
        local pos3d = mj:getPosition3D()
        local camera = self:get3DCamera()
        local realPos3d
        if bedir == 1 then
            realPos3d = cc.vec3(pos3d.x, pos3d.y + MJ_HOU, pos3d.z + MJ_GAO * 0.5)
        elseif bedir == 2 then
            realPos3d = cc.vec3(pos3d.x + MJ_GAO * 0.5, pos3d.y + MJ_HOU, pos3d.z)
        elseif bedir == 3 then
            realPos3d = cc.vec3(pos3d.x, pos3d.y + MJ_HOU, pos3d.z - MJ_GAO * 0.5)
        elseif bedir == 4 then
            realPos3d = cc.vec3(pos3d.x - MJ_GAO * 0.5, pos3d.y + MJ_HOU, pos3d.z + MJ_GAO * 0.5)
        end
        pos = camera:projectGL(realPos3d)

        mj = self:getRedundantMj(data)
    else
        mj = self:getRedundantMj(data)
    end
    self:addHuMJToShouPai(dir, mj)
    --self:resetHandTilePosition(dir)
    return pos
    --i = i + 1
    --end
end

function Desk3DUI:ziMo(turn, data)
    local dir = self:playerDeskSide(turn)
    audioEngine.playEffect(configManager.soundConfig.effectFilePath(stringDefine.zimo, deskManager.getPlayerData(turn):getUserSex()))
    if dir ~= 1 then
        local handInfo = self.handTiles[dir]
        local tile = handInfo.tiles[#handInfo.tiles]
        tile:finishAllActions()
        self:resetHandTilePosition(dir)
        if data then tile:setData(data) end
        tile:setUIType(MJ3DUI.UIType.ZHENG)
        local pos = tile:getPosition3D()
        pos.y = MJ_GAO * 0.5
        pos.x = pos.x + MOPAI_OFFSETX
        tile:setPosition3D(pos)
    end
end

function Desk3DUI:showAllHandTiles(shouPais)
    local function sortDatas(datas)
        local function comp(data1, data2)
            if not data1 or not data2 then
                return true
            end
            local huase1 = data1:getHuaSe()
            local value1 = data1:getValue()
            local huase2 = data2:getHuaSe()
            local value2 = data2:getValue()

            if huase1 == huase2 then
                return value1 <= value2
            end
            return huase1 <= huase2
        end

        table.bubbleSort(datas, comp)
    end

    for _, v in pairs(shouPais) do
        local side = self:playerDeskSide(v.turn)
        local handInfo = self.handTiles[side]
        if side ~= 1 then
            local shoupai = v.shouPai
            sortDatas(shoupai)
            local shouPaiMj = handInfo.tiles
            for i = 1, #shoupai do
                local mj = shouPaiMj[i]
                if mj then
                    mj:setData(shoupai[i])
                else
                    printError("此处不应该报错, 可能是服务器传过来的手牌数据不正确, i=%d", i)
                end
            end
            if v.huPai then
                local idx = #handInfo.tiles
                local mj = shouPaiMj[idx]
                mj:setData(v.huPai)
                local pos = self:getHandTilePosition(idx, side)
                pos.x = pos.x + MOPAI_OFFSETX
                self:setTileParameter(mj, pos, MJ3DUI.UIType.LI, math.pow(2, side), MJ3DUI.Direction.PLAYER)
                mj:setAnchorZ(0.5)
            end
            self:daoPai(side, 0.2)
        end
    end
end

function Desk3DUI:_decreaseChuPaiCnt(dir)
    local chuInfo = self.chuTiles[dir]
    local overCount = chuInfo.overCount
    local sideCount = chuInfo.sideCount
    if overCount > 1 then
        chuInfo.overCount = overCount - 1
    else
        chuInfo.sideCount = sideCount - 1
    end
end

function Desk3DUI:pengPai(turn, beturn, datas)
    audioEngine.playEffect(configManager.soundConfig.effectFilePath(stringDefine.peng, deskManager.getPlayerData(turn):getUserSex()))
    local dir = self:playerDeskSide(turn)
    local bedir = self:playerDeskSide(beturn)
    local idx = datas[1]:getNetValue()
    assert(#datas == 3, "Desk3DUI:pengPai: datas must three. datas size:%d", #datas)
    assert(idx == self.deskLastTile:getData():getNetValue(), "Desk3DUI:pengPai: current desk mj's idx must equal.")
    assert(bedir == self.deskCurrentSide, "Desk3DUI:pengPai: be dir must equal to cur desk mj dir")

    local pong = {}
    self.currentDeskTileHint:hide()
    self:_decreaseChuPaiCnt(bedir)
    local handInfo = self.handTiles[dir]
    local tiles = handInfo.tiles
    table.push(pong, self.deskLastTile)

    for i = 2, 3 do
        local t = self:findTileByNetIndex(tiles, datas[i]:getNetValue())
        table.removebyvalue(tiles, t)
        table.push(pong, t)
    end

    assert(#pong == 3, "Desk3DUI:pengPai: player count not enough")

    self:moveTileToPongKong(dir, bedir, pong, true, true)
    self:computeSideShouPaiOffset(dir, 0)
    self:resetHandTilePosition(dir, true)
    self:makeLastMJOffset(dir)
end

function Desk3DUI:makeLastMJOffset(dir)
    local handInfo = self.handTiles[dir]
    local tiles = handInfo.tiles
    local tileCount = #tiles
    local pos = self:getHandTilePosition(tileCount, dir)
    local tile = tiles[tileCount]
    local oriPos = tile:getPosition3D()
    local t = cc.vec3(pos.x + MOPAI_OFFSETX, oriPos.y, pos.z)
    tile:setPosition3D(t)
end

function Desk3DUI:anGang(turn, datas)
    audioEngine.playEffect(configManager.soundConfig.effectFilePath(stringDefine.gang, deskManager.getPlayerData(turn):getUserSex()))
    local side = self:playerDeskSide(turn)
    local tmp = self:removeFromHandTiles(side, datas)
    for _, v in pairs(tmp) do
        v:finishAllActions()
    end
    self:addGangToPengPaiPos(side, side, tmp, true, true)
    self:computeSideShouPaiOffset(side, 1)
    self:resetHandTilePosition(side, true)
end

function Desk3DUI:mingGang(turn, beturn, datas)
    audioEngine.playEffect(configManager.soundConfig.effectFilePath(stringDefine.gang, deskManager.getPlayerData(turn):getUserSex()))
    local side = self:playerDeskSide(turn)
    local bedir = self:playerDeskSide(beturn)
    local mjs = self:removeFromHandTiles(side, datas)
    assert(self.deskLastTile:getData():getNetValue() == datas[1]:getNetValue(), "")
    table.push(mjs, self.deskLastTile)
    self.currentDeskTileHint:hide()
    self:_decreaseChuPaiCnt(bedir)
    self:addGangToPengPaiPos(side, bedir, mjs, true, true)
    self:computeSideShouPaiOffset(side, 1)
    self:resetHandTilePosition(side, true)
end

function Desk3DUI:baGang(turn, data)
    audioEngine.playEffect(configManager.soundConfig.effectFilePath(stringDefine.gang, deskManager.getPlayerData(turn):getUserSex()))
    local side = self:playerDeskSide(turn)
    local datas = { data }
    local tiles = self:removeFromHandTiles(side, datas)
    local tile = tiles[1]
    self.m_baGangMj = tile
    self:resetHandTilePosition(side, true)
    self:addGangToPengPaiPos(side, side, tile, true, true)
end

function Desk3DUI:clearDeskMj()
    self:resetDeskStatus()
end

function Desk3DUI:qiPai(startDir, immediate)
    if self.m_makerIdx then
        startDir = self.m_makerIdx
    end
    self:resetDeskStatus()
end

function Desk3DUI:addTileToChuPosition(mj, dir, idx, hasShowHint)
    if hasShowHint == nil then hasShowHint = true end
    local chuInfo = self.chuTiles[dir]
    local chuPosition = chuInfo.chuPosition
    local pos
    if idx <= #chuPosition then
        pos = chuPosition[idx]
        pos = cc.vec3(pos.x, pos.y, pos.z)
    else
        local tmp = chuPosition[#chuPosition]
        pos = cc.vec3(tmp.x, tmp.y, tmp.z)
        local outCnt = chuInfo.overCount
        if dir == 1 then pos.x = pos.x + MJ_KUAN * outCnt end
        if dir == 2 then pos.z = pos.z - MJ_KUAN * outCnt end
        if dir == 3 then pos.x = pos.x - MJ_KUAN * outCnt end
        if dir == 4 then pos.z = pos.z + MJ_KUAN * outCnt end
        chuInfo.overCount = outCnt + 1
    end
    mj:removeSelf()
    self:addChild(mj)

    -- 先移动到过渡位置, 再移动到牌堆
    local deleyPos = chuInfo.transitionPosition
    self:setTileParameter(mj, pos, MJ3DUI.UIType.ZHENG, math.pow(2, dir), dir)
    mj:runAction(cc.MoveTo:create(1, pos))
    if hasShowHint then self:addChuPaiHint(dir, pos) end

    mj:setAnchorZ(0)
    self.deskLastTile = mj
    self.deskCurrentSide = dir
end

function Desk3DUI:addChuPaiHint(dir, pos)
    self.currentDeskTileHint:show()
    local p = cc.vec3(pos.x, pos.y + 1.3 * MJ_HOU, pos.z)
    local off = MJ_GAO * 0.5
    if dir == 1 then pos.z = pos.z + off end
    if dir == 2 then pos.x = pos.x + off end
    if dir == 3 then pos.z = pos.z - off end
    if dir == 4 then pos.x = pos.x - off end
    self.currentDeskTileHint:setPosition3D(cc.vec3(pos.x, pos.y + 1.3 * MJ_HOU, pos.z))
end

function Desk3DUI:addTileToHand(mj, dir, idx, uitype)
    uitype = uitype or MJ3DUI.UIType.LI
    local node = self.handTiles[dir].tileNode
    mj:removeSelf()
    node:addChild(mj)
    local pos = self:getHandTilePosition(idx, dir)
    self:setTileParameter(mj, pos, uitype, math.pow(2, dir), MJ3DUI.Direction.PLAYER)
    mj:setAnchorZ(0.5)
end

function Desk3DUI:addTileToHandWithAction(tile, side, index, hasOffset)
    local uitype = MJ3DUI.UIType.LI
    -- appConfig.isShowAllShouPai
    if side ~= 1 and (self.isLookback or configManager.debug.enable) then
        uitype = MJ3DUI.UIType.ZHENG
    end
    self:addTileToHand(tile, side, index, uitype)
    --show action
    tile:finishAllActions()
    local pos = self:getHandTilePosition(index, side)
    local offset = 0
    if hasOffset then offset = MOPAI_OFFSETX end
    local pos1 = cc.vec3(pos.x + offset, pos.y, pos.z)
    local pos2 = cc.vec3(pos1.x, pos1.y + MJ_GAO, pos1.z)
    local rz = -30
    local ry = -30
    local rx = 30
    tile:setRotationZ(rz)
    tile:setRotationX(rx)
    tile:setRotationY(ry)
    tile:setPosition3D(pos2)

    local action1 = cc.RotateBy:create(0.2, cc.vec3(-rx, -ry, -rz))
    local action2 = cc.MoveTo:create(0.3, pos1)
    tile:runAction(action1)
    tile:runAction(action2)
    return 0.3
end

--duanpai
function Desk3DUI:setDice(dice1, dice2, hasAction)
    if hasAction == nil then
        hasAction = true
    end
    self.m_nextDuanPaiPos = math.min(dice1, dice2) * 2 + 1
    local dice = dice1 + dice2
    dice = dice + self.m_makerIdx - 1
    while dice > 4 do
        dice = dice - 4
    end
    self.m_nextDuanPaiDir = dice

    self.diceUI:show()
    self.diceUI:start(dice1, dice2, hasAction)
    if hasAction then
        audioEngine.playEffect(configManager.soundConfig.effectFilePath(stringDefine.dice))
    end
end

function Desk3DUI:setPlayerTurnIdx(idx)
    assert(type(idx) == "number", "Desk3DUI:setPlayerTurnIdx must be number.")
    assert(idx ~= nil, "Desk3DUI:setPlayerTurnIdx must be not nil.")
    self.m_playerTurnIdx = idx
end

function Desk3DUI:playerDeskSide(turn)
    assert(type(turn) == "number", "Desk3DUI:playerDeskSide must be number.")
    if turn == self.m_playerTurnIdx then return 1 end

    if self.mode == MODE_FOURS then
        -- 四人模式
        if turn < self.m_playerTurnIdx then turn = turn + 4 end
        local diff = turn - self.m_playerTurnIdx
        return 1 + diff
    else
        -- 三人模式
        if self.m_playerTurnIdx == 3 then
            if turn == 2 then return 4 else return 2 end
        else
            if turn == self.m_playerTurnIdx + 1 then return 2 else return 4 end
        end
    end
end

function Desk3DUI:setMakerByTurnIdx(turn)
    self.m_makerIdx = self:playerDeskSide(turn)
    self.m_makerHint:setRotation(center_mark_direction[self.m_makerIdx])
end

function Desk3DUI:getOneTile()
    assert(self.curRestTileCount > 0, "rest tile count must more than 1.")
    local tile = self.allTiles[self.curRestTileCount]
    self.curRestTileCount = self.curRestTileCount - 1
    self.m_manager.m_ui:updateRestTileCount(self.curRestTileCount)
    return tile
end

function Desk3DUI:duanPai(turn, datas)
    local side = self:playerDeskSide(turn)
    local handInfo = self.handTiles[side]
    local tiles = handInfo.tiles
    local tileCount = #tiles
    if tileCount >= 13 then return 0 end
    if tileCount >= 12 then --1 zhang
        local mj = self:getOneTile()
        local idx = tileCount + 1
        self:addTileToHand(mj, side, idx, MJ3DUI.UIType.LI)
        table.insert(tiles, mj)
        if datas and #datas >= 1 then
            mj:setData(datas[1])
        end
        return 1
    end

    local startIdx = tileCount
    for i = 1, 4 do
        local mj = self:getOneTile()
        self:addTileToHand(mj, side, startIdx + i, MJ3DUI.UIType.LI)
        local rotateAngle = -90
        if side == 1 then
            rotateAngle = rotateAngle + CAMERA_RX
        end
        mj:setRotationX(-rotateAngle)
        local action = cc.RotateBy:create(0.5, cc.vec3(rotateAngle, 0, 0))
        mj:runAction(action)
        tiles[startIdx + i] = mj
        if datas and #datas >= i then
            mj:setData(datas[i])
        end
    end
    return 4
end

function Desk3DUI:throughAllShouPai(side, callback)
    local handInfo = self.handTiles[side]
    local tiles = handInfo.tiles
    local tileCount = #tiles
    for j = 1, tileCount do
        local tile = tiles[j]
        callback(tile)
    end
end

--- 将牌扣下, 牌面朝下
-- @param side 方位, 自己为1, 逆时针1/2/3/4
-- @param time 动画时间
--
function Desk3DUI:kouPai(dir, time)
    local rx = 90
    if dir == 1 then
        rx = rx - CAMERA_RX
    end
    local actions = {}
    --actions[1] = cc.RotateBy:create(time, cc.vec3(rx, 0, 0))
    --actions[2] = cc.MoveBy:create(time, cc.vec3(0, -MJ_GAO * 0.5, 0))
    local diffR = cc.vec3(rx, 0, 0)
    local diffP = cc.vec3(0, -MJ_GAO * 0.5, 0)
    local function func(mj)
        mj:finishAllActions()
        local cr = mj:getRotation3D()
        local cp = mj:getPosition3D()
        mj:runAction(cc.RotateTo:create(time, cc.vec3(diffR.x + cr.x, diffR.y + cr.y, diffR.z + cr.z)))
        mj:runAction(cc.MoveTo:create(time, cc.vec3(diffP.x + cp.x, diffP.y + cp.y, diffP.z + cp.z)))
    end

    self:throughAllShouPai(dir, func)
end

--- 将牌倒下, 牌面朝上
-- @param side 方位, 自己为1, 逆时针1/2/3/4
-- @param time 动画时间
--
function Desk3DUI:daoPai(dir, time)
    local rx = -90
    if dir == 1 then
        rx = rx - CAMERA_RX
    end
    local mv = MJ_GAO * 0.5 - MJ_HOU
    --local action = cc.RotateBy:create(time, cc.vec3(rx, 0, 0))
    --local action2 = cc.MoveBy:create(time, cc.vec3(0, -mv, 0))
    local diffR = cc.vec3(rx, 0, 0)
    local diffP = cc.vec3(0, -mv, 0)
    local function func(mj)
        mj:setUIType(MJ3DUI.UIType.ZHENG)
    end

    self:throughAllShouPai(dir, func)
end

--- 理牌结束, 再将牌面朝自己
-- @param side 方位, 自己为1, 逆时针1/2/3/4
-- @param time 动画时间
--
function Desk3DUI:kanPai(dir, time)
    local rx = -90
    if dir == 1 then
        rx = rx + CAMERA_RX
    end
    --local action1 = cc.RotateBy:create(time, cc.vec3(rx, 0, 0))
    local diffR = cc.vec3(rx, 0, 0)
    local function func(mj)
        mj:finishAllActions()
        local curY = mj:getPositionY()
        local targetY = 0
        local diff = targetY - curY
        local diffP = cc.vec3(0, diff, 0)

        local cr = mj:getRotation3D()
        local cp = mj:getPosition3D()
        --local action2 = cc.MoveBy:create(time, cc.vec3(0, diff, 0))
        mj:runAction(cc.RotateTo:create(time, cc.vec3(diffR.x + cr.x, diffR.y + cr.y, diffR.z + cr.z)))
        mj:runAction(cc.MoveTo:create(time, cc.vec3(diffP.x + cp.x, diffP.y + cp.y, diffP.z + cp.z)))
    end

    self:throughAllShouPai(dir, func)
    if self.isLookback then
        self:resetHandTilePosition(dir)
    end
end

--- 理牌, 将乱序的牌按顺序排列
-- @param side
--
function Desk3DUI:liPai(side)
    local kouPaiTime = 0.1
    local function koupai()
        self:kouPai(side, kouPaiTime)
    end

    local function kanpai()
        local handInfo = self.handTiles[side]
        local tiles = handInfo.tiles
        self:sortTilesBySide(side)
        for i = 1, #tiles do
            local pos = self:getHandTilePosition(i, side)
            tiles[i]:setPositionX(pos.x)
        end
        self:kanPai(side, 0.1)
    end

    local actions = {
        cc.CallFunc:create(koupai),
        cc.DelayTime:create(kouPaiTime + 0.1),
        cc.CallFunc:create(kanpai),
    }
    self:runAction(transition.sequence(actions))
    return 0.5
end

function Desk3DUI:moPai(turn, data, hasOffset)
    local side = self:playerDeskSide(turn)
    local tile = self:getOneTile()
    if data then
        tile:setData(data)
    end
    local handInfo = self.handTiles[side]
    local tiles = handInfo.tiles
    table.insert(tiles, tile)
    self:resetHandTilePosition(side, true)
    local time = self:addTileToHandWithAction(tile, side, #tiles, hasOffset)
    return time
end

function Desk3DUI:getIdxByData(data)
    local handInfo = self:getSelfHandInfo()
    local tiles = handInfo.tiles
    local tileCount = #tiles
    for i = 1, tileCount do
        local tile = tiles[i]
        if tile:getData():getNetValue() == data:getNetValue() then
            return i
        end
    end
    return -1
end

function Desk3DUI:findIndexByData(tiles, netIndex)
    for i = 1, #tiles do
        local tile = tiles[i]
        local data = tile:getData()
        if data and data:getNetValue() == netIndex then
            return i
        end
    end
end

function Desk3DUI:chuPai(turn, data)
    audioEngine.playEffect(configManager.soundConfig.effectFilePath(data:getIdx(), deskManager.getPlayerData(turn):getUserSex()))
    local side = self:playerDeskSide(turn)
    local handInfo = self.handTiles[side]
    local tiles = handInfo.tiles
    local handTileCount = #tiles
    local index = self:findIndexByData(tiles, data:getNetValue())
    if not index then
        local handTiles = {}
        for _, t in ipairs(tiles) do
            table.insert(handTiles, t:getNetValue())
        end
        assert(false, string.format("未在手牌中找到要出的牌, Side: %d, 出牌ID: %d, 手牌: %s", side, data:getNetValue(), json.encode(handTiles)))
    end
    assert(index > 0 and index <= handTileCount, "出牌超出手牌范围")
    local tile = tiles[index]
    local chuInfo = self.chuTiles[side]
    local chuSideCount = chuInfo.sideCount
    -- 本家有可能是听牌
    if side == SELF_SIDE then
        tile:enableChuPai(true)
    end
    self:addTileToChuPosition(tile, side, chuSideCount)
    chuInfo.sideCount = chuSideCount + 1
    table.remove(tiles, index)
    self:sortTilesBySide(side)
    self:resetHandTilePosition(side, true)
end

--matrix rotation help functions
function Desk3DUI:rotatePosByYAxis(pos, angle)
    local mat = self:getRotationByYAxisMat(math.rad(angle))
    local newPos = self:rotatePosByMat(pos, mat)
    return newPos
end

function Desk3DUI:rotateAGroupByYAxis(poses, angle)
    local posVec = {}
    local mat = self:getRotationByYAxisMat(math.rad(angle))
    for i = 1, #poses do
        local pos = poses[i]
        local newPos = self:rotatePosByMat(pos, mat)
        posVec[i] = newPos
    end
    return posVec
end

function Desk3DUI:getRotationByYAxisMat(angle)
    local mat = {}
    for i = 1, 16 do mat[i] = 0 end
    mat = mat4_createRotation(cc.vec3(0, 1, 0), angle, mat)
    return mat
end

function Desk3DUI:rotatePosByMat(pos, mat)
    local pos4 = cc.vec4(pos.x, pos.y, pos.z, 1)
    pos4 = mat4_transformVector(mat, pos4, pos4)
    local ret = cc.vec3(pos4.x, pos4.y, pos4.z)
    return ret
end

function Desk3DUI:getSelfMJSurfaceNormal()
    local dir = cc.vec4(0, 0, 1, 0)

    local mat = {}
    for i = 1, 16 do mat[i] = 0 end
    mat = mat4_createRotation(cc.vec3(1, 0, 0), math.rad(self.selfTileSurfaceNode:getRotationX()), mat)

    dir = mat4_transformVector(mat, dir, dir)

    return cc.vec3(dir.x, dir.y, dir.z)
end

function Desk3DUI:get3DCamera()
    return self.camera
    --local camera = cc.Camera:getCameraByFlag(2)
    --return camera
end

function Desk3DUI:convertGLScreenPosToCameraPos(camera, pos, z, isGLScreen)
    return camera:convertGLScreenPosToZZero(pos, z, isGLScreen)
end

function Desk3DUI:setTileClickable(enable)
    self.isCanClickTile = enable
    if not enable then
        self:resetHandTilePosition(1)
    end
end

function Desk3DUI:clearChoosedMj()
    if self.chosenTile then
        self.chosenTile = nil
        self:resetHandTilePosition(1)
    end
end

function Desk3DUI:onTouchBegin(touch, event)
    if not self.isCanClickTile then
        return false
    end
    local tile, pos = self:findTouchTile(touch)
    if tile then
        return true
    end
    if self.chosenTile then
        self:resetHandTilePosition(1)
        self.chosenTile = nil
        self.m_manager:onTileFirstChosen(nil)
    end
    return false
end

function Desk3DUI:getHuTilesByIndex(index)
    local hu = {}
    for i = 1, #self.tings do
        local ting = self.tings[i]
        if ting.index == index then
            hu = ting.hu
        end
    end
    return hu
end

function Desk3DUI:onTouchEnded(touch, event)
    if self.isLookback then
        return
    end
    local tile, pos = self:findTouchTile(touch)
    if not tile then return end

    self:resetHandTilePosition(SELF_SIDE)
    self:chooseHandTile(tile)

    -- 显示听牌提示
    if self.isCanChuPai then
        local deskUi = self.m_manager.m_ui
        local hu = self:getHuTilesByIndex(tile:getData():getIdx())
        deskUi:showHuTilesHint(hu)
    end

    -- 正常出牌流程
    if self.chosenTile == tile and tile.isEnableChuPai and self.isCanChuPai then
        local handInfo = self:getSelfHandInfo()
        local tiles = handInfo.tiles
        local tileCount = handInfo.tileCount
        local idx = table.indexof(tiles, tile)
        if not idx then
            return
        end

        local islast = tileCount == idx
        self.m_manager:onChuPaiChoose(idx, tile:getData(), islast)
        self.chosenTile = nil
        self:enableChuPai(false)

        -- 重置角标
        tile:enableTing(false)
        self:resetTingCorner()
    else
        self.chosenTile = tile
        self.m_manager:onTileFirstChosen(tile)
    end
end

function Desk3DUI:findTouchTile(touch)
    local handInfo = self:getSelfHandInfo()
    local tiles = handInfo.tiles
    local tileCount = #tiles
    if tileCount <= 0 then return false end
    local camera = self:get3DCamera()
    local scPos = touch:getLocationInView()
    local pos = self:getTouchPosOnTileSurface(touch)
    for i = 1, tileCount do
        local tile = tiles[i]
        local min, max = tile:getFaceRect()
        local t1 = cc.vec3(min.x, min.y, min.z)
        local t2 = cc.vec3(max.x, max.y, max.z)
        min = camera:project(t1)
        max = camera:project(t2)

        local minx = math.min(min.x, max.x)
        local miny = math.min(min.y, max.y)
        local maxx = math.max(min.x, max.x)
        local maxy = math.max(min.y, max.y)

        local rect = cc.rect(minx, miny, maxx - minx, maxy - miny)
        local isContain = cc.rectContainsPoint(rect, scPos)
        if isContain then
            return tile, pos
        end
    end
    return nil
end

function Desk3DUI:resetHandTilePosition(side, isIgnoreOffset)
    local handInfo = self.handTiles[side]
    local tiles = handInfo.tiles
    local tileCount = #tiles
    local hasQue = false
    for i = 1, tileCount do
        local tile = tiles[i]
        assert(tile ~= nil, string.format("手牌实际数量: %d, 记录数量: %d", #tiles, tileCount))
        tile:finishAllActions()
        local pos
        if isIgnoreOffset then
            pos = self:getHandTilePosition(i, side)
        else
            pos = tile:getPosition3D()
            pos.y = self:getHandTilePosition(i, side).y
        end
        tile:setPosition3D(pos)
        if side ~= 1 then
            if self.isLookback or configManager.debug.enable then
                tile:setUIType(MJ3DUI.UIType.ZHENG)
            else
                tile:setUIType(MJ3DUI.UIType.LI)
            end
        end

        -- 定缺的牌不能出
        if self.mode == MODE_FOURS and side == 1 and not self.isLookback then
            if self.que == tile:getData():getHuaSe() then
                hasQue = true
                tile:enableChuPai(true)
            else
                tile:enableChuPai(false)
            end
        end
    end

    if self.mode == MODE_FOURS and not hasQue then
        for i = 1, tileCount do
            local tile = tiles[i]
            tile:enableChuPai(true)
        end
    end
end

function Desk3DUI:chooseHandTile(tile)
    local handInfo = self:getSelfHandInfo()
    local index = table.indexof(handInfo.tiles, tile)
    local pos = tile:getPosition3D()
    tile:setPosition3D(cc.vec3(pos.x, pos.y + 10, pos.z))
end

function Desk3DUI:getTouchPosOnTileSurface(touch)
    local camera = self:get3DCamera()
    local scPos = touch:getLocationInView()
    local p1 = camera:unproject(cc.vec3(scPos.x, scPos.y, -1))
    local cameraPos = camera:unproject(cc.vec3(scPos.x, scPos.y, 1))
    --local cameraPos = camera:getPosition3D()
    local direction = cc.vec3(p1.x - cameraPos.x, p1.y - cameraPos.y, p1.z - cameraPos.z)
    direction = cc.vec3normalize(direction)

    if not self.m_A then
        self.m_A = self.selfTileSurfaceNormal.x
        self.m_B = self.selfTileSurfaceNormal.y
        self.m_C = self.selfTileSurfaceNormal.z
        local pos = self.selfTileSurfaceNode:getPosition3D()
        self.m_D = self.m_A * pos.x + self.m_B * pos.y + self.m_C * pos.z
        self.m_pos = pos

        self.m_RD = self.m_A * cameraPos.x + self.m_B * cameraPos.y + self.m_C * cameraPos.z

        self.m_diff = self.m_D - self.m_RD

        self.m_mat = self.selfTileSurfaceNode:getWorldToNodeTransform()
    end

    local tmp = self.m_A * direction.x + self.m_B * direction.y + self.m_C * direction.z
    local t = self.m_diff / tmp

    local x = cameraPos.x + t * direction.x
    local y = cameraPos.y + t * direction.y
    local z = cameraPos.z + t * direction.z

    local checkSurface = self.m_A * (x - self.m_pos.x) + self.m_B * (y - self.m_pos.y) + self.m_C * (z - self.m_pos.z)

    local vec = cc.vec4(x, y, z, 1)
    vec = mat4_transformVector(self.m_mat, vec, vec)

    return cc.vec3(vec.x, vec.y, vec.z + 5)
end

function Desk3DUI:findTileByIndex(vec, idx, count)
    local ret = {}
    for i = 1, #vec do
        local mj = vec[i]
        if mj:getData():getIdx() == idx then
            table.push(ret, mj)
            count = count - 1
            if count <= 0 then
                break
            end
        end
    end
    return ret
end

function Desk3DUI:findTileByNetIndex(vec, idx)
    for i = 1, #vec do
        local mj = vec[i]
        if mj:getData() and mj:getData():getNetValue() == idx then
            return mj
        end
    end
end

function Desk3DUI:getLeftMJCount(turn)
    local side = self:playerDeskSide(turn)
    local tiles = self.handTiles[side].tiles
    return #tiles
end

function Desk3DUI:computeSideShouPaiOffset(side, andOff)
    local handInfo = self.handTiles[side]
    if side % 2 == 0 then
        handInfo.tileOffset = handInfo.tileOffset + MJ_KUAN
        return
    end
    local pongKong = self.pongKongTiles[side]
    local node = pongKong.tileNode
    local nextPos = pongKong.nextPongPosition
    local handInfo = self.handTiles[side]
    local tiles = handInfo.tiles
    local shouPaiCnt = #tiles
    if andOff == 1 then
        if shouPaiCnt % 3 == 1 then
            shouPaiCnt = shouPaiCnt + 1
        end
    end
    local pos = self.handTilePosition[shouPaiCnt]
    pos = cc.vec3(pos.x, pos.y, pos.z)

    if side == 1 then
        local pengPosx = node:getPositionX() + nextPos
        local curPosx = pos.x * SELF_MJ_SCALE
        local targetPosx = pengPosx - MJ_KUAN * 2 * SELF_MJ_SCALE
        local off = targetPosx - curPosx
        handInfo.tileOffset = off / SELF_MJ_SCALE
        printInfo("pengPosx: %d, curPosx: %d, targetPosx: %d, off: %d", pengPosx, curPosx, targetPosx, off)
    elseif side == 3 then
        local pengPosx = node:getPositionX() - nextPos
        local curPosx = -pos.x
        local targetPosx = pengPosx + MJ_KUAN * 2
        local off = targetPosx - curPosx
        handInfo.tileOffset = -off
    end
end

function Desk3DUI:getHandTilePosition(idx, dir)
    assert(idx <= 14 and idx > 0, "idx over range: " .. idx)
    local off = self.handTiles[dir].tileOffset
    local pos = self.handTilePosition[idx]
    return cc.vec3(pos.x + off, pos.y, pos.z)
end

local PGType = {}
PGType.PENG = 0
PGType.AN_GANG = 2
PGType.MING_GANG = 2
PGType.BA_GANG = 1

function Desk3DUI:syncDesk(info)
    self:setMakerByTurnIdx(info.markerTurn)
    self:setDice(info.dice1, info.dice2, false)
    local function getUsedTile(count)
        if count == 1 then
            local ret = self:getOneTile()
            return ret
        end
        local ret = {}
        for i = 1, count do
            table.push(ret, self:getOneTile())
        end
        return ret
    end

    info.lastMoPaiDir = self:playerDeskSide(info.lastMoPaiTurn)
    self:setCurOperateDir(info.lastMoPaiDir)
    local tmpLastSideMj = {}

    local key = function(dir)
        return string.format("key%d", dir)
    end

    -- 初始化麻将
    for _, player in ipairs(info.players) do
        player.dir = self:playerDeskSide(player.turn)
        self.m_lastTiles[player.dir] = player.lastTile
        for i, data in ipairs(player.chuPaiDatas) do
            local mj = getUsedTile(1)
            mj:setData(data)
            self:addTileToChuPosition(mj, player.dir, i, false)
            self.chuTiles[player.dir].sideCount = i + 1
            tmpLastSideMj[key(player.dir)] = mj
        end

        local handInfo = self.handTiles[player.dir]
        for i, data in ipairs(player.shouPaiDatas) do
            local tile = getUsedTile(1)
            tile:setData(data)
            self:addTileToHand(tile, player.dir, i)
            table.insert(handInfo.tiles, tile)
        end

        for i, pgInfo in ipairs(player.pengGangStats) do
            local bedir = self:playerDeskSide(judgeToMinMax(1, 3, player.turn + 1))
            if pgInfo.type == PGType.PENG then
                local mjs = getUsedTile(3)
                for i = 1, 3 do
                    mjs[i]:setData(pgInfo.mjs[i])
                end
                self:moveTileToPongKong(player.dir, bedir, mjs, false)
                self:computeSideShouPaiOffset(player.dir, 0)
            else
                local mjs = getUsedTile(4)
                for i = 1, 4 do
                    mjs[i]:setData(pgInfo.mjs[i])
                end
                self:addGangToPengPaiPos(player.dir, bedir, mjs, false)
                self:computeSideShouPaiOffset(player.dir, 1)
            end
        end
        self:sortTilesBySide(player.dir)
        self:resetHandTilePosition(player.dir, true)

        -- 处理已经和牌的玩家
        if player.isHu then
            local tileData = MJDataClass:create(player.huPai, true)
            local tile = getUsedTile(1)
            tile:setData(tileData)
            self:addHuMJToShouPai(player.dir, tile)
        end
    end

    if info.status == typeDefine.sDeskStatus.duanpai then
        networkManager.notify("DeskManager.QiPaiFinished", {})
    end
    if info.status == typeDefine.sDeskStatus.playing and info.lastChuPaiTurn then
        info.lastChuPaiDir = self:playerDeskSide(info.lastChuPaiTurn)
        self.deskCurrentSide = info.lastChuPaiDir
        self.deskLastTile = nil
        local mj = tmpLastSideMj[key(info.lastChuPaiDir)]
        if info.lastChuPaiData ~= nil and mj then
            self.deskLastTile = mj
            local pos = mj:getPosition3D()
            self:addChuPaiHint(info.lastChuPaiDir, pos)
        end
    end

    if info.lastMoPaiDir ~= 1 then
        self:makeLastMJOffset(info.lastMoPaiDir)
    end

    if info.hint ~= nil then
        local data = info.hint
        self.m_manager:actionHint(data.ops, data.uid, data.tings)
    end
end

--- 获取某方玩家的手牌信息
function Desk3DUI:getSideHandInfo(side)
    return self.handTiles[side]
end

--- 获取自己的手牌信息
function Desk3DUI:getSelfHandInfo()
    return self.handTiles[SELF_SIDE]
end

--- 获取手上的麻将
function Desk3DUI:getSelfHandTiles()
    return self:getSelfHandInfo().tiles
end

function Desk3DUI:getShouPaiMJPosByIdx(idx)
    local mjs = self:findTileByIndex(self:getSelfHandTiles(), idx, 5)
    local poses = {}
    local camera = self:get3DCamera()
    for i = 1, #mjs do
        local mj = mjs[i]

        local min, max = mj:getFaceRect()
        local t1 = cc.vec3(min.x, min.y, min.z)
        local t2 = cc.vec3(max.x, max.y, max.z)
        local t = cc.vec3((min.x + max.x) * 0.5, max.y, max.z)
        min = camera:projectGL(t)
        table.push(poses, { mj, min })
    end
    return poses
end

function Desk3DUI:enableLookback()
    self.isLookback = true
end

function Desk3DUI:isTileOnHand(turn, tileId)
    local side = self:playerDeskSide(turn)
    local handInfo = self.handTiles[side]
    local tiles = handInfo.tiles

    return self:findTileByNetIndex(tiles, tileId)
end

function Desk3DUI:resetTingCorner()
    local handTiles = self:getSelfHandTiles()
    for i = 1, #handTiles do
        local tile = handTiles[i]
        tile:enableTing(false)
    end
end

function Desk3DUI:refreshTing(tings)
    self.tings = tings
    printInfo("tings: %s", vardump(tings))
    local shoupai = self:getSelfHandTiles()
    for i = 1, #tings do
        local ting = tings[i]
        local mjs = self:findTileByIndex(shoupai, ting.index, 4)
        for j = 1, #mjs do
            local mj = mjs[j]
            mj:enableTing(true)
        end
    end
end

function Desk3DUI:setMode(mode)
    self.mode = mode
end

function Desk3DUI:setDingQue(que)
    self.que = que
end

return Desk3DUI
