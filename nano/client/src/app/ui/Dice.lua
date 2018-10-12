local Dice = class("Dice", cc.Node)
local diceConfig = require "app.config.diceConfig"

local circle_rotate_step = 
{
    kStepUp = 0,
    kStepConst = 1,
    kStepDown = 2,
    kStepEnd = 3,
}
local circle_radius_step = 
{
    kStepUp = 0,
    kStepConst = 1,
    kStepDown = 2,
    kStepEnd = 3,
}
local dice_rotate_step = 
{
    kStepConst = 1,
    kStepDown = 2,
    kStepEnd = 3,
}
local diceCountR = {
    [1] = cc.vec3(-90, 0, 0),
    [2] = cc.vec3(0, 0, 180),
    [3] = cc.vec3(0, 0, 270),
    [4] = cc.vec3(0, 0, 0),
    [5] = cc.vec3(0, 0, 90),
    [6] = cc.vec3(90, 0, 0),
}
function Dice:ctor()
    self.m_isRunning = false

    local modelName = "model/dice.c3t"
    self.m_diceModel1 = cc.Sprite3D:create(modelName)
    self.m_diceModel2 = cc.Sprite3D:create(modelName)
    self.m_diceModel1:setPosition3D(cc.vec3(0, 0, -5))
    self.m_diceModel2:setPosition3D(cc.vec3(0, 0, -5))
    self.m_diceModel1:setRotation3D(cc.vec3(0, 0, 0))
    self.m_diceModel2:setRotation3D(cc.vec3(0, 0, 0))
    self.m_diceModel1:setScale(1.2)
    self.m_diceModel2:setScale(1.2)
    self.m_diceFace1 = cc.Node:create();
    self.m_diceFace2 = cc.Node:create();
    self.m_diceFace1:addChild(self.m_diceModel1)
    self.m_diceFace2:addChild(self.m_diceModel2)

    self.m_diceRY1 = cc.Node:create();
    self.m_diceRY2 = cc.Node:create();
    self.m_diceRY1:addChild(self.m_diceFace1)
    self.m_diceRY2:addChild(self.m_diceFace2)

    self.m_dice1 = cc.Node:create()
    self.m_dice2 = cc.Node:create()
    self.m_dice1:addChild(self.m_diceRY1)
    self.m_dice2:addChild(self.m_diceRY2)

    self:addChild(self.m_dice1)
    self:addChild(self.m_dice2)

    self.m_dice1:setPosition3D(cc.vec3(-diceConfig.radius1, 0, 0))
    self.m_dice2:setPosition3D(cc.vec3(diceConfig.radius1, 0, 0))
    self:reset()
    self:setPositionY(4)
    self:setPositionZ(-4)
end

function Dice:reset()
    self.m_circleSpeed = 0
    self.m_radiusSpeed = 0
    self.m_diceSpeed = 0
    self:setRotationY(0)

    self.m_circleStep = circle_rotate_step.kStepUp
    self.m_circleRStep = circle_radius_step.kStepUp
    self.m_diceRStep = dice_rotate_step.kStepConst
    self.m_usedTime = 0
end

function Dice:start(dice1, dice2, action)
    local initRotate = math.random(0, 360)
    self.m_isRunning =  action and true
    self:__setInitRotate(initRotate)

    self.m_dice1:setPosition3D(cc.vec3(-diceConfig.radius1, 0, 0))
    self.m_dice2:setPosition3D(cc.vec3(diceConfig.radius1, 0, 0))
    self.m_dice1:setRotation3D(cc.vec3(0, 0, 0))
    self.m_dice2:setRotation3D(cc.vec3(0, 0, 0))

    local v1 = cc.vec3(0, math.random(0, 360), 0)
    local v2 = cc.vec3(0, math.random(0, 360), 0)
    self.m_diceFace1:setRotation3D(diceCountR[dice1])
    self.m_diceFace2:setRotation3D(diceCountR[dice2])
    self.m_diceRY1:setRotation3D(v1)
    self.m_diceRY2:setRotation3D(v2)

    self:reset()
end

function Dice:__setInitRotate(initRotate)
    self:setRotationY(initRotate)
end

function Dice:update(dt)
    if not self.m_isRunning then
        return
    end
    self.m_usedTime = self.m_usedTime + dt
    --circle rotate
    self:__updateCircleRotate(dt)

    --circle Radius
    self:__updateCircleRadius(dt)

    --dice rotate
    self:__updateDiceRotate(dt)
end

function Dice:__updateCircleRotate(dt)
    if self.m_circleStep == circle_rotate_step.kStepUp then
        self.m_circleSpeed = self.m_circleSpeed + diceConfig.circleRotate1a * dt
        self:__setCircleRotate(self.m_circleSpeed, dt)
        if self.m_usedTime > diceConfig.totalRotateStep1Time then
            self.m_circleStep = circle_rotate_step.kStepConst
            self.m_circleSpeed = diceConfig.rotate2Speed
        end
    elseif self.m_circleStep == circle_rotate_step.kStepConst then
        self:__setCircleRotate(self.m_circleSpeed, dt)
        if self.m_usedTime > diceConfig.totalRotateStep2Time then
            self.m_circleStep = circle_rotate_step.kStepDown
        end
    elseif self.m_circleStep == circle_rotate_step.kStepDown then
        self.m_circleSpeed = self.m_circleSpeed + diceConfig.circleRotate3a * dt
        self:__setCircleRotate(self.m_circleSpeed, dt)
        if self.m_usedTime > diceConfig.totalRotateStep3Time then
            self.m_circleStep = circle_rotate_step.kStepEnd
        end
    elseif self.m_circleStep == circle_rotate_step.kStepEnd then
    end
end

function Dice:__setCircleRotate(v, dt)
    if v < 0 then v = 0 end
    local circlemv = v * dt
    local curRotate = self:getRotationY()
    self:setRotationY(curRotate + circlemv)
end

function Dice:__updateCircleRadius(dt)
    if self.m_circleRStep == circle_radius_step.kStepUp then
        self:__setCircleRadius(diceConfig.radius1v, dt)
        if self.m_usedTime > diceConfig.totalRadiusStep1Time then
            self.m_circleRStep = circle_radius_step.kStepConst
        end
    elseif self.m_circleRStep == circle_radius_step.kStepConst then
        if self.m_usedTime > diceConfig.totalRadiusStep2Time then
            self.m_circleRStep = circle_radius_step.kStepDown
        end
    elseif self.m_circleRStep == circle_radius_step.kStepDown then
        self:__setCircleRadius(diceConfig.radius3v, dt)
        if self.m_usedTime > diceConfig.totalRadiusStep3Time then
            self.m_circleRStep = circle_radius_step.kStepEnd
        end
    elseif self.m_circleRStep == circle_radius_step.kStepEnd then
    end
end
function Dice:__setCircleRadius(v, dt)
    local x = v * dt
    local curx = self.m_dice1:getPositionX()
    local newPos = math.abs(curx) + x
    self.m_dice1:setPosition3D(cc.vec3(-newPos, 0, 0))
    self.m_dice2:setPosition3D(cc.vec3(newPos, 0, 0))
end

function Dice:__updateDiceRotate(dt)
    if self.m_diceRStep == dice_rotate_step.kStepConst then
        local cx = diceConfig.diceRotateSpeed * self.m_usedTime
        if cx > 360 then cx = cx - 360 end
        self.m_dice1:setRotationX(cx)
        self.m_dice2:setRotationZ(cx)
        if self.m_usedTime > diceConfig.totalDiceTime1 then
            self.m_diceRStep = dice_rotate_step.kStepDown
            self.m_downStartRX = self.m_dice1:getRotationX()
            self.m_downStartRZ = self.m_dice2:getRotationZ()
            local vt = diceConfig.diceRotateSpeed * diceConfig.diceRotateDownTime
            self.m_diceRotate1a = (2 * (360 - self.m_downStartRX) - vt) / diceConfig.diceRotateTimePow
            self.m_diceRotate2a = (2 * (360 - self.m_downStartRZ) - vt) / diceConfig.diceRotateTimePow
        end
    elseif self.m_diceRStep == dice_rotate_step.kStepDown then
        local time = self.m_usedTime
        if self.m_usedTime > diceConfig.totalDiceTime2 then
            time = diceConfig.diceRotateDownTime
            self.m_diceRStep = dice_rotate_step.kStepEnd
            self.m_isRunning = false
        end
        time = time - diceConfig.diceRotate1Time
        local ptime = math.pow(time, 2)
        local s1 = 0.5 * self.m_diceRotate1a * ptime + diceConfig.diceRotateSpeed * time
        local s2 = 0.5 * self.m_diceRotate2a * ptime + diceConfig.diceRotateSpeed * time

        local cx = self.m_downStartRX + s1
        local cz = self.m_downStartRZ + s2
        if not self.m_isRunning then
            cx = 0
            cz = 0
        end
        self.m_dice1:setRotationX(cx)
        self.m_dice2:setRotationZ(cz)
    elseif self.m_diceRStep == dice_rotate_step.kStepEnd then
    end
end
return Dice