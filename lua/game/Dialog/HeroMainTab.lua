local const = GMethod.loadScript("game.GameLogic.Const")

local HeroMainTab = class(DialogTab)

function HeroMainTab:onLifeCycle(event)
    if event=="enter" then
        local dialog = self:getDialog()
        local context = dialog.context
        dialog.questionBut:setVisible(true)
        dialog.title:setVisible(false)
        dialog:changeTabTag("main")
        dialog.questionTag = "dataQuestionHeroMain"
        local hdata = context.heroData
        hdata:checkHeroNum()
        local index = 1
        local infos = self.infos
        local hlist = {}
        for _, hero in pairs(hdata:getAllHeros()) do
            table.insert(hlist, hero)
        end
        table.sort(hlist, GameLogic.sortExpHero2)
        for _, v in ipairs(hlist) do
            infos[index].type = "hero"
            infos[index].heroKey=v.idx
            infos[index].deadTime = v.recoverTime
            if v.idx==dialog.dialogParam then
                infos[index].selected = true
            else
                infos[index].selected = nil
            end
            index = index+1
        end
        local max = hdata:getHeroMax()
        while index<=max do
            infos[index].type = nil
            infos[index].heroKey=0
            infos[index].selected = nil
            index = index+1
        end
        while index<=const.MaxHeroNum do
            infos[index].type="add"
            infos[index].heroKey=0
            infos[index].selected = nil
            index = index+1
        end
        for _, info in ipairs(infos) do
            if info.view then
                self:updateHeroCell(info.view, self.tableView, info)
            end
        end
        local num = context:getFreeHeroChance(GameLogic.getSTime())
        self.freeNum:setNum(num)
        self.tabTextLabel:setString(StringManager.getFormatString("btnTabHeroMain",{num=hdata:getHeroNum(), max=hdata:getHeroMax()}))
        self.labelMedicine:setString(N2S(context:getRes(const.ResMedicine)))
        local allcomb = GameLogic.getUserContext().heroData:getAllCombatData()
        self.allCombat:setString(tostring(allcomb))
        --引导
        if context.guide:getStep().type == "exHero1" then
            context.guideHand:removeHand("exHero1")
            context.guideHand:showArrow(self.btnExtracthero,132,250,0)
        elseif context.guide:getStep().type ~= "finish" then
            self.btnExtracthero:setListener(GameLogic.lockInGuide)
        end
    elseif event=="exit" then
        local context = self:getContext()
        if context.guide:getStep().type == "exHero1" then
            context.guideHand:removeHand()
        end
    end
end

local _tsetting = {flagState=true, flagEquip=true}
function HeroMainTab:updateHeroCell(cell, scrollView, info)
    local bg = cell:getDrawNode()
    if not info.view then
        info.view = cell
        cell:setScriptCallback(Script.createCallbackHandler(self.onHeroCellAction, self, info))
    end
    GameUI.updateHeroTemplate(bg, info, self:getContext().heroData:getHero(info.heroKey), _tsetting)

    --引导
    local context = GameLogic.getUserContext()
    local gstep = context.guide:getStep()
    if gstep.type == "upgradeHero" then
        local hero = self:getContext().heroData:getHero(info.heroKey)
        if hero and hero.hid and hero.hid == gstep.hid then
            if not cell.arrow then
                context.guideHand:removeHand("upgradeHeroArrow")
                local x,y = cell:getPosition()
                local arrow = context.guideHand:showArrow(cell:getParent(),x,y-50)
                arrow:setScaleY(-1)
                cell:setScriptCallback(Script.createCallbackHandler(self.onHeroCellAction, self, info))
                cell.arrow = arrow
            end
        else
            ui.setListener(cell,function()
                display.pushNotice(Localize("stringPleaseGuideFirst"))
            end)
        end
    else
        if cell.arrow then
            cell.arrow:removeFromParent(true)
            cell.arrow = nil
        end
    end
end

function HeroMainTab:create()
    local dialog = self:getDialog()
    local bg, temp
    bg = ui.node({0,0},true)
    self.view = bg
    RegLife(bg, Handler(self.onLifeCycle, self))
    temp = ui.label(StringManager.getString("labelHeroMainInfo"), General.font2, 40, {color={49,48,49}, fontW = 1500, fontH = 75})
    display.adapt(temp, 93,1306)
    bg:addChild(temp)

    temp = ui.colorNode({419,1352},{255,255,255})
    display.adapt(temp,1605,24)
    bg:addChild(temp,1)
    temp:setOpacity(0.5*255)

    local infos = {}
    for i=1, const.MaxHeroNum do
        infos[i] = {index=i}
    end
    self.infos = infos
    local tableView = ui.createTableView({1565, 1266}, false, {size=cc.size(238, 229), offx=50, offy=32, disx=70, disy=52, rowmax=5, infos=infos, cellUpdate=Handler(self.updateHeroCell, self)})
    display.adapt(tableView.view, 40, 1293, GConst.Anchor.LeftTop)
    bg:addChild(tableView.view)
    self.tableView = tableView

    if GameLogic.useTalentMatch then
        local temp = ui.button({140, 140}, Handler(display.showDialog, StrongerDialog), {image="images/otherIcon/iconActivity40001.png"})
        display.adapt(temp, 1650, 1450, GConst.Anchor.Center)
        bg:addChild(temp, 2)
    end


    temp = ui.label(StringManager.getString("combOfTeam"), General.font1, 50, {color=GConst.Anchor.White,fontW=360,fontH=60})
    display.adapt(temp, 1634, 1309, GConst.Anchor.LeftTop)
    bg:addChild(temp,2)
    temp = ui.label(" ", General.font1, 50, {color=GConst.Anchor.White})
    display.adapt(temp, 1814, 1229, GConst.Anchor.Top)
    bg:addChild(temp,2)
    self.allCombat = temp

    temp = ui.label(StringManager.getString("btnExtracthero"), General.font1, 50, {color=GConst.Anchor.White})
    display.adapt(temp, 1814, 820, GConst.Anchor.Top)
    bg:addChild(temp,2)
    temp = ui.button({264, 283}, self.pushDialogTab, {cp1=self, cp2="extract", image="images/btnHeroMethod.png", scale9edge={55,96,63,63}})
    display.adapt(temp, 1812, 959, GConst.Anchor.Center)
    bg:addChild(temp,2)
    self.btnExtracthero = temp

    local but = temp:getDrawNode()
    temp = ui.sprite("images/otherIcon/iconHeroExtract.png", {181, 167})
    display.adapt(temp, 132, 152, GConst.Anchor.Center)
    but:addChild(temp)

    self.freeNum = GameUI.addRedNum(but,8,246,0,0.8,10000)

    temp = ui.label(StringManager.getString("btnHeroImage"), General.font1, 50, {color=GConst.Anchor.White})
    display.adapt(temp, 1814, 406, GConst.Anchor.Top)
    bg:addChild(temp,2)
    temp = ui.button({264, 283}, self.pushDialogTab, {cp1=self, cp2="image", image="images/btnHeroMethod.png", scale9edge={55,96,63,63}})
    display.adapt(temp, 1812, 554, GConst.Anchor.Center)
    bg:addChild(temp,2)
    but = temp:getDrawNode()
    temp = ui.sprite("images/btnHeroImage.png")
    display.adapt(temp, 132, 151, GConst.Anchor.Center)
    but:addChild(temp)

    temp = ui.sprite("images/items/itemIconBackPurple.png",{100, 100})
    display.adapt(temp, 1626, 131, GConst.Anchor.LeftBottom)
    bg:addChild(temp,2)
    GameUI.addResourceIcon(bg, 10, 0.86, 1634+45, 138+42,2)
    -- temp = ui.sprite("images/resMedicine.png",{89, 85})
    -- display.adapt(temp, 1634+45, 138+42, GConst.Anchor.Center)
    -- bg:addChild(temp,2)
    temp = ui.scale9("images/proBack1_2.png", 27, {202, 70})
    display.adapt(temp, 1731, 145, GConst.Anchor.LeftBottom)
    bg:addChild(temp,2)

    temp = ui.label("", General.font1, 50, {color={255,255,255}})
    display.adapt(temp, 1742, 180, GConst.Anchor.Left)
    bg:addChild(temp,2)
    self.labelMedicine = temp

    temp = ui.button({130, 131} ,StoreDialog.new, {cp1={id=1,labelMedicineNum=self.labelMedicine},image="images/btnAddNum.png"})
    display.adapt(temp, 1974, 179, GConst.Anchor.Center)
    bg:addChild(temp,2)

    self.tabTextLabel = self.parent.tab.tabLabels[1]
    return self.view
end

function HeroMainTab:onHeroCellAction(info)
    local dialog = self:getDialog()
    if dialog.deleted then
        return
    end
    if info.type=="add" then
        local idx = info.index
        local max = self:getContext().heroData:getHeroMax()
        if idx>max then
            local num = idx-max
            local cost = const.PriceHeroNum * num
            display.showDialog(AlertDialog.new(1, StringManager.getString("alertTitleBuyHeroNum"), StringManager.getFormatString("alertTextBuyHeroNum", {cost=cost, num=num}), {callback=Handler(self.onBuyHeroNum, self, num), ctype=const.ResCrystal, cvalue=cost}))
        end
    elseif info.type=="hero" then
        self:selectCell(info)
        local hero = self:getContext().heroData:getHero(info.heroKey)
        hero.assists = {}
        dialog:pushTab("info", info.heroKey)
    end
end

function HeroMainTab:pushDialogTab(tag, param)
    local dialog = self:getDialog()
    dialog:pushTab(tag, param)
end

function HeroMainTab:onBuyHeroNum(num)
    local cost = const.PriceHeroNum * num
    local context = self:getContext()
    if num>context:getRes(const.ResCrystal) then
        display.showDialog(AlertDialog.new({ctype=const.ResCrystal, cvalue=cost}))
    else
        context:buyHeroPlace(num)
        self:onLifeCycle("enter")
    end
end

function HeroMainTab:selectCell(info)
    if self.selectedItem~=info then
        local reuseGrid = nil
        if self.selectedItem then
            self.selectedItem.selected = nil
            reuseGrid = GameUI.resetTemplateSelect(self.selectedItem.view, self.selectedItem, true)
        end
        self.selectedItem = info
        local dialog = self:getDialog()
        dialog.dialogParam = info.heroKey
        if info then
            info.selected = true
            GameUI.resetTemplateSelect(info.view, info, reuseGrid)
        end
    end
end

return HeroMainTab
