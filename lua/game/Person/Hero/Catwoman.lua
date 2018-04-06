local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        CatwomanEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
    else
        local mode = self.C.rd:randomInt(3)
        local shot = AttackeffectShot.new(nil, 120,0,0,0,attackTarget,1,mode,0,1.25,callback)
        shot.attacker = self
        shot:addToScene(self.scene)
    end
end


local C = class(AvtControler)

--2005 猫女 持续[y]秒内，提升自身[c]%攻速，[d]%移速，[e]%攻击力，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local c,d,e,y = params.c,params.d,params.e,params.y
    local viewChange = {sc=1.5, actRp={{"tintto",0.5,{216,0,255}},{"tintto",0.5,{0,0,0}}}, amode=0.75}
    BuffUtil.setBuff(self,{lastedTime = y, bfAtkSpeedPct = c, bfMovePct = d, bfAtkPct = e, viewChange=viewChange})
end

CatwomanEffect=class()

function CatwomanEffect:ctor(params,callback)
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

function CatwomanEffect:initParams(params)
    self.effectManager=GameEffect.new("CatwomanEffect.json")
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
end

function CatwomanEffect:initEffect()
  if self.mode==0 then

  elseif self.mode==1 then
     self:initSkill()
  end
end

function CatwomanEffect:initSkill()
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
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(1.5)
   upNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3]-10)
   downNode:setScale(1.5)
   downNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

   local function delayFrameIndex_34()
     effectManager:addEffect("views1_delay34",downNode)
      temp=views.Ground_00001_5
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
      temp=views.UP_Line_C_00001_2
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      
    effectManager:addEffect("views1_delay34_up",upNode)
      temp=views.UP_Line_S_00001_1
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_34}}))

   local function delayFrameIndex_44()
     effectManager:addEffect("views1_delay44",downNode)
      temp=views.Glow_02_3
      temp:runAction(ui.action.sequence({{"fadeTo",3/60,224},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_44}}))

   local function delayFrameIndex_46()
     effectManager:addEffect("views1_delay46",upNode)
      temp=views.Particle_1
      temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",12/60},{"call",delayFrameIndex_46}}))

end

function CatwomanEffect:update(diff)
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
