local MJData = class("MJData")

local HuaSeMap = {"tiao", "tong", "wan"}
local ValueMap = {1, 2, 3, 4, 5, 6, 7, 8, 9}

function MJData:ctor(idx, isNet)
    self.m_isInvalid = false
    if type(isNet) == "boolean" and isNet then
        self.m_netValue = idx
        self:netToLocal()
        if idx < 0 then self.m_isInvalid = true end
        return
    end
    self.m_idx = idx

    self.m_huase = math.floor(idx / 10 + 1)
    self.m_value = self.m_idx  % 10
    self:localToNet()
end
function MJData:isInvalid()
    return self.m_isInvalid
end
function MJData:localToNet()
    local tmp = (self.m_huase - 1) * 9 + self.m_value - 1
    tmp = tmp * 4 + 0
    self.m_netValue = tmp
end
function MJData:netToLocal()
    self.m_idx, self.m_huase, self.m_value = self.netIdxToLocalIdx(self.m_netValue)
end

function MJData:getNetValue()
    return self.m_netValue
end

function MJData:toString()
    return tostring(ValueMap[self.m_value] .. HuaSeMap[self.m_huase])
end

function MJData:getIdx()
    return self.m_idx
end
function MJData:getValue()
    return self.m_value
end
function MJData:getHuaSe()
    return self.m_huase
end

function MJData.randomGenerate(isnet)
    if isnet then
        local rd = math.random(0, 83)
        return MJData:create(rd, true)
    end
    local rd1 = math.random(0, 2)
    local rd = math.random(1, 9)
    local data = rd1 * 10 + rd
    return MJData:create(data)
end
function MJData.computeIdx(huase, value)
    return (huase - 1) * 10 + value
end

function MJData.netIdxToLocalIdx(netIdx)
    local tmp = math.floor((netIdx) / 4)
    local huase = math.floor((tmp / 9)) + 1
    local value = (tmp % 9) + 1
    local idx = (huase - 1) * 10 + value
    return idx, huase, value
end

function MJData.localIdxToHuaseAndValue(idx)
    local huase = math.floor(idx / 10 + 1)
    local value = idx  % 10
    return huase, value
end
return MJData