local SettingDetailUi = class("SettingDetailUi", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local LocalRecord = require "app.core.LocalRecord"
local stringDefine = require "app.data.stringDefine"
local gameAssistant = require "app.logic.gameAssistant"
local EventManager = require "app.core.EventManager"
local dataManager = require "app.data.dataManager"
local PushWindow = require "app.ui.PushWindow"

SettingDetailUi.RESOURCE_FILENAME = "layout/setting_detail.csb"
SettingDetailUi.RESOURCE_BINDING = {
    music = { id = "music_checkbox", onClick = "onMusicSwitch"},
    effect = { id = "effect_checkbox", onClick = "onEffectSwitch" },
    close = { id = "close", onClick = "onClose" },
    quite = { id = "quit", onClick = "onQuit" },
    nickname = { id = "nickname" },
    uid = { id = "uid" },
    headIcon = { id = "head" },
    version = { id = "version" },
}

function SettingDetailUi:onClose()
    gameAssistant.playCloseUISound()
    LocalRecord.instance():save()
    UIStack.popUI()
end

function SettingDetailUi:onQuit()
    local function back()
        self:unregistEvent()
        self.lobby.exit()
    end

    local windowTable = { title = "是否退出登录", yes = { title = "确定", fun = back }, no = { title = "取消", fun = function()  end } }
    local ui = PushWindow:create("", "", windowTable)
    UIStack.pushUI(ui)
end

function SettingDetailUi:onMusicSwitch(sender)
    local enabled = not sender:isSelected()
    LocalRecord.instance():setProperty(stringDefine.SOUND_BG, enabled)
    audioEngine.enableBackgroundMusic(enabled)
    gameAssistant.playBtnClickedSound()
end

function SettingDetailUi:onEffectSwitch(sender)
    local enabled = not sender:isSelected()
    LocalRecord.instance():setProperty(stringDefine.SOUND_EF, enabled)
    audioEngine.enableEffect(enabled)
    gameAssistant.playBtnClickedSound()
end

function SettingDetailUi:onCreate(lobby)
    self:initCheck()
    self.root:ignoreAnchorPointForPosition(true)
    self.root:setAnchorPoint(cc.p(0.5, 0.5))
    self:addABlockLayer(true, 130)
    self.root:setScale(0.5)
    local action1 = cc.ScaleTo:create(0.15, 1.1)
    local action2 = cc.ScaleTo:create(0.1, 1)
    self.root:runAction(cc.Sequence:create(action1, action2))
    self:setGlobalZOrder(100)
    self.root:setPosition(display.center)

    self.lobby = lobby

    -- 数据绑定
    local name = dataManager.playerData:getNickname()
    if utfstrlen(name) > 8 then
        name = string.format("%s...", subUTF8String(name, 1, 6))
    end
    self:updateNickname(name)
    self:updateUid(dataManager.playerData:getId())

    if dataManager.playerData:getHeadIcon() and dataManager.playerData:getHeadIcon() ~= "" then
        self:updateHeadIcon(dataManager.playerData:getHeadIcon())
    end

    self.version:setString(string.format("版本：v%s",appConfig.version))
end

function SettingDetailUi:initCheck()
    local enableBG = LocalRecord.instance():getProperty(stringDefine.SOUND_BG)
    local enableMU = LocalRecord.instance():getProperty(stringDefine.SOUND_EF)
    if enableBG then
        self.music:setSelected(false);
    else
        self.music:setSelected(true);
    end

    if enableMU then
        self.effect:setSelected(false);
    else
        self.effect:setSelected(true);
    end
end

function SettingDetailUi:updateNickname(name)
    self.nickname:setText(name)
end

function SettingDetailUi:updateUid(id)
    self.uid:setText(id)
end

function SettingDetailUi:updateHeadIcon(icon)
    self.headIcon:setScale(1)
    self.headIcon:setTexture(icon)
    self.headIcon:setScale(95 / self.headIcon:getContentSize().width)
end

---------------------------------------------------------------------------------
--- EVENT HANDLER
---------------------------------------------------------------------------------
function SettingDetailUi:onHeadIconChanged(event)
    if tostring(event.id) == tostring(dataManager.playerData:getAcId()) then
        self:updateHeadIcon(event.head)
    end
end

function SettingDetailUi:onNicknameChanged(event)
    self:updateNickname(event.newValue)
end

function SettingDetailUi:registEvent()
    self._, self.nicknameChangedHandler = EventManager:addEventListener(event_name.PLAYERDATA_NICKNAME_CHANGED, handler(self, self.onNicknameChanged))
    self._, self.headChangedHandler = EventManager:addEventListener(event_name.PLAYERDATA_HEADICON_CHANGED, handler(self, self.onHeadIconChanged))
end

function SettingDetailUi:unregistEvent()
    EventManager:removeEventListener(self.nicknameChangedHandler)
    EventManager:removeEventListener(self.headChangedHandler)
end

return SettingDetailUi
