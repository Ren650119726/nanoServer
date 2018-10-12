local SettingUi = class("SettingUi", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local LocalRecord = require "app.core.LocalRecord"
local stringDefine = require "app.data.stringDefine"
local gameAssistant = require "app.logic.gameAssistant"

SettingUi.RESOURCE_FILENAME = "layout/setting.csb"
SettingUi.RESOURCE_BINDING = {
    music = { id = "music_checkbox", onClick = "onMusicSwitch"},
    effect = { id = "effect_checkbox", onClick = "onEffectSwitch" },
    version = { id = "version" },
    close = { id = "close", onClick = "onClose" },
}

--- 关闭设置界面
function SettingUi:onClose()
    gameAssistant.playCloseUISound()
    LocalRecord.instance():save()
    UIStack.popUI()
end

function SettingUi:onMusicSwitch(sender)
    local enabled = not sender:isSelected()
    LocalRecord.instance():setProperty(stringDefine.SOUND_BG, enabled)
    audioEngine.enableBackgroundMusic(enabled)
    gameAssistant.playBtnClickedSound()
end

function SettingUi:onEffectSwitch(sender)
    local enabled = not sender:isSelected()
    LocalRecord.instance():setProperty(stringDefine.SOUND_EF, enabled)
    audioEngine.enableEffect(enabled)
    gameAssistant.playBtnClickedSound()
end

function SettingUi:onCreate()
    self:initCheck()
    self.root:ignoreAnchorPointForPosition(true)
    self.root:setAnchorPoint(cc.p(0.5, 0.5))
    self:addABlockLayer(true, 130)
    self.root:setScale(0.5)
    local action1 = cc.ScaleTo:create(0.15, 1.1)
    local action2 = cc.ScaleTo:create(0.1, 1)
    self.root:runAction(cc.Sequence:create(action1, action2))
    self:setGlobalZOrder(100)
    self.version:setString(string.format("版本：v%s", appConfig.version))
    self.root:setPosition(display.center)
end

function SettingUi:initCheck()
    if LocalRecord.instance():getProperty(stringDefine.SOUND_BG) then
        self.music:setSelected(false);
    else
        self.music:setSelected(true);
    end

    if LocalRecord.instance():getProperty(stringDefine.SOUND_EF) then
        self.effect:setSelected(false);
    else
        self.effect:setSelected(true);
    end
end

return SettingUi
