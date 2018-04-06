local const = GMethod.loadScript("game.GameLogic.Const")

WeaponUpgradeDialog = class(DialogViewLayout)

function WeaponUpgradeDialog:onInitDialog()
    --self.priority = 1
    self.questionTag = "dataQuestionWeaponUpgrade"
    self:setLayout("WeaponUpgradeDialog.json")
    self:loadViewsTo()

    self.title:setString(Localize("titleWeaponResearch"))
    self.btnUpgrade:setScriptCallback(ButtonHandler(self.onUpgrade, self))
    self.btnLeft:setScriptCallback(ButtonHandler(self.onChangeIndex, self, -1))
    self.btnRight:setScriptCallback(ButtonHandler(self.onChangeIndex, self, 1))
    GameUI.addResourceIcon(self.nodeIconCurrent, const.ResMagic, 1, 0, 0)
    GameUI.addResourceIcon(self.nodeIconNeed, const.ResMagic, 1, 0, 0)


    GameLogic.getJumpGuide(const.JumpTypeSuperWeapons,self.btnUpgrade,170,90)
    self.weapons = {}
    for i=0, 4 do
        self.weapons[i] = {but=self["btnWeapon" .. i], name=self["labelName" .. i], icon=nil, level=self["labelWeaponLevel" .. i]}
        self.weapons[i].but:setScriptCallback(ButtonHandler(self.onSelectWeapon, self, i))
    end
    self.properties = {}
    for i=1, 6 do
        self.properties[i] = {name=self["labelPropertyName" .. i], value=self["labelPropertyValue" .. i], add=self["labelPropertyAdd" .. i]}
    end
    self:changeIndex(self.weaponIdx or 1)
end

function WeaponUpgradeDialog:onEnter()
    self.labelCurrent:setString(self.context:getRes(const.ResMagic))
    self:changeIndex(self.weaponIdx or 1)
end

function WeaponUpgradeDialog:onChangeIndex(dir)
    local idx = (self.weaponIdx or 1)+dir
    if idx<=0 then
        idx = 6
    elseif idx>6 then
        idx = 1
    end
    self:changeIndex(idx)
end

function WeaponUpgradeDialog:changeIndex(idx, subIdx)
    self.weaponIdx = idx
    local winfo = self.context.weaponData:getWeaponAllDatasByIdx(idx)
    self.winfo = winfo
    self.labelWeaponDesc:setString(winfo.desc)
    for i=0, 4 do
        local wid = winfo.subitems[i]
        local wlv = winfo.sublevels[i]
        local wtype, widx
        if i==0 then
            wtype, widx = 0, wid
        else
            wtype, widx = winfo.wtype, i
        end
        local weapon = self.weapons[i]
        if weapon.icon then
            weapon.icon:removeFromParent(true)
        end
        weapon.icon = GameUI.addWeaponIcon(weapon.but, wtype, widx, 1, 113, 113)

        local curLevel = self.winfo.sublevels[0]
        local wtype, widx = 0, self.winfo.subitems[0]
        local nextData = self.context.weaponData:getWeaponProperty(wtype, widx, self.winfo.subitems[0], curLevel+1)
        if i==0 and nextData and nextData.needLevel>self.context.buildData:getMaxLevel(const.WeaponBase) then
            weapon.but:setGray(true)
            weapon.icon:setSValue(-100)
        elseif i>0 and winfo.sublevels[0]==0 then
            weapon.but:setGray(true)
            weapon.icon:setSValue(-100)
        else
            weapon.but:setGray(false)
            weapon.icon:setSValue(0)
        end
        weapon.name:setString(winfo.subnames[i])
        weapon.level:setString(tostring(wlv))
    end
    for i, pitem in ipairs(self.properties) do
        local property = winfo.properties[i]
        pitem.add:setVisible(false)
        if property then
            pitem.name:setVisible(true)
            pitem.value:setVisible(true)
            pitem.name:setString(property[1])
            pitem.value:setString(self:getProperty(property[2], property[3]))
        else
            pitem.name:setVisible(false)
            pitem.value:setVisible(false)
        end
    end
    self.subWeaponIdx = nil
    self:onSelectWeapon(subIdx)
end

function WeaponUpgradeDialog:onSelectWeapon(subIdx)
    if subIdx and subIdx==self.subWeaponIdx then
        return
    end
    if subIdx and subIdx>0 and self.winfo.sublevels[0]==0 then
        display.pushNotice(Localize("noticeSubWeaponLock"))
        return
    end
    self.subWeaponIdx = subIdx
    for i=1, 6 do
        self.properties[i].add:setVisible(false)
    end
    for i=0, 4 do
        self.weapons[i].level:setColor(GConst.Color.White)
        self.weapons[i].level:setString(tostring(self.winfo.sublevels[i]))
    end
    local costValue = 0
    self.btnUpgrade:setVisible(true)
    if not subIdx then
        self.selectedGrid:setVisible(false)
    else
        local sgview = self.selectedGrid.view
        sgview:retain()
        sgview:removeFromParent(false)
        self.weapons[subIdx].but:addChild(self.selectedGrid)
        sgview:release()
        self.selectedGrid:setVisible(true)

        local curLevel = self.winfo.sublevels[subIdx]
        local wtype, widx = 0, subIdx
        if subIdx>0 then
            wtype = self.winfo.wtype
        else
            widx = self.winfo.subitems[subIdx]
        end
        local nextData = self.context.weaponData:getWeaponProperty(wtype, widx, self.winfo.subitems[subIdx], curLevel+1)
        
        if nextData then
            self.weapons[subIdx].level:setColor(GConst.Color.Green)
            self.weapons[subIdx].level:setString(tostring(curLevel+1))
            for pid, pvalue in pairs(nextData.properties) do
                local mp = self.winfo.properties[pid]
                self.properties[pid].add:setString("+" .. self:getProperty(mp[2], pvalue-mp[3]))
                self.properties[pid].add:setVisible(true)
            end
            costValue = nextData.cost
        else
            self.btnUpgrade:setVisible(false)
        end
        self.nextData = nextData
    end
    if costValue<=self.context:getRes(const.ResMagic) then
        self.labelNeed:setColor(GConst.Color.White)
    else
        self.labelNeed:setColor(GConst.Color.Red)
    end
    self.labelNeed:setString(tostring(costValue))
end

function WeaponUpgradeDialog:getProperty(ptype, pvalue)
    if ptype==0 then
        return tostring(pvalue)
    elseif ptype==1 then
        return tostring(pvalue) .. Localize("tmSec")
    else
        return tostring(pvalue) .. "%"
    end
end

function WeaponUpgradeDialog:onUpgrade()   
    GameLogic.removeJumpGuide(const.JumpTypeSuperWeapons)
    local subIdx = self.subWeaponIdx
    if not subIdx then
        display.pushNotice(Localize("noticeSelectWeaponNone"))
        return
    end
    local nextData = self.nextData
    if nextData then
        if subIdx==0 and nextData.needLevel>self.context.buildData:getMaxLevel(const.WeaponBase) then
            if nextData.level==1 then
                display.pushNotice(Localizef("noticeWeaponBaseLevel",{level=nextData.needLevel}))
            else
                display.pushNotice(Localizef("noticeWeaponBaseLevel2",{level=nextData.needLevel}))
            end
            return
        elseif subIdx>0 and nextData.needLevel>self.winfo.sublevels[0] then
            display.pushNotice(Localizef("noticeWeaponMainLevel", {level=nextData.needLevel}))
            return
        end
        if nextData.cost>self.context:getRes(const.ResMagic) then
            display.pushNotice(Localize("noticeMagicNotEnough"))
            return
        end
        -- 日常任务超级武器研究
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeSuperWeapons,1)
        music.play("sounds/mercenary_upgrade.mp3")
        UIeffectsManage:showEffect_yonbingshenji(1,self.weapons[subIdx].but,113,113,3,1.5)
        self.context.weaponData:upgradeWeapon(nextData.id, nextData.cost)
        self.labelCurrent:setString(self.context:getRes(const.ResMagic))
        self:changeIndex(self.weaponIdx, self.subWeaponIdx)
    end
end
