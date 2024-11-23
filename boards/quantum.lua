--[[
    a board with infinite dimensions where mines exist in all
    possible vairantions simultanously.
    defined by mine density rather than count of mines.
]]

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
end


-- ensures grid position exists.
function QuantumBoard:inbounds(x, y)
end


-- quick all. same as all, but faster.
-- uses pregenerated list, but lacks option to go over only subset.
function QuantumBoard:qall(apply, condition)
end


-- creates an empty grid
function QuantumBoard:empty()
end


-- creates the starting board state
function QuantumBoard:generate(x, y)
end


-- game actions for left click: reveal, cord
function QuantumBoard:lclick(cursor) 
end


-- game actions for right click: flag
function QuantumBoard:rclick(cursor)
end