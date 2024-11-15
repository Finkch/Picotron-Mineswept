--[[
    writes to a file to track user's win-loss ratio
]]

include("lib/logger.lua")
include("lib/log.lua")

Winlosser = {}
Winlosser.__index = Winlosser
Winlosser.__type = "winlosser"

function Winlosser:new()

    local d = "appdata/minesweeper"

    local w = {
        d = d,                  -- directory to which to write
        f = "wl.txt",           -- file to which to write
        logger = Logger:new(d), -- logger used to write
    }

    setmetatable(w, Winlosser)
    return w
end