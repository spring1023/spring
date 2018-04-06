local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        ScissorhandEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
    else
        local mode = self.C.rd:randomInt(3)
        local shot = AttackeffectShot.new(nil, 120,0,0,0,attackTarget,1,mode,0,1.25,callback)
        shot.attacker = self
        shot:addToScene(self.scene)
    end
end


local C = class(AvtControler)

--2003 剪刀手  对目标造成a+c%*攻击力的伤害，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    if target and target.deleted then
        return
    end
    local params = self.actSkillParams
    local a,c = params.a,params.c
    SkillPlugin.exe2(self,self.attackTarget,a,c)
end

ScissorhandEffect=class()

function ScissorhandEffect:ctor(params,callback)
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

function ScissorhandEffect:initParams(params)
    self.effectManager=GameEffect.new("ScissorhandEffect.json")
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

function ScissorhandEffect:initEffect()
  if self.mode==0 then
    
  elseif self.mode==1 then
     self:initAttack()
  end
end

function ScissorhandEffect:initAttack()
  local setting={{10,5,-15},{50,40,-60},{55,80,-110},{-55,80,110},{-50,40,60},{-10,5,15}}
  local setting2={{25,20,-55},{40,50,-120},{35,85,-155},{-35,85,155},{-40,50,120},{-25,20,55}}

   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   self.time=10/60
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]+10000

  local initPos2={}
   initPos2[1]=self.initPos[1]+setting2[direction][1]
   initPos2[2]=self.initPos[2]+setting2[direction][2]
   initPos2[3]=self.initPos[3]+10000

   local r=setting[direction][3]
   local r2=setting2[direction][3]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setRotation(r)
   upNode:setScale(1.3)
   upNode:runAction(ui.action.sequence({{"delay",100/60},"remove"}))

  local upNode2=ui.node()
   upNode2:setPosition(initPos2[1],initPos2[2])
   bg:addChild(upNode2,initPos2[3]+10)
   upNode2:setRotation(r2)
   upNode2:setScale(1.3)
   upNode2:runAction(ui.action.sequence({{"delay",100/60},"remove"}))

   local function delayFrameIndex_29()
     effectManager:addEffect("views1_delay29",upNode)
      temp=views.Weapontrail_00000_8
      if direction>3 then
        temp:setFlippedX(true)
      end
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
   end
   delayFrameIndex_29()

   local function delayFrameIndex_31()
     effectManager:addEffect("views1_delay31",upNode)
      temp=views.Paw_Flare_00000_1
      if direction>3 then
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
        temp:setPositionX(-temp:getPositionX())
      end
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",2/60},{"call",delayFrameIndex_31}}))

   local function delayFrameIndex_33()
     effectManager:addEffect("views1_delay33",upNode)
      temp=views.Glow_02_3
      if direction>3 then
        temp:setFlippedX(true)
        temp:setPositionX(-temp:getPositionX())
      end
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,170},{"delay",5/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",9/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_33}}))

   local function delayFrameIndex_44()
     effectManager:addEffect("views1_delay44",upNode2)
      temp=views.Weapontrail_00006_10
      if direction>3 then
        temp:setFlippedX(true)
      end
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_44}}))

   local function delayFrameIndex_46()
     effectManager:addEffect("views1_delay46",upNode2)
      temp=views.Paw_Flare_00000_1_0
      if direction>3 then
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
        temp:setPositionX(-temp:getPositionX())
      end
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",17/60},{"call",delayFrameIndex_46}}))

   local function delayFrameIndex_48()
     effectManager:addEffect("views1_delay48",upNode2)
      temp=views.Glow_02_3_0
      if direction>3 then
        temp:setFlippedX(true)
        temp:setPositionX(-temp:getPositionX())
      end
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,170},{"delay",5/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",9/60},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_48}}))

end

function ScissorhandEffect:update(diff)
    if not self.allTime then
        self.allTime = 0 
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.targetss)
        self.time = nil
        self.updateMy = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end

return {M,V,C}
