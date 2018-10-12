-- send http request
local json = require "cocos.cocos2d.json"
local HttpRequest = {}

function HttpRequest.send(url, callback, postdata, requestType)
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_JSON
    local rtype = requestType or "POST"
    xhr:open(rtype, url)
    local function rcallback()
        --BlockLayer.hide()
        local response = xhr.response
        if response ~= "pong" then
            print("HTTP RESPONSE:", response)
        end
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            local httpStatusCode = xhr.statusText
            local response = xhr.response
            if string.len(response) < 2 then
                callback(false, response)
            else
                callback(true, response)
            end
        else
            print("xhr.readyState is:", xhr.readyState, "xhr.status is: ", xhr.status)
            callback(false)
        end
        xhr:unregisterScriptHandler()
    end

    xhr:registerScriptHandler(rcallback)
    xhr:send(postdata)
    --BlockLayer.show()
end

function HttpRequest.download(url, callback, postdata, requestType, fileName)
    local xhr = cc.XMLHttpRequest:new()
    xhr.responseType = cc.XMLHTTPREQUEST_RESPONSE_STRING
    local rtype = requestType or "POST"
    xhr:open(rtype, url)
    local function rcallback()
        local response = xhr.response
        if response ~= "pong" then
            print("HTTP RESPONSE:", response)
        end
        if xhr.readyState == 4 and (xhr.status >= 200 and xhr.status < 207) then
            local fileData = xhr.response
            cc.FileUtils:getInstance():createDirectory(cc.FileUtils:getInstance():getWritablePath() .. "avt/")
            local fullFileName = cc.FileUtils:getInstance():getWritablePath() .. "avt/" .. fileName
            printInfo("download fullFileName:%s", fullFileName)
            local file = io.open(fullFileName, "wb")
            file:write(fileData)
            file:close()
            cc.Director:getInstance():getTextureCache():addImage(fullFileName)
            callback(true, fullFileName)
        else
            print("xhr.readyState is:", xhr.readyState, "xhr.status is: ", xhr.status)
            callback(false)
        end
        xhr:unregisterScriptHandler()
    end

    xhr:registerScriptHandler(rcallback)
    xhr:send(postdata)
end

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
            resp.error = "网络错误，请检查网络是否正常"
        else
            resp = parseRecvStr(str, 1)
        end
        callback(resp)
    end

    method = method or "POST"
    HttpRequest.send(url, onResponse, data, method)
end

HttpRequest.Get = function(url, callback, data)
    httpRequest(url, callback, data, "GET")
end

return HttpRequest
