local M = class(AvtInfo)


local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    local params = self.C.actSkillParams
   VampireEffect.new({attacker = self, mode = mode, target = attackTarget,total=params.y},callback)
end


local C = class(AvtControler)

--2002 吸血鬼 持续y秒内，每次普通攻击使自身恢复c%*实际伤害值的血量，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local c,y = params.c,params.y
    BuffUtil.setBuff(self,{lastedTime = y, bfSuckBlood = {c}})
end

VampireEffect=class()

function VampireEffect:ctor(params,callback)
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

function VampireEffect:initParams(params)
    self.effectManager=GameEffect.new("VampireEffect.json")
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

function VampireEffect:initEffect()
  if self.mode==0 then
     self:initAttack()
  elseif self.mode==1 then
     self:initSkill()
  end
end

function VampireEffect:initSkill()
  self.time = 0
  local setting={{29,-7},{96,47},{68,116},{-68,116},{-96,47},{-29,-7}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]+10000

   local total=self.total
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1]+setting[direction][1],initPos[2]+setting[direction][2])
   bg:addChild(upNode,initPos[3]+12)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",total+60/60},"remove"}))

    local upNode2=ui.node()
   upNode2:setPosition(0,0)
   upNode:setScale(1.5)
   self.attacker.view:addChild(upNode2,initPos[3]+12)
   upNode2:runAction(ui.action.sequence({{"delay",total+60/60},"remove"}))

   local function delayFrameIndex_29()
     effectManager:addEffect("views1_delay29",upNode)
      temp=views.Glow_02_12
      temp:runAction(ui.action.sequence({{"delay",17/60},{"scaleTo",3/60,1.0,1.0},{"scaleTo",1/60,2.0,2.0},{"scaleTo",12/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",16/60},{"delay",13/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",33/60},"remove"}))
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_29}}))

   local function delayFrameIndex_46()
     effectManager:addEffect("views1_delay46",upNode)
      temp=views.Sprite_1
      temp:runAction(ui.action.sequence({{"delay",3/60},{"scaleTo",1/60,1.0,1.0},{"scaleTo",11/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",3/60,255},{"delay",1/60},{"delay",9/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",17/60},{"call",delayFrameIndex_46}}))

   local function delayFrameIndex_49()
     effectManager:addEffect("views1_delay49",upNode)
      temp=views.Blood_00011_9
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_49}}))

   local function delayFrameIndex_59()
     effectManager:addEffect("views1_delay59",upNode2)
      temp=views.Particle_2
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Particle_3
      temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",20/60,0,13}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_59}}))

end
function VampireEffect:initAttack()
  self.time = 0
  local setting={{14,-2},{73,41},{60,97},{-60,97},{-73,41},{-14,-2}}

   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]+10000

   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+12)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",116/60},"remove"}))

   local function delayFrameIndex_29()
     effectManager:addEffect("views2_delay29",upNode)
      temp=views.Glow_02_12
      temp:runAction(ui.action.sequence({{"delay",17/60},{"scaleTo",3/60,0.5,0.5},{"scaleTo",1/60,1,1},{"scaleTo",12/60,0.25,0.25}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",16/60},{"delay",13/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",33/60},"remove"}))
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_29}}))

   local function delayFrameIndex_46()
     effectManager:addEffect("views2_delay46",upNode)
      temp=views.Sprite_1
      temp:runAction(ui.action.sequence({{"delay",3/60},{"scaleTo",1/60,0.5,0.5},{"scaleTo",11/60,0.15,0.15}}))
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",1/60},{"delay",9/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",17/60},{"call",delayFrameIndex_46}}))

   local function delayFrameIndex_49()
     effectManager:addEffect("views2_delay49",upNode)
      temp=views.Blood_00011_9
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_49}}))
end
function VampireEffect:update(diff)
    if not self.allTime then
        self.allTime = 0 
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target)
        self.time = nil
        self.update = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end



return {M,V,C}
