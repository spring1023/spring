
local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    local y
    if isSkill then
        mode = 1
        y = self.C.actSkillParams.y
    end
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.id%10]
    BeastTwoEffect.new({attacker = self, mode = mode, target = attackTarget,scale=scal,total=y},callback)
end

function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    if self.animaConfig.skill_params then
        self.loop = false
        self.isExeRealAtk = false

        local sfmt,sparams 
        if type(self.animaConfig.skill_fmt) == "string" then
            sfmt = self.animaConfig.skill_fmt
            sparams = self.animaConfig.skill_params
        else
            sfmt = self.animaConfig.skill_fmt[1]
            sparams = self.animaConfig.skill_params[1]
        end
        self.frameFormat = sfmt
        self.animaTime = 0
        self.frameIndex = 0
        self.oneFrameTime = sparams[1]/sparams[2]
        self.frameMaxIndex = sparams[2]
        self.actionTime = 0
        self.allActionTime = self.avtInfo.aspeed
        if sparams[1]>self.avtInfo.aspeed then
            self.allActionTime = sparams[1]
        end
        self.exeAtkFrame = sparams[3]
    else
        self:attack(viewInfo1,viewInfo2,b)
    end
    self.skillStopNum = 6
    self.exeAtkFrame = 3
    self.allActionTime = self.allActionTime+self.oneFrameTime*(self.skillStopNum-1)
    --通用特效
    local bss = (1/(self.animaConfig.scale or 0.5))
    local scals = {bss*0.25,bss*0.325,bss*0.5}
    local scal=scals[self.C.sid%10]
    BeastTwoEffect.new({attacker = self, mode = 2, target = attackTarget,scale=scal})
    self.state = PersonState.SKILL
end

local C = class(GodBeast)
-- 对3个目标造成[a]+[c]%的伤害，在[y]秒内，目标死亡会对周围半径3格范围内的敌方目标造成[d]%*攻击力的伤害。技能冷却时间[z]秒。
function C:sg_ppexeSkill(target)
    local n = 3
    self.skillTargetGroup = self:getMinDisTarget(n)
    if self.skillTargetGroup[1] then
      self.isSkillAttack = true
      self.isSkillNotAttack = true
    end
end

function C:exeSkillForGodBeast(target)
    if target and not target.deleted then
      local ps = self.actSkillParams
      local a,c,y,d = ps.a,ps.c,ps.y,ps.d
      --target
      target.GB2stateT = {time = y,callback = function()
          local pointT = {}
          local sgx,sgy = target.avater.gx,target.avater.gy
          for k,v in ipairs(self.battleMap.battlerAll) do
              local viewInfo = v.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(v)
              table.insert(pointT,{viewInfo[1],viewInfo[2],viewInfo[3],v})
          end
          local result = Aoe.circlePoint(pointT,{sgx,sgy},3)
          for k,v in ipairs(result) do
              SkillPlugin.exe2(self,v[4],0,d)
          end
          BeastTwoEffect.new({attacker = self.V, mode = 3, target = target})
      end}
      return SkillPlugin.exe2(self,target,a,c)
    end
end

BeastTwoEffect=class()
function BeastTwoEffect:ctor(params,callback)
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

function BeastTwoEffect:initParams(params)
    self.effectManager=GameEffect.new("BeastTwoEffect.json")
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


function BeastTwoEffect:initEffect()
   if self.mode==0 then
      	self:initAttack()
   elseif self.mode==1 then
	    self:initSkill()
	    self:initSkill_move()
   elseif  self.mode==2 then
   	  	self:initCurrency()
   elseif self.mode == 3 then
        self:targetDie()
   end
end
--技能通用
function BeastTwoEffect:initCurrency()
  local setting={{72,-5},{149,85},{75,173},{-75,173},{-149,85},{-72,-5}}
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
      temp=views.Common_00000_32
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Common_00000_32_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",30/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views3_delay20",upNode)
      temp=views.Glow_01_23_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",10/60},{"scaleTo",5/60,8.0,8.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,191},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_20}}))
end
function BeastTwoEffect:initAttack()
   local setting={{114,-99},{231,37},{125,211},{-125,211},{-231,37},{-114,-99}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]*baseScal
   initPos[2]=self.initPos[2]+setting[direction][2]*baseScal
   initPos[3]=self.initPos[3]+10000
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

   local function delayFrameIndex_29()
      local function showTargetBao(  )
         self:initAttack_bao()
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
    effectManager:addEffect("views1_delay29",moveNode)
      temp=views.Fire_00000_76
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp=views.Glow_01
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_29}}))

end
--普通攻击受击
function BeastTwoEffect:initAttack_bao()
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
   upNode:runAction(ui.action.sequence({{"delay",21/60},"remove"}))

     effectManager:addEffect("views2_delay64",upNode)
      temp=views.Sprite_79
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Glow_16_80
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,4,4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
end

function BeastTwoEffect:initSkill()
   local setting={{36,-20},{68,20},{36,60},{-36,60},{-68,20},{-36,-20}}
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local total=self.total
   -- local initPos={}
   -- initPos[1]=self.initPos[1]+setting[direction][1]*baseScal
   -- initPos[2]=self.initPos[2]+setting[direction][2]*baseScal
   -- initPos[3]=self.initPos[3]
   local initPos=self.offInitPos
   local temp

   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(baseScal*1.5)
   downNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

   local function delayFrameIndex_55()
     effectManager:addEffect("views3_delay55",downNode)
      temp=views.Glow_16_2_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,127},{"delay",total-78/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-55/60},"remove"}))
      temp=views.Ground_00000_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",total-78/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-55/60},"remove"}))
      temp=views.Glow_16_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,178},{"delay",total-78/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-55/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_55}}))
end
--技能子弹
function BeastTwoEffect:initSkill_move()
   local setting={{114,-99},{231,37},{125,211},{-125,211},{-231,37},{-114,-99}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local baseScal=self.baseScal
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]*baseScal
   initPos[2]=self.initPos[2]+setting[direction][2]*baseScal
   initPos[3]=self.initPos[3]+10000
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
   moveNode:setScale(baseScal*2)
   moveNode:setRotation(r)
   local function delayFrameIndex_59()
      local function showTargetBao(  )
         self:initSkill_bao()
      end
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
     effectManager:addEffect("views4_delay59",moveNode)
      temp=views.Fire_Ball_00000_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Fire_Ball_00000_2_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
      temp=views.Glow_01_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,153},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_59}}))

end
--技能受击
function BeastTwoEffect:initSkill_bao()
   local effectManager=self.effectManager
   local bg=self.targetView
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local initPos=self.offTargetPos
   local baseScal=self.baseScal
   local total=self.total
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(baseScal*2)
   upNode:runAction(ui.action.sequence({{"delay",total+37/60},"remove"}))

   local function delayFrameIndex_93()
    if self.target.deleted then
      total = 1
    end
     effectManager:addEffect("views5_delay93",upNode)
      temp=views.Fire_00000_12
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",19/60,255},{"delay",total-39/60},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
      temp=views.Shockwave_00000_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
      temp=views.Shockwave_00000_6_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
      temp=views.Sprite_9
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Glow_01_11
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0},{"call",delayFrameIndex_93}}))

   local function delayFrameIndex_213()
     effectManager:addEffect("views5_delay213",upNode)
      temp=views.Shockwave_00000_6_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
      temp=views.Shockwave_00000_6_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
      temp=views.Sprite_9_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(8)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Glow_01_11_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(9)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Glow_01_15
      temp:setPosition(0,0)
      temp:setLocalZOrder(10)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",16/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",16/60},{"fadeTo",30/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
   end
   --upNode:runAction(ui.action.sequence({{"delay",total-20/60},{"call",delayFrameIndex_213}}))
end

function BeastTwoEffect:targetDie()
    local bg = self.viewsNode
    local upNode=ui.node()
    local views=self.views
    local temp
    upNode:setPosition(self.targetPos[1],self.targetPos[2])
    bg:addChild(upNode,self.targetPos[3])
    upNode:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    local effectManager=self.effectManager
    effectManager:addEffect("views5_delay213",upNode)
    temp=views.Shockwave_00000_6_1
    temp:setPosition(0,0)
    temp:setLocalZOrder(6)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",18/60},{"fadeTo",18/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    temp=views.Shockwave_00000_6_0_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(7)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",18/60},{"fadeTo",18/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
    temp=views.Sprite_9_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(8)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,2.0,2.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",6/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
    temp=views.Glow_01_11_0
    temp:setPosition(0,0)
    temp:setLocalZOrder(9)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,3.0,3.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
    temp=views.Glow_01_15
    temp:setPosition(0,0)
    temp:setLocalZOrder(10)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",16/60,3.0,3.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",16/60},{"fadeTo",30/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
end

function BeastTwoEffect:update(diff)
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
