HeroUpgradeTab = class(DialogTab)
local SData = GMethod.loadScript("data.StaticData")

function HeroUpgradeTab:create()
    local dialog = self:getDialog()
    self.heroIdx = dialog.dialogParam
    self.heroMsg = self:getContext().heroData:getHero(self.heroIdx)
    dialog.title:setString(StringManager.getString("titleHeroUpgrade"))
    dialog.title:setVisible(true)
    local bg = ui.node(nil, true)
    self.view = bg

    self:loadHeroBlock()
    self:loadOtherHeroBlock()
    self:getDialog().questionTag = "dataQuestionHeroUpgrade"

    local bNode=ui.node()
    self.view:addChild(bNode)
    GameEvent.bindEvent(bNode,"refreshOtherHeroBlock", self, self.loadOtherHeroBlock)
    return self.view
end

function HeroUpgradeTab:loadHeroBlock()
    local bg, temp = self.view
    temp = ui.sprite("images/heroBackGrayAlpha.png",{944, 1350})
    display.adapt(temp, 1073, 1, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    temp = ui.sprite("images/dialogBackSmallYellow.png",{932, 1297})
    display.adapt(temp, 1080, 39, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    temp = ui.sprite("images/dialogBackHeroInfo.png",{1019, 1317})
    display.adapt(temp, 40, 39, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    bg = ui.node(nil, true)
    self.view:addChild(bg, 1)
    self.heroBlock = bg
    temp = ui.label("", General.font1, 47)
    display.adapt(temp, 160, 1300, GConst.Anchor.Left)
    bg:addChild(temp)
    self.nameLabel = temp
    self:getDialog():initStars(self, bg)
    temp = ui.label("", General.font1, 47, {color={255,255,255}})
    display.adapt(temp, 112, 375, GConst.Anchor.Left)
    bg:addChild(temp)
    self.levelLabel = temp

    temp = ui.sprite("images/proBack4.png",{888, 56})
    display.adapt(temp, 106, 279, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    temp = ui.sprite("images/proFillerBlue.png",{880, 48})
    display.adapt(temp, 110, 283, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    self.expProcess = temp

    temp = ui.label("", General.font1, 47, {color={255,255,255}})
    display.adapt(temp, 550, 307, GConst.Anchor.Center)
    bg:addChild(temp)
    self.expLabel = temp
    temp = ui.label("", General.font1, 47, {color={121,212,2}})
    display.adapt(temp, 550, 307, GConst.Anchor.Left)
    bg:addChild(temp)
    self.expAddLabel = temp

    temp = ui.button({208, 158}, self.autoSelectHeros, {cp1=self, image="images/btnOrange.png"})
    display.adapt(temp, 899, 1231, GConst.Anchor.Center)
    bg:addChild(temp)
    self.autoSelectHerosBut=temp
    local but=temp:getDrawNode()
    temp = ui.sprite("images/btnMBattle1.png",{121*0.77, 117*0.77})
    display.adapt(temp, 94, 44, GConst.Anchor.LeftBottom)
    but:addChild(temp)
    temp = ui.sprite("images/btnMBattle1.png",{121, 117})
    display.adapt(temp, 43, 41, GConst.Anchor.LeftBottom)
    but:addChild(temp)
    temp = ui.sprite("images/dialogItemYes.png",{90, 108})
    display.adapt(temp, 140, 84, GConst.Anchor.LeftBottom)
    but:addChild(temp)
    self.autoSelectImage = temp

    temp = ui.button({208, 158}, self.onUpgradeHero, {cp1=self, image="images/btnOrange.png"})
    display.adapt(temp, 899, 149, GConst.Anchor.Center)
    bg:addChild(temp)
    temp:setBackgroundSound("sounds/mercenary_upgrade.mp3")
    self.upgradeBut = temp
    but=temp:getDrawNode()
    local but=temp:getDrawNode()
    temp = ui.sprite("images/btnMBattle1.png",{121,117})
    display.adapt(temp, 104, 96, GConst.Anchor.Center)
    but:addChild(temp)
    temp = ui.sprite("images/btnUpgrade2.png",{110, 122})
    display.adapt(temp, 129, 76, GConst.Anchor.LeftBottom)
    but:addChild(temp)

    temp = ui.particle("images/dialogs/xingpao1.plist")
    temp:setPosition(795,228)
    temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
    bg:addChild(temp)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",0.4,208,0},{"moveBy",0.3,0,-150},{"moveBy",0.4,-208,0},{"moveBy",0.3,0,150}})))
    self.upgradeEffect = temp
    self.upgradeEffect:setVisible(false)

    local infoLabels = {}
    for i=1, 4 do
        -- temp=ui.colorNode({579, 2},{0,0,0})
        -- display.adapt(temp, 121, 252-50*i, GConst.Anchor.LeftBottom)
        -- bg:addChild(temp)
        temp = ui.label("", General.font2, 32, {color={255,255,255}})
        display.adapt(temp, 410, 254-50*i, GConst.Anchor.RightBottom)
        bg:addChild(temp)
        infoLabels[i] = temp
        temp = ui.label("", General.font2, 32, {color={255,255,255}})
        display.adapt(temp, 462, 254-50*i, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        infoLabels[i+4] = temp
        if i<4 then
            temp = ui.label("", General.font2, 32, {color={121,212,2}})
            display.adapt(temp, 462, 254-50*i, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            infoLabels[i+8] = temp
        end
    end
    infoLabels[1]:setString(StringManager.getString("propertyHp"))
    infoLabels[2]:setString(StringManager.getString("propertyDps"))
    infoLabels[3]:setString(StringManager.getString("propertyTroops"))
    infoLabels[4]:setString(StringManager.getString("propertyHeros"))
    self.infoLabels = infoLabels

    self.upgradeStat = {exp=0, num=0, star=0, heros={}}
    self.upgradeStat.chips = {}
    self.autoSelected = false

    local hero = self.heroMsg
    --刷新英雄图片
    if self.roleFeature then
        self.roleFeature:removeFromParent(true)
        self.roleFeature = nil
    end
    self.roleFeature = GameUI.addHeroFeature(self.view, hero.hid, 1, 540, 242, 0, nil, hero.awakeUp)
    if self.roleJob then
        self.roleJob:removeFromParent(true)
        self.roleJob = nil
    end
    self.roleJob = GameUI.addHeroJobIcon(self.heroBlock, hero.info.job, 0.95, 95, 1300)
    self.nameLabel:setString(hero:getName())
    GameUI.setHeroNameColor(self.nameLabel, hero.info.displayColor or hero.info.color)
    local hdata = hero:getHeroDataByLevel(hero.level, hero.starUp)
    for i=1, 3 do
        local olabel = self.infoLabels[i+4]
        olabel:setString(tostring(hdata[i]))
        self.infoLabels[i+8]:setPositionX(470+olabel:getContentSize().width*olabel:getScaleX())
    end
    self:reloadUpgradeItems()
    self.upStartsInfos={}
    self.upStartsInfos.hid=hero.hid
    self.upStartsInfos.maxStar=hero.info.maxStar
    local lv,mlv,star,exp,nextExp = hero:computeAddExp(self.upgradeStat)
    self.upStartsInfos.oldStar=star
    self.upStartsInfos.oldHp=hdata[1]
    self.upStartsInfos.oldDps=hdata[2]
    self.upStartsInfos.oldMaxLv=mlv
end

function HeroUpgradeTab:reloadUpgradeItems()
    local hero = self.heroMsg
    --刷新英雄的星星/荣耀
    local lv,mlv,star,exp,nextExp = hero:computeAddExp(self.upgradeStat)
    self:getDialog():reloadStars(self, hero.info.maxStar, star)
    --刷新英雄等级
    self.levelLabel:setString(StringManager.getFormatString("labelHeroLevel", {num=lv, max=mlv}))
    if exp>=nextExp then
        self.expLabel:setString(tostring(exp))
        if nextExp==0 then
            nextExp = 1
            exp = 0
        else
            exp = nextExp
        end
    else
        self.expLabel:setString(exp .. "/" .. nextExp)
    end
    self.isMaxLevel = lv>=mlv
    self.isMaxStar = self.isMaxLevel and star>=hero.info.maxStar
    if self.upgradeStat.exp>0 then
        self.expAddLabel:setString("+" .. self.upgradeStat.exp)
        local w1 = self.expLabel:getContentSize().width*self.expLabel:getScaleX()
        local w2 = self.expAddLabel:getContentSize().width*self.expAddLabel:getScaleX()
        self.expLabel:setPositionX(550-w2/2-4)
        self.expAddLabel:setPositionX(550+w1/2+4)
    else
        self.expAddLabel:setString("")
        self.expLabel:setPositionX(550)
    end
    local p = exp/nextExp
    if p>1 then
        p = 1
    end
    self.expProcess:setScaleX(880*p/self.expProcess:getContentSize().width)
    local hdata = hero:getHeroDataByLevel(hero.level, hero.starUp)
    local hdata2 = hero:getHeroDataByLevel(lv, star)
    for i=1, 3 do
        if hdata2[i]>hdata[i] then
            self.infoLabels[i+8]:setString("+" .. (hdata2[i]-hdata[i]))
        else
            self.infoLabels[i+8]:setString("")
        end
    end
    self.infoLabels[8]:setString(tostring(self.upgradeStat.num))

    local isGuide = false
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "upgradeHero" then
        isGuide = true
    end
    if self.upgradeStat.num==0 then
        self.upgradeBut:setGray(true)
        self.upgradeEffect:setVisible(false)
        if isGuide then
            if self.guideArrow then
                self.guideArrow:removeFromParent(true)
                self.guideArrow = nil
            end
        end
        if self.guideIcon then
            self.guideIcon:setVisible(true)
        end
    else
        self.upgradeBut:setGray(false)
        self.upgradeEffect:setVisible(true)
        if isGuide then
            if not self.guideArrow then
                self.guideArrow = context.guideHand:showArrow(self.view, 899, 200, 10)
            end
            if self.guideIcon then
                self.guideIcon:setVisible(false)
            end
        end
    end
    if self.autoSelected then
        self.autoSelectImage:setSValue(0)
    else
        self.autoSelectImage:setSValue(-100)
    end
end

function HeroUpgradeTab:loadOtherHeroBlock()
    local context = self:getContext()
    local canUseHero = {}
    local heros = context.heroData:getAllHeros()
    for _, hero in pairs(heros) do
        if hero~=self.heroMsg and hero.lock==0 then
            table.insert(canUseHero, hero)
        end
    end
    table.sort(canUseHero, GameLogic.sortExpHero)
    self.numLabel = {}
    self.willUsedChipNum = {}
    local infos={}
    local count = 4
    --标题1
    infos[1] = {index=1,type="label1"}
    infos[2] = {index=2,type="none"}
    infos[3] = {index=3,type="none"}
    local chipTypeNum = SData.getData("property",const.ItemChip)
    for i, item in KTIPairs(chipTypeNum) do
        local chipnum = context:getItem(const.ItemChip, i)
        if chipnum ~= 0 then
            infos[count] = {index=count,type="newPropChip",resID=i,num=chipnum}
            count = count + 1
        end
    end

    --补充空格
    if count >= 4 and count <= 6 then
        if count == 4 then
            infos[4] = {index=4, type="buyExp"}
            infos[5] = {index=5,type="none"}
            infos[6] = {index=6,type="none"}
        elseif count == 5 then
            infos[5] = {index=5,type="none"}
            infos[6] = {index=6,type="none"}
        elseif count == 6 then
            infos[6] = {index=6,type="none"}
        end
        count = 7
    elseif count > 7 and count <= 9 then
        if count == 8 then
            infos[8] = {index=8,type="none"}
            infos[9] = {index=9,type="none"}
        elseif count == 9 then
            infos[9] = {index=9,type="none"}
        end
        count = 10
    end
    --标题2
    infos[count] = {index=count,type="label2"}
    infos[count+1] = {index=count+1,type="none"}
    infos[count+2] = {index=count+2,type="none"}
    count = count + 2
    --添加英雄
    for i, hero in ipairs(canUseHero) do
        infos[i+count]={index=i+count, type="hero", heroKey=hero.idx , hero = hero}
    end
    if self.tableView then
        self.tableView.view:removeFromParent(true)
        self.tableView = nil
    end
    local tableView = ui.createTableView({930, 1306}, false, {size=cc.size(238,229), offx=20, offy=32, disx=70, disy=52, rowmax=3, infos=infos, cellUpdate=Handler(self.updateHeroCell, self)})
    display.adapt(tableView.view, 1096, 54, GConst.Anchor.LeftBottom)
    self.view:addChild(tableView.view)
    self.infos = infos
    self.tableView = tableView
end

local _tsetting = {flagState=true, flagEquip=true}
function HeroUpgradeTab:updateHeroCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    if info.type=="none" then
        return
    elseif info.type=="label1" then
        cell:setEnable(false)
        --吞噬芯片标题
        local title = ui.label(Localize("titleDevourChip"), General.font1, 57)
        display.adapt(title,5,54)
        bg:addChild(title)
    elseif info.type=="label2" then
        cell:setEnable(false)
         --吞噬芯片标题
        local title = ui.label(Localize("titleDevourHero"), General.font1, 57)
        display.adapt(title,5,54)
        bg:addChild(title)
    elseif info.type=="buyExp" then
        --增加购买芯片
        local temp = ui.scale9("images/bgWhite.9.png", 20, {248, 238})
        temp:setColor(cc.c3b(0,0,0))
        temp:setOpacity(79)
        temp:setCustomPoint(0,0.025,0,0,0)
        temp:setCustomPoint(1,0,0.945,0,1)
        temp:setCustomPoint(2,1,0.029,1,0)
        temp:setCustomPoint(3,0.935,1,1,1)
        display.adapt(temp, 3, -14)
        bg:addChild(temp)
        temp = ui.scale9("images/bgDarkEdgeWhite.9.png", 20, {240,231})
        temp:setColor(cc.c3b(82,186,231))
        temp:setCustomPoint(1,0,0.975,0,1)
        temp:setCustomPoint(3,0.962,1,1,1)
        display.adapt(temp, -1, -1)
        bg:addChild(temp)
        temp = ui.sprite("images/storeItemResource4.png",{457*0.5,279*0.5})
        display.adapt(temp, 0, 120, GConst.Anchor.Left)
        bg:addChild(temp)
        temp = ui.sprite("images/btnAdd.png",{80,80})
        display.adapt(temp, -20, -20, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        local function callStore()
            if self.inAnimate then
                return
            end
            display.showDialog(AlertDialog.new(3,Localize("alertTitleNormal"),Localize("alertTextGobuyExp"),{callback=function ()
                StoreDialog.new({id=1,guideBuyExp=true})
            end}))
        end
        cell:setScriptCallback(ButtonHandler(callStore))
    elseif info.type=="newPropChip" then
        local temp = ui.scale9("images/bgWhite.9.png", 20, {248, 238})
        temp:setColor(cc.c3b(0,0,0))
        temp:setOpacity(79)
        temp:setCustomPoint(0,0.025,0,0,0)
        temp:setCustomPoint(1,0,0.945,0,1)
        temp:setCustomPoint(2,1,0.029,1,0)
        temp:setCustomPoint(3,0.935,1,1,1)
        display.adapt(temp, 3, -14)
        bg:addChild(temp)
        temp = ui.scale9("images/bgDarkEdgeWhite.9.png", 20, {240,231})
        temp:setColor(cc.c3b(82,186,231))
        temp:setCustomPoint(1,0,0.975,0,1)
        temp:setCustomPoint(3,0.962,1,1,1)
        display.adapt(temp, -1, -1)
        bg:addChild(temp)
        temp = ui.sprite("images/roles/heroExp"..info.resID..".png")
        temp:setScale(0.56)
        display.adapt(temp, 10, 120, GConst.Anchor.Left)
        bg:addChild(temp)
        self.numLabel[info.resID] = ui.label("0/"..tostring(info.num), General.font1, 47)
        display.adapt(self.numLabel[info.resID],125,35, GConst.Anchor.Center)
        bg:addChild(self.numLabel[info.resID])
        info.view = cell

        local function onUseItemChip(num)
            local willUsedChip = num
            local us = self.upgradeStat
            if not us then
                return
            end
            local oldNum = us.chips[info.resID] or 0
            us.chips[info.resID] = willUsedChip
            us.exp = us.exp+(willUsedChip-oldNum)*SData.getData("property", const.ItemChip, info.resID).value
            us.num = us.num+(willUsedChip-oldNum)
            self.autoSelected = false
            self:reloadUpgradeItems()
            self.numLabel[info.resID]:setString(tostring(willUsedChip).."/"..tostring(info.num))
            return true
        end

        local function chilkedChip()
            if self.inAnimate then
                return
            end
            local hero = self.heroMsg
            local property = SData.getData("property", const.ItemChip, info.resID)
            local lv,mlv,star,exp,nextExp = hero:computeAddExp(self.upgradeStat)
            local nowExp = SData.getData("hlevels",hero.info.type,lv).total + exp - property.value * (self.upgradeStat.chips[info.resID] or 0)
            local maxExp = SData.getData("hlevels",hero.info.type,mlv).total
            local countExp = maxExp - nowExp
            if countExp < 0 then countExp = 0 end
            local canUsedChipNum = math.ceil(countExp/property.value)
            if canUsedChipNum > info.num then canUsedChipNum = info.num end
            local params = {context=self:getContext(), parent=self, itemtype=const.ItemChip, itemid=info.resID, itemnum=canUsedChipNum, num=self.upgradeStat.chips[info.resID] or 0, minNum=0}
            params.mode = const.ResExp
            params.price = property.value
            params.onSureCallback = onUseItemChip
            display.showDialog(ItemUseDialog.new(params))
        end
        cell:setScriptCallback(ButtonHandler(chilkedChip))
        --引导
        local context = GameLogic.getUserContext()
        local temp=GameLogic.useTalentMatch and 4 or 3
        if info.resID==temp and context.guide:getStep().type == "upgradeHero" and context.guide:getStep().type ~= "finish" then
            local guideIcon = context.guideHand:showArrow(cell,100,50,100)
            guideIcon:setScaleY(-1)
            self.guideIcon = guideIcon
        end
    else
        if not info.view then
            info.view = cell
            cell:setScriptCallback(ButtonHandler(self.onHeroCellAction, self, info))
        end
        GameUI.updateHeroTemplate(bg, info, self:getContext().heroData:getHero(info.heroKey), _tsetting)
    end
end

function HeroUpgradeTab:onHeroCellAction(info)
    if self.inAnimate then
        return
    end
    if self:getContext().guide:getStep().type ~= "finish" and info.hero.hid%1000 ~= 0 then
        display.pushNotice(Localize("stringPleaseGuideFirst"))
        return
    end
    local hero = self:getContext().heroData:getHero(info.heroKey)
    if self.upgradeStat.heros[hero.idx] then
        self:removeSelectedHero(hero, info)
        self.autoSelected = false
        self:reloadUpgradeItems()
    else
        if self:checkUpgradeMax(info, false) then
            return
        end
        local layouts = hero.layouts
        local needEnsure = false
        for _, ltype in pairs(layouts) do
            if ltype.type>=1 then
                needEnsure = true
                break
            end
        end
        if needEnsure then
            display.showDialog(AlertDialog.new(3,Localize("alertTitleNormal"),Localize("alertTextHeroState"),{callback=Handler(self.onForceSelect, self, info)}))
        else
            self:addSelectedHero(hero, info)
            self.autoSelected = false
            self:reloadUpgradeItems()
        end
    end
end

function HeroUpgradeTab:onForceSelect(info)
    local heroData = self:getContext().heroData
    local hero = heroData:getHero(info.heroKey)
    local layouts = hero.layouts
    for lid, _ in pairs(layouts) do
        heroData:changeHeroLayout(hero, lid, 0, 0)
    end
    self:onHeroCellAction(info)
end

function HeroUpgradeTab:checkUpgradeMax(heros, isAuto)
    if self.isMaxStar then
        display.showDialog(AlertDialog.new(4,Localize("alertTitleNormal"),Localize("noticeHeroLevelMax2")))
        return true
    end
    if self.showedNotice or (not self.isMaxLevel and not isAuto) then
        return false
    end
    local shouldNotice = false
    local hero = self.heroMsg
    local us = {}
    if isAuto then
        us.exp = 0
        us.star = 0
        for _, hero2 in pairs(heros) do
            us.exp = us.exp+hero2:getAddExp()
            if hero2.hid==hero.hid then
                us.star = us.star+1
            end
        end
        local lv,mlv,star,exp,nextExp = hero:computeAddExp(us)
        shouldNotice = lv>=mlv
    else
        shouldNotice = true
    end
    if shouldNotice then
        self.showedNotice = true
        local handler = nil
        if isAuto then
            handler = Handler(self.autoSelectHeros, self)
        else
            handler = Handler(self.onHeroCellAction, self, heros)
        end
        display.showDialog(AlertDialog.new(3,Localize("alertTitleNormal"),Localize("noticeHeroLevelMax1"),{callback=handler}))
        return true
    end
    return false
end

function HeroUpgradeTab:addSelectedHero(hero, info)
    local exp = hero:getAddExp()
    local us = self.upgradeStat
    us.heros[hero.idx] = exp
    us.num = us.num+1
    us.exp = us.exp+exp
    if hero.hid==self.heroMsg.hid then
        us.star = us.star+1
    end
    info.forceState = true
    GameUI.resetHeroState(info.view, info, hero)

    --引导
    if info.guideIcon then
        info.guideIcon:removeFromParent(true)
        info.guideIcon = nil
    end
end

function HeroUpgradeTab:removeSelectedHero(hero, info)
    local us = self.upgradeStat
    us.num = us.num-1
    us.exp = us.exp-us.heros[hero.idx]
    us.heros[hero.idx] = nil
    if hero.hid==self.heroMsg.hid then
        us.star = us.star-1
    end
    info.forceState = nil
    GameUI.resetHeroState(info.view, info, hero)

    --引导
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "upgradeHero" and info.hero.hid%1000 == 0 then
        if not info.guideIcon then
            local view = info.view:getParent()
            local x,y = info.view:getPosition()
            info.guideIcon = context.guideHand:showArrow(view,x,y-50,100)
            info.guideIcon:setScaleY(-1)
        end
    end
end

function HeroUpgradeTab:autoSelectHeros()
    --引导
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "upgradeHero" and context.guide:getStep().type ~= "finish" then
        display.pushNotice(Localize("stringPleaseGuideFirst"))
        return
    end
    local us = self.upgradeStat
    local hdata = self:getContext().heroData
    if not self.autoSelected then
        local autoSuit, hero = false
        local myColor = self.heroMsg.info.color
        local autoSuits = {}
        local autoChips = {}
        local isLevelMax = self.heroMsg.level>=self.heroMsg.maxLv
        local isRealMax = (self.heroMsg.starUp>=self.heroMsg.info.maxStar and isLevelMax)
        if not isLevelMax then
            local checkUs = {exp=0, star=0}
            --选择芯片
            local hero = self.heroMsg
            local nowExp = SData.getData("hlevels",hero.info.type,hero.level).total + hero.exp
            local maxExp = SData.getData("hlevels",hero.info.type,hero.maxLv).total
            local countExp = maxExp - nowExp
            if countExp < 0 then countExp = 0 end
            local chipTypeNums = SData.getData("property",const.ItemChip)
            for j, item in KTIPairs(chipTypeNums) do
                local chipnum = self:getContext():getItem(const.ItemChip, j)
                if chipnum ~= 0 then
                    local chipTypeNum = item
                    -- local needNum = math.ceil(countExp/chipTypeNum.value)
                    local needNum = math.ceil(countExp/chipTypeNum.value)
                    if needNum > chipnum then
                        needNum = chipnum
                    end
                    autoChips[j] = needNum
                    checkUs.exp = checkUs.exp + needNum*chipTypeNum.value
                    countExp = countExp - needNum*chipTypeNum.value
                    if countExp < 0 then
                        for k = j - 1, 1, -1 do
                            local backValue = autoChips[k] or 0
                            if backValue > 0 then
                                local chipTypeNum2 = chipTypeNums[k]
                                local backNeedValue = math.floor(-countExp/chipTypeNum2.value)
                                if backNeedValue > backValue then
                                    backNeedValue = backValue
                                end
                                countExp = countExp + backNeedValue * chipTypeNum2.value
                                autoChips[k] = autoChips[k] - backNeedValue
                                if countExp == 0 then
                                    break
                                end
                            end
                        end
                        countExp = 0
                    end
                end
            end
            if countExp > 0 then
                autoSuit, hero = false
                for _, info in ipairs(self.infos) do
                    if info.heroKey then
                        hero = hdata:getHero(info.heroKey)
                        if hero.info.job==0 then
                            autoSuit = true
                        elseif self:getContext().guide:getStep().type == "finish" and hero.level==1 and hero.exp==0 and hero.info.color<myColor and hero.info.color<4 and (hero.info.rating or 0) < 3 then
                            autoSuit = true
                            for _, ltype in pairs(hero.layouts) do
                                if ltype.type>=1 then
                                    autoSuit = false
                                    break
                                end
                            end
                        else
                            autoSuit = false
                        end
                        if autoSuit then
                            autoSuits[info] = hero
                            checkUs.exp = checkUs.exp+hero:getAddExp()
                            local lv,mlv,star,exp,nextExp = self.heroMsg:computeAddExp(checkUs)
                            if lv>=mlv then
                                break
                            end
                        end
                    end
                end
            end
        end
        for _, info in ipairs(self.infos) do
            if info.heroKey then
                if autoSuits[info] then
                    if not us.heros[info.heroKey] then
                        self:addSelectedHero(autoSuits[info], info)
                    end
                else
                    if us.heros[info.heroKey] then
                        self:removeSelectedHero(hdata:getHero(info.heroKey), info)
                    end
                end
            end
        end
        for i, num in pairs(autoChips) do
            local oldNum = us.chips[i] or 0
            us.chips[i] = num
            us.exp = us.exp + (num-oldNum) * SData.getData("property",const.ItemChip,i).value
            us.num = us.num + (num-oldNum)
            self.numLabel[i]:setString(tostring(num).."/"..tostring(self:getContext():getItem(const.ItemChip, i)))
        end
    else
        --取消选择芯片
        for i,num in KTIPairs(SData.getData("property",const.ItemChip)) do
            if self.numLabel[i] then
                local oldNum = us.chips[i] or 0
                us.chips[i] = 0
                us.exp = us.exp - oldNum * SData.getData("property",const.ItemChip,i).value
                us.num = us.num - oldNum
                local num = self:getContext():getItem(const.ItemChip, i)
                self.numLabel[i]:setString("0/"..tostring(self:getContext():getItem(const.ItemChip, i)))
            end
        end

        for _, info in ipairs(self.infos) do
            if info.heroKey then
                if us.heros[info.heroKey] then
                    self:removeSelectedHero(hdata:getHero(info.heroKey), info)
                end
            end
        end
    end
    self.autoSelected = not self.autoSelected
    self:reloadUpgradeItems()
end

function HeroUpgradeTab:onUpgradeHero(force)
    local us = self.upgradeStat
    if self.inAnimate or not us or us.num==0 then
        return
    end
    local hero
    local colorHigh = false
    local hdata = self:getContext().heroData
    local myColor = self.heroMsg.info.color
    for hidx, _ in pairs(us.heros) do
        hero = hdata:getHero(hidx)
        if hero and hero.info.color>myColor and hero.info.job>0 then
            colorHigh = true
            break
        end
    end
    if colorHigh and not force then
        display.showDialog(AlertDialog.new(3, Localize("alertTitleNormal"), Localize("alertTextColorHigh"), {callback=Handler(self.onUpgradeHero, self, true)}))
        return
    else
        hdata:upgradeHero(self.heroMsg, us)
        self.autoSelected = false
        if self.guideIcon then
            self.guideIcon = nil
        end
        self:onUpgradeHeroAnimate()
    end
end

function HeroUpgradeTab:onCellUseAnimate(info)
    local bg = info.view:getDrawNode()
    local p=ui.animateSprite(0.7,"kapian",7,{beginNum=0,plist="images/dialogs/upgrade_kapianposui.plist",isRepeat=false})
    display.adapt(p, 119, 118, GConst.Anchor.Center)
    bg:addChild(p)
    p:setOpacity(0)
    p:runAction(ui.action.sequence({{"fadeIn",0.4}, {"delay",0.3},"remove"}))
    p = ui.particle("images/dialogs/chibaokai.plist")
    p:setPosition(119, 118)
    p:setPositionType(cc.POSITION_TYPE_GROUPED)
    bg:addChild(p)
    local pos2 = info.view:convertToWorldSpace(cc.p(119,118))
    local pos3 = self.view:convertToNodeSpace(pos2)
    local x = pos3.x+36
    local y = pos3.y-28
    p = ui.particle("images/dialogs/chika.plist")
    p:setPosition(x,y)
    p:setPositionType(cc.POSITION_TYPE_RELATIVE)
    self.view:addChild(p,3)
    p:runAction(ui.action.sequence({{"moveTo",1,545,485},"remove"}))
end

function HeroUpgradeTab:onCellUseAnimate2(info)
    local bg = info.view:getDrawNode()
    local p
    local pos2 = info.view:convertToWorldSpace(cc.p(119,118))
    local pos3 = self.view:convertToNodeSpace(pos2)
    local x = pos3.x+36
    local y = pos3.y-28
    p = ui.particle("images/dialogs/chika.plist")
    p:setPosition(x,y)
    p:setPositionType(cc.POSITION_TYPE_RELATIVE)
    self.view:addChild(p,3)
    p:runAction(ui.action.sequence({{"moveTo",1,545,485},"remove"}))
end

local function _addThunder(bg)
    local p= ui.animateSprite(0.6, "coushandian_",6, {beginNum=0,isRepeat=false, plist="images/dialogs/upgrade_dian.plist"})
    display.adapt(p,545,485,GConst.Anchor.Center)
    bg:addChild(p,2)
    p:setRotation(40)
    p:setScaleX(2.8)
    p:setScaleY(5.6)
    p:runAction(ui.action.sequence({{"scaleTo",0.1,3.3,6.6},{"scaleTo",0,2.8,5.6},{"scaleTo",0.1,3.3,6.6},{"rotateBy",0,-83},ui.action.arepeat(ui.action.sequence({{"scaleTo",0,2.8,5.6},{"scaleTo",0.1,3.3,6.6}}),4),"remove"}))
    ui.setBlend(p,772,1)
end

local function _addThunder3(bg)
    local p = ui.animateSprite(0.5, "baodian_",5, {beginNum=1, isRepeat=false, plist="images/dialogs/upgrade_baodian.plist"})
    display.adapt(p,545,485,GConst.Anchor.Center)
    bg:addChild(p,2)
    ui.setBlend(p,772,1)
    p:runAction(ui.action.sequence({{"delay",0.5},"remove"}))
end

local function _addThunder2(bg)
    local p=ui.sprite("images/dialogs/baodian_0.png")
    display.adapt(p,565,485,GConst.Anchor.Center)
    bg:addChild(p,2)
    p:setScale(0.5)
    ui.setBlend(p,772,1)
    p:runAction(ui.action.sequence({{"scaleTo",0.2,1.5,1.5},{"call",Handler(_addThunder3, bg)},"remove"}))

    p=ui.sprite("images/dialogs/upgrade_chongjibo.png")
    display.adapt(p,565,485,GConst.Anchor.Center)
    bg:addChild(p,2)
    p:setScale(0.25)
    p:runAction(ui.action.scaleTo(0.2,1.5,1.5))
    p:runAction(ui.action.sequence({{"fadeOut",0.2},"remove"}))
    ui.setColor(p,255,166,0)
    ui.setBlend(p, 770, 1)
end

function HeroUpgradeTab:onUpgradeHeroAnimate()
    --引导
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "upgradeHero" then
        context.guide:addStep()
        self.shouldShowArrow = true
    end

    music.play("sounds/heroUpgrade.wav")
    self.inAnimate = true
    self.autoSelectHerosBut:setEnable(false)
    self.upgradeBut:setGray(true)
    self.upgradeEffect:setVisible(false)
    local us = self.upgradeStat
    local delay = 0
    for i, info in ipairs(self.infos) do
        if info.type == "newPropChip" and info.resID and (us.chips[info.resID] or 0) > 0 then
            info.view:runAction(ui.action.sequence({{"delay", delay},{"call",Handler(self.onCellUseAnimate2, self, info)}}))
            delay = delay+0.2
        end
        if info.heroKey and info.content and us.heros[info.heroKey] then
            info.content:runAction(ui.action.sequence({{"delay", delay},{"fadeOut",0.2},{"call",Handler(self.onCellUseAnimate, self, info)}, "hide"}))
            delay = delay+0.2
        end
    end
    local p = ui.sprite("images/dialogs/upgrade_mofaz5.png")
    p:setScale(1.4)
    display.adapt(p, 545, 485, GConst.Anchor.Center)
    self.heroBlock:addChild(p)
    p:setOpacity(0)
    p:runAction(ui.action.sequence({{"fadeIn",1.5},{"fadeOut",1},"remove"}))
    ui.setBlend(p, 772, 1)

    p=ui.sprite("images/dialogs/upgrade_mofaz2.png")
    p:setScale(1.75)
    display.adapt(p, 545, 485, GConst.Anchor.Center)
    self.heroBlock:addChild(p)
    p:setOpacity(0)
    p:setVisible(false)
    p:runAction(ui.action.sequence({{"delay",0.2},"show",{"fadeIn",1.4},{"fadeOut",1.4},"remove"}))
    ui.setBlend(p, 772, 1)

    local node=ui.node()
    node:setPosition(545,485)
    self.heroBlock:addChild(node)
    node:setScale(10)
    p=ui.sprite("images/dialogs/upgrade_guang.png")
    display.adapt(p, 0, 0, GConst.Anchor.Center)
    node:addChild(p)
    p:setVisible(false)
    p:setOpacity(0)
    ui.setColor(p,255,193,0)
    ui.setBlend(p, 770, 1)
    p:runAction(ui.action.sequence({{"delay",0.1},"show",{"fadeIn",0.8},{"delay",1.1},{"fadeOut",0.8},"remove"}))
    p:runAction(ui.action.rotateBy(14,1800))
    node:runAction(ui.action.sequence({{"delay",2.8},"remove"}))

    p=ui.sprite("images/dialogs/upgrade_chi.png")
    display.adapt(p, 458, 589, GConst.Anchor.Center)
    self.heroBlock:addChild(p,2)
    p:setScale(0.7)
    p:setVisible(false)
    p:setOpacity(0)
    p:setRotation(-75)
    p:runAction(ui.action.rotateBy(8,2000))
    p:runAction(ui.action.sequence({{"delay",0.3},"show",{"fadeIn",0.2},{"fadeOut",0.8},"remove"}))
    ui.setColor(p,255,154,61)
    ui.setBlend(p, 772, 1)

    p=ui.sprite("images/dialogs/upgrade_chi.png")
    display.adapt(p, 695, 460, GConst.Anchor.Center)
    self.heroBlock:addChild(p,2)
    p:setScale(0.7)
    p:setVisible(false)
    p:setOpacity(0)
    p:setRotation(-200)
    p:runAction(ui.action.rotateBy(8,2000))
    p:runAction(ui.action.sequence({{"delay",0.8},"show",{"fadeIn",0.2},{"fadeOut",0.8},"remove"}))
    ui.setColor(p,255,154,61)
    ui.setBlend(p, 772, 1)

    p=ui.sprite("images/dialogs/upgrade_chi.png")
    display.adapt(p, 454, 263, GConst.Anchor.Center)
    self.heroBlock:addChild(p,2)
    p:setScale(0.7)
    p:setVisible(false)
    p:setOpacity(0)
    p:setRotation(-375)
    p:runAction(ui.action.rotateBy(8,2000))
    p:runAction(ui.action.sequence({{"delay",1.5},"show",{"fadeIn",0.2},{"fadeOut",0.8},"remove"}))
    ui.setColor(p,255,154,61)
    ui.setBlend(p, 772, 1)

    self.heroBlock:runAction(ui.action.sequence({{"delay",1.6},{"call",Handler(_addThunder, self.heroBlock)}}))

    local node2=ui.node()
    node2:setPosition(545,485)
    self.heroBlock:addChild(node2,2)
    node2:setScale(10)
    p=ui.sprite("images/dialogs/upgrade_guang.png")
    display.adapt(p, 0, 0, GConst.Anchor.Center)
    node2:addChild(p)
    p:setVisible(false)
    p:setOpacity(0)
    p:runAction(ui.action.sequence({{"delay",1},"show",{"fadeIn",0.5},{"fadeOut",0.5},"remove"}))
    p:runAction(ui.action.rotateBy(14,1800))
    node2:runAction(ui.action.sequence({{"delay",2.8},"remove"}))
    ui.setColor(p,255,193,0)
    ui.setBlend(p, 770, 1)

    self.heroBlock:runAction(ui.action.sequence({{"delay",1.2},{"call",Handler(_addThunder2, self.heroBlock)}}))
    self.heroBlock:runAction(ui.action.sequence({{"delay",3.5},{"call",Handler(self.finishUpgradeHeroAnimate, self)}}))
end

function HeroUpgradeTab:finishUpgradeHeroAnimate()
    if self.shouldShowArrow then
        local context = GameLogic.getUserContext()
        local x,y = self:getDialog().closeBut:getPosition()
        local arrow = context.guideHand:showArrow(self:getDialog().view,x,y-70,100)
        arrow:setScaleY(-1)
        if self.guideArrow then
            self.guideArrow:removeFromParent(true)
            self.guideArrow = nil
        end
    end

    self.inAnimate = false
    self.autoSelectHerosBut:setEnable(true)
    self.upgradeStat = {num=0, exp=0, star=0, heros={}, chips={}}
    self:loadOtherHeroBlock()
    local hdata = self.heroMsg:getHeroDataByLevel(self.heroMsg.level, self.heroMsg.starUp)
    for i=1, 3 do
        local olabel = self.infoLabels[i+4]
        olabel:setString(tostring(hdata[i]))
        self.infoLabels[i+8]:setPositionX(470+olabel:getContentSize().width*olabel:getScaleX())
    end
    self:reloadUpgradeItems()
    local hero = self.heroMsg
    local lv,mlv,star,exp,nextExp = hero:computeAddExp(self.upgradeStat)
    local hdata2 = hero:getHeroDataByLevel(hero.level, hero.starUp)
    self.upStartsInfos.newStar=star
    self.upStartsInfos.newMaxLv=mlv
    self.upStartsInfos.newHp=hdata2[1]
    self.upStartsInfos.newDps=hdata2[2]
    if star>self.upStartsInfos.oldStar then
        UpgradeStartsDialog.new(self.upStartsInfos)
        self:updateStarInfosAfterUpgrade()
    end
end
-- @brief: 用于在英雄升星后对英雄数据进行更新
function HeroUpgradeTab:updateStarInfosAfterUpgrade()
    self.upStartsInfos.oldHp=self.upStartsInfos.newHp
    self.upStartsInfos.oldDps=self.upStartsInfos.newDps
    self.upStartsInfos.oldMaxLv=self.upStartsInfos.newMaxLv
    self.upStartsInfos.oldStar=self.upStartsInfos.newStar
end
return HeroUpgradeTab
