local const = GMethod.loadScript("game.GameLogic.Const")
local SetBattleArrDialog = class2("SetBattleArrDialog",function()
    return BaseView.new("SetBattleArrDialog.json")
end)

function SetBattleArrDialog:ctor(setIdx)
    self.context = GameLogic.getUserContext()
    self.setIdx = setIdx or 1
    local sgin = self.context:getProperty(const.ProUseLayout)
    sgin = GameLogic.dnumber(sgin, 6)
    self.sgin = {sgin[1]>0,sgin[2]>0,sgin[3]>0, sgin[4]>0, sgin[5]>0, sgin[6]>0}

    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function SetBattleArrDialog:onQuestion()
    HelpDialog.new("dataQuestionSetBattleArr")
end

function SetBattleArrDialog:initUI()
    self:loadView("backAndupViews")
    self:insertViewTo()
    self.butClose:setListener(function()
        display.closeDialog(0)
    end)
    self.butCheck:setListener(function()
        local str = self.sgin[self.setIdx] and "stringNotUseSetPrompt" or "stringUseSetPrompt"
        local otherSettings = {callback = function()
            self.sgin[self.setIdx] = not self.sgin[self.setIdx]
            self.iconGou:setVisible(self.sgin[self.setIdx])
            local sgin = {}
            for i,v in ipairs(self.sgin) do
                sgin[i] = v and 1 or 0
            end
            sgin = GameLogic.enumber(sgin,6)
            self.context:setProperty(const.ProUseLayout,sgin)
            self.context:addCmd({const.CmdUseLayout,sgin})
        end}
        local dl = AlertDialog.new(3,Localize("btnSetUp"),Localize(str),otherSettings)
        display.showDialog(dl)
    end)

    if self.setIdx <= 3 then
        self:addTabView({Localize("labelLDZLMZJQZY"),Localize("labelArena"),Localize("labelLeaguePve")}, {558,148,490,1299-79,-40,"images/tabSetBattleArr_",50,279,60,0,0,0,0})
        self.tab[3]:addTab({create=Script.createBasicHandler(self.createPvpLineup,self)})
        self.tab[3]:addTab({create=Script.createBasicHandler(self.createAreneLineup,self)})
        self.tab[3]:addTab({create=Script.createBasicHandler(self.createUnionLineup,self)})
    else
        -- TODO 先临时随便写一下
        local SData = GMethod.loadScript("data.StaticData")
        self:addTabView({Localize(SData.getData("tmInfos", 100+self.setIdx).nameKey)}, {558,148,490,1299-79,-40,"images/tabSetBattleArr_",50,279,60,0,0,0,0})
        self.tab[3]:addTab({create=Script.createBasicHandler(self.createTMLineup,self)})
    end
    self:changeTabIdx(self.setIdx > 3 and 1 or self.setIdx)
    self.bgTab = {}
    RegActionUpdate(self, Handler(self.updateMy, self, 0.2), 0.2)
end

function SetBattleArrDialog:canExit()
    if self.sureExit then
        return true
    end
    if self.forceLayouts:isChanged() then
        local otherSettings = {callback = function()
            self.sureExit = true
            display.closeDialog(0)
        end}
        local dl = AlertDialog.new(3,Localize("labelPrompt"),Localize("stringTrialLineup1"),otherSettings)
        display.showDialog(dl)
    else
        return true
    end
end

function SetBattleArrDialog:createPvpLineup()
    local bg, temp
    bg = ui.node({0,0},true)
    self:showView(bg,const.LayoutPve)
    self.bgTab[1] = bg
    return bg
end

function SetBattleArrDialog:createAreneLineup()
    local bg, temp
    bg = ui.node({0,0},true)
    self:showView(bg,const.LayoutPvc)
    self.bgTab[2] = bg
    return bg
end

function SetBattleArrDialog:createUnionLineup()
    local bg, temp
    bg = ui.node({0,0},true)
    self:showView(bg,const.LayoutUPve)
    self.bgTab[3] = bg
    return bg
end

function SetBattleArrDialog:createTMLineup()
    local bg, temp
    bg = ui.node({0,0},true)
    self:showView(bg,const.LayoutUPve+self.setIdx-3)
    self.bgTab[1] = bg
    return bg
end

function SetBattleArrDialog:canChangeTab(change,i)
    if i == 1 then

    elseif i == 2 then
        if not self.context.buildData:getBuild(5) then
            display.pushNotice(Localize("stringNotArena"))
            return
        end
    elseif i == 3 then
        if not self.context.union then
            display.pushNotice(Localize("stringNotUnion"))
            return
        end
    end

    local modeNumSet = {const.LayoutPve,const.LayoutPvc,const.LayoutUPve, const.LayoutUPve+1, const.LayoutUPve+2, const.LayoutUPve+3}
    if self.forceLayouts:isChanged() then
        local otherSettings = {callback = function()
            local i = change()
            self:showView(self.bgTab[i],modeNumSet[i])
        end}
        local dl = AlertDialog.new(3,Localize("labelPrompt"),Localize("stringTrialLineup1"),otherSettings)
        display.showDialog(dl)
    else
        local i = change()
        self:showView(self.bgTab[i],modeNumSet[i])
    end
end

function SetBattleArrDialog:showView(bg,modeNum,isRefresh)
    bg:removeAllChildren(true)
    if not isRefresh then
        self.forceLayouts = GameLogic.getUserContext().heroData:getForceLayouts(modeNum)
    end
    local ltb = self.forceLayouts:getLayouts() or {}
    local infos = {}
    for i=1,self.context.heroData.baseNum do
        local layout = ltb[i] or {}
        local base = self.forceLayouts:getBase(i)
        infos[i] = {id = i, modeNum = modeNum, layout = layout, bg = bg, base=base}
    end
    self:addTableViewProperty("infoTableview",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("infoTableview",bg)
    local typeSet = {[const.LayoutPve] = 1, [const.LayoutPvc] = 2, [const.LayoutUPve] = 3}
    self.setIdx = typeSet[modeNum] or self.setIdx
    self.iconGou:setVisible(self.sgin[self.setIdx])

    self.butSave:setListener(function()
        --保存时检测一下,某一个英雄台下的助战英雄是否有重复,如果有则提示不能保存
        if self.forceLayouts:isChanged() then
            if self.forceLayouts:isRepeat() then
                display.pushNotice(Localize("stringTrialLineup7"))
            elseif self.forceLayouts:save() then
                self.forceLayouts = GameLogic.getUserContext().heroData:getForceLayouts(modeNum)
                display.pushNotice(Localize("stringTrialLineup4"))
            end
        else
            display.pushNotice(Localize("stringTrialLineup2"))
        end
    end)
end

function SetBattleArrDialog:callcell(cell, tableView, info)
    local layout = info.layout
    local modeNum = info.modeNum
    local base = info.base
    local callback = function()
        if self.showView then
            self:showView(info.bg,modeNum,true)
        end
    end
    local bg = cell:getDrawNode()
    self:loadView("infoCellView",bg)
    self:insertViewTo()
    self.heroHeadNode:setListener(function()--换出战英雄
        if self.sgin[self.setIdx] then
            display.showDialog(HeroMainDialog.new({initTag="fight", dialogParam={pos=info.id, lid=info.modeNum, hasHelp=true,
            forceLayouts=self.forceLayouts}, callback=callback}))
        else
            display.pushNotice(Localize("stringCantSetBattleArr"))
        end
    end)
    self.heroHeadNode:setTouchThrowProperty(true, true)
    local heroBg = self.heroHeadNode:getDrawNode()
    if layout[1] then
        GameUI.updateHeroTemplate(heroBg, {}, layout[1].hero, {})
    else
        GameUI.updateHeroTemplate(heroBg, {})
    end

    for i=1,3 do
        self["assiatBut" .. i]:setTouchThrowProperty(true,true)
        self["assiatBut" .. i]:setListener(function()--换助战英雄
            if self.sgin[self.setIdx] then
                -- display.showDialog(HeroMainDialog.new({initTag=tag, dialogParam={pos=self.lidx, lid=const.LayoutPvp, hasHelp=true}}))
                display.showDialog(HeroMainDialog.new({initTag="help", dialogParam={notSave=true,pos=info.id, hpos=i, lid=modeNum, hasHelp=true,
                forceLayouts=self.forceLayouts}, callback=callback}))
            else
                display.pushNotice(Localize("stringCantSetBattleArr"))
            end
        end)
        if layout[i+1] then
            self["assiatBack" .. i]:setVisible(true)
            GameUI.addHeroHead2(self["assiatHeadNode" .. i],layout[i+1].hero.hid,104,138,0,0,0,{lv = layout[i+1].hero.awakeUp})
        else
            self["assiatBack" .. i]:setVisible(false)
            if base.level<const.HelpUnlockLevel[i] then
                self["assiatBut" .. i]:setGray(true)
                self["addBack" .. i]:setVisible(false)
                self["assiatBut" .. i]:setListener(function()
                    display.pushNotice(Localizef("labelHelpUnlockLevel",{level=const.HelpUnlockLevel[i]}))
                end)
            else
                self["addBack" .. i]:setVisible(true)
            end
        end
    end
end

function SetBattleArrDialog:updateMy()
    if self.forceLayouts and self.forceLayouts:isChanged() and not self.forceLayouts:isRepeat()then
        --保存当前阵容
        self.butSave:setGray(false)
    else
        self.butSave:setGray(true)
    end
end

return SetBattleArrDialog











