--[[
    a cobbled-together gui for mineswept
]]

include("lib/vec.lua")

Window = {}
Window.__index = Window
Window.__type = "window"

function Window:new(windowed, width, height)

    -- gets defaults when in fullscreen
    if not windowed then
        windowed = false
        width = 480
        height = 270
    end

    local w = {
        fullscreen = not fullscreen,
        w = width,
        h = height,
        p = 2,
        banner_h = 24
    }
    setmetatable(w, Window)

    -- creates a window
    if not w.fullscreen then
        window({
            width = w.w,
            height = w.h,
            resizable = true,
            title = "mineswept"
        })
    end
    
    logger(w.width, "window.lua")

    return w
end

-- moves camera
function Window:update()
    cam:focus(-Vec:new(2 * self.p, self.banner_h + 2 * self.p) + cam.centre)
end

-- draws window
function Window:draw()
    cls()

    -- absolute draws
    self:draw_frame()
    self:draw_banner()

    cam:focus(-Vec:new(2 * self.p, self.banner_h + 2 * self.p) + cam.centre)

    -- relative draws
    cam()

    board:draw()
    cursor:draw()


    cam(true)
end


-- the background and frame behind important elements
function Window:draw_frame()

    local p = self.p

    -- background colours
    rect(0, self.banner_h, self.w - 1, self.h - 1, 6)
    rect(1, self.banner_h + 1, self.w - 2, self.h - 2, 6)

    rectfill(0, 0, self.w, self.banner_h, 6)


    -- main window frame
    rect(p, self.banner_h + p, self.w - p - 1, self.h - p - 1, 7)

    line(p, self.banner_h + p, p, self.h - p - 1, 5)
    line(p, self.banner_h + p, self.w - p - 2, self.banner_h + p, 5)

    -- banner frame
    rect(p, p, self.w - p - 1, self.banner_h - p, 7)

    line(p, p, p, self.banner_h - p, 5)
    line(p, p, self.w - p - 2, p, 5)
end

function Window:draw_banner()

    local p = self.p

    -- moves the camera to the boxes
    cam:focus(-Vec:new(self.w / 3 - 15, self.banner_h / 2 - 5) + cam.centre)

    cam()

    -- boxes to contain banner elements
    rectfill(0, 0, 17, 10, 0)

    rect(-1, -1, 18, 11, 7)

    line(-1, -1, -1, 11, 5)
    line(-1, -1, 17, -1, 5)

    -- flag banner sprite
    spr(56, 21, -1)

    -- prints the guessed number of unflagged mines
    print(string.format("%03d", board.bombs - board.flags), p, p, 8)


    -- moves camera to the second box
    cam:focus(-Vec:new(self.w * 2 / 3 - 15, self.banner_h / 2 - 5) + cam.centre)
    cam()

    -- boxes to contain banner elements
    rectfill(0, 0, 17, 10, 0)

    rect(-1, -1, 18, 11, 7)

    line(-1, -1, -1, 11, 5)
    line(-1, -1, 17, -1, 5)

    -- need to draw a black box so sprite can contain black
    rectfill(21, -1, 33, 11, 0)

    -- clock banner sprite
    spr(57, 21, -1)

    -- prints elapsed time
    print(string.format("%03d", min(flr(clock:secs()), 999)), p, p, 8)


end