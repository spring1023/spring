local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        BatmanEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
    else
        local mode = self.C.rd:randomInt(3)
        local shot = AttackeffectShot.new(nil, 120,0,0,0,attackTarget,1,mode,0,1.25,callback)
        shot.attacker = self
        shot:addToScene(self.scene)
    end
end


local C = class(AvtControler)

--3006 蝙蝠侠  持续y秒内，提升自身和己方所有掠夺机器人减伤率c%，攻击力a，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local c,a,y = params.c,params.a,params.y
    BuffUtil.setBuff(self,{lastedTime = y, bfDefPct = c, bfAtkAdd = a})
    for i,v in ipairs(self.battleMap2.mer) do
        if v.sid == 600 then
            BuffUtil.setBuff(v, {lastedTime = y, bfDefPct = c, bfAtkAdd = a})
        end
    end
end

BatmanEffect=class()

function BatmanEffect:ctor(params,callback)
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
function BatmanEffect:update(diff)
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
function BatmanEffect:initParams(params)
    self.effectManager=GameEffect.new("BatmanEffect.json")
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

function BatmanEffect:initEffect()
  if self.mode==0 then
     
  elseif self.mode==1 then
     self:initSkill()
  end
end

function BatmanEffect:initSkill()
   self.time = 0
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local initPos={0,0,0}
   local temp

    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.3)
   upNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(1.3)
   downNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

  local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",downNode)
      temp=views.Ground_00001_5
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
   end
   delayFrameIndex_0()

   local function delayFrameIndex_14()
     effectManager:addEffect("views1_delay14",upNode)
      temp=views.Glow_02_3
      temp:runAction(ui.action.sequence({{"fadeTo",11/60,219},{"delay",30/60},{"fadeTo",16/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",57/60},"remove"}))
      temp=views.Sphere_00000_10
      temp:runAction(ui.action.sequence({{"fadeTo",16/60,255},{"delay",15/60},{"fadeTo",26/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",57/60},"remove"}))
      temp=views.Sphere_00000_10_0
      temp:runAction(ui.action.sequence({{"fadeTo",16/60,128},{"fadeTo",15/60,127},{"fadeTo",20/60,20},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",57/60},"remove"}))

     effectManager:addEffect("views1_delay14_down",downNode)
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",47/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",14/60},{"call",delayFrameIndex_14}}))

   local function delayFrameIndex_34()
     effectManager:addEffect("views1_delay34",downNode)
      temp=views.Glow_02_6
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,224},{"fadeTo",13/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",14/60},{"call",delayFrameIndex_34}}))

end


return {M,V,C}
