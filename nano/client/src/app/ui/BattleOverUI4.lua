local BattleOverUI4 = class("BattleOverUI", cc.load("mvc").ViewBase)
local deskManager = require "app.logic.deskManager"
local UIStack = require "packages.mvc.UIStack"
local gameAssistant = require "app.logic.gameAssistant"
local configManager = require "app.config.configManager"

BattleOverUI4.RESOURCE_FILENAME = "layout/game_end4.csb"
BattleOverUI4.RESOURCE_BINDING = {
    m_cancel = { id = "container,cancel", onClick = "onBack" },
    m_share = { id = "container,share", onClick = "onShare" },
    m_desc = { id = "container,desc" },
    m_rule = { id = "container,title" },
    m_timestamp = { id = "container,timestamp" },
    m_player1zimoScore = { id = "container,player1,zimoScore" },
    m_player1huScore = { id = "container,player1,huScore" },
    m_player1paoScore = { id = "container,player1,paoScore" },
    m_player1mingScore = { id = "container,player1,mingScore" },
    m_player1anScore = { id = "container,player1,anScore" },
    m_player1headIcon = { id = "container,player1,headIcon" },
    m_player1name = { id = "container,player1,name" },
    m_player1id = { id = "container,player1,id" },
    m_player1owner = { id = "container,player1,owner" },
    m_player1winner = { id = "container,player1,winner" },
    m_player1loser = { id = "container,player1,loser" },
    m_player1total = { id = "container,player1,total" },
    m_player2zimoScore = { id = "container,player2,zimoScore" },
    m_player2huScore = { id = "container,player2,huScore" },
    m_player2paoScore = { id = "container,player2,paoScore" },
    m_player2mingScore = { id = "container,player2,mingScore" },
    m_player2anScore = { id = "container,player2,anScore" },
    m_player2headIcon = { id = "container,player2,headIcon" },
    m_player2name = { id = "container,player2,name" },
    m_player2id = { id = "container,player2,id" },
    m_player2owner = { id = "container,player2,owner" },
    m_player2winner = { id = "container,player2,winner" },
    m_player2loser = { id = "container,player2,loser" },
    m_player2total = { id = "container,player2,total" },
    m_player3zimoScore = { id = "container,player3,zimoScore" },
    m_player3huScore = { id = "container,player3,huScore" },
    m_player3paoScore = { id = "container,player3,paoScore" },
    m_player3mingScore = { id = "container,player3,mingScore" },
    m_player3anScore = { id = "container,player3,anScore" },
    m_player3headIcon = { id = "container,player3,headIcon" },
    m_player3name = { id = "container,player3,name" },
    m_player3id = { id = "container,player3,id" },
    m_player3owner = { id = "container,player3,owner" },
    m_player3winner = { id = "container,player3,winner" },
    m_player3loser = { id = "container,player3,loser" },
    m_player3total = { id = "container,player3,total" },
    m_player4zimoScore = { id = "container,player4,zimoScore" },
    m_player4huScore = { id = "container,player4,huScore" },
    m_player4paoScore = { id = "container,player4,paoScore" },
    m_player4mingScore = { id = "container,player4,mingScore" },
    m_player4anScore = { id = "container,player4,anScore" },
    m_player4headIcon = { id = "container,player4,headIcon" },
    m_player4name = { id = "container,player4,name" },
    m_player4id = { id = "container,player4,id" },
    m_player4owner = { id = "container,player4,owner" },
    m_player4winner = { id = "container,player4,winner" },
    m_player4loser = { id = "container,player4,loser" },
    m_player4total = { id = "container,player4,total" },
}

function BattleOverUI4:onBack(sender)
    gameAssistant.playCloseUISound()
    UIStack.popUI()
    deskManager.exit()
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

function BattleOverUI4:onShare(sender)
    gameAssistant.playCloseUISound()
    local fileName = "CaptureScreen.png"
    cc.utils:captureScreen(afterCaptured, fileName)
end

function BattleOverUI4:onCreate(title, rule, stats)
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    self.m_desc:setString(title)
    self.m_rule:setString(rule)
    self.m_timestamp:setString(os.date("%Y-%m-%d %H:%M:%S"))
    for i = 1, #stats do
        local item = stats[i]
        local prefix = string.format("m_player%d", i)
        local zimoScore = self[prefix .. "zimoScore"]
        local huScore = self[prefix .. "huScore"]
        local paoScore = self[prefix .. "paoScore"]
        local mingScore = self[prefix .. "mingScore"]
        local anScore = self[prefix .. "anScore"]
        local headIcon = self[prefix .. "headIcon"]
        local name = self[prefix .. "name"]
        local id = self[prefix .. "id"]
        local owner = self[prefix .. "owner"]
        local winner = self[prefix .. "winner"]
        local loser = self[prefix .. "loser"]
        local total = self[prefix .. "total"]

        zimoScore:setString(item.ziMo)
        huScore:setString(item.hu)
        paoScore:setString(item.pao)
        mingScore:setString(item.mingGang)
        anScore:setString(item.anGang)
        headIcon:setTexture(deskManager.getPlayerData(i):getHeadIcon())
        headIcon:setScale(97 / headIcon:getContentSize().width)
        local nickname = item.account
        if utfstrlen(nickname) > 8 then
            nickname = string.format("%s...", subUTF8String(nickname, 1, 6))
        end
        name:setString(nickname)
        id:setString(string.format("ID:%d", item.uid))
        owner:setVisible(item.isCreator)
        winner:setVisible(item.isBigWinner)
        loser:setVisible(item.isPaoWang)
        local flag = item.totalScore > 0 and "+" or ""
        total:setString(string.format("%s%d", flag, item.totalScore))
    end
    printInfo("BattleOverUI:onCreate finished")
end

function BattleOverUI4:registEvent()
    printInfo("BattleOverUI:registEvent")
end

return BattleOverUI4