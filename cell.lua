--[[
    represents a cell: one item on the game board
]]

Cell = {}
Cell.__index = Cell
Cell.__type = "cell"

function Cell:new(base_sprite)

    local c = {
        bs = base_sprite,   -- index of the first sprite in this sprite set
        x = 0,              -- grid coordinates of cell
        y = 0,
        value = 0,          -- count of adjacent mines
        flag = false,       -- is a flag
        mine = false,       -- is a mine
        falsy = false,      -- is a false cell (aka, special flag)
        adj = {}            -- list of adjacent cells
    }

    setmetatable(c, Cell)
    return c
end

function 