local M = class(AvtInfo)

local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        SwatEffect.new({attacker = self, mode = mode, target = attackTarget,total=self.C.actSkillParams.y},callback)
    else
      local mode = self.C.rd:randomInt(3)
      local shot = AttackeffectShot.new(nil, 120,0,0,0,attackTarget,1,mode,0,1.25,callback)
      shot.attacker = self
      shot:addToScene(self.scene)
    end  
end


local C = class(AvtControler)

--1001 巨警神盾 持续[y]秒内，自身增加减伤率[c]%，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local y,c = params.y,params.c
    BuffUtil.setBuff(self,{lastedTime = y, bfDefPct = c})
end

SwatEffect=class()

function SwatEffect:ctor(params,callback)
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

function SwatEffect:initParams(params)
    self.effectManager=GameEffect.new("SwatEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode=self.attacker.scene.delayNode
    self.total=params.total

    --起始点坐标
    local x,y = 0,self.attacker.animaConfig.Ymove
    local p = {self.attacker.view:getPosition()}
    p[1] = p[1] + x
    p[2] = p[2] + y
    self.initPos = {p[1],p[2],General.sceneHeight-p[2]}
end

function SwatEffect:initEffect()
  if self.mode==0 then
    --无特效
  elseif self.mode==1 then
     self:initSkill()
  end
end
function SwatEffect:initSkill()
   local effectManager=self.effectManager
   local bg=self.attacker.view
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={0,0,10}
   
   self.time=10/60
   local temp
   local total=self.total
   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2]+60)
   bg:addChild(upNode,initPos[3]+10)
   upNode:runAction(ui.action.sequence({{"delay",30/60+total},"remove"}))

   local function delayFrameIndex_30()
     effectManager:addEffect("views1_delay30",upNode)
      temp=views.Shield_00000_7
      temp:runAction(ui.action.sequence({{"fadeTo",2/60,198},{"delay",18/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_30}}))

    local function delayFrameIndex_50()
     effectManager:addEffect("views1_delay50",upNode)
      temp=views.Shield_00003_1
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",15/60,198},{"fadeTo",15/60,127}})))
   end
   upNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_50}}))
end

function SwatEffect:update(diff)
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
