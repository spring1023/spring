local const = GMethod.loadScript("game.GameLogic.Const")
AlertDialog = class()

function AlertDialog:ctor(mode,title,text,otherSettings)
    if type(mode)=="table" then
        mode, title, text, otherSettings = self:analyzeMode(mode)
        if mode==0 then
            self.deleted = true
            return
        end
    end
    DialogTemplates.loadSmallTemplate(self)
    local bg=self.view
    local temp
    local btnText = ""
    self.title:setString(title)
    if not otherSettings then
        otherSettings = {}
    end
    -- 花宝石购买的显示
    if mode==2 then
        GameUI.addResourceIcon(bg, const.ResCrystal, 1.7, 419, 268)
        temp = ui.label(text, General.font2, 40, {color={0,0,0},width=750})
        display.adapt(temp, 433, 418, GConst.Anchor.Top)
        bg:addChild(temp)
    elseif mode == const.ResCustom then
        GameUI.addResourceIcon(bg, const.ResCrystal, 0.8, 350, 124,10)
        temp = ui.label(text, General.font2, 40, {color={0,0,0},width=750})
        display.adapt(temp, 433, 418, GConst.Anchor.Top)
        bg:addChild(temp)
        btnText = otherSettings.yesBut
    elseif mode == 16 then
        temp = ui.label(text, General.font2, 40, {color={0,0,0},width=750})
        display.adapt(temp, 433, 278, GConst.Anchor.Center)
        bg:addChild(temp)
        btnText = otherSettings.yesBut
    elseif mode == const.AlertDownload then
        self._downloadSetting = text
        temp = ui.label(Localizef("noticeMoreDownload2", {a=math.floor(text[3]*100/1024/1024)/100}),
            General.font2, 40, {color={0,0,0}, width=750})
        display.adapt(temp, 433, 418, GConst.Anchor.Top)
        bg:addChild(temp)
        self._downloadLabel = temp
    elseif mode ~= 10 then
        temp = ui.label(text, General.font2, 40, {color={0,0,0},width=750})
        local height = temp:getContentSize().height
        if height > 220 then
            local layout = otherSettings.layout or {}
            temp = ui.scrollLabel(text, General.font2, 40, {color=layout.color or {0, 0, 0} ,width=layout.width or 800, height=layout.height or 240, align=GConst.Align[layout.align or "Center"],offx=layout.offx or 0,offy=layout.offy or 10})
        end
        display.adapt(temp, 433, 418-100, GConst.Anchor.Center)
        bg:addChild(temp)
        self.text = temp
    end

    self.callback = otherSettings.callback

    temp = ui.button({360, 141},self.onCallback,{cp1=self, image="images/btnGreen.png"})
    display.adapt(temp, 433, 106, GConst.Anchor.Center)
    bg:addChild(temp)
    self.yesBut = temp

    --引导
    local context = GameLogic.getUserContext()
    if context and context.guide:getStep().type == "cnow" then
        context.guideHand:showArrow(temp,180,120,0)
    end

    self.closeBut:setScriptCallback(Script.createCallbackHandler(self.onClose, self, true))
    if otherSettings.noCloseBut then
        self.closeBut:setVisible(false)
    end
    local but=self.yesBut:getDrawNode()
    if mode == const.AlertDownload then
        self.yesBut:setPosition(630, 106)
        temp = ui.label(Localize("btnDownload"), General.font1, 45, {color={255,255,255}, fontW=360, fontH=130})
        display.adapt(temp, 180, 85, GConst.Anchor.Center)
        but:addChild(temp)
        self._downloadYesWord = temp

        temp = ui.button({360, 141}, self.onClose, {cp1=self,image="images/btnOrange.png"})
        display.adapt(temp, 236, 106, GConst.Anchor.Center)
        bg:addChild(temp)
        self.noBut = temp
        local word = otherSettings.noBut or "btnCancel"
        temp = ui.label(Localize(word), General.font1, 45, {color={255,255,255},fontW=360,fontH=130})
        display.adapt(temp, 180, 85, GConst.Anchor.Center)
        self.noBut:getDrawNode():addChild(temp)
    elseif mode==1 or mode == 5 then
        local str = tostring(otherSettings.cvalue)
        local resScale=1
        if mode==1 then
            resScale=0.75
        end
        if otherSettings.cvalue == 0 then
            str = Localize("labelFree")
        else
            GameUI.addResourceIcon(but, otherSettings.ctype, resScale, 298, 85)
        end

        temp = ui.label(str, General.font1, 70, {color={255,255,255},fontW=180,fontH=130})
        display.adapt(temp, 238, 85, GConst.Anchor.Right)
        but:addChild(temp)

        if not otherSettings.skipRes and otherSettings.cvalue>GameLogic.getUserContext():getRes(otherSettings.ctype) then
            ui.setColor(temp, GConst.Color.Red)
            self.doResCallback = otherSettings
        end
        if mode == 5 then
            self.yesBut:setPosition(630, 106)
            temp = ui.button({360, 135},self.onClose,{cp1=self,image="images/btnOrange.png"})
            display.adapt(temp, 236, 106, GConst.Anchor.Center)
            bg:addChild(temp)
            self.noBut = temp
            local word = otherSettings.noBut or "btnCancel"
            temp = ui.label(Localize(word), General.font1, 45, {color={255,255,255},fontW=340,fontH=120})
            display.adapt(temp, 180, 85, GConst.Anchor.Center)
            self.noBut:getDrawNode():addChild(temp)
            if otherSettings.noCallback then
                self.noCallback = otherSettings.noCallback
            else
                self.closeBut:setVisible(false)
            end
        end
    elseif mode == 15 then
        temp = ui.label(btnText, General.font1, 60, {color={255,255,255},fontW=180,fontH=130})
        display.adapt(temp, 160, 90, GConst.Anchor.Left)
        but:addChild(temp)
    else
        local word = otherSettings.yesBut or "btnYes"
        if mode==13 then
           word = "buttonGo"
           self.yesBut:setHValue(111)
        end

        temp = ui.label(Localize(word), General.font1, 45, {color={255,255,255},fontW=340,fontH=120})
        display.adapt(temp, 180, 85, GConst.Anchor.Center)
        but:addChild(temp)

        if mode==3 or mode==10 then
            self.yesBut:setPosition(630, 106)
            temp = ui.button({360, 135},self.onClose,{cp1=self,image="images/btnOrange.png"})
            display.adapt(temp, 236, 106, GConst.Anchor.Center)
            bg:addChild(temp)
            self.noBut = temp
            word = otherSettings.noBut or "btnCancel"
            temp = ui.label(Localize(word), General.font1, 45, {color={255,255,255},fontW=340,fontH=120})
            display.adapt(temp, 180, 85, GConst.Anchor.Center)
            self.noBut:getDrawNode():addChild(temp)
            if otherSettings.noCallback then
                self.noCallback = otherSettings.noCallback
            else
                self.closeBut:setVisible(false)
            end
        end
    end

    --输入框
    if mode == 10 then
        local textBox = ui.textBox({780, 210}, text, General.font6, 40, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
        display.adapt(textBox, 433, 205, GConst.Anchor.Bottom)
        bg:addChild(textBox)
        self.textBox = textBox
    end

    --封禁使用
    if mode == 12 then
        if otherSettings.noCallback then
            self.noCallback = otherSettings.noCallback
        else
            self.closeBut:setVisible(false)
        end
        self.update = GMethod.schedule(Handler(self.updateTime, self),0,false)
        self.textStr = text
        self.labelTimeDes = otherSettings.labelTimeDes
        self.time=otherSettings.time
        self.curServerTime=GameLogic.getSTime()
    end

    local enode = ui.node()
    RegLife(enode, Handler(self.onAlertLife, self))
    bg:addChild(enode)
end

function AlertDialog:onAlertLife(event)
    if event == "enter" then
        GameUI.setLoadingState(true)
    elseif event == "exit" then
        GameUI.setLoadingState(false)
    end
end

function AlertDialog:onClose(onlyQuit)
    if self.lock then
        return
    end
    self.lock = true
    display.closeDialog(self.priority)
    if self.noCallback and not onlyQuit then
        self.noCallback()
    end
end

function AlertDialog:downloadPercent(percent)
    if not self.deleted and self._downloadSetting then
        local amax = math.floor(self._downloadSetting[3]*100/1024/1024)/100
        local anow = math.floor(self._downloadSetting[3]*percent/1024/1024)/100
        self._downloadLabel:setString(Localizef("alertTextDownloading",
            {percent=math.floor(percent), max=amax, now=anow}))
    end
end

function AlertDialog:downloadFinish(success)
    if not self.deleted and self._downloadSetting then
        if success then
            self._downloadSetting = nil
            self:onCallback()
        else
            self._downloading = nil
            self._downloadLabel:setString(Localize("labelDownloadFailedAndRetry"))
            self._downloadYesWord:setString(Localize("labelRetry"))
        end
    end
end

function AlertDialog:onCallback()
    if self.lock then
        return
    end
    if self._downloadSetting then
        if not self._downloading then
            self._downloading = true
            local DownloadUtil = GMethod.loadScript("game.GameLogic.DownloadUtil")
            DownloadUtil.addDownloadTask(self._downloadSetting, self,
                self.downloadPercent, self.downloadFinish)
        end
        return
    end
    self.lock = true
    display.closeDialog(self.priority)
    if self.doResCallback then
        local dialog = AlertDialog.new(self.doResCallback)
        if not dialog.deleted then
            display.showDialog(dialog)
        end
    elseif self.callback then
        if self.textBox then
            self.callback(self.textBox:getText())
        else
            self.callback()
        end
    end
end

local function showRankSelf()
    AllRankingListDialog.new(1)
end

local function showSingleStage()
    display.showDialog(PlayInterfaceDialog.new())
end

local function showExtractDialog()
    local context = GameLogic.getUserContext()
    local curDialog = context.curDialog
    if curDialog and not curDialog.deleted and curDialog.name=="HeroMain" then
        display.closeDialog(2)
        curDialog:pushTab("extract")
    else
        display.showDialog(HeroMainDialog.new({initTag="extract"}))
    end
end

function AlertDialog:analyzeMode(data)
    if data.ctype then
        if data.ctype==const.ResGold then
            local context = GameLogic.getUserContext()
            local cvalue = data.cvalue - context:getRes(data.ctype)
            local ccost = GameLogic.computeCostByRes(data.ctype, cvalue)
            if data.cvalue>context:getResMax(data.ctype) then
                local bid = const.GoldStorage
                display.pushNotice(StringManager.getFormatString("noticeStorageFull", {name=BU.getBuildName(bid)}))
                return 0
            end
            return 1, Localize("alertTitleBuyGold"), Localizef("alertTextBuyGold",{cost=ccost, num=cvalue}), {ctype=4, cvalue=ccost, callback=Handler(GameLogic.buyResAndCallback, data.ctype, cvalue, data.callback)}
        elseif data.ctype==const.ResCrystal then
            return 2, Localize("alertTitleBuyCrystal"), Localize("alertTextBuyCrystal"),{yesBut="btnEnterShop", callback=Handler(StoreDialog.new, 1)}
        elseif data.ctype==const.ResZhanhun then --勋章
            local context = GameLogic.getUserContext()
            local cvalue = data.cvalue - context:getRes(data.ctype)
            local ccost = GameLogic.computeCostByRes(data.ctype, cvalue)
            return 1, Localize("alertTitleBuyZhanhun"), Localizef("alertTextBuyZhanhun",{cost=ccost, num=cvalue}), {ctype=4, cvalue=ccost, callback=Handler(GameLogic.buyResAndCallback, data.ctype, cvalue, data.callback)}
        elseif data.ctype==const.ResSpecial then  --黑晶
            local context = GameLogic.getUserContext()
            local cvalue = data.cvalue - context:getRes(data.ctype)
            local ccost = GameLogic.computeCostByRes(data.ctype, cvalue)
            return 1, Localize("alertTitleBuySpecial"), Localizef("alertTextBuySpecial",{cost=ccost, num=cvalue}), {ctype=4, cvalue=ccost, callback=Handler(GameLogic.buyResAndCallback, data.ctype, cvalue, data.callback)}
        elseif data.ctype==const.ResMedicine then  --基因药水
            local context = GameLogic.getUserContext()
            local cvalue = data.cvalue - context:getRes(data.ctype)
            local ccost = GameLogic.computeCostByRes(data.ctype, cvalue)
            return 1, Localize("alertTitleBuyGene"), Localizef("alertTextBuyGene",{cost=ccost, num=cvalue}), {ctype=4, cvalue=ccost, callback=Handler(GameLogic.buyResAndCallback, data.ctype, cvalue, data.callback)}
        elseif data.ctype==const.ResBeercup then
            return 3, Localize("alertTitleNoBeercup"), Localize("alertTextNoBeercup"), {yesBut="buttonGo", noBut="labelClose", callback=showSingleStage}
        elseif data.ctype==const.ResTrials then
            display.pushNotice(Localize("stringNotEnoughResTrial"))
            return 0
        elseif data.ctype==const.ResGXun then
            display.pushNotice(Localize("noticeGXunNotEnough"))
            return 0
        elseif data.ctype==const.ResGaStone then
            display.pushNotice(Localize("noticeGaStoneNotEnough"))
            return 0
        elseif data.ctype == const.ResCustom then
            return const.ResCustom, data.title, data.text, {yesBut=data.value, callback=data.callback}
        elseif data.ctype == 16 then
            return 16,data.title,data.text,{yesBut=data.value,callback=data.callback}
        end
    end
end

--用于做封禁倒计时
function AlertDialog:updateTime(diff)
    if self.time then
        self.time = self.time-diff
        if self.time<=0 then
            GMethod.unschedule(self.update)
            display.closeDialog(self.priority)
            GEngine.restart()
            return
        end
        if self.text then
            local text=self.textStr..self.labelTimeDes..StringManager.getTimeString(self.time-self.curServerTime)
            self.text:setString(text)
        end
    end
end
