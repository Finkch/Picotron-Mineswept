--[[
    allows either the mouse or arrow keys to be used as input
]]

include("lib/vec.lua")

Cursor = {}
Cursor.__index = Cursor
Cursor.__type = "cursor"

function Cursor:new()

    local c = {
        pos = Vec:new(),
        lpos = Vec:new(),
        mouse = true,
        speed = 1,
        action = nil
    }

    setmetatable(c, Cursor)
    return c
end


-- update
function Cursor:update()

    -- polls kbm
    kbm:update()

    -- tracks whether the mouse was the previous method of input
    if (self:keydown()) self.mouse = false

    if self:mousedown() then
        self.lpos = kbm.pos
        self.mouse = true
    end

    self:input()

end

-- checks if the arrow keys are in use
function Cursor:keydown()
    return kbm:held("left") or kbm:held("right") or kbm:held("up") or kbm:held("down")
end

-- checks if the mouse is in use
function Cursor:mousedown()
    return self.lpos != kbm.pos or kbm:held("lmb") or kbm:held("rmb")
end


-- handles inputs
function Cursor:input()
    
    -- updates cursor's position
    if self.mouse then
        self.pos = kbm.pos
    else
        if (kbm:held("left"))   self.pos += Vec:new(-self.speed, 0)
        if (kbm:held("right"))  self.pos += Vec:new(self.speed, 0)
        if (kbm:held("up"))     self.pos += Vec:new(0, -self.speed)
        if (kbm:held("down"))   self.pos += Vec:new(0, self.speed)
    end

    -- sends an action
    if kbm:released("lmb") or kbm:released("x") then
        self.action = "reveal"
    elseif kbm:released("rmb") or kbm:released("z") then
        self.action = "flag"
    else
        self.action = nil
    end
end


-- maps the coordinates down
function Cursor:map(d)
    return self.pos.x // d, self.pos.y // d
end

-- maps down then back up
function Cursor:mapu(d)
    return self.pos.x // d * d, self.pos.y // d * d
end


function Cursor:draw()

    -- draw a special cursor when mouse is not in use
    if not self.mouse then
        window({cursor = 0})
        spr(59, self.pos.x - 8, self.pos.y - 8)
    else
        window({cursor = 1})
    end

    -- shows which tile the cursor would select
    local x, y = self:map(board.d)

    -- don't if out of bounds
    if (not board:inbounds(x, y)) return

    -- snaps to grid
    x, y = self:mapu(board.d)

    -- otherwise, draw sprite
    spr(board.bs + 50, x, y)
end