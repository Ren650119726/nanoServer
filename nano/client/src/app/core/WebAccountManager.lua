local HttpRequest = require "app.network.HttpRequest"
local appConfig = require "appConfig"

local WebAccountManager = {}
local channelId = appConfig.channelId
local appId = appConfig.appId
local guestLoginUrl = appConfig.guestLogin
local thirdLoginUrl = appConfig.thirdLogin

local function parseRecvStr(str)
    if string.len(str) < 2 then
        return { code = 1000002, error = "json decode error" }
    end
    return json.decode(str, 1)
end

local function httpRequest(url, callback, data, method)
    local function onResponse(ok, str)
        local resp = {}
        if not ok then
            resp.code = 1000001
            resp.error = "网络连接失败"
        else
            resp = parseRecvStr(str, 1)
        end
        callback(resp)
    end

    method = method or "POST"
    HttpRequest.send(url, onResponse, data, "POST")
end

function WebAccountManager.wechatSignIn(callback, wechatInfo)
    local function onResponse(data)
        callback(data)
    end
    local payload = {}
    payload.platform = "wechat"
    payload.appId = appId
    payload.channelId = channelId
    payload.name = wechatInfo.name
    payload.openid = wechatInfo.openid
    payload.access_token = wechatInfo.access_token
    local request = json.encode(payload)
    httpRequest(thirdLoginUrl, onResponse, request, "POST")
end

function WebAccountManager.guestSignIn(callback, deviceId)
    local onResponse = function(data)
        callback(data)
    end
    local payload = {}
    payload.appId = appId
    payload.channelId = channelId
    payload.imei = deviceId
    local request = json.encode(payload)
    httpRequest(guestLoginUrl, onResponse, request, "POST")
end

return WebAccountManager
