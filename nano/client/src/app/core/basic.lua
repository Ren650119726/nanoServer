local basic = {}
local silverSplitCount = 4
local significantDigit = 4
local zeroCode = string.byte("0")
local negCode = string.byte("-")
local updaterHelper = ccluaext.UpdaterHelper:getInstance(6, 4, '.tmp')
local updater = require "app.updater.updater"
local appConfig =  require "appConfig"

function callFunctionAfterTime(time, node, handler)
    local delay = cc.DelayTime:create(time)
    local callback = cc.CallFunc:create(handler)
    local action = node:runAction(cc.Sequence:create({delay, callback}))
    return action
end

function uploadFile(url, filename, fileType, handler)
    local utils = cc.FileUtils:getInstance()
    local fullPath = utils:fullPathForFilename(filename)
    local isExist = utils:isFileExist(fullPath)
    if isExist then
        local tmp = ccluaext.UploadFile:create(url)
        tmp:addFormFile("file", fullPath, fileType)
        tmp:addFormContents("act", "upload")
        tmp:registerScriptHandler(function(isok, code, data, header, errorMsg)
            handler(isok, code, data, header, errorMsg)
        end)
        tmp:perform()
    end
end

function table.push(t, v)
    t[#t + 1] = v
end
function table.count(t, v, fn)
    if not fn then
        fn = function (t1, _v) return t1 == _v end
    end
    local cn = 0
    for _, _v in pairs(t) do
        if fn(_v, v) then
            cn = cn + 1
        end
    end
    return cn
end

local function splitStrByCount(str, splitCount)
    local ta = {}
    local len = string.len(str)
    local firstLen = len % splitCount
    local count = math.floor(len / splitCount)
    if firstLen > 0 then
        table.push(ta, string.sub(str, 1, firstLen))
    end
        
    for i = 1, count do
        local startIdx = firstLen + (i - 1) * splitCount + 1
        local endIdx = startIdx + splitCount - 1
        local pushStr = string.sub(str, startIdx, endIdx)
        table.push(ta, pushStr)
    end 
    return ta
end

--a method show convert silver to visual string.
function scoreToString(coin, hasUnit)
    local oriStr = tostring(coin)
    local len = string.len(oriStr)
    local pre = ""
    if string.byte(oriStr, 1) == negCode then
        pre = "-"
        oriStr = string.sub(oriStr, 2)
    end
    if not hasUnit then
        if len <= silverSplitCount then
            return pre .. oriStr
        else
            local ta = splitStrByCount(oriStr, silverSplitCount)
            ta[1] = pre .. ta[1]
            return table.concat(ta, ",")
        end
    else
        if len <= 4 then
            return pre .. oriStr
        end
        local ta = splitStrByCount(oriStr, 4)
        local tableLen = #ta
        local unitValue = ""
        local unitPos = 2
        if tableLen == 2 then
            unitValue = "万"
        elseif tableLen == 3 then
            unitValue = "亿"
        elseif tableLen == 4 then
            unitValue = "千亿"
        end
        local tmpLen = string.len(ta[1])
        local left = significantDigit - tmpLen
        if left ~= 0 then
            local ta2 = ta[2]
            for i = left, 1, -1 do
                if string.byte(ta2, i) ~= zeroCode then
                    break
                end 
                left = left - 1
            end
            if left ~= 0 then
                local tstr = string.sub(ta2, 1, left)
                ta[2] = "."
                ta[3] = tstr
                unitPos = 4
            end
        end
        ta[unitPos] = unitValue
        ta[unitPos + 1] = nil
        table.insert(ta, 1, pre)
        return table.concat(ta, "")
    end
    return pre .. oriStr
end

function toUpperString(value)
    return string.upper(tostring(value))
end

local function _findCombination(a, m, n, ret)
	if n == 0 then
		coroutine.yield(ret)
		return
	end
	while m >= n do
		ret[n] = a[m]
		find(a, m - 1, n - 1, ret)
		m = m - 1
	end
end

--findCombination(a, 3)
local function findCombination(a, n)
	local ret = {}
	co = coroutine.create(function() find(a, #a, n, ret) end)
	return function(task)
		local isok, output = coroutine.resume(task)
		return output
	end, co
end

function dump(object, label, isReturnContents, nesting)
    if type(nesting) ~= "number" then nesting = 99 end

    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local traceback = string.split(debug.traceback("", 2), "\n")
    echo("dump from: " .. string.trim(traceback[3]))

    local function _dump(object, label, indent, nest, keylen)
        label = label or "<var>"
        spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(_v(label)))
        end
        if type(object) ~= "table" then
            result[#result +1 ] = string.format("%s%s%s = %s", indent, _v(label), spc, _v(object))
        elseif lookupTable[object] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, label, spc)
        else
            lookupTable[object] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, label)
            else
                result[#result +1 ] = string.format("%s%s = {", indent, _v(label))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(object) do
                    keys[#keys + 1] = k
                    local vk = _v(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    _dump(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    _dump(object, label, "- ", 1)

    if isReturnContents then
        return table.concat(result, "\n")
    end

    for i, line in ipairs(result) do
        echo(line)
    end
end

function createLabel(text, fontsize, alignment, maxwidth, fontname)
    local ttfConfig = {}
    text = text or ""
    ttfConfig.fontFilePath = fontname or "fonts/simhei.ttf"
    ttfConfig.fontSize = fontsize or 30
    alignment = alignment or 0
    maxwidth = maxwidth or 0
    return cc.Label:createWithTTF(ttfConfig, text, alignment, maxwidth)
end

function vardump(object, label)
    local lookupTable = {}
    local result = {}

    local function _v(v)
        if type(v) == "string" then
            v = "\"" .. v .. "\""
        end
        return tostring(v)
    end

    local function _vardump(object, label, indent, nest)
        label = label or "<var>"
        local postfix = ""
        if nest > 1 then postfix = "," end
        if type(object) ~= "table" then
            if type(label) == "string" then
                result[#result +1] = string.format("%s%s = %s%s", indent, label, _v(object), postfix)
            else
                result[#result +1] = string.format("%s%s%s", indent, _v(object), postfix)
            end
        elseif not lookupTable[object] then
            lookupTable[object] = true

            if type(label) == "string" then
                result[#result +1 ] = string.format("%s%s = {", indent, label)
            else
                result[#result +1 ] = string.format("%s{", indent)
            end
            local indent2 = indent .. "    "
            local keys = {}
            local values = {}
            for k, v in pairs(object) do
                keys[#keys + 1] = k
                values[k] = v
            end
            table.sort(keys, function(a, b)
                if type(a) == "number" and type(b) == "number" then
                    return a < b
                else
                    return tostring(a) < tostring(b)
                end
            end)
            for i, k in ipairs(keys) do
                _vardump(values[k], k, indent2, nest + 1)
            end
            result[#result +1] = string.format("%s}%s", indent, postfix)
        end
    end
    _vardump(object, label, "", 1)

    return table.concat(result, "\n")
end

local fileutils = cc.FileUtils:getInstance() 
function basic.readFile(path)
    return fileutils:getDataFromFile(path)
end

function basic.isFileExists(path)
    return fileutils:isFileExist(path)
end

function basic.isDirExists(path)
    return fileutils:isDirectoryExist(path)
end

function basic.writeFile(path, content, mode)
    mode = mode or "wb"
    local file = io.open(path, mode)
    if file then
        if file:write(content) == nil then return false end
        io.close(file)
        return true
    else
        return false
    end
end

function basic.bindAccessFunc(classname, varname, default, funcname, set, get, modify)
    classname[varname] = default
    if set then
        classname["set"..funcname] = function(c, v) 
            c[varname] = v
        end
    end
    if get then
        classname["get"..funcname] = function(c)
            return c[varname]
        end
    end
    if modify then
        classname["modify"..funcname] = function(c, v)
            c[varname] = c[varname] + v
            return c[varname]
        end
    end
end

local function escape(k)
    local ret = k
    if type(ret) ~= "string" then
        ret = tostring(ret)
    end
    ret = string.gsub(k, "[&=+%%%c]", function (c)
        return string.format("%%%02X", string.byte(c))
    end)
    ret = string.gsub(ret, " ", "+")
    return ret
end

function basic.encodeURL(t)
    local b = {}
    for k, v in pairs(t) do
        b[#b + 1] = (escape(k) .. "=" .. escape(v))
    end
    return table.concat(b, "&")
end 

function basic.concat(t, space, orderT)
    local b = {}
    if not orderT then
        for k, v in pairs(t) do
            b[#b + 1] = v
        end
    else
        for i, v in ipairs(orderT) do
            local tv = t[v]
            if tv then
                b[#b + 1] = tv
            end
        end
    end
    return table.concat(b, space)
end

function basic.getMD5(t, orderT)
    local str = basic.concat(t, "", orderT)
    str = str .. "68475F71B9E447AC8D2E9962246DD295"
    printInfo("getMD5 " .. str)
    return crypto.md5(str)
end

local key = "68475F71B9E447AC8D2E9962246DD295"
function basic.getAESCode(input)
    return crypto.encrypt(input, key, 256)
end 
function basic.getPWCode(input)
    return crypto.decrypt(input, key, 256)
end 

function table.bubbleSort(t, comp, len)
    if not comp then
        comp = function (a1, a2)
            return a1 < a2
        end
    end
    len = len or #t

    local s = len - 1
    local e = len - 1
    local tmp
    for j = 1, e do 
        s = len - j
        for i = s, e do
            if not comp(t[i], t[i + 1]) then
                tmp = t[i + 1]
                t[i + 1] = t[i]
                t[i] = tmp
            else 
                break
            end
        end
    end
end

function basic.getDeviceId()
    if appConfig.deviceId then
        return appConfig.deviceId
    end
    return ccextplatform.getDeviceId()
--    return "test_2016041916-PC"
end

function basic.openExplore(url)
    return ccextplatform.openExplore(url)
end

local Node = cc.Node

function Node:callFunctionAfterTime(time, handler)
    local args = {}
    args.delay = time
    args.onComplete = function()
        handler()
    end
    transition.execute(self, nil, args)
end

SECOND_PER_MIN = 60
SECOND_PER_HOUR = 60 * SECOND_PER_MIN
SECOND_PER_DAY = 24 * SECOND_PER_HOUR

return basic
