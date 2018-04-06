
local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    ButcherZbEffect.new({attacker = self, mode = mode, target = attackTarget,total=self.C.actSkillParams.y},callback)
end


local C = class(AvtControler)

--9004    屠夫    在[y]秒内，持续对周围5格半径内的敌人造成每秒[a]+[c]%的伤害，自身减伤[d]%。冷却[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local y,a,c,d = params.y,params.a,params.c,params.d
    BuffUtil.setBuff(self,{lastedTime = y,bfDefPct = d})
    self.skillLastTime = 0
    self.allDtime = 0
end

function C:sg_updateBattle(diff)
    if self.deleted then
      return
    end
    if self.skillLastTime then
        local params = self.actSkillParams
        local y,a,c,d = params.y,params.a,params.c,params.d
        self.skillLastTime = self.skillLastTime+diff
        if self.skillLastTime>y then
            self.skillLastTime = nil
            return
        end
        self.allDtime = self.allDtime+diff
        if self.allDtime>=1 then
            self.allDtime = self.allDtime-1
            local result = self:getCircleTarget(self,self.battleMap.battlerAll,5)
            for i,v in ipairs(result) do
                SkillPlugin.exe2(self,v,a,c)
            end
        end
    end
end

ButcherZbEffect=class()

function ButcherZbEffect:ctor(params,callback)
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
function ButcherZbEffect:update(diff)
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
function ButcherZbEffect:initParams(params)
    self.effectManager=GameEffect.new("ButcherZbEffect.json")
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

function ButcherZbEffect:initEffect()
  if self.mode==0 then
     self:attack()
  elseif self.mode==1 then
    self:createViews_1()
    self:createViews_2()
    self:createViews_3()
  end
end

--下层的
function ButcherZbEffect:createViews_1()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local initPos={0,0,0}

   local total=self.total
   local temp
   self.time=0.5
    local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2]+40)
   bg:addChild(downNode,initPos[3]-10)
   downNode:runAction(ui.action.sequence({{"delay",total+43/60},"remove"}))

   local function delayFrameIndex_40()
     effectManager:addEffect("views1_delay40",downNode)
      temp=views.Ground_Wave_00000_6
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,12.5,10.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,127},{"delay",total-25/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_40}}))

   local function delayFrameIndex_42()
     effectManager:addEffect("views1_delay42",downNode)
      temp=views.Particle_3
      temp:runAction(ui.action.sequence({{"scaleTo",1/60,4.0,4.0},{"scaleTo",6/60,4.0,4.0}}))
      temp:runAction(ui.action.sequence({{"delay",total-12/60},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",2/60},{"call",delayFrameIndex_42}}))

   local function delayFrameIndex_43()
     effectManager:addEffect("views1_delay43",downNode)
      temp=views.Shockwave_00000_3
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,10,8}}))
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,51},{"fadeTo",39/60,127},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",52/60},"remove"}))
      temp=views.Shockwave_00000_3_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,10,8}}))
      temp:runAction(ui.action.sequence({{"delay",3/60},{"fadeTo",39/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",52/60},"remove"}))
      temp=views.mask_161_2
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",4/60,8.0,7.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,178},{"fadeTo",total-27/60,76},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-8/60},"remove"}))
      temp=views.Sprite_1
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",4/60,20,15}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,51},{"delay",total-27/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-8/60},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",3/60},{"call",delayFrameIndex_43}}))

end

function ButcherZbEffect:createViews_2()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local initPos={0,0,0}

   local total=self.total
   local temp

    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+40)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",total+45/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views2_delay0",upNode)
      temp=views.Particle_2_0
      temp=views.Sprite_5
      temp:runAction(ui.action.sequence({{"scaleTo",35/60,1.0,1.0},{"scaleTo",15/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"delay",34/60},{"fadeTo",1/60,127},{"delay",30/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",80/60},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_40()
     effectManager:addEffect("views2_delay40",upNode)
      temp=views.Shield_00000_9
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"delay",585/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total-10/60},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_40}}))

   local function delayFrameIndex_43()
     effectManager:addEffect("views2_delay43",upNode)
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"delay",total-23/60},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",3/60},{"call",delayFrameIndex_43}}))

   local function delayFrameIndex_45()
     effectManager:addEffect("views2_delay45",upNode)
      temp=views.Particle_2
      temp:runAction(ui.action.sequence({{"scaleTo",2/60,1.8,1.44},{"scaleTo",3/60,4.0,3.0}}))
      temp:runAction(ui.action.sequence({{"delay",total-15/60},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_45}}))

end

function ButcherZbEffect:createViews_3()
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
   upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_30()
     effectManager:addEffect("views3_delay30",upNode)
      temp=views.Splash_00000_7_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",19/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.Splash_00000_7
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",19/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_30}}))
end

function ButcherZbEffect:attack()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]
   local temp
   self.time=0.5
   local function delayFrameIndex_29()
      local upNode=ui.node()
      upNode:setPosition(initPos[1],initPos[2])
      bg:addChild(upNode,initPos[3]+10000)
      upNode:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
    local dir=direction
    if dir>3 then
      dir=7-dir
    end
     effectManager:addEffect("attack_views_delay29_"..dir,upNode)

      temp=views.Q_00000_3_0
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,255},{"delay",7/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
      if direction>3 then
        temp:setPositionX(-temp:getPositionX())
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
      end
      temp=views.Q_00000_3_1
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,127},{"delay",7/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
      if direction>3 then
        temp:setPositionX(-temp:getPositionX())
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
      end
   end
   delayNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_29}}))

end

return {M,V,C}
