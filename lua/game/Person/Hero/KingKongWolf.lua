
local AnimaConfigData = GMethod.loadScript('data.AnimaConfigData')
local AllConfig = GMethod.loadScript('data.AllConfig')
local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
        -- callback()
    end
    local attackMode=1
    if self.skillLastTimeAll then
        attackMode=2
        KingKongWolfEffect.new({attacker = self, mode = mode, target = attackTarget,attackMode=attackMode}, callback)
    else
        local mode = self.C.rd:randomInt(3)
        local shot = AttackeffectShot.new(nil, 120,0,0,0,attackTarget,1,mode,0,1.25,callback)
        shot.attacker = self
        shot:addToScene(self.scene)
    end


end
--技能执行特效
function V:sg_skillAttack(attackTarget,viewInfo1,viewInfo2,b)
    self.skillStopNum = 6
    self.exeAtkFrame = 1
    self:attack(viewInfo1,viewInfo2,b)
    self.allActionTime = self.allActionTime+self.oneFrameTime*(self.skillStopNum-1)
    local id=self.id
    local off=AllConfig.heroCurrencyEffect
    local mode,oy,scal=off[id][1],off[id][2],off[id][3]
    self:currencyEffect(mode,oy,scal)
    self.state = PersonState.SKILL
end

--技能持续状态
function V:skillState(skillLastTimeAll)
    self.skillLastTimeAll = skillLastTimeAll
    self.skillLastTime = 0
    self.animaConfig = AnimaConfigData[30015]
    self.imgType = 5
    self.plistFile = string.format(self.animaConfig.plistFile, self.imgType)
    memory.loadSpriteSheet(self.plistFile)
end

function V:skillAfter()

    self.skillLastTimeAll = nil
    self.skillLastTime = nil
    self.animaConfig = AnimaConfigData[3001]
    self.imgType = 1
    self.plistFile = string.format(self.animaConfig.plistFile, self.imgType)
    memory.loadSpriteSheet(self.plistFile)
    self:resetFree()
end

local C = class(AvtControler)

--3001 金刚狼 持续[y]秒内，总共回复自身[c]%*攻击力的血量，并且增加自身和己方所有岩石人[a]的攻击力，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local y,c,a = params.y,params.c,params.a
    BuffUtil.setBuff(self,{lastedTime = y, bfAtkAdd = a, lastAddHp = self.M.atk*c/100})
    for i,v in ipairs(self.battleMap2.mer) do
        if v.sid == 700 then
            BuffUtil.setBuff(v,{lastedTime = y, bfAtkAdd = a,})
        end
    end
    self.V:skillState(y)
end


KingKongWolfEffect=class()

function KingKongWolfEffect:ctor(params,callback)
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

function KingKongWolfEffect:initParams(params)
    self.effectManager=GameEffect.new("KingKongWolfEffect.json")
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

function KingKongWolfEffect:initEffect()
  if self.mode==0 then
     self:initSkill()
  elseif self.mode==1 then
     self:initSkill()
  end
end

function KingKongWolfEffect:initSkill()
  local setting={{15,30,45},{-20,65,-60},{-25,50,-120},{25,50,120},{20,65,60},{-15,30,-45}}
  local setting2={{-20,35,-15},{-10,5,-65},{10,30,-125},{-10,30,125},{10,5,65},{20,35,15}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local delayNode=self.delayNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]

  local initPos2={}
   initPos2[1]=self.initPos[1]+setting2[direction][1]
   initPos2[2]=self.initPos[2]+setting2[direction][2]
   initPos2[3]=self.initPos[3]

  self.time=10/60
   local r=setting[direction][3]
   local r2=setting2[direction][3]
   local temp

    local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10000)
   upNode:setRotation(r)
   upNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

   local upNode2=ui.node()
   upNode2:setPosition(initPos2[1],initPos2[2])
   bg:addChild(upNode2,initPos2[3]+10000)
   upNode2:setRotation(r2)
   upNode2:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

   local function delayFrameIndex_48()
     effectManager:addEffect("views1_delay48",upNode)
      temp=views.Sprite_4
      if direction>3 then
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
      end

      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
   end
   delayFrameIndex_48()

   local function delayFrameIndex_56()
     effectManager:addEffect("views1_delay56",upNode)
      temp=views.Sprite_7
      if direction>3 then
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
        temp:setPositionX(-temp:getPositionX())
      end

      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",2/60,0.75,0.5},{"scaleTo",1/60,0.5,0.5},{"scaleTo",4/60,0.05,0.05}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",3/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",8/60},{"call",delayFrameIndex_56}}))

   local function delayFrameIndex_68()
     effectManager:addEffect("views1_delay68",upNode2)
      temp=views.Sprite_4_0
      if direction>3 then
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
      end

      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_68}}))

   local function delayFrameIndex_76()
     effectManager:addEffect("views1_delay76",upNode2)
      temp=views.Sprite_7_0
      if direction>3 then
        temp:setFlippedX(true)
        temp:setRotation(-temp:getRotation())
        temp:setPositionX(-temp:getPositionX())
      end

      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",2/60,0.75,0.5},{"scaleTo",1/60,0.5,0.5},{"scaleTo",4/60,0.05,0.05}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",3/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",8/60},"remove"}))
   end
   upNode2:runAction(ui.action.sequence({{"delay",23/60},{"call",delayFrameIndex_76}}))

end

function KingKongWolfEffect:update(diff)
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
