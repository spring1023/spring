local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    BeekEffect.new({realAttacker = self,attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--3008 一次性回复[n]个己方血量最低单位[a]+[c]%*攻击力的血量，优先英雄，消耗[x]怒，冷却时间[z]秒
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
    if target then
        SkillPlugin.exe7(self,target,a,c)
    end
end
function C:searchAddTarget(again)
    local params = self.avtInfo.person.actSkillParams
    local n = params.n
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
BeekEffect=class()

function BeekEffect:ctor(params,callback)
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
function BeekEffect:update(diff)
    if not self.allTime then
        self.allTime = 0 
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target)
        self.time = nil
        if self.mode == 1 then
            local hero = self.realAttacker.C
            hero.skillNum = hero.skillNum-1
            if hero.skillNum>0 then
                if hero:searchAddTarget() then
                    BeekEffect.new({realAttacker = self.realAttacker, attacker = self.target.avater or self.target, mode = 1, target = hero.skillTarget},self.callback)
                else
                    self.skillNum = nil
                    self.isAddGroup = nil
                end
            else
                self.skillNum = nil
                self.isAddGroup = nil
            end
        end
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end
function BeekEffect:initParams(params)
    self.effectManager=GameEffect.new("BeekEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.realAttacker = params.realAttacker
    self.direction = self.realAttacker.direction
    self.mode = params.mode
    self.viewsNode = self.realAttacker.scene.objs
    self.delayNode = self.realAttacker.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    self.total=params.total
    self.baseScal=params.scale or 1

    --起始点坐标
    if self.attacker.animaConfig then
        local x,y = 0,self.attacker.animaConfig.Ymove
        local p = {self.attacker.view:getPosition()}
        p[1] = p[1] + x
        p[2] = p[2] + y
        self.initPos = {p[1],p[2],General.sceneHeight - p[2]}
    else
        local view = self.attacker.view
        local height = view:getContentSize().height/2
        self.initPos = {view:getPositionX(),view:getPositionY() + height}
        self.initPos[3] = General.sceneHeight-self.initPos[2]
    end
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

function BeekEffect:initEffect()
  if self.mode==0 then
     self:initAttack()
  elseif self.mode==1 then
     self:initSkill()
  end
end

--普通攻击
function BeekEffect:initAttack()
    local setting={{58,-22},{117,51},{58,306},{-58,306},{-117,51},{-58,-22}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local delayNode=self.delayNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local targetPos=self.targetPos
    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time=moveTime

    local temp

    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+10000)
    moveNode:setScale(1.5)

    local function delayFrameIndex_44()
    moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"delay",11/60},"remove"}))
     effectManager:addEffect("views1_delay44",moveNode)
      temp=views.Sprite_21
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",2/60+moveTime},"remove"}))
      temp=views.Sprite_21_0
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,127},{"delay",moveTime},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",2/60+moveTime},"remove"}))
      temp=views.Glow_01_1
      temp:runAction(ui.action.sequence({{"delay",moveTime+1/60},{"scaleTo",5/60,0.3*1.5,0.3*1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,204},{"delay",moveTime},{"fadeTo",5/60,255},{"fadeTo",5/60,0}}))
      temp=views.Glow_01_2
      temp:runAction(ui.action.sequence({{"delay",moveTime+1/60},{"scaleTo",5/60,0.15*1.5,0.15*1.5}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime},{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",moveTime+11/60},"remove"}))
   end
   delayFrameIndex_44()
end
--技能攻击
function BeekEffect:initSkill()
    self.time = 36/60
    local setting={{20,114},{14,129},{-8,133},{8,133},{-14,129},{-20,114}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local delayNode=self.delayNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local temp

    local function delayFrameIndex_44()
    self:initSkill_move()

    effectManager:addEffect("views2_delay44",bg)
    temp=views.Sprite_20
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+10)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,0.7,0.7},{"scaleTo",15/60,0.25,0.25}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",10/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",21/60},"remove"}))
    end
    delayNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_44}}))

end
--技能攻击子弹
function BeekEffect:initSkill_move()
    local setting={{20,114},{14,129},{-8,133},{8,133},{-14,129},{-20,114}}
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+setting[direction][1]
    initPos[2]=self.initPos[2]+setting[direction][2]
    initPos[3]=self.initPos[3]
    local targetPos=self.targetPos
    local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
    local length=math.sqrt(moveX*moveX+moveY*moveY)
    local r=-math.deg(math.atan2(moveY,moveX))
    local temp


     effectManager:addEffect("views2_delay39",bg)
      temp=views.Trail_00000_11
      temp:setPosition(initPos[1],initPos[2])
      temp:setLocalZOrder(initPos[3]+10009)
      temp:setScaleY(1.5)
      temp:setScaleX(length/400)
      temp:setRotation(r)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",1/60,0}}))
    local function showTargetBao( )
    self:initSkill_target()
    end
    temp:runAction(ui.action.sequence({{"delay",32/60},{"call",showTargetBao},"remove"}))
end
--受击
function BeekEffect:initSkill_target()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local delayNode=self.delayNode
    local views=self.views
    local direction=self.direction
    local initPos=self.targetPos
    local temp

   local upNode=ui.node()
   upNode:setPosition(initPos[1],initPos[2])
   bg:addChild(upNode,initPos[3]+10)
   upNode:setScale(3.5)
   upNode:runAction(ui.action.sequence({{"delay",35/60},"remove"}))

    local function delayFrameIndex_50()
    effectManager:addEffect("views3_delay50",upNode)
    temp=views.Glow_02_13
    temp:runAction(ui.action.sequence({{"fadeTo",5/60,153},{"delay",20/60},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
    end
    delayFrameIndex_50()

    local function delayFrameIndex_54()
    effectManager:addEffect("views3_delay54",upNode)
    temp=views.Circle_R_00000_16
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",15/60,0.2,0.15}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",26/60},"remove"}))
    temp=views.Particle_1
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    temp=views.Particle_1_0
    temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
    end
    upNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_54}}))
end



return {M,V,C}
