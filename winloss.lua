--[[
    writes to a file to track user's win-loss ratio
]]

include("lib/log.lua")

Winlosser = {}
Winlosser.__index = Winlosser
Winlosser.__type = "winlosser"

function Winlosser:new()

    local d = "appdata/mineswept"

    local w = {
        d = d,                  -- directory to which to write
        f = "wl.txt",           -- file to which to write
        w = 0,                  -- number of wins
        l = 0                   -- number of losses
    }

    setmetatable(w, Winlosser)

    -- grabs w:l ratio
    w:read()

    return w
end


-- writes to the file
function Winlosser:write(data)
    log(self.f, data, {"-d " .. self.d})
end

-- reads from file
function Winlosser:read()

    -- fetches the file contents
    local contents = unlog(self.f, self.d)

    -- creates new file in case one does not exist
    if (not contents) then
        self:clear()
        contents = unlog(self.f, self.d)
    end

    -- gets the number of wins and losses.
    -- thanks, chatgpt, for doing the regex for me
    local w, l = contents:match("w:(%d+)%s*l:(%d+)")

    -- converts from string to int
    self.w, self.l = tonumber(w), tonumber(l)
end

-- clears the file, resetting w:l
function Winlosser:clear()
    self.w, self.l = 0, 0
    self:update()
end

-- updates the file to match winlosser's w:l
function Winlosser:update()
    self:write(string.format("w:%d\nl:%d", self.w, self.l))
end