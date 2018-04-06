local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

   FutureWarriorEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--3004 未来战士  对目标及其g格半径范围内的敌人造成a+c%*攻击力的伤害，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    if not target then
        return
    end
    local params = self.actSkillParams
    local a,c = params.a,params.c
    local g = params.g
    local targetG = self:getCircleTarget(target,self.battleMap.battlerAll,g)
    for i,v in ipairs(targetG) do
        SkillPlugin.exe2(self,v,a,c)
    end
end

FutureWarriorEffect=class()

function FutureWarriorEffect:ctor(params,callback)
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
function FutureWarriorEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target)
        self.time = nil
        self.updateMy = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end
function FutureWarriorEffect:initParams(params)
    self.effectManager=GameEffect.new("FutureWarriorEffect.json")
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

function FutureWarriorEffect:initEffect()
  if self.mode==0 then
     self:initAttack()
     self:initAttack_move()
  elseif self.mode==1 then
     self:initSkill()
     self:initSkill_move()
  end
end

--普通攻击开火
function FutureWarriorEffect:initAttack()
  local setting={{27,-20,45},{90,29,0},{70,97,-45},{-70,97,-135},{-90,29,-180},{-27,-20,135}}
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
   bg:addChild(upNode,initPos[3]+12)
   upNode:setRotation(r)
   upNode:runAction(ui.action.sequence({{"delay",72/60},"remove"}))

   local function delayFrameIndex_9()
     effectManager:addEffect("views1_delay9",upNode)
      temp=views.Sprite_17_0_0_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",22/60},{"fadeTo",1/60,0},"remove"}))
      temp=views.Glow_02_25
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",22/60},{"fadeTo",1/60,0},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_9}}))

end
--普攻子弹
function FutureWarriorEffect:initAttack_move()
  local setting={{27,-20,45},{90,29,0},{70,97,-45},{-70,97,-135},{-90,29,-180},{-27,-20,135}}
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


   local function delayFrameIndex_14()
      local pos={{0,0},{-20,-8},{-40,8},{-60,0},{-80,-8},{-100,8},{-120,0}}
      local i=0
      local function createBullte(  )
          i=i+1
          if i>7 then
            return
          end
          effectManager:addEffect("views2_delay14",moveNode)
          temp=views.Bullet_1_Y
          temp:setPosition(pos[i][1],pos[i][2])

          local function showTargetBao()
            self:initAttack_target()
          end
          temp:runAction(ui.action.sequence({{"delay",moveTime-(i-1)*3/60},{"call",showTargetBao},"remove"}))
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime*2,moveX*2,moveY*2},"remove"}))
      moveNode:runAction(ui.action.arepeat(ui.action.sequence({{"call",createBullte},{"delay",3/60}}),7))
   end
   moveNode:runAction(ui.action.sequence({{"delay",14/60},{"call",delayFrameIndex_14}}))

end
--普通攻击受击
function FutureWarriorEffect:initAttack_target()
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
   upNode:runAction(ui.action.sequence({{"delay",36/60},"remove"}))


     effectManager:addEffect("views3_delay37",upNode)
      -- temp=views.Glow_02_46
      -- temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",34/60},{"fadeTo",1/60,0}}))
      -- temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Particle_16
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
end

--技能开火
function FutureWarriorEffect:initSkill()
  local setting={{19,-31,45},{120,26,0},{104,120,-45},{-104,120,-135},{-120,26,-180},{-19,-31,135}}
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
   bg:addChild(upNode,initPos[3]+12)
   upNode:setRotation(r)
   upNode:runAction(ui.action.sequence({{"delay",72/60},"remove"}))

   local function delayFrameIndex_34()
     effectManager:addEffect("views4_delay34",upNode)
      temp=views.Sprite_17_0_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",34/60},{"call",delayFrameIndex_34}}))

   local function delayFrameIndex_37()
     effectManager:addEffect("views4_delay37",upNode)
      temp=views.Glow_02_46_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",6/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
   end
   delayFrameIndex_37()
end
--技能子弹
function FutureWarriorEffect:initSkill_move()
  local setting={{19,-31},{120,26},{104,120},{-104,120},{-120,26},{-19,-31}}
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
   self.time=moveTime+5/60
   local r=-math.deg(math.atan2(moveY,moveX))

   local temp

  local moveNode=ui.node()
  moveNode:setPosition(initPos[1],initPos[2])
  bg:addChild(moveNode,initPos[3]+10000)
  moveNode:setRotation(r)
  moveNode:setVisible(false)
  effectManager:addEffect("views5_delay34",moveNode)
   local function delayFrameIndex_34()
      local function showTargetBao( )
        self:initSkill_target()
      end
      moveNode:setVisible(true)
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
      temp=views.Sprite_6
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Particle_1
      temp=views.Particle_1_0
   end
   delayFrameIndex_34()
end
--技能受击
function FutureWarriorEffect:initSkill_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+100000)
   upNode:setScale(2)
   upNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

   effectManager:addEffect("views6_delay54",upNode)
      temp=views.Circle_1_0
      local scal=0.75
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.8*scal,0.6*scal},{"scaleTo",24/60,1.08*scal,0.81*scal}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",17/60,127},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Circle_1
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.8*scal,0.6*scal},{"scaleTo",24/60,1.08*scal,0.81*scal}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",17/60,127},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.hedangkeng2_13
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",19/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Glow_02_14
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"fadeTo",5/60,170},{"fadeTo",5/60,57},{"fadeTo",5/60,193},{"fadeTo",5/60,126},{"fadeTo",14/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Glow_02_14_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"fadeTo",5/60,170},{"fadeTo",5/60,57},{"fadeTo",5/60,193},{"fadeTo",5/60,126},{"fadeTo",14/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Explosion_00000_11
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",33/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Glow_02_2
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,1.6*scal,1.6*scal}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",3/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))

end

return {M,V,C}
