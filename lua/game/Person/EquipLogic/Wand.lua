--权杖

--增加远程英雄的攻击距离，只对远程英雄有效，提升等级可以继续增强效果
local Wand = class()

function Wand:ctor(hero)
    self.hero = hero
    local equip = hero.person.equip
    if equip and equip.id == 2009 and not hero.params.isZhaoHuan then
        self.haveEquip = true
    end
    if self.haveEquip then
        local bg = hero.V.blood
        if not bg then
            return
        end
        GameUI.addBattleEquipIcon(bg,equip,bg:getContentSize().width/2,50)
    end
end

function Wand:exe(soldier)
    local hero = self.hero
    local equip = hero.person.equip
    if not self.haveEquip then
        return
    end
    local eps = equip.params

    local a = eps.a
    if not soldier then
        -- 英雄的
        if hero.M.range>1 then
            BuffUtil.setStaticBuff(hero, "range", a) --增加攻击距离
            local avater = hero.avater
            if avater.personView and avater.shadow then
                local temp = ui.csbNode("UICsb/batterEquip2009_2.csb")
                display.adapt(temp,0,0,GConst.Anchor.Center)
                avater.personView:addChild(temp,-1)
                local action = ui.csbTimeLine("UICsb/batterEquip2009_2.csb")
                temp:runAction(action)
                action:gotoFrameAndPlay(0,true)
            end
        end
    else
        --佣兵的
        if soldier.BV.M.range>1 then
            BuffUtil.setStaticBuff(soldier, "range", a) --增加攻击距离
        end
    end
end

return Wand


