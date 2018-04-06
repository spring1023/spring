--邀请好友奖励对话框
local InviteFriendsRewardDialog = class2("InviteFriendsRewardDialog",function()
    return BaseView.new("InviteFriendsRewardDialog.json")
end)
function InviteFriendsRewardDialog:ctor(rewardInfos)
    self.rewardInfos=rewardInfos
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end
function InviteFriendsRewardDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))

    local infos=self.rewardInfos or {}
    self:addTableViewProperty("rewardTableView",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("rewardTableView")
end

function InviteFriendsRewardDialog:onQuestion()
    HelpDialog.new("dataQuestionInviteFdRd")
end

function InviteFriendsRewardDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    self:loadView("rewardCellViews",bg)
    local viewTab=self:getViewTab()
    local imaReward = viewTab.imaReward
    local labReward =viewTab.labReward
    viewTab.lvBox:setString(Localizef("labelLvBox",{lv=info.id}))
    if info.cState then--已达成
        ui.setFrame(imaReward, "images/rewardAchievement1.png")
        labReward:setString(Localize("labelYesReached"))
        labReward:setColor(cc.c3b(254,65,65))
    else
        labReward:setString(Localize("labelNotReached"))
    end
    if info.rState then--已领取
        ui.setFrame(viewTab.imaBox, "images/battleBox2.png")
    end
    local text=""
    for i,reward in ipairs(info.rewards) do
        local num=reward.gnum
        local rName=GameLogic.getItemName(reward.gtype,reward.gid)

        local f=","
        if i%2==0 then
            f="\n"
        end
        text=text..rName.."x"..num..f
    end
    viewTab.labelRewards:setString(text)
end
return InviteFriendsRewardDialog
