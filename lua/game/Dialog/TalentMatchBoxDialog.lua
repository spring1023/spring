local TalentMatchBoxDialog = class(DialogViewLayout)

function TalentMatchBoxDialog:onInitDialog()
    self:setLayout("TalentMatchBoxDialog.json")
end

function TalentMatchBoxDialog:onEnter()
    self.title:setString(self.titleName)
    self.boxTableView:setLazyTableData(self.rewards, Handler(self.onUpdateItemCell, self), 0)
end

-- 数据
function TalentMatchBoxDialog:onUpdateItemCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    if info[1] ~= reuseCell.displayIType or info[2] ~= reuseCell.displayIId then
        reuseCell.displayIType = info[1]
        reuseCell.displayIId = info[2]
        reuseCell.iconNode:removeAllChildren(true)
        GameUI.addItemIcon(reuseCell.iconNode, info[1], info[2], reuseCell.iconNode.size[1]/200,
            reuseCell.iconNode.size[1]/2, reuseCell.iconNode.size[2]/2, true)
        GameUI.registerTipsAction(reuseCell.iconNode, self.view, info[1], info[2], reuseCell.size[1]/2, reuseCell.size[2]/2)
    end
    reuseCell.labelName:setString(GameLogic.getItemName(info[1], info[2]))
    reuseCell.labelNum:setString(Localizef("labelFormatX", {num=info[3]}))
    return reuseCell
end

return TalentMatchBoxDialog
