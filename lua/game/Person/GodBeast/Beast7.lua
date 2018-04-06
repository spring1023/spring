
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
    BeastSevenEffect.new({attacker = self, mode = mode, target = attackTarget,scale=scal,total=3},callback)
end

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self.exeAtkFrame = 3
    self:attack(viewInfo1,viewInfo2,b)
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastSevenEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end

local C = class(GodBeast)
--吐出n个风球，对敌人造成[a]+[c]%*攻击力的伤害，并击退敌人m格。技能冷却时间[z]秒。
function C:sg_ppexeSkill(target)
    local n  = self.actSkillParams.n
    self.skillTargetGroup = self:getMinDisTarget(n)
    if self.skillTargetGroup[1] then
      self.isSkillAttack = true
      self.isSkillNotAttack = true
    end
end

function C:exeSkillForGodBeast(target)
    local ps = self.actSkillParams
    local a,c,m = ps.a,ps.c,ps.m
    SkillPlugin.exe2(self,target,a,c)
    if target.avater then
        target:beRepel(self,m or 3)
    end
end


BeastSevenEffect=class()

function BeastSevenEffect:ctor(params,callback)
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

function BeastSevenEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastSevenEffect.json")
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

function BeastSevenEffect:initEffect()
  if self.mode==0 then
    self:initAttack()
  elseif self.mode==1 then
  	--self:initSkill()
  	self:initSkill_move()
   elseif self.mode==2 then
   	self:initCurrency()
  end
end

--技能通用
function BeastSevenEffect:initCurrency()
  local setting={{16,127},{30,145},{11,236},{-11,236},{-30,145},{-16,127}}
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
   upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views2_delay0",upNode)
      temp=views.Common_00000_4
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Common_00000_4_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views2_delay20",upNode)
      temp=views.Glow_16_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,8.0,8.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end
--普攻
function BeastSevenEffect:initAttack()
  local setting={{77,-13},{182,95},{98,221},{-98,221},{-182,95},{-77,-13}}
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
   local r=-math.deg(math.atan2(moveY,moveX))-30
   local temp
   self.time = moveTime+0.25
  local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+10000)
   moveNode:setScale(2*baseScal)
   moveNode:setRotation(r)

    local function callMove(  )
      moveNode:runAction(ui.action.moveBy(moveTime,moveX,moveY))
      moveNode:runAction(ui.action.sequence({{"delay",moveTime-10/60},{"fadeTo",10/60,0},"remove"}))
    end
    moveNode:runAction(ui.action.sequence({{"delay",0.25},{"call",callMove}}))

     effectManager:addEffect("views1_delay15",moveNode)
      temp=views.Weapontrail_60_00000_21
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp=views.Weapontrail_60_00000_21_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp=views.Weapontrail_60_00000_21_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp=views.Weapontrail_60_00000_21_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
end
--技能
function BeastSevenEffect:initSkill()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local total=self.total
   local oy=80
   local initPos=self.offInitPos
   initPos[2]=initPos[2]+oy*baseScal
   local temp

   local function delayFrameIndex_30()
    local upNode=ui.node()
     upNode:setPosition(initPos[1],initPos[2])
     bg:addChild(upNode,initPos[3]+10)
     upNode:setScale(baseScal)
     upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))
    local downNode=ui.node()
     downNode:setPosition(initPos[1],initPos[2])
     bg:addChild(downNode,initPos[3]-10)
     downNode:setScaleX(baseScal)
      downNode:setScaleY(baseScal*0.75)
     downNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

    effectManager:addEffect("views2_delay30",downNode)
      temp=views.Glow_16_18
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-25/60},{"fadeTo",15/60,0}}))
      temp=views.Glow_16_18_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
       temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-25/60},{"fadeTo",15/60,0}}))
      temp=views.glow_00075_00000_16
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(30/60,-60)))
       temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-25/60},{"fadeTo",15/60,0}}))
      temp=views.glow_00075_00000_16_0
       temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(30/60,-60)))
       temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-25/60},{"fadeTo",15/60,0}}))

     effectManager:addEffect("views2_delay30_up",upNode)
      temp=views.Glow_01_20
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-25/60},{"fadeTo",15/60,0}}))
   end
   bg:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_30}}))

end
--技能攻击子弹
function BeastSevenEffect:initSkill_move()
  local setting={{77,-13},{182,95},{98,221},{-98,221},{-182,95},{-77,-13}}
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
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp
   self.time = moveTime
  local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+1000)
   moveNode:setScale(baseScal*1.5)
   moveNode:setRotation(r)

   local function delayFrameIndex_45()
      local function showTargetBao(  )
         self:initSkill_bao()
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views3_delay0",moveNode)
      temp=views.Wind_Ball_7
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(45/60,360)))
      temp=views.Wind_Ball_7_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(45/60,360)))
      temp=views.Glow_16_9
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
   end
   moveNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_45}}))

end
--技能受击
function BeastSevenEffect:initSkill_bao()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local baseScal=self.baseScal
   local temp

  local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal)
   upNode:runAction(ui.action.sequence({{"delay",21/60},"remove"}))

     effectManager:addEffect("views4_delay74",upNode)
      temp=views.Finish_00000_10
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Finish_00000_10_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))

      temp=views.Sprite_4
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.Sprite_4_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.Sprite_4_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.Sprite_4_0_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.Sprite_4_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.Sprite_4_0_0_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(8)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.Sprite_4_0_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(9)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.Sprite_4_0_0_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(10)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.base_Glow_01_13
      temp:setPosition(0,0)
      temp:setLocalZOrder(11)
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,2.0,2.0},{"scaleTo",13/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",5/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))

     effectManager:addEffect("views4_delay79",upNode)
      temp=views.Glow_16_14
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))

end

function BeastSevenEffect:update(diff)
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
