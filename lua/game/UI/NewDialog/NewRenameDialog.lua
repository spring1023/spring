local const = GMethod.loadScript("game.GameLogic.Const")
local RenameDialog = class(DialogViewLayout)

function RenameDialog:ctor(params)
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth;
    self.callback = params.callback
    self:initUI()
end

function RenameDialog:onCreate()
    self:setLayout("userInfo_main_dialog.json")
    self:loadViewsTo()
end

function RenameDialog:initUI()
    self.bg:setVisible(false)
    self.main:setVisible(false)
    self.name:setVisible(true)

    local context = GameLogic.getUserContext()
    -- 根據屬性值對應的購買次數設置需要的钻石数量
    if context:getProperty(const.ProRenameCount)>0 then
        -- 设置改名消耗信息
        -- dump("--------------", Localizef(const.PriceRename))
        self.lb_num1:setString(Localizef(const.PriceRename))
        if const.PriceRename>context:getRes(const.ResCrystal) then
            ui.setColor(self.lb_num1.view,GConst.Color.Red)
        end
    else
        self.lb_num1:setString(Localize("btnFreeRename"));
    end

    -- 创建文本框
    local x, y = self.lb_input:getPosition()
    local placeHolder = self.lb_input;
    local textBox = ui.textBox({720, 90}, "", General.font6,40,
        {
            align=cc.TEXT_ALIGNMENT_LEFT, 
            back="images/inputBack.png",
            callback = {txtBegan = function(sender) placeHolder:setVisible(false) end, 
                        txtEnded = function(sender) placeHolder:setVisible(sender:getText() == "") end}
        })
    textBox:setPosition(x, y)
    textBox:setOpacity(0)
    self.name:addChild(textBox)
    self.textBox = textBox

    self.btn_cancle:setScriptCallback(ButtonHandler(display.closeDialog,self.priority))

    self.btn_ok:setScriptCallback(ButtonHandler(function()
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
    end))

    RegActionUpdate(self.view, Handler(self.update, self), 0.2)
end


function RenameDialog:onExit()
    -- dump("-----------------onExit------------");
    return true;
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
        GameUI.showAlert({ctype=ctype, cvalue=cvalue})
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
                self.callback()
            end
            if not self.deleted then
                display.closeDialog(self.priority)
            end
            display.pushNotice(Localize("stringRenameSucceed"))
            GameLogic.getUserContext().achieveData:finish(12,1)
        end
    end
end


function RenameDialog:update()
    local name = self.textBox:getText()
    local str = string.trim(name)
    if str == "" then
        self.btn_ok:setGray(true)
        self.btn_ok:setEnable(false)
    else
        self.btn_ok:setGray(false)
        self.btn_ok:setEnable(true)
    end
end

function RenameDialog:onEnter()

end

function RenameDialog:canExit()
    return true;
end

return RenameDialog
