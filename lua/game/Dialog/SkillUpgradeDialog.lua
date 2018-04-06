local const = GMethod.loadScript("game.GameLogic.Const")

--技能升级的模板对话框，可复用
SkillUpgradeDialog = class(DialogViewLayout)

function SkillUpgradeDialog:onInitDialog()
    self:setLayout("SkillUpgradeDialog.json")
    self:loadViewsTo()
end

function SkillUpgradeDialog:onEnter()
    GameUI.addSkillIcon(self.nodeSkillIcon.view, self.stype, self.sid, 1, 0, 0)
    self.upgradeIcon:setTemplateValue(self.ctype)
    self.upgradeBut:setScriptCallback(ButtonHandler(self.onUpgradeSkill,self))
    self:reloadSkills()
end

function SkillUpgradeDialog:reloadSkills()
    local stype, sid, mlv, lv = self.stype, self.sid, self.mlv, self.lv
    local getDescCallback = self.getDescCallback
    if lv<mlv then
        self.title:setString(Localizef("titleUpgrade",{level=lv+1}))
        self.l2label:setString(getDescCallback(lv+1))
        if self.cvalue>self.context:getRes(self.ctype) then
            self.upgradeLabel:setColor(GConst.Color.Red)
        else
            self.upgradeLabel:setColor(GConst.Color.White)
        end
        self.upgradeLabel:setString(N2S(self.cvalue))
        self.upgradeBut:setGray(false)
    else
        self.title:setString(Localize("labelLevelMax"))
        self.upgradeLabel:setColor(GConst.Color.White)
        self.upgradeLabel:setString(Localize("labelLevelMax"))
        self.upgradeIcon:setVisible(false)
        self.upgradeBut:setGray(true)
        self.l2label:setString(Localize("labelLevelMax"))
    end
    if lv<1 then
        self.l1label:setString(Localize("labelTalentLevel0"))
    else
        self.l1label:setString(getDescCallback(lv))
    end
    self.levelLabel:setString(Localizef("labelHeroLevel",{num=lv, max=mlv}))
end

function SkillUpgradeDialog:onExit()
    if self.parent and not self.parent:getDialog().deleted and self.needReload then
        if self.onExitCallback then
            self.onExitCallback()
        end
    end
end

function SkillUpgradeDialog:onUpgradeSkill()
    local stype, sid, mlv, lv = self.stype, self.sid, self.mlv, self.lv
    if lv>=mlv then
        return
    end
    if self.cvalue>self.context:getRes(self.ctype) then
        local dialog = AlertDialog.new({ctype=self.ctype, cvalue=self.cvalue})
        if not dialog.deleted then
            display.showDialog(dialog)
        end
    else
        local upgradeCallback = self.upgradeCallback
        if upgradeCallback(self) then
            self:finishUpgrade()
        end
    end
end

function SkillUpgradeDialog:finishUpgrade()
    self.needReload = true
    self.lv = self.lv+1
    self:reloadSkills()
end
