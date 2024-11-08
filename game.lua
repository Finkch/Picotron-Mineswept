--[[
    handles the gamestates
]]

State = {}
State.__index = State
State.__type = "state"


function State:new(initial, states)
    states = states or {}

    local s = {
        state = initial,
        states = states
    }

    setmetatable(s, State)
    return s
end

function State:change() end -- override me!

function State:__eq(state)
    return self.state == state
end

function State:__tostring()
    return self.state
end


function gamestate(state)

    if state:__eq("menu")then

    elseif state:__eq("play") then

        play()

    elseif state:__eq("gameover") then
    
    else

        q:add("unknown state: " .. state.state)
    end
end


-- mineswept controls
function play()
    
    -- handles input
    play_input()


    -- updates the clock
    clock()

    q:add(cursor:posm())
    q:add(Vec:new(cursor:map(board.d)))
    q:add(board:value(cursor:map(board.d)))
end

function play_input()

    -- reveal / cord
    if (cursor.action == "reveal") board:lclick(cursor)

    -- flag
    if (cursor.action == "flag") board:rclick(cursor)

    -- debug; reveal all
    if (kbm:released("`")) board:reveal_all()
end