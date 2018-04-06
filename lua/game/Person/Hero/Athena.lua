

local M = class(AvtInfo)













local V = {}
function V:viewEffect(attackTarget,callback,isSkill)
    local mode = 0
    if isSkill then
        mode = 1
    end

    AthenaEffect.new({attacker = self, mode = mode, target = attackTarget},callback)
end


local C = class(AvtControler)

--4009    雅典娜     4019    主动技能25  回复本方所有单位a+c%*攻击力的血量，消耗x怒，冷却时间z秒
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

function C:sg_exeSkill(target)
    local params = self.actSkillParams
    local a,c = params.a,params.c

    for i,v in ipairs(self.battleMap2.battler) do
        if v.V then
            local value = BattleUtil.getHeal(self,v,a,c)
            v:damage(value)
            if value < 0 then
                LogicEffects.HeroEffect:runAnimation(AthenaEffect, self, v, {attacker = self.V, mode = 2, target = v})
            end
            --AthenaEffect.new({attacker = self.V, mode = 2, target = v})
        end
    end
end

--天神技  冻结所有地面单位，并增强己方空中单位攻击速度[x]%，移动速度[y]%，持续[t]秒。
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    local ps = self.person.awakeData.ps
    for i,v in ipairs(self.battleMap.battler) do
        if v.M.utype == 1 then
            if v.vstate then
                if v.info.btype == 2 then
                    AthenaEffect.new({attacker = self.V, mode = 5, target = v, lastedTime=ps.t})
                    BuffUtil.setBuff(v,{lastedTime = ps.t,bfDizziness = ps.t})
                end
            else
                AthenaEffect.new({attacker = self.V, mode = 5, target = v, lastedTime=ps.t})
                BuffUtil.setBuff(v,{lastedTime = ps.t,bfDizziness = ps.t})
            end
        end
    end
    for i,v in ipairs(self.battleMap2.battler) do
        if v.M.utype == 2  then
            BuffUtil.setBuff(v,{lastedTime = ps.t,bfMovePct = ps.y,bfAtkSpeedPct = ps.x})
        end
    end

end


function V:godSkillViewEffect(attackTarget,callback,skillLastTimeAll)
    AthenaEffect.new({attacker = self, mode = 4, target = attackTarget},callback)
end

--防守时，增加爱国者[x]%的攻击力，[y]%的血量。爱国者每[d]次攻击，就对[m]个空中单位造成[z]%的伤害。
function C:sg_updateBattle(diff)
    if self.deleted then
        return
    end
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.build
        for k,v in ipairs(group) do
            if v.bid == 24 then
                v.M.nowHp = v.M.nowHp*(1+ps.y/100)
                v.M.maxHp = v.M.maxHp*(1+ps.y/100)
                v.M.atk = v.M.atk*(1+ps.x/100)
                BuffUtil.setBuff(v,{d= ps.d,m=ps.m,z=ps.z},"AthenaGodSkill2")
            end
        end
    end
end


AthenaEffect = class()

function AthenaEffect:ctor(params,callback)
    self.scene = GMethod.loadScript("game.View.Scene")
    self.callback = callback
    self:initParams(params)
    self:initEffect()
    -- 纯显示的效果不要占用update队列
    if self.scene.replay and self.mode ~= 2 then
        self.scene.replay:addUpdateObj(self)
    end
end

function AthenaEffect:initParams(params)
    self.effectManager = EffectMaker:getInstance()
    self.effectId = self.effectManager:registerGameEffect("game/GameEffect/effectsConfig/AthenaEffect.json")
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
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
    self.targetView=view
    self.targetPos = {view:getPositionX(),view:getPositionY() + height}
    if self.target.viewInfo then
        self.targetPos[2] = self.targetPos[2] + self.target.viewInfo.y
    end
    self.targetPos[3] = General.sceneHeight-self.targetPos[2]+self.targetZ
end

function AthenaEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    elseif self.mode == 1 then
        self:initSkill()
    elseif self.mode == 2 then
        self:initSkillTarget()
    elseif self.mode == 4 then
        self:initGodSkill()
        self:createViews_2()
    elseif self.mode == 5 then
        self:createViews_3()
    end
end

local Attack_Setting = {{58,-36},{130,42},{66,124},{-50,80},{-90,22},{-43,-28}}
function AthenaEffect:initAttack()
    local effectManager = self.effectManager
    local effectId = self.effectId
    local bg = self.viewsNode
    local direction = self.direction
    local initPos = self.initPos
    initPos[1] = initPos[1]+Attack_Setting[direction][1]
    initPos[2] = initPos[2]+Attack_Setting[direction][2]
    local moveTime = math.sqrt((self.targetPos[1]-initPos[1])^2+(self.targetPos[2]-initPos[2])^2)/self.speed
    self.time = moveTime + 39/60

    local function delayFrameIndex_49()
        local moveNode=ui.node()
        moveNode:setScale(1.5)
        moveNode:setPosition(initPos[1],initPos[2])
        bg:addChild(moveNode,initPos[3]+10000)

        --旋转
        local ox=self.targetPos[1]-initPos[1]
        local oy=self.targetPos[2]-initPos[2]
        local r=math.deg(math.atan2(ox, oy))
        moveNode:setRotation(r)
        moveNode:runAction(ui.action.sequence({{"moveBy",moveTime,ox,oy},"remove"}))

        effectManager:addGameEffect(moveNode, effectId, "views2_delay49", 0, 0, 0)
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",39/60},{"call",delayFrameIndex_49}}))

    local function delayFrameIndex_44()
        effectManager:addGameEffect(bg, effectId, "views2_delay44", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",34/60},{"call",delayFrameIndex_44}}))

    local function delayFrameIndex_39()
        effectManager:addGameEffect(bg, effectId, "views2_delay39", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",29/60},{"call",delayFrameIndex_39}}))
end

function AthenaEffect:initSkill()
    self.time = 0.6
    local effectManager = self.effectManager
    local effectId = self.effectId
    local bg = self.attacker.view
    local initPos={0, self.attacker.animaConfig.Ymove, 0}

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(1.5)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",88/60},"remove"}))

    local downNode=ui.node()
    downNode:setPosition(initPos[1],initPos[2])
    downNode:setScale(1.5)
    bg:addChild(downNode,initPos[3]-10)
    downNode:runAction(ui.action.sequence({{"delay",88/60},"remove"}))

    effectManager:addGameEffect(upNode, effectId, "views1_delay44", 0, 0, 0)
    effectManager:addGameEffect(upNode, effectId, "views1_delay45", 0, 0, 0)

    local function delayFrameIndex_49()
        effectManager:addGameEffect(upNode, effectId, "views1_delay49", 0, 0, 0)
    end
    upNode:runAction(ui.action.sequence({{"delay",5/60},{"call",delayFrameIndex_49}}))

    local function delayFrameIndex_84()
        effectManager:addGameEffect(downNode, effectId, "views1_delay84", 0, 0, 0)
    end
    downNode:runAction(ui.action.sequence({{"delay",40/60},{"call",delayFrameIndex_84}}))

    local function delayFrameIndex_54()
        effectManager:addGameEffect(downNode, effectId, "views1_delay84", 0, 0, 0)
        effectManager:addGameEffect(upNode, effectId, "views1_delay54_up", 0, 0, 0)
    end
    downNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_54}}))
end

function AthenaEffect:initSkillTarget()
    if not self.target or self.target.deleted then
        return
    end
    local effectManager = self.effectManager
    local effectId = self.effectId
    local bg = self.targetView
    local oy = 0
    local baseScal = 1.5

    if self.target.avater then
        oy=self.target.avater.animaConfig.Ymove
        if self.target.sid>=100 and self.target.sid<=700 then
            baseScal=0.3
        end
    elseif self.target.view then
        oy= self.target.view:getContentSize().height/2
        baseScal=1
    end
    local initPos={0,oy,0}
    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(baseScal)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",88/60},"remove"}))

    local downNode=ui.node()
    downNode:setPosition(initPos[1],initPos[2])
    downNode:setScale(baseScal)
    bg:addChild(downNode,initPos[3]-10)
    downNode:runAction(ui.action.sequence({{"delay",88/60},"remove"}))

    local function delayFrameIndex_34()
        effectManager:addGameEffect(upNode, effectId, "views1_delay34", 0, 0, 0)
    end
    upNode:runAction(ui.action.sequence({{"delay",0/60},{"call",delayFrameIndex_34}}))
    local function delayFrameIndex_45()
        effectManager:addGameEffect(upNode, effectId, "views1_delay45", 0, 0, 0)
    end
    upNode:runAction(ui.action.sequence({{"delay",1/60},{"call",delayFrameIndex_45}}))

    local function delayFrameIndex_84()
        effectManager:addGameEffect(downNode, effectId, "views1_delay84", 0, 0, 0)
    end
    downNode:runAction(ui.action.sequence({{"delay",40/60},{"call",delayFrameIndex_84}}))

    local function delayFrameIndex_54()
        effectManager:addGameEffect(downNode, effectId, "views1_delay84", 0, 0, 0)
        effectManager:addGameEffect(upNode, effectId, "views1_delay54_up", 0, 0, 0)
    end
    upNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_54}}))
end

local God_Setting = {{-50,-7,0},{-10,-31,-45},{44,-20,-90},{-44,-20,-90},{10,-31,-45},{50,-7,0}}
function AthenaEffect:initGodSkill()
    self.time = 1.5
    local effectManager = self.effectManager
    local effectId = self.effectId
    local bg = self.viewsNode
    local direction=self.direction
    local initPos={}
    initPos[1]=self.initPos[1]+God_Setting[direction][1]
    initPos[2]=self.initPos[2]+God_Setting[direction][2]
    initPos[3]=self.initPos[3]
    local r = God_Setting[direction][3]

    effectManager:addGameEffect(bg, effectId, "godSkill_views1_delay0", initPos[1], initPos[2], initPos[3])
    local temp = bg:getChildByName("godNodeAthena")
    if not temp then
        print("error add god athena")
        return
    end
    if direction>3 then
        temp:setScaleX(-2)
    end
    temp:setRotation(r)
end

function AthenaEffect:createViews_2()
    local effectManager = self.effectManager
    local effectId = self.effectId
    local bg = self.viewsNode
    local direction=self.direction
    local initPos=self.initPos

    local upNode=ui.node()
    upNode:setPosition(initPos[1],initPos[2])
    upNode:setScale(1.5)
    bg:addChild(upNode,initPos[3]+10)
    upNode:runAction(ui.action.sequence({{"delay",120/60},"remove"}))

    local downNode=ui.node()
    downNode:setPosition(initPos[1],initPos[2])
    downNode:setScale(1.5)
    bg:addChild(downNode,initPos[3]-10)
    downNode:runAction(ui.action.sequence({{"delay",120/60},"remove"}))

    local function delayFrameIndex_49()
        effectManager:addGameEffect(upNode, effectId, "godSkill_views2_delay49", 0, 0, 0)
        effectManager:addGameEffect(downNode, effectId, "godSkill_views2_delay49_down", 0, 0, 0)
    end
    upNode:runAction(ui.action.sequence({{"delay",49/60},{"call",delayFrameIndex_49}}))

    local function delayFrameIndex_50()
        effectManager:addGameEffect(downNode, effectId, "godSkill_views2_delay50", 0, 0, 0)
    end
    downNode:runAction(ui.action.sequence({{"delay",50/60},{"call",delayFrameIndex_50}}))

    local function delayFrameIndex_59()
        effectManager:addGameEffect(upNode, effectId, "godSkill_views2_delay59", 0, 0, 0)
    end
    upNode:runAction(ui.action.sequence({{"delay",59/60},{"call",delayFrameIndex_59}}))

    local function delayFrameIndex_40()
        effectManager:addGameEffect(upNode, effectId, "godSkill_views2_delay40", 0, 0, 0)
    end
    upNode:runAction(ui.action.sequence({{"delay",40/60},{"call",delayFrameIndex_40}}))
end

function AthenaEffect:createViews_3()
    local effectManager = self.effectManager
    local effectId = self.effectId
    local bg = self.attacker.scene.effects
    local direction = self.direction
    local initPos = self.targetPos
    local total=self.lastedTime-1.8

    effectManager:addGameEffect(bg, effectId, "godSkill_views3_delay55", initPos[1], initPos[2], initPos[3])
    
    local function delayFrameIndex_65()
        effectManager:addGameEffect(bg, effectId, "godSkill_views3_delay65", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",10/60},{"call",delayFrameIndex_65}}))

    local function delayFrameIndex_70()
        effectManager:addGameEffect(bg, effectId, "godSkill_views3_delay70", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",15/60},{"call",delayFrameIndex_70}}))

    local function delayFrameIndex_74()
        effectManager:addGameEffect(bg, effectId, "godSkill_views3_delay70", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",19/60},{"call",delayFrameIndex_74}}))

    local function delayFrameIndex_75()
        effectManager:addGameEffect(bg, effectId, "godSkill_views3_delay75", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",20/60},{"call",delayFrameIndex_75}}))

    local function delayFrameIndex_80()
        effectManager:addGameEffect(bg, effectId, "godSkill_views3_delay80", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",25/60},{"call",delayFrameIndex_80}}))

    local function delayFrameIndex_144()
        effectManager:addGameEffect(bg, effectId, "godSkill_views3_delay144", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",89/60},{"call",delayFrameIndex_144}}))

    local function delayFrameIndex_159()
        effectManager:addGameEffect(bg, effectId, "godSkill_views3_delay159", initPos[1], initPos[2], initPos[3])
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",104/60},{"call",delayFrameIndex_159}}))

    local function delayFrameIndex_175()
        local buffNode = ui.node()
        display.adapt(buffNode, initPos[1], initPos[2])
        bg:addChild(buffNode, initPos[3]+14)
        effectManager:addGameEffect(buffNode, effectId, "godSkill_views3_delay175", 0, 0, 0)
        buffNode:setOpacity(0)
        buffNode:runAction(ui.action.sequence({{"fadeTo",0.25,255},{"fadeTo",total-0.317,178},{"fadeTo",0.167,0},"remove"}))
    end
    self.delayNode:runAction(ui.action.sequence({{"delay",120/60},{"call",delayFrameIndex_175}}))
end

function AthenaEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self.target)
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end

return {M,V,C}
