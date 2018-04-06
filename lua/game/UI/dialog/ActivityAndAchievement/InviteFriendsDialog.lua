--邀请好友对话框
local InviteFriendsDialog = class2("InviteFriendsDialog",function()
    return BaseView.new("InviteFriendsDialog.json")
end)
function InviteFriendsDialog:ctor(params,friends)
    self.params=params or {}
    self.friends=friends or {}
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end
function InviteFriendsDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))

    self:loadView("upViews")
    self:loadView("downViews")
    self.chosedFriends={}
    local context = GameLogic.getUserContext()
    local infos={}
    if context.fbFriends then
        for i=1,#context.fbFriends do
            infos[i]={id=i,friendInfos=context.fbFriends[i]}
        end
    end
    self.infos=infos
    self:addTableViewProperty("friendsTableView",infos,Script.createBasicHandler(self.updateFriendsCell,self))
    self:loadView("friendsTableView")
    self:insertViewTo()
    --全选或取消全选
    self.butCheckAllCancel:setListener(function()
        self:choseAllFriends()
    end)
    --确定邀请
    self.butInviteFriendsOpenBox:setListener(function()
        self:sureInvite()
    end)
end

function InviteFriendsDialog:onQuestion()
    HelpDialog.new("dataQuestionInviteFd")
end

function InviteFriendsDialog:updateFriendsCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    self:loadView("friendsCellViews",bg)
    info.cell=cell
    self:insertViewTo(info)
    GameUI.addFacebookHead(bg,info.friendInfos[4],{size={200,200}})
    info.labFriendName:setString(Localize(info.friendInfos[2]))
    if info.isChosed then
        info.imaChosed:setVisible(true)
    else
        info.imaChosed:setVisible(false)
    end
    cell:setScriptCallback(Script.createCallbackHandler(function()
        if info.isChosed then
            info.isChosed=nil
            info.imaChosed:setVisible(false)
            table.remove(self.chosedFriends,info.id)
        else
            info.isChosed=true
            info.imaChosed:setVisible(true)
            table.insert(self.chosedFriends,info.id,info.friendInfos)
        end
        if #self.chosedFriends==#self.infos and not self.isAllChosed then
            self:changeBtnState()
        elseif #self.chosedFriends==0 and self.isAllChosed then
            self:changeBtnState()
        end   
    end))
end

function InviteFriendsDialog:changeBtnState()
    if self.isAllChosed then
        self.isAllChosed=nil
        self.wordRowSelect:setString(Localize("wordRowSelect"))
    else
        self.isAllChosed=true
        self.wordRowSelect:setString(Localize("btnCancel")..Localize("wordRowSelect"))
    end
end

function InviteFriendsDialog:choseAllFriends()
    if self.isAllChosed then
        self.chosedFriends={}
        for i,info in ipairs(self.infos) do
            info.isChosed=nil
            if info.imaChosed then
                info.imaChosed:setVisible(false)
            end
        end
    else
        for i,info in ipairs(self.infos) do
            info.isChosed=true
            if info.imaChosed then
                info.imaChosed:setVisible(true)
            end
            table.insert(self.chosedFriends,info.id,info.friendInfos)
        end

    end
    self:changeBtnState()
end

function InviteFriendsDialog:sureInvite()
    if #self.chosedFriends==0 then
        display.pushNotice(Localize("labelPleaseChosedFriends"))
        return
    end
    display.pushNotice(Localize("labelInviteSucceed"))
    local tab = {}
    for i,v in ipairs(self.chosedFriends) do
        if self.params.help[v[1]] and self.params.help[v[1]][2] == 1 then
        else
            table.insert(tab,v[1])
        end
    end
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdActSHelp,tab})
    display.closeDialog(self.priority)
end

return InviteFriendsDialog
