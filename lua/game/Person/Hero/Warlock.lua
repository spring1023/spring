local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    --召唤物攻击
    if self.C.params.isZhaoHuan then
        WarlockEffect.new({attacker = self, mode = 2, target = attackTarget},callback)
    else
        local mode = 0
        if isSkill then
            mode = 1
        end
        WarlockEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
    end
end

local C = class(AvtControler)

--取得person周围n个范围内的敌方英雄和佣兵
local function getHeroAndSoldier(person, n)
    local targetG = {}
    local enemySoldier = person:getCircleTarget(person, person.battleMap.mer, n)
    local enemyHero = person:getCircleTarget(person, person.battleMap.hero, n)
    for _,v in ipairs(enemySoldier) do
        table.insert(targetG, v)
    end
    for _,v in ipairs(enemyHero) do
        table.insert(targetG, v)
    end
    return targetG
end

--[[4008 术士 主动技能
原版:在当前攻击目标处召唤地狱火，地狱火血量为术士的c%，攻击力为d%，减少e%受到的伤
    害，持续时间y秒，消耗x怒，冷却时间z秒
改版:在当前攻击目标处召唤地狱火，地狱火享有星际术士[c]%的生命值，[d]%的攻击力，
    且受到伤害时伤害减免[e]%，召唤持续时间[y]秒，地狱火会持续灼烧周围n格范围内目标，
    造成自身攻击f%的伤害，消耗[x]怒，冷却时间[z]秒]]--
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local viewInfo = self.attackTarget.battleViewInfo or (self.battleMap:getSoldierBattleViewInfoReal(self.attackTarget))
    local tx,ty = viewInfo[1],viewInfo[2]
    local ps = self.actSkillParams
    local hpAddRate, liveTime = ps.c, ps.y
    --守护技:在防守时，召唤的地狱火和巨型地狱火生命值增加[x]%，持续时间增加[y]%。
    if self.person.awakeData2 and self.groupData.isDef and self.targetGrid then
        local ps2 = self.person.awakeData2.ps
        hpAddRate = (hpAddRate/100) * (1+ps2.x/100)*100
        liveTime = liveTime * (1+ps2.y/100)
    end
    local role = SkillPlugin.summonTroop(self.params.person, self.params.group,
            tx, ty, {atkPercent=ps.d, hpPercent=hpAddRate, summonTime=liveTime, master=self, acid=8})
        --普通分身效果
        self.V:addFenShenEff(role.V)
    role.M.defenseParam = role.M.defenseParam*(1-ps.e/100) --减伤率

    --灼烧
    local targetG = getHeroAndSoldier(role, ps.n)
    for _,v in ipairs(targetG) do
        BuffUtil.setBuff(v,{lastedTime=ps.y, lastAddHp=-ps.f/100*role.M.base_atk})
    end
end

local function _doUpdateGod1(self, diff)
    --天神技巨型地狱火每隔a秒吞噬等相关逻辑
    local ps = self.person.awakeData.ps
    self.count = (self.count or 0) + diff--吞噬计时器
    if self.count >= ps.a then
        local enemyHero = self:getCircleTarget(self, self.battleMap.hero, ps.m) or {}--m格内敌方英雄
        local targetHero = {}--敌方普通召唤物
        for _,v in ipairs(enemyHero) do
            if v.params.isZhaoHuan and not v.params.isGodZhaoHuan and v.avtInfo.immune <= 0 then
                table.insert(targetHero, v)
            end
        end
        local target
        if #targetHero == 0 then
            local targetSoldier = self:getCircleTarget(self, self.battleMap.mer, ps.m) or {}--m格内敌方佣兵
            for _,v in ipairs(targetSoldier) do
                if v.avtInfo.immune <= 0 then
                    table.insert(targetHero, v)
                end
            end
            if #targetHero == 0 then
                return
            end
        end
        target = targetHero[self.rd:randomInt(#targetHero)]
        target:damage(10000000)
        if self.avater.personView2 then
            if self._scaleCount < 5 then
                self._scaleCount = self._scaleCount + 1
                local scale = self.avater.personView2:getScaleX() * 1.2
                self.avater.personView2:setScale(scale)

                scale = self.avater._effect1:getScaleX()
                self.avater._effect1:setScale(scale * 1.2)
                -- self.avater._effect1:setPositionY(self.avater._effect1:getPositionY() * scale * 1.2)

                scale = self.avater._effect2:getScaleX()
                self.avater._effect2:setScale(scale * 1.2)
            end
        end
        self:damage(-self.avtInfo.maxHp * ps.o / 100)
        self.M.atk = self.M.atk + self.M.base_atk*ps.z/100
        self.count = self.count - ps.a
    end

    --嘲讽
    local timer = self.timer or 0.5--每0.5秒让地狱火找一次嘲讽目标
    timer = timer - diff
    if timer <= 0 then
        self.timer = self.timer + 0.5
        local target = getHeroAndSoldier(self, ps.n)
        for _,v in ipairs(target) do
            if v.attackTarget == self.master then
                v.lockTarget = self--嘲讽
            end
        end
    else
        self.timer = timer
    end
end

function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

--[[开场后[cd]秒可释放，从天而降巨型地狱火砸晕[n]格范围内目标[t]秒，其攻
击力为术士的[x]%，血量为[p]%且拥有减免伤害[y]%，持续时间[k]秒，每[a]秒吞
噬周围[m]格范围内一只佣兵或召唤物（优先），成功吞食则增加自身[z]%攻击力和
回复自身[o]%生命值，地狱火会持续嘲讽正在攻击术士的[n]格内的敌对目标。]]--
function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    local hpAddRate, liveTime = ps.p, ps.k
    local viewInfo = self.attackTarget.battleViewInfo or (self.battleMap:getSoldierBattleViewInfoReal(self.attackTarget))
    local tx,ty = viewInfo[1],viewInfo[2]
    if self.person.awakeData2 and self.groupData.isDef and self.targetGrid then
        local ps2 = self.person.awakeData2.ps
        hpAddRate = (hpAddRate/100) * (1+ps2.x/100)*100
        liveTime = liveTime * (1+ps2.y/100)
    end
    local role = SkillPlugin.summonTroop(self.params.person, self.params.group,
            tx, ty, {atkPercent=ps.x, hpPercent=hpAddRate, summonTime=liveTime, master=self, acid=9})
        --普通分身效果
        self.V:addFenShenEff(role.V)
    role._scaleCount = 0
    if role.V.personView2 then
        role.V.personView2:setHValue(-150)
        role.V.personView2:setSValue(12)
        role.V.personView2:setLValue(2)
    else
        role.hsl = {-150, 12, 2}
    end
    role.params.isGodZhaoHuan = true
    role.M.defenseParam = role.M.defenseParam*(1-ps.y/100) --减伤率
    LGBT.addComponentFunc(role, "updateComponent", _doUpdateGod1)

    --巨型地狱火的出场特效
    local p = {role.avater.view:getPosition()}
    p[3] = General.sceneHeight - p[2]
    local bg = role.avater.view
    local temp = ui.simpleCsbEffect("UICsb/HeroEffect_4008/a_1.csb")
    display.adapt(temp,0,100,GConst.Anchor.Center)
    temp:setScale(1.8)
    bg:addChild(temp,p[3]+100)
    role.avater._effect1 = temp
    temp = ui.simpleCsbEffect("UICsb/HeroEffect_4008/c_0.csb")
    display.adapt(temp,0,0,GConst.Anchor.Center)
    bg:addChild(temp,p[3]+100)
    role.avater._effect2 = temp

    --砸晕敌方英雄和佣兵
    local target = getHeroAndSoldier(role, ps.n)
    for _,v in ipairs(target) do
        BuffUtil.setBuff(v,{lastedTime = ps.t,bfDizziness = ps.t})--砸晕
        if v.sid and v.sid >= 1000 then
            Vertigo.new(v.BV.view, 0, v.BV.animaConfig.Ymove, v.BV.M.bfDizziness)
        end
    end
end


WarlockEffect = class()

function WarlockEffect:ctor(params,callback)
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

function WarlockEffect:initParams(params)
    self.effectManager=GameEffect.new("WarlockEffect.json")
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

function WarlockEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:initZhaoHuanAttack()
    end
end

function WarlockEffect:initAttack()
    local setting={{41,5},{92,64},{47,120},{-47,120},{-92,64},{-41,5}}
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

    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+10000)
    moveNode:setVisible(false)
    moveNode:setRotation(r)
    local function showTargetBao()
    self:createViews_2()
    end
    local function delayFrameIndex_24()
    effectManager:addEffect("views1_delay24",moveNode)
    temp=views.Particle_1
    temp:setRotation(-90)
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp=views.Particle_1_0
    temp:setRotation(-90)
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    end
    delayFrameIndex_24()

    local function delayFrameIndex_20()
    moveNode:setVisible(true)
    moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
    effectManager:addEffect("views1_delay20",moveNode)
    temp=views.Glow_01_7
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
    temp=views.Glow_01_7_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,191},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end
--普攻受体
function WarlockEffect:createViews_2()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.targetPos
    local temp

    effectManager:addEffect("views2_delay54",bg)
    temp=views.Glow_01_7_b
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_7_0_b
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,191},{"delay",9/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.person_Glow_01_9
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,2.0,2.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))

end

function WarlockEffect:initSkill()
    local setting={20,0,-20,-20,0,20}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]
    initPos[2]=self.initPos[2]+setting[direction]
    initPos[3]=self.initPos[3]
    local temp

    local function delayFrameIndex_59()
    effectManager:addEffect("views3_delay59",bg)
    temp=views.Particle_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",24/60},{"call",delayFrameIndex_59}}))

    local function delayFrameIndex_50()
    effectManager:addEffect("views3_delay50",bg)
    temp=views.Line_00000_23
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",20/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_50}}))

    local function delayFrameIndex_35()
    effectManager:addEffect("views3_delay35",bg)
    temp=views.Glow_01_20
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",40/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
    temp=views.Magic_Circle_Hue220_19
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",40/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
    temp=views.Glow_01_20_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",40/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
    temp=views.Glow_01_20_0_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,178},{"fadeTo",40/60,179},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_35}}))

    self:createViews_4()
end

function WarlockEffect:createViews_4()
    self.time = 54/60
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.targetPos
    local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(1.5)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",142/60},"remove"}))

    local function delayFrameIndex_49()
    effectManager:addEffect("views4_delay49",upNode)
    temp=views.Circle_Hue130_3
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.4,0.3},{"scaleTo",10/60,0.6,0.45}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Glow_01_14_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",35/60,3.0,2.25}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",35/60},{"fadeTo",18/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",54/60},"remove"}))
    temp=views.Glow_01_14_0_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(5)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",35/60,1.5,1.125}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",35/60},{"fadeTo",18/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",54/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",49/60},{"call",delayFrameIndex_49}}))

    local function delayFrameIndex_54()
    effectManager:addEffect("views4_delay54",upNode)
    temp=views.Smoke_00000_2
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"delay",18/60},{"fadeTo",12/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    temp=views.Smoke_00000_2_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",7/60,255},{"delay",18/60},{"fadeTo",12/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",54/60},{"call",delayFrameIndex_54}}))
end
--召唤物攻击
function WarlockEffect:initZhaoHuanAttack()
    self.time = 10/60
    local setting={{89,-71},{216,55},{135,200},{-135,200},{-216,55},{-89,-71}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local temp

    local function delayFrameIndex_139()
    effectManager:addEffect("views4_delay139",bg)
    temp=views.Impact_Purple_00000_2_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+6)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",18/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
    temp=views.Glow_01_3_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+7)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",8/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
    temp=views.Glow_01_3_0_a
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,204},{"delay",15/60},{"fadeTo",13/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
    end
    delayFrameIndex_139()
end

function WarlockEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    if not self.time then
        self.time = 0
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




















