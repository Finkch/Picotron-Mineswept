--[[pod_format="raw",created="2024-11-04 21:31:02",modified="2024-11-19 22:26:20",revision=15]]
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

include("cell.lua")


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
        second_gen = false,     -- trackes whether fairness < 2 second generation pass has occured
        grid = {}
    }

    setmetatable(b, Board)

    -- creates a grid of unrevealed zeroes
    b:empty()
    b:adjacify()

    return b
end


-- calling the board returns the given cell
function Board:__call(x, y)
    if (not x or not y) return self.grid

    assert(x and y, string.format("invalid grid coordinates b(%s, %s)", x, y))
    assert(self:inbounds(x, y), string.format("grid call out of bounds c(%d, %d), wh(%d, %d)", x, y, self.w, self.h))

    return self.grid[x][y]
end



-- creates a board of empty cells
function Board:empty()
    for i = 1, self.w do
        self.grid[i] = {}
        for j = 1, self.h do
            self.grid[i][j] = Cell:new(self.bs, i, j, self.d)
        end
    end
end




-- creates a 1d list of all cells.
function Board:cells()
    local cells = {}
    for _, col in ipairs(self()) do
        for _, cell in ipairs(col) do
            add(cells, cell)
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

        -- in case of bad gen
        assert(#cells > 0, string.format("cannot find tiles to place %d remaining mines", mines - i))

        -- pops a random item from the list
        local bombify = del(cells, rnd(cells))

        -- if the tile has a false flag, mulligan
        if bombify.is_false then
            add(clear, bombify)
        
        -- places a mine, if the tile isn't already revealed or a mine
        elseif not bombify.is_reveal and not bombify.is_mine then

            -- turns the popped cell into a mine.
            -- ...i forgor lua was 1-index :^(.
            -- aha!, refactor prevents bad practice!
            bombify:mine()

            -- increments mine count
            i += 1
        end
    end


    -- adds the cell back to the list, so that it's value is updated
    for _, cell in ipairs(clear) do

        cell:falsy()

        add(cells, cell)
    end

    -- all cells that do not have a mine
    return cells
end

-- updates values
function Board:count(cells)

    -- if cells aren't supplied, creates the list
    if (not cells) cells = self:cells()

    -- for each cell, count its neighbours
    for _, cell in ipairs(cells) do

        -- don't set count it tile is already revealed or is a mine
        if (not cell.is_reveal and not cell.is_mine) cell:count()
    end
end


-- updates the adjacency lists for all cells
function Board:adjacify()

    -- scans over each cell
    for x = 1, self.w do
        for y = 1, self.h do
            
            -- gets a list of neighbours
            local adjs = {}
            for dx = -1, 1 do
                for dy = -1, 1 do
                    if (not (dx == 0 and dy == 0) and self:inbounds(x + dx, y + dy)) add(adjs, self(x + dx, y + dy))
                end
            end
            
            -- assigns neighbours
            self(x, y).adj = adjs
        end
    end
end




-- reveals remaining bombs
function Board:reveal_mines()

    -- in insidious mode, places the final mines in the special zone
    if (self.fairness == 0 and not self.second_gen) self:ensure_insidious()

    if (self.fairness == 1 and not self.second_gen) self:ensure_cruel()

    -- looks for mines
    for _, col in ipairs(self()) do
        for _, cell in ipairs(col) do

            -- reveals bad flags and mines
            if not cell.is_reveal and (cell.is_mine or cell.is_flag) then

                cell.is_reveal = true

                -- updates sprite
                cell:set()
            end
        end
    end
end



-- gets the numeric value of a tile.
-- bombs have a value of -1
function Board:value(x, y)
    if (not self.grid or not self.grid[x] or not self.grid[x][y]) return -3
    if (self(x, y).is_mine) return -1
    if (self(x, y).is_false) return -2

    return self(x, y).value
end


-- checks if x,y is in bounds
function Board:inbounds(x, y)
    return x >= 1 and y >= 1 and x <= self.w and y <= self.h
end



-- applies some function to all cells
function Board:apply_all(apply, cells, condition)

    -- gets the defaults
    cells = cells or self:cells()
    condition = condition or function() return true end

    -- performs the application to all cells meeting the condition
    for _, col in ipairs(self()) do
        for _, cell in ipairs(col) do
            if (condition(cell)) apply(cell)
        end
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

    -- otherwise, reveal a cell
    self(x, y):reveal()

end

-- right click to flag
function Board:rclick(pos)

    -- converts screen coordinates to grid coordinates
    local x, y = cursor:map(self.d)

    -- can't flag before the first click, or flag revealed cell
    if (self.reveals == 0 or not self:inbounds(x, y) or self(x, y).is_reveal) return

    self(x, y):flag()
end



-- draws the map
function Board:draw()
    for _, col in ipairs(self()) do
        for _, cell in ipairs(col) do
            cell:draw()
        end
    end
end






--[[
//////////////////////////////////////////////////
                generation methods
//////////////////////////////////////////////////
]]



-- selects correct generation schema
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





--[[
//////////////////////////////////////////////////
                fair generation
//////////////////////////////////////////////////
]]


-- creates a regular ol' board of mineswept
function Board:generate_fair(x, y, mines)

    -- sets false flags ensure first click reveals a zero
    for dx = -1, 1 do
        for dy = -1, 1 do
            if (self:inbounds(x + dx, y + dy)) self(x + dx, y + dy):falsy()
        end
    end

    -- places mines
    local cells = self:place_mines(mines)

    -- clears false flags
    self:apply_all(
        function(c) return c:falsy() end,
        cells,
        function(c) return c.is_false end
    )

    -- counts the value of all non-mine cells
    self:count(cells)
end






--[[
//////////////////////////////////////////////////
                insidious generation
//////////////////////////////////////////////////
]]

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


-- if the player has not revealed a false flag during insidious
-- by the gameover, this is called to place a random varaint.
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









--[[
//////////////////////////////////////////////////
                cruel generation
//////////////////////////////////////////////////
]]

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
        -- weights the starting number to be lower.
        -- this feels marginally more fair, but
        -- more importanatly it obfuscates the cheating
        local start = nearby - flr((rnd(nearby ^ 3)) ^ (1 / 3))

        -- tracks the data of the first reveal for the second gen pass
        self.first_reveal = {x, y, start}


        -- for easy reference
        local cell = self(x, y)

        -- place a random number under the cursor
        cell.value = start

        -- updates tile's sprite
        cell:set()

        -- reveal the tile
        cell:reveal()

    -- on second click, force the loss
    elseif self.reveals == 1 then

        self.second_gen = true

        -- grabs the x, y, and count data of the initial reveal
        local fx, fy, fc = unpack(self.first_reveal)

        -- places false flags about the first reveal.
        -- we'll generate these mines after the regular board mines
        for dx = -1, 1 do
            for dy = -1, 1 do

                local u, v = fx + dx, fy + dy

                if not (dx == 0 and dy == 0) and self:inbounds(u, v) then
                    self(u, v):falsy()
                end
            end
        end
        
        -- places a mine under the cursor
        self(x, y):mine()

        -- checks if the mine placed was adjacent to the first reveal
        local adj = false
        if (abs(x - fx) <= 1 and abs(y - fy) <= 1) adj = true

        -- places most mines
        if adj then
            self:place_mines(mines - fc)
        else
            self:place_mines(mines - fc - 1)
        end
        

        -- creates a list of cells about the start
        local cells = {}
        for dx = -1, 1 do
            for dy = -1, 1 do

                local u, v = fx + dx, fy + dy

                if not (dx == 0 and dy == 0) and self:inbounds(u, v) and not self(u, v).is_mine then

                    -- if the cell doesn't have a mine, add it to choices
                    add(cells, self(u, v))

                    -- resets any lingering false flags
                    if (self(u, v).is_false) self(u, v):falsy()
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

        -- if the spot is valid, start cruel gen
        if not cell.is_reveal then
            self:generate(cell.x, cell.y, self.bombs)
            return
        end
    end
end

