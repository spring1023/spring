local const = GMethod.loadScript("game.GameLogic.Const")


--英雄试炼布阵对话框
local HeroTrialLineupDialog = class2("HeroTrialLineupDialog",function()
    return BaseView.new("HeroTrialLineupDialog.json")
end)

function HeroTrialLineupDialog:ctor(callback)
    self.callback = callback
	self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function HeroTrialLineupDialog:initUI(idx)
    self:removeAllChildren(true)
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,0))

    local tabArr = {Localize("label_battleArr"),Localize("label_battleArrD")}
    if self.callback then
        tabArr = {Localize("label_battleArr")}
    end

    self:addTabView(tabArr, {543,149,468,1370,87,"images/dialogTabBack3_",55,271,69,1540,57,43,1324})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.createAttackLineup,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.createDefenseLineup,self)})
    if self.callback then
        self:changeTabIdx(1)
    else
        self:changeTabIdx(1)
    end
    self.bgTab = {}
    RegActionUpdate(self, Handler(self.updateMy, self, 0.2), 0.2)
end

function HeroTrialLineupDialog:canChangeTab(change)
    if self.forceLayouts:isChanged() then
        local otherSettings = {callback = function()
            local i = change()
            self:showView(self.bgTab[i],40+i*10)
        end}
        local dl = AlertDialog.new(3,Localize("labelPrompt"),Localize("stringTrialLineup1"),otherSettings)
        display.showDialog(dl)
    else
        local i = change()
        self:showView(self.bgTab[i],40+i*10)
    end
end

function HeroTrialLineupDialog:canExit()
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

function HeroTrialLineupDialog:showView(bg,modeNum,isRefresh)
    bg:removeAllChildren(true)

    --TODO 注意在两个TAB之间切换时的逻辑
    if not isRefresh then
        self.forceLayouts = GameLogic.getUserContext().heroData:getForceLayouts(modeNum)
    end
    local empty = {}
    local ltb = self.forceLayouts:getLayouts() or empty
    local temp
    self:loadView("leftTopBackViews",bg)
    local heroHeads = {}

    local callback = function()
        self:showView(bg,modeNum,true)
    end

    for i=1,3 do
        heroHeads[i] = {}
        local leftTopNode = ui.node()
        display.adapt(leftTopNode, 68+(i-1)*433, 683, GConst.Anchor.LeftBottom)
        bg:addChild(leftTopNode)

        self:loadView("leftTopButtonNodeViews",leftTopNode)
        self:loadView("leftTopNodeViews",leftTopNode)
        self:insertViewTo()

        self.butSetLine:setListener(function()
            print("设置",i,modeNum)
            display.showDialog(HeroMainDialog.new({initTag="fight", dialogParam={pos=i, lid=modeNum, hasHelp=true, posStart=1, posEnd=3, forceLayouts=self.forceLayouts}, callback=callback}))
        end)
        if i == 3 and GameLogic.getUserContext().heroData.baseNum<3 then
            self.butSetLine:setListener(function()
                display.pushNotice(Localize("stringHeroBaseNotEnough"))
            end)
        end

        --第几个
        self.viewTab.labelStarterHero:setString(StringManager.getFormatString("labelStarterHero") ..i)
        --英雄效果
        self.viewTab.labelUpLastHart:setString(Localize("dataHeroTrialLine"..i))
        local layout = ltb[i] or empty
        if layout[1] then
            GameUI.updateHeroTemplate(self.butSetLine:getDrawNode(), heroHeads[i], layout[1].hero, {})
        else
            GameUI.updateHeroTemplate(self.butSetLine:getDrawNode(), heroHeads[i])
        end
        for j=1,3 do
            local heroNode= ui.node()
            display.adapt(heroNode, 18+(j-1)*126, 48, GConst.Anchor.LeftBottom)
            leftTopNode:addChild(heroNode)
            self:loadView("leftTopHeroBack1",heroNode)
            self:insertViewTo()
            self.butZhuzhan:setListener(function()
                print("助战",i,j)
                if i == 3 and GameLogic.getUserContext().heroData.baseNum<3  then
                    display.pushNotice(Localize("stringHeroBaseNotEnough"))
                else
                    display.showDialog(HeroMainDialog.new({initTag="help", dialogParam={notSave=true,pos=i, hpos=j, lid=modeNum, hasHelp=true, posStart=1, posEnd=3, forceLayouts=self.forceLayouts}, callback=callback}))
                end
            end)

            local base = self.forceLayouts:getBase(i)
            if base and base.level<const.HelpUnlockLevel[j] then
                self.butZhuzhan:setGray(true)
                self.butZhuzhan:setListener(function()
                    display.pushNotice(Localizef("labelHelpUnlockLevel",{level=const.HelpUnlockLevel[j]}))
                end)
            else
                if layout[j+1] then
                    self:loadView("leftTopHeroBack2",self.butZhuzhan:getDrawNode())
                    GameUI.addHeroHead2(self.butZhuzhan:getDrawNode(),layout[j+1].hero.hid,102,131,8,14,0,{lv=layout[j+1].hero.awakeUp})
                    --GameUI.addHeroHead(heroNode,3001,{size={102,131},x=8,y=14})
                else
                    self:loadView("leftTopHeroAdd",self.butZhuzhan:getDrawNode())
                end
            end
        end
    end

    self:loadView("leftRightViews",bg)
    if modeNum == const.LayoutPvtDef then
        self.viewTab.butLineupButton2:removeFromParent(true)
        self.viewTab.btnLineupButton1:setString(StringManager.getFormatString("btnLineupButton1_2"))
    else
        --按钮    选择战队技能
        self.viewTab.butLineupButton2:setListener(function()
            HeroTrialCorpsSkillDialog.new()
        end)

        local redNum = GameUI.addRedNum(self.viewTab.butLineupButton2,235,85,0,0.8,1)
        GameEvent.bindEvent(redNum,"refreshHeroTrailSkillRedNum",redNum,function()
            local num = 0
            local pvtdata = GameLogic.getUserContext().pvtdata
            local useSkill = {}
            local useNum = 0
            for i,v in ipairs(pvtdata.skills) do
                if GameLogic.getUserContext():getItem(12,v)>0 then
                    useSkill[v] = true
                    useNum = useNum+1
                end
            end
            if useNum>=3 then

            else
                for i=1,6 do
                    if GameLogic.getUserContext():getItem(12,i)>0 and not useSkill[i] then
                        num = 1
                    end
                end
            end
            redNum:setNum(num)
        end)
        GameEvent.sendEvent("refreshHeroTrailSkillRedNum")
    end


    self:loadView("downBackViews",bg)
    for i=1, 6 do
        local downNode = ui.node()
        display.adapt(downNode, 106+(i-1)*320, 256, GConst.Anchor.LeftBottom)
        bg:addChild(downNode)
        self:loadView("downNodeViews",downNode)
        self:insertViewTo()
        self.butTibu:setListener(function()
            print("替补",i)
            display.showDialog(HeroMainDialog.new({initTag="fight", dialogParam={pos=i+3, lid=modeNum, hasHelp=false, posStart=4, posEnd=9, forceLayouts=self.forceLayouts}, callback=callback}))
        end)
        local layout = ltb[i+3] or empty
        if layout[1] then
            GameUI.updateHeroTemplate(self.butTibu:getDrawNode(), {}, layout[1].hero, {})
        else
            GameUI.updateHeroTemplate(self.butTibu:getDrawNode(), {type="add"})
        end
        self.labelSkillTips:setString(Localize("dataHeroTrialLine" .. (i+1)))
    end

    --保存阵容
    self.butLineupButton3:setListener(function()
        if self.forceLayouts:isChanged() then
            if self.forceLayouts:isRepeat() then
                display.pushNotice(Localize("stringTrialLineup7"))
            else
                if ltb[1] and ltb[2] and ltb[3] and ltb[3][1] and ltb[1][1] and ltb[2][1] and ltb[3][1] then
                    if self.forceLayouts:save() then
                        self.forceLayouts = GameLogic.getUserContext().heroData:getForceLayouts(modeNum)
                    end
                    display.pushNotice(Localize("stringTrialLineup4"))
                    if self.callback then
                        self.callback()
                    end
                else
                    display.pushNotice(Localize("stringTrialLineup3"))
                end
            end
        else
            display.pushNotice(Localize("stringTrialLineup2"))
        end
    end)

    --应用到
    self.butLineupButton1:setListener(function()
        if not self.canYY then
            display.pushNotice(Localize("stringCantYY"))
            return
        end
        if self.forceLayouts:isChanged() then
            display.pushNotice(Localize("stringTrialLineup5"))
        else
            local atk = GameLogic.getUserContext().heroData:getForceLayouts(const.LayoutPvtAtk)
            local def = GameLogic.getUserContext().heroData:getForceLayouts(const.LayoutPvtDef)

            def.nlayouts = self.forceLayouts.nlayouts
            def.nlmap = self.forceLayouts.nlmap
            atk.nlayouts = self.forceLayouts.nlayouts
            atk.nlmap = self.forceLayouts.nlmap

            atk:save()
            def:save()
            display.pushNotice(Localize("stringTrialLineup6"))
        end
    end)


    --部分技能变更
    self.butLineupButton4:setListener(function()
        PartSkillChangeDialog.new()
    end)
    --暂无此功能，关闭
    self.butLineupButton4:setVisible(false)

end
function HeroTrialLineupDialog:createAttackLineup(tab)
    local bg, temp
    bg = ui.node({0,0},true)
    self:showView(bg,const.LayoutPvtAtk)
    self.bgTab[1] = bg
    return bg
end

function HeroTrialLineupDialog:createDefenseLineup(tab)
    local bg, temp
    bg = ui.node({0,0},true)
    self:showView(bg,const.LayoutPvtDef)
    self.bgTab[2] = bg
    return bg
end

function HeroTrialLineupDialog:updateMy()
    if self.forceLayouts and self.forceLayouts:isChanged() and not self.forceLayouts:isRepeat() then
        --保存当前阵容
        self.butLineupButton3:setGray(false)
        --应用到
        self.butLineupButton1:setGray(true)
    else
        self.butLineupButton3:setGray(true)
        self.butLineupButton1:setGray(false)
    end

    if self.forceLayouts then
        local g = false
        for i=1,3 do
            local ltb = self.forceLayouts:getLayouts() or {}
            local layout = ltb[i]
            if layout and layout[1] then

            else
                g = true
            end
        end
        if g then
            self.butLineupButton1:setGray(true)
        end
        self.canYY = not g
    end
end

---------------------------------------------------------------------------------


return HeroTrialLineupDialog
