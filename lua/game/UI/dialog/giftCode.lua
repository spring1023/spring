local GiftCode = class(DialogViewLayout)
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

function GiftCode:onInitDialog()
	self:initUI()
	-- self:initData()
end

function GiftCode:initUI()
	self:setLayout("giftCode.json")
    self:loadViewsTo()
    self.lab_tittle:setString(Localize("labelInputPackCode"))
    self.lab_giftCode:setString(Localize("labelPackCode"))
    self.lab_confirm:setString(Localize("btnYes"))
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.btn_confirm:setScriptCallback(ButtonHandler(self.OnRecieveClick, self))
    --礼品码输入
    local textBox = ui.textBox({760,84}, Localize("labelInputPlaceHolder"), General.font6, 45, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
    display.adapt(textBox, 400, 0, GConst.Anchor.Center)
    self.node_input:addChild(textBox)
    self.textBox = textBox
end

function GiftCode:initData()
end

function GiftCode:OnRecieveClick()
    local str = self.textBox:getText()
    if GameLogic.getStringLen(str)<=0 then
        display.pushNotice(Localize("labelCantSendNothing"))
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("packCode",{code=str,language=General.language,uid=GameLogic.getUserContext().uid,zid=GameLogic.zid},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==0 then
                display.pushNotice(Localize("noticePackCode0"))
            elseif data.code==1 then
                display.pushNotice(Localize("noticePackCode1"))
                --刷新邮件
                GameLogic.getUserContext().logData:getEmailDatas()
            elseif data.code==2 then
                display.pushNotice(Localize("noticePackCode2"))
            elseif data.code==3 then
                display.pushNotice(Localize("noticePackCode3"))
            elseif data.code==5 then
                display.pushNotice(Localize("noticePackCode4"))
            end
        end
    end)
end

return GiftCode