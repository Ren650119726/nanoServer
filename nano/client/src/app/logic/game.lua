--- 游戏主模块
---
--- 控制游戏生命周期, 处理由WEB服务器登录后的流程
---
--- @version : 0.0.1
--- @author : Chris Lonng
--- @create : 2016.12.01
--- @modify : 2016.12.02

cc.exports.dataManager = require "app.data.dataManager"
cc.exports.configManager = require "app.config.configManager"

local networkManager = require "app.network.NetworkManager"
local packetHandler = require "app.network.packetHandler"

local game = {}
game.isFromLogin = true

function game.login(data, preUIClass, callback)
    dataManager.loginData:setUid(data.uid)
    dataManager.loginData:setName(data.name)
    dataManager.playerData:setIp(data.playerIp)
    dataManager.playerData:setHeadIcon(data.headUrl, data.uid)

    dataManager.serverData.clubList = data.clubList

    --- 广播消息
    dataManager.broadcast.messages = data.messages

    --- 设置远程配置
    configManager.systemConfig = data.config

    --- 调试相关
    configManager.debug.permission = data.debug == 1

    networkManager.init(data.ip, data.port)
    local name = data.name
    local uid = data.uid
    local headUrl = data.headUrl
    local sex = data.sex
    local fangka = data.fangka
    local playerIp = data.playerIp

    local function loginCallback(data)
        game.onLogin(data, preUIClass)
    end

    local payload = {
        name = name,
        uid = uid,
        headUrl = headUrl,
        sex = sex,
        fangka = fangka,
        ip = playerIp
    }

    networkManager.request("Manager.Login", payload, loginCallback)
end

function game.onLogin(data, preUIClass)
    game.preUIClass = preUIClass

    dataManager.playerData:setNickname(data.nickname)
    dataManager.playerData:setAcId(data.acId)
    dataManager.playerData:setCardCount(data.fangka)
    dataManager.playerData:setHeadIcon(data.headURL, data.acId)
    dataManager.playerData:setUserSex(data.sex)
    game.enter()
end

function game.enter(preUIClass)
    -- 注册消息处理函数
    packetHandler.globalRegister()

    if preUIClass then game.preUIClass = preUIClass end
    local lobbyUI = require "app.ui.Lobby"
    lobbyUI:create():showWithScene()
end

function game.exit()
    if game.preUIClass then
        game.preUIClass:create():showWithScene(false)
    end
end

return game
