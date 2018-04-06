
local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        attackTarget = self.C.skillTarget
    end
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.id%10]
    BeastFiveEffect.new({attacker = self, mode = mode, target = attackTarget,scale=scal,total=3},callback)
end

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    if self.animaConfig.skill_params then
        self.loop = false
        self.isExeRealAtk = false
        self.frameFormat = self.animaConfig.skill_fmt 
        self.animaTime = 0
        self.frameIndex = 0
        self.oneFrameTime = self.animaConfig.skill_params[1]/self.animaConfig.skill_params[2]
        self.frameMaxIndex = self.animaConfig.skill_params[2]
        self.actionTime = 0
        self.allActionTime = self.avtInfo.aspeed
        if self.animaConfig.skill_params[1]>self.avtInfo.aspeed then
            self.allActionTime = self.animaConfig.skill_params[1]
        end
        self.exeAtkFrame = self.animaConfig.skill_params[3]
    else
        self:attack(viewInfo1,viewInfo2,b)
    end
    self.allActionTime = self.allActionTime+self.oneFrameTime*(self.skillStopNum-1)
    self.state = PersonState.SKILL


    self.skillStopNum = 6
    self.exeAtkFrame = 5
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastFiveEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end

local C = class(GodBeast)
--对目标释放一个4X4格的熔岩球，造成[a]+[c]%*攻击力的伤害，并对经过的敌方目标造成[d]%*攻击的伤害。技能冷却时间[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:exeSkillForGodBeast(target)
    target = self.attackTarget
    if not target then
        return
    end
    local w = 4
    local l = self:getSoldierDistance(self.avater.gx,self.avater.gy,target)
    l = math.sqrt(l)+2
    local ps = self.actSkillParams
    local a,c,d = ps.a,ps.c,ps.d
    local result = self:getLineTarget(self,self.battleMap.battlerAll,l,w,target)
    for k,v in ipairs(result) do
        if v~= target then
            SkillPlugin.exe2(self,v,0,d)
        end
    end
    SkillPlugin.exe2(self,target,a,c)
end

BeastFiveEffect=class()

function BeastFiveEffect:ctor(params,callback)
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

function BeastFiveEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastFiveEffect.json")
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

function BeastFiveEffect:initEffect()
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
function BeastFiveEffect:initCurrency()
local setting={{15,64},{11,78},{11,111},{-11,111},{-11,78},{-15,64}}
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
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end
--普攻
function BeastFiveEffect:initAttack()
	local setting={{104,-65},{221,45},{138,187},{-138,187},{-221,45},{-104,-65}}
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
   self.time=moveTime
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+10000)
   moveNode:setScale(baseScal*1.5)
   moveNode:setRotation(r)
   moveNode:setVisible(false)
   effectManager:addEffect("views1_delay29",moveNode)
      temp=views.Particle_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp=views.Particle_6_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp=views.Glow_01_12
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp=views.Glow_01_12_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp=views.Glow_01_12_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
   local function delayFrameIndex_29()
      local function showTargetBao(  )
         self:initAttack_bao()
      end
      moveNode:setVisible(true)
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_29}}))

end
--普攻受击
function BeastFiveEffect:initAttack_bao()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos=self.targetPos
   local temp

  local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+1)
   upNode:setScale(baseScal*1.5)
   upNode:runAction(ui.action.sequence({{"delay",16/60},"remove"}))

     effectManager:addEffect("views2_delay50",upNode)
      temp=views.kk0001_16
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Glow_01_17
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",8/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",7/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))

end
--技能攻击方
function BeastFiveEffect:initSkill()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local total=30/60
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local temp

  local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScaleX(baseScal)
   downNode:setScaleY(baseScal*0.75)
   downNode:runAction(ui.action.sequence({{"delay",total+35/60},"remove"}))
   local function delayFrameIndex_35()
     effectManager:addEffect("views3_delay35",downNode)
      temp=views.Sprite_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.arepeat(ui.action.rotateBy(200/60,360)))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-25/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Glow_01_8
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",total-25/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Glow_01_8_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,216},{"delay",total-25/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_35}}))

end
--技能攻击子弹
function BeastFiveEffect:initSkill_move()
   local setting={{104,-65},{221,45},{138,187},{-138,187},{-221,45},{-104,-65}}
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
   self.speed=400
   local moveTime=math.sqrt((self.targetPos[1]-initPos[1])^2+(self.targetPos[2]-initPos[2])^2)/self.speed
   self.time=moveTime
   local r=-math.deg(math.atan2(moveY,moveX))
   local temp

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+10000)
   moveNode:setScale(baseScal)
   moveNode:setRotation(-90+r)
   moveNode:setVisible(false)
   effectManager:addEffect("views4_delay60",moveNode)
   local function delayFrameIndex_60()
      local function showTargetBao(  )
        self:initSkill_bao()
      end
      moveNode:setVisible(true)
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
     
      temp=views.Glow_01_7
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",18/60,2.0,2.0}}))
      temp=views.Magma_00000_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(8)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",18/60,6.5,6.5}}))
      temp=views.Magma_00000_6_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(9)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",18/60,5,5}}))
      temp=views.Glow_01_11
      temp:setPosition(0,0)
      temp:setLocalZOrder(0)
      temp:runAction(ui.action.sequence({{"delay",8/60},{"scaleTo",moveTime-8/60,3.0567,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",8/60,107},{"delay",moveTime-9/60},{"fadeTo",1/60,0}}))
      temp=views.Glow_01_11_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(0)
      temp:runAction(ui.action.sequence({{"delay",8/60},{"scaleTo",moveTime-8/60,3.0567,0.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",8/60,255},{"delay",moveTime-9/60},{"fadeTo",1/60,0}}))
      temp=views.Particle_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp=views.Particle_2_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp=views.Particle_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp=views.Particle_1_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp=views.Particle_1_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp=views.Particle_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
   end
   moveNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_60}}))
end
--技能受击
function BeastFiveEffect:initSkill_bao()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos=self.targetPos
   local temp


  local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+1)
   upNode:setScale(baseScal*1.47)
   upNode:runAction(ui.action.sequence({{"delay",28/60},"remove"}))

     effectManager:addEffect("views5_delay207",upNode)
      temp=views.Boom_00000_14
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",24/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Boom_00000_15
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",24/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Glow_01_18
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",21/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Glow_01_18_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",21/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Glow_01_18_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",6/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",21/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
end

function BeastFiveEffect:update(diff)
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
