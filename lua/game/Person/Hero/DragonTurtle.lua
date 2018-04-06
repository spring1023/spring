

local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    local y = 4
    DragonTurtleEffect.new({attacker = self, mode = mode, target = attackTarget, lastedTime = self.C.actSkillParams.y},callback)
end

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self:attack(viewInfo1,viewInfo2,b)
    self.allActionTime = self.allActionTime+self.oneFrameTime*(self.skillStopNum-1)
    --通用特效
    local off={[4001]={1,40,1},[4002]={1,60,1},[4003]={1,50,1},[4005]={1,60,1},[4007]={1,40,1},[4008]={1,50,1},[4009]={1,50,1},[4010]={1,70,1},
                [4011]={1,70,1},[4012]={1,50,1},[4013]={1,70,2},[4014]={1,50,1},[4015]={1,50,1},[4016]={1,70,1},[4017]={1,70,1},[4018]={1,70,1},
                [4019]={1,70,1},[4020]={1,60,1.5},[4021]={1,70,1.5},[4022]={1,70,1},[4023]={1,70,1},[4024]={1,40,1},
                [1001]={4,40,1.2},[1002]={4,40,1},[1003]={4,50,1},
                [2001]={3,50,1.5},[2002]={3,40,1},[2003]={3,40,1},[2004]={3,60,1},[2005]={3,50,1},
                [3001]={2,50,1},[3002]={2,60,1.2},[3003]={2,50,1},[3004]={2,50,1},[3005]={2,40,1},[3006]={2,40,1},[3007]={2,10,1},[3008]={2,40,1}}
    local id = self.id
    if off[id] then
        local mode,oy,scal=off[id][1],off[id][2],off[id][3]
        self:currencyEffect(mode,oy,scal)
    end
    self.state = PersonState.SKILL
end

function V:sg_godSkillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self:attack(viewInfo1,viewInfo2,b)
    self.allActionTime = self.allActionTime+self.oneFrameTime*(self.skillStopNum-1)
    --通用特效
    local off={[4001]={1,40,1},[4002]={1,60,1},[4003]={1,50,1},[4005]={1,60,1},[4007]={1,40,1},[4008]={1,50,1},[4009]={1,50,1},[4010]={1,70,1},
                [4011]={1,70,1},[4012]={1,50,1},[4013]={1,70,2},[4014]={1,50,1},[4015]={1,50,1},[4016]={1,70,1},[4017]={1,70,1},[4018]={1,70,1},
                [4019]={1,70,1},[4020]={1,60,1.5},[4021]={1,70,1.5},[4022]={1,70,1},[4023]={1,70,1},[4024]={1,40,1},
                [1001]={4,40,1.2},[1002]={4,40,1},[1003]={4,50,1},
                [2001]={3,50,1.5},[2002]={3,40,1},[2003]={3,40,1},[2004]={3,60,1},[2005]={3,50,1},
                [3001]={2,50,1},[3002]={2,60,1.2},[3003]={2,50,1},[3004]={2,50,1},[3005]={2,40,1},[3006]={2,40,1},[3007]={2,10,1},[3008]={2,40,1}}
    local id = self.id
    if off[id] then
        local mode,oy,scal=off[id][1],off[id][2],off[id][3]
        self:currencyEffect(mode,oy,scal)
    end
    self.state = PersonState.GODSKILL
end

function V:spmoveDirect(tx,ty,speed)
    self.moveComplete = false
    self.targetPoint = {tx, ty}
    local fx,fy = self.gx,self.gy
    self.moveDirection = {tx-fx,ty-fy}
    self.allActionTime = math.sqrt(self.moveDirection[1]*self.moveDirection[1]+self.moveDirection[2]*self.moveDirection[2])/speed
    self:changeDirection(tx, ty)
    self.loop = true
    self.frameFormat = self.animaConfig.skill_fmt[1]
    self.animaTime = 0
    self.frameIndex = 0
    self.oneFrameTime = self.animaConfig.skill_params[1][1]/self.animaConfig.skill_params[1][2]
    self.frameMaxIndex = self.animaConfig.skill_params[1][2]
    self.actionTime = 0
    self.state = PersonState.SPMOVING
end

local C = class(AvtControler)
--4020    龙龟   主动技能36  持续y秒内，使自身5格半径范围内的敌人攻击自己，立即恢复c%的血量并减伤d%，反弹e%的伤害，己方英雄3秒内减伤f%，消耗X怒，冷却z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local y,c,d,e,f = params.y,params.c or 10,params.d,params.sg_exeSkill,params.f
    local result = self:getCircleTarget(self,self.battleMap.battler,5)
    self.lockTime = y
    for k,v in pairs(result) do
        v.lockTarget = self
        DragonTurtleEffect.new({attacker = self.avater, mode = 2, target = v,lastedTime = y})
    end
    self.lockGroup = result

    BuffUtil.setBuff(self,{lastedTime = y,bfDefPct = d,bfRebound = e})

    local value = BattleUtil.getHeal(self,self,0,c)
    self:damage(value)

    for i,v in ipairs(self.battleMap2.hero) do
        BuffUtil.setBuff(v,{lastedTime = 3,bfDefPct = f})
        if v.person and v.person.equip then
        else
            DragonTurtleEffect.new({attacker = self.avater, mode = 3, target = v,lastedTime = 3})
        end
    end
end

function C:sg_updateBattle(diff)
    if self.lockTime then
        if not self.allLockTime then
            self.allLockTime = 0
        end
        self.allLockTime = self.allLockTime+diff
        if self.allLockTime>self.lockTime then
            for k,v in pairs(self.lockGroup) do
                if v.attackTarget == self then
                    v.shouldReCheck = true
                end
            end
            self.lockTime = nil
            self.allLockTime = nil
            self.musicTime = nil
        else
            if not self.musicTime then
                self.musicTime = 0
            end
            self.musicTime = self.musicTime+diff
            if self.musicTime>=0.8 then
                self.musicTime = 0
                if self.V.animaConfig.skill_music2 then
                    music.play("sounds/" .. self.V.animaConfig.skill_music2)
                end
            end
        end
    end
    
    --当进攻方投放英雄达到[m]个时，英雄会主动出击飞向最近的敌人造成[a]+[x]%自身攻击力的半径[n]格范围伤害，并降低其[y]%的移速持续[t]秒，同时自身无敌[k]秒。
    if self:checkGodSkill2(true) then
        if not self.isAddedHero then
            self.isAddedHero = {}
            self.isAddedHeroNum = 0
        end
        local group = self.battleMap.hero
        if DEBUG.DEBUG_GODSKILL2 then
            group = self.battleMap2.hero
        end
        local ps = self.person.awakeData2.ps
        for k,v in pairs(group) do
            if not v.params.isZhaoHuan and not v.params.isRebirth then
                if not self.isAddedHero[v] then
                    self.isAddedHeroNum = self.isAddedHeroNum+1
                    if self.isAddedHeroNum>=ps.m then
                        self:checkGodSkill2()
                        local ret = self:getMinDisTarget(1)
                        local target = ret[1]
                        if target then
                            self:resetFree()
                            local viewInfo = target.battleViewInfo or (self.battleMap:getSoldierBattleViewInfoReal(target))
                            self.V:spmoveDirect(viewInfo[1],viewInfo[2],14)
                            BuffUtil.setBuff(self,{lastedTime=ps.k, immune=ps.k})
                            self.scene.replay:addDelay(function()
                                local px,py = self.scene.map.convertToPosition(viewInfo[1],viewInfo[2])
                                Explosion2.new(self.scene.objs,px,py,ps.n)
                                self.shouldReCheck = true
                                local ret = self:getCircleTarget(viewInfo,self.battleMap.battlerAll,ps.n)
                                for k,v in ipairs(ret) do
                                    SkillPlugin.exe2(self,v,ps.a,ps.x)
                                    BuffUtil.setBuff(v,{lastedTime=ps.t, bfMovePct=-ps.y})
                                end
                            end,self.V.allActionTime)
                            Invincible.new(self.V.view,0,0,self.V.allActionTime)
                        end
                    end
                end
            end
        end
    end

end

--天神技 对自身半径[n]格范围内的地面敌人造成[a]+[x]%自身攻击力的伤害，同时眩晕[t]秒，并在[k]秒内清除敌人的增益状态。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    local tg = self:getCircleTarget(self,self.battleMap.battlerAll,ps.n)
    for i,v in ipairs(tg) do
        SkillPlugin.exe2(self,v,ps.a,ps.x)
        BuffUtil.setBuff(v,{lastedTime = ps.t,bfDizziness = ps.t})
        BuffUtil.setBuff(v,{lastedTime = ps.k,clearGain = ps.k})
    end

end
function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    DragonTurtleEffect.new({attacker = self, mode = 4, target = attackTarget,lastedTime = self.C.actSkillParams.y},callback)
end


DragonTurtleEffect = class()

function DragonTurtleEffect:ctor(params,callback)
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

function DragonTurtleEffect:initParams(params)
    self.effectManager=GameEffect.new("DragonTurtleEffect.json")
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

function DragonTurtleEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:targetState()
    elseif self.mode == 3 then
        self:initSkillHuDun()
    elseif self.mode==4 then
        self.time = 0.1
        self:initGodSkill()
        --self:initGodSkill_target()
    end
end

function DragonTurtleEffect:initAttack()
    self.time = 0
    local setting={{78,-92,1},{162,7,1},{81,118,-1},{-81,118,-1},{-162,7,1},{-78,-92,1}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]+setting[direction][3]*20
    
    local temp

    local function delayFrameIndex_24()
    effectManager:addEffect("views2_delay24",bg)
    temp=views.Glow_01_7_0_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-2)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.5,1.125}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,170},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Shockwave_6_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,0.88},{"scaleTo",10/60,1.2,1.056}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Sparkless_00000_4_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10001)
    temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Sparkless_00000_4_0_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10002)
    temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Sparkless_00000_4_1_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10003)
    temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Sparkless_00000_4_0_0_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10004)
    temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Boom_10_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10005)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.7,0.7}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
    temp=views.Boom_10_0_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10006)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.7,0.7}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,165},{"fadeTo",5/60,166},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
    temp=views.Glow_01_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10007)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,128},{"fadeTo",10/60,126},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    end
    delayFrameIndex_24()
end

function DragonTurtleEffect:initSkill()
    self.time = 0.1
    local settingOY={0,10,40,40,10,0}
    local setting={{78,-92,1},{162,7,1},{81,118,-1},{-81,118,-1},{-162,7,1},{-78,-92,1}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local bg2 = self.attacker.view
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]
    initPos[2]=self.initPos[2]+settingOY[direction]
    initPos[3]=self.initPos[3]
    local initPos2={}
    initPos2[1]=self.initPos[1]+setting[direction][1]
    initPos2[2]=self.initPos[2]+setting[direction][2]
    initPos2[3]=self.initPos[3]+setting[direction][3]*20
    local temp
    local z=0
    local tatol = self.lastedTime

    local downNode=ui.node()
    downNode:setPosition(0,0)
    bg2:addChild(downNode,-10)
    downNode:setScale(1.2)
    downNode:runAction(ui.action.sequence({{"delay",30/60+tatol},"remove"}))
    local upNode=ui.node()
    upNode:setPosition(0,0)
    bg2:addChild(upNode,10)
    upNode:setScale(1.2)
    upNode:runAction(ui.action.sequence({{"delay",30/60+tatol},"remove"}))

    local function delayFrameIndex_75()
    effectManager:addEffect("views1_delay75",downNode)
    temp=views.Glow_01_9
    temp:setPosition(16,-18)
    temp:setLocalZOrder(-5)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,204},{"delay",tatol-25/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Glow_01_9_1
    temp:setPosition(16,-18)
    temp:setLocalZOrder(-4)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,204},{"delay",tatol-25/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Glow_01_9_0
    temp:setPosition(16,-18)
    temp:setLocalZOrder(-3)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"scaleTo",25/60,1.0,0.75},{"scaleTo",50/60,1.0,0.75},{"scaleTo",25/60,0.5,0.375}})))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,204},{"delay",110/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Ground_Wave_00000_8
    temp:setPosition(17,-5)
    temp:setLocalZOrder(-2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",tatol-25/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Ground_Wave_00000_8_0
    temp:setPosition(17,-5)
    temp:setLocalZOrder(-1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",tatol-25/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    effectManager:addEffect("views1_delay75_up",upNode)
    temp=views.Shield_00000_5
    temp:setPosition(15,57)
    temp:setLocalZOrder(15)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",tatol-20/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    end
    downNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_75}}))

    local function delayFrameIndex_84()
    effectManager:addEffect("views1_delay84",bg)
    temp=views.Particle_2
    temp:setPosition(initPos[1]+22,initPos[2]-12)
    temp:setLocalZOrder(initPos[3]+z+14)
    temp:runAction(ui.action.sequence({{"delay",102/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",34/60},{"call",delayFrameIndex_84}}))

    local function delayFrameIndex_54()
    effectManager:addEffect("views1_delay54",bg)
    temp=views.Glow_01_7
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]-10)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,3.5,2.625}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,126},{"fadeTo",30/60,127},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
    temp=views.Glow_01_7_0
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]-9)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,3.5,2.625}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
    temp=views.Shockwave_6
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]-8)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,0.88},{"scaleTo",10/60,1.2,1.056}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Sparkless_00000_4
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+6)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Sparkless_00000_4_0
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+7)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Sparkless_00000_4_1
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+8)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Sparkless_00000_4_0_0
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+9)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Boom_10
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+10)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
    temp=views.Boom_10_0
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+11)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,165},{"fadeTo",5/60,166},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_54}}))

    local function delayFrameIndex_55()
    effectManager:addEffect("views1_delay55",bg)
    temp=views.Stone_00000_9
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+4)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",27/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
    temp=views.Stone_00000_9_0
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+5)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",27/60},{"fadeTo",3/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_55}}))

    local function delayFrameIndex_59()
    effectManager:addEffect("views1_delay59",bg)
    temp=views.Crack_1
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]-7)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",21/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    temp=views.Crack_1_0
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]-6)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",21/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    temp=views.Glow_01_10
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+13)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_59}}))

    local function delayFrameIndex_60()
    effectManager:addEffect("views1_delay60",bg)
    temp=views.Particle_1
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+12)
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_60}}))
end

function DragonTurtleEffect:initSkillHuDun()
    local settingOY={0,10,40,40,10,0}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local bg2 = self.target.avater.view
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]
    initPos[2]=self.initPos[2]+settingOY[direction]
    initPos[3]=self.initPos[3]
    local temp
    local z=0
    local tatol = self.lastedTime

    local downNode=ui.node()
    downNode:setPosition(0,0)
    bg2:addChild(downNode,-10)
    downNode:setScale(1.2)
    downNode:runAction(ui.action.sequence({{"delay",30/60+tatol},"remove"}))
    local upNode=ui.node()
    upNode:setPosition(0,0)
    bg2:addChild(upNode,10)
    upNode:setScale(1.2)
    upNode:runAction(ui.action.sequence({{"delay",30/60+tatol},"remove"}))

    local function delayFrameIndex_75()
    effectManager:addEffect("views1_delay75",downNode)
    temp=views.Glow_01_9
    temp:setPosition(16,-18)
    temp:setLocalZOrder(-5)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,204},{"delay",tatol-25/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Glow_01_9_1
    temp:setPosition(16,-18)
    temp:setLocalZOrder(-4)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,204},{"delay",tatol-25/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Glow_01_9_0
    temp:setPosition(16,-18)
    temp:setLocalZOrder(-3)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",15/60},{"scaleTo",25/60,1.0,0.75},{"scaleTo",50/60,1.0,0.75},{"scaleTo",25/60,0.5,0.375}})))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,204},{"delay",110/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Ground_Wave_00000_8
    temp:setPosition(17,-5)
    temp:setLocalZOrder(-2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",tatol-25/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Ground_Wave_00000_8_0
    temp:setPosition(17,-5)
    temp:setLocalZOrder(-1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",tatol-25/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    effectManager:addEffect("views1_delay75_up",upNode)
    temp=views.Shield_00000_5
    temp:setPosition(15,57)
    temp:setLocalZOrder(15)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",tatol-20/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    end
    downNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_75}}))

end

function DragonTurtleEffect:targetState()
    local effectManager=self.effectManager
    local bg=self.target.avater and self.target.avater.view or self.target.view
    local obj = self.target.avater or self.target
    local views=self.views
    local ox,oy=0,0
    if not self.target.avater and self.target.view then
        ox=self.target.view:getContentSize().width/2
        oy=self.target.view:getContentSize().height/2
    end
    local initPos={ox,oy,0}
    local temp
    local tatol = self.lastedTime
    local tatol = 3

    local function delayFrameIndex_80()
        if obj.deleted then
            return
        end
    effectManager:addEffect("views3_delay80",bg)
    temp=views.Taunt_1_3
    temp:setPosition(initPos[1]+3,initPos[2]+155)
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",tatol-15/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    end

    self.delayNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_80}}))

    local function delayFrameIndex_74()
        if obj.deleted then
            return
        end
    effectManager:addEffect("views3_delay74",bg)
    temp=views.Glow_01_4
    temp:setPosition(initPos[1]+4,initPos[2]+150)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,127},{"delay",10/60},{"fadeTo",10/60,0}})))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Glow_01_4_0
    temp:setPosition(initPos[1]+4,initPos[2]+150)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255},{"delay",110/60},{"fadeTo",15/60,0}})))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Circle_Hue130_5
    temp:setPosition(initPos[1]+4,initPos[2]+157)
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.15,0.15},{"scaleTo",15/60,0.2,0.2}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"delay",5/60},{"fadeTo",10/60,0}})))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    temp=views.Circle_Hue130_5_0
    temp:setPosition(initPos[1]+4,initPos[2]+157)
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.15,0.15},{"scaleTo",15/60,0.2,0.2}})))
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"delay",5/60},{"fadeTo",10/60,0}})))
    temp:runAction(ui.action.sequence({{"delay",tatol},"remove"}))
    end

    self.delayNode:runAction(ui.action.sequence({{"delay",24/60},{"call",delayFrameIndex_74}}))

    local function delayFrameIndex_60()
        if obj.deleted then
            return
        end
    effectManager:addEffect("views3_delay60",bg)
    temp=views.Trail_00000_7
    temp:setPosition(initPos[1]-2,initPos[2]+73)
    temp:setLocalZOrder(initPos[3]+6)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    end

    self.delayNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_60}}))

    local function delayFrameIndex_50()
        if obj.deleted then
            return
        end
    effectManager:addEffect("views3_delay50",bg)
    temp=views.Glow_01_8
    temp:setPosition(initPos[1]+9,initPos[2]+46)
    temp:setLocalZOrder(initPos[3]+7)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",25/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
    temp=views.Glow_01_8_0
    temp:setPosition(initPos[1]+9,initPos[2]+46)
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",25/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
    end

    delayFrameIndex_50()
end

function DragonTurtleEffect:initGodSkill()
  local setting={{78,-92,1},{162,7,1},{81,118,-1},{-81,118,-1},{-162,7,1},{-78,-92,1}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(1.5)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

    local downNode=ui.node()
    downNode:setPosition(initPos[1],initPos[2])
    downNode:setScale(1.5)
    bg:addChild(downNode,initPos[3]-10)
    downNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_23()
     effectManager:addEffect("godSkill_views1_delay23",upNode)
      temp=views.Impact_00002_4
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",17/60},{"scaleTo",9/60,3,3},{"scaleTo",16/60,4,4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",12/60,255},{"delay",30/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",43/60},"remove"}))
      temp=views.Impact_00002_4_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",17/60},{"scaleTo",9/60,3,3},{"scaleTo",16/60,4,4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",12/60,255},{"delay",30/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",43/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",3/60},{"call",delayFrameIndex_23}}))

   local function delayFrameIndex_24()
     effectManager:addEffect("godSkill_views1_delay24",downNode)
      temp=views.Sprite_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(-4)
      temp:runAction(ui.action.sequence({{"delay",6/60},{"scaleTo",20/60,1.4,1.3}}))
      temp:runAction(ui.action.sequence({{"delay",1/60},{"fadeTo",35/60,127},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_24}}))

   local function delayFrameIndex_25()
     effectManager:addEffect("godSkill_views1_delay25",downNode)
      temp=views.Glow_02_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(-9)
      temp:runAction(ui.action.sequence({{"scaleTo",7/60,1.3,1.3},{"scaleTo",13/60,1.4,1.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",7/60,255},{"fadeTo",13/60,0}}))
      temp:runAction(ui.action.sequence({"remove"}))
      temp=views.Dankeng_15_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(-8)
      temp:runAction(ui.action.sequence({{"scaleTo",3/60,1.0,0.9},{"scaleTo",1/60,1.2,1.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",50/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",65/60},"remove"}))
      temp=views.Shockwave_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(-7)
      temp:runAction(ui.action.sequence({{"scaleTo",20/60,0.75,0.75},{"scaleTo",10/60,0.9,0.9}}))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",5/60},{"fadeTo",10/60,0},{"delay",1/60}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
      temp=views.Glow_01_19
      temp:setPosition(0,0)
      temp:setLocalZOrder(-5)
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.2,1.2},{"scaleTo",20/60,1.3,1.3}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Shockwave_00000_32_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(-3)
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.1,1.0},{"scaleTo",10/60,1.2,1.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,186},{"fadeTo",15/60,255},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Stone_00000_10
      temp:setPosition(0,0)
      temp:setLocalZOrder(-2)
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",27/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",34/60},"remove"}))
      temp=views.Stone_00000_10_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(-1)
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",27/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",34/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_25}}))

   local function delayFrameIndex_40()
     effectManager:addEffect("godSkill_views1_delay40",downNode)
      temp=views.Shockwave_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(-6)
      temp:runAction(ui.action.sequence({{"scaleTo",20/60,0.75,0.75},{"scaleTo",10/60,0.9,0.9}}))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",5/60},{"fadeTo",10/60,0},{"delay",1/60}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_40}}))
end

function DragonTurtleEffect:initGodSkill_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.targetPos[1]
   initPos[2]=self.targetPos[2]
   initPos[3]=self.targetPos[3]+100000
   local oy=120
   local total=self.lastedTime
   local temp

   local function delayFrameIndex_30()
     effectManager:addEffect("godSkill_views2_delay30",bg)
      temp=views.Fire_Impact_00001_29
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",16/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
      temp=views.Stone_00000_27
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",25/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
      temp=views.Glow_02_28
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"delay",2/60},{"scaleTo",10/60,0.8,0.8},{"scaleTo",1/60,0.81,0.81},{"scaleTo",9/60,0.9,0.9}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Sparkless_00001_34
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_30}}))

   local function delayFrameIndex_45()
     effectManager:addEffect("godSkill_views2_delay45",bg)
      temp=views.Vertigo_00000_18
      temp:setPosition(initPos[1],initPos[2]+oy)
      temp:setLocalZOrder(initPos[3]+5)
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   self.delayNode:runAction(ui.action.sequence({{"delay",35/60},{"call",delayFrameIndex_45}}))
end

function DragonTurtleEffect:update(diff)
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

--防御天神技特效
Invincible=class()
function Invincible:ctor(bg,x,y,lastedTime)
    self.effectManager=GameEffect.new("Invincible.json")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,0}
    self.targetPos={x+400,y-400,0}
    self.lastedTime = lastedTime
    self:initEffect()
end
function Invincible:initEffect()
    self:createViews_1()
end
function Invincible:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]

   local total=self.lastedTime
   local temp

    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",230/60},"remove"}))

  local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]+10)
   downNode:runAction(ui.action.sequence({{"delay",230/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",downNode)
      temp=views.Glow_02_16
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,1.8,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",total-20/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Glow_02_16_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,1.8,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",total-20/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Shockwave_18
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",15/60,0.8,0.8},{"scaleTo",25/60,1.0,1.0},{"scaleTo",55/60,0.01,0.01}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,255},{"fadeTo",25/60,0},{"delay",55/60}})))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))

       effectManager:addEffect("views1_delay0_up",upNode)
      temp=views.Gundam_Shield_3
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,76},{"fadeTo",total-25/60,206},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Gundam_Shield_3_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"fadeTo",total-25/60,76},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_30()
     effectManager:addEffect("views1_delay30",downNode)
      temp=views.Shockwave_18_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",15/60,0.8,0.8},{"scaleTo",25/60,1.0,1.0},{"scaleTo",60/60,0.01,0.01}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,255},{"fadeTo",25/60,0},{"delay",60/60}})))
      temp:runAction(ui.action.sequence({{"delay",total-30/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_30}}))

   local function delayFrameIndex_60()
     effectManager:addEffect("views1_delay60",downNode)
      temp=views.Shockwave_18_0_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",15/60,0.8,0.8},{"scaleTo",25/60,1.0,1.0},{"scaleTo",65/60,0.01,0.01}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,255},{"fadeTo",25/60,0},{"delay",65/60}})))
      temp:runAction(ui.action.sequence({{"delay",total-60/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",60/60},{"call",delayFrameIndex_60}}))

end

Explosion2=class()
function Explosion2:ctor(bg,x,y,sc,attackMode,direction)
    self.effectManager=GameEffect.new("Explosion2.json")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,10000}
    self.targetPos={x+400,y-400,0}
    self.attackMode=attackMode
    self.direction=direction
    self.sc = sc
    self:initEffect()
end
function Explosion2:initEffect()
    self:createViews_1()
end
function Explosion2:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local temp

  local upNode=ui.node()
  upNode:setScale(self.sc/2)
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

   local function delayFrameIndex_25()
     effectManager:addEffect("views1_delay25",upNode)
      temp=views.Glow_02_14
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,2.3,2.3},{"scaleTo",19/60,2.5,2.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",19/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Impact_00000_11
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",10/60},{"delay",25/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.Impact_00000_11_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",35/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.Shockwave_15
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.0,1.0},{"scaleTo",15/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_25}}))

   local function delayFrameIndex_29()
     effectManager:addEffect("views1_delay29",upNode)
      temp=views.Sparkless_00000_13
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",15/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_29}}))

end









return {M,V,C}



























