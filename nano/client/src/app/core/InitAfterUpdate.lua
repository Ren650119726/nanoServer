function applicationWillEnterForeground()
    cc.Director:getInstance():stopAnimation()
    cc.Director:getInstance():resume()
    cc.Director:getInstance():startAnimation()
    audioEngine.resume()
    cloudvoice.resume()
    eventManager:dispatchEvent({ name = "APPLICATION_STATUS_CHANGE", resume = true })
end

function applicationDidEnterBackground()
    cloudvoice.pause()
    cc.Director:getInstance():stopAnimation()
    cc.Director:getInstance():pause()
    audioEngine.pause()
    eventManager:dispatchEvent({ name = "APPLICATION_STATUS_CHANGE", resume = false })
end

require "app.core.basic"
require "app.core.EventName"
require "cocos.init"
require "app.core.stack"

-- 全局变量
cc.exports.eventManager = require "app.core.EventManager"
cc.exports.MODE_TRIOS = 3
cc.exports.MODE_FOURS = 4

cc.exports.json = require "cocos.cocos2d.json"
local network = require "app.network.NetworkManager"
cc.exports.onNativeTimerCall = function()
    network.heartbeat()
end
