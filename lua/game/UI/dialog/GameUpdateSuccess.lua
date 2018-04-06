--游戏更新成功对话框
local GameUpdateSuccess = class2("GameUpdateSuccess",function()
    return BaseView.new("GameUpdateSuccess.json",true)
end)

function GameUpdateSuccess:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function GameUpdateSuccess:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()

    self:loadView("allViews")
    self:insertViewTo()
    self.butSure:setListener(function()
        display.closeDialog(0)
        GEngine.restart()
    end)
end
return GameUpdateSuccess