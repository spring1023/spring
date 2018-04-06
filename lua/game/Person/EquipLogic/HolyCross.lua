--圣眷十字（不死之心）

local HolyCrossEffect = class()

function HolyCrossEffect:ctor(params)
    if params.attacker.deleted then
        return
    end
    self.scene = GMethod.loadScript("game.View.Scene")
    self:initParams(params)
    self:initEffect()
end

function HolyCrossEffect:initParams(params)
    self.baseEffect=GameEffect.new("HolyCrossEffect.json")
    self.views=self.baseEffect.views
    self.attacker = params.attacker
    self.viewsNode = self.attacker.view
    self.lastedTime = params.lastedTime
    self.delayNode=self.scene.delayNode
end

function HolyCrossEffect:initEffect()
    local bg = self.viewsNode
    local x,y,z=0, self.attacker.animaConfig.Ymove,10
    local downNode=ui.node()
    downNode:setPosition(x,y)
    bg:addChild(downNode)
    self.baseEffect:addEffect("downViews",downNode)

    local upNode=ui.node()
    upNode:setPosition(x,y)
    bg:addChild(upNode,z)
    self.upNode = upNode
    self.downNode = downNode
    self.baseEffect:addEffect("upViews",upNode)
    self:addAnimate()
end

function HolyCrossEffect:addAnimate()
    local totalTime=1000000
    local temp
    temp=self.views.Glow1
    temp:runAction(ui.action.sequence({{"fadeIn",10/60},{"fadeOut",10/60},"remove"}))

    temp=self.views.Glow2
    temp:runAction(ui.action.sequence({{"fadeIn",10/60},{"fadeOut",10/60},"remove"}))

    temp=self.views.shield
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeIn",25/60},{"delay",totalTime-55/60},{"fadeOut",30/60}})))
    temp:runAction(ui.action.sequence({{"delay",totalTime},"remove"}))
    temp=self.views.Shield_00000_4_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeIn",25/60},{"delay",totalTime-55/60},{"fadeOut",30/60}})))
    temp:runAction(ui.action.sequence({{"delay",totalTime},"remove"}))
    temp=self.views.Shield_00000_4_0_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",25/60,115},{"delay",totalTime-55/60},{"fadeOut",30/60}})))
    temp:runAction(ui.action.sequence({{"delay",totalTime},"remove"}))

    temp=self.views.loop
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",25/60,64},{"delay",totalTime-55/60},{"fadeOut",30/60}})))
    temp:runAction(ui.action.sequence({{"delay",totalTime},"remove"}))
    temp=self.views.Loop_00000_5_0
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeIn",25/60},{"delay",totalTime-55/60},{"fadeOut",30/60}})))
    temp:runAction(ui.action.sequence({{"delay",totalTime},"remove"}))
end
--在装备英雄死亡后触发复活效果，装备英雄在死亡a秒后复活，并回复生命值上限b%+c的血量，复活效果每场战斗只能触发一次
local HolyCross = class()
local _animateTime = 0.6

function HolyCross:ctor(hero)
    self.hero = hero
    local equip = hero.person.equip
    if equip and equip.id == 2005 and not hero.params.isZhaoHuan and not hero.params.holyRebirthed then
        self.haveEquip = true
        LGBT.addComponentFunc(hero, "beforeDie", Handler(self.exe, self))
    end
    if self.haveEquip then
        local bg = hero.V.blood
        if not bg then
            return
        end
        GameUI.addBattleEquipIcon(bg,equip,bg:getContentSize().width/2,50)
    end
end

-- @brief 复活动画第二阶段
function HolyCross:realRebirth(scene)
    if scene.replay and scene.replay.isBattleEnd then
        return
    end
    UIeffectsManage:showEffect_busizhixinfuhuo(self.effectsNode,0,0,1)
    self.effectsNode:runAction(ui.action.sequence({{"delay",_animateTime},"remove"}))
end

-- @brief 执行复活逻辑
function HolyCross:exe(hero)
    local equip = hero.person.equip
    -- 召唤物或已重生不能重复重生
    if hero.isRebirthed then
        return
    end
    local eps = equip.params
    local a, b, c = eps.a, eps.b, eps.c
    -- 因为要放动画，所以不要提前结束战斗
    local scene = hero.scene
    if scene.objs then
        self.effectsNode = self:addFuhuoEffets(hero)
        scene.objs:addChild(self.effectsNode, 100000)
        self.effectsNode:runAction(ui.action.sequence({{"delay",a},{"call",Handler(self.realRebirth, self, scene)}}))
    end
    hero.params.holyRebirthed = (hero.params.holyRebirthed or 0) + 1
    local newHero = hero:normalRebirth(hero.avater.gx, hero.avater.gy, false, a + _animateTime)
    local maxHp = newHero.avtInfo.maxHp
    local dv = maxHp-(maxHp*b/100+c)
    if dv>0 and dv < maxHp then
        newHero:damage(dv)
    end
    newHero.V.personView:setOpacity(0)
    newHero.V.personView:runAction(ui.action.sequence({{"delay", a}, {"fadeTo", _animateTime, 255}}))
    if newHero.V.shadow then
        newHero.V.shadow:setOpacity(0)
        newHero.V.shadow:runAction(ui.action.sequence({{"delay", a}, {"fadeTo", _animateTime, 255}}))
    end
    if newHero.V.blood then
        newHero.V.blood:setOpacity(0)
        newHero.V.blood:runAction(ui.action.sequence({{"delay", a}, {"fadeTo", _animateTime, 255}}))
    end
end

function HolyCross:addFuhuoEffets(hero)
    local scene = GMethod.loadScript("game.View.Scene")
    local gx, gy = hero.avater.gx, hero.avater.gy
    local _x,_y = scene.map.convertToPosition(gx,gy)
    local _node = ui.node()
    display.adapt(_node,_x,_y+70,GConst.Anchor.Center)

    local _sp1 = ui.sprite("images/items/equipIcon2005.png")
    display.adapt(_sp1,0,0,GConst.Anchor.Center)
    _sp1:setScale(0.8)
    _node:addChild(_sp1)

    UIeffectsManage:showEffect_busizhixin(_node,25,0,0,_animateTime)
    return _node
end

return HolyCross


