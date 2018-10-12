local MJ3DUIClass = require "app.ui.MJ3DUI"

local HuHintItem = class("HuHintItem", cc.load("mvc").ViewBase)
HuHintItem.RESOURCE_FILENAME = "layout/huHintItem.csb"
HuHintItem.RESOURCE_BINDING = {
    m_fan = { id = "fan" },
    m_zhang = { id = "zhang" },
    m_huase = { id = "huase" },
    m_bg = { id = "bg" },
}
local basicDir = "huase/"

function HuHintItem:onCreate()
end

function HuHintItem:setFanShu(fan)
    self.m_fan:setString(fan)
end

function HuHintItem:setLeft(zhang)
    self.m_zhang:setString(zhang)
end

function HuHintItem:setMJIdx(idx)
    local icon = MJ3DUIClass.getIconByIdx(idx, basicDir)
    self.m_huase:setTexture(icon)
end

local TingPaiHint = class("TingPaiHint", cc.load("mvc").ViewBase)
TingPaiHint.RESOURCE_FILENAME = "layout/huHint.csb"
TingPaiHint.RESOURCE_BINDING = {
    m_bg = { id = "bg" },
    m_hbg = { id = "hbg" },
    m_huIcon = { id = "huIcon" },
}
function TingPaiHint:onCreate()
    self.m_items = {}
end

function TingPaiHint:clear()
    for i = 1, #self.m_items do
        self.m_items[i]:release()
    end
end

function TingPaiHint:getItem(idx)
    if idx > #self.m_items then
        self.m_items[idx] = HuHintItem:create()
        self.m_items[idx]:retain()
        self.root:addChild(self.m_items[idx])
    end
    return self.m_items[idx]
end

function TingPaiHint:hideAllItem()
    for i = 1, #self.m_items do
        self.m_items[i]:hide()
    end
end

local startPosx = 146
local startPosy = 66
local heightGap = 77
local widthGap = 135
local startSizeWidth = 203
local startSizeHeight = 97
local hbgStartSizeWidth = 232
local hbgStartSizeHeight = 131

function TingPaiHint:setParam(param)
    local size = #param
    if size <= 0 then
        return
    end
    local totalRow = math.floor((size - 1) / 3) + 1
    local totalCol = totalRow > 1 and 3 or (size)
    self:hideAllItem()
    local width = startSizeWidth + widthGap * (totalCol - 1)
    local height = startSizeHeight + heightGap * (totalRow - 1)
    local initPosY = startPosy + heightGap * (totalRow - 1)
    self.m_huIcon:setPositionY(initPosY)
    for i = 1, size do
        local row = math.floor((i - 1) / 3)
        local col = (i - 1) % 3
        local x = startPosx + col * widthGap
        local y = initPosY - row * heightGap
        local item = self:getItem(i)
        local info = param[i]
        item:setFanShu(info.fan)
        item:setLeft(info.left)
        item:setMJIdx(info.idx)
        item:show()
        item:setPosition(x, y)
    end
    self.m_bg:setContentSize(width, height)
    width = hbgStartSizeWidth + widthGap * (totalCol - 1)
    height = hbgStartSizeHeight + heightGap * (totalRow - 1)
    self.m_hbg:setContentSize(width, height)
    self:setContentSize(width, height)
end

return TingPaiHint

