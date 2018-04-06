
local SuperWeapon={}
function SuperWeapon.createQuanzhang_zhaohuan(MainScene,id,x,y,Zongtime,snum)--毒性攻击
    snum = snum/4
    local zidanNode = ui.node()
    zidanNode:setPosition(x,y)
    MainScene.effects:addChild(zidanNode, 1)

    local baseNode = ui.node()--人物图层下
    baseNode:setPosition(x,y)
    MainScene.bottom:addChild(baseNode, 3)
    baseNode:setScale(0.35*snum)

    local baseNode2=ui.node()--人物图层上
    baseNode2:setPosition(x,y)
    MainScene.effects:addChild(baseNode2, 0)
    baseNode2:setScale(0.35*snum)
    x=0
    y=0
    local hight=200
    local movetime=0.25
    local dan=ui.sprite("swPoison.png")
    dan:setAnchorPoint(0.5,0)
    dan:setPosition(x,y+hight)
    zidanNode:addChild(dan)

    local move=ui.action.easeSineIn(ui.action.moveTo(movetime,x,y))
    dan:runAction(ui.action.sequence({move,{"fadeOut",0.03},"remove"}))

    local blend1={}     
        blend1.src=gl.SRC_ALPHA
        blend1.dst=gl.ONE_MINUS_SRC_ALPHA

    local blend2={}
        blend2.src=gl.ONE
        blend2.dst=gl.ONE_MINUS_SRC_ALPHA

    local blend3={}
        blend3.src=gl.DST_ALPHA
        blend3.dst=gl.ONE_MINUS_SRC_COLOR

    local blend4={}
        blend4.src=gl.SRC_ALPHA
        blend4.dst=gl.ONE

    local blend5={}
        blend5.src=gl.ONE
        blend5.dst=gl.ONE

    local blend6={}
        blend6.src=gl.DST_COLOR
        blend6.dst=gl.ONE

    dan:setBlendFunc(blend1)

    local p=ui.sprite("smallGlow.png")
    ui.setColor(p, {0, 128, 0})
    p:setAnchorPoint(0.5,0.5)
    p:setPosition(x,y-31)
    baseNode:addChild(p)
    p:setScaleX(14)
    p:setScaleY(10.62)
    p:setBlendFunc(blend2)
    p:setOpacity(0)
    p:setVisible(false)
    p:runAction(ui.action.sequence({{"delay",0.416},"show",{"fadeTo",0.617,0.09*255},{"delay",0.967},{"fadeTo",0.4,0},"remove"}))

    p=ui.sprite("smallGlow.png")
    p:setAnchorPoint(0.5,0.5)
    p:setPosition(x,y+78)
    baseNode:addChild(p)
    p:setScaleX(12)
    p:setScaleY(9)
    p:setBlendFunc(blend3)
    ui.setColor(p, {253,140,0})
    p:setVisible(false)
    p:runAction(ui.action.sequence({{"delay",0.283},"show",{"fadeOut",0.75},"remove"}))

    p=ui.sprite("smallGlow.png")
    p:setAnchorPoint(0.5,0.5)
    p:setPosition(x,y-31)
    baseNode:addChild(p)
    p:setScaleX(14)
    p:setScaleY(10.5)
    p:setBlendFunc(blend3)
    ui.setColor(p, {4,255,0})
    p:setOpacity(0)
    p:setVisible(false)
    p:runAction(ui.action.sequence({{"delay",0.283},"show",{"fadeIn",0.75},{"delay",Zongtime-1.033-0.6},{"fadeOut",0.6},"remove"}))

    p=ui.sprite("smallGlow3.png")
    p:setAnchorPoint(0.5,0.5)
    p:setPosition(x,y)
    baseNode:addChild(p)
    p:setScaleX(5.52)
    p:setScaleY(4.12)
    p:setBlendFunc(blend4)
    ui.setColor(p, {0,255,54})
    p:setOpacity(0)
    p:setVisible(false)
    p:runAction(ui.action.sequence({{"delay",0.67},"show",{"fadeIn",0.363},{"delay",Zongtime-1.033-0.6},{"fadeOut",0.6},"remove"}))

    p=ui.sprite("bombHole.png")
    p:setAnchorPoint(0.5,0.5)
    p:setPosition(x,y-30)
    baseNode:addChild(p)
    p:setScaleX(1)
    p:setScaleY(1)
    p:setOpacity(0.7*255)
    p:setVisible(false)
    p:runAction(ui.action.sequence({{"delay",0.283},"show",{"fadeTo",1.577,0},"remove"}))

    p=ui.sprite("partiLightPoint.png")--黄点 
    p:setAnchorPoint(0.5,0.5)
    p:setPosition(x,y-30)
    baseNode:addChild(p)
    p:setScaleX(1)
    p:setScaleY(0.75)
    p:setVisible(false)
    p:runAction(ui.action.sequence({{"delay",0.283},"show",{"delay",1.084},{"fadeOut",0.167},"remove"}))

    local smoke1,smoke2
    smoke1= ui.sprite("superWeapon_Smoke_0.png")
    smoke1:setPosition(x,y+9)
    baseNode:addChild(smoke1)
    smoke1:setVisible(false)

    smoke2= ui.sprite("Smoke_Invert_0.png")
    smoke2:setPosition(x,y+18)
    baseNode:addChild(smoke2)
    smoke2:setVisible(false)
    smoke2:setBlendFunc(blend1)

    smoke1:runAction(ui.action.sequence({{"delay",0.307},"show", {"easeSineOut", {"animate", 0.464, "superWeapon_Smoke_", 8}}, "remove"}))
    smoke2:runAction(ui.action.sequence({{"delay",0.51},"show", {"easeSineOut", {"animate", 0.25, "Smoke_Invert_", 5}}, "remove"}))
    smoke2:runAction(ui.action.sequence({{"delay",0.51},{"fadeOut",0.2}}))

    p=ui.sprite("smallGlow.png")
    p:setAnchorPoint(0.5,0.5)
    p:setPosition(x,y)
    baseNode:addChild(p)
    p:setScaleX(2.5)
    p:setScaleY(1.875)
    p:setOpacity(0.7*255)
    p:setBlendFunc(blend4)
    p:setColor(cc.c3b(255,0,0))
    p:setVisible(false)
    p:runAction(ui.action.sequence({{"delay",0.283},"show",{"fadeTo",0.75,0},"remove"}))

    local dan_yingzi=ui.sprite("smallGlowDark.png")
    dan_yingzi:setAnchorPoint(0.5,0.5)
    dan_yingzi:setPosition(x,y+10)
    MainScene.objs:addChild(dan_yingzi,100000)

    dan_yingzi:setOpacity(0)
    dan_yingzi:runAction(ui.action.fadeTo(0.283,0.5*255))
    dan_yingzi:setScaleX(1.4)
    dan_yingzi:setScaleY(1.05)
    dan_yingzi:runAction(ui.action.scaleTo(0.283,0.5,0.375))
    dan_yingzi:runAction(ui.action.sequence({{"delay",0.283},"remove"}))

    local function delayTimeCreate()
        p=ui.particle("particles/partiBubble.json", {d=Zongtime-0.67})
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        p:setScale(1)
        baseNode:addChild(p)

        p=ui.particle("particles/partiSwStar.json", {d=Zongtime-0.67})
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        p:setScale(1)
        baseNode2:addChild(p,100000)

        p=ui.particle("particles/partiGhost.json", {d=Zongtime-0.67})
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        p:setScale(1)
        baseNode2:addChild(p,100000)
        p:setBlendFunc(blend5)

        p=ui.particle("particles/partiSmoke.json", {d=Zongtime-0.67})
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        p:setScale(1.5)
        baseNode2:addChild(p,100000)
        p:setBlendFunc(blend5)
    end

    local node67s=ui.node()
    node67s:setPosition(x,y)
    baseNode:addChild(node67s)
    node67s:runAction(ui.action.sequence({{"delay",0.67},{"call",delayTimeCreate},"remove"}))

    local function delayTimeCreate0283()    
        p= ui.animateSprite(0.933,"Circle_Smoke_",6,{beginNum=0, isRepeat=true})
        p:setPosition(x,y)
        baseNode2:addChild(p,100000)
        p:setBlendFunc(blend6)
        p:setScaleX(4)
        p:setScaleY(3)
        p:setOpacity(0.3*255)
        p:runAction(ui.action.scaleTo(0.417,6.8,5.1))
        p:runAction(ui.action.sequence({{"delay",1.033},{"fadeTo",0.183,0},"remove"}))
    end
    local node0283=ui.node()
    node0283:setPosition(x,y)
    baseNode2:addChild(node0283)
    node0283:runAction(ui.action.sequence({{"delay",0.283},{"call",delayTimeCreate0283},"remove"}))

    p=ui.sprite("Circle_Smoke_0.png")
    p:setAnchorPoint(0.5,0.5)
    p:setPosition(x,y)
    baseNode2:addChild(p,100000)
    p:setScaleX(3.2)
    p:setScaleY(2.4)
    p:setOpacity(0.3*255)
    p:setBlendFunc(blend6)
    p:setVisible(false)
    p:runAction(ui.action.sequence({{"delay",0.283},{"scaleTo",0.633,6,4.5},{"scaleTo",0.02,6*0.95,4.5*0.95},{"scaleTo",0.02,6,4.5}}))
    p:runAction(ui.action.sequence({{"delay",0.283},"show",{"delay",Zongtime-0.283-0.5},{"fadeTo",0.5,0},"remove"}))

    local function delayTimeCreate09s()
        p= ui.animateSprite(0.35,"Circle_Poison_",6,{beginNum=0, isRepeat=true})
        p:setPosition(x,y)
        baseNode2:addChild(p,100000)
        p:setBlendFunc(blend6)
        p:setScaleX(6)
        p:setScaleY(4.5)
        p:setOpacity(0)
        p:runAction(ui.action.fadeIn(0.35))
        p:runAction(ui.action.sequence({{"delay",Zongtime-0.9-0.3},{"fadeOut",0.3},"remove"}))
    end
    local node09s=ui.node()
    node09s:setPosition(x,y)
    baseNode2:addChild(node09s)
    node09s:runAction(ui.action.sequence({{"delay",0.9},{"call",delayTimeCreate09s},"remove"}))

    local function createSmoke(number)
       for i=1,number do
            p=ui.sprite("smokeLine.png")
            p:setAnchorPoint(0.5,0)
            baseNode2:addChild(p,100000)
            local r=180
            local Tx=math.random(2)
            local Ty=math.random(2)
            local ox=math.random(r)
            local oy=math.random(r)
            if Tx==2 then
                ox=-ox
            end
            if Ty==2 then
                oy=-oy
            end
            p:setPosition(x+ox,y+oy)
            p:setScaleX(0.7)
            p:setScaleY(0.5)
            p:setOpacity(0.5*255)
            p:runAction(ui.action.sequence({{"scaleTo",0.58,0.2,0.7},{"fadeTo",0.1,0},"remove"}))
        end
    end
    local nd=ui.node()
    nd:setPosition(x,y)
    baseNode2:addChild(nd)
    nd:runAction(ui.action.sequence({{"delay",0.67},ui.action.arepeat(ui.action.sequence({{"call",Handler(createSmoke,1)},{"delay",0.68},{"call",Handler(createSmoke,2)},{"delay",0.68}}), math.ceil((Zongtime-0.67)/1.36)),"remove"}))
end

function SuperWeapon.createQuanzhang_kuangbao(MainScene,id,x,y,Zongtime,snum) --狂暴
    local zidanNode = ui.node()
    zidanNode:setPosition(x,y)
    MainScene.objs:addChild(zidanNode,1000000)

    local baseNode = ui.node()
    baseNode:setPosition(x,y)
    MainScene.objs:addChild(baseNode,100000)
    snum = snum/8
    baseNode:setScale(1.1*snum)
    local baseNode_down = ui.node()
    baseNode_down:setScale(1.1*snum)
    baseNode_down:setPosition(x,y)
    MainScene.objs:addChild(baseNode_down, MainScene.map.minZ-1)

    x,y=0,0
    local hight=320
    local movetime=0.416
    local dan=ui.sprite("swGyroscope.png")
    dan:setAnchorPoint(0.5,0)
    dan:setPosition(x,y+hight)
    zidanNode:addChild(dan,100000)
    dan:setScaleX(0.9)
    dan:setScaleY(1.2)
    local move=ui.action.easeSineIn(ui.action.moveTo(movetime,x,y))
    dan:runAction(ui.action.sequence({move,"remove"}))

    local blend={}
        blend.src=gl.SRC_ALPHA
        blend.dst=gl.ONE_MINUS_SRC_ALPHA
    local blend2={}
        blend2.src=gl.SRC_ALPHA
        blend2.dst=gl.ONE
    local blend3={}
        blend3.src=gl.DST_ALPHA
        blend3.dst=gl.ONE
    local blend4={}
        blend4.src=gl.DST_ALPHA
        blend4.dst=gl.ONE_MINUS_SRC_COLOR
    local blend5={}
        blend5.src=gl.ONE
        blend5.dst=gl.ONE_MINUS_SRC_COLOR


        dan:setBlendFunc(blend)

    local node=ui.node()
          node:setPosition(x,y)
          baseNode_down:addChild(node)
          node:setScaleX(1)
          node:setScaleY(0.75)
    local p=ui.sprite("smallGlow.png")
    p:setPosition(x,y)
    node:addChild(p)
    p:setScale(11.2)
    p:setBlendFunc(blend3)
    --205,100,255
    p:setColor(cc.c3b(133,0,255))
    p:setOpacity(0)
    local spawn=ui.action.spawn({{"scaleTo",0.17,20,20},{"fadeIn",0.17}})
    p:runAction(ui.action.sequence({{"delay",0.33},spawn,{"delay",Zongtime-0.5-0.5},{"fadeOut",0.5},"remove"}))
    local function delayTimeCreate()
        p=ui.sprite("swCircle2.png")
        p:setPosition(0,0)
        node:addChild(p)
        p:setScale(2.4)
        p:setBlendFunc(blend3)
        p:runAction(ui.action.rotateBy(Zongtime-movetime,(Zongtime-movetime)*22.5))
        p:runAction(ui.action.sequence({{"delay",Zongtime-movetime-0.5},{"fadeOut",0.5}}))  

        p=ui.sprite("swCircle_R_2.png")
        p:setPosition(0,0)
        node:addChild(p)
        p:setScale(2.06)
        p:setBlendFunc(blend2)
        p:runAction(ui.action.sequence({{"delay",Zongtime-movetime-0.5},{"fadeOut",0.5},"remove"}))
        p=ui.sprite("swCircle_R_2.png")
        p:setPosition(0,0)
        node:addChild(p)
        p:setScale(2.06)
        p:setBlendFunc(blend2)
        p:runAction(ui.action.sequence({{"delay",Zongtime-movetime-0.5},{"fadeOut",0.5},"remove"}))

        p= ui.animateSprite(2,"swCyclone_",20,{beginNum=0,isRepeat=true})
        p:setPosition(x,y+165)
        baseNode:addChild(p,100000)
        p:setBlendFunc(blend3)
        p:setScale(2.24)
        local seq=ui.action.sequence({{"scaleTo",2,2,2},{"scaleTo",0,2.4,2.4}})
        p:runAction(ui.action.arepeat(seq))
        p:runAction(ui.action.sequence({{"delay",Zongtime-movetime},"remove"}))

        p=ui.particle("particles/partiSmokeWhite.json")
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        p:setScale(1)
        baseNode:addChild(p,100000)
        p:setBlendFunc(blend)

        p=ui.sprite("smallGlow.png")
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        baseNode_down:addChild(p,100000)
        p:setScale(12)
        p:runAction(ui.action.sequence({{"delay",Zongtime-movetime-0.25},{"fadeOut",0.25},"remove"}))
        p:setColor(cc.c3b(203,54,179))
        p:setBlendFunc(blend4)

        local smoke1,smoke2
        smoke1= ui.sprite("superWeapon_Smoke_0.png")
        smoke1:setPosition(x,y+24)
        baseNode:addChild(smoke1,100000)
        smoke1:setBlendFunc(blend5)

        smoke2= ui.sprite("Smoke_Invert_0.png")
        smoke2:setPosition(x,y+34)
        baseNode:addChild(smoke2,100000)
        smoke2:setVisible(false)
        smoke2:setBlendFunc(blend)

        smoke1:runAction(ui.action.sequence({{"delay",0.028},"show", {"easeSineOut", {"animate", 0.5, "superWeapon_Smoke_", 8}}, "remove"}))
        smoke1:runAction(ui.action.sequence({{"delay",0.074},{"fadeOut",0.293}}))
        smoke2:runAction(ui.action.sequence({{"delay",0.151},"show", {"delay",0.078}, {"easeSineOut", {"animate", 0.5, "Smoke_Invert_", 5}}, "remove"}))
        smoke2:runAction(ui.action.sequence({{"delay",0.151},{"fadeOut",0.349}}))
    end
    node:runAction(ui.action.sequence({{"delay",0.416},{"call",delayTimeCreate}}))

    local dan_yingzi=ui.sprite("smallGlowDark.png")
    dan_yingzi:setAnchorPoint(0.5,0.5)
    dan_yingzi:setPosition(x,y+10)
    baseNode_down:addChild(dan_yingzi,100000)

    dan_yingzi:setOpacity(0)
    dan_yingzi:runAction(ui.action.fadeTo(movetime,0.5*255))
    dan_yingzi:setScaleX(1.4)
    dan_yingzi:setScaleY(1.05)
    dan_yingzi:runAction(ui.action.scaleTo(movetime,0.5,0.375))
    dan_yingzi:runAction(ui.action.sequence({{"delay",movetime},"remove"}))

end

function SuperWeapon.create_zhiliao(MainScene,id,x,y,Zongtime,snum)--治疗
    snum = snum/8
    local zidanNode = ui.node()
    zidanNode:setPosition(x,y)
    MainScene.objs:addChild(zidanNode,1000000)

    local baseNode = ui.node()
    baseNode:setScale(snum)
    baseNode:setPosition(x,y)
    MainScene.objs:addChild(baseNode,1000000)

    local baseNode_down = ui.node()
    baseNode_down:setScale(snum)
    baseNode_down:setPosition(x,y)
    x,y=0,0
    MainScene.objs:addChild(baseNode_down, MainScene.map.minZ-1)

    local hight=200
    local movetime=0.4
    local dan=ui.sprite("swRecover.png")
    dan:setAnchorPoint(0.5,0.5)
    dan:setPosition(x,y+hight)
    zidanNode:addChild(dan,100000)
    dan:runAction(ui.action.rotateBy(movetime,360))
    local move=ui.action.easeSineIn(ui.action.moveTo(movetime,x,y))
    dan:runAction(ui.action.sequence({move,"remove"}))

    local dan_yingzi=ui.sprite("smallGlowDark.png")
    dan_yingzi:setAnchorPoint(0.5,0.5)
    dan_yingzi:setPosition(x,y)
    baseNode_down:addChild(dan_yingzi,100000)

    dan_yingzi:setOpacity(0)
    dan_yingzi:runAction(ui.action.fadeTo(movetime,0.5*255))
    dan_yingzi:setScaleX(1.4)
    dan_yingzi:setScaleY(1.05)
    dan_yingzi:runAction(ui.action.scaleTo(movetime,0.5,0.375))

    dan_yingzi:runAction(ui.action.sequence({{"delay",movetime},"remove"}))
    -- local sp=ui.sprite("effects/liaoguan.png")
    --      sp:setAnchorPoint(0.5,0.5)
    --      sp:setScaleX(3)
    --      sp:setScaleY(2.25)
    --      sp:setPosition(x,y)
    --      baseNode:addChild(sp,6)
    --      sp:setVisible(false)
    --      sp:runAction(ui.action.sequence({{"delay",movetime-0.02},{"show"},{"fadeOut",0.1},"remove"}))
    --      local blend1={}
    --      blend1.src=770
    --      blend1.dst=1
    --      sp:setBlendFunc(blend1)


    local function createTexiao()
        local p=ui.sprite("smallGlow.png")
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        baseNode_down:addChild(p,100000)
        p:setScale(14)
        p:runAction(ui.action.sequence({{"delay",0.1},{"fadeOut",0.07},"remove"}))
        p:setColor(cc.c3b(255,0,0))
        local blend={}
        blend.src=gl.DST_ALPHA
        blend.dst=gl.ONE_MINUS_SRC_COLOR
        p:setBlendFunc(blend)

        p = ui.sprite("swCircle_R.png")
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        baseNode_down:addChild(p,100000)
        p:setScaleX(2.4)
        p:setScaleY(1.8)
        p:runAction(ui.action.sequence({{"delay",Zongtime-movetime-0.05},{"fadeOut",0.05},"remove"}))

        p=ui.sprite("swCircle_R.png")
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        baseNode_down:addChild(p,100000)
        p:setScaleX(0.82)
        p:setScaleY(0.72)
        p:runAction(ui.action.scaleTo(0.33,2.4,1.8))
        p:runAction(ui.action.sequence({{"delay",0.05},{"fadeOut",0.21},"remove"}))

        p=ui.sprite("swCircle_R.png")
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        baseNode_down:addChild(p,100000)
        p:setScaleX(0.52)
        p:setScaleY(0.42)
        p:runAction(ui.action.scaleTo(0.33,2.4,1.8))
        p:runAction(ui.action.sequence({{"delay",0.1},{"fadeOut",0.21},"remove"}))

        p=ui.sprite("swCircle_R.png")
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        baseNode_down:addChild(p,100000)
        p:setScaleX(0.4)
        p:setScaleY(0.3)
        p:runAction(ui.action.sequence({{"delay",0.03},{"scaleTo",0.33,2.4,1.8}}))
        p:runAction(ui.action.sequence({{"delay",0.15},{"fadeOut",0.21},"remove"}))

        p= ui.animateSprite(0.5,"Circle_Recover_",6,{beginNum=0,isRepeat=true})
        p:setPosition(x,y)
        baseNode_down:addChild(p,100000)
        p:setScaleX(2.64)
        p:setScaleY(1.98)
        p:setOpacity(0)
        p:runAction(ui.action.sequence({{"delay",0.05},{"fadeIn",0.08}}))
        p:runAction(ui.action.sequence({{"delay",Zongtime-movetime-0.05},{"fadeOut",0.05},"remove"}))

        local smoke1,smoke2
        smoke1= ui.sprite("superWeapon_Smoke_0.png")
        smoke1:setPosition(x,y+30)
        baseNode:addChild(smoke1,100000)

        smoke2= ui.sprite("Smoke_Invert_0.png")
        smoke2:setPosition(x,y+46)
        baseNode:addChild(smoke2,100000)
        smoke2:setVisible(false)

        smoke1:runAction(ui.action.sequence({{"delay",0.03},"show", {"easeSineOut", {"animate", 0.52, "superWeapon_Smoke_", 8}}, "remove"}))
        smoke1:runAction(ui.action.sequence({{"delay",0.05},{"fadeOut",0.35}}))
        smoke2:runAction(ui.action.sequence({{"delay",0.02},"show", {"delay",0.08}, {"easeSineOut", {"animate", 0.5, "Smoke_Invert_", 5}}, "remove"}))
        smoke2:runAction(ui.action.sequence({{"delay",0.35},{"fadeOut",0.25}}))

        local function createQuan()
            p= ui.animateSprite(0.5,"Circle_Recover_D_",6,{beginNum=0,isRepeat=true})
            p:setPosition(x,y)
            baseNode_down:addChild(p,100000)
            p:setScaleX(2.64)
            p:setScaleY(1.98)
            p:runAction(ui.action.sequence({{"delay",Zongtime-movetime-0.15-0.05},{"fadeOut",0.05},"remove"}))
        end
            
        local node=ui.node()
        node:setPosition(x,y)
        baseNode:addChild(node)
        node:runAction(ui.action.sequence({{"delay",0.15},"remove"}))

        p = ui.particle("particles/partiYellowLine.json", {d=Zongtime-movetime})
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        p:setScale(1)
        baseNode:addChild(p,100000)
        p:setVisible(false)
        p:runAction(ui.action.sequence({{"delay",0.07},"show"}))

        p=ui.particle("particles/partiSwStar2.json", {d = Zongtime-movetime})
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        p:setScale(1)
        baseNode:addChild(p,100000)
        p:setVisible(false)
        p:runAction(ui.action.sequence({{"delay",0.07},"show"}))

        p=ui.particle("particles/partiRedCross.json", {ptype = cc.POSITION_TYPE_GROUPED, d=Zongtime-movetime})
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        p:setScale(1)
        baseNode:addChild(p,100000)
        p:setVisible(false)
        p:runAction(ui.action.sequence({{"delay",0.07},"show"}))

        p=ui.sprite("smallGlow.png")
        p:setAnchorPoint(0.5,0.5)
        p:setPosition(x,y)
        baseNode_down:addChild(p,100000)
        p:setScaleX(20)
        p:setScaleY(15)
        p:setOpacity(0)
        p:runAction(ui.action.sequence({{"fadeTo",0.15,0.5*255},{"delay",Zongtime-movetime-0.15-0.8},{"fadeTo",0.8,0},"remove"}))
        blend.src=gl.SRC_ALPHA
        blend.dst=gl.ONE
        p:setBlendFunc(blend)
        p:setColor(cc.c3b(255,56,0))
    end

    local node=ui.node()
    node:setPosition(x,y)
    baseNode:addChild(node)
    --     node:runAction(ui.action.sequence({{"delay",movetime-0.15},{"call",createTexiao2}}))
    node:runAction(ui.action.sequence({{"delay",movetime},{"call",createTexiao},"remove"}))
end

return SuperWeapon
