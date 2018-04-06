
local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.id%10]
    BeastSixEffect.new({attacker = self, mode = mode, target = attackTarget,scale=scal,total=3},callback)
end

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self.exeAtkFrame = 5
    self:attack(viewInfo1,viewInfo2,b)
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastSixEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end

local C = class(GodBeast)
--恢复己方所有单位[a]+[c]%攻击力的血量，并在[y]秒内，己方英雄不受减速与眩晕的影响。技能冷却时间[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:exeSkillForGodBeast(target)
    local ps = self.actSkillParams
    local a,c,y = ps.a,ps.c,ps.y
    for k,v in ipairs(self.battleMap2.battlerAll) do
        if v.sid and v.sid>1000 then
            BeastSixEffect.new({attacker = self.V, mode = 3, target = v,scale=1,total=y},function()
              SkillPlugin.exe7(self,v,a,c)
            end)
        end
    end
    for k,v in ipairs(self.battleMap2.hero) do
        BuffUtil.setBuff(v,{lastedTime = y,allTime = 0},"ctEffectBuff")
    end
end


BeastSixEffect=class()

function BeastSixEffect:ctor(params,callback)
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

function BeastSixEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastSixEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode =self.attacker.scene.delayNode
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
    else
        view = self.target.view
        height = view:getContentSize().height/2
        self.targetZ = 0
        self.offTargetPos={view:getContentSize().width/2,view:getContentSize().height/2,0}
    end
    self.targetView=view
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function BeastSixEffect:initEffect()
  if self.mode==0 then
    self:initAttack()
  elseif self.mode==1 then
  	self:initSkill()
   elseif self.mode==2 then
   	self:initCurrency()
    elseif self.mode == 3 then
      self:initSkill_bao()
  end
end

--技能通用
function BeastSixEffect:initCurrency()
local setting={{15,64},{11,78},{11,111},{-11,111},{-11,78},{-15,64}}
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
     effectManager:addEffect("views3_delay0",upNode)
      temp=views.Common_00000_5
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Common_00000_5_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views3_delay20",upNode)
      temp=views.Glow_16_7
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,8.0,8.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end

function BeastSixEffect:initAttack()
   local setting={{51,-43},{112,35},{56,145},{-56,145},{-112,35},{-51,-43}}
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
   local targetPos=self.targetPos
   local moveX=targetPos[1]-initPos[1]
   local moveY=targetPos[2]-initPos[2]
   local moveTime=math.sqrt((self.targetPos[1]-initPos[1])^2+(self.targetPos[2]-initPos[2])^2)/self.speed
   self.time=moveTime
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+10000)
   moveNode:setScale(baseScal*1.5)
   moveNode:setRotation(r)

   local function delayFrameIndex_29()
       local function showTargetBao(  )
         self:initAttack_bao()
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
     
     effectManager:addEffect("views1_delay29",moveNode)
      temp=views.Poison_00000_22
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Poison_00000_22_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Glow_01_25
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,204},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_29}}))

end
--普通受击
function BeastSixEffect:initAttack_bao()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos=self.targetPos

   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+1)
   upNode:setScale(baseScal*1.5)
   upNode:runAction(ui.action.sequence({{"delay",20/60},"remove"}))

     effectManager:addEffect("views2_delay55",upNode)
      temp=views.Splash_00000_26
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Glow_01_28
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
end
--技能
function BeastSixEffect:initSkill()
  self.time = 0.5
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
   upNode:setScale(baseScal*1.5)
   upNode:runAction(ui.action.sequence({{"delay",total+67/60},"remove"}))
  local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScaleX(baseScal*1.5)
    downNode:setScaleY(baseScal*1.5*0.75)
   downNode:runAction(ui.action.sequence({{"delay",total+67/60},"remove"}))

   local function delayFrameIndex_60()
     effectManager:addEffect("views3_delay60",downNode)
      temp=views.Circle_11
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-40/60},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Sprite_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(10/60,10)))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Sprite_3_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(10/60,10)))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))

    effectManager:addEffect("views3_delay60_up",upNode)
      temp=views.Glow_01_8
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,191},{"delay",135/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",155/60},"remove"}))
      temp=views.Sprite_13
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",20/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.Sprite_13_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,204},{"delay",20/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_60}}))

   local function delayFrameIndex_64()
     effectManager:addEffect("views3_delay64",upNode)
      temp=views.Particle_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",total-4/60},"remove"}))
      temp=views.Particle_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",total-4/60},"remove"}))
      temp=views.Particle_4
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",25/60,0,300}}))
      temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_64}}))

end
--技能受体
function BeastSixEffect:initSkill_bao()
    self.time = 1
   local effectManager=self.effectManager
   local bg=self.targetView
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos=self.offTargetPos
   local total=self.total
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))
  local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(baseScal)
   downNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

   local function delayFrameIndex_75()
     effectManager:addEffect("views4_delay75",upNode)
      temp=views.Glow_01_15
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",total-45/60},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Glow_01_15_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,153},{"delay",total-45/60},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_75}}))

   local function delayFrameIndex_85()
     effectManager:addEffect("views4_delay85",upNode)
      temp=views.Sprite_13_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",20/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.Sprite_13_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,204},{"delay",20/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_85}}))

   local function delayFrameIndex_89()
     effectManager:addEffect("views4_delay89",upNode)
      temp=views.Particle_5
      temp:setPosition(0,300)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",25/60,0,-300}}))
      temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",14/60},{"call",delayFrameIndex_89}}))

   local function delayFrameIndex_109()
     effectManager:addEffect("views4_delay109",downNode)
      temp=views.Circle_11_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.7,0.525},{"scaleTo",10/60,0.8,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",34/60},{"call",delayFrameIndex_109}}))

   local function delayFrameIndex_119()
     effectManager:addEffect("views4_delay119",downNode)
      temp=views.Circle_11_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.7,0.525},{"scaleTo",10/60,0.8,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
     effectManager:addEffect("views4_delay119_up",upNode)
      temp=views.Particle_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"delay",total-44/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",35/60},{"call",delayFrameIndex_119}}))

end

function BeastSixEffect:update(diff)
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
