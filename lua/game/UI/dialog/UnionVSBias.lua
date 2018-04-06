
--联盟对战偏好
local UnionVSBias = class2("UnionVSBias",function()
    return BaseView.new("UnionVSBias.json")
end)

function UnionVSBias:ctor(callback)
    self.callback = callback
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function UnionVSBias:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))

    self:loadView("views")
    self:insertViewTo()
    self.butLeft:setListener(function()
        self.callback(0)
        display.closeDialog(self.dialogDepth)
    end)
    self.butRight:setListener(function()
        self.callback(1)
        display.closeDialog(self.dialogDepth)
    end)
end

return UnionVSBias