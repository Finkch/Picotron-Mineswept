

include("boards/classic.lua")

FairBoard = setmetatable({}, ClassicBoard)
FairBoard.__index = FairBoard
FairBoard.__type = "fairboard"


function FairBoard:new(fairness, oldsprites, mines, w, h)
    local fb = ClassicBoard:new(fairness, oldsprites, mines, w, h)

    setmetatable(fb, FairBoard)
    return fb
end


-- calling the board returns the given cell.
function FairBoard:__call(x, y)
    return ClassicBoard.__call(self, x, y)
end


-- creates a regular ol' board of mineswept.
-- (x, y) is the position of the first reveal.
function FairBoard:generate(x, y)

    -- sets false flags ensure first click reveals a zero
    self(x, y):all(function(cell) cell:falsy() end)
    self(x, y):falsy()


    -- places mines.
    -- cells is the list of all cells without a mine
    local cells = self:place(self.mines)

    -- clears any lingering false flags
    self:all(
        function(c) return c:falsy() end,
        function(c) return c.is_false end,
        cells
    )

    -- counts the value of all non-mine cells
    self:count(cells)
end