--loading ui
--this ui may show before cocos framework loaded,
--so we do not use cocos framework function here.
local json = require "cocos.cocos2d.json"
local updater = require "app.updater.updater"
local UIStack = require "packages.mvc.UIStack"

local LoadingUI = {}
LoadingUI.__index = LoadingUI
local director = cc.Director:getInstance()
local winSize = director:getWinSize()
local center = { x = winSize.width * 0.5, y = winSize.height * 0.5 }
function LoadingUI:new()
    ret = {}
    setmetatable(ret, self)
    ret:ctor()
    return ret
end

function LoadingUI:create()
    return self:new()
end

function LoadingUI:ctor()
end

function LoadingUI:showWithScene(hasUpdate)
    return self:run(hasUpdate)
end

function LoadingUI:run(hasUpdate)
    local scene = cc.Scene:create()
    self.layer = cc.Layer:create()
    scene:addChild(self.layer)

    self:initLayer()

    -- 热更功能
    if hasUpdate == true then
        self:checkUpdate()
    else
        self:preLoadResource()
    end

    self.m_moduleNode = cc.Node:create()
    self.layer:addChild(self.m_moduleNode)
    self.m_moduleNode:setLocalZOrder(100)

    if director:getRunningScene() then
        director:replaceScene(scene)
    else
        director:runWithScene(scene)
    end
    UIStack.changeBaseUI(self.m_moduleNode)
end

function LoadingUI:initLayer()
    local width = winSize.width
    local height = winSize.height

    local background = cc.Sprite:create("images/login/background.png")
    background:setPosition(center)
    self.layer:addChild(background)

    local nodeSize = background:getContentSize()
    local scaleW = width / nodeSize.width
    local scaleH = height / nodeSize.height
    background:setScale(scaleW, scaleH)

    local logo = cc.Sprite:create("images/common/logo.png")
    logo:setPosition({ x = winSize.width * 0.5, y = winSize.height * 2 / 3 })
    self.layer:addChild(logo)

    self.pencilbg = cc.Sprite:create("images/login/login_pic_gengxin.png")
    self.pencilbg:setPosition(winSize.width / 2, 80)
    self.layer:addChild(self.pencilbg)

    self.pencil = cc.ProgressTimer:create(cc.Sprite:create("images/login/login_icon_gengxin.png"))
    self.pencil:setType(1)
    self.pencil:setMidpoint({ 0, 0 })
    self.pencil:setBarChangeRate({ x = 1, y = 0 })
    self.pencil:setPercentage(0)
    self.pencil:setPosition(233, 106)
    self.pencilbg:addChild(self.pencil)

    self.pencilT = cc.LabelTTF:create("正在更新中...", "fonts/simhei", 26)
    self.pencilT:setPosition(233, 70)
    self.pencilbg:addChild(self.pencilT)
    self.pencilbg:setVisible(false)
end

function LoadingUI:checkUpdate()
    local function checkUpdateCallback(isNeedUpdate, forceUpdate, updateURL)
        if forceUpdate then
            self.pencilbg:setVisible(true)
            self.pencilT:setString("发现新版本, 即将跳转到下载地址...")
            print("发现强更版本，准备跳转到新地址，地址", updateURL)
            ccextplatform.openExplore(updateURL)
        elseif isNeedUpdate then
            self.pencilbg:setVisible(true)
            print("发现新版本，准备更新，补丁地址", updateURL)
            self.pencilT:setString("发现新版本, 正在下载补丁包...")
            self:startUpdate(updateURL)
        else
            self:preLoadResource()
        end
    end

    --[[self.resourceNode = cc.CSLoader:createNode("layout/loading.csb")
    local action = cc.CSLoader:createTimeline("layout/loading.csb")
    self.resourceNode:runAction(action)
    action:gotoFrameAndPlay(0)
    self.resourceNode:setPosition(winSize.width * 0.5, winSize.height * 0.5)
    self.layer:addChild(self.resourceNode) ]]

    self.pencilT:setString("正在连接游戏服务器...")
    updater.checkHasUpdate(checkUpdateCallback)
end

function LoadingUI:startUpdate(patchUrl)
    self.pencilbg:setVisible(true)
    if self.resourceNode then
        self.resourceNode:stopAllActions()
        self.resourceNode:removeFromParent()
    end
    local function onProcessCallback(curCnt, totalCnt, msg)
        self.pencil:setPercentage(curCnt / totalCnt * 100)
        if msg ~= nil then
            self.pencilT:setString(msg)
        end
    end

    local function onCompleteCallback(isok)
        self:preLoadResource()
    end

    updater.startUpdate(patchUrl, onProcessCallback, onCompleteCallback)
end

function LoadingUI:preLoadResource()
    require "app.core.InitAfterUpdate"
    local function showLoginUI()
        if not tolua.isnull(self.resourceNode) then
            self.resourceNode:stopAllActions()
            self.resourceNode:removeFromParent()
        end
        local LoginUI = require "app.ui.LoginUI"
        self.layer:addChild(LoginUI:create("", ""))
    end

    showLoginUI()
end

return LoadingUI
