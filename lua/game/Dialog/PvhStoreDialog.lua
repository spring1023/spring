PvhStoreDialog = class(DialogViewLayout)
function PvhStoreDialog:onInitDialog()
    self:setLayout("PvhStoreDialog.json")
    self:loadViewsTo()

    self.closeBut:setScriptCallback(ButtonHandler(display.closeDialog, 0))
end

function PvhStoreDialog:onEnter()
    local pvh = self.nightmare and self.context.npvh or self.context.pvh
    local items = pvh:getStoreItems(self.storeIdx)
    if not items then
        self:requestStoreItems()
    else
        self:reloadStoreItems(items)
    end
end

function PvhStoreDialog:requestStoreItems()
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("pvhstore", {getpvhshops={self.storeIdx,self.nightmare}}, self.onResponseStoreItems, self)
end

function PvhStoreDialog:onResponseStoreItems(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        local pvh = self.nightmare and self.context.npvh or self.context.pvh
        pvh:setStoreItems(self.storeIdx, data)
        if not self.deleted then
            self:reloadStoreItems(pvh:getStoreItems(self.storeIdx))
        end
    else
        log.e("store error",json.encode(data))
    end
end

function PvhStoreDialog:reloadStoreItems(items)
    self.nodeItemTable:removeAllChildren(true)
    local size = self.nodeItemTable.size
    local ts = self.nodeItemTable:getSetting("tableSetting")
    local infos = {}
    for _, item in ipairs(items) do
        table.insert(infos, {item=item})
    end
    local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=infos, cellUpdate=Handler(self.updateItemCell, self)})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
    self.nodeItemTable.view:addChild(tableView.view)
    self.tableView = tableView
    self.infos = infos
end

function PvhStoreDialog:updateItemCell(cell,tableView,info)
    if not info.viewLayout then
        info.viewLayout = self:addLayout("ItemCell", cell:getDrawNode())
        info.cell = cell
        info.viewLayout:loadViewsTo(info)
        cell:setScriptCallback(ButtonHandler(self.onBuyItem, self, info))
    end
    local item = info.item
    if info.displayType~=item.itemType or info.displayId~=item.itemId then
        info.nodeItemBack:removeAllChildren(true)
        info.itemNode=GameUI.addItemIcon(info.nodeItemBack, item.itemType, item.itemId, 1, 0, 0, 0, false)
        info.displayType = item.itemType
        info.displayId = item.itemId
    end
    local name = GameLogic.getItemName(item.itemType, item.itemId) .. "x" .. item.itemNum
    info.labelName:setString(name)
    info.nodeCostType:setTemplateValue(item.ctype)
    info.labelCostValue:setString(N2S(item.cvalue))
    if item.buyed then
        cell:setGray(true)
        info.itemNode:setSValue(-100)
        local selled=GameUI.addHaveGet(cell:getDrawNode(),Localize("labelItemSelled"),0.9,562/2-33,394/2+10,2)
        selled:setSValue(0)
    else
        cell:setGray(false)
        info.itemNode:setSValue(0)
    end
    self:reloadInfoPrice(info)
end

function PvhStoreDialog:reloadStorePrices()
    for _, info in ipairs(self.infos) do
        self:reloadInfoPrice(info)
    end
end

function PvhStoreDialog:reloadInfoPrice(info)
    if info.cell then
        local item = info.item
        if self.context:getRes(item.ctype)<item.cvalue then
            info.labelCostValue:setColor(GConst.Color.Red)
        else
            info.labelCostValue:setColor(GConst.Color.White)
        end
    end
end

function PvhStoreDialog:onBuyItem(info)
    if not GameNetwork.checkRequest() then
        local item = info.item
        if item.buyed then
            display.pushNotice(Localize("noticeItemSelled"))
            music.play("sounds/buyDef.mp3")
            return
        else
            display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"),Localizef("alertTextBuyItem",{name=GameLogic.getItemName(item.itemType,item.itemId) .. "x" .. item.itemNum}),{ctype=item.ctype, cvalue=item.cvalue, callback=Handler(self.requestBuyItem, self, info)}))
        end
    end
end

function PvhStoreDialog:requestBuyItem(info)
    if GameNetwork.lockRequest() then
        GameNetwork.request("pvhbuyitem",{buypvhshop={info.item.itemIdx}},self.onResponseBuyItem, self, info)
    end
end

function PvhStoreDialog:onResponseBuyItem(info, suc, data)
    GameNetwork.unlockRequest()
    if suc then
        local item = info.item
        item.buyed = true
        self.context:changeRes(item.ctype, -item.cvalue)
        GameLogic.statCrystalCost("远征商店购买资源消耗",item.ctype, -item.cvalue)
        GameLogic.addRewards(data)
        display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(item.itemType,item.itemId) .. "x" .. item.itemNum}))
        if not self.deleted then
            music.play("sounds/buy.mp3")
            self:reloadStorePrices()
            self:updateItemCell(info.cell, self.tableView, info)
        end
    end
end
