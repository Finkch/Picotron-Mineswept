--[[pod_format="raw",created="2024-11-04 21:31:02",modified="2024-11-22 21:15:05",revision=17]]
--[[
    the board is a grid. each tile is an object that encodes
    the state of that tile; whether its a bomb or its value.

    on it's own, a board can't do much. it must be instantiated to a type of game.
    for example, to play an insidious game, an indidious board must be instantiated.
    as such, board is mostly just an interface for the classic and quantum variants.

    due to needing to support quantum boards, the board family looks as such...
          board
        /       \
    quantum    classic
            /     |     \
        cruel   fair    insidious
]]

Board = {}
Board.__index = Board
Board.__type = "board"

function Board:new(fairness, oldsprites)
    
    -- sprite info
    local base_sprite   = 72
    local d             = 8
    if not oldsprites then
        base_sprite = 8
        d           = 16
    end

    local b = {
        fairness    = fairness,     -- used for generation
        bs          = base_sprite,  -- which sprite set to use
        d           = d,            -- cell pixel dimensions
        flags       = 0,
        reveals     = 0,
        grid        = {}
    }

    setmetatable(b, Board)
    return b
end


-- gets the value of a given cell
function Board:value(x, y)
    if (not self:inbounds(x, y)) return -3
    return self(x, y):value()
end


-- conditionally iterates over cells, performing some action.
-- condition defaults to true.
-- cells attribute is optional; if not provided, iterate all cells
function Board:all(apply, condition, cells)
    
    -- gets a 1d list of cells, if not provided
    if (not cells) cells = self:cells()

    -- performs a conditional action on all cells
    for _, cell in ipairs(cells) do
        if (not condition or condition(cell)) apply(cell)
    end
end


-- reveals mines and bad flags
function Board:gameover()

    -- for some board gen strategies, ensures second gen occurs before mines are revealed.
    -- equality operator is in case second_gen is nil
    if (self.ensure and not self.second_gen == true) self:ensure()

    -- sets all cells to reveal if they are not already and either mine or incorrect flag
    self:all(
        function(cell)
            cell.is_reveal = true
            cell:set()
        end,
        function(cell) return not cell.is_reveal and (cell.is_mine or cell.is_flag) end
    )
end



-- left click to reveal or cord
function Board:lclick(cursor)

    -- converts screen coordinates to grid coordinates
    local x, y = cursor:map(self.d)

    -- makes sure the click is inbounds
    if (not self:inbounds(x, y)) return

    -- if this is the first click, also generate the board
    if (self.reveals == 0) self:generate(x, y, self.bombs)

    -- otherwise, reveal a cell
    self(x, y):reveal()

end

-- right click to flag
function Board:rclick(pos)

    -- converts screen coordinates to grid coordinates
    local x, y = cursor:map(self.d)

    -- can't flag before the first click, revealed cell, or when there's too many flags
    if (self.reveals == 0 or not self:inbounds(x, y) or self(x, y).is_reveal or (self.flags >= self.bombs and not self(x, y).is_flag)) return

    self(x, y):flag()

    -- tracks number of flags
    if self(x, y).is_flag then
        self.flags += 1
    else
        self.flags -= 1
    end
end



-- for each cell, call its draw method
function Board:draw()
    self:qall(function(cell) cell:draw() end)
end






--[[
//////////////////////////////////////////////////
                interface methods
//////////////////////////////////////////////////
]]

-- calling the board returns the given cell.
-- turns out, lua doesn't respect metamethod inheritence!
function Board:__call(x, y)
    if (not x or not y) return self.grid

    assert(x and y, string.format("invalid grid coordinates b(%s, %s)", x, y))
    assert(self:inbounds(x, y), string.format("grid call out of bounds c(%d, %d)", x, y))

    return self.grid[x][y]
end

-- gets a 1d list representation of all cells
--  !!  interface method    !!
function Board:cells() assert(false, "invalid interface method call, board:cells()") end


-- ensures grid position exists.
--  !!  interface method    !!
function Board:inbounds(x, y) assert(false, string.format("invalid interface method call, board:inbounds(%s, %s)", x, y)) end


-- quick all. same as all, but faster.
-- uses pregenerated list, but lacks option to go over only subset.
--  !!  interface method    !!
function Board:qall(apply, condition) assert(false, "invalid interface method call, board:qall()") end


-- creates an empty grid
--  !!  interface method    !!
function Board:empty() assert(false, "invalid interface method call, board:empty()") end


-- creates the starting board state
--  !!  interface method    !!
function Board:generate(x, y, mines) assert(false, "invalid interface method call, board:generate()") end