--狂暴

--装备英雄入场后进入狂暴状态，获得a点生命上限，b点攻击力，增加c攻速，d移速，持续n秒
local Rage = class()

function Rage:ctor(hero)
    self.hero = hero
    local equip = hero.person.equip
    if equip and equip.id == 2007 and not hero.params.isZhaoHuan then
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

function Rage:exe()
    local hero = self.hero
    local equip = hero.person.equip
    if not self.haveEquip then
        return
    end
    local eps = equip.params
    local a,b,c,d,n = eps.a,eps.b,eps.c,eps.d,eps.n
    hero.M.maxHp = hero.M.maxHp+a
    hero.M.nowHp = hero.M.nowHp+a
    BuffUtil.setBuff(hero,{lastedTime=n, bfAtkAdd=b, bfAtkSpeedPct=c, bfMovePct=d})
    self:updateProgressBar(n)
    local avater = hero.avater
    local glow
    if avater.personView and avater.shadow then
        avater.view:setScale(1.5)
        --avater.personView:setColor(cc.c3b(255,0,0))
        avater.shadow:setScale(2.5*1.5)
        local temp = ui.sprite("Glow_01.png")
        temp:setColor(cc.c3b(255,0,0))
        local y = avater.animaConfig.Ymove+50
        temp:setPosition(0,y)
        temp:setOpacity(0.6*255)
        avater.view:addChild(temp,10)
        temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeTo",0.4,0.8*255},{"fadeTo",0.4,0.4*255}})))
        -- local blend={}
        -- blend.src=1
        -- blend.dst=1
        -- temp:setBlendFunc(blend)
        glow=temp
    end
    local function huifu()
        if avater.personView and avater.shadow then
            avater.view:runAction(ui.action.scaleTo(0.5,1,1))
            avater.shadow:runAction(ui.action.scaleTo(0.5,2.5,2.5))
            glow:runAction(ui.action.sequence({{"fadeOut",0.5},"remove"}))
        end
    end
    avater.personView:runAction(ui.action.sequence({{"delay",n-0.5},{"call",huifu}}))
end
--==============================--
--desc:装备特效进度条初始化
--time:2018-01-10 10:24:48
--author:aoyue
--@args:parentNode hero
--@return nil
--==============================--
function Rage:inintProgressBar(bg,hero)
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
--time:2018-01-10 11:54:02
--@return nil
--==============================--
function Rage:updateProgressBar(t)
    local function onEffectFinished()
        self.progressCharged:setVisible(false)
    end
    if tolua.isnull(self.progressCharged) then
        return
    end
    self.progressCharged:setPercentage(100)
    local action=cc.ProgressTo:create(t,0)
    self.progressCharged:runAction(ui.action.sequence{action,{"call",onEffectFinished}})
end
return Rage


