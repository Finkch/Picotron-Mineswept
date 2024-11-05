--[[
    allows either the mouse or arrow keys to be used as input
]]

Cursor = {}
Cursor.__index = Cursor
Cursor.__type = "cursor"

function Cursor:new()

    local c = {
        x = 0,
        y = 0
    }

    setmetatable(c, Cursor)
    return c
end