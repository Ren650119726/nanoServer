local deskManager = require "app.logic.deskManager"
local DeskUI = require "app.ui.DeskUI"
local NetMJManager = require "app.logic.NetMJManager"
local ClassicMJLogicClass = require "app.logic.ClassicMJLogic"

local deskEnterHelper = {}

function deskEnterHelper.enterClassicMatch(tableInfo)
    deskManager.isJoinedDesk = true
    deskManager.enterAsync(DeskUI, ClassicMJLogicClass, NetMJManager, tableInfo)
end

function deskEnterHelper.enterLookback(tableInfo)
    deskManager.isJoinedDesk = true
    deskManager.enterAsync(DeskUI, ClassicMJLogicClass, NetMJManager, tableInfo)
end

return deskEnterHelper
