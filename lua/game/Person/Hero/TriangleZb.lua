
local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    TriangleZbEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--9005   三角头    对周围5格半径内的敌人造成一次[a]+[c]%的伤害。冷却[z]秒。
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local a,c = params.a,params.c
    local result = self:getCircleTarget(self,self.battleMap.battlerAll,5)
    for i,v in ipairs(result) do
        SkillPlugin.exe2(self,v,a,c)
    end
end

TriangleZbEffect=class()

function TriangleZbEffect:ctor(params,callback)
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
function TriangleZbEffect:update(diff)
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
function TriangleZbEffect:initParams(params)
    self.effectManager=GameEffect.new("TriangleZbEffect.json")
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

function TriangleZbEffect:initEffect()
  if self.mode==0 then
    self:attack()
  elseif self.mode==1 then
    self:createViews_1()
    self:createViews_2()
  end
end

function TriangleZbEffect:createViews_1()
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
   self.time=20/60
    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",70/60},"remove"}))
  local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:runAction(ui.action.sequence({{"delay",70/60},"remove"}))

   local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",downNode)
      temp=views.Sprite_4
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
     effectManager:addEffect("views1_delay0_up",upNode)
      temp=views.Glow_02_1
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,255},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_13()
     effectManager:addEffect("views1_delay13",upNode)
      temp=views.Xuanzs_00001_6
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",16/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",37/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",3/60},{"call",delayFrameIndex_13}}))

end

function TriangleZbEffect:createViews_2()
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
   upNode:runAction(ui.action.sequence({{"delay",70/60},"remove"}))

   local function delayFrameIndex_29()
     effectManager:addEffect("views2_delay29",upNode)
      temp=views.Glow_02_7
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.8,0.8},{"scaleTo",8/60,1.0,1.0},{"scaleTo",13/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",22/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.RTD0_00_5
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",28/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",33/60},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_29}}))

   local function delayFrameIndex_32()
     effectManager:addEffect("views2_delay32",upNode)
      temp=views.Sprite_3
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",25/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))
   end
   delayNode:runAction(ui.action.sequence({{"delay",22/60},{"call",delayFrameIndex_32}}))

end

function TriangleZbEffect:attack()
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
   self.time=15/60
   local function delayFrameIndex_24()
      local upNode=ui.node()
      upNode:setPosition(initPos[1],initPos[2])
      bg:addChild(upNode,initPos[3]+10000)
      upNode:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
    local dir=direction
    if dir>3 then
      dir=7-dir
    end
     effectManager:addEffect("attack_views_delay24_"..dir,upNode)

      temp=views.A_00000_3
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",10/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      if direction>3 then
        temp:setPositionX(-temp:getPositionX())
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
      end
      temp=views.A_00000_3_0
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",10/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      if direction>3 then
        temp:setPositionX(-temp:getPositionX())
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
      end
   end
   delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_24}}))

end

return {M,V,C}
