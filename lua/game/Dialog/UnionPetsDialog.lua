local const = GMethod.loadScript("game.GameLogic.Const")

local UnionPetsSelectTab = GMethod.loadScript("game.Dialog.UnionPetsSelectTab")
local UnionPetsInfoTab = GMethod.loadScript("game.Dialog.UnionPetsInfoTab")

local UnionPetsMergeTab = class(DialogTabLayout)

function UnionPetsMergeTab:create()
    self:setLayout("UnionPetsMergeTab.json")
    self:loadViewsTo()
    self.btnMerge:setScriptCallback(ButtonHandler(self.onMergePet, self))
    return self.view
end

function UnionPetsMergeTab:onEnter()
    local dialog = self:getDialog()
    dialog.title:setString(Localize("titlePetsMerge"))
    dialog.title:setVisible(true)
    dialog.questionTag = "dataUnionPetsMerge"

    local pets = dialog.pets
    local idMap = {}
    local imgMap = {}
    self.idMap = idMap
    self.imgMap = {}
    for _, pid in ipairs(pets.pets) do
        idMap[pid] = true
    end
    local ct = 0
    for i=1, 10 do
        local iback = self["nodeHeadIcon" .. i]
        iback:removeAllChildren(true)
        local sca=0.8
        if i==10 then
            sca=1.4
        end
        local img = GameUI.addHeroHeadCircle2(iback.view, 8000+i*10, sca, 0, 0, 0)
        if not idMap[i] then
            img:setSValue(-100)
        elseif i<10 then
            ct = ct+1
        end
        imgMap[i] = img
    end
    if ct==9 and not idMap[10] then
        self.btnMerge:setEnable(true)
        self.btnMerge:setGray(false)
    else
        self.btnMerge:setEnable(false)
        self.btnMerge:setGray(true)
    end
end

function UnionPetsMergeTab:onMergePet()
    if GameNetwork.lockRequest() then
        GameNetwork.request("upetsmerge",nil,self.onResponseMergeUPets, self)
    end
end

function UnionPetsMergeTab:onResponseMergeUPets(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        local context = GameLogic.getUserContext()
        local pets = context:getUnionPets()
        if pets then
            table.insert(pets.pets, 10)
            if not self.deleted then
                UIeffectsManage:showEffect_weishouhechen(self.view,645,712)
                self:onEnter()
            end
        end
    end
end

local UnionPetsStorageTab = class(DialogTabLayout)

function UnionPetsStorageTab:create()
    self:setLayout("UnionPetsStorageTab.json")
    self:loadViewsTo()

    self.infos = {}
    for i=1, 10 do
        self.infos[i] = {hinfo={noLv=true}, pid=i-1}
    end
    self.infos[1].pid = 10
    self.btnShop:setScriptCallback(ButtonHandler(self.onOpenShop, self))
    self.btnUnionPBead:setScriptCallback(ButtonHandler(self.onUsePBead, self))
    GameLogic.getJumpGuide(const.JumpTypeOrb,self.btnUnionPBead,145,200)
    return self.view
end

function UnionPetsStorageTab:onEnter()
    self:getDialog():changeTabTag("storage")
    self:getDialog().questionTag = "dataUnionPetsStorage"
    self:reloadAll()
    GameEvent.registerEvent("refreshDialog",self,self.reloadAll)
end

function UnionPetsStorageTab:onExit()
    GameEvent.unregisterEvent("refreshDialog", self)
end

function UnionPetsStorageTab:onUsePBead()
    local context = self:getContext()
    GameLogic.removeJumpGuide(const.JumpTypeOrb)
    if context:getRes(const.ResPBead)>0 then
        local params = {context=context, parent=self, itemtype=const.ItemRes, itemid=const.ResPBead, itemnum=context:getRes(const.ResPBead)}
        params.mode = -1
        params.onSureCallback = Handler(self.onRealUsePBead, self)
        display.showDialog(ItemUseDialog.new(params))
    else
        display.pushNotice(Localize("noticePBeadNotEnough2"))
    end
end

function UnionPetsStorageTab:onRealUsePBead(num, dialog)
    if self:getContext():getRes(const.ResPBead)<num then
        return
    end
    if GameNetwork.lockRequest() then
        self:getContext():changeRes(const.ResPBead, -num)
        GameNetwork.request("upetsgive",{giveclanbead={num}},self.onResponseGivePBead,self,num,dialog)
    end
end

function UnionPetsStorageTab:onResponseGivePBead(num, dialog, suc, data)
    GameNetwork.unlockRequest()
    dialog:onDelaySure(suc)
    if suc then
        local context = GameLogic.getUserContext()
        context:changeRes(const.ResGXun, num*const.GXunByPBead)
        local pets = context:getUnionPets()
        if pets then
            pets.pbead = pets.pbead+num
        end
        if not self.deleted then
            self.labelPBeadNum:setString(N2S(context:getRes(const.ResPBead)))
        end
        display.pushNotice(Localizef("noticeupetsgive",{num=num*const.GXunByPBead}))
    else
        self:getContext():changeRes(const.ResPBead, num)
    end
end

function UnionPetsStorageTab:reloadAll()
    local context = self:getContext()
    local mhnum = 10
    local dialog = self:getDialog()
    local infos = self.infos
    local idsMap = {}
    local pets = self:getDialog().pets
    for _, pid in ipairs(pets.pets) do
        idsMap[pid] = true
    end
    local hnum = #(pets.pets)
    infos[1].gray = not idsMap[10]
    infos[1].hero = context.heroData:makeHero(8100)
    if pets.curPid==10 then
        infos[1].hero:setLayout(10, 1, 1)
    end
    local idx = 2
    for i=1, 9 do
        if idsMap[i] then
            infos[idx].hero = context.heroData:makeHero(8000+10*i)
            if i==pets.curPid then
                infos[idx].hero:setLayout(10, 1, 1)
            end
            idx = idx+1
        end
    end
    for i=idx, 10 do
        infos[idx].hero = nil
    end
    if not self.tableView then
        self.tableView = self.nodeHeroTable:loadTableView(infos, Handler(self.updateUPetsCell, self))
    else
        for _,info in ipairs(infos) do
            self:updateUPetsCell(info.cell, self.tableView, info)
        end
    end
    self.labelPBeadNum:setString(N2S(context:getRes(const.ResPBead)))
    self.labelUnionPetsNum:setString(hnum .. "/" .. mhnum)
end

function UnionPetsStorageTab:onOpenShop()
    local context = self:getContext()
    if context:hasUnionPermission(1) then
        StoreDialog.new({pri=self:getDialog().priority+1, stype="upets", pets=self:getDialog().pets,needBack=true,callBack=true})
    else
        display.pushNotice(Localize("noticeUnionPermission"))
    end
end
local _tsetting = {flagState=true}
function UnionPetsStorageTab:updateUPetsCell(cell, tableView, info)
    if not info.cell then
        info.cell = cell
        cell:setScriptCallback(ButtonHandler(self.onCellAction, self, info))
    end
    GameUI.updateHeroTemplate(cell:getDrawNode(), info.hinfo, info.hero,_tsetting)
    if info.gray then
        cell:setGray(true)
    else
        cell:setGray(false)
    end
end

function UnionPetsStorageTab:onCellAction(info)
    if info.pid==10 and info.gray then
        self:getDialog():pushTab("merge")
    elseif info.hero then
        self:getDialog().forcePid = info.pid
        self:getDialog().isInfo=true
        self:getDialog():reloadTab("info")
    else
        print("empty")
    end
end

local UnionPetsMainTab = class(DialogTabLayout)

function UnionPetsMainTab:create()
    local bg, temp
    bg = ui.node(nil, true)
    self.view = bg

    local tabTitles = {Localize("labelUnionPetsInfo"),Localize("labelUnionPetsStorage")}
    local tabs = {UnionPetsInfoTab.new(self), UnionPetsStorageTab.new(self)}

    local dialog = self:getDialog()
    local tabView = dialog.nodeTabView
    local tab = DialogTemplates.createTabView(self.view,tabTitles,tabs,tabView:getSetting("tabSetting"))
    tab:changeTab(self.initIdx or 1)
    self.tab = tab
    self:getDialog().tab=tab
    RegLife(self.view, Handler(self.onLifeCycle, self))
    return self.view
end

function UnionPetsMainTab:onEnter()
    local dialog = self:getDialog()
    dialog.title:setVisible(false)
end

function UnionPetsMainTab:reloadTab(tag)
    local idx = 2
    if tag=="info" then
        idx = 1
    end
    if self.tab then
        self.tab:changeTab(idx)
    else
        self.initIdx = idx
    end
end

UnionPetsDialog = class(DialogTabViewLayout)

function UnionPetsDialog:getTab(tag)
    local newTab
    if tag=="info" or tag=="storage" then
        newTab = UnionPetsMainTab.new(self)
        newTab:create()
        self:addReuseTab("info", newTab)
        self:addReuseTab("storage", newTab)
        newTab:reloadTab(tag)
    elseif tag=="select" then
        newTab = UnionPetsSelectTab.new(self)
        newTab:create()
    elseif tag=="merge" then
        newTab = UnionPetsMergeTab.new(self)
        newTab:create()
        self:addReuseTab("merge", newTab)
    end
    return newTab
end
