local UnionPetsSelectTab = class(DialogTabLayout)

function UnionPetsSelectTab:create()
    self:setLayout("UnionPetsSelectTab.json")
    self:loadViewsTo()

    self:reloadPetsInfo()
    return self.view
end

function UnionPetsSelectTab:onEnter()
    local dialog = self:getDialog()
    dialog.title:setString(Localize("titleUnionPetsSelect"))
    dialog.title:setVisible(true)
    dialog.questionTag = "dataUnionPetsSelect"

    local hdata = self:getContext().heroData
    local pets = self:getDialog().pets
    local infos = {}
    self.infos = {}
    self.initPid = pets.curPid
    for i, pid in ipairs(pets.pets) do
        local hero = hdata:makeHero(pid*10+8000)
        hero.level = pets.level
        infos[i] = {hero=hero, hinfo={}, pid=pid}
        if pid==pets.curPid then
            infos[i].hinfo.selected = true
            infos[i].hero:setLayout(10, 1, 1)
            self.selectedItem = infos[i]
        end
    end
    self.tableView = self.nodeHeroTable:loadTableView(infos, Handler(self.updatePetCell, self))
end

local function _doNothing()
end

function UnionPetsSelectTab:onExit()
    local pets = self:getDialog().pets
    if pets.curPid~=self.initPid then
        GameNetwork.request("upetschange",{changepets={pets.curPid}},_doNothing)
    end
end

function UnionPetsSelectTab:reloadPetsInfo()
    local pets = self:getDialog().pets
    self.heroMsg = nil
    if pets.curPid>0 then
        --将联盟神兽转换为英雄
        local skills = {}
        local hid = pets.curPid*10+8000
        local hero = self:getContext().heroData:makeHero(hid)
        hero.level = pets.level
        hero.exp = pets.exp
        table.insert(skills, {stype=1,sid=hero.info.mid})
        if pets.curPid==10 then
            table.insert(skills, {stype=5,sid=hero.info.mid})
        end
        for i=1, 4 do
            hero.bskills[i] = {id=i, level=pets.skill[i+2]}
            table.insert(skills, {stype=3, sid=i})
        end
        --联盟神兽没有觉醒，用觉醒等级代替天神技等级
        hero.awakeUp = pets.skill[1]
        hero.mSkillLevel = pets.skill[2]
        self.heroMsg = hero
        self.levelLabel:setString(Localizef("labelHeroLevel", {num=pets.level, max=hero.maxLv}))
        if self.displayHid~=hid then
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
            self.nodeSkills:removeAllChildren(true)
            for i,sitem in ipairs(skills) do
                GameUI.addSkillIcon(self.nodeSkills, sitem.stype, sitem.sid, 0.5, 119+(i-1)*118, 74)
            end
        end
        local hdata = hero:getHeroData()
        self.infoLabels1:setString(tostring(hdata.hp))
        self.infoLabels2:setString(tostring(hdata.atk))
    end
end

local _flagState = {flagState=true}
function UnionPetsSelectTab:updatePetCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    if not info.view then
        info.view = bg
        cell:setScriptCallback(ButtonHandler(self.onSelectBoss, self, info))
    end
    GameUI.updateHeroTemplate(bg, info.hinfo, info.hero, _flagState)
end

function UnionPetsSelectTab:onSelectBoss(newItem)
    local oldItem = self.selectedItem
    if newItem~=oldItem then
        if oldItem then
            oldItem.hinfo.selected = nil
            oldItem.hero:setLayout(10, 0, 0)
            GameUI.updateHeroTemplate(oldItem.view, oldItem.hinfo, oldItem.hero, _flagState)
        end
        self.selectedItem = newItem
        if newItem then
            newItem.hinfo.selected = true
            newItem.hero:setLayout(10, 1, 1)
            GameUI.updateHeroTemplate(newItem.view, newItem.hinfo, newItem.hero, _flagState)
        end
        self:getDialog().pets.curPid = newItem.pid
        self:reloadPetsInfo()
    end
end

return UnionPetsSelectTab
