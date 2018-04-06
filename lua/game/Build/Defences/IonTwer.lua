--离子塔 28

local IonTwer = {}
function IonTwer:attack(target)
    self.coldTime = self.coldTime+self.avtInfo.aspeed
    local shot
    shot = self.GunShot
    local vstate = self.vstate
    local attackValue = BattleUtil.getHurt(self, target)


    if GEngine.rawConfig.DEBUG_NOBEFFECT then
        shotDamage({attacker = self},target,attackValue)
    else
        if not shot or not shot.view or shot.target~=target then
            local imaLevel=self.vconfig.imaLevel
            local setting={{0,130,0,0},{0,140,0,0},{0,140,0,0},{0,140,0,0},{0,140,0,0},{0,140,0,0},{0,140,0,0},{0,140,0,0},{0,140,0,0},{0,140,0,0},{0,150,0,0},{0,150,0,0},{0,150,0,0}}
            if not imaLevel or not setting[imaLevel] then
                return
            end
            if shot and shot.target ~= target then
                shot.__leftTime = 0
            end
            local ox,oy,r=setting[imaLevel][1],setting[imaLevel][2],setting[imaLevel][3]
            local p = self:getAttackPosition(ox,oy,r,1)
            shot = GunShot.new(attackValue, 120, p[1], p[2], p[3], target, p[4], 1.5,imaLevel,self.avtInfo.aspeed)
            if not shot then
                return
            end
            shot.attackValue = attackValue
            self.GunShot=shot
            shot.build=self
            shot.attacker = self
            shot:addToScene(vstate.scene)
        end
        shot.__leftTime = 1
        local buff = self.allBuff.ShamanGodSkill2
        if buff then
          local ps = buff.ps
          if not self.countForGodSkill then
            self.countForGodSkill = 0
          end
          self.countForGodSkill = self.countForGodSkill+self.M.aspeed
          if self.countForGodSkill>=ps.t then
            self.countForGodSkill = 0
            shot.callback = function()
              SkillPlugin.exe2(self,target,0,ps.z)
              BuffUtil.setBuff(target,{lastedTime=ps.k, bfAtkPct=-ps.o, bfAtkSpeedPct=-ps.o, bfMovePct=-ps.o,})
            end
          else
            shot.callback = nil
          end
        end
    end
end

GunShot=class(SingleShot)
function GunShot:ctor(attack, speed, x, y, z, target, angle, scale,imaLevel,aspeed)
    self.angle = angle
    self.scale = scale or 1
    self.imaLevel=imaLevel
    self.aspeed=aspeed
    self.callback = nil
end
function GunShot:shouldDelete()
    if self.target.deleted or self.attacker.deleted then
        return true
    end
    if not self.target.deleted and self.target.avater then
        local view = self.target.avater.view
        local height = 40 + self.target.avater.personView:getPositionY()
        local targetPos = {view:getPositionX(), view:getPositionY() + height}
        if self.targetPos[1] ~= targetPos[1] or self.targetPos[2] ~= targetPos[2] then
            self.targetPos[1], self.targetPos[2] = targetPos[1], targetPos[2]
            return false, true
        end
    end
    if self.attacker.avtInfo.bfDizziness>0 then
        return true
    end
    return false
end
function GunShot:update(diff)
    local stateTime = self.stateTime + diff
    local state = self.state
    local shouldDelete, shouldUpdate = self:shouldDelete()
    if self.__leftTime then
        self.__leftTime = self.__leftTime - diff
        if self.__leftTime <= 0 then
            shouldDelete = true
        end
    end
    if shouldDelete then
        if self.view then
            self.view:removeFromParent(true)
            self.view=nil
            self.deleted = true
            self.scene.replay:removeUpdateObj(self)
        end
        return
    elseif shouldUpdate then
        if self.view then
            local initPos=self.initPos
            local targetPos=self.targetPos
            local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
            local r=-math.deg(math.atan2(moveY,moveX))
            local length=math.sqrt(moveX*moveX+moveY*moveY)
             -- self.length=length
            self.view:setScaleX(length/1000)
            self.view:setRotation(r)
        end
    end
    if stateTime >= self.time[state] then
        stateTime=0
        if self.callback then
          self.callback()
        else
          shotDamage(self, self.target, self.attackValue)
        end
        --被击特效
        self:createViews_5()
    end
    self.stateTime = stateTime
end

function GunShot:initView()
    self.time = {self.aspeed}
    self.state = 1

    self.effectManager=GameEffect.new("Build_lizita.json")
    self.views=self.effectManager.views
    self.viewsNode=self.scene.objs
    self.initPos[3]=self.initZorder+10000
    self.targetPos[3]=self.targetZ+10000

    self:resetView()
    self:initEffect()
end

function GunShot:resetView()
    if self.state==1 then
        if self.target.deleted then
            return
        end
        self.scene.replay:addUpdateObj(self)
    end
end

function GunShot:initEffect()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local imaLevel= self.imaLevel
   local initPos=self.initPos
   local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local r=-math.deg(math.atan2(moveY,moveX))
   local length=math.sqrt(moveX*moveX+moveY*moveY)
   self.length=length
   local lineNode=ui.node()
   lineNode:setPosition(initPos[1],initPos[2])
   bg:addChild(lineNode,initPos[3])
   lineNode:setScaleX(length/1000)
   lineNode:setRotation(r)
   self.view=lineNode
   --lineNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   --电击
   if imaLevel<=5 then
      self:createViews_3(lineNode)
   elseif imaLevel<=10 then
      self:createViews_3(lineNode)
   elseif imaLevel<=13 then
       self:createViews_4(lineNode)
   end
end

function GunShot:createViews_2(lineNode)
   local effectManager=self.effectManager
   local bg=lineNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views2_delay0",bg)
      temp=views.Sprite_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      --temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Sprite_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      --temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
end

function GunShot:createViews_3(lineNode)
   local effectManager=self.effectManager
   local bg=lineNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views3_delay0",bg)
      temp=views.Sprite_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      --temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Sprite_2_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      --temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Particle_5
      temp:setPosition(480, 0)
      temp:setLocalZOrder(3)
end

function GunShot:createViews_4(lineNode)
   local effectManager=self.effectManager
   local bg=lineNode
   local views=self.views
   local initPos=self.initPos
   local targetPos=self.targetPos
   local centerPos={(initPos[1]+targetPos[1])/2,(initPos[2]+targetPos[2])/2}
   local temp

     effectManager:addEffect("views4_delay0",bg)
      temp=views.Sprite_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      --temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Sprite_3_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      --temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.Particle_5
      temp:setPosition(480,0)
      temp:setLocalZOrder(3)
end

function GunShot:createViews_5()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views5_delay0",bg)
      temp=views.Particle_6
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:runAction(ui.action.sequence({{"delay",0.5},"remove"}))
      temp=views.Particle_4
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"delay",0.5},"remove"}))
      temp=views.Particle_3
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0.5},"remove"}))
end

return IonTwer