--[[
    represents a cell: one item on the game board
]]

Cell = {}
Cell.__index = Cell
Cell.__type = "cell"

function Cell:new(base_sprite)

    local c = {
        bs = base_sprite,   -- index of the first sprite in this sprite set
        s = base_sprite,    -- current sprite used by cell
        x = 0,              -- grid coordinates of cell
        y = 0,
        px = 0,             -- pixel coordinates of the cell
        py = 0,
        d = board.d,        -- board dimension
        value = 0,          -- count of adjacent mines
        revealed = false,   -- is revealed
        mine = false,       -- is a mine
        flag = false,       -- is a flag
        falsy = false,      -- is a false cell (aka, special flag)
        adj = {}            -- list of adjacent cells
    }

    setmetatable(c, Cell)
    return c
end


-- methods to toggle cell state
function Cell:reveal()
    self.revealed = not self.revealed
    self:set()
end

function Cell:mine()
    if self.mine then
        self.value = -1
        self.mine = true
    else
        self.value = 0
        self.mine = false
        self:count()
    end

    self:set()
end

function Cell:flag()
    self.flag = not self.flag
    self:set()
end

function Cell:falsy()
    self.falsly = not self.falsly
    self:set()
end


-- sets the sprite for the cell
function Cell:set()

    -- when cell is revealed
    if self.revealed then

        -- either cell is mine or regular cell
        if self.mine then
            self.s = self.bs + 9
        else
            self.s = self.bs + self.value
        end

    -- when the cell is flagged
    elseif self.flag then
        self.s = self.bs + 32

    -- otherwise, unrevealed sprite
    else
        self.s = self.bs
    end
end

function Cell:draw()
    spr(self.s, self.px, self.py)
end