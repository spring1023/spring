local GConst = _G["GConst"]
local GMethod = _G["GMethod"]
local ui = _G["ui"]
local display = _G["display"]
local SData = GMethod.loadScript("data.StaticData")
local const = GMethod.loadScript("game.GameLogic.Const")
local BU = GMethod.loadScript("game.Build.Util")
local BuildProcess = GMethod.loadScript("game.Build.BuildProcess")
local buildLevelsConfig = GMethod.loadScript("data.AllConfig").buildLevelsConfig
local Build = class()

--以下是建筑的视图逻辑；设计的时候需要降低耦合性，增强可配置性、可调整性
--因此将部分逻辑改为模板化的实现方式可能是个更合理的做法。

--规定：所有局域方法都作用于vstate和vconfig两个table
--vstate用于存放所有视图view的节点和当前状态；
--vstate里必须保存对当前场景scene的引用
--vstate包括view(建筑的根节点)、build(建筑的视图显示节点)、bottom(建筑的底部)、shadow(建筑的阴影)
--vstate包括一些building\circle之类的临时节点
--vconfig用于存放视图有关的配置

-- 作用：添加加速特效
local function _refreshDShadow(vstate, show, forceRefresh)
    if not vstate then
        return
    end
    local shadow = vstate.dshadow
    if not shadow then
        show = false
    end
    if vstate.effectShadow and (forceRefresh or not show) then
        vstate.effectShadow:runAction(ui.action.sequence({{"fadeOut",1},"remove"}))
        vstate.effectShadow = nil
        vstate.build:stopActionByTag(2)
    end
    if show and not vstate.effectShadow and not vstate.destroyed then
        if shadow==1 then
            local scene = vstate.scene
            local shadowview = ui.node(nil, true)
            local map = vstate.scene.map
            local gx, gy = vstate.gx, vstate.gy
            local gsize = vstate.gsize

            local px, py = map.convertToPosition(gx+gsize/2, gy+gsize/2)
            shadowview:setPosition(px,py)
            shadowview:setScaleX(0.433*gsize)
            shadowview:setScaleY(0.325*gsize)
            vstate.scene.objs:addChild(shadowview, map.minZ-1)
            local p=ui.sprite("images/buildBoostShadow.png")
            display.adapt(p, 0, 0, GConst.Anchor.Center)
            shadowview:addChild(p)
            p:runAction(ui.action.arepeat({"rotateBy",10,360}))
            p:runAction(ui.action.fadeIn(1 ))
            ui.setBlend(p, 770, 1)
            vstate.effectShadow = shadowview
            local seqH=ui.action.sequence({{"scaleTo",0.15,1,1.1},{"scaleTo",0.15,1,1}})
            local seqW=ui.action.sequence({{"delay",0.04},{"scaleTo",0.15,1.03,1},{"scaleTo",0.15,1,1}})
            local accAnimat=ui.action.arepeat(ui.action.sequence({ui.action.spawn({seqH,seqW}),{"delay",1.2}}))
            accAnimat:setTag(2)
            vstate.build:runAction(accAnimat)
        end
    end
end

-- 作用：刷新建筑的阴影部分；根据vconfig中的shadow字段来进行阴影添加
local function _refreshShadow(vstate, vconfig, show, forceRefresh)
    if not vstate then
        return
    end
    if vstate.shadow and (forceRefresh or not show) then
        vstate.shadow:removeFromParent(true)
        vstate.shadow = nil
    end
    if not vconfig then
        return
    end
    if show and not vstate.shadow then
        local shadow = vconfig.shadow
        if shadow then
            local scene = vstate.scene
            local shadowview = nil
            local px, py = vstate.view:getPosition()
            shadowview = ui.sprite(shadow[1], {shadow[4], shadow[5]})
            display.adapt(shadowview, px+shadow[2], py+shadow[3], GConst.Anchor.Center)
            scene.shadows:addChild(shadowview, 1)
            vstate.shadow = shadowview
            if shadow[6] then
                --即有多个影子的话，在此处继续添加到当前shadowview上
                local ssview
                local sx = shadowview:getScaleX()
                local sy = shadowview:getScaleY()
                local ox = shadow[4]/2-shadow[2]
                local oy = shadow[5]/2-shadow[3]
                for _, ss in ipairs(shadow[6]) do
                    ssview = ui.sprite(ss[1], {ss[4]/sx, ss[5]/sy})
                    display.adapt(ssview, (ss[2]+ox)/sx, (ss[3]+oy)/sy, GConst.Anchor.Center)
                    shadowview:addChild(ssview, 0)
                end
            end
        end
    end
    _refreshDShadow(vstate, show)
end

local function _addModelView(vstate, setting, key)
    if not vstate then
        return
    end
    if vstate[key] then
        for _, view in ipairs(vstate[key]) do
            view:removeFromParent(true)
        end
        vstate[key] = nil
    end
    if not setting then
        return
    end
    local ox = setting.x or 0
    local oy = setting.y or 0
    local views = {}
    for i, v in ipairs(setting.views) do
        local view = ui.sprite(v[1])
        view:setScale(v[5] or 1)
        display.adapt(view, v[2]+ox, v[3]+oy, GConst.Anchor.Bottom)
        vstate.view:addChild(view, v[4] or 0)
        views[i] = view
    end
    vstate[key] = views
end

local function _addBuildingView(vstate, vconfig, show)
    local setting = nil
    if show then
        setting = BU.getModelConfig("upgrade", vconfig.upgrade or vstate.gsize)
    end
    _addModelView(vstate, setting, "buildingViews")
end

local function _addBuildView(vstate, vconfig)
    if not vstate then
        return
    end
    if vstate.build then
        vstate.build:removeFromParent(true)
        vstate.build = nil
        vstate.money = nil
    end
    if not vconfig then
        return
    end

    local bid = vstate.bid
    local blv = vstate.level
    --设置tips需要的主城等级
    local key = "tips"
    if bid==1 and GEngine.getConfig(key) then
        local info = json.decode(GEngine.getConfig(key))
        info.lv = blv
        GEngine.setConfig(key, json.encode(info),true)
    end

    --根据图片等级配置显示
    if buildLevelsConfig and buildLevelsConfig[bid] and buildLevelsConfig[bid][blv] then
        blv=buildLevelsConfig[bid][blv]
    else
        if vconfig.maxLv and blv>vconfig.maxLv then
            blv = vconfig.maxLv
        end
    end
    local build
    local views = vconfig.views
    local vbase = vconfig.base or 2
    if type(vbase)=="table" then
        if vbase[1]==2 then
            build = ui.sprite(vbase[2])
        elseif vbase[1]==3 then
            build = ui.sprite(vbase[2] .. bid .. (vbase[3] or ".png"))
        else
            build = ui.sprite(vbase[2] .. blv .. (vbase[3] or ".png"))
        end
    elseif vbase==1 then
        build = ui.sprite("images/build" .. bid .. ".png")
    elseif vbase==2 then
        build = ui.sprite("images/build" .. bid .. "_" .. blv .. ".png")
    else
        build = ui.node({0,0}, true)
    end
    --build:setScale(2)
    --local bviews = {build}
    if not build then
        if not vstate.retryTest then
        --强制加载建筑图片
            memory.releaseCacheFrame()
            for i=1,5 do
                memory.loadSpriteSheet("images/builds"..i..".plist")
            end
            vstate.retryTest = true
            return _addBuildView(vstate, vconfig)
        else
            GameLogic.otherGlobalInfo = {bid, blv, vbase}
        end
    end
    local bviews = {}
    local bformats = {}
    build:setCascadeOpacityEnabled(true)
    build:setCascadeColorEnabled(true)

    if views then
        local cx = build:getContentSize().width/2
        local reuse, view, vanchor
        for _, vs in ipairs(views) do
            local ss = 1
            if vs.reuseId then
                reuse = vconfig.reuses[vs.reuseId]
            else
                reuse = vs
            end
            local vidx = vs.idx or reuse.idx
            if reuse.type=="image" then
                local fparams = reuse.params or vs.params
                local format = vs.format or reuse.format
                if fparams then
                    local params = {}
                    for k, v in pairs(fparams) do
                        if v=="blv" then
                            params[k] = blv
                        elseif v=="bid" then
                            params[k] = bid
                        else
                            params[k] = v
                        end
                    end
                    if vs.params and vs.params~=fparams then
                        for k, v in pairs(vs.params) do
                            params[k] = v
                        end
                    end
                    view = ui.sprite(StringManager.formatString(format, params))

                    if vidx then
                        bformats[vidx] = {format, params}
                    end
                else
                    if not memory.getFrame(reuse.image, true) and not cc.FileUtils:getInstance():isFileExist(reuse.image) then
                        --判断是否是淘汰赛
                        if bid == 72 then
                            local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
                            view = KnockMatchData:newImageStatusStage(blv)
                        elseif reuse.image == "images/pvz/imgPvzOutStatueUp.png" then
                            -- 这原图是脑残吗？
                            view = ui.sprite("images/pvz/imgPvzOutStatueUpSmall.png")
                            reuse.image = "images/pvz/imgPvzOutStatueUpSmall.png"
                            reuse.sx = nil
                            reuse.sy = nil
                        else
                            view = ui.sprite(reuse.image)
                        end
                    else
                        view = ui.sprite(reuse.image)
                    end
                end
            elseif reuse.type=="particle" then
                if reuse.plist then
                    view = ui.particle(reuse.plist)
                else
                    view = ui.particle(reuse.file, reuse.conf)
                end
                --ss = 0.5
                view:setPositionType(cc.POSITION_TYPE_GROUPED)
            elseif reuse.type=="csb" then
                view = ui.csbNode(reuse.path)
                local action = ui.csbTimeLine(reuse.path)
                view:runAction(action)
                action:gotoFrameAndPlay(0,true)
            end
            if not view then
                GameLogic.otherGlobalInfo = {bid, blv, vs}
            end
            local sx = vs.sx or reuse.sx or 1
            view:setScaleX(sx*ss)
            view:setScaleY((vs.sy or reuse.sy or sx)*ss)
            if reuse.action then
                view:runAction(ui.action.action(reuse.action))
            end
            if reuse.anchor then
                vanchor = GConst.Anchor[reuse.anchor]
            else
                vanchor = GConst.Anchor.Bottom
            end
            if reuse.visible==false then
                view:setVisible(false)
            end
            if reuse.r then
                view:setRotation(reuse.r)
            end
            if reuse.color then
                ui.setColor(view,reuse.color)
            end
            if reuse.opacity then
                view:setOpacity(reuse.opacity)
            end
            if reuse.flip=="X" then
                view:setFlippedX(true)
            elseif reuse.flip=="Y" then
                view:setFlippedY(true)
            elseif reuse.flip=="XY" then
                view:setFlippedX(true)
                view:setFlippedY(true)
            end
            if vs.gz then
                view:setGlobalZOrder(vs.gz)
            end
            if reuse.hvalue then
                view:setHValue(reuse.hvalue)
            end
            if reuse.blend then
                ui.setBlend(view, reuse.blend)
            end
            --display.adapt(view, cx+(vs.x or reuse.x or 0)/2, (vs.y or reuse.y or 0)/2, vanchor)
            display.adapt(view, cx+(vs.x or reuse.x or 0), vs.y or reuse.y or 0, vanchor)
            if vidx then
                bviews[vidx] = view
            end
            if vidx and reuse.delayCreate then
                bviews[vidx]:retain()
                build:runAction(ui.action.sequence({{"delay",reuse.delayCreate},{"call",function ()
                    build:addChild(bviews[vidx], vs.z or reuse.z or 0)
                end}}))
            else
                build:addChild(view, vs.z or reuse.z or 0)
            end
        end
    end
    display.adapt(build, vstate.view:getContentSize().width/2+(vconfig.x or 0), vconfig.y or 0, GConst.Anchor.Bottom)
    vstate.view:addChild(build)
    vstate.build = build
    vstate.bviews = bviews
    vstate.bformats = bformats
    return build, bviews
end

local function _refreshBuildView(vstate, vconfig, forceUpdateShadow)
    local focus = vstate.focus
    if vstate.destroyed then
        vconfig = BU.getModelConfig("ruin", vconfig.ruin or vstate.gsize)
    end
    _addBuildView(vstate, vconfig)
    vstate.isBottom = vconfig.isBottom
    vstate.edge = vconfig.edge or 5
    if forceUpdateShadow then
        _refreshShadow(vstate, vconfig, vstate.bottomState==0, true)
    end
end

--重新设定建筑的Z坐标
local function _reorderZ(vstate, zOrder)
    local view = vstate.view
    local parent = view:getParent()
    local scene = vstate.scene
    -- view:setPositionZ((3072-zOrder)/3072)
    if not parent then
        --simpleRegisterEvent(view, self.eventEntries, build)
        -- if vstate.bid == 15 then
        --     scene.objs:addChild(view, 0)
        -- else
        --     scene.objs:addChild(view, 1)
        -- end
        scene.objs:addChild(view)
        scene.upNode:addChild(vstate.upNode)
        --scene.uiground:addChild(self.uiview, zOrder)
    end
    if scene.useDepth then
        view:setPositionZ(zOrder/3072)
        vstate.upNode:setLocalZOrder(zOrder)
    else
        local curZorder = view:getLocalZOrder()
        if curZorder~=zOrder then
            view:setLocalZOrder(zOrder)
            vstate.upNode:setLocalZOrder(zOrder)
            --scene.uiground:reorderChild(build.uiview, zOrder)
        end
    end
end

-- 作用：将Build移动到指定格子；其深度由所在地图map的属性决定
-- 当建筑是一个最下层建筑或者当前状态为最下层状态时，深度为最低深度；否则，由其坐标位置修改深度层级
local function _moveGrid(vstate, gix, giy)
    local map = vstate.scene.map
    local gsize = vstate.gsize
    local px, py = map.convertToPosition(gix, giy)
    vstate.view:setPosition(px, py)
    vstate.upNode:setPosition(px,py)
    py = py+map.gsizeY*gsize/2
    vstate.cpx, vstate.cpy = px, py
    if vstate.isBottom then
        vstate.cpz = map.minZ
    else
        vstate.cpz = map.maxZ-py
    end
    --vstate.uiview:setPosition(px, py)
    if vstate.circle then
        vstate.circle:setPosition(px, py)
    end
end


--以下是一些游戏逻辑

--作用：设置建筑底部图片
function Build:setBottomState(bottomState, gix, giy)
    local vstate = self.vstate
    if vstate.bottomState == bottomState then
        return bottomState<2
    end
    if vstate.bottom and ((bottomState==0 and vstate.bottomState>0) or vstate.bottomState==0) then
        vstate.bottom:removeFromParent(true)
        vstate.bottom = nil
    end
    vstate.bottomState = bottomState
    local gsize = vstate.gsize
    local scene= vstate.scene
    local map = scene.map
    if bottomState==0 then
        if not vstate.bottom then
            local bottom = self.vconfig.bottom or 1
            if scene.bottomType then
                if bottom >= 1 and bottom <= 2 then
                    vstate.bottom = ui.sprite("sceneBottom" .. scene.bottomType .. gsize .. ".png")
                end
            else
                if bottom==1 then
                    vstate.bottom = ui.sprite("sceneBottom" .. gsize .. ".png")
                elseif bottom==2 then
                    vstate.bottom = ui.sprite("sceneBottom" .. gsize .. "b.png")
                end
                if vstate.bottom and (gix<=5 or giy<=5 or gix+gsize>=37 or giy+gsize>=37) then
                    ui.setColor(vstate.bottom, {248, 230, 231})
                end
            end
            if vstate.bottom then
                local px, py = map.convertToPosition(gix, giy)
                display.adapt(vstate.bottom, px, py, GConst.Anchor.Bottom)
                scene.grass:addChild(vstate.bottom, 0)
            end
        end
    else
        if not vstate.bottom then
            local bottomImage = "images/buildDownGridR.png"
            local bottom = ui.shlNode()
            local sizeX, sizeY = map.gsizeX, map.gsizeY
            local baseX, baseY = sizeX * gsize/2, -sizeY
            bottom:setContentSize(cc.size(sizeX*gsize, sizeY*gsize))
            for i=1, gsize do
                for j=1, gsize do
                    local temp = ui.sprite(bottomImage, {sizeX, sizeY})
                    display.adapt(temp, (j-i)*sizeX/2 + baseX, (i+j+1)*sizeY/2 + baseY, GConst.Anchor.Center)
                    bottom:addChild(temp)
                end
            end
            display.adapt(bottom, baseX, 0, GConst.Anchor.Bottom)
            vstate.view:addChild(bottom, -2)
            vstate.bottom = bottom
        end
        if bottomState==1 then
            vstate.bottom:setHValue(114)
        else
            vstate.bottom:setHValue(0)
        end
    end
    _refreshShadow(vstate, self.vconfig, bottomState==0, false)
end

--返回可移动状态（可移动到此处为true，不可则为false)
function Build:moveAndCheck(gix, giy, moving)
    local vstate = self.vstate
    local scene = vstate.scene
    local gsize = vstate.gsize
    local map = scene.map
    --[[
    if isOk then
        if scene.touchAble then
            if gix<scene.touchArea[1] or gix+gsize-1>scene.touchArea[3] or giy<3 or giy+gsize-1>scene.touchArea[4] then
                isOk = false
            end
        end
    end
    --]]
    local bottomState = 0
    local isOk = true
    if moving then
        isOk = not map.checkGridUse(gix, giy, gsize, self)
        bottomState = (isOk and 1) or 2
    end
    self:setBottomState(bottomState, gix, giy)
    return isOk
end

--将一个建筑按指定深度移动到指定节点上；未指定则使用默认深度
function Build:moveGrid(gix, giy, gz)
    local vstate = self.vstate
    _moveGrid(vstate, gix, giy)
    _reorderZ(vstate, gz or vstate.cpz)
end

--将建筑在touch状态下移动到某格子
function Build:moveInTouch(gix, giy)
    local vstate = self.vstate
    local scene = vstate.scene
    vstate.gx = gix
    vstate.gy = giy

    local isOk = self:moveAndCheck(gix, giy, true)
    vstate.moveOk = isOk
    self:moveGrid(gix, giy, scene.map.maxZ+1)

    if self.bstate and self.bstate[2] then
        self.bstate[2][1]:setGray(not isOk)
    end
end

--将建筑在非touch状态下定位到某格子；注意购买状态下的建筑是无法调用该方法的
function Build:resetGrid()
    if self.bstate then
        return
    end
    local vstate = self.vstate
    local scene = vstate.scene

    if not vstate.moveOk then
        vstate.gx = vstate.bgx
        vstate.gy = vstate.bgy
        vstate.moveOk = true
    end
    local gix, giy = vstate.gx, vstate.gy
    self:moveGrid(gix, giy)
    self:moveAndCheck(gix, giy)
    if vstate.bgx ~= gix or vstate.bgy ~= giy then
        if vstate.bgx then
            self:clearGridUse(vstate.bgx, vstate.bgy)
        end
        self:setGridUse(gix, giy)

        local builder = self.vstate.builder
        if builder then
            if builder.target==self then
                builder:setTarget(self)
            end
        end
    end
end

--touch事件
--判断点击位置是否在建筑上；这是一个功能逻辑;
--简化判断的话，只对出格建筑进行出格检测
function Build:cbtCheck(x, y)
    local vstate = self.vstate
    if not vstate then return false end
    local gsize = vstate.gsize
    local map = vstate.scene.map
    if map.isTouchInGrid(x, y, vstate.gx, vstate.gy, gsize) then
        return true
    end
    if not vstate.destroyed then
        local vconfig = self.vconfig
        local sw = vconfig.w
        local sh = vconfig.h
        local bx, by = vstate.view:getPosition()
        if x>=bx-sw/2 and x<=bx+sw/2 and y>by+gsize*map.gsizeY/2 and y<=by+(vstate.y or 0)+sh then
            return true
        end
    end
end

function Build:cbtBegin(x, y)
    local vstate = self.vstate
    if not vstate then
        return
    end
    local touchInfo = {btime=GMethod.getGTime()}
    if vstate.focus and vstate.movable then
        touchInfo.bpx = vstate.cpx
        touchInfo.bpy = vstate.cpy
    end
    vstate.touchInfo = touchInfo
end

function Build:cbtMove(ox, oy)
    local vstate = self.vstate
    if not vstate then
        return
    end
    local scene = vstate.scene

    if vstate.focus and vstate.movable then
        local ti = vstate.touchInfo
        local gsize = vstate.gsize
        local ogx, ogy = vstate.gx, vstate.gy
        local gx, gy = scene.map.convertToGrid(ox + ti.bpx, oy + ti.bpy, gsize)
        gx = math.floor(gx)
        gy = math.floor(gy)
        if gx ~= ogx or gy ~= ogy then
            self:moveInTouch(gx, gy)
            music.play("sounds/buildMove.wav")
            BU.hideBuildMenu(self)
        end
        return true
    end
end

function Build:cbtEnd()
    local vstate = self.vstate
    if not vstate then
        return
    end
    local scene = vstate.scene
    vstate.touchInfo = nil
    if vstate.focus then
        if vstate.bottomState==0 then
            self:setFocus(false)
        elseif vstate.moveOk and vstate.movable then
            if not self.bstate then
                self:resetGrid()
                GameEvent.sendEvent(GameEvent.EventBuildMove, self)
            end
        end
    else
        if vstate.upIcon and self:onUpTouch() then
            return
        end
        self:setFocus(true)
    end
end

function Build:cbtHold(x, y)
    local vstate = self.vstate
    if not vstate then
        return
    end
    local touchInfo = vstate.touchInfo
    if not vstate.focus and vstate.movable and touchInfo.btime then
        local now = GMethod.getGTime()
        if now-touchInfo.btime>0.6 then
            touchInfo.bpx = vstate.cpx
            touchInfo.bpy = vstate.cpy
            touchInfo.btime = nil
            self:setFocus(true)
            vstate.moveOk = true
        end
    end
end

function Build:isInUpgrade()
    return self.worklist~=nil
end

function Build:reloadArmor()
    local alv = self.armor or 0
    local vstate = self.vstate
    if vstate.armorDestroyed then
        alv = 0
    end
    if alv~=vstate.alv then
        --位置偏移，大小
        local setting={[37]={0,20,1.2}}
        local ox,oy,oScale=0,0,1
        if setting[vstate.bid] then
            ox,oy,oScale = setting[vstate.bid][1],setting[vstate.bid][2],setting[vstate.bid][3]
        end
        local index=math.floor(alv/5)+1
        if index~=vstate.aIdx and vstate.armor then
            vstate.aIdx=index
            vstate.armor:removeFromParent(true)
            vstate.armor = nil
        end
        local scals={{1.05,1.6,1.76},{1.5,2.2,2.4},{2.2,3.3,3.6}}
        local gridI=vstate.gsize-1
        local scal=scals[gridI]
        if not scal then
            return
        end
        local temp
        if vstate.armor and vstate.alv and alv<vstate.alv then
            vstate.armor:removeFromParent(true)
            vstate.armor = nil
            local armorBomb = ui.node()
            display.adapt(armorBomb, vstate.view:getContentSize().width/2+ox, vstate.view:getContentSize().height/2+oy, GConst.Anchor.Center)
            vstate.view:addChild(armorBomb)
            armorBomb:setScale(oScale)
            vstate.armorEffectManager:addEffect("views1_delayTotal_lv"..index,armorBomb)
            temp=vstate.armorEffectManager.views.bao
            temp:setScale(3.3*scal[1])
            temp:setPosition(0,20)
            armorBomb:runAction(ui.action.sequence({{"delay",0.75},{"remove"}}))
        end
        vstate.alv = alv
        if alv>0 and not vstate.armor then
            vstate.armor = ui.node()
            display.adapt(vstate.armor, vstate.view:getContentSize().width/2+ox, vstate.view:getContentSize().height/2+oy, GConst.Anchor.Center)
            vstate.view:addChild(vstate.armor)
            vstate.armor:setScale(oScale)
            local effectManager=GameEffect.new("Build_Shield.json")
            local views=effectManager.views
            vstate.armorEffectManager=effectManager
            local bg=vstate.armor
             effectManager:addEffect("views1_delay0_lv"..index,bg)
              temp=views.Shield_Breaking_00000_11
              temp:setScale(scal[1])
              temp:setPosition(0,20)
              temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",35/60,128},{"fadeTo",35/60,255}})))
              temp=views.guangquan1_14
              temp:setScale(scal[2])
              temp:setPosition(0,20)
              temp=views.hudun1_12_0
              temp:setScale(scal[3])
              temp:setPosition(0,20)
              temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",35/60,52},{"fadeTo",35/60,128}})))

        end
    end
end

function Build:reloadUpText(backType2, resText)
    local vstate = self.vstate
    --参观不显示气泡
    if vstate.scene.sceneType=="visit" then
        return
    end
    if vstate.buildName then
        return
    end
    if not resText or resText == "" then
        backType2 = 0
    end
    local backType = backType2 + 10
    local upText = nil
    if vstate.upBack ~= backType then
        vstate.upBack = backType
        if vstate.upTextBack then
            vstate.upTextBack:removeFromParent(true)
            vstate.upTextBack = nil
        end
        if vstate.upIcon then
            vstate.upIcon:removeFromParent(true)
            vstate.upIcon = nil
        end
        if backType2>0 and backType2<=2 then
            upText = vstate.upText
            if not upText then
                vstate.upTextBack = ui.node()
                display.adapt(vstate.upTextBack, vstate.view:getContentSize().width/2, self:getHeight()-20, GConst.Anchor.Bottom)
                vstate.upNode:addChild(vstate.upTextBack, 10)
                local image = ui.sprite("images/buildUpTextBack" .. backType2 .. ".png")
                display.adapt(image, 0, 0, GConst.Anchor.Bottom)
                vstate.upTextBack:addChild(image)
                local sx,sy=image:getContentSize().width-10,image:getContentSize().height-10
                upText = ui.label("", General.font1, 48,{fontW=sx,fontH=sy})
                display.adapt(upText, 0, 75, GConst.Anchor.Center)
                vstate.upTextBack:addChild(upText)
            end
        elseif vstate.upTextBack then
            vstate.upTextBack:removeFromParent(true)
            vstate.upTextBack = nil
        end
    end
    if upText then
        upText:setString(resText)
    end
end

function Build:reloadUpIcon(backType, resIcon)
    local vstate = self.vstate
    local but
    if vstate.scene.sceneType == "visit" then
        return
    end
    if vstate.upBack ~= backType then
        vstate.upBack = backType
        if vstate.upTextBack then
            vstate.upTextBack:removeFromParent(true)
            vstate.upTextBack = nil
        end
        if backType>0 and backType<=2 then
            but = vstate.upIcon
            local image = "images/buildUpResBg" .. backType .. ".png"
            if not but then
                but = ui.button({99, 107}, self.onUpTouch, {cp1=self, actionType=0, image=image, priority=0})
                but:setTouchThrowProperty(true, false)
                display.adapt(but, vstate.view:getContentSize().width/2, self:getHeight()-20, GConst.Anchor.Bottom)
                vstate.upNode:addChild(but, 10)
                vstate.upRes = nil
                vstate.upResIcon = nil
                vstate.upIcon = but
            else
                but:setBackgroundImage(image, 0)
            end
        elseif vstate.upIcon then
            vstate.upIcon:removeFromParent(true)
            vstate.upIcon = nil
        end
    end
    if but and resIcon~=vstate.upRes then
        vstate.upRes = resIcon
        if vstate.upResIcon then
            vstate.upResIcon:removeFromParent(true)
            vstate.upResIcon = nil
        end
        vstate.upResIcon = GameUI.addResourceIcon(vstate.upIcon:getDrawNode(), resIcon, 0.6, 50, 62)
    end
end

function Build:setWorkProcess(lt, mt, otherSetting)
    local vstate = self.vstate
    if not vstate then
        return
    end
    local hasProcess = lt and lt>0 and not vstate.bprocess
    if hasProcess then
        if not vstate.wprocess then
            vstate.wprocess = BuildProcess.new(2, mt)
            display.adapt(vstate.wprocess.view, vstate.view:getContentSize().width/2, vstate.view:getContentSize().height+((otherSetting and otherSetting.oy) or 0), GConst.Anchor.Bottom)
            vstate.upNode:addChild(vstate.wprocess.view)
            if vstate.buildName then
                BU.showBuildName(self)
            end
        end
        vstate.wprocess:setMax(mt)
        vstate.wprocess:setLeftValue(lt)
    else
        if vstate.wprocess then
            vstate.wprocess.view:removeFromParent(true)
            vstate.wprocess = nil
            if vstate.buildName then
                BU.showBuildName(self)
            end
        end
    end
end

function Build:runFocusAnimate(focus)
    local vstate = self.vstate
    if not vstate then return end
    local vb = vstate.build
    if not vb then return end
    if focus then
        if not vstate.backViewState then
            vstate.backViewState = {vb:getScaleX(), vb:getScaleY()}
        end
        local ascale, sx, sy = 1.2, vstate.backViewState[1], vstate.backViewState[2]
        vb:runAction(ui.action.easeSineIO(ui.action.sequence({
            {"scaleTo", 0.1, sx * ascale, sy * ascale},
            {"scaleTo", 0.1, sx, sy}
        })))
        local focusAnimate=ui.action.arepeat(ui.action.sequence({{"tintto",0.75,{100,100,100}},{"tintto",0.75,{255,255,255}}}))
        focusAnimate:setTag(1)
        vb:runAction(focusAnimate)
    else
        vb:stopAllActionsByTag(1)
        if vstate.backViewState then
            vb:setScaleX(vstate.backViewState[1])
            vb:setScaleY(vstate.backViewState[2])
        end
        vb:setColor(cc.c3b(255,255,255))
    end
    if vstate.upTextBack then
        if vstate.bprocess or vstate.wprocess then
            vstate.upTextBack:setVisible(false)
        else
            vstate.upTextBack:setVisible(not focus)
        end
    end
    if vstate.upIcon then
        if vstate.bprocess or vstate.wprocess then
            vstate.upIcon:setVisible(false)
        else
            vstate.upIcon:setVisible(not focus)
        end
    end
end

function Build:setFocus(focus)
    local vstate = self.vstate
    if not vstate then
        GameEvent.sendEvent(GameEvent.EventFocus, nil)
        return
    end
    local scene = vstate.scene
    if focus==vstate.focus then
        return
    end
    vstate.focus = focus
    if focus then
        GameEvent.sendEvent(GameEvent.EventFocus, self)
        local ssize = vstate.view:getContentSize()
        if vstate.movable then
            local pt, pts = BU.reusePts(self)
            local gsize = vstate.gsize
            for i=1, 4 do
                local xk, yk = 3-math.ceil(i/2)*2, 1-(i%2)*2
                display.adapt(pts[i], ssize.width*(1+gsize)/4/gsize*xk, ssize.height*(1+gsize)/4/gsize*yk, GConst.Anchor.Center)
            end
        end
        BU.showBuildName(self)
        if self.bsetting.hasCircle then
            BU.reuseCircle(self)
        end
        if not self.bstate then
            BU.showBuildMenu(self)
        end
    else
        GameEvent.sendEvent(GameEvent.EventFocus, nil)
        if vstate.bottomState>0 and not self.bstate then
            self:resetGrid()
        end
        if self.bsetting.hasCircle then
            BU.recoveryCircle(self)
        end
        if vstate.movable then
            BU.recoveryPts(self)
        end
        BU.recoveryBuildName(self)
        if self.bstate then
            self:removeFromScene()
        else
            BU.hideBuildMenu(self)
        end
    end
    self:runFocusAnimate(focus)
end

function Build:clearGridUse(bgx, bgy)
    if not bgx or not bgy then return end
    local vstate = self.vstate
    local scene = vstate.scene
    local map = scene.map
    local mapView = scene.mapView

    local gsize = vstate.gsize
    local isGridHide = self.vconfig.isGridHide
    local rowMode = self.bsetting.rowMode
    if not isGridHide and not self.inHVH then
        mapView.clearGridUse(bgx-1, bgy-1, gsize+2)
    end
    map.clearGridUse(bgx, bgy, gsize)
    if self.onGridCleared then
        self:onGridCleared(bgx, bgy)
    end
end

function Build:setGridUse(ngx, ngy)
    if not ngx or not ngy then return end
    local vstate = self.vstate
    local scene = vstate.scene
    local map = scene.map
    local mapView = scene.mapView

    local gsize = vstate.gsize
    local isGridHide = self.vconfig.isGridHide
    local rowMode = self.bsetting.rowMode
    if not isGridHide and not self.inHVH then
        mapView.setGridUse(ngx-1, ngy-1, gsize+2)
    end
    map.setGridUse(ngx, ngy, gsize, self)

    self:onGridSeted(ngx, ngy)
    if self.id and vstate.bgx then
        local delegate = BU.getPlanDelegate() or self.context.buildData
        delegate:changeBuildLayout(self.id, ngx, ngy)
    end
    vstate.bgx, vstate.bgy = ngx, ngy
end

function Build:reloadBuilding()
    local vstate = self.vstate
    if self.worklist and not BU.getPlanDelegate() and not vstate.scene.isBattle and vstate.scene.sceneType~="visit" then
        local bprocess = vstate.bprocess
        if not bprocess then
            local wl = self.worklist
            vstate.bprocess = BuildProcess.new(1, wl[4]-wl[3])
            display.adapt(vstate.bprocess.view, vstate.view:getContentSize().width/2, self:getHeight()+30, GConst.Anchor.Bottom)
            vstate.upNode:addChild(vstate.bprocess.view)
            vstate.bprocess:setLeftValue(wl[4] - GameLogic.getSFloatTime())
        end
    elseif vstate.bprocess then
        vstate.bprocess.view:removeFromParent(true)
        vstate.bprocess = nil
    end
    if vstate.buildName then
        BU.showBuildName(self)
    end
    _addBuildingView(vstate, self.vconfig, self.worklist and not vstate.destroyed and self.info.btype ~= 6)
    if vstate.focus then
        self:runFocusAnimate(true)
        BU.showBuildMenu(self)
    end
end

function Build:reloadEffectShadow()
    local vstate = self.vstate
    if not vstate then
        return
    end
    local dshadow = nil
    if self.boostlist then
        dshadow = 1
    end
    if dshadow~=vstate.dshadow then
        vstate.dshadow = dshadow
        _refreshDShadow(vstate, vstate.bottomState==0 and not vstate.destroyed)
    end
end

function Build:reloadView(forceUpdateShadow)
    local vstate = self.vstate
    vstate.level = self.level
    self.vconfig = BU.loadBuildConfig(vstate.bid, vstate.level, vstate.gsize)
    _refreshBuildView(vstate, self.vconfig, forceUpdateShadow)
    self:reloadBuilding()
    self:reloadEffectShadow()
    self:reloadArmor()
    if self.onReloadView and not vstate.destroyed then
        self:onReloadView()
    end
end

--检查购买或升级花费等逻辑
function Build:checkCost(data)
    local context = GameLogic.getUserContext()
    local cbuilds = context.buildData
    if not data then
        if self.bsetting.numAsLevel and not self.dataReseted then
            local nlv = cbuilds:getBuildNum(self.bid)+1
            if nlv>self.info.maxNum then
                nlv = self.info.maxNum
            end
            self.data = SData.getData("bdatas", self.bsetting.bdid, nlv)
            self.dataReseted = true
        end
        data = self.data
    end
    if self.bid == const.Town then       --主城判断玩家经营等级
        local nlv = SData.getData("townLimit",self.level+1)
        local clv = context:getInfoItem(const.InfoLevel)
        if nlv>clv then
            display.pushNotice(Localizef("stringToLvCanUpTown",{a = nlv}))
            return false
        end
    elseif data.needLevel>cbuilds:getTownLevel() then
        display.pushNotice(StringManager.getFormatString("noticeNeedLevel2", {level=data.needLevel, name=BU.getBuildName(const.Town)}))
        return false
    end
    if data.costitem then
        if context:getItem(const.ItemBuild, data.costitem) <= 0 then
            return false
        end
    elseif context:getRes(data.ctype) < data.cvalue then
        local max = context:getResMax(data.ctype)
        if max>0 and data.cvalue>max then
            local bid = const.GoldStorage
            display.pushNotice(StringManager.getFormatString("noticeStorageFull", {name=BU.getBuildName(bid)}))
        else
            local dialog = AlertDialog.new({ctype=data.ctype, cvalue=data.cvalue, callback=Handler(self.onActionRestore, self, data)})
            if not dialog.deleted then
                display.showDialog(dialog)
            end
        end
        return false
    end
    if data.ctime>0 then
        if self.worklist then
            return false
        elseif context:getRes(const.ResBuilder)==0 then
            if context:getResMax(const.ResBuilder)==0 then
                display.pushNotice(StringManager.getFormatString("noticeBuilderNotEnough",{name=BU.getBuildName(const.BuilderRoom)}))
            else
                local wlists = cbuilds:getBuildWorkList()
                local minItem = nil
                for _, wl in pairs(wlists) do
                    if not minItem or minItem[4]>wl[4] then
                        minItem = wl
                    end
                end
                if minItem then
                    local cost = GameLogic.computeCostByTime(minItem[4]-GameLogic.getSTime())
                    display.showDialog(AlertDialog.new(1, StringManager.getString("alertTitleAccBuild2"), StringManager.getFormatString("alertTextAccBuild2",{num=cost}), {ctype=4, cvalue=cost, callback=Handler(self.onActionWithAcc, self, data)}))
                end
            end
            return false
        end
    end
    return true
end

--当前数值不足，通过其他逻辑补充数值后重新进行回调的逻辑
function Build:onActionRestore(data)
    if self:checkCost(data) then
        local vstate = self.buyVState
        if vstate then
            local scene = vstate.scene
            local gx, gy = vstate.gx, vstate.gy
            local map = scene.map
            if not map.checkGridUse(gx, gy, self.info.size, self) then
                self:addToScene(scene, gx, gy)
                self:onRealBuy()
                self.buyVState = nil
            end
        else
            self:onBeginUpgrade()
        end
    end
end

--当前建造者不足，通过该逻辑进行建造者加速后，再回调的逻辑
function Build:onActionWithAcc(data)
    local vstate = self.buyVState or self.vstate
    local context = self.context
    if context:getRes(const.ResBuilder) > 0 then
        self:onActionRestore(data)
        return
    end
    local cbuilds = context.buildData
    local wlists = cbuilds:getBuildWorkList()
    local minItem = nil
    for _, wl in pairs(wlists) do
        if not minItem or minItem[4]>wl[4] then
            minItem = wl
        end
    end
    if minItem then
        local build = vstate.scene.builds[minItem[5]]
        if build:onAccBuild(true) then
            self:onActionRestore(data)
        end
    end
end

--升级特效
function Build:addUpgradeEffect()
    local vstate = self.vstate
    local scale=0.5+self.info.size*0.2
    local effect=EffectControl.new("buildUpgradeEffect", {scale=scale, x=vstate.view:getContentSize().width/2, y=vstate.view:getContentSize().height/2, z=100})
    effect:addEffect(vstate.view)
    music.play("sounds/buildFinish.wav")
end

--加速动画特效
function Build:addBoostEffect()
    local vstate = self.vstate
    local scale= vstate.gsize/3
    local effect=EffectControl.new("buildSpeedupEffect", {scale=scale, x=vstate.view:getContentSize().width/2, y=vstate.view:getContentSize().height/2, z=100})
    effect:addEffect(vstate.view)
end

--最终确定购买的逻辑入口
function Build:onRealBuy(bstate)
    local stime = GameLogic.getSTime()
    if self.data.ctime>0 then
        self.level = 0
    end
    self:onInit(stime)
    self.context.buildData:buyNewBuild(self, stime)
    local vstate = self.vstate
    vstate.scene.builds[self.id] = self
    if self.data.ctime>0 then
        self:reloadView(true)
        music.play("sounds/buildStart.wav")
        GameEvent.sendEvent(GameEvent.EventBuilderCome, self)
    else
        self:onReload()
        self:addUpgradeEffect()
    end
    if self.updateOperation then
        vstate.scene:addOperationUpdate(vstate.view, Handler(self.updateOperation, self))
    end
    if bstate and bstate[1][1] then
        local tid = 1
        local buildData = self.context.buildData
        local tlevel = buildData:getMaxLevel(tid)
        local bsetting = BU.getBSetting(50)
        local binfo = SData.getData("binfos", bsetting.bdid)
        local max=binfo.levels[tlevel]
        local bnum = buildData:getBuildNum(50)
        if bnum>=max then
            display.pushNotice(Localize("labelHaveBuildAll"))
            return
        end
        local gx, gy = vstate.gx, vstate.gy
        local param = {gx,gy}
        if bstate[1][2] then
            param[3] = bstate[1][2]
            param[4] = bstate[1][3]
        end
        GameEvent.sendEvent(GameEvent.EventBuyBuild, {bid=self.bid, blevel=self.blevel, otherSetting=param})
    end
end

--点击事件购买操作
function Build:onBuy(butOk)
    local vstate = self.vstate
    if not vstate then
        return
    end
    --引导
    local context = self.context
    local menu = self.vstate.scene.menu
    local isGuide = false
    if context.guide:getStep().type == "buyBuild" then
        isGuide = true
    end
    if butOk then
        if not vstate.moveOk then
            return
        end
        local checkSuccess = self:checkCost()
        if checkSuccess then
            local bstate = self.bstate
            if bstate and bstate[2] then
                bstate[2][1]:removeFromParent(true)
                bstate[2][2]:removeFromParent(true)
                bstate[2] = nil
            end
            self.bstate = nil

            self:setFocus(false)
            self:resetGrid()
            self:onRealBuy(bstate)
            if isGuide then
                context.guide:setStepState(1)
                menu:pstory2Show()
                self:setFocus(true)
            end
        else
            self.buyVState = {scene=vstate.scene, gx=vstate.gx, gy=vstate.gy}
            self:setFocus(false)
        end
    else

        self:setFocus(false)
        if isGuide then
            menu:buyBuildShow()
        end
    end
end

--最终确定升级的逻辑入口
function Build:onRealBeginUpgrade(ndata)
    local stime = GameLogic.getSTime()
    if self.beforeUpgrade then
        self:beforeUpgrade(stime)
    end
    if ndata.ctime==0 then
        self.level = self.level+1
        self.data = ndata
        self:onReload(stime)
    end
    self.context.buildData:beginUpgradeBuild(self, stime, ndata)
    if ndata.ctime>0 then
        self:reloadBuilding()
        music.play("sounds/buildStart.wav")
        GameEvent.sendEvent(GameEvent.EventBuilderCome, self)
    else
        self:addUpgradeEffect()
        self:reloadView(true)
    end

    -- 日常任务升级建筑
    GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeBuildLevelUp,1)

    display.closeDialog()
end

--点击事件升级操作
function Build:onBeginUpgrade(level)
    if self.level==self.info.maxLevel or self.worklist then
        return
    end
    if level and type(level) == "number" and level < self.level then
        return
    end
    local ndata = self:getNextData()
    local checkSuccess = self:checkCost(ndata)
    if checkSuccess then
        self:onRealBeginUpgrade(ndata)
    end
end

--完成一次建造升级
function Build:upgradeOver(stime)
    if not self.worklist then
        return
    end
    local context = GameLogic.getUserContext()
    local gstep = context.guide:getStep()
    if gstep.type == "buyBuild" then
        if gstep.id == self.bid and context.buildData:getBuildNum(gstep.id) >= gstep.num then
            context.guide:addStep()
            context.guideHand:removeHand("buyBuild")
        end
    elseif gstep.type == "upgradeTown" then
        if gstep.id == self.bid and self.level + 1 >= gstep.level then
            context.guide:addStep()
            context.guideHand:removeHand("buyBuild")
        end
    end

    if self.info.btype == 6 then
        local rewards = {self.context.buildData:finishRemoveObstacle(self, stime, self.data)}
        GameEvent.sendEvent(GameEvent.EventBuilderGo, self)
        GameLogic.addRewards(rewards)
        GameLogic.statCrystalRewards("移除障碍物奖励",rewards)
        GameLogic.showGet(rewards, 0, false, false)
        self:removeFromScene()
        music.play("sounds/receive.mp3")
        return
    end
    self.data = self:getNextData()
    self.level = self.level+1
    self:onReload(stime)
    self.context.buildData:upgradeBuildOver(self, stime, self.data)
    GameEvent.sendEvent(GameEvent.EventBuilderGo, self)
    self:reloadView(true)
    self:addUpgradeEffect()

    local vstate = self.vstate
    if vstate.effectShadow then
        local seqH=ui.action.sequence({{"scaleTo",0.15,1,1.1},{"scaleTo",0.15,1,1}})
        local seqW=ui.action.sequence({{"delay",0.04},{"scaleTo",0.15,1.03,1},{"scaleTo",0.15,1,1}})
        local accAnimat=ui.action.arepeat(ui.action.sequence({ui.action.spawn({seqH,seqW}),{"delay",1.2}}))
        accAnimat:setTag(2)
        vstate.build:runAction(accAnimat)
    end

    if self.bid == 1 then   --主城升级时触发其他引导
        local tbid
        local step = context.guideOr:getStep()
        local tstep
        if self.level == 3 then
            tstep = 11
        elseif self.level == 4 then
            tstep = 21
        elseif self.level == 5 then
            if not GameLogic.useTalentMatch then
                local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
                KnockMatchData:checkDivideGuide()
            end
        elseif self.level == 6 then
            tstep = 31
        elseif self.level == 7 then
            tstep = 41
        elseif step<50 and self.level == 8 then
            tstep = 51
        elseif step == 0 and self.level == 8 then
            tstep = 61
        end
        if tstep then
            context.guideOr:setStep(tstep)
        end
    end

    --对应建筑建造完成时
    local stepSet = {[2]=14, [5]=24, [4]=34, [6]=44, [8]=64}
    local step = stepSet[self.bid]
    if self.level == 1 and step then
        context.guideOr:setStep(step)
        --给竞技场默认阵型
        if self.bid==const.ArenaBase then
            GameLogic.getUserContext().heroData:setPvcForceLayouts()
        end
    end

    -- 统计主城的等级
    if self.bid == const.Town then
        GameLogic.getUserContext().activeData:finishActConditionOnce(const.ActStatCityLevel,self.level)
    end
end

function Build:onCancelBuild(force)
    if self.worklist then
        local stime = GameLogic.getSTime()
        if self.worklist[4]-stime<=0 then
            return
        end
        if not force then
            local suffix = "Upgrading"
            if self.level==0 then
                suffix = "Building"
            elseif self.info.btype == 6 then
                suffix = "Removing"
            end
            display.showDialog(AlertDialog.new(3,StringManager.getString("alertTitleCancel" .. suffix),StringManager.getFormatString("alertTextCancel" .. suffix, {name=BU.getBuildName(self.bid)}), {callback=Handler(self.onCancelBuild, self, true)}))
        else
            self.context.buildData:cancelBuild(self, stime, self:getNextData())
            GameEvent.sendEvent(GameEvent.EventBuilderGo, self)
            if self.level==0 then
                self:removeFromScene()
                self:onRemove()
            else
                self:onReload(stime)
                self:reloadBuilding()
            end
        end
    end
end

function Build:onAccBuild(force)
    if self.worklist then
        local stime = GameLogic.getSTime()
        local ltime = self.worklist[4]-stime
        if ltime<=0 then
            return
        end
        local cost = GameLogic.computeCostByTime(ltime)
        if not force then
            local suffix = "Upgrading"
            if self.level==0 then
                suffix = "Building"
            elseif self.info.btype == 6 then
                suffix = "Removing"
            end
            display.showDialog(AlertDialog.new(3,StringManager.getString("alertTitleFinish"),StringManager.getFormatString("alertTextFinish" .. suffix,{num=cost, name=BU.getBuildName(self.bid)}), {callback=Handler(self.onAccBuild, self, true)}))
        else
            local context = self.context
            if context:getRes(const.ResCrystal)<cost then
                display.showDialog(AlertDialog.new({ctype=const.ResCrystal, cvalue=cost}))
            else
                self.context.buildData:accBuild(self, stime, cost)
                self:upgradeOver(stime)
                return true
            end
        end
    end
    return false
end

function Build:getNextData()
    return SData.getData("bdatas", self.bsetting.bdid, self.level+1)
end

function Build:onBeginUpgradeArmor(level)
    if level and type(level) == "number" and level < (self.armor or 0) then
        return
    end
    local costData = SData.getData("armors", self.bsetting.bdid, (self.armor or 0)+1)
    if costData.needLevel>self.level then
        display.pushNotice(Localizef("noticeNeedLevel2",{name=BU.getBuildName(self.bid), level=costData.needLevel}))
    elseif costData.cvalue>self.context:getRes(const.ResZhanhun) then
        display.showDialog(AlertDialog.new({ctype=const.ResZhanhun, cvalue=costData.cvalue,callback=Handler(self.onBeginUpgradeArmor,self,level)}))
    else
        self.context.buildData:upgradeBuildArmor(self, costData.cvalue)
        self:reloadArmor()
        if self.vstate.focus then
            self:runFocusAnimate(true)
            BU.showBuildMenu(self)
        end
        display.closeDialog()
    end
end

--这里是建筑的事件
function Build:onInit(initTime)
end
function Build:onReload()
end
function Build:onRemove()
end
function Build:onGridSeted()
end

function Build:ctor(bid, level)
    if not level then level=1 end
    local bsetting = BU.getBSetting(bid)
    if not bsetting then
        log.e(string.format("This bid:%d is not exist",bid))
        return
    end

    self.bid = bid
    self.level = level
    self.bsetting = bsetting
    self.info = SData.getData("binfos",bsetting.bdid)
    if level<=0 then
        self.data = SData.getData("bdatas",bsetting.bdid,1)
        self.level = 0
    else
        if bsetting.numAsLevel then
            if level > self.info.maxNum then
                level = self.info.maxNum
                self.level = level
            end
        elseif level > self.info.maxLv then
            level = self.info.maxLv
            self.level = level
        end
        self.data = SData.getData("bdatas",bsetting.bdid,level)
    end
    if not self.data then
        GameLogic.otherGlobalInfo = {"bdatas", bsetting.bdid, level}
    end
    BU.loadExtPlugins(self)
end

local function updateBuff(self, diff)
    BuffUtil.updateBuff(self, diff)
end

function Build:addToScene(scene, gix, giy)
    if self.onSpecialAdd and self:onSpecialAdd(scene, gix, giy) then
        return
    end
    if scene.sceneType ~= "operation" then
        local stime = scene.startTime or GameLogic.getSTime()
        if self:isStatue() and self.extData and self.extData[2] < stime then
            self.deleted = true
            return
        end
    end
    local gsize = self.info.size
    local map = scene.map
    if self.level == 0 and not self.worklist then
        self.level = 1
    end
    if self.armor and self.armor>0 and self.info.maxArmor then
        if self.armor > self.info.maxArmor then
            self.armor = self.info.maxArmor
        end
    else
        self.armor = nil
    end
    if not self.context and scene.context then
        self.context = scene.context
    end
    local vstate = {bid=self.bsetting.bvid,bottomState=-1, focus=false, scene=scene,gsize=gsize,view=ui.node({map.gsizeX*gsize,map.gsizeY*gsize}),gx=gix,gy=giy}
    if vstate.bid==const.Town and scene.battleType==const.BattleTypePvc then
        vstate.bid = BU.getBSetting(const.ArenaBase).bvid
    end
    --主城换僵尸主城
    if vstate.bid==1 and (scene.battleType==const.BattleTypePve or scene.battleType==const.BattleTypeUPve) then
        vstate.bid = 21
    end
    --建造者小屋换僵尸建筑
    if vstate.bid==10 and scene.battleType==const.BattleTypePve then
        local random=19
        if math.random(2)>1 then
            random=20
        end
        vstate.bid = random
    end
    if scene.sceneType == "visit" or self.info.btype == 6 then
        vstate.movable = false
    else
        vstate.movable = true
    end
    self.vstate = vstate
    display.adapt(vstate.view, 0, 0, GConst.Anchor.Bottom)
    vstate.upNode = ui.node({map.gsizeX*gsize,map.gsizeY*gsize})
    display.adapt(vstate.upNode, 0, 0, GConst.Anchor.Bottom)
    self:reloadView()
    scene.allobjs[self] = 1
    self.removed = nil
    self.deleted = nil
    --BattleLogic.addBuild(self, self.isDefence)
    if self.bstate then
        self:setFocus(true)
        vstate.moveOk = self:moveAndCheck(gix, giy, true)
        self:moveGrid(gix, giy, scene.map.maxZ)
        BU.reuseBuyButs(self)
        self.bstate[2][1]:setGray(not vstate.moveOk)
    else
        vstate.moveOk = true
        self:resetGrid()
        self:onReload()
        if scene.sceneType=="battle" then
            self.view = self.vstate.view
            self.scene = self.vstate.scene
            if not self.data then
                GameLogic.otherGlobalInfo = {"bdata_error", self.bid, self.bsetting.bdid, self.level}
            end
            self.params = {id=self.bid, level=self.level, utype=1, speed=0, hp=self.data.hp, aspeed=0, range=0, drange=0, atk=0}
            if self.armor and self.armor>0 then
                local avalue = SData.getData("armors", self.bsetting.bdid, self.armor)
                if not avalue then
                    GameLogic.otherGlobalInfo = {"barmor_error", self.bid, self.bsetting.bdid, self.armor}
                end
                self.params.armor = avalue.armor
            end
            if self.info.btype < 4 then
                self.update = updateBuff
            else
                self.update = nil
            end

            self.BV = {}
            self.BV.gx = self.vstate.gx + self.vstate.gsize / 2
            self.BV.gy = self.vstate.gy + self.vstate.gsize / 2
            self.BV.gsize = self.vstate.gsize / 2 - self.vstate.edge / 10
            self.BV.px = self.vstate.view:getPositionX()
            self.BV.py = self.vstate.view:getPositionY() + self.vconfig.y + self.vconfig.h/2

            if self.readyToBattle then
                self:readyToBattle()
            end

            local setting = self.context:getBattleBuff()
            local defBuff = scene.battleData.preDefBuffs
            if self.params.hp then
                --计算加血
                local hpAns = 1 + (defBuff and defBuff.hpPct or 0)
                if self.params.atk and self.params.atk > 0 then
                    hpAns = hpAns + (defBuff and defBuff.defBuildHp or 0)
                end
                if setting then
                    hpAns = hpAns * (1 + (setting.hpPct or 0))
                end
                self.params.hp = self.params.hp * hpAns
            end
            if self.params.atk and self.params.atk > 0 then
                local atkAns = 1 + (defBuff and defBuff.atkPct or 0) + (defBuff and defBuff.defBuildAtk or 0)
                if setting then
                    atkAns = atkAns * (1 + (setting.atkPct or 0))
                end
                self.params.atk = self.params.atk * atkAns
            end
            self.params.defenseParam = (self.params.defenseParam or 1) * (defBuff and defBuff.defenceParam or 1)

            --更新buff
            if self.update then
                self.vstate.scene.replay:addUpdateObj(self)
            end
            self.allBuff = {}
            self.cantAddBuff = {}
            self.avtInfo = AvtInfo.new({person=self.params},self)
            self.M = self.avtInfo
            self.avtInfo.ptype = 3
            scene.battleData:addObj(self)
        elseif scene.sceneType=="prepare" then
            if self.readyToBattle then
                self:readyToBattle()
            end
        elseif scene.sceneType == "visit" then
            self:readyToVisit()
        elseif self.updateOperation then
            vstate.scene:addOperationUpdate(vstate.view, Handler(self.updateOperation, self))
        end
    end

    --加建造者
    local scene = self.vstate.scene
    if (scene.sceneType == "operation" or scene.sceneType == "visit") and self.worklist and not self.vstate.builder and not BU.getPlanDelegate() then
        self.vstate.builder = PersonUtil.C({sid =1, target = self, state=AvtControlerState.BUILDER, group=1})
        self.vstate.builder:addToScene(scene)
    end
end

function Build:readyToVisit()
    local vstate = self.vstate
    if self.updateOperation then
        vstate.scene:addOperationUpdate(vstate.view, Handler(self.updateOperation, self))
    end
end

function Build:damage(atk,damager)
    if self.deleted then
        return
    end
    local vstate = self.vstate
    local scene = vstate.scene
    --print('受到伤害：',value)
    -- print('攻击力',self.avtInfo.atk)
    -- print('移速：',self.avtInfo.moveSpeed)
    local flag, dv = self.avtInfo:damage(atk)

    if flag ==1 and self.avtInfo.bossIdx then
        scene.battleData.bossDamageValue = scene.menu.battleData.bossDamageValue+dv
    end
    if flag==1 and scene.battleType == 8 then
        if self.bid ~= 50 then
            scene.battleData.allNowHp = scene.battleData.allNowHp-dv
        end
    end

    --主城护盾消失时伤害 GouDa天神技能
    if self.bid == 1 then
        if flag == 2 then
            if self.M.nowHp2<=0 then
                if self.allBuff.GoudaGodSkill2 then
                    local ps = self.allBuff.GoudaGodSkill2.ps
                    local ret = self.battleMap:getCircleTarget(self,self.battleMap.battlerAll,5)
                    if self.forBaoZaEffect then
                        self.forBaoZaEffect:removeFromParent(true)
                        self.forBaoZaEffect=nil
                    end
                    local x,y = self:getCenterPoint()
                    ZhuchengBaozha.new(self.view,x,y,0)
                    for k,v in pairs(ret) do
                        local value = v.M.base_hp*ps.z/100
                        SkillPlugin.exe2(self,v,value)
                        BuffUtil.setBuff(v,{lastedTime=ps.t, bfDizziness=ps.t})
                    end
                end
            end
        end
    end
    --加血显示
    if dv<0 then
        self:showHurtPerformance(math.floor(-dv), 2)
    end

    if self.showEffect then
        self:showEffect()
    end
    --self.avater:damage(self.avtInfo.nowHp,self.avtInfo.maxHp)

    if not vstate.blood then
        local mode
        if self.group==1 then
            mode = ProgressBarMode.BUILD_MY
        else
            mode = ProgressBarMode.BUILD_HE
        end
        vstate.blood = ProgressBar.new(mode,self.avtInfo.maxHp)
        display.adapt(vstate.blood, self.vstate.view:getContentSize().width/2, 100+self:getHeight(), GConst.Anchor.Bottom)
        vstate.upNode:addChild(vstate.blood.view,100)
        --self.vstate.view:addChild(self.blood,100)
        if self.avtInfo.nowHp2 and self.avtInfo.nowHp2>0 then
            vstate.blood:addHpBar(self.avtInfo.nowHp,self.avtInfo.nowHp2)
        end
    end
    if flag == 1 then
        vstate.blood:changeValue(self.avtInfo.nowHp)
    else
        vstate.blood:changeValue(self.avtInfo.nowHp2)
        if self.avtInfo.nowHp2<=0 then
            self.vstate.armorDestroyed = true
            self:reloadArmor()
        end
    end
    if self.avtInfo.nowHp<=0 then
        --血光之书
        if damager and damager.bloodBook and not damager.deleted then
            damager.bloodBook:exe(self)
        end
        self.deleted = true
        self.vstate.scene.battleData:destroyObj(self)
        self.vstate.scene.replay:removeUpdateObj(self)
        if self.bid==const.Town then
            self.vstate.scene.scroll:getScrollNode():runAction(ActionShake:create(0.5, 40, 30))
        end
        self:runBombAnimation()
        BuffUtil.removeAllBuffComponents(self)
        self:setDestroyedView()
        if self.dieEvent then
            self:dieEvent()
        end
        return true
    end
end

function Build:resetBlood()
    local vstate = self.vstate
    if vstate.blood then
        vstate.blood:removeFromParent(true)
        local mode
        if self.group==1 then
            mode = ProgressBarMode.BUILD_MY
        else
            mode = ProgressBarMode.BUILD_HE
        end
        vstate.blood = ProgressBar.new(mode,self.avtInfo.maxHp)
        display.adapt(vstate.blood, self.vstate.view:getContentSize().width/2, 100+self:getHeight(), GConst.Anchor.Bottom)
        vstate.upNode:addChild(vstate.blood.view,100)
        --self.vstate.view:addChild(self.blood,100)
        if self.avtInfo.nowHp2 and self.avtInfo.nowHp2>0 then
            vstate.blood:addHpBar(self.avtInfo.nowHp,self.avtInfo.nowHp2)
        end
    end
end

function Build:setDestroyedView()
    local vstate = self.vstate
    vstate.destroyed = true
    vstate.view:stopAllActions()
    vstate.view:removeAllChildren(true)
    vstate.buildingViews = nil
    vstate.build = nil
    self:reloadView(true)
    self:moveGrid(vstate.bgx, vstate.bgy)
    if vstate.blood then
        vstate.blood:removeFromParent(true)
        vstate.blood = nil
    end
    if vstate.upNode then
        vstate.upNode:removeAllChildren(true)
    end
end

function Build:runBombAnimation()
    local vstate = self.vstate
    local vconfig = self.vconfig
    local bomb = LogicEffects.Bomb
    bomb:runAnimation(vstate.upNode:getParent(), vstate.cpx, vstate.cpy, vstate.gsize, math.floor(vstate.cpx*4096+vstate.cpy+self.id), vstate.gsize*3+1, vconfig.btFlag)
end

function Build:removeFromScene()
    local vstate = self.vstate
    if not vstate then return end
    --去掉建造者
    if vstate.builder then
        vstate.builder:removeFromScene()
        vstate.builder = nil
    end
    local scene = vstate.scene
    self.view = nil
    scene.allobjs[self] = nil
    if self.onClean then
        self:onClean()
    end
    if self.bstate then
        if self.bstate[2] then
            self.bstate[2][1]:removeFromParent(true)
            self.bstate[2][2]:removeFromParent(true)
            self.bstate[2] = nil
        end
        self.bstate = nil
    end
    if scene and vstate.view then
        scene:removeOperationUpdate(vstate.view)
        if vstate.focus then
            self:setFocus(false)
        end
        self.initGrid = {vstate.bgx, vstate.bgy}
        self:clearGridUse(vstate.bgx, vstate.bgy)
        vstate.bgx = nil
        vstate.bgy = nil
        if vstate.shadow then
            vstate.shadow:removeFromParent(true)
            vstate.shadow = nil
        end
        if vstate.effectShadow then
            vstate.effectShadow:removeFromParent(true)
            vstate.effectShadow = nil
        end
        if vstate.bottom then
            vstate.bottom:removeFromParent(true)
            vstate.bottom = nil
        end
        if vstate.money then
            vstate.money:removeFromParent(true)
            vstate.money = nil
        end
        vstate.bottomState = -1
        vstate.view:removeFromParent(true)
        vstate.view = nil
        if vstate.upNode then
            vstate.upNode:removeFromParent(true)
            vstate.upNode = nil
        end

        vstate.armor = nil
        vstate.alv = nil
        vstate.upIcon = nil
        vstate.upBack = nil
        vstate.blood = nil
    end
    self.vstate = nil
    self.removed = true
    self.deleted = true

    --去掉战斗中的属性
    self.avtInfo = nil
    self.target = nil
    self.coldTime = nil
    GameEvent.unregisterAllEvents(self)
end

function Build:addBuildView(bg, cx, cy, cw, ch, vs,viewid)
    local vconfig = self.vconfig
    local bid = viewid or self.bsetting.bvid
    local blv = self.level
    if blv==0 then
        blv = 1
        vconfig = nil
    end
    if not vconfig then
        vconfig = BU.loadBuildConfig(bid, blv)
    end
    local tvstate = {view=bg, bid=bid, level=blv}
    self.tvstate=tvstate
    local bview, bviews = _addBuildView(tvstate, vconfig)
    local vx = vconfig.vx or 0
    local vy = vconfig.vy or 0
    local vw, vh = vconfig.w, vconfig.h-vy - (vconfig.vh or 0)
    if ch/vh<vs then
        vs = ch/vh
    end
    if cw/vw<vs then
        vs = cw/vw
    end
    --bview:setScale(vs*2)
    bview:setScale(vs)
    bview:setPosition(cx+vx*vs, cy-(vh/2+vy)*vs)
end

function Build:getHp()
    return self.hp or self.data.hp
end

function Build:getHeight()
    local vconfig = self.vconfig
    local h = (vconfig.y or 0)+vconfig.h
    return h
end

--根据金币数量添加金库，金矿对应的金币图片
function Build:addMoneyView(number)
    local vstate = self.vstate
    if not vstate.view then
        return
    end
    local vconfig = self.vconfig
    local bid = self.bsetting.bvid
    local blv = self.level
    if blv==0 then
        return
    end
    if vconfig.maxLv and blv>vconfig.maxLv then
        blv = vconfig.maxLv
    end

    local temp
    if bid==11 then--金矿
        local img_i=1
        if number<=0.3 then     --少
            img_i=1
        elseif number<=0.6 then --中
            img_i=2
        else                    --多
            img_i=3
        end
        if not vstate.money then
            temp=ui.sprite("images/build11k_"..img_i..".png")
            display.adapt(temp, vstate.build:getContentSize().width/2, 0, GConst.Anchor.Bottom)
            self.vstate.build:addChild(temp,-1)
            vstate.money=temp
        else
            vstate.money:removeFromParent(true)
            temp=ui.sprite("images/build11k_"..img_i..".png")
            display.adapt(temp, vstate.build:getContentSize().width/2, 0, GConst.Anchor.Bottom)
            self.vstate.build:addChild(temp,-1)
            vstate.money=temp
        end
    elseif bid==12 then--金库
        local imgs={[1]={"build12m_0102_"},[2]={"build12m_0102_"},[3]={"build12m_0304_"},[4]={"build12m_0304_"},[5]={"build12m_0005_"},
                    [6]={"build12m_0607_"},[7]={"build12m_0607_"},[8]={"build12m_0809_"},[9]={"build12m_0809_"},[10]={"build12m_0010_"},
                    [11]={"build12m_1113_"},[12]={"build12m_1113_"},[13]={"build12m_1113_"},[14]={"build12m_1415_"},[15]={"build12m_1415_"},[16]={"build12m_0016_"}}
        local img=imgs[blv][1]
        local img_i=1
        if number==0 then
             img_i=0
        elseif number<=0.25 then
            img_i=1
        elseif number<=0.5 then
            img_i=2
        elseif number<=0.75 then
            img_i=3
        else
            img_i=4
        end
        if img_i==0 then
            if vstate.money then
                vstate.money:removeFromParent(true)
                vstate.money=nil
            end
            return
        end
        if not vstate.money then
            temp=ui.sprite("images/"..img..img_i..".png")
            display.adapt(temp,vstate.build:getContentSize().width/2,0, GConst.Anchor.Bottom)
            self.vstate.build:addChild(temp,2)
            vstate.money=temp
        else
            vstate.money:removeFromParent(true)
            temp=ui.sprite("images/"..img..img_i..".png")
            display.adapt(temp,vstate.build:getContentSize().width/2, 0, GConst.Anchor.Bottom)
            self.vstate.build:addChild(temp,2)
            vstate.money=temp
        end
    end
end

function Build:showHurtPerformance(s, ftype)
    if self.vstate and self.vstate.upNode then
        local effect = LogicEffects.SPFont
        local x, y = self.vstate.view:getPosition()
        y = y + 80 + self:getHeight()

        effect:runAnimation(self.vstate.scene.upNode, x, y, s, ftype)
    end
end

function Build:isStatue()
    return false
end

function Build:addDefBuff(defBuff)

end

function Build:addAtkBuff(atkBuff)

end

function Build:getDamagePoint()
    local tx,ty = self.view:getPosition()
    ty = ty+self.view:getContentSize().height/2
    local tz = General.sceneHeight-ty
    return tx,ty,tz
end

function Build:getCenterPoint()
    local size= self.view:getContentSize()
    local x,y = size.width/2,size.height/2
    return x,y
end

--得到debug replay 的tag

function Build:getTag()
    local tag = self.group .. "_" .. self.bid .. "_" .. self.vstate.gx .. self.vstate.gy
    return tag
end

local Tomb = class()

function Tomb:movePosition(px, py)
    local parent = self.view:getParent()
    if parent then
        parent:reorderChild(self.view, 10)
    else
        self.scene.objs:addChild(self.view, 10)
    end
    self.view:setPosition(px, py)
end

function Tomb:resetGridUse(backGrid, newGrid)
    local mapGrid = self.scene.map
    if backGrid then
        mapGrid.clearGridUse(backGrid[1], backGrid[2], 1)
    end
    if newGrid then
        mapGrid.setGridUse(newGrid[1], newGrid[2], 1)
    end
end

function Tomb:resetGrid()
    local scene = self.scene
    local grid = self.initSetting
    local px, py = scene.map.convertToPosition(grid[1], grid[2])
    self:movePosition(px, py)
    self:resetGridUse(nil, grid)
end

function Tomb:removeFromScene()
    self.view:removeFromParent(true)
    self:resetGridUse(self.initSetting, nil)
    self.deleted = true
end

function Tomb:ctor(gx, gy)
    self.initSetting = {gx, gy}
end

function Tomb:addToScene(scene)
    local bg = ui.node(nil,{scene.map.gsizeX,scene.map.gsizeY})
    display.adapt(bg, 0, 0, GConst.Anchor.Bottom)
    self.view = bg
    self.scene=scene
    self.deleted = true

    self.build = ui.sprite("images/buildTomb.png")
    --self.build:setScale(2)
    display.adapt(self.build, scene.map.gsizeX/2, 0, GConst.Anchor.Bottom)
    self.view:addChild(self.build)

    self:resetGrid()
end

GEngine.export("Build",Build)
GEngine.export("BU",BU)
GEngine.export("Tomb",Tomb)
return Build
