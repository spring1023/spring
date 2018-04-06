--磐石

--减少英雄a秒被晕眩时间，提升等级可以继续增强效果
local Rock = class()

function Rock:ctor(hero)
    self.hero = hero
    local equip = hero.person.equip
    if equip and equip.id == 2008 and not hero.params.isZhaoHuan then
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

function Rock:exe()
    local hero = self.hero
    local equip = hero.person.equip
    if not self.haveEquip then
        return
    end
    local eps = equip.params
    local a = eps.a
    BuffUtil.setStaticBuff(hero, "minusDizz", a) --减免眩晕时间
    local avater = hero.avater
    if avater.personView and avater.shadow then
        local temp = ui.csbNode("UICsb/batterEquip2008_1.csb")
        display.adapt(temp,0,0,GConst.Anchor.Center)
        temp:setScale(0.8)
        avater.personView:addChild(temp)
        local action = ui.csbTimeLine("UICsb/batterEquip2008_1.csb")
        temp:runAction(action)
        action:gotoFrameAndPlay(0,true)
    end
end

return Rock


