local GameMap = {}
local _baseX, _baseY, _sizeX, _sizeY
local _limitMin, _limitMax, _limitSize
local _grids
local _rhomb = false
local _limitGrids

function GameMap.initGridSetting(baseX, baseY, gsizeX, gsizeY, msizeX, msizeY, isRhomb)
    _baseX = baseX
    _baseY = baseY
    _sizeX = gsizeX
    _sizeY = gsizeY
    _rhomb = isRhomb
    GameMap.gsizeX = gsizeX
    GameMap.gsizeY = gsizeY
    GameMap.msizeX = msizeX
    GameMap.msizeY = msizeY
    GameMap.minZ = 3
    GameMap.maxZ = GameMap.minZ+msizeY
    _limitGrids = nil
end

function GameMap.initGridUse()
    _grids = {}
end

function GameMap.initGridLimit(lmin, lmax)
    _limitMin = lmin
    _limitMax = lmax
    _limitSize = lmax-lmin+1
end

function GameMap.setSpecialLimitGrids(lg)
    _limitGrids = lg
end

local function getGridKey(gridX, gridY)
    if gridX<_limitMin or gridX>_limitMax or gridY<_limitMin or gridY>_limitMax then
        return 0
    end
    return (gridX-_limitMin)*_limitSize+gridY-_limitMin+1
end
GameMap.getGridKey = getGridKey

local function _getGrid(x, y)
    local gl = _grids[x]
    if gl then
        return gl[y]
    end
end

local function _setGrid(x, y, obj)
    local gl = _grids[x]
    if not gl then
        gl = {}
        _grids[x] = gl
    end
    --为了把城墙权重加到battleMap中
    local scene = GMethod.loadScript("game.View.Scene")
    if obj then
        scene.battleMap:addWallWeight(obj,x, y)
    else
        if gl[y] then
            scene.battleMap:removeWallWeight(gl[y],x, y)
        end
    end
    gl[y] = obj
end

function GameMap.getGridObj(x, y)
    if x<_limitMin or y<_limitMin or x>_limitMax or y>_limitMax then
        return nil
    end
    return _getGrid(x, y)
end

function GameMap.checkGridUse(gx, gy, gsize, obj)
    if gx<_limitMin or gy<_limitMin or gx+gsize-1>_limitMax or gy+gsize-1>_limitMax then
        return true
    end
    if _limitGrids and (gx<_limitGrids[1] or gx+gsize-1>_limitGrids[2] or gy<_limitGrids[3] or gy+gsize-1>_limitGrids[4]) then
        return true
    end
    local x, y, gk
    for i=1, gsize do
        for j=1, gsize do
            x, y = gx+i-1, gy+j-1
            gk = _getGrid(x, y)
            if gk and gk~=obj then
                return true
            end
        end
    end
    return false
end

function GameMap.setGridUse(gx, gy, gsize, obj)
    local x,y,gk
    for i=1, gsize do
        for j=1, gsize do
            x, y = gx+i-1, gy+j-1
            _setGrid(x, y, obj)
        end
    end
end

--Ê¹ÓÃ¹ã¶ÈÓÅÏÈÀ´ËÑË÷
function GameMap.findEmptyGrid(gx, gy, gsize)
    if gx<_limitMin then
        gx = _limitMin
    elseif gx>_limitMax then
        gx = _limitMax
    end
    if gy<_limitMin then
        gy = _limitMin
    elseif gy>_limitMax then
        gy = _limitMax
    end
    local offsets = {{0,1},{1,0},{0,-1},{-1,0}}
    local openXs = {gx}
    local openYs = {gy}
    local closeGrids = {}
    local idx = 1
    local ngx, ngy, ngkey, ngx2, ngy2
    while openXs[idx] do
        ngx, ngy = openXs[idx], openYs[idx]
        if not GameMap.checkGridUse(ngx, ngy, gsize) then
            return ngx, ngy
        else
            closeGrids[getGridKey(ngx, ngy)] = 1
            idx = idx+1
            for _, offset in ipairs(offsets) do
                ngx2, ngy2 = ngx+offset[1], ngy+offset[2]
                ngkey = getGridKey(ngx2, ngy2)
                if not closeGrids[ngkey] then
                    closeGrids[ngkey] = 1
                    table.insert(openXs, ngx2)
                    table.insert(openYs, ngy2)
                end
            end
        end
    end
end

function GameMap.clearGridUse(gx, gy, gsize)
    local x,y,gk
    for i=1, gsize do
        for j=1, gsize do
            x, y = gx+i-1, gy+j-1
            _setGrid(x, y, nil)
        end
    end
end

local function convertToGrid(x, y, gsize)
    local fx, fy = (x-_baseX)/_sizeX, (y-_baseY)/_sizeY
    local mathSize = 0
    if gsize then
        mathSize = (gsize-1)/2 
    end
    local rx, ry = fy-fx,fx+fy
    return rx-mathSize, ry-mathSize
end
GameMap.convertToGrid = convertToGrid

-- ×ª»»Ò»¸ö¸ñ×Óµ½ÆäÖÐÏÂµÄ×ø±ê
function GameMap.convertToPosition(gx, gy)
    return (gy-gx)*_sizeX/2 + _baseX, (gy+gx)*_sizeY/2 + _baseY
end

function GameMap.isTouchInGrid(x, y, gx, gy, gsize)
    local fx, fy = convertToGrid(x, y)
    return (fx>=gx and fx<gx+gsize and fy>=gy and fy<gy+gsize)
end

function GameMap.getGridDistance(ox, oy)
    local fx, fy = ox/_sizeX, oy/_sizeY
    local rx, ry = fy-fx, fx+fy
    return math.sqrt(rx*rx + ry*ry)
end

function GameMap.getDistance(rx, ry)
    return math.sqrt(rx*rx + ry*ry)
end

return GameMap
