
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
    BeastNineEffect.new({attacker = self, mode = mode, target = attackTarget,scale=scal,total=3},callback)
end

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self.exeAtkFrame = 3
    self:attack(viewInfo1,viewInfo2,b)
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastNineEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end

local C = class(GodBeast)
--对目标及其周围半径8格范围内的敌人造成[a]+[c]%的伤害，并且恢复友军[d]%攻击力的血量。技能冷却时间[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:exeSkillForGodBeast(target)
    if not target then
      return
    end
    local ps = self.actSkillParams
    local a,c,d = ps.a,ps.c,ps.d
    local result = self:getCircleTarget(target,self.battleMap.battlerAll,8)
    for k,v in ipairs(result) do
        SkillPlugin.exe2(self,v,a,c)
    end
    for k,v in ipairs(self.battleMap2.battlerAll) do
      if v.avater then--不对建筑回血
        SkillPlugin.exe7(self,v,0,d)
      end
    end
end


BeastNineEffect=class()

function BeastNineEffect:ctor(params,callback)
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

function BeastNineEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastNineEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode=self.attacker.scene.delayNode
    self.speed = params.speed or 800
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

function BeastNineEffect:initEffect()
  if self.mode==0 then
    self:initAttack()
  elseif self.mode==1 then
  	self:initSkill()
  	self:initSkill_move()
   elseif self.mode==2 then
   	self:initCurrency()
  end
end

--技能通用
function BeastNineEffect:initCurrency()
  local setting={{45,8},{81,65},{43,121},{-43,121},{-81,65},{-45,8}}
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
      temp=views.Common_00000_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Common_00000_3_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views3_delay20",upNode)
      temp=views.Glow_16_5
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end

function BeastNineEffect:initAttack()
  local setting={{111,-115},{228,29},{123,192},{-123,192},{-228,29},{-111,-115}}
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
   self.time=moveTime+5/60
  local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+1000)
   moveNode:setScale(baseScal*1.5)
   moveNode:setRotation(r)

   local function delayFrameIndex_19()
     effectManager:addEffect("views1_delay19",moveNode)
      temp=views.Void_00000_23_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(0)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",4/60},"remove"}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_19}}))

   local function delayFrameIndex_24()
     local function showTargetBao(  )
         self:initAttack_bao()
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views1_delay24",moveNode)
     
      temp=views.Sprite_24
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Void_00000_23
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Void_Center_00000_25
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_24}}))

end
--普通受击
function BeastNineEffect:initAttack_bao()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos=self.targetPos

   local temp
   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal*1.5)
   upNode:runAction(ui.action.sequence({{"delay",16/60},"remove"}))

     effectManager:addEffect("views2_delay64",upNode)
      temp=views.Void_00006_28
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Void_00006_28_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,4.8,4.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
end

--回血
function BeastNineEffect:initSkill()
  local setting={{25,-40},{60,10},{20,40},{-20,40},{-60,10},{-25,-40}}
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local total=self.total

   local initPos=self.offInitPos
   initPos[1]=initPos[1]+setting[direction][1]*baseScal
   initPos[2]=initPos[2]+setting[direction][2]*baseScal
   local temp

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

   local function delayFrameIndex_25()
     effectManager:addEffect("views3_delay25",downNode)
      temp=views.Glow_01_32
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.fadeTo(10/60,255))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Sprite_34
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(10/60,20)))
       temp:runAction(ui.action.fadeTo(10/60,255))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Glow_01_32_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.fadeTo(10/60,255))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_25}}))

   local function delayFrameIndex_34()
     effectManager:addEffect("views3_delay34",downNode)
      temp=views.Particle_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",total-9/60},"remove"}))
     effectManager:addEffect("views3_delay34_up",upNode)
      temp=views.Particle_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"delay",total-9/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_34}}))

end

function BeastNineEffect:initSkill_move()
  local setting={{111,-115},{228,29},{123,192},{-123,192},{-228,29},{-111,-115}}
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
   self.time=moveTime+21/60
  local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+1000)
   moveNode:setScale(baseScal)
   moveNode:setRotation(r)

   local function delayFrameIndex_49()
     effectManager:addEffect("views4_delay49",moveNode)
      temp=views.Black_Hole_Start_00001_7
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_49}}))

   local function delayFrameIndex_67()
     effectManager:addEffect("views4_delay67",moveNode)
      temp=views.lanren1_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,255}}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",18/60},{"call",delayFrameIndex_67}}))

   local function delayFrameIndex_70()
   	 
     local function showTargetBao(  )
         self:initSkill_bao()
     end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views4_delay70",moveNode)
      temp=views.Black_Hole_Blackground_00000_9
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))

      temp=views.Black_Hole_Particle_00000_10
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))

      temp=views.Black_Hole_Continue_00000_8
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",21/60},{"call",delayFrameIndex_70}}))

end

--技能受体
function BeastNineEffect:initSkill_bao()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local baseScal=self.baseScal
   local temp

  local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal*2)
   upNode:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
  local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(baseScal*2)
   downNode:runAction(ui.action.sequence({{"delay",21/60},"remove"}))

   local function delayFrameIndex_146()
     effectManager:addEffect("views5_delay146",downNode)
      temp=views.Black_Hole_Finish_00000_14
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0},{"call",delayFrameIndex_146}}))

   local function delayFrameIndex_150()
     effectManager:addEffect("views5_delay150",upNode)
      temp=views.Glow_16_20
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_150}}))

   local function delayFrameIndex_154()
     effectManager:addEffect("views5_delay154",upNode)
      temp=views.Extruder_00000_18
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",25/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_154}}))

end

function BeastNineEffect:update(diff)
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
