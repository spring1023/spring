local const = GMethod.loadScript("game.GameLogic.Const")

PvhDialog = class(DialogViewLayout) --英雄远征准备对话框
function PvhDialog:onInitDialog()
    self.chance = 0
    --self.priority = 1
    self:setLayout("PvhDialog.json")
    self:loadViewsTo()

    self.title:setString(Localize("titlePvhSetting"))
    self.btnStartBattle:setScriptCallback(ButtonHandler(self.onStartBattle, self))
end

function PvhDialog:onEnter()
    self.pvhContext=self.nightmare and self.context.npvh or self.context.pvh
    self.questionTag = "dataQuestionPvhPrepare"
    self:reloadRightHeros()
    self:reloadLeftHeros()
    self.labelMagicNum:setString(N2S(self.context:getRes(const.ResMagic)))
    self.chance = self.pvhContext:getChance(GameLogic.getSTime())
    self.labelPvhChance:setString(self.chance .. "/" .. self.pvhContext:getMaxChance())
end

function PvhDialog:reloadLeftHeros()
    if not self.selectedHeros then
        self.selectedHeros = {}
        for i=1, 15 do
            self.selectedHeros[i] = {hinfo={btype=1}}
        end
    end
    local hidx = 0
    for _, hitem in ipairs(self.otherHeros) do
        if hitem.pvhSelected then
            hidx = hidx+1
            if self.selectedHeros[hidx] then
                self.selectedHeros[hidx].hero = hitem.hero
            end
        end
    end
    self.labelPvhHeros:setString(hidx .. "/15")
    self.selectedNum = hidx
    self.btnStartBattle:setGray(hidx==0)
    for i=hidx+1, 15 do
        self.selectedHeros[i].hero = nil
    end
    if self.selectedTableView then
        for _,hitem in ipairs(self.selectedHeros) do
            if hitem.cell then
                self:updateSelectedHeroCell(hitem.cell, self.selectedTableView, hitem)
            end
        end
    else
        local size = self.nodeHeroSelectedTable.size
        local ts = self.nodeHeroSelectedTable:getSetting("tableSetting")

        local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=self.selectedHeros, cellUpdate=Handler(self.updateSelectedHeroCell, self)})
        display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
        self.nodeHeroSelectedTable.view:addChild(tableView.view)
        self.selectedTableView = tableView
    end
end

local function sortByHero(h1, h2)
    local hero1, hero2 = h1.hero, h2.hero
    local isPre1 = hero1.layouts[const.LayoutPvh]~=nil
    local isPre2 = hero2.layouts[const.LayoutPvh]~=nil
    if isPre1~=isPre2 then
        return isPre1
    elseif hero1.info.color~=hero2.info.color then
        return hero1.info.color>hero2.info.color
    elseif hero1.level~=hero2.level then
        return hero1.level>hero2.level
    elseif hero1.exp~=hero2.exp then
        return hero1.exp>hero2.exp
    else
        return hero1.hid<hero2.hid
    end
end

local function nsortByHero(h1, h2)
    local hero1, hero2 = h1.hero, h2.hero
    local isPre1 = hero1.layouts[const.LayoutnPvh]~=nil
    local isPre2 = hero2.layouts[const.LayoutnPvh]~=nil
    if isPre1~=isPre2 then
        return isPre1
    elseif hero1.info.color~=hero2.info.color then
        return hero1.info.color>hero2.info.color
    elseif hero1.level~=hero2.level then
        return hero1.level>hero2.level
    elseif hero1.exp~=hero2.exp then
        return hero1.exp>hero2.exp
    else
        return hero1.hid<hero2.hid
    end
end

function PvhDialog:reloadRightHeros()
    local heroData = self.context.heroData
    local lid = self.nightmare and const.LayoutnPvh or const.LayoutPvh
    if not self.otherHeros then
        local hidx = 0
        local allHeros = heroData:getAllHeros()
        self.otherHeros = {}
        for _, hero in pairs(allHeros) do
            if hero.info.job>0 then
                hidx = hidx+1
                self.otherHeros[hidx] = {hero=hero, hinfo={}}
                if hero.layouts[lid] and hero.layouts[lid].pos > 0 and hero.layouts[lid].type == 1 then
                    self.otherHeros[hidx].pvhSelected = true
                end
            end
        end
        if self.nightmare then
            table.sort(self.otherHeros, nsortByHero)
        else
            table.sort(self.otherHeros, sortByHero)
        end
        local midx = 9
        if hidx>9 then
            midx = hidx-hidx%3+3
        end
        for i=hidx+1, midx do
            self.otherHeros[i] = {hinfo={}}
        end
    end
    if self.otherTableView then
        for _,hitem in ipairs(self.otherHeros) do
            self:updateOtherHeroCell(hitem.cell, self.otherTableView, hitem)
        end
    else
        local size = self.nodeHeroOtherTable.size
        local ts = self.nodeHeroOtherTable:getSetting("tableSetting")

        local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=self.otherHeros, cellUpdate=Handler(self.updateOtherHeroCell, self)})
        display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
        self.nodeHeroOtherTable.view:addChild(tableView.view)
        self.otherTableView = tableView
    end
end

function PvhDialog:updateSelectedHeroCell(cell,tableView,info)
    if not info.view then
        info.view = cell:getDrawNode()
        info.cell = cell
        ui.setListener(info.cell,function()
            if info.hero then
                local context = self.context
                display.showDialog(HeroMainDialog.new({initTag="info",dialogParam=info.hero.idx,context = context}))
            end
        end)
    end
    GameUI.updateHeroTemplate(info.view, info.hinfo, info.hero)
end

local _flagPvh = {flagEquip=true}
function PvhDialog:updateOtherHeroCell(cell,tableView,info)
    if not info.view then
        info.view = cell:getDrawNode()
        cell:setScriptCallback(ButtonHandler(self.onSelectHero, self, info))
        cell:setBackgroundSound("sounds/heroSelected.mp3")
        info.cell = cell
    end
    local bg = info.view
    local temp
    info.hinfo.lvUpZ=10
    GameUI.updateHeroTemplate(bg, info.hinfo, info.hero, _flagPvh)

    if info.pvhSelected then
        if not info.pvhIcon then
            temp = ui.sprite("images/gouzi.png",{271, 172})
            display.adapt(temp, -7, -35, GConst.Anchor.LeftBottom)
            bg:addChild(temp,0)
            temp:setGlobalZOrder(3)
            info.pvhIcon = temp
        end
    else
        if info.pvhIcon then
            info.pvhIcon:removeFromParent(true)
            info.pvhIcon = nil
        end
    end
end

function PvhDialog:onSelectHero(info)
    if not info.hero then
        return
    end
    if self.chance==0 then
        self.notChanceChange=true
    end
    if info.pvhSelected then
        info.pvhSelected = nil
    else
        if self.selectedNum>=15 then
            display.pushNotice(Localize("noticePvhFull"))
            return
        end
        info.pvhSelected = true
    end
    self:reloadLeftHeros()
    self:updateOtherHeroCell(info.cell, self.otherTableView, info)
end
--点X前先保存好
function PvhDialog:canExit()
    local hdatas,heros=self:savePvh()
    if self.chance==0 and self.notChanceChange then
        local lid = self.nightmare and const.LayoutnPvh or const.LayoutPvh
        for i=1, 15 do
            local hero = self.context.heroData:getHeroByLayout(lid, i, 1)
            if hero then
                self.context.heroData:changeHeroLayout(hero, lid, 0, 0)
            end
        end
        for i, hero in ipairs(heros) do
            self.context.heroData:changeHeroLayout(hero, lid, i, 1)
        end
    end
    return true
end

function PvhDialog:savePvh()
    local heros = {}
    for _, hitem in ipairs(self.selectedHeros) do
        if hitem.hero and hitem.hero.info.job>0 then
            table.insert(heros, hitem.hero)
        end
    end
    local hdatas = self.context.heroData:initPvhHeros(heros,self.nightmare)
    return hdatas,heros
end

function PvhDialog:onStartBattle(force)
    if self.selectedNum==0 then
        return
    end
    if self.chance<=0 then
        display.pushNotice(Localize("noticePvhTomorrow"))
        return
    end
    if self.selectedNum<15 and not force then
        GameNetwork.unlockRequest()
        display.showDialog(AlertDialog.new(3,Localize("alertTitlePvh"),Localize("alertTextPvhNotFull"),{callback=Handler(self.onStartBattle, self, true)}))
        return
    else
        local hdatas = self:savePvh()
        if self.nightmare then
            self.context:addCmd({const.CmdnPvhHset,hdatas})
            self.context.npvh:startNewBattle(GameLogic.getSTime())
            self.context.talentMatch:saveTalentMatchPvh()
            display.closeDialog(0)
            display.sendIntent{class="game.Dialog.NightmareDialog", params={nightmare=true}}
        else 
            self.context:addCmd({const.CmdPvhHSet,hdatas})
            self.context.pvh:startNewBattle(GameLogic.getSTime())
            display.closeDialog(0)
            display.showDialog(PvhMapDialog.new())
        end
        local activeData = GameLogic.getUserContext().activeData
        activeData:finishAct(10)
    end
end


