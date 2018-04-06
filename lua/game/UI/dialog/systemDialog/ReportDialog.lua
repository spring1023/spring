
--举报对话框
local ReportDialog = class2("ReportDialog",function()
    return BaseView.new("ReportDialog.json", true)
end)

function ReportDialog:ctor(params)
    self.params = params or {}
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self.selectType = false
    self.context = GameLogic.getUserContext()
    self:initUI()

    display.showDialog(self, false, false)
end

function ReportDialog:initUI()
    self:loadView("backAndupViews")
    self:loadView("views")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.selectLabel:setString(Localize("labelComplaints0"))
    self.vType = 0
    local headid = self.params.headid or 200101
    local lv = self.params.lv or 0
    local name = self.params.name or ""
    GameUI.addPlayHead(self,{id=headid,scale=0.85,x=175,y=1021,z=0,blackBack=true})
    viewTab.name:setString("lv:"..lv.."  "..name)
    
    local textBox = ui.textBox({1094, 315}, Localize("labelInputPlaceHolder"), General.font6, 45, {back = "images/inputBack.png",max=200})
    display.adapt(textBox, 105, 297, GConst.Anchor.LeftBottom)
    self:addChild(textBox)

    viewTab.butSend:setScriptCallback(Script.createCallbackHandler(function ()
        -- body
        if self.vType == 0 then
            display.pushNotice(Localize("labelComplaints0"))
        else
            if not GameNetwork.lockRequest() then
                return
            end
            display.pushNotice(Localize("labelSendSuccess"))
            GameEvent.sendEvent("refreshReplay")
            _G["GameNetwork"].request("getTipoffs",{uid=self.context.uid,rid=self.params.id,cont=textBox:getText(),ctype=self.vType,cmode=self.params.mode,language=General.language},function(isSuc,data)
                GameNetwork.unlockRequest()
            end)
        end
    end,self))

    viewTab.None:setScriptCallback(Script.createCallbackHandler(self.showDropDownNode,self))

end

function ReportDialog:showDropDownNode()
    -- body
    if self.bgNode then
        self.selectType = not self.selectType
        self.bgNode:setVisible(self.selectType)
        self.bgNodeImg:setVisible(self.selectType)
        return
    end
    local info = {}
    self.selectType = true
    for k=1,4 do
        table.insert(info,{id=k,key = "labelComplaints"..k})
    end
    self:loadView("tableviewNode")
    self:insertViewTo()
    self:addTableViewProperty("infoTableview",info,Script.createBasicHandler(self.cellCallBack,self))
    self:loadView("infoTableview",self.bgNode)    
end

function ReportDialog:cellCallBack(cell, tableView, info)
    -- body
    local bg = cell:getDrawNode()
    self:loadView("dropDownNode",bg)
    self:insertViewTo()
    self.selectNode:setVisible(false)
    self.comLabel:setString(Localize(info.key))
    info.selectNode = self.selectNode
    info.comLabel = self.comLabel
    cell:setScriptCallback(Script.createCallbackHandler(function ()
        -- body
        if self.selectItem and next(self.selectItem) then
            self.selectItem[1]:setVisible(false)
            self.selectItem[2]:setColor(cc.c3b(255,255,255))
        end
        info.selectNode:setVisible(true) 
        info.comLabel:setColor(cc.c3b(47,111,185))
        self.vType = info.id
        self.selectItem = {info.selectNode,info.comLabel}
        self.viewTab.selectLabel:setString(Localize(info.key)) 
        self:showDropDownNode()  
    end,self))
end

return ReportDialog








