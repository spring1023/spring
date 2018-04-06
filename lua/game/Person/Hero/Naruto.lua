local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local y = self.C.actSkillParams.y
    local mode = 0
    if isSkill then
        mode = 1
    end
    NarutoEffect.new({attacker = self, mode = mode, target = attackTarget, lastedTime = y},callback)
end

function V:zhaoHuanDie()
    NarutoEffect.new({attacker = self, mode = 3, target = self.C})
    self.view:removeAllChildren(true)
end

local C = class(AvtControler)

--4014    漩涡鸣人 自身5格范围内随机出现[n]个分身，分身继承本体[c]%的攻击力，[d]%的生命值。自身与分身增加攻速[e]%，增加移速[f]%，持续[y]秒，消耗[x]怒，冷却时间[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local  n,e,f,y,d,c = params.n,params.e,params.f,params.y,params.d,params.c
    BuffUtil.setBuff(self,{lastedTime = y,bfAtkSpeedPct = e,bfMovePct = f})
    for i=1,n do
        local gx, gy = self:getRandomGrid(3)
        local role = SkillPlugin.summonTroop(self.params.person, self.params.group, gx, gy,
            {atkPercent=c, hpPercent=d, summonTime=y, master=self, isFenShen = true})
        local viewGhost = {color={255,71,0}, blend={1,1}, op=0.73*255}
        BuffUtil.setBuff(role, {viewGhost=viewGhost, viewChange={op=0.3*255}})
        BuffUtil.setBuff(role, {lastedTime=y, bfAtkSpeedPct=e, bfMovePct = f})
        NarutoEffect.new({attacker = role.avater, mode = 2, target = role, lastedTime = y})
    end
end

--当英雄防御时，敌方每投放一个英雄，名人提升自身[x]%的血量,[y]%的攻击力。
local function _doUpdateGod2(self, diff)
    if self.deleted then
        return
    end
    if self:checkGodSkill2(true) then
        if not self.isAddedHero then
            self.isAddedHero = {}
        end
        local group = self.battleMap.hero
        for k,v in pairs(group) do
            if not v.params.isZhaoHuan and not v.params.isRebirth then
                if not self.isAddedHero[v] then
                    local ps = self.person.awakeData2.ps
                    self.isAddedHero[v] = true
                    self.M.maxHp = self.M.maxHp+self.M.base_hp*ps.x/100
                    self:damage(-self.M.base_hp*ps.x/100)
                    self.M.atk = self.M.atk + self.M.base_atk*ps.y/100
                end
            end
        end
    end
end

-- @brief 通用添加逻辑组件的方法
function C:onInitComponentsDelay()
    if not self.params.isZhaoHuan and self:checkGodSkill2(true) then
        LGBT.addComponentFunc(self, "updateComponent", _doUpdateGod2)
    end
end

--天神技 快速的冲向目标，对目标及其周围[n]格范围内的敌人造成（[a]+[x]%*攻击力）伤害，并让范围内的敌人减少移速[y]%，每秒损失[z]%*攻击力的血量，持续[t]秒。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    if self.deleted then
        return
    end
    NarutoEffect.new({attacker = self.V, mode = 5, target = self})
    self.scene.replay:addDelay(function()
        local ps = self.person.awakeData.ps
        local tg = self:getCircleTarget(self.attackTarget,self.battleMap.battlerAll,ps.n)
        for i,v in ipairs(tg) do
            SkillPlugin.exe2(self,v,ps.a,ps.x)
            BuffUtil.setBuff(v,{lastedTime = ps.t,bfAtkSpeedPct = -ps.y,lastAddHp = -ps.z*self.M.atk*ps.t/100})
        end
    end,1)
end

function V:sg_godSkillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self.loop = false
    self.isExeRealAtk = false

    local sfmt,sparams
    sfmt = self.animaConfig.skill_fmt[2]
    sparams = self.animaConfig.skill_params[2]
    self.frameFormat = sfmt
    self.animaTime = 0
    self.frameIndex = 0
    self.oneFrameTime = sparams[1]/sparams[2]
    self.frameMaxIndex = sparams[2]
    self.actionTime = 0
    self.allActionTime = 4
    self.notRecoverFrame = true

    self.exeAtkFrame = sparams[3]

    self.allActionTime = self.allActionTime+self.oneFrameTime*(self.skillStopNum-1)
    --通用特效

    self:currencyEffect(1,50,1)
    self.state = PersonState.GODSKILL
end

function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    local viewInfo = attackTarget.battleViewInfo or self.C.battleMap:getSoldierBattleViewInfoReal(attackTarget)
    local gx,gy = viewInfo[1],viewInfo[2]
    local gridInfo = {math.floor(gx),math.floor(gy),gx,gy}
    local check = self.C:checkPointInBuild(gridInfo)
    if check then
        gx,gy = check[2],check[3]
    end
    self.noResetFrame = true
    self:spmoveDirect(gx,gy,10)
    self.scene.replay:addDelay(function()
        self.noResetFrame = nil
        callback()
        BuffUtil.setBuff(self.C,{lastedTime=2, bfDizziness=2})
    end,self.allActionTime-0.1)
    NarutoEffect.new({attacker = self, mode = 4, target = attackTarget, lastedTime=self.allActionTime},callback)
end


NarutoEffect = class()

function NarutoEffect:ctor(params,callback)
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

function NarutoEffect:initParams(params)
    self.effectManager=GameEffect.new("NarutoEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 2000
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

function NarutoEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:fenshenState()
    elseif self.mode == 3 then
        self:fenshenMiss()
    elseif self.mode == 4 then
        self:initGodSkill_move()
    elseif self.mode == 5 then
        self:initGodSkill_bao()
    end
end

function NarutoEffect:initAttack()
    self.time = 0
    local setting={{89,-26,45},{131,65,0},{55,92,-45},{-55,92,-135},{-131,65,-180},{-89,-26,135}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]+10
    local r=setting[direction][3]
    local temp
    local attNode=ui.node()
    attNode:setPosition(initPos[1],initPos[2])
    bg:addChild(attNode,initPos[3]+10000)
    attNode:setScale(2)
    attNode:setRotation(r)
    attNode:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
    local function delayFrameIndex_18()
    effectManager:addEffect("views2_delay18",attNode)
    temp=views.Sparkless_00000_40_111
    temp:setPosition(0,0)
    temp:setLocalZOrder(3)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
    temp=views.Glow_01_41_111
    temp:setPosition(0,0)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",8/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
    temp=views.Glow_01_41_0_111
    temp:setPosition(0,0)
    temp:setLocalZOrder(5)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.35,0.35}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",8/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
    end
    attNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_18}}))

    local function delayFrameIndex_14()
    effectManager:addEffect("views2_delay14",attNode)
    temp=views.Weapontrail_00000_36_111
    temp:setRotation(-60)
    temp:setPosition(-50,-15)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,204},{"delay",10/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
    temp=views.Weapontrail_00000_36_0_111
    temp:setRotation(-60)
    temp:setPosition(-50,-15)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"delay",10/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
    end
    delayFrameIndex_14()
end

function NarutoEffect:initSkill()
    self.time = 11/60
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos={0,0,0}
    local temp

    local total=self.lastedTime

    if self.attacker.deleted then
        return
    end
    local function delayFrameIndex_64()
    effectManager:addEffect("views1_delay64",bg)
    temp=views.Smoke_00000_6
    temp:setPosition(initPos[1]+5,initPos[2]+44)
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",35/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",51/60},"remove"}))
    end
    delayFrameIndex_64()

    local function delayFrameIndex_65()
    effectManager:addEffect("views1_delay65",bg)
    temp=views.Ground_Glow_00000_31
    temp:setPosition(initPos[1],initPos[2]+14)
    temp:setLocalZOrder(initPos[3]-4)
    temp:runAction(ui.action.sequence({{"fadeTo",20/60,127},{"delay",total-105/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total-65/60},"remove"}))
    temp=views.Ground_Glow_00000_31_0
    temp:setPosition(initPos[1],initPos[2]+14)
    temp:setLocalZOrder(initPos[3]-3)
    temp:runAction(ui.action.sequence({{"fadeTo",20/60,127},{"delay",total-105/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total-65/60},"remove"}))
    end
    delayFrameIndex_65()

    local function delayFrameIndex_75()
        if self.attacker.deleted then
            return
        end
    effectManager:addEffect("views1_delay75",bg)
    temp=views.Glow_01_14_1_0_1
    temp:setPosition(initPos[1],initPos[2]+7)
    temp:setLocalZOrder(initPos[3]-2)
    temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",total-105/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total-75/60},"remove"}))
    temp=views.Glow_01_14_1_0_0_0
    temp:setPosition(initPos[1],initPos[2]+7)
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,255},{"fadeTo",15/60,127}})))
    temp:runAction(ui.action.sequence({{"delay",total-95/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total-75/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",11/60},{"call",delayFrameIndex_75}}))
end

function NarutoEffect:fenshenState()
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos={0,0,0}
    local temp

    local total=self.lastedTime

    effectManager:addEffect("views3_delay75",bg)
    temp=views.Glow_01_14
    temp:setPosition(initPos[1],initPos[2]+40)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,255},{"fadeTo",15/60,127}})))
    temp:runAction(ui.action.sequence({{"delay",total-20/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Glow_01_14_2
    temp:setPosition(initPos[1],initPos[2]+40)
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,255},{"fadeTo",15/60,127}})))
    temp:runAction(ui.action.sequence({{"delay",total-20/60},{"fadeTo",20/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Glow_01_14_2_0
    temp:setPosition(initPos[1],initPos[2]+40)
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,127},{"fadeTo",15/60,0}})))
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
end

function NarutoEffect:fenshenMiss()
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos={0,0,0}
    local temp
    effectManager:addEffect("views3_delay149",bg)
    temp=views.Smoke_00000_6_0
    temp:setPosition(initPos[1],initPos[2]+40)
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",35/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",51/60},"remove"}))
end

--飞行
function NarutoEffect:initGodSkill_move()
    --578 433
    local setting = {{53,-37,10},{130,45,10},{80,133,-1},{-80,133,-1},{-130,45,10},{-53,-37,10}}
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos = setting[self.direction]
    local temp
    local moveTime=self.lastedTime
    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3])
    upNode:runAction(ui.action.arepeat(ui.action.rotateBy(5/60,-60)))
    upNode:runAction(ui.action.sequence({{"delay",moveTime+60/60},"remove"}))
    effectManager:addEffect("god_views4_delay20",upNode)

     temp=views.FengQiu_15_0_0
      temp:setPosition(0,0)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",moveTime+80/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime+90/60},"remove"}))
      temp=views.FengQiu_15_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(initPos[3]+0)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",moveTime+80/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime+90/60},"remove"}))
      temp=views.Quang_0_3
      temp:setPosition(0,0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",moveTime+80/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime+90/60},"remove"}))
end

--持续并爆炸
function NarutoEffect:initGodSkill_bao()
    local total=1
    local setting = {{53,-37,10},{130,45,10},{80,133,-1},{-80,133,-1},{-130,45,10},{-53,-37,10}}
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local initPos=self.target
    local temp
   local upNode=ui.node()
   local upP = setting[self.direction]
   upNode:setPosition(upP[1],upP[2])
   bg:addChild(upNode,upP[3])
   upNode:runAction(ui.action.sequence({{"delay",total+60/60},"remove"}))

   initPos={0,0,0}

   local function delayFrameIndex_50()
     effectManager:addEffect("god_views4_delay50",upNode)
      temp=views.arcane_25
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(5/60,-30)))
      temp:runAction(ui.action.sequence({{"delay",45/60},{"scaleTo",15/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",40/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
      temp=views.arcane_orb_spirl_26
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(5/60,-65)))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",35/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",20/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

      temp=views.GF_472_23
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,2.5,2.5},{"scaleTo",10/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
      temp=views.GF_472_23_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,2.2,2.2},{"scaleTo",10/60,4.0,4.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
      temp=views.GF_472_31
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",25/60,255},{"delay",25/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
      temp=views.GF_472_31_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",25/60,255},{"delay",25/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
   end
    upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_50}}))

   local function delayFrameIndex_55()
     effectManager:addEffect("god_views4_delay55",upNode)
      temp=views.Sprite_33
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1.0,1.0},{"scaleTo",15/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,127},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
    upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_55}}))

    local function delayFrameIndex_60()
     effectManager:addEffect("god_views4_delay60",upNode)
      temp=views.arcane_orb_spirl_26_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",35/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",20/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
    upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_60}}))

   local function delayFrameIndex_70()
     effectManager:addEffect("god_views4_delay70",upNode)
      temp=views.Sprite_33_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1.0,1.0},{"scaleTo",15/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,127},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.arcane_orb_spirl_26_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",35/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",20/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

   end
    upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_70}}))

    local function delayFrameIndex_80()
     effectManager:addEffect("god_views4_delay80",upNode)
      temp=views.arcane_orb_spirl_26_0_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",20/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
    upNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_80}}))

    local function delayFrameIndex_85()
     effectManager:addEffect("god_views4_delay85",upNode)
      temp=views.Sprite_33_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,1.0,1.0},{"scaleTo",15/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,127},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",35/60},{"call",delayFrameIndex_85}}))



   local function showBao()
       effectManager:addEffect("god_views4_delay100",upNode)
      temp=views.GF_472_3
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,6.0,4.8},{"scaleTo",9/60,8.8125,7.05},{"scaleTo",7/60,11.0,8.8}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",11/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Sprite_4
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,3.0,3.0},{"scaleTo",10/60,3.0,3.0},{"scaleTo",9/60,3.5,3.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",11/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.SDA_00_1
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",11/60,6.0,4.8}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,255},{"delay",5/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.BaoZa_00_37_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
      temp=views.BaoZa_00_37_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",total},{"call",showBao}}))
end

function NarutoEffect:update(diff)
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

































