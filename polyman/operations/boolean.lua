-- written by Le Juez Victor -- from https://github.com/Bigfoot71/2d-polygon-boolean-lua
-- MIT license

local function sign(x)
    if x>0 then return 1
    elseif x<0 then return -1
    else return 0 end
end

local function push(tab,tab2)
    for i = 1, #tab2 do
        tab[#tab+1] = tab2[i]
    end
end

local function unshift(tab,tab2)
    for i,v in ipairs(tab2) do
        table.insert(tab,i,v)
    end
end

local function reverse(tab)
    local len = #tab
    local rt = {}
    for i,v in ipairs(tab) do
        rt[len-i+1] = v
    end
    tab = rt
end

local function copy(tab)
    return {unpack(tab)}
end


local Node = {}
Node.__index = Node
function Node:new(x,y,alpha,intersection)
    return setmetatable({
        x = x, y = y,
        alpha = alpha or 0,
        intersect = intersection,
        next = nil,
        prev = nil,
        nextPoly = nil,
        neighbor = nil,
        entry = nil,
        visited = false,
    }, Node)
end

function Node:nextNonIntersection()
    local a = self
    while a and a.intersect and a.next do
        a = a.next
    end
    return a
end

function Node:last()
    local a = self
    while a.next and a.next ~= self do
        a = a.next
    end
    return a
end

function Node:createLoop()
    local last = self:last()
    last.prev.next = self
    self.prev = last.prev
end

function Node:firstNodeOfInterest()
    local a = self
    if a then
        a = a.next
        while a ~= self and (not a.intersect or (a.intersect and a.visited)) do
            a = a.next
        end
    end
    return a
end

function Node:insertBetween(first, last)
    local a = first
    while a ~= last and a.alpha < self.alpha do
        a = a.next
    end

    self.next = a
    self.prev = a.prev
    if self.prev then
        self.prev.next = self
    end
    self.next.prev = self
end

local function createList(p)

    local len = #p
    local ret, where

    for i = 1, len-1, 2 do

        if not ret then
            where = Node:new(p[i],p[i+1])
            ret = where
        else
            where.next = Node:new(p[i],p[i+1])
            where.next.prev = where
            where = where.next
        end

    end

    return ret

end

local function clean(verts)
    for i = #verts-2, 1, -2 do
        if verts[i-1] == verts[i+1]
        and verts[i] == verts[i+2]
        then
            table.remove(verts, i+1)
            table.remove(verts, i)
        end
    end
    return verts
end


local function lineCross(x1,y1,x2,y2,x3,y3,x4,y4)

    local a1 = y2 - y1
    local b1 = x1 - x2
    local c1 = x2 * y1 - x1 * y2

    local r3 = a1 * x3 + b1 * y3 + c1
    local r4 = a1 * x4 + b1 * y4 + c1

    if r3 ~= 0 and r4 ~= 0 and ((r3 >= 0 and r4 >= 0) or (r3 < 0 and r4 < 0)) then
        return
    end

    local a2 = y4 - y3
    local b2 = x3 - x4
    local c2 = x4 * y3 - x3 * y4

    local r1 = a2 * x1 + b2 * y1 + c2
    local r2 = a2 * x2 + b2 * y2 + c2

    if r1 ~= 0 and r2 ~= 0 and ((r1 >= 0 and r2 >= 0) or (r1 < 0 and r2 < 0)) then
        return
    end

    local denom = a1 * b2 - a2 * b1

    if denom == 0 then
        return true
    end

    --offset = denom < 0 and - denom / 2 or denom / 2

    local x = b1 * c2 - b2 * c1
    local y = a2 * c1 - a1 * c2

    return x~=0 and x/denom or x,
           y~=0 and y/denom or y

end

local function pointContain(x,y,p)

    local oddNodes = false

    local j = #p-1
    for i = 1, #p-1, 2 do

        local px1,py1 = p[i], p[i+1]
        local px2,py2 = p[j], p[j+1]

        if (py1 < y and py2 >= y or py2 < y and py1 >= y) then
            if (px1 + ( y - py1 ) / (py2 - py1) * (px2 - px1) < x) then
                oddNodes = not oddNodes
            end
        end

        j = i

    end

    return oddNodes

end

local function area(p)

    local ax,ay = 0,0
    local bx,by = 0,0

    local area = 0
    local fx,fy = p[1],p[2]

    for i = 3, #p-1, 2 do
        local px,py = p[i-2],p[i-1]
        local cx,cy = p[i],p[i+1]
        ax = fx - cx
        ay = fy - cy
        bx = fx - px
        by = fy - py
        area = area + (ax*by) - (ay*bx)
    end

    return area/2

end

local function distance(x1,y1,x2,y2)
    return math.sqrt((x1-x2)^2+(y1-y2)^2)
end


local function identifyIntersections(subjectList, clipList)

    local auxs = subjectList:last()
    auxs.next = Node:new(subjectList.x, subjectList.y, auxs)
    auxs.next.prev = auxs

    local auxc = clipList:last()
    auxc.next = Node:new(clipList.x, clipList.y, auxc)
    auxc.next.prev = auxc

    local found = false
    local subject = subjectList

    while subject.next do

        local clip = clipList
        if(not subject.intersect) then

            while clip.next do
                if(not clip.intersect) then

                    local subjectNext = subject.next:nextNonIntersection()
                    local clipNext = clip.next:nextNonIntersection()

                    local x1,y1 = subject.x, subject.y
                    local x2,y2 = subjectNext.x, subjectNext.y
                    local x3,y3 = clip.x, clip.y
                    local x4,y4 = clipNext.x, clipNext.y

                    local x, y = lineCross(x1,y1,x2,y2,x3,y3,x4,y4)

                    if x and x ~= true then
                        found = true
                        local intersectionSubject = Node:new(x,y, distance(x1,y1,x,y)/distance(x1,y1,x2,y2), true)
                        local intersectionClip = Node:new(x,y, distance(x3,y3,x,y) / distance(x3,y3,x4,y4), true)
                        intersectionSubject.neighbor = intersectionClip
                        intersectionClip.neighbor = intersectionSubject
                        intersectionSubject:insertBetween(subject, subjectNext)
                        intersectionClip:insertBetween(clip, clipNext)
                    end
                end

                clip = clip.next

            end
        end

        subject = subject.next

    end

    return found

end

local function identifyIntersectionType(subjectList, clipList, clipPoly, subjectPoly, type)

    local se = pointContain(subjectList.x, subjectList.y, clipPoly)
    if (type == 'and') then se = not se end

    local subject = subjectList
    while subject.next do
        if(subject.intersect) then
            subject.entry = se
            se = not se
        end
        subject = subject.next
    end

    local ce = not pointContain(clipList.x, clipList.y, subjectPoly)
    if (type == 'or') then ce = not ce end

    local clip = clipList
    while clip.next do
        if(clip.intersect) then
            clip.entry = ce
            ce = not ce
        end
        clip = clip.next
    end

end


local function collectClipResults(subjectList, clipList, getMostRevelant)

    subjectList:createLoop()
    clipList:createLoop()

    local results, walker = {}, nil

    while true do

        walker = subjectList:firstNodeOfInterest()
        if walker == subjectList then break end

        local result = {}

        while true do

            if walker.visited  then break end

            walker.visited = true
            walker = walker.neighbor

            result[#result+1] = walker.x
            result[#result+1] = walker.y

            local forward = walker.entry

            while true do

                walker.visited = true
                walker = forward and walker.next or walker.prev

                if walker.intersect then
                    --walker.visited = true
                    break
                else
                    result[#result+1] = walker.x
                    result[#result+1] = walker.y
                end

            end

        end

        results[#results+1] = clean(result)

    end

    local res
    if getMostRevelant then

        res = {}

        local index, length = 1, -math.huge

        for i = 1, #results do
            if #results[i] > length then
                index, length = i, #results[i]
            end
        end

        res = results[index]

    end

    return res or results

end


return function (subjectPoly, clipPoly, operation, getMostRevelant)

    local subjectList = createList(subjectPoly)
    local clipList = createList(clipPoly)

    -- Phase 1: Identify and store intersections between the subject
    --					and clip polygons
    local isects = identifyIntersections(subjectList, clipList)

    if isects then
        -- Phase 2: walk the resulting linked list and mark each intersection
        --					as entering or exiting
        identifyIntersectionType(
            subjectList,
            clipList,
            clipPoly,
            subjectPoly,
            operation
        )

        -- Phase 3: collect resulting polygons
        return collectClipResults(subjectList, clipList, getMostRevelant)

    else
        -- No intersections

        local inner = pointContain(subjectPoly[1], subjectPoly[2], clipPoly)
        local outer = pointContain(clipPoly[1], clipPoly[2], subjectPoly)

        local res = {}

        if operation == "or" then

            if (not inner and not outer) then
                push(res, copy(subjectPoly))
                push(res, copy(clipPoly))
            elseif (inner) then
                push(res, copy(clipPoly))
            elseif (outer) then
                push(res, copy(subjectPoly))
            end

        elseif operation == "and" then

            if (inner) then
                push(res, copy(subjectPoly))
            elseif (outer) then
                push(res, copy(clipPoly))
            end

        elseif operation == "not" then

            local sclone = copy(subjectPoly)
            local cclone = copy(clipPoly)

            local sarea = area(sclone)
            local carea = area(cclone)
            if (sign(sarea) == sign(carea)) then
                if (outer) then
                    cclone = reverse(cclone)
                elseif (inner) then
                    sclone = reverse(sclone)
                end
            end

            push(res, sclone)

            if (math.abs(sarea) > math.abs(carea)) then
                push(res, cclone)
            else
                unshift(res, cclone)
            end

        end

        if getMostRevelant then
            return false, res
        end

        return res

    end

end

