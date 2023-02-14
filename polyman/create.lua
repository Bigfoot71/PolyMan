-- written by Le Juez Victor
-- MIT license

local sin, cos, pi = math.sin, math.cos, math.pi
local acos, rand = math.acos, math.random
local floor = math.floor

local function triangle(cx, cy, sideLength, type)
    type = type or "equilateral"
    if type == "equilateral" then
        local halfSide = sideLength / 2
        local height = halfSide * (3^0.5)
        return {
            cx, cy - height / 2,
            cx + halfSide, cy + height / 2,
            cx - halfSide, cy + height / 2
        }
    elseif type == "isosceles" then
        local height = sideLength / 2
        return {
            cx - height, cy + height,
            cx + height, cy + height,
            cx, cy - height
        }
    elseif type == "rectangle" then
        local halfSide = sideLength / 2
        local quatSide = halfSide / 2
        return {
            (cx - halfSide) + quatSide, (cy - halfSide) - quatSide,
            (cx - halfSide) + quatSide, (cy + halfSide) - quatSide,
            (cx + halfSide) + quatSide, (cy + halfSide) - quatSide
        }
    end
end

local function rectangle(cx, cy, width, height)
    return {
        cx - width / 2, cy - height / 2,
        cx - width / 2, cy + height / 2,
        cx + width / 2, cy + height / 2,
        cx + width / 2, cy - height / 2
    }
end

local function ellipse(cx, cy, rx, ry, segments)
    segments = segments or 40
    local vertices = {cx,cy}
    for i=0, segments do
        local angle = (i / segments) * pi * 2
        local x = cx + cos(angle) * rx
        local y = cy + sin(angle) * ry
        vertices[#vertices+1] = x
        vertices[#vertices+1] = y
    end
    return vertices
end

local function circle(cx,cy,r,segments,err)
    return ellipse(cx,cy,r,r,segments or floor((pi/acos(1-(err or 0.33)/r)+.5)))
end

local function donut(cx, cy, rx, ry, hrx, hry, segments)
    segments = segments or 40
    local vertices = {}
    for i=0, segments do
        local angle = (i / segments) * pi * 2
        local x = cx + cos(angle) * rx
        local y = cy + sin(angle) * ry
        vertices[#vertices+1] = x
        vertices[#vertices+1] = y
    end
    for i=0, segments do
        local angle = (i / segments) * pi * 2
        local x = cx + cos(angle) * hrx
        local y = cy + sin(angle) * hry
        vertices[#vertices+1] = x
        vertices[#vertices+1] = y
    end
    return vertices
end

local function random(cx, cy, numSides, maxRadius)
    maxRadius = maxRadius or 100
    local vertices = {}
    for i = 1, numSides do
        local angle = 2 * pi * (i - 1) / numSides
        local radius = maxRadius * rand()
        local x = cx + radius * cos(angle)
        local y = cy + radius * sin(angle)
        vertices[#vertices + 1] = x
        vertices[#vertices + 1] = y
    end
    return vertices
end

return {
    triangle = triangle,
    rectangle = rectangle,
    ellipse = ellipse,
    circle = circle,
    donut = donut,
    random = random,
};