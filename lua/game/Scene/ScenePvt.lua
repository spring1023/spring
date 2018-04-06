local ScenePvt = {state="cleanup", delta=0}

function ScenePvt:loadGround(scene)
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
    --RegUpdate(ground, Handler(self.updateGround, self), 0)
    --local land = ui.sprite("images/background/sceneBgPvt.png",{sizeX, sizeY}, false, true)
    local land = ui.spriteBlock("images/background/sceneBgPvt.png",{sizeX, sizeY},{4,3}, false, true)
    display.adapt(land,0,0)
    ground:addChild(land)

    scene.bgPng = "images/background/sceneBgPvt.png"
    scene.scroll:moveAndScaleToCenter(0.6*smin, sizeX/2, sizeY/2,0.5)

    UIeffectsManage:showEffect_huanyeCJ(ground,sizeX/2,sizeY/2)
    
    scene.bottomType = "Pvt"
    return self.view
end

return ScenePvt
