
local SData = GMethod.loadScript("data.StaticData")
local AvtInfo = class()

function AvtInfo:ctor(params,parent)
    self.params = params
    self.person = params.person
    self.parent = parent
    self.C = parent
    self.V = self.C.V
    self.id = self.person.id
    self.level = self.person.level
    --觉醒等级
    self.alevel = self.person.awakeUp or 0
    self:initNormalBattle()

    -- self:initAll()
    local scene = GMethod.loadScript("game.View.Scene")
    if scene.battleType == const.BattleTypeUPve then   --联盟副本
        if self.C.group == 2 then
            self:initUnionPve()
        elseif self.C.group == 1 then
            self:initPvbHurtAdd()
        end
    elseif scene.battleType == const.BattleTypeUPvp then   --联盟战
        self:initUnionPvl()
    elseif scene.battleType == const.BattleTypePvb then --神兽挑战
        if self.C.group == 2 and self.person.forceData then
            self.bossIdx = self.person.forceData.idx
            self.nowHp = self.maxHp - self.person.forceData.lostHp
        end
    end

    --引导
    -- local context = GameLogic.getUserContext()
    -- if context.guide:getStep().type == "pvj" and not self.parent.bid then
    --     self.params.person.fav = 2
    -- end
    -- if self.C.group == 1 then
    --     self.nowHp = 1000000
    --     self.atk = 1000000
    -- end
end
-- BOSS种类  加成攻击力       加成血量
--     白银BOSS  黄金BOSS  白银BOSS  黄金BOSS
-- 建筑  200%    250%    3000%   6000%
-- 怪物  150%    200%    2000%   4000%

function AvtInfo:initPvbHurtAdd()
    local context = GameLogic.getUserContext()
    self.hurtParam = self.hurtParam*(1+(context.pvbHurtAdd or 0)/100)
end

function AvtInfo:initUnionPve()
    local scene = GMethod.loadScript("game.View.Scene")
    local index = scene.battleParams.index
    local bosslist = scene.battleParams.bosslist
    local bossItem = SData.getData("upveboss",index)
    local id = self.C.bid or self.C.sid
    local addPs = SData.getData("upveadd")
    if not scene.battleData.bossIdxList then
        scene.battleData.bossIdxList = {}
    end

    for i=1, KTLen(bossItem) do
        local v = bossItem[i]
        --if v[1] == id then
        if v[1] == id and v[2] == self.level and not scene.battleData.bossIdxList[i] then
            self.bossIdx = i
            scene.battleData.bossIdxList[i] = true
            if i == 1 then      --黄金boss
                if not DEBUG.passUnionPve then
                    if id<100 then
                        self.maxHp = self.maxHp*addPs[1][1].hp/100
                        self.nowHp = bosslist and bosslist[i] and tonumber(bosslist[i][1]) or self.maxHp
                        self.atk = self.atk*addPs[1][1].atk/100
                    else
                        self.maxHp = self.maxHp*addPs[2][1].hp/100
                        self.nowHp = bosslist and bosslist[i] and tonumber(bosslist[i][1]) or self.maxHp
                        self.atk = self.atk*2*addPs[2][1].atk/100
                    end
                end
            else
                self.C.cantUseSkill = true
                if not DEBUG.passUnionPve then
                    if id<100 then
                        self.maxHp = self.maxHp*addPs[1][2].hp/100
                        self.nowHp = bosslist and bosslist[i] and tonumber(bosslist[i][1]) or self.maxHp
                        self.atk = self.atk*addPs[1][2].atk/100
                    else
                        self.maxHp = self.maxHp*addPs[2][2].hp/100
                        self.nowHp = bosslist and bosslist[i] and tonumber(bosslist[i][1]) or self.maxHp
                        self.atk = self.atk*addPs[2][2].atk/100
                    end
                end
            end
            break
        end
    end
end

function AvtInfo:initUnionPvl()
    local scene = GMethod.loadScript("game.View.Scene")

    if self.C.group == 1 then      --进攻方
        local addlv = scene.battleParams.pvldata.addlv
        self.base_hp = self.base_hp*(1+5*addlv[1]/100)
        self.maxHp = self.base_hp
        self.nowHp = self.maxHp
        self.base_atk = self.base_atk*(1+5*addlv[2]/100)
        self.atk = self.base_atk
    else                                --防守方
        if self.C.bid then      --建筑
            if self.C.bid ~= 50 then
                --先计算加成
                local index = scene.battleParams.index
                local addP = const.UnionPvlData[index]
                self.maxHp = self.maxHp*addP[1]/100
                self.nowHp = self.maxHp
                self.atk = self.atk*addP[2]/100

                if not scene.battleData.allMaxHp then
                    scene.battleData.allMaxHp = 0
                end

                local hpPct = scene.battleData.allHpPct
                scene.battleData.allMaxHp = scene.battleData.allMaxHp+self.maxHp
                scene.battleData.allNowHp = scene.battleData.allMaxHp*hpPct/10000

                self.maxHp = self.maxHp
                self.nowHp = self.maxHp*hpPct/10000
            end
        elseif self.C.sid>1000 then     --英雄
            local destroyDebuffs = scene.battleParams.pvldata.destroyDebuffs or {}
            local p=destroyDebuffs.atk or 0
            local hpP = destroyDebuffs.hp or 0
            self.base_atk = self.base_atk*(1-p/100)
            self.atk = self.base_atk
            self.base_hp = self.base_hp*(1-hpP/100)
            self.maxHp = self.base_hp
            self.nowHp = self.maxHp
        end
    end
end

function AvtInfo:initNormalBattle()
    local person = self.person
    self.base_hp = person.hp or 0
    self.base_atk = person.atk or 0
    --修改1：base_atkSpeed去除，改为aspeed和attackScale两个值
    self.aspeed = (person.aspeed or 0)/1000
    self.attackScale = 1+(person.ascale or 0)
    self.attackScale_base = self.attackScale
    --修改2：base_moveSpeed去除，改为speed和moveScale两个值
    self.speed = (person.speed or 0)/10
    self.moveScale = 1+(person.mscale or 0)
    self.moveScale_base = self.moveScale
    self.base_hurtParam = person.hurtParam or 1
    self.base_defenseParam = person.defenseParam or 1  --所有单位防御
    self.base_ndefParam = person.ndefParam or 1
    self.base_sdefParam = person.sdefParam or 1
    self.base_rating = person.rating or 1     --命中
    self.base_dodge = person.dodge or 0      --闪避
    self.base_critical = person.critical or 0 --暴击率
    self.base_dscritical = person.dscritical or 0--抗爆率
    self.base_criticalNum = person.criticalNum or 2 --暴击倍率
    self.range = (person.range or 0)/10 --攻击距离
    self.drange = (person.drange or 0)/10
    self.mrange = (person.mrange or 0)/10
    self.utype = person.utype or 1
    self.autype = person.autype or 1

    self.maxHp = self.base_hp

    self.nowHp = person.nowHp or self.maxHp
    self.nowHp2 = person.armor or 0     --护盾假血
    self.atk = self.base_atk

    self.hurtParam = self.base_hurtParam
    self.defenseParam = self.base_defenseParam
    self.rating = self.base_rating      --命中
    self.dodge = self.base_dodge        --闪避
    self.critical = self.base_critical  --暴击率
    self.dscritical = self.base_dscritical --抗爆率
    self.criticalNum = self.base_criticalNum --暴击倍率
    self.healps = 1             --治疗率

    self.bfDizziness = 0 --眩晕
    self.bfRebound = 0  --反弹伤害
    self.bfRebound1 = 0  --反弹伤害
    self.bfRebound2 = 0  --反弹伤害
    self.bfReAtk = 0 --反射伤害
    self.bfSilent = 0  --沉默
    self.immune = 0     --免疫伤害
    self.cantRebirth = 0 --死亡不能复活
    self.clearGain = 0    --清除增益效果

    self.ctDizziness = 0 --免疫眩晕
end

function AvtInfo:damage(value)
    if self.nowHp2 and self.nowHp2>0 and value>0 then
        self.nowHp2 = self.nowHp2 - value
        if self.nowHp2<0 then
            self.nowHp2 = 0
        end
        return 2,0
    else
        self.nowHp = self.nowHp - value
        local dv = value
        if self.nowHp < 0 then
            dv = self.nowHp+value
            self.nowHp=0
        elseif self.nowHp > self.maxHp then
            dv = value+self.nowHp - self.maxHp
            self.nowHp = self.maxHp
        end
        return 1,dv
    end
end

return AvtInfo
