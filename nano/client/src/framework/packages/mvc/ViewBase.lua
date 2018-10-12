local ViewBase = class("ViewBase", cc.Node)
local UIStack = require "packages.mvc.UIStack"

function ViewBase:ctor(app, name, ...)
    self:enableNodeEvents()
    self.app_ = app
    self.name_ = name

    -- check CSB resource file
    local res = self.class["RESOURCE_FILENAME"] --rawget(self.class, "RESOURCE_FILENAME")
    if res then
        self:createResoueceNode(res)
    end

    local binding = self.class["RESOURCE_BINDING"] --rawget(self.class, "RESOURCE_BINDING")
    if res and binding then
        self:createResoueceBinding(binding)
    end
    self.m_block = true

    self.m_moduleNode = cc.Node:create()
    self:addChild(self.m_moduleNode)
    self.m_moduleNode:setLocalZOrder(100)
    if self.onCreate then self:onCreate(...) end
end

function ViewBase:getApp()
    return self.app_
end

function ViewBase:getName()
    return self.name_
end

function ViewBase:getResourceNode()
    return self.root
end

function ViewBase:createResoueceNode(resourceFilename)
    if self.root then
        self.root:removeSelf()
        self.root = nil
    end
    print(string.format("RESOURCE_FILENAME： %s", resourceFilename))
    self.root = cc.CSLoader:createNode(resourceFilename)
    assert(self.root, string.format("ViewBase:createResoueceNode() - load resouce node from file \"%s\" failed", resourceFilename))
    self:addChild(self.root)
end

local function split(str, sep)
    local pattern = string.format("[^%s]+", sep)
    local fields = {}
    str:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

local function findNodeChild(node, name)
    local names = split(name, ",")
    local len = #names
    local ret = node
    for i = 1, len do
        local name = names[i]
        ret = ret:getChildByName(name)
        if not ret then
            printError("Node Not Found: %s", name)
        end
    end
    return ret
end

function ViewBase:createResoueceBinding(binding)
    assert(self.root, "ViewBase:createResoueceBinding() - not load resource node")
    for varname, args in pairs(binding) do
        local node = findNodeChild(self.root, args.id)
        if varname then
            self[varname] = node
        end
        if args.zorder then
            node:setLocalZOrder(args.zorder)
        end
        if args.label and self[varname] then
            local content = args.content or ""
            local fontSize = args.fontSize or 25
            local align = args.align or cc.TEXT_ALIGNMENT_LEFT
            local label = createLabel(content, fontSize, align)
            label:setAnchorPoint(args.anchor or display.CENTER)
            label:setTextColor(args.color or display.COLOR_WHITE)
            if args.outline then
                label:enableOutline(args.outlineColor or display.COLOR_BLACK, args.outlineSize or 2)
            end
            self[varname]:addChild(label)
            self[varname] = label
        end
        if args.onClick then
            node:addClickEventListener(handler(self, self[args.onClick]))
        end
        if args.onTouch then
            node:onTouch(handler(self, self[args.onTouch]), args.isMultiTouches, args.swallowTouches)
        end
        if args.onUITouch then
            node:addTouchEventListener(handler(self, self[args.onUITouch]))
        end
    end
end

function ViewBase:showWithScene(transition, time, more)
    self:setVisible(true)
    local scene = display.newScene(self.name_)
    scene:addChild(self)
    local isReplace = false
    if time and more then
        isReplace = display.runScene(scene, transition, time, more)
    else
        isReplace = display.runScene(scene)
    end
    if isReplace then
        UIStack.changeBaseUI(self.m_moduleNode)
    else
        UIStack.pushBaseUI(self.m_moduleNode)
    end
    return self
end

function ViewBase:pushScene()
    self:setVisible(true)
    local scene = display.newScene(self.name_)
    scene:addChild(self)
    local director = cc.Director:getInstance()
    director:pushScene(scene)
    UIStack.pushBaseUI(self.m_moduleNode)
    return self
end

function ViewBase:popScene()
    local director = cc.Director:getInstance()
    director:popScene()
    UIStack.popBaseUI()
    UIStack.popAllUI()
end

function ViewBase:addABlockLayer(dark, value)
    local layer
    if dark then
        value = value or 128
        layer = cc.LayerColor:create(cc.c4b(0, 0, 0, value))
    else
        layer = cc.Layer:create()
    end
    local function onTouch(state, ...)
        if state == "began" then
            if self:isVisible() then
                return self.m_block
            end
        end
        if state == "ended" then
            if self.onBlockLayerClicked then
                self:onBlockLayerClicked(...)
            end
        end
    end

    layer:registerScriptTouchHandler(onTouch, false, 0, true)
    layer:setTouchEnabled(true)
    self:addChild(layer, -1000)
end

function ViewBase:enableBlockLayer(enabled)
    self.m_block = enabled
end

function ViewBase:registEvent()
end

function ViewBase:unregistEvent()
end

return ViewBase
