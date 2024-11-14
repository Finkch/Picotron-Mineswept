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
    x   * board generation
    x       > fair
    x       > insidious
    x       > unfair
    x   * gui (use necrodancer gui?); no.
    x       > timer
    x       > mine count
    x       > camera
    x   * menu
    x       > dimension selection
    x       > mine selection
    -       > screen size?
    -       > sprite set
    x       > fairness
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
    x   * secret fairness 2 needs to reset to menu fairness upon returning to menu
    x   * menu button prompts change depending on current input method
    x       > menu mouse inputs
    x   * hide cursor on menu
    -   * start in mouse false mode
    x   * fix cruel mode deleting flags adjacent to first reveal
    x   * on insidious, game over also runs second gen
    * allow insidious gens not in corners
    x   * lshift also pans/speeds up cursor
    * get tighter bounds for insidious through smart reflection of 3x2
    * insidious loses on the n + mth move (allow moves that result in further 50-50s)
    * demo game with set board to showcase colours...but it's actually insiidous
    * show win-loss ratio on gameover screen
        > write to appdata
        > reset by through grave on menu/gameover?
    * title on menu screen?
    x   * don't reset cursor to centre screen if playing again
    x       > track previous gamestate
    * move random 50-50 selection into fifties
        > add weight to given types
        > find clever way of compressing similar layouts
    * fix insidious gen starting on non-0 due to inideal 50-50 placement

    * refactor board
    x       > better tile manipulation logic (clean functions, no if tile(is_flag_false) lying about)
        > move board to memory to allow alternative sprite sets?
            - or simply wrap mg/set functions?
            - infinite board (for quantum) might not work using map
        > small sprites!

    * quantum minesweeper
        > infinite board
        > density of mines, not count of mines
        > board is generated as play progresses
        > always results in a valid board
        > difficulty chooses probability of random choice succeeding
            - easy:     guaranteed success (where possible)
            - normal:   1/rho chance of success
            - hard:     guaranteed loss (where possible)
        > victory is tracked through tiles revealed
        > what is minimum density to prevent an infinite reveal?

]]

-- a lib of mine with useful functions
rm("/ram/cart/lib") -- makes sure at most one copy is present
mount("/ram/cart/lib", "/ram/lib")

include("board.lua")
include("window.lua")
include("cursor.lua")
include("game.lua")
include("fifties.lua")

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
    kbm = KBM:new({"lmb", "rmb", "x", "z", "left", "right", "up", "down", "space", "lshift"})

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

            -- resets displayed fairness value
            self.data.fairness = self.data.menu_fairness

            -- resets clock
            clock.f = 0


        elseif self:__eq("gameover") then

            -- do nothing special

        -- when starting a game...
        elseif self:__eq("play") then

            -- clears any previous boards
            board:clear()

            -- create a new board
            board = Board:new(board.w, board.h, board.bombs, self.data.fairness, board.oldsprites)

            -- precalculations for this board
            wind:edges()

            -- focus the camera to the centre of the board
            if self.previous == "menu" then
                cursor.pos = Vec:new(480 / 2, 270 / 2)
                wind.focal = -Vec:new(board.w / 2 * board.d, board.h / 2 * board.d)
            end

            -- updates the window to show the board immediately
            wind:update()

            -- reset the clock
            clock.f = 0

            -- resets state values
            self.data.win = false

        end
    end

    -- default values
    state.data.mi = 0   -- menu index
    state.data.ml = 4   -- menu length
    state.data.mind = 8     -- min and max board dimensions
    state.data.maxd = 32
    state.data.minmines = 6
    state.data.maxmines = -1 -- will be update to match board dimensions
    state.data.fairness = 0  -- tracking fairness here, not board, for interround continuity
    state.data.menu_fairness = 0

    -- moves state to menu
    state:change("menu")

    -- initialises list of possible 50-50s
    fifties = Fifties:new()

    -- do debug printout
    debug = false
end


function _update()

    -- polls kbm
    kbm:update()

    -- handles input
    cursor:update()

    -- updates gui
    wind:update()

    -- updates based on the current state
    gamestate(state)

    if debug then
        q:add(cursor:posm())
        q:add(Vec:new(cursor:map(board.d)))
        q:add(board:value(cursor:map(board.d)))
        q:add(state.state)
        q:add(state.previous)
    end
end

function _draw()

    -- draws the main window
    wind:draw()

    -- debug
    q:print(4, 150, 8)
end