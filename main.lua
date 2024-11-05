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

include("lib/queue.lua")
include("lib/logger.lua")
include("lib/kbm.lua")
include("lib/Clock.lua")

function _init()

    q = Q:new()
    logger = Logger:new("appdata/mineswept/logs")

    -- keyboard and mouse
    kbm = KBM:new({"lmb", "rmb", "x"})

    -- tracks time
    clock = Clock:new()

    -- creates the map
    local w, h = 6, 8
    local bombs = 12
    local fairness = 2
    local oldsprites = false
    board = Board:new(w, h, bombs, fairness, oldsprites)
end


function _update()

    -- polls kbm
    kbm:update()

    -- handles input
    input()


    -- updates the clock
    clock()

    q:add(kbm.pos)
    q:add(board:value(kbm.pos.x // board.d, kbm.pos.y // board.d))
end

function input()

    if kbm:released("lmb") then

        -- converts from screen coordinates to tile coordinates
        board:lclick(kbm.pos)
    end

    if kbm:released("rmb") then

        -- converts from screen coordinates to tile coordinates
        board:rclick(kbm.pos)
    end

    if kbm:released("x") then
        board:reveal_all()
    end
end

function _draw()
    cls()

    q:print(0, 200)

    board:draw()
end