local Wall = {}
local BuildGroup = GMethod.loadScript("game.Build.Group")

function Wall:checkRowMode()
    local vstate = self.vstate
    if not vstate or not vstate.bgx or not vstate.scene then
        return false
    end
    local scene = vstate.scene
    local map = scene.map
    local gx, gy = vstate.bgx, vstate.bgy
    for i=1, 4 do
        local ox, oy = 0, 0
        if i%2==1 then
            oy = i-2
        else
            ox = i-3
        end
        if scene.walls[map.getGridKey(gx+ox, gy+oy)] then
            return true
        end
    end
    return false
end

function Wall:selectRow()
    local vstate = self.vstate
    if not vstate or not vstate.bgx or not vstate.scene then
        return false
    end
    local scene = vstate.scene
    local map = scene.map
    local gx, gy = vstate.bgx, vstate.bgy
    local walls = scene.walls
    local wallx = {}
    local wally = {}
    local gsizes = {}
    for i=1, 4 do
        local ox, oy = 0, 0
        local swalls
        if i%2==1 then
            oy = i-2
            swalls = wally
        else
            ox = i-3
            swalls = wallx
        end
        gsizes[i] = 0
        for j=1, 40 do
            local wall = walls[map.getGridKey(gx+ox*j, gy+oy*j)]
            if wall then
                table.insert(swalls, wall)
                gsizes[i] = j
            else
                break
            end
        end
    end
    local swalls = wallx
    local dirx = true
    if #wally>#wallx then
        swalls = wally
        dirx = false
    end
    table.insert(swalls, self)
    if dirx then
        gsizes[1], gsizes[3] = 0, 0
    else
        gsizes[2], gsizes[4] = 0, 0
    end
    local buildGroup = BuildGroup.new(swalls, self, gsizes)
    buildGroup.context = self.context
    buildGroup:addToScene(scene, gx, gy)
end

function Wall:addMenuButs(buts, item)
    if item=="row" then
        if self:checkRowMode() then
            table.insert(buts,{key="row",callback=self.selectRow, cp1=self})
        end
    end
end

function Wall:resetWallView(vstate)
    local level = vstate.level
    if level>self.vconfig.maxLv then
        level = self.vconfig.maxLv
    end
    local wallIndex = 1
    if vstate.dirWall then
        wallIndex = 1 + vstate.dirWall[1] + vstate.dirWall[2]*2
    end
    local frame = ui.reuseFrame("wall" .. level .. "_" .. wallIndex .. ".png")
    if frame then
        vstate.build:setSpriteFrame(frame)
    end
    if level>=15 and level<=17 and vstate.bviews[1] then
        if wallIndex==1 then
            vstate.bviews[1]:setVisible(false)
            vstate.bviews[2]:setVisible(false)
        elseif wallIndex==2 then
            vstate.bviews[1]:setVisible(true)
            vstate.bviews[2]:setVisible(false)
        elseif wallIndex==3 then
            vstate.bviews[1]:setVisible(false)
            vstate.bviews[2]:setVisible(true)
        elseif wallIndex==4 then
            vstate.bviews[1]:setVisible(true)
            vstate.bviews[2]:setVisible(true)
        end
    end
end

function Wall:onReloadView()
    self:resetWallView(self.vstate)
    return
end

function Wall:setDirWall(dir, value)
    local vstate = self.vstate
    if not vstate then return end
    vstate.dirWall[dir] = value
    self:resetWallView(vstate)
end

function Wall:setDirsWall(d1, d2)
    local vstate = self.vstate
    vstate.dirWall[1] = d1
    vstate.dirWall[2] = d2
    self:resetWallView(vstate)
end

function Wall:onGridSeted(ngx, ngy)
    local vstate = self.vstate
    local scene = vstate.scene
    local map = scene.map
    vstate.dirWall = {0, 0}
    scene.walls[map.getGridKey(ngx, ngy)] = self
    if scene.walls[map.getGridKey(ngx+1, ngy)] then
        vstate.dirWall[2] = 1
    end
    if scene.walls[map.getGridKey(ngx, ngy+1)] then
        vstate.dirWall[1] = 1
    end
    self:resetWallView(vstate)
    local lw = scene.walls[map.getGridKey(ngx, ngy-1)]
    if lw then
        lw:setDirWall(1, 1)
    end
    local rw = scene.walls[map.getGridKey(ngx-1, ngy)]
    if rw then
        rw:setDirWall(2, 1)
    end
end

function Wall:onGridCleared(bgx, bgy)
    local vstate = self.vstate
    local scene = vstate.scene
    local map = scene.map
    scene.walls[map.getGridKey(bgx, bgy)] = nil
    local lw = scene.walls[map.getGridKey(bgx, bgy-1)]
    if lw then
        lw:setDirWall(1, 0)
    end
    local rw = scene.walls[map.getGridKey(bgx-1, bgy)]
    if rw then
        rw:setDirWall(2, 0)
    end
end

return Wall
