LocalRecord = {}

local s_self = nil
local fileutils = cc.FileUtils:getInstance()
local writablePath = fileutils:getWritablePath()

function LocalRecord:writeFile(path, content, mode)
    fileutils:writeStringToFile(content, path)
    --    mode = mode or "wb"
    --    local file = io.open(path, mode)
    --    if file then
    --        if file:write(content) == nil then return false end
    --        io.close(file)
    --        return true
    --    else
    --        return false
    --    end
end

function LocalRecord:isFileExists(path)
    return fileutils:isFileExist(path)
end

function LocalRecord.instance()
    if not s_self then
        LocalRecord:ctor()
        s_self = LocalRecord
        s_self:load()
    end
    return s_self
end

function LocalRecord.destory()
    if s_self then
        s_self:save()
        s_self.m_proto:release()
        s_self = nil
    end
end

function LocalRecord:getPath(name)
    local filename = name or "player.rs"
    local path = writablepath .. filename
    return path
end

function LocalRecord:save(name)
    local path = self:getPath(name)
    self.m_proto:reset()
    self:saveAProperty("key", self.m_attr)
    local str = self.m_proto:getTotalBuff()
    self:writeFile(path, str)
end

function LocalRecord:load(name)
    local path = self:getPath(name)
    self.m_isLoad = true
    if not self:isFileExists(path) then
        return
    end
    local str = fileutils:getDataFromFile(path)
    self.m_nextPos = 4
    self.m_attr = self:readAProperty(str)
end

function LocalRecord:readAProperty(str)
    local name
    local typename
    name, self.m_nextPos = self.m_proto:inplaceReadString(str, self.m_nextPos)
    typename, self.m_nextPos = self.m_proto:inplaceReadString(str, self.m_nextPos)
    local value
    if typename == "table" then
        value = self:readATable(str)
    elseif typename == "string" then
        value, self.m_nextPos = self.m_proto:inplaceReadString(str, self.m_nextPos)
    elseif typename == "number" then
        value, self.m_nextPos = self.m_proto:inplaceReadString(str, self.m_nextPos)
        value = tonumber(value)
    elseif typename == "boolean" then
        value, self.m_nextPos = self.m_proto:inplaceReadInt8(str, self.m_nextPos)
        value = value > 0 and true or false
    else
        printInfo("typeName: %s", typename)
        assert(false, "read one error type:" .. typename)
    end
    return value, name
end

function LocalRecord:readATable(str)
    local ret = {}
    local size
    size, self.m_nextPos = self.m_proto:inplaceReadInt32(str, self.m_nextPos)
    for i = 1, size do
        local value, key = self:readAProperty(str)
        ret[key] = value
    end
    return ret
end

function LocalRecord:saveAProperty(key, value)
    local typename = type(value)
    self.m_proto:writeString(key)
    self.m_proto:writeString(typename)
    if typename == "table" then
        self:saveATable(value)
    elseif typename == "string" then
        self.m_proto:writeString(value)
    elseif typename == "number" then
        self.m_proto:writeString(tostring(value))
    elseif typename == "boolean" then
        local value = value and 1 or 0
        self.m_proto:writeInt8(value)
    else
        assert(false, "save one error type:" .. typename)
    end
end

function LocalRecord:saveATable(value)
    local size = 0
    for _, v in pairs(value) do
        size = size + 1
    end
    self.m_proto:writeInt(size)
    for k, v in pairs(value) do
        self:saveAProperty(k, v)
    end
end

function LocalRecord:ctor()
    self.m_proto = ccluaext.BinaryStream:create(1024)
    self.m_proto:retain()
    self.m_attr = {}
    self.m_attr.sound = true
    self.m_attr.effect = true
    self.m_attr.shake = true

    self.m_isLoad = false
end

function LocalRecord:setProperty(name, value)
    self.m_attr[name] = value
    --print(self.m_attr,name,value,self.m_attr[name])
    --for key, var in pairs(self.m_attr) do
    --     print(key, var)
    --end
end

function LocalRecord:getProperty(name)
    return self.m_attr[name]
end

return LocalRecord
