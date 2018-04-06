local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local ItemMainTab = class(DialogTabLayout)

local ItemCostTab = class(DialogTabLayout)

function ItemCostTab:create()
    self:setLayout("ItemCostTab.json")
    self:loadViewsTo()
    self.btnUseItem:setScriptCallback(ButtonHandler(self.onUseItem, self))
    --右侧的UI灰框和下方按钮的显示
    self.nodeItemInfos:setVisible(false)

    return self.view
end

function ItemCostTab:updateCostItemCell(cell, tableView, info)
    if not info.cell then
        info.cell = cell
        info.viewLayout = self:addLayout("ItemCell",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        cell:setScriptCallback(ButtonHandler(self.onSelectCell, self, info))
    end
    if info.itemtype~=info.displayType or info.itemid~=info.displayId then
        info.nodeItemBack:removeAllChildren(true)
        info.displayType = info.itemtype
        info.displayId = info.itemid
        if info.itemtype then
            GameUI.addItemIcon(info.nodeItemBack.view, info.itemtype, info.itemid, 1, 0, 0, true)
        end
    end
    if info.itemnum then
        info.labelItemNum:setString("x" .. info.itemnum)
    else
        info.labelItemNum:setString("")
    end
    info.scale=0.95
    GameUI.resetTemplateSelect(cell:getDrawNode(), info)
end

function ItemCostTab:onSelectCell(info)
    if info and not info.itemnum then
        return
    end
    if info~=self.selectedItem then
        local reuse = nil
        if self.selectedItem then
            self.selectedItem.selected = nil
            reuse = GameUI.resetTemplateSelect(self.selectedItem.cell:getDrawNode(), self.selectedItem, true)
        end
        self.selectedItem = info
        if info then
            info.selected = true
            GameUI.resetTemplateSelect(info.cell:getDrawNode(), info, reuse)
            self.nodeItemInfos:setVisible(true)
            --获取物品数目
            self.labelItemNum:setString("x" .. info.itemnum)
            self.labelItemName:setString(GameLogic.getItemName(info.itemtype, info.itemid))
            self.labelItemInfo:setString(GameLogic.getItemDesc(info.itemtype, info.itemid))
            self.nodeItemBack:removeAllChildren(true)
            --将左侧物品的图片添加到右侧上方的灰框中
            GameUI.addItemIcon(self.nodeItemBack.view, info.itemtype, info.itemid, 1, 0, 0, true)
            --对物品的属性进行判断，分别处理
            if info.itemtype==const.ItemWelfare or info.itemtype==const.ItemResBox
                or info.itemtype==const.ItemHWater or info.itemtype==const.ItemNewBox
                or info.itemtype==const.ItemSpringBox
                or info.itemtype == const.ItemBuild then
                --使用按钮
                self.labelUseItem:setString(Localize("btnUseItem"))
                self.btnUseItem:setVisible(true)
            else
                local property = SData.getData("property",info.itemtype,info.itemid)
                --如果是武器的话就有了出售按钮
                if property and property.price and property.price>0 then
                    self.labelUseItem:setString(Localize("wordSell"))
                    self.btnUseItem:setVisible(true)
                else
                    self.btnUseItem:setVisible(false)
                end
            end
        else
            self.nodeItemInfos:setVisible(false)
        end
    end
end

function ItemCostTab:onUseItem()
    local info = self.selectedItem
    if info then
        local params = {context=self:getContext(), parent=self, itemtype=info.itemtype, itemid=info.itemid, itemnum=info.itemnum}
        local property = SData.getData("property",info.itemtype,info.itemid)
        if info.itemtype==const.ItemResBox then
            params.mode = property.rtype
            params.price = property.value
        elseif info.itemtype == const.ItemNewBox then
            params.mode = info.itemtype
            params.price = property.value
        elseif info.itemtype == const.ItemSpringBox then
            params.mode = info.itemtype
            params.price = property.value
        elseif info.itemtype==const.ItemHWater then
            params.mode = 0
        elseif info.itemtype==const.ItemWelfare then
            params.mode = info.itemtype
            params.price = property.value
            local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWelfare)
            if buffInfo[4]~=0 then
                params.price = buffInfo[4]
            end
        elseif info.itemtype == const.ItemBuild then
            GameEvent.sendEvent(GameEvent.EventBuyBuild, {bid=property.rtype, blevel=1, useItem=true})
            return
        else
            -- 这里在多点操作时有可能会有问题，但事实上不影响显示，所以注释掉得了
            -- params.price = property.price
            return
        end
        params.onSureCallback = Handler(self.onRealUseItem, self, info)
        display.showDialog(ItemUseDialog.new(params))
    end
end

function ItemCostTab:onRealOpenBox(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        if data.code == 0 then
            GameLogic.addRewards(data.rwds)
            local context = GameLogic.getUserContext()
            context:changeItem(data.btype, data.bid, -data.bnum)
            local dialog = self:getDialog()
            if not dialog.deleted then
                display.closeDialog(dialog.priority+1)
                if self.selectedItem and data.btype == self.selectedItem.itemtype and data.bid == self.selectedItem.itemid then
                    if context:getItem(data.btype, data.bid) > 0 then
                        self.labelItemNum:setString("x" .. context:getItem(data.btype, data.bid))
                    else
                        self:onSelectCell(nil)
                    end
                end
                self:reloadInfos()
            end
            GameLogic.showGet(data.rwds, 0, true, true)
        end
    end
end

function ItemCostTab:onRealUseItem(info, num)
    --物品数据
    local context = self:getContext()
    if info.itemtype == const.ItemNewBox or info.itemtype == const.ItemSpringBox then
        if context:getItem(info.itemtype, info.itemid) >= num then
            if GameNetwork.lockRequest() then
                GameNetwork.request("openbox", {btype=info.itemtype, bid=info.itemid, bnum=num}, self.onRealOpenBox, self)
            end
        end
        return false
    end
    context:useOrSellItem(info.itemtype, info.itemid, num)
    if info.itemnum>num then
        self.labelItemNum:setString("x" .. (info.itemnum-num))
    else
        self:onSelectCell(nil)
    end
    self:reloadInfos()
    return true
end

function ItemCostTab:onEnter()
    if not self.infos then
        local infos = {}
        for i=1, 200 do
            infos[i] = {}
        end
        self.infos = infos
    end
    self.parent.curIdx = 1
    self:reloadInfos()
end

function ItemCostTab:reloadInfos()
    local context = self:getContext()
    local itemTypes = {const.ItemWelfare,const.ItemChip,const.ItemSpringBox,const.ItemNewBox,const.ItemPvtSkill, const.ItemResBox, const.ItemAccObj, const.ItemHWater, const.ItemEquipPart, const.ItemEquipStone,const.ItemRefreshStone,const.ItemWashsStone, const.ItemBuild, const.ItemExchange}
    local idx = 0
    local infos = self.infos
    if context:getProperty(const.ProMonthCard) > 0 then
        idx = idx + 1
        infos[idx].itemtype = const.ItemOther
        infos[idx].itemid = const.ProMonthCard
        infos[idx].itemnum = context:getProperty(const.ProMonthCard)
        infos[idx].selected = (self.selectedItem==infos[idx])
    end
    --读取types表
    for _, itype in ipairs(itemTypes) do
        local ps = SData.getData("property", itype)
        local sitems = {}
        --存储自己所需要的信息
        for itemid, _ in pairs(ps) do
            local num = context:getItem(itype,itemid)
            if num>0 then
                table.insert(sitems, {itemtype=itype, itemid=itemid, itemnum=num})
            end
        end
        GameLogic.mySort(sitems, "itemid")
        for _, item in ipairs(sitems) do
            idx = idx+1
            infos[idx].itemtype = item.itemtype
            infos[idx].itemid = item.itemid
            infos[idx].itemnum = item.itemnum
            infos[idx].selected = (self.selectedItem==infos[idx])
        end
    end
    for i=idx+1, 200 do
        infos[i].itemtype = nil
        infos[i].itemid = nil
        infos[i].itemnum = nil
        infos[i].selectedItem = nil
    end
    -- dump(infos)
    if not self.tableView then
        self.tableView = self.nodeItemTable:loadTableView(infos, Handler(self.updateCostItemCell, self))
    else
        for _,info in ipairs(infos) do
            if info.cell then
                self:updateCostItemCell(info.cell, self.tableView, info)
            end
        end
    end
end

local ItemEquipTab = class(DialogTabLayout)

function ItemEquipTab:create()
    self:setLayout("ItemEquipTab.json")
    self:loadViewsTo()
    self.btnForge:setScriptCallback(ButtonHandler(self.onForgeEquip, self))
    self.btnSell:setScriptCallback(ButtonHandler(self.onSellEquip, self))
    --self.btnImage:setScriptCallback(ButtonHandler(self.onEquipImage, self))
    self.btnImage:setVisible(false)
    self.einfo = {}
    self.nodeItemInfos:setVisible(false)
    return self.view
end

function ItemEquipTab:onForgeEquip()
    local item = self.selectedItem
    display.showDialog(EquipDialog.new({parent=self, context=self:getContext(), selectedEidx=item.equip.idx}))
end

function ItemEquipTab:onSellEquip(force)
    local item = self.selectedItem
    local equip = item.equip
    if not force then
        local dl = AlertDialog.new(3,Localize("labelAffirmSell"),Localizef("stringAffirmSell",
                {a = equip:getName(), b = equip:getSellPrice()}),{callback=Handler(self.onSellEquip, self, true)})
        display.showDialog(dl)
    else
        music.play("sounds/sell.mp3")
        self:getContext().equipData:sellEquip(equip)
        self.selectedItem = nil
        self:reloadInfos()
        self.nodeItemInfos:setVisible(false)
    end
end

function ItemEquipTab:onEquipImage()
    self:getDialog():pushTab("eimage")
end

function ItemEquipTab:onChildDialogExit()
    self:reloadInfos()
    self:reloadNotice()
end

local _flagSetting1 = {flagHero=true}
function ItemEquipTab:updateEquipCell(cell, tableView, info)
    if not info.cell then
        info.cell = cell
        cell:setScriptCallback(ButtonHandler(self.onSelectCell, self, info))
    end
    GameUI.updateEquipTemplate(cell:getDrawNode(), info, info.equip, _flagSetting1)
end

function ItemEquipTab:onSelectCell(info)
    if info and not info.equip then
        return
    end
    if info~=self.selectedItem then
        local reuse = nil
        if self.selectedItem then
            self.selectedItem.selected = nil
            reuse = GameUI.resetTemplateSelect(self.selectedItem.cell:getDrawNode(), self.selectedItem, true)
        end
        self.selectedItem = info
        if info then
            info.selected = true
            GameUI.resetTemplateSelect(info.cell:getDrawNode(), info, reuse)
            self.nodeItemInfos:setVisible(true)

            self.labelItemName:setString(info.equip:getName())
            GameUI.setHeroNameColor(self.labelItemName, info.equip.color)
            self.labelItemInfo:setString(info.equip:getDesc(2))
            GameUI.updateEquipTemplate(self.nodeItemBack.view, self.einfo, info.equip)

        else
            self.nodeItemInfos:setVisible(false)
        end
    end
end

function ItemEquipTab:onUseItem()
    local info = self.selectedItem
    if info then
        local params = {context=self:getContext(), parent=self, itemtype=info.itemtype, itemid=info.itemid, itemnum=info.itemnum}
        local property = SData.getData("property",info.itemtype,info.itemid)
        if info.itemtype==const.ItemResBox then
            params.mode = property.rtype
            params.price = property.value
        elseif info.itemtype==const.ItemHWater then
            params.mode = 0
        else
            params.price = property.price
        end
        params.onSureCallback = Handler(self.onRealUseItem, self, info)
        display.showDialog(ItemUseDialog.new(params))
    end
end

function ItemEquipTab:onRealUseItem(info, num)
    local context = self:getContext()
    context:useOrSellItem(info.itemtype, info.itemid, num)
    self:reloadInfos()
    return true
end

function ItemEquipTab:onEnter()
    if not self.infos then
        local infos = {}
        for i=1, const.MaxEquipNum do
            infos[i] = {}
        end
        self.infos = infos
    end
    self.parent.curIdx = 2
    self:reloadInfos()
    self:reloadNotice()
end

local function _sortEquip(e1, e2)
    local equip1 = e1
    local equip2 = e2

    local eh1 = equip1.hidx>0
    local eh2 = equip2.hidx>0
    if eh1 ~= eh2 then
        return eh1
    end
    if equip1.color~=equip2.color then
        return equip1.color>equip2.color
    elseif equip1.level~=equip2.level then
        return equip1.level>equip2.level
    else
        return equip1.eid<equip2.eid
    end
end

local function getSortedEquips(context)
    local equips = context.equipData:getAllEquips()
    local infos = {}
    local eitem
    for i, equip in pairs(equips) do
        table.insert(infos, equip)
    end
    table.sort(infos, _sortEquip)
    return infos
end

function ItemEquipTab:reloadInfos()
    local context = self:getContext()
    local equips = getSortedEquips(context)
    local idx = 0
    local infos = self.infos
    for _, item in ipairs(equips) do
        idx = idx+1
        infos[idx].equip = item
        infos[idx].selected = (self.selectedItem==infos[idx])
    end
    for i=idx+1, const.MaxEquipNum do
        infos[i].equip = nil
        infos[i].selected = nil
    end
    if not self.tableView then
        self.tableView = self.nodeItemTable:loadTableView(infos, Handler(self.updateEquipCell, self))
    else
        for _,info in ipairs(infos) do
            if info.cell then
                self:updateEquipCell(info.cell, self.tableView, info)
            end
        end
    end
end

function ItemEquipTab:reloadNotice()
    local num = 0
    if num>0 then
        self.nodeNoticeBack:setVisible(true)
        self.labelNoticeNum:setString(N2S(num))
    else
        self.nodeNoticeBack:setVisible(false)
    end
end

function ItemMainTab:onEnter()
    local dialog = self:getDialog()
    dialog.questionBut:setVisible(true)
    dialog.title:setVisible(false)
    dialog:changeTabTag("storage")
    dialog.questionTag = "dataQuestionItemMain"
    if dialog.curIdx then
        self.curIdx = dialog.curIdx
    end
    self.tab:changeTab(self.curIdx or 1)
end

function ItemMainTab:create()
    self:setLayout("ItemMainTab.json")
    self:loadViewsTo()
    --消耗品
    local tabTitles = {Localize("tabCostItem"),Localize("tabEquip")}
    local tabs = {ItemCostTab.new(self), ItemEquipTab.new(self)}
    self.tab = DialogTemplates.createTabView(self.view, tabTitles, tabs, self.nodeItemTab:getSetting("tabSetting"), {actionType=2, tabType=2})
    return self.view
end

return ItemMainTab
