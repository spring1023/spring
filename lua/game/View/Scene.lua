local SceneZombie = GMethod.loadScript("game.Person.SceneZombie")
local const = GMethod.loadScript("game.GameLogic.Const")

GMethod.loadScript("game.Scene.SceneNormal")
GMethod.loadScript("game.Scene.SceneCity")
GMethod.loadScript("game.Scene.SceneUmland")
GMethod.loadScript("game.Scene.SceneArena")
GMethod.loadScript("game.Scene.ScenePvt")
local MainScene = class()

function MainScene:ctor()
    self.state = "cleanup"
end

function MainScene:show()
    if self.state=="cleanup" then
        local touchNode = ui.touchNode(display.winSize, 0, true)
        self.view = display.addLayer(touchNode, 0, 3)
        local scrollNode = ui.scrollNode(display.winSize, 0, true, true, {scroll=true, inertia=true, clip=true})
        self.state = "enter"
        self.scroll = scrollNode
        display.adapt(scrollNode, 0, 0)
        self.view:addChild(scrollNode)
        self.base = scrollNode:getScrollNode()

        --[[
        此处对场景层做个规划，尽量让相同内容的元素在一起渲染
        从底层到最上层应该分别是：
            场景底部和场景装饰(以及经营时的僵尸）
            建筑底部草坪
            地图格子
            建筑底部阴影
            建筑底部建筑
            人物阴影
            所有建筑和人物角色图
            建筑和人物光影特效
            血条等UI元素
        --]]
        self.grass = ui.node()
        self.base:addChild(self.grass, 2)
        self.map = GMethod.loadScript("game.Scene.GameMap")
        self.mapView = GMethod.loadScript("game.Scene.SquareMapView")
        local mview = self.mapView.initView("images/grid",40,92,69)
        self.mview = mview
        self.base:addChild(mview, 3)
        self.mapView.getBatch():setVisible(false)
        self.shadows = ui.node()
        self.base:addChild(self.shadows, 4)
        self.bottom = ui.node()
        self.base:addChild(self.bottom, 5)
        self.useDepth = false
        self.objs = CaeDrawControlNode:create(self.useDepth)--ui.node()
        self.base:addChild(self.objs, 7)
        self.roleShadows = ui.node()
        self.objs:addChild(self.roleShadows, 4)
        self.effects = ui.node()
        self.base:addChild(self.effects, 8)
        self.upNode = ui.node()
        self.base:addChild(self.upNode, 9)

        self.delayNode = self.effects
        --下雪逻辑
        if cc.FileUtils:getInstance():isFileExist("images/loadLightX2.png") and false then
            local globalSnow = {ui.node(),{},false}
            for i=1, 6 do
                local enode = ui.node({4096,3072})
                -- local p = CaeParticleNode:create("images/loadIceX.png", 30+(6-i)*10, -1)
                -- p:setPositionType(cc.POSITION_TYPE_GROUPED)
                -- p:setEmitterMode(cc.PARTICLE_MODE_GRAVITY)
                -- p:setEmissionRate(1)
                -- p:setAngle(265)
                -- p:setAngleVar(0)
                -- p:setLife(36)
                -- p:setLifeVar(3)
                -- p:setStartSize(20)
                -- p:setStartSizeVar(3+(6-i))
                -- p:setEndSize(20)
                -- p:setEndSizeVar(3)
                -- p:setStartColor(cc.c4f(1,1,1,1))
                -- p:setStartColorVar(cc.c4f(0,0,0,0))
                -- p:setEndColor(cc.c4f(1,1,1,1))
                -- p:setEndColorVar(cc.c4f(0,0,0,0))
                -- p:setPosValues(cc.p(2048, 0), cc.p(1, 1))
                -- p:setStartSpin(-720)
                -- p:setStartSpinVar(720)
                -- p:setEndSpin(720)
                -- p:setEndSpinVar(720)
                -- p:setEmitterMode(0)
                -- p:setGravity(cc.p(0, 0))
                -- p:setSpeed(100)
                -- p:setSpeedVar(30)
                -- p:setRadialAccel(0)
                -- p:setRadialAccelVar(1)
                -- p:setTangentialAccel(0)
                -- p:setTangentialAccelVar(3)
                -- ui.setBlend(p, 1, gl.ONE_MINUS_SRC_ALPHA)
                -- display.adapt(p, 2048, 3200)
                -- enode:addChild(p)
                local p = CaeParticleNode:create("images/loadLightX2.png", 60+(6-i)*20, -1)
                p:setPositionType(cc.POSITION_TYPE_GROUPED)
                p:setEmitterMode(cc.PARTICLE_MODE_GRAVITY)
                p:setEmissionRate(2)
                p:setLife(36)
                p:setLifeVar(0)
                p:setStartSize(20)
                p:setStartSizeVar(3+(6-i))
                p:setEndSize(20)
                p:setEndSizeVar(3)
                p:setEmissionRate(3)
                p:setSpeed(100)
                p:setSpeedVar(30)
                p:setAngle(-90)
                p:setAngleVar(10)
                p:setGravity(cc.p(0,-5))
                p:setPosValues(cc.p(2048, 0), cc.p(1,1))
                p:setStartColor(cc.c4f(1,1,1,0.8))
                p:setStartColorVar(cc.c4f(0,0,0,0))
                p:setEndColor(cc.c4f(1,1,1,0.8))
                p:setEndColorVar(cc.c4f(0,0,0,0))
                p:setRadialAccel(0)
                p:setRadialAccelVar(1)
                p:setTangentialAccel(0)
                p:setTangentialAccelVar(5)
                ui.setBlend(p, 1, gl.ONE_MINUS_SRC_ALPHA)
                -- ui.setBlend(p, gl.SRC_COLOR, 1)
                -- ui.setBlend(p, gl.SRC_ALPHA, 1)
                display.adapt(p, 2048, 3072)
                enode:addChild(p)
                globalSnow[2][i] = enode
                enode:setScale(i*0.6+0.4)
                display.adapt(enode, 2048, 1536, GConst.Anchor.Center)
                globalSnow[1]:addChild(enode)
            end
            globalSnow[1]:retain()
            self.base:addChild(globalSnow[1], 10)

            local winSize = display.winSize
            local pos1 = globalSnow[1]:convertToNodeSpace(cc.p(winSize[1]/2, winSize[2]/2))
            local x1, y1 = 2048-pos1.x, 1536-pos1.y
            for i=2, 6 do
                globalSnow[2][i]:setPosition(2048+x1*(i*0.6+0.4-1),1536+y1*(i*0.6+0.4-1))
                globalSnow[2][i]:setVisible(true)
            end
            self.snow = globalSnow[1]
            self.snows = globalSnow[2]
        end
    end
end

function MainScene:reloadGround()
    local groundType
    if self.battleType==const.BattleTypePve then
        local stage = self.battleParams.stage
        if stage == 0 then
            groundType = "game.Scene.SceneCity"
        elseif stage<60 then
            groundType = "game.Scene.SceneCity"
        elseif stage<120 then
            groundType = "game.Scene.SceneUmland"
        else
            groundType = "game.Scene.SceneArena"
        end
        if DEBUG.DEBUG_BATTLE then
            groundType = "game.Scene.SceneNormal"
        end
    elseif self.battleType==const.BattleTypePvc or self.battleType==const.BattleTypePvh then
        groundType = "game.Scene.SceneArena"
    elseif self.battleType==const.BattleTypePvt or self.battleType==const.BattleTypePvb then
        groundType = "game.Scene.ScenePvt"
    else
        groundType = "game.Scene.SceneNormal"
    end
    if self.displayGroundType~=groundType then
        SceneZombie.destory(self)
        self.displayGroundType = groundType
        if self.ground then
            self.ground:removeFromParent(true)
        end
        local groundView = GMethod.loadScript(groundType)
        self.ground = groundView:loadGround(self)
        self.base:addChild(self.ground, 0, 1)
    end

    local BattleMap = GMethod.loadScript("game.Scene.BattleMap")
    if self.battleMap then
        self.battleMap:clear()
    end
    if self.battleMap2 then
        self.battleMap2:clear()
    end
    self.battleMap = BattleMap.new(40)
    self.battleMap2 = BattleMap.new(40)
    self.battleMap.scene = self
    self.battleMap2.scene = self
    self.battleMap:init(self.map)
    self.battleMap2:init(nil)

    if self.sceneType~="operation" then
        SceneZombie.destory(self)
        self.sceneTime = 0
        local Replay = GMethod.loadScript("game.GameLogic.Replay")
        self.replay = Replay.new(self)
    else
        self.replay = nil
    end
end

function MainScene:reloadMenu()
    if not self.menu then
        local menu = GMethod.loadScript("game.Scene.Menu")
        menu:init()
        self.menu = menu
        self.view:addChild(menu.view, 1)
        menu.scene = self
    end
    local batch = self.mapView.getBatch()
    if self.sceneType=="operation" then
        self.menu:reloadOperation()
        ui.setColor(batch, GConst.Color.White)
        batch:setVisible(false)
        self.mview:setOpacity(0.4*255)
    elseif self.sceneType == "visit" then
        self.menu:reloadVisit()
        ui.setColor(batch, GConst.Color.White)
        batch:setVisible(false)
    else
        batch:stopAllActions()
        batch:setVisible(self.battleType~=const.BattleTypePvj)
        batch:setOpacity(64)
        self.mview:setOpacity(255)
        ui.setColor(batch, GConst.Color.Red)

        self.menu.isStartAnger = false
        self.menu:reloadBattle()
    end
end

function MainScene:clearAll(notInitReplay)
    local allobjs = self.allobjs
    if self.replay and not notInitReplay then
        if self.battleParams and self.battleParams.isReplay then
            self.replay:init(self.battleParams.isReplay)
        else
            self.replay:init()
        end
    end
    if allobjs then
        for obj, _ in pairs(allobjs) do
            obj:removeFromScene()
        end
    end
    self.objs:removeAllChildren(true)
    self.grass:removeAllChildren(true)
    self.bottom:removeAllChildren(true)
    self.shadows:removeAllChildren(true)
    self.effects:removeAllChildren(true)
    self.effects:stopAllActions()
    self.upNode:removeAllChildren(true)
    self.roleShadows = ui.node()
    self.objs:addChild(self.roleShadows, 4)

    self.onlineReward = nil
    self.groups = {{},{}}
    self.walls = {}
    self.allobjs = {}
    self.builds = {}
    self.persons = {}
    self.ebuilds = {}

    ui.clearReuseFrame()
    if music.uncacheAll then
        music.uncacheAll()
    end
end

function MainScene:reloadBuilds(notInitReplay)
    self:clearAll(notInitReplay)
    self.loadBuildsThread = coroutine.create(self.loadBuildsXpcall)
    coroutine.resume(self.loadBuildsThread, self)
end

function MainScene:loadBuildsXpcall()
    xpcall(Handler(self.loadBuilds, self), _G.__G__TRACKBACK__)
end

function MainScene:loadBuilds()
    self.mapView.locked = true
    local context
    if self.updateView then
        self.updateView:removeFromParent(true)
    end
    self.lbpercent = 0
    self.updateView = ui.node()
    self.view:addChild(self.updateView)
    BU.setHvhMenus(nil)
    self.mapView.setSpecialLimitGrids(nil)
    if self.sceneType=="operation" then
        context = GameLogic.getUserContext()
        self.controller:setMode(false, true)
        RegTimeUpdate(self.updateView, Handler(self.controller.updateOperation, self.controller), 0.2)
        local onlineReward = GMethod.loadScript("game.UI.interface.OnlineReward").new()
        onlineReward:setPosition(870+30,635+47)
        --350,350,220,186
        self.objs:addChild(onlineReward,100000)
        self.onlineReward = onlineReward
        coroutine.yield()
        SceneZombie.init(self)
        coroutine.yield()
    else
        context = GameLogic.getCurrentContext()
        if self.sceneType=="battle" then
            self.controller:setMode(true, false)
            RegTimeUpdate(self.updateView, Handler(self.controller.updateBattle, self.controller), 1)
        elseif self.sceneType == "visit" then
            self.controller:setMode(false, true)
            BU.setHvhMenus({"info"})
            RegTimeUpdate(self.updateView, Handler(self.controller.updateVisit, self.controller), 1)
        else
            self.controller:setMode(false, true)
            RegTimeUpdate(self.updateView, Handler(self.controller.updatePrepare, self.controller), 1)
            self.map.setSpecialLimitGrids({10,31,5,18})
            self.mapView.setSpecialLimitGrids({10,31,5,18})
            if self.battleType==const.BattleTypePvc or self.battleType==const.BattleTypePvh or self.battleType==const.BattleTypePvb then
                BU.setHvhMenus({"select"})
            elseif self.battleType==const.BattleTypePvt then
                BU.setHvhMenus({"info"})
            end
        end
    end
    self.context = context
    local isHVH = context.enemy
    local sbuilds = context.buildData:getSceneBuilds()
    coroutine.yield()
    local sgroup = 2
    if isHVH or self.sceneType=="operation" or self.battleType==const.BattleTypePvj then
        sgroup = 1
    end
    local unBuild
    local bloaded = 0
    local btotal = context.buildData.btotal
    local bcount = 0
    local blimit = 3
    if isHVH then
        local ebuilds = context.enemy.buildData:getSceneBuilds()
        btotal = btotal + context.enemy.buildData.btotal
        coroutine.yield()
        for bidx, build in pairs(ebuilds) do
            if isHVH then
                if self.battleType==3 then
                    build.inHVH = const.LayoutPvc
                elseif self.battleType==4 then
                    if context.nightmare then
                        build.inHVH=const.LayoutnPvh
                    else
                        build.inHVH = const.LayoutPvh
                    end
                else
                    build.inHVH = const.LayoutPvtDef
                end
            end
            bloaded = bloaded + 1
            bcount = bcount + 1
            self.lbpercent = bloaded/btotal
            build.group = 3-sgroup
            if build.avtInfo and build.avtInfo.nowHp<=0 then
            else
                build:addToScene(self,build.initGrid[1],build.initGrid[2])
                if bcount>=blimit then
                    bcount = 0
                    coroutine.yield()
                end
            end
        end
        self.ebuilds = ebuilds
    end
    for bidx, build in pairs(sbuilds) do
        if isHVH then
            if self.battleType==3 then
                build.inHVH = const.LayoutPvc
            elseif self.battleType==4 then
                if context.nightmare then
                    build.inHVH=const.LayoutnPvh
                else
                    build.inHVH = const.LayoutPvh
                end
            else
                build.inHVH = const.LayoutPvtAtk
            end
        end
        build.group = sgroup

        --剧情pve中主城变护盾墙
        local bp = self.battleParams

        local changeTown = false
        if bp and build.bid == 1 then
            if bp.special and bp.special[1]==const.ItemOther and self.battleType == const.BattleTypePve and bp.star<3 then
                changeTown = true
            end
        end
        bloaded = bloaded + 1
        bcount = bcount + 1
        self.lbpercent = bloaded/btotal
        if changeTown then
            --护盾墙
            local rbuild = Build.new(1000)
            rbuild.group = 1
            rbuild.avtInfo = nil
            rbuild.data = clone(rbuild.data)
            rbuild.data.hp = 0
            rbuild:addToScene(self,build.initGrid[1],build.initGrid[2])
            self.battleData.sheildWall = rbuild
        else
            --addToScene之后才有avtInfo
            build:addToScene(self,build.initGrid[1],build.initGrid[2])
            if build.avtInfo and build.avtInfo.nowHp and build.avtInfo.nowHp<=0 then
                --先把战斗中的给去掉
                if self.battleMap then
                    self.battleMap:removeBattler(build)
                end
                build:removeFromScene()
            end
        end
        if bcount>=blimit then
            bcount = 0
            coroutine.yield()
        end
        if build.bid == 2 then
            unBuild = build
        end
        if not unBuild then
            unBuild = build
        end
    end

    self.builds = sbuilds

    self.mapView.locked = nil
    self.mapView.update()
    self.loadBuildsThread = nil

    context:changeRes(const.ResGold, 0)
    context:changeRes(const.ResBuilder, 0)
end

function MainScene:addOperationUpdate(view, callback)
    if not self._updates then
        self._updates = {}
    end
    self._updates[view] = callback
    view.inUpdate = true
end

function MainScene:removeOperationUpdate(view)
    if self._updates then
        self._updates[view] = nil
        view.inUpdate = nil
    end
end


return MainScene.new()
