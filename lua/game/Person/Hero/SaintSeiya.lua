--控制

local M = class(AvtInfo)












--数据
local V = {}








--表现
local C = class(AvtControler)
--4002自身一次性回血a+c%*攻击力的血量,并在t秒内持续恢复b血量，同时增加d%移速
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    --local a,b,c,t,d = params.a,params.b,params.c,params.t,params.d
    local a,c,b,d,t = params.a,params.c,params.b,params.d,params.t
    SkillPlugin.exe7(self,self,a,c) 
    BuffUtil.setBuff(self,{lastAddHp = b,lastedTime = t})
    BuffUtil.setBuff(self,{bfMovePct = d,lastedTime = t})
end

function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local params = self.actSkillParams
    --local a,b,c,t,d = params.a,params.b,params.c,params.t,params.d
    local a,b,c,t,d = params.a,params.b,params.c,params.t
    SkillPlugin.exe7(self,self,a,b) 
    BuffUtil.setBuff(self,{lastAddHp = c,lastedTime = t})
    BuffUtil.setBuff(self,{bfMovePct = d,lastedTime = t})
end

function V:godSkillViewEffect(attackTarget,callback,lastedTime)
    self:viewEffect(attackTarget,callback,true,lastedTime)
end


function V:viewEffect(attackTarget,callback,isSkill,lastedTime)
    local attackmode = 0
    if isSkill then
        attackmode = 1
    end

    local p = {self.view:getPosition()}
    local x,y = 0,self.animaConfig.Ymove
    p[3] = General.sceneHeight - p[2]
    p[1] = p[1] + x
    p[2] = p[2] + y
    local shot = SaintSeiyaShot.new(100, 1250, p[1], p[2], p[3],attackTarget,1,self.direction,attackmode,callback,lastedTime)
    shot.attacker = self
    if isSkill then
        shot.targetPos = p
    end
    shot:addToScene(self.scene)
end

SaintSeiyaShot=class(SingleShot)
function SaintSeiyaShot:ctor(attack, speed, x, y, z, target,level,dir,attackmode,callback,lastedTime)
    self.lastedTime = lastedTime
    self.callback = callback
    self.speed = speed
    self.attackmode=attackmode
    self.dir=dir
    self.effectManager=GameEffect.new("SaintSeiyaEffect.json")
    self.effectViews=self.effectManager.views

    self.scene = GMethod.loadScript("game.View.Scene")
    self.dnode = ui.node()
    self.scene.objs:addChild(self.dnode)
end

function SaintSeiyaShot:update(diff)
if not self.view then return end
    local stateTime = self.stateTime + diff
    local state = self.state
    if stateTime >= self.time[state] then
        self.state = state+1
        stateTime = stateTime - self.time[state]
        self.view = nil
        self.callback(self.target)
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
    self.stateTime = stateTime
end

function SaintSeiyaShot:initView()
	  self.time={0}
    self.state = 1
    if self.attackmode==0 then
      self.time={5/60}
      self.view=true
      self.scene = GMethod.loadScript("game.View.Scene")
      if self.scene.replay then
          self.scene.replay:addUpdateObj(self)
      else
          RegActionUpdate(self, Handler(self.update, self, 0.025), 0.025)
      end
      self:createAttackEffect()
    elseif self.attackmode==1 then
      self:createSkillEffect()
      self.callback()
    end
end

function SaintSeiyaShot:createSkillEffect()
   local lastedTime = self.lastedTime
   local x,y = 0,self.attacker.animaConfig.Ymove
   local bg=self.attacker.view

   local effectManager=self.effectManager
   local views=self.effectViews
   local initPos={0,0,0}
   local temp
   self.dnode:runAction(ui.action.sequence({{"delay",67/60},"remove"}))

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   upNode:setScale(3)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",lastedTime+20/60},"remove"}))

      local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   downNode:setScale(3)
   bg:addChild(downNode,initPos[3]-10)
   downNode:runAction(ui.action.sequence({{"delay",lastedTime+20/60},"remove"}))

   local function delayFrameIndex_64()
     effectManager:addEffect("views1_delay64",downNode)
      temp=views.Circle_Hue130_12
      temp:setPosition(0,0)
      temp:setLocalZOrder(-1)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",1/60},{"scaleTo",50/60,0.5,0.375},{"scaleTo",25/60,0.3,0.225},{"scaleTo",50/60,0.5,0.375}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",20/60,0},{"delay",24/60},{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",20/60,0}})))
      temp:runAction(ui.action.sequence({{"delay",lastedTime},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_64}}))


   local function delayFrameIndex_55()
     effectManager:addEffect("views1_delay55",downNode)
      temp=views.Circle_Hue130_9
      temp:setPosition(0,0)
      temp:setLocalZOrder(-2)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0/60},{"fadeTo",20/60,255},{"delay",lastedTime-40/60},{"fadeTo",20/60,0}})))
      temp:runAction(ui.action.sequence({{"delay",lastedTime},"remove"}))

    effectManager:addEffect("views1_delay55_up",upNode)
      temp=views.Shield_00000_5
      temp:setPosition(0,30)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0/60},{"fadeTo",20/60,255},{"delay",lastedTime-40/60},{"fadeTo",20/60,0}})))
      temp:runAction(ui.action.sequence({{"delay",lastedTime},"remove"}))
      temp=views.Shield_00000_5_0
      temp:setPosition(0,30)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0/60},{"fadeTo",20/60,153},{"delay",lastedTime-40/60},{"fadeTo",20/60,0}})))
      temp:runAction(ui.action.sequence({{"delay",lastedTime},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_55}}))
end

function SaintSeiyaShot:createAttackEffect()
   local SETTING={{15,32,0},{30,54,-45},{13,66,-90},{-13,66,90},{-30,54,45},{-15,32,0}}
   local effectManager=self.effectManager
  local bg=self.scene.objs
   local views=self.effectViews
   local dir=self.dir
   local ox=SETTING[dir][1]
   local oy = SETTING[dir][2]
   local r=SETTING[dir][3]
   local initPos={self.initPos[1]+ox,self.initPos[2]+oy,self.initZorder+100}
   local temp

   self.dnode:runAction(ui.action.sequence({{"delay",29/60},"remove"}))

   local atNode = ui.node()
   atNode:setPosition(initPos[1],initPos[2])
   bg:addChild(atNode,initPos[3])
   atNode:setRotation(r)
   atNode:runAction(ui.action.sequence({{"delay",40/60},"remove"}))

   local function delayFrameIndex_26()
     effectManager:addEffect("views2_delay26",atNode)
     local ox,oy=62,-76
      if dir>3 then
      	ox=-ox
      	views.Flare_1:setFlippedX(true)
      	views.Glow_01_2:setFlippedX(true)
      end
      temp=views.Flare_1
      temp:setPosition(ox,oy)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",3/60},}))
      temp:runAction(ui.action.sequence({{"delay",3/60},{"scaleTo",2/60,0.3,0.3}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",6/60},"remove"}))
      temp=views.Glow_01_2
      temp:setPosition(ox,oy)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",2/60,0.3,0.3},{"scaleTo",2/60,0.1,0.1}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",6/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",11/60},{"call",delayFrameIndex_26}}))

   local function delayFrameIndex_20()
     effectManager:addEffect("views2_delay20",atNode)
      if dir>3 then
      	views.Weapontrail_60_00000_30:setFlippedX(true)
      	views.Weapontrail_60_00000_30_0:setFlippedX(true)
      end
      temp=views.Weapontrail_60_00000_30
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
      temp=views.Weapontrail_60_00000_30_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,128},{"fadeTo",10/60,127},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_20}}))

end

return {M,V,C}
