local PGChooseItem = class("PGChooseItem", cc.load("mvc").ViewBase)
local MJ3DUIClass = require "app.ui.MJ3DUI"

PGChooseItem.RESOURCE_FILENAME = "layout/pongkong_item.csb"
PGChooseItem.RESOURCE_BINDING = {
    m_di1 = { id = "di1" },
    m_di2 = { id = "di2" },
    m_di3 = { id = "di3" },
    m_diIcon1 = { id = "diIcon1" },
    m_diIcon2 = { id = "diIcon2" },
    m_diIcon3 = { id = "diIcon3" },
    m_shangIcon = { id = "shangIcon" },
}
local MJBaseIcon = { "images/desk/majiang_1.png", "images/desk/majiang_2.png" }
local huaseBaseDir = "huase/"
function PGChooseItem:onCreate(mjData, pType, callback)
    self.m_mjData = mjData
    self.m_callback = callback
    local iconName = huaseBaseDir .. MJ3DUIClass.getIconByIdx(mjData:getIdx())
    if pType == "ming" then
        self.m_diIcon1:setTexture(iconName)
        self.m_diIcon2:setTexture(iconName)
        self.m_diIcon3:setTexture(iconName)

        self.m_shangIcon:setTexture(iconName)
    else
        self.m_diIcon1:hide()
        self.m_diIcon2:hide()
        self.m_diIcon3:hide()

        self.m_di1:setTexture(MJBaseIcon[2])
        self.m_di2:setTexture(MJBaseIcon[2])
        self.m_di3:setTexture(MJBaseIcon[2])
        self.m_shangIcon:setTexture(iconName)
    end

    local box1 = self.m_di1:getBoundingBox()
    local box2 = self.m_di2:getBoundingBox()
    local box3 = self.m_di3:getBoundingBox()
    local box4 = self.m_shangIcon:getBoundingBox()
    self.m_rect = cc.rectUnion(cc.rectUnion(cc.rectUnion(box1, box2), box3), box4)

    local listenner = cc.EventListenerTouchOneByOne:create()
    listenner:setSwallowTouches(true)
    listenner:registerScriptHandler(function(touch, event)
        local pos = self:convertTouchToNodeSpace(touch)
        if cc.rectContainsPoint(self.m_rect, pos) then
            return true
        end
        return false
    end, cc.Handler.EVENT_TOUCH_BEGAN)

    listenner:registerScriptHandler(function(touch, event)
        local pos = self:convertTouchToNodeSpace(touch)
        if cc.rectContainsPoint(self.m_rect, pos) then
            self.m_callback(self.m_mjData)
        end
    end, cc.Handler.EVENT_TOUCH_ENDED)
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listenner, self)
end

local PGChoose = class("PGChoose", cc.load("mvc").ViewBase)
PGChoose.RESOURCE_FILENAME = "layout/pongkong.csb"
PGChoose.RESOURCE_BINDING = {
    m_pos1 = { id = "pos1" },
    m_pos2 = { id = "pos2" },
}

function PGChoose:onItemChoose(mjData)
    printInfo(mjData:toString())
    if self.m_callback then
        self.m_callback(mjData)
    end
end

function PGChoose:onCreate(vec, callback)
    self.m_callback = callback
    local size = #vec
    local diff = size - 2
    local pos1 = self.m_pos1:getPosition()
    local pos2 = self.m_pos2:getPosition()

    local gap = pos2 - pos1
    local x, y = self.m_pos1:getPosition()
    local prePos = nil
    local curPos = nil
    for i = 1, size do
        local ui = PGChooseItem:create("", "", vec[i].mjData, vec[i].gType, handler(self, PGChoose.onItemChoose))
        local posx = x + (i - 1) * gap
        ui:setPosition(posx, y)
        self:addChild(ui)
        prePos = curPos
        curPos = posx
    end

    self:addABlockLayer()
end

return PGChoose
