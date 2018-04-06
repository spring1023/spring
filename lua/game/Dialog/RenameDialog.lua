local const = GMethod.loadScript("game.GameLogic.Const")

RenameDialog = class()

function RenameDialog:ctor()
    DialogTemplates.loadDefaultTemplate(self, 3)
    local bg = self.view
    local temp
    self.title:setString(StringManager.getString("wordRename"))
    temp = ui.label(StringManager.getString("labelNotice2"), General.font1, 50, {color={255,255,255}})
    display.adapt(temp, 188, 1019, GConst.Anchor.Left)
    bg:addChild(temp)
    temp = ui.label(StringManager.getString("noticeNameLimit"), General.font1, 50, {color={255,255,255},fontW=800,fontH = 150, align=GConst.Align.Left})
    display.adapt(temp, 185, 970, GConst.Anchor.LeftTop)
    bg:addChild(temp)
    temp = ui.label(StringManager.getString("noticeNameLimit2"), General.font1, 50, {color={255,255,255},width=800,align=GConst.Align.Left})
    display.adapt(temp, 185, 542, GConst.Anchor.Left)
    bg:addChild(temp)

    temp=ui.button({361, 141},self.onRename,{cp1=self, image="images/btnGreen.png"})
    display.adapt(temp, 562, 154, GConst.Anchor.Center)
    bg:addChild(temp)
    self.butRename = temp
    local but=temp:getDrawNode()
    local context = GameLogic.getUserContext()
    if context:getProperty(const.ProRenameCount)>0 then
        GameUI.addResourceIcon(but, const.ResCrystal, 0.8, 300, 84)
        temp = ui.label(StringManager.getNumberString(const.PriceRename), General.font1, 55, {color={255,255,255}})
        display.adapt(temp, 241, 84, GConst.Anchor.Right)
        but:addChild(temp)
        if const.PriceRename>context:getRes(const.ResCrystal) then
            ui.setColor(temp,GConst.Color.Red)
        end
    else
        temp = ui.label(StringManager.getString("btnFreeRename"), General.font1, 55, {fontW=400, fontH = 90})
        display.adapt(temp, 180, 84, GConst.Anchor.Center)
        but:addChild(temp)
    end

    local textBox = ui.textBox({760, 84}, StringManager.getString("labelInputPlaceHolder"), General.font6, 40, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
    display.adapt(textBox, 203, 760, GConst.Anchor.Left)
    bg:addChild(textBox)
    self.textBox = textBox
    RegActionUpdate(bg,function()
        self:updateView()
    end,0.2)
end

function RenameDialog:updateView()
    local name = self.textBox:getText()
    local str = string.trim(name)
    if str == "" then
        self.butRename:setGray(true)
        self.butRename:setEnable(false)
    else
        self.butRename:setGray(false)
        self.butRename:setEnable(true)
    end
end

function RenameDialog:onRename()
    local name = self.textBox:getText()
    local context = GameLogic.getUserContext()
    local check = GameLogic.checkName(name,const.InfoName)
    if check<0 then
        if check == -1 then
            display.pushNotice(Localize("stringNameTooLong"))
        elseif check == -2 then
            display.pushNotice(Localize("stringNameWrong"))
        elseif check == -3 then
            display.pushNotice(Localize("stringNameSame"))
        end
        return
    end
    local cvalue = 0
    if context:getProperty(const.ProRenameCount)>0 then
        cvalue = const.PriceRename
    end
    local ctype = const.ResCrystal
    if context:getRes(ctype)<cvalue then
        display.showDialog(AlertDialog.new({ctype=ctype, cvalue=cvalue}))
    elseif GameNetwork.lockRequest() then
        GameLogic.dumpCmds(true)
        GameNetwork.request("rename", {name=name}, self.onRenameCallback, self)
    end
end

function RenameDialog:onRenameCallback(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        if data.code==2 then
            display.pushNotice(Localize("noticeNameLimit3"))
        else
            local context = GameLogic.getUserContext()
            context:setProperty(const.ProRenameCount,1)
            if data.cost then
                context:changeRes(const.ResCrystal, -data.cost)
                GameLogic.statCrystalCost("更换昵称消耗",const.ResCrystal, -data.cost)
            end
            if data.name then
                context:setInfoItem(const.InfoName, data.name)
            end
            if not self.deleted then
                display.closeDialog(self.priority)
            end
            display.pushNotice(Localize("stringRenameSucceed"))
            -- GameLogic.getUserContext().achieveData:finish(12,1)
            GameLogic.getUserContext().achieveData:finish(const.ActTypeRename,1)
        end
    end
end
