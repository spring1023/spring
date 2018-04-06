--加农炮21
local Connon = {}

function Connon:attack(target)
    self.coldTime = self.coldTime+self.avtInfo.aspeed

    local vstate = self.vstate
    local attackValue = BattleUtil.getHurt(self, target)

    
    if GEngine.rawConfig.DEBUG_NOBEFFECT then
        shotDamage({attacker = self},target,attackValue)
    else
        local dir=vstate.rotateInfo.dir
        local mx=-10*math.cos(math.rad(-90-dir*20))
        local my=-10*math.sin(math.rad(-90-dir*20))
        vstate.bviews[2]:runAction(ui.action.sequence({{"moveBy",0.1,mx,my},{"moveBy",0.1,-mx,-my}}))
        vstate.bviews[2]:runAction(ui.action.sequence({{"scaleTo",0.1,0.95,1},{"scaleTo",0.1,1,1}}))
        
        local imaLevel=self.vconfig.imaLevel
        local setting={{0,35,0.6,0},{0,35,0.65,0},{0,25,0.7,0},{0,35,0.75,0},{0,35,0.85,0},{0,40,0.8,0},{0,40,0.85,0},{0,40,0.85,0},{0,35,0.9,0}}
        local ox,oy,r=setting[imaLevel][1],setting[imaLevel][2],setting[imaLevel][3]

        local p = self:getAttackPosition( ox, oy, r, self.vstate.rotateInfo.dir)
        local shot = CannonShot.new(attackValue, 120, p[1], p[2], p[3], target,imaLevel,dir)
        shot.build=self
        if not shot then
            return
        end
        shot.attacker = self
        shot:addToScene(vstate.scene)
    end
end

CannonShot = class(SingleShot)
function CannonShot:ctor(attack, speed, x, y, z, target,imaLevel,dir)
    self.imaLevel=imaLevel
    self.dir=dir
    self.callback = nil
end
function CannonShot:update(diff)
    local stateTime = self.stateTime + diff
    local state = self.state
    if stateTime >= self.time[state] then
        self.state = state+1
        shotDamage(self, self.target, self.attackValue)
        self:resetView()
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
    self.stateTime = stateTime
end

function CannonShot:initView()
    local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {distance*10/self.speed}
    self.state = 1

    self.effectManager=GameEffect.new("Build_jianongpao.json")
    self.views=self.effectManager.views
    self.viewsNode=self.scene.objs
    self.initPos[3]=self.initZorder+10000
    self.targetPos[3]=self.targetZ

    self:resetView()
    self:initEffect()
end

function CannonShot:resetView()
    if self.state==1 then
        if self.target.deleted then
            return
        end
        self.scene.replay:addUpdateObj(self)
    else
        local p = ui.particle("particles/battleEffectNormal.json")
        p:setPosition(self.targetPos[1],self.targetPos[2])
        p:setPositionType(cc.POSITION_TYPE_GROUPED)
        self.scene.objs:addChild(p,self.targetPos[3])
    end
end

function CannonShot:initEffect()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local imaLevel= self.imaLevel
   local initPos=self.initPos
   local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local moveTime=self.time[1]
   local r=-math.deg(math.atan2(moveY,moveX))
   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3])
   moveNode:setRotation(r)
   self:createViews_1()
   if imaLevel==1 then
      self:createViews_9(moveNode)
   elseif imaLevel==2 then
      self:createViews_10(moveNode)
   elseif imaLevel==3 then
       self:createViews_11(moveNode)
   elseif imaLevel==4 then
     self:createViews_12(moveNode)
   elseif imaLevel==5 then
      self:createViews_13(moveNode)
   elseif imaLevel==6 then
      self:createViews_13(moveNode)
   elseif imaLevel==7 then
      self:createViews_14(moveNode)
   elseif imaLevel==8 then
      self:createViews_14(moveNode)
   elseif imaLevel==9 then
      self:createViews_14(moveNode)
   end
   moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},"remove"}))
end

function CannonShot:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local temp
   local imaLevel=self.imaLevel
   local dir=self.dir
   --一个等级增加0.07大小
     effectManager:addEffect("views1_delay0",bg)
      temp=views.Particle_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setAutoRemoveOnFinish(true)
      temp:setScale(0.6+(imaLevel-1)*0.07)
      temp=views.Particle_2
      temp:setRotation(20*dir)
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setAutoRemoveOnFinish(true)
       temp:setScale(0.3+(imaLevel-1)*0.07)
      temp=views.Particle_3
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setAutoRemoveOnFinish(true)
       temp:setScale(0.2+(imaLevel-1)*0.07)
end

--子弹
function CannonShot:createViews_9(moveNode)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={0,0,0}
   local temp

     effectManager:addEffect("views9_delay0",moveNode)
      temp=views.jia1_4
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp=views.tuowei1_00000_6_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
      temp=views.tuowei1_00000_6_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
      temp=views.tuowei1_00000_6
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
end

function CannonShot:createViews_10(moveNode)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={0,0,0}
   local targetPos=self.targetPos
   local temp

     effectManager:addEffect("views10_delay0",moveNode)
      temp=views.jia1_3
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp=views.tuowei1_00000_5_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
      temp=views.tuowei1_00000_5_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
      temp=views.tuowei1_00000_5
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
end

function CannonShot:createViews_11(moveNode)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={0,0,0}
   local temp

     effectManager:addEffect("views11_delay0",moveNode)
      temp=views.jia1_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp=views.tuowei1_00000_4_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
      temp=views.tuowei1_00000_4_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
      temp=views.tuowei1_00000_4
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
end

function CannonShot:createViews_12(moveNode)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={0,0,0}
   local temp
     effectManager:addEffect("views12_delay0",moveNode)
      temp=views.jia1_5
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp=views.tuowei1_00000_3_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
      temp=views.tuowei1_00000_3_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
      temp=views.tuowei1_00000_3
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.4}}))
end

function CannonShot:createViews_13(moveNode)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={0,0,0}
   local temp

     effectManager:addEffect("views13_delay0",moveNode)
      temp=views.Particle_12
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp=views.jia1_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp=views.tuowei1_00000_3_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.7}}))
      temp=views.tuowei1_00000_3_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1.2,1.7}}))
end

function CannonShot:createViews_14(moveNode)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={0,0,0}
   local temp
     effectManager:addEffect("views14_delay0",moveNode)
      temp=views.Sprite_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp=views.jia6_6
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp=views.Particle_10
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp=views.Particle_10_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
end

return Connon