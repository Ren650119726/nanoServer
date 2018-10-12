writablepath = cc.FileUtils:getInstance():getWritablePath()
cc.FileUtils:getInstance():setPopupNotify(false)
cc.FileUtils:getInstance():addSearchPath(writablepath ..  "hotfix/res/")
cc.FileUtils:getInstance():addSearchPath("src/")
cc.FileUtils:getInstance():addSearchPath("res/")
package.path = './src/?.lua;' .. './src/framework/?.lua' .. package.path
package.path = writablepath .. 'hotfix/src/?.lua;' .. writablepath .. 'hotfix/src/framework/?.lua;' .. package.path

local paths = cc.FileUtils:getInstance():getSearchPaths()
for i = 1, #paths do
    print("==>SearchPath", paths[i])
end

require "config"
require "cocos.cocos2d.functions"

appConfig = require "appConfig"
require "app.core.InitBeforeUpdate"
require "app.core.InitScreen"

ccui.TextField:setInputHintTexture("intputHint.png")
ccui.TextField:setIntputHintFadeTime(0.6)

local sx = 0
local sy = 0.123526894
local winSize = cc.Director:getInstance():getWinSize()
local oriX = (sx + 1) * 0.5 * 1280
local oriY = (sy + 1) * 0.5 * 720
local curX = (sx + 1) * 0.5 * winSize.width
local curY = (sy + 1) * 0.5 * winSize.height

multyResolution.addRelativePos(1, oriX, oriY, curX, curY, 1)

local LoadingUI = require "app.ui.LoadingUI"

local function main()
    LoadingUI:new():run(true)
end

local status, msg = xpcall(main, function(msg)
    print(msg)
end)
if not status then
    print(msg)
end