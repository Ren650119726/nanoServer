local MJ3DUICreator = class("MJ3DUICreator")
local MJ3DUIClass = require "app.ui.MJ3DUI"

function MJ3DUICreator:ctor(modelName, relativeRotate, relativePos, relativeScale, folder)
    self.m_modelName = modelName
    self.m_relativeRotate = relativeRotate
    self.m_relativePos = relativePos
    self.m_relativeScale = relativeScale
    self.m_folder = folder
end

function MJ3DUICreator:createUIWithData(mjData)
    local ui =  MJ3DUIClass:create(self.m_modelName, self.m_relativeRotate, self.m_relativePos, self.m_relativeScale, self.m_folder)
    ui:setData(mjData)
    return ui
end
function MJ3DUICreator:createUI()
    local ui =  MJ3DUIClass:create(self.m_modelName, self.m_relativeRotate, self.m_relativePos, self.m_relativeScale, self.m_folder)
    ui:setUIType(MJ3DUIClass.UIType.BEI)
    return ui
end

return MJ3DUICreator
