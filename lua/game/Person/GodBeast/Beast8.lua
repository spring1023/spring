
local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    local y
    if isSkill then
        mode = 1
        y = self.C.actSkillParams.y
    end
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.id%10]
    BeastEightEffect.new({attacker = self, mode = mode, target = attackTarget,scale=scal,total=y},callback)
end

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self.exeAtkFrame = 3
    self:attack(viewInfo1,viewInfo2,b)
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastEightEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end

local C = class(GodBeast)
--在[y]秒内，使自身半径8格的敌人攻击自己，自身受到伤害减少[c]%，恢复自身[d]%的血量，并反射[e]%*攻击力的伤害给攻击者。冷却[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:exeSkillForGodBeast(target)
    local ps = self.actSkillParams
    local y,c,d,e = ps.y,ps.c,ps.d,ps.e
    local result = self:getCircleTarget(self,self.battleMap.battler,8)
    self.lockTime = y
    for k,v in pairs(result) do
        v.lockTarget = self
    end
    self.lockGroup = result
    BuffUtil.setBuff(self,{lastedTime = y,bfDefPct = c, bfReAtk = e})
    local value = BattleUtil.getHeal(self,self,0,d)
    self:damage(value)
end

function C:sg_updateBattle(diff)
    if not self.lockTime then
        return
    end
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

BeastEightEffect=class()

function BeastEightEffect:ctor(params,callback)
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    self.scene = GMethod.loadScript("game.View.Scene")
    if self.scene.replay then
        self.scene.replay:addUpdateObj(self)
    else
        RegActionUpdate(self, Handler(self.update, self, 0.025), 0.025)
    end
end

function BeastEightEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastEightEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.attacker.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.total=params.total
    self.baseScal=params.scale or 1

    --起始点坐标
    local x,y = 0,self.attacker.animaConfig.Ymove
    local p = {self.attacker.view:getPosition()}
    p[1] = p[1] + x
    p[2] = p[2] + y
    self.initPos = {p[1],p[2],General.sceneHeight-p[2]}
    self.offInitPos={0,self.attacker.animaConfig.Ymove,0}
    --目标点坐标
    local view,height
    if self.target.avater then
        view = self.target.avater.view
        height = 40 + self.target.avater.animaConfig.Ymove
        self.targetZ = 41 + self.target.avater.animaConfig.Ymove
        self.offTargetPos={0,height,0}
        self.pbView=self.target.V.personView
    else
        view = self.target.view
        height = view:getContentSize().height/2
        self.targetZ = 0
        self.offTargetPos={view:getContentSize().width/2,view:getContentSize().height/2,0}
        self.pbView=self.target.vstate.build
    end
    self.targetView=view
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function BeastEightEffect:initEffect()
  if self.mode==0 then
    self:initAttack()
  elseif self.mode==1 then
      self:initSkill_att()
      self:initSkill()
      self:initSkill_fanshang()
      self:inintSkill_chaofeng()
   elseif self.mode==2 then
   	self:initCurrency()
  end
end

--技能通用
function BeastEightEffect:initCurrency()
  local setting={{23,54},{34,73},{14,95},{-14,95},{-34,73},{-23,54}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]*baseScal
   initPos[2]=self.initPos[2]+setting[direction][2]*baseScal
   initPos[3]=self.initPos[3]
   local temp

  local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+1)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views2_delay0",upNode)
      temp=views.Common_00000_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Common_00000_6_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views2_delay20",upNode)
      temp=views.Glow_16_23
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,8.0,8.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end
--普通攻击
function BeastEightEffect:initAttack()
	self.time=0.3
   local setting={{58,-71},{151,12},{102,111},{-102,111},{-151,12},{-58,-71}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]*baseScal
   initPos[2]=self.initPos[2]+setting[direction][2]*baseScal
   initPos[3]=self.initPos[3]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10000)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

   local function delayFrameIndex_19()
     effectManager:addEffect("views1_delay19",upNode)
      temp=views.Glow_01_4_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
      temp=views.Sparkless_00000_12_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Sparkless_00000_12_0_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Sparkless_00000_14_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Sparkless_00000_14_0_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Glow_01_9_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,2.25},{"scaleTo",10/60,3.5,2.625}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Glow_01_9_0_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,2.0,1.5},{"scaleTo",10/60,2.5,1.875}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Glow_01_9_0_0_a
      temp:setPosition(0,0)
      temp:setLocalZOrder(8)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.6,0.45},{"scaleTo",10/60,1.0,0.75}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_19}}))

end
--技能攻击手下
function BeastEightEffect:initSkill_att()
   local setting={{58,-71},{151,12},{102,111},{-102,111},{-151,12},{-58,-71}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]*baseScal
   initPos[2]=self.initPos[2]+setting[direction][2]*baseScal
   initPos[3]=self.initPos[3]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10000)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",100/60},"remove"}))

   local function delayFrameIndex_49()
     effectManager:addEffect("views2_delay49",upNode)
      temp=views.Shockwave_8
      temp:setPosition(0,0)
      temp:setLocalZOrder(0)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,0.85},{"scaleTo",10/60,1.2,1.02}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Glow_01_4
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",35/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",51/60},"remove"}))
      temp=views.Glow_01_4_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",35/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",51/60},"remove"}))
      temp=views.Sparkless_00000_12
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Sparkless_00000_12_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Sparkless_00000_14
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Sparkless_00000_14_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(8)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Stone_00000_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(9)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",33/60},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))

      temp=views.Glow_01_9_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(12)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.6,0.45},{"scaleTo",10/60,1.0,0.75}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Boom_6_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(14)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",5/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))

      temp=views.Shockwave_00000_7
      temp:setPosition(0,0)
      temp:setLocalZOrder(8)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",31/60,4,3.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",11/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))

      temp=views.SDA_00_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(9)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",39/60,4.2,3.36}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",6/60,127},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))

      temp=views.BaoZa_00_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(16)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",2/60,255},{"delay",27/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",34/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_49}}))

   local function delayFrameIndex_54()
     effectManager:addEffect("views2_delay54",upNode)
      temp=views.Crack_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
      temp=views.Crack_2_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
      temp=views.Particle_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(15)
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))

      temp=views.base_Crack_2_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_54}}))
end
--技能身上回血
function BeastEightEffect:initSkill()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local total=self.total
   local initPos=self.offInitPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",total+87/60},"remove"}))
   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(baseScal)
   downNode:runAction(ui.action.sequence({{"delay",total+87/60},"remove"}))

   local function delayFrameIndex_59()
     effectManager:addEffect("views2_delay59",downNode)
      temp=views.Circle_16
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.85,0.6375},{"scaleTo",10/60,1.0,0.75}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_59}}))

   local function delayFrameIndex_60()
     effectManager:addEffect("views2_delay60",downNode)
      temp=views.Glow_01_18
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-11/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total+9/60},"remove"}))
      temp=views.Glow_01_18_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,153},{"delay",total-11/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total+9/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",1/60},{"call",delayFrameIndex_60}}))

   local function delayFrameIndex_69()
     effectManager:addEffect("views2_delay69",downNode)
      temp=views.Circle_16_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.85,0.6375},{"scaleTo",10/60,1.0,0.75}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))

    effectManager:addEffect("views2_delay69_up",upNode)
      temp=views.Fire_00000_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",26/60,127},{"fadeTo",total-56/60,128},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Fire_00000_3_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",26/60,127},{"fadeTo",total-56/60,128},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_69}}))

   local function delayFrameIndex_70()
     effectManager:addEffect("views2_delay70",downNode)
      temp=views.Ground_00000_20
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-20/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-1/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",11/60},{"call",delayFrameIndex_70}}))

   local function delayFrameIndex_84()
     effectManager:addEffect("views2_delay84",upNode)
      temp=views.Particle_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",total-15/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_84}}))

end
--反伤
function BeastEightEffect:initSkill_fanshang()
	 self.time=0.2
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos=self.targetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+1)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",160/60},"remove"}))

   local function delayFrameIndex_114()
     effectManager:addEffect("views3_delay114",upNode)
      temp=views.Impact_Green_00000_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",20/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
      temp=views.Impact_Green_00000_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_114}}))

end
--嘲讽
function BeastEightEffect:inintSkill_chaofeng()
   local effectManager=self.effectManager
   local bg=self.targetView
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local total=self.total
   local initPos=self.offTargetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+1)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",total+59/60},"remove"}))

   local function delayFrameIndex_59()
     effectManager:addEffect("views4_delay59",upNode)
      temp=views.Blood_00000_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",total-2/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Blood_00000_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",total-2/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_59}}))

   --被嘲讽的
   local function delayFrameIndex_65()
      if self.target.deleted then
        return
      end
      temp=self.pbView
      local function callArep( )
         temp:runAction(ui.action.arepeat(ui.action.sequence({{"tintto",10/60,{255,192,203}},{"tintto",10/60,{255,0,0}}})))
      end
      temp:runAction(ui.action.sequence({{"tintto",30/60,{255,0,0}},{"call",callArep}}))
      local function callHuiFu( ... )
        temp:setColor(cc.c3b(255,255,255))
        temp:stopAllActions()
      end
      temp:runAction(ui.action.sequence({{"delay",total},{"call",callHuiFu}}))
   end
   upNode:runAction(ui.action.sequence({{"delay",6/60},{"call",delayFrameIndex_65}}))

end

function BeastEightEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback()
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end


return {M,V,C}
