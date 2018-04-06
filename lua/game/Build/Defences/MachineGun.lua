--重型机关枪 27

local MachineGun = {}

function MachineGun:attack(target)
    self.coldTime = self.coldTime+self.avtInfo.aspeed
    local shot
    shot = self.mgShot
    local vstate = self.vstate
    local attackValue = BattleUtil.getHurt(self, target)
    if GEngine.rawConfig.DEBUG_NOBEFFECT then
        shotDamage({attacker = self},target,attackValue)
    else
        local dir=vstate.rotateInfo.dir
        local mx=-8*math.cos(math.rad(-90-dir*20))
        local my=-8*math.sin(math.rad(-90-dir*20))
        vstate.bviews[2]:runAction(ui.action.sequence({{"moveBy",0.05,mx,my},{"moveBy",0.05,-mx,-my}}))
        vstate.bviews[2]:runAction(ui.action.sequence({{"scaleTo",0.05,0.95,1},{"scaleTo",0.05,1,1}}))

        local imaLevel=self.vconfig.imaLevel

        local setting={{0,66,1,0},{0,66,1,0},{0,70,1.2,0},{0,75,1.3,0},{0,75,1.6,0},{0,85,1.75,0}}
        local ox,oy,r,eh=setting[imaLevel][1],setting[imaLevel][2],setting[imaLevel][3],setting[imaLevel][4]

        local setOXOy={[1]={{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}},
                        [2]={{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0},{0,0}},
                        [3]={{0,0},{5,0},{10,0},{10,0},{0,0},{0,0},{0,8},{0,10},{0,13},{0,13},{0,18},{0,15},{0,15},{0,10},{0,10},{0,0},{-5,0},{0,5}},
                        [4]={{0,0},{5,0},{10,0},{10,0},{0,0},{0,0},{0,8},{0,10},{0,13},{0,13},{0,18},{0,15},{0,15},{0,10},{0,0},{-5,-5},{-10,0},{-5,5}},
                        [5]={{0,15},{10,5},{20,5},{15,0},{5,0},{0,0},{0,8},{0,10},{0,13},{0,13},{0,18},{-5,20},{0,15},{-5,15},{-10,0},{-15,5},{-20,5},{-10,15}},
                        [6]={{0,10},{15,7},{10,0},{23,0},{20,2},{10,5},{0,8},{0,10},{0,13},{0,13},{0,18},{0,15},{-10,5},{-10,5},{-15,-5},{-12,0},{-20,0},{-10,5}},
                            }
        local direction=self.vstate.rotateInfo.dir
          ox=ox+setOXOy[imaLevel][direction+1][1]
          oy=oy+setOXOy[imaLevel][direction+1][2]

        local p = self:getAttackPosition( ox, oy,r, self.vstate.rotateInfo.dir)

        local targetView=target.avater.view
        local targetPos={targetView:getPositionX(),targetView:getPositionY()}
        if not self.targetPos then
            self.targetPos=targetPos
        end

        if not shot or not shot.view or shot.target~=target then
          shot = MachineGunShot.new(attackValue, 120, p[1], p[2], p[3], target, p[4], 1.5, self.vstate.rotateInfo.dir,imaLevel,self.avtInfo.aspeed)
          shot.build=self
          self.targetPos=targetPos
          if not shot then
              return
          end
          self.mgShot=shot
          shot.attacker = self
          shot:addToScene(vstate.scene)
        end
    end
end

function MachineGun:dieEvent()
  local buff = self.allBuff.HulkGodSkill2
  if buff then
    local hero = buff.hero
    local params = clone(hero.params,{scene = 1})
    params.index = nil
    params.isZhaoHuan = true
    local gx,gy = self.battleViewInfo[1],self.battleViewInfo[2]
    local role = PersonUtil.C(params)
    role.M.base_hp = role.M.base_hp*buff.z/100
    role.M.maxHp = role.M.base_hp
    role.M.nowHp = role.M.maxHp
    role:addToScene(self.vstate.scene,gx,gy)
    role:hideSelf(2, false)
    local px,py = self.vstate.scene.map.convertToPosition(gx,gy)
    Hulk2ZhaoHuan.new(self.vstate.scene.objs,px,py)
    ui.setColor(role.V.personView2,{0,159,255})
    role.V.personView2:setOpacity(0)
    role.V.personView2:runAction(ui.action.sequence({{"fadeTo",15/60,255}}))
  end
end

--重机枪
MachineGunShot=class(SingleShot)

function MachineGunShot:ctor(attack, speed, x, y, z, target, angle, scale,direction,imaLevel,aspeed)
    self.angle = angle
    self.scale = scale or 1
    self.direction=direction
    self.imaLevel=imaLevel
    self.aspeed=aspeed
    self.callback = nil
end
function MachineGunShot:shouldDelete()
    if self.target.deleted or self.attacker.deleted then
        return true
    end
    if not self.target.deleted and self.target.avater then
        local view = self.target.avater.view
        local height = 40 + self.target.avater.personView:getPositionY()
        local targetPos = {view:getPositionX(),view:getPositionY() + height}
        if self.targetPos[1]~=targetPos[1] or self.targetPos[2]~=targetPos[2] then
          return true
        end
    end
    if self.attacker.avtInfo.bfDizziness>0 then
        return true
    end
    return false
end
function MachineGunShot:update(diff)
    local stateTime = self.stateTime + diff
    local state = self.state
    if self:shouldDelete() then
       if self.view then
          --防止目标被一次打死特效不出现加的延迟
          self.scene.replay:addDelay(function()
            if self.view then
              self.view:removeFromParent(true)
              self.view=nil
              self.deleted = true
              self.scene.replay:removeUpdateObj(self)
            end
          end,0.2)
       end
    end
    if stateTime >= self.time[state] then
        stateTime=0
        shotDamage(self, self.target, self.attackValue)
        --被击特效
        local imaLevel=self.imaLevel
        if imaLevel<=3 then
            self:createViews_7()
         elseif imaLevel<=5 then
            self:createViews_8()
         elseif imaLevel<=6 then
            self:createViews_9()
         end
    end
    self.stateTime = stateTime
end

function MachineGunShot:initView()
    self.time = {self.aspeed}
    self.state = 1

    self.effectManager=GameEffect.new("Build_zhongjiqiang.json")
    self.views=self.effectManager.views
    self.viewsNode=self.scene.objs
    self.initPos[3]=self.initZorder+10000
    self.targetPos[3]=self.targetZ+10000

    self:resetView()
    self:initEffect()
end

function MachineGunShot:resetView()
    if self.state==1 then
        if self.target.deleted then
            return
        end
        self.scene.replay:addUpdateObj(self)
    end
end
function MachineGunShot:initEffect()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local imaLevel= self.imaLevel
   local direction=self.direction
   local initPos=self.initPos
   local targetPos=self.targetPos

   local aNode=ui.node()
   aNode:setPosition(initPos[1],initPos[2])
   aNode:setRotation(20*direction)
   bg:addChild(aNode,initPos[3])
   self.view=aNode

   --开火
   if imaLevel==1 then
      self:createViews_1(aNode)
   elseif imaLevel==2 then
      self:createViews_2(aNode)
   elseif imaLevel==3 then
      self:createViews_3(aNode)
   elseif imaLevel==4 then
       self:createViews_4(aNode)
   elseif imaLevel==5 then
       self:createViews_5(aNode)
   elseif imaLevel==6 then
       self:createViews_6(aNode)
   end
end

function MachineGunShot:createViews_1(bg)
   local effectManager=self.effectManager
   local views=self.views
   local initPos={0,0,0}
   local direction=self.direction
   local temp

     effectManager:addEffect("views1_delay0",bg)
      temp=views.Sprite_1_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      
      temp=views.diguang_1_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]-1)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",3/60,127},{"fadeTo",3/60,0}})))
end

function MachineGunShot:createViews_2(bg)
   local effectManager=self.effectManager
   local views=self.views
   local initPos={0,0,0}
   local direction=self.direction
   local temp

     effectManager:addEffect("views2_delay0",bg)
      temp=views.Sprite_1_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)

      temp=views.diguang_1_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]-1)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",3/60,127},{"fadeTo",3/60,0}})))
end

function MachineGunShot:createViews_3(bg)
   local effectManager=self.effectManager
   local views=self.views
   local initPos={0,0,0}
   local direction=self.direction
   local temp

     effectManager:addEffect("views3_delay0",bg)
      temp=views.Sprite_1_0_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)

      temp=views.diguang_1_0_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]-1)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",3/60,127},{"fadeTo",3/60,0}})))

end

function MachineGunShot:createViews_4(bg)
   local effectManager=self.effectManager
   local views=self.views
   local initPos={0,0,0}
   local direction=self.direction
   local temp
   

     effectManager:addEffect("views4_delay0",bg)
      temp=views.Sprite_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp=views.diguang_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]-1)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",3/60,127},{"fadeTo",3/60,0}})))
      temp=views.GF_472_8
      temp:setPosition(initPos[1],initPos[2]+60)
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",6/60,3,3},{"scaleTo",0/60,1.4,1.4}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",6/60,0},{"fadeTo",0/60,255}})))
      temp=views.GF_472_8_0
      temp:setPosition(initPos[1],initPos[2]+60)
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",6/60,3,3},{"scaleTo",0/60,1,1}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",6/60,0},{"fadeTo",0/60,255}})))
end

function MachineGunShot:createViews_5(bg)
   local effectManager=self.effectManager
   local views=self.views
   local initPos={0,0,0}
   local direction=self.direction
   local temp
     effectManager:addEffect("views5_delay0",bg)
      temp=views.Sprite_1_0_0_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      
      temp=views.diguang_1_0_0_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]-1)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",3/60,127},{"fadeTo",3/60,0}})))

      temp=views.GF_472_8
      temp:setPosition(initPos[1],initPos[2]+60)
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",6/60,4,4},{"scaleTo",0/60,2,2}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",6/60,0},{"fadeTo",0/60,255}})))
      temp=views.GF_472_8_0
      temp:setPosition(initPos[1],initPos[2]+60)
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",6/60,3,3},{"scaleTo",0/60,1,1}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",6/60,0},{"fadeTo",0/60,255}})))
end

function MachineGunShot:createViews_6(bg)
   local effectManager=self.effectManager
   local views=self.views
   local initPos={0,0,0}
   local direction=self.direction
   local temp

     effectManager:addEffect("views6_delay0",bg)
      temp=views.Sprite_1_0_0_0_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp=views.diguang_1_0_0_0_0_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]-1)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",3/60,127},{"fadeTo",3/60,0}})))
      temp=views.GF_472_8
      temp:setPosition(initPos[1],initPos[2]+60)
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",6/60,4,4},{"scaleTo",0/60,2,2}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",6/60,0},{"fadeTo",0/60,255}})))
      temp=views.GF_472_8_0
      temp:setPosition(initPos[1],initPos[2]+60)
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",6/60,3,3},{"scaleTo",0/60,1,1}})))
      temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",6/60,0},{"fadeTo",0/60,255}})))
end

function MachineGunShot:createViews_7()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views7_delay0",bg)
      temp=views.beijizi_00000_4_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0.1},"remove"}))
end

function MachineGunShot:createViews_8()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views8_delay0",bg)
      temp=views.beijizi_00000_4_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0.1},"remove"}))
end

function MachineGunShot:createViews_9()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views9_delay0",bg)
      temp=views.beijizi_00000_4
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0.1},"remove"}))
      temp=views.C_00_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:runAction(ui.action.sequence({{"delay",0.1},"remove"}))
end

return  MachineGun