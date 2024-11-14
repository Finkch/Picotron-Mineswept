--[[
    stores various 50-50s along with their mine requirements
]]

Fifty = {}
Fifty.__index = Fifty
Fifty.__type = "fifty"

-- all grids will face the bottom left corner by default.
--  n >= 0   = normal cell; n = count of adjacent quantum mines
--  -1      = mine
--  -2      = false flag
--
-- a mine grid, or mgrid, is a fifty that is a specific placement of mines.
-- the active bits represent which variants in which that cell contains a mine.
function Fifty:new(grid, mgrid, mines, bc_mines, reflectable)

    local f = {
        grid = grid,
        mgrid = mgrid,
        w = #grid[1],
        h = #grid,
        mines = mines,  -- total mines
        bc_mines,       -- mines sitting on the boundary
        reflectable = reflectable   -- whether or not it can be usefully reflected about the diagonal
    }
    setmetatable(f, Fifty)
    return f
end



-- rotates the fifty's grid to fit in other corners.
-- also reflects a grid about the off-diagonal.
-- methods that begin with an '_' were made by ChatGPT

function Fifty:rotate90()
    return Fifty:new(
        self:_rotate90(self.grid), 
        self:_rotate90(self.mgrid),
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
    return Fifty:new(
        self:_rotate180(self.grid), 
        self:_rotate180(self.mgrid),
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
    return Fifty:new(
        self:_rotate270(self.grid), 
        self:_rotate270(self.mgrid),
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

function Fifty:reflect()
    return Fifty:new(
        self:_reflect(self.grid), 
        self:_reflect(self.mgrid),
        self.mines,
        self.bc_mines
    )
end

function Fifty:_reflect(grid)
    local numRows = #grid
    local numCols = #grid[1]
    local newGrid = {}

    -- Initialize the new grid
    for i = 1, numCols do
        newGrid[i] = {}
    end

    -- Swap elements (i, j) with (numCols - j + 1, numRows - i + 1)
    for i = 1, numRows do
        for j = 1, numCols do
            newGrid[numCols - j + 1][numRows - i + 1] = grid[i][j]
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
function Fifties:add(mines, bc_mines, reflectable, grid, mgrid)
    add(self.grids, Fifty:new(grid, mgrid, mines, bc_mines, reflectable))
end


-- edit this to add 50-50s
function Fifties:_init()

    -- 2x3
    self:add(3, 1, true,
        {
            {-1, -1},
            {-2, 1},
            {-2, 1}
        }, {
            {0, 0},
            {1, 0},
            {2, 0}
        }
    )

    self:add(4, 1, true,
        {
            {-1, -1},
            {-2, -1},
            {-2, 1}
        }, {
            {0, 0},
            {1, 0},
            {2, 0}
        }
    )

    self:add(4, 1, true,
        {
            {-1, -1},
            {-2, 1},
            {-2, -1}
        }, {
            {0, 0},
            {1, 0},
            {2, 0}
        }
    )

    -- 3x3
    self:add(3, 2, false,
        {
            {1, 1, -1},
            {-2, -2, 1},
            {-2, -2, 1}
        }, {
            {0, 0, 0},
            {1, 2, 0},
            {2, 1, 0}
        }
    )

    self:add(4, 1, true,
        {
            {-1, -1, -1},
            {1, -2, 1},
            {1, -2, 1}
        }, {
            {0, 0, 0},
            {0, 2, 0},
            {0, 1, 0}
        }
    )

    self:add(5, 1, true,
        {
            {-1, -1, -1},
            {1, -2, 1},
            {1, -2, -1}
        }, {
            {0, 0, 0},
            {0, 2, 0},
            {0, 1, 0}
        }
    )

    self:add(5, 1, true,
        {
            {-1, -1, -1},
            {1, -2, -1},
            {1, -2, 1}
        }, {
            {0, 0, 0},
            {0, 2, 0},
            {0, 1, 0}
        }
    )

    -- 3x4
    self:add(5, 3, true, 
        {
            { 1,  1, -1},
            {-2, -2, -1},
            {-2,  2, -1},
            {-2,  1, 0}
        }, {
            {0, 0, 0},
            {1, 2, 0},
            {2, 0, 0},
            {1, 0, 0}
        }
    )

    self:add(5, 3, true, 
        {
            { 1,  1, -1},
            {-2, -2, -1},
            {-2,  2, -1},
            {-2,  1, 0}
        }, {
            {0, 0, 0},
            {1, 2, 0},
            {1, 0, 0},
            {2, 0, 0}
        }
    )
end
