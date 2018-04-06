local const = GMethod.loadScript("game.GameLogic.Const")

local HeroMainTab = GMethod.loadScript("game.Dialog.HeroMainTab")
local ItemMainTab = GMethod.loadScript("game.Dialog.ItemMainTab")
local HeroExtractNewTab = GMethod.loadScript("game.Dialog.HeroExtractNewTab")
local HeroImageTab = GMethod.loadScript("game.Dialog.HeroImageTab")
local HeroInfoTab = GMethod.loadScript("game.Dialog.HeroInfoTab")
local HeroUpgradeTab = GMethod.loadScript("game.Dialog.HeroUpgradeTab")
local HeroFightLayoutTab = GMethod.loadScript("game.Dialog.HeroFightLayoutTab")
local HeroHelpLayoutTab = GMethod.loadScript("game.Dialog.HeroHelpLayoutTab")
local EquipImageTab = GMethod.loadScript("game.Dialog.EquipImageTab")

local HeroMainDialogTab = class(DialogTab)

function HeroMainDialogTab:create()
    local context = self:getContext()
    local hdata = context.heroData
    local bg, temp
    bg = ui.node(nil, true)
    self.view = bg
    local tab = DialogTemplates.createTabView(bg, {StringManager.getFormatString("btnTabHeroMain",
        {num=hdata:getHeroNum(), max=hdata:getHeroMax()}), StringManager.getString("btnTabItemMain")},
        {HeroMainTab.new(self), ItemMainTab.new(self)}, {543,149,468,1370,87,"images/dialogTabBack3_",
        55,271,69,1540,57,43,1324})
    tab:changeTab(self.initIdx or 1)
    self.tab = tab
    return self.view
end

function HeroMainDialogTab:reloadTab(tag)
    local idx = 2
    if tag=="main" then
        idx = 1
    end
    if self.tab then
        self.tab:changeTab(idx)
    else
        self.initIdx = idx
    end
end

local HeroLayoutTab = class(DialogTab)

function HeroLayoutTab:create()
    local context = self:getContext()
    local hdata = context.heroData
    local bg, temp
    bg = ui.node(nil, true)
    self.view = bg
    local tabTitles = {StringManager.getString("btnTabHeroFight")}
    local tabs = {HeroFightLayoutTab.new(self)}
    local dialog = self:getDialog()
    dialog.title:setVisible(false)
    if not dialog.layoutParam then
        dialog.layoutParam = dialog.dialogParam
    end
    local layoutParam = dialog.layoutParam
    if layoutParam and layoutParam.hasHelp then
        table.insert(tabTitles, StringManager.getString("btnTabHeroHelp"))
        table.insert(tabs, HeroHelpLayoutTab.new(self))
        self.hasHelp = true
    end
    local tab = DialogTemplates.createTabView(bg,tabTitles,tabs,{543,149,468,1370,87,"images/dialogTabBack3_",55,271,69,1540,57,43,1324})
    tab:changeTab(self.initIdx or 1)
    self.tab = tab
    self:reloadHelpNum()
    return self.view
end

function HeroLayoutTab:reloadTab(tag)
    local idx=2
    if tag=="fight" then
        idx = 1
    end
    if self.tab then
        self.tab:changeTab(idx)
    else
        self.initIdx = idx
    end
end

function HeroLayoutTab:reloadHelpNum()
    if self.hasHelp then
        local dialog = self:getDialog()
        local layoutParam = dialog.layoutParam
        local context = dialog.context
        local num = 0
        local fl = layoutParam.forceLayouts
        if fl then
            local base = fl:getBase(layoutParam.pos)
            for i=1, 3 do
                if base.level>=const.HelpUnlockLevel[i] and not fl:getHeroByLayout(layoutParam.pos, i+1) then
                    num = num+1
                end
            end
        else
            local base = context.heroData.bases[layoutParam.pos]
            local heroes = context.heroData:getHeroByLayout(layoutParam.lid, layoutParam.pos) or {}
            for i=1, 3 do
                if base.level>=const.HelpUnlockLevel[i] and not heroes[i+1] then
                    num = num+1
                end
            end
        end
        if num>0 then
            if not self.numNotice then
                local bg = ui.node(nil, true)
                display.adapt(bg, 492, 113)
                self.tab.tabButs[2]:getDrawNode():addChild(bg)
                local temp = ui.sprite("images/noticeBackRed.png",{69, 70})
                display.adapt(temp, 0, 0, GConst.Anchor.Center)
                bg:addChild(temp)
                temp = ui.label("", General.font2, 53, {color={255,255,255}})
                display.adapt(temp, 0, 0, GConst.Anchor.Center)
                bg:addChild(temp)
                self.numNoticeLabel = temp
                self.numNotice = bg
            end
            self.numNotice:setVisible(true)
            self.numNoticeLabel:setString(N2S(num))
        elseif self.numNotice then
            self.numNotice:setVisible(false)
        end
    end
end

local HeroStarDialog = class(ViewLayout)

function HeroStarDialog:onCreate()
    self.priority=display.getDialogPri()+1
    self:setLayout("HeroStarDialog.json")
    local setting = self._setting
    local hero = setting.hero
    self:getView("labelStarLevel"):setString(setting.curStar .. "/" .. setting.maxStar)
    self:getView("labelHp"):setString(setting.curStar*hero.info.starHp .. "/" .. setting.maxStar*hero.info.starHp)
    self:getView("labelDps"):setString(setting.curStar*hero.info.starDps .. "/" .. setting.maxStar*hero.info.starDps)
end

HeroMainDialog = class(DialogTabViewLayout)

--防止逻辑错误，先注释
local _tabCache = {}

function HeroMainDialog:ctor()
    self.name="HeroMain"
end

function HeroMainDialog:canExit()
    if self.callback then
        self.callback()
    end
    --引导
    local context = GameLogic.getUserContext()
    local menu = GMethod.loadScript("game.View.Scene").menu
    if context.guide:getStep().type == "exHero1" then
        menu:exHero1Show()
    elseif context.guide:getStep().type == "upgradeHero" then
        menu:guideUpgradeHero()
    end
    return true
end

function HeroMainDialog:getTab(tag)
    local newTab
    --  = _tabCache[tag]
    -- if newTab then
    --     newTab.parent = self
    --     if newTab.reloadTab then
    --         newTab:reloadTab(tag)
    --     end
    --     return newTab
    -- end
    if tag=="main" or tag=="storage" then
        newTab = HeroMainDialogTab.new(self)
        newTab:create()
        self:addReuseTab("main", newTab)
        self:addReuseTab("storage", newTab)
        newTab:reloadTab(tag)
    else
        if tag=="extract" then
            newTab = HeroExtractNewTab.new(self)
        elseif tag=="image" then
            newTab = HeroImageTab.new(self)
        elseif tag=="eimage" then
            newTab = EquipImageTab.new(self)
        elseif tag=="info" then
            newTab = HeroInfoTab.new(self)
        elseif tag=="upgrade" then
            newTab = HeroUpgradeTab.new(self)
        elseif tag=="fight" or tag=="help" then
            newTab = HeroLayoutTab.new(self)
            newTab:reloadTab(tag)
            self.priority=display.getDialogPri()+1
        end
        newTab:create()
    end
    return newTab
end

function HeroMainDialog:showHeroStarInfo(hsContext)
    display.showDialog(HeroStarDialog.new(hsContext))
end

function HeroMainDialog:initStars(tab, bg)
    local temp
    temp = ui.label(StringManager.getString("labelHeroStar"), General.font1, 40, {color={255,255,255}})
    display.adapt(temp, 56, 1213, GConst.Anchor.Left)
    bg:addChild(temp)
    tab.starLabel = temp
    local h=temp:getContentSize().height* temp:getScaleY()
    tab.hsContext = {}
    local addW=tab.starLabel:getContentSize().width-100
    temp = ui.button({76, 71}, self.showHeroStarInfo, {cp1=self, cp2=tab.hsContext, image="images/btnInfo2.png"})
    display.adapt(temp, 502+addW, 1215, GConst.Anchor.Center)
    bg:addChild(temp)
    tab.starBut = temp
    if tab.heroMsg then
        local rating = tab.heroMsg.info.displayColor and tab.heroMsg.info.displayColor >= 5 and 5 or tab.heroMsg.info.rating
        GameUI.addSSR(bg, rating, 0.35,555+addW,1180,0, GConst.Anchor.LeftBottom)
    end
    local stars = {}
    for i=1, 12 do
        temp = ui.sprite("images/heroStarIcon.png",{38,54})
        bg:addChild(temp)
        stars[i] = temp
    end
    tab.heroStars = stars
end
function HeroMainDialog:reloadStars(tab, maxStar, star)
    local stars = tab.heroStars
    local singleLine = maxStar<=6
    local w = 62+tab.starLabel:getContentSize().width*tab.starLabel:getScaleX()
    tab.hsContext.hero = tab.heroMsg
    tab.hsContext.maxStar = maxStar
    tab.hsContext.curStar = star
    for i=1, 12 do
        if i>maxStar then
            stars[i]:setVisible(false)
        else
            stars[i]:setVisible(true)
            if i>star then
                stars[i]:setSValue(-100)
            else
                stars[i]:setSValue(0)
            end
            if singleLine then
                display.adapt(stars[i], w+((i-1)%6)*50, 1240-52*math.ceil(i/6))
            else
                display.adapt(stars[i], w+((i-1)%6)*50, 1266-52*math.ceil(i/6))
            end
        end
    end
    if maxStar==0 then
        tab.starLabel:setVisible(false)
        tab.starBut:setVisible(false)
    else
        tab.starLabel:setVisible(true)
        tab.starBut:setVisible(true)
    end
end
