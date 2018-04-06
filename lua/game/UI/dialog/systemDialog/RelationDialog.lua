
--关联对话框
local RelationDialog = class2("RelationDialog",function(params)
    if params and params.useBig then
        return BaseView.new("GameAnnouncement.json", true)
    else
        return BaseView.new("RelationDialog.json", true)
    end
end)

function RelationDialog:ctor(params,callback)
    self.params = params
    self.callback = callback
    self.priority = 5
    self:initUI()
    display.showDialog(self, false, false)
end

function RelationDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local close=viewTab.butClose
    close:setListener(function()
        if self.params.cancelCall then
            self.params.cancelCall()
        elseif self.params.mode == 1 then
            self.callback()
        end
        display.closeDialog(self.priority)
    end)
    
    if self.params.useBig then
        self:loadView("allViews")
        self:insertViewTo()
        self.butKnow:setListener(function()
            self.callback()
            display.closeDialog(self.priority)
        end)
        if self.params.okText then
            self.labelIKnow:setString(self.params.okText)
        end
        self.labelGGtitle:setString(self.params.title)
        self.stringGGcontent:setString(self.params.text)
    else
        self:loadView("views")
        self:insertViewTo()
        self.butCancel:setListener(function()
            if self.params.cancelCall then
                self.params.cancelCall()
            end
            display.closeDialog(self.priority)
        end)
        self.butSure:setListener(function()
            self.callback()
            display.closeDialog(self.priority)
        end)
        self.labelLink:setString(self.params.title)
        self.stringIsLink:setString(self.params.text)
        if self.params.mode == 1 then
            self.butCancel:setVisible(false)
            self.butSure:setPosition(434,98)
        end
    end
end

return RelationDialog








