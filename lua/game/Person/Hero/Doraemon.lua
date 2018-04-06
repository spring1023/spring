
local M = class(AvtInfo)

local V = {}
--5格内，弹射式对敌方[n]个目标造成[a]+[c]%*攻击力的伤害，消耗[x]怒，冷却时间[z]秒
function V:viewEffect(attackTarget,callback,isSkill)

    local mode = 0
    if isSkill then
        mode = 1
    end
    DoraemonEffect.new({realAttacker = self,attacker = self, mode = mode, target = attackTarget},callback)
end
function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    DoraemonEffect.new({realAttacker = self,attacker = self, mode = 4, target = attackTarget},callback)
end

local C = class(AvtControler)

function C:sg_ppexeSkill(target)
    self.isAddGroup = {}
    if self:searchAddTarget() then
        self.isSkillAttack = true
        self.isSkillNotAttack = true
        self.skillNum = self.actSkillParams.n
        self.allSkillNum = self.actSkillParams.n
    end
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local a,c = params.a,params.c
    return SkillPlugin.exe2(self,target,a,c)
end

function C:searchAddTarget(again)
    local params = self.actSkillParams
    local a,c,n = params.a,params.c,params.n
    local allBuilds = self.battleMap.hero
    if again then
        allBuilds = self.battleMap.battler
    end
    local sgx, sgy = self.avater.gx,self.avater.gy

    local target

    local minDs = 5.1^2
    if not next(self.isAddGroup) then
        minDs = 1000000
    end

    for i,v in ipairs(allBuilds) do
        if not self.isAddGroup[v] then
            local gx,gy = self.avater.gx,self.avater.gy
            local sk = self.skillTarget
            if sk then
                if sk.avater then
                    gx,gy = sk.avater.gx,sk.avater.gy
                else
                    gx,gy = sk.battleViewInfo[1],sk.battleViewInfo[2]
                end
            end
            local ds

            ds = self:getSoldierDistance(gx,gy,v)

            if ds < minDs then
                target = v
                minDs = ds
            end
        end
    end

    if target then
        if self.skillNum == self.actSkillParams.n then
            self.skillTarget = target
        else
            self.skillTarget = target
        end
        self.isAddGroup[target] = 1
        return true
    else
        if not again then
            return self:searchAddTarget(true)
        else
            return false
        end
    end
end

--天神技 发射一个火球，对目标极其周围造成([a]+[x]%攻击力)的伤害，并在[t]秒内造成[b]的流血伤害。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    local target = self:getCircleTarget(self.attackTarget,self.battleMap.battlerAll,3)
    for k,v in ipairs(target) do
        SkillPlugin.exe2(self,v,ps.a,ps.x)
        BuffUtil.setBuff(v,{lastAddHp = -ps.b/ps.t,lastedTime = ps.t})
    end
end

--当英雄防御时，电塔增加[x]%攻击，[y]%血量。每[d]次攻击造成[z]%的半径[n]格的范围性伤害。
function C:sg_updateBattle(diff)
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.build
        if DEBUG.DEBUG_GODSKILL2 then
            group = self.battleMap.build
        end
        for k,v in pairs(group) do
            if v.bid == 26 then
                v.M.nowHp = v.M.nowHp*(1+ps.y/100)
                v.M.maxHp = v.M.maxHp*(1+ps.y/100)
                v.M.atk = v.M.atk*(1+ps.x/100)
                BuffUtil.setBuff(v,{d= ps.d, z=ps.z, n=ps.n},"DoraemonGodSkill2")
            end
        end
    end
end

----------------------------------------------------------------------
DoraemonEffect = class()

function DoraemonEffect:ctor(params,callback)
    self.scene = GMethod.loadScript("game.View.Scene")
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    if self.scene.replay then
        self.scene.replay:addUpdateObj(self)
    else
        RegUpdate(function(diff)
            self.updateMy(diff)
        end,0)
    end
end

function DoraemonEffect:initParams(params)
    self.effectManager=GameEffect.new("DoraemonEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.delayNode = self.scene.delayNode
    self.realAttacker = params.realAttacker
    self.direction = self.realAttacker.direction
    self.mode = params.mode
    self.viewsNode = self.realAttacker.scene.objs
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget
    
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
    else
        view = self.target.view
        height = view:getContentSize().height/2
        self.targetZ = 0
    end
    self.targetView=view
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function DoraemonEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:createSkillMove()
    elseif self.mode == 4 then
        self:initGodSkill()
    end
end

function DoraemonEffect:initAttack()
    local setting={{58,-33},{92,47},{65,98},{-65,98},{-92,47},{-58,-33}}
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
    local r=-math.deg(math.atan2(moveY,moveX))
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime
    local temp
    local function delayFrameIndex_9()

    effectManager:addEffect("views3_delay9",bg)
    temp=views.Sprite_10_0
    temp:setRotation(-90+r)
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_30_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_30_0_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end
    delayFrameIndex_9()

    local function delayFrameIndex_24_bao()
    effectManager:addEffect("views3_delay24",bg)
    temp=views.Glow_01_9_b
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+6)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,1.0,1.0}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,179},{"fadeTo",5/60,178},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_9_0_b
    temp:setPosition(targetPos[1],targetPos[2])
    temp:setLocalZOrder(targetPos[3]+7)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",6/60,0.5,0.5}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,179},{"fadeTo",5/60,178},{"fadeTo",5/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end

    local function delayFrameIndex_9_move()
    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+10000)
    moveNode:setRotation(r)
    moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",delayFrameIndex_24_bao},"remove"}))
    effectManager:addEffect("views3_delay9_move",moveNode)
    temp=views.Bullet_8_m
    temp:setPosition(0,0)
    temp:setLocalZOrder(1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Normal_6_m
    temp:setPosition(0,0)
    temp:setLocalZOrder(2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Glow_01_12_0_0_m
    temp:setPosition(0,0)
    temp:setLocalZOrder(8)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,165},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    temp=views.Glow_01_12_1_m
    temp:setPosition(0,0)
    temp:setLocalZOrder(9)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,165},{"delay",moveTime-2/60},{"fadeTo",1/60,0}}))
    end
    delayFrameIndex_9_move()
end

function DoraemonEffect:initSkill()
    local setting={{67,-48},{144,43},{86,140},{-86,140},{-144,43},{-67,-48}}
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
    local r=-math.deg(math.atan2(moveY,moveX))
    local temp

    local function delayFrameIndex_54()
    self:createSkillMove()

    effectManager:addEffect("views1_delay54",bg)
    temp=views.Sprite_10
    temp:setRotation(-90+r)
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_30
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    temp=views.Glow_01_30_0
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",9/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
    end
    delayFrameIndex_54()
end

--技能攻击移动
function DoraemonEffect:createSkillMove()
    local setting={{58,-33},{92,47},{65,98},{-65,98},{-92,47},{-58,-33}}
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
    local r=-math.deg(math.atan2(moveY,moveX))
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime
    local temp
    local function showTargetBao( )
    self:createViews_2()
    end
    local moveNode=ui.node()
    moveNode:setPosition(initPos[1],initPos[2])
    bg:addChild(moveNode,initPos[3]+10000)
    moveNode:setRotation(r)
    moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))

    effectManager:addEffect("views1_delay60",moveNode)
    temp=views.Bullet_11_move
    temp:setPosition(0,0)
    temp:setLocalZOrder(4)
    temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",10/60,5.0,5.0}}))
    effectManager:addEffect("views1_delay0",bg)
    temp=views.Skill_6_move
    temp:setPosition(0,0)
    temp:setLocalZOrder(5)
    temp=views.Glow_01_12_move
    temp:setPosition(0,0)
    temp:setLocalZOrder(6)
    temp=views.Glow_01_12_0_move
    temp:setPosition(0,0)
    temp:setLocalZOrder(7)
end

--技能攻击到爆炸
function DoraemonEffect:createViews_2()
    local effectManager=self.effectManager
    local bg=self.viewsNode
    local views=self.views
    local direction=self.direction
    local initPos=self.targetPos
    local temp

    effectManager:addEffect("views2_delay69",bg)
    temp=views.Fire_Impact_00000_15_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+1)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    temp=views.Glow_01_32_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+2)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"fadeTo",31/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    temp=views.Glow_01_32_0_111
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+3)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",3/60},{"fadeTo",6/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
    temp=views.Fire_Impact_00000_15_112
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+4)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",30/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    temp=views.Glow_01_32_112
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+5)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"fadeTo",31/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
    temp=views.Glow_01_32_0_112
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+6)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",3/60},{"fadeTo",6/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
    temp=views.Shockwave_1
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+7)
    temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",5/60,1.2,0.9},{"scaleTo",5/60,1.5,1.125}}))
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",5/60},{"fadeTo",6/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",12/60},"remove"}))
    temp=views.Sparkless_00000_4
    temp:setPosition(initPos[1],initPos[2])
    temp:setLocalZOrder(initPos[3]+8)
    temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",14/60},{"fadeTo",1/60,0}}))
    temp:runAction(ui.action.sequence({{"delay",16/60},"remove"}))
end

function DoraemonEffect:initGodSkill()
   local setting={{67,-48},{144,43},{86,140},{-86,140},{-144,43},{-67,-48}}
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.initPos[1]+setting[direction][1]
   initPos[2]=self.initPos[2]+setting[direction][2]
   initPos[3]=self.initPos[3]
   local targetPos={}
   targetPos[1]=self.targetPos[1]
   targetPos[2]=self.targetPos[2]
   targetPos[3]=self.targetPos[3]

   local moveX,moveY=targetPos[1]-initPos[1],targetPos[2]-initPos[2]
   local r=-math.deg(math.atan2(moveY,moveX))
    local moveTime=math.sqrt(moveX^2+moveY^2)/self.speed
    self.time = moveTime
   local temp

   local rs={45,0,-45,-135,-180,135}
   local atNode=ui.node()
   atNode:setPosition(initPos[1],initPos[2])
   bg:addChild(atNode,initPos[3]+2)
   atNode:setRotation(rs[direction])
   atNode:setScale(1.5)
   atNode:runAction(ui.action.sequence({{"delay",18/60},"remove"}))
   local function delayFrameIndex_9()
     effectManager:addEffect("godSkill_views1_delay9",atNode)
      temp=views.Sprite_9_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:setRotation(-90)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",15/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",17/60},"remove"}))

      temp=views.pirate_bqqh_00031_10_0_1
      temp:setPosition(-20,0)
      temp:setLocalZOrder(3)
      temp:setRotation(-90)
      temp:runAction(ui.action.sequence({{"delay",8/60},{"scaleTo",3/60,0.38,0.45}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",3/60},{"fadeTo",4/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
      temp=views.pirate_bqqh_00031_10_1
      temp:setPosition(-20,0)
      temp:setLocalZOrder(4)
      temp:setRotation(-90)
      temp:runAction(ui.action.sequence({{"delay",4/60},{"scaleTo",7/60,0.38,0.33}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",2/60},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",11/60},"remove"}))
   end
   delayFrameIndex_9()

   local function delayFrameIndex_10()
     effectManager:addEffect("godSkill_views1_delay10",atNode)
      local rs={45,0,-45,-135,-180,135}
      temp=views.Strike_00000_4_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,255},{"delay",12/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",14/60},"remove"}))
      temp=views.Glow_01_2_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.5,0.5},{"scaleTo",5/60,0.65,0.65}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,86},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
      temp=views.Glow_01_2_0_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.5,0.5},{"scaleTo",5/60,0.65,0.65}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,207},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
      temp=views.Glow_01_2_0_0_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"scaleTo",5/60,0.5,0.5},{"scaleTo",5/60,0.65,0.65}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,43},{"fadeTo",5/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",10/60},"remove"}))
   end
   delayFrameIndex_10()

   local moveNode=ui.node()
   moveNode:setPosition(initPos[1],initPos[2])
   bg:addChild(moveNode,initPos[3]+10000)
   moveNode:setRotation(r)
   moveNode:setVisible(false)
   effectManager:addEffect("godSkill_views2_delay13",moveNode)
   local function delayFrameIndex_13()
      local function showTargetBao( )
         self:initGodSkill_target()
      end
      moveNode:setVisible(true)
      moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,moveX,moveY},{"call",showTargetBao},"remove"}))
      temp=views.Particle_1_1
      temp:setPosition(-50,-4)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",2/60},{"scaleTo",2/60,1.0,1.0}}))
      temp=views.Particle_2_1
      temp:setPosition(-50,-4)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"delay",2/60},{"scaleTo",2/60,1.0,1.0}}))
      temp=views.Poison_1_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:setRotation(-90)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",2/60,255}}))
      temp=views.Particle_2_0_1
      temp:setPosition(-50,-4)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",2/60,1.0179,0.7}}))
   end
   moveNode:runAction(ui.action.sequence({{"delay",4/60},{"call",delayFrameIndex_13}}))
end

function DoraemonEffect:initGodSkill_target()
   local effectManager=self.effectManager
   local bg=self.viewsNode
   local views=self.views
   local direction=self.direction
   local initPos={}
   initPos[1]=self.targetPos[1]
   initPos[2]=self.targetPos[2]
   initPos[3]=self.targetPos[3]
   local total=30/60--状态燃烧持续时间
   local temp

   local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode,initPos[3]+10000)
    upNode:setScale(3)
    upNode:runAction(ui.action.sequence({{"delay",62/60},"remove"}))

   local function delayFrameIndex_29()
     effectManager:addEffect("godSkill_views3_delay29",upNode)
      temp=views.Sparkless_00000_6
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",3/60,255},{"delay",18/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Impact_00000_13
      temp:setPosition(0,0)
      temp:setLocalZOrder(8)
      temp:runAction(ui.action.sequence({{"delay",6/60},{"scaleTo",4/60,2,2},{"scaleTo",1/60,2.275,2.275}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,108},{"fadeTo",3/60,255},{"delay",47/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",52/60},"remove"}))
      temp=views.Glow_01_7
      temp:setPosition(0,0)
      temp:setLocalZOrder(9)
      temp:runAction(ui.action.sequence({{"delay",3/60},{"scaleTo",3/60,0.7,0.7},{"scaleTo",25/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,101},{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
      temp=views.Glow_01_7_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(10)
      temp:runAction(ui.action.sequence({{"delay",3/60},{"scaleTo",3/60,0.6,0.6},{"scaleTo",25/60,1.0,1.0}}))
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",1/60,104},{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",31/60},"remove"}))
   

   end
   delayFrameIndex_29()

   local function delayFrameIndex_30()
     effectManager:addEffect("godSkill_views3_delay30",upNode)
      temp=views.Glow_01_3
      temp:setPosition(0,0)
      temp:setLocalZOrder(2)
      temp:runAction(ui.action.sequence({{"scaleTo",8/60,1.0,1.0},{"scaleTo",32/60,1.5,1.5}}))
      temp:runAction(ui.action.sequence({{"fadeTo",8/60,255},{"delay",12/60},{"fadeTo",20/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",40/60},"remove"}))
   end
   delayFrameIndex_30()

   local function delayFrameIndex_31()
     effectManager:addEffect("godSkill_views3_delay31",upNode)
      temp=views.Electricity_Explosion
      temp:setPosition(0,0)
      temp:setLocalZOrder(6)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"fadeTo",2/60,153},{"fadeTo",54/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",56/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",2/60},{"call",delayFrameIndex_31}}))

   local function delayFrameIndex_34()
     effectManager:addEffect("godSkill_views3_delay34",upNode)
      temp=views.Shockwave_00000_14
      temp:setPosition(0,0)
      temp:setLocalZOrder(3)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",15/60,1.6,1.4},{"scaleTo",15/60,1.8,1.7}}))
      temp:runAction(ui.action.sequence({{"fadeTo",6/60,255},{"delay",20/60},{"fadeTo",6/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",32/60},"remove"}))
      temp=views.Shockwave_00000_15
      temp:setPosition(0,0)
      temp:setLocalZOrder(4)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.6,1.4},{"scaleTo",10/60,1.8,1.7}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",17/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))
      temp=views.Shockwave_00000_15_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(5)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.6,1.4},{"scaleTo",10/60,1.8,1.7}}))
      temp:runAction(ui.action.sequence({{"fadeTo",4/60,255},{"delay",17/60},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",22/60},"remove"}))

      temp=views.barbarian_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,2.2,1.98}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,204},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
      temp=views.barbarian_1_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(7)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,2.2,1.98}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",10/60},{"fadeTo",15/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))

   end
   upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_34}}))

   local function delayFrameIndex_40()
     effectManager:addEffect("godSkill_views3_delay40",upNode)
      temp=views.Glow_01_1
      temp:setPosition(0,0)
      temp:setLocalZOrder(1)
      temp:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",5/60,1.2,1.2}}))
      temp:runAction(ui.action.sequence({{"fadeTo",5/60,255},{"delay",15/60},{"fadeTo",10/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",30/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",11/60},{"call",delayFrameIndex_40}}))

   local function delayFrameIndex_42()
     effectManager:addEffect("godSkill_views3_delay42",upNode)
      temp=views.Electricity_Explosion_0
      temp:setPosition(0,0)
      temp:setLocalZOrder(13)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,126},{"fadeTo",5/60,255},{"fadeTo",40/60,214},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",47/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",13/60},{"call",delayFrameIndex_42}}))

   local function delayFrameIndex_44()
     effectManager:addEffect("godSkill_views3_delay44",upNode)
      temp=views.NanGuan_00000_20
      temp:setPosition(0,0)
      temp:setLocalZOrder(12)
      temp:runAction(ui.action.sequence({{"delay",1/60},{"scaleTo",10/60,1.6,1.8},{"scaleTo",17/60,2.0,2.1}}))
      temp:runAction(ui.action.sequence({{"fadeTo",9/60,159},{"fadeTo",2/60,132},{"fadeTo",17/60,0},{"delay",1/60}}))
      temp:runAction(ui.action.sequence({{"delay",7/60},{"moveBy",21/60,0,11}}))
      temp:runAction(ui.action.sequence({{"delay",29/60},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_44}}))

   local function delayFrameIndex_59()
     effectManager:addEffect("godSkill_views3_delay59",upNode)
      temp=views.Fire_00000_19
      temp:setPosition(0,0)
      temp:setLocalZOrder(13)
      temp:runAction(ui.action.sequence({{"fadeTo",1/60,68},{"fadeTo",total/2-1/60,255},{"fadeTo",total/2-1/60,127},{"fadeTo",1/60,0}}))
      temp:runAction(ui.action.sequence({{"delay",total},"remove"}))
   end
   upNode:runAction(ui.action.sequence({{"delay",30/60},{"call",delayFrameIndex_59}}))
end

function DoraemonEffect:update(diff)
    if not self.allTime then
        self.allTime = 0 
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        local hero = self.realAttacker.C
        self.callback(self.target)
        local isFirst = false
        if hero.skillNum == hero.allSkillNum then
            isFirst = true
        end
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
        --链式伤害
        if self.mode == 1 or self.mode == 2 then
            if not hero.skillNum then
                return
            end
            hero.skillNum = hero.skillNum-1
            if hero.skillNum>0 then
                if hero:searchAddTarget() then
                    if isFirst then
                        music.play("sounds/" .. hero.avater.animaConfig.skill_music11)
                    else
                        music.play("sounds/" .. hero.avater.animaConfig.skill_music12)
                    end
                    DoraemonEffect.new({realAttacker = self.realAttacker,attacker = self.target.avater or self.target, mode = 2, target = hero.skillTarget},self.callback)
                else
                    music.play("sounds/" .. hero.avater.animaConfig.skill_music13)
                    hero.skillNum = nil
                    hero.isAddGroup = nil
                end
            else
                music.play("sounds/" .. hero.avater.animaConfig.skill_music13)
                hero.skillNum = nil
                hero.allSkillNum = nil
                hero.isAddGroup = nil
            end
        end
    end
end


return {M,V,C}



















