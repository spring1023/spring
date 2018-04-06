
local M = class(AvtInfo)

local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        local skillTargetGroup=self.C:getMinDisTarget(self.C.actSkillParams.n,8)
      if not skillTargetGroup[1] then
        return
      end
      MacGunZbEffect.new({attacker = self, mode = mode, target = attackTarget,group=skillTargetGroup},callback)
    else
      MacGunZbEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
    end
end

local C = class(AvtControler)

--9001    机枪僵尸  随机对周围8格范围内的n个目标造成一次[a]+[c]%的伤害。冷却[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local a,c,n = params.a,params.c,params.n
    local skillTargetGroup = self:getMinDisTarget(n,8)
    if not skillTargetGroup[1] then
      return
    end
    self.skillTargetGroup=skillTargetGroup
    for i,v in ipairs(skillTargetGroup) do
        SkillPlugin.exe2(self,v,a,c)
    end
end

MacGunZbEffect=class()

function MacGunZbEffect:ctor(params,callback)
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
function MacGunZbEffect:update(diff)
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
function MacGunZbEffect:initParams(params)
    self.effectManager=GameEffect.new("MacGunZbEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode=self.attacker.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.total=params.total
    self.baseScal=params.scale or 1

    self.group=params.group

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

function MacGunZbEffect:initEffect()
  if self.mode==0 then
    self:attack()
    self:attack_move()
  elseif self.mode==1 then
    self:initSkill()
    self:initSkill_move()
  end
end

--技能攻击
function MacGunZbEffect:initSkill()
   local setting={{110,50,45},{127,167,0},{27,247,-45},{-27,247,-135},{-127,167,-180},{-110,50,135}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local centerTarget=self.group[math.ceil(#self.group/2)]
        local view,height,targetZ
        if centerTarget.avater then
            view = centerTarget.avater.view
            height = 40 + centerTarget.avater.animaConfig.Ymove
            targetZ = 41 + centerTarget.avater.animaConfig.Ymove
        else
            view = centerTarget.view
            height = view:getContentSize().height/2
            targetZ = 0
        end
        local targetPos = {view:getPositionX(),view:getPositionY() + height}
        if centerTarget.viewInfo then
            targetPos[2] = targetPos[2] + centerTarget.viewInfo.y
        end
        targetPos[3] = General.sceneHeight-targetPos[2]+targetZ
   self.centerPos={}
   local oy=math.abs(targetPos[2]-initPos[2])/2
   if oy<400 then
      oy=400
   end
   self.centerPos[1]=targetPos[1]
   self.centerPos[2]=targetPos[2]+oy
   self.centerPos[3]=targetPos[3]

   local r=setting[direction][3]
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setRotation(r)
   upNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

   local function delayFrameIndex_30()
     effectManager:addEffect("views1_delay30",upNode)
      temp=views.Common_O_00000_6_0
      temp:runAction(ui.action.sequence({{"fadeTo",9/60,102},{"fadeTo",3/60,255},{"delay",11/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",33/60},"remove"}))
      temp=views.Common_O_00000_6
      temp:runAction(ui.action.sequence({{"fadeTo",9/60,102},{"fadeTo",3/60,255},{"delay",11/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",33/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_30}}))

   local function delayFrameIndex_55()
     effectManager:addEffect("views1_delay55",upNode)
      temp=views.Glow_01_7_1
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.2,1.2},{"scaleTo",20/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Glow_01_7
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,1.1,1.1},{"scaleTo",20/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Glow_01_7_0
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.9,0.9},{"scaleTo",20/60,1.3,1.3}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",5/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_55}}))

   local function delayFrameIndex_58()
     effectManager:addEffect("views1_delay58",upNode)
      temp=views.Sparkless_00000_14
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",28/60},{"call",delayFrameIndex_58}}))

   local function delayFrameIndex_59()
     effectManager:addEffect("views1_delay59",upNode)
      temp=views.t_00000_15
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",9/60,0.7,0.9}}))
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",7/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
      temp=views.t_00000_15_0
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",9/60,0.8,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",7/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
      temp=views.t_00000_15_1
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",9/60,0.5,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",7/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
      temp=views.t_00000_15_1_0
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",9/60,0.5,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",7/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",29/60},{"call",delayFrameIndex_59}}))

   local function delayFrameIndex_60()
     effectManager:addEffect("views1_delay60",upNode)
      temp=views.Shockwave_00000_17
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.6,1.4},{"scaleTo",14/60,0.65,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
      temp=views.Shockwave_00000_17_0
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.6,1.4},{"scaleTo",14/60,0.65,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"fadeTo",10/60,153},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_60}}))
end
--打到空中子弹
function MacGunZbEffect:initSkill_move()
   local setting={{110,50,45},{127,167,0},{27,247,-45},{-27,247,-135},{-127,167,-180},{-110,50,135}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]

   local targetPos=self.centerPos

   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   local r=-math.deg(math.atan2(moveY,moveX))

   local temp

   local function delayFrameIndex_60()
      local moveNode=ui.node()
      moveNode:setPosition(initPos[1],initPos[2])
      bg:addChild(moveNode,initPos[3]+10)
      moveNode:setRotation(-90+r)
      effectManager:addEffect("views2_delay19",moveNode)
      local function showTargetBao(  )
         self:initSkill_target1()
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
     effectManager:addEffect("views2_delay60",moveNode)
   end
   delayNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_60}}))

end
--空中爆炸
function MacGunZbEffect:initSkill_target1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.centerPos
   local temp

    for i,v in ipairs(self.group) do
        local view,height,targetZ
        if v.avater then
            view = v.avater.view
            height = 40 + v.avater.animaConfig.Ymove
            targetZ = 41 + v.avater.animaConfig.Ymove
        else
            view = v.view
            height = view:getContentSize().height/2
            targetZ = 0
        end
        local targetPos = {view:getPositionX(),view:getPositionY() + height}
        if v.viewInfo then
            targetPos[2] = targetPos[2] + v.viewInfo.y
        end
        targetPos[3] = General.sceneHeight-targetPos[2]+targetZ
        self:initSkill_move2(targetPos)
    end

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",50/60},"remove"}))

     effectManager:addEffect("views3_delay74",upNode)
      temp=views.Impact_00000_20
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.6,0.6},{"scaleTo",5/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",31/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
      temp=views.Fire_Impact_00001_22
      temp:runAction(ui.action.sequence({{"delay",17/60},{"scaleTo",9/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",35/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",41/60},"remove"}))
      temp=views.Impact_00000_20_0
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,178},{"delay",39/60},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))
end
--打到人物的子弹
function MacGunZbEffect:initSkill_move2(targetPos)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos=self.centerPos

   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local function delayFrameIndex_85()
      local moveNode=ui.node()
      moveNode:setPosition(initPos[1],initPos[2])
      bg:addChild(moveNode,initPos[3]+10)
      moveNode:setRotation(-90+r)
      effectManager:addEffect("views2_delay19",moveNode)
      local function showTargetBao(  )
         self:initSkill_target2(targetPos)
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views4_delay85",moveNode)
   end
   delayNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_85}}))

end

--受击
function MacGunZbEffect:initSkill_target2(targetPos)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=targetPos
   local temp
   self.time=0.5
   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",55/60},"remove"}))

     effectManager:addEffect("views5_delay98",upNode)
      temp=views.RTD0_00_25_b
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",5/60},{"delay",24/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Explosion_00000_27_b
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,2.3,2.7}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,160}}))
      temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))
      temp=views.RTD0_00_25_0_b
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",5/60},{"delay",24/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
      temp=views.Explosion_00000_27_0_b
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,2.3,2.7}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",6/60,160}}))
      temp:runAction(ui.action.sequence({{"delay",55/60},"remove"}))

end

--普通攻击开火
function MacGunZbEffect:attack()
   local setting={{123,-74,45},{271,81,0},{153,250,-45},{-153,250,-135},{-271,81,-180},{-123,-74,135}}
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
   bg:addChild(upNode,initPos[3]+10000)
   upNode:setRotation(r)
   upNode:runAction(ui.action.sequence({{"delay",72/60},"remove"}))

   local function delayFrameIndex_9()
     effectManager:addEffect("attack_views1_delay9",upNode)
      temp=views.Sprite_17_0_0_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",22/60},{"fadeTo",1/60,0},"remove"}))
      temp=views.Glow_02_25
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",22/60},{"fadeTo",1/60,0},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_9}}))

end
--普攻子弹
function MacGunZbEffect:attack_move()
  local setting={{123,-74,45},{271,81,0},{153,250,-45},{-153,250,-135},{-271,81,-180},{-123,-74,135}}
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
   local r=-math.deg(math.atan2(moveY,moveX))
   self.time=moveTime
   local temp

  local moveNode=ui.node()
  moveNode:setPosition(initPos[1],initPos[2])
  bg:addChild(moveNode,initPos[3]+10000)
  moveNode:setRotation(r)


   local function delayFrameIndex_14()
      local pos={{0,0},{-60,-15},{-120,15},{-180,0},{-240,-15},{-300,15},{-360,0}}
      local i=0
      local function createBullte(  )
          i=i+1
          if i>7 then
            return
          end
          effectManager:addEffect("attack_views2_delay14",moveNode)
          temp=views.Bullet_1_Y
          temp:setPosition(pos[i][1],pos[i][2])

          temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      end

      local function showTargetBao()
          self:attack_bao()
      end
      moveNode:runAction(ui.action.sequence({{"delay",moveTime},{"call",showTargetBao}}))
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime*10,moveX*10,moveY*10,"remove"}}))
      moveNode:runAction(ui.action.arepeat(ui.action.sequence({{"call",createBullte},{"delay",3/60}}),7))
   end
   moveNode:runAction(ui.action.sequence({{"delay",14/60},{"call",delayFrameIndex_14}}))

end
--普通攻击受击
function MacGunZbEffect:attack_bao()
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
   upNode:runAction(ui.action.sequence({{"delay",45/60},"remove"}))

     effectManager:addEffect("attack_views3_delay37",upNode)
      temp=views.Glow_01_29
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,0},{"delay",5/60}}),3))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
      temp=views.Glow_01_29_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",5/60,0},{"delay",5/60}}),3))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
      temp=views.Particle_16
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
end

return {M,V,C}
