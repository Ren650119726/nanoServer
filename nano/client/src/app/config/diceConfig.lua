local diceConfig = {

--time(second)
--rotate(degree)

--circle rotate config
rotate1Time = 0.2,
rotate2Time = 1.5,
rotate2Speed = 1500,
rotate3Time = 0.3,

--circle radius
radius1 = 8,
radius1Time = 0.2,
radius2 = 12,
radius2Time = 1.5,
radius3 = 8,
radius3Time = 0.3,

--dice rotate config
diceRotateSpeed = 720,
diceRotate1Time = 0.8,
diceRotateDownTime = 1.2,

}

function diceConfig.compute()
    diceConfig.circleRotate1a = diceConfig.rotate2Speed / diceConfig.rotate1Time
    diceConfig.circleRotate3a = -diceConfig.rotate2Speed / diceConfig.rotate3Time

    diceConfig.radius1v = (diceConfig.radius2 - diceConfig.radius1) / diceConfig.radius1Time
    diceConfig.radius3v = -(diceConfig.radius2 - diceConfig.radius3) / diceConfig.radius3Time

    diceConfig.diceRotateTimePow = 2 * 360 / math.pow(diceConfig.diceRotateDownTime, 2)

    diceConfig.totalRotateStep1Time = diceConfig.rotate1Time
    diceConfig.totalRotateStep2Time = diceConfig.totalRotateStep1Time + diceConfig.rotate2Time
    diceConfig.totalRotateStep3Time = diceConfig.totalRotateStep2Time + diceConfig.rotate3Time

    diceConfig.totalRadiusStep1Time = diceConfig.radius1Time
    diceConfig.totalRadiusStep2Time = diceConfig.totalRadiusStep1Time + diceConfig.radius2Time
    diceConfig.totalRadiusStep3Time = diceConfig.totalRadiusStep2Time + diceConfig.radius3Time

    diceConfig.totalDiceTime1 = diceConfig.diceRotate1Time
    diceConfig.totalDiceTime2 = diceConfig.totalDiceTime1 + diceConfig.diceRotateDownTime
end

diceConfig.compute()
return diceConfig