local MJ3DUI = class("MJ3DUI", cc.Node)
local mjImgMap = {
    "tiao_1.png", "tiao_2.png", "tiao_3.png", "tiao_4.png", "tiao_5.png", "tiao_6.png", "tiao_7.png", "tiao_8.png", "tiao_9.png", "tiao_t.png",
    "tong_1.png", "tong_2.png", "tong_3.png", "tong_4.png", "tong_5.png", "tong_6.png", "tong_7.png", "tong_8.png", "tong_9.png", "tong_w.png",
    "wan_1.png", "wan_2.png", "wan_3.png", "wan_4.png", "wan_5.png", "wan_6.png", "wan_7.png", "wan_8.png", "wan_9.png", "wan_w.png",
}

MJ3DUI.UIType = {}
MJ3DUI.UIType.NONE = 0
MJ3DUI.UIType.LI = 1 --玩家手牌类型，竖立
MJ3DUI.UIType.BEI = 2 --背面向上
MJ3DUI.UIType.ZHENG = 3 --正面向上

MJ3DUI.Direction = {}
MJ3DUI.Direction.PLAYER = 1
MJ3DUI.Direction.PLAYER_NEXT = 2
MJ3DUI.Direction.PLAYER_FACE = 3
MJ3DUI.Direction.PLAYER_PRE = 4
function MJ3DUI:ctor(modelName, rotate, pos, scale, folder)
    self.isEnableChuPai = true
    self.m_model = cc.Sprite3D:create(modelName)
    self:addChild(self.m_model)
    self.m_model:setScaleX(1)
    self.m_model:setScaleY(1)
    self.m_model:setScaleZ(1)
    self.m_model:setPosition3D(cc.vec3(0, 0, 0))
    self.m_model:setRotation3D(cc.vec3(0, 0, 0))

    self.m_model:getMeshByIndex(0):getTexture():setAntiAliasTexParameters()

    self.m_aabb = self.m_model:getAABB()
    local corners = {}
    for i = 1, 8 do
        corners[i] = {}
    end
    --self.m_sprite = sp
    self.m_corners = self.m_aabb:getCorners(corners)
    self.m_min = self.m_corners[7]
    self.m_max = self.m_corners[4]
    self.m_center = self.m_aabb:getCenter()
    self.m_offsetX = self.m_center.x - self.m_min.x
    self.m_offsetY = self.m_center.y - self.m_min.y
    self.m_offsetZ = self.m_max.z - self.m_min.z

    self.m_hou = self.m_max.x - self.m_min.x
    self.m_kuan = self.m_max.y - self.m_min.y
    self.m_gao = self.m_max.z - self.m_min.z
    self.m_folder = folder

    self.m_ting = cc.Sprite:create("desk_ui/flag_ting.png")
    self.m_ting:setScale(0.25)
    self:addChild(self.m_ting)
    self.m_ting:setAnchorPoint(cc.p(1, 0))
    self.m_ting:setPosition(cc.p(0, 5))
    self.m_ting:setVisible(false)


    self.m_anchorz = 0
    self.m_mjUIIdx = -1
    self:setUIType(MJ3DUI.UIType.BEI)
end

function MJ3DUI:setLightMask(mask)
    self.m_model:setLightMask(mask)
end

function MJ3DUI:setData(mjData)
    self.m_data = mjData
    if not self.m_data or self.m_data:isInvalid() then
        --self.m_sprite:hide()
        self.m_model:getMeshByIndex(0):setTexture(self.m_folder .. mjImgMap[10])
        return
    end
    self:updateHuase(mjData:getIdx())
end

function MJ3DUI:getData()
    return self.m_data
end

function MJ3DUI:setUIType(uitype)
    if self.m_uiType == uitype then return end
    self.m_uiType = uitype
    if uitype == MJ3DUI.UIType.BEI then
        self.m_model:setRotation3D(cc.vec3(180, 180, 90))
        self.m_model:setPosition3D(cc.vec3(0, self.m_offsetX, 0))
    elseif uitype == MJ3DUI.UIType.ZHENG then
        self.m_model:setRotation3D(cc.vec3(180, 0, 90))
        self.m_model:setPosition3D(cc.vec3(0, self.m_offsetX, self.m_offsetZ))
    elseif uitype == MJ3DUI.UIType.LI then
        self.m_model:setRotation3D(cc.vec3(0, 90, -90))
        self.m_model:setPosition3D(cc.vec3(0, 0, -self.m_offsetX))
    else
        assert(false, "majiang's uitype is undifined.")
    end
    self:setAnchorZ(self.m_anchorz)
end

function MJ3DUI:getUIType()
    return self.m_uiType
end

function MJ3DUI:updateHuase(idx)
    if self.m_mjUIIdx == idx then return end
    self.m_mjUIIdx = idx
    --self.m_sprite:hide()
    --self.m_sprite:setTexture(self.m_folder .. mjImgMap[idx])
    self.m_model:getMeshByIndex(0):setTexture(self.m_folder .. mjImgMap[idx])
    self.m_model:getMeshByIndex(0):getTexture():setAntiAliasTexParameters()
end

function MJ3DUI:setDirection(direction)
    --if self.m_direction == direction then return end
    self.m_direction = direction
    if direction == MJ3DUI.Direction.PLAYER then
        self:setRotationY(0)
    elseif direction == MJ3DUI.Direction.PLAYER_NEXT then
        self:setRotationY(90)
    elseif direction == MJ3DUI.Direction.PLAYER_FACE then
        self:setRotationY(180)
    elseif direction == MJ3DUI.Direction.PLAYER_PRE then
        self:setRotationY(-90)
    end
end

function MJ3DUI:setAnchorZ(z)
    self.m_anchorz = z
    local dis = z * self.m_gao
    local uitype = self.m_uiType
    if uitype == MJ3DUI.UIType.BEI then
        local curz = 0
        local newz = curz - dis
        self.m_model:setPositionZ(newz)
    elseif uitype == MJ3DUI.UIType.ZHENG then
        local curz = self.m_offsetZ
        local newz = curz - dis
        self.m_model:setPositionZ(newz)
    elseif uitype == MJ3DUI.UIType.LI then
        local cury = 0
        local newy = cury - dis
        self.m_model:setPositionY(newy)
    else
        assert(false, "majiang's uitype is undifined.")
    end
end

function MJ3DUI:getAABBBox()
    local aabb = self.m_model:getAABB()
    local corners = {}
    for i = 1, 8 do
        corners[i] = {}
    end
    corners = aabb:getCorners(corners)
    local min = corners[7]
    local max = corners[4]
    return min, max
end

function MJ3DUI:getOBB()
    if not self.m_obb then
        self.m_obb = cc.OBB:new(self.m_aabb)
    end
    local mat = self.m_model:getNodeToWorldTransform()

    self.m_obb._xAxis = cc.vec3(mat[1], mat[2], mat[3])
    self.m_obb._xAxis = cc.vec3normalize(self.m_obb._xAxis)

    self.m_obb._yAxis = cc.vec3(mat[5], mat[6], mat[7])
    self.m_obb._yAxis = cc.vec3normalize(self.m_obb._yAxis)

    self.m_obb._zAxis = cc.vec3(-mat[9], -mat[10], -mat[11])
    self.m_obb._zAxis = cc.vec3normalize(self.m_obb._zAxis)

    local ori = cc.vec4(self.m_center.x, self.m_center.y, self.m_center.z, 1)
    local cur = mat4_transformVector(mat, ori, ori)
    self.m_obb._center = cc.vec3(cur.x, cur.y, cur.z)
    self.m_obb:computeExtAxis()
    return self.m_obb
end

function MJ3DUI:getFaceRect()
    local mat = self.m_model:getNodeToWorldTransform()
    local p1 = cc.vec4(self.m_min.x, self.m_min.y, self.m_min.z, 1)
    local p2 = cc.vec4(self.m_min.x, self.m_max.y, self.m_max.z, 1)

    p1 = mat4_transformVector(mat, p1, p1)
    p2 = mat4_transformVector(mat, p2, p2)

    return p1, p2
end

function MJ3DUI:enableChuPai(enable)
    if self.isEnableChuPai == enable then
        return
    end
    self.isEnableChuPai = enable
    if enable then
        self.m_model:setColor(cc.c3b(255, 255, 255))
    else
        self.m_model:setColor(cc.c3b(170, 170, 170))
    end
end

-- 听角标
function MJ3DUI:enableTing(enable)
    self.m_ting:setVisible(enable)
end
function MJ3DUI.getIconByIdx(idx, basicDir)
    if not basicDir then
        return mjImgMap[idx]
    else
        return basicDir .. mjImgMap[idx]
    end
end

return MJ3DUI
