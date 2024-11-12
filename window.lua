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

    local bh = 24
    local p = 2

    local w = {
        fullscreen = not fullscreen,
        w = width,
        h = height,
        p = p,              -- padding
        b = 15 * p,         -- buffer; big padding
        banner_h = bh,
        wt = bh + 2 * p - 1, -- game window edges
        wb = height - 2 * p + 1,
        wl = 2 * p - 1,
        wr = width - 2 * p + 1,
        st = 0,
        sb = 0,
        sl = 0,
        sr = 0,
        focal = Vec:new(0, 0)           -- centre of camera
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

    return w
end

-- updates the window bounds based on the board
function Window:edges()
    self.sl = 0
    self.sr = board.w * board.d - 1
    self.st = 0
    self.sb = board.h * board.d - 1
end

-- moves camera
function Window:update()

    -- if the cursor is on the edge of the window, pan
    if not (kbm:held("space") and cursor.mouse) then

        local s = 1
        if (kbm:held("space")) s *= 2

        -- prevents panning if the map is too small
        if board.w * board.d > self.w - 4 * self.p then

            -- pans if cursor is at edge of screen
            if cursor.pos.x < self.wl + self.b then
                self.focal.x += s
            elseif cursor.pos.x > self.wr - self.b then
                self.focal.x -= s
            end
        end

        if board.h * board.d > self.h - 4 * self.p - self.banner_h then
            if (cursor.pos.y < self.wt + self.b) and not (cursor.pos.y < self.banner_h) then
                self.focal.y += s
            elseif cursor.pos.y > self.wb - self.b then
                self.focal.y -= s
            end
        end
    end

    -- bounds camera
    self.focal.x = min(-self.sl, self.focal.x)
    self.focal.x = max(-self.sr, self.focal.x)

    self.focal.y = min(-self.st, self.focal.y)
    self.focal.y = max(-self.sb, self.focal.y)

    -- sets the focus
    cam:focus(-self.focal)
end


-- draws a box
function Window:box(l, t, r, b, two_wide, background)

    if (not background) background = 0

    local c1, c2 = 7, 5

    if (background != 0) c1, c2 = c2, c1

    -- background
    rectfill(l, t, r, b, background)

    -- grey border
    rect(l, t, r, b, c1)

    -- white border
    line(l, t, l, b, c2)
    line(l, t, r - 1, t, c2)

    -- additional border
    if two_wide then
        rect(l + 1, t + 1, r - 1, b - 1, c1)

        line(l + 1, t + 1, l + 1, b - 1, c2)
        line(l + 1, t + 1, r - 2, t + 1, c2)
    end

end

-- draws window
function Window:draw()
    cls()

    -- relative draws
    cam()

    if (not state:__eq("menu")) board:draw()

    cam(true)

    -- absolute draws
    self:draw_frame()
    self:draw_banner()

    cam(true)

    -- state appropriate draws

    -- menus
    if state:__eq("menu") then

        self:draw_menu()

    -- board and cursor
    -- well, board is in another step
    elseif state:__eq("play") then

        -- more relative draws
        cam:focus(-self.focal)
        cam()

        cursor:draw()

    -- menus
    elseif state:__eq("gameover") then

        self:draw_gameover()
    end
    

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
    cam:focus(-Vec:new(self.w / 3 - 17, self.banner_h / 2 - 5) + cam.centre)

    cam()

    -- boxes to contain banner elements
    self:box(-1, -1, 23, 11, false)

    -- flag banner sprite
    spr(56, 26, -1)

    -- prints the guessed number of unflagged mines
    print(string.format("%04d", board.bombs - board.flags), p, p, 8)


    -- moves camera to the second box
    cam:focus(-Vec:new(self.w * 2 / 3 - 17, self.banner_h / 2 - 5) + cam.centre)
    cam()

    -- boxes to contain banner elements
    self:box(-1, -1, 23, 11, false)

    -- need to draw a black box so sprite can contain black
    rectfill(26, -1, 38, 11, 0)

    -- clock banner sprite
    spr(57, 26, -1)

    -- prints elapsed time
    print(string.format("%04d", min(flr(clock:secs()), 999)), p, p, 8)


end


function Window:draw_gameover()

    -- precalculations
    local w = 41
    local wm = self.w / 2

    local wt = self.h / 2 + w
    local wl = wm - 2 * w
    local wr = wm + 2 * w

    local tl = self.h / 2 + w + 2 * self.p + 1

    -- box to contain the messages
    self:box(wl, wt, wr, wt + w, true)

    local gameover_message = "gameover!"
    if (state.data.win) gameover_message = "you win!"

    -- centres the messages
    local pw = print(gameover_message, 500, 500, 8) - 500
    print(gameover_message, wm - pw / 2, tl, 8)


    if cursor.mouse then
        pw = print("left click to start a new game", 500, 500, 8) - 500
        print("left click to start a new game", wm - pw / 2, tl + 12, 8)

        pw = print("right click to return to menu", 500, 500, 8) - 500
        print("right click to return to menu", wm - pw / 2, tl + 24, 8)
    else
        pw = print("press x to start a new game", 500, 500, 8) - 500
        print("press x to start a new game", wm - pw / 2, tl + 12, 8)

        pw = print("press z to return to menu", 500, 500, 8) - 500
        print("press z to return to menu", wm - pw / 2, tl + 24, 8)
    end

end

function Window:draw_menu()

    -- precalcs
    local wm = self.w / 2
    
    local t = 80
    local b = 30

    local pw = print("0000", 500, 500) - 500

    local c1, c2, c3, c4 = 5, 5, 5, 5

    -- conditional highlighting
    if state.data.mi == 0 then
        c1 = 8

        print("width", wm - t, t + 3, 5)
        print(state.data.mind, wm - b - 9, t + 3, 5)
        print(state.data.maxd, wm + b + 3, t + 3, 5)

        spr(60, wm - 13 - 15, t + 1)
        spr(61, wm + 16, t + 1)
    elseif state.data.mi == 1 then
        c2 = 8

        print("height", wm - t, t + b + 3, 5)
        print(state.data.mind, wm - b - 9, t + b + 3, 5)
        print(state.data.maxd, wm + b + 3, t + b + 3, 5)

        spr(60, wm - 13 - 15, t + b + 1)
        spr(61, wm + 16, t + b + 1)
    elseif state.data.mi == 2 then
        c3 = 8

        print("mines", wm - t, t + 2 * b + 3, 5)
        print(state.data.minmines, wm - b - 9, t + 2 * b + 3, 5)
        print(state.data.maxmines, wm + b + 3, t + 2 * b + 3, 5)

        spr(60, wm - 13 - 15, t + 2 * b + 1)
        spr(61, wm + 16, t + 2 * b + 1)
    elseif state.data.mi == 3 then
        c4 = 8

        print("difficulty", wm - t, t + 3 * b + 3, 5)

        spr(60, wm - 13 - 15, t + 3 * b + 1)
        spr(61, wm + 16, t + 3 * b + 1)
    end


    -- width selection
    self:box(wm - pw / 2 - 3, t, wm + pw / 2 + 1, t + 12)
    print(string.format("%04d", board.w), wm - pw / 2, t + 3, c1)


    -- height selection
    self:box(wm - pw / 2 - 3, t + b, wm + pw / 2 + 1, t + b + 12)
    print(string.format("%04d", board.h), wm - pw / 2, t + b + 3, c2)


    -- mines selection
    self:box(wm - pw / 2 - 3, t + 2 * b, wm + pw / 2 + 1, t + 2 * b + 12)
    print(string.format("%04d", board.bombs), wm - pw / 2, t + 2 * b + 3, c3)


    -- difficulty select
    self:box(wm - pw / 2 - 3, t + 3 * b, wm + pw / 2 + 1, t + 3 * b + 12)
    if state.data.fairness == 0 then
        print("easy", wm - pw / 2, t + 3 * b + 3 - 1, c4)
    elseif state.data.fairness == 1 then
        print("hard", wm - pw / 2, t + 3 * b + 3, c4)
    end
    


    -- draws box
    if cursor.mouse then
        pw = print("right click to start", 500, 500) - 500
        self:box(wm - pw / 2 - 4, t + 4 * b, wm + pw / 2 + 3, t + 4 * b + 16, true, 6)

        -- text shadow
        print("right click to start", wm - pw / 2, t + 4 * b + 5, 5)
        print("right click to start", wm - pw / 2 + 1, t + 4 * b + 4, 5)
        print("right click to start", wm - pw / 2 + 1, t + 4 * b + 5, 5)

        -- text
        print("right click to start", wm - pw / 2, t + 4 * b + 4, 7)
    else
        pw = print("press x to start", 500, 500) - 500
        self:box(wm - pw / 2 - 4, t + 4 * b, wm + pw / 2 + 3, t + 4 * b + 16, true, 6)

        -- text shadow
        print("press x to start", wm - pw / 2, t + 4 * b + 5, 5)
        print("press x to start", wm - pw / 2 + 1, t + 4 * b + 4, 5)
        print("press x to start", wm - pw / 2 + 1, t + 4 * b + 5, 5)

        -- text
        print("press x to start", wm - pw / 2, t + 4 * b + 4, 7)
    end
end