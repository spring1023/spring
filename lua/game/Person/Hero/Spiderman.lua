local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    SpidermanEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--3003 蜘蛛侠  对目标造成a+c%*攻击力的伤害，并眩晕t秒，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    if not target or target.deleted then
        return
    end
    local params = self.actSkillParams
    local a,c,t = params.a,params.c,params.t
    BuffUtil.setBuff(target,{lastedTime = t, bfDizziness = t})
    SkillPlugin.exe2(self,target,a,c)
end

SpidermanEffect=class()

function SpidermanEffect:ctor(params,callback)
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
function SpidermanEffect:update(diff)
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
function SpidermanEffect:initParams(params)
    self.effectManager=GameEffect.new("SpidermanEffect.json")
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

function SpidermanEffect:initEffect()
  if self.mode==0 then
     self:initAttack()
  elseif self.mode==1 then
     self:initSkill()
  end
end

--普攻子弹
function SpidermanEffect:initAttack()
  local setting={{8,45},{16,54},{8,66},{-8,66},{-16,54},{-8,45}}
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
   targetPos[2]=targetPos[2]+42
   local temp

    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   self.time=moveTime
   local r=-math.deg(math.atan2(moveY,moveX))


  local moveNode=ui.node()
  moveNode:setPosition(initPos[1],initPos[2])
  bg:addChild(moveNode,initPos[3]+10000)
  moveNode:setScale(1.5)
  moveNode:setRotation(r)


   local function delayFrameIndex_44()
      local function showTargetBao( )
        self:initAttack_target()
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views1_delay44",moveNode)
      temp=views.Bullet_5
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
   end
   delayFrameIndex_44()

   local function delayFrameIndex_46()
     effectManager:addEffect("views1_delay46",moveNode)
      temp=views.Line_00001_1
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",moveTime-5/60},{"fadeTo",3/60,0}}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",2/60},{"call",delayFrameIndex_46}}))

end
--普通受击
function SpidermanEffect:initAttack_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1)
   upNode:runAction(ui.action.sequence({{"delay",26/60},"remove"}))

     effectManager:addEffect("views2_delay80",upNode)
      temp=views.Net0001_1_p
      temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",6/60,0,-42}}))
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,0.5,0.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
      temp=views.Glow_01_3_p
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,1.5,1.125}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,41},{"delay",9/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Glow_01_3_0_p
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,1.5,1.125}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,170},{"delay",9/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))

end
--技能子弹
function SpidermanEffect:initSkill()
  local setting={{8,45},{16,54},{8,66},{-8,66},{-16,54},{-8,45}}
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
   targetPos[2]=targetPos[2]+42
   local temp


    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   self.time=moveTime
   local r=-math.deg(math.atan2(moveY,moveX))
   local leng=math.sqrt(moveX*moveX+moveY*moveY)

  local moveNode=ui.node()
  moveNode:setPosition(initPos[1],initPos[2])
  bg:addChild(moveNode,initPos[3]+10)
  moveNode:setRotation(r)
  moveNode:setScale(1.5)

  local upNode=ui.node()
  upNode:setPosition(initPos[1],initPos[2])
  bg:addChild(upNode,initPos[3]+11)
  upNode:setRotation(r)
  upNode:setScale(1.5)

   local function delayFrameIndex_44()
      local function showTargetBao( )
        self:initSkill_target()
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views3_delay44",moveNode)
      temp=views.Bullet_5
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))

      effectManager:addEffect("views3_delay44_line",upNode)
      temp=views.Glow_08_2
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",moveTime-1/60,leng/32,0.0775}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Glow_08_2_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",moveTime-1/60,leng/32,0.0775}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      upNode:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
   end
   delayFrameIndex_44()

   local function delayFrameIndex_46()
     effectManager:addEffect("views3_delay46",moveNode)
      temp=views.Line_00001_1
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,255},{"delay",moveTime-5/60},{"fadeTo",3/60,0}}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",2/60},{"call",delayFrameIndex_46}}))

end
--技能受击
function SpidermanEffect:initSkill_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp
   local total=46/60+30/60
   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.3)
   upNode:runAction(ui.action.sequence({{"delay",total+5/60},"remove"}))

   effectManager:addEffect("views4_delay69",upNode)

      temp=views.Net0001_1
      temp:runAction(ui.action.sequence({{"delay",1/60},{"moveBy",15/60,0,-42}}))
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",15/60,5,5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",44/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
      temp=views.Glow_01_3
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,1.5,1.125}}))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,41},{"delay",total-37/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-21/60},"remove"}))
      temp=views.Glow_01_3_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,1.5,1.125}}))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,170},{"delay",total-37/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-21/60},"remove"}))
end


return {M,V,C}
