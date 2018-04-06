-- 战斗实用函数
-- Author：lianghaoran
-- Date：2017-10-10 16:18:19
local BattleUtil = {}
local LGBT = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")
local _globalRd

function BattleUtil.setGlobalRd(rd)
    _globalRd = rd
end

local __tmpValueTable = {0}
function BattleUtil.getHurt(attack,defense)
    if not attack or not defense then
        return 0
    end
    --判断名字
    local value
    local a_info = attack.avtInfo
    local d_info = defense.avtInfo
    local israt = a_info.rating - d_info.dodge

    if _globalRd:random2() > israt then
        defense:showHurtPerformance("MISS", 3)
        GameEvent.sendEvent("eHeroMiss", attack)
        return 0
    end

    local iscritical = a_info.critical - d_info.dscritical
    if _globalRd:random2()<=iscritical then
        iscritical = true
    else
        iscritical = false
    end
    value = a_info.atk*a_info.hurtParam*d_info.defenseParam*d_info.base_ndefParam
    value = iscritical and value*a_info.criticalNum or value
    __tmpValueTable[1] = value
    LGBT.useComponent(attack, "beforeNormalAttack", __tmpValueTable, defense)
    LGBT.useComponent(defense, "beforeNormalDefence", __tmpValueTable, attack)
    value = __tmpValueTable[1]
    if value<1 then
        value = 1
    end
    -- --埃及艳后专属技能 对异性英雄造成伤害增加[c]%，受到异性英雄的伤害减少[d]%
    -- local ps = GMethod.loadScript("data.StaticData").getData("mskdatas",4330,1)
    -- if a_info.sex and a_info.id==4030 and  d_info.sex==1 then
    --     value = value * (1+ps.c)--提升的参数,暂不确定是这个
    -- end
    -- if a_info.sex and a_info.sex==1 and  d_info.id==4030 then
    --     value = value * (1-ps.d)--降低的参数,暂不确定是这个
    -- end
    return value
end

function BattleUtil.getSkillHurt(attack,defense,a,b)
    if not attack or not defense then
        return 0
    end
    local value
    local a_info = attack.avtInfo
    local d_info = defense.avtInfo

    local iscritical = a_info.critical - d_info.dscritical
    if _globalRd:random2() <= iscritical then
        iscritical = true
    else
        iscritical = false
    end
    if not b then
        b = 0
    end
    value = (a_info.atk*b/100+a)*a_info.hurtParam*d_info.defenseParam*d_info.base_sdefParam
    value = iscritical and value*a_info.criticalNum or value
    __tmpValueTable[1] = value
    LGBT.useComponent(attack, "beforeSkillAttack", __tmpValueTable, defense)
    LGBT.useComponent(defense, "beforeSkillDefence", __tmpValueTable, attack)
    value = __tmpValueTable[1]
    if value < 1 then
        value = 1
    end
    -- --埃及艳后专属技能 对异性英雄造成伤害增加[c]%，受到异性英雄的伤害减少[d]%
    -- local ps = GMethod.loadScript("data.StaticData").getData("mskdatas",self.sid+300,1)
    -- if a_info.sex and a_info.id==4030 and  d_info.sex==1 then
    --     value = value * (1+ps.c)--提升的参数,暂不确定是这个
    -- end
    -- if a_info.sex and a_info.sex==1 and  d_info.id==4030 then
    --     value = value * (1-ps.d)--降低的参数,暂不确定是这个
    -- end
    return value
end

function BattleUtil.getHeal(healer,behealer,a,b)
    local value
    b = b or 0
    local a_info = healer.avtInfo
    local d_info = behealer.avtInfo

    value = (a_info.atk*b/100+a)*d_info.healps
    return -value
end

GEngine.export("BattleUtil",BattleUtil)
