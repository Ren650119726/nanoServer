local dataManager = {}

local LoginDataClass = require "app.data.LoginData"
local PlayerDataClass = require "app.data.PlayerData"

dataManager.PlayerDataClass = PlayerDataClass

dataManager.typeDefine = require "app.data.typeDefine"

dataManager.loginData = LoginDataClass:create()
dataManager.playerData = PlayerDataClass:create()
dataManager.playerData:setAsSelf()

--- 来自服务器的数据
dataManager.serverData = {}

--- 广播消息
dataManager.broadcast = {}
dataManager.broadcast.messages = {}
dataManager.broadcast.next = function()
    local messages = dataManager.broadcast.messages
    if not messages or #messages < 1 then
        return "系统消息：健康游戏，禁止赌博, 欢迎举报"
    end

   return messages[math.random(1, #messages)]
end

dataManager.broadcast.append = function(msg)
    if msg ~= nil and #msg then
        table.insert(dataManager.broadcast.messages, msg)
    end
end

return dataManager
