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
        mpos = Vec:new(),
        lmpos = Vec:new(),
        mouse = true,
        pant = 0, -- pan not -> pan't -> pant
        speed = 1,
        action = nil
    }

    setmetatable(c, Cursor)
    return c
end


-- update
function Cursor:update()

    -- updates raw mouse position
    self.lmpos = self.mpos
    self.mpos = Vec:new(mouse())

    -- tracks whether the mouse was the previous method of input
    if self:keydown() then
        self.pos = Vec:new(wind.w / 2, wind.h / 2)
        self.mouse = false
    end

    if self:mousedown() then
        self.lpos = kbm.spos
        self.mouse = true
    end

    -- performs actions depending on inputs
    self:input()

    -- binds cursor to screen
    self.pos.x = mid(8, self.pos.x, 472)
    self.pos.y = mid(8, self.pos.y, 262)
end

-- checks if the arrow keys are in use
function Cursor:keydown()
    return kbm:held("left") or kbm:held("right") or kbm:held("up") or kbm:held("down")
end

-- checks if the mouse is in use
function Cursor:mousedown()
    return self.lpos != kbm.spos or kbm:held("lmb") or kbm:held("rmb")
end

-- checks whether the cursor should pan
function Cursor:pan()
    return kbm:held("space") or kbm:held("lshift") or kbm.keys["lmb"].down > 5
end


-- handles inputs
function Cursor:input()

    -- don't accept input while panning
    if not (self:pan()) then
    
        -- updates cursor's position
        if self.mouse then
            self.pos = kbm.spos
        else
            if (kbm:held("left"))   wind.focal += Vec:new(self.speed, 0)
            if (kbm:held("right"))  wind.focal += Vec:new(-self.speed, 0)
            if (kbm:held("up"))     wind.focal += Vec:new(0, self.speed)
            if (kbm:held("down"))   wind.focal += Vec:new(0, -self.speed)
        end

        -- sends an action
        if kbm:released("lmb") and self.pant > 0 or kbm:released("x") then
            self.action = "reveal"
        elseif kbm:released("rmb") and self.pant > 0 or kbm:released("z") then
            self.action = "flag"
        else
            self.action = nil
        end


    -- pan the camera
    else
        
        -- mouse pan
        wind.focal += self.mpos - self.lmpos

        -- fast arrow key movement
        if (kbm:held("left"))   wind.focal += Vec:new(2.5 * self.speed, 0)
        if (kbm:held("right"))  wind.focal += Vec:new(-2.5 * self.speed, 0)
        if (kbm:held("up"))     wind.focal += Vec:new(0, 2.5 * self.speed)
        if (kbm:held("down"))   wind.focal += Vec:new(0, -2.5 * self.speed)
    end

    -- update time since last pan.
    -- ensures stopping a pan doesn't immediately reveal
    if self:pan() then
        self.pant = 0
    else
        self.pant += 1
    end
end


-- maps the coordinates down
function Cursor:posm()
    return self.pos + cam.pos
end

function Cursor:map(d)
    local pos = self:posm()
    return pos.x // d, pos.y // d
end

-- maps down then back up
function Cursor:mapu(d)
    local x, y = self:map(d)
    return x * d, y * d
end

-- draw
function Cursor:draw()

    cam()

    -- draw a special cursor when mouse is not in use
    if not self.mouse then
        window({cursor = 0})
        local x, y = self:posm():u()

        if (state:__eq("play")) spr(59, x - 8, y - 8)
    else
        window({cursor = 1})
    end

    -- shows which tile the cursor would select
    if (self:pan() or state:__eq("menu") or state:__eq("gameover")) return

    local x, y = self:map(board.d)

    -- don't if out of bounds
    if (not board:inbounds(x, y)) return

    -- snaps to grid
    x, y = self:mapu(board.d)

    -- otherwise, draw sprite
    spr(board.bs + 50, x, y)

    cam(true)
end