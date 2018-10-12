local DeskBackground = class("DeskBackground", cc.load("mvc").ViewBase)
DeskBackground.RESOURCE_FILENAME = "layout/desk_background.csb"
DeskBackground.RESOURCE_BINDING = {
    m_background = { id = "background" },
}
function DeskBackground:onCreate(idx, text)
    self.root:setLocalZOrder(1000)
    self.root:setPosition(cc.p(0,0))
end

function DeskBackground:getSize()
    return self.m_background:getContentSize()
end

return DeskBackground