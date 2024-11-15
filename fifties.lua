--[[
    stores various 50-50s along with their mine requirements
]]

Fifty = {}
Fifty.__index = Fifty
Fifty.__type = "fifty"

-- all grids will face the bottom left corner by default.
--  n > 0   = quantum count; n = count of adjacent quantum mines
--  0       = obeys fair generation rules
--  -1      = mine
--  -2      = false flag
--
-- a mine grid, or mgrid, is a fifty that is a specific placement of mines.
-- the active bits represent which variants in which that cell contains a mine.
function Fifty:new(grid, mgrid, mines, reflectable, weight)
    local f = {
        grid = grid,
        mgrid = mgrid,
        w = #grid[1],
        h = #grid,
        mines = mines,              -- mines needed for this grid
        reflectable = reflectable,  -- whether or not it can be usefully reflected about the diagonal
        weight = weight or 1        -- how common this pattern appears
    }
    setmetatable(f, Fifty)
    return f
end

-- returns a potentially modified copy
function Fifty:copy(grid, mgrid)
    if (not grid) grid = self.grid
    if (not mgrid) mgrid = self.mgrid

    return Fifty:new(
        grid,
        mgrid,
        self.mines,
        self.reflectable,
        self.weight
    )
end


-- rotates the fifty's grid to fit in other corners.
-- also reflects a grid about the off-diagonal.
-- methods that begin with an '_' were made by ChatGPT

function Fifty:rotate90()
    return self:copy(
        self:_rotate90(self.grid), 
        self:_rotate90(self.mgrid)
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
    return self:copy(
        self:_rotate180(self.grid), 
        self:_rotate180(self.mgrid)
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
    return self:copy(
        self:_rotate270(self.grid), 
        self:_rotate270(self.mgrid)
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
    return self:copy(
        self:_reflect(self.grid), 
        self:_reflect(self.mgrid)
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

-- chooses a random element according to the weights.
-- the element must satisfy the given function
function Fifties:rnd(condition)

    local weight = 0            -- running/prefix sum
    local valid_fifties = {}    -- list of valid choices
    local cumulatives = {}      -- cumulative weight up to the i-th item

    -- gets valid items and their sum of weights
    for _, fifty in ipairs(self.grids) do
        if condition(fifty) then
            weight += fifty.weight
            add(cumulatives, weight)
            add(valid_fifties, fifty)
        end
    end

    -- returns an error message if no item has satisfied the condition
    assert(#valid_fifties > 0, "sorry! i'll cheat better next time (couldn't find valid 50-50).")

    -- gets a random number to select the item
    local choice = rnd(weight)

    -- finds and returns the corresponding choice
    for i = 1, #valid_fifties do
        if (choice < cumulatives[i]) return valid_fifties[i]
    end

    assert(false, "sorry! i'll cheat better next time (rnd call was out of table during 50-50 selection).")
end

-- adds a new 50-50 grid to the collection
function Fifties:add(mines, reflectable, weight, grid, mgrid)
    add(self.grids, Fifty:new(grid, mgrid, mines, reflectable, weight))
end


-- edit this to add 50-50s
function Fifties:_init()

    -- 2x3
    self:add(3, true, 2,
        {
            {-1, -1},
            {-2, 0},
            {-2, 0}
        }, {
            {0, 0},
            {1, 0},
            {2, 0}
        }
    )

    -- 3x3
    self:add(3, false, 1,
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

    self:add(4, true, 1,
        {
            {-1, -1, -1},
            {0, -2, 0},
            {0, -2, 0}
        }, {
            {0, 0, 0},
            {0, 2, 0},
            {0, 1, 0}
        }
    )


    -- 3x4
    self:add(5, true, 1,
        {
            { 0,  0, -1},
            {-2, -2, -1},
            {-2,  0, -1},
            {-2,  0, 0}
        }, {
            {0, 0, 0},
            {5, 10, 0},
            {6, 0, 0},
            {9, 0, 0}
        }
    )
end
