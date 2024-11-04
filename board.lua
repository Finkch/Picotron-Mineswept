--[[pod_format="raw",created="2024-11-04 21:31:02",modified="2024-11-04 21:33:57",revision=5]]
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

include("lib/tstr.lua")

-- some constants for the checking flags
is_mine     = 7
is_flag     = 6
is_reveal   = 5



Board = {}
Board.__index = Board
Board.__type  = "board"

function Board:new(w, h, bombs, fairness, oldsprites)

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
        bombs = bombs,
        flags = 0,
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
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do
            mset(i, j, self.bs)
        end
    end

    -- generates the board according to fairness value
    if self.fairness == 0 then
        self:generate_unfair()
    elseif self.fairness == 1 then
        self:generate_insidious()
    else
        self:generate_fair()
    end
end

-- creates a regular ol' board of mineswept
function Board:generate_fair()

    -- creates a 1d list of all cells
    local cells = {}
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do
            add(cells, {i, j})
        end
    end

    -- adds mines to the map
    for i = 0, self.bombs - 1 do

        -- pops a random item from the list
        local bombify = del(cells, rnd(cells))

        -- turns the popped cell into a mine.
        -- ...i forgor lua was 1-index :^(
        mset(bombify[1], bombify[2], self.bs + 9)
    end

    -- for the remaining cells, count adjacent mines add set the cell's value
    for i = 1, #cells do

        -- counts neighbours
        local count = 0

        for dx = -1, 1 do
            for dy = -1, 1 do
                if not (dx == 0 and dy == 0) then   -- don't consider self

                    -- check if neighbour is a mine; if so, increment count
                    if (self:tile(cells[i][1] + dx, cells[i][2] + dy, is_mine)) count += 1
                end
            end
        end

        -- sets the value of the tile
        mset(cells[i][1], cells[i][2], self.bs + count)
    end
end

-- generates a guaranteed loss, that will take a while to uncover
function Board:generate_insidious()
    -- todo
end

-- lose in two moves
function Board:generate_unfair()
    -- todo
end


-- reveals a tile
function Board:reveal(x, y, f)
    f = f or false  -- force reveal
    
    -- only reveals if the tile if it is not already revealed
    -- or if it is not a flag (unless force reveal)
    if (self:tile(x, y, is_reveal) or self:tile(x, y, is_flag)) and not f then
        return
    end


    -- reveal a flag
    if self:tile(x, y, is_flag) then

        -- flag is correct
        if self:tile(x, y, is_mine) then
            mset(x, y, self.bs + 25)
        
        -- flag is incorrect
        else
            mset(x, y, self.bs + 42)
        end

    -- reveal a normal tile
    else
        mset(x, y, mget(x, y) + 16)
    end
end


-- reveals all tiles
function Board:reveal_all()

    -- force reveal on all tiles
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do

            self:reveal(i, j, true)
        end
    end
end



-- checks whether a given flag is set.
-- if the cell is out-of-bounds, return false
function Board:tile(x, y, f)

    -- if out of bounds, return false
    if (x < 0 or y < y or x >= self.w or y >= self.h) return false

    -- return whether the flag is set.
    -- huh, there's a bug in picotron! fget(n, f) should return the
    -- state of flag f when f is specified. currently, it ingores the
    -- f parameter and returns the flag bitmap regardless.
    -- here, i unpack the flag and check it
    return (fget(mget(x, y)) >> f) & 1 == 1
end



-- draws the map
function Board:draw()

    -- is sprites are 16x16 (new sprite set), draw normally
    if self.bs == 8 then
        map(0, 0)
        return
    end

    -- when using old sprites, must draw each sprite since map assumes
    -- sprites are 16x16
    for i = 0, self.w do
        for j = 0, self.h do
            map(i, j, i * self.d, j * self.d, 1, 1)
        end
    end
end
