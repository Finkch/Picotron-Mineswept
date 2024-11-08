--[[
    mineswept is a minesweeper clone where you are guaranteed to lose
    on the second move. that is, unless you start a normal game with a
    hidden key combo.

    can be played with either mouse or keyboard.

    soon to be a widget!
]]


--[[    todo

    * gameplay
    x       > reveal
    x       > cord
    x       > flag
        > gameover
        > reveal ONLY MINES on gameover
    x   * sprites
    x       > 16x16 sprites
    x       > 8x8 sprites
    * board generation
    x       > fair
        > insidious
        > unfair
    x   * gui (use necrodancer gui?)
    x       > timer
    x       > mine count
    x       > camera
    * menu
        > dimension selection
        > screen size?
        > sprite set
        > fairness
    x   * controls
    x       > mouse
    x       > mouse scrolling
    x       > keyboard
    x       > scheme swapping

    * starting new game returns cursor to centre screen

]]

-- a lib of mine with useful functions
rm("/ram/cart/lib") -- makes sure at most one copy is present
mount("/ram/cart/lib", "/ram/lib")

include("board.lua")
include("window.lua")
include("cursor.lua")
include("game.lua")

include("lib/queue.lua")
include("lib/logger.lua")
include("lib/kbm.lua")
include("lib/clock.lua")
include("lib/camera.lua")
include("lib/vec.lua")

include("lib/tstr.lua")

function _init()

    q = Q:new()
    logger = Logger:new("appdata/mineswept/logs")

    -- keyboard and mouse
    kbm = KBM:new({"lmb", "rmb", "x", "z", "left", "right", "up", "down", "space", "`"})

    -- tracks time
    clock = Clock:new()

    cam = Camera:new()

    cursor = Cursor:new()

    -- creates the map
    local w, h = 8, 8
    local bombs = w * h / 4
    local fairness = 2
    local oldsprites = false
    board = Board:new(w, h, bombs, fairness, oldsprites)

    wind = Window:new()

    wind.focal = -Vec:new(board.w / 2 * board.d, board.h / 2 * board.d)
    wind:edges()

    state = State:new({"menu", "play", "gameover"})
    state._change = function(self, continue)
        
        if self:__eq("menu") then

            -- resets menu index
            self.data.mi = 0

            -- reset the clock
            clock.f = 0

        elseif self:__eq("gameover") then

            -- reveals mines
            board:reveal_mines()

        -- when starting a game...
        elseif self:__eq("play") then

            -- create a new board
            board = Board:new(board.w, board.h, board.bombs, board.fairness, board.oldsprites)

            -- moves the cursor to the centre of the screen
            cursor.pos = Vec:new(480 / 2, 270 / 2)

            -- reset the clock
            clock.f = 0

            -- focus the camera to the centre of the board
            wind.focal = -Vec:new(board.w / 2 * board.d, board.h / 2 * board.d)

        end
    end

    -- default values
    state.data.mi = 0   -- menu index
    state.data.ml = 3   -- menu length
    state.data.mind = 4
    state.data.maxd = 32
    state.data.minmines = 4
    state.data.maxmines = -1 -- will be update to match board dimensions

    state:change("menu")

end


function _update()

    -- polls kbm
    kbm:update()

    gamestate(state)

end

function _draw()

    -- draws the main window
    wind:draw()

    q:print(4, 150, 8)
end