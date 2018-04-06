--问号对话框
local HelpDialog = class2("HelpDialog",function()
    return BaseView.new("HelpDialog.json")
end)

function HelpDialog:ctor(str)
    self.str = str
   	self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function HelpDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:loadView("views")
    self:insertViewTo()
    self.labeltishi:setString(Localize(self.str))
end

return HelpDialog