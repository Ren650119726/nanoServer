local Lobby = class("Lobby", cc.load("mvc").ViewBase)

local game = require "app.logic.game"
local LobbyUI = require "app.ui.LobbyUI"
local eventManager = require "app.core.EventManager"

event_name.EXIT_GAME = "EXIT_GAME"

Lobby.RESOURCE_FILENAME = "layout/lobby.csb"
Lobby.RESOURCE_BINDING = {}

local lobbyInstance
local lobbyUIInstance
function Lobby.instance()
    return lobbyInstance
end

function Lobby.exit()
    lobbyUIInstance:unregistEvent()
    eventManager:removeEventListener(lobbyInstance.exitHandler)
    lobbyInstance = nil
    lobbyUIInstance = nil
    game.exit()
end

function Lobby:onCreate(app, name)
    print("Lobby:oncreate()")
    self.root:setLocalZOrder(100)

    local ui = LobbyUI:create("", "", self)
    self:addChild(ui)
    ui:registEvent()

    -- lobby ui
    lobbyUIInstance = ui

    lobbyInstance = self
    self._, self.exitHandler = eventManager:addEventListener(event_name.EXIT_GAME, Lobby.exit)

    self:enableNodeEvents()
end

function Lobby:inAction(node, callBack)
    local endY = node:getPositionY()
    node:setPositionY(endY - 900)
    local act = cc.Sequence:create(cc.MoveTo:create(0.3, cc.p(node:getPositionX(), endY + 20)), cc.MoveTo:create(0.05, cc.p(node:getPositionX(), endY)), cc.CallFunc:create(function() if callBack then callBack() end end))
    node:runAction(act)
end

function Lobby:outAction(node, callBack)
    local beginY = node:getPositionY()
    --node:setPositionY(endY-700)
    local act = cc.Sequence:create(cc.MoveTo:create(0.3, cc.p(node:getPositionX(), beginY + 900)), cc.CallFunc:create(function() if callBack then callBack() end end))
    node:runAction(act)
end

return Lobby