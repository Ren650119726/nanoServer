local PockerData = class("PockerData")

local ValueAspectTable = {A, 2, 3, 4, 5, 6, 7, 8, 9, 10, J, Q, K}
local ColorAspectTable = {fangkuai, meihua, hongtao, heitao,} 

function PockerData:ctor(idx)
    self.m_idx = idx
    self.m_value = (idx - 1) % 13 + 1
    self.m_color = (idx - 1) / 13 + 1
end

function PockerData:toString()
    if self.m_idx == 53 then return "xiaowang" end
    if self.m_idx == 54 then return "dawang" end
    local tt = {}
    tt[1] = ColorAspectTable[self.m_color]
    tt[2] = ValueAspectTable[self.Value]
    return table.concat(tt, " ")
end

function PockerData:getIdx()
    return self.m_idx
end
function PockerData.getValue()
    return self.m_value
end
function PockerData.getColor()
    return self.m_color
end

return PockerData
