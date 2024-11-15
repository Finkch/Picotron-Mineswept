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
        previous = nil,
        states = states,
        data = {}           -- misc data that doesn't fit elsewhere
    }

    setmetatable(s, State)
    return s
end

function State:change(state)
    self.previous = self.state
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
        play()
    elseif state:__eq("gameover") then
        gameover()
    end
end


-- menus
function menu()
    menu_input()
end

function menu_input()
    
    if cursor.mouse then
        menu_input_mouse()
    else
        menu_input_keys()
    end

    -- enforces bounds on mines
    state.data.maxmines = mid(6, (board.w - 1) * (board.h - 1) - 1, 999)
    board.bombs = mid(state.data.minmines, board.bombs, state.data.maxmines)


    -- reset score
    if (kbm:pressed("`")) winlosser:clear()

    
    -- starts the game
    if kbm:released("x") or kbm:released("rmb") then

        -- secret input for normal play
        if (kbm:held("z"))  state.data.fairness = 2

        state:change("play")
    end

end

-- menu input with keyboard
function menu_input_keys()

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
        if kbm:pressed("right") or kbm:pressed("left") then
            state.data.menu_fairness = (state.data.menu_fairness + 1) % 2
            state.data.fairness = state.data.menu_fairness
        end
    end
end

function menu_input_mouse()

    -- precalcs
    local wm = wind.w / 2
    
    local b = 30
    local t = 80 - b / 4

    local pw = print("0000", 500, 500) - 500

    -- hover over menu item to select it
    if t < kbm.spos.y and kbm.spos.y < t + b then
        state.data.mi = 0
    elseif t + b < kbm.spos.y and kbm.spos.y < t + 2 * b then
        state.data.mi = 1
    elseif t + 2 * b < kbm.spos.y and kbm.spos.y < t + 3 * b then
        state.data.mi = 2
    elseif t + 3 * b < kbm.spos.y and kbm.spos.y < t + 4 * b then
        state.data.mi = 3
    end

    -- when the user clicks on a menu item
    --if state.data.mi > -1 and kbm:pressedr("lmb") then
    if state.data.mi > -1 and kbm:pressedr("lmb") then

        local select = false    -- if the user clicked within the target area
        local left = false      -- decrement?

        -- figure out if it's on the left or right
        -- i.e., increment or decrement value
        if wm - pw / 2 - b < kbm.spos.x and kbm.spos.x < wm - pw / 2 then
            select = true
            left = true

        elseif wm + pw / 2 < kbm.spos.x and kbm.spos.x < wm + pw / 2 + b then
            select = true
            left = false
        end

        if (not select) return


        -- updates appropraite item
        if state.data.mi == 0 then

            -- changes selected item
            if not left then 
                board.w += 1
                board.w = mid(state.data.mind, board.w, state.data.maxd)

                board.bombs = board.w * board.h // 5
            elseif left then
                board.w -= 1
                board.w = mid(state.data.mind, board.w, state.data.maxd)

                board.bombs = board.w * board.h // 5
            end

        elseif state.data.mi == 1 then

            -- changes selected item
            if not left then 
                board.h += 1
                board.h = mid(state.data.mind, board.h, state.data.maxd)

                board.bombs = board.w * board.h // 5
            elseif left then
                board.h -= 1
                board.h = mid(state.data.mind, board.h, state.data.maxd)

                board.bombs = board.w * board.h // 5
            end

        elseif state.data.mi == 2 then

            -- changes selected item
            if (not left) board.bombs += 1
            if (left) board.bombs -= 1
        
        elseif state.data.mi == 3 then

            -- changes selected item.
            -- only two options, so toggle between them
            state.data.menu_fairness = (state.data.menu_fairness + 1) % 2
            state.data.fairness = state.data.menu_fairness
        end
    end
end


-- mineswept controls
function play()
    
    -- handles input
    play_input()

    -- updates the clock after the first reveal
    if (board.reveals > 0) clock()

end

function play_input()

    -- reveal / cord
    if (cursor.action == "reveal") board:lclick(cursor)

    -- flag
    if (cursor.action == "flag") board:rclick(cursor)

    -- lose game.
    -- must be after reveal, otherwise no board has been generated
    if (board.reveals > 0 and kbm:pressed("`")) state:change("gameover")
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

    -- reset score
    if (kbm:pressed("`")) winlosser:clear()

end