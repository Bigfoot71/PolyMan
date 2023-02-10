-- written by Le Juez Victor
-- MIT license

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
        local angle = (i / segments) * math.pi * 2
        local x = cx + math.cos(angle) * rx
        local y = cy + math.sin(angle) * ry
        vertices[#vertices+1] = x
        vertices[#vertices+1] = y
    end
    return vertices
end

local function circle(cx,cy,r,segments,err)
    return ellipse(cx,cy,r,r,segments or math.floor((math.pi/math.acos(1-(err or 0.33)/r)+.5)))
end

local function random(cx, cy, numSides, maxRadius)
    maxRadius = maxRadius or 100
    local vertices = {}
    for i = 1, numSides do
        local angle = 2 * math.pi * (i - 1) / numSides
        local radius = maxRadius * math.random()
        local x = cx + radius * math.cos(angle)
        local y = cy + radius * math.sin(angle)
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
    random = random,
};