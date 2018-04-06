--磁暴塔 25

local Storm = {}

function Storm:attack(target)
    self.coldTime = self.coldTime+self.avtInfo.aspeed

    local vstate = self.vstate
    local attackValue = BattleUtil.getHurt(self, target)
    if GEngine.rawConfig.DEBUG_NOBEFFECT then
        shotDamage({attacker = self},target,attackValue)
    else
        local imaLevel=self.vconfig.imaLevel
        local setting={{0,80,0.2},{0,88,0.4},{0,90,0.35},{0,92,0.35},{0,105,0.5},{0,105,0.5}}
        local ox,oy,r=setting[imaLevel][1],setting[imaLevel][2],setting[imaLevel][3]

        local p = self:getAttackPosition(ox,oy,r, self.vstate.rotateInfo.dir)
        local tgx, tgy = target.avater.gx, target.avater.gy
        local tpx, tpy = vstate.scene.map.convertToPosition(tgx, tgy)
        local shot = StormShot.new(attackValue, 120, p[1], p[2], tpx, tpy, self.avtInfo.drange, GroupTypes.Defense, 3)
        
        if target.avtInfo.utype == 2 then
            shot.oy = target.avater.animaConfig.Ymove
        else
            shot.oy = 0
        end
        shot.imaLevel=imaLevel
        shot.build=self
        
        if not shot then
            return
        end

        shot.attacker = self
        shot:addToScene(vstate.scene)
    end
end

function Storm:dieEvent()
  local buff = self.allBuff.MagnetoGodSkill2
  if buff then
    local ps = buff.ps
    local px,py = self:getDamagePoint()
    Magneto03.new(self.vstate.scene.objs,px,py)
    for i,v in ipairs(self.battleMap.battlerAll) do
      SkillPlugin.exe2(self,v,0,ps.z)
      BuffUtil.setBuff(v,{lastedTime=ps.t, lastAddHp=-ps.a})
    end
  end
end


StormShot=class(AreaSplash)

function StormShot:update(diff)
    local stateTime = self.stateTime + diff
    local state = self.state
    if stateTime >= self.time[state] then
        self.state = state+1
        self:executeDamage()
        self:resetView()
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
    self.stateTime = stateTime
end

function StormShot:initView()
    local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {distance*10/self.speed}
    self.juliTime=0.3
    self.state = 1

    self.effectManager=GameEffect.new("Build_cibaota.json")
    self.views=self.effectManager.views
    self.viewsNode=self.scene.effects

    self.initPos[3] = 2
    self.targetPos[3] = 2
    self:resetView()
    self:initEffect()
end

function StormShot:resetView()
    if self.state==1 then
        self.scene.replay:addUpdateObj(self)
    end
end

function StormShot:initEffect()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local imaLevel= self.imaLevel
   local direction=self.direction
   local initPos=self.initPos
   local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]+self.oy
   local moveTime= self.time[1]
   local juliTime=self.juliTime
   local r=-math.deg(math.atan2(moveY,moveX))
   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3])
   moveNode:setRotation(r)
   self:createViews_1()
   local function showMove( )
      if imaLevel<=2 then
          self:createViews_7(moveTime,moveX,moveY,moveNode)
      elseif imaLevel<=3 then
          self:createViews_8(moveTime,moveX,moveY,moveNode)
      elseif imaLevel<=6 then
          self:createViews_9(moveTime,moveX,moveY,moveNode)
      end
   end

   local delayNode=ui.node()
    delayNode:setPosition(initPos[1],initPos[2])
    bg:addChild(delayNode)
    delayNode:runAction(ui.action.sequence({{"delay",juliTime},{"call",showMove},"remove"}))
end
function StormShot:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local temp
   local juliTime=self.juliTime
   local direction=self.direction
   local imaLevel=self.imaLevel
     effectManager:addEffect("views1_delay0_"..imaLevel,bg)

      temp=views.Particle_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"delay",juliTime},"remove"}))
      temp=views.Particle_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"delay",juliTime},"remove"}))
      temp=views.Particle_4
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",juliTime},"remove"}))
end

function StormShot:createViews_7(moveTime,moveX,moveY,moveNode)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local temp
  local function showTargetBao( )
      self:createViews_10()
   end
   moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views7_delay0",moveNode)
      temp=views.Particle_3_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)

      temp=views.Particle_3_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)

      temp=views.Particle_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)

      temp=views.Particle_5
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)

end

function StormShot:createViews_8(moveTime,moveX,moveY,moveNode)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local temp
   local function showTargetBao( )
      self:createViews_11()
   end
   moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views8_delay0",moveNode)
      temp=views.Particle_13_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)

      temp=views.Particle_13_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)

      temp=views.Particle_13_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)

      temp=views.Particle_13
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)

end

function StormShot:createViews_9(moveTime,moveX,moveY,moveNode)
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local temp
   local function showTargetBao( )
      self:createViews_12()
   end
   moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

     effectManager:addEffect("views9_delay0",moveNode)
      temp=views.Particle_9_0_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)

      temp=views.Particle_9_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)

      temp=views.Particle_9_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)

      temp=views.Particle_9
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
end

function StormShot:createViews_10()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views10_delay0",bg)
      temp=views.Particle_20
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_19
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_18
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setAutoRemoveOnFinish(true)
end

function StormShot:createViews_11()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views11_delay0",bg)
      temp=views.Particle_27
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_26
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_25
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setAutoRemoveOnFinish(true)
end

function StormShot:createViews_12()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views12_delay0",bg)
      temp=views.Particle_24
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_23
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_22
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setAutoRemoveOnFinish(true)
end

--防御天神技特效
Magneto03=class()
function Magneto03:ctor(bg,x,y)
    self.effectManager=GameEffect.new("Magneto03.json")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,10000}
    self.targetPos={x+400,y-400,0}
    self:initEffect()
end
function Magneto03:initEffect()
    self:createViews_1()
end
function Magneto03:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos={}
   initPos[1]=self.initPos[1]
   initPos[2]=self.initPos[2]
   initPos[3]=self.initPos[3]

   local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(0.7)
   upNode:runAction(ui.action.sequence({{"delay",40/60},"remove"}))

  effectManager:addEffect("views1_delay0",upNode)

      temp=views.Glow_01_2_0_0
      temp:runAction(ui.action.sequence({{"scaleTo",8/60,3.0,3.0},{"scaleTo",20/60,4.0,4.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",4/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Glow_01_2_0
      temp:runAction(ui.action.sequence({{"scaleTo",8/60,2.0,2.0},{"scaleTo",20/60,3.0,3.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",4/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Glow_01_2
      temp:runAction(ui.action.sequence({{"scaleTo",8/60,2.3,2.3},{"scaleTo",20/60,3.5,3.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",4/60},{"fadeTo",18/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.guanghuad_6
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,1.3,1.04},{"scaleTo",15/60,2.0,1.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,127},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.guanghuad_6_0
      temp:runAction(ui.action.sequence({{"scaleTo",6/60,1.3,1.04},{"scaleTo",15/60,2.0,1.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Spark_00000_8
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Spark_00000_8_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",8/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Sprite_10
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",1/60,0},{"delay",5/60},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,127},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Sprite_10_0
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",1/60,0},{"delay",5/60},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",3/60,0},{"delay",2/60},{"fadeTo",1/60,255},{"fadeTo",2/60,0},{"delay",2/60},{"fadeTo",1/60,127},{"fadeTo",3/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Glow_01_12
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,2.5,2.5},{"scaleTo",23/60,3.5,3.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",23/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.Glow_01_12_0
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,2.5,2.5},{"scaleTo",23/60,5.0,5.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"fadeTo",23/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",28/60},"remove"}))
      temp=views.CD_00_1
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",11/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))

end



return Storm