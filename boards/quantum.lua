--[[
    a board with infinite dimensions where mines exist in all
    possible vairantions simultanously.
    defined by mine density rather than count of mines.


    quantum/infini board generation scheme
    * start with no grid.
    * wherever the user first clicks and in a (Chebyshev) radius of one about the click,
        place qcells with eigenvalues of 0 (no mine).
    * then, building (Chebyshev) radially outward next to 0 values cells by placing 
        qcells with eigenvalues of (0...01) corresponding to the board's density.
        > whenever a new cell is placed, count its neighbours
        > new cells can only be added next to cells with a count of 0
    * stop building when there are no more 0 values cells that lack neighbours
    * go over the frontier, wiping starting quantum data and building
        up full quantum data for the given board


    according to chatgpt, which in turn sites percolation theory (study of network
    connectiveness), the smallest desnity (or critical density) to ensure the first
    reveal is finite rather than infinite p(mine) must be greater than 0.5927 or so.
    that's not too promising, given my default setting is 1/5, a far cry from 3/5.
        > so, maybe as we build a board, we start at density but lerp on radius to 3/5?
        > also, apparently infinite minesweeper is turing complete.

]]

include("cells.lua")
include("board/boards.lua")



QuantumBoard = setmetatable({}, Board)
QuantumBoard.__index = QuantumBoard
QuantumBoard.__type = "quantumboard"


-- Board header so I know what each field means
--function ClassicBoard:new(w, h, bombs, fairness, oldsprites)
function QuantumBoard:new(fairness, oldsprites, density)
    
    local qb = Board:new(fairness, oldsprites)

    qb["density"]   = density   -- mines per tile
    qb["cells"]     = {}        -- a 1d representation constantly stored in memory
    qb["frontier"]  = {}        -- the frontier is comprised of all undiscovered cells

    setmetatable(ib, QuantumBoard)
    return ib
end




--[[
//////////////////////////////////////////////////
                interface methods
//////////////////////////////////////////////////
]]


-- calling the board returns the given cell.
function QuantumBoard:__call(x, y)
    return Board.__call(self, x, y)
end

-- gets a 1d list representation of all cells
function QuantumBoard:cells()
    return self.cells
end


-- ensures grid position exists.
-- simply checks if the value exists
function QuantumBoard:inbounds(x, y)
    return self.grid[x] and self.grid[x][y]
end


-- quick all. same as all, but faster.
-- uses pregenerated list, but lacks option to go over only subset.
function QuantumBoard:qall(apply, condition)
    for _, cell in self:cells() do
        if (condition(cell)) apply(cell)
    end
end


-- creates an empty grid
function QuantumBoard:empty()
    self.grid = {}
    self.cells = {}
end



-- game actions for left click: reveal, cord
function QuantumBoard:lclick(cursor)

    -- for first reveal, force cursor to b(0, 0)
    if (self.reveals == 0) cursor.pos = -cam.pos + cursor.pos % 8

end


-- game actions for right click: flag
function QuantumBoard:rclick(cursor)
end




--[[
//////////////////////////////////////////////////
                generation methods
//////////////////////////////////////////////////
]]


-- adds a cell to the board
function QuantumBoard:add(x, y)

    -- creates a new cell
    local cell = QuantumCell:new(self.bs, x, y, self.d)

    -- ensures that column exists
    if (not self.grid[x]) self.grid[x] = {}

    -- adds the cell to the map
    self.grid[x][y] = cell
    add(self:cells(), cell)

    -- updates adjacency
    self(x, y).adj = {}
    for dx = -1, 1 do
        for dy = -1, 1 do

            local u, v = x + dx, y + dy

            -- self is not a neighbour of self
            if not (dx == 0 and dy == 0) and self:inbounds(u, v) then

                -- adds that cell to this cell's neighbours
                add(self(x, y).adj, self(u, v))

                -- adds this cell to that cell's neihbours
                add(self(u, v).adj, cell)
            end
        end
    end

    -- !! todo !!
    -- builds frontier superpositions
end



-- creates the starting board state
function QuantumBoard:generate(x, y)

    -- we don't need to do this, but useful for clarity
    self:empty()

    -- starts recursive generation
    self:_generate(x, y, 0)
end

function QuantumBoard:_generate(x, y, i)

    -- base case: recursion got out of hand

    -- base case: no valid neighbours

    -- add tile

    -- add tile's neighbours

end