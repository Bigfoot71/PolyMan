-- written by Le Juez Victor
-- MIT license

local PATH = ...

local create = require(PATH..".create")
local collisions = require(PATH..".collisions")
local operations = require(PATH..".operations")


-- Get value --

local function getSignedArea(polygon)
    local sum = 0
    local len = #polygon
    local x1 = polygon[len-1]
    local y1 = polygon[len]
    for i = 1, len do
      local x2, y2 = polygon[i], polygon[i+1]
      sum = sum + (x1+x2)*(y1-y2)
      x1, y1 = x2, y2
    end
    return sum
end

local function getArea(polygon)
    local sum = getSignedArea(polygon)
    return math.abs(sum/2)
end

local function getPerimeter(vertices)
    local sum = 0
    for i = 1, #vertices, 2 do
        local x1, y1, x2, y2
        if i == #vertices - 1 then
            x1, y1 = vertices[i], vertices[i+1]
            x2, y2 = vertices[1], vertices[2]
        else
            x1, y1 = vertices[i], vertices[i+1]
            x2, y2 = vertices[i+2], vertices[i+3]
        end
        sum = sum + math.sqrt((x2-x1)^2+(y2-y1)^2)
    end
    return sum
end

local function getCenter(polygon)
    local x, y = 0, 0
    for i = 1, #polygon, 2 do
        x = x + polygon[i]
        y = y + polygon[i+1]
    end
    return x/(#polygon/2), y/(#polygon/2)
end

local function getCentroid(polygon)
    local area = 0
    local centroid_x, centroid_y = 0, 0
    for i = 1, #polygon, 2 do
        local j = (i + 2 - 1) % #polygon + 1
        local x1, y1 = polygon[i], polygon[i + 1]
        local x2, y2 = polygon[j], polygon[j + 1]
        local cross_product = x1 * y2 - x2 * y1
        area = area + cross_product
        centroid_x = centroid_x + (x1 + x2) * cross_product
        centroid_y = centroid_y + (y1 + y2) * cross_product
    end
    area = area / 2
    centroid_x = centroid_x / (6 * area)
    centroid_y = centroid_y / (6 * area)
    return centroid_x, centroid_y
end

local function getClosestVertice(x,y,polygon)
    local min_dist = math.huge
    local nx, ny, nix, niy
    local sqrt = math.sqrt
    for i = 1, #polygon-1, 2 do
        local px = polygon[i]
        local py = polygon[i+1]
        local dist = sqrt((x-px)^2+(y-py)^2)
        if dist < min_dist then
            min_dist = dist
            nx, ny = px, py
            nix, niy = i, i+1
        end
    end
    return nx,ny,nix,niy
end

local function getBoundingBox(polygon)
    local xMin, xMax = math.huge, -math.huge
    local yMin, yMax = math.huge, -math.huge
    for i = 1, #polygon-1, 2 do
        xMin = polygon[i] < xMin and polygon[i] or xMin
        xMax = polygon[i] > xMax and polygon[i] or xMax
        yMin = polygon[i+1] < yMin and polygon[i+1] or yMin
        yMax = polygon[i+1] > yMax and polygon[i+1] or yMax
    end
    local width = xMax - xMin
    local height = yMax - yMin
    return xMin, yMin, xMax, yMax, width, height
end

local function getDistanceBetweenPolys(polygon1, polygon2, fromCenter)
    if fromCenter then
        local cx1, cy1, cx2, cy2
        if fromCenter == "centroid" then
            cx1, cy1 = getCentroid(polygon1)
            cx2, cy2 = getCentroid(polygon2)
        else
            cx1, cy1 = getCenter(polygon1)
            cx2, cy2 = getCenter(polygon2)
        end
        return math.sqrt((cx1-cx2)^2+(cy1-cy2)^2)
    else
        local min_dist = math.huge
        for i = 1, #polygon1-3, 2 do
            for j = i+2, #polygon2-1, 2 do
                local x1, y1 = polygon1[i], polygon1[i+1]
                local x2, y2 = polygon2[j], polygon2[j+1]
                local distance = math.sqrt((x1-x2)^2+(y1-y2)^2)
                if distance < min_dist then
                    min_dist = distance
                end
            end
        end
        return min_dist
    end
end


-- Set value --

local function setReverse(polygon)
    local n = #polygon
    for i = 1, n/2 do
      local i2 = n-i+2*(i + 1)%2
      polygon[i] = polygon[i2]
      polygon[i2] = polygon[i]
    end
end

local function setTransform(polygon, dx, dy, r, sx, sy)
    local vertices = #polygon/2
    local cosR = math.cos(r)
    local sinR = math.sin(r)
    for i = 1, vertices do
        local x, y = polygon[2*i-1], polygon[2*i]
        polygon[2*i-1] = (x*cosR-y*sinR)*sx+dx
        polygon[2*i] = (x*sinR+y*cosR)*sy+dy
    end
    return polygon
end

local function setTranslation(polygon,dx,dy)
    for i = 1, #polygon, 2 do
        polygon[i] = polygon[i]+dx
        polygon[i+1] = polygon[i+1]+dy
    end
end

local function setPosition(polygon,x,y,type)
    type = type or "center"
    local cx, cy
    if type == "center" then
        cx, cy = getCenter(polygon)
    elseif type == "centroid" then
        cx, cy = getCentroid(polygon)
    end
    local dx, dy = x - cx, y - cy
    setTranslation(polygon, dx, dy)
end

local function setRotation(polygon,r,from)
    from = from or "center"
    local cx, cy
    if "center" then
        cx, cy = getCenter(polygon)
    elseif "centroid" then
        cx, cy = getCentroid(polygon)
    end
    local vertices = #polygon / 2
    for i = 1, vertices do
        local x, y = polygon[2*i-1]-cx, polygon[2*i]-cy
        polygon[2*i-1], polygon[2*i] = cx+x*math.cos(r)-y*math.sin(r), cy+x*math.sin(r)+y*math.cos(r)
    end
end

local function setScale(polygon,sx,sy)
    sy = sy or sx
    local cx, cy = getCenter(polygon)
    local vertices = #polygon/2
    for i = 1, vertices do
        local x, y = polygon[2*i-1]-cx, polygon[2*i]-cy
        polygon[2*i-1], polygon[2*i] = cx+x*sx, cy+y*sy
    end
end


-- Is something --

local function isCCW(polygon)
    return getSignedArea(polygon) > 0
end

local function isConvex(polygon)
    local ccw = isCCW(polygon)
    local n = #polygon
    local ax, ay = polygon[n-3], polygon[n-2]
    local bx, by = polygon[n-1], polygon[n]
    for i = n - 1, 1, -2 do
      local cx, cy = polygon[i], polygon[i+1]
      local s = (cx-ax)*(by-ay)-(cy-ay)*(bx-ax)
      s = (ccw) and -s or s
      if s > 0 then return false end
      ax, ay = bx, by
      bx, by = cx, cy
    end
    return true
end

local function isSimple(polygon)
    local n = #polygon
    local finish = n-3
    local ax, ay = polygon[n-1], polygon[n]
    for i = 1, n, 2 do
        local bx, by = polygon[i], polygon[i+1]
        local cx, cy = polygon[i+2], polygon[i+3]
        for j = i + 4, finish, 2 do
            local dx, dy = polygon[j], polygon[j+1]
            local dx1, dy1 = bx - ax, by - ay
            local dx2, dy2 = dx - cx, dy - cy
            local dx3, dy3 = ax - cx, ay - cy
            local q = dx1*dy2 - dy1*dx2
            if q == 0 then
                return false
            end
            local t1 = (dx2*dy3 - dy2*dx3)/q
            if t1 < 0 or t1 > 1 then
                return false
            end
            local t2 = (dx1*dy3 - dy1*dx3)/q
            if t2 < 0 or t2 > 1 then
                return false
            end
            cx, cy = dx, dy
        end
        ax, ay = bx, by
        finish = n
    end
    return true
end


-- Return module --

return {

    getSignedArea = getSignedArea;
    getArea = getArea;
    getPerimeter = getPerimeter;
    getCenter = getCenter;
    getCentroid = getCentroid;
    getClosestVertice = getClosestVertice;
    getBoundingBox = getBoundingBox;
    getDistanceBetweenPolys = getDistanceBetweenPolys;

    setReverse = setReverse;
    setTransform = setTransform;
    setTranslation = setTranslation;
    setPosition = setPosition;
    setRotation = setRotation;
    setScale = setScale;

    isCCW = isCCW;
    isConvex = isConvex;
    isSimple = isSimple;

    create = create;
    collisions = collisions;
    operations = operations;

}