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

