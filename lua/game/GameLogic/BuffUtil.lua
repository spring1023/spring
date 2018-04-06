local BuffUtil = {allBuff = {{},{}}}

--lastedTime 持续时间
--bfAtkAdd 攻击固定值增加
--bfAtkPct 攻击百分比增加
--bfHpPct  血量百分比增加
--bfDefPct  减伤率
--bfAtkSpeedPct 攻速百分比
--bfMovePct  移速百分比
--bfHurt  最终伤害
--bfDizziness     眩晕
--bfHealps      治疗效果
--bfRebound   反弹伤害
--bfRebound1   反弹普攻伤害
--bfRebound2   反弹技能伤害
--bfReAtk   反射攻击力伤害
--bfSilent  沉默
--immune    免疫伤害
--cantRebirth   死亡不能复活
--clearGain   清楚增益效果
--bfSuckBlood 吸血
--lastAddHp  持续回血
--critical 暴击率
--dscritical 抗暴率
--criticalNum 暴击倍率

--view的变化
--viewGhost  身上出现镜像
--viewChange 自身变化
--ctDizziness 免疫眩晕


function BuffUtil.setBuff(target,buff,key)
    if target.deleted or target.isHide then
        return
    end

    local avtInfo = target.avtInfo
    -- 免疫眩晕的逻辑
    if target.allBuff.ctEffectBuff then
        if buff.bfDizziness or buff.bfSilent or buff.isDebuff or buff.cantRebirth then
            return
        elseif buff.bfAtkPct and buff.bfAtkPct < 0 then
            return
        elseif buff.bfMovePct and buff.bfMovePct < 0 then
            return
        elseif buff.bfAtkSpeedPct and buff.bfAtkSpeedPct < 0 then
            return
        elseif buff.bfDefPct and buff.bfDefPct < 0 then
            return
        elseif buff.lastAddHp and buff.lastAddHp < 0 then
            return
        elseif buff.bfHealps and buff.bfHealps < 0 then
            return
        end
    end
    if buff.bfDizziness then
        --眩晕
        if avtInfo.ctDizziness > 0 then
            return
        end
        if avtInfo.minusDizz then
            if buff.lastedTime <= avtInfo.minusDizz then
                return
            end
            buff.lastedTime = buff.lastedTime - avtInfo.minusDizz
            buff.bfDizziness = buff.bfDizziness - avtInfo.minusDizz
        end
    end

    if buff.cantKey then
        if not target.cantAddBuff then
            target.cantAddBuff = {}
        end
        if target.cantAddBuff[buff.cantKey] then
            return
        else
            target.cantAddBuff[buff.cantKey] = buff
        end
    end

    if key then
        buff.allTime = buff.allTime or 0
        target.allBuff[key] = buff
    else
        buff.allTime = 0
        table.insert(target.allBuff,buff)
    end
    if buff.buffComponent then
        BuffUtil.addBuffComponent(target, buff.buffComponent)
    end

    avtInfo.atk = avtInfo.atk+(buff.bfAtkAdd or 0)+avtInfo.base_atk*(buff.bfAtkPct or 0)/100 --攻击
    if buff.bfAtkSpeedPct then
        avtInfo.attackScale = avtInfo.attackScale+(buff.bfAtkSpeedPct/100) * avtInfo.attackScale_base
    end
    avtInfo.moveScale = avtInfo.moveScale+(buff.bfMovePct or 0)/100 * avtInfo.moveScale_base

    if buff.sdefParam then -- 技能减伤
        avtInfo.base_sdefParam = avtInfo.base_sdefParam*(1-buff.sdefParam/100)
    end
    if buff.bfHpAdd then -- 生命上限
        avtInfo.maxHp = avtInfo.maxHp + buff.bfHpAdd
        avtInfo.nowHp = avtInfo.nowHp + buff.bfHpAdd
    end
    avtInfo.hurtParam = avtInfo.hurtParam*(1+(buff.bfHurt or 0)/100)
    avtInfo.defenseParam = avtInfo.defenseParam*(1-(buff.bfDefPct or 0)/100) --减伤率
    avtInfo.rating = avtInfo.base_rating      --命中
    avtInfo.dodge = avtInfo.dodge + (buff.bfDodge or 0)/100       --闪避
    avtInfo.critical = avtInfo.critical+(buff.critical or 0)/100  --暴击率
    avtInfo.dscritical = avtInfo.dscritical+(buff.dscritical or 0)/100 --抗爆率
    avtInfo.criticalNum = avtInfo.criticalNum+(buff.criticalNum or 0)/100 --暴击倍率
    avtInfo.healps = avtInfo.healps+(buff.bfHealps or 0)/100    --治疗率
    avtInfo.bfRebound = avtInfo.bfRebound+(buff.bfRebound or 0) --反弹
    avtInfo.bfRebound1 = avtInfo.bfRebound1+(buff.bfRebound1 or 0) --反弹
    avtInfo.bfRebound2 = avtInfo.bfRebound2+(buff.bfRebound2 or 0) --反弹
    avtInfo.bfReAtk = avtInfo.bfReAtk+(buff.bfReAtk or 0) --反射
    if buff.bfSuckBlood then      --吸血
        if not avtInfo.bfSuckBlood then
            avtInfo.bfSuckBlood = {0}
        end
        avtInfo.bfSuckBlood[1] = avtInfo.bfSuckBlood[1] + buff.bfSuckBlood[1]
        if buff.bfSuckBlood[2] then
            avtInfo.bfSuckBlood[2] = (avtInfo.bfSuckBlood[2] or 0) + buff.bfSuckBlood[2]
        end
        if buff.bfSuckBlood[3] then
            if not avtInfo.bfSuckBlood[3] then
                avtInfo.bfSuckBlood[3] = {0, 0}
            end
            avtInfo.bfSuckBlood[3][1] = avtInfo.bfSuckBlood[3][1] + buff.bfSuckBlood[3][1]
            avtInfo.bfSuckBlood[3][2] = avtInfo.bfSuckBlood[3][2] + buff.bfSuckBlood[3][2]
        end
    end
    if buff.bfSputter then
        avtInfo.bfSputter = buff.bfSputter  --溅射
    end
    avtInfo.bfSilent = avtInfo.bfSilent + (buff.bfSilent or 0)     --沉默
    avtInfo.clearGain = avtInfo.clearGain + (buff.clearGain or 0)       --清除增益效果
    --眩晕
    if buff.bfDizziness then
        avtInfo.bfDizziness = avtInfo.bfDizziness + buff.bfDizziness
    end

    avtInfo.immune = avtInfo.immune + (buff.immune or 0)
    avtInfo.cantRebirth = avtInfo.cantRebirth + (buff.cantRebirth or 0)
    avtInfo.beKill = buff.beKill

    if buff.ctDizziness then
        avtInfo.ctDizziness = avtInfo.ctDizziness + buff.ctDizziness
    end
    --view
    local avater = target.avater
    if buff.viewGhost then
        avater.viewGhost = buff.viewGhost
    end
    if buff.viewChange then
        avater.viewChange = buff.viewChange
    end
end

-- 设置被动技能型方法，持续整场战斗，不可被驱逐
-- 说白了就是直接设置avtInfo的属性
function BuffUtil.setStaticBuff(target, buffKey, buffValue)
    local avtInfo = target.avtInfo
    if not avtInfo[buffKey .. "_base"] then
        avtInfo[buffKey .. "_base"] = avtInfo[buffKey] or 0
    end
    avtInfo[buffKey] = (avtInfo[buffKey] or 0) + buffValue
end

local keyIdx = 0
function BuffUtil.setAllBuff(buff)
    BuffUtil.allBuff[buff.tg][buff.keyAppoint or tostring(keyIdx)] = buff
    keyIdx = keyIdx+1
    buff.allTime = 0
    local scene = GMethod.loadScript("game.View.Scene")
    if not BuffUtil.isAddAllBuffUp then
        BuffUtil.isAddAllBuffUp = true
        local function tempUpdateAll(self, diff)
            BuffUtil.updateAllBuff(diff)
        end
        scene.replay:addUpdateObj({update=tempUpdateAll})
    end
end

function BuffUtil.clearAll()
    keyIdx = 0
    BuffUtil.isAddAllBuffUp = nil
    BuffUtil.allBuff = {{},{},{}}
end
local TeamSkillsEffect=GMethod.loadScript("game.GameEffect.TeamSkillsEffect").new()
function BuffUtil.updateAllBuff(diff)
    local scene = GMethod.loadScript("game.View.Scene")
    for k,v in ipairs(BuffUtil.allBuff) do
        for key,buff in pairs(v) do
            buff.allTime = buff.allTime+diff
            if buff.allTime>buff.lastedTime then
                buff = nil
            else
                local tgT
                if k == 1 then
                    tgT = scene.battleMap2.hero
                elseif k == 2 then
                    tgT = scene.battleMap.hero
                end
                if buff.tgAppoint then
                    tgT = buff.tgAppoint()
                end
                for k1,v1 in pairs(tgT) do
                    if not v1.deleted and not v1.allBuff[key] then
                        local b = clone(buff)
                        BuffUtil.setBuff(v1,b,key)
                        if key == "HeroTrialSkill2" then
                            TeamSkillsEffect:showEffect_XingFengJi(v1.V.view,0,v1.V.animaConfig.Ymove+150,{t = b.lastedTime})
                        end
                    end
                end
            end
        end
    end
end

function BuffUtil.updateBuff(target, diff)
    for k,buff in pairs(target.allBuff) do
        buff.allTime = buff.allTime + diff
        if (buff.lastedTime and buff.allTime > buff.lastedTime) or (type(k) == "table" and k.deleted) then
            target.allBuff[k]=nil
            if buff.effect then
                buff.effect:runAction(ui.action.sequence({{"fadeOut",1},"remove"}))
            end
            if buff.buffComponent then
                BuffUtil.removeBuffComponent(target, buff.buffComponent)
            end
            local avtInfo = target.avtInfo
            if buff.sdefParam then -- 技能减伤
                avtInfo.base_sdefParam = avtInfo.base_sdefParam/(1-buff.sdefParam/100)
            end
            if buff.bfHpAdd then  -- 生命上限
                avtInfo.maxHp = avtInfo.maxHp - (buff.bfHpAdd or 0)
                if avtInfo.nowHp > avtInfo.maxHp then
                    avtInfo.nowHp = avtInfo.maxHp
                end
            end
            avtInfo.atk = avtInfo.atk-(buff.bfAtkAdd or 0)-avtInfo.base_atk*(buff.bfAtkPct or 0)/100 --攻击
            avtInfo.attackScale = avtInfo.attackScale-(buff.bfAtkSpeedPct or 0)/100 * avtInfo.attackScale_base
            avtInfo.moveScale = avtInfo.moveScale-(buff.bfMovePct or 0)/100 * avtInfo.moveScale_base
            avtInfo.hurtParam = avtInfo.hurtParam/(1+(buff.bfHurt or 0)/100)
            avtInfo.defenseParam = avtInfo.defenseParam/(1-(buff.bfDefPct or 0)/100)
            avtInfo.rating = avtInfo.base_rating      --命中
            avtInfo.dodge = avtInfo.dodge - (buff.bfDodge or 0)/100        --闪避
            avtInfo.critical = avtInfo.critical-(buff.critical or 0)/100  --暴击率
            avtInfo.dscritical = avtInfo.dscritical-(buff.dscritical or 0)/100 --抗爆率
            avtInfo.criticalNum = avtInfo.criticalNum-(buff.criticalNum or 0)/100 --暴击倍率
            avtInfo.healps = avtInfo.healps-(buff.bfHealps or 0)/100    --治疗率
            avtInfo.cantRebirth = avtInfo.cantRebirth - (buff.cantRebirth or 0) --死亡不能复活

            --眩晕
            avtInfo.bfDizziness = avtInfo.bfDizziness - (buff.bfDizziness or 0)
            avtInfo.bfRebound = avtInfo.bfRebound-(buff.bfRebound or 0) --反弹
            avtInfo.bfRebound1 = avtInfo.bfRebound1-(buff.bfRebound1 or 0) --反弹
            avtInfo.bfRebound2 = avtInfo.bfRebound2-(buff.bfRebound2 or 0) --反弹
            avtInfo.bfSilent = avtInfo.bfSilent - (buff.bfSilent or 0)     --沉默
            avtInfo.immune = avtInfo.immune - (buff.immune or 0)
            avtInfo.clearGain = avtInfo.clearGain - (buff.clearGain or 0)   --清除增益效果
            if buff.bfSuckBlood then   --吸血
                if avtInfo.bfSuckBlood then
                    avtInfo.bfSuckBlood[1] = avtInfo.bfSuckBlood[1] - buff.bfSuckBlood[1]
                    if buff.bfSuckBlood[2] and avtInfo.bfSuckBlood[2] then
                        avtInfo.bfSuckBlood[2] = avtInfo.bfSuckBlood[2] - buff.bfSuckBlood[2]
                        if avtInfo.bfSuckBlood[2] <= 0 then
                            avtInfo.bfSuckBlood[2] = nil
                        end
                    end
                    if buff.bfSuckBlood[3] and avtInfo.bfSuckBlood[3] then
                        avtInfo.bfSuckBlood[3][1] = avtInfo.bfSuckBlood[3][1] - buff.bfSuckBlood[3][1]
                        avtInfo.bfSuckBlood[3][2] = avtInfo.bfSuckBlood[3][2] - buff.bfSuckBlood[3][2]
                        if avtInfo.bfSuckBlood[3][1] <= 0 and avtInfo.bfSuckBlood[3][2] <= 0 then
                            avtInfo.bfSuckBlood[3] = nil
                        end
                    end
                    if avtInfo.bfSuckBlood[1] <= 0 and not avtInfo.bfSuckBlood[2] and not avtInfo.bfSuckBlood[3] then
                        avtInfo.bfSuckBlood = nil
                    end
                end
            end
            if buff.bfSputter then
                avtInfo.bfSputter = nil     --溅射
            end
            if buff.cantKey then
                if target.cantAddBuff then
                    target.cantAddBuff[buff.cantKey] = nil
                end
            end
            if buff.beKill then
                avtInfo.beKill = nil        --击杀者加成
            end

            --清除增益效果
            if avtInfo.clearGain>0 then
                BuffUtil.clearGain(avtInfo,buff)
            end
            --存活时间
            if buff.canLive then
                target:damage(10000000)
            end

            if buff.ctDizziness then
                avtInfo.ctDizziness = avtInfo.ctDizziness - buff.ctDizziness
            end

            --view
            local avater = target.avater
            if buff.viewGhost then
                avater.viewGhost = nil
            end
            if buff.viewChange then
                avater.viewChange = nil
            end
        end


        --持续回血
        if buff.lastAddHp then
            if not buff.dtime then
                buff.dtime = 0
            end
            buff.dtime = buff.dtime+diff
            if buff.dtime>=(buff.dtimeAppoint or 1) then
                buff.dtime = buff.dtime-(buff.dtimeAppoint or 1)
                local value = -(buff.lastAddHp/buff.lastedTime*(buff.dtimeAppoint or 1))
                if value>0 then
                    SkillPlugin.exe2(buff.damager or target, target, value, 0)
                else
                    SkillPlugin.exe7(buff.damager or target, target, -value, 0)
                end
            end
        end
    end
end

function BuffUtil.clearGain(avtInfo,buff)
    if buff.bfAtkAdd and buff.bfAtkAdd>0 then
        avtInfo.atk = avtInfo.atk-buff.bfAtkAdd
        buff.bfAtkAdd = nil
    end
    if buff.bfAtkPct and buff.bfAtkPct>0 then
        avtInfo.atk = avtInfo.atk-avtInfo.base_atk*(buff.bfAtkPct or 0)/100 --攻击
        buff.bfAtkPct = nil
    end
    if buff.bfAtkSpeedPct and buff.bfAtkSpeedPct>0 then
        avtInfo.attackScale = avtInfo.attackScale-(buff.bfAtkSpeedPct or 0)/100 * avtInfo.attackScale_base
        buff.bfAtkSpeedPct = nil
    end
    if buff.bfMovePct and buff.bfMovePct>0 then
        avtInfo.moveScale = avtInfo.moveScale-(buff.bfMovePct or 0)/100 * avtInfo.moveScale_base
        buff.bfMovePct = nil
    end
    if buff.bfHurt and buff.bfHurt>0 then
        avtInfo.hurtParam = avtInfo.hurtParam/(1+(buff.bfHurt or 0)/100)
        buff.bfHurt = nil
    end
    if buff.bfDefPct and buff.bfDefPct>0 then
        avtInfo.defenseParam = avtInfo.defenseParam/(1-(buff.bfDefPct or 0)/100)
        buff.bfDefPct = nil
    end
    avtInfo.rating = avtInfo.base_rating      --命中
    if buff.bfDodge and buff.bfDodge>0 then
        avtInfo.dodge = avtInfo.dodge - (buff.bfDodge or 0)/100        --闪避
        buff.bfDodge = nil
    end
    avtInfo.critical = avtInfo.base_critical  --暴击率
    avtInfo.dscritical = avtInfo.base_dscritical --抗爆率
    avtInfo.criticalNum = avtInfo.base_criticalNum --暴击倍率
    if buff.bfHealps and buff.bfHealps>0 then
        avtInfo.healps = avtInfo.healps-(buff.bfHealps or 0)/100    --治疗率
        buff.bfHealps = nil
    end
    avtInfo.cantRebirth = avtInfo.cantRebirth - (buff.cantRebirth or 0) --死亡不能复活

    --眩晕
    avtInfo.bfRebound = avtInfo.bfRebound-(buff.bfRebound or 0) --反弹
    avtInfo.bfRebound1 = avtInfo.bfRebound1-(buff.bfRebound1 or 0) --反弹
    avtInfo.bfRebound2 = avtInfo.bfRebound2-(buff.bfRebound2 or 0) --反弹
    avtInfo.bfReAtk  = avtInfo.bfReAtk-(buff.bfReAtk or 0) --反射
    avtInfo.bfSilent = avtInfo.bfSilent - (buff.bfSilent or 0)     --沉默
    avtInfo.immune = avtInfo.immune - (buff.immune or 0)
    avtInfo.clearGain = avtInfo.clearGain - (buff.clearGain or 0)   --清除增益效果
    if buff.bfSuckBlood then
        avtInfo.bfSuckBlood = nil   --吸血
    end
    if buff.bfSputter then
        avtInfo.bfSputter = nil     --溅射
    end
    if buff.cantKey then
        if target and target.cantAddBuff then
            target.cantAddBuff[buff.cantKey] = nil
        end
    end
end

do
    local __buffCountCache = {}
    local __buffCountNum = 0
    -- 添加buff组件
    function BuffUtil.addBuffComponent(target, component)
        if not target._component_buffs then
            target._component_buffs = {}
        end
        if target._component_buffs[component._viewTag] then
            return
        else
            target._component_buffs[component._viewTag] = component
            component:addView(target)
        end
    end

    -- 移除buff组件
    function BuffUtil.removeBuffComponent(target, component)
        if not target._component_buffs then
            return
        end
        if not target._component_buffs[component._viewTag] then
            return
        else
            component = target._component_buffs[component._viewTag]
            component:removeView(target)
            target._component_buffs[component._viewTag] = nil
        end
    end

    -- 移除所有buff组件
    function BuffUtil.removeAllBuffComponents(target)
        if not target._component_buffs then
            return
        end
        for k, v in pairs(target._component_buffs) do
            v:removeView(target)
        end
        target._component_buffs = nil
    end

end

GEngine.export("BuffUtil",BuffUtil)
