

local M = class(AvtInfo)













local V = {}


function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.exeAtkFrame = 1
    self.skillStopNum = 6
    self:attack(viewInfo1,viewInfo2,b)
    self.state = PersonState.SKILL
    --通用特效
    self:currencyEffect(1,50,1)
end

function V:viewEffect(attackTarget,callback,isSkill)
    local attackMode = 1
    if self.skillLastTimeAll then
        attackMode = 2
    end
    KurosakiEffect.new({attacker = self, mode = 0, target = attackTarget, attackMode = attackMode},callback)
end

function V:skillViewEffect(attackTarget,callback,skillLastTimeAll)
    skillLastTimeAll = self.C.actSkillParams.y
    KurosakiEffect.new({attacker = self, mode = 1, target = attackTarget, lastedTime = skillLastTimeAll},function()
        callback()
        self.skillLastTimeAll = skillLastTimeAll
        self.skillLastTime = 0
    end)
end

function V:skillAfter()
    self.skillLastTimeAll = nil
    self.skillLastTime = nil
end

local C = class(AvtControler)

--4022    死神 持续[y]秒内，在普通攻击时，为自身恢复实际伤害值[c]%的生命值，为周围友军恢复实际伤害值[d]%的生命值，同时提升自身攻速[e]%, 移速[f]%, 消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local c,d,y,e,f = params.c,params.d,params.y,params.e,params.f
    BuffUtil.setBuff(self,{lastedTime = y,bfSuckBlood = {c,d}})
    BuffUtil.setBuff(self,{lastedTime = y,bfAtkSpeedPct = e,bfMovePct = f})
end

--天神技   [d]连斩，依次对周围目标造成[a]+[x]%自身攻击力的伤害，并让目标的伤害下降[y]%。英雄自身免疫眩晕[t]秒。
function C:ppexeGodSkill()
    self.godSkillNum = 0
    self.isAddGroup = {}
    self.godSkillTarget = self:searchTarget()
    if self.godSkillTarget then
        self.isGodSkillAttack = true
        self.isGodSkillNotAttack = true
    end
end

function C:searchTarget() 
    local targetG = {}
    for k,v in ipairs(self.battleMap.battler) do
        if not self.isAddGroup[v] then
            table.insert(targetG,v)
        end
    end
    local ret = self:getMinDisTarget(1,nil,targetG)
    if ret[1] then
        self.isAddGroup[ret[1]] = true
    else
        if next(self.isAddGroup) then
            self.isAddGroup = {}
            return self:searchTarget()
        end
    end
    return ret[1]
end

function C:exeGodSkill(target)
    if self.godSkillNum then
        self.godSkillNum = self.godSkillNum+1
    end
    local ps = self.person.awakeData.ps
    SkillPlugin.exe2(self,target,ps.a,ps.x)
    BuffUtil.setBuff(target,{cantKey = "KurosakiGodSkill",lastedTime = ps.t,bfHurt = -ps.y})
    BuffUtil.setBuff(self,{cantKey = "KurosakiGodSkillself",lastedTime = ps.t, ctDizziness=1})
end

function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    self.scene.replay:addDelay(function()
        local d = self.C.person.awakeData.ps.d
        if not self.deleted then
            self.C:hideSelf(0.23*(d-1)+0.6, true)
        end
    end,0.7)
    KurosakiEffect.new({attacker = self, mode = 4, target = attackTarget},function()
        KurosakiEffect.new({attacker = self, mode = 5, target = attackTarget},callback)
    end)
end
--防守时，英雄攻击与移动速度增加[x]%，减少[y]%受到的伤害，并将减少的伤害变成恢复血量平均分摊给存活的英雄。
function C:sg_updateBattle(diff)
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        BuffUtil.setBuff(self,{bfAtkSpeedPct=ps.x, bfMovePct=ps.x})
    end
end

function C:sg_damage(value,damager)
    if value <= 0 then
        return value
    end
    if self:haveGodSkill2() then
        local ps = self.person.awakeData2.ps
        local dvalue = value*ps.y/100
        local avalue = dvalue/#self.battleMap2.hero
        for k,v in pairs(self.battleMap2.hero) do
            if not v == self then
                SkillPlugin.exe7(self,v,avalue)
            end
        end
        return (value-dvalue)
    else
        return value
    end
end

KurosakiEffect = class()

function KurosakiEffect:ctor(params,callback)
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

function KurosakiEffect:initParams(params)
    self.effectManager=GameEffect.new("KurosakiEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 2000
    self.lastedTime = params.lastedTime
    self.attackMode = params.attackMode
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

function KurosakiEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 4 then
        self.time = 0.7
        self:createViews_1()
    elseif self.mode == 5 then
        self:createViews_3()
    end
end

function KurosakiEffect:initAttack()
    if self.attackMode == 1 then
        self:initAttack1()
    elseif self.attackMode == 2 then
        self:initAttack2()
    end
end

function KurosakiEffect:initAttack1()
    self.time = 0.2
    local setting={{80,0,30},{100,0,30},{100,60,0},{-100,60,0},{-100,0,-30},{-80,0,-30}}
    local setting2={{180,-75,-15},{240,-20,-15},{240,70,-30},{-240,70,30},{-240,-20,15},{-180,-75,15}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]+10000
    local oR1=setting[direction][3]
    local initPos2={}
    initPos2[1]=self.initPos[1]+setting2[direction][1]
    initPos2[2]=self.initPos[2]+setting2[direction][2]
    initPos2[3]=self.initPos[3]+10000
    local oR2=setting2[direction][3]
    local targetPos=self.targetPos
    targetPos[3]=100000
    local temp

    local function delayFrameIndex_19()
    effectManager:addEffect("views2_delay19",bg)
    temp=views.Weapontrail_1
    if direction>3 then
    temp:setFlippedX(true)
    end
    temp:setRotation(oR1)
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
    end
    delayFrameIndex_19()

    local function delayFrameIndex_28()
    effectManager:addEffect("views2_delay28",bg)
    temp=views.Flare_yellow_18
    if direction>3 then
    temp:setFlippedX(true)
    end
    temp:setRotation(oR2)
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",2/60,4.5,3.0},{"scaleTo",3/60,3.0,3.0},{"scaleTo",2/60,2.0,2.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",7/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",9/60},"remove"}))
    temp=views.Glow_01_21
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_28}}))
end

function KurosakiEffect:initAttack2()
    self.time = 0.3
    local setting={{80,0,30},{100,0,30},{100,60,0},{-100,60,0},{-100,0,-30},{-80,0,-30}}
    local setting2={{180,-75,-15},{240,-20,-15},{240,70,-30},{-240,70,30},{-240,-20,15},{-180,-75,15}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]
    initPos[2]=self.initPos[2]
    initPos[3]=self.initPos[3]+10000
    local initPos1={}
    initPos1[1]=self.initPos[1]+setting[direction][1]
    initPos1[2]=self.initPos[2]+setting[direction][2]
    initPos1[3]=self.initPos[3]+10000
    local oR1=setting[direction][3]
    local initPos2={}
    initPos2[1]=self.initPos[1]+setting2[direction][1]
    initPos2[2]=self.initPos[2]+setting2[direction][2]
    initPos2[3]=self.initPos[3]+10000

    local targetPos=self.targetPos
    targetPos[3]=100000
    local oR2=setting2[direction][3]
    local temp


    local function delayFrameIndex_69()
    effectManager:addEffect("views1_delay69",bg)
    temp=views.Kurosaki_Weapontrail_Black_00000_8_111
    temp:setScaleX(1.2*5.5)
    temp:setScaleY(1.2*4.6)
    if direction>3 then
    temp:setFlippedX(true)
    end
    temp:setRotation(oR1)
    temp:setPosition(initPos1[1],initPos1[2])
    temp:setLocalZOrder(initPos1[3]-3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
    end
    delayFrameIndex_69()

    local function delayFrameIndex_78()
    effectManager:addEffect("views1_delay78",bg)
    temp=views.Flare_yellow_18_0_111
    if direction>3 then
    temp:setFlippedX(true)
    end
    temp:setRotation(oR2)
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+6)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",2/60,4.5,3.0},{"scaleTo",3/60,3.0,3.0},{"scaleTo",2/60,2.0,2.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",7/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",9/60},"remove"}))
    temp=views.Flare_yellow_18_0_0_111
    if direction>3 then
    temp:setFlippedX(true)
    end
    temp:setRotation(oR2)
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+9)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",2/60,4.5,3.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",2/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",4/60},"remove"}))
    temp=views.Glow_01_21_0_111
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+7)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_78}}))
end

function KurosakiEffect:initSkill()
    self.time = 0.3
    local effectManager=self.effectManager
    local bg=self.attacker.view
    local views=self.views
    local direction=self.direction
    local total= self.lastedTime
    local initPos={0,0,0}
    local temp
    local delayNode = ui.node()
    bg:addChild(delayNode)
    delayNode:runAction(ui.action.sequence({{"delay",total+1}}))
    local function delayFrameIndex_34()
    effectManager:addEffect("views1_delay34",bg)
    temp=views.Change_Buff_00000_11_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-2)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",12/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
    temp=views.Shockwave_14_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]-1)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.8,0.704},{"scaleTo",10/60,1.2,1.056}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Glow_01_12_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",12/60,3.0,2.25}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",11/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
    end
    delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_34}}))
    local function delayFrameIndex_44()
    effectManager:addEffect("views1_delay44",bg)
    temp=views.Particle_1_0_0_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
    temp=views.Light_0_111
    temp:setPosition(initPos[1],initPos[2]+20)
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",8/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,1.2}}))
    temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
    temp=views.Light_1_111
    temp:setPosition(initPos[1],initPos[2]+20)
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",8/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,1.2}}))
    temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
    end
    delayNode:runAction(ui.action.sequence({{"delay",44/60},{"call",delayFrameIndex_44}}))

    local function delayFrameIndex_37()
    effectManager:addEffect("views1_delay37",bg)
    temp=views.Glow_01_19_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
    end
    delayNode:runAction(ui.action.sequence({{"delay",37/60},{"call",delayFrameIndex_37}}))

    local function delayFrameIndex_79()
    effectManager:addEffect("views1_delay79",bg)
    temp=views.Glow_01_21_0_0_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",2/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
    end
    delayNode:runAction(ui.action.sequence({{"delay",79/60},{"call",delayFrameIndex_79}}))

    local function delayFrameIndex_48()

    local rNode=ui.node()
    rNode:setPosition(initPos[1],initPos[2])
    rNode:setScaleY(0.75)
    bg:addChild(rNode,initPos[3]-10)
    effectManager:addEffect("views1_delay48",rNode)
    rNode:runAction(ui.action.sequence({{"delay",total-4/60},"remove"}))
    temp=views.HeiFa_1
    temp:setPosition(0,0)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",9/60,255}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",9/60,1.15,1.15}}))
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(20/60,66)))
    temp:runAction(ui.action.sequence({{"delay",total-4/60},"remove"}))
    temp=views.Glow_01_5
    temp:setPosition(0,0)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",9/60,255}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",9/60,3,3}}))
    temp:runAction(ui.action.sequence({{"delay",total-4/60},"remove"}))

    end
    delayNode:runAction(ui.action.sequence({{"delay",48/60},{"call",delayFrameIndex_48}}))
end

function KurosakiEffect:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local temp

      local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(1.5)
   downNode:runAction(ui.action.sequence({{"delay",70/60},"remove"}))

      local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",70/60},"remove"}))

   local function delayFrameIndex_34()
     effectManager:addEffect("godSkill_views1_delay34",downNode)
      temp=views.Change_Buff_00000_11
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"delay",12/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
      temp=views.Shockwave_14
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",24/60,0.8,0.704},{"scaleTo",10/60,1.2,1.056}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"fadeTo",34/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
    effectManager:addEffect("godSkill_views1_delay34_up",upNode)
      temp=views.Glow_01_12
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",12/60,3.0,2.25}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",11/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",34/60},{"call",delayFrameIndex_34}}))

   local function delayFrameIndex_37()
     effectManager:addEffect("godSkill_views1_delay37",upNode)
      temp=views.Glow_01_19
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",37/60},{"call",delayFrameIndex_37}}))

   local function delayFrameIndex_44()
     effectManager:addEffect("godSkill_views1_delay44",upNode)
      temp=views.Light_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,1.2}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
      temp=views.Light_1
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,1.2}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",44/60},{"call",delayFrameIndex_44}}))

end

function KurosakiEffect:createViews_2()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

  local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+100000)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",210/60},"remove"}))


   local function delayFrameIndex_133()
     effectManager:addEffect("godSkill_views2_delay133",upNode)
      temp=views.Glow_02_1
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,2.5,2.5},{"scaleTo",15/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   delayFrameIndex_133()

   local function delayFrameIndex_185()
     effectManager:addEffect("godSkill_views2_delay185",upNode)
      temp=views.Glow_01_2_0
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,2.5,2.5},{"scaleTo",15/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Boom_6
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.5,1.5},{"scaleTo",15/60,1.8,1.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Glow_01_2
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,2.5,2.5},{"scaleTo",15/60,3.5,3.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Flare_yellow_3
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",15/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Flare_yellow_3_0
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",15/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Sparkless_00000_7
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Impact_00000_10
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.5,1.5},{"scaleTo",40/60,1.8,1.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",40/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.Sprite_8
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.3,1.3},{"scaleTo",15/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Sprite_8_0
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.3,0.4843},{"scaleTo",15/60,1.7331,0.8008}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   delayFrameIndex_185()

end

function KurosakiEffect:createViews_3()
    self.time = 13/60
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp
   if not self.attacker.C.godSkillNum then
      return
   end
    local index=self.attacker.C.godSkillNum+1
      if index>6 then
        index = 1
      end

      local setting={{403,380,-45,true},{-403,380,0,false},{0,308,45,false},{403,0,0,true},{-403,-380,-45,false},{-403,380,0,false}}
      local ox=setting[index][1]
      local oy=setting[index][2]
      local r=setting[index][3]
      local fx=setting[index][4]
      local oox=1
      if fx then
        oox=-1
      end
      local moveNode=ui.node()
      moveNode:setPosition(initPos[1]+ox,initPos[2]+oy)
      bg:addChild(moveNode,initPos[3]+100000)
      moveNode:setRotation(r)
      local function showTargetBao()
        self:createViews_4(index)
      end
      moveNode:runAction(ui.action.sequence({{"delay",4/60},{"call",showTargetBao}}))
      moveNode:runAction(ui.action.sequence({{"moveBy",13/60,-ox*1.5,-oy*1.5},"remove"}))

     effectManager:addEffect("godSkill_views3_delay60",moveNode)
      temp=views.HuoHong01_00000_2
      temp:setFlippedX(fx)
      temp:setPositionX(temp:getPositionX()*oox)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",4/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
      temp=views.HuoHong01_00000_2_0
      temp:setFlippedX(fx)
      temp:setPositionX(temp:getPositionX()*oox)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,153},{"fadeTo",4/60,133},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
      temp=views.HuoHong01_00000_2_0_0
      temp:setFlippedX(fx)
      temp:setPositionX(temp:getPositionX()*oox)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
      temp=views.HuoHong01_00000_2_0_0_0
      temp:setFlippedX(fx)
      temp:setPositionX(temp:getPositionX()*oox)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,102},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
      temp=views.HuoHong01_00000_2_0_0_0_0
      temp:setFlippedX(fx)
      temp:setPositionX(temp:getPositionX()*oox)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,63},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
end

function KurosakiEffect:createViews_4(index)
  local setR={145,45,90,180,-45,45}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local r=setR[index]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+100000)
   upNode:setScale(2)
   upNode:setRotation(r)
   upNode:runAction(ui.action.sequence({{"delay",30/60},"remove"}))

   local function delayFrameIndex_74()
     effectManager:addEffect("godSkill_views4_delay74",upNode)
      temp=views.Strike_00000_12
      temp:runAction(ui.action.sequence({{"delay",6/60},{"scaleTo",3/60,1.1,0.7}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",11/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",13/60},"remove"}))
      temp=views.shengui_00016_16
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,170},{"fadeTo",21/60,255},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
      temp=views.Glow_02_42
      temp:runAction(ui.action.sequence({{"delay",2/60},{"scaleTo",9/60,0.2,0.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Glow_01_43
      temp:runAction(ui.action.sequence({{"scaleTo",3/60,1.5,1.5},{"scaleTo",7/60,1.7,1.7},{"scaleTo",6/60,0.2,0.2}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
   end
   delayFrameIndex_74()

  if not self.attacker.C.godSkillNum then
    local function showTargetBao()
      self:createViews_2()
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",16/60},{"call",showTargetBao}}))
  end

end


function KurosakiEffect:update(diff)
    if not self.allTime then
        self.allTime = 0 
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target,true)
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
        if self.mode == 5 then
            local hero = self.attacker.C
            local ps = hero.person.awakeData.ps
            if hero.godSkillNum and hero.godSkillNum<ps.d then
                local target = hero:searchTarget()
                if target then
                    KurosakiEffect.new({attacker = self.attacker, mode = 5, target = target},self.callback)
                end
                if hero.godSkillNum == ps.d-1 then
                    hero.godSkillNum = nil
                    hero.isAddGroup = nil
                    hero.godSkillTarget = nil
                end
            end
        end
    end
end

return {M,V,C}




























