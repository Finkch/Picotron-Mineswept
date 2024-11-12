--[[
    stores various 50-50s along with their mine requirements
]]

Fifty = {}
Fifty.__index = Fifty
Fifty.__type = "fifty"

-- all grids will face the bottom left corner by default.
--  0   = normal cell
--  1   = mine
--  2   = false flag
function Fifty:new(grid, mines)

    local f = {
        grid = grid,
        w = #grid[1],
        h = #grid,
        mines = mines
    }
    setmetatable(f, Fifty)
    return f
end



-- rotates the fifty's grid to fit in other corners
function Fifty:rotate90()
    local grid = self.grid
    local numRows = #grid
    local numCols = #grid[1]
    local newGrid = {}

    for col = 1, numCols do
        newGrid[col] = {}
        for row = numRows, 1, -1 do
            newGrid[col][numRows - row + 1] = grid[row][col]
        end
    end
    return Fifty:new(newGrid, self.mines)
end

function Fifty:rotate180()
    local grid = self.grid
    local numRows = #grid
    local numCols = #grid[1]
    local newGrid = {}

    for row = numRows, 1, -1 do
        newGrid[numRows - row + 1] = {}
        for col = numCols, 1, -1 do
            newGrid[numRows - row + 1][numCols - col + 1] = grid[row][col]
        end
    end
    return Fifty:new(newGrid, self.mines)
end

function Fifty:rotate270()
    local grid = self.grid
    local numRows = #grid
    local numCols = #grid[1]
    local newGrid = {}

    for col = numCols, 1, -1 do
        newGrid[numCols - col + 1] = {}
        for row = 1, numRows do
            newGrid[numCols - col + 1][row] = grid[row][col]
        end
    end
    return Fifty:new(newGrid, self.mines)
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






-- initialises various 50-50s
function init_fifties()
    fifties = {}

    add(fifties, Fifty:new({
            {1, 1},
            {2, 0},
            {2, 0}
        }, 3)
    )
end