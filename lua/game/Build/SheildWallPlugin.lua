


local SheildWallPlugin = {}
local SData = GMethod.loadScript("data.StaticData")
function SheildWallPlugin:onReload()
    -- local vstate = self.vstate
    -- local sinfo = SData.getData("sinfos",902)
    -- local rhero = PersonUtil.C({person=PersonUtil.newPersonData(sinfo,{hp=10,atk=10,id=902,level=1}), state=AvtControlerState.Operation, group=1})
    -- rhero.target = self
    -- rhero:addToScene(vstate.scene, vstate.gx+vstate.gsize/2,vstate.gy+vstate.gsize/2)

    local vstate = self.vstate
    if vstate.scene.battleParams.special and vstate.scene.battleParams.special[2] ~= 1 then
        local sinfo = SData.getData("sinfos",2)
        local params = {group = 1,state = AvtControlerState.ZOMBIE,sid = 2}
        local zombie = PersonUtil.C(params)
        local gx,gy = vstate.scene.map.convertToGrid(0,69*2)
        local s = vstate.gsize
        local edge = 80
        local gpos = {{-184+edge,138},{0,0+edge},{184-edge,138},{0,276-edge}}
        zombie.changjing_pos = gpos
        local node = ui.node()
        vstate.build:addChild(node)
        --node:setScale(0.5)
        local tscene = {objs = vstate.scene.objs ,map = vstate.scene.map, ground = node, upNode = vstate.scene.upNode}
        zombie:addToScene(tscene,gx,gy)
    else
        local sinfo = SData.getData("sinfos",3)
        local params = {group = 1,state = AvtControlerState.ZOMBIE,sid = 3}
        local zombie = PersonUtil.C(params)
        local gx,gy = vstate.scene.map.convertToGrid(0,69*2)
        local s = vstate.gsize
        local edge = 80
        local gpos = {{-184+edge,138},{0,0+edge},{184-edge,138},{0,276-edge}}
        zombie.changjing_pos = gpos
        local node = ui.node()
        vstate.build:addChild(node)
        --node:setScale(0.5)
        local tscene = {objs = vstate.scene.objs ,map = vstate.scene.map, ground = node, upNode = vstate.scene.upNode}
        zombie:addToScene(tscene,gx,gy)
    end
end

return SheildWallPlugin