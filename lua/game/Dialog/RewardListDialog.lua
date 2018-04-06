local RewardListDialog = class(DialogViewLayout)

function RewardListDialog:onInitDialog()
    self:setLayout("RewardListDialog.json")
    self:loadViewsTo()
    self.title:setString(Localize("titleGetRewards"))
    local rewards = self.rewards
    local infos = {}
    for _, reward in ipairs(rewards) do
        table.insert(infos, {gtype=reward[1], gid=reward[2], gnum=reward[3]})
    end
    self.nodeTableView:loadTableView(infos, Handler(self.updateRewardCell, self))
    self.btnReceive:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
end

function RewardListDialog:updateRewardCell(cell, tableView, info)
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("RewardCell",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
    end
    info.itemBack:removeAllChildren(true)
    GameUI.addItemIcon(info.itemBack,info.gtype,info.gid,1,0,0,true)
    info.itemName:setString(GameLogic.getItemName(info.gtype, info.gid))
    info.itemNum:setString("x" .. info.gnum)
end

GEngine.export("RewardListDialog",RewardListDialog)
