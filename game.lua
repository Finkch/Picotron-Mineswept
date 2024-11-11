--[[
    handles the gamestates
]]

State = {}
State.__index = State
State.__type = "state"


function State:new(states)
    states = states or {}

    local s = {
        state = nil,
        states = states,
        data = {}           -- misc data that doesn't fit elsewhere
    }

    setmetatable(s, State)
    return s
end

function State:change(state)
    self.state = state

    self:_change()
end

function State:_change() end -- override me!

function State:__eq(state)
    return self.state == state
end

function State:__tostring()
    return self.state
end


function gamestate(state)

    if state:__eq("menu") then

        menu()

    elseif state:__eq("play") then
        
        -- update key elements
        wind:update()
        cursor:update()

        play()

    elseif state:__eq("gameover") then

        -- update key elements
        wind:update()
        cursor:update()

        gameover()
    
    end
end


-- menus
function menu()
    menu_input()
end

function menu_input()
    
    -- navigates through the manu
    if (kbm:pressed("down")) then
        state.data.mi += 1
        state.data.mi %= state.data.ml
    end

    if (kbm:pressed("up")) then
        state.data.mi -= 1
        state.data.mi %= state.data.ml
    end

    -- updates appropraite item
    if state.data.mi == 0 then

        -- changes selected item
        if kbm:pressedr("right") then 
            board.w += 1
            board.w = mid(state.data.mind, board.w, state.data.maxd)

            board.bombs = board.w * board.h // 5
        elseif kbm:pressedr("left") then
            board.w -= 1
            board.w = mid(state.data.mind, board.w, state.data.maxd)

            board.bombs = board.w * board.h // 5
        end

    elseif state.data.mi == 1 then

        -- changes selected item
        if kbm:pressedr("right") then 
            board.h += 1
            board.h = mid(state.data.mind, board.h, state.data.maxd)

            board.bombs = board.w * board.h // 5
        elseif kbm:pressedr("left") then
            board.h -= 1
            board.h = mid(state.data.mind, board.h, state.data.maxd)

            board.bombs = board.w * board.h // 5
        end

    elseif state.data.mi == 2 then

        -- changes selected item
        if (kbm:pressedr("right")) board.bombs += 1
        if (kbm:pressedr("left")) board.bombs -= 1
    
    elseif state.data.mi == 3 then

        -- changes selected item.
        -- only two options, so toggle between them
        if (kbm:pressed("right") or kbm:pressed("left")) state.data.fairness = (state.data.fairness + 1) % 2
    end

    -- enforces bounds on mines
    state.data.maxmines = mid(4, (board.w - 1) * (board.h - 1) - 1, 999)
    board.bombs = mid(state.data.minmines, board.bombs, state.data.maxmines)


    -- starts the game
    if kbm:released("x") then

        -- secret input for normal play
        if (kbm:held("z"))  state.data.fairness = 2

        state:change("play")
    end

end


-- mineswept controls
function play()
    
    -- handles input
    play_input()

    -- updates the clock after the first reveal
    if (board.reveals > 0) clock()

    -- check if the game has ended to reveal mines
    if (state:__eq("gameover")) board:reveal_mines()


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


-- end of game logic
function gameover()
    -- nothing to do here but check for new game or menu
    gameover_input()
end

function gameover_input()

    -- newgame
    if (cursor.action == "reveal") state:change("play")

    -- return to menu
    if (cursor.action == "flag") state:change("menu")

end