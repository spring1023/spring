--游戏公告对话框
local GameAnnouncement = class2("GameAnnouncement",function()
    return BaseView.new("GameAnnouncement.json",true)
end)

function GameAnnouncement:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function GameAnnouncement:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))

    self:loadView("allViews")
    self:insertViewTo()

    local noticeInfo = GameLogic.getVersionData("GVNotice" .. General.language)
    if noticeInfo.title then
        self.labelGGtitle:setString(noticeInfo.title)
    end
    if noticeInfo.text then
        self.stringGGcontent:setString(noticeInfo.text)
    end
    self.butKnow:setListener(function()
        display.closeDialog(0)
    end)
end
return GameAnnouncement
