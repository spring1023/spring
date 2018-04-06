--好友助战对话框
local UnionFriendAssistant = class2("UnionFriendAssistant",function()
    return BaseView.new("UnionFriendAssistant.json",true)
end)

function UnionFriendAssistant:ctor()
    self.scene = GMethod.loadScript("game.View.Scene")
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initBack()
    self:getFriends()
    display.showDialog(self)
end

function UnionFriendAssistant:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))
    self:loadView("allViews")
    self:insertViewTo()
end
function UnionFriendAssistant:onQuestion()
    HelpDialog.new("dataQuestionUnFdAss")
end
function UnionFriendAssistant:initUI()
    local context = GameLogic.getUserContext()
    self.labelAllHurtAddBValue:setString((context.pvbHurtAdd or 0).. "%")
   
    local infos={}
    local items = context.fbFriends or {}
    for i=1,#items do
        infos[i]={id=i,item = items[i]}
    end
    self:addTableViewProperty("infoTableViews",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("infoTableViews")
end
function UnionFriendAssistant:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    local item = info.item
    if info.id%2==1 then
        self:loadView("infoCellBack",bg)
    end
    self:loadView("cellViews",bg)

    local context = GameLogic.getUserContext()
    if context.union.id == item[3] then
        self:loadView("labelViews",bg)
        self:insertViewTo()
        self.labelHurtAdd:setString(Localizef("stringSameUnionHurtAdd",{a = item[20]}))
    else
        self:loadView("invitationViews",bg)
        self:insertViewTo()
        self.butInvitation:setListener(function()
            self:addclanfriend(item[1])
        end)
    end

    self:insertViewTo()
    self.labelLv:setString(item[5])
    self.labelName:setString(item[2])
end

function UnionFriendAssistant:addclanfriend(uid)
    if GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("addclanfriend",{tid = uid},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data == 10 then
                display.pushNotice(Localize("labelYouHaveNotUnion"))
            else
                display.pushNotice(Localizef("stringHaveSendInviteTo",{a = item[2]}))
            end
        end
    end)
end

function UnionFriendAssistant:getFriends()
    self.scene.menu:initFacebooFriends(function ()
        if self.initUI then
            self:initUI()
        end
    end)
end

return UnionFriendAssistant
















