--英雄试炼战斗记录对话框
local PartSkillChangeDialog = class2("PartSkillChangeDialog",function()
    return BaseView.new("PartSkillChangeDialog.json")
end)

function PartSkillChangeDialog:ctor()
    self:loadView("backAndupViews")
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    display.showDialog(self)
    self:insertViewTo()
    self.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
end

return PartSkillChangeDialog
