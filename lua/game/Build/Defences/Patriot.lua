--爱国者 24
local Patriot = {}

function Patriot:attack(target)
    self.coldTime = self.coldTime+self.avtInfo.aspeed
    local shot
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
        local setting={{0,76,0.4,0},{0,70,0.45,0},{0,70,0.45,0},{0,80,0.5,0},{0,80,0.6,0},{0,85,0.6,0},{0,85,0.6,0},{0,85,0.6,0},{0,85,0.6,0},{0,80,0.6,0},{0,80,0.6,0},{0,80,0.6,0},{0,80,0.6,0}}
        local ox,oy,r=setting[imaLevel][1],setting[imaLevel][2],setting[imaLevel][3]
        
        local p = self:getAttackPosition( ox, oy, r, self.vstate.rotateInfo.dir)
        self.count=((self.count or 0)+1)%2
        shot = AirShot.new(attackValue, 130, p[1], p[2], p[3], target, 0, imaLevel,self.count)

        if not shot then
            return
        end

        shot.attacker = self
        shot:addToScene(vstate.scene)

        --Athena防御觉醒
        local buff = self.allBuff.AthenaGodSkill2
        if buff then
          if not self.countAtkNum then
            self.countAtkNum = 0
          end
          self.countAtkNum = self.countAtkNum+1
          if self.countAtkNum>=buff.d then
            self.countAtkNum = 0
            local num = 1
            for k,v in ipairs(self.battleMap.battler) do
              if v.M.utype == 2 and num<buff.m then
                num=num+1 
                self.count=((self.count or 0)+1)%2
                local attackValue = attackValue*buff.z/100
                local shot = AirShot.new(attackValue, 130, p[1], p[2], p[3], v, 0, imaLevel,self.count)
                shot.attacker = self
                self.vstate.scene.replay:addDelay(function()
                  shot:addToScene(vstate.scene)
                end,0.2)
              end
            end
          end
        end
    end
end


--防空炮
AirShot = class(SingleShot)

function AirShot:ctor(attackValue, speed, x, y, z, target, height, imaLevel,count)
    self.height = height or 0
    self.imaLevel = imaLevel
    self.count=count
    self.callback=nil
end

function AirShot:update(diff)
    diff = diff * (self.scene.speed or 1)
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

function AirShot:initView()
    local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {distance*10/self.speed}
    self.state = 1

    self.effectManager=GameEffect.new("Build_fangkongpao.json")
    self.views=self.effectManager.views
    self.viewsNode=self.scene.objs
    self.initPos[3]=self.scene.map.maxZ
    self.targetPos[3]=self.scene.map.maxZ

    self:resetView()
    self:initEffect()
end

function AirShot:resetView()
    if self.state==1 then
        if self.target.deleted then
            return
        end
        self.scene.replay:addUpdateObj(self)
    end
end

function AirShot:initEffect()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local imaLevel= self.imaLevel
   local direction=self.direction
   local initPos=self.initPos
   local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local moveTime=self.time[1]
   local r=-math.deg(math.atan2(moveY,moveX))
   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3])
   
   local function showTargetBao( )
      self:createViews_17()
   end
   self:createViews_1()
    if imaLevel<=3 then
      self:createViews_14(moveNode)
    elseif imaLevel<=9 then
      self:createViews_15(moveNode)
    elseif imaLevel<=13 then
      self:createViews_16(moveNode)
    end
    moveNode:setRotation(r)
    moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
end
--发射点特效
function AirShot:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local imaLevel=self.imaLevel
   local sclas={{0.45,0.35},{0.55,0.45},{0.65,0.55}}
   local temp
   local scla1
   local scla2
   if imaLevel<=4 then
      scla1=sclas[1][1]
      scla2=sclas[1][2]
   elseif imaLevel<=10 then
      scla1=sclas[2][1]
      scla2=sclas[2][2]
   elseif imaLevel<=13 then
      scla1=sclas[3][1]
      scla2=sclas[3][2]
   end
     effectManager:addEffect("views1_delay0",bg)
      temp=views.Particle_1
      temp:setScale(scla1)
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_3
      temp:setScale(scla2)
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setAutoRemoveOnFinish(true)
end

function AirShot:createViews_14(moveNode)
   local effectManager=self.effectManager
   local bg=moveNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views14_delay0",bg)
      temp=views.fangkongzidan3_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp=views.Particle_18
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp=views.Particle_37
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
end

function AirShot:createViews_15(moveNode)
   local effectManager=self.effectManager
   local bg=moveNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views15_delay0",bg)
      temp=views.fangkongzidan2_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp=views.Particle_18_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp=views.Particle_35
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp=views.Particle_36
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
end

function AirShot:createViews_16(moveNode)
   local effectManager=self.effectManager
   local bg=moveNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views16_delay0",bg)
      temp=views.fangkongzidan1_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp=views.Particle_18_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp=views.Particle_28_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp=views.Particle_28
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
end

function AirShot:createViews_17()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views17_delay0",bg)
      temp=views.Particle_32
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_31
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_34
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setAutoRemoveOnFinish(true)
end


return Patriot
