--- 本模块暂时不用了
--- @Deprecated

local luaCustomEvent = require('app.core.LuaCustomEvent')
local updater = {}
local lfs = require('lfs')

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
                    local curDir = path..dir
                    local mode = lfs.attributes(curDir, "mode") 
                    if mode == "directory" then
                        _rmdir(curDir.."/")
                    elseif mode == "file" then
                        os.remove(curDir)
                    end
                end
            end
            local succ, des = lfs.rmdir(path)--os.remove(path)
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

local basedir = 'src/app/'
local resinfoFileName = 'resinfo.lua'
local writablePath = fileutils:getWritablePath()
local tmpdir = writablePath .. 'tmp/'

local updateModuleNamePath = ''

local resInfoRelativePath = ''
local uresInfoPath = writablePath .. resInfoRelativePath
local uresInfoTmpPath = tmpdir .. resInfoRelativePath

local resInfoDownloadID = '__DownloadResInfo__'

local updaterHelper = ccluaext.UpdaterHelper:getInstance(6, 4, '.tmp')

--this value must be clear
local localResInfo = nil
local remoteResInfo = nil
local checkUpdateHandler = nil
local updateCompleteHander = nil
local updateProcessHander = nil

local diffResDict = {}
local totalNeedDownloadFiles = 0
local totalNeedDownloadSize = 0
local curDownloadFiles = 0
local curDownloadSize = 0
local errorDownloadFiles = 0
local uresInfoDir = nil
updater._dirList = {}
local downloadFileSizeCache = {}
isForceUpdate = nil

function updater.clear()
    localResInfo = nil
    remoteResInfo = nil
    checkUpdateHandler = nil
    updateCompleteHander = nil
    updateProcessHander = nil

    diffResDict = {}
    totalNeedDownloadFiles = 0
    curDownloadFiles = 0
    totalNeedDownloadSize = 0
    curDownloadSize = 0
    errorDownloadFiles = 0
    uresInfoDir = nil
    updater._dirList = {}
    downloadFileSizeCache = {}
    isForceUpdate = nil
end

function updater.registerEventCallback()
    luaCustomEvent.registerEventHandle(9, function (proto)
        local url = proto:readString()
        local storagePath = proto:readString()
        local id = proto:readString()
        local errorCode = proto:readInt()
        local errorCodeInternal = proto:readInt()
        local errorMsg = proto:readString()
        print('===============ontaskerror:url:%s, sotagePath:%s', url, storagePath)
        print('===============ontaskerror', 'codeInternal', errorCodeInternal, 'msg', errorMsg)
        if id == resInfoDownloadID then
            updater.onDownloadResinfo(storagePath, false)
        elseif customDownloadHandler[id] then
            customDownloadHandler[id].func(false, url, storagePath, customDownloadHandler[id].id, errorCode, errorCodeIn, errorMsg)
            customDownloadHandler[id] = nil
        else
            errorDownloadFiles = errorDownloadFiles + 1
            curDownloadFiles = curDownloadFiles + 1
            updater.onOneFileDownload(id, false)
        end
    end)

    luaCustomEvent.registerEventHandle(10, function (proto)
        print('===============ontaskprocess==================')
        local totalSize = (proto:readInt())
        local curSize = (proto:readInt())
        local id = (proto:readString())
        if id == resInfoDownloadID then
        elseif customDownloadHandler[id] then
        else 
            local oldSize = downloadFileSizeCache[id]
            if nil == oldSize then
                oldSize = 0
            end
            local addSize = curSize - oldSize
            downloadFileSizeCache[id] = curSize
            curDownloadSize = curDownloadSize + addSize
            print('curSize', curDownloadSize, 'totalSize', totalNeedDownloadSize)
            if updateProcessHander then updateProcessHander(curDownloadSize, totalNeedDownloadSize, id) end
        end
    end)

    luaCustomEvent.registerEventHandle(11, function (proto)
        print('===============ontasksuccess==================')
        local url = proto:readString()
        local storagePath = proto:readString()
        local id = proto:readString()
        if id == resInfoDownloadID then
            updater.onDownloadResinfo(storagePath, true)
        elseif customDownloadHandler[id] then
            customDownloadHandler[id].func(true, url, storagePath, customDownloadHandler[id].id)
            customDownloadHandler[id] = nil
        else 
            curDownloadFiles = curDownloadFiles + 1
            updater.onOneFileDownload(id, true)
        end
    end)
end

function updater.setUpdateModuleName(name)
    if string.len(name) > 0 then
        name = name .. '/'
    end
    updateModuleNamePath = name
    resInfoRelativePath = basedir .. updateModuleNamePath .. resinfoFileName
    uresInfoPath = writablePath .. resInfoRelativePath
    uresInfoTmpPath = tmpdir .. resInfoRelativePath
    uresInfoDir = writablePath .. basedir .. updateModuleNamePath
end

local function getLocalResInfo()
    local resInfoTex = nil
    if updater.isFileExists(uresInfoPath) then 
        resInfoTex = updater.readFile(uresInfoPath)
    else 
        resInfoTex = updater.readFile(resInfoRelativePath)
        if resInfoTex then
            updater.mkdir(uresInfoDir)
            updater.writeFile(uresInfoPath, resInfoTex)
        end
    end
    if resInfoTex and string.len(resInfoTex) > 1 then
        return assert(loadstring(resInfoTex))()
    end
    return nil
end

local function downloadResInfo(url)
    printInfo("start download remote ResInfo")
    url = url .. '?ts=' .. tostring(os.time())
    updaterHelper:downloadFile(url, uresInfoTmpPath, resInfoDownloadID)
end

local function downloadRes(url, id)
    local realUrl = url .. id
    local storagePath = tmpdir .. id
    updaterHelper:downloadFile(realUrl, storagePath, id)
end

--modulename '' is game lobby. other is gamename.
function updater.checkHasUpdate(modulename, callback)
    updater.clear()
    updater.registerEventCallback()
    updater.setUpdateModuleName(modulename)
    localResInfo = getLocalResInfo()
    local remoteUrl = (localResInfo and localResInfo.remoteUrl) or (require "appConfig").resinfoURL
    downloadResInfo(remoteUrl)
    checkUpdateHandler = callback
end

local function compaireDiff()
    if remoteResInfo then
        local tmdiffFile = tmpdir .. "diff.lua"
        local tmpDiff
        if updater.isFileExists(tmdiffFile) then
            local diffStr = updater.readFile(tmdiffFile)
            local tmpDict = assert(loadstring(diffStr))()
            if tmpDict.version == remoteResInfo.version then
                tmpDiff = tmpDict.diffDict
            end
        end
        if not localResInfo then
            --diffResDict = updater.clone(localResInfo.resDict)
            for id, info in pairs(remoteResInfo.resDict) do
                diffResDict[id] = updater.clone(info)
            end
        else
            localResDict = localResInfo.resDict
            remoteResDict = remoteResInfo.resDict
            for id, info in pairs(remoteResDict) do
                localInfo = localResDict[id]
                if not localInfo then
                    diffResDict[id] = updater.clone(info)
                elseif localInfo.md5 ~= info.md5 then
                    diffResDict[id] = updater.clone(info)
                end
            end
        end

        if tmpDiff then
            for id, info in pairs(diffResDict) do
                local tinfo = tmpDiff[id]
                if tinfo then
                    diffResDict[id].isok = tinfo.isok
                end
            end
        end

        for id, info in pairs(diffResDict) do
            if not info.isok then
                totalNeedDownloadSize = totalNeedDownloadSize + info.size
            end
        end
    end
end

local function splitVersion(version)
    local s = 1
    local e = 1
    local ret = {}
    for i = 1, #version do
        if string.byte(version, i) == string.byte('.') then
            ret[#ret + 1] = string.sub(version, s, i - 1)
            s = i + 1
        end
    end
    if s <= #version then
        ret[#ret + 1] = string.sub(version, s, #version)
    end
    return ret
end

local function checkIsForceUpdate(curVersion, forceMinVersion)
    if nil == forceMinVersion then
        return false
    end
    if nil == curVersion then
        curVersion = '0.0.0'
    end
    local cur = splitVersion(curVersion)
    local force = splitVersion(forceMinVersion)
    for i = 1, #cur do
        local tc = tonumber(cur[i])
        local tf = tonumber(force[i])
        if tc < tf then
            return true
        elseif tc > tf then
            return false
        end
    end
    return true
end

function updater.onDownloadResinfo(path, isok)
    local hasUpdate = false
    if isok then
        remoteResInfo = assert(loadstring(updater.readFile(path)))()
        if remoteResInfo and remoteResInfo.version then
            if not localResInfo then
                hasUpdate = true
            elseif remoteResInfo.version ~= localResInfo.version then
                hasUpdate = true
            end
        end
    end
    if hasUpdate then
        compaireDiff()
        local localVersion
        if localResInfo then localVersion = localResInfo.version end
        isForceUpdate = checkIsForceUpdate(localVersion, remoteResInfo.forceUpdateVersion)
    end
    checkUpdateHandler(hasUpdate, totalNeedDownloadSize, isForceUpdate)
end

function updater.onOneFileDownload(filename, isok)
    diffResDict[filename].isok = isok
    if curDownloadFiles ~= totalNeedDownloadFiles then
        --if updateProcessHander then updateProcessHander(curDownloadFiles, totalNeedDownloadFiles, filename) end
        return
    end
    --if updateProcessHander then updateProcessHander(curDownloadFiles, totalNeedDownloadFiles, filename) end
    print('curSize', curDownloadSize, 'totalSize', totalNeedDownloadSize)
    if updateProcessHander then updateProcessHander(curDownloadSize, totalNeedDownloadSize, filename) end
    if errorDownloadFiles > 0 then
        updater.onDownloadAllFiles(false)
    else
        updater.onDownloadAllFiles(true)
    end
end

local function copyOneFile(relativeFileName)
    -- Create nonexistent directory in update res.
    local i,j = 1,1
    while true do
        j = string.find(relativeFileName, "/", i)
        if j == nil then break end
        local dir = string.sub(relativeFileName, 1,j)
        -- Save created directory flag to a table because
        -- the io operation is too slow.
        if not updater._dirList[dir] then
            updater._dirList[dir] = true
            local fullUDir = writablePath .. dir
            updater.mkdir(fullUDir)
        end
        i = j + 1
    end
    local fullFileInURes = writablePath .. relativeFileName
    local fullFileInUTmp = tmpdir .. relativeFileName
    print(string.format('copy %s to %s', fullFileInUTmp, fullFileInURes))
    local zipFileContent = updater.readFile(fullFileInUTmp)
    if zipFileContent then
        updater.writeFile(fullFileInURes, zipFileContent)
        return fullFileInURes
    end
    return nil
end

function updater.dump(object, label)
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
                if nest > 1 then 
                    result[#result +1] = string.format("%s['%s'] = %s%s", indent, label, _v(object), postfix)
                else 
                    result[#result +1] = string.format("%s%s = %s%s", indent, label, _v(object), postfix)
                end
            else
                result[#result +1] = string.format("%s%s%s", indent, _v(object), postfix)
            end
        elseif not lookupTable[object] then
            lookupTable[object] = true

            if type(label) == "string" then
                if nest > 1 then
                    result[#result +1 ] = string.format("%s['%s'] = {", indent, label)
                else
                    result[#result +1 ] = string.format("%s%s = {", indent, label)
                end
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

function updater.onDownloadAllFiles(isok)
    if isok then --copy files to real dir
        for id, info in pairs(diffResDict) do
            copyOneFile(id)
        end
        copyOneFile(resInfoRelativePath)
        updater.rmdir(tmpdir)
    end
    local tmdiffFile = tmpdir .. "diff.lua"
    local tmpDict = {}
    tmpDict.version = remoteResInfo.version
    tmpDict.diffDict = diffResDict
    local str = updater.dump(tmpDict, "local data") .. "\nreturn data"
    updater.writeFile(tmdiffFile, str)
    if updateCompleteHander then updateCompleteHander(isok, isForceUpdate) end
end

function updater.startUpdate(onProcessCallback, onCompleteCallback)
    --compaireDiff()
    for id, info in pairs(diffResDict) do
        if not info.isok then
            downloadRes(remoteResInfo.resUrl, id)
            totalNeedDownloadFiles = totalNeedDownloadFiles + 1
        end
    end
    curDownloadFiles = 0
    errorDownloadFiles = 0

    updateCompleteHander = onCompleteCallback
    updateProcessHander = onProcessCallback
end

function getRealKey(id)
    local key = "custom_download" .. id
    return key
end
function updater.addCustomDownloadHandler(id, handler)
    local key = getRealKey(id)
    if customDownloadHandler.key then
        return false
    else
        customDownloadHandler[key] = {id = id, func = handler}
        return true
    end
    
end
function updater.customDownload(url, path, id)
    local key = getRealKey(id)
    updaterHelper:downloadFile(url, path, key)
end

--local localpath = cc.FileUtils:getInstance():getWritablePath() .. 'tmp/'
--updater.rmdir(localpath)
return updater
