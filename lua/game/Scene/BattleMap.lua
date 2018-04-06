local BattleMap = class()

local function squeeze(value, min, max)
    if min and value<min then
        return min
    elseif max and value>max then
        return max
    else
        return value
    end
end

function BattleMap:ctor(size)
    self.searchCache = {}
    self.battlerAll = {}
    self.battler = {}  --所有的战斗者 建筑和英雄
    self.build = {}     --建筑
    self.hero = {}     --英雄
    self.mer = {}       --士兵
    self.diedHero = {}  --死亡的英雄
    self.diedMer = {}    --死亡的佣兵
    self._btaid = 0
    self._btid = 0
    self._bid = 0
    self._hid = 0
    self._mid = 0
    self._bfid1 = 0
    self._bfid2 = 0
    self._dmid = 0
    self._dhid = 0

    self.favBuilds = {[1]={}, [2]={}}
    self.noUseWalls = {}
    self.useWalls = {}
    self.mapGrid = nil
    self.size = size
    --最外延多一圈，用于寻路时允许从外延绕过去，因此，astar搜索时下标不是1至size，而是0至size+1
    self.astarSize = size+2
    self.directions = {{-1,-1,-self.astarSize-1,14}, {0,-1,-self.astarSize,10},{1,-1,-self.astarSize+1,14},{1,0,1,10},{1,1,self.astarSize+1,14},{0,1,self.astarSize,10},{-1,1,self.astarSize-1,14},{-1,0,-1,10},{-1,-1,-self.astarSize-1,14}, {0,-1,-self.astarSize,10},{1,-1,-self.astarSize+1,14},{1,0,1,10},{1,1,self.astarSize+1,14},{0,1,self.astarSize,10},{-1,1,self.astarSize-1,14},{-1,0,-1,10}}
    --懒得求余运算，直接让数组长一倍
    self.searchId = 0
    local searchCells = {}
    --local reuseCells = {}
    local closeSet = {}
    local max = self.astarSize * self.astarSize
    for i=1, max do
        --ID,W,G,H,F,parent,[edge]
        searchCells[i] ={0,0,0,0,0,0}
        closeSet[i] = 0
        --reuseCells[i] = {{0},{0},{0}}
    end
    searchCells[self:getAstarKey(0, 0)][7]  = {4,6}
    searchCells[self:getAstarKey(size+1, 0)][7] = {6,8}
    searchCells[self:getAstarKey(size+1, size+1)][7] = {8,10}
    searchCells[self:getAstarKey(0, size+1)][7] = {2,4}
    for i=1, size do
        searchCells[self:getAstarKey(0, i)][7] = {2,6}
        searchCells[self:getAstarKey(i, 0)][7] = {4,8}
        searchCells[self:getAstarKey(size+1, i)][7] = {6,10}
        searchCells[self:getAstarKey(i, size+1)][7] = {8,12}
    end
    self.searchCells = searchCells
    --self.reuseCells = reuseCells
    --self.reuseInfos = {}
    self.closeSet = closeSet
    self.searchViewInfo = {0,0,0}
end

function BattleMap:getAstarKey(x, y)
    local key=x+y*self.astarSize+1
    if key<1 then
        key=1
    elseif key>self.astarSize*self.astarSize then
        key=self.astarSize*self.astarSize
    end
    return key
end

function BattleMap:getAstarXY(key)
    local x=(key-1)%self.astarSize
    return x, (key-1-x)/self.astarSize
end

function BattleMap:clear()
    self:removeAllObj(self.battlerAll, "_btaid")
    self:removeAllObj(self.battler, "_btid")
    self:removeAllObj(self.build, "_bid")
    self:removeAllObj(self.hero, "_hid")
    self:removeAllObj(self.mer, "_mid")
    self:removeAllObj(self.favBuilds[1], "_bfid1")
    self:removeAllObj(self.favBuilds[2], "_bfid2")
    self:removeAllObj(self.diedMer, "_dmid")
    self:removeAllObj(self.diedHero, "_dhid")

    for k, _ in pairs(self) do
        self[k] = nil
    end
end

function BattleMap:init(mapGrid)
    self.searchId = self.searchId+1
    self.loopLimit = 0
    self.searchCache = {}
    self.battler = {}
    self.build = {}     --建筑
    self.hero = {}     --英雄
    self.mer = {}       --士兵
    self._btaid = 0
    self._btid = 0
    self._bid = 0
    self._hid = 0
    self._mid = 0
    self._bfid1 = 0
    self._bfid2 = 0
    self._dmid = 0
    self._dhid = 0
    self.favBuilds = {[1]={},[2]={}}
    self.noUseWalls = {}
    self.useWalls = {}
    self.types = {[0]=0,[1]=0,[2]=0,[3]=0,[4]=0,[5]=0}
    self.mapGrid = mapGrid
    --self.tempWalls = {{}, {}}
    --self.tempWallsNum = {{}, {}}
    self.allWalls = {}
    local max = self.astarSize * self.astarSize
    local searchCells = self.searchCells
    local reuseCells = {}
    for i=1, max do
        searchCells[i][2] = 0
        reuseCells[i] = {{0},{0},{0}}
    end
    self.reuseCells = reuseCells
    self.reuseInfos = {}
end

function BattleMap:hasType(fav)
    return self.types[fav]>0
end

function BattleMap:getFavBuilds(fav)
    if fav>0 then
        return self.favBuilds[fav]
    else
        return self.battler
    end
end

function BattleMap:getWalls()
    if #(self.useWalls)==0 then
        return self.noUseWalls
    else
        return self.useWalls
    end
end

function BattleMap:getAllBuilds()
    return self.battler
end

function BattleMap:addObj(tb, item, key)
    if not item[key] then
        -- if self[key] ~= #tb then
        --     print("???add", key, self[key], #tb)
        --     print(debug.traceback())
        --     return 
        -- end
        self[key] = self[key] + 1
        tb[self[key]] = item
        item[key] = self[key]
    end
end

function BattleMap:removeObj(tb, item, key)
    local id = item[key]
    if id then
        item[key] = nil
        -- if id > self[key] or self[key] ~= #tb then
        --     print("???", key, id, self[key], #tb)
        --     print(debug.traceback())
        --     return 
        -- end
        if id ~= self[key] then
            tb[id] = tb[self[key]]
            tb[id][key] = id
        end
        tb[self[key]] = nil
        self[key] = self[key] - 1
    end
end

function BattleMap:removeAllObj(tb, key)
    local m = self[key]
    for i = m, 1, -1 do
        tb[i][key] = nil
        tb[i] = nil
    end
    self[key] = nil
end

--should only be call when init the map
function BattleMap:addBattler(battler)
    if battler.avater then
        self:addObj(self.battler, battler, "_btid")
        if battler.sid<1000 then
            self:addObj(self.mer, battler, "_mid")
        elseif battler.sid>1000 then
            self:addObj(self.hero, battler, "_hid")
        end
    else
        local buildData = battler.data
        local bid = battler.bid
        if not battler.vstate then
            return
        end
        local bgx, bgy = battler.vstate.bgx, battler.vstate.bgy
        local gridSize = battler.vstate.gsize
        local edge = (battler.vstate.edge or 5)/10
        
        battler.battleViewInfo = {bgx+gridSize/2, bgy+gridSize/2, gridSize/2-edge, battler.vstate.view:getPositionX(), battler.vstate.view:getPositionY()+battler.vstate.view:getContentSize().height/2}
        if not buildData.hp or buildData.hp==0 or battler.btt==2 then return end
        if bid==50 then
            local key = self:getAstarKey(bgx, bgy)
            self.allWalls[key] = battler
            self.searchCells[key][2] = 200
            self.types[5] = self.types[5]+1
        else
            local fav = battler.info.btype
            if fav>=1 and fav<=2 then
                self.types[fav] = self.types[fav]+1
                if self.favBuilds[fav] then
                    self:addObj(self.favBuilds[fav], battler, "_bfid" .. fav)
                    battler.favSearch = fav
                end
            end
            if fav<4 then
                self.types[0] = self.types[0] + 1
                self:addObj(self.battler, battler, "_btid")
                self:addObj(self.build, battler, "_bid")
            end
        end
    end
    self:addObj(self.battlerAll, battler, "_btaid")
    return true
end

--跳跃城墙加权重
function BattleMap:addWallWeight(build,gx,gy)
    if build.bid and build.bid==50 then
        local gx, gy = gx or build.vstate.gx, gy or build.vstate.gy
        local key = self:getAstarKey(gx, gy)
        self.searchCells[key][2] = 80
    end
end

function BattleMap:removeWallWeight(build,gx,gy)
    if build.bid and build.bid==50 then
        local gx, gy = gx or build.vstate.gx, gy or build.vstate.gy
        local key = self:getAstarKey(gx, gy)
        self.searchCells[key][2] = 0
    end
end



--生成所有有关数据
function BattleMap:makeAllGrid()
end

function BattleMap:removeBattler(battler)
    self:removeObj(self.battlerAll, battler, "_btaid")
    self:removeObj(self.battler, battler, "_btid")
    if battler.avater then
        if battler.sid<1000 then
            self:removeObj(self.mer, battler, "_mid")
            if not battler.params.isZhaoHuan and battler.M.cantRebirth<=0 then
                self:addObj(self.diedMer, battler, "_dmid")
            end
        else
            self:removeObj(self.hero, battler, "_hid")
            --把死亡的英雄记下
            if not battler.params.isZhaoHuan and battler.M.cantRebirth<=0 then
                self:addObj(self.diedHero, battler, "_dhid")
            end
        end
    else
        self:destroyBuild(battler)
    end
end

function BattleMap:destroyBuild(build)
    if build.btt==2 then
        return
    end
    local bid = build.bid
    local fav = build.info.btype or 0
    if bid==50 then
        self.types[5] = self.types[5]-1
        local bgx, bgy = build.vstate.bgx, build.vstate.bgy
        local key = self:getAstarKey(bgx, bgy)
        self.allWalls[key] = nil
        self.searchCells[key][2] = 0
    else
        if fav>=1 and fav<=2 then
            self.types[fav] = self.types[fav]-1
            if self.favBuilds[fav] then
                self:removeObj(self.favBuilds[fav], build, "_bfid" .. fav)
            end
        end
        if fav<4 then
            self.types[0] = self.types[0] - 1
            self:removeObj(self.battler, build, "_btid")
            self:removeObj(self.build, build, "_bid")
        end
    end
end

function BattleMap:getCachedBuild(gx, gy, fav)
    local temp = self.searchCache[gx]
    if temp then
        if temp[gy] then
            return temp[gy][fav]
        else
            temp[gy] = {}
            return nil
        end
    else
        self.searchCache[gx] = {[gy]={}}
        return nil
    end
end

function BattleMap:setCachedBuild(gx, gy, fav, item)
    local temp = self.searchCache[gx]
    if temp then
        if temp[gy] then
            temp[gy][fav] = item
        else
            temp[gy] = {[fav]=item}
        end
    else
        self.searchCache[gx] = {[gy]={[fav]=item}}
    end
end

function BattleMap:searchPathUsingAstarSample(sgx,sgy,tgx,tgy)
    self.searchId = self.searchId+1
    local sgix, sgiy = math.floor(sgx), math.floor(sgy)
    local startX, startY = squeeze(sgix,0,self.astarSize-1),squeeze(sgiy,0,self.astarSize-1)
    local tgx,tgy = math.floor(tgx),math.floor(tgy)
    local key = self:getAstarKey(startX, startY)
    local searchCells = self.searchCells
    local cell = searchCells[key]
    cell[3] = 0
    local openList = {}
    local closeSet = self.closeSet
    local searchViewInfo = {tgx,tgy,0,tgx*10-5,tgy*10-5}

    local function resetCell(parentGridKey, cell, newGscore, currentGridKey)
        cell[6] = parentGridKey
        cell[3] = newGscore
        cell[5] = cell[3]+cell[4]
        heapq.heappushArray(openList, {cell[5], currentGridKey})
    end

    local function checkAstarNeibor(x,y)
        local gridKey = self:getAstarKey(x, y)
        local s,e = 1,8
        local pcell = searchCells[gridKey]
        local edgeInfo = pcell[7]
        if edgeInfo then
            s,e = edgeInfo[1], edgeInfo[2]
        end
        for i=s, e do
            local direction = self.directions[i]
            local nx, ny = x+direction[1], y+direction[2]
            local nkey = gridKey+direction[3]
            if closeSet[nkey]<self.searchId then
                local cell = self.searchCells[nkey]
                local ng = direction[4]+cell[2]+pcell[3]

                if cell[1]<self.searchId then
                    cell[1] = self.searchId
                    cell[4] = math.abs(searchViewInfo[4]-nx*10)+math.abs(searchViewInfo[5]-ny*10)
                    resetCell(gridKey, cell, ng, nkey)
                else
                    --说明已经加入到openList里，需要更新
                    if ng<cell[3] then
                        resetCell(gridKey, cell, ng, nkey)
                    end
                end
            end
        end
        closeSet[gridKey] = self.searchId
    end
    checkAstarNeibor(startX, startY)
    local lastPoint = self:getAstarKey(tgx,tgy)
    while openList[1] ~= nil do
        local item = heapq.heappopArray(openList)
        if closeSet[item[2]]<self.searchId then
            local gx,gy = self:getAstarXY(item[2])
            if item[2] == lastPoint then
                break
            else
                checkAstarNeibor(gx, gy)
            end
        end
    end

    local gx,gy = self:getAstarXY(lastPoint)
    local path = {{gx,gy}}
    local temp,back = 0
    while true do
        back = lastPoint
        lastPoint = searchCells[lastPoint][6]
        if lastPoint == 0 then
            break
        end
        if temp~=lastPoint-back then
            if temp~=0 then
                gx, gy = self:getAstarXY(back)
                table.insert(path,{gx+0.5, gy+0.5})
            end
            temp = lastPoint-back
        end
        if lastPoint==key then
            break
        end
    end
    return path
end

function BattleMap:searchPathUsingAstar(soldier, sgx, sgy, target)
    if false and self.loopLimit > 200 then
        return target, nil, nil
    end
    self.searchId = self.searchId+1
    local battleViewInfo = target.battleViewInfo
    if battleViewInfo then
        local ex, ey = math.floor(battleViewInfo[1]*10-5), math.floor(battleViewInfo[2]*10-5)
        self.searchViewInfo = {battleViewInfo[1], battleViewInfo[2], battleViewInfo[3], ex, ey}
    else
        self.searchViewInfo = self:getSoldierBattleViewInfo(target)
    end
    local reuseType = soldier.favSearch+1
    local sgix, sgiy = math.floor(sgx), math.floor(sgy)
    local startX, startY = squeeze(sgix,0,self.astarSize-1),squeeze(sgiy,0,self.astarSize-1)
    local startInOutside = (startX~=sgix or startY~=sgiy)
    local key = self:getAstarKey(startX,startY)
    local searchCells = self.searchCells
    --判断一下搜索点是否正在城墙内；在移动时确实可能从边线上越过城墙。
    if searchCells[key][2]>0 then
        local rect = {sgx-sgix, sgy-sgiy, 1-sgx+sgix, 1-sgy+sgiy}
        local directions = {{-1,0},{0,-1},{1,0},{0,1}}
        local newKey,min = 0,1
        for i=1, 4 do
            local tempKey = self:getAstarKey(startX+directions[i][1], startY+directions[i][2])
            if rect[i]<min and searchCells[tempKey][2]==0 then
                newKey = tempKey
                min = rect[i]
            end
        end
        if newKey~=0 then
            key = newKey
            startX, startY = self:getAstarXY(key)
        else
            return target, self.allWalls[key], {}
        end
    end
    local realTarget, attackTarget, path = self:checkReusePath(key,reuseType, target)
    if realTarget and path then
        if startInOutside then
            table.insert(path,{startX+0.5, startY+0.5})
        end
        return realTarget, attackTarget, path
    end
    local cell = searchCells[key]
    cell[3] = 0
    local openList = {}
    self.openList = openList
    self:checkAstarNeibor(startX, startY)
    local checkResult = nil
    local lastPoint = 0
    local loopNum = 0
    local reuseCheck = true
    while openList[1]~=nil do
        local item = heapq.heappopArray(openList)
        loopNum = loopNum+1
        if self.closeSet[item[2]]<self.searchId then
            checkResult = self:checkIsResultGrid(item[2], soldier, target)
            if checkResult then
                lastPoint = item[2]
                break
            else
                if reuseCheck then
                    if searchCells[item[2]][2]>0 then
                        reuseCheck=false
                    else
                        realTarget, attackTarget, path = self:checkReusePath(item[2],reuseType,target)
                        if realTarget then
                            if path then
                                lastPoint = item[2]
                                break
                            else
                                reuseCheck = false
                            end
                        end
                    end
                end

                local cx, cy = self:getAstarXY(item[2])
                self:checkAstarNeibor(cx, cy)
            end
        end
    end
    self.loopLimit = self.loopLimit+loopNum
    openList = nil
    self.openList = nil
    if realTarget and path then
        local gx, gy = self:getAstarXY(lastPoint)
        table.insert(path, {gx+0.5, gy+0.5})
        local temp,back = 0
        while true do
            back = lastPoint
            lastPoint = searchCells[lastPoint][6]
            if temp~=lastPoint-back then
                if temp~=0 then
                    gx, gy = self:getAstarXY(back)
                    table.insert(path,{gx+0.5, gy+0.5})
                end
                temp = lastPoint-back
            end
            if lastPoint==key then
                break
            end
        end
        if startInOutside then
            table.insert(path, {startX+0.5, startY+0.5})
        end
        return realTarget, attackTarget, path
    end
    --需要返回搜索结果，搜索到的真实target, 攻击target，路径
    if checkResult then
        local gx, gy = self:getAstarXY(lastPoint)
        path = {{gx+0.5,gy+0.5}}
        --使小兵尽量不重合
        local viewInfo = target.battleViewInfo
        if not viewInfo then
            viewInfo = self:getSoldierBattleViewInfo(target)
        end
        local s = viewInfo[3]/2
        local temp,back = 0
        local reuseCells = self.reuseCells
        local toPoint = lastPoint
        reuseCells[lastPoint][reuseType] = {toPoint, self.searchId, checkResult}
        while true do
            back = lastPoint
            lastPoint = searchCells[lastPoint][6]
            if searchCells[lastPoint][2]>0 and self.allWalls[lastPoint] and lastPoint~=key then
                --说明选中了城墙
                attackTarget = self.allWalls[lastPoint]
                gx, gy = self:getAstarXY(lastPoint)
                path = {{gx+0.5, gy+0.5}}
                temp = 0
                reuseCells[lastPoint][reuseType] = {toPoint, self.searchId, attackTarget}
                toPoint = lastPoint
                searchCells[lastPoint][2] = 60
            else
                if temp~=lastPoint-back then
                    if temp~=0 then
                        gx, gy = self:getAstarXY(back)
                        table.insert(path,{gx+0.5, gy+0.5})
                        toPoint = back
                    end
                    temp = lastPoint-back
                end
                reuseCells[lastPoint][reuseType] = {toPoint, self.searchId}
                if lastPoint==key then
                    break
                end
            end
        end
        if checkResult and attackTarget then
            self.reuseInfos[self.searchId] = {checkResult, attackTarget, self.scene.sceneTime}
        end
        --当是从场外进场时，需要把起始点加入到路径
        if startInOutside then
            table.insert(path, {startX+0.5, startY+0.5})
        end
        return checkResult, attackTarget or checkResult, path
    else
    --事实上不可能出现这种情况
        print("impossible situation because all can move in this map!")
        return target, nil, nil
    end
end

function BattleMap:checkAstarNeibor(x, y)
    local gridKey = self:getAstarKey(x, y)
    local s,e = 1,8
    local pcell = self.searchCells[gridKey]
    local edgeInfo = pcell[7]
    if edgeInfo then
        s,e = edgeInfo[1], edgeInfo[2]
    end
    local closeSet = self.closeSet
    for i=s, e do
        local direction = self.directions[i]
        local nx, ny = x+direction[1], y+direction[2]
        local nkey = gridKey+direction[3]
        if closeSet[nkey]<self.searchId then
            local cell = self.searchCells[nkey]
            local ng = direction[4]+cell[2]+pcell[3]

            if cell[1]<self.searchId then
                cell[1] = self.searchId
                cell[4] = math.abs(self.searchViewInfo[4]-nx*10)+math.abs(self.searchViewInfo[5]-ny*10)
                self:resetCell(gridKey, cell, ng, nkey)
            else
                --说明已经加入到openList里，需要更新
                if ng<cell[3] then
                    self:resetCell(gridKey, cell, ng, nkey)
                end
            end
        end
    end
    closeSet[gridKey] = self.searchId
end

function BattleMap:resetCell(parentGridKey, cell, newGscore, currentGridKey)
    cell[6] = parentGridKey
    cell[3] = newGscore
    cell[5] = cell[3]+cell[4]
    heapq.heappushArray(self.openList, {cell[5], currentGridKey})
end

function BattleMap:getSoldierBattleViewInfo(target)
    if not target.avater then
        return
    end
    local gx,gy = target.avater.gx,target.avater.gy
    return {gx, gy, 1, math.floor(gx*10-5), math.floor(gy*10-5)}
end

function BattleMap:getSoldierBattleViewInfoReal(target)
    local px, py = target.avater.view:getPosition()
    local gx,gy = target.avater.gx,target.avater.gy
    return {gx, gy, 1, px, py}
end

function BattleMap:canMoveWithDirectMove(sgx,sgy,tgx,tgy)
    local dx,dy = math.abs(sgx-tgx),math.abs(sgy-tgy)
    local dis = math.sqrt(dx*dx+dy*dy)
    if tgx<sgx then dx=-dx end
    if tgy<sgy then dy=-dy end
    dx,dy = dx/dis, dy/dis
    local step,gx,gy = 0,0,0
    while true do
        step = step+1
        gx,gy = sgx+step*dx, sgy+step*dy
        local intx, inty = math.floor(gx),math.floor(gy)
        if dis-step<=0 then
            return {{tgx,tgy}}
        end
        if intx>=0 and intx<self.astarSize and inty>=0 and inty<self.astarSize then
            if self.searchCells[self:getAstarKey(intx,inty)][2]>0 then
                return nil
            end
        end
    end
end

function BattleMap:canAttackWithDirectMove(sx, sy, soldier, target)
    local viewInfo = target.battleViewInfo
    if not viewInfo then
        viewInfo = self:getSoldierBattleViewInfo(target)
    end
    local dx, dy = math.abs(sx-viewInfo[1])-viewInfo[3], math.abs(sy-viewInfo[2])-viewInfo[3]
    if dx<0 then dx=0 end
    if dy<0 then dy=0 end
    local dis = math.sqrt(dx*dx+dy*dy)
    if dis<=soldier.avtInfo.range then
        return {}
    else
        local step,gx,gy = 0,0,0
        if viewInfo[1]<sx then dx=-dx end
        if viewInfo[2]<sy then dy=-dy end
        dx, dy = dx/dis, dy/dis
        while true do
            step = step+1
            gx, gy = sx+step*dx, sy+step*dy
            local intx, inty = math.floor(gx), math.floor(gy)
            if intx>=0 and intx<self.astarSize and inty>=0 and inty<self.astarSize then
                if self.searchCells[self:getAstarKey(intx, inty)][2]>0 then
                    return nil
                end
            end
            if dis-step<=soldier.avtInfo.range then
                local s = viewInfo[3]/2
                return {{gx, gy}}
            end
        end
    end
end

function BattleMap:checkIsResultGrid(gridKey, soldier, target)
    if self.searchCells[gridKey][2]==0 then
        local x, y = self:getAstarXY(gridKey)
        local build = nil
        if self.mapGrid then
            build = self.mapGrid.getGridObj(x, y)
        end
        --一旦踩到建筑且满足爱好
        if build and (not build.deleted) and build.avtInfo.nowHp>0 and (soldier.favSearch==0 or soldier.favSearch==build.favSearch) then
            return build
        end
        local viewInfo = self.searchViewInfo
        local dx, dy = math.abs(x+0.5-viewInfo[1])-viewInfo[3], math.abs(y+0.5-viewInfo[2])-viewInfo[3]
        if dx<0 then dx=0 end
        if dy<0 then dy=0 end
        if dx*dx+dy*dy <= soldier.avtInfo.range*soldier.avtInfo.range then
            return target
        end
    end
end

function BattleMap:checkReusePath(gridKey, reuseType, astarTarget)
    local reuseCells = self.reuseCells
    if not reuseCells or not reuseCells[gridKey] then return end
    local cell = reuseCells[gridKey][reuseType]
    if cell and cell[1]~=0 then
        local reuseId = cell[2]
        local info = self.reuseInfos[reuseId]
        if not info or info[3]+5<self.scene.sceneTime or info[1].deleted or info[2].deleted then
            self.reuseInfos[reuseId] = nil
            cell[1] = 0
        elseif astarTarget~=info[4] then
            return astarTarget, nil, nil
        else
            local nextKey = cell[1]
            local path1 = {nextKey}
            while true do
                cell = reuseCells[nextKey][reuseType]
                nextKey = cell[1]
                table.insert(path1, cell[1])
                if cell[3] then
                    break
                end
            end
            local path = {}
            local range = #path1
            for i=1, range do
                local grid = table.remove(path1)
                local x,y = self:getAstarXY(grid)
                table.insert(path,{x+0.5, y+0.5})
            end
            self.loopLimit = self.loopLimit+4
            return info[1], cell[3], path
        end
    end
end
function BattleMap:checkPointInBuild(gridInfo)
    local mapGrid = self.scene.map
    local build = mapGrid.getGridObj(gridInfo[1], gridInfo[2])
    if build and not build.deleted then
        local vstate = build.vstate
        if vstate.isBottom then
            return
        end
        local gsize = vstate.gsize
        local edge = vstate.edge/10
        local bgx, bgy = vstate.bgx, vstate.bgy
        if not bgx then
            bgx, bgy = vstate.gx, vstate.gy
        end
        local xs = {gridInfo[3]-(bgx+edge), bgx+gsize-edge-gridInfo[3]}
        local ys = {gridInfo[4]-(bgy+edge), bgy+gsize-edge-gridInfo[4]}
        if xs[1]>0 and xs[2]>0 and ys[1]>0 and ys[2]>0 then
            local ret = {build,gridInfo[3],gridInfo[4]}
            local mi = {1,1}
            if xs[2]<xs[1] then
                mi[1] = 2
            end
            if ys[2]<ys[1] then
                mi[2] = 2
            end
            if xs[mi[1]] < ys[mi[2]] then
                ret[2] = bgx+gsize/2+(mi[1]-1.5)*(gsize-edge*2+0.2)
            else
                ret[3] = bgy+gsize/2+(mi[2]-1.5)*(gsize-edge*2+0.2)
            end
            return ret
        end
    end
end

function BattleMap:getMoveArroundPosition(build)
    local vstate = build.vstate
    if not vstate then
        return
    end
    local gsize = vstate.gsize
    local edge = vstate.edge
    if vstate.isBottom then
        edge = gsize*5
    end
    local e1, e2 = edge/10, gsize-edge/10
    local gx, gy = vstate.scene.replay.rd:random2()*gsize, vstate.scene.replay.rd:random2()*gsize
    if gx>e1 and gx<e2 and gy>e1 and gy<e2 then
        if vstate.scene.replay.rd:random2() > 0.5 then
            gx = (gx-e1)/(e2-e1)*edge/5
            if gx>e1 then
                gx = gx-e1+e2
            end
        else
            gy = (gy-e1)/(e2-e1)*edge/5
            if gy>e1 then
                gy = gy-e1+e2
            end
        end
    end
    local bgx, bgy = vstate.bgx, vstate.bgy
    if not gx or not gy then
        bgx, bgy = vstate.gx, vstate.gy
    end
    return bgx + gx, bgy + gy
end
-------------得到各种目标
function BattleMap:getCircleTarget(sobj,tT,r)
    local pointT = {}
    local sgx,sgy
    if sobj.avater then
        sgx,sgy = sobj.avater.gx,sobj.avater.gy
    elseif sobj.battleViewInfo then
        sgx,sgy = sobj.battleViewInfo[1],sobj.battleViewInfo[2]
    else
        sgx,sgy = sobj[1],sobj[2]
    end
    for k,v in ipairs(tT) do
        local viewInfo = v.battleViewInfo or self:getSoldierBattleViewInfoReal(v)
        table.insert(pointT,{viewInfo[1],viewInfo[2],viewInfo[3],v})
    end
    local result = Aoe.circlePoint(pointT,{sgx,sgy},r)
    local rs = {}
    for i,v in ipairs(result) do
        rs[i] = v[4]
    end
    return rs
end

return BattleMap
