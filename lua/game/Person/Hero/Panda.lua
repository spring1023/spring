
local M = class(AvtInfo)













local V = {}



local C = class(AvtControler)
--4007 对自身g格半径范围内所有敌方单位造成[a]+[c]%*攻击力的伤害，消耗[x]怒，冷却时间[z]秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    local params = self.avtInfo.person.actSkillParams
    local a,c= params.a,params.c
    local g = params.g
    local allBuilds = self.battleMap.battlerAll
    local sgx, sgy = self.avater.gx,self.avater.gy

    local pointTab = {}
    for i,v in ipairs(allBuilds) do
        local viewInfo = v.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(v)
        table.insert(pointTab,{viewInfo[1],viewInfo[2],viewInfo[3],v})
    end
    local result = Aoe.circlePoint(pointTab,{sgx,sgy},g)
    for k,v in ipairs(result) do
        SkillPlugin.exe2(self,v[4],a,c)
    end
end



function V:viewEffect(attackTarget,callback,isSkill)
    local attackmode = 0
    if isSkill then
        attackmode = 1
    end
    local p = {self.view:getPosition()}
    local x,y = 0,self.animaConfig.Ymove
    p[3] = General.sceneHeight - p[2]
    p[1] = p[1] + x
    p[2] = p[2] + y
    local shot = PandaShot.new(100, 1250, p[1], p[2], p[3],attackTarget,1,self.direction,attackmode,callback)
    shot.attacker = self
    if isSkill then
      shot.targetPos = p
    end
    shot:addToScene(self.scene)
end

PandaShot = class(SingleShot)
function PandaShot:ctor(attack, speed, x, y, z, target,level,dir,attackmode,callback)
    self.callback = callback
    self.speed = speed
    self.attackmode = attackmode
    self.dir = dir
    self.target=target
    self.effectManager = GameEffect.new("PandaEffect.json")
    self.effectViews = self.effectManager.views
    self.scene = GMethod.loadScript("game.View.Scene")
    self.dnode = ui.node()
    self.scene.objs:addChild(self.dnode)
end

function PandaShot:update(diff)
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

function PandaShot:initView()
    self.time={5/60*5}
    self.state = 1
    self.view=true
    self.scene = GMethod.loadScript("game.View.Scene")
    if self.scene.replay then
        self.scene.replay:addUpdateObj(self)
    else
        RegActionUpdate(self, Handler(self.update, self, 0.025), 0.025)
    end
    if self.attackmode==0 then
      self:createAttackEffect()
    elseif self.attackmode==1 then
      self:createSkillEffect()
    end
end


function PandaShot:createSkillEffect()
   local setting={{5,-50},{61,-15},{52,23},{-52,23},{-61,-15},{-5,-50}}
   local effectManager=self.effectManager
   local bg=self.scene.objs
   local views=self.effectViews
   local initPos={self.initPos[1],self.initPos[2],self.initZorder}
   local direction=self.dir
   initPos[1]=initPos[1]+setting[direction][1]
   initPos[2]=initPos[2]+setting[direction][2]
   local temp

   self.dnode:runAction(ui.action.sequence({{"delay",57/60},"remove"}))

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(1.2)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

    local downNode=ui.node()
    downNode:setPosition(initPos[1],initPos[2])
    downNode:setScale(1.2)
    bg:addChild(downNode,initPos[3]-10)
    downNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

   local function delayFrameIndex_46()
     effectManager:addEffect("views1_delay46",upNode)
      temp=views.Boom_8
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",4/60,1.0,1.0},{"scaleTo",8/60,0.2,0.2}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,127},{"delay",12/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))

      temp=views.Boom_8_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",4/60,1.0,1.0},{"scaleTo",8/60,0.2,0.2}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,126},{"fadeTo",12/60,127},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))

      temp=views.Glow_01_10
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,191},{"delay",8/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",1/60},{"call",delayFrameIndex_46}}))

   local function delayFrameIndex_49()
     effectManager:addEffect("views1_delay49",downNode)
      temp=views.Crack_00000_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(-5)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",24/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))

      temp=views.Crack_00000_6_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(-4)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"delay",1/60},{"fadeTo",24/60,255},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",50/60},"remove"}))

      temp=views.Stone_00000_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(-2)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",28/60},{"fadeTo",17/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_49}}))

   local function delayFrameIndex_50()
     effectManager:addEffect("views1_delay50",downNode)
      temp=views.Glow_01_11
      temp:setPosition(0,0)
      temp:setLocalZOrder(-1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",5/60,255},{"delay",18/60},{"fadeTo",25/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",48/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_50}}))

   local function delayFrameIndex_54()
     effectManager:addEffect("views1_delay54",downNode)
      temp=views.Shockwave_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(-3)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.2,1.056},{"scaleTo",10/60,1.5,1.32}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      effectManager:addEffect("views1_delay54_up",upNode)
      temp=views.Particle_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"delay",44/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_54}}))
   self.callback()
end


function PandaShot:createAttackEffect()
   local setting={{-15,18,-205},{36,71,-255},{37,110,-320},{-37,110,320},{-36,71,255},{15,18,205}}
   local effectManager=self.effectManager
   local bg=self.scene.objs
   local views=self.effectViews
   local initPos={self.initPos[1],self.initPos[2],self.initZorder+10000}
   local direction=self.dir
   local ox,oy,r=setting[direction][1],setting[direction][2],setting[direction][3]
   local temp

   self.dnode:runAction(ui.action.sequence({{"delay",18/60},"remove"}))

   local function delayFrameIndex_15()
     effectManager:addEffect("views2_delay15",bg)
      temp=views.Weapontrail_00000_35_0
      temp:setPosition(initPos[1]+ox,initPos[2]+oy)
      temp:setLocalZOrder(initPos[3]+1)
      temp:setRotation(r)
      if direction>3 then
        temp:setFlippedX(true)
      end
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",2/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_15}}))

end

return {M,V,C}
