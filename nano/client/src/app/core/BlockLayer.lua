
local BlockLayer = {}

local layer = cc.Layer:create()
layer:retain()
local function onTouch(state, ...)
    if state == "began" then
        return true
    end
end
layer:registerScriptTouchHandler(onTouch, false, 0, true)
layer:setTouchEnabled(true)
layer:setGlobalZOrder(1000)
local director = cc.Director:getInstance()
local winSize = director:getWinSize()
local center = {x = winSize.width * 0.5, y = winSize.height * 0.5}
local label = cc.Label:createWithSystemFont("loading...", "", 40)
label:setTextColor(cc.BLACK)
layer:addChild(label)
label:setPosition(center)

function BlockLayer.show(node)
    layer:removeFromParent()
    node = node or director:getRunningScene()
    if not node then return end
    node:addChild(layer)
end

function BlockLayer.hide()
    layer:removeFromParent()
end

function BlockLayer.getLayer()
    return layer
end

function BlockLayer.createNewBlockLayer()
    local layer = cc.Layer:create()
    local function onTouch(state, ...)
        if state == "began" then
            return true
        end
    end
    layer:registerScriptTouchHandler(onTouch, false, 0, true)
    layer:setTouchEnabled(true)
    layer:setGlobalZOrder(1000)
    return layer
end

return BlockLayer
