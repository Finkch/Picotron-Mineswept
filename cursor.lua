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
        speed = 1
    }

    setmetatable(c, Cursor)
    return c
end


function Cursor:update()

    -- polls kbm
    kbm:update()

    -- tracks whether the mouse was the previous method of input
    if (self:keydown()) self.mouse = false

    if self:mousedown() then
        self.lpos = kbm.pos
        self.mouse = true
    end


    -- don't draw the cursor if keyboard is in use
    if not self.mouse then
        window({cursor = 0})
    else
        window({cursor = 1})
    end


    -- updates cursor's position
    if self.mouse then
        self.pos = kbm.pos
    else
        if (kbm:held("left"))   self.pos += Vec:new(-self.speed, 0)
        if (kbm:held("right"))  self.pos += Vec:new(self.speed, 0)
        if (kbm:held("up"))     self.pos += Vec:new(0, -self.speed)
        if (kbm:held("down"))   self.pos += Vec:new(0, self.speed)
    end

end

function Cursor:keydown()
    return kbm:held("left") or kbm:held("right") or kbm:held("up") or kbm:held("down")
end

function Cursor:mousedown()
    return self.lpos != kbm.pos or kbm:held("lmb") or kbm:held("rmb")
end

function Cursor:input()
end