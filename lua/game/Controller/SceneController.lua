--场景通用逻辑控制器
local MainController = {}

local _EventSingle = "single"
local _EventScroll = "scroll"
local _EtypeBegin = "begin"
local _EtypeMove = "move"
local _EtypeEnd = "end"
local _EtypeHold = "hold"

GMethod.loadScript("game.Person.AvtControler")
GMethod.loadScript("game.GameLogic.SwControler")

function MainController:setScene(scene)
    if self.scene==scene then
        return
    end

    self.scene = scene
    self.scroll = scene.scroll
    scene.controller = self
    self.scroll:setScriptHandler(Script.createCObjectHandler(self))
    GameEvent.registerEvent(GameEvent.EventBuyBuild, self, self.onBuyBuild)
    GameEvent.registerEvent({GameEvent.EventDialogOpen, GameEvent.EventDialogClose}, self, self.onDialogEvent)
    GameEvent.registerEvent({GameEvent.EventStartPlan, GameEvent.EventEndPlan, GameEvent.EventPlanMode, GameEvent.EventPlanItem}, self, self.onPlanMode)
    GameEvent.registerEvent({GameEvent.EventBattleBegin}, self, self.onBattleLogic)
    GameEvent.registerEvent(GameEvent.EventFocus, self, self.onFocus)
    GameEvent.registerEvent(GameEvent.EventBuildMove, self, self.onBuildMove)
    GameEvent.registerEvent(GameEvent.EventVisitBegin, self, self.onVisit)
end

function MainController:setMode(inBattle, canControll)
    self.inBattle = inBattle
    self.canControll = canControll
    BU.changeMenuVisible(not inBattle, self.scene, self.focusItem)
    BU.setPlanDelegate(nil)
end

function MainController:onBattleLogic(event, param)
    local loading = GMethod.loadScript("game.Controller.ChangeController")
    display.closeDialog(1)
    if param.showStoryIdx then
        local storyIdx = param.showStoryIdx
        param.showStoryIdx = nil
        display.showDialog(StoryDialog.new({hideMenu=true, context=GameLogic.getUserContext(), storyIdx=storyIdx,
            callback=Handler(GameEvent.sendEvent, GameEvent.EventBattleBegin, param)}), false, true)
    else
        loading:startChange(param)
    end
end

function MainController:onVisit(event,param)
    local loading = GMethod.loadScript("game.Controller.ChangeController")
    display.closeDialog(1)
    loading:startChange(param)
end


function MainController:onBuildMove(event, param)
    local scene = self.scene
    if scene.sceneType ~= "prepare" and not scene.menu.camara then
        local function showB()
            local mapView = scene.mapView
            local batch = mapView.getBatch()
            batch:stopAllActions()
            batch:setVisible(true)
            if scene.sceneType == "battle" then
                batch:setOpacity(64)
            else
                batch:setOpacity(255)
            end
            batch:runAction(ui.action.sequence({{"delay",2.25},{"fadeTo",0.75,0},"hide"}))
        end
        if scene.sceneType == "battle" then
            if scene.battleData.state>0 then
                showB()
            end
        else
            showB()
        end
    end
    --是建筑，发声音
    if param and param.vstate then
        if scene.sceneType == "prepare" then
            local context = GameLogic.getCurrentContext()
            if param.lidx then
                if scene.battleType == const.BattleTypePvc then
                    context.heroData:changeHeroLayoutPos(const.LayoutPvc, param.lidx, param.vstate.bgx, param.vstate.bgy)
                elseif scene.battleType==const.BattleTypePvh then
                    context.forceLayouts:changeHeroLayoutPos(param.lidx, param.vstate.bgx, param.vstate.bgy)
                end
            end
        end
        music.play("sounds/buildSet.wav")
        BU.showBuildMenu(param)
    end
end

function MainController:onPlanMode(event, param)
    if event==GameEvent.EventPlanItem then
        self.toBuildItem = param
    else
        if self.focusItem then
            self.focusItem:setFocus(false)
        end
        self.scroll:setSingleTouchState(0)
        if event==GameEvent.EventStartPlan then
            self.scene.menu:hideAll()
            BU.setPlanDelegate(param)
        elseif event==GameEvent.EventPlanMode then
            self.cmode=param
        else
            self.scene.menu:reloadOperation()
            self.scene.menu.inCount=true
            self.cmode = nil
            self.toBuildItem = nil
            BU.setPlanDelegate(nil)
        end
    end
end

function MainController:onBuyBuild(event, param)
    display.closeDialog()
    local build = Build.new(param.bid, param.blevel or 1)
    local scene = self.scene
    build.context = GameLogic.getUserContext()
    build.group = 1
    build.bstate = {{false}}
    local gx, gy = nil, nil
    local gsize = build.info.size
    if build.bsetting.rowMode then
        build.bstate[1][1] = true
        local otherSetting = param.otherSetting
        if otherSetting then
            local dx, dy = -1, 0
            local gx2, gy2 = otherSetting[1],otherSetting[2]
            build.bstate[1][2] = otherSetting[1]
            build.bstate[1][3] = otherSetting[2]
            if otherSetting[3] then
                local gx1, gy1 = otherSetting[3],otherSetting[4]
                local ox, oy = gx2-gx1, gy2-gy1
                local mx, my = math.abs(ox), math.abs(oy)
                if mx>my then
                    dx, dy = ox/mx, 0
                else
                    dx, dy = 0, oy/my
                end
            end
            dx = dx*gsize
            dy = dy*gsize
            while gx2+dx<1 or gx2+dx>41-gsize or gy2+dy<1 or gy2+dy>41-gsize do
                dx, dy = -dy, dx
            end
            gx, gy = gx2+dx, gy2+dy
        end
    end
    if not gx then
        local winSize = display.winSize
        local centerPoint = scene.ground:convertToNodeSpace(cc.p(winSize[1]/2, winSize[2]/2))
        gx, gy = scene.map.convertToGrid(centerPoint.x, centerPoint.y, gsize)
    end
    gx, gy = math.floor(gx), math.floor(gy)
    local map = scene.map
    if map.checkGridUse(gx, gy, gsize) then
        --这里用来寻找一个空位
        local ngx, ngy = map.findEmptyGrid(gx, gy, gsize)
        if ngx and ngy then
            gx, gy = ngx, ngy
            local px, py = map.convertToPosition(gx+gsize/2, gy+gsize/2)
            scene.scroll:moveAndScaleToCenter(scene.scroll:getScrollNode():getScaleX(), px, py, 0.5)
        end
    end
    build:addToScene(scene, gx, gy)
end

function MainController:onDialogEvent(event, param)
    BU.changeMenuVisible(display.getDialogPri()==0, self.scene, self.focusItem)
end

function MainController:onFocus(event, item)
    if self.focusItem then
        if item and self.focusItem.vstate and self.focusItem.vstate.focus then
            self.focusItem:setFocus(false)
        end
        if self.focusItem==self.touchItem then
            self.touchItem = nil
            self.buildMoved = false
        end
    end
    self.focusItem = item
    if item then
        if item.bid == 2 then
            if not GameLogic.getUserContext().union then
                GameNetwork.request("claninfo",{},function(isSuc,data)
                    if isSuc then
                        if data.linfo and next(data.linfo) then
                            local context = GameLogic.getUserContext()
                            local linfo = data.linfo
                            context.union = {id=linfo[1], job=linfo[2], name=linfo[3], flag=linfo[4], enterTime=linfo[5], cup = linfo[6]}
                            context.unionPets = {skill=data.psk or {1,1,1,1,1,1}, pets=data.pids, curPid=linfo[9], level=linfo[7], exp=linfo[8], pbead=linfo[10] or 0}
                            GameEvent.sendEvent("EventFreshUnionMenu")
                        end
                    end
                end)
            end
        end
        music.play((item.vconfig and item.vconfig.focusSound) or "sounds/buildFocus.wav")
        if item.vstate.isJumpGuide then
            GameLogic.getUserContext().guideHand:removeHand("JumpGoldOre")
            item.vstate.isJumpGuide = nil
        end
    end
    if item and item.bstate then
        self.inBuying = true
    else
        self.inBuying = false
    end
end

function MainController:getFocusItem(item)
    return self.focusItem
end

--处理经营touch事件
function MainController:handlerControlLogic(etype, x, y)
    if etype==_EtypeBegin then
        self.touchItem = nil
        local firstCheck = self.focusItem
        local isTouch = false
        if firstCheck and firstCheck:cbtCheck(x, y) then
            isTouch = true
            self.touchItem = firstCheck
        end
        local map = self.scene.map
        local gridx, gridy = map.convertToGrid(x, y)
        if not isTouch and not self.inBuying then
            gridx = math.floor(gridx)
            gridy = math.floor(gridy)
            for i=0, 3 do
                local gx, gy = gridx-1+(i%2),gridy-1+math.floor(i/2)
                local build = map.getGridObj(gx, gy)
                if build and build~=firstCheck and build:cbtCheck(x, y) and (not build.inHVH or build.canMove) then
                    isTouch = true
                    self.touchItem = build
                    break
                end
            end
        end
        self.buildMoved = false
        if self.touchItem then
            self.touchItem:cbtBegin()
        elseif self.toBuildItem and self.toBuildItem.bsetting.rowMode then
            if not map.checkGridUse(gridx, gridy, 1) then
                self.toBuildItem:addToScene(self.scene, gridx, gridy)
                self.buildMoved = true
                self.tbx = x
                self.tby = y
                GameEvent.sendEvent(GameEvent.EventPlanSeted, self.toBuildItem)
            end
        end
        self.scroll:setSingleTouchState(1)
    elseif etype==_EtypeMove then
        local mscale = self.scene.base:getScaleX()
        if self.buildMoved then
            if self.touchItem then
                self.touchItem:cbtMove(x/mscale, y/mscale)
            elseif self.toBuildItem and self.toBuildItem.bsetting.rowMode then
                local map = self.scene.map
                local gridx, gridy = map.convertToGrid(self.tbx+x/mscale, self.tby+y/mscale)
                gridx = math.floor(gridx)
                gridy = math.floor(gridy)
                if not map.checkGridUse(gridx, gridy, 1) then
                    self.toBuildItem:addToScene(self.scene, gridx, gridy)
                    GameEvent.sendEvent(GameEvent.EventPlanSeted, self.toBuildItem)
                end
            end
        else
            local mov = math.abs(x)+math.abs(y)
            if self.touchItem and self.touchItem:cbtMove(x/mscale, y/mscale) then
                self.buildMoved = true
                mov = 0
            end
            if mov>20 then
                self.touchItem = nil
                self.scroll:setSingleTouchState(0)
            end
        end
    elseif etype==_EtypeEnd then
        if self.touchItem then
            self.touchItem:cbtEnd()
            self.touchItem = nil
        else
            local skip = false
            if self.toBuildItem then
                local map = self.scene.map
                local gridx, gridy = map.convertToGrid(x, y, self.toBuildItem.info.size)
                gridx = math.floor(gridx)
                gridy = math.floor(gridy)
                if not map.checkGridUse(gridx, gridy, self.toBuildItem.info.size) then
                    skip = true
                    self.toBuildItem:addToScene(self.scene, gridx, gridy)
                    self.toBuildItem:setFocus(true)
                    GameEvent.sendEvent(GameEvent.EventPlanSeted, self.toBuildItem)
                end
            end
            if not skip and self.focusItem and not self.inBuying then
                self.focusItem:setFocus(false)
            end
        end
        self.buildMoved = false
    elseif etype==_EtypeHold then
        if self.touchItem then
            self.touchItem:cbtHold(x, y)
        end
    end
end

function MainController:handlerPlanRemoveLogic(etype, x, y)
    if etype==_EtypeBegin or etype==_EtypeEnd then
        self.touchItem = nil
        self.buildMoved = false
        local map = self.scene.map
        local gridx, gridy = map.convertToGrid(x, y)
        gridx = math.floor(gridx)
        gridy = math.floor(gridy)
        local build = map.getGridObj(gridx, gridy)
        if etype == _EtypeBegin then
            self.toCheckMove = false
        end
        if build then
            if build.info.btype ~= 6 then
                build:removeFromScene()
                GameEvent.sendEvent(GameEvent.EventPlanRecovery, build)
                self.tbx = x
                self.tby = y
                self.scroll:setSingleTouchState(1)
            elseif etype==_EtypeBegin then
                display.pushNotice(Localize("noticeObstaclePlan"))
                self.scroll:setSingleTouchState(0)
            end
        elseif self.toBuildItem then
            gridx, gridy = map.convertToGrid(x, y, self.toBuildItem.info.size)
            gridx = math.floor(gridx)
            gridy = math.floor(gridy)
            if etype==_EtypeBegin then
                if map.checkGridUse(gridx, gridy, self.toBuildItem.info.size) then
                    self.scroll:setSingleTouchState(0)
                else
                    self.scroll:setSingleTouchState(1)
                    self.toCheckMove = true
                end
            elseif self.toCheckMove then
                if map.checkGridUse(gridx, gridy, self.toBuildItem.info.size) then
                    self.scroll:setSingleTouchState(0)
                else
                    self.toBuildItem:addToScene(self.scene, gridx, gridy)
                    self.toBuildItem:setFocus(true)
                    GameEvent.sendEvent(GameEvent.EventPlanSeted, self.toBuildItem)
                end
                self.toCheckMove = nil
            end
        else
            self.scroll:setSingleTouchState(0)
        end
    elseif etype==_EtypeMove then
        local mscale = self.scene.base:getScaleX()
        local map = self.scene.map
        if self.toCheckMove then
            local mov = math.abs(x)+math.abs(y)
            if mov>20 then
                self.toCheckMove = nil
                self.scroll:setSingleTouchState(0)
            end
        else
            local gridx, gridy = map.convertToGrid(self.tbx+x/mscale, self.tby+y/mscale)
            gridx = math.floor(gridx)
            gridy = math.floor(gridy)
            local build = map.getGridObj(gridx, gridy)
            if build then
                if build.info.btype ~= 6 then
                    build:removeFromScene()
                    GameEvent.sendEvent(GameEvent.EventPlanRecovery, build)
                end
            end
        end
    end
end

--处理战斗touch事件
function MainController:handlerBattleLogic(etype, x, y)
    if etype==_EtypeBegin then
        self.scroll:setSingleTouchState(1)
    elseif etype==_EtypeMove then
        local mscale = self.scene.base:getScaleX()
        local mov = math.abs(x)+math.abs(y)
        if mov>20 then
            self.scroll:setSingleTouchState(0)
        end
    elseif etype==_EtypeEnd then
        local gx, gy = self.scene.map.convertToGrid(x, y)
        GameEvent.sendEvent(GameEvent.EventBattleTouch, {gx=gx, gy=gy})
    elseif etype==_EtypeHold then
    end
end

function MainController:onEvent(event, ...)
    local param = {...}
    if event==_EventSingle and not GameUI.loadingEffects.inLoading then
        local etype, x, y = param[1], param[2], param[3]
        if self.canControll then
            GameLogic.keepOnline()
            if self.cmode==1 then
                self:handlerPlanRemoveLogic(etype, x, y)
            else
                self:handlerControlLogic(etype, x, y)
            end
        elseif self.inBattle then
            self:handlerBattleLogic(etype, x, y)
        end
    elseif event == "scrollTo" then
        if self.scene.snow then
            local x, y = param[1], param[2]
            local scale = self.scene.scroll:getScrollNode():getScaleX()
            local winSize = display.winSize
            local pos1 = self.scene.snows[1]:convertToNodeSpace(cc.p(winSize[1]/2, winSize[2]/2))
            local x1, y1 = 2048-pos1.x, 1536-pos1.y
            for i=2, 6 do
                self.scene.snows[i]:setPosition(2048+x1*(i*0.6+0.4-1),1536+y1*(i*0.6+0.4-1))
            end
            local scMin = display.getScalePolicy(4096, 3072)[GConst.Scale.Big]
            for i=4, 6 do
                if scale/scMin*(i*0.6+0.4)>=8 then
                    self.scene.snows[i]:setVisible(false)
                else
                    self.scene.snows[i]:setVisible(true)
                end
            end
        end
    end
end

function MainController:updateOperation(diff)
    local context = GameLogic.getUserContext()
    --规划过程中不执行升级逻辑,不包括障碍物
    local stime = GameLogic.getSTime()
    if self.scene.menu and self.scene.menu.inCount then
        if not BU.getPlanDelegate() then
            local wls = context.buildData:getBuildWorkList()
            local builds = self.scene.builds
            for bidx, wl in pairs(wls) do
                local build = builds[bidx]
                if build and build.vstate and build.vstate.bprocess then
                    if wl[4] > stime then
                        build.vstate.bprocess:setLeftValue(wl[4] - GameLogic.getSFloatTime())
                    else
                        build:upgradeOver(stime)
                    end
                end
            end
            local ups = self.scene._updates
            if ups then
                for view, callback in pairs(ups) do
                    if view.inUpdate then
                        callback(diff)
                    else
                        ups[view] = nil
                    end
                end
            end
            wls = context.buildData:getBoostWorkList()
            for bidx, wl in pairs(wls) do
                if wl[4] < stime then
                    local build = builds[bidx]
                    if build and build.vstate and build.boostlist then
                        build:boostOver(stime)
                    end
                end
            end
            context.weaponData:updateProduces(stime)
            if context:getProperty(const.ProObsTime) < stime then
                if context.buildData.obsNum < 40 then
                    local tbid = math.random(200, 212)
                    local build = Build.new(tbid, 1)
                    local tryCount = 0
                    local gx, gy
                    local found = false
                    while tryCount < 100 do
                        tryCount = tryCount + 1
                        gx, gy = math.random(1, 39), math.random(1, 39)
                        if not self.scene.map.checkGridUse(gx, gy, build.info.size) then
                            found = true
                            break
                        end
                    end
                    if not found then
                        build = nil
                    else
                        build.group = 1
                        build.context = context
                        build:addToScene(self.scene, gx, gy)
                    end
                    context.buildData:initObstacle(build)
                    if build then
                        self.scene.builds[build.id] = build
                    end
                else
                    context.buildData:initObstacle(nil, stime)
                end
            end
            -- 每隔1分钟去刷一次吧
            local tick = math.floor(stime / 60)
            if tick ~= self.__obsTick then
                self.__obsTick = tick
                local actObstacle = context.activeData:getBuffInfo(const.ActTypeBuffObstacle)
                if actObstacle[4] > 0 then
                    local obsNum = 0
                    local actReward = context.activeData:getConfigableRwds(actObstacle[1], 1)
                    local actRecord = context.activeData:getActRecord(actObstacle[1], const.ActTypeBuffObstacle)
                    -- 初始化活动时间
                    if actRecord[2] < actObstacle[2] then
                        actRecord[2] = actObstacle[2]
                    end
                    if actRecord[2] < context:getInfoItem(const.InfoRegTime) then
                        actRecord[2] = context:getInfoItem(const.InfoRegTime)
                    end
                    local bids = actReward.bids
                    local bmap = {}
                    for _, bid in ipairs(bids) do
                        bmap[bid] = 1
                    end
                    for _, build in pairs(builds) do
                        if bmap[build.bid] then
                            obsNum = obsNum + 1
                        end
                    end
                    if actRecord[2] < stime then
                        if obsNum < actObstacle[4] then
                            local tbid = bids[math.random(1, #bids)]
                            local build = Build.new(tbid, 1)
                            local tryCount = 0
                            local gx, gy
                            local found = false
                            while tryCount < 100 do
                                tryCount = tryCount + 1
                                gx, gy = math.random(1, 39), math.random(1, 39)
                                if not self.scene.map.checkGridUse(gx, gy, build.info.size) then
                                    found = true
                                    break
                                end
                            end
                            if not found then
                                build = nil
                            else
                                build.group = 1
                                build.context = context
                                build:addToScene(self.scene, gx, gy)
                            end
                            actRecord[2] = actRecord[2] + actReward.interval
                            context.buildData:initObstacle(build, actRecord[2], actObstacle[1])
                            if build then
                                self.scene.builds[build.id] = build
                            end
                        else
                            actRecord[2] = actRecord[2] + math.ceil((stime-actRecord[2])/actReward.interval) * actReward.interval
                            context.buildData:initObstacle(nil, actRecord[2], actObstacle[1])
                        end
                    end
                end
            end
            --其他引导
            local tbidSet = {[15]=2, [25]=5, [35]=4, [45]=6, [65]=8}
            local step = context.guideOr:getStep()
            local tbid = tbidSet[step]
            if tbid then
                for i,v in ipairs(self.scene.builds) do
                    if tbid == v.bid then
                        if v.vstate then
                            if not v.vstate.focus then
                                if not v.vstate.guideOrBuildHand then
                                    if context.guideHand.handArr["guideOrBuildBtn"] then
                                        context.guideHand:removeHand("guideOrBuildBtn")
                                    end
                                    local x = v.vstate.view:getContentSize().width/2
                                    local y = v.vstate.view:getContentSize().height/2
                                    v.vstate.guideOrBuildHand = context.guideHand:showHandSmall(v.vstate.view,x,y,0)
                                end
                            else
                                if v.vstate.guideOrBuildHand then
                                    v.vstate.guideOrBuildHand:removeFromParent(true)
                                    v.vstate.guideOrBuildHand = nil
                                end
                            end
                            self.tbuild = v
                        end
                    end
                end
            else
                if self.tbuild and self.tbuild.vstate and self.tbuild.vstate.guideOrBuildHand then
                    self.tbuild.vstate.guideOrBuildHand:removeFromParent(true)
                    self.tbuild.vstate.guideOrBuildHand = nil
                    self.tbuild = nil
                end
            end
        else
            local wls = context.buildData:getBuildWorkList()
            local builds = self.scene.builds
            for bidx, wl in pairs(wls) do
                local build = builds[bidx]
                if build and build.info.btype==6 and build.vstate and build.vstate.bprocess then
                    if wl[4] > stime then
                        build.vstate.bprocess:setLeftValue(wl[4] - GameLogic.getSFloatTime())
                    else
                        build:upgradeOver(stime)
                    end
                end
            end
        end

    end
end

function MainController:updateBattle(diff)
end

function MainController:updatePrepare(diff)
end

function MainController:updateVisit(diff)
    local context = GameLogic.getCurrentContext()
    local stime = GameLogic.getSTime()
    if self.scene.menu and self.scene.menu.inCount then
        local ups = self.scene._updates
        if ups then
            for view, callback in pairs(ups) do
                if view.inUpdate then
                    callback(diff)
                else
                    ups[view] = nil
                end
            end
        end
    end
end

return MainController
