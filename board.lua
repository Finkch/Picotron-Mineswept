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
        

-- some constants for the checking flags
is_mine     = 7
is_flag     = 6
is_reveal   = 5
is_false    = 4


-- board object
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
        reveals = 0,
        fairness = fairness,    -- 0 = two move, 1 = insidious, 2 = standard
        bs = base_sprite,       -- which sprite represents unrevealed 0
        d = d                   -- cell side length
    }

    setmetatable(b, Board)

    -- creates a grid of unrevealed zeroes
    b:empty()

    return b
end

-- creates a new board
function Board:generate(dni)

    dni = dni or {}

    -- generates the board according to fairness value
    if self.fairness == 0 then
        self:generate_unfair(dni)
    elseif self.fairness == 1 then
        self:generate_insidious(dni)
    else


        -- sets false flags ensure first click reveals a zero
        mset(dni[1][1], dni[1][2], self.bs + 10)
        for dx = -1, 1 do
            for dy = -1, 1 do
                if (not (dx == 0 and dy == 0) and self:inbounds(dni[1][1] + dx, dni[1][2] + dy))  mset(dni[1][1] + dx, dni[1][2] + dy, self.bs + 10)
            end
        end

        self:generate_fair(dni)
    end
end

function Board:empty()
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do
            mset(i, j, self.bs)
        end
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

    -- tiles whose false flag needs to be cleared
    local clear = {}


    -- adds mines to the map
    local i = 0
    while i < self.bombs do

        -- pops a random item from the list
        local bombify = del(cells, rnd(cells))

        -- if the tile has a false flag, mulligan
        if self:tile(bombify[1], bombify[2], is_false) then

            if (self:inbounds(bombify[1], bombify[2])) add(clear, bombify)
        
        else

            -- turns the popped cell into a mine.
            -- ...i forgor lua was 1-index :^(
            mset(bombify[1], bombify[2], self.bs + 9)

            i += 1
        end
    end

    -- adds the false flagged tiles back to cells, reseting their sprite
    for i = 1, #clear do
        mset(clear[i][1], clear[i][2], self.bs)
        add(cells, clear[i])
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


-- left click to reveal or cord
function Board:lclick(cursor)

    -- converts screen coordinates to grid coordinates
    local x, y = cursor:map(self.d)

    -- makes sure the click is inbounds
    if (not self:inbounds(x, y)) return

    -- if this is the first click, also generate the board
    if (self.reveals == 0) self:generate({{x, y}})
    self.reveals += 1


    -- if the tile is revealed, attempt to cord
    if self:tile(x, y, is_reveal) then
        self:cord(x, y)
        
    -- otherwise, attempt to reveal
    else
        self:reveal(x, y)
    end

end

-- right click to flag
function Board:rclick(pos)

    -- can't flag before the first click
    if (self.reveals == 0) return

    -- converts screen coordinates to grid coordinates
    local x, y = cursor:map(self.d)

    self:flag(x, y)
end



-- reveals a tile
function Board:reveal(x, y)

    -- don't reveal if it is a flag or out of bounds
    if (self:tile(x, y, is_reveal) or self:tile(x, y, is_flag) or not self:inbounds(x, y)) return
    
    -- reveals tile
    mset(x, y, mget(x, y) + 16)

    -- if the value of a tile is zero, reveal its neighbours
    if (self:value(x, y) == 0) self:reveal_neighbours(x, y)
end

-- reveals neighbours
function Board:reveal_neighbours(x, y)
    for dx = -1, 1 do
        for dy = -1, 1 do
            if (not (dx == 0 and dy == 0)) self:reveal(x + dx, y + dy)
        end
    end
end


-- reveals all tiles
function Board:reveal_all()

    -- force reveal on all tiles
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do

            -- do nothing if it's already revealed
            if not self:tile(i, j, is_reveal) then

                -- if it's an incorrect flag
                if self:tile(i, j, is_flag) and not self:tile(i, j, is_mine) then
                    mset(i, j, self.bs + 42)
                
                -- otherwise normal reveal
                elseif not self:tile(i, j, is_flag) then
                    mset(i, j, mget(i, j) + 16)
                end
            end
        end
    end
end




-- cords a tile.
-- if a revealed tile is clicked and the number of flags neighbouring
-- the tile equals it's value, reveal all unrevealed neighbours
function Board:cord(x, y)

    -- counts flags around tile
    local flags = 0
    for dx = -1, 1 do
        for dy = -1, 1 do
            if (self:tile(x + dx, y + dy, 6)) flags += 1
        end
    end

    -- if the number of flags matches the revealed tile, reveal neighbours
    if (flags == self:value(x, y)) self:reveal_neighbours(x, y)
end



-- flags a tile
function Board:flag(x, y)

    -- does nothing if tile is already revealed or out of bounds
    if (self:tile(x, y, is_reveal) or not self:inbounds(x, y)) return

    -- if the tile is flagged, unflag it
    if self:tile(x, y, is_flag) then
        mset(x, y, mget(x, y) - 32)

        self.flags -= 1
    
    -- otherwise, unless it would cause more flags than bombs, flag tile
    elseif self.flags < self.bombs then
        
        mset(x, y, mget(x, y) + 32)

        self.flags += 1
    end
end



-- checks whether a given flag is set.
-- if the cell is out-of-bounds, return false
function Board:tile(x, y, f)

    -- if out of bounds, return false
    if (not self:inbounds(x, y)) return false

    -- return whether the flag is set.
    -- huh, there's a bug in picotron! fget(n, f) should return the
    -- state of flag f when f is specified. currently, it ingores the
    -- f parameter and returns the flag bitmap regardless.
    -- here, i unpack the flag and check it
    return (fget(mget(x, y)) >> f) & 1 == 1
end

-- gets the numeric value of a tile.
-- bombs have a value of -1
function Board:value(x, y)
    if (self:tile(x, y, is_mine)) return -1

    -- uses mask to obtain value bits
    return fget(mget(x, y)) & 15
end


-- checks if x,y is in bounds
function Board:inbounds(x, y)
    return x >= 0 and y >= 0 and x < self.w and y < self.h
end



-- draws the map
function Board:draw()

    -- is sprites are 16x16 (new sprite set), draw normally
    if self.bs == 8 then
        map(0, 0)

    else

        -- when using old sprites, must draw each sprite since map assumes
        -- sprites are 16x16
        for i = 0, self.w do
            for j = 0, self.h do
                map(i, j, i * self.d, j * self.d, 1, 1)
            end
        end
    end
end
