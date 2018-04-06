
local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    MissileZbEffect.new({attacker = self, mode = mode, target = attackTarget,total=5},callback)
end


local C = class(AvtControler)

--9002    导弹僵尸  对目标及其周围敌方单位造成一次[a]+[c]%攻击力的伤害。并造成每秒[d]%攻击力的持续伤害，持续5秒。冷却[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    local target = self.attackTarget
    if not target or target.deleted then
        return
    end
    local params = self.actSkillParams
    local a,c,d = params.a,params.c,params.d
    local result = self:getCircleTarget(target,self.battleMap.battlerAll,3)
    for i,v in ipairs(result) do
        SkillPlugin.exe2(self,v,a,d)
        BuffUtil.setBuff(v,{lastedTime = 5,lastAddHp = -d*self.M.atk*5})
    end
end

MissileZbEffect=class()

function MissileZbEffect:ctor(params,callback)
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
function MissileZbEffect:update(diff)
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
function MissileZbEffect:initParams(params)
    self.effectManager=GameEffect.new("MissileZbEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode =self.attacker.scene.delayNode
    self.speed = params.speed or 600
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

function MissileZbEffect:initEffect()
  if self.mode==0 then
     self:attack()
  elseif self.mode==1 then
    self:initSkill()
    self:initSkill_move()
  end
end

function MissileZbEffect:initSkill()
  local setting={{119,-66,45},{229,79,0},{122,234,-45},{-122,234,-135},{-229,79,-180},{-119,-66,135}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local r=90+setting[direction][3]
   local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+20)
    upNode:setRotation(r)
    upNode:runAction(ui.action.sequence({{"delay",40/60},"remove"}))

   local function delayFrameIndex_10()
     effectManager:addEffect("views1_delay10",upNode)
      temp=views.Common_G_00000_2_a
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",16/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_10}}))

   local function delayFrameIndex_15()
     effectManager:addEffect("views1_delay15",upNode)
      temp=views.Glow_01_4_1_a
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.5,1.5},{"scaleTo",15/60,2.4,2.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
      temp=views.Glow_01_4_a
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.0,1.0},{"scaleTo",19/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",19/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
      temp=views.Glow_01_4_0_a
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.7,0.7},{"scaleTo",19/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",19/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_15}}))

   local function delayFrameIndex_16()
     effectManager:addEffect("views1_delay16",upNode)
      temp=views.Sparkless_00000_8_a
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",24/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",16/60},{"call",delayFrameIndex_16}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views1_delay20",upNode)
      temp=views.guang1_00000_3_a
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",12/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      temp=views.guang1_00000_3_0_a
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",12/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))

end

function MissileZbEffect:initSkill_move()
  local setting={{119,-66},{229,79},{122,234},{-122,234},{-229,79},{-119,-66}}
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
   self.time=moveTime+20/60
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local function delayFrameIndex_19()
      local moveNode=ui.node()
      moveNode:setPosition(initPos[1],initPos[2])
      bg:addChild(moveNode,initPos[3]+10000)
      moveNode:setRotation(-90+r)
      moveNode:setVisible(false)
      effectManager:addEffect("views2_delay19",moveNode)
      local function showTargetBao(  )
         self:initSkill_target()
      end
      moveNode:setVisible(true)
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
      temp=views.Particle_2_move
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",15/60,-1.1987,1.1}}))
      temp=views.Particle_1_0_move
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",15/60,1.4254,1.4}}))
      temp=views.Poison_4_move
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",moveTime-4/60},{"fadeTo",2/60,0}}))
      temp=views.Particle_1_move
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",15/60,1.4254,1.4}}))
   end
   bg:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_19}}))

end
--受击，灼烧
function MissileZbEffect:initSkill_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local total=self.total
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",total+45/60},"remove"}))

   local bg2=self.target.avater and self.target.avater.view or self.target.view
   local upNode2=ui.node()
   upNode2:setPosition(self.offTargetPos[1],self.offTargetPos[2])
   bg2:addChild(upNode2,10)
   upNode2:runAction(ui.action.sequence({{"delay",total+45/60},"remove"}))

   local function delayFrameIndex_34()
     effectManager:addEffect("views3_delay34",upNode)
      temp=views.Impact_Green_00000_6
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",35/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",54/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_34}}))

   local function delayFrameIndex_35()
     effectManager:addEffect("views3_delay35",upNode)
      temp=views.putong_00000_5
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",45/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",65/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",1/60},{"call",delayFrameIndex_35}}))

   local function delayFrameIndex_40()
     effectManager:addEffect("views3_delay40",upNode)
      temp=views.Shockwave_00000_7
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",45/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",6/60},{"call",delayFrameIndex_40}}))

   local function delayFrameIndex_75()
    if self.target.deleted then
      return
    end
     effectManager:addEffect("views3_delay75",upNode2)
      temp=views.Particle_3_0
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Fire_00000_1_0
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,178},{"fadeTo",215/60,153},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",41/60},{"call",delayFrameIndex_75}}))

   local function delayFrameIndex_79()
      if self.target.deleted then
        return
      end
     effectManager:addEffect("views3_delay79",upNode2)
      temp=views.Particle_3_1
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",45/60},{"call",delayFrameIndex_79}}))

end


function MissileZbEffect:attack()
  local setting={{119,-66,45},{229,79,0},{122,234,-45},{-122,234,-135},{-229,79,-180},{-119,-66,135}}
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
   self.time=moveTime+12/60
   local r=-math.deg(math.atan2(moveY,moveX))
   local rr=setting[direction][3]
   local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+10000)
    upNode:setRotation(rr)
    upNode:runAction(ui.action.sequence({{"delay",51/60},"remove"}))

   local function delayFrameIndex_9()
     effectManager:addEffect("attack_views1_delay9",upNode)
      temp=views.Sprite_58
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Glow_01_60
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",44/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_9}}))

    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+10000)
    moveNode:setRotation(r)
    moveNode:setVisible(false)
    effectManager:addEffect("attack_views1_delay19",moveNode)
   local function delayFrameIndex_19()
      local function showTargetBao(  )
         self:attack_Bao()
      end
      moveNode:setVisible(true)
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_19}}))

end

function MissileZbEffect:attack_Bao()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+10)
    upNode:setScale(1.5)
    upNode:runAction(ui.action.sequence({{"delay",51/60},"remove"}))

   local function delayFrameIndex_44()
     effectManager:addEffect("attackBao_views2_delay44",upNode)
      temp=views.hedangkeng2_62
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
      temp=views.Glow_01_63
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",35/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",51/60},"remove"}))
      temp=views.Explosion_00000_61
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",33/60},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Glow_01_65
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",3/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_44}}))

   local function delayFrameIndex_50()
     effectManager:addEffect("attackBao_views2_delay50",bg)
      temp=views.Glow_01_63_0
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",10/60,127},{"fadeTo",10/60,204},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
   end
   bg:runAction(ui.action.sequence({{"delay",6/60},{"call",delayFrameIndex_50}}))

end



return {M,V,C}
