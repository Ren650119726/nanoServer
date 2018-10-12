local LoginData = class("LoginData")
local basic = require "app.core.basic"

function LoginData:ctor()
    self.uid = nil
    self.name = ""

    basic.bindAccessFunc(self, "m_userType", nil, "UserType", true, true)
end

function LoginData:setUid(id)
    self.uid = id
end

function LoginData:getUid()
    return self.uid
end

function LoginData:setName(name)
    self.name = name
end

function LoginData:getName()
    return self.name
end

return LoginData
