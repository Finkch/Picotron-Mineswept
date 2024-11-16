--[[
    represents a cell: one item on the game board
]]

Cell = {}
Cell.__index = Cell
Cell.__type = "cell"

function Cell:new()

    local c = {}
    setmetatable(c, Cell)
    return c
end