--[[
    writes to a file to track user's win-loss ratio
]]

Winlosser = {}
Winlosser.__index = Winlosser
Winlosser.__type = "winlosser"

function Winlosser:new()
    local w = {}
    setmetatable(w, Winlosser)
    return w
end