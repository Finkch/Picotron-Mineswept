--[[
    stores various 50-50s along with their mine requirements
]]

Fifty = {}
Fifty.__index = Fifty
Fifty.__type = "fifty"

-- all grids will face the bottom left corner by default.
--  n > 0   = normal cell; n = count of adjacent quantum mines
--  -1      = mine
--  -2      = false flag
--
-- a mine grid, or mgrid, is a fifty that is a specific placement of mines.
-- in other words, a specific collapse of the quantum mine funciton.
function Fifty:new(grid, mgrids, mines, bc_mines)

    local f = {
        grid = grid,
        mgrids = mgrids,
        w = #grid[1],
        h = #grid,
        mines = mines,  -- total mines
        bc_mines        -- mines sitting on the boundary
    }
    setmetatable(f, Fifty)
    return f
end



-- rotates the fifty's grid to fit in other corners
function Fifty:rotate90()
    
    local mgrids = {}
    for i = 1, #self.mgrids do
        add(mgrids, self:_rotate90(self.mgrids[i]))
    end

    return Fifty:new(
        self:_rotate90(self.grid), 
        mgrids,
        self.mines,
        self.bc_mines
    )
end

function Fifty:_rotate90(grid)
    local numRows = #grid
    local numCols = #grid[1]
    local newGrid = {}

    for col = 1, numCols do
        newGrid[col] = {}
        for row = numRows, 1, -1 do
            newGrid[col][numRows - row + 1] = grid[row][col]
        end
    end

    return newGrid
end

function Fifty:rotate180()

    local mgrids = {}
    for i = 1, #self.mgrids do
        add(mgrids, self:_rotate180(self.mgrids[i]))
    end

    return Fifty:new(
        self:_rotate180(self.grid), 
        mgrids,
        self.mines,
        self.bc_mines
    )
end

function Fifty:_rotate180(grid)
    local numRows = #grid
    local numCols = #grid[1]
    local newGrid = {}

    for row = numRows, 1, -1 do
        newGrid[numRows - row + 1] = {}
        for col = numCols, 1, -1 do
            newGrid[numRows - row + 1][numCols - col + 1] = grid[row][col]
        end
    end

    return newGrid
end

function Fifty:rotate270()

    local mgrids = {}
    for i = 1, #self.mgrids do
        add(mgrids, self:_rotate270(self.mgrids[i]))
    end

    return Fifty:new(
        self:_rotate270(self.grid), 
        mgrids,
        self.mines,
        self.bc_mines
    )
end

function Fifty:_rotate270(grid)
    local numRows = #grid
    local numCols = #grid[1]
    local newGrid = {}

    for col = numCols, 1, -1 do
        newGrid[numCols - col + 1] = {}
        for row = 1, numRows do
            newGrid[numCols - col + 1][row] = grid[row][col]
        end
    end

    return newGrid
end


-- metamethods
function Fifty:__tostring()
    local s = ""
    for i = 1, #self.grid do
        for j = 1, #self.grid[1] do
            s ..= string.format("%d ", self.grid[i][j]) 
        end
        s ..= "\n"
    end
    return s
end



-- fifties stores fifty's
Fifties = {}
Fifties.__index = Fifties
Fifties.__type = "fifties"

function Fifties:new()
    
    local f = {
        grids = {}
    }
    setmetatable(f, Fifties)

    -- inits the list of 50-50s
    f:_init()

    return f
end

-- adds a new 50-50 grid to the collection
function Fifties:add(mines, bc_mines, grid)
    add(self.grids, Fifty:new(grid, mines, bc_mines))
end


-- edit this to add 50-50s
function Fifties:_init()
    self:add(3, 1,
        {
            {-1, -1},
            {-2, 1},
            {-2, 1}
        }
    )
end
