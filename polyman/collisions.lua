-- written by Le Juez Victor
-- MIT license

local function pointInPolyFast(px,py,polygon)
    local oddNodes = false
    local j = #polygon-1
    for i = 1, #polygon-1, 2 do
      if ((polygon[i+1] < py and polygon[j+1] >= py) or (polygon[j+1] < py and polygon[i+1] >= py)) then
        if (polygon[i] + (py - polygon[i+1]) / (polygon[j+1] - polygon[i+1]) * (polygon[j] - polygon[i]) < px) then
          oddNodes = not oddNodes
        end
      end
      j = i
    end
    return oddNodes
end

local function polyInPolyFast(p1, p2)
    for i = 1, #p1-1, 2 do
        if pointInPolyFast(p1[i], p1[i+1], p2) then return true end
    end
    for i = 1, #p2-1, 2 do
        if pointInPolyFast(p2[i], p2[i+1], p1) then return true end
    end
    for i1 = 1, #p1-1, 2 do
        local i2 = i1+2 < #p1 and i1+2 or 1
        for j1 = 1, #p2-1, 2 do
            local j2 = (j1+2 < #p2) and j1+2 or 1
            local x1, y1 = p1[i1], p1[i1+1]
            local x2, y2 = p1[i2], p1[i2+1]
            local x3, y3 = p2[j1], p2[j1+1]
            local x4, y4 = p2[j2], p2[j2+1]
            local dx1, dy1 = x2 - x1, y2 - y1
            local dx2, dy2 = x4 - x3, y4 - y3
            local dx3, dy3 = x1 - x3, y1 - y3
            local d = dx1*dy2 - dy1*dx2
            if d == 0 then goto continue end
            local t1 = (dx2*dy3 - dy2*dx3)/d
            if t1 < 0 or t1 > 1 then goto continue end
            local t2 = (dx1*dy3 - dy1*dx3)/d
            if t2 < 0 or t2 > 1 then goto continue
            else return true end
            ::continue::
        end
    end
    return false
end

local function pointInPoly(x, y, polygon)
    local intersections = 0
    local vertices = #polygon/2
    local closest_x, closest_y = polygon[1], polygon[2]
    local closest_distance = math.huge
    local closest_normal_x, closest_normal_y
    for i = 1, vertices do
        local j = i % vertices + 1
        local x1, y1 = polygon[2*i-1], polygon[2*i]
        local x2, y2 = polygon[2*j-1], polygon[2*j]
        if ((y1 > y) ~= (y2 > y)) and (x < (x2-x1) * (y-y1) / (y2-y1) + x1) then
            intersections = intersections + 1
        end
        local segment_distance = math.min(math.sqrt((x-x1)^2+(y-y1)^2), math.sqrt((x-x2)^2+(y-y2)^2))
        if segment_distance < closest_distance then
            closest_distance = segment_distance
            closest_x, closest_y = x, y
            local segment_normal_x, segment_normal_y = y2-y1, x1-x2
            local segment_normal_length = math.sqrt(segment_normal_x * segment_normal_x + segment_normal_y * segment_normal_y)
            closest_normal_x, closest_normal_y = segment_normal_x / segment_normal_length, segment_normal_y / segment_normal_length
        end
    end
    return (intersections % 2) == 1, closest_x, closest_y, closest_normal_x, closest_normal_y, closest_distance
end

local function polyInPoly(polygon1, polygon2)
    local min_distance = math.huge
    local min_nx, min_ny

    -- Calculate the normals for each line of the second polygon
    for i = 1, #polygon2, 2 do

        local x1, y1, x2, y2
        if i == #polygon2 - 1 then
            x1, y1 = polygon2[i], polygon2[i+1]
            x2, y2 = polygon2[1], polygon2[2]
        else
            x1, y1 = polygon2[i], polygon2[i+1]
            x2, y2 = polygon2[i+2], polygon2[i+3]
        end

        local nx, ny = y2-y1, x1-x2
        local length = math.sqrt(nx * nx + ny * ny)
        nx = nx / length
        ny = ny / length

        -- Checks the minimum distance between the two polygons along each normal
        local min1, max1, min2, max2 = math.huge, -math.huge, math.huge, -math.huge
        for j = 1, #polygon1, 2 do
            local dot = nx * polygon1[j] + ny * polygon1[j+1]
            min1 = math.min(min1, dot)
            max1 = math.max(max1, dot)
        end
        for j = 1, #polygon2, 2 do
            local dot = nx * polygon2[j] + ny * polygon2[j+1]
            min2 = math.min(min2, dot)
            max2 = math.max(max2, dot)
        end

        -- If the polygons do not overlap, there is no collision
        if min1 > max2 or min2 > max1 then
            return false
        end

        local distance = math.min(max2 - min1, max1 - min2)

        if distance < min_distance then
            min_distance = distance
            min_nx, min_ny = nx, ny
            if max2 - min1 > max1 - min2 then
                min_nx = -min_nx
                min_ny = -min_ny
            end
        end

    end

    return true, min_nx, min_ny, min_distance

end

local function segmentPoly(x1, y1, x2, y2, polygon)
    local len = #polygon
    for i = 1, len-1, 2 do
        local j = (i+2 < len) and i+2 or 1
        local x3, y3 = polygon[i], polygon[i+1]
        local x4, y4 = polygon[j], polygon[j+1]
        local dx1, dy1 = x2 - x1, y2 - y1
        local dx2, dy2 = x4 - x3, y4 - y3
        local dx3, dy3 = x1 - x3, y1 - y3
        local d = dx1*dy2 - dy1*dx2
        if d == 0 then goto continue end
        local t1 = (dx2*dy3 - dy2*dx3)/d
        if t1 < 0 or t1 > 1 then goto continue end
        local t2 = (dx1*dy3 - dy1*dx3)/d
        if t2 < 0 or t2 > 1 then goto continue
        else return true end
        ::continue::
    end
    return false
end

return {

    pointInPolyFast = pointInPolyFast,
    polyInPolyFast = polyInPolyFast,

    pointInPoly = pointInPoly,
    polyInPoly = polyInPoly,

    segmentPoly = segmentPoly

};