local gameAssistant = require "app.logic.gameAssistant"
local LoginUI = class("LoginUI", cc.load("mvc").ViewBase)
local WebAccountManager = require "app.core.WebAccountManager"
local LoadingUI = require "app.ui.LoadingUI"
local WaitUi = require "app.ui.SkipUI"
local UIStack = require "packages.mvc.UIStack"
local PushWindow = require "app.ui.PushWindow"
local LocalRecord = require "app.core.LocalRecord"
local stringDefine = require "app.data.stringDefine"
local configManager = require "app.config.configManager"
local basic = require "app.core.basic"
local AgreementUI = require "app.ui.AgreementUI"
local HttpRequest = require "app.network.HttpRequest"

LoginUI.RESOURCE_FILENAME = "layout/login.csb"
LoginUI.RESOURCE_BINDING = {
    m_background = { id = "background" },
    m_logo = { id = "logo" },
    wechat = { id = "webchat", onClick = "onLogin" },
    cAgreement = { id = "agreement", onClick = "onCheckboxClick" },
    bAgreement = { id = "agreement,show_agreement", onClick = "onAgreement" },
}

function LoginUI:onCheckboxClick(sender)
    self.agreewithAgreement = sender:isSelected()
end

function LoginUI:onLogin(sender)
    if not self.agreewithAgreement then
        gameAssistant.showHintAlertUI("请认证阅读用户使用协议，确认后进入游戏。")
        return
    end

    local ui = WaitUi:create()
    UIStack.pushUI(ui)

    local payload = {
        appId = appConfig.appId,
        channelId = appConfig.channelId,
    }

    local response = function(sucess, data)
        if not sucess then
            gameAssistant.showHintAlertUI("连接游戏服务器失败", function() UIStack.popUI() end)
        else
            local res = json.decode(data)
            if res.code ~= 0 then
                gameAssistant.showHintAlertUI(res.error)
            elseif res.guest then
                self:onGuestLogin()
            else
                self:onWeChatLogin()
            end
        end
    end

    -- 查询服务器，当前渠道是否使用游客登陆
    HttpRequest.send(appConfig.loginQuery, response, json.encode(payload), "POST")
end

function LoginUI:onLoginResult(resp)
    local popUi = function()
        UIStack.popUI()
    end
    if resp.code ~= 0 then
        gameAssistant.showHintAlertUI(resp.error, popUi)
    else
        (require "app.logic.game").login(resp, LoadingUI, popUi)
    end
end

-- 三方SDK登录
function LoginUI:onThirdsdkLoginSuccess(pluginType, retCode, retContent)
    if retCode ~= 0 then
        return
    end
    LocalRecord.instance():setProperty(stringDefine.LONG_LOGIN_TOKEN, retContent.refresh_token)
    LocalRecord.instance():save()
    local function callback(resp)
        self:onLoginResult(resp)
    end

    WebAccountManager.wechatSignIn(callback, retContent)
end

-- 微信登录
function LoginUI:onWeChatLogin()
    local rd = LocalRecord.instance()
    --printInfo(vardump(LocalRecord.instance()))
    local token = rd:getProperty(stringDefine.LONG_LOGIN_TOKEN)
    if token then
        local param = { [stringDefine.LONG_LOGIN_TOKEN] = token }
        thirdsdk.login(0, param)
    else
        thirdsdk.login(0)
    end
end

-- 协议
function LoginUI:onAgreement()
    local ui = AgreementUI:create()
    UIStack.pushUI(ui)
end

-- 游客登录
function LoginUI:onGuestLogin()
    local function callback(resp)
        self:onLoginResult(resp)
    end

    WebAccountManager.guestSignIn(callback, basic.getDeviceId())
end

function LoginUI:onCreate()
    print("loginUI:oncreate()")
    self.m_window = PushWindow
    self.agreewithAgreement = true
    local gbgSize = self.m_background:getContentSize()
    local scaleW = display.width / gbgSize.width
    local scaleH = display.height / gbgSize.height
    self.m_background:setScale(scaleW, scaleH)
    self.m_logo:setPosition(cc.p(display.width / 2, display.height * 2 / 3))

    thirdsdk.initPlugin(0, "wx5c1c4bf394bc59c5", "3d4393d09924d1058bea0681f7372563", "")
    thirdsdk.registerScriptLoginHandler(handler(self, LoginUI.onThirdsdkLoginSuccess))
    audioEngine.playBackgroundMusic(configManager.soundConfig.musicFilePath())

    local ar = cc.ParticleSystemQuad:create("particle/login/login.plist")
    self.root:addChild(ar)
end

return LoginUI
