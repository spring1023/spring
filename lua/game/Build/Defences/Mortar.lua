--迫击炮23
local Mortar = {}
function Mortar:attack(target)
    self.coldTime = self.coldTime+self.avtInfo.aspeed
    local shot
    local vstate = self.vstate
    local attackValue = BattleUtil.getHurt(self, target)
    
  
    if GEngine.rawConfig.DEBUG_NOBEFFECT then
        shotDamage({attacker = self},target,attackValue)
    else
        if self.level<14 then
          local dir=vstate.rotateInfo.dir
          local mx=-12*math.cos(math.rad(-90-dir*20))
          local my=-12*math.sin(math.rad(-90-dir*20))
          vstate.bviews[2]:runAction(ui.action.sequence({{"moveBy",0.1,mx,my},{"moveBy",0.1,-mx,-my}}))
          vstate.bviews[2]:runAction(ui.action.sequence({{"scaleTo",0.1,0.95,1},{"scaleTo",0.1,1,1}}))
        end

       local imaLevel=self.vconfig.imaLevel
        local setting={{0,66,0.2,0},{0,66,0.2,0},{0,66,0.3,0},{0,70,0.32,0},{0,80,0.32,0},{0,95,0,0}}
        local ox,oy,r=setting[imaLevel][1],setting[imaLevel][2],setting[imaLevel][3]
        local dir=1
        if imaLevel<6 then
          dir=self.vstate.rotateInfo.dir
        end
        local p = self:getAttackPosition(ox, oy, r, dir)
        local tx, ty = target.avater.view:getPosition()

        local callback
        local buff = self.allBuff.ThorGodSkill2
        if buff then
          local ps = buff.ps
          if not self.countForGodSkill2 then
            self.countForGodSkill2 = 0
          end
          self.countForGodSkill2 = self.countForGodSkill2+1
          if self.countForGodSkill2 >= ps.d then
            self.countForGodSkill2 = 0
            attackValue = attackValue*ps.z/100
            callback = function(ret)
              for k,v in ipairs(ret) do
                BuffUtil.setBuff(v,{lastedTime=ps.t, bfDizziness=ps.t})
              end
            end
          end
        end

        shot = MortarSplash.new(attackValue, 60, p[1], p[2], tx, ty, self.avtInfo.drange, GroupTypes.Defense, 1, 0, imaLevel,dir,self,callback)
        if not shot then
            return
        end
        shot:addToScene(vstate.scene)

        self:onReloadView(true)
    end
end

function Mortar:onReloadView(ani)
    local vstate = self.vstate
    local bviews = vstate.bviews
    local bformats = vstate.bformats
    if bviews[2] and bformats[2] then
        if not vstate.rotateInfo then
            vstate.rotateInfo = {dir=3, toDir=3}
        end
        local format = bformats[2]
        local params = format[2]
        params["num"] = nil
        vstate.rotateInfo.format = StringManager.formatString(format[1], params)
        self:changeDirectionView(vstate.rotateInfo.dir)
    else
        vstate.rotateInfo = nil
    end

    local vstate = self.vstate
    local vconfig = self.vconfig
    local bid = self.bsetting.bvid
    local blv = self.level
    if vconfig.maxLv and blv>vconfig.maxLv then
        blv = vconfig.maxLv
    end
    if blv<14 then
      return
    end
    -- if not vstate.MortarHead then
    --   local temp=ui.sprite("images/build32_14b2.png")
    --   display.adapt(temp,vstate.build:getContentSize().width/2,0, GConst.Anchor.Bottom)
    --   vstate.build:addChild(temp,2)
    --   vstate.MortarHead=temp
    -- end
end

--大炮
MortarSplash = class(AreaSplash)

function MortarSplash:ctor(attackValue, speed, x, y, targetX, targetY, damageRange, group, unitType, height,imaLevel,dir,attacker,callback)
    self.callback = callback
    self.height = height
    self.imaLevel=imaLevel
    self.direction=dir
    self.attacker=attacker
end

function MortarSplash:update(diff)
    diff = diff * (self.scene.speed or 1)
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

function MortarSplash:initView()
    local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {distance*10/self.speed}
    self.moveTime=self.time[1]
    self.state = 1

    self.effectManager=GameEffect.new("Build_dapao.json")
    self.views=self.effectManager.views
    self.viewsNode=self.scene.objs
    self.initPos[3]=self.scene.map.maxZ-self.initPos[2]+10000
    self.initPos2={self.attacker.vstate.view:getPositionX(),self.attacker.vstate.view:getPositionY()+self.attacker.vstate.view:getContentSize().height/2,self.initPos[3]}
    self.targetPos[3]=self.scene.map.maxZ-self.targetPos[2]+10000

    self:resetView()
    self:initEffect()


    local bviews = self.attacker.vstate.bviews
    if bviews[1] then--超过14级才有,炮头
       bviews[1]:runAction(ui.action.sequence({{"moveBy",0.2,0,-20},ui.action.easeSineOut(ui.action.moveBy(0.2,0,30)),{"moveBy",0.1,0,-10}}))
    end
end

function MortarSplash:resetView()
    if self.state==1 then
        self.scene.replay:addUpdateObj(self)
    end
end
function MortarSplash:JShtpoint()
  local ox,oy=math.abs(self.targetPos[1]-self.initPos[1]),math.abs(self.targetPos[2]-self.initPos[2])
  local r=math.atan2(oy, ox)
  local Lenth=math.sqrt((self.targetPos[1]-self.initPos[1])^2+(self.targetPos[2]-self.initPos[2])^2)
  local Cpoint={(self.targetPos[1]+self.initPos[1])/2,(self.targetPos[2]+self.initPos[2])/2}
  local pos=Cpoint
  --pos[2]=pos[2]+Lenth/2*math.sin(r)+Lenth/2*math.cos(r)
  pos[2]=pos[2]+ox
  self.htpos=pos
  self.endR=-math.deg(math.atan2(self.targetPos[2]-Cpoint[2],self.targetPos[1]-Cpoint[1]))
end
function MortarSplash:initEffect()
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
   self.moveX=moveX
   self.moveY=moveY
   self.moveTime=moveTime
   self.r=r
   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3])
   local function showTargetBao( )
    if imaLevel<=1 then
      self:createViews_6()
    elseif imaLevel<=3 then
      self:createViews_7()
    elseif imaLevel<=6 then
      self:createViews_8()
    end
   end
   moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
   self:createViews_1()

    self:JShtpoint()
    if self.targetPos[1]-self.initPos[1]>=0 then
      self.fuhao=1
      self.bR=-45
    else
      self.fuhao=-1
       self.bR=45
    end
    if imaLevel==1 then
      self:createViews_9()
    elseif imaLevel==2 then
      self:createViews_10()
    elseif imaLevel==3 then
      self:createViews_11()
    elseif imaLevel==4 then
      self:createViews_12()
    elseif imaLevel==5 then
      self:createViews_13()
    elseif imaLevel==6 then
      self:createViews_13()
    end


end

function MortarSplash:createViews_1()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local initPos=self.initPos
    local initPos2=self.initPos2
    local imaLevel=self.imaLevel
    local temp

    effectManager:addEffect("views1_delay0",bg)
    temp=views.Particle_2
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:setAutoRemoveOnFinish(true)
    temp=views.Particle_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:setAutoRemoveOnFinish(true)
    temp=views.Sprite_5
    if imaLevel >= 4 then
        temp:setScale(5.6)
    end
    temp:setPosition(initPos2[1],initPos2[2])
    temp:setLocalZOrder(initPos2[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",15/60,0},"remove"}))
end

function MortarSplash:createViews_6()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

   self.scene.scroll:getScrollNode():runAction(ui.action.actionShake(0.5, 40, 30))

     effectManager:addEffect("views6_delay0",bg)
      temp=views.baozhaquan_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,2.0,1.5}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
    local function delay6()
      effectManager:addEffect("views6_delay0_6",bg)
      temp=views.Particle_11_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setAutoRemoveOnFinish(true)
    end
    bg:runAction(ui.action.sequence({{"delay",3/60},{"call",delay6}}))
end

function MortarSplash:createViews_7()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

  self.scene.scroll:getScrollNode():runAction(ui.action.actionShake(0.5, 40, 30))

     effectManager:addEffect("views7_delay0",bg)
      temp=views.Particle_15
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_13
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setAutoRemoveOnFinish(true)
    local function delay6()
      effectManager:addEffect("views7_delay0_6",bg)
      temp=views.Particle_14
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setAutoRemoveOnFinish(true)
    end
    bg:runAction(ui.action.sequence({{"delay",6/60},{"call",delay6}}))
end

function MortarSplash:createViews_8()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

   self.scene.scroll:getScrollNode():runAction(ui.action.actionShake(0.5, 40, 30))

    effectManager:addEffect("views8_delay0",bg)
      temp=views.Particle_9
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_8
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setAutoRemoveOnFinish(true)
      temp=views.Particle_10
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setAutoRemoveOnFinish(true)
    local function delay6()
      effectManager:addEffect("views8_delay0_6",bg)
      temp=views.Particle_11
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp:setAutoRemoveOnFinish(true)
    end
    bg:runAction(ui.action.sequence({{"delay",6/60},{"call",delay6}}))
end
function MortarSplash:createViews_9()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local targetPos=self.targetPos
   local htpos=self.htpos
   local moveX=self.moveX
   local moveY=self.moveY
   local moveTime=self.moveTime
   local r=self.r
   local temp
   local acX,acY1,acY2
     effectManager:addEffect("views9_delay0",bg)
      temp=views.pojipao5
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setRotation(90+r+self.bR)
      local bezier = {
        cc.p(initPos[1],initPos[2]),
        cc.p(htpos[1],htpos[2]),
        cc.p(targetPos[1],targetPos[2]),
      }

      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp:runAction(ui.action.rotateTo(moveTime,90+self.endR))
     
      temp=views.Particle_16
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))

      temp=views.Particle_13
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
end

function MortarSplash:createViews_10()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local targetPos=self.targetPos
   local htpos=self.htpos
   local moveX=self.moveX
   local moveY=self.moveY
   local moveTime=self.moveTime
   local r=self.r
   local temp
   local acX,acY1,acY2

     effectManager:addEffect("views10_delay0",bg)
      temp=views.pojipao4
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setRotation(90+r+self.bR)
      local bezier = {
        cc.p(initPos[1],initPos[2]),
        cc.p(htpos[1],htpos[2]),
        cc.p(targetPos[1],targetPos[2]),
      }

      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp:runAction(ui.action.rotateTo(moveTime,90+self.endR))
      temp=views.Particle_6_Copy_Copy
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
     temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp=views.Particle_14
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
end

function MortarSplash:createViews_11()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local targetPos=self.targetPos
   local htpos=self.htpos
   local moveX=self.moveX
   local moveY=self.moveY
   local moveTime=self.moveTime
   local r=self.r
   local temp
   local acX,acY1,acY2

     effectManager:addEffect("views11_delay0",bg)
      temp=views.pojipao3
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setRotation(90+r+self.bR)
           local bezier = {
        cc.p(initPos[1],initPos[2]),
        cc.p(htpos[1],htpos[2]),
        cc.p(targetPos[1],targetPos[2]),
      }

      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp:runAction(ui.action.rotateTo(moveTime,90+self.endR))
      temp=views.Particle_11
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp=views.Particle_12
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
end

function MortarSplash:createViews_12()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local targetPos=self.targetPos
   local htpos=self.htpos
   local moveX=self.moveX
   local moveY=self.moveY
   local moveTime=self.moveTime
   local r=self.r
   local temp
   local acX,acY1,acY2

     effectManager:addEffect("views12_delay0",bg)
      temp=views.pojipao2
      temp:setRotation(90+r+self.bR)
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      local bezier = {
        cc.p(initPos[1],initPos[2]),
        cc.p(htpos[1],htpos[2]),
        cc.p(targetPos[1],targetPos[2]),
      }

      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp:runAction(ui.action.rotateTo(moveTime,90+self.endR))
      temp=views.Particle_6
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
     temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp=views.Particle_4
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
     temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp=views.Particle_3
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
end
function MortarSplash:createViews_13()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local targetPos=self.targetPos
   local htpos=self.htpos
   local moveX=self.moveX
   local moveY=self.moveY
   local moveTime=self.moveTime
   local r=self.r
   local temp
   local acX,acY1,acY2

     effectManager:addEffect("views13_delay0",bg)
      temp=views.pojipao1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+4)
      temp:setRotation(90+r+self.bR)
      local bezier = {
        cc.p(initPos[1],initPos[2]),
        cc.p(htpos[1],htpos[2]),
        cc.p(targetPos[1],targetPos[2]),
      }

      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp:runAction(ui.action.rotateTo(moveTime,90+self.endR))
      temp=views.Particle_6_Copy
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+3)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp=views.Particle_7
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+2)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
      temp=views.Particle_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
      temp:runAction(cc.BezierTo:create(moveTime, bezier)) 
      temp:runAction(ui.action.sequence({{"delay",moveTime},"remove"}))
end

return Mortar
