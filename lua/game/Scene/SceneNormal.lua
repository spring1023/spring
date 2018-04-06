local SceneNormal = {state="cleanup", delta=0}

function SceneNormal:updateGround(diff)
    self.delta = self.delta+diff
    if self.delta>5 then
        self.delta = self.delta-5
        for i, item in ipairs(self.anis) do
            if item[1]=="tree" then
                if math.random()>0.33 then
                    --item[2]:runAction(ui.action.sequence({{"easeSineOut",{"skewBy",1.25,1,0}},{"delay",0.1},{"easeSineIn",{"skewBy",1.25,-1,0}}}))
                    item[2]:runAction(ui.action.sequence({{"easeSineOut",{"rotateBy",1.25,5}},{"delay",0.1},{"easeSineIn",{"rotateBy",1.25,-5}}}))
                end
            elseif math.random()>0.75 then
                if item[1]=="obj1" then
                    item[2]:runAction(ui.action.animate(1,"sceneObj1_",{3,4,3,2,1,0,1,2}))
                elseif item[1]=="obj2" then
                    item[2]:setSpriteFrame(memory.getFrame("sceneObj2_1.png"))
                    item[2]:runAction(ui.action.sequence({{"moveBy",1,30,0},{"delay",2},{"moveBy",1,-30,0},{"animate", 0.1, "sceneObj2_",1}}))
                elseif item[1]=="obj3" then
                    item[2]:runAction(ui.action["repeat"](ui.action.animate(0.2, "sceneObj3_", 2),3))
                end
            elseif item[1] == ("light" .. i) then
                if math.random()>0.2 then
                    item[2]:runAction(ui.action.blink(0.15*4, 4))
                end
            end
        end
    end
end

function SceneNormal:loadGround(scene)
    local aniNodes = {}
    self.anis = aniNodes
    local map = scene.map

    local sizeX, sizeY = 4096, 3072
    local smin = display.getScalePolicy(sizeX, sizeY)[GConst.Scale.Big]
    --local smax = 1
    --if smax>4*smin then
    local smax = 4*smin
    --end
    ui.setRectAndScale(scene.scroll, {0,0,sizeX,sizeY}, {smin*1.1, smax, smin, smax*1.1})
    scene.map.initGridSetting(2064, 105, 92, 69, sizeX, sizeY, true)
    scene.map.initGridLimit(1,40)
    scene.map.initGridUse()
    scene.mapView:getView():setPosition(2064,105)
    General.sceneHeight = scene.map.maxZ
    local ground = ui.node({sizeX, sizeY}, true)
    self.view = ground
    RegTimeUpdate(ground, Handler(self.updateGround, self), 0.2)

    local land = ui.spriteBlock("images/background/sceneBg.png", {sizeX, sizeY}, {4,3}, false, true)
    display.adapt(land,0,0)
    ground:addChild(land)
    scene.bgPng = "images/background/sceneBg.png"
    local sprite

    local settings = {{181,638,192,0, 3},{910,2513,185,-5,2},{939,2482,159,10,2},{1492,2899,161,8,3,2},{3448,664,162,-10},{2720,111,147,10},{2705,103,172,-4},{1763,-28,192,0,2},{1681,-66,182,-5,2},{2955,2786,192,0,2},{2888,2736,155,-5,2},{3410,2458,170,3,2},{3438,2355,177,0,2},{3474,2347,143,10,2},{4014,1869,186,-5,2},{4043,1825,200,0,2},{67,828,192,0,3},{44,783,152,-10,3}}
    for _,setting in ipairs(settings) do
        if setting[5] then
            sprite = ui.sprite("sceneTree" .. setting[5] .. ".png")
        else
            sprite = ui.sprite("sceneTree.png")
        end
        sprite:setAnchorPoint(0.51,0.03)
        sprite:setPosition(setting[1], setting[2])
        sprite:setScale(setting[3]/192)
        sprite:setRotation(setting[4])
        ground:addChild(sprite,3072-setting[2])
        table.insert(aniNodes, {"tree", sprite})
    end

    sprite = ui.sprite("sceneObj1_2.png")
    sprite:setAnchorPoint(0.62,1)
    sprite:setPosition(1115, 491)
    ground:addChild(sprite)
    table.insert(aniNodes,{"obj1",sprite})

    settings = {{1021,772},{3096,758},{1050,2347},{3050,2371}}
    for _, setting in ipairs(settings) do
        sprite = ui.sprite("sceneObj2_0.png")
        display.adapt(sprite, setting[1], setting[2], GConst.Anchor.Center)
        ground:addChild(sprite)
        table.insert(aniNodes,{"obj2",sprite})
    end

    sprite = ui.sprite("sceneObj3_1.png")
    display.adapt(sprite,329,2170)
    ground:addChild(sprite)
    table.insert(aniNodes,{"obj3",sprite})
    --{2946,646},
    settings = {{2356,200},{3526,1084},{3826,2022},{2612,2926},{900,2464},{610,2248},{195,1368},{828,612}}
    for _, setting in ipairs(settings) do
        sprite = ui.sprite("sceneLight.png")
        display.adapt(sprite, setting[1], setting[2], GConst.Anchor.Center)
        ground:addChild(sprite,2)
        table.insert(aniNodes,{"light" .. (#aniNodes+1),sprite})
    end
    sprite = ui.animateSprite(0.8, "sceneWater_", 8, {isRepeat=true})
    display.adapt(sprite, 2980, 2633)
    ground:addChild(sprite)
    sprite:setScale(2)

    local p = ui.particle("particles/sceneWave.json")
    p:setScaleX(3)
    p:setScaleY(6)
    p:setRotation(-125)
    p:setPosition(4096+272,-376)
    ground:addChild(p, 1)

    settings = {{5,5,30,-346,2889},{5,5,30,-658,1826},{5,5,30,-667,885},{5,5,30,-595,-184},{5,5,75,1097,3537},{5,5,75,2345,3621},{5,5,75,3460,3556},{5,5,75,4285,3503},{5,6,0,4202,2291},{5,6,90,1164,-149}}
    for _, setting in ipairs(settings) do
        p = ui.particle("particles/sceneFog.json")
        p:setScaleX(setting[1])
        p:setScaleY(setting[2])
        p:setRotation(setting[3])
        p:setPosition(setting[4],setting[5])
        p:setPositionType(cc.POSITION_TYPE_GROUPED)
        ground:addChild(p, 1)
    end
    local config = GMethod.loadConfig("configs/sceneScale.json").SceneNormal
    scene.scroll:moveAndScaleToCenter(smin*config, sizeX/2, sizeY/2,0.5)
    self:initChuansong()
    scene.bottomType = nil
    return self.view
end

function SceneNormal:initChuansong()
	local p = ui.sprite("images/sceneAniDoor1.png")
	p:setPosition(331,2623)
	p:setAnchorPoint(0.5,0.5)
	p:setScaleX(3.2)
	p:setScaleY(3.52)
	self.view:addChild(p)
	ui.setColor(p,30,215,255)
	ui.setBlend(p, 772, 1)
	p:setOpacity(0)
	p:runAction(ui.action.arepeat(ui.action.sequence({{"fadeIn",1.5},{"fadeOut",1.5}})))
	local nd1=ui.node()
	nd1:setPosition(331+14,2623-10)
	nd1:setScaleX(1.5)
	nd1:setScaleY(1.65)
	nd1:setSkewX(10)
	nd1:setSkewY(12)
	nd1:setRotation(10)
	self.view:addChild(nd1)
	p=ui.sprite("images/sceneAniDoor1.png")
	p:setPosition(0,0)
	p:setAnchorPoint(0.5,0.5)

	nd1:addChild(p)
	ui.setBlend(p, 772, 1)
	p:runAction(ui.action.arepeat(ui.action.rotateBy(6,-360)))
	local nd2=ui.node()
	nd2:setPosition(331+14,2623-10)
	nd2:setScaleX(1.5)
	nd2:setScaleY(1.65)
	nd2:setSkewX(10)
	nd2:setSkewY(12)
	nd2:setRotation(10)
	self.view:addChild(nd2)
	p=ui.sprite("images/sceneAniDoor2.png")
	p:setPosition(0,0)
	p:setAnchorPoint(0.5,0.5)
	nd2:addChild(p)
	ui.setBlend(p, 1, 1)
	p:runAction(ui.action.arepeat(ui.action.rotateBy(6,360)))

	p = ui.particle("particles/sceneParti1.json")
    p:setPosition(345,2613)
    p:setSkewX(10)
    p:setSkewY(12)
    p:setScaleX(0.75)
    p:setScaleY(0.9375)
    p:setRotation(10)
    self.view:addChild(p)
end
return SceneNormal
