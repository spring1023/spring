local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    ChopperEffect.new({attacker = self, mode = 0, target = attackTarget},callback)
end

function V:sg_godSkillAttack(attackTarget,viewInfo1,viewInfo2,b)
    if self.C.heroState == 0 then
        self.__skip = true
        return
    end
    --目标点坐标
    local viewInfo = attackTarget.battleViewInfo or self.C.battleMap:getSoldierBattleViewInfoReal(attackTarget)
    local gx,gy = viewInfo[1],viewInfo[2]
    local gridInfo = {math.floor(gx),math.floor(gy),gx,gy}
    local check = self.C:checkPointInBuild(gridInfo)
    if check then
        gx,gy = check[2],check[3]
    end
    --飞的人 是自己
    self.C.shouldReCheck = true
    local direction=self.direction
    local setting={{1,1.5},{2,0},{1,-1.5},{-1,-1.5},{-2,0},{-1,1.5}}

    self:spmoveDirect(gx+setting[direction][1], gy+setting[direction][2], 30)
    -- 考虑这个时间内适当延长一点做跳跃
    local allActionTime = self.allActionTime + 1
    self.allActionTime = allActionTime
    -- 考虑给自己加一个非常短暂的无敌buff；否则这种技能放到一半莫名奇妙挂掉都可能出BUG
    BuffUtil.setBuff(self.C,{lastedTime = allActionTime, immune = 1, ctDizziness=1})


    self.personView:runAction(ui.action.sequence({ui.action.easeSineOut(ui.action.moveBy(self.allActionTime/2,0,200)),
        ui.action.easeSineIn(ui.action.moveBy(self.allActionTime/2,0,-200))}))

    self.loop = false
    local sfmt,sparams
    if type(self.animaConfig.skill_fmt) == "string" then
        sfmt = self.animaConfig.skill_fmt
        sparams = self.animaConfig.skill_params
    else
        sfmt = self.animaConfig.skill_fmt[3]
        sparams = self.animaConfig.skill_params[3]
    end
    self.frameFormat = sfmt
    self.animaTime = 0
    self.frameIndex = 0
    -- self.oneFrameTime = sparams[1]/sparams[2]
    self.frameMaxIndex = sparams[2]
    self.actionTime = 0
    -- 增加最大像素
    self.maxZorder = self.maxZorder + 300
    self.state = PersonState.GODSKILL

    self.specialList = {{6, {0, 1, 7, 4, 5, 6}}, {-1, 2}, {-4, {7, 0}}}
    self.oneFrameTime = 0.1

    self.inSkillEffect = nil
end
function V:updateSpecialState(diff)
    if self.C.heroState == 0 then
        self.__skip = true
        return
    end
    self.actionTime = self.actionTime+diff
    if self.inSkillEffect then
        if self.actionTime >= self.allActionTime + self.specialList[3][1]*self.oneFrameTime then
            self.animaTime = self.specialList[3][2][math.floor(self.actionTime - (self.allActionTime + self.specialList[3][1]*self.oneFrameTime)) + 1] or 0
            self:resetFrame(0)
        end
        if self.actionTime >= self.allActionTime then
            self.actionTime = self.actionTime-self.allActionTime
            self:resetFree()
            self.attackEffectView = nil
        end
    elseif self.actionTime >= self.allActionTime then
        self.allActionTime = self.allActionTime + 0.5
        self.animaTime = 3 * self.oneFrameTime
        self:resetFrame(0)
        self.gx = self.targetPoint[1]
        self.gy = self.targetPoint[2]
        self.C:exeGodSkill(self.gx, self.gy)
        local px,py = self.map.convertToPosition(self.gx,self.gy)
        for _, view in ipairs(self._logicViews) do
            view:setPosition(px, py)
        end
        self.px, self.py = px, py + self.animaConfig.Ymove
        self.view:setLocalZOrder(self.maxZorder-py)
        if self.blood then
            self.blood:setLocalZOrder(self.maxZorder-py)
        end
        self.inSkillEffect = true
    else
        if self.actionTime <= self.oneFrameTime * self.specialList[1][1] then
            self.animaTime = self.specialList[1][2][math.floor(self.actionTime/self.oneFrameTime)+1] * self.oneFrameTime
            self:resetFrame(0)
        elseif self.actionTime >= self.allActionTime + self.oneFrameTime * self.specialList[2][1] then
            self.animaTime = self.specialList[2][2] * self.oneFrameTime
            self:resetFrame(0)
        end
        self:resetPosition()
    end
end
local C = class(AvtControler)

local heroState = {ren = 0, shou = 1}

function C:_doUpdate1(diff)
    --人形时使敌军流血[n]秒,每隔[t]秒使周围[y]格内的目标损失[b]点生命
    if self.heroState == heroState.shou then
        self.timerN = nil
        self.timerT1 = nil
        LGBT.removeComponentFunc(self, "updateComponent", self._doUpdate1)
        return
    end

    local ps = GMethod.loadScript("data.StaticData").getData("mskdatas", 4531, self.mSkillLevel)
    local timerN = self.timerN or ps.n
    timerN = timerN - diff
    if timerN < 0 then
        self.timerN = nil
        self.timerT1 = nil
        LGBT.removeComponentFunc(self, "updateComponent", self._doUpdate1)
    else
        self.timerN = timerN
        local timerT = self.timerT1 or ps.t
        timerT = timerT - diff
        if timerT <= 0 then
            self.timerT1 = self.timerT1 + ps.t
            local target = self:getHeroAndSoldier(self, ps.y)
            if not target then
                return
            end
            for _,v in ipairs(target) do
                v:damage(ps.b)
            end
        else
            self.timerT1 = timerT
        end
    end
end

local function _doUpdate2(self, diff)
    --嘲讽
    if self.heroState == heroState.ren then
        self.timerT = nil
        self.timerT2 = nil
        LGBT.removeComponentFunc(self, "updateComponent", _doUpdate2)
        return
    end

    local ps = GMethod.loadScript("data.StaticData").getData("mskdatas", 4131, self.mSkillLevel)
    local timerT = self.timerT2 or ps.t
    timerT = timerT - diff
    if timerT < 0 then--每隔t秒嘲讽一次
        self.timerT2 = self.timerT2 + ps.t
        local ourHero = self:getCircleTarget(self, self.battleMap2.hero, ps.n)
        local ourSoldier = self:getCircleTarget(self, self.battleMap2.mer, ps.n)
        for _,v in ipairs(ourHero) do
            if v == self then
                BuffUtil.setBuff(v, {lastedTime = ps.y, bfDefPct = ps.b})
            else
                BuffUtil.setBuff(v, {lastedTime = ps.y, bfDefPct = ps.f})
            end
        end
        for _,v in ipairs(ourSoldier) do
            BuffUtil.setBuff(v, {lastedTime = ps.y, bfDefPct = ps.f})
        end
        local target = self:getHeroAndSoldier(self, ps.a)
        if not target then
            return
        end
        for _,v in ipairs(target) do
            v.lockTarget = self
        end
    else
        self.timerT2 = timerT
    end
end

local function _doUpdate3(self, diff)
    --城墙生命值提高[a]%，反弹[b]%的技能伤害和[c]%的普攻伤害。
    if self.deleted then
        return
    end
    if self:checkGodSkill2() then
        local ps = self.person.awakeData2.ps
        local group = self.battleMap2.battlerAll
        for _,v in pairs(group) do
            if v.bid and v.bid == 50 then--城墙
                v.M.maxHp = v.M.maxHp*(1+ps.a/100)
                v.M.nowHp = v.M.nowHp*(1+ps.a/100)
                BuffUtil.setBuff(v,{bfRebound1 = ps.c, bfRebound2 = ps.b})
            end
        end
    end
end

function C:onInitComponents()
    self.heroState = heroState.shou
    LGBT.addComponentFunc(self, "updateComponent", _doUpdate3)
    LGBT.addComponentFunc(self, "updateComponent", _doUpdate2)
end

function C:exeAttack(target)
    --普攻特效
    local direction=self.avater.direction
    local setting={{58,-33},{92,47},{65,98},{-65,98},{-92,47},{-58,-33}}
    local temp
    local a
    if direction == 1 or direction == 6 then
        a = 1
    elseif direction == 2 or direction == 5 then
        a = 2
    elseif direction == 3 or direction == 4 then
        a = 3
    end
    local effectScale
    if self.heroState == heroState.ren then
        temp = ui.simpleCsbEffect("UICsb/HeroEffect_4031/a_"..a..".csb")
        effectScale = 0.5
    elseif self.heroState == heroState.shou then
        temp = ui.simpleCsbEffect("UICsb/HeroEffect_40312/a_"..a..".csb")
        effectScale = 1
    end
    display.adapt(temp,setting[direction][1],setting[direction][2],GConst.Anchor.Center)
    temp:setScaleY(effectScale)
    if direction > 3 then
        temp:setScaleX(-effectScale)
    else
        temp:setScaleX(effectScale)
    end
    self.avater.view:addChild(temp, 0)
    temp:runAction(ui.action.sequence({{"delay", 3}, "remove"}))
end
--[[
4031 乔巴 主动技能
圣诞驯鹿吞下蓝波球在兽形态和人形态之间切换（初始为兽形态），消耗怒气[x]，冷却时间
    [z]秒。
人形态：自身伤害持续增加[c]%，攻速增加[d]%，移速增加[e]%，每[a]次攻击后对周围[y]格
    造成一次[f]%攻击力的范围伤害并使敌军流血[n]秒，每隔[t]秒损失[b]点生命。
兽形态：每隔[t]秒会嘲讽周围[a]格敌人欺负圣诞驯鹿[y]秒，自身减伤持续增加[b]%，受到
    伤害时[d]%概率将伤害值[e]%转化为生命值，同时使周围[n]格友军减伤增加[f]%。
]]--
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end

--主动技能
function C:sg_exeSkill(target)
    self.heroState = math.abs(self.heroState-1)
    --主动技变身特效
    local bg = self.avater.view
    local temp = ui.simpleCsbEffect("UICsb/HeroEffect_4031/a_4.csb")
    display.adapt(temp,0,0,GConst.Anchor.Center)
    temp:setScale(1.0)
    bg:addChild(temp,0)
    temp:runAction(ui.action.sequence({{"delay", 3}, "remove"}))
    if self.heroState == heroState.ren then
        local ps = GMethod.loadScript("data.StaticData").getData("mskdatas", 4531, self.mSkillLevel)
        BuffUtil.setStaticBuff(self, "atk", ps.c/100*self.M.base_atk)
        BuffUtil.setStaticBuff(self, "attackScale", ps.d/100 * self.M.attackScale_base)
        BuffUtil.setStaticBuff(self, "moveScale", ps.e/100 * self.M.moveScale_base)
        self.needCountForAttack = {a = ps.a, b = ps.f, n = ps.y}
        LGBT.removeComponentFunc(self, "updateComponent", _doUpdate2)
    elseif self.heroState == heroState.shou then
        local ps = GMethod.loadScript("data.StaticData").getData("mskdatas", 4531, self.mSkillLevel)
        BuffUtil.setStaticBuff(self, "atk", -ps.c/100*self.M.base_atk)
        BuffUtil.setStaticBuff(self, "attackScale", -ps.d/100 * self.M.attackScale_base)
        BuffUtil.setStaticBuff(self, "moveScale", -ps.e/100 * self.M.moveScale_base)
        self.needCountForAttack = nil
        self.timerN = nil
        self.timerT1 = nil
        LGBT.removeComponentFunc(self, "updateComponent", self._doUpdate1)
        LGBT.addComponentFunc(self, "updateComponent", _doUpdate2)
    end
end

function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

--[[
天神技开场后[cd]秒可进行释放。
人形态：清除敌方[c]点怒气，并使其接下来[t]秒怒气回复速度降低[x]%，同时自身回复
    [y]%生命，并使周围[n]格范围内敌方英雄和分身晕眩[k]秒，并在[a]秒内普攻伤害
    降低[z]%，技能伤害降低[o]%。
兽形态：快速跃起，践踏对周围[n]格范围敌军造成[x]%攻击力的伤害，并跃至当前生命
    最少敌方英雄身边[t]秒内持续攻击该目标并使其晕眩，此期间对其造成伤害的[y]%
    将转化为生命值。
]]--
function C:exeGodSkill()
    --天神技摇铃铛/跳跃特效
    local direction=self.avater.direction
    local setting={{58,-33},{92,47},{65,98},{-65,98},{-92,47},{-58,-33}}
    local temp
    local a,b,effectScale
    if direction == 1 or direction == 6 then
        a,b = 4,7
    elseif direction == 2 or direction == 5 then
        a,b = 5,8
    elseif direction == 3 or direction == 4 then
        a,b = 6,9
    end
    if self.heroState == heroState.ren then
        temp = ui.simpleCsbEffect("UICsb/HeroEffect_4031/a_"..b..".csb")
        effectScale = 2.25
    elseif self.heroState == heroState.shou then
        temp = ui.csbNode("UICsb/HeroEffect_40312/a_"..a..".csb")
        local action = ui.csbTimeLine("UICsb/HeroEffect_40312/a_"..a..".csb")
        action:setTimeSpeed(0.4)
        temp:runAction(action)
        action:gotoFrameAndPlay(28, 55, false)
        effectScale = 1
    end
    display.adapt(temp,setting[direction][1]/10,setting[direction][2]/10,GConst.Anchor.Center)
    temp:setScaleY(effectScale)
    if direction > 3 then
        temp:setScaleX(-effectScale)
    else
        temp:setScaleX(effectScale)
    end
    self.avater.view:addChild(temp, 0)
    temp:runAction(ui.action.sequence({{"delay", 5}, "remove"}))
    if self.heroState == heroState.ren then
        local ps = GMethod.loadScript("data.StaticData").getData("adatas",40312,self.person.awakeData.skillLv)
        local eAnger = self.attackTarget.groupData.anger
        self.attackTarget.groupData.anger = eAnger-ps.c > 0 and eAnger-ps.c or 0--清除敌方[c]点怒气
        self.attackTarget.groupData.speedScale = 1-ps.x/100--回复速度降低[x]%
        self:damage(-self.avtInfo.maxHp * ps.y/100)--自身回复[y]%生命
        local target = self:getCircleTarget(self, self.battleMap.hero ,ps.n)
        if target then
            for _,v in ipairs(target) do
                if not v.isZhaoHuan or v.isFenShen then--敌方英雄和分身
                    BuffUtil.setBuff(v,{lastedTime = ps.k, bfDizziness = ps.k})--晕眩[k]秒
                    Vertigo.new(v.BV.view, 0, v.BV.animaConfig.Ymove, v.BV.M.bfDizziness)
                    BuffUtil.setBuff(v,{lastedTime = ps.a, bfAtkPct = ps.z, sdefParam = ps.o})
                end
            end
        end
    elseif self.heroState == heroState.shou then
        local ps = self.person.awakeData.ps
        local target = self.attackTarget
        if target then
            BuffUtil.setBuff(target,{lastedTime = ps.t, bfDizziness = ps.t})--晕眩t秒
            local bg, x, y, vertigoTime
            if not target.avater then
                x = 100
                y = target:getHeight()-100
                vertigoTime = target.M.bfDizziness
                bg = target.vstate.view
            else
                x = 0
                y = target.BV.animaConfig.Ymove
                vertigoTime = target.BV.M.bfDizziness
                bg = target.BV.view
            end
            Vertigo.new(bg, x, y, vertigoTime)
            self.lockTarget = target--持续攻击该目标
            self.chaoFengHuiXue = true
            local function delay()
                self.chaoFengHuiXue = nil
            end
            self.scene.replay:addDelay(delay, vertigoTime)

        end
        local targetG = self:getHeroAndSoldier(self, ps.n)
        if #targetG > 0 then
            for _,v in ipairs(targetG) do
                v:damage(self.M.base_atk*ps.x/100)--践踏范围内敌军
            end
        end
        self.V.maxZorder = self.V.maxZorder - 300
    end

    self.isGodSkillAttack = nil
    self.isGodSkillNotAttack = nil
    self.isGodSkillNow = nil
end

function C:specialGodSkillTarget()
    local ps = self.person.awakeData.ps
    local targetG
    targetG = self:getCircleTarget(self, self.battleMap.hero, ps.n)
    if targetG[1] then
        local  minHp = targetG[1].avtInfo.nowHp
        for i=1,#targetG-1 do
            minHp = targetG[i].avtInfo.nowHp < targetG[i+1].avtInfo.nowHp and targetG[i].avtInfo.nowHp or targetG[i+1].avtInfo.nowHp
        end
        for _,v in ipairs(targetG) do
            if v.avtInfo.nowHp == minHp then
                return v
            end
        end
    else
        targetG = self:getCircleTarget(self, self.battleMap.battler, ps.n)
        if #targetG >0  then
            local targetG2 = {}
            for _,v in ipairs(targetG) do
                if v.M.id <= 1000 then
                    table.insert(targetG2, v)
                    if #targetG2 > 0 then
                        local  minHp = targetG2[1].M.nowHp
                        for i=1,#targetG2-1 do
                            minHp = targetG2[i].M.nowHp < targetG2[i+1].M.nowHp and targetG2[i].M.nowHp or targetG2[i+1].M.nowHp
                        end
                        for _,t in ipairs(targetG2) do
                            if t.M.nowHp == minHp then
                                return t
                            end
                        end
                    else
                        self.isGodSkillAttack = nil
                        self.isGodSkillNotAttack = nil
                        self.isGodSkillNow = nil
                        self.avater.exeRealAtk = false
                    end
                end
            end
        end
        return
    end
end

ChopperEffect = class()

function ChopperEffect:ctor(params,callback)
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

function ChopperEffect:initParams(params)
    self.effectManager=GameEffect.new("ChopperEffect.json")
    self.views=self.effectManager.views
    self.attacker = params.attacker
    self.direction = self.attacker.direction
    self.mode = params.mode
    self.viewsNode = self.attacker.scene.objs
    self.delayNode = self.scene.delayNode
    self.speed = params.speed or 1000
    self.target = params.target or params.attacker.C.attackTarget

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

function ChopperEffect:initEffect()
    if self.mode == 0 then
        self:initAttack()
    end
end

function ChopperEffect:initAttack()

end

function ChopperEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    if not self.time then
        self.time = 0
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
