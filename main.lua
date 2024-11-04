--[[
    mineswept is a minesweeper clone where you are guaranteed to lose
    on the second move. that is, unless you start a normal game with a
    hidden key combo.

    can be played with either mouse or keyboard.

    soon to be a widget!
]]

-- a lib of mine with useful functions
rm("/ram/cart/lib") -- makes sure at most one copy is present
mount("/ram/cart/lib", "/ram/lib")

include("board.lua")

include("lib/queue.lua")
include("lib/logger.lua")
include("lib/kbm.lua")

function _init()

    q = Q:new()
    logger = Logger:new("appdata/mineswept/logs")

    -- keyboard and mouse
    kbm = KBM:new("lbm", "rmb")

    -- creates the map
    local w, h = 6, 8
    local bombs = 12
    local fairness = 2
    local oldsprites = false
    board = Board:new(w, h, bombs, fairness, oldsprites)

    board:generate()
end


function _update()

    -- polls kbm
    kbm:update()

    -- handles input
    input()


    q:add(kbm.pos)
end

function input()
    if kbm:released("lbm") then
        board:reveal(kbm.pos.x // board.d, kbm.pos.y // board.b)
    end

    if kbm:releaved("rmb") then
        board:flag(kbm.pos.x // board.d, kbm.pos.y // board.d)
    end
end

function _draw()
    cls()

    q:print(0, 200)

    board:draw()
end