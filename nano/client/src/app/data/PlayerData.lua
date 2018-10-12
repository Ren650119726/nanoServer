local PlayerData = class("PlayerData")
local EventManager = require "app.core.EventManager"
local basic = require "app.core.basic"
local HttpRequest = require "app.network.HttpRequest"

event_name.PLAYERDATA_NICKNAME_CHANGED = "playerData_nickname_changed"
event_name.PLAYERDATA_HEADICON_CHANGED = "playerData_headIcon_changed"
event_name.PLAYERDATA_CARD_COUNT_CHANGED = "PLAYERDATA_CARD_COUNT_CHANGED"
event_name.PLAYERDATA_SCORE_CHANGED = "playerData_score_changed"

function PlayerData:ctor(acId)
    self.headUrl = ""
    self.nickname = "无名氏"
    self.m_headIcon = ""
    self.acId = acId
    self.isSelf = false
    self.isExit = false
    self.score = 1000
    self.fangka = 0
    self.totalScoreChange = 0
    self.piao = 0
    self.ip = "127.0.0.1"
    basic.bindAccessFunc(self, "m_userSex", nil, "UserSex", true, true)
end

function PlayerData:setAsSelf()
    self.isSelf = true
end

function PlayerData:dispathcEvent(_name, _oldvalue, _newvalue)
    if not self.isSelf then
        return
    end
    if _oldvalue ~= _newvalue then
        EventManager:dispatchEvent({ name = _name, oldValue = _oldvalue, newValue = _newvalue })
    end
end

-- 昵称
function PlayerData:setNickname(name)
    local old = self.nickname
    self.nickname = name
    self:dispathcEvent(event_name.PLAYERDATA_NICKNAME_CHANGED, old, name)
end

function PlayerData:getNickname()
    return self.nickname
end

function PlayerData:getId()
    return "ID:" .. self.acId
end

-- 头像
function PlayerData:setHeadIcon(headURL, uid)
    self.headUrl = headURL
    local old = self.m_headIcon
    self.m_headIcon = "images/common/WeChatKWX_UserFaceBg.png"
    if headURL and #headURL > 1 then
        local gameAssistant = require "app.logic.gameAssistant"
        local writablePath = cc.FileUtils:getInstance():getWritablePath() .. "avt/"
        local fileName = string.format("head-%s_%d.png", gameAssistant.getUrlFileName(headURL, "/"), uid)
        local localPath = string.format("%s/%s", writablePath, fileName)
        printInfo("localpath ===> %s", localPath)
        local file = io.open(localPath, "r")
        if file then
            file:close()
            self.m_headIcon = localPath
            EventManager:dispatchEvent({ name = event_name.PLAYERDATA_HEADICON_CHANGED, a = old, head = self.m_headIcon, id = uid })
        else
            local onResponse = function(success, fullpath)
                if success then
                    self.m_headIcon = fullpath
                    EventManager:dispatchEvent({ name = event_name.PLAYERDATA_HEADICON_CHANGED, a = old, head = self.m_headIcon, id = uid })
                end
            end
            HttpRequest.download(headURL, onResponse, "", "GET", fileName)
        end
    end
end

function PlayerData:getHeadIcon()
    return self.m_headIcon
end

-- 账号ID
function PlayerData:getAcId()
    return self.acId
end

function PlayerData:setAcId(id)
    self.acId = id
end

function PlayerData:getIp()
    return self.ip
end

function PlayerData:setIp(ip)
    self.ip = ip
end

-- 积分
function PlayerData:getScore()
    return self.score
end

function PlayerData:setScore(score)
    local old = self.score
    self.score = score
    EventManager:dispatchEvent({ name = event_name.PLAYERDATA_SCORE_CHANGED, score = score, acid = self.acId })
end

function PlayerData:scoreChange(diff, type)
end

function PlayerData:setCardCount(n)
    local old = self.fangka
    self.fangka = n
    self:dispathcEvent(event_name.PLAYERDATA_CARD_COUNT_CHANGED, old, n)
end

function PlayerData:getCardCount(n)
    return self.fangka
end

function PlayerData:getPiao()
    return self.piao
end

function PlayerData:getHeadUrl()
    return self.headUrl
end

return PlayerData
