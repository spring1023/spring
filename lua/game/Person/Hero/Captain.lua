local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        local params = self.C.actSkillParams
        CaptainEffect.new({attacker = self, mode = mode, target = attackTarget,total=params.y},callback)
    else
        local mode = self.C.rd:randomInt(3)
        local shot = AttackeffectShot.new(nil, 120,0,0,0,attackTarget,1,mode,0,1.25,callback)
        shot.attacker = self
        shot:addToScene(self.scene)
    end


end


local C = class(AvtControler)

--3002 美国队长  持续[y]秒内，自身增加减伤率[c]%，其他己方英雄增加减伤率[d]%，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local y,c,d = params.y,params.c,params.d
    BuffUtil.setBuff(self,{lastedTime = y, bfDefPct = c})
    for i,v in ipairs(self.battleMap2.hero) do
        if v ~= self then
            BuffUtil.setBuff(v,{lastedTime = y, bfDefPct = d})
        end
    end
end

CaptainEffect=class()

function CaptainEffect:ctor(params,callback)
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

function CaptainEffect:initParams(params)
    self.effectManager=GameEffect.new("CaptainEffect.json")
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

function CaptainEffect:initEffect()
  if self.mode==0 then

  elseif self.mode==1 then
     self:initSkill()
     self:initSkill_total()
  end
end

function CaptainEffect:initSkill()
    self.time = 0
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

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   upNode:setScale(2)
   bg:addChild(upNode,initPos[3]+10)

   upNode:runAction(ui.action.sequence({{"delay",64/60},"remove"}))
   local function delayFrameIndex_14()
     effectManager:addEffect("views1_delay14",upNode)
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   delayFrameIndex_14()

   local function delayFrameIndex_34()
     effectManager:addEffect("views1_delay34",upNode)
      temp=views.Shield_00000_6
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",20/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_34}}))

end

function CaptainEffect:initSkill_total()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local delayNode=bg
   local views=self.views
   local direction=self.direction
   local initPos={0,0,0}
   local total=self.total
   local temp

    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   upNode:setScale(2)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",total+60/60},"remove"}))
   local function delayFrameIndex_54()
     effectManager:addEffect("views2_delay54",upNode)
      temp=views.Particle_2
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",40/60},{"call",delayFrameIndex_54}}))

   local function delayFrameIndex_59()
     effectManager:addEffect("views2_delay59",upNode)
      temp=views.Glow_02_15
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",40/60,102},{"fadeTo",40/60,153}})))
      temp:runAction(ui.action.sequence({{"delay",total-5/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",45/60},{"call",delayFrameIndex_59}}))

end

function CaptainEffect:update(diff)
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
