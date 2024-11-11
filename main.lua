--[[
    mineswept is a minesweeper clone where you are guaranteed to lose
    on the second move. that is, unless you start a normal game with a
    hidden key combo.

    can be played with either mouse or keyboard.

    soon to be a widget!
]]


--[[    todo

    x   * gameplay
    x       > reveal
    x       > cord
    x       > flag
    x       > gameover loss
    x       > gameover win
    x       > reveal ONLY MINES on gameover
    x   * sprites
    x       > 16x16 sprites
    x       > 8x8 sprites
    * board generation
    x       > fair
        > insidious
        > unfair
    x   * gui (use necrodancer gui?); no.
    x       > timer
    x       > mine count
    x       > camera
    * menu
    x       > dimension selection
    x       > mine selection
        > screen size?
        > sprite set
        > fairness
    x   * controls
    x       > mouse
    x       > mouse scrolling
    x       > keyboard
    x       > scheme swapping

    x   * starting new game returns cursor to centre screen
    x   * start new game keep map centred
    x   * memory leak?
    x   * going oob on menu board dimensions falsly updates mines
    x   * can't create board with d < 8; can create, just forgot to clear previous boards
    x   * losing during cord causes false flag to have incorrect sprite (reveal then cord is issue?)

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

    -- creates the map.
    -- these values don't matter since new board will be made during bootup
    board = Board:new(8, 8, 12, 0, false)

    -- creates the display window
    wind = Window:new()

    -- creates the state machine
    state = State:new({"menu", "play", "gameover"})

    -- executes on a state change
    state._change = function(self, continue)
        
        if self:__eq("menu") then

            -- resets menu index
            self.data.mi = 0

            -- reset the clock
            clock.f = 0

        elseif self:__eq("gameover") then

            -- do nothing special

        -- when starting a game...
        elseif self:__eq("play") then

            -- clears any previous boards
            board:clear()

            -- create a new board
            board = Board:new(board.w, board.h, board.bombs, self.data.fairness, board.oldsprites)

            -- moves the cursor to the centre of the screen
            cursor.pos = Vec:new(480 / 2, 270 / 2)

            -- reset the clock
            clock.f = 0

            -- resets state values
            self.data.win = false

            -- precalculations for this board
            wind:edges()

            -- focus the camera to the centre of the board
            wind.focal = -Vec:new(board.w / 2 * board.d, board.h / 2 * board.d)

            -- updates the window to show the board immediately
            wind:update()

        end
    end

    -- default values
    state.data.mi = 0   -- menu index
    state.data.ml = 4   -- menu length
    state.data.mind = 4
    state.data.maxd = 32
    state.data.minmines = 4
    state.data.maxmines = -1 -- will be update to match board dimensions
    state.data.fairness = 1  -- tracking fairness here, not board, for interround continuity

    -- moves state to menu
    state:change("menu")

end


function _update()

    -- polls kbm
    kbm:update()

    -- updates based on the current state
    gamestate(state)

end

function _draw()

    -- draws the main window
    wind:draw()

    -- debug
    q:print(4, 150, 8)
end