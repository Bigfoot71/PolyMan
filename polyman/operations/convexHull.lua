-- written by Le Juez Victor - from https://rosettacode.org/wiki/Convex_hull#Lua
-- MIT license

local ccw = function(a,b,c)
    return (b[1]-a[1]) * (c[2]-a[2]) > (b[2]-a[2]) * (c[1]-a[1])
end

return function (poly) -- TODO: Find a way to avoid double conversion

    if #poly == 0 then return {} end

    local pl = {}
    for i = 1, #poly-1, 2 do -- CONVERT
        pl[#pl+1] = {poly[i], poly[i+1]}
    end

    table.sort(pl, function(left,right)
        return left[1] < right[1]
    end)

    local h = {}

    for i,pt in ipairs(pl) do
        while #h >= 2 and not ccw(h[#h-1], h[#h], pt) do
            table.remove(h,#h)
        end
        table.insert(h,pt)
    end

    local t = #h + 1
    for i=#pl, 1, -1 do
        local pt = pl[i]
        while #h >= t and not ccw(h[#h-1], h[#h], pt) do
            table.remove(h,#h)
        end
        table.insert(h,pt)
    end

    table.remove(h,#h)

    pl = {} -- RE-CONVERT
    for _, v in pairs(h) do
        pl[#pl+1] = v[1]
        pl[#pl+1] = v[2]
    end

    return pl

end
