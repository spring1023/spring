local DHEffect = class()

function DHEffect:ctor(params)
    if params.attacker.deleted then
        return
    end
    self.scene = GMethod.loadScript("game.View.Scene")
    self:initParams(params)
    self:initEffect()
end

function DHEffect:initParams(params)
    self.baseEffect=GameEffect.new("Equipment2Effect.json")
    self.views=self.baseEffect.views
    self.attacker = params.attacker
    self.viewsNode = self.attacker.view
    self.lastedTime = params.lastedTime
    self.delayNode=self.scene.delayNode
end

function DHEffect:initEffect()
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

function DHEffect:addAnimate()
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

--巨龙之心 英雄在成功闪避敌人攻击时，有a%的概率回血b%；此外，该英雄每受到30次数后。会获得一个存在5秒的护盾，护盾可以使英雄闪避提升c%
local DragonHeart = class()

function DragonHeart:ctor(hero)
    self.damageTimes = 0
    self.hero = hero
    local equip = hero.person.equip
    if equip and equip.id == 2002 and not hero.params.isZhaoHuan then
        self.haveEquip = true
    end
    if self.haveEquip then
        local bg = hero.V.blood
        if not bg then
            return
        end
        GameUI.addBattleEquipIcon(bg,equip,bg:getContentSize().width/2,50)
        if self.hero.state ~= 4 then      -- 4是Operation状态
            self:inintProgressBar(bg,hero)
        end
    end
end

function DragonHeart:exe(value)
    local hero = self.hero
    local equip = hero.person.equip
    if not self.haveEquip then
        return
    end
    local eps = equip.params
    local a,b,c = eps.a,eps.b,eps.c
    --成功闪避后
    if value==0 then
        if hero.rd:randomInt(100)<=a then
            local addHp = hero.M.maxHp*b/100
            local vl = BattleUtil.getHeal(hero,hero,addHp,0)
            hero:damage(vl)
        end
    end

    self.damageTimes = self.damageTimes+1
    self:updateProgressBar()
    if self.damageTimes>=30 then
        local buff = hero.allBuff.dragonHeartBuff
        if buff then
            buff.lastedTime = -1
        end
        BuffUtil.updateBuff(hero, 0)
        local buff = {
            lastedTime = 5,
            bfDodge = c,
        }
        BuffUtil.setBuff(hero,buff,"dragonHeartBuff")
        self.damageTimes = 0
        if self.efView then
            self.efView.upNode:stopAllActions()
            self.efView.downNode:stopAllActions()
            self.efView.upNode:runAction(ui.action.sequence({{"delay",5},{"call",function()
                self.efView = nil
            end},"remove"}))
            self.efView.downNode:runAction(ui.action.sequence({{"delay",5},{"call",function()
                self.efView = nil
            end},"remove"}))
        else
            self.efView = DHEffect.new({attacker = hero.V})
            self.efView.upNode:runAction(ui.action.sequence({{"delay",5},{"call",function()
                self.efView = nil
            end},"remove"}))
            self.efView.downNode:runAction(ui.action.sequence({{"delay",5},{"call",function()
                self.efView = nil
            end},"remove"}))
        end
    end
end

--==============================--
--desc:装备特效进度条初始化
--time:2018-01-10 10:24:48
--author:aoyue
--@args:parentNode hero
--@return nil
--==============================--
function DragonHeart:inintProgressBar(bg,hero)
    local sp = ui.scale9("images/equipProRed.png", 0, {85, 85})
    local progressCharge=cc.ProgressTimer:create(sp)
    display.adapt(progressCharge,bg:getContentSize().width/2+bg._ox,bg._oy+50,GConst.Anchor.Center)
    bg:addChild(progressCharge,51)
    progressCharge:setReverseDirection(true)
    self.progressCharge=progressCharge
    self.progressCharge:setPercentage(100)

    local sp = ui.scale9("images/equipProGreen.png", 0, {85, 85})
    local progressCharged=cc.ProgressTimer:create(sp)
    display.adapt(progressCharged,bg:getContentSize().width/2+bg._ox,bg._oy+50,GConst.Anchor.Center)
    bg:addChild(progressCharged,51)
    progressCharged:setReverseDirection(true)
    self.progressCharged=progressCharged
    self.progressCharged:setPercentage(0)
end
--==============================--
--desc:装备特效进度条状态更新
--time:2018-01-09 16:37:02
--@return nil
--==============================--
function DragonHeart:updateProgressBar()
    local function onEffectFinished()
        self.progressCharge:setVisible(true)
    end
    if tolua.isnull(self.progressCharge) or tolua.isnull(self.progressCharged) then
        return
    end
    self.progressCharge:setVisible(self.progressCharged:getPercentage()==0) 
    self.progressCharge:setPercentage((30-self.damageTimes)/3*10)
    if self.damageTimes>=30 then
        self.progressCharge:setPercentage(0)
        self.progressCharged:setPercentage(100)
        local action=cc.ProgressTo:create(5,0)
        self.progressCharged:runAction(ui.action.sequence{action,{"call",onEffectFinished}})
    end
end
return DragonHeart


