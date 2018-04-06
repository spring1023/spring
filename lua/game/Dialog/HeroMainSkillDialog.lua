local const = GMethod.loadScript("game.GameLogic.Const")

HeroMainSkillDialog = class()

function HeroMainSkillDialog:ctor(parent, context, heroMsg)
    self.parent = parent
    self.context = context
    self.heroMsg = heroMsg
    self:initView()
end

function HeroMainSkillDialog:initView()
    DialogTemplates.loadDefaultTemplate(self, 3, display.getDialogPri()+1, {1514,1136})
    local bg, temp = self.view
    RegLife(bg, Handler(self.onLifeCycle, self))
    GameUI.addSkillIcon(bg, 1, self.heroMsg.info.mid, 1, 757, 833)

    temp = ui.label("", General.font1, 40)
    display.adapt(temp, 757, 690, GConst.Anchor.Center)
    bg:addChild(temp)
    self.levelLabel = temp

    temp = ui.label(StringManager.getString("labelCurLevel"), General.font1, 43, {color={255,255,255},width=241,align=GConst.Align.Left})
    display.adapt(temp, 53, 621, GConst.Anchor.LeftTop)
    bg:addChild(temp)
    temp = ui.label(StringManager.getString("labelNextLevel"), General.font1, 43, {color={255,255,255},width=241,align=GConst.Align.Left})
    display.adapt(temp, 53, 394, GConst.Anchor.LeftTop)
    bg:addChild(temp)

    temp = ui.label("", General.font2, 35, {color={30,91,165},width=1083,align=GConst.Align.Left})
    display.adapt(temp, 341, 621, GConst.Anchor.LeftTop)
    bg:addChild(temp)
    self.l1label = temp

    temp = ui.label("", General.font2, 35, {color={30,91,165},width=1083,align=GConst.Align.Left})
    display.adapt(temp, 341, 394, GConst.Anchor.LeftTop)
    bg:addChild(temp)
    self.l2label = temp

    temp = ui.button({264, 104}, self.onUpgradeMainSkill, {cp1=self, image="images/btnGreen.png"})
    display.adapt(temp, 757, 107, GConst.Anchor.Center)
    bg:addChild(temp)
    self.upgradeBut = temp
    local but=temp:getDrawNode()
    temp = ui.label("", General.font1, 40)
    display.adapt(temp, 117, 62, GConst.Anchor.Center)
    but:addChild(temp)
    self.upgradeLabel = temp
    self.upgradeIcon = GameUI.addResourceIcon(but, const.ResSpecial, 0.58, 147, 60)

    self:reloadAll()
end

function HeroMainSkillDialog:onLifeCycle(event)
    if event=="exit" then
        if self.parent and not self.parent:getDialog().deleted and self.needReload then
            self.parent:reloadMainSkills(true)
        end
    end
end

function HeroMainSkillDialog:reloadAll()
    if self.heroMsg.mSkillLevel<const.MaxMainSkillLevel then
        local lv = self.heroMsg.mSkillLevel+1
        self.title:setString(Localizef("titleUpgrade",{level=lv}))
        self.l2label:setString(self.heroMsg:getSkillDesc(lv))
        local costData = self.heroMsg:getMainSkillCost(lv)
        if costData.cvalue>self.context:getRes(const.ResSpecial) then
            ui.setColor(self.upgradeLabel, GConst.Color.Red)
        else
            ui.setColor(self.upgradeLabel, GConst.Color.White)
        end
        self.upgradeLabel:setString(N2S(costData.cvalue))
        self.upgradeBut:setGray(false)
    else
        self.title:setString(Localize("labelLevelMax"))
        ui.setColor(self.upgradeLabel, GConst.Color.White)
        self.upgradeLabel:setString(Localize("labelLevelMax"))
        self.upgradeBut:setGray(true)
        self.upgradeBut:setVisible(false)
        self.l2label:setString(Localize("labelLevelMax"))
    end
    local w = self.upgradeLabel:getContentSize().width*self.upgradeLabel:getScaleX()
    self.upgradeIcon:setPositionX(147+w/2)
    self.l1label:setString(self.heroMsg:getSkillDesc())
    self.levelLabel:setString(Localizef("labelHeroLevel",{num=self.heroMsg.mSkillLevel, max=const.MaxMainSkillLevel}))
end

function HeroMainSkillDialog:onUpgradeMainSkill()
    if self.heroMsg.mSkillLevel>=const.MaxMainSkillLevel then
        return
    end
    local lv = self.heroMsg.mSkillLevel+1
    local costData = self.heroMsg:getMainSkillCost(lv)
    if costData.cvalue>self.context:getRes(const.ResSpecial) then
        display.showDialog(AlertDialog.new({ctype=const.ResSpecial, cvalue=costData.cvalue, callback=Handler(self.onUpgradeMainSkill, self)}))
    elseif self.context.heroData:upgradeMainSkill(self.heroMsg) then
        self.needReload = true
        self:reloadAll()
        music.play("sounds/mercenary_upgrade.mp3")
        UIeffectsManage:showEffect_jinengshenji(self.view,757,833,1)
    end
end
