

local M = class(AvtInfo)













local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end
    ThorEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end

local C = class(AvtControler)

--4010    雷神  主动技能26  对自身g格范围内所有敌方目标造成a+c%攻击力的伤害，并眩晕t秒，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local a,c,t = params.a,params.c,params.t
    local g = params.g
    local sgx, sgy = self.avater.gx,self.avater.gy
    local pointTab = {}
    for i,v in ipairs(self.battleMap.battlerAll) do
        local viewInfo = v.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(v)
        table.insert(pointTab,{viewInfo[1],viewInfo[2],viewInfo[3],v})
    end
    local result = Aoe.circlePoint(pointTab,{sgx,sgy},g)
    for k,v in ipairs(result) do
        SkillPlugin.exe2(self,v[4],a,c)
        SkillPlugin.exe3(v[4],t)
        ThorEffect.new({attacker = self.V, mode = 2, target = v[4],lastedTime=t},nil)
    end
end

--天神技 从附近的敌人身上吸取([a]+[x]%攻击力)的血量，在接下来的[t]秒内恢复自己。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    local r = 5
    local target = self:getCircleTarget(self.attackTarget,self.battleMap.battlerAll,r)
    local blood, allBlood  = ps.a+ps.x*self.M.atk/100, 0
    for _,v in ipairs(target) do
        if not v.deleted then
            SkillPlugin.exe2(self, v, blood, nil, nil, true)
            allBlood = allBlood + blood
        end
    end
    BuffUtil.setBuff(self, {lastAddHp = allBlood, lastedTime = ps.t})
end

function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    local ps = self.C.person.awakeData.ps
    ThorEffect.new({attacker = self, mode = 4, target = attackTarget, lastedTime=ps.t},callback)
end

--当英雄防御时，迫击炮增加[x]%攻击力，[y]%血量。每[d]次攻击造成[z]%的范围性伤害。并眩晕目标[t]秒。
function C:sg_updateBattle(diff)
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.build
        if DEBUG.DEBUG_GODSKILL2 then
            group = self.battleMap.build
        end
        for k,v in pairs(group) do
            if v.bid == 23 then
                v.M.nowHp = v.M.nowHp*(1+ps.y/100)
                v.M.maxHp = v.M.maxHp*(1+ps.y/100)
                v.M.atk = v.M.atk*(1+ps.x/100)
                BuffUtil.setBuff(v,{ps = ps},"ThorGodSkill2")
            end
        end
    end
end


----------------------------------------------------------------------------------------------------------------
ThorEffect = class()

function ThorEffect:ctor(params,callback)
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

function ThorEffect:initParams(params)
    self.effectManager = EffectMaker:getInstance()
    self.effectId = self.effectManager:registerGameEffect("game/GameEffect/effectsConfig/ThorEffect.json")

    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 2000
    self.target = params.target or params.attacker.C.attackTarget
    self.lastedTime = params.lastedTime

    --起始点坐标
    local x,y = 0,self.attacker.animaConfig.Ymove
    local p = {self.attacker.view:getPosition()}
    p[1] = p[1] + x
    p[2] = p[2] + y
    self.initPos = {p[1],p[2],General.sceneHeight - p[2]}

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
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function ThorEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:initSkill_target()
    elseif self.mode==4 then
        self.time = 1
        self:createViews_1()
        self:createViews_2()
        self:createViews_3()
    end
end

function ThorEffect:initAttack()
    self.time = 0
    local effectManager = self.effectManager
    local bg = self.viewsNode
    local direction=self.direction
    local initPos=self.targetPos
    initPos[3]=initPos[3]+10000

    effectManager:addGameEffect(bg, self.effectId, "views2_delay19", initPos[1], initPos[2], initPos[3])
end

local Skill_Setting={{74,-100},{182,-10},{100,104},{-100,104},{-182,-10},{-74,-100}}
function ThorEffect:initSkill()
    self.time = 0.1
    local effectManager = self.effectManager
    local bg = self.viewsNode
    local direction = self.direction
    local initPos = self.initPos
    local ox = Skill_Setting[direction][1]
    local oy = Skill_Setting[direction][2]
    local temp
    local scale = self.delayNode:getScale()
    self.delayNode:setScale(scale*1.5)

    effectManager:addGameEffect(bg, self.effectId, "Skill_Top", initPos[1], initPos[2], initPos[3])
    effectManager:addGameEffect(bg, self.effectId, "Skill_Weapon", initPos[1]+ox, initPos[2]+oy, initPos[3])

    effectManager:addGameEffect(bg, self.effectId, "views1_delay50", initPos[1], initPos[2], initPos[3])

    local function delayFrameIndex_54()
        effectManager:addGameEffect(bg, self.effectId, "views1_delay54", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_54}}))

    local function delayFrameIndex_55()
        effectManager:addGameEffect(bg, self.effectId, "views1_delay55", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",6/60},{"call",delayFrameIndex_55}}))

    local function delayFrameIndex_57()
        effectManager:addGameEffect(bg, self.effectId, "views1_delay57", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",8/60},{"call",delayFrameIndex_57}}))

    local function delayFrameIndex_59()
        effectManager:addGameEffect(bg, self.effectId, "views1_delay59", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_59}}))
    self.delayNode:setScale(scale)
end

local God_Setting1={{-4,183},{-69,152},{-69,97},{69,97},{69,152},{4,183}}
local God_Setting2={{99,-63},{213,75},{114,208},{-114,208},{-213,75},{-99,-63}}
--攻击
function ThorEffect:createViews_1()
    local effectManager = self.effectManager
    local bg = self.viewsNode
    local direction=self.direction

    local initPos = self.initPos
    local targetPos=self.targetPos

    local temp

    local atNode=ui.node()
    atNode:setScale(1.3)
    bg:addChild(atNode, initPos[3]+10000)
    atNode:runAction(ui.action.sequence({{"delay",50/60},"remove"}))

    effectManager:addGameEffect(bg, self.effectId, "godSkill_views1_delay0", initPos[1], initPos[2], initPos[3])

    local function delayFrameIndex_9()
        local ox = God_Setting1[direction][1]
        local oy = God_Setting1[direction][2]
        atNode:setPosition(initPos[1]+ox,initPos[2]+oy)
        effectManager:addGameEffect(atNode, self.effectId, "godSkill_views1_delay9", 0, 0, 0)
    end
    atNode:runAction(ui.action.sequence({{"delay",9/60},{"call",delayFrameIndex_9}}))

    local function delayFrameIndex_19()
        local ox = God_Setting2[direction][1]
        local oy = God_Setting2[direction][2]
        atNode:setPosition(initPos[1]+ox,initPos[2]+oy)

        local moveX,moveY=targetPos[1]-initPos[1]-ox,targetPos[2]-initPos[2]-oy
        local length=math.sqrt(moveX*moveX+moveY*moveY)
        local baseScale=length/256
        local r=-math.deg(math.atan2(moveY,moveX))
        atNode:setRotation(r)

        effectManager:addGameEffect(atNode, self.effectId, "godSkill_views1_delay19", 0, 0, 0)
   end
   atNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_19}}))
end
--受击
function ThorEffect:createViews_2()
    local effectManager=self.effectManager
    local bg = self.viewsNode
    local direction=self.direction
    local initPos=self.targetPos

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    bg:addChild(upNode, initPos[3]+10000)
    upNode:setScale(1.3)
    upNode:runAction(ui.action.sequence({{"delay",60/60},"remove"}))

    local function delayFrameIndex_22()
        effectManager:addGameEffect(upNode, self.effectId, "godSkill_views2_delay22", 0, 0, 0)
    end
    upNode:runAction(ui.action.sequence({{"delay",22/60},{"call",delayFrameIndex_22}}))
end

--回血
function ThorEffect:createViews_3()
    local effectManager=self.effectManager
    local bg = self.attacker.view
    local direction = self.direction
    local initPos = {0,0,10}

    local total = self.lastedTime

    local upNode = ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(1.5)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",total},{"fadeTo",10/60,0},"remove"}))

    effectManager:addGameEffect(upNode, self.effectId, "godSkill_views3_delay0", 0, 0, 0)
end

--主动晕眩
function ThorEffect:initSkill_target()
    local effectManager=self.effectManager
    local ox,oy=0,0
    local bg
    if self.target.avater then
        bg=self.target.avater.view
        oy=120
    elseif self.target.vstate.build and self.target.vstate.upNode then
        bg=self.target.vstate.upNode
        ox,oy=self.target.vstate.view:getContentSize().width/2, self.target:getHeight()+80
    else
        return
    end
    local total = self.target.avtInfo.bfDizziness
    if total <= 0 then
        return
    end

    local upNode = ui.node()
    upNode:setPosition(0,120)
    bg:addChild(upNode,10)
    upNode:runAction(ui.action.sequence({{"delay",total},"remove"}))

    effectManager:addGameEffect(upNode, self.effectId, "skill_views3_delay0", 0, 0, 0)
end


function ThorEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        if self.callback then
            self.callback(self.target)
        end
        self.time = nil
        self.scene.replay:removeUpdateObj(self)
    end
end

return {M,V,C}




























