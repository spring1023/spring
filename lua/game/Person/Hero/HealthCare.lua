local M = class(AvtInfo)













local V = {}
function V:viewEffect(target,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        target = self.C.skillTarget
    end
    HealthCareEffect.new({attacker = self, mode = mode, target = target},callback)
end


local C = class(AvtControler)

--1003 特级医护 恢复己方血量最低的一个目标[a]+[c]%*攻击力的血量，优先英雄，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
    self.skillTarget = self:getMinHpTarget(self.battleMap2.hero) or self:getMinHpTarget(self.battleMap2.battler)
end

function C:sg_exeSkill(target)
    if not target or target.deleted then
        return
    end
    local params = self.actSkillParams
    local a,c = params.a,params.c
    SkillPlugin.exe7(self,target,a,c)
end

HealthCareEffect=class()

function HealthCareEffect:ctor(params,callback)
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

function HealthCareEffect:initParams(params)
    self.effectManager=GameEffect.new("HealthCareEffect.json")
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

function HealthCareEffect:initEffect()
  if self.mode==0 then
     self:initAttack()
     self:initAttack_move()
  elseif self.mode==1 then
     self:initSkill()
  end
end
function HealthCareEffect:initSkill()
  local setting={{58,-14},{116,63},{65,137},{-65,137},{-116,63},{-58,-14}}
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
   local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   self.time=moveTime+4/60
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local function delayFrameIndex_39()

     effectManager:addEffect("views1_delay39",bg)
      local function showTargetBao()
          self:initSkill_target()
      end
      temp=views.Glow_06_10
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10)
      temp:setRotation(-90+r)
      temp:setScale(1.2)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-3/60},{"fadeTo",2/60,0}}))

   end
   delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_39}}))

end

function HealthCareEffect:initSkill_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10000)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",37/60},"remove"}))

   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10+10000)
   downNode:setScale(1.5)
   downNode:runAction(ui.action.sequence({{"delay",21/60},"remove"}))

   local function delayFrameIndex_39()
     effectManager:addEffect("views2_delay39",downNode)
      temp=views.Sprite_9
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",44/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",51/60},"remove"}))
   end
   delayFrameIndex_39()

   local function delayFrameIndex_40()
     effectManager:addEffect("views2_delay40",downNode)
      temp=views.Circle_R_00000_5
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",13/60,0.5,0.375}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",33/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",44/60},"remove"}))
   end
   delayFrameIndex_40()

   local function delayFrameIndex_43()
     effectManager:addEffect("views2_delay43",downNode)
      temp=views.Circle_R_00000_5_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",13/60,0.5,0.375}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",33/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",44/60},"remove"}))

     effectManager:addEffect("views2_delay43_up",upNode)
      temp=views.Particle_2
      temp:runAction(ui.action.sequence({{"delay",63/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_43}}))

   local function delayFrameIndex_46()
     effectManager:addEffect("views2_delay46",upNode)
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",7/60},{"call",delayFrameIndex_46}}))

end

--普攻
function HealthCareEffect:initAttack()
  local setting={{37,28,45},{59,68,0},{21,100,-45},{-21,100,-135},{-59,68,-180},{-37,28,135}}
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
   bg:addChild(upNode,initPos[3]+10)
   upNode:setRotation(r)
   upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_29()
     effectManager:addEffect("views3_delay29",upNode)
      temp=views.Strike_00000_4
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_29}}))

   local function delayFrameIndex_30()
     effectManager:addEffect("views3_delay30",upNode)
      temp=views.Sprite_6
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.7,0.7},{"scaleTo",15/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Sprite_6_0
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.5,0.5},{"scaleTo",15/60,0.7,0.7}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",1/60},{"call",delayFrameIndex_30}}))

end

function HealthCareEffect:initAttack_move()
local setting={{37,28},{59,68},{21,100},{-21,100},{-59,68},{-37,28}}
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
   self.time=moveTime+4/60
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+10000)
   moveNode:setRotation(r)
   moveNode:setScale(1.5)
   local function delayFrameIndex_20()
    local function showTargetBao()
      self:initAttack_target()
    end
     moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
     effectManager:addEffect("views4_delay32",moveNode)
      temp=views.Bullet_8
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",13/60,1.0,1.0}}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",3/60},{"call",delayFrameIndex_20}}))


end

function HealthCareEffect:initAttack_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

  local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",26/60},"remove"}))

     effectManager:addEffect("views5_delay44",upNode)
      temp=views.Sparkless_00001_5
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
end

function HealthCareEffect:update(diff)
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
