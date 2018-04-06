heapq = {}

-- 整数小堆排序
function heapq.heappush(list, item, insertId)
    local i=insertId
    list[i] = item
    local curPos = i 
    local parent = math.floor(i/2)
    while parent > 0 do
        if list[curPos] < list[parent] then
            list[curPos], list[parent] = list[parent], list[curPos]
        else
            break
        end
        curPos, parent = parent, math.floor(parent/2)
    end
end
function heapq.heappop(list, maxId)
    local pop = list[1]
    list[1] = list[maxId]
    list[maxId] = nil
    local curPos = 1
    local left = curPos*2
    local right = curPos*2+1
    while curPos<maxId do
        local state = 0 -- 0parent最小 1左最小 2右最小 
        local min = curPos
        if left < maxId then
            if list[min] > list[left] then
                state = 1
                min = left
            end
        end
        if right < maxId then
            if list[min] > list[right] then
                state = 2
                min = right
            end
        end
        if state == 0 then
            break
        elseif state == 1 then
            list[curPos], list[left] = list[left], list[curPos]
            curPos, left, right = left, left*2, left*2+1
        elseif state == 2 then
            list[curPos], list[right] = list[right], list[curPos]
            curPos, left, right = right, right*2, right*2+1
        end
    end
    return pop
end

-- table小堆排序
function heapq.heappushArray(list, item)
    local i=(#list)+1
    list[i] = item
    local curPos = i 
    local parent = math.floor(i/2)
    while parent > 0 do
        if list[curPos][1] < list[parent][1] then
            list[curPos], list[parent] = list[parent], list[curPos]
        else
            break
        end
        curPos, parent = parent, math.floor(parent/2)
    end
end

function heapq.heappopArray(list)
    local pop = list[1]
    local maxId = #list
    list[1] = list[maxId]
    list[maxId] = nil
    local curPos = 1
    local left = curPos*2
    local right = curPos*2+1
    while curPos<maxId do
        local state = 0 -- 0parent最小 1左最小 2右最小 
        local min = curPos
        if left < maxId then
            if list[min][1] > list[left][1] then
                state = 1
                min = left
            end
        end
        if right < maxId then
            if list[min][1] > list[right][1] then
                state = 2
                min = right
            end
        end
        if state == 0 then
            break
        elseif state == 1 then
            list[curPos], list[left] = list[left], list[curPos]
            curPos, left, right = left, left*2, left*2+1
        elseif state == 2 then
            list[curPos], list[right] = list[right], list[curPos]
            curPos, left, right = right, right*2, right*2+1
        end
    end
    return pop
end