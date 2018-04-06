--关联设备对话框
local RelatedEquipDialog = class2("RelatedEquipDialog",function()
    return BaseView.new("RelatedEquipDialog.json",true)
end)

function RelatedEquipDialog:ctor(mode)
    self.mode=mode
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function RelatedEquipDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))
    
    if self.mode==1 then --连接另一装置
        self:loadView("allViews_1")
    elseif self.mode==2 then
        self:loadView("allViews_2")
    elseif self.mode==3 then
        self:loadView("allViews_3")
    elseif self.mode==4 then
        self:loadView("allViews_4")
    elseif self.mode==5 then
        self:loadView("allViews_5")
    end
end

return RelatedEquipDialog