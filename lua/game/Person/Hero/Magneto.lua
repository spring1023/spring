

local M = class(AvtInfo)













local V = {}



local C = class(AvtControler)

--4011    万磁王    主动技能27  对前方3个大范围内（每个范围为g格半径圆）的敌方单位造成a+c%攻击力的伤害，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.avtInfo.person.actSkillParams
    local a,c = params.a,params.c
    local g = params.g

    local dt = 0
    for i,point in ipairs(self.cgxcgy) do
        self.scene.replay:addDelay(function()
            local pointTab = {}
            for i,v in ipairs(self.battleMap.battlerAll) do
                local viewInfo = v.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(v)
                table.insert(pointTab,{viewInfo[1],viewInfo[2],viewInfo[3],v})
            end
            local result = Aoe.circlePoint(pointTab,{point[1],point[2]},g)
            for k,v in ipairs(result) do
                SkillPlugin.exe2(self,v[4],a,c)
            end
        end,dt)
        dt = dt+0.5
    end
end

--对空中敌人造成[a]+[x]%攻击力的伤害(最多为敌人血量的[y]%),全体成员[t]秒内回复[b]+[z]%攻击力的血量
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill(v)
    if not v or v.deleted then
        return
    end
    MagnetoEffect.new({attacker = self.V, mode = 3, target = v})
    local ps = self.person.awakeData.ps
    local value1 = ps.a+ps.x*self.M.atk/100
    local value2 = v.M.base_hp*ps.y/100
    value1 = value1>value2 and value2 or value1
    SkillPlugin.exe2(self,v,value1,0)
end

function V:viewEffect(attackTarget,callback,isSkill)
    local attackmode = 0
    if isSkill then
        attackmode = 1
    end


    local dt = 0
    for i,point in ipairs(self.C.cgxcgy) do
        self.scene.replay:addDelay(function()
            if not self.exeNum then
                self.exeNum = 0
            end
            local cb
            if self.exeNum == 0 then
                cb = callback
            end
            p = {self.map:convertToPosition(point[1],point[2])}
            local shot = MagnetoEffect.new(100, 1250, p[1], p[2], 10000,attackTarget,1,self.direction,attackmode,cb)
            shot.attacker = self
            shot:addToScene(self.scene)
            self.exeNum = self.exeNum+1
            if self.exeNum>=3 then
                self.exeNum = nil
            end
        end,dt)
        dt = dt+0.5
    end
end

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        local target = attackTarget
        local gx,gy = self.gx,self.gy
        local viewInfo = target.battleViewInfo or self.C.battleMap:getSoldierBattleViewInfoReal(target)
        local cgx,cgy = viewInfo[1],viewInfo[2]
        local dx,dy = cgx-gx,cgy-gy
        local d = math.sqrt(dx*dx+dy*dy)
        local sin,cos = dy/d,dx/d
        self.C.cgxcgy = {{cgx,cgy},{cgx+6*cos,cgy+6*sin},{cgx+12*cos,cgy+12*sin}}
    end
    MagnetoEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end

function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    MagnetoEffect.new({attacker = self, mode = 2, target = self.C})
    self.scene.replay:addDelay(function()
        for i,v in ipairs(self.C.battleMap.battler) do
            if v.M.utype == 2 then
                MagnetoEffect.new({attacker = self, mode = 0, target = v, speed = 2000},callback)
            end
        end
        local ps = self.C.person.awakeData.ps
        for i,v in ipairs(self.C.battleMap2.battlerAll) do
            BuffUtil.setBuff(v,{lastedTime=ps.t, lastAddHp=ps.b+ps.z*self.M.atk/100})
        end
    end,0.5)
end

--防守时增加磁暴塔[x]%血量，[y]%攻击力，磁暴塔爆炸时对周围单位造成[z]%自身攻击力伤害，并在[t]秒内使敌方损失[a]血量
function C:sg_updateBattle(diff)
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.build
        if DEBUG.DEBUG_GODSKILL2 then
            group = self.battleMap.build
        end
        for k,v in pairs(group) do
            if v.bid == 25 then
                v.M.nowHp = v.M.nowHp*(1+ps.x/100)
                v.M.maxHp = v.M.maxHp*(1+ps.x/100)
                v.M.atk = v.M.atk*(1+ps.y/100)
                BuffUtil.setBuff(v,{ps = ps},"MagnetoGodSkill2")
            end
        end
    end
end

MagnetoEffect = class()

function MagnetoEffect:ctor(params,callback)
    self.scene = GMethod.loadScript("game.View.Scene")
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    if self.scene.replay then
        self.scene.replay:addUpdateObj(self)
    else
        RegUpdate(function(diff)
            self.updateMy(diff)
        end,0)
    end
end

function MagnetoEffect:initParams(params)
    self.effectManager=GameEffect.new("MagnetoEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget

    --起始点坐标
    local x,y = 0,self.attacker.animaConfig.Ymove
    local p = {self.attacker.view:getPosition()}
    p[1] = p[1] + x
    p[2] = p[2] + y
    self.initPos = {p[1],p[2],General.sceneHeight - p[2]}

    --目标点坐标
    local view,height
    if self.target.avater then
        view = self.target.avater.view
        height = 40 + self.target.avater.animaConfig.Ymove
        self.targetZ = 41 + self.target.avater.animaConfig.Ymove
    else
        view = self.target.view
        height = view:getContentSize().height/2
        self.targetZ = 0
    end
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function MagnetoEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:initGodSkill()
    elseif self.mode == 3 then
        self:initGodSkill_bao1()
    end
end

function MagnetoEffect:initAttack()
    local setting={{55,11},{109,76},{77,154},{-77,154},{-109,76},{-55,11}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local targetPos=self.targetPos
    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime

    local temp

    local function delayFrameIndex_44_Bao()
        local upNode=ui.node()
        upNode:setPosition(targetPos[1],targetPos[2])
        upNode:setScale(1.3)
        bg:addChild(upNode,targetPos[3]+10)
        upNode:runAction(ui.action.sequence({{"delay",20/60},"remove"}))

    effectManager:addEffect("views3_delay44",upNode)
    temp=views.Sprite_5
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",14/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Sprite_5_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Glow_01_7
    temp:setPosition(0,0)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",8/60},{"fadeTo",7/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},"remove"}))
    end

    local function delayFrameIndex_19()
    effectManager:addEffect("views3_delay19",bg)
    temp=views.Ball_Large_4
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10000)
    temp:setScale(1.3)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY},{"call",delayFrameIndex_44_Bao}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",moveTime+2/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",3/60},{"call",delayFrameIndex_19}}))
end

function MagnetoEffect:initSkill()
    self.time = 40/60
    local setting={{55,11},{109,76},{77,154},{-77,154},{-109,76},{-55,11}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos2={}
    initPos2[1]=self.initPos[1]
    initPos2[2]=self.initPos[2]
    initPos2[3]=self.initPos[3]

    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local targetPos=self.targetPos
    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    moveY = moveY+240
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    local oy=360
    local temp

    local function showBao()
        self:createViews_2(oy,1)

        self.delayNode:runAction(ui.action.sequence({{"delay",30/60},{"call",function()
            self:createViews_2(oy,2)
        end}}))
        self.delayNode:runAction(ui.action.sequence({{"delay",60/60},{"call",function()
            self:createViews_2(oy,3)
        end}}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",10/60},{"call",showBao}}))

    local function delayFrameIndex_49()
        effectManager:addEffect("views1_delay49",bg)
        temp=views.Glow_01_24
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3]+10000000)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",6/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
    end
    delayFrameIndex_49()

    local function delayFrameIndex_0()
        effectManager:addEffect("views1_delay0",self.attacker.view)
        temp=views.Sprite_2
        temp:setPosition(0,120)
        temp:setLocalZOrder(2)
        temp:runAction(ui.action.sequence({{"fadeTo",5/60,178},{"delay",45/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))
        temp=views.Glow_01_3
        temp:setPosition(0,120)
        temp:setLocalZOrder(2)
        temp:runAction(ui.action.sequence({{"fadeTo",5/60,178},{"delay",45/60},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))
    end
    delayFrameIndex_0()

    local scalNode=ui.node()
    scalNode:setPosition(0,200)
    self.attacker.view:addChild(scalNode,10)
    scalNode:setScaleX(0.2)
    scalNode:setScaleY(0.14)
    scalNode:runAction(ui.action.scaleTo(10/60,1,0.7))
    local rNode=ui.node()
    rNode:setPosition(0,0)
    scalNode:addChild(rNode)
    effectManager:addEffect("views1_delay10",rNode)
    rNode:runAction(ui.action.rotateBy(75/60,450))
    scalNode:runAction(ui.action.sequence({{"scaleTo",75/60,1,0.7},"remove"}))


end

function MagnetoEffect:createViews_2(oy,i)
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction

    local p = self.attacker.C.cgxcgy[i]
    local x,y=self.attacker.map.convertToPosition(p[1],p[2])
    local temp
    local starF=50/60
    local upNode=ui.node()
    upNode:setPosition(x,y)
    upNode:setScale(1.8)
    bg:addChild(upNode,100000)

    local initPos={0,0,0}
    local function delayFrameIndex_57()
    effectManager:addEffect("views2_delay57",upNode)
    temp=views.Glow_01_41
    temp:setPosition(initPos[1],initPos[2]+oy)
    temp:setLocalZOrder(initPos[3]-6)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"moveBy",24/60,0,-oy}}))
    temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",17/60},{"fadeTo",6/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
    temp=views.Glow_01_41_0
    temp:setPosition(initPos[1],initPos[2]+oy)
    temp:setLocalZOrder(initPos[3]-5)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"moveBy",24/60,0,-oy}}))
    temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",17/60},{"fadeTo",6/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",50/60-starF},{"call",delayFrameIndex_57}}))

    local function delayFrameIndex_74()
    effectManager:addEffect("views2_delay74",upNode)
    temp=views.Glow_01_8_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",8/60},{"fadeTo",28/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    temp=views.Electricity_Explosion_00000_6
    temp:setPosition(initPos[1],initPos[2]+100)
    temp:setLocalZOrder(initPos[3]+7)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",33/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    temp=views.Electricity_Explosion_00000_6_0
    temp:setPosition(initPos[1],initPos[2]+100)
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",33/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    temp=views.Glow_01_8
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+9)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",39/60,4.0,3.0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",39/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
    temp=views.Glow_01_8_1
    temp:setPosition(initPos[1],initPos[2]+100)
    temp:setLocalZOrder(initPos[3]+10)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",3/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",9/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",74/60-starF},{"call",delayFrameIndex_74}}))

    local function delayFrameIndex_77()
    effectManager:addEffect("views2_delay77",upNode)
    temp=views.Sprite_39
    temp:setPosition(initPos[1],initPos[2]+100)
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",35/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",77/60-starF},{"call",delayFrameIndex_77}}))

    local function delayFrameIndex_78()
    effectManager:addEffect("views2_delay78",upNode)
    temp=views.Wave_00000_25
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",35/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",41/60},"remove"}))
    temp=views.Wave_00000_25_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",35/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",41/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",78/60-starF},{"call",delayFrameIndex_78}}))
    upNode:runAction(ui.action.sequence({{"delay",78/60-starF+41/60},"remove"}))
end

--自身
function MagnetoEffect:initGodSkill()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.initPos
    local temp

    local upNode=ui.node()
    upNode:setPosition(self.initPos[1],self.initPos[2]+50)
    bg:addChild(upNode,10000000)
    upNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

    initPos={0,0,0}
    effectManager:addEffect("god_views4_delay22",upNode)

      temp=views.Glow_01_2_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",8/60,3.0,3.0},{"scaleTo",20/60,4.0,4.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",4/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.SDA_03_14
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",8/60,3.3,2.64},{"scaleTo",17/60,5.0,4.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",8/60,255},{"fadeTo",17/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Glow_01_2_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",8/60,2.0,2.0},{"scaleTo",20/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",4/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Glow_01_2
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",8/60,2.3,2.3},{"scaleTo",20/60,3.5,3.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",4/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.guanghuad_6
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",8/60,1.3,1.04},{"scaleTo",20/60,2.0,1.6}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",8/60,127},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.guanghuad_6_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",8/60,1.3,1.04},{"scaleTo",20/60,2.0,1.6}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",8/60,255},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Spark_00000_8
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Spark_00000_8_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Sprite_10
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"fadeTo",1/60,0},{"delay",5/60},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,127},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Sprite_10_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"fadeTo",1/60,0},{"delay",5/60},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,127},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Glow_01_12
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,2.5,2.5},{"scaleTo",23/60,3.5,3.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"fadeTo",23/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Glow_01_12_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,2.5,2.5},{"scaleTo",23/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"fadeTo",23/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Boom02_18
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",8/60,1.5,1.5},{"scaleTo",10/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",8/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
end

--爆炸1
function MagnetoEffect:initGodSkill_bao1()
    local effectManager=self.effectManager
    local avater = self.target.V
    local views=self.views
    local direction=self.direction
    local initPos=self.initPos
    local temp

    local upNode=ui.node()
    upNode:setPosition(0, avater.animaConfig.Ymove)
    avater.view:addChild(upNode,100000)
    upNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

    initPos={0,0,0}

    local function delayFrameIndex_3()
    effectManager:addEffect("god_views5_delay3",upNode)
      temp=views.Shockwave_00000_22_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",32/60,0.4,0.4}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",32/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Shockwave_00000_22
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",32/60,0.4,0.4}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",3/60},{"call",delayFrameIndex_3}}))
    local function delayFrameIndex_20()
    effectManager:addEffect("god_views5_delay20",upNode)
      temp=views.BaoDiantt_00_25
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,2.0,2.0},{"scaleTo",15/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",9/60},{"fadeTo",1/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Smoke_00000_20
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",23/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Smoke_00000_20_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",23/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
    local function delayFrameIndex_29()
    effectManager:addEffect("god_views5_delay29",upNode)
      temp=views.GF_472_26
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,3.0,3.0},{"scaleTo",20/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",5/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",29/60},{"call",delayFrameIndex_29}}))
end

--爆炸2
function MagnetoEffect:initGodSkill_bao2()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.initPos
    local temp

    local upNode=ui.node()
    upNode:setPosition(x,y)
    bg:addChild(upNode,100000)
    upNode:runAction(ui.action.sequence({{"delay",30/60},"remove"}))

    initPos={0,0,0}
    effectManager:addEffect("god_views6_delay0",upNode)
    temp=views.shouji_00000_1
    temp:setPosition(initPos[1],initPos[2])
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1.5,1.5}}))
    temp:runAction(ui.action.sequence({{"delay",20/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))

end

function MagnetoEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target)
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end

return {M,V,C}




















