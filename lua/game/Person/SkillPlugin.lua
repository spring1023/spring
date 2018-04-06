GMethod.loadScript('game.GameLogic.BuffUtil')
local Aoe = GMethod.loadScript('game.GameLogic.Aoe')

local SkillPlugin = {}

--增加减伤率a%,持续y秒
function SkillPlugin.exe1(hero,a,y)

    BuffUtil.setBuff(hero,{bfDefPct = a,lastedTime=y})
end

--对目标造成a+b%*攻击力的伤害
function SkillPlugin.exe2(hero,target,a,b,c,isPure,isFT)
    local value = BattleUtil.getSkillHurt(hero,target,a,b)
    value = value*(c and c/100 or 1)
    --纯粹伤害
    if isPure then
        value = a
    end
    if not target or target.deleted or value == 0 then
        return
    end

    if target.showHurtPerformance then
        target:showHurtPerformance(math.floor(value), 1)
    end
    if not isFT then
        if target.M.bfRebound2 > 0 then
            SkillPlugin.exe2(target,hero,value*target.M.bfRebound2/100,0,nil,true,true)
        end
        return target:damage(value, hero)
    else
        return target:damage(value)
    end
end

--眩晕t秒
function SkillPlugin.exe3(target,t)
    BuffUtil.setBuff(target,{bfDizziness = t,lastedTime = t})
end

--增加固定攻击力b
function SkillPlugin.exe4(soldier,b,y)
    BuffUtil.setBuff(soldier,{bfAtkAdd = b,lastedTime = y})
end

--增加百分比攻击力
function SkillPlugin.exe5(target,a,t)
    BuffUtil.setBuff(target,{bfAtkPct = a,lastedTime = t})
end

--增加百分比血量
function SkillPlugin.exe6(target,b,t)
    BuffUtil.setBuff(target,{bfHpPct = b/100,lastedTime = t})
end

--恢复a+b%*攻击力血量
function SkillPlugin.exe7(hero,target,a,b)
    local value = BattleUtil.getHeal(hero,target,a,b)
    target:damage(value,hero)
end

-- 当英雄防御时，电塔增加a%ATK，b%HP。每e次攻击造成c%的范围性伤害。
function SkillPlugin.exeDefendLeiShen(hero)
    local a,b = 10,10
    for i, v in ipairs(allBuilds) do
        SkillPlugin.exe5(v,a)
        SkillPlugin.exe6(v,b)
        v.specialAtk = true
    end
end


--建筑技能
--迫击炮 每e次攻击造成c%的范围性伤害。并眩晕目标tS。
function SkillPlugin:ppexePaiJiPao(attacker,target)

end

function SkillPlugin:exePaiJiPao(attacker,target)
    local t = 5
    --计算范围
    SkillPlugin.exe3(target,5)
end

--电塔 每e次攻击造成c%的范围性伤害。
function SkillPlugin:ppexeDianTa(attacker,target)

end

function SkillPlugin:exeDianTa(attacker,target)
    local t = 5
    --计算范围
end

--巨龙之心 英雄在成功闪避敌人攻击时，有a%的概率回血b%；此外，该英雄每受到30次数后。会获得一个存在5秒的护盾，护盾可以使英雄闪避提升c%
function SkillPlugin.ppexeJuLongZhiXin(avtControler,value)
    local equip = avtControler.params.person.equip
    if not equip or equip.id ~=2002 then
        return
    end

    --成功闪避后
    if value==0 then
        if avtControler.rd:randomInt(100)<=equip.params.a then
            local addHp = avtControler.avtInfo.maxHp*equip.params.b/100
            if avtControler.avtInfo.nowHp+avtControler.avtInfo.maxHp*equip.params.b/100>avtControler.avtInfo.maxHp then
               addHp = avtControler.avtInfo.maxHp-avtControler.avtInfo.nowHp
            end
            avtControler:damage(-addHp)
        end
    end

    if not avtControler.equip_damageTimes then
        avtControler.equip_damageTimes = 0
    end
    avtControler.equip_damageTimes = avtControler.equip_damageTimes+1
    if avtControler.equip_damageTimes>=30 then
        local buff = {
            lastedTime = 5,
            bfDodge = equip.params.c,
        }
        BuffUtil.setBuff(avtControler,buff)
        avtControler.equip_damageTimes = 0
    end
end


-- @brief 其他单位召唤逻辑
-- @params person 召唤物的数据
-- @params group 召唤物的阵营；不排除召唤敌方单位的可能，所以不用默认的
-- @params gx, gy 召唤时的坐标
-- @params summonParams 召唤物的参数，详情如下：
--           atkPercent, atkValue 召唤物的攻击力调整
--           hpPercent, hpValue 召唤物的生命值调整
--           summonTime 召唤物持续时间
--           master 召唤物主人；有主人的召唤物在主人死了召唤物随之消失
function SkillPlugin.summonTroop(person, group, gx, gy, summonParams)
    local scene = GMethod.loadScript("game.View.Scene")
    local params = {
        person=person,
        state=AvtControlerState.BATTLE,
        group=group,
        isZhaoHuan = true
    }
    local role = PersonUtil.C(params)
    role.M.nowHp = role.M.maxHp
    if summonParams then
        if summonParams.atkPercent or summonParams.atkValue then
            role.M.base_atk = role.M.base_atk*(summonParams.atkPercent or 0)/100
                + (summonParams.atkValue or 0)
            role.M.atk = role.M.base_atk
        end
        if summonParams.hpPercent or summonParams.hpValue then
            role.M.base_hp = role.M.base_hp*(summonParams.hpPercent or 0)/100
                + (summonParams.hpValue or 0)
            role.M.maxHp = role.M.base_hp
            role.M.nowHp = role.M.maxHp
        end
        if summonParams.summonTime then
            role.allLiveTime = summonParams.summonTime
        end
        if summonParams.master then
            role.master = summonParams.master
        end
        if summonParams.acid then
            role.params.acid = summonParams.acid
        end
        if summonParams.isFenShen then
            role.isFenShen = true
        end
        if summonParams.isGodZhaoHuan then
            role.params.isGodZhaoHuan = true
        end
    end
    role:addToScene(scene, gx, gy)
    return role
end

_G["SkillPlugin"] = SkillPlugin
return SkillPlugin
