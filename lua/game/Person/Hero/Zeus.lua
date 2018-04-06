

local M = class(AvtInfo)













local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    ZeusEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end

local C = class(AvtControler)

--4016对目标及其g格半径范围内的敌人造成a+c%*攻击力的伤害，并让目标受到的治疗效果降低d%，持续t秒；同时回复己方所有英雄e%*攻击力的血量，并提升f%伤害，持续t秒，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local a,c,e,t,d,f = params.a,params.c,params.e,params.t,params.d,params.f
    local g = params.g
    local targetG = self:getCircleTarget(target,self.battleMap.battlerAll,g)
    for i,v in ipairs(targetG) do
        SkillPlugin.exe2(self,v,a,c)
    end
    BuffUtil.setBuff(target,{lastedTime = t,bfHealps = -d})
    for i,v in ipairs(self.battleMap2.hero) do
        local value = BattleUtil.getHeal(self,v,0,e)
        v:damage(value,self)
        BuffUtil.setBuff(v,{lastedTime = t,bfHurt = f})
        ZeusEffect.new({attacker = v.avater, mode = 2, target = v, lastedTime = t})
    end
end

--天神技 将所有英雄的剩余总血量平均分给每个英雄，并且对[m]个敌方目标及其周围区域半径[n]格范围内的敌人造成[a]+[x]%自身攻击力的伤害，恢复己方英雄[b]+[y]%自身攻击力的血量。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    local allHp = 0
    local heroG = self.battleMap2.hero
    for i,v in ipairs(heroG) do
        allHp = v.M.nowHp+allHp
    end

    local tempHeroG = {}
    for i,v in ipairs(heroG) do
        tempHeroG[i] = v
    end
    local value = 0
    while allHp>0 do
        local ev = allHp/#tempHeroG
        value = value+ev
        local dh = 0
        local idx = 0
        for i=1,#tempHeroG do
            idx = idx+1
            local v = tempHeroG[idx]
            if v.M.maxHp<ev then
                dh = dh+ev-v.M.maxHp
                table.remove(tempHeroG,i)
                idx = idx-1
            end
        end
        allHp = dh
    end
    for i,v in ipairs(heroG) do
        v:damage(v.M.nowHp-value)
    end

    local tg = self:getMinDisTarget(ps.m)
    local tgG = {}
    for i,v in ipairs(tg) do
        tgG[i] = self:getCircleTarget(v,self.battleMap.battlerAll,ps.n)
    end
    local hg = {}
    for i,v in ipairs(tgG) do
        for i1,v1 in ipairs(v) do
            if not hg[v1] then
                SkillPlugin.exe2(self,v1,ps.a,ps.x)
                hg[v1] = 1
            end
        end
    end
    for i,v in ipairs(self.battleMap2.hero) do
        SkillPlugin.exe7(self,v,ps.b,ps.y)
        ZeusEffect.new({attacker = v.V, mode = 5, target = v})
    end

end
function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    ZeusEffect.new({attacker = self, mode = 4, target = attackTarget},callback)
end

--增加己方英雄[x]%的伤害，并受到的治疗效果提升[y]%。并增大自身攻击距离至[z]%。
function C:sg_updateBattle(diff)
    if self.deleted then
        return
    end
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.hero
        if DEBUG.DEBUG_GODSKILL2 then
            group = self.battleMap.hero
        end
        for k,v in ipairs(group) do
            BuffUtil.setBuff(v,{bfHurt=ps.x, bfHealps=ps.y})
        end
        self.M.range = (self.M.range or 0) + (self.M.range_bak or self.M.range or 0) * (ps.z-100)/100
    end
    if self.params.isRebirth then
        return
    end
    local ps = self:getExtSkillData()
    self.count = (self.count or 0) + diff
    if self.count >= ps.z then
        local group = {}
        for i, enemy in ipairs(self.battleMap.hero) do
            table.insert(group, enemy)
        end
        for i, enemy in ipairs(group) do
            if not enemy.deleted then
                ZeusEffect.new({attacker=self.V, mode=6, target=enemy}, Handler(self.onExtSkill, self, enemy))
            end
        end
        self.count = self.count - ps.z
    end
end

function C:onExtSkill(enemy)
    if enemy.deleted then
        return
    end
    local ps = self:getExtSkillData()
    SkillPlugin.exe2(self, enemy, ps.a, ps.d)
    if not enemy.deleted then
        local random = self.rd:randomInt(100)
        if random <= ps.c then
            BuffUtil.setBuff(enemy, {lastedTime=ps.t, bfDizziness=ps.t})
        end
    end
end

ZeusEffect = class()

function ZeusEffect:ctor(params,callback)
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

function ZeusEffect:initParams(params)
    self.effectManager=GameEffect.new("ZeusEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.lastedTime = params.lastedTime
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
        -- 特别的，如果是地面单位则直接砸地板
        if self.mode == 6 and self.target.avtInfo.utype == 1 then
            self.groundMode = height
        end
        self.targetZ = 41 + self.target.avater.animaConfig.Ymove
    else
        view = self.target.view
        height = view:getContentSize().height/2
        self.targetZ = 0
    end
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo and not self.groundMode then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function ZeusEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:heroState()
    elseif self.mode ==4 then
        self.time = 1
        self:initGodSkill()
        self:initGodSkill_dun()
    elseif self.mode == 5 then
        self:initGodSkill_buff()
        self:initGodSkill_huixue()
    elseif self.mode == 6 then
        self:initExtSkill()
    end
end

function ZeusEffect:initAttack()
    local setting={{72,-12},{156,82},{60,157},{-60,157},{-156,82},{-72,-12}}
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
    local r=-math.deg(math.atan2(moveY,moveX))
    local temp

    local function delayFrameIndex_19()
    local function showTargetBao( ... )
    self:createViews_5()
    end
    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+10000)
    moveNode:setRotation(r)
    moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

    effectManager:addEffect("views4_delay19",moveNode)
    temp=views.Glow_01_9_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,178},{"delay",moveTime},{"fadeTo",1/60,0}}))

    temp=views.Zues_Lightning_001_7
    temp:setRotation(65)
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",moveTime},{"fadeTo",1/60,0}}))
    temp=views.Zues_Lightning_001_7_0
    temp:setRotation(65)
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime},{"fadeTo",1/60,0}}))
    temp=views.Particle_4
    temp:setPosition(0,0)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",6/60,1.5,1.5}}))
    temp=views.Glow_01_9
    temp:setPosition(0,0)
    temp:setLocalZOrder(5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,216},{"delay",moveTime},{"fadeTo",1/60,0}}))
    end
    delayFrameIndex_19()
end

function ZeusEffect:createViews_5()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.targetPos
    local temp

    local function delayFrameIndex_35()
    effectManager:addEffect("views5_delay35",bg)
    temp=views.Glow_01_6_1_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,77},{"fadeTo",30/60,76},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    temp=views.Glow_01_6_0_0_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    temp=views.Glow_01_6_0_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    temp=views.Glow_01_6_0_2_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
    end
    delayFrameIndex_35()

    local function delayFrameIndex_39()
    effectManager:addEffect("views5_delay39",bg)
    temp=views.Particle_1_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_39}}))
end



function ZeusEffect:initSkill()
    local setting={{72,-12},{156,82},{60,157},{-60,157},{-156,82},{-72,-12}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]
    initPos[2]=self.initPos[2]
    initPos[3]=self.initPos[3]
    local initPos2={}
    initPos2[1]=self.initPos[1]+setting[direction][1]
    initPos2[2]=self.initPos[2]+setting[direction][2]
    initPos2[3]=self.initPos[3]
    local targetPos=self.targetPos

    local moveX,moveY=targetPos[1]-initPos2[1],targetPos[2]-initPos2[2]
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime+10/60
    local r=-math.deg(math.atan2(moveY,moveX))
    local temp


    local function showTargetBao( ... )
        self:createViews_2()
    end
    local moveNode=ui.node()
    moveNode:setPosition(initPos2[1],initPos2[2])
    moveNode:setScale(1.5)
    moveNode:setRotation(r)
    bg:addChild(moveNode,initPos[3]+10000)

    local atNode = self.attacker
    if atNode.deleted then
        return
    end
    local function delayFrameIndex_30()
        effectManager:addEffect("views1_delay30", atNode.view)
        temp=views.Glow_01_12_0_0
        temp:setPosition(0,15)
        temp:setLocalZOrder(-3)
        temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",60/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",80/60},"remove"}))
        temp=views.Glow_01_12_1
        temp:setPosition(0,15)
        temp:setLocalZOrder(-2)
        temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",60/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",80/60},"remove"}))
        temp=views.Glow_01_12
        temp:setPosition(0,0)
        temp:setLocalZOrder(-5)
        temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",60/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",80/60},"remove"}))
        temp=views.Glow_01_12_3
        temp:setPosition(0,0)
        temp:setLocalZOrder(-4)
        temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",60/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",80/60},"remove"}))
        temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
        temp=views.Glow_01_12_2
        temp:setPosition(0,0)
        temp:setLocalZOrder(-2)
        temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",60/60},{"fadeTo",10/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",80/60},"remove"}))
    end
    delayFrameIndex_30()

    local function delayFrameIndex_39()
        if atNode.deleted then
            return
        end
        effectManager:addEffect("views1_delay39",atNode.view)
        temp=views.Particle_2
        temp:setPosition(0,0)
        temp:setLocalZOrder(-1)
        temp:runAction(ui.action.sequence({{"delay",62/60},"remove"}))
        temp=views.Particle_3
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp:runAction(ui.action.sequence({{"delay",67/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_39}}))

    local function delayFrameIndex_49()
        moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
        effectManager:addEffect("views1_delay49_move",moveNode)
        temp=views.Glow_01_6_1_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(1)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",moveTime-5/60},{"fadeTo",5/60,0}}))
        temp=views.Particle_6
        temp:setPosition(-30,0)
        temp:setLocalZOrder(1)
        temp=views.Particle_6_1
        temp:setPosition(-30,0)
        temp:setLocalZOrder(1)
        temp=views.Glow_01_6_1_0_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(2)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",moveTime-5/60},{"fadeTo",5/60,0}}))
        temp=views.Particle_1_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(3)
        temp=views.Glow_01_6_0_0_0
        temp:setPosition(0,0)
        temp:setLocalZOrder(4)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,216},{"fadeTo",moveTime-5/60,255},{"fadeTo",5/60,0}}))
        temp=views.Glow_01_6_0_1
        temp:setPosition(0,0)
        temp:setLocalZOrder(5)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,204},{"fadeTo",moveTime-5/60,170},{"fadeTo",5/60,0}}))
        temp=views.Circle_00000_34
        temp:setPosition(0,0)
        temp:setLocalZOrder(6)
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-5/60},{"fadeTo",5/60,0}}))
    end
    delayFrameIndex_49()
end

--技能敌方受体
function ZeusEffect:createViews_2()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.targetPos
    local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(3.5)
    bg:addChild(upNode,initPos[3]+10000)
    upNode:runAction(ui.action.sequence({{"delay",72/60},"remove"}))

    local function delayFrameIndex_69()
    effectManager:addEffect("views2_delay69",upNode)
    temp=views.Shockwave_00000_15_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(7)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",31/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Shockwave_00000_15
    temp:setPosition(0,0)
    temp:setLocalZOrder(8)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",35/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    temp=views.Particle_1
    temp:setPosition(0,0)
    temp:setLocalZOrder(10)
    temp:runAction(ui.action.sequence({{"delay",42/60},"remove"}))
    temp=views.Sparkless_00000_38
    temp:setPosition(0,0)
    temp:setLocalZOrder(11)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",28/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    temp=views.Sparkless_00000_38_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(12)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",38/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    temp=views.Particle_10
    temp:setPosition(0,0)
    temp:setLocalZOrder(15)
    temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
    temp=views.Sprite_2
    temp:setPosition(0,0)
    temp:setLocalZOrder(16)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",15/60,3.0,3.0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
    temp=views.Glow_01_18
    temp:setPosition(0,0)
    temp:setLocalZOrder(17)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    temp=views.Glow_01_18_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(18)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_69}}))

    local function delayFrameIndex_65()
    effectManager:addEffect("views2_delay65",upNode)
    temp=views.Glow_01_6_1
    temp:setPosition(0,0)
    temp:setLocalZOrder(9)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,77},{"fadeTo",30/60,76},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    temp=views.Glow_01_6_0_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(13)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    temp=views.Glow_01_6_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(14)
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    end
    delayFrameIndex_65()

end
--技能友方受体
function ZeusEffect:heroState()
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local direction=self.direction
    local initPos={0,0,0}
    local temp
    local total=self.lastedTime

    if bg.deleted then
        return
    end
    local function delayFrameIndex_70()
    effectManager:addEffect("views3_delay70",bg)
    temp=views.Glow_01_13
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total+20/60},"remove"}))
    temp=views.Glow_01_13_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,197},{"fadeTo",total,195},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total+20/60},"remove"}))
    end
    delayFrameIndex_70()

    local function delayFrameIndex_79()
    effectManager:addEffect("views3_delay79",bg)
    temp=views.Particle_2_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"delay",total+2/60},"remove"}))
    temp=views.Particle_5
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",total+2/60},"remove"}))
    temp=views.Particle_5_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"delay",total+2/60},"remove"}))
    end
    delayFrameIndex_79()
end

function ZeusEffect:initGodSkill()
  local setting={{-36,44},{35,42},{70,89},{-70,89},{-35,42},{36,44}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]

   local ox=setting[direction][1]
   local oy=setting[direction][2]
   local temp

  local function delayFrameIndex_0()
     effectManager:addEffect("godSkill_views1_delay0",bg)
      temp=views.Common_B_00000_2_1
      temp:setPosition(initPos[1]+ox,initPos[2]+oy)
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",35/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))
      temp=views.Common_B_00000_2_0_1
      temp:setPosition(initPos[1]+ox,initPos[2]+oy)
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"delay",35/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))
   end
   delayFrameIndex_0()

   local function delayFrameIndex_60()
     effectManager:addEffect("godSkill_views1_delay60",bg)
      temp=views.Shockwave_00000_8_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.5,0.375},{"scaleTo",5/60,0.8,0.65},{"scaleTo",4/60,1.032,0.882},{"scaleTo",21/60,1.2,1.05}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,66},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Glow_16_6_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,4.8,4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",25/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Glow_16_6_0_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+5)
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,0.7,0.6},{"scaleTo",5/60,6.4,5.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,166},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
      temp=views.Sprite_9_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+6)
      temp:runAction(ui.action.sequence({{"delay",2/60},{"scaleTo",15/60,3.2,2.8},{"scaleTo",3/60,3.3,3.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",7/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",60/60},{"call",delayFrameIndex_60}}))

   local function delayFrameIndex_64()
     effectManager:addEffect("godSkill_views1_delay64",bg)
      temp=views.Glow_16_7_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]-1)
      temp:runAction(ui.action.sequence({{"scaleTo",3/60,0.65,0.55},{"scaleTo",18/60,5.2,4.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,151},{"fadeTo",18/60,110},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
      temp=views.Line_00000_3_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+7)
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",27/60},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Line_00000_3_0_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+8)
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",27/60},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Sharingan_00000_6_0_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+9)
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",21/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",64/60},{"call",delayFrameIndex_64}}))

end
--buff
function ZeusEffect:initGodSkill_buff()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local views=self.views
   local direction=self.direction
   local oy=200
   local initPos={0,oy,10}
   local total=2
   local temp

   local function delayFrameIndex_59()
        if self.attacker.deleted then
            return
        end
     effectManager:addEffect("godSkill_views2_delay59",bg)
      temp=views.Common_B_00000_2_0_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,146},{"fadeTo",17/60,148},{"fadeTo",11/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
   end
   delayFrameIndex_59()

   local function delayFrameIndex_60()
        if self.attacker.deleted then
            return
        end
     effectManager:addEffect("godSkill_views2_delay60",bg)
      temp=views.drf01_1_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",40/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
      temp=views.drf01_1_0_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.9,0.9},{"scaleTo",15/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.drf01_1_0_0_111
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",total-15/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   delayFrameIndex_60()

end
--回血
function ZeusEffect:initGodSkill_huixue()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local views=self.views
   local direction=self.direction
   local initPos={0,0,10}

   local total=2
   local temp


   local function delayFrameIndex_69()
        if self.attacker.deleted then
            return
        end
      effectManager:addEffect("godSkill_views3_delay69",bg)
      temp=views.Particle_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Particle_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Particle_3
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_69}}))
end
--屏幕中间盾
function ZeusEffect:initGodSkill_dun()
   local effectManager=self.effectManager
   local bg = self.attacker.scene.menu.view
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]

  local temp
  local upNode=ui.node({display.winSize[1],display.winSize[2]})
  --upNode:setPosition(display.winSize[1]/2,display.winSize[2]/2)
  display.adapt(upNode, display.winSize[1]/2,display.winSize[2]/2,GConst.Anchor.Center,{scale=ui.getUIScale2()})
  bg:addChild(upNode)
  upNode:runAction(ui.action.sequence({{"delay",131/60},"remove"}))
  local function delayFrameIndex_40()
      effectManager:addEffect("godSkill_views4_delay40",upNode)
      temp=views.base_GF_472_8
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",15/60,255},{"delay",20/60},{"fadeTo",56/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",91/60},"remove"}))
      temp=views.guangci_07_6
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(20/60,60)))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,8.5,8.3894}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",15/60,255},{"delay",45/60},{"fadeTo",31/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",91/60},"remove"}))
      temp=views.guangci_07_6_0
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(20/60,60)))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,8.5,8.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",15/60,102},{"fadeTo",76/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",91/60},"remove"}))

      temp=views.GF_472_4
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,15.0,15.0},{"scaleTo",28/60,23.0,23.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"fadeTo",28/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.GF_472_4_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",7/60,14.0,14.0},{"scaleTo",28/60,20.0,20.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"fadeTo",28/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",40/60},{"call",delayFrameIndex_40}}))

  local function delayFrameIndex_45()
    effectManager:addEffect("godSkill_views4_delay45",upNode)
      temp=views.drf01_2
      temp:runAction(ui.action.sequence({{"delay",15/60},{"scaleTo",52/60,2.0,2.0},{"scaleTo",19/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",15/60,255},{"delay",52/60},{"fadeTo",19/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",86/60},"remove"}))
      temp=views.drf01_2_0
      temp:runAction(ui.action.sequence({{"delay",15/60},{"scaleTo",52/60,2.0,2.0},{"scaleTo",19/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",15/60,178},{"delay",52/60},{"fadeTo",19/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",86/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",45/60},{"call",delayFrameIndex_45}}))

  local function delayFrameIndex_49()
    effectManager:addEffect("godSkill_views4_delay49",upNode)
      temp=views.Boom_00000_11
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,229},{"fadeTo",26/60,255},{"fadeTo",7/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",38/60},"remove"}))
      temp=views.Boom_00000_11_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",26/60},{"fadeTo",7/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",38/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",40/60},{"call",delayFrameIndex_49}}))

end

function ZeusEffect:initExtSkill()
    local bg = self.attacker.scene.effects
    local targetPos = self.targetPos
    local temp
    self.time = 0.1
    temp = ui.animateSprite(0.1, "Lightning_", 5, {beginNum=1, plist="effects/effectsRes/Lightning.plist", isRepeat=false})
    temp:setRotation(90)
    temp:setPosition(targetPos[1], targetPos[2]+1015-(self.groundMode or 0))
    temp:setScaleX(4.1)
    temp:setScaleY(1.2)
    temp:setOpacity(0)
    temp:runAction(ui.action.sequence({{"fadeTo",0.033,230},{"delay",0.033},{"fadeTo",0.033,0},"remove"}))
    ui.setBlend(temp, 1, 0x303)
    self.attacker.scene.effects:addChild(temp, targetPos[3])
    temp = ui.animateSprite(0.1, "Lightning_", 5, {beginNum=1, plist="effects/effectsRes/Lightning.plist", isRepeat=false})
    temp:setRotation(90)
    temp:setPosition(targetPos[1], targetPos[2]+1015-(self.groundMode or 0))
    temp:setScaleX(4.2)
    temp:setScaleY(1.2)
    temp:setOpacity(0)
    temp:runAction(ui.action.sequence({{"fadeTo",0.033,230},{"delay",0.033},{"fadeTo",0.033,0},"remove"}))
    ui.setBlend(temp, 1, 0x301)
    self.attacker.scene.effects:addChild(temp, targetPos[3])

    local bottomNode = self.attacker.scene.bottom
    local upNode = self.attacker.scene.upNode
    temp = ui.sprite("Glow_01.png")
    ui.setColor(temp, 0, 124, 252)
    temp:setPosition(targetPos[1], targetPos[2] + 8)
    temp:setOpacity(0)
    temp:setScaleX(0.5)
    temp:setScaleY(0.425)
    temp:runAction(ui.action.sequence({{"fadeTo",0.033,255},{"fadeTo",0.283,0}}))
    temp:runAction(ui.action.sequence({{"scaleTo",0.033,1,0.85},{"scaleTo",0.283,1.5,1.275},"remove"}))
    upNode:addChild(temp, targetPos[3])

    local function addBombEffect()
        if self.groundMode then
            temp = ui.sprite("Glow_01.png")
            ui.setColor(temp, 0, 105, 255)
            temp:setPosition(targetPos[1], targetPos[2]-self.groundMode)
            temp:setOpacity(205)
            temp:setScaleX(1.4)
            temp:setScaleY(1.19)
            temp:runAction(ui.action.sequence({{"delay",0.1},{"fadeTo",0.6,0},"remove"}))
            bottomNode:addChild(temp, targetPos[3])

            temp=ui.sprite("bombHole.png")
            temp:setPosition(targetPos[1], targetPos[2]-self.groundMode)
            temp:setScaleX(2)
            temp:setScaleY(1.5)
            temp:setOpacity(205)
            temp:runAction(ui.action.sequence({{"delay",0.2},{"fadeTo",0.4,0},"remove"}))
            bottomNode:addChild(temp, targetPos[3])

            temp = ui.sprite("Glow_01.png")
            ui.setColor(temp, 0, 152, 255)
            temp:setPosition(targetPos[1], targetPos[2]-self.groundMode)
            temp:setOpacity(127)
            temp:setScaleX(0.8)
            temp:setScaleY(0.68)
            temp:runAction(ui.action.sequence({{"delay",0.15},{"fadeTo",0.55,0},"remove"}))
            bottomNode:addChild(temp, targetPos[3])

            local bomb = LogicEffects.Bomb
            bomb:runAnimation(upNode, targetPos[1], targetPos[2]-self.groundMode, 1, math.floor(targetPos[1]*4096+targetPos[2]), 8, 2)
        end
        temp = ui.animateSprite(0.2, "Effects_Textures1_", 5, {isRepeat=false})
        temp:setScale(1.2)
        temp:setPosition(targetPos[1], targetPos[2]+5)
        temp:setOpacity(127)
        temp:runAction(ui.action.scaleTo(0.07, 2.4, 2.4))
        temp:runAction(ui.action.sequence({{"delay", 0.06}, {"fadeTo",0.13,0}, "remove"}))
        upNode:addChild(temp, targetPos[3])
        ui.setBlend(temp, 1, 1)

        temp = ui.animateSprite(0.3, "beidaji_", 10, {isRepeat=false})
        temp:setScale(2)
        temp:setPosition(targetPos[1], targetPos[2])
        temp:setRotation(135)
        temp:setOpacity(127)
        temp:runAction(ui.action.sequence({{"delay", 0.06}, {"fadeTo",0.15,0}, "remove"}))
        upNode:addChild(temp, targetPos[3])
        ui.setBlend(temp, 1, 1)
    end
    upNode:runAction(ui.action.sequence({{"delay", 0.09}, {"call", addBombEffect}}))
end

function ZeusEffect:update(diff)
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
