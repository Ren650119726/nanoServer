local gameAssistant = require "app.logic.gameAssistant"
local CreateRoomUI = class("CreateRoomUI", cc.load("mvc").ViewBase)
local stringDefine = require "app.data.stringDefine"
local UIStack = require "packages.mvc.UIStack"
local dataManager = require "app.data.dataManager"
local PushWindow = require "app.ui.PushWindow"
local deskEnterHelper = require "app.logic.deskEnterHelper"
local WaitUI = require "app.ui.WaitUi"
local ContactUI = require "app.ui.ContactUI"
local LocalRecord = require "app.core.LocalRecord"

CreateRoomUI.RESOURCE_FILENAME = "layout/create_room.csb"
CreateRoomUI.RESOURCE_BINDING = {
    close = { id = "close", onClick = "onClose" },
    --- 选择自摸玩法
    mode3 = { id = "mode,m3", onClick = "onSwithMode" },
    mode4 = { id = "mode,m4", onClick = "onSwithMode" },

    --- 轮数
    roundCount4 = { id = "round,r4", onClick = "onRoundCountClick" },
    roundCount8 = { id = "round,r8", onClick = "onRoundCountClick" },
    roundCount16 = { id = "round,r16", onClick = "onRoundCountClick" },
    --- 选择自摸玩法
    zimo1 = { id = "zimo,fan", onClick = "onSwithZimo" },
    zimo2 = { id = "zimo,di", onClick = "onSwithZimo" },

    --- 选择玩法（3/4/5番封顶）
    maxFan3 = { id = "max_fan,f3", onClick = "onMaxFanSwitch" },
    maxFan4 = { id = "max_fan,f4", onClick = "onMaxFanSwitch" },
    maxFan5 = { id = "max_fan,f5", onClick = "onMaxFanSwitch" },
    _create = { id = "create", onClick = "onCreateRoom" },
    --- 额外选项
    m_menqing = { id = "rules,menqing", onClick = "onCheckBoxSelected" },
    m_jiangdui = { id = "rules,jiangdui", onClick = "onCheckBoxSelected" },
    m_jiaxin = { id = "rules,jiaxin", onClick = "onCheckBoxSelected" },
    m_pengpeng = { id = "rules,pengpeng", onClick = "onCheckBoxSelected" },
    m_pinghu = { id = "rules,pinghu", onClick = "onCheckBoxSelected" },
    m_yaojiu = { id = "rules,yaojiu", onClick = "onCheckBoxSelected" },
}

local selectedColor = cc.c3b(98, 50, 16)
local unselectedColor = cc.c3b(73, 141, 196)
local rounds = { 4, 8, 16 }
local fans = { 3, 4, 5 }

local function changeSelectStatus(node, selected)
    node:setSelected(selected)
    if not selected then
        node:getChildByName("name"):setTextColor(unselectedColor)
    else
        node:getChildByName("name"):setTextColor(selectedColor)
    end
end

--- 关闭按钮
function CreateRoomUI:onClose()
    self.gameAssistant.playCloseUISound()
    UIStack.popUI()
end

--- 选择局数
function CreateRoomUI:onRoundCountClick(sender)
    self.gameAssistant.playBtnClickedSound()
    local name = sender:getName()
    for _, r in ipairs(rounds) do
        if name == string.format("r%d", r) then
            self.options.round = r
        end
        changeSelectStatus(self[string.format("roundCount%d", r)], false)
    end
    changeSelectStatus(sender, true)
end

--- 选择玩法选项
function CreateRoomUI:onSwithMode(sender)
    self.gameAssistant.playBtnClickedSound()
    local name = sender:getName()
    for i = 3, 4 do
        if name == string.format("m%d", i) then
            self.options.mode = i
        end
        local nodeName = "mode" .. i
        changeSelectStatus(self[nodeName], false)
    end
    -- 三人模式才显示平胡选项
    self.m_pinghu:setVisible(self.options.mode == 3)
    changeSelectStatus(sender, true)
end

--- 选择自摸选项
function CreateRoomUI:onSwithZimo(sender)
    self.gameAssistant.playBtnClickedSound()
    local name = sender:getName()
    self.options.zimo = name
    for i = 1, 2 do
        local nodeName = "zimo" .. i
        changeSelectStatus(self[nodeName], false)
    end
    changeSelectStatus(sender, true)
end

--- 选择封顶番数
function CreateRoomUI:onMaxFanSwitch(sender)
    self.gameAssistant.playBtnClickedSound()
    local name = sender:getName()
    for _, r in ipairs(fans) do
        if name == string.format("f%d", r) then
            self.options.maxFan = r
        end
        changeSelectStatus(self[string.format("maxFan%d", r)], false)
    end
    changeSelectStatus(sender, true)
end

function CreateRoomUI:requireCard()
    local round = self.options.round
    if round <= 4 then
        return 2
    else
        return 3
    end
end

--- 创建房间
function CreateRoomUI:onCreateRoom(sender)
    self.gameAssistant.playBtnClickedSound()
    local n = dataManager.playerData:getCardCount()
    if self.clubId < 0 and n < self:requireCard() then
        local function charge()
            UIStack.popUI()
            local ui = ContactUI:create("", "", self.gameAssistant)
            UIStack.pushUI(ui)
        end

        local windowTable = { title = "房卡不足, 是否前往获取房卡", yes = { title = "确定", fun = charge }, no = { title = "取消", fun = function() end } }
        local ui = PushWindow:create("", "", windowTable)
        UIStack.pushUI(ui)
    else
        local payload = { version = appConfig.version, clubId=self.clubId, options = self.options }
        LocalRecord.instance():setProperty(stringDefine.PREVIOUR_OPTION, self.options)
        printInfo(json.encode(payload))
        local networkManager = require "app.network.NetworkManager"
        networkManager.request("DeskManager.CreateDesk", payload, function(resp)
            UIStack.popUI()
            if resp.code > 0 then
                gameAssistant.showHintAlertUI(resp.error)
            else
                printInfo("CreateRoomResult: %s", json.encode(resp.tableInfo))
                deskEnterHelper.enterClassicMatch(resp.tableInfo)
                WaitUI.show()
            end
        end)
    end
end

--- 控制所有的复选框
function CreateRoomUI:onCheckBoxSelected(sender)
    local selected = sender:isSelected()
    --sender:getChildByName("name"):setTextColor(selected and selectedColor or unselectedColor)
    self.options[sender:getName()] = selected
end

--- 创建初始化函数
function CreateRoomUI:onCreate(gameAssistant, clubId)
    self.clubId = clubId
    self.options = {
        mode = 3,
        round = 8,
        maxFan = 3,
        zimo = "di" -- 自摸加底
    }

    self.gameAssistant = gameAssistant
    self.root:setPosition(display.center)
    self:addABlockLayer(true, 130)
    self.root:ignoreAnchorPointForPosition(true)
    self.root:setAnchorPoint(cc.p(0.5, 0.5))

    local oldoptions = LocalRecord.instance():getProperty(stringDefine.PREVIOUR_OPTION)
    if oldoptions ~= nil then
        self.options = oldoptions
        -- 最大番数
        if self.options.maxFan ~= nil then
            for _, r in ipairs(fans) do
                changeSelectStatus(self[string.format("maxFan%d", r)], false)
            end
            changeSelectStatus(self[string.format("maxFan%d", self.options.maxFan)], true)
        end

        -- 局数
        if self.options.round ~= nil then
            for _, r in ipairs(rounds) do
                changeSelectStatus(self[string.format("roundCount%d", r)], false)
            end
            changeSelectStatus(self[string.format("roundCount%d", self.options.round)], true)
        end

        -- 玩法选项
        if self.options.mode ~= nil then
            for i = 3, 4 do
                local nodeName = "mode" .. i
                changeSelectStatus(self[nodeName], false)
            end
            changeSelectStatus(self[string.format("mode%d", self.options.mode)], true)
        end
        -- 三人模式才显示平胡选项
        self.m_pinghu:setVisible(self.options.mode == 3)

        -- 自摸加底/加番
        for i = 1, 2 do
            local nodeName = "zimo" .. i
            changeSelectStatus(self[nodeName], false)
        end
        local zimo = self.options.zimo == "fan" and "zimo1" or "zimo2"
        changeSelectStatus(self[zimo], true)

        -- 其他选项
        if self.options.menqing then
            local node = self[string.format("m_menqing")]
            node:setSelected(true)
        end
        if self.options.jiangdui then
            local node = self[string.format("m_jiangdui")]
            node:setSelected(true)
        end
        if self.options.jiaxin then
            local node = self[string.format("m_jiaxin")]
            node:setSelected(true)
        end
        if self.options.pengpeng then
            local node = self[string.format("m_pengpeng")]
            node:setSelected(true)
        end
        if self.options.pinghu then
            local node = self[string.format("m_pinghu")]
            node:setSelected(true)
        end
        if self.options.yaojiu then
            local node = self[string.format("m_yaojiu")]
            node:setSelected(true)
        end

        print("======", json.encode(oldoptions))
    end
end

return CreateRoomUI