

include("boards/classic.lua")

CruelBoard = setmetatable({}, ClassicBoard)
CruelBoard.__index = CruelBoard
CruelBoard.__type = "cruelboard"

function CruelBoard:new(fairness, oldsprites, mines, w, h)
    local cb = ClassicBoard:new(fairness, oldsprites, mines, w, h)

    cb["first_gen"] = false
    cb["second_gen"] = false

    setmetatable(cb, CruelBoard)
    return cb
end





-- lose in two moves
function ClassicBoard:generate_unfair(x, y, mines)

    -- on first click, perform a false generation
    if not self.first_gen then

        self.first_gen = true

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
    else

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

    end
end



-- if the player pressed the lose-game button, this is called
-- to place the mines to the board looks fair.
function CruelBoard:ensure()

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
            self:generate(cell.x, cell.y, self.mines)
            return
        end
    end
end

