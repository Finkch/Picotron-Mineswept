--[[
    stores various 50-50s along with their mine requirements
]]

Fifty = {}
Fifty.__index = Fifty
Fifty.__type = "fifty"

-- all grids will face the bottom left corner by default
function Fifty:new(grid, mines)

    local f = {
        grid = grid,
        w = #grid[0],
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