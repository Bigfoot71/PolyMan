local pm = require("polyman")

local lg = love.graphics
local gw, gh = lg.getDimensions()
local gox, goy = gw/2, gh/2

math.randomseed(os.time())

local randomColor = function(alpha) -- rand color without gray

    local c = {
        math.random(),
        math.random() * .390625,
        math.random() * .390625 + 1 - .390625
    }

    table.sort(c, function(a, b)
        return math.random() < .5
    end)

    c[4] = alpha or 1

    return c

end

local triangle = pm.create.triangle(0,0,64)

local polygons = {
    {pm.create.random(gox,goy-128,7,64), randomColor()},        -- random polygon
    {pm.create.circle(gox-128,goy,64,8), randomColor()},        -- octogon
    {pm.create.circle(gox+128,goy,64,6), randomColor()},        -- hexagon
    {pm.create.ellipse(gox,goy+128,64,32,92), randomColor()},   -- ellipse 
}

local temp_rand_poly;
local editor = false
local click;

function love.update(dt)

    local mx, my = love.mouse.getPosition()

    if editor then

        ::begin::

        if not temp_rand_poly then
            temp_rand_poly = pm.create.random(mx,my,math.random(3,9),math.random(32,64))
        end

        pm.setPosition(temp_rand_poly, mx, my)

        if not click then

            if love.mouse.isDown(1) then

                for _, polygon in ipairs(polygons) do
                    local inside, nx, ny, dist = pm.collisions.polyInPoly(temp_rand_poly, polygon[1])
                    if inside then pm.setTranslation(temp_rand_poly, nx*dist, ny*dist) end
                end

                polygons[#polygons+1] = {temp_rand_poly, randomColor()}
                temp_rand_poly = nil
                click = true

            elseif love.mouse.isDown(2) then

                for i, polygon in ipairs(polygons) do
                    if pm.collisions.polyInPolyFast(temp_rand_poly, polygon[1]) then
                        local p = pm.operations.boolean(temp_rand_poly, polygon[1], "or", true)
                        polygons[i][1], temp_rand_poly, click = p, nil, true; break
                    end
                end

            end

            if click then
                goto begin
            end

        end

    else

        pm.setPosition(triangle, mx, my)

        if love.mouse.isDown(1) then pm.setRotation(triangle,-2*dt) end
        if love.mouse.isDown(2) then pm.setRotation(triangle,2*dt) end

        for _, polygon in ipairs(polygons) do
            local inside, nx, ny, dist = pm.collisions.polyInPoly(triangle, polygon[1])
            if inside then pm.setTranslation(triangle, nx*dist, ny*dist) end
        end

    end

end

function love.keypressed(key)
    if key == "space" then
        editor = not editor
    elseif key == "c" then
        for i, polygon in ipairs(polygons) do
            polygons[i][1] = pm.operations.convexHull(polygon[1])
        end
    end
end

function love.wheelmoved(dx,dy)
    pm.setScale(triangle,math.max(dy+.1,.9))
end

function love.mousereleased()
    click = false
end

function love.draw()

    for _, polygon in ipairs(polygons) do
        lg.setColor(polygon[2])
        lg.polygon("line", polygon[1])
    end

    lg.setColor(1,1,1)

    if editor then
        lg.polygon("line", temp_rand_poly)
    else
        lg.polygon("line", triangle)
    end

    lg.print("FPS: "..tostring(love.timer.getFPS()))

    local font = lg.getFont()
    local fh = font:getHeight()

    if editor then
        lg.print("Left click to add polygon", 0, gh-fh*2)
        lg.print("Right click to merge polygons", 0, gh-fh)
    else
        lg.print("Left/right click to rotate triangle", 0, gh-fh*2)
        lg.print("Wheel mouse to scale triangle", 0, gh-fh)
    end

    local str = "Press C to get the convex hulls"
    local strw = font:getWidth(str)
    lg.print(str, gw-strw, gh-fh*2)

    str = "Press SPACE to "..(editor and "quit" or "enter").." editor mode"
    strw = font:getWidth(str)
    lg.print(str, gw-strw, gh-fh)

end