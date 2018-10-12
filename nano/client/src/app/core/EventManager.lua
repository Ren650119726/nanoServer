local EventManager = {}
local Event = require("cocos.framework.components.event")
local event = Event.new()
event:bind(EventManager)


return EventManager
