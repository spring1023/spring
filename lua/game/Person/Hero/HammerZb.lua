
local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    HammerZbEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--9003    铁锤僵尸  对目标造成一次[a]+[c]%的伤害，自身减伤[d]%，并恢复自身[e]%的血量。冷却[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    local target = self.attackTarget
    if not target or target.deleted then
        return
    end
    local params = self.actSkillParams
    local a,c,d,e,k = params.a,params.c,params.d,params.e,params.k
    SkillPlugin.exe2(self,target,a,c)
    local value = BattleUtil.getHeal(self,self,0,e)
    self:damage(value)
    BuffUtil.setBuff(self,{lastedTime = k,bfDefPct = d})
end

HammerZbEffect=class()

function HammerZbEffect:ctor(params,callback)
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
function HammerZbEffect:update(diff)
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
function HammerZbEffect:initParams(params)
    self.effectManager=GameEffect.new("HammerZbEffect.json")
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

function HammerZbEffect:initEffect()
  if self.mode==0 then
     self:attack()
  elseif self.mode==1 then
    self:initSkill()
    self:initSkill_target()
  end
end

function HammerZbEffect:initSkill()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local temp
   self.time=15/60

    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10000)
   upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))
   local rs={0,-45,-75,75,45,0}
   upNode:setRotation(rs[direction])
   local function delayFrameIndex_15()
     effectManager:addEffect("views1_delay15",upNode)
      temp=views.Dao_00003_2
      if direction>3 then
        temp:setFlippedX(true)
      end
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",25/60},{"fadeTo",7/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_15}}))

end

function HammerZbEffect:initSkill_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos

   local total=270/60
   local temp

    --爆炸节点
   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10000)
   upNode:runAction(ui.action.sequence({{"delay",65/60},"remove"}))

   local function delayFrameIndex_24()
     effectManager:addEffect("views2_delay24",upNode)
      temp=views.Sprite_7
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",4/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",6/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_24}}))

   local function delayFrameIndex_25()
     effectManager:addEffect("views2_delay25",upNode)
      temp=views.Sparkless_00000_5
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",3/60,255},{"delay",17/60},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_25}}))

   local function delayFrameIndex_26()
     effectManager:addEffect("views2_delay26",upNode)
      temp=views.Glow_02_3
      temp:runAction(ui.action.sequence({{"scaleTo",4/60,1.2,1.2},{"scaleTo",15/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
      temp=views.Glow_01_4
      temp:runAction(ui.action.sequence({{"scaleTo",4/60,0.5,0.5},{"scaleTo",15/60,0.8,0.8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",19/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",11/60},{"call",delayFrameIndex_26}}))

   local function delayFrameIndex_29()
     effectManager:addEffect("views2_delay29",bg)
      temp=views.kb_00018_4
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",25/60},{"fadeTo",1/60,0},{"delay",9/60}}))
      temp:runAction(ui.action.sequence({{"delay",36/60},"remove"}))
   end
   bg:runAction(ui.action.sequence({{"delay",14/60},{"call",delayFrameIndex_29}}))
    --[[
   local function delayFrameIndex_34()
     if self.target.deleted then
      return
     end
    local bg2=self.target.avater and self.target.avater.view or self.target.view
    local upNode2=ui.node()
     upNode2:setPosition(self.offTargetPos[1],self.offTargetPos[2]+120)
     bg2:addChild(upNode2,10)
     upNode2:runAction(ui.action.sequence({{"delay",total},"remove"}))

     effectManager:addEffect("views2_delay34",upNode2)
      temp=views.Vertigo_00000_6
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",total-2/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_34}}))
    --]]
end

function HammerZbEffect:attack()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local temp
   self.time=15/60
   local function delayFrameIndex_20()
      local upNode=ui.node()
      upNode:setPosition(initPos[1],initPos[2])
      bg:addChild(upNode,initPos[3]+10000)
      upNode:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
    local dir=direction
    if dir>3 then
      dir=7-dir
    end
     effectManager:addEffect("attack_views_delay20_"..dir,upNode)

      temp=views.A_00000_3
      temp:runAction(ui.action.sequence({{"delay",1/60},{"fadeTo",5/60,255},{"delay",8/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      if direction>3 then
        temp:setPositionX(-temp:getPositionX())
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
      end
      temp=views.A_00000_3_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"fadeTo",5/60,255},{"delay",8/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
      if direction>3 then
        temp:setPositionX(-temp:getPositionX())
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
      end
   end
   delayNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_20}}))

end

return {M,V,C}
