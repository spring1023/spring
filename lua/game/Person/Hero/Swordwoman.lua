local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    SwordwomanEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--2004 女剑仙 对n个敌方单位造成a+c%*攻击力的伤害，优先英雄，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    local params = self.actSkillParams
    local n = params.n
    self.skillTargetGroup = self:getMinDisTarget(n)
    if self.skillTargetGroup[1] then
      self.isSkillAttack = true
      self.isSkillNotAttack = true
    end
end

function C:sg_exeSkill(target)
    if not target or target.deleted then
        return
    end
    local params = self.actSkillParams
    local a,c = params.a,params.c
    SkillPlugin.exe2(self,target,a,c)
end

SwordwomanEffect=class()

function SwordwomanEffect:ctor(params,callback)
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

function SwordwomanEffect:initParams(params)
    self.effectManager=GameEffect.new("SwordwomanEffect.json")
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

function SwordwomanEffect:initEffect()
  if self.mode==0 then
     self:initAttack()
     self:initAttack_move()
  elseif self.mode==1 then
     self:initSkill()
  end
end

function SwordwomanEffect:initSkill()
  local setting={{48,13},{89,69},{43,127},{-43,127},{-89,69},{-48,13}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   self.time=moveTime+4/60
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   moveNode:setRotation(-45+r)
   moveNode:setScale(1.5)
   bg:addChild(moveNode,initPos[3]+10000)

   local function delayFrameIndex_40()
    local function showTargetBao()
      self:initSkill_target()
    end
     moveNode:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
     effectManager:addEffect("views1_delay40",moveNode)
      temp=views.Swordwoman_Sword_60_0000_5
      temp=views.Line_00001_11
   end
   moveNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_40}}))

end

--受击
function SwordwomanEffect:initSkill_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local rs={30,0,-30,-120,-180,120}
   local r=rs[direction]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",12/60},"remove"}))

     effectManager:addEffect("views2_delay63",upNode)
      temp=views.Flare_7
      temp:setRotation(r)
      temp:runAction(ui.action.sequence({{"delay",2/60},{"scaleTo",3/60,1.0124,0.7},{"scaleTo",2/60,0.9343,0.7},{"scaleTo",5/60,0.1,0.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
      temp=views.Glow_02_9
      temp:runAction(ui.action.sequence({{"delay",6/60},{"scaleTo",1/60,1.0,1.0},{"scaleTo",1/60,0.7,0.7},{"scaleTo",4/60,1.15,1.15}}))
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,126},{"fadeTo",10/60,63}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
end

--普通攻击
function SwordwomanEffect:initAttack()
  local setting={{48,13},{89,69},{43,127},{-43,127},{-89,69},{-48,13}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",47/60},"remove"}))

   local function delayFrameIndex_10()
     effectManager:addEffect("views3_delay10",upNode)
      temp=views.Glow_16_9
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,2.8,2.8}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
      temp=views.Glow_16_9_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,2.8,2.8}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
   end
   delayFrameIndex_10()
end
--普攻子弹
function SwordwomanEffect:initAttack_move()
  local setting={{48,13},{89,69},{43,127},{-43,127},{-89,69},{-48,13}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]

   local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
  local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   self.time=moveTime
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+10000)
   moveNode:setRotation(r)

   local function delayFrameIndex_20()
    local function showTargetBao()
      self:initAttack_target()
    end
     moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views4_delay20",moveNode)
      temp=views.Line_00001_11
      temp=views.CRDds_01_00_11
   end
   delayFrameIndex_20()
end
--普通受击
function SwordwomanEffect:initAttack_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp
   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",16/60},"remove"}))

     effectManager:addEffect("views5_delay44",upNode)
      temp=views.Glow_02_9_0
      temp:runAction(ui.action.sequence({{"scaleTo",1/60,1.0,1.0},{"scaleTo",1/60,0.7,0.7},{"scaleTo",4/60,1.15,1.15}}))
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,126},{"fadeTo",4/60,63},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.Sprite_12
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
end

function SwordwomanEffect:update(diff)
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
