

local M = class(AvtInfo)













local V = {}

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
    local shot = MinisterShot.new(100, 1250, p[1], p[2], p[3],attackTarget,1,self.direction,attackmode,true,callback)
    shot.attacker = self
    shot:addToScene(self.scene)
end

local C = class(AvtControler)
--4005 10格内，链式加血，给己方血量最低的n个单位回复a+c%*攻击力的血量，优先英雄
function C:sg_ppexeSkill(target)
    self.isAddGroup = {}
    if self:searchAddTarget() then
        self.isSkillAttack = true
        self.isSkillNotAttack = true
        self.skillNum = self.avtInfo.person.actSkillParams.n
    end
end

function C:sg_exeSkill(target)
    local params = self.avtInfo.person.actSkillParams
    local a,c = params.a,params.c
    if not self.skillTarget then
      return
    end
    SkillPlugin.exe7(self,self.skillTarget,a,c)
end

function C:searchAddTarget(again)
    local params = self.avtInfo.person.actSkillParams
    local a,b,n = params.a,params.c,params.n
    local allBuilds = self.battleMap2.hero
    if again then
        allBuilds = self.battleMap2.battler
    end
    local sgx, sgy = self.avater.gx,self.avater.gy

    local pointTab = {}
    for i,v in ipairs(allBuilds) do
        if not self.isAddGroup[v] then
            local viewInfo = v.battleViewInfo or self.battleMap2:getSoldierBattleViewInfoReal(v)
            table.insert(pointTab,{viewInfo[1],viewInfo[2],viewInfo[3],v})
        end
    end
    local result = Aoe.circlePoint(pointTab,{sgx,sgy},100)
    local minHp = 11
    local target
    for k,v in ipairs(result) do
        local hp = v[4].avtInfo.nowHp/v[4].avtInfo.maxHp
        if hp<minHp then
            minHp = hp
            target = v[4]
        end
    end
    if target then
        if self.skillNum == self.avtInfo.person.actSkillParams.n then
            self.skillTarget = target
        else
            self.skillTarget = target
        end
        self.isAddGroup[target] = 1
        return true
    else
        if not again then
            self:searchAddTarget(true)
        else
            return false
        end
    end
end

MinisterShot=class(SingleShot)
function MinisterShot:ctor(attack, speed, x, y, z, target,level,dir,attackmode,first,callback)
    self.callback = callback
    self.speed = speed
    self.attackmode=attackmode
    self.dir=dir
    self.first=first
    self.effectManager=GameEffect.new("MinisterEffect.json")
    self.effectViews=self.effectManager.views

    self.scene = GMethod.loadScript("game.View.Scene")
    self.dnode = ui.node()
    self.scene.objs:addChild(self.dnode)
end

function MinisterShot:update(diff)
    if not self.view then return end
    local stateTime = self.stateTime + diff
    local state = self.state
    if stateTime >= self.time[state] then
        self.state = state+1
        stateTime = stateTime - self.time[state]
        self.view = nil
        self:resetView()
        self.callback(self.target)
        local hero = self.attacker.C
        local allSkillNum = hero.M.person.actSkillParams.n
        local isFirst = false
        if allSkillNum == self.skillNum then
            isFirst = true
        end
        --链式加血
        if self.attackmode == 1 then
            hero.skillNum = hero.skillNum-1
            if hero.skillNum>0 then
                if hero:searchAddTarget() then
                    if isFirst then
                        music.play("sounds/" .. hero.avater.animaConfig.skill_music11)
                    else
                        music.play("sounds/" .. hero.avater.animaConfig.skill_music12)
                    end
                    local shot = MinisterShot.new(100, 1250, self.targetPos[1], self.targetPos[2], General.sceneHeight,hero.skillTarget,1,self.dir,self.attackmode,false,self.callback)
                    shot.attacker = self.attacker
                    shot:addToScene(self.attacker.scene)
                else
                    music.play("sounds/" .. hero.avater.animaConfig.skill_music13)
                    self.skillNum = nil
                    self.isAddGroup = nil
                end
            else
                music.play("sounds/" .. hero.avater.animaConfig.skill_music13)
                self.skillNum = nil
                self.isAddGroup = nil
            end
        end
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
    self.stateTime = stateTime
end

function MinisterShot:initView()
    self.state = 1
    self:resetView()
end
function MinisterShot:resetView()
    if self.state==1 then
        if self.attackmode==0 then
            local movetime=math.sqrt((self.targetPos[1]-self.initPos[1])^2+(self.targetPos[2]-self.initPos[2])^2)/self.speed
            self.time={movetime}
            self:createAttackEffect()
        elseif self.attackmode==1 then
            self.time={0.4}   
            if self.first then
                self:createSkillEffect()
            else
                self:createAttackerEffect()
            end
            self:createLine()
        end
        self.view=true
        self.scene = GMethod.loadScript("game.View.Scene")
        if self.scene.replay then
            self.scene.replay:addUpdateObj(self)
        else
            RegActionUpdate(self, Handler(self.update, self, 0.025), 0.025)
        end
    end
end


function MinisterShot:createAttackEffect()
   local setting={{76,-40,1},{145,69,1},{86,154,1},{-86,154,1},{-145,69,1},{-76,-40,1}}
   local effectManager=self.effectManager
   local bg=self.scene.objs
   local views=self.effectViews
   local direction=self.dir
   local initPos={self.initPos[1],self.initPos[2]}
   initPos[1]=initPos[1]+setting[direction][1]
   initPos[2]=initPos[2]+setting[direction][2]

   local targetPos=self.targetPos
   targetPos[3]=10000
   local temp
   local moveTime=self.time[1]

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   moveNode:setScale(2)
   bg:addChild(moveNode,targetPos[3])

   self.dnode:runAction(ui.action.sequence({{"delay",64/60},"remove"}))

     effectManager:addEffect("views3_delay19",moveNode)
      temp=views.Glow_01_23
      temp:setPosition(0,0)
      temp=views.Particle_3
      temp:setPosition(0,0)
      temp=views.Particle_3_0
      temp:setPosition(0,0)
      temp=views.Particle_7
      temp:setPosition(0,0)
   moveNode:runAction(ui.action.sequence({{"moveTo",moveTime,targetPos[1],targetPos[2]},{"delay",5/60},"remove"}))

   local function delayFrameIndex_61()
     effectManager:addEffect("views3_delay61",bg)
      temp=views.Circle_26_0
      temp:setPosition(targetPos[1],targetPos[2])
      temp:setLocalZOrder(targetPos[3]+7)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.3,0.3},{"scaleTo",10/60,0.45,0.45}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",moveTime+5/60},{"call",delayFrameIndex_61}}))

   local function delayFrameIndex_54()
     effectManager:addEffect("views3_delay54",bg)
      temp=views.Circle_26
      temp:setPosition(targetPos[1],targetPos[2])
      temp:setLocalZOrder(targetPos[3]+6)
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.3,0.3},{"scaleTo",10/60,0.45,0.45}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Glow_01_27
      temp:setPosition(targetPos[1],targetPos[2])
      temp:setLocalZOrder(targetPos[3]+8)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"fadeTo",15/60,126},{"fadeTo",7/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
      temp=views.Glow_01_27_0
      temp:setPosition(targetPos[1],targetPos[2])
      temp:setLocalZOrder(targetPos[3]+9)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"fadeTo",10/60,126},{"fadeTo",12/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",23/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",moveTime},{"call",delayFrameIndex_54}}))

end

function MinisterShot:createSkillEffect()
  -- local setting={{-40,40},{-50,-10},{-60,-40},{60,-40},{50,-10},{{40,40}}}
   local effectManager=self.effectManager
   local bg=self.scene.objs
   local views=self.effectViews
   local direction=self.dir
   local initPos={self.initPos[1],self.initPos[2],0}
   -- initPos[1]=initPos[1]+setting[direction][1]
   -- initPos[2]=initPos[2]+setting[direction][2]

   local temp
   self.dnode:runAction(ui.action.sequence({{"delay",100/60},"remove"}))

   local function delayFrameIndex_64()
     effectManager:addEffect("views1_delay64",bg)
      temp=views.Circle_25_0_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3])
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.4,0.3},{"scaleTo",10/60,0.5,0.375}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_64}}))

   local function delayFrameIndex_49()
     effectManager:addEffect("views1_delay49",bg)
      temp=views.Trail_00000_18
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3])
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,178},{"delay",25/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",27/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_49}}))

   local function delayFrameIndex_45()
     effectManager:addEffect("views1_delay45",bg)
      temp=views.Magic_Circle_9_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3])
      temp:runAction(ui.action.rotateBy(40/60,360))
      temp:runAction(ui.action.sequence({{"fadeTo",20/60,255},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
      temp=views.Glow_01_10
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3])
      temp:runAction(ui.action.sequence({{"fadeTo",10/60,168},{"delay",20/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
      temp=views.Glow_01_10_0
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3])
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",10/60,168},{"delay",20/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_45}}))

   local function delayFrameIndex_54()
     effectManager:addEffect("views1_delay54",bg)
      temp=views.Circle_25_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3])
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.4,0.3},{"scaleTo",10/60,0.5,0.375}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Particle_2
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10000)
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_54}}))
end

function MinisterShot:createLine()
   local setting={{76,-40,1},{145,69,1},{86,154,1},{-86,154,1},{-145,69,1},{-76,-40,1}}
   local effectManager=self.effectManager
   local bg=self.scene.objs
   local views=self.effectViews
   local initPos={self.initPos[1],self.initPos[2],100000}
   local direction=self.dir
   if self.first then
    initPos[1]=initPos[1]+setting[direction][1]
    initPos[2]=initPos[2]+setting[direction][2]
   end
   local temp
   local px=self.targetPos[1]-initPos[1]
   local py=self.targetPos[2]-initPos[2]
   local initPos2={(self.targetPos[1]+initPos[1])/2,(self.targetPos[1]+initPos[2])/2}
   local length=math.sqrt(px*px+py*py)
   local r=math.deg(math.atan2(py, px))

     if self.first then
        effectManager:addEffect("Sprite_15",bg)
        temp=views.Sprite_15
        temp:setPosition(initPos[1],initPos[2])
        temp:setLocalZOrder(initPos[3])
        temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.0,1.0},{"scaleTo",10/60,0.8,0.8}}))
        temp:runAction(ui.action.sequence({{"fadeTo",1/60,195},{"fadeTo",10/60,255},{"fadeTo",10/60,197},{"fadeTo",5/60,0}}))
        temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
     end
     effectManager:addEffect("views2_delay54",bg)
      temp=views.Trail_00000_9
      temp:setPosition(initPos[1],initPos[2])
      temp:setRotation(-r)
      temp:setScaleX(length/500)
      temp:setLocalZOrder(initPos[3]+10003)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",44/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",49/60},"remove"}))
      temp=views.Trail_00000_9_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setScaleX(length/500)
      temp:setRotation(-r)
      temp:setLocalZOrder(initPos[3]+10004)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,178},{"delay",44/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",49/60},"remove"}))
      temp=views.Particle_1
      temp:setPosition(initPos[1],initPos[2])
      temp:setRotation(-r)
      temp:setScaleX(length/500)
      temp:setLocalZOrder(initPos[3]+10005)
      temp:runAction(ui.action.sequence({{"delay",46/60},"remove"}))
end

function MinisterShot:createAttackerEffect()
   local effectManager=self.effectManager
   local bg=self.scene.objs
   local views=self.effectViews
   local initPos={self.initPos[1],self.initPos[2],self.initZorder}

   local temp


   self.dnode:runAction(ui.action.sequence({{"delay",83/60},"remove"}))

  local upNode=ui.node()
  upNode:setPosition(initPos[1],initPos[2])
  bg:addChild(upNode,initPos[3]+10)
  upNode:setScale(2.5)
  upNode:runAction(ui.action.sequence({{"delay",83/60},"remove"}))
  
   local function delayFrameIndex_67()
     effectManager:addEffect("views2_delay67",upNode)
      temp=views.Glow_01_16
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",4/60,255},{"delay",4/60},{"fadeTo",17/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",25/60},"remove"}))
      temp=views.Glow_01_16_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(0)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",4/60,255},{"fadeTo",12/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
      temp=views.Glow_01_22
      temp:setPosition(0,0)
      temp:setLocalZOrder(10)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",4/60,255},{"delay",50/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",69/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_67}}))

   local function delayFrameIndex_70()
     effectManager:addEffect("views2_delay70",upNode)
      temp=views.Circle_25
      temp:setPosition(0,0)
      temp:setLocalZOrder(-3)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,0.4,0.3},{"scaleTo",10/60,0.5,0.375}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
      temp=views.Line_PRT
      temp:setPosition(0,0)
      temp:setLocalZOrder(8)
      temp:runAction(ui.action.sequence({{"delay",52/60},"remove"}))
      temp=views.Star_PRT
      temp:setPosition(0,0)
      temp:setLocalZOrder(9)
      temp:runAction(ui.action.sequence({{"delay",52/60},"remove"}))
   end
   self.dnode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_70}}))

end

return {M,V,C}
