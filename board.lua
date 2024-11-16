--[[pod_format="raw",created="2024-11-04 21:31:02",modified="2024-11-14 20:14:15",revision=8]]
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

    the cruel strategy to build a board is as follows:
    * don't do anything to build the board.
    * after the players selects the first tile, reveal is as 1-8
    * after the player selects a second tile, reveal it as a bomb
    * place mines such that the board could be valid

    the insidious strategy to build a board is as follows:
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
        d = d,                  -- cell side length
        second_gen = false      -- trackes whether fairness < 2 second generation pass has occured
    }

    setmetatable(b, Board)

    -- creates a grid of unrevealed zeroes
    b:empty()

    return b
end


-- clears any existing boards
function Board:clear()
    for i = 0, state.data.maxd do
        for j = 0, state.data.maxd do
            mset(i, j, 0)
        end
    end
end

-- creates a new board
function Board:generate(x, y, mines)

    -- generates the board according to fairness value
    if self.fairness == 0 then
        self:generate_insidious(x, y, mines)
    elseif self.fairness == 1 then
        self:generate_unfair(x, y, mines)
    else
        self:generate_fair(x, y, mines)
    end
end

-- creates an empty board
function Board:empty()
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do
            mset(i, j, self.bs)
        end
    end
end

-- creates a 1d list of all cells.
function Board:cells()
    local cells = {}
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do
            add(cells, {i, j})
        end
    end
    return cells
end

-- places mines
function Board:place_mines(mines, cells)

    -- in case cells were not provided
    if (not cells) cells = self:cells()

    -- tiles whose false flag needs to be cleared
    local clear = {}

    -- adds mines to the map
    local i = 0
    while i < mines do

        assert(#cells > 0, string.format("cannot find tiles to place %d remaining mines", mines - i))

        -- pops a random item from the list
        local bombify = del(cells, rnd(cells))

        -- if the tile has a false flag, mulligan
        if self:tile(bombify[1], bombify[2], is_false) then

            if (self:inbounds(bombify[1], bombify[2])) add(clear, bombify)
        
        -- places a mine, if the tile isn't already revealed
        elseif not self:tile(bombify[1], bombify[2], is_reveal) then

            -- turns the popped cell into a mine.
            -- ...i forgor lua was 1-index :^(
            self:mineify(bombify[1], bombify[2])

            i += 1
        end
    end

    -- adds the false flagged tiles back to cells, reseting their sprite to 0 value
    self:ify_all(self.falseify, clear, function(x, y) return true end, cells)

    -- all cells that do not have a mine
    return cells
end

-- updates values
function Board:count(cells)

    -- if cells aren't supplied, creates the list
    if (not cells) cells = self:cells()

    -- for each cell, count its neighbours
    for i = 1, #cells do

        local x, y = unpack(cells[i])

        -- don't set count it tile is already revealed or is a mine
        if (not self:tile(x, y, is_reveal) and not self:tile(x, y, is_mine)) self:countify(x, y)
    end
end

-- creates a regular ol' board of mineswept
function Board:generate_fair(x, y, mines)

    -- sets false flags ensure first click reveals a zero
    for dx = -1, 1 do
        for dy = -1, 1 do
            if (self:inbounds(x + dx, y + dy)) mset(x + dx, y + dy, self.bs + 10)
        end
    end

    local cells = self:place_mines(mines)
    self:count(cells)
end

-- generates a guaranteed loss, that will take a while to uncover
function Board:generate_insidious(x, y, mines)

    local do_log = true
    
    -- on normal board generation
    if self.reveals == 0 then

        -- chooses an appropriate 50-50.
        -- largest dimensions must be less than integer half min d;
        -- thus, there must be space on the board for the 50-50 regardless
        -- of the initial reveal
        local fifty = fifties:rnd(
            function(f) return min(f.w, f.h) < max(board.w, board.h) // 2 end
        )

        -- if the grid is reflectable, perform a coin flip for the version
        if (fifty.reflectable and rnd() < 0.5) fifty = fifty:reflect()

        -- chooses a random corner.
        -- 0 is bottom left, increasing is clockwise
        local corners = {0, 1, 2, 3}
        local corner = -1

        if do_log then
            logger(string.format("min f(%d, %d) = %d; max d(%d, %d) // 2 = %d", fifty.w, fifty.h, min(fifty.w, fifty.h), board.w, board.h, max(board.w, board.h) // 2), "fd.txt")
            logger(string.format("cursor: (%d, %d)\n", x, y), "fd.txt")
        end

        
        -- whether or not the cursor's cell overlaps with the grid
        local overlap = true

        -- top left corner of the grid relative to the baord
        local t = -1
        local l = -1

        -- allows rotation without affecting the original
        local try_fifty = nil

        -- in case current reflection cannot allow it to fit, reflect and try again
        local second_try = false

        -- ensures the chosen corner is sificiently far from the revealed tile
        while overlap do

            -- if we can't fit the 50-50, try reflecting it and starting again
            if #corners == 0 then
                fifty = fifty:reflect()
                corners = {0, 1, 2, 3}

                -- crashes rather than trying infinitely
                assert(not second_try, "sorry! i'll cheat better next time (couldn't find corner in which to place 50-50).")

                second_try = true
            end

            -- picks a random corner
            corner = del(corners, rnd(corners))

            -- ensures the initial reveal is not close.
            -- otherwise, initial reveal would not be guaranteed to be a zero.

            -- bottom left
            if corner == 0 then
                try_fifty = fifty:copy()

                -- top left corner
                l = 0
                t = self.h - try_fifty.h

            -- top left
            elseif corner == 1 then
                try_fifty = fifty:rotate90()

                l = 0
                t = 0


            -- top right
            elseif corner == 2 then
                try_fifty = fifty:rotate180()

                l = self.w - try_fifty.w
                t = 0


            -- bottom right
            elseif corner == 3 then
                try_fifty = fifty:rotate270()

                l = self.w - try_fifty.w
                t = self.h - try_fifty.h
            end

            -- checks if the corner is valid.
            -- it is valid if the cursor doesn't overlap the grid's region.
            -- this ensures the initial reveal is a zero
            overlap = self:overlap(x, y, l, t, try_fifty)
        end

        -- grabs the orientation that was deemed to fit
        fifty = try_fifty


        -- stores the data for second gen
        self.fifty = fifty
        self.t = t
        self.l = l

        -- sets false flags on the 50-50
        for i = 0, fifty.w - 1 do
            for j = 0, fifty.h - 1 do
                if (fifty.grid[j + 1][i + 1] != 0) mset(l + i, t + j, self.bs + 10)
            end
        end

        -- normal generation
        -- sets false flags ensure first click reveals a zero
        for dx = -1, 1 do
            for dy = -1, 1 do
                if (self:inbounds(x + dx, y + dy)) mset(x + dx, y + dy, self.bs + 10)
            end
        end

        self:place_mines(mines - fifty.mines)
        -- end normal generation


        -- generates 50-50 boundary
        for i = 0, fifty.w - 1 do
            for j = 0, fifty.h - 1 do
                if (fifty.grid[j + 1][i + 1] == -1) mset(l + i, t + j, self.bs + 9)
            end
        end

        -- counts board
        self:count()

        -- introduces quantum information
        for i = 0, fifty.w - 1 do
            for j = 0, fifty.h - 1 do

                local ix, iy = i + 1, j + 1

                -- sets false flag
                if fifty.grid[iy][ix] == -2 then
                    mset(l + i, t + j, self.bs + 10)

                -- counts quantum mines
                elseif fifty.grid[j + 1][i + 1] > 0 then
                    mset(l + i, t + j, mget(l + i, t + j) + fifty.grid[iy][ix])

                -- counts fair gen quantum mines
                elseif fifty.grid[iy][ix] == 0 and not self:tile(l + i, t + j, is_mine) then

                    -- chooses the first adjacent non-zero number it finds on the mgrid.
                    -- by counting the adjacent quantum mines of that variant, it will
                    -- know what it would need to add to its count.
                    -- a random adjacent quantum mine variant is guaranteed to be the
                    -- same as all adjacent others, since otherwise it wouldn't be quantum.
                    local first = nil
                    local count = 0
                    for dx = -1, 1 do
                        for dy = -1, 1 do

                            -- ensures all accesses lie on the (m)grid.
                            -- strictly speaking, no need to prevent dx == 0 and dy == 0,
                            -- since such a tile is guaranteed to not be a qmine variant
                            if 1 <= ix + dx and ix + dx <= fifty.w and 1 <= iy + dy and iy + dy <= fifty.h and not (dx == 0 and dy == 0) then

                                -- check for quantum mine
                                if fifty.mgrid[iy + dy][ix + dx] != 0 then

                                    -- finds the first variant
                                    if (not first) first = self:choose_variant(l + i + dx, t + j + dy) -- 10 deep!

                                    -- counts occurances of that variant
                                    if (fifty.mgrid[iy + dy][ix + dx] & first > 0) count += 1

                                end
                            end -- 8 deep nested statements |:^(
                        end
                    end

                    -- adds the count of adjacnet quantum mines to the cell
                    mset(l + i, t + j, mget(l + i, t + j) + count)
                end
            end
        end


    -- on finding the special 50-50.
    -- i.e., when revealing a false flag tile
    else

        self.second_gen = true

        -- retrieves some handy info
        local fifty = self.fifty
        local t = self.t
        local l = self.l

        -- figures out which variant supports this mine placement.
        -- i.e., which variant has an active bit in this tile
        local variant = self:choose_variant(x, y)

        -- places mines according to that variant
        self:place_variant(variant)
    end
end

-- checks for a collision between cursor and a grid position
function Board:overlap(x, y, l, t, fifty)
    return l - 1 <= x and x <= l + fifty.w and t - 1 <= y and y <= t + fifty.h
end

-- given the flags on a cell, choose one at random
function Board:choose_variant(x, y)

    local fifty = self.fifty
    local t = self.t
    local l = self.l

    local variants = fifty.mgrid[y - t + 1][x - l + 1]

    -- finds the present variants of the given cell
    local flags = {}
    local i = 0
    local pow = 1

    -- checks each bit
    while pow <= variants do

        -- checks if this flag is active
        if ((variants // pow) & 1 == 1) add(flags, pow)

        -- checks the next power
        i += 1
        pow = 2 ^ i
    end

    -- returns a random variant from the cell's possible variants
    return rnd(flags)
end


-- collapses a mine wave function into a specific variant
function Board:place_variant(v)

    -- for whatever reason, we can't pass these value since
    -- i guess they're local when this is called from insidious?
    -- that makes no sense because otherwise 'v,' too, would be nil.
    -- nevertheless, fifty is nil if passed in
    local fifty = self.fifty
    local t = self.t
    local l = self.l

    for i = 0, fifty.w - 1 do
        for j = 0, fifty.h - 1 do
            if fifty.mgrid[j + 1][i + 1] & v != 0 then

                -- in case flagged
                if self:tile(l + i, t + j, is_flag) then
                    mset(l + i, t + j, self.bs + 41)
                else
                    mset(l + i, t + j, self.bs + 9)
                end
            end
        end
    end
end

-- lose in two moves
function Board:generate_unfair(x, y, mines)

    -- on first click, perform a false generation
    if self.reveals == 0 then

        -- chooses an appropriate starting number that is always possible.
        -- counts adjacent inbounds cells
        local nearby = 0
        for dx = -1, 1 do
            for dy = -1, 1 do
                if (not (dx == 0 and dy == 0) and self:inbounds(x + dx, y + dy)) nearby += 1
            end
        end

        -- ensures the starting number isn't larger than the number of mines
        nearby = min(nearby, mines - 1)

        -- chooses a starting number.
        -- weights the starting number to be lower,
        -- this feels marginally more fair, but
        -- more importanatly it obfuscates the cheating
        local start = nearby - flr((rnd(nearby ^ 3)) ^ (1 / 3))

        -- tracks the data of the first reveal for the second gen pass
        self.first_reveal = {x, y, start}

        -- place a random number under the cursor
        mset(x, y, self.bs + start)

        -- reveal the tile
        self:reveal(x, y)

    -- on second click, force the loss
    elseif self.reveals == 1 then

        self.second_gen = true

        -- grabs the x, y, and count data of the initial reveal
        local fx, fy, fc = unpack(self.first_reveal)

        -- places false flags about the first reveal.
        -- we'll generate these mines after the regular board mines
        for dx = -1, 1 do
            for dy = -1, 1 do
                if not (dx == 0 and dy == 0) and self:inbounds(fx + dx, fy + dy) then
                    self:falseify(fx + dx, fy + dy)
                end
            end
        end
        
        -- also a false flag under the cursor
        mset(x, y, self.bs + 10)

        -- checks if the mine placed was adjacent to the first reveal
        local adj = false
        if (abs(x - fx) <= 1 and abs(y - fy) <= 1) adj = true

        -- places most mines
        if adj then
            self:place_mines(mines - fc)
        else
            self:place_mines(mines - fc - 1)
        end

        -- places a mine under the cursor
        mset(x, y, self.bs + 9)

        -- creates a list of cells about the start
        local cells = {}
        for dx = -1, 1 do
            for dy = -1, 1 do
                if not (dx == 0 and dy == 0) and self:inbounds(fx + dx, fy + dy) and not self:tile(fx + dx, fy + dy, is_mine) then

                    -- if the cell doesn't have a mine, add it to choices
                    add(cells, {fx + dx, fy + dy})

                    -- resets any lingering false flags
                    self:falseify(fx + dx, fy + dy)
                end
            end
        end

        -- places the final mines about the initial reveal
        if adj then
            self:place_mines(fc - 1, cells)
        else
            self:place_mines(fc, cells)
        end

        -- updates the counts around the board.
        -- stricly, we don't need to do this because other tiles are never revealed...
        self:count()

    -- it should be impossible to reach this far
    else
        assert(false, "how'd you do that?")
    end
end


-- left click to reveal or cord
function Board:lclick(cursor)

    -- converts screen coordinates to grid coordinates
    local x, y = cursor:map(self.d)

    -- makes sure the click is inbounds
    if (not self:inbounds(x, y)) return

    -- if this is the first click, also generate the board
    if (self.reveals == 0) self:generate(x, y, self.bombs)

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

    -- on insidious mode, generate again when clicking on a false flag
    if (self.fairness == 0 and self.reveals > 0 and self:tile(x, y, is_false) and not self.second_gen) self:generate(x, y, self.bombs)

    -- on cruel mode, generate again on the second click
    if (self.fairness == 1 and self.reveals > 0 and not self.second_gen) self:generate(x, y, self.bombs)
    
    -- reveals tile
    mset(x, y, mget(x, y) + 16)
    self.reveals += 1

    -- if the value of a tile is zero, reveal its neighbours
    if (self:value(x, y) == 0) self:reveal_neighbours(x, y)

    -- if the tile is a bomb, change to gameover state
    if (self:tile(x, y, is_mine)) state:change("gameover")

    -- if the final tile was revealed, and it isn't a gameover, win the game
    if not state:__eq("gameover") and self.w * self.h - self.bombs == self.reveals then
        
        -- push win to state
        state.data.win = true
        
        state:change("gameover")
    end
end

-- reveals neighbours in a random order.
-- random order makes cording in cruel mode look more real
function Board:reveal_neighbours(x, y)
    
    -- list of neighbouring cells
    local adjs = {}
    for dx = -1, 1 do
        for dy = -1, 1 do
            if (not (dx == 0 and dy == 0)) add(adjs, {dx, dy})
        end
    end

    -- pops random neighbours until no neighbours remain
    while #adjs > 0 do

        -- exit should this lead to a gameover
        if (state:__eq("gameover")) return

        -- choose a random item
        local adj = del(adjs, rnd(adjs))

        -- reveal the neighbour
        self:reveal(x + adj[1], y + adj[2])
    end
end

-- reveals remaining bombs
function Board:reveal_mines()

    -- in insidious mode, places the final mines in the special zone
    if (self.fairness == 0 and not self.second_gen) self:ensure_insidious()

    if (self.fairness == 1 and not self.second_gen) self:ensure_cruel()

    -- looks for mines
    for i = 0, self.w - 1 do
        for j = 0, self.h - 1 do

            -- do nothing if it's already revealed
            if not self:tile(i, j, is_reveal) then

                -- if it's an incorrect flag
                if self:tile(i, j, is_flag) and not self:tile(i, j, is_mine) then
                    mset(i, j, self.bs + 42)
                
                -- otherwise, reveal if it's a mine
                elseif self:tile(i, j, is_mine) and not self:tile(i, j, is_reveal) and not self:tile(i, j, is_flag) then
                    mset(i, j, mget(i, j) + 16)
                end
            end
        end
    end
end

-- if the player has not revealed a false flag during insidious,
-- this is called to place a random varaint.
function Board:ensure_insidious()

    local fifty = self.fifty
    local l = self.l
    local t = self.t

    -- gets a list of all cells containing quantum mines
    local cells = {}
    for i = 0, fifty.w - 1 do
        for j = 0, fifty.h - 1 do
            if (fifty.mgrid[j + 1][i + 1] > 0) add(cells, {l + i, t + j})
        end
    end

   -- chooses a random cell with a quantum mine
   local x, y = unpack(rnd(cells))

    -- randomly selects a variant from the given cell
    local variant = self:choose_variant(x, y)

    -- places the mines for that variant
    self:place_variant(variant)
end

-- if the player pressed the lose-game button, this is called
-- to place the mines to the board looks fair.
function Board:ensure_cruel()

    local cells = self:cells()

    -- choose a random, non-revealed cell as the second "revealed" 
    -- cell for cruel generation.
    -- now, maybe this should also not work on flagged cells, but it
    -- should be fine as is, and appear marginally more fiar
    while #cells > 0 do

        -- chooses a random cell
        local cell = del(cells, rnd(cells))
        local x, y = cell[1], cell[2]

        -- if the spot is valid, start cruel gen
        if not self:tile(x, y, is_reveal) then
            self:generate(x, y, self.bombs)
            return
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
            if (self:tile(x + dx, y + dy, is_flag)) flags += 1
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

        self:flagify(x, y)

        self.flags -= 1
    
    -- otherwise, unless it would cause more flags than bombs, flag tile
    elseif self.flags < self.bombs then
        
        self:flagify(x, y)

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
    if (self:tile(x, y, is_false)) return -2

    -- uses mask to obtain value bits
    return fget(mget(x, y)) & 15
end


-- checks if x,y is in bounds
function Board:inbounds(x, y)
    return x >= 0 and y >= 0 and x < self.w and y < self.h
end


-- methods for altering with a cell
function Board:countify(x, y)

    -- counts neighbours
    local count = 0

    -- counts neighbouring mines
    for dx = -1, 1 do
        for dy = -1, 1 do
            if (not (dx == 0 and dy == 0) and self:tile(x + dx, y + dy, is_mine)) count += 1
        end
    end

    -- sets the value of the tile
    if self:tile(x, y, is_flag) then
        mset(x, y, self.bs + count + 32)
    else
        mset(x, y, self.bs + count)
    end
end

function Board:mineify(x, y)

    -- mine/unmine
    if self:tile(x, y, is_mine) then
        mset(x, y, self.bs)
    else
        mset(x, y, self.bs + 9)
    end
end

function Board:flagify(x, y)

    -- false flag case
    if self:tile(x, y, is_false) then

        -- flag/unflag
        if self:tile(x, y, is_flag) then
            mset(x, y, mget(x, y) - 1)
        else
            mset(x, y, mget(x, y) + 1)
        end

    -- normal cell case
    else

        -- flag/unflag
        if self:tile(x, y, is_flag) then
            mset(x, y, mget(x, y) - 32)
        else
            mset(x, y, mget(x, y) + 32)
        end
    end
end

function Board:falseify(x, y)

    -- flag case
    if self:tile(x, y, is_flag) then

        -- false/unfalse
        if self:tile(x, y, is_false) then
            mset(x, y, self.bs + 32)
        else
            mset(x, y, self.bs + 11)
        end

    -- normal case
    else

        -- false/unfalse
        if self:tile(x, y, is_false) then
            mset(x, y, self.bs)
        else
            mset(x, y, self.bs + 10)
        end
    end
end


-- applies an -ify function to all cells.
-- 'ify' is a method that ends in the suffix '-ify'.
-- condition is an optional method that accepts (x, y) and returns true/false.
function Board:ify_all(ify, cells, condition, cellsout)
    
    -- grabs cells if supplied
    if (not cells) cells = self:cells()

    for i = 1, #cells do
        local x, y = unpack(cells[i])

        -- apply the alteration to the given cell
        if (not condition or condition(self, x, y)) ify(self, x, y)

        -- usefull to track to which cells an alteration has been applied
        if (cellsout) add(cellsout, cells[i])
    end

    return cellsout
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
