local SData = GMethod.loadScript("data.StaticData")
local const = GMethod.loadScript("game.GameLogic.Const")

local BuildGroup = class()

function BuildGroup:ctor(builds, center, gsizes)
    self.builds = builds
    if center then
        self.center = center
        self.gsizes = gsizes
        self.bid = center.bid
        self.level = center.level
        self.bsetting = {menus={"rotate","upgradeRow"}, planMenus={"rotate"}}
    end
end
function BuildGroup:isStatue()
    return false
end

function BuildGroup:moveAndCheck(gix, giy, moving)
    local vstate = self.vstate
    if not vstate then
        return false
    end
    local scene = vstate.scene
    local map = scene.map
    local isOk = true
    local bottomState = 0
    local cvstate = self.center.vstate
    local cgx, cgy = cvstate.gx, cvstate.gy
    if moving then
        for _, build in ipairs(self.builds) do
            local bvstate = build.vstate
            if bvstate then
                local gx, gy = bvstate.gx-cgx+gix, bvstate.gy-cgy+giy
                local ckey = map.getGridKey(gx, gy)
                if ckey==0 then
                    isOk = false
                    break
                end
                local cbuild = map.getGridObj(gx, gy)
                if cbuild and not vstate.gmap[cbuild] then
                    isOk = false
                    break
                end
            end
        end
        bottomState = (isOk and 1) or 2
    end
    vstate.bottomState = bottomState
    for _, build in ipairs(self.builds) do
        local bvstate = build.vstate
        local gx, gy = bvstate.gx-cgx+gix, bvstate.gy-cgy+giy
        build:setBottomState(bottomState, gx, gy)
    end
    return isOk
end

function BuildGroup:moveGrid(gix, giy, z, resetWall)
    local maxXY = 0
    local cvstate = self.center.vstate
    if not cvstate or not self.vstate then
        return
    end
    local cgx, cgy = cvstate.gx, cvstate.gy
    local gview = self.vstate.view
    if z then
        for _, build in ipairs(self.builds) do
            local bvstate = build.vstate
            local gx, gy = bvstate.gx, bvstate.gy
            local xy = gx+gy
            if xy>maxXY then
                maxXY = xy
            end
        end
        gview:getParent():reorderChild(gview, z)
        local dy = ((self.gsizes[1]+self.gsizes[3])==0 and 1) or 0
        for _, build in ipairs(self.builds) do
            local bvstate = build.vstate
            local xy = bvstate.gx+bvstate.gy
            local gx, gy = bvstate.gx-cgx+gix, bvstate.gy-cgy+giy
            bvstate.gx, bvstate.gy = gx, gy 
            build:moveGrid(gx, gy, z+maxXY-xy)
            if resetWall then
                if xy<maxXY then
                    build:setDirsWall(1-dy, dy)
                else
                    build:setDirsWall(0, 0)
                end
            end
        end
    else
        local sx, sy, sn = 0, 0, 0
        for _, build in ipairs(self.builds) do
            local bvstate = build.vstate
            local gx, gy = bvstate.gx-cgx+gix, bvstate.gy-cgy+giy
            bvstate.gx, bvstate.gy = gx, gy
            build:moveGrid(gx, gy)
            sx, sy, sn = sx+gx, sy+gy, sn+1
        end
        local map = cvstate.scene.map
        local px, py = map.convertToPosition(sx/sn, sy/sn)
        gview:getParent():reorderChild(gview, map.maxZ-py-map.gsizeY-1)
    end
    gview:setPosition(self.center.vstate.view:getPosition())
end

function BuildGroup:resetGrid()
    local vstate = self.vstate
    if not vstate then
        return
    end
    local scene = vstate.scene
    if not vstate.moveOk then
        for _, build in ipairs(self.builds) do
            local bvstate = build.vstate
            if not bvstate then
                break
            end
            bvstate.gx, bvstate.gy = bvstate.bgx, bvstate.bgy
        end
        vstate.moveOk = true
    end
    local cvstate = self.center.vstate
    if not cvstate then
        return
    end
    local gix, giy = cvstate.gx, cvstate.gy
    self:moveGrid(gix, giy)
    self:moveAndCheck(gix, giy)
    if cvstate.bgx ~= gix or cvstate.bgy ~= giy or vstate.rotated then
        for _, build in ipairs(self.builds) do
            local bvstate = build.vstate
            build:clearGridUse(bvstate.bgx, bvstate.bgy)
        end
        for _, build in ipairs(self.builds) do
            local bvstate = build.vstate
            build:setGridUse(bvstate.gx, bvstate.gy)
        end
    end
end

function BuildGroup:setFocus(focus)
    local vstate = self.vstate
    if not vstate then
        return
    end
    local scene = vstate.scene
    if focus==vstate.focus then
        return
    end
    vstate.focus = focus
    if focus then
        GameEvent.sendEvent(GameEvent.EventFocus, self)
        local pt, pts = BU.reusePts(self)
        self:resetPtPos()
        BU.showBuildMenu(self)
        BU.showBuildName(self.center)
    else
        GameEvent.sendEvent(GameEvent.EventFocus, nil)
        if vstate.bottomState>0 then
            self:resetGrid()
        end
        BU.recoveryPts(self)
        BU.hideBuildMenu(self)
        BU.recoveryBuildName(self.center)
        self:removeFromScene()
    end
    for _, build in ipairs(self.builds) do
        build:runFocusAnimate(focus)
    end
end

function BuildGroup:cbtCheck(x, y)
    if not self.vstate then
        return false
    end
    for _, build in ipairs(self.builds) do
        if build:cbtCheck(x, y) then
            return true
        end
    end
    return false
end

function BuildGroup:cbtBegin(x, y)
    local vstate = self.vstate
    if not vstate then
        return
    end
    local touchInfo = {}
    local cvstate = self.center.vstate
    touchInfo.bpx = cvstate.cpx
    touchInfo.bpy = cvstate.cpy
    vstate.touchInfo = touchInfo
end

function BuildGroup:cbtMove(ox, oy)
    local vstate = self.vstate
    if not vstate then
        return
    end
    local scene = vstate.scene

    local ti = vstate.touchInfo
    local gsize = 1
    local cvstate = self.center.vstate
    local ogx, ogy = cvstate.gx, cvstate.gy
    local gx, gy = scene.map.convertToGrid(ox + ti.bpx, oy + ti.bpy, gsize)
    gx = math.floor(gx)
    gy = math.floor(gy)
    if gx ~= ogx or gy ~= ogy then
        vstate.moved = true
    
        local isOk = self:moveAndCheck(gx, gy, true)
        vstate.moveOk = isOk
        self:moveGrid(gx, gy, scene.map.maxZ+1)
        music.play("sounds/buildMove.wav")
        BU.hideBuildMenu(self)
    end
    return true
end

function BuildGroup:cbtEnd()
    local vstate = self.vstate
    if not vstate then
        return
    end
    local scene = vstate.scene
    vstate.touchInfo = nil
    if vstate.bottomState==0 then
        self:setFocus(false)
    elseif vstate.moveOk then
        self:resetGrid()
        GameEvent.sendEvent(GameEvent.EventBuildMove, self)
        if not vstate.moved then
            self:setFocus(false)
        end
    end
    vstate.moved = false
end

function BuildGroup:cbtHold(x, y)
end

function BuildGroup:checkRowUpgrade()
    local minLv = 1000
    local builds = self.builds
    for _, build in ipairs(builds) do
        if build.level<minLv then
            minLv = build.level
        end
    end
    if minLv>=self.center.info.maxLv then
        return false
    end
    local bnum = 0
    for _, build in ipairs(builds) do
        if build.level==minLv then
            bnum = bnum+1
        end
    end
    local bdata = SData.getData("bdatas",self.center.bsetting.bdid,minLv+1)
    if bdata and bdata.needLevel<=self.context.buildData:getTownLevel() then
        return true, bnum*bdata.cvalue, minLv
    end
    return false
end

function BuildGroup:resetPtPos()
    local gsizes = self.gsizes
    local vstate = self.vstate
    local scene = vstate.scene
    local pts = vstate.pts
    local map = scene.map
    local w, h = map.gsizeX, map.gsizeY
    display.adapt(pts[1], w*(1+gsizes[2])/2+w*(-gsizes[1]+gsizes[3])/4, -h*(1+gsizes[2])/2+h*(-gsizes[1]+gsizes[3])/4, GConst.Anchor.Center)
    display.adapt(pts[2], w*(1+gsizes[3])/2-w*(-gsizes[2]+gsizes[4])/4, h*(1+gsizes[3])/2+h*(-gsizes[2]+gsizes[4])/4, GConst.Anchor.Center)
    display.adapt(pts[3], -w*(1+gsizes[1])/2-w*(-gsizes[2]+gsizes[4])/4, -h*(1+gsizes[1])/2+h*(-gsizes[2]+gsizes[4])/4, GConst.Anchor.Center)
    display.adapt(pts[4], -w*(1+gsizes[4])/2+w*(-gsizes[1]+gsizes[3])/4, h*(1+gsizes[4])/2+h*(-gsizes[1]+gsizes[3])/4, GConst.Anchor.Center)
end

function BuildGroup:rotateRow()
    local center = self.center
    local cvstate = center.vstate
    if not cvstate then
        return
    end
    local cgx, cgy = cvstate.gx, cvstate.gy
    local builds = self.builds
    for _, build in ipairs(builds) do
        if build~=center then
            local bvstate = build.vstate
            local gx, gy = cgx+(cgy-bvstate.gy), cgy+(bvstate.gx-cgx)
            bvstate.gx, bvstate.gy = gx, gy
        end
    end
    local gsizes = self.gsizes
    table.insert(gsizes, table.remove(gsizes, 1))
    self:resetPtPos()
    self.vstate.moveOk = self:moveAndCheck(cgx, cgy, true)
    self.vstate.rotated = true
    self:moveGrid(cgx, cgy, cvstate.scene.map.maxZ, true)
end

function BuildGroup:upgradeRow(force)
    local canUpgrade, upgradeCost, minLv = self:checkRowUpgrade()
    if canUpgrade then
        local context = self.context
        local cbuilds = context.buildData
        local ctype = const.ResGold
        local max = context:getResMax(ctype)
        if upgradeCost>max then
            local bid = const.GoldStorage
            display.pushNotice(StringManager.getFormatString("noticeStorageFull", {name=BU.getBuildName(bid)}))
            return false
        end
        if not force then
            display.showDialog(AlertDialog.new(3,Localize("titleUpgradeWall"),Localizef("labelUpgradeWall",{num = upgradeCost}),{callback=Handler(self.upgradeRow, self,true)}))
            return false
        end
        if context:getRes(ctype)<upgradeCost then
            display.showDialog(AlertDialog.new({ctype=ctype, cvalue=upgradeCost, callback=Handler(self.upgradeRow, self,true)}))
            return false
        end
        for _, build in ipairs(self.builds) do
            if build.level==minLv then
                build:onRealBeginUpgrade(build:getNextData())
                build:runFocusAnimate(true)
            end
        end
        BU.showBuildMenu(self)
    end
end

function BuildGroup:addMenuButs(buts, item)
    if item=="rotate" then
        table.insert(buts, {key="rotate", callback=self.rotateRow ,cp1=self})
    elseif item=="upgradeRow" then
        local canUpgrade, upgradeCost, minLv = self:checkRowUpgrade()
        if canUpgrade then
            table.insert(buts, {key="upgrade", callback=Handler(self.upgradeRow, self)})
        end
    end
end

function BuildGroup:addToScene(scene, gix, giy)
    local vstate = {scene=scene, bottomState=0}
    self.vstate = vstate
    if gix then
        local map = scene.map
        local view = ui.node({map.gsizeX, map.gsizeY})
        local px, py = map.convertToPosition(gix, giy)
        display.adapt(view, px, py, GConst.Anchor.Bottom)
        scene.objs:addChild(view, map.maxZ)
        vstate.view = view
        local gmap = GMethod.getWeakTable("k")
        for _, build in pairs(self.builds) do
            gmap[build] = 1
        end
        vstate.gmap = gmap
        self:setFocus(true)
        vstate.moveOk = self:moveAndCheck(gix, giy, true)
        self:moveGrid(gix, giy, map.maxZ)
        RegLife(view, Handler(self.onLifeCycle))
    end
end

function BuildGroup:onLifeCycle(event)
    if event == "exit" or event == "cleanup" then
        self.vstate = nil
    end
end

function BuildGroup:removeFromScene()
    local vstate = self.vstate
    if vstate and vstate.view then
        vstate.view:removeFromParent(true)
        vstate.view = nil
    end
    self.vstate = nil
end

return BuildGroup
