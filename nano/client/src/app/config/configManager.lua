local configManager = {}

configManager.soundConfig = require "app.config.soundConfig"
configManager.fxIconConfig = require "app.config.fxIconConfig"

--- 调试模式
configManager.debug = {
    permission = false,
    enable = false,
}

--- 登录从服务器获取
configManager.systemConfig = {}
return configManager
