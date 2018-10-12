require "app.core.BabeOutput"
require "app.core.LuaCustomEvent"
require "app.core.audioEngine"
require "app.core.LocalRecord"
require "socket"
require "app.core.stack"

math.randomseed(os.time())

audioEngine.enableBackgroundMusic(LocalRecord.instance():getProperty("sound"))
audioEngine.enableEffect(LocalRecord.instance():getProperty("effect"))


local function formatTime()
    return (os.date("_%Y-%m-%d_ %X"))
end

if DEBUG > 0 then
    local _assert = assert
    assert = function(v, msg)
        msg = msg or "assertion failed!"
        if not v then
            ccextplatform.MessageBox(formatTime() .. '\n' .. msg)
        end
        msg = "lua_assert:" .. msg
        return _assert(v, msg)
    end
    local _error = error
    error = function(msg, level)
        ccextplatform.MessageBox(formatTime() .. '\n' .. msg, "error")
        return _error(msg, level)
    end
end

__G__TRACKBACK__ = function(msg)
    local msg = debug.traceback(msg, 3)
    print(msg)
    if DEBUG > 0 then
        ccextplatform.MessageBox(formatTime() .. '\n' .. msg, "__G__TRACKBACK__")
    end
    return msg
end

local _loadstring = loadstring
loadstring = function(s, name)
    name = name or "loadstring_chunk_name"
    return ccextplatform.loadBuffer(s, name)
end


-- 获取utf8编码字符串长度，中文长度为1
function utfstrlen(str)
    if not str then
        return 0
    end

    local len = #str;
    local left = len;
    local cnt = 0;
    local arr = { 0, 0xc0, 0xe0, 0xf0, 0xf8, 0xfc };
    while left ~= 0 do
        local tmp = string.byte(str, -left);
        local i = #arr;
        while arr[i] do
            if tmp >= arr[i] then left = left - i; break; end
            i = i - 1;
        end
        cnt = cnt + 1;
    end
    return cnt;
end


--截取中英文混合字符串
--参数
--  string str  原始字符串
--  number start 起始位置，注意中文长度为1
--  number len  截取长度
--返回值
--  string 截取后的字符串
--备注
--  1)中文UTF8默认占3个字节，可能对于一些占2个或4个字节的中文处理有问题
--  2)回车\n等特殊控制字符也算一个长度
function subUTF8String(str, start, len)
    local firstResult = ""
    local strResult = ""
    local maxLen = string.len(str)
    start = start - 1
    --找到起始位置
    local preSite = 1
    if start > 0 then
        for i = 1, maxLen do
            local s_dropping = string.byte(str, i)
            if not s_dropping then
                local s_str = string.sub(str, preSite, i - 1)
                preSite = i + 1
                break
            end


            if s_dropping < 128 or (i + 1 - preSite) == 3 then
                local s_str = string.sub(str, preSite, i)
                preSite = i + 1
                firstResult = firstResult .. s_str
                local curLen = utfstrlen(firstResult)
                if (curLen == start) then
                    break
                end
            end
        end
    end


    --截取字符串
    preSite = string.len(firstResult) + 1
    local startC = preSite
    for i = startC, maxLen do
        local s_dropping = string.byte(str, i)
        if not s_dropping then
            local s_str = string.sub(str, preSite, i - 1)
            preSite = i
            strResult = strResult .. s_str
            return strResult
        end


        if s_dropping < 128 or (i + 1 - preSite) == 3 then
            local s_str = string.sub(str, preSite, i)
            preSite = i + 1
            strResult = strResult .. s_str
            local curLen = utfstrlen(strResult)
            if (curLen == len) then
                return strResult
            end
        end
    end

    return strResult
end