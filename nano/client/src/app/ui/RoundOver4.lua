local dataManager = require "app.data.dataManager"
local RoundOver = class("RoundOver", cc.load("mvc").ViewBase)
local UIStack = require "packages.mvc.UIStack"
local gameAssistant = require "app.logic.gameAssistant"
local configManager = require "app.config.configManager"

local banners = {
    "images/over/WeChatKWX_SingleEndZiMo.png", --[1]自摸
    "images/over/WeChatKWX_Hu_font.png", --[2]胡
    "images/over/WeChatKWX_dianpao_font.png", --[3]点炮
    "images/over/WeChatKWX_chating.png" --[4]赔付
}

RoundOver.RESOURCE_FILENAME = "layout/round_end4.csb"
RoundOver.RESOURCE_BINDING = {
    m_exitBtn = { id = "exitBtn", onClick = "OnClose" },
    m_againBtn = { id = "again", onClick = "OnAgain" },
    m_share = { id = "share", onClick = "onShare" },
    m_banner = { id = "banner" },
    m_round = { id = "bg,round" },
    m_title = { id = "bg,title" },
    m_bg1name = { id = "bg1,name" },
    m_bg1totalScore = { id = "bg1,totalScore" },
    m_bg1yuScore = { id = "bg1,yuScore" },
    m_bg1fengScore = { id = "bg1,fengScore" },
    m_bg1fanScore = { id = "bg1,fanScore" },
    m_bg1banner = { id = "bg1,banner" },
    m_bg2name = { id = "bg2,name" },
    m_bg2totalScore = { id = "bg2,totalScore" },
    m_bg2yuScore = { id = "bg2,yuScore" },
    m_bg2fengScore = { id = "bg2,fengScore" },
    m_bg2fanScore = { id = "bg2,fanScore" },
    m_bg2banner = { id = "bg2,banner" },
    m_bg3name = { id = "bg3,name" },
    m_bg3totalScore = { id = "bg3,totalScore" },
    m_bg3yuScore = { id = "bg3,yuScore" },
    m_bg3fengScore = { id = "bg3,fengScore" },
    m_bg3fanScore = { id = "bg3,fanScore" },
    m_bg3banner = { id = "bg3,banner" },
    m_bg4name = { id = "bg4,name" },
    m_bg4totalScore = { id = "bg4,totalScore" },
    m_bg4yuScore = { id = "bg4,yuScore" },
    m_bg4fengScore = { id = "bg4,fengScore" },
    m_bg4fanScore = { id = "bg4,fanScore" },
    m_bg4banner = { id = "bg4,banner" },
}

function RoundOver:OnClose(sender)
    gameAssistant.playCloseUISound()
    UIStack.popUI()
end

function RoundOver:OnAgain(sender)
    gameAssistant.playCloseUISound()
    self.callback()
    UIStack.popUI()
end

--截屏回调方法
local function afterCaptured(succeed, outputFile)
    if succeed then
        local title = configManager.systemConfig.title
        local desc = configManager.systemConfig.desc
        printInfo("capture screen succeed: %s, %s, %s", outputFile, title, desc)
        thirdsdk.share("session", outputFile, title, desc)
    else
        printInfo("capture screen failed.")
    end
end

function RoundOver:onShare(sender)
    gameAssistant.playCloseUISound()
    local fileName = "CaptureScreen.png"
    cc.utils:captureScreen(afterCaptured, fileName)
end

--- 创建结算界面
-- @param fn
-- @param totalPlayer
-- @param title
-- @param round
-- @param isLookback 是否是回放结算
--
function RoundOver:onCreate(fn, totalPlayer, title, round, isLookback, isLastRound)
    self.isLookback = isLookback
    self.callback = fn
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 90)
    self.m_againBtn:hide()
    self.m_round:setString(round)
    self.m_title:setString(title)
    self.m_bg1banner:setVisible(false)
    self.m_bg2banner:setVisible(false)
    self.m_bg3banner:setVisible(false)
    self.m_bg4banner:setVisible(false)
    self:setAction()
    self:setTotalChangeScore(totalPlayer)
    if isLookback or isLastRound then
        local child = self.m_againBtn:getChildByName("result_font_zailaiyiju_6")
        if child and isLookback then
            child:setTexture("majiang/alert/lookback_finish.png")
        end
        if child and isLastRound then
            child:setTexture("majiang/alert/finish_battle.png")
        end
    end
end

function RoundOver:setBanner(score)
    if score > 0 then
        self.m_banner:setTexture("images/over/title_win.png")
    elseif score < 0 then
        self.m_banner:setTexture("images/over/title_lost.png")
    end
end

local function flagScore(score)
    if score >= 0 then
        return string.format("+%d", score)
    else
        return score
    end
end

--TODO(important): -1番表示极品
local function flagFan(fan, desc)
    if fan == 0 then
        return "平胡"
    elseif fan == -1 then
        return string.format("极品(%s)", desc)
    elseif fan == -2 then
        return "～"
    else
        if desc ~= nil and string.len(desc) > 0 then
            return string.format("%d番(%s)", fan, desc)
        else
            return string.format("%d番", fan)
        end
    end
end

function RoundOver:setTotalChangeScore(totalPlayer)
    for i = 1, #totalPlayer do
        local player = totalPlayer[i]
        local prefix = "m_bg" .. i
        local name = self[prefix .. "name"]
        local totalScore = self[prefix .. "totalScore"]
        local yuScore = self[prefix .. "yuScore"]
        local fengScore = self[prefix .. "fengScore"]
        local fanScore = self[prefix .. "fanScore"]
        local banner = self[prefix .. "banner"]
        local desc = self[prefix .. "desc"]
        local nickname = player.nickName
        if utfstrlen(nickname) > 8 then
            nickname = string.format("%s...", subUTF8String(nickname, 1, 6))
        end
        name:setString(nickname)
        fengScore:setString("刮风: " .. flagScore(player.fengScore))
        yuScore:setString("下雨: " .. flagScore(player.yuScore))
        fanScore:setString("番数: " .. flagFan(player.fanScore, player.desc))
        totalScore:setString("总分: " .. flagScore(player.totalScore))
        if player.bannerType and banners[player.bannerType] then
            banner:setVisible(true)
            banner:setTexture(banners[player.bannerType])
        end
        if player.uid == dataManager.playerData:getAcId() then
            self:setBanner(player.totalScore)
        end
    end
end

function RoundOver:setAction()
    self.m_againBtn:show()
    self.m_againBtn:setOpacity(0)
    self.m_againBtn:runAction(cc.FadeIn:create(0.1))

    self.m_share:show()
    self.m_share:setOpacity(0)
    self.m_share:runAction(cc.FadeIn:create(0.1))
end

return RoundOver