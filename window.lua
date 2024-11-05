--[[
    a cobbled-together gui for mineswept
]]

Window = {}
Window.__index = Window
Window.__type = "window"

function Window:new(windowed, width, height)

    -- gets defaults when in fullscreen
    if windowed then
        windowed = false
        width = 480
        height = 270
    end

    local w = {
        fullscreen = not fullscreen,
        width = width,
        height = height
    }
    setmetatable(w, Window)

    -- creates a window
    if not w.fullscreen then
        window({
            width = w.width,
            height = w.height,
            resizable = true,
            title = "mineswept"
        })
    end

    return w
end