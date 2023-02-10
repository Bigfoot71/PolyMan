-- written by Le Juez Victor
-- MIT license

local function getLineIntersection(x1,y1, x2,y2, x3,y3, x4,y4)
    local dx1, dy1 = x2 - x1, y2 - y1
    local dx2, dy2 = x4 - x3, y4 - y3
    local dx3, dy3 = x1 - x3, y1 - y3
    local d = dx1*dy2 - dy1*dx2
    if d == 0 then return false end
    local t1 = (dx2*dy3 - dy2*dx3)/d
    if t1 < 0 or t1 > 1 then return false end
    local t2 = (dx1*dy3 - dy1*dx3)/d
    if t2 < 0 or t2 > 1 then return false end
    return x1 + t1*dx1, y1 + t1*dy1
end

local function isPointOnLine(px, py, x1, y1, x2, y2)
    if x1 == x2 then return px == x1 and math.min(y1, y2) <= py and py <= math.max(y1, y2) end
    local m = (y2 - y1) / (x2 - x1)
    local b = y1 - m * x1
    return py == m * px + b
end

return function (polygon)   -- TODO: optimize this with better algorithm

    local len = #polygon

    local simplified = {}
    local intersections = {}

    -- Loop through all lines in the polygon to find intersections

    for i = 1, len - 3, 2 do
        for j = i + 2, len - 1, 2 do

            -- Ignore identical segmements

            if i ~= j then

                local i2 = (i+2<len) and i+2 or 1
                local j2 = (j+2<len) and j+2 or 1

                local x1, y1 = polygon[i], polygon[i+1]
                local x2, y2 = polygon[i2], polygon[i2+1]
                local x3, y3 = polygon[j], polygon[j+1]
                local x4, y4 = polygon[j2], polygon[j2+1]

                -- Calculate the intersection between the two lines
                local x, y = getLineIntersection(x1,y1,x2,y2,x3,y3,x4,y4)

                -- If there is an intersection add the intersection to the list of intersections
                if x and y then table.insert(intersections, {x, y}) end

            end

        end
    end

    -- Loop through all the lines in the polygon to simplify it

    for i = 1, len - 3, 2 do

        local i2 = (i+2<len) and i+2 or 1

        local x1, y1 = polygon[i], polygon[i+1]
        local x2, y2 = polygon[i2], polygon[i2+1]

        -- Loop through all intersections
        for j, isect in ipairs(intersections) do
            -- Check if the intersection is on the line
            if isPointOnLine(isect[1],isect[2], x1,y1, x2,y2) then
                -- If yes, do not add the line to the simplified list
                goto continue
            end
        end

        -- Add the line to the simplified table

        simplified[#simplified+1] = x1
        simplified[#simplified+1] = y1
        simplified[#simplified+1] = x2
        simplified[#simplified+1] = y2

        ::continue::

    end

    return simplified

end