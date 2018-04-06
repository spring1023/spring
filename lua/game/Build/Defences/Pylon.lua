--电塔 26
local Pylon = {}

function Pylon:attack(target)
    self.coldTime = self.coldTime+self.avtInfo.aspeed
    local shot
    local vstate = self.vstate
    local attackValue = BattleUtil.getHurt(self, target)

    local scene = self.vstate.scene
    if GEngine.rawConfig.DEBUG_NOBEFFECT then
        shotDamage({attacker = self},target,attackValue)
    else
        local imaLevel=self.vconfig.imaLevel
        local setting={{0,86,0},{0,86,0},{0,86,0},{0,86,0},{0,86,0},{0,86,0},{0,86,0},{0,86,0},{0,86,0},{0,86,0},{0,86,0},{0,95,0},{0,95,0},{0,100,0}}
        local ox,oy,r=setting[imaLevel][1],setting[imaLevel][2],setting[imaLevel][3]
        local p = self:getAttackPosition(ox,oy,r, 1)

        --哆啦A梦觉醒
        local function callback(target)
          local buff = self.allBuff.DoraemonGodSkill2
          if buff then
            if not self.countForGodSkill then
              self.countForGodSkill = 0
            end
            self.countForGodSkill = self.countForGodSkill+1
            if self.countForGodSkill>=buff.d then
              self.countForGodSkill = 0
              local ret = self.battleMap:getCircleTarget(target,self.battleMap.battlerAll,buff.n)
              for k,v in ipairs(ret) do
                if v~= target then
                  SkillPlugin.exe2(self,v,0,buff.z)
                end
              end

              local sgx,sgy
              if target.avater then
                  sgx,sgy = target.avater.gx,target.avater.gy
              elseif target.battleViewInfo then
                  sgx,sgy = target.battleViewInfo[1],target.battleViewInfo[2]
              end
              local px,py = scene.map.convertToPosition(sgx,sgy)
              ElectricShock.new(scene.objs,px,py)

            end
          end
          return true
        end
        local shot = ThunderShot.new(attackValue, 180, p[1], p[2], p[3], target,imaLevel,callback)
        if not shot then
            return
        end

        shot.attacker = self
        shot:addToScene(vstate.scene) 
    end
end

ThunderShot = class(SingleShot)

function ThunderShot:ctor(attack, speed, x, y, z, target,imaLevel,callback)
    self.callback = callback
    self.imaLevel=imaLevel
end

function ThunderShot:update(diff)
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

function ThunderShot:initView()
   local distance = self.scene.map.getGridDistance(self.targetPos[1]-self.initPos[1], self.targetPos[2]-self.initPos[2])
    self.time = {0.2}
    self.state = 1

    self.effectManager=GameEffect.new("Build_dianta.json")
    self.views=self.effectManager.views
    self.viewsNode=self.scene.objs
    self.initPos[3]=self.initZorder+10000
    self.targetPos[3]=self.targetZ+10000

    self:resetView()
    self:initEffect()
end

function ThunderShot:resetView()
    if self.state==1 then
        if self.target.deleted then
            return
        end
        self.scene.replay:addUpdateObj(self)
    end
end

function ThunderShot:initEffect()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local imaLevel= self.imaLevel
   local direction=self.direction
   local initPos=self.initPos
   local targetPos=self.targetPos
   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local r=-math.deg(math.atan2(moveY,moveX))
   local length=math.sqrt(moveX*moveX+moveY*moveY)
   local lineNode=ui.node()
   lineNode:setPosition(initPos[1],initPos[2])
   bg:addChild(lineNode,initPos[3]+10000)
   lineNode:setScaleX(length/1060)
   lineNode:setRotation(r)
   lineNode:runAction(ui.action.sequence({{"delay",17/60},"remove"}))

   self:createViews_0()
   --电击
   if imaLevel<=4 then
      self:createViews_1(lineNode)
   elseif imaLevel<=8 then
      self:createViews_2(lineNode)
   elseif imaLevel<=11 then
       self:createViews_3(lineNode)
   elseif imaLevel<=14 then
     self:createViews_4(lineNode)
   end
   --被击
   if imaLevel<=11 then
      self:createViews_5()
   elseif imaLevel<=14 then
      self:createViews_6()
   end
end

function ThunderShot:createViews_0()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.initPos
   local imaLevel=self.imaLevel
   local temp
    if imaLevel<=11 then
      effectManager:addEffect("views7_delay0",bg)
   elseif imaLevel<=14 then
      effectManager:addEffect("views8_delay0",bg)
   end
    
    temp=views.Sprite_10_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10001)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",2/60,0},{"fadeTo",2/60,255}})))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.Sprite_10_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10002)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",2/60,0},{"fadeTo",2/60,255}})))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.GF_472_4
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10003)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",3/60,255},{"fadeTo",3/60,102}})))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    temp=views.dianhuang_00000_13
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10004)
    temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",20/60},"remove"}))
    temp=views.Sprite_3_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10005)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",15/60,0.8,0.8}}))
    temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",15/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",15/60},"remove"}))
end

function ThunderShot:createViews_1(lineNode)
   local effectManager=self.effectManager
   local bg=lineNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views1_delay0",bg)
      temp=views.dianji_00016_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
end

function ThunderShot:createViews_2(lineNode)
   local effectManager=self.effectManager
   local bg=lineNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views2_delay0",bg)
      temp=views.dianji_00016_3_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)

      temp=views.dianji_00016_3_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
end

function ThunderShot:createViews_3(lineNode)
   local effectManager=self.effectManager
   local bg=lineNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views3_delay0",bg)
      temp=views.dianji_00016_3_0_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp=views.dianji_00016_3_0_0_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp=views.dianji_00016_3_0_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
end

function ThunderShot:createViews_4(lineNode)
   local effectManager=self.effectManager
   local bg=lineNode
   local views=self.views
   local initPos=self.initPos
   local temp

     effectManager:addEffect("views4_delay0",bg)
      temp=views.dianji_00016_3_0_2_0
     temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp=views.dianji_00016_3_0_2_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp=views.dianji_00016_3_0_2_2
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
end

function ThunderShot:createViews_5()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views5_delay0",bg)
      temp=views.beiji1_00000_13
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
end

function ThunderShot:createViews_6()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local initPos=self.targetPos
   local temp

     effectManager:addEffect("views6_delay0",bg)
      temp=views.beiji2_00000_21
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+1)
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
end

--防御天神技
ElectricShock=class()
function ElectricShock:ctor(bg,x,y,attackMode,direction)
    self.effectManager=GameEffect.new("ElectricShock.json")
    self.views=self.effectManager.views
    self.viewsNode=bg
    self.initPos={x,y,0}
    self.targetPos={x+400,y-400,0}
    self.attackMode=attackMode
    self.direction=direction
    self:initEffect()
end
function ElectricShock:initEffect()
    self:createViews_1()
end
function ElectricShock:createViews_1()
   local effectManager=self.effectManager
   local bg=self.viewsNode
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
   upNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

   local downNode=ui.node()
   downNode:setPosition(initPos[1],initPos[2])
   bg:addChild(downNode,initPos[3])
   downNode:runAction(ui.action.sequence({{"delay",80/60},"remove"}))

    local function delayFrameIndex_0()
     effectManager:addEffect("views1_delay0",downNode)
      temp=views.Glow_02_15
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,1.6,1.4},{"scaleTo",35/60,2.2,1.6}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",35/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
      temp=views.Glow_16_10_0
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,8.0,6.4},{"scaleTo",35/60,12,10.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,153},{"fadeTo",35/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
      temp=views.Glow_16_10
      temp:runAction(ui.action.sequence({{"scaleTo",10/60,8.0,6.4},{"scaleTo",35/60,12,10.4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,255},{"fadeTo",35/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",45/60},"remove"}))
      temp=views.DIanqn_00000_8
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",30/60,4,4}}))
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.DIanqn_00000_8_0
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",30/60,4,4}}))
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.DIan_00000_12
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",25/60,4,4}}))
      temp:runAction(ui.action.sequence({{"fadeTo",15/60,204},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_0}}))

   local function delayFrameIndex_2()
     effectManager:addEffect("views1_delay2",upNode)
      temp=views.Glow_01_17
      temp:runAction(ui.action.sequence({{"scaleTo",8/60,1.3,1.1},{"scaleTo",10/60,2.0,2.0}}))
      temp:runAction(ui.action.sequence({{"fadeTo",8/60,255},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",2/60},{"call",delayFrameIndex_2}}))

   local function delayFrameIndex_15()
     effectManager:addEffect("views1_delay15",downNode)
      temp=views.DIanqn_00000_8_1
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",5/60,0.4,0.4},{"scaleTo",30/60,4,4}}))
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
      temp=views.DIanqn_00000_8_0_0
      temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",5/60,0.4,0.4},{"scaleTo",30/60,4,4}}))
      temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",35/60},"remove"}))
   end
   downNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_15}}))

end





return Pylon