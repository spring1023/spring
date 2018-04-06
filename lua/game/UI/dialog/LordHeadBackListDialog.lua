local const = GMethod.loadScript("game.GameLogic.Const")
local vipset = {0, 1,5,10}
local SData = GMethod.loadScript("data.StaticData")

--领主头像框列表对话框
local LordHeadBackListDialog = class(DialogViewLayout)

function LordHeadBackListDialog:onInitDialog()
    self:setLayout("dialogViewsConfig/LordHeadBackListDialog.json")
end

function LordHeadBackListDialog:onEnter()
    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, 1))
    self.btnBack:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.title:setString(Localize("labelHeadBackList"))
    local infos = {{cellType=1, text="labelHeadBackList"}}
    local maxHeads = 4
    local curValue = self.context:getInfoItem(const.InfoVIPlv)
    local needValues = vipset
    local unlockAdded = false
    local headIds = {1,2,3,4}
    if GameLogic.useTalentMatch then
        needValues = SData.getData("constsNew", 5).data
        curValue = self.context:getInfoItem(const.InfoCryNum)
        headIds = {1,2,5,3,4,6}
        maxHeads = 6
    end
    for i=1, maxHeads do
        local needValue = needValues[i]
        if needValue > curValue and not unlockAdded then
            unlockAdded = true
            table.insert(infos, {cellType = 1, text="labelLockHead"})
        end
        table.insert(infos, {cellType = 2, headId = headIds[i],
            curValue=curValue, needValue=needValue})
    end
    self.headBackTableView:setBusyTableData(infos, Handler(self.onUpdateHeadBackCell, self))
end

function LordHeadBackListDialog:onUpdateHeadBackCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(info.cellType)
        reuseCell:loadViewsTo()
    end
    if info.cellType == 1 then
        reuseCell.labelName:setString(Localize(info.text))
    else
        if info.headId == 1 then
            reuseCell.labelName:setString(Localize("labelNormalHead"))
        else
            reuseCell.labelName:setString(Localize("labelVip" .. (info.headId-1) .. "Head"))
        end
        GameUI.setHeadBackIcon(reuseCell.iconHeadBack, info.headId, false)
        if info.curValue < info.needValue then
            reuseCell.imgLock:setVisible(true)
        else
            reuseCell.imgLock:setVisible(false)
        end
        if info.headId == 3 or info.headId == 4 then
            reuseCell.imgLock:setImage("images/iconBackLock_4.png")
        else
            reuseCell.imgLock:setImage("images/iconBackLock_2.png")
        end
        reuseCell.btnHeadIcon:setScriptCallback(ButtonHandler(self.onChooseHeadBack, self, info))
    end
    return reuseCell
end

function LordHeadBackListDialog:onChooseHeadBack(info)
    if info.curValue < info.needValue then
        if GameLogic.useTalentMatch then
            display.pushNotice(Localizef("labelVipCanUnlock",{a = info.curValue, b = info.needValue}))
        else
            display.pushNotice(Localizef("labelVipCanUnlock",{a = info.needValue}))
        end
    else
        self.callback(info.headId)
        display.closeDialog(self.priority)
    end
end

return LordHeadBackListDialog
