local const = GMethod.loadScript("game.GameLogic.Const")
local HeroHelpLayoutTab = class(DialogTabLayout)

local _helpPosTabHValues = {0, 111, 180}
function HeroHelpLayoutTab:create()
    self:setLayout("HeroHelpLayoutTab.json")
    self:loadViewsTo()

    self.tabButs = {}
    self.tabLabels = {}
    self.tabNotices = {}
    local tabNode = self.nodeTabBack.view
    for i=1, 3 do
        --助战界面，助战一，助战二，助战三
        local temp = ui.button({382, 119}, self.changeTab, {cp1=self, cp2=i, anchor=GConst.Anchor.Bottom})
        display.adapt(temp, 320*i-140, 0, GConst.Anchor.Bottom)
        tabNode:addChild(temp, i)
        self.tabButs[i] = temp
        temp:setBackgroundSound("sounds/switch.mp3")
        temp = ui.label(StringManager.getString("dataHelpPos" .. i), General.font1, 40)
        display.adapt(temp, 191, 61, GConst.Anchor.Center)
        self.tabButs[i]:getDrawNode():addChild(temp,2)
        self.tabLabels[i] = {temp, temp:getScaleY()}
        temp = ui.sprite("images/dialogTabBack4_1.png", {382, 119})
        display.adapt(temp, 0, 0)
        self.tabButs[i]:getDrawNode():addChild(temp, -1)
        temp:setHValue(_helpPosTabHValues[i])
        local notice = ui.node(nil, true)
        display.adapt(notice, 327, 94)
        self.tabButs[i]:getDrawNode():addChild(notice)
        self.tabNotices[i] = notice
        temp = ui.sprite("images/noticeBackRed.png",{69, 70})
        display.adapt(temp, 0, 0, GConst.Anchor.Center)
        notice:addChild(temp)
        temp = ui.label("!", General.font2, 53, {color={255,255,255}})
        display.adapt(temp, 0, 0, GConst.Anchor.Center)
        notice:addChild(temp)
    end
    local dialog = self:getDialog()
    local layoutParam = dialog.layoutParam
    local context = self:getContext()

    self.btnLeft:setScriptCallback(ButtonHandler(self.onChangePos, self, -1))
    self.btnRight:setScriptCallback(ButtonHandler(self.onChangePos, self, 1))
    self.btnEquip:setScriptCallback(ButtonHandler(self.onEquipAction, self))

    self:changeTab(layoutParam.hpos or 1)
    return self.view
end

function HeroHelpLayoutTab:onEnter()
    self:onChangePos(0)
    self:reloadHero()
    self:loadOtherHeroBlock()
    self:getDialog().questionTag = "dataQuestionHeroHelp"
end

function HeroHelpLayoutTab:changeTab(idx)
    if idx==self.curTab then
        return
    end
    local buts = self.tabButs
    local labels = self.tabLabels
    local curTab = self.curTab
    if curTab and buts[curTab] then
        buts[curTab]:setEnable(true)
        buts[curTab]:setLocalZOrder(curTab)
        buts[curTab]:setPositionY(0)
        labels[curTab][1]:setScale(labels[curTab][2])
    end
    self.curTab = idx
    if buts[idx] then
        buts[idx]:setEnable(false)
        buts[idx]:setLocalZOrder(#buts+1)
        buts[idx]:setPositionY(23)
        labels[idx][1]:setScale(labels[idx][2]*1.125)
        self:reloadHero()
    end
end

function HeroHelpLayoutTab:onChangePos(dir)
    local layoutParam = self:getDialog().layoutParam
    local context = self:getContext()
    local posStart, posEnd
    if layoutParam.posStart then
        posStart, posEnd = layoutParam.posStart, layoutParam.posEnd
    else
        posStart, posEnd = 1, context.heroData.baseNum
    end
    local newPos = layoutParam.pos
    while true do
        newPos = newPos+dir
        if newPos<posStart then
            newPos = posEnd
        elseif newPos>posEnd then
            newPos = posStart
        end
        if newPos==layoutParam.pos then
            break
        elseif layoutParam.forceLayouts then
            break
        elseif context.heroData.bases[newPos].level>0 then
            break
        end
    end
    if newPos~=layoutParam.pos then
        layoutParam.pos = newPos
        self:reloadHero()
        self:loadOtherHeroBlock()
    end
end

function HeroHelpLayoutTab:reloadHero()
    local dialog = self:getDialog()
    local layoutParam = dialog.layoutParam
    local context = dialog.context
    local curTab = self.curTab
    local base
    local hero
    if layoutParam.forceLayouts then
        base = layoutParam.forceLayouts:getBase(layoutParam.pos)
        for i=1, 3 do
            self.tabNotices[i]:setVisible(base.level>=const.HelpUnlockLevel[i] and not layoutParam.forceLayouts:getHeroByLayout(layoutParam.pos, i+1))
        end
        hero = layoutParam.forceLayouts:getHeroByLayout(layoutParam.pos, curTab+1)
    else
        base = context.heroData.bases[layoutParam.pos]
        local heroes = context.heroData:getHeroByLayout(layoutParam.lid, layoutParam.pos) or {}
        for i=1, 3 do
            self.tabNotices[i]:setVisible(not heroes[i+1] and base.level>=const.HelpUnlockLevel[i])
        end
        hero = heroes[curTab+1]
    end
    if base.level>=const.HelpUnlockLevel[curTab] then
        self.nodeHeroInfo:setVisible(true)
        self.labelLevelNotice:setVisible(false)
        if hero then
            self.nodeHeroInfo2:setVisible(true)
            self.nodeHeroHead:removeAllChildren(true)
            GameUI.addHeadIcon(self.nodeHeroHead,hero.hid,0.92,109,105,{lv = hero.awakeUp})
            self.labelNormalEffect:setString(Localize("labelHelpNormalPrefix") .. Localizef("labelHelpNormalEffect" .. curTab, {num=hero:getNormalHelpValue(curTab)}))
            self.labelHeroLevel:setString(Localizef("labelHeroLevel2", {level=hero.level}))
            if hero.info.hsid>0 then
                self.nodeSkillInfo:setVisible(true)
                self.nodeSkillIcon:removeAllChildren(true)
                GameUI.addSkillIcon(self.nodeSkillIcon, 4, hero.info.hsid, 0.97, 110, 110)
                self.labelSkillName:setString(hero:getHelpSkillFormatName(true))
                self.labelSkillDesc:setString(hero:getHelpSkillDesc(nil, true))
            else
                self.nodeSkillInfo:setVisible(false)
            end
            local sid = context.heroData:getHeroByLayout(layoutParam.lid, layoutParam.pos, 1)
            if sid == nil then
                self.nodeHelpSoldierInfo:setVisible(false)
            else
                self.nodeHelpSoldierInfo:setVisible(true)
                self.nodeHelpSoldierIcon:removeAllChildren(true)
                GameUI.addHeadIcon(self.nodeHelpSoldierIcon,sid.info.sid,0.92,109,105,{lv=sid.soldierLevel})
                self.labelHelpSoldierName:setString(Localize("SoldierHelp"))
                self.labelHelpSoldierDesc:setString(hero:getHelpSoldierSkillDesc())
            end
        else
            self.nodeHeroInfo2:setVisible(false)
        end
    else
        self.nodeHeroInfo:setVisible(false)
        self.labelLevelNotice:setVisible(true)
        self.labelLevelNotice:setString(Localizef("labelHelpUnlockLevel",{level=const.HelpUnlockLevel[curTab]}))
    end
end

function HeroHelpLayoutTab:onEquipAction()
end

function HeroHelpLayoutTab:loadOtherHeroBlock()
    local dialog = self:getDialog()
    local layoutParam = dialog.layoutParam
    local context = self:getContext()
    local canUseHero = {}
    local heros = context.heroData:getAllHeros()
    local helpedHeros={}
    for _, hero in pairs(heros) do
        if (hero.info.job or 0)>0 and hero.info.aspeed>0 then
            local posAndType = hero.layouts[layoutParam.lid]
            if posAndType and posAndType.pos==layoutParam.pos and posAndType.type>1 then
                helpedHeros[hero.hid]=true
            end
        end
    end

    for _, hero in pairs(heros) do
        if (hero.info.job or 0)>0 and hero.info.aspeed>0 then
            local posAndType = hero.layouts[layoutParam.lid]
            if not posAndType or posAndType.pos==layoutParam.pos and posAndType.type>1 then
                if posAndType or not helpedHeros[hero.hid] then
                    table.insert(canUseHero, hero)
                end
            end
        end
    end
    table.sort(canUseHero, GameLogic.sortExpHero)
    local infos={}
    for i, hero in ipairs(canUseHero) do
        infos[i]={index=i, type="hero", heroKey=hero.idx, lid=layoutParam.lid, forceLayouts=layoutParam.forceLayouts}
    end
    if self.tableView then
        self.tableView.view:removeFromParent(true)
        self.tableView = nil
    end
    local tableView = ui.createTableView({930, 1286}, false, {size=cc.size(238,229), offx=20, offy=32, disx=70, disy=52,
        rowmax=3, infos=infos, cellUpdate=Handler(self.updateHeroCell, self)})
    display.adapt(tableView.view, 1096, 54, GConst.Anchor.LeftBottom)
    self.view:addChild(tableView.view)
    self.infos = infos
    self.tableView = tableView

    self.parent:reloadHelpNum()
end

local _cellSetting = {flagState=true}
function HeroHelpLayoutTab:updateHeroCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    if not info.view then
        info.view = cell
        cell:setScriptCallback(ButtonHandler(self.onHeroCellAction, self, info))
        cell:setBackgroundSound("sounds/heroSelected.mp3")
        if info.index==1 and GameLogic.getUserContext().guideHand.handArr["guideHeroSeleted"] and not self.guideArrow then
            display.showDialog(StoryDialog.new({context=GameLogic.getUserContext(),storyIdx=303,callback=function()
                self.guideArrow=GameLogic.getUserContext().guideHand:showArrow(self.view,1230, 1280,20)
            end}),false,true)
        end
    end
    GameUI.updateHeroTemplate(bg, info, self:getContext().heroData:getHero(info.heroKey), _cellSetting)
end

function HeroHelpLayoutTab:onHeroCellAction(info)
    local hidx = info.heroKey
    local dialog = self:getDialog()
    local layoutParam = dialog.layoutParam
    local context = dialog.context
    if self.guideArrow and GameLogic.getUserContext().guideHand.handArr["guideHeroSeleted"] then
        GEngine.setConfig("isHeroBaseGuided"..context.sid..context.uid,1,true)
        self.guideArrow:removeFromParent(true)
        self.guideArrow = nil
        GameLogic.getUserContext().guideHand:removeHand("guideHeroSeleted")
        display.showDialog(StoryDialog.new({context=GameLogic.getUserContext(),storyIdx=304,callback=nil}),false,true)
    end
    local base
    local hero = context.heroData:getHero(hidx)
    local fl = layoutParam.forceLayouts
    local lpos, ltype = layoutParam.pos, self.curTab+1
    if fl then
        base = fl:getBase(lpos)
    else
        base = context.heroData.bases[lpos]
    end
    if hero then
        if base.level<const.HelpUnlockLevel[self.curTab] then
            display.pushNotice(Localizef("labelHelpUnlockLevel",{level=const.HelpUnlockLevel[self.curTab]}))
        else
            if fl then
                local hlayout = layoutParam.forceLayouts:getLayout(hero)
                if hlayout and hlayout.pos==lpos and hlayout.type==ltype then
                    layoutParam.forceLayouts:changeHeroLayout(hero, 0, 0)
                else
                    layoutParam.forceLayouts:changeHeroLayout(hero, lpos, ltype)
                end
                if not layoutParam.notSave then
                    layoutParam.forceLayouts:save()
                end
            else
                if hero.layouts[layoutParam.lid] then
                    context.heroData:changeHeroLayout(hero, layoutParam.lid, 0, 0)
                else
                    context.heroData:changeHeroLayout(hero, layoutParam.lid, lpos, ltype)
                end
                local uphero = context.heroData:getHeroByLayout(const.LayoutPvp, lpos, 1)
                if uphero then
                    -- 更换助战英雄检查战斗力
                    context.heroData:setCombatData(uphero)
                end
            end
        end
        self:reloadHero()
        self:loadOtherHeroBlock()
    end
end

return HeroHelpLayoutTab
