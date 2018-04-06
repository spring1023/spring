local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    SniperEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--1002 特种狙击 对目标造成[a]+[c]%*攻击力的伤害，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    if not target or target.deleted then
        return
    end
    local params = self.actSkillParams
    local a,c = params.a,params.c
    SkillPlugin.exe2(self,self.attackTarget,a,c)
end

SniperEffect=class()

function SniperEffect:ctor(params,callback)
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

function SniperEffect:initParams(params)
    self.effectManager=GameEffect.new("SniperEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.attacker.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
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

function SniperEffect:initEffect()
  if self.mode==0 then
     self:initSkill()
     self:initSkill_move()
  elseif self.mode==1 then
     self:initSkill(true)
     self:initSkill_move(true)
  end
end

--攻击
function SniperEffect:initSkill(isSkill)
  local setting={{49,-31,45},{119,39,0},{72,119,-45},{-72,119,-135},{-119,39,-180},{-49,-31,135}}
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
   upNode:runAction(ui.action.sequence({{"delay",42/60},"remove"}))
   if isSkill then
    upNode:setScale(2)
   else
    upNode:setScale(1.5)
  end

   local function delayFrameIndex_34()
     effectManager:addEffect("views1_delay34",upNode)
      temp=views.Glow_02_11
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",7/60},"remove"}))
      temp=views.Sprite_10
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",6/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_34}}))

end
--子弹
function SniperEffect:initSkill_move(isSkill)
  local setting={{83,-70},{189,40},{113,174},{-113,174},{-189,40},{-83,-70}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]+10000

   local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
   self.time=moveTime+4/60
   local r=-math.deg(math.atan2(moveY,moveX))

   local temp

   local function delayFrameIndex_35()
       local moveNode=ui.node()
       moveNode:setPosition(initPos[1],initPos[2])
       bg:addChild(moveNode,initPos[3]+10)
       moveNode:setRotation(r)
      if isSkill then
        moveNode:setScale(4)
      else
        moveNode:setScale(3)
      end
       local function showTargetBao( )
        if isSkill then
         self:initSkill_target()
        else
          self:initSkill_target2()
        end
       end
       moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
     effectManager:addEffect("views2_delay35",moveNode)
      temp=views.Line_01
      temp:setVisible(false)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",1/60,1.0,1.0},{"scaleTo",1/60,1.0,0.6}})))
      temp=views.Line_01_0
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",1/60,0.6,0.6},{"scaleTo",1/60,0.6,0.36}})))
      temp=views.Line_01_0_0
      temp:setVisible(false)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",1/60,0.3,0.3},{"scaleTo",1/60,0.3,0.18}})))
      temp=views.Glow_02_11_0_0
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",8/60,0.3,0.3}}))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",8/60,255},{"fadeTo",9/60,127}})))

   end
   delayFrameIndex_35()
end
--技能受击
function SniperEffect:initSkill_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos=self.targetPos
   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(2)
   upNode:runAction(ui.action.sequence({{"delay",10/60},"remove"}))


     effectManager:addEffect("views3_delay58",upNode)
      temp=views.kk0001_13
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",2/60},{"fadeTo",7/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
      temp=views.Glow_02_11_0
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",1/60,0.5,0.5},{"scaleTo",1/60,1.0,1.0},{"scaleTo",7/60,0.1,0.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"fadeTo",9/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
      temp=views.BaoZa_00_1
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))
end

function SniperEffect:initSkill_target2()
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
   upNode:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
     effectManager:addEffect("views4_delay58",upNode)
      temp=views.Sparkless_00000_4_0
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,100},{"delay",30/60},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
end

function SniperEffect:update(diff)
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

return {M,V,C}
