local const = GMethod.loadScript("game.GameLogic.Const")

local UnionPetsUpgradeDialog = GMethod.loadScript("game.Dialog.UnionPetsUpgradeDialog")

local UnionPetsInfoTab = class(DialogTabLayout)

function UnionPetsInfoTab:create()
    self:setLayout("UnionPetsInfoTab.json")
    self:loadViewsTo()

    local tabView = self.nodeSkillTab1
    local tab = DialogTemplates.createTabView(tabView.view, {Localize("btnMainSkill"),Localize("btnGodSkill")}, Handler(self.onChangeSkill, self), tabView:getSetting("tabSetting"), {actionType=2, tabType=2})
    self.tab = tab

    local sbuts = {}
    for i=1, 4 do
        sbuts[i] = {button=self["btnBSkill" .. i], name=self["labelBSkillName" .. i], isBSkill=true, stype=3, sid=i}
        sbuts[i].name:setString(Localize("dataSkillName3_" .. i))
    end
    sbuts[5] = {button=self.btnUpgradeMSkill, name=self.labelMSkillName, info=self.labelMSkillInfo}
    for i,but in ipairs(sbuts) do
        but.viewLayout = self:addLayout("SkillBut",but.button._view)
        but.viewLayout:loadViewsTo(but)
        but.button:setScriptCallback(ButtonHandler(self.onUpgradeSkill, self, but))
    end
    self.sbuts = sbuts
    tabView = self.nodeSkillTab2
    tab = DialogTemplates.createTabView(tabView.view, {Localize("btnTalentSkill")}, nil, tabView:getSetting("tabSetting"), {actionType=2, tabType=2})
    tab:changeTab(1)
    self.btnUpgrade:setScriptCallback(ButtonHandler(self.onUpgrade, self))    
    GameLogic.getJumpGuide(const.JumpTypeGodBaest,self.btnUpgrade,104,100)
    return self.view
end

function UnionPetsInfoTab:onEnter()
    local dialog = self:getDialog()
    local forcePid = dialog.forcePid
    dialog.forcePid = nil
    dialog:changeTabTag("info")
    self.forcePid = forcePid
    dialog.questionTag = "dataUnionPetsInfo"

    --isInfo,true：点击仓库神兽，false：tab界面
    self.isInfo=dialog.isInfo or false

    self:reloadPetsInfo()
    for i,but in ipairs(self.sbuts) do
        if self.isInfo then
            but.button:setEnable(false)
            but.imgUpgrade:setVisible(false)
        else
            but.button:setEnable(true)
            but.imgUpgrade:setVisible(true)
        end
        self:reloadSkillBut(but)
    end
    if self:getContext():hasUnionPermission(1) and not self.forcePid and not self.isInfo then
        self.btnReplace:setVisible(true)
        self.btnReplace:setScriptCallback(ButtonHandler(self.onReplaceClick, self))
    else
        self.btnReplace:setVisible(false)
    end
    local function callBack()
        dialog.isInfo = false
        local tab=dialog.tab
        tab.tabButs[1]:setVisible(true)
        tab.tabButs[2]:setVisible(true)
        self:getDialog():reloadTab("storage")
    end

    if not self.isInfo then
        self.title.view:setVisible(false)
        self.butBack.view:setVisible(false)
        self.btnUpgrade:setVisible(true)
    else
        self.title.view:setVisible(true)
        self.butBack.view:setVisible(true)
        self.btnUpgrade:setVisible(false)
        local tab=dialog.tab
        tab.tabButs[1]:setVisible(false)
        tab.tabButs[2]:setVisible(false)
        self.butBack:setScriptCallback(ButtonHandler(callBack))
    end
end

function UnionPetsInfoTab:onReplaceClick()
    self:getDialog():pushTab("select")
end

function UnionPetsInfoTab:onUpgrade()
    GameLogic.removeJumpGuide(const.JumpTypeGodBaest)
    display.showDialog(UnionPetsUpgradeDialog.new({parent=self, context=self.context, pets=self:getDialog().pets}))
end

local function getAwakeSkillDesc(hero)
    return hero:getAwakeSkill(hero.awakeUp).info
end

function UnionPetsInfoTab:onUpgradeSkill(info)
    local getDescCallback
    local sidx = self:getPetsSkillIdx(info)
    if sidx==1 then
        getDescCallback = Handler(getAwakeSkillDesc, self.heroMsg)
    elseif sidx==2 then
        getDescCallback = Handler(self.heroMsg.getSkillDesc, self.heroMsg)
    else
        getDescCallback = Handler(self.heroMsg.getTalentSkillInfo, self.heroMsg, info.sid)
    end
    local data = self.heroMsg:getUPSkillDetail(sidx)
    data.getDescCallback = getDescCallback
    data.onExitCallback = Handler(self.reloadSkillBut, self, info, true)
    data.upgradeCallback = Handler(self.onRealUpgradeSkill, self, info)
    data.parent = self
    data.context = self:getContext()
    display.showDialog(SkillUpgradeDialog.new(data))
end

function UnionPetsInfoTab:getPetsSkillIdx(info)
    local sidx
    if info.isBSkill then
        sidx = info.sid+2
    elseif self.skillTabId==1 then
        sidx = 2
    else
        sidx = 1
    end
    return sidx
end

function UnionPetsInfoTab:onRealUpgradeSkill(info, dialog)
    local sidx = self:getPetsSkillIdx(info)
    local data = self.heroMsg:getUPSkillDetail(sidx)
    if dialog.lv ~= data.lv then
        return
    end
    if GameNetwork.lockRequest() then
        self:getContext():changeRes(dialog.ctype, -dialog.cvalue)
        GameNetwork.request("upetskill",{petsskilllv={sidx,dialog.lv}}, self.onResponseUpgradeSkill, self, info, dialog)
    end
    return false
end

function UnionPetsInfoTab:onResponseUpgradeSkill(info, dialog, suc, data)
    GameNetwork.unlockRequest()
    if suc then
        local sidx = self:getPetsSkillIdx(info)
        local pets = self:getDialog().pets
        pets.skill[sidx] = pets.skill[sidx]+1
        self.heroMsg:upgradeUPSkill(sidx)
        if not dialog.deleted then
            local data = self.heroMsg:getUPSkillDetail(sidx)
            dialog.cvalue = data.cvalue
            dialog:finishUpgrade()
        elseif not self:getDialog().deleted then
            self:reloadSkillBut(info, true)
        end
    else
        self:getContext():changeRes(dialog.ctype, dialog.cvalue)
    end
end

function UnionPetsInfoTab:reloadSkillBut(but, checkUpgrade)
    if self.heroMsg then
        local sidx = self:getPetsSkillIdx(but)
        local data = self.heroMsg:getUPSkillDetail(sidx)
        local stype,sid,lv,mlv = data.stype, data.sid, data.lv, data.mlv
        
        local name,info = nil
        if sidx==2 then
            name = self.heroMsg:getSkillName()
            info = self.heroMsg:getSkillDesc()
        elseif sidx==1 then
            local tmd = self.heroMsg:getAwakeSkill(lv)
            name = tmd.name
            info = tmd.info
        end
        if name then
            but.name:setString(name)
        end
        if info then
            but.info:setString(info)
        end
        if sid~=self.displaySid or stype~=self.displayStype then
            self.displayStype = stype
            self.displaySid = sid
            but.nodeIcon:removeAllChildren(true)
            GameUI.addSkillIcon(but.nodeIcon.view, stype, sid, 0.85)
        end
        but.labelLevel:setString(Localizef("labelLevelFormat", {level=lv}))
        but.imgUpgrade:setVisible(mlv>lv)

        if checkUpgrade then
            self.labelUnionFeatsValue:setString(N2S(self:getContext():getRes(const.ResGXun)))
        end
    end
end

function UnionPetsInfoTab:reloadPetsInfo()
    self.labelUnionFeatsValue:setString(N2S(self:getContext():getProperty(const.ProGXun)))
    local pets = self:getDialog().pets
    local pid = self.forcePid or pets.curPid or 0
    self.tab.tabButs[2]:setVisible(pid==10)
    self.nodeHeroInfo:setVisible(pid>0)
    local sid = self.skillTabId or 1
    if sid==2 and pid~=10 then
        sid = 1
    end
    self.tab:changeTab(sid)
    self.heroMsg = nil
    if pid>0 then
        --将联盟神兽转换为英雄
        local hid = pid*10+8000
        local hero = self:getContext().heroData:makeHero(hid)
        hero.level = pets.level
        hero.exp = pets.exp
        for i=1, 4 do
            hero.bskills[i] = {id=i, level=pets.skill[i+2]}
        end
        --联盟神兽没有觉醒，用觉醒等级代替天神技等级
        hero.awakeUp = pets.skill[1]
        hero.mSkillLevel = pets.skill[2]
        self.heroMsg = hero
        self.levelLabel:setString(Localizef("labelHeroLevel", {num=pets.level, max=hero.maxLv}))
        local nextExp = hero:getNextExp()
        local exp = pets.exp
        if exp>=nextExp then
            self.expLabel:setString(Localize("labelLevelMax"))
            nextExp = exp
            if nextExp==0 then
                nextExp = 1
                exp = 1
            end
        else
            self.expLabel:setString(exp .. "/" .. nextExp)
        end
        self.expProcess:setScaleProcess(true, exp/nextExp)
        if self.displayHid~=hid then
            self.displayHid = hid
            if self.roleFeature then
                self.roleFeature:removeFromParent(true)
                self.roleFeature = nil
            end
            self.roleFeature = GameUI.addHeroFeature(self.nodeHeroFeature.view, hid, 1, 0, 0, 0)
            if self.roleJob then
                self.roleJob:removeFromParent(true)
                self.roleJob = nil
            end
            self.roleJob = GameUI.addHeroJobIcon(self.nodeJobIcon, hero.info.job, 0.95, 44, 44)
            self.nameLabel:setString(hero:getName())
            GameUI.setHeroNameColor(self.nameLabel, hero.info.color)
        end
        local hdata = hero:getHeroData()
        self.infoLabels1:setString(tostring(hdata.hp))
        self.infoLabels2:setString(tostring(hdata.atk))
    end
        -- self.nodeSoldierHead:removeAllChildren(true)
        -- GameUI.addHeadIcon(self.nodeSoldierHead,hero.info.sid,0.833,99,95)
        -- self.nodeSkills:removeAllChildren(true)
        -- GameUI.addSkillIcon(self.nodeSkills, 1, hero.info.mid, 0.56, 63, 63)
        -- local ox = 216
        -- for i=1, 3 do
        --     if hero.bskills[i].id>0 then
        --         GameUI.addSkillIcon(self.nodeSkills, 3, hero.bskills[i].id, 0.56, ox, 63)
        --         ox = ox + 151
        --     else
        --         break
        --     end
        -- end
end

function UnionPetsInfoTab:onChangeSkill(idx)
    self.skillTabId = idx
    self:reloadSkillBut(self.sbuts[5])
end

return UnionPetsInfoTab
