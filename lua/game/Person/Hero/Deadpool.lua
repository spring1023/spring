--死侍  4032

local M = class(AvtInfo)

local V = {}

function V:viewEffect(attackTarget,callback,isSkill)
    if not isSkill then
        -- 普攻直接执行伤害
        if self.__godSkillNum then
            local ps = self.C.person.awakeData.ps
            self.__godSkillNum = self.__godSkillNum - 1
            self.hasShadowRole = nil
            local denyRebirth = false
            if attackTarget.avtInfo.cantRebirth == 0 then
                attackTarget.avtInfo.cantRebirth = 1000000
                denyRebirth = true
            end
            SkillPlugin.exe2(self.C, attackTarget, ps.a, ps.x)
            if not attackTarget.deleted and denyRebirth then
                attackTarget.avtInfo.cantRebirth = 0
            end
            if self.__godSkillNum <= 0 then
                self.__godSkillNum = nil
                self.C.cantUseSkill = nil
                self.C:endGodSkill()
            end
        else
            callback(attackTarget)
        end
        return
    end
    DeadpoolEffect.new({attacker = self, mode = 1, target = attackTarget},callback)
end

function V:sg_godSkillAttack(attackTarget, viewInfo1, viewInfo2, b)
    self.skillStopNum = 5
    self.skillStopStart = 3
    self.loop = false
    self.isExeRealAtk = false
    local sfmt,sparams
    sfmt = self.animaConfig.atk_fmt[5]
    sparams = self.animaConfig.atk_fmt[5]
    self.frameFormat = sfmt
    self.animaTime = 0
    self.frameIndex = 0
    self.oneFrameTime = 0.083
    self.frameMaxIndex = 8
    self.actionTime = 0
    self.notRecoverFrame = true
    self.exeAtkFrame = 3
    self.state = PersonState.GODSKILL

    self.allActionTime = 2
    self.__godSkillNum = self.C.person.awakeData.ps.n
    BuffUtil.setBuff(self.C, {lastedTime = 1, immune = 1, ctDizziness=1})

    self.C.cantUseSkill = true
    local temp
    self.viewsNode = self.scene.objs
    local a, effectScale = 1, 1
    local direction = self.direction
    local setting={{58,-33},{92,47},{65,98},{-65,98},{-92,47},{-58,-33}}
    local x,y = 0,self.animaConfig.Ymove
    local p = {self.view:getPosition()}
    p[1] = p[1] + x
    p[2] = p[2] + y
    local initPos = {p[1],p[2],General.sceneHeight - p[2]}
    if direction == 1 or direction == 6 then
        a = 13
    elseif direction == 2 or direction == 5 then
        a = 14
    elseif direction == 3 or direction == 4 then
        a = 15
    end
    temp = ui.simpleCsbEffect("UICsb/HeroEffect_40322/a_"..a..".csb")
    display.adapt(temp, initPos[1] + setting[direction][1]/10, initPos[2] + setting[direction][2]/10, GConst.Anchor.Center)
    temp:setScaleY(effectScale)
    if direction > 3 then
        temp:setScaleX(-effectScale)
    else
        temp:setScaleX(effectScale)
    end
    self.viewsNode:addChild(temp, initPos[3])
    temp:runAction(ui.action.sequence({{"delay", 5}, "remove"}))
end


local C = class(AvtControler)

--后边把各式移动都扩展出来,可以考虑把方法移动到Avtcontroler里去
local function fakeTeleport(self, target, speed)
    local sViewInfo = self.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(self)
    local sx,sy = sViewInfo[1], sViewInfo[2]
    local tViewInfo = target.battleViewInfo or self.battleMap:getSoldierBattleViewInfoReal(target)
    local gx,gy = tViewInfo[1], tViewInfo[2]
    local gridInfo = {math.floor(gx),math.floor(gy),gx,gy}
    local check = self:checkPointInBuild(gridInfo)
    if check then
        gx,gy = check[2],check[3]
    end
    self.V:spmoveDirect(gx, gy, 80)
    local movetime = math.floor((math.sqrt((gy-sy)^2+(gx-sx)^2)/80)*100)/100
    BuffUtil.setBuff(self,{lastedTime = movetime, immune = 1, ctDizziness=1})
end

local function updateForGodSkill(self, diff)
    local ps = self.person.awakeData.ps

    if not self.__godSkillTarget or self.__godSkillTarget.deleted or self.__godSkillTarget.isHide then
        local ps = self.person.awakeData.ps
        local eHero = self.battleMap.hero
        local eSolider = self.battleMap.mer
        local eBuid = self.battleMap.battler
        local target
        if #eHero > 0 then
            target = eHero[self.rd:random(#eHero)]
        elseif #eSolider > 0 then
            target = eSolider[self.rd:random(#eSolider)]
        elseif #eBuid > 0 then
            target = eBuid[self.rd:random(#eBuid)]
        else
            return
        end
        self.__godSkillTarget = target
        self.attackTarget = target
        self.realTarget = target
        if self.realTarget.avater then
            self.brealTargetInfo = self.battleMap:getSoldierBattleViewInfo(self.realTarget)
        end
        self.V:spmoveDirect(target.BV.gx, target.BV.gy, 20, true)
        if self.__godFirstTarget then
            self.__godFirstTarget = nil
            self.V.animaTime = self.V.oneFrameTime * 3
            -- self.frameMaxIndex = 8
            self.V.exeAtkFrame = 7
            self.V.exeRealAtk = false
            self.V.isExeRealAtk = false
            self.V.attackType = 5
            self.V.allActionTime = self.V.oneFrameTime * 5
            -- self.V.animaTime = 0
            -- self.V.frameIndex = 0
            -- self.V.oneFrameTime = self.V.allActionTime / 8
            -- self.V.actionTime = 0
        else
            if self.V.allActionTime > self.V.oneFrameTime * 10 then
                self.V.allActionTime = self.V.oneFrameTime * 10
            end
        end
        self.V.hasShadowRole = true
        -- self.V.attackInMoving = true
        -- self.V.
        self.V.state = PersonState.ATTACK
    end
end

--守护技:防守时，自身闪避提升[x]%，每出现一次Miss，死侍便会瞬移到该英雄附近攻击一次，冷却[b]秒。
local function defendSkill(self, diff)
    self.coldTime = self.coldTime and self.coldTime - diff or 0
end

function C:onInitComponentsDelay()
    if self:checkGodSkill2() and not self.deleted then
        local ps = self.person.awakeData2.ps
        BuffUtil.setStaticBuff(self, "dodge", ps.x)
        local newNode = ui.node()
        self.V.view:addChild(newNode)
        GameEvent.bindEvent(newNode, "eHeroMiss", self, function (onuse, event, target)
            if not target.deleted and self.coldTime <= 0 and self.group ~= target.group and
            GameLogic.getCombatUnitType(target) == "hero" then
                self.coldTime = ps.b
                self.V:spmoveDirect(target.BV.gx, target.BV.gy, 60, true)
                self.V.hasShadowRole = true
                self.attackTarget = target
                self.realTarget = target
                self.__godSkillTarget = target
                if self.realTarget.avater then
                    self.brealTargetInfo = self.battleMap:getSoldierBattleViewInfo(self.realTarget)
                end
                -- fakeTeleport(self, target, 40)
            end
        end)
        LGBT.addComponentFunc(self, "updateComponent", defendSkill)
    else
        return
    end
end

--[[主动技能:死侍双手持枪对前方[n]格范围(半径为n的半圆)内的敌人造成[a]+[c]%*攻击力伤害,受到伤害的敌人在接
下来[b]秒内受到伤害加深[d]%。消耗[x]怒，冷却时间[z]秒]]--
function C:sg_ppexeSkill(target)
    self.isSkillAttack = true
    self.isSkillNotAttack = true
end
function C:sg_exeSkill(target)
    self:extSkill()
    local ps = self.actSkillParams

    local initGrid = target.initGrid
    local direction = target.direction

    local sgx, sgy = initGrid[1], initGrid[2]
    local pointTab = {}
    for _,v in ipairs(self.battleMap.battlerAll) do
        table.insert(pointTab, {v.BV.gx, v.BV.gy, v.BV.gsize, v})
    end
    local result = Aoe.sectorPoint(pointTab, initGrid, ps.n, 180, -60*direction+255)

    local dcount = 0
    local a = 3 --伤害展示次数
    local function delayDamage()
        dcount = dcount + 1
        for _, tv in ipairs(result) do
            if not tv[4].deleted then
                SkillPlugin.exe2(self, tv[4], ps.a/a, ps.c/a)
                if dcount == 3 and not tv[4].deleted and tv[4].avater then
                    local view = tv[4].avater and tv[4].avater.view or tv[4].view
                    local temp = ui.simpleCsbEffect("UICsb/HeroEffect_40322/c_0.csb")
                    display.adapt(temp, 0, self.avater.animaConfig.Ymove or 0, GConst.Anchor.Center)
                    view:addChild(temp, 0)
                    temp:runAction(ui.action.sequence({{"delay", ps.b},"remove"}))
                    BuffUtil.setBuff(tv[4], {lastTime = ps.b, bfDefPct = -ps.d})
                end
            end
        end
        if dcount == 3 and not self.deleted then
            self:extSkill()
        end
    end
    for i=1, 3 do
        self.scene.replay:addDelay(delayDamage, (i-1)*ps.n/a/15)
    end
end

--[[天神技:开场[cd]秒后可释放，死侍双剑交叉，出现光效，短暂蓄力后，快速地在战场上移动，攻击附近的敌方
单位（英雄优先）[n]次，每剑造成[a]+[x]%*攻击力伤害。在使用技能的时候是无敌的。如攻击目标在攻击完成
前死亡，则转移至下个目标完成攻击，依次类推。被死侍天神技打死的英雄无法被复活。]]--
function C:ppexeGodSkill()
    self.isGodSkillAttack = true
    self.isGodSkillNotAttack = true
end

function C:exeGodSkill()
    LGBT.addComponentFunc(self, "updateComponent", updateForGodSkill)
    self.__godBackGrid = {self.V.gx, self.V.gy}
    self.__godFirstTarget = true
    -- 这里再提高攻速，否则效果不太好
    BuffUtil.setBuff(self, {lastedTime = 3000, immune = 1, ctDizziness=1, bfAtkSpeedPct=200}, "Deadpool")
end

function C:endGodSkill()
    LGBT.removeComponentFunc(self, "updateComponent", updateForGodSkill)
    if self.allBuff["Deadpool"] then
        self.allBuff["Deadpool"].lastedTime = 1
    end

    self.__godSkillTarget = nil
    self.attackTarget = nil
    self.realTarget = nil
    local friend = {}
    for _, f in ipairs(self.battleMap2.hero) do
        if f ~= self then
            table.insert(friend, f)
        end
    end
    if #friend <= 0 then
        self.V:spmoveDirect(self.__godBackGrid[1], self.__godBackGrid[2], 60, true)
        self.V.hasShadowRole = true
    else
        local target = friend[self.rd:random(#friend)]
        self.V:spmoveDirect(target.BV.gx, target.BV.gy, 60, true)
        self.V.hasShadowRole = true
        -- fakeTeleport(self, target, 40)
    end
end

function C:doGodkillAttack()
    local ps = self.person.awakeData.ps
    local damage = ps.a+attack.M.base_atk*ps.x/100
    if damage >= self.godSkillTarget.nowHp then
        target.avtInfo.cantRebirth = 1000000
    end
    self.godSkillTarget:damage(damage)
end

--专属技:死侍每次切换武器(释放主动技或天神技)，会增加[a]%的暴击率、[b]%的暴击伤害，持续整场战斗。（死亡后该BUFF消失）
function C:extSkill()
    local ps = self:getExtSkillData()
    BuffUtil.setStaticBuff(self, "critical", ps.a/100)
    BuffUtil.setStaticBuff(self, "criticalNum", ps.b/100)
end


DeadpoolEffect = class()

function DeadpoolEffect:ctor(params,callback)
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

function DeadpoolEffect:initParams(params)
    self.effectManager=GameEffect.new("DeadpoolEffect.json")
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
    self.initGrid = {self.attacker.gx, self.attacker.gy}
end

function DeadpoolEffect:initEffect()
    if self.mode == 1 then
        self:initSkill()
    end
end

function DeadpoolEffect:initSkill()
    local direction = self.direction
    local setting={{58,-33},{92,47},{65,98},{-65,98},{-92,47},{-58,-33}}
    local temp
    local a, effectScale = 1, 1
    if direction == 1 or direction == 6 then
        a = 1
    elseif direction == 2 or direction == 5 then
        a = 2
    elseif direction == 3 or direction == 4 then
        a = 3
    end
    if self.attacker.C.person.awakeUp > 0 then
        temp = ui.simpleCsbEffect("UICsb/HeroEffect_40322/j_"..a..".csb")
    else
        temp = ui.simpleCsbEffect("UICsb/HeroEffect_4032/j_"..a..".csb")
    end
    display.adapt(temp, self.initPos[1] + setting[direction][1]/10, self.initPos[2] + setting[direction][2]/10, GConst.Anchor.Center)
    temp:setScaleY(effectScale)
    if direction > 3 then
        temp:setScaleX(-effectScale)
    else
        temp:setScaleX(effectScale)
    end
    self.viewsNode:addChild(temp, self.initPos[3])
    temp:runAction(ui.action.sequence({{"delay", 5}, "remove"}))

    local temp2 = ui.simpleCsbEffect("UICsb/HeroEffect_40322/b_0.csb")
    local deepValue
    if direction == 3 or direction == 4 then
        deepValue = self.initPos[3]
    else
        deepValue = self.initPos[3]+4000
    end
    display.adapt(temp2, self.initPos[1] + setting[direction][1]/2+40, self.initPos[2] + setting[direction][2]/2+40, GConst.Anchor.Center)
    temp2:setScaleX(0.5)
    temp2:setRotation((2-direction)*60)
    self.viewsNode:addChild(temp2, deepValue)
    temp2:runAction(ui.action.sequence({{"delay",5},"remove"}))
end

function DeadpoolEffect:update(diff)
    if not self.allTime then
        self.allTime = 0
    end
    if not self.time then
        self.time = 0.4
    end
    self.allTime = self.allTime+diff
    if self.time and self.allTime>self.time then
        self.callback(self)
        self.time = nil
        self.deleted = true
        self.scene.replay:removeUpdateObj(self)
    end
end

return {M,V,C}




















