--[[
    represents a cell: one item on the game board
]]

Cell = {}
Cell.__index = Cell
Cell.__type = "cell"

function Cell:new(base_sprite)

    local c = {
        bs = base_sprite,   -- index of the first sprite in this sprite set
        value = 0,          -- count of adjacent mines
        flag = false,       -- is a flag
        mine = false,       -- is a mine
        falsy = false       -- is a false cell (aka, special flag)
    }

    setmetatable(c, Cell)
    return c
end