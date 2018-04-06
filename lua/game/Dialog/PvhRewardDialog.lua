PvhRewardDialog = class(DialogViewLayout) --领取奖励对话框
function PvhRewardDialog:onInitDialog()
    self:setLayout("PvhRewardDialog.json")
    self:loadViewsTo()

    self.white:setVisible(false)
    self.closeBut:setVisible(false)
    self.title:setString(Localize("titleReward1"))
    self.btnSure:setScriptCallback(ButtonHandler(display.closeDialog, 0))
end

function PvhRewardDialog:onEnter()
    local bg = self.view
    for i, reward in ipairs(self.rewardList) do
        local node = ui.node({226, 226}, true)
        display.adapt(node, 92+327*((i-1)%4), 454-330*math.floor((i-1)/4), GConst.Anchor.LeftBottom)
        bg:addChild(node, 1)
        GameUI.addItemIcon(node, reward[1], reward[2], 1.13, 113, 113, 0, true)
        local label = ui.label("", General.font1, 53)
        display.adapt(label, 113, -36, GConst.Anchor.Center)
        node:addChild(label)
        GameUI.setItemName(label,reward[1],reward[2],reward[3])
    end
end
