-- written by Le Juez Victor - from https://github.com/Bigfoot71/simplify-lua
-- MIT license

local simplifyRadialDistance = function(points, sqTolerance)

    local prev_x, x = points[1], nil
    local prev_y, y = points[2], nil

    local new_points = {prev_x, prev_y}

    for i = 1, #points-1, 2 do
        x, y = points[i], points[i+1]
        if math.sqrt((x-prev_x)^2+(y-prev_y)^2) > sqTolerance then
            new_points[#new_points+1] = x
            new_points[#new_points+1] = y
            prev_x, prev_y = x, y
        end
    end

    if prev_x ~= x and prev_y ~= y then
        new_points[#new_points+1] = x
        new_points[#new_points+1] = y
    end

    return new_points

end

local simplifyDPStep
simplifyDPStep = function(points, first, last, sqTolerance, simplified)

    local maxDist, index = sqTolerance, nil

    local x1, y1 = points[first], points[first+1]
    local x2, y2 = points[last], points[last+1]

    for i = first+2, last, 2 do

        local x, y = points[i], points[i+1]

        local dx = x2 - x1
        local dy = y2 - y1

        if dx ~= 0 or dy ~= 0 then

            local t = ((x - x1) * dx + (y - y1) * dy) / (dx^2 + dy^2)

            if t > 1 then
                x1, y1 = x2, y2
            elseif t > 0 then
                x1 = x1 + dx * t
                y1 = y1 + dy * t
            end

        end

        local dist = (x-x1)^2+(y-y1)^2

        if (dist > maxDist) then
            index, maxDist = i, dist
        end

    end

    if maxDist > sqTolerance then

        if index - first > 1 then
            simplifyDPStep(points, first, index, sqTolerance, simplified)
            simplified[#simplified+1] = points[index]
            simplified[#simplified+1] = points[index+1]
        end

        if last - index > 1 then
            simplifyDPStep(points, index, last, sqTolerance, simplified)
        end

    end

end

local simplifyDouglasPeucker = function(points, sqTolerance)

    local last = #points-1
    local simplified = {points[1], points[2]}

    simplifyDPStep(points, 1, last, sqTolerance, simplified)

    simplified[#simplified+1] = points[last]
    simplified[#simplified+1] = points[last+1]

    return simplified;

end

return function (points, tolerance, highestQuality)

    tolerance = tolerance or .1
    highestQuality = highestQuality or true

    local sqtolerance = tolerance ^ 2

    if not highestQuality then
        points = simplifyRadialDistance(points, sqtolerance)
    end

    points = simplifyDouglasPeucker(points, sqtolerance)

    return points

end