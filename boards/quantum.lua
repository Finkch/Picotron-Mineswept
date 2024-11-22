--[[
    a board with infinite dimensions where mines exist in all
    possible vairantions simultanously.
    defined by mine density rather than count of mines.
]]

include("board/boards.lua")

QuantumBoard = {}
QuantumBoard.__index = QuantumBoard
QuantumBoard.__type = "quantumboard"

-- Board header so I know what each field means
--function ClassicBoard:new(w, h, bombs, fairness, oldsprites)
function QuantumBoard:new(density, generosity, oldsprites)
    
    -- sprite info
    local base_sprite   = 72
    local d             = 8
    if not oldsprites then
        base_sprite = 8
        d           = 16
    end

    local ib = {
        density = density,
        generosity = generosity,
        bs = base_sprite,
        d = d,
    }


    setmetatable(ib, QuantumBoard)
    return ib
end