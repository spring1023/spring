local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    JakiroEffect.new({attacker = self, mode = mode, target = attackTarget,lastedTime = self.C.actSkillParams.t},callback)
end


local C = class(AvtControler)

--3007 双头龙  对目标造成一次a+c%*攻击力的伤害，并在之后t秒内持续造成总共b伤害，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    if not target or target.deleted then
        return
    end
    local params = self.actSkillParams
    local a,c,t,b = params.a,params.c,params.t,params.b
    SkillPlugin.exe2(self,target,a,c)
    BuffUtil.setBuff(target,{lastedTime = t, lastAddHp = -b, damager = self})
end

JakiroEffect=class()

function JakiroEffect:ctor(params,callback)
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
function JakiroEffect:update(diff)
    if not self.allTime then
        self.allTime = 0 
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target,true)
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end
function JakiroEffect:initParams(params)
    self.effectManager=GameEffect.new("JakiroEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.attacker.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.total=params.lastedTime
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
        height = self.target.avater.animaConfig.Ymove
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

function JakiroEffect:initEffect()
  if self.mode==0 then
     self:initAttack()
     self:initAttack_move()
  elseif self.mode==1 then
     self:initSkill()
  end
end

function JakiroEffect:initSkill()
  local setting={{28,-55},{96,-5},{75,64},{-75,64},{-96,-5},{-28,-55}}
  local setting2={{70,-50},{108,22},{44,116},{-44,116},{-108,22},{-70,-50}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]+10000

   local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local length1=math.sqrt(moveX^2+moveY^2)
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local total=self.total

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+100000)
   upNode:setRotation(r)
   upNode:setScaleX(length1/250)
   upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
   upNode:setRotation(r)

   local initPos2={}
   initPos2[1]=self.initPos[1]+setting2[direction][1]
   initPos2[2]=self.initPos[2]+setting2[direction][2]
   initPos2[3]=self.initPos[3]
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local length2=math.sqrt(moveX^2+moveY^2)
   local r=-math.deg(math.atan2(moveY,moveX))

   self.time=30/60

   local upNode2=ui.node()
   upNode2:setPosition(initPos2[1],initPos2[2])
   bg:addChild(upNode2,initPos2[3]+100000)
   upNode2:setRotation(r)
   upNode2:setScaleX(length2/250)
   upNode2:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
   upNode2:setRotation(r)

   local function delayFrameIndex_0()
    effectManager:addEffect("views1_delay0_blue",upNode)
      temp=views.Particle_6
      temp=views.Particle_3
      temp=views.Particle_8

    effectManager:addEffect("views1_delay0_red",upNode2)
      temp=views.Particle_7
      temp=views.Particle_1
  
     effectManager:addEffect("views1_delay0_ranshao",self.target.avater and self.target.avater.view or self.target.view)
     temp=views.Fire_00000_1
     temp:setPosition(self.offTargetPos[1],self.offTargetPos[2])
     temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   delayFrameIndex_0()
end

function JakiroEffect:initAttack()
  local setting={{28,-55,45},{96,-5,0},{75,64,-45},{-75,64,-135},{-96,-5,-180},{-28,-55,135}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local r=setting[direction][3]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3])
   upNode:setRotation(r)
   upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_26()
     effectManager:addEffect("views2_delay26",upNode)
      temp=views.Glow_02_5
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.3,0.3},{"scaleTo",9/60,0.4607,0.4607},{"scaleTo",5/60,0.55,0.55}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",7/60},{"fadeTo",7/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
      temp=views.Glow_02_5_0
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.2,0.2},{"scaleTo",14/60,0.4,0.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",4/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",1/60},{"call",delayFrameIndex_26}}))

   local function delayFrameIndex_29()
     effectManager:addEffect("views2_delay29",upNode)
      temp=views.Strike_00000_4
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
      temp=views.Sprite_7
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"fadeTo",8/60,110},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_29}}))
end

function JakiroEffect:initAttack_move()
  local setting={{28,-55},{96,-5},{75,64},{-75,64},{-96,-5},{-28,-55}}
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
   moveNode:setScale(0.9)

   local function delayFrameIndex_33()
    local function showTargetBao()
      self:initAttack_target()
    end
     moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
     effectManager:addEffect("views2_delay33",moveNode)
      temp=views.Sprite_8
      temp=views.Sprite_8_0
   end
   moveNode:runAction(ui.action.sequence({{"delay",8/60},{"call",delayFrameIndex_33}}))
end

function JakiroEffect:initAttack_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3])
   upNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

     effectManager:addEffect("views2_delay55",upNode)
      temp=views.RTD0_00_3
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.RTD0_00_3_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
end

return {M,V,C}
