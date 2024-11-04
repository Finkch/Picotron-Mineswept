--[[
    the board is an wxh grid. each tile is an object that encodes
    the state of that tile; whether its a bomb or its value.

    the board is encoded through the map. while it could be stored in
    memory in a 2d table, the map offers an elegant solution. there
    are 9 sprites representing unrevealed tiles, corresponding to
    tiles with a value of 0-9 as well as a mine; the difference is
    denoted by the sprites' flags.
    that said, there still is a board object. it contains handy-dandy
    methods of interacting with the map.

    the strategy (normal) to build a board is as follows:
    * create a list of all tiles.
    * pop a random tile; turn the tile into a bomb tile
    * after mines have been placed, go over remaining tiles and
        tally the count of neighbouring mines

    the strategy (swept, naive) to build a baord is as follows:
    * don't do anything to build the board.
    * after the players selects the first tile, reveal is as 1-8
    * after the player selects a second tile, reveal it as a bomb
    * place mines such that the board could be valid

    the strategy (swept, advanced) to build a baord is as follows:
    * first, place a 50-50 on the board; this 50-50 is tracked
    * as the rest of the board is built, build according to first
        strategy, except maintining boundary conditions
    * when the player encounters the tracked 50-50, place a mine
        under whichever tile the user picks
    * place mines in the tracked 50-50 in accordance; otherwise
        reveal the board as per normal
]]

Board = {}
Board.__index = Board
Board.__type  = "board"

function Board:new(w, h, fairness, oldsprites)

    -- default values
    fairness = fairness or 0


    -- sprite info
    local base_sprite   = 72
    local d             = 8
    if not oldsprites then
        base_sprite = 8
        d           = 16
    end


    -- board object
    local b = {
        w = w,
        h = h,
        fairness = fairness,    -- 0 = two move, 1 = insidious, 2 = standard
        bs = base_sprite,       -- which sprite represents unrevealed 0
        d = d                   -- cell side length
    }

    setmetatable(b, Board)
    return b
end

-- creates a new board
function Board:generate()

    -- starts by creating a grid of unrevealed zeroes
    for i = 0, self.w do
        for j = 0, self.h do
            mset(i, j, self.bs)
        end
    end


end

-- draws the map
function Board:draw()

    -- is sprites are 16x16 (new sprite set), draw normally
    if self.bs == 8 then
        map(0, 0)
        return
    end

    -- when using old sprites, must draw each sprite since map assumes
    -- sprites are 16x15
    for i = 0, self.w do
        for j = 0, self.h do
            map(i, j, i * self.d, j * self.d, 1, 1)
        end
    end
end
