--[[
    a board with infinite dimensions where mines exist in all
    possible vairantions simultanously.
    defined by mine density rather than count of mines.


    hm, this approach likely isn't that good.
        quantum/infini board generation scheme
        * start with no grid.
        * wherever the user first clicks and in a (Chebyshev) radius of one about the click,
            place qcells with eigenvalues of 0 (no mine).
        * then, building (Chebyshev) radially outward next to 0 values cells by placing 
            qcells with eigenvalues of (0...01) corresponding to the board's density.
            > whenever a new cell is placed, count its neighbours
            > new cells can only be added next to cells with a count of 0
        * stop building when there are no more 0 values cells that lack neighbours
        * go over the frontier, wiping starting quantum data and building
            up full quantum data for the given board


    quantum/infini board generation scheme v2
    * do nothing.
        |
        \/
    quantum/infini board cell reveal scheme
    --  * when a tile is revealed, add neighbours until it has 8 neigbbours
    --      > every reveal is guaranteed to be on the frontier
    --          - wait, no dumass, that ain't true. what about distant reveals?
    * when a tile is revealed, choose an appropriate value
        > first, observe a state for adjacent quantum cells
        > second, add a random number E 0, #new_frontier
            - the random number follows a binomial distribition?
        > the revealed cell's value is the sum of qmines and new_frontier roll
    * update the frontier to include the new frontier
        > update superpositions
    


    according to chatgpt, which in turn sites percolation theory (study of network
    connectiveness), the smallest desnity (or critical density) to ensure the first
    reveal is finite rather than infinite p(mine) must be greater than 0.5927 or so.
    that's not too promising, given my default setting is 1/5, a far cry from 3/5.
        > so, maybe as we build a board, we start at density but lerp on radius to 3/5?
        > also, apparently infinite minesweeper is turing complete.

]]

include("cells.lua")
include("board/boards.lua")



QuantumBoard = setmetatable({}, Board)
QuantumBoard.__index = QuantumBoard
QuantumBoard.__type = "quantumboard"


-- Board header so I know what each field means
--function ClassicBoard:new(w, h, bombs, fairness, oldsprites)
function QuantumBoard:new(fairness, oldsprites, density)
    
    local qb = Board:new(fairness, oldsprites)

    qb["density"]   = density   -- mines per tile
    qb["cells"]     = {}        -- a 1d representation constantly stored in memory
    qb["frontier"]  = {}        -- the frontier is comprised of all undiscovered cells

    setmetatable(ib, QuantumBoard)
    return ib
end




--[[
//////////////////////////////////////////////////
                interface methods
//////////////////////////////////////////////////
]]


-- calling the board returns the given cell.
function QuantumBoard:__call(x, y)
    return Board.__call(self, x, y)
end

-- gets a 1d list representation of all cells
function QuantumBoard:cells()
    return self.cells
end


-- ensures grid position exists.
-- simply checks if the value exists
function QuantumBoard:inbounds(x, y)
    return self.grid[x] and self.grid[x][y]
end


-- quick all. same as all, but faster.
-- uses pregenerated list, but lacks option to go over only subset.
function QuantumBoard:qall(apply, condition)
    for _, cell in self:cells() do
        if (condition(cell)) apply(cell)
    end
end


-- creates an empty grid
function QuantumBoard:empty()
    self.grid = {}
    self.cells = {}
    self.frontier = {}

    -- adds a starting cell that's guaranteed to not be a mine
    self:add(0, 0, 1, 0)
end



-- game actions for left click: reveal, cord
function QuantumBoard:lclick(cursor)

    -- for first reveal, force cursor to b(0, 0)
    if (self.reveals == 0) cursor.pos = -cam.pos + cursor.pos % 8

end


-- game actions for right click: flag
function QuantumBoard:rclick(cursor)
end




--[[
//////////////////////////////////////////////////
                generation methods
//////////////////////////////////////////////////
]]


-- adds a cell to the board
function QuantumBoard:add(x, y, superposition, eigenvalues)

    assert(not self:inbounds(x, y), string.format("cannot add cell to already occupied cell position at b(%s, %s)", x, y))

    -- creates a new cell
    local cell = QuantumCell:new(self.bs, x, y, self.d, superposition, eigenvalues)

    -- ensures that column exists
    if (not self.grid[x]) self.grid[x] = {}

    -- adds the cell to the map
    self.grid[x][y] = cell
    add(self.cells, cell)
    add(self.frontier, cell)

    -- updates adjacency
    self(x, y).adj = {}
    for dx = -1, 1 do
        for dy = -1, 1 do

            local u, v = x + dx, y + dy

            -- self is not a neighbour of self
            if not ((dx == 0 and dy == 0) and self:inbounds(u, v)) self(u, v):neighbour(cell)
        end
    end

    -- !! todo !!
    -- builds frontier superpositions

    return cell
end



-- reveals a cell, adding new cells and updating quantum information
function QuantumBoard:reveal(x, y)

    -- when the cell is not on the frontier
    --  !! todo !!  incorporate fairness
    if (not self:inbounds(x, y)) self:add(x, y)
   
    -- gets cell in question
    local cell = self(x, y)

    -- deletes the revealed cell from the frontier
    del(self.frontier, cell)

    -- finds the number of adjacent mines for currently existing qcells
    local qmines = cell:count()

    -- tracks the new frontier
    local nfrontier = {}

    -- adds new cells to the frontier
    for dx = -1, 1 do
        for dy = -1, 1 do

            -- self is not a neighbour of self.
            -- we only create a cell if it is out-of-bounds, which just means that
            -- it isn't on the board yet. hence, we need to add it
            if not (dx == 0 and dy == 0) and not self:inbounds(u, v) then
                
                -- gets the cell added to the frontier
                add(nfrontier, self:add(u, v))
            end
        end
    end


    -- updates the cell's value
    local fmines = self:binomial(#nfrontier, 1 / self.density)
    cell.v = qmines + fmines


    -- updates superposition on the new frontier


    -- reveals cell
    --  !! todo !!  incorporate fairness
    cell:reveal()
end


-- returns a random amount of successes given n trials at probability p.
-- used to calcualte the number of mines on the new frontier.
--
-- i was going to calculate the binomial cdf and randomly choose a bin,
-- but i realised that was a very costly operation. so i asked gpt and it
-- told me to roll a dice n times. yeah, sometimes i overthing these things.
function QuantumBoard:binomial(n, p)
    
    -- number of successes
    local k = 0

    -- performs n trials
    for i = 1, n do
        if (rnd() <= p) k += 1
    end

    return k
end


-- given some cells on a frontier and a number of mines that
-- belong to them all, updates their superposition.
-- all cells are assumed to be adjacent to the cell with value = "mines"
--
-- let n = #frontier, m = mines.
-- superposition will be "1" * nCm.
-- eigenvalues will be permutations of "1" * m + "0" * (n - m).
--
-- note: n = 8, m = 4 -> nCm = 70. off by 6!
-- and there's a ~5% chance an 8 reveal (empty tile) results in
-- this bad outcome. 
function QuantumBoard:quantum_frontier(frontier, mines)

    -- special case: no mines
    if mines == 0 then
        for _, cell in ipairs(frontier) do
            cell.superposition = 1
            cell.eigenvalues = 0
        end
        return
    end

    -- special case: same number of mines as frontier cells
    if mines == #frontier then
        for _, cells in ipairs(frontier) do
            cell.superposition = 1
            cell.eigenvalues = 1
        end
        return
    end

    -- generates permutations of mines within the cells
    local perms = self:generate_permutations(#frontier, mines)


    -- assigns permutations to the frontier
    self:count_permutations(perms, frontier)

end


-- n is the number of permutations, aka the length of the binary number,
-- and m is the count of 1s. c is the current 
function QuantumBoard:generate_permutations(n, m)

    -- i don't usually use local functions, but gpt suggests...
    -- o and z are ones and zeroes remaining to be added
    local function generate(current, o, z, perms)
        
        -- base case: nothing left to add
        if o == 0 and z == 0 then

            -- adds results when 
            table.insert(perms, table.concat(current))
            return
        end

        -- tries placing a one in this position
        if o > 0 then
            current[#current + 1] = "1"
            generate(current, o - 1, z, perms)
            table.remove(current)
        end

        -- tries placing a zero in this position
        if z > 0 then
            current[#current + 1] = "0"
            generate(current, o, z - 1, perms)
            table.remove(current)
        end
    end

    -- gneerates permutations
    local perms = {}
    generate({}, m, n - m, perms)


    -- there is a small chance there are more than 64 permutations,
    -- which can occur when revealing 8 new cells (an isolated cell)
    -- with a mine value of 4, resulting in 70 permutations.
    -- pop permutations until there are 64 or less
    while #perms > 64 do
        del(perms, rnd(perms))
    end

    -- converts each binary string sequence to a decimal number
    for i = 1, #perms do
        local d = 0
        for j = 1, #perms[i] do
            if (perms[i][j] == "1") d |= 1 << j
        end
        perms[i] = d
    end

    return perms
end


-- counts permutations and assigns them to the new frontier
function QuantumBoard:count_permutations(p, frontier)

    for i = 0, #frontier - 1 do

        -- grabs the current cell
        local cell = frontier[i + 1]

        -- assigns superposition
        cell.superposition = (1 << #p) - 1

        local eigenvalues = 0

        -- for each permutation where a mine is present, make the corresponding
        -- eigenvalue a one. so, the j-th digit corresponds to the j-th permutation
        for j = 0, #p - 1 do
            eigenvalues |= ((p[j + 1] >> i) & 1) << j
        end

        -- assigns value
        cell.eigenvalues = eigenvalues
    end
end


-- nCr function
function choose(n, m)
    return factorial(n) / (factorial(m) * factorial(n - m))
end

-- bang! factorial
function factorial(n)
    local m = 1
    for i = 2, n do
        m *= i
    end

    return i
end