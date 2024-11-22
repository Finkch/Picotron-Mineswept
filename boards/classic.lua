--[[pod_format="raw",created="2024-11-22 21:16:21",modified="2024-11-22 21:17:39",revision=1]]
--[[
    classic grid approach
        the board is stored in memory in a 2d table. each cell tracks
        its own information, including its neighbours. while the deprecated
        solution (below) offers some elegence, particularly in quick ways of
        updating sprites and state, it is very inelegent to perform an operation
        over all neighbours of a cell, which is very important for the non-fair
        generation techniques. furthermore, the map approach does not practically
        support tiles with a sidelength != 16, nor would it work for 'infinite'
        grid sizes, as required of quantum minesweeper

    deprecated
        the board is encoded through the map. while it could be stored in
        memory in a 2d table, the map offers an elegant solution. there
        are 9 sprites representing unrevealed tiles, corresponding to
        tiles with a value of 0-9 as well as a mine; the difference is
        denoted by the sprites' flags.
        that said, there still is a board object. it contains handy-dandy
        methods of interacting with the map.



    the strategy (fair) to build a board is as follows:
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
        > ammendment: this special 50-50 encodes all possible variants,
            or the superposition, of the positions of its mines. this uses
            a special type of cell called a quantum cell. when the 50-50
            is encountered, i.e. when the user reveals a quantum cell, it
            chooses a random variant in which there is a mine there, and
            "observes" that state, similar to collapsing a wavefunction.
            it i wanted, it could do the opposite and ensure the user
            succeeds in the 50-50 by observing a non-mine variant, 
            but what fun would that be?
]]

include("cell.lua")
include("boards/board.lua")


ClassicBoard = setmetatable({}, Board)
ClassicBoard.__index = ClassicBoard
ClassicBoard.__type  = "classicboard"

function ClassicBoard:new(fairness, oldsprites, mines, w, h)

    local cb = Board:new(fairness, oldsprites)

    cb["mines"] = mines
    cb["w"] = w
    cb["h"] = h

    setmetatable(cb, ClassicBoard)

    -- creates a grid of unrevealed zeroes
    cb:empty()
    cb:adjacify()

    return cb
end




--[[
//////////////////////////////////////////////////
                interface methods
//////////////////////////////////////////////////
]]

-- calling the board returns the given cell.
function ClassicBoard:__call(x, y)
    return Board.__call(self, x, y)
end

-- gets a 1d list representation of all cells
function ClassicBoard:cells()
    local cells = {}
    for _, col in ipairs(self()) do
        for _, cell in ipairs(col) do
            add(cells, cell)
        end
    end
    return cells
end


-- ensures grid position exists.
function ClassicBoard:inbounds(x, y)
    return x >= 1 and y >= 1 and x <= self.w and y <= self.h
end


-- quick all. same as all, but faster.
-- uses pregenerated list, but lacks option to go over only subset.
function ClassicBoard:qall(apply, condition)
    for _, col in ipairs(self()) do
        for _, cell in ipairs(col) do
            if (not condition or condition(cell)) apply(cell)
        end
    end
end


-- creates an empty grid
function ClassicBoard:empty()
    for i = 1, self.w do
        self.grid[i] = {}
        for j = 1, self.h do
            self.grid[i][j] = Cell:new(self.bs, i, j, self.d)
        end
    end
end


-- no generation interface override!
-- that is the sole duty of the children of this metatable







--[[
//////////////////////////////////////////////////
                generation methods
//////////////////////////////////////////////////
]]

-- places mines
function ClassicBoard:place_mines(mines, cells)

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
        local cell = del(cells, rnd(cells))

        -- if the tile has a false flag, mulligan
        if cell.is_false then
            add(clear, cell)
        
        -- places a mine, if the tile isn't already revealed or a mine
        elseif not cell.is_reveal and not cell.is_mine then

            -- turns the popped cell into a mine.
            -- ...i forgor lua was 1-index :^(.
            -- aha!, refactor prevents bad practice!
            cell:mine()

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
function ClassicBoard:count(cells)
    self:all(
        function(cell) cell:count() end,
        function(cell) return not cell.is_reveal and not cell.is_mine end,
        cells
    )
end


-- updates the adjacency lists for all cells
function ClassicBoard:adjacify()

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