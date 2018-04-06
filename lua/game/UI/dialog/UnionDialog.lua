local const = GMethod.loadScript("game.GameLogic.Const")
--联盟对话框，加入联盟，创建联盟，搜索联盟
local UnionDialog = class2("UnionDialog",function()
    return BaseView.new("UnionDialog.json")
end)

function UnionDialog:ctor(params,callback)
    self.params,self.callback = params,callback
    self.ps1,self.ps2,self.ps3,self.flagCost = 1,1,1,0
    self.tabId = self.params and self.params.tabId or 1

    self.createParams = {}
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth

    if self.params then
        self:initEdit()
    else
        self:initUI()
    end
    local eventNode = ui.node()
    GameEvent.bindEvent(eventNode, {"EventJoinClan", "EventCloseFinish"}, self, self.onEvent)
    self:addChild(eventNode)
    display.showDialog(self)
end

function UnionDialog:onEvent(event, params)
    if event == "EventJoinClan" then
        self.shouldClose = true
    elseif event == "EventCloseFinish" then
        if not self.deleted and self.priority == display.getDialogPri() and self.shouldClose then
            self.shouldClose = nil
            display.closeDialog(self.priority)
        end
    end
end

function UnionDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,0))
    self:loadView("buttonsViews")

    local bg = ui.node()
    self:addChild(bg,0)
    self.middleBack = bg
    self:loadView("middleBack",bg)
    self:insertViewTo()
    self.middleBack:setVisible(false)

    local bg = ui.node()
    self:addChild(bg,0)
    self.middleBack1 = bg
    self:loadView("middleBack1",bg)
    self:insertViewTo()
    self.middleBack1:setVisible(false)
    viewTab = self:getViewTab()
    self.buttons={}
    self.buttonsBack={}
    self.buttonsBack[1]=viewTab.but1BackImage
    self.buttonsBack[2]=viewTab.but2BackImage
    self.buttonsBack[3]=viewTab.but3BackImage
    --加入联盟按钮
    self.buttons[1]=viewTab.but1
    --创建联盟按钮
    self.buttons[2]=viewTab.but2
    --搜索联盟按钮
    self.buttons[3]=viewTab.but3
    viewTab.but1:setScriptCallback(Script.createCallbackHandler(Script.createBasicHandler(self.checkRandomleague,self,true)))
    viewTab.but2:setScriptCallback(Script.createCallbackHandler(Script.createBasicHandler(self.addCreateUnionViews,self)))
    viewTab.but3:setScriptCallback(Script.createCallbackHandler(Script.createBasicHandler(self.addSearchUnionViews,self)))
    local midNode=ui.node()
    midNode:setPosition(0,0)
    self:addChild(midNode,1)
    self.midNode=midNode
    --默认先选中3
    self.piackedButIdx=1
    self:initStaticVariable()
    self:initAddUnionRankUI()
    self:randomleague(0,0,false)

end

function UnionDialog:canChangeTab(call,tabId)
    if call and self.rightBut and self.leftBut then
        call()
        if tabId == 1 then
            self.rightBut:setGray(self.sBtnCup>=self.maxGoldCupNum or false)
            self.leftBut:setGray(self.sBtnCup<2 or false)
        else
            self.rightBut:setGray(self.sBtnWel>=self.maxWelfareNum or false)
            self.leftBut:setGray(self.sBtnWel<2 or false)
        end
        if tabId ~= self.selectTab then
            self.selectTab = tabId
        end
    end
end

function UnionDialog:initSwichButtonUI()
    -- body
    self.rightBut:setVisible(false)
    self.leftBut:setVisible(false)
    self.rightBut:setTouchPriority(-10)
    self.leftBut:setTouchPriority(-10)
    self.rightBut:setScriptCallback(Script.createCallbackHandler(self.checkBtnCallback,self,1,true))
    self.leftBut:setScriptCallback(Script.createCallbackHandler(self.checkBtnCallback,self,-1,false))
end

function UnionDialog:initStaticVariable()
    -- body
    self.sBtnCup = 1
    self.sBtnWel = 1
    self.selectTab = 1
    self.selectScreening = false
    self.checkFirst = true
    self.unionRankInfos = {}
    self.unionRankInfos1 = {}
end

function UnionDialog:initAddUnionRankUI()
    -- body
    local tabTitles
    if GameLogic.useTalentMatch then
        tabTitles = {Localize("btnUnionWarRank")}
    else
        tabTitles = {Localize("btnUnionWarRank"),Localize("btnUnionWelfareRank")}
    end
    local settings = {344,110,340,1250,96,"images/dialogTabBackSmall",50,150,55,0,0,0,0}
    local bg = ui.node()
    self:addChild(bg)
    self.rankBtnBg = bg
    self:addTabView(tabTitles,settings,nil,bg)
    self.tab[3]:addTab({create=Script.createBasicHandler(self.unionWarRankBtn,self)})
    if GameLogic.useTalentMatch then
    else
        self.tab[3]:addTab({create=Script.createBasicHandler(self.unionWelfareRankBtn,self)})
    end
end

function UnionDialog:checkBtnCallback(num,condition)
    local maxNum,sNum = 0,1
    if self.unionGoldCupInfo and self.unionWelfareInfo then
        local data,data1 = self.unionGoldCupInfo,self.unionWelfareInfo
        if self.selectScreening then
            data,data1 = self.checkGlodCupInfo,self.checkWelfareInfo
        end
        if self.selectTab == 1 then
            maxNum = self.maxGoldCupNum
            sNum = self.sBtnCup
        else
            maxNum = self.maxWelfareNum
            sNum = self.sBtnWel
        end
        local bidx = sNum + num
        self.rightBut:setGray(bidx>=maxNum or false)
        self.leftBut:setGray(bidx<2 or false)
        local judge = false
        if condition then
            if bidx <= maxNum then
                judge = true
            end
        else
            if bidx >= 1 then
                judge = true
            end
        end
        if judge then
            if self.selectTab == 1 then
                self.sBtnCup = bidx
                self:changeUnionInfo(data,bidx,1)
                self:unionWarRankBtn(nil)
            else
                self.sBtnWel = bidx
                self:changeUnionInfo(data1,bidx,2)
                self:unionWelfareRankBtn(nil)
            end
        end
    end
end

function UnionDialog:changeUnionInfo(unionInfo,idx,tabId)
    local infos={}
    if unionInfo and unionInfo[idx] then
        for i=1,#unionInfo[idx] do
            infos[i]={id=i,type=tabId,unionInfo = unionInfo[idx][i]}
        end
        if tabId == 1 then
            self.unionRankInfos = infos
        else
            self.unionRankInfos1 = infos
        end
    end
end

function UnionDialog:unionWarRankBtn(tab)
    if self.warNode then
        self.warNode:removeAllChildren(true)
    else
        local bg = ui.node()
        self.warNode = bg
    end
    self:addTableViewProperty("joinTableview",self.unionRankInfos,Script.createBasicHandler(self.callcell,self))
    self:loadView("joinTableview",self.warNode)
    local tableView = self:getTableView("joinTableview")
    tableView.view:setScrollEnable(false)
    return self.warNode
end

function UnionDialog:unionWelfareRankBtn(tab)
    if self.welfareNode then
        self.welfareNode:removeAllChildren(true)
    else
        local bg = ui.node()
        self.welfareNode = bg
    end
    self:addTableViewProperty("joinTableview",self.unionRankInfos1,Script.createBasicHandler(self.callcell,self))
    self:loadView("joinTableview",self.welfareNode)
    local tableView = self:getTableView("joinTableview")
    tableView.view:setScrollEnable(false)
    return self.welfareNode
end

function UnionDialog:callcell(cell, tableView, info)
    local item = info.unionInfo
    local bg = cell:getDrawNode()
    if info.id%2==1 then
        self:loadView("joinUnionViewsBack",bg)
    end
    self:loadView("joinUnionViews",bg)
    --把view加到self中
    self:insertViewTo()
    --联盟旗帜
    local temp = GameUI.addUnionFlag(item.ps1,item.ps2,item.ps3)
    bg:addChild(temp)
    temp:setScale(0.4)
    temp:setPosition(95,95)
    --联盟名字
    self.labelUnioName:setString(item.name)
    --语言
    self.labelCellLanguage:setString(Localize("labelLanguage"..item.language))
    --成员数量
    self.labelCellValue:setString(item.currentNum.."/"..item.maxNum)
    --宝石的icon
    if info.type == 2 then
        ui.setFrame(self.imgScoreName,"images/resCrystal.png")
    end
    --奖杯数量
    self.labelCellTrophyNum:setString(item.cup)
    --状态
    self.labelUnioJob:setString(Localize("labelJoinMethodValue"..item.state))
    ui.setListener(cell,function()
        UnionInfoDialog.new(item.uid)
    end)
    self.lab_PowerLimit:setString(Localize("labelPowerLimit"))
    self.lab_PowerValue:setString(item.powerLimit)
end

function UnionDialog:initFlag()
    local bg = self.midNode
    if self.flagNode then
        self.flagNode:removeFromParent(true)
        self.flagNode = nil
    end
    local temp = GameUI.addUnionFlag(self.ps1,self.ps2,self.ps3)
    temp:setScale(0.4)
    temp:setPosition(651,1167)
    bg:addChild(temp)
    self.flagNode = temp
    self:checkCreateCost()
end

function UnionDialog:addCreateUnionViews()
    self.rankBtnBg:setVisible(false)

    self.middleBack:setVisible(true)
    self.middleBack1:setVisible(false)
    self.screeningBg:setVisible(false)

    self.changeBtn1 = false
    self.changeBtn2 = false
    self:pickedButton(2)
    local bg=self.midNode
    bg:removeAllChildren(true)
    self.searchNode = nil
    self:loadView("createUnionViews",bg)
    self:insertViewTo()

    --联盟名字输入
    local unionName = ui.textBox({715,70}, "", General.font6, 45, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
    display.adapt(unionName, 557, 993, GConst.Anchor.LeftBottom)
    bg:addChild(unionName)

    --联盟公告输入
    local unionNotice = ui.textBox({715,218}, "", General.font6, 45, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
    display.adapt(unionNotice, 557, 754, GConst.Anchor.LeftBottom)
    bg:addChild(unionNotice)

    --旗帜
    self.flagNode = nil
    self:initFlag()
    --选择
    self.butChoose:setListener(function()
        UnionFlagDialog.new(self.ps1,self.ps2,self.ps3,function(ps1,ps2,ps3,flagCost)
            if self.initFlag then
                self.ps1,self.ps2,self.ps3,self.flagCost = ps1,ps2,ps3,flagCost
                self:initFlag()
            end
        end)
    end)

    --宝石数
    self.btnCrystal:setString(200)
    --加入方式
    self.labelJoinMethodValue:setString(Localize("labelJoinMethodValue1"))
    --金杯限制
    self.labelTrophyLimitValue:setString("0")
    --联盟语言
    self.labelLanguageMethodValue:setString(Localize("labelLanguageCN"))
    self.jmIndex,self.tlIndex,self.llIndex = 1,0,1

    --创建
    self.butCrystal:setListener(function()
        local name = unionName:getText()
        if name == "" then
            display.pushNotice(Localize("stringUnionCreate1"))
            return
        end
        if GameLogic.getStringLen(name)>15 then
            display.pushNotice(Localize("stringUnionCreate2"))
            return
        end
        --宝石不足
        if GameLogic.getUserContext():getRes(const.ResCrystal)< self.flagCost+200 then
            local otherSettings = {yesBut="btnEnterShop",callback = function()
                        StoreDialog.new({id=1})
                    end}
            local dl = AlertDialog.new(2, Localize("alertTitleBuyCrystal"), Localize("alertTextBuyCrystal"),otherSettings)
            display.showDialog(dl)
        else
            local notice = unionNotice:getText()
            self.createParams = {name,notice, self.ps1*10000+self.ps2*100+self.ps3, self.jmIndex, self.tlIndex*2000,self.languageArr[self.llIndex]}

            local otherSettings = {ctype = const.ResCrystal,cvalue = self.flagCost+200,callback = function()
                self:createleague()
            end}

            local createDetial = ""
            if self.flagCost>0 then
                createDetial = Localizef("stringCreateDetial",{num = self.flagCost})
            end

            local dialog = AlertDialog.new(1,Localize("affirmCreate"),Localizef("stringAffirmCreate",{num = self.flagCost+200})..createDetial,otherSettings)
            display.showDialog(dialog)
        end
    end)

    --几个上下按钮
    self.joinMethodLeft:setListener(function()
        if self.jmIndex==1 then
            self.jmIndex = 3
        else
            self.jmIndex = self.jmIndex-1
        end
        self.createParams[4] = self.jmIndex
        self.labelJoinMethodValue:setString(Localize("labelJoinMethodValue"..self.jmIndex))
    end)
    local temp = ui.sprite("images/butUinonCreateNext.png",{74,74})
    temp:setFlippedX(true)
    display.adapt(temp,37,37,GConst.Anchor.Center)
    self.joinMethodLeft:getDrawNode():addChild(temp)
    self.joinMethodRight:setListener(function()
        if self.jmIndex==3 then
            self.jmIndex = 1
        else
            self.jmIndex = self.jmIndex+1
        end
        self.createParams[4] = self.jmIndex
        self.labelJoinMethodValue:setString(Localize("labelJoinMethodValue"..self.jmIndex))
    end)

    self.trophyLimitLeft:setListener(function()
        if self.tlIndex==0 then
        else
            self.tlIndex = self.tlIndex-1
        end
        self.createParams[5] = 2000*self.tlIndex
        self.labelTrophyLimitValue:setString(2000*self.tlIndex)
    end)
    temp = ui.sprite("images/butUinonCreateNext.png",{74,74})
    temp:setFlippedX(true)
    display.adapt(temp,37,37,GConst.Anchor.Center)
    self.trophyLimitLeft:getDrawNode():addChild(temp)
    self.trophyLimitRight:setListener(function()
        self.tlIndex = self.tlIndex+1
        self.createParams[5] = 2000*self.tlIndex
        self.labelTrophyLimitValue:setString(2000*self.tlIndex)
    end)
    self.languageArr = {"CN","HK","EN","IR","AR","FR","DE","OTHER"}
    self.languageLimitLeft:setListener(function()
        if self.llIndex == 1 then
            self.llIndex = #(self.languageArr)
        else
            self.llIndex = self.llIndex-1
        end
        self.createParams[6] = self.llIndex
        self.labelLanguageMethodValue:setString(Localize("labelLanguage"..self.languageArr[self.llIndex]))
    end)
    temp = ui.sprite("images/butUinonCreateNext.png",{74,74})
    temp:setFlippedX(true)
    display.adapt(temp,37,37,GConst.Anchor.Center)
    self.languageLimitLeft:getDrawNode():addChild(temp)
    self.languageLimitRight:setListener(function()
        if self.llIndex == #(self.languageArr) then
            self.llIndex = 1
        else
            self.llIndex = self.llIndex+1
        end
        self.createParams[6] = self.llIndex
        self.labelLanguageMethodValue:setString(Localize("labelLanguage"..self.languageArr[self.llIndex]))
    end)
end


function UnionDialog:checkCreateCost()
    local cost = 0
    if GameLogic.getUserContext().union then
        cost = self.flagCost
    else
        cost = self.flagCost+200
    end

    if GameLogic.getUserContext():getRes(const.ResCrystal)<cost then
        --宝石数
        self.btnCrystal:setString(cost)
        ui.setColor(self.btnCrystal,"red")
    end

    if cost>0 then
        self.btnCrystal:setString(cost)
        self.butCrystalImg:setVisible(true)
    else
        self.butCrystalImg:setVisible(false)
        self.btnCrystal:setString(Localize("buttonSave"))
    end
end


function UnionDialog:addSearchUnionViews()
    self.rankBtnBg:setVisible(false)

    self.middleBack:setVisible(true)
    self.middleBack1:setVisible(false)
    self.screeningBg:setVisible(false)

    self.changeBtn1 = false
    self.changeBtn2 = false
    self:pickedButton(3)
    local bg=self.midNode
    bg:removeAllChildren(true)
    self.searchNode = nil
    self.flagNode = nil
    self:loadView("searchUnionViews",bg)
    self:insertViewTo()

    local textBox = ui.textBox({715,70}, "", General.font6, 45, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
    display.adapt(textBox, 348, 1178, GConst.Anchor.LeftBottom)
    bg:addChild(textBox)

    --搜索按钮
    self.butSearch:setListener(function()
        local text = textBox:getText()
        if GameLogic.getStringLen(text)<1 then
            display.pushNotice(Localize("stringSearchCantNone"))
            return
        end
        self:searchleague(text)
    end)
end

function UnionDialog:addSearchUnionResult(unionInfo)
    if self.searchNode then
        self.searchNode:removeFromParent(true)
        self.searchNode = nil
    end
    self.searchNode = ui.node()
    self.midNode:addChild(self.searchNode)

    local infos={}
    for i=1,#unionInfo do
        infos[i]={id=i,unionInfo = unionInfo[i]}
    end
    self:addTableViewProperty("searchTableview",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("searchTableview",self.searchNode)
end


function UnionDialog:pickedButton(idx)
    self.buttons[self.piackedButIdx]:setEnable(true)
    self.buttons[idx]:setEnable(false)
    local backImag=ui.sprite("images/btnUnionOrange.png",{407,169})
    display.adapt(backImag, 0, 0, GConst.Anchor.LeftBottom)
    local pickedBackImag=ui.sprite("images/btnUnionWhite.png",{407,169})
    display.adapt(pickedBackImag, 0, 0, GConst.Anchor.LeftBottom)
    self.buttonsBack[self.piackedButIdx]:removeFromParent(true)
    self.buttons[self.piackedButIdx]:getDrawNode():addChild(backImag)
    self.buttonsBack[self.piackedButIdx]=backImag
    self.buttonsBack[idx]:removeFromParent(true)
    self.buttons[idx]:getDrawNode():addChild(pickedBackImag)
    self.buttonsBack[idx]=pickedBackImag
    if self.piackedButIdx==2 then
        backImag:setHValue(22)
        backImag:setSValue(71)
        backImag:setLValue(9)
    elseif self.piackedButIdx==3 then
        backImag:setHValue(180)
        backImag:setSValue(5)
        backImag:setLValue(-7)
    end
    self.piackedButIdx=idx
end


function UnionDialog:initEdit()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,0))
    self:loadView("buttonsViews")

    local bg = ui.node()
    self:addChild(bg,0)
    self.middleBack = bg
    self:loadView("middleBack",bg)
    self:insertViewTo()

    self.but2:setVisible(false)
    self.but3:setVisible(false)
    self.but1:setEnable(false)
    self.btnBut1:setString(Localize("tabMyLeague"))
    self.but1BackImage:removeFromParent(true)
    local pickedBackImag=ui.sprite("images/btnUnionWhite.png",{407,169})
    display.adapt(pickedBackImag, 0, 0, GConst.Anchor.LeftBottom)
    self.but1:getDrawNode():addChild(pickedBackImag)

    local midNode=ui.node()
    midNode:setPosition(0,0)
    self:addChild(midNode)
    self.midNode=midNode
    local bg=self.midNode
    bg:removeAllChildren(true)
    self:loadView("createUnionViews",bg)
    self:insertViewTo()

    self.languageArr = {"CN","HK","EN","IR","AR","FR","DE","OTHER"}
    local leaguedata = self.params.leaguedata

    --联盟名字
    local nameLb = ui.label(leaguedata.name, General.font2,45,{color = {0,0,0}})
    display.adapt(nameLb, 557, 1020, GConst.Anchor.LeftBottom)
    bg:addChild(nameLb)
    self.namaInputImg:setVisible(false)

    --联盟公告输入
    local unionNotice = ui.textBox({715,218}, "", General.font6, 45, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
    display.adapt(unionNotice, 557, 754, GConst.Anchor.LeftBottom)
    bg:addChild(unionNotice)

    --旗帜
    self.flagNode = nil
    self.ps1,self.ps2,self.ps3 = leaguedata.ps1,leaguedata.ps2,leaguedata.ps3
    self:initFlag()
    --选择
    self.butChoose:setListener(function()
        UnionFlagDialog.new(self.ps1,self.ps2,self.ps3,function(ps1,ps2,ps3,flagCost)
            self.ps1,self.ps2,self.ps3,self.flagCost = ps1,ps2,ps3,flagCost
            self:initFlag()
        end)
    end)

    --保存
    self.butCrystal:setListener(function()
        local notice = unionNotice:getText()

        self.createParams = {self.ps1*10000+self.ps2*100+self.ps3,notice,self.jmIndex,self.tlIndex*2000,self.languageArr[self.llIndex]}
        if self.flagCost<=0 then
            local otherSettings = {callback = function()
                self:manageleague()
            end}
            local dialog = AlertDialog.new(3,Localize("affirmSave"),Localize("stringAffirmSvae"),otherSettings)
            display.showDialog(dialog)
        else
            local otherSettings = {ctype = const.ResCrystal,cvalue = self.flagCost,callback = function()
                self:manageleague()
            end}

            local createDetial = ""
            if self.flagCost>0 then
                createDetial = Localizef("stringCreateDetial",{num = self.flagCost})
            end

            local dialog = AlertDialog.new(1,Localize("affirmSave"),Localize("stringAffirmSvae")..createDetial,otherSettings)
            display.showDialog(dialog)
        end
    end)
    self.butCrystalImg:setVisible(false)
    self.btnCrystal:setString(Localize("buttonSave"))

    --加入方式
    self.labelJoinMethodValue:setString(Localize("labelJoinMethodValue" .. leaguedata.state))
    --金杯限制
    self.labelTrophyLimitValue:setString(leaguedata.minCup)
    for k,v in ipairs(self.languageArr) do
        if tostring(v)==tostring(leaguedata.language) then
            self.llIndex = k
        end
    end
    self.jmIndex,self.tlIndex = leaguedata.state,leaguedata.minCup/2000
    self.labelLanguageMethodValue:setString(Localize("labelLanguage"..self.languageArr[self.llIndex]))
    --几个上下按钮f
    self.joinMethodLeft:setListener(function()
        if self.jmIndex == 1 then
            self.jmIndex = 3
        else
            self.jmIndex = self.jmIndex-1
        end
        self.createParams[4] = self.jmIndex
        self.labelJoinMethodValue:setString(Localize("labelJoinMethodValue"..self.jmIndex))
    end)
    temp = ui.sprite("images/butUinonCreateNext.png",{74,74})
    temp:setFlippedX(true)
    display.adapt(temp,37,37,GConst.Anchor.Center)
    self.joinMethodLeft:getDrawNode():addChild(temp)
    self.joinMethodRight:setListener(function()
        if self.jmIndex == 3 then
            self.jmIndex = 1
        else
            self.jmIndex = self.jmIndex+1
        end
        self.createParams[4] = self.jmIndex
        self.labelJoinMethodValue:setString(Localize("labelJoinMethodValue"..self.jmIndex))
    end)
    self.trophyLimitLeft:setListener(function()
        if self.tlIndex==0 then
        else
            self.tlIndex = self.tlIndex-1
        end
        self.createParams[5] = 2000*self.tlIndex
        self.labelTrophyLimitValue:setString(2000*self.tlIndex)
    end)
    temp = ui.sprite("images/butUinonCreateNext.png",{74,74})
    temp:setFlippedX(true)
    display.adapt(temp,37,37,GConst.Anchor.Center)
    self.trophyLimitLeft:getDrawNode():addChild(temp)
    self.trophyLimitRight:setListener(function()
        self.tlIndex = self.tlIndex+1
        self.createParams[5] = 2000*self.tlIndex
        self.labelTrophyLimitValue:setString(2000*self.tlIndex)
    end)
    self.languageLimitLeft:setListener(function()
        if self.llIndex == 1 then
            self.llIndex = #(self.languageArr)
        else
            self.llIndex = self.llIndex-1
        end
        self.createParams[6] = self.llIndex
        self.labelLanguageMethodValue:setString(Localize("labelLanguage"..self.languageArr[self.llIndex]))
    end)
    temp = ui.sprite("images/butUinonCreateNext.png",{74,74})
    temp:setFlippedX(true)
    display.adapt(temp,37,37,GConst.Anchor.Center)
    self.languageLimitLeft:getDrawNode():addChild(temp)
    self.languageLimitRight:setListener(function()
        if self.llIndex == #(self.languageArr) then
            self.llIndex = 1
        else
            self.llIndex = self.llIndex + 1
        end
        self.createParams[6] = self.llIndex
        self.labelLanguageMethodValue:setString(Localize("labelLanguage"..self.languageArr[self.llIndex]))
    end)

end

------------------------------------------------------------------------------------------------------------
function UnionDialog:checkRandomleague(tType)
    self:pickedButton(1)
    self.middleBack:setVisible(false)
    self.middleBack1:setVisible(true)
    local bg=self.midNode
    bg:removeAllChildren(true)
    self.searchNode = nil
    self.flagNode = nil
    self.rankBtnBg:setVisible(true)
    if tType then
        self.screeningBg:setVisible(true)
        self:changeTabIdx(self.selectTab)
        self:checkUnion()
    end
end

function UnionDialog:randomleague(tId1,tId2,refresh)
    local _type1,_type2 = tId1 or 1,tId2 or 1
    self:checkRandomleague(false)
    self:initScreeningUI()
    self:initSwichButtonUI()
    self:getAllUnionData(_type1,_type2,refresh)
end

function UnionDialog:getAllUnionData(t1,t2,refresh)
    self.maxWelfareNum = 0
    self.maxGoldCupNum = 0
    self:randomGoldCup(t1,refresh)
    self:randomWelfare(t2,refresh)
end

function UnionDialog:randomGoldCup(tId,refresh)
    self.changeBtn1 = true
    local context = GameLogic.getUserContext()
    local power = context:getProperty(const.ProCombat)
    _G["GameNetwork"].request("randomleague",{maxs = tId, ctype = 1, power = power},function(isSuc, data)
        if isSuc and self.tidyData then
            self.rightBut:setVisible(true)
            self.leftBut:setVisible(true)
            local unionInfo = self:tidyData(data,1)
            local unionInfo1 = {}
            local sId = 1
            for k,v in ipairs(unionInfo) do
                if not unionInfo1[sId] then
                    unionInfo1[sId] = {}
                end
                table.insert(unionInfo1[sId],v)
                if k%5==0 then
                    sId =sId +1
                end
            end
            self.maxGoldCupNum = sId-1
            if self.selectScreening then
                self.checkGlodCupInfo = unionInfo1
            else
                self.unionGoldCupInfo = unionInfo1
            end

            if self.changeBtn1 then
                self.changeBtn1 = false
                self:changeUnionInfo(unionInfo1,1,1)
                if refresh then
                    if self.selectTab == 1 or self.warNode then
                        self:unionWarRankBtn(nil)
                    end
                    return
                end
                self:canChangeTab(function ()
                    self:changeTabIdx(1)
                end,1)
            end
        end
    end)
end


function UnionDialog:randomWelfare(tId,refresh)
    self.changeBtn2 = true
    _G["GameNetwork"].request("randomleague",{maxs = tId,ctype=2},function(isSuc, data)
        if isSuc and self.tidyData then
            self.rightBut:setVisible(true)
            self.leftBut:setVisible(true)
            local unionInfo = self:tidyData(data,2)
            local unionInfo1 = {}
            local sId = 1
            for k,v in ipairs(unionInfo) do
                if not unionInfo1[sId] then
                    unionInfo1[sId] = {}
                end
                table.insert(unionInfo1[sId],v)
                if k%5==0 then
                    sId =sId +1
                end
            end
            self.maxWelfareNum = sId-1
            if self.selectScreening then
                self.checkWelfareInfo = unionInfo1
            else
                self.unionWelfareInfo = unionInfo1
            end

            if self.changeBtn2 then
                self.changeBtn2 = false
                self:changeUnionInfo(unionInfo1,1,2)
                if refresh then
                    if self.selectTab==2 or self.welfareNode then
                        self:unionWelfareRankBtn(nil)
                    end
                end
            end
        end
    end)
end


function UnionDialog:initScreeningUI()
    -- body
    if self.screeningBg then
        self.screeningBg:removeFromParent(true)
    end
    local bg = ui.node()
    self:addChild(bg,0)
    self.screeningBg = bg
    self:loadView("screeningNode",bg)
    local tabView = self:getViewTab()
    if self.selectScreening then
        tabView.screeningImgDui:setVisible(true)
    else
        tabView.screeningImgDui:setVisible(false)
    end

    tabView.screeningInfo:setString(Localize("screeningInfo"))
    tabView.screeningBtn:setScriptCallback(Script.createCallbackHandler(Script.createBasicHandler(function()
        -- body
        self.sBtnCup = 1
        self.sBtnWel = 1
        self.selectScreening = not self.selectScreening
        self:checkUnion()
    end,self)))
end

function UnionDialog:checkUnion()
    local tabView = self:getViewTab()
    if self.selectScreening then
        tabView.screeningImgDui:setVisible(true)
        if self.checkFirst then
            self.checkFirst = false
            self:getAllUnionData(1,1,true)
            return
        else
            self:changeUnionInfo(self.checkGlodCupInfo,self.sBtnCup,1)
            self:changeUnionInfo(self.checkWelfareInfo,self.sBtnWel,2)
        end
    else
        tabView.screeningImgDui:setVisible(false)
        self:changeUnionInfo(self.unionGoldCupInfo,self.sBtnCup,1)
        self:changeUnionInfo(self.unionWelfareInfo,self.sBtnWel,2)
    end
    if self.warNode then
        self:unionWarRankBtn(nil)
    end
    if self.welfareNode then
        self:unionWelfareRankBtn(nil)
    end
end


function UnionDialog:tidyData(data,tId)
    local unionInfo = {}
    if tId == 3 then
    --搜索联盟
        for k,v in pairs(data) do
            local info = {
                uid = v[1],
                name = v[2],
                state = v[3],
                language = v[8],
                currentNum = v[5],
                maxNum = v[4],
                cup = v[7],
                ps1 = math.floor(v[6]/10000),
                ps2 = math.floor((v[6]%10000)/100),
                ps3 = v[6]%100
            }
            table.insert(unionInfo,info)
        end
    else
        for k,v in pairs(data) do
            local _cup = nil
            if tId == 1 then
                --联盟金杯榜
                _cup = v[8]
            elseif tId == 2 then
                --联盟福利榜
                _cup = v[9]
            end
            local info = {
                uid = v[1],
                name = v[3],
                state = v[4],
                member = v[4],
                language = v[5],
                currentNum = v[6],
                maxNum = v[7],
                cup = _cup,
                ps1 = math.floor(v[2]/10000),
                ps2 = math.floor((v[2]%10000)/100),
                ps3 = v[2]%100,
                powerLimit = v[10]
            }
            table.insert(unionInfo,info)
        end
    end

    for i=1,#unionInfo do
        for j=1,#unionInfo-i do
            if unionInfo[j].cup<unionInfo[j+1].cup then
                unionInfo[j],unionInfo[j+1] = unionInfo[j+1],unionInfo[j]
            end
        end
    end

    return unionInfo
end


function UnionDialog:searchleague(str)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("searchleague",{searchleague={str}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc and self.tidyData then
            local unionInfo = self:tidyData(data,3)
            if not next(unionInfo) then
                display.pushNotice(Localize("stringNoSearchResult"))
            end

            if self.addSearchUnionResult then
                self:addSearchUnionResult(unionInfo)
            end
        end
    end)
end

function UnionDialog:createleague()
    local createParams = self.createParams
    local check = GameLogic.checkName(createParams[1])
    if check<0 then
        if check == -1 then
            display.pushNotice(Localize("stringUNameTooLong"))
        elseif check == -2 then
            display.pushNotice(Localize("stringUNameWrong"))
        end
        return
    end
    local wn, cn, l = GameLogic.getStringLen(createParams[2])
    if wn >= 200 then
        display.pushNotice(Localize("stringUNameTooLong"))
        return
    elseif wn>0 and (GameLogic.checkWrong(createParams[2]) or GameLogic.checkSign(createParams[2])) then
        display.pushNotice(Localize("stringUNameWrong"))
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    local cost = self.flagCost+200
    _G["GameNetwork"].request("createleague",{createleague=self.createParams},function(isSuc,data)
        GameNetwork.unlockRequest()
        local context = GameLogic.getUserContext()
        if data.code == 0 then
            display.pushNotice(Localize("stringUnionCreate5"))
            local linfo = data.cinfo
            local pinfo = data.plays
            context.unionPets = {skill=data.psk or {1,1,1,1,1,1}, pets=data.pids, curPid=linfo[14], level=linfo[12], exp=linfo[13], pbead=linfo[11] or 0}
            context.union = {id=linfo[1],job=pinfo[1][5],name=linfo[2], flag=linfo[7], enterTime=GameLogic.getTime(), cup = linfo[6],language = linfo[16]}
            GameLogic.getUserContext():changeRes(const.ResCrystal,-cost)
            GameLogic.statCrystalCost("创建联盟消耗",const.ResCrystal,-cost)
            if self.addSearchUnionResult then
                display.closeDialog(display.getDialogPri())
                UnionInfoDialog.new()
            end
            local activeData = GameLogic.getUserContext().activeData
            activeData:finishAct(52)
        elseif data.code==-1 then
            print("已经有联盟")
        elseif data.code==2 then
            display.pushNotice(Localize("noticeHaveUnion"))
            self:changeUnionData(data)
            GameEvent.sendEvent("EventFreshUnionMenu")
            display.closeDialog(display.getDialogPri())
        elseif data.code == -3 then
            print("钻石不足")
        elseif data.code == 10 then
            display.pushNotice(Localize("stringUnionCreate4"))
        end
    end)
end
function UnionDialog:changeUnionData(data)
    local context = GameLogic.getUserContext()
    local linfo = data.cinfo
    local pinfo = data.plays
    context.unionPets = {skill=data.psk or {1,1,1,1,1,1}, pets=data.pids, curPid=linfo[14], level=linfo[12], exp=linfo[13], pbead=linfo[11] or 0}
    for k,v in ipairs(pinfo) do
        if v[11] == context.uid then
            local info = {
                uid = linfo[1],         --联盟id
                unid = v[11],        --人id
                icon = v[1],
                lv = v[2],
                name = v[3],
                vip = v[4],
                job = v[5],
                power = v[6],
                contribute = v[7],

                lastLogin = v[9],
                cardTime = v[10],
                welfare = v[8],--总福利
                alreadyReceive= v[12],--已领取福利
                fstate = v[14],--参战状态
                joinTime = v[15]
            }
            context.union = {id=info.uid,job=info.job,name=linfo[2], flag=linfo[7], enterTime=GameLogic.getTime(), cup = linfo[6],language = linfo[16],joinTime=info.joinTime,fstate = info.fstate}
        end
    end
end


function UnionDialog:manageleague()
    local ps = self.createParams
    local cost = self.flagCost

    local createParams = self.createParams
    --[[
    local check = GameLogic.checkName(createParams[1])
    if check<0 then
        if check == -1 then
            display.pushNotice(Localize("stringUNameTooLong"))
        elseif check == -2 then
            display.pushNotice(Localize("stringUNameWrong"))
        end
        return
    end
    --]]
    local wn, cn, l = GameLogic.getStringLen(createParams[2])
    if wn >= 200 then
        display.pushNotice(Localize("stringUNameTooLong200"))
        return
    elseif wn>0 and (GameLogic.checkWrong(createParams[2]) or GameLogic.checkSign(createParams[2])) then
        display.pushNotice(Localize("stringUNameWrong"))
        return
    end

    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("manageleague",{manageleague=ps},function(isSuc,data)
        GameNetwork.unlockRequest()
        if data.code == 0 then
            display.pushNotice(Localize("labelSaveSucceed"))
            GameLogic.getUserContext():changeRes(const.ResCrystal,-cost)
            GameLogic.statCrystalCost("联盟旗帜消耗",const.ResCrystal,-cost)
            local union = GameLogic.getUserContext().union
            if ps[1]~=0 then
                self.params.leaguedata.ps1 = math.floor(ps[1]/10000)
                self.params.leaguedata.ps2 = math.floor((ps[1]%10000)/100)
                self.params.leaguedata.ps3 = ps[1]%100
                union.flag = ps[1]
            end
            if ps[2]~="" then
                self.params.leaguedata.notice = ps[2]
            end
            if ps[3]~=0 then
                self.params.leaguedata.state = ps[3]
            end
            if ps[4]~=-1 then
                self.params.leaguedata.minCup = ps[4]
                union.cup = ps[4]
            end
            if ps[5] then
                self.params.leaguedata.language = ps[5]
            end

            display.closeDialog(0)
            self.callback()
            GameLogic.sendChat({mtype=4,mode=3})
        elseif data.code == 10 then
            display.pushNotice(Localize("labelCantManageleague"))
        elseif data.code == 11 then
            print("信息不对")
        elseif data == -3 then
            print("钻石不足")
        end
    end)
end

return UnionDialog
