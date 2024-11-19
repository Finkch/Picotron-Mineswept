--[[pod_format="raw",created="2024-11-19 20:08:51",modified="2024-11-19 20:08:51",revision=0]]
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

function Cell:new(base_sprite, x, y, d)

    local c = {
        bs = base_sprite,   -- index of the first sprite in this sprite set
        s = base_sprite,    -- current sprite used by cell
        x = x,              -- grid coordinates of cell
        y = y,
        px = x * d,         -- pixel coordinates of the cell
        py = y * d,
        value = 0,          -- count of adjacent mines
        is_reveal   = false,-- is revealed
        is_mine     = false,-- is a mine
        is_flag     = false,-- is a flag
        is_false    = false,-- is a false cell (aka, special flag)
        is_quantum  = false,-- whether the cell is a superposition of mine and not mine
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
        if (cell.is_mine) self.value += 1

        -- counts quantum mines
        if (cell.is_quantum) then

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

-- this, er, uh...what does it do again?
function Cell:count_flags()
    local flags = 0

    for _, cell in ipairs(self.adj) do
        if (cell.is_flag) flags += 1
    end

    return flags
end



-- methods to toggle cell state
function Cell:reveal()

    -- if the cell is revealed, try to cord then return
    if (self.is_reveal and self.value == self:count_flags()) self:reveal_neighbours()

    -- can't reveal a flagged or revealed cell
    if (self.is_flag or self.is_reveal) return

    -- reveals
    self.is_reveal = true
    board.reveals += 1

    -- if the cell was revealed and was a mine, change to gameover
    if self.is_mine then
        state:change("gameover")
        self:set() -- update sprite

        return
    end

    -- updates the cell's value if it's not a mine
    self:count()

    -- if this cell is zero, reveal neighbours
    if (self.value == 0) self:reveal_neighbours()

    -- updates sprite
    self:set()

    -- if the final tile was revealed, and it isn't a gameover, win the game
    --      todo: push to board, or at least elsewhere?
    if board.w * board.h - board.bombs == board.reveals then
    
        -- push win to state
        state.data.win = true
        
        state:change("gameover")
    end
end

-- reveals neighbours in a random order, prioritising mines.
-- random order makes cruel/insidious gens less obvious
function Cell:reveal_neighbours()

    -- creates a list of indices for adjacent cells.
    -- list of indices so the actual adjaceny list is not modified
    local adjs = {}
    for _, adj in ipairs(self.adj) do

        -- don't bother if the cell is revealed or flagged
        if not (adj.is_reveal or adj.is_flag) then

            -- if the cell is a mine, reveal it and back out
            if adj.is_mine then
                adj:reveal()
                return
            end

            add(adjs, adj)
        end
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
    self.is_mine = not self.is_mine
    self:set()
end

function Cell:flag()
    self.is_flag = not self.is_flag
    self:set()
end

function Cell:falsy()
    self.is_false = not self.is_false
    self:set()
end


-- sets the sprite for the cell
function Cell:set()

    -- when cell is revealed
    if self.is_reveal then

        -- is a mine that is not flagged
        if self.is_mine then
            if not self.is_flag then
                self.s = self.bs + 25
            end

        -- an incorrect flag
        elseif self.is_flag then
            self.s = self.bs + 42

        -- normal reveal
        else
            self.s = self.bs + 16 + self.value
        end

    -- normal flag
    elseif self.is_flag then
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
QuantumCell.__type = "quantumcell"

function QuantumCell:new(base_sprite)

    local qc = Cell:new(base_sprite)

    qc["quantum"]       = true  -- whether the cell is quantum or not
    qc["superposition"] = 0     -- the superposition state (aka variants)
    qc["eigenvalues"]   = 0     -- whether an eigenstate resolves to be a mine or no mine

    setmetatable(qc, QuantumCell)
    return qc
end


-- obtains the collection of all eigenstates, state by state.
-- not really a hilbert space, but the closest analogue i could find
function QuantumCell:hilbert(space)

    -- default set of eigenstates are the superposition eigenstates
    space = space or self.superposition
    
    -- tracks data
    local eigenstates = {}
    local eigenstate = 1

    -- probes each possible eigenstate of the system that could exist
    while eigenstate <= self.superposition do
        if (self:is_entangled(eigenstate, space)) add(eigenstates, eigenstate)
        eigenstate = eigenstate << 1
    end

    return eigenstates
end




-- finds the ratio of eigenstates that are a mine to those that are not
function QuantumCell:ratio()
    local _, mineable = self:mineable()
    local _, cellable = self:cellable()

    return len(mineable) / len(cellable)
end

-- returns whether this cell can be a mine, and a list of mineable variants
function QuantumCell:mineable()

    -- we don't need the '&,' but i'm keeping it for clarity
    local cells = self:hilbert(self.superposition & self.eigenvalues)

    return #cells > 0, cells
end


-- returns whether this cell can be a mineless cell, and a list of mineless variants
function QuantumCell:cellable()
    local cells = self:hilbert(self.superposition & not self.eigenvalues)
    return #cells > 0, cells
end




-- returns a random possible eigenstate given the cell's superposition.
-- this does not collapse the wavefunction
function QuantumCell:infer()
    return rnd(self:hilbert())
end


-- given an eigenstate or superposition, return whether 
-- this cell is entangled in the given space.
-- default space is entire superposition space
function QuantumCell:is_entangled(supereigen, space)
    space = space or self.superposition
    return space & supereigen > 0
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
    self.quantum = false
end