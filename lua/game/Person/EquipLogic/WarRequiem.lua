--战争挽歌

--装备英雄的全体佣兵获得b点攻击力，c点血量上限，受到的技能伤害降低a%
local WarRequiem = class()

function WarRequiem:ctor(hero)
    self.hero = hero
    local equip = hero.person.equip
    if equip and equip.id == 2006 and not hero.params.isZhaoHuan then
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

function WarRequiem:exe(soldier)
    local hero = self.hero
    local equip = hero.person.equip
    if not self.haveEquip then
        return
    end
    local eps = equip.params
    local a,b,c = eps.a,eps.b,eps.c
    soldier.M.maxHp = soldier.M.maxHp+c
    soldier.M.nowHp = soldier.M.nowHp+c
    --加成时间一直保持

    YonBingDun.new(soldier.V.view,0,20+soldier.V.animaConfig.Ymove,60000)
    BuffUtil.setBuff(soldier,{lastedTime=60000, bfAtkAdd=b, bfDefPct=a})
    --print("bfAtkPct,bfDefPct,max",b,a,c)
end

return WarRequiem


