local _modelCache
local _buildConfigCache
local _bidGroupCache
local _bidSettings
local _bdidmap, _bvidmap
local _buildMenuSettings

local log = _G["log"]
local GMethod = _G["GMethod"]

local BU = {}
local SData = GMethod.loadScript("data.StaticData")
local const = GMethod.loadScript("game.GameLogic.Const")
local buildLevelsConfig = GMethod.loadScript("data.AllConfig").buildLevelsConfig
--首先是所有配置加载相关的代码放在此处

--加载某些模板的配置
function BU.getModelConfig(mtype, k)
    if type(k)=="table" then
        return k
    end
    if mtype then
        local _mtypes = _modelCache[mtype]
        if _mtypes and k then
            return _mtypes[k]
        end
    end
    return nil
end

--加载建筑的视图的配置
function BU.loadBuildConfig(bid, level, gsize)
    local rbid = bid
    local useGroup = false
    if _bidGroupCache[bid] then
        bid = _bidGroupCache[bid]
        useGroup = true
    end
    local vconfig = _buildConfigCache[bid]
    if not vconfig then
        vconfig = GMethod.loadConfig("configs/builds/" .. bid .. ".json")
        if not vconfig then
            log.e("Not find config with bid:%d, blevel:%d",bid,level)
        end
        _buildConfigCache[bid] = vconfig
        local vmtable = {__index=vconfig}
        if vconfig.levels then
            for lv, vl in pairs(vconfig.levels) do
                setmetatable(vl, vmtable)
            end
        end
        if vconfig.bids then
            for _, vl in pairs(vconfig.bids) do
                setmetatable(vl, vmtable)
            end
        end
    end
    local vlconfig
    if useGroup and vconfig.bids then
        vlconfig = vconfig.bids[rbid]
    elseif not vconfig.levels then
        if level==0 then
            vlconfig = BU.getModelConfig("init",gsize)
        else
            vlconfig = vconfig
        end
    else
        if buildLevelsConfig and buildLevelsConfig[bid] and buildLevelsConfig[bid][level] then
            level=buildLevelsConfig[bid][level]
        else
            if vconfig.maxLv and level>vconfig.maxLv then
                level = vconfig.maxLv
            end
        end
        vlconfig = vconfig.levels[level]
        if not vlconfig and level==0 then
            vlconfig= BU.getModelConfig("init",gsize)
        end
        if not vlconfig then
            local realLv
            for i=level-1,1,-1 do
                if vconfig.levels[i] then
                    vlconfig = vconfig.levels[i]
                    realLv = i
                    break
                end
            end
            for j=realLv, level do
                vconfig.levels[j] = vlconfig
            end
        end
    end
    return vlconfig
end

--重新从文件加载所有模板和建筑分组信息
function BU.reloadConfigs()
    _modelCache = {}
    _buildConfigCache = {}
    _bidGroupCache = {}
    
    local models = GMethod.loadConfig("configs/builds/models.json")
    for k, v in pairs(models) do
        _modelCache[k] = v
    end
    local groups = GMethod.loadConfig("configs/builds/groups.json")
    if groups then
        for gid, bids in pairs(groups) do
            for _, bid in ipairs(bids) do
                if type(bid)=="table" then
                    for tbid=bid[1],bid[2] do
                        _bidGroupCache[tbid] = gid
                    end
                else
                    _bidGroupCache[bid] = gid
                end
            end
        end
    end
    _bidSettings = GMethod.loadConfig("configs/builds/builds.json")
    _bdidmap = {}
    _bvidmap = {}
    for bid, setting in pairs(_bidSettings) do
        if setting.group then
            local group = _bidSettings[setting.group]
            if group then
                local gmeta = group.meta
                if not gmeta then
                    gmeta = {__index=group}
                    group.meta = gmeta
                end
                setmetatable(setting, gmeta)
            end
        end
        if setting.bdid then
            _bdidmap[setting.bdid] = bid
        end
        if setting.bvid then
            _bvidmap[setting.bvid] = bid
        end
    end
    _buildMenuSettings = GMethod.loadConfig("configs/builds/bmenus.json")
end

function BU.getBSetting(bid)
    return _bidSettings[bid]
end

function BU.getBidByDid(bdid)
    return _bdidmap[bdid]
end

function BU.getBidByVid(bvid)
    return _bvidmap[bdid]
end

BU.reloadConfigs()

--下面是建筑的一些字符串有关方法
local localize = StringManager.getString
local localizef = StringManager.getFormatString
function BU.getBuildName(bid,suffix)
    if suffix then
        return localize("dataBuildName" .. _bidSettings[bid].bdid.. "_" .. suffix)
    else
        return localize("dataBuildName" .. _bidSettings[bid].bdid)
    end
end

function BU.getBuildInfo(bid,suffix, params)
    if params then 
        if suffix then
            return localizef("dataBuildInfo" .. _bidSettings[bid].bdid.. "_" .. suffix, params)
        else
            return localizef("dataBuildInfo" .. _bidSettings[bid].bdid, params)
        end
    else
        if suffix then
            return localize("dataBuildInfo" .. _bidSettings[bid].bdid.. "_" .. suffix)
        else
            return localize("dataBuildInfo" .. _bidSettings[bid].bdid)
        end
    end
end

function BU.getBuildTitle(build)
    if build:isStatue() then
        return BU.getBuildName(build.bid, build.level)
    end
    local name = BU.getBuildName(build.bid)
    if build.level then
        if build.level==0 then
            if build.worklist then
                name = localizef("titleBuilding", {name=name})
            else
                name = localizef("titleRuin", {name=name})
            end
        elseif build.info and build.info.maxLv>1 then
            name = localizef("titleWithLevel", {name=name, level=build.level})
        end
    end
    return name
end

local SginExtPlugin = {
    [21] = "game.Build.Defences.Connon",
    [22] = "game.Build.Defences.Hwtw",
    [23] = "game.Build.Defences.Mortar",
    [24] = "game.Build.Defences.Patriot",
    [25] = "game.Build.Defences.Storm",
    [26] = "game.Build.Defences.Pylon",
    [27] = "game.Build.Defences.MachineGun",
    [28] = "game.Build.Defences.IonTwer",    
}
GEngine.lockG(false)
for k,v in pairs(SginExtPlugin) do
    GMethod.loadScript(v)
end
GEngine.lockG(true)

--下面是一些装载其他配置的方法
function BU.loadExtPlugins(build)
    local bsetting = build.bsetting
    if bsetting.extPlugin then
        build.extSetting = bsetting.extSetting

        local plugin = GMethod.loadScript(bsetting.extPlugin)

        for k, f in pairs(plugin) do
            build[k] = f
        end

        if bsetting.extPlugin == "game.Build.Defences.DefencePlugin" then
            local extPlugin = SginExtPlugin[build.bid]
            local plugin = GMethod.loadScript(extPlugin)

            for k, f in pairs(plugin) do
                build[k] = f
            end
        end
    end
end

--下面是一些通用建筑逻辑复用的情况
local _pt, _pts = nil, {}
local _circle
local _yesBut, _noBut

function BU.reusePts(build)
    if not _pt then
        _pt = ui.node()
        _pt:retain()
        for i=1, 4 do
            _pts[i] = ui.sprite("images/buildDownPt" .. i .. ".png")
            _pt:addChild(_pts[i])
        end
    else
        _pt:removeFromParent(false)
    end

    local vstate = build.vstate
    local view = vstate.view
    if vstate.upNode then
        view=vstate.upNode
    end
    local ssize = view:getContentSize()
    display.adapt(_pt, ssize.width/2, ssize.height/2, GConst.Anchor.Center)
    view:addChild(_pt, -2)
    vstate.pt = _pt
    vstate.pts = _pts
    return _pt, _pts
end

function BU.recoveryPts(build)
    local vstate = build.vstate
    vstate.pt = nil
    vstate.pts = nil
    if _pt then
        _pt:removeFromParent(false)
    end
end

function BU.showBuildName(build)
    if GMethod.loadScript("game.View.Scene").sceneType=="prepare" then
        return
    end
    --雕像不显示名字
    if (not build.vstate.rankName) and build.vstate.upNode and not build.bstate then
        if build.vstate.buildName then
            build.vstate.buildName:removeFromParent(true)
            build.vstate.buildName=nil
        end
        local hy=0
        if build.vstate.wprocess then
            hy=build.vstate.wprocess.view:getPositionY()-build.vstate.view:getContentSize().height+100
        elseif build.vstate.bprocess then
            hy=80
        elseif build.vstate.bid==70 then
            hy=90
        end
        local blView=ui.node()
        display.adapt(blView, build.vstate.view:getContentSize().width/2, build:getHeight()+hy, GConst.Anchor.Center)
        build.vstate.upNode:addChild(blView)
        build.vstate.buildName=blView
        local maxLv=build.vconfig.maxLv
        local oy=0
        if not maxLv or maxLv<=1 then
            oy=-60
        end
        local bName=ui.label(BU.getBuildName(build.bid),General.font1, 56, {color={255,255,255}})
        display.adapt(bName, 0, 120+oy, GConst.Anchor.Center)
        blView:addChild(bName)
        bName:setGlobalZOrder(2)

        if oy==0 then
            local bLv=ui.label("Lv."..build.level,General.font1, 47, {color={194,235,85}})
            display.adapt(bLv, 0, 54, GConst.Anchor.Center)
            blView:addChild(bLv)
            bLv:setGlobalZOrder(2)
        end
    end
end

function BU.recoveryBuildName(build)
    local vstate = build.vstate
    if GameLogic.isEmptyTable(vstate) then 
        return
    end
    if vstate.buildName then
        vstate.buildName:removeFromParent(true)
        vstate.buildName = nil
    end
end

function BU.reuseCircle(build)
    if not _circle then
        _circle = CaeShaderNode:create("circle", cc.size(0,0))
        --_circle:setAnchorPoint(GConst.Anchor.Center)
        _circle:setAnchorPoint(cc.p(0.5,0.5))
        _circle:retain()
        _circle:setColor(cc.c3b(255,255,255))
    else
        _circle:stopAllActions()
        _circle:removeFromParent(false)
    end
    local binfo = build.info
    local r1, r2 = binfo.maxRange or 0, binfo.minRange or 0
    local tr = r1 * 0.1414
    local vstate = build.vstate
    local map = vstate.scene.map
    _circle:setContentSize(cc.size(map.gsizeX*tr, map.gsizeY*tr))
    _circle:setShaderUniform4f(8/r1,r2/r1,1/r1 ,0)
    if vstate.cpx then
        _circle:setPosition(vstate.cpx, vstate.cpy)
    end
    vstate.scene.objs:addChild(_circle, map.minZ-1)
    vstate.circle = _circle
    _circle:setScale(0.5)
    _circle:setOpacity(0)
    _circle:runAction(ui.action.sequence({{"scaleTo",0.15,1.1,1.1},{"scaleTo",0.15,1,1}}))
    _circle:runAction(ui.action.fadeTo(0.2, 200))
    return _circle
end

function BU.recoveryCircle(build)
    local vstate = build.vstate
    if vstate.circle and _circle then
        _circle:stopAllActions()
        _circle:runAction(ui.action.sequence({{"fadeTo",0.2,0},{"remove",false}}))
        vstate.circle = nil
    end
end

function BU.reuseBuyButs(build)
    if not _yesBut then
        _yesBut = ui.button({92,95},nil,{image="images/buildUpBtn1.png"})
        _yesBut:retain()
        _yesBut:setTouchThrowProperty(true, false)
        _noBut = ui.button({92,95},nil,{image="images/buildUpBtn2.png"})
        _noBut:retain()
        _noBut:setTouchThrowProperty(true, false)
    else
        _yesBut:removeFromParent(false)
        _noBut:removeFromParent(false)
    end
    _yesBut:setScriptCallback(ButtonHandler(build.onBuy, build, true))
    _noBut:setScriptCallback(ButtonHandler(build.onBuy, build, false))

    --引导
    local context = GameLogic.getUserContext()
    local isGuide = false
    if context.guide:getStep().type == "buyBuild" then
        isGuide = true
    end
    
    local vstate, bstate = build.vstate, build.bstate
    if not bstate[2] then
        bstate[2] = {0,0}
    end
    local view = vstate.upNode
    local scx = view:getContentSize().width/2
    local vc = build.vconfig
    local butY = (vc.y or 0)+vc.h+60
    display.adapt(_yesBut, scx+88, butY, GConst.Anchor.Center)
    view:addChild(_yesBut, 10)
    bstate[2][1] = _yesBut
    display.adapt(_noBut, scx-88, butY, GConst.Anchor.Center)
    view:addChild(_noBut, 10)
    bstate[2][2] = _noBut
    if isGuide then
        context.guideHand:removeHand("buyBuild")
        if not _yesBut.arrow then
            _yesBut.arrow = context.guideHand:showArrow(_yesBut,46,95,0)
        end
    else
        if _yesBut.arrow then
            _yesBut.arrow:removeFromParent(true)
            _yesBut.arrow = nil
        end
    end
end

function BU.recoveryBuyButs(build)
    local vstate, bstate = build.vstate, build.bstate
    if bstate then
        _yesBut:removeFromParent(false)
        _noBut:removeFromParent(false)
        bstate[2][1] = 0
        bstate[2][2] = 0
    end
end

--菜单有关

local _menuVisible = true
local _menuShowed = false

local function _getMenu(scene)
    local cmenu = scene.menu.cmenu
    if not cmenu then
        cmenu = {view=ui.node({1024,256}), buts={}, mbuts={}, dbuts={}}
        scene.menu.cmenu = cmenu
        display.adapt(cmenu.view, 0, 0, GConst.Anchor.Bottom, {scale=ui.getUIScale2()})
        scene.menu.view:addChild(cmenu.view)
        cmenu.title = ui.label("", General.font1, 46, {color={255,255,255}})
    	display.adapt(cmenu.title, 512, 318, GConst.Anchor.Bottom)
    	cmenu.view:addChild(cmenu.title)
    	cmenu.title:setOpacity(0)
        cmenu.title:setGlobalZOrder(2)
    end
    return cmenu
end

local function _showMenu(cmenu)
    if _menuVisible then
        cmenu.title:stopAllActions()
        if #cmenu.dbuts>0 then
            cmenu.title:setVisible(true)
        else
            cmenu.title:setVisible(false)
        end
        cmenu.title:runAction(ui.action.fadeTo(0.2,255))
        for _, but in ipairs(cmenu.mbuts) do
            if but.view:isVisible() then
                but.view:setVisible(false)
                but.view:setEnable(false)
                but.view:stopAllActions()
            end
        end
        cmenu.mbuts = {}
        local bnum = #(cmenu.dbuts)
        local ox = 512-232*(1+bnum)/2
    	local oy = 170
    	local oh = 239
        for i, but in ipairs(cmenu.dbuts) do
            local bn = but.view
            bn:setEnable(true)
    		bn:setVisible(true)
    		bn:setPosition(232*i+ox, oy-oh)
    		bn:setOpacity(0)
    		bn:runAction(ui.action.sequence({{"delay",0.06*(bnum-i)},{"easeBackOut",{"moveBy",0.2,0,oh}}}))
    		bn:runAction(ui.action.sequence({{"delay",0.06*(bnum-i)},{"fadeIn",0.2}}))
    		cmenu.mbuts[i] = but
        end
    end
end

local function _hideMenu(cmenu)
    if _menuVisible then
        cmenu.title:stopAllActions()
        cmenu.title:runAction(ui.action.sequence({{"fadeOut",0.2},"hide"}))
        local oh = 239
        local oy = 170
        for i, but in ipairs(cmenu.mbuts) do
            local bn = but.view
            bn:setEnable(false)
            if bn:isVisible() then
                bn:stopAllActions()
    		    bn:runAction(ui.action.sequence({{"delay",0.04*(i-1)},{"easeBackIn",{"moveBy",0.12,0,-oy}}}))
    		    bn:runAction(ui.action.sequence({{"delay",0.04*(i-1)},{"fadeTo",0.06,204},{"fadeTo",0.06,0},"hide"}))
            end
        end
    end
end

local function _addBUIViews(node, tb, setting)
    if setting.views then
        if not tb.views then
            tb.views = {}
        end
        for _, vs in ipairs(setting.views) do
            local view
            if vs.type=="icon" then
                view = {icon=vs.icon, view=GameUI.addResourceIcon(node, vs.icon, vs.scale or 1, vs.x or 101, vs.y), setting=vs}
            else
                if vs.type=="image" then
                    view = ui.sprite(vs.image)
                    view:setFlippedX(vs.fx or false)
                    view:setFlippedY(vs.fy or false)
                elseif vs.type=="label" then
                    local setting={color=vs.color or GConst.Color.White}
                    --if vs.fontW and vs.fontH then
                        setting.fontW=vs.fontW or 180
                        setting.fontH=vs.fontH or 100
                    --end
                    view = ui.label(vs.text or "", General[vs.font], vs.size, setting)
                    view:setGlobalZOrder(2)
                end
                view:setScale(vs.scale or 1)
                local anchor = GConst.Anchor.Center
                if vs.anchor then
                    anchor = GConst.Anchor[vs.anchor]
                end
                display.adapt(view, 101+(vs.x or 0), vs.y or 0, anchor)
                node:addChild(view, vs.z or 0)
            end
            if vs.id then
                tb.views[vs.id] = view
            end
        end
    end
    local mode = setting.mode
    if mode then
        local msetting = _buildMenuSettings[mode]
        if msetting then
            _addBUIViews(node, tb, msetting)
        end
    end
end

local _planDelegate = nil
local _hvhMenus = nil
function BU.setPlanDelegate(delegate)
    _planDelegate = delegate
end

function BU.getPlanDelegate()
    return _planDelegate
end

function BU.setHvhMenus(menus)
    _hvhMenus = menus
end

function BU.showAccDialog(build)
    local dialog = AccDialog.new(1, build)
    display.showDialog(dialog)
end

function BU.showBuildMenu(build)
    GameEvent.sendEvent("OCItem",false)
    local bsetting = build.bsetting
    local context = GameLogic.getUserContext()
	local buts = {}
    local wl = build.worklist
    local menus = bsetting.menus
    if _planDelegate then
        menus = bsetting.planMenus
    elseif _hvhMenus then
        local temp = {}
        local tempMenu = {}
        for i,v in ipairs(_hvhMenus) do
            temp[v] = true
        end
        for i,v in ipairs(bsetting.menus) do
            if temp[v] then
                table.insert(tempMenu,v)
            end
        end
        menus = tempMenu
    end
    local sgin = false
    local gstep = context.guide:getStep()
    if gstep.type == "finish" then
        sgin = true
    elseif gstep.type == "buyBuild" then
        if build.bid == gstep.id and build.level<1 then
            sgin = true
        end
    elseif context.guide:getStep().type == "upgradeTown" then
        if build.bid == gstep.id then
            sgin = true
        end
    end
	if menus then
	    for _, item in ipairs(menus) do
	        if item=="info" then
                if build.level>=1 then
                    table.insert(buts,{key="info", callback=InfoDialog.show,cp1=build,cp2=1})
                end
	        elseif item=="armor" then
                if sgin then
                    if build.info.maxArmor and not wl then
                        local alv = build.armor or 0
                        if alv<build.info.maxArmor and (alv>0 or SData.getData("armors", build.bsetting.bdid, 1).needLevel<=build.level) then
        	               table.insert(buts,{key="armor", callback=InfoDialog.show, cp1=build, cp2=3})
                        end
                    end
                end
		    elseif item=="upgrade" then
                if sgin then
    		        if wl then
                        local cost = GameLogic.computeCostByTime(wl[4]-GameLogic.getSTime())
                        if gstep.type == "finish" then
                            table.insert(buts, {key="cancel", callback=build.onCancelBuild, cp1=build})
                        end
    		            table.insert(buts, {key="acc", callback=build.onAccBuild, cp1=build,exts={rcost={text=cost}}})
                        if gstep.type == "finish" then
                            table.insert(buts, {key="acc2", callback=BU.showAccDialog, cp1=build})
                        end
                    else
                        if build.level<build.info.maxLv then
                            table.insert(buts, {key="upgrade",callback=InfoDialog.show,cp1=build,cp2=2})
                        end
    		        end
                end
            elseif build.addMenuButs and build.level>0 then
                if gstep.type == "finish" or (gstep.type == "selectHero" and build.bid==gstep.bid) then
                    build:addMenuButs(buts, item)
                end
    		end
	    end
    else
        return
	end
	
	local scene = build.vstate.scene
	local cmenu = _getMenu(scene)
    cmenu.title:setString(BU.getBuildTitle(build))
    
    cmenu.dbuts = {}
    for i, butInfo in ipairs(buts) do
        local but = cmenu.buts[butInfo.key]
        if not but then
            local default = _buildMenuSettings["default"]
            local butSetting = _buildMenuSettings[butInfo.key]
            local back = butInfo.back or butSetting.back or default.back
            but = {sx=default.sx, sy=default.sy, bx=default.ox, views={}, type="button", back=back, view=ui.button({default.sx,default.sy},nil,{image=back})}
            but.view:retain()
            cmenu.buts[butInfo.key] = but
            _addBUIViews(but.view:getDrawNode(), but, butSetting)
            if butSetting.texts then
                for k, v in pairs(butSetting.texts) do
                    but.views[k]:setString(localize(v))
                end
            end
            display.adapt(but.view, 512, -500, GConst.Anchor.Center)
            cmenu.view:addChild(but.view)
            if butInfo.leftTopText then
                GameUI.addCornerSgin(but.view,butInfo.leftTopText,1,45,169)
            end
        end
        if butInfo.callback then
            but.view:setScriptCallback(Script.createCallbackHandler(butInfo.callback, butInfo.cp1, butInfo.cp2))
        else
            but.view:setScriptCallback(nil)
        end
        BU.reloadMenuBut(butInfo, but)
		but.idx = i
		cmenu.dbuts[i] = but

        --引导
        local context = GameLogic.getUserContext()
        local gstep = context.guide:getStep()
        local showBut = false
        if gstep.type == "buyBuild" then
            if build.bid == gstep.id then
                if butInfo.key == "acc" then
                    showBut = true
                end
            end
        elseif gstep.type == "selectHero" then
            if butInfo.key == "select" then
                showBut = true
            end
        elseif gstep.type == "upgradeTown" then
            if build.bid == gstep.id and (butInfo.key == "upgrade" or butInfo.key == "acc") then
                showBut = true
            end
        end
        if not showBut and but.view.guideArrow then
            but.view.guideArrow:removeFromParent(true)
            but.view.guideArrow = nil
        elseif showBut then
            local x = but.view:getContentSize().width/2
            local y = but.view:getContentSize().height
            if not but.view.guideArrow then
                but.view.guideArrow = context.guideHand:showArrow(but.view,x,y,0)
            end
            if context.guide.buyBuildShow and context.guide.buyBuildShow ~= build then
                context.guideHand:removeHand("buyBuild")
                context.guide.buyBuildShow = build
            end
        end

        --其他引导
        local tbidSet = {[15]={2,"league"}, [25]={5,"arena"}, [35]={4,"expedition"}, [45]={6,"challenge"}, [65]={8,"melting"}}
        local step = context.guideOr:getStep()
        local tbid = tbidSet[step] and tbidSet[step][1]
        local butKey = tbidSet[step] and tbidSet[step][2]
        if tbid and tbid == build.bid and butInfo.key == butKey then
            local x = but.view:getContentSize().width/2
            local y = but.view:getContentSize().height/1.5
            if not context.guideHand.handArr["guideOrBuildBtn"] then
                context.guideHand:showHandSmall(but.view,x,y,0,"guideOrBuildBtn")
            end
        end
        if butInfo.key == "select" and context.guideHand.handArr["guideHeroSeleted"]  then
            context.guideHand:removeHand("guideHeroSeleted")
        end
        if not GEngine.getConfig("isHeroBaseGuided"..context.sid..context.uid) and build.level>=3 and butInfo.key == "select" then
            local x = but.view:getContentSize().width/2
            local y = but.view:getContentSize().height/1.5
            context.guideHand:showHandSmall(but.view,x,y,0,"guideHeroSeleted")
        end
    end
    _showMenu(cmenu)
    _menuShowed = true
end

function BU.reloadMenuBut(butInfo, but)
    local bn = but.view
    if butInfo.update~=but.update then
        but.update = butInfo.update
        if butInfo.update then
            butInfo.but = but
            if not but.updateNode then
                but.updateNode = ui.node()
                bn:addChild(but.updateNode)
            end
            RegTimeUpdate(but.updateNode, butInfo.update, 0.2)
        elseif but.updateNode then
            but.updateNode:removeFromParent(true)
            but.updateNode = nil
        end
    end
    local default = _buildMenuSettings["default"]
    local butSetting = _buildMenuSettings[butInfo.key]
    local back = butInfo.back or butSetting.back or default.back
    if back~=but.back then
        bn:setBackgroundImage(back, 0)
        but.back = back
    end
    if butInfo.exts then
        for k, v in pairs(butInfo.exts) do
            local view = but.views[k]
            if view then
                if view.icon then
                    if v.icon and v.icon~=view.icon then
                        view.icon = v.icon
                        local p = view.view:getParent()
                        view.view:removeFromParent(true)
                        view.view = GameUI.addResourceIcon(p, v.icon, view.setting.scale or 1, view.setting.x or 101, view.setting.y)
                    end
                    view = view.view
                elseif v.text then
                    view:setString(localize(v.text))
                end
                local color = v.color or GConst.Color.White
                ui.setColor(view, color)
                view:setOpacity(v.alpha or 255)
            end
        end
    end
end

function BU.hideBuildMenu(build)
    if _menuShowed then
        _hideMenu(_getMenu(build.vstate.scene))
        _menuShowed = false
    end
end

function BU.isShowedBuildMenu()
    return _menuShowed
end

function BU.changeMenuVisible(visible, scene, build)
    if visible ~= _menuVisible then
        if _menuShowed then
            local cmenu = _getMenu(scene)
            if visible then
                _menuVisible = true
                if build then
                    BU.showBuildMenu(build)
                else
                    _showMenu(cmenu)
                end
            else
                _hideMenu(cmenu)
                _menuVisible = false
            end
        else
            _menuVisible = visible
        end
    end
end

--服务端执行脚本的时间，目前只用于神像，统一预设30分钟，后面有需求再单独修改
function BU.inServerCalTime(bid)
    local flag = false
    local nowTime = GameLogic.getSTime()
    if (GameLogic.getWeek() == 1) and (nowTime <= GameLogic.getServerCalTime()) then 
        flag = true
    end
    if not (bid >=181 and bid <= 186) then 
        flag = false
    end
    return flag
end
return BU
