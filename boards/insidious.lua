
--[[
    the insidious strategy to build a board is as follows:
    * first, place a 50-50 on the board; this 50-50 is tracked
    * as the rest of the board is built, build according to first
        strategy, except maintining boundary conditions
    * when the player encounters the tracked 50-50, place a mine
        under whichever tile the user picks
    * place mines in the tracked 50-50 in accordance; otherwise
        reveal the board as per normal

    > ammendment: this special 50-50 encodes all possible variants,
        or the superposition, of the positions of its mines. this uses
        a special type of cell called a quantum cell. when the 50-50
        is encountered, i.e. when the user reveals a quantum cell, it
        chooses a random variant in which there is a mine there and
        "observes" that state, similar to collapsing a wavefunction.
        it i wanted, it could do the opposite and ensure the user
        succeeds in the 50-50 by observing a non-mine variant, 
        but what fun would that be?
]]

include("boards/classic.lua")
include("cell.lua")

InsidiousBoard = setmetatable({}, ClassicBoard)
InsidiousBoard.__index = InsidiousBoard
InsidiousBoard.__type = "insidiousboard"


function InsidiousBoard:new(fairness, oldsprites, mines, w, h)
    local ib = ClassicBoard:new(fairness, oldsprites, mines, w, h)

    ib["first_gen"] = false
    ib["second_gen"] = false

    setmetatable(ib, InsidiousBoard)
    return ib
end


-- calling the board returns the given cell.
function InsidiousBoard:__call(x, y)
    return ClassicBoard.__call(self, x, y)
end



-- generates a guaranteed loss, that will take a while to uncover
function InsidiousBoard:generate(x, y)
    
    -- on normal board generation
    if not self.first_gen then

        self.first_gen = true

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
        self.corner = corner

        
        -- places false flags over the no-gen zone of the fifty
        for i = 1, fifty.w do
            for j = 1, fifty.h do

                -- places false flags
                if fifty(i, j) == -2 then
                    self(l + i, t + j):falsy()

                -- places mines
                elseif (fifty(i, j) == -1) then
                    self(l + i, t + j):mine()
                end
            end
        end


        -- applies fair generation to place mines outside of fifty's no-gen
        -- this is the same as what is done for fairboard:generate()


        -- sets false flags ensure first click reveals a zero
        self(x, y):all(function(cell) cell:falsy() end)
        self(x, y):falsy()

        -- places mines.
        -- cells is the list of all cells without a mine
        local cells = self:place(self.mines - fifty.mines)

        -- clears any lingering false flags
        self:all(
            function(c) c:falsy() end,
            function(c) return c.is_false end,
            cells
        )

        -- updates values
        self:count(cells)

        

        -- precalc
        local superposition = fifty:find_superposition()
        
        local entangled = {}


        -- places quantum cells in the fifty
        for i = 1, fifty.w do
            for j = 1, fifty.h do
                if fifty(i, j, true) != 0 then

                    -- creates the quantum cell
                    local cq = QuantumCell:new(board.bs, l + i, t + j, board.d)

                    -- gives the cell a superposition
                    cq.superposition = superposition
                    cq.eigenvalues = fifty(i, j, true)
                    cq.is_quantum = true

                    -- gives this cell a list of entangled cells
                    cq.entangled = entangled
                    add(entangled, cq)

                    -- assigns the cell to the grid
                    self.grid[l + i][t + j] = cq
                end
            end
        end

        -- reconsideres adjacency due to updated cells
        self:adjacify()

        -- updates the board's counts
        self:count()

    -- on finding the special 50-50.
    -- i.e., when revealing a quantum cell
    else

        self.second_gen = true

        -- observes the quantum cell to a random ill favoured state
        self(x, y):collapse(nil, -1)
    end
end

-- checks for a collision between cursor and a grid position
function InsidiousBoard:overlap(x, y, l, t, fifty)
    return l <= x and x <= l + fifty.w + 1 and t <= y and y <= t + fifty.h + 1
end


-- if the player has not revealed a false flag during insidious
-- by the gameover, this is called to place a random varaint.
function InsidiousBoard:ensure()

    local fifty = self.fifty
    local l = self.l
    local t = self.t

    -- gets a list of all cells containing quantum mines
    local cells = {}
    for i = 1, fifty.w do
        for j = 1, fifty.h do
            if (self(l + i, t + j).is_quantum) add(cells, self(l + i, t + j))
        end
    end

   -- chooses a random cell with a quantum mine
   local cell = rnd(cells)

    -- selects a random mine-eigenstate and observes it 
    cell:collapse(nil, -1)
end

