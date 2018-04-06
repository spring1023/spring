local ActivityMoreGiftDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")

function ActivityMoreGiftDialog:onInitDialog()
    self:setLayout("TalentMatchMoreGiftDialog.json")
end

function ActivityMoreGiftDialog:onEnter()
    self.title:setString(Localize("labelMoreGift"))
    self.btnChoose:setScriptCallback(ButtonHandler(self.onSaveChoose, self))
    GameUI.setNormalIcon(self.iconRes, {const.ItemRes, const.ResCrystal}, true)
    self:initData()
end

function ActivityMoreGiftDialog:initData()
    local items = {}
    local act = self.act
    local actId = self.actId
    local i = 2
    local initGift = (self.initGift or 1) * 3 - 1
    local rwd2 = self.context.activeData:getConfigableRwds(actId, initGift)
    table.insert(items, {idx=initGift, exchange=rwd2.exchange, items=rwd2.items})
    while true do
        local rwd = self.context.activeData:getConfigableRwds(actId, i)
        if rwd then
            if i ~= initGift then
                table.insert(items, {idx=i, exchange=rwd.exchange, items=rwd.items})
            end
            i = i + 3
        else
            break
        end
    end
    self.initInfo = items[1]

    self.giftTableView:setBusyTableData(items, Handler(self.onUpdateGiftCell, self))
    self:onChooseOtherGift(items[1])
end

function ActivityMoreGiftDialog:onChooseOtherGift(info)
    if self.selectInfo ~= info then
        if self.selectInfo then
            self.selectInfo.selected = nil
            local reuseCell = self.selectInfo.reuseCell
            reuseCell.selectImg:removeFromParent(true)
            reuseCell.selectImg = nil
            reuseCell.imgNameBack.view:setHValue(0)
            reuseCell.imgNameBack.view:setSValue(0)
        end
        self.selectInfo = info
        if self.selectInfo then
            local reuseCell = self.selectInfo.reuseCell
            reuseCell.imgNameBack.view:setHValue(-155)
            reuseCell.imgNameBack.view:setSValue(36)

            local img = ui.scale9("images/matchs/giftSelect.9.png", 20, reuseCell.nodeRewards.size)
            display.adapt(img, 0, 0)
            reuseCell.nodeRewards:addChild(img)
            reuseCell.selectImg = img
            self.labelOk:setString(tostring(info.exchange))
            self.iconRes:setVisible(true)
        end
        self.btnChoose:setGray(self.selectInfo == self.initInfo)
    end
end

function ActivityMoreGiftDialog:onSaveChoose(force)
    if self.selectInfo ~= self.initInfo then
        if not force then
            local dialog = AlertDialog.new(1, Localize("alertTitleNormal"),
                Localizef("alertTextExchangeGift", {num=self.selectInfo.exchange}),
                {ctype=const.ResCrystal, cvalue=self.selectInfo.exchange,
                callback=Handler(self.onSaveChoose, self, true)})
            display.showDialog(dialog)
            return
        end
        self.context.activeData:setMultiControlGift(self.actId, self.selectInfo.idx)
        self.initInfo = self.selectInfo
        display.closeDialog(self.priority)
        GameEvent.sendEvent("refreshEggDialog")
    end
end

function ActivityMoreGiftDialog:onUpdateGiftCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
        ViewTemplates.setImplements(reuseCell.layoutItems, "LayoutImplement", {callback=Handler(self.onUpdateItemCell, self), withIdx=false})
        reuseCell.nodeRewards:setScriptCallback(ButtonHandler(self.onChooseOtherGift, self, info))
    end
    info.reuseCell = reuseCell
    local vt = self.act.viewTemplates and self.act.viewTemplates.pages and self.act.viewTemplates.pages[info.idx]
    if vt and vt.key then
        reuseCell.itemName:setString(Localize(vt.key))
    end
    reuseCell.layoutItems:setLayoutDatas(info.items)
    reuseCell.backColor:setSize(reuseCell.backColor.size[1], reuseCell.layoutItems.size[2])
    reuseCell.nodeRewards:setSize(reuseCell.backColor.size[1], reuseCell.layoutItems.size[2])
    return reuseCell
end

-- 数据
function ActivityMoreGiftDialog:onUpdateItemCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    GameUI.setNormalIcon(reuseCell.itemIcon, info)
    GameUI.registerTipsAction(reuseCell.itemIcon, self.view, info[1], info[2])
    reuseCell.labelNumber:setString(Localizef("labelFormatX", {num=info[3]}))
    reuseCell.labelName:setString(GameLogic.getItemName(info[1], info[2]))
    return reuseCell
end

return ActivityMoreGiftDialog
