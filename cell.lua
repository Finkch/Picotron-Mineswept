--[[
    represents a cell: one item on the game board.
    quick quantum mechanics recap:
        * eigenstate: a realised state out of all possible states
        * eigenvalue: a scalar factor representing the eigenstate's relation to the superposition
        * superposition: a (linear) combination of all eigenstates
]]

-- a cell is an item on the gameboard.
-- classic cells, or just cells, are as one would expact form minesweeper,
-- quantum cells track all possible states they could be in
Cell = {}
Cell.__index = Cell
Cell.__type = "cell"

function Cell:new(base_sprite)

    local c = {
        bs = base_sprite,   -- index of the first sprite in this sprite set
        s = base_sprite,    -- current sprite used by cell
        x = 0,              -- grid coordinates of cell
        y = 0,
        px = 0,             -- pixel coordinates of the cell
        py = 0,
        d = board.d,        -- board dimension
        value = 0,          -- count of adjacent mines
        revealed = false,   -- is revealed
        mine = false,       -- is a mine
        flag = false,       -- is a flag
        falsy = false,      -- is a false cell (aka, special flag)
        quantum = false,    -- whether the cell is a superposition of mine and not mine
        adj = {}            -- list of adjacent cells
    }

    setmetatable(c, Cell)
    return c
end


-- updates the value of this cell based on the count of adjacent mines
function Cell:count()
    self.value = 0
    local eigenstate = nil

    -- checks all neighbours for whether they are a mine
    for _, cell in ipairs(self.adj) do

        -- counts classical mines
        if (cell.mine) self.value += 1

        -- counts quantum mines
        if (cell.quantum) then

            -- finds a random eigenstate.
            -- use this eigenstate for all adjacent quantum cells
            if (not eigenstate) eigenstate = cell:infer()

            -- counts occurnaces of the previously found eigenstate.
            -- by requirement, all possible eigenstates as observed from
            -- any given cell must all have the same count. hence, we can
            -- simply use any random eigenstate.
            -- '& eigenvalue' ensures that the state corresponds to a mine
            if (cell.superposition & cell.eigenvalues & eigenstate > 0) self.value += 1
        end
    end
end



-- methods to toggle cell state
function Cell:reveal()

    -- can't unreveal a cell or reveal a flagged cell
    if (self.revealed or self.flag) return

    -- reveals
    self.revealed = true

    -- updates the cell's value if it's not a mine
    if (not self.mine) self:count()

    -- if this cell is zero, reveal neighbours
    self:reveal_neighbours()

    -- updates sprite
    self:set()
end

-- reveals neighbours in a random order, prioritising mines.
-- random order makes cruel/insidious gens less obvious
function Cell:reveal_neighbours()

    -- creates a list of indices for adjacent cells.
    -- list of indices so the actual adjaceny list is not modified
    local adjs = {}
    for _, adj in ipairs(self.adj) do

        -- if the cell is a mine, reveal it and back out
        if adj.mine then
            adj:reveal()
            return
        end

        add(adjs, adj)
    end

    -- pops adjacent cells until there are none left, or until it reveals a mine
    while #adjs > 0 and not state:__eq("gameover") do

        -- chooses a random cell
        local adj = del(adjs, rnd(adjs))

        -- reveals the cell
        adj:reveal()
    end
end

function Cell:mine()
    if self.mine then
        self.value = -1
        self.mine = true
    else
        self.value = 0
        self.mine = false
        self:count()
    end

    self:set()
end

function Cell:flag()
    self.flag = not self.flag
    self:set()
end

function Cell:falsy()
    self.falsly = not self.falsly
    self:set()
end


-- sets the sprite for the cell
function Cell:set()

    -- when cell is revealed
    if self.revealed then

        -- either cell is mine or regular cell
        if self.mine then
            self.s = self.bs + 9
        else
            self.s = self.bs + self.value
        end

    -- when the cell is flagged
    elseif self.flag then
        self.s = self.bs + 32

    -- otherwise, unrevealed sprite
    else
        self.s = self.bs
    end
end

function Cell:draw()
    spr(self.s, self.px, self.py)
end









-- like a regular cell, but tracks all its possible states at once.
-- reverts to a normal cell when observed
QuantumCell = setmetatable({}, Cell)
QuantumCell.__index = QuantumCell
quantumCell.__type = "quantumcell"

function QuantumCell:new(base_sprite)

    local qc = Cell:new(base_sprite)

    qc["quantum"]       = true  -- whether the cell is quantum or not
    qc["superposition"] = 0     -- the superposition state (aka variants)
    qc["eigenvalues"]   = 0     -- whether an eigenstate resolves to be a mine or no mine

    setmetatable(qc, QuantumCell)
    return qc
end


-- returns a random possible eigenstate given the cell's superposition.
-- this does not collapse the wavefunction
function QuantumCell:infer()
    local eigenstates = {}

    -- the current eigenstate being checked
    local eigenstate = 1

    -- finds all possible eigenstates
    while eigenstate <= self.superposition do
        if (self:is_entangled(eigenstate)) add(eigenstates, eigenstate)
        eigenstate = eigenstate << 1
    end

    -- return a random variant
    return rnd(eigenstates)
end


-- given an eigenstate or superposition, return whether this cell is entangled
function QuantumCell:is_entangled(supereigen)
    return self.superposition & supereigen > 0
end

-- given an eigenstate returns..
--  ..  1 if the cell is not a mine
--  ..  0 if the cell is not entangled to that eigenstate
--  .. -1 if the cell is a mine
function QuantumCell:resolve(eigenstate)

    -- not entangled to this state
    if (not self:is_entangled(eigenstate)) return 0

    -- is a mine
    if (self.eigenvalues & eigenstate > 0) return -1

    -- is not a mine
    return 1
end


-- observes the cell, collapsing the wavefunction and choosing an eigenstate.
--      !! todo !! this observation must affect entangled cells
function QuantumCell:observe(eigenstate)

    -- if no eigenstate was provided, choose one at random
    eigenstate = eigenstate or self:infer()

    -- ensures valid eigenstate
    assert(self:is_entangled(eigenstate), string.format("cannot observe non-entagled eigenstate; eigenstate '%s' for superposition '%s'", eigenstate, self.superposition))

    --[[ nyi
    for _, cell in pairs(self.entangled) do
        cell:observe(eigenstate)
    end
    ]]

    -- checks if in this state, there is mine
    self.mine = self:resolve(eigenstate) < 0

    -- collapses the wavefunciton, becoming a classical cell
    setmetatable(self, Cell)    

    -- when not a mine, update count
    if (not self.mine) self:count()
end