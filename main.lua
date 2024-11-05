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
    x   * sprites
    x       > 16x16 sprites
    x       > 8x8 sprites
    * board generation
    x       > fair
        > insidious
        > unfair
    * gui (use necrodancer gui?)
        > timer
        > mine count
        > camera
    * menu
        > dimension selection
        > screen size?
        > sprite set
        > fairness
    * controls
    x       > mouse
        > mouse scrolling
        > keyboard
        > scheme swapping

]]

-- a lib of mine with useful functions
rm("/ram/cart/lib") -- makes sure at most one copy is present
mount("/ram/cart/lib", "/ram/lib")

include("board.lua")
include("window.lua")
include("cursor.lua")

include("lib/queue.lua")
include("lib/logger.lua")
include("lib/kbm.lua")
include("lib/clock.lua")
include("lib/camera.lua")

include("lib/tstr.lua")

function _init()

    q = Q:new()
    logger = Logger:new("appdata/mineswept/logs")

    -- keyboard and mouse
    kbm = KBM:new({"lmb", "rmb", "x", "z", "left", "right", "up", "down", "`"})

    -- tracks time
    clock = Clock:new()

    cam = Camera:new()

    cursor = Cursor:new()

    -- creates the map
    local w, h = 6, 8
    local bombs = 12
    local fairness = 2
    local oldsprites = false
    board = Board:new(w, h, bombs, fairness, oldsprites)

    wind = Window:new()

end


function _update()

    cursor:update()

    -- handles input
    input()

    wind:update()


    -- updates the clock
    clock()

    q:add(cursor.pos)
    q:add(cursor.pos // board.d)
    q:add(board:value(cursor.pos.x // board.d, cursor.pos.y // board.d))
end

function input()

    -- reveal / cord
    if (cursor.action == "reveal") board:lclick(cursor)

    -- flag
    if (cursor.action == "flag") board:rclick(cursor)

    -- debug; reveal all
    if (kbm:released("`")) board:reveal_all()
end

function _draw()

    -- draws the main window
    wind:draw()

    q:print(4, 200)
end