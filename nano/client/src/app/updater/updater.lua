local luaCustomEvent = require('app.core.LuaCustomEvent')
local updater = {}
local lfs = require('lfs')
local json = require "cocos.cocos2d.json"
local patch = require "app.version.patch"

-- 系统平台常量
local const = {}
const.PLATFORM_OS_WINDOWS = 0
const.PLATFORM_OS_LINUX = 1
const.PLATFORM_OS_MAC = 2
const.PLATFORM_OS_ANDROID = 3
const.PLATFORM_OS_IPHONE = 4
const.PLATFORM_OS_IPAD = 5
const.PLATFORM_OS_BLACKBERRY = 6
const.PLATFORM_OS_NACL = 7
const.PLATFORM_OS_EMSCRIPTEN = 8
const.PLATFORM_OS_TIZEN = 9
const.PLATFORM_OS_WINRT = 10
const.PLATFORM_OS_WP8 = 11

local customDownloadHandler = {}
function updater.clone(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for key, value in pairs(object) do
            new_table[_copy(key)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end

    return _copy(object)
end

local fileutils = cc.FileUtils:getInstance()
function updater.readFile(path)
    return fileutils:getDataFromFile(path)
end

function updater.isFileExists(path)
    return fileutils:isFileExist(path)
end

function updater.isDirExists(path)
    return fileutils:isDirectoryExist(path)
end

function updater.mkdir(path)
    if not updater.isDirExists(path) then
        --return lfs.mkdir(path)
        return fileutils:createDirectory(path)
    end
    return true
end

--updater.mkdir(fileutils:getWritablePath() .. "test")

function updater.rmdir(path)
    print("updater.rmdir:", path)

    local app = cc.Application:getInstance()
    local target = app:getTargetPlatform()
    if target == 0 then
        fileutils:removeDirectory(path)
        return
    end

    local ret, des = lfs.rmdir(path)
    if updater.isDirExists(path) then
        print('do rm dir=============')
        local function _rmdir(path)
            local iter, dir_obj = lfs.dir(path)
            while true do
                local dir = iter(dir_obj)
                if dir == nil then break end
                if dir ~= "." and dir ~= ".." then
                    local curDir = path .. dir
                    local mode = lfs.attributes(curDir, "mode")
                    if mode == "directory" then
                        _rmdir(curDir .. "/")
                    elseif mode == "file" then
                        os.remove(curDir)
                    end
                end
            end
            local succ, des = lfs.rmdir(path) --os.remove(path)
            if des then print(des) end
            return succ
        end

        _rmdir(path)
    end
    return true
end

--updater.rmdir(fileutils:getWritablePath() .. "tt/")

function updater.writeFile(path, content, mode)
    --    mode = mode or "wb"
    --    local file = io.open(path, mode)
    --    if file then
    --        if file:write(content) == nil then return false end
    --        io.close(file)
    --        return true
    --    else
    --        return false
    --    end
    fileutils:writeStringToFile(content, path)
end

local writablePath = fileutils:getWritablePath()
local tmpdir = writablePath .. 'tmp/'
local reversionFile = tmpdir .. "version.json"
local reversionPatch = "__version_patch__"
local hotfixDir = writablePath .. "hotfix/"

local updaterHelper = ccluaext.UpdaterHelper:getInstance(6, 4, '.tmp')

--this value must be clear
local checkUpdateHandler
local updateCompleteHander
local updateProcessHander

function updater.clear()
    checkUpdateHandler = nil
    updateCompleteHander = nil
    updateProcessHander = nil
end

function updater.registerEventCallback()
    luaCustomEvent.registerEventHandle(9, function(proto)
        local url = proto:readString()
        local storagePath = proto:readString()
        local filename = proto:readString()
        local errorCode = proto:readInt()
        local errorCodeInternal = proto:readInt()
        local errorMsg = proto:readString()
        print('===============ontaskerror:url:%s, sotagePath:%s', url, storagePath)
        print('===============ontaskerror', 'codeInternal', errorCodeInternal, 'msg', errorMsg)
        if filename == reversionPatch then
            updater.checkPatchVersion(storagePath, false)
        else
            updater.onPatchDownload(storagePath, false)
        end
    end)

    luaCustomEvent.registerEventHandle(10, function(proto)
        print('===============ontaskprocess==================')
        local totalSize = (proto:readInt())
        local curSize = (proto:readInt())
        local filename = (proto:readString())
        if filename == reversionPatch then
        elseif customDownloadHandler[filename] then
        else
            print('curSize', curSize, 'totalSize', totalSize)
            if updateProcessHander then updateProcessHander(curSize, totalSize) end
        end
    end)

    luaCustomEvent.registerEventHandle(11, function(proto)
        print('===============ontasksuccess==================')
        local url = proto:readString()
        local storagePath = proto:readString()
        local filename = proto:readString()
        if filename == reversionPatch then
            updater.checkPatchVersion(storagePath, true)
        else
            updater.onPatchDownload(storagePath, true)
        end
    end)
end

local function downloadVersionFile(url)
    updater.mkdir(tmpdir)
    print("start download remote version file: %s", url)
    url = url .. '?ts=' .. tostring(os.time())
    updaterHelper:downloadFile(url, reversionFile, reversionPatch)
end

local function downloadPatch(url, filename)
    local storagePath = tmpdir .. filename
    updaterHelper:downloadFile(url, storagePath, filename)
end

function updater.checkHasUpdate(callback)
    updater.clear()
    updater.registerEventCallback()
    local remoteUrl = appConfig.revinfoURL
    downloadVersionFile(remoteUrl)
    checkUpdateHandler = callback
end

function updater.platform()
    local app = cc.Application:getInstance()
    return app:getTargetPlatform()
end

function updater.checkPatchVersion(path, success)
    local hasUpdate = false
    local forceUpdate = false
    local updateURL = ""
    if success then
        local content = updater.readFile(path)
        print("==============检查热更=================")
        print("==> 文件路径", path, updater.isFileExists(path))
        local versionInfo = json.decode(content)
        print("==> 本地版本号", appConfig.version)
        print("==> 远程版本号", versionInfo.version)
        print("==> 本地补丁号", patch.patch)
        print("==> 远程补丁号", versionInfo.patch)
        print("==> 补丁地址", versionInfo.download)

        -- 本地版本与远程版本必须大版本号一致，并且远程补丁号大于本地补丁号才能热更
        if versionInfo.version ~= appConfig.version then
            local platform = updater.platform()
            print("========发现强更版本=======", platform)
            print("====> platform", const.PLATFORM_OS_IPHONE, const.PLATFORM_OS_IPAD, const.PLATFORM_OS_ANDROID)
            print("====> android", versionInfo.android, platform == const.PLATFORM_OS_ANDROID)
            print("====> ios", versionInfo.ios, platform == const.PLATFORM_OS_IPHONE or platform == const.PLATFORM_OS_IPAD)
            print("====> mac", versionInfo.ios, platform == const.PLATFORM_OS_MAC)
            if platform == const.PLATFORM_OS_ANDROID and versionInfo.android then
                forceUpdate = true
                updateURL = versionInfo.android
            elseif (platform == const.PLATFORM_OS_IPHONE or platform == const.PLATFORM_OS_IPAD) and versionInfo.ios then
                forceUpdate = true
                updateURL = versionInfo.ios
            end
        elseif versionInfo.patch > patch.patch then
            hasUpdate = true
            updateURL = versionInfo.download
        end
    end
    if not hasUpdate then
        updater.rmdir(tmpdir)
    end
    checkUpdateHandler(hasUpdate, forceUpdate, updateURL)
end

function updater.onPatchDownload(path, success)
    if success then
        -- 如果之前存在补丁，则移除之前的补丁文件夹
        if updater.isDirExists(hotfixDir) then
            updater.rmdir(hotfixDir)
        end

        if updateProcessHander then updateProcessHander(100, 100, "下载完成，正在应用补丁...") end

        -- 解压补丁要hotfix文件夹
        unzip.uncompress(path, hotfixDir)
        updater.rmdir(tmpdir)
    end
    if updateCompleteHander then updateCompleteHander(success) end
end

function updater.startUpdate(patchUrl, onProcessCallback, onCompleteCallback)
    downloadPatch(patchUrl, "hotfix.patch")
    updateCompleteHander = onCompleteCallback
    updateProcessHander = onProcessCallback
end

return updater
