-- Depiction：背包主对话框
-- Author：王雨(w3333y@126.com)
-- Create Date：2018.03.15
local BagMainDialog = class(DialogViewLayout)
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")

local tabName = {Consum = 1, Equip = 2, Frag = 3, Other = 4}

--@breif装备排序
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

--@breif获取所有装备的信息
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

--@breif加载已有装备信息
local function loadEquipInfo(self)
    local context = self.context
    local idx = 0
    local infos = {}
    ViewTemplates.setImplements(self.itemLayout, "LayoutImplement", {callback=Handler(self.onUpdateItemsCell2, self), withIdx=false})
    local equips = getSortedEquips(context)
    for _, item in ipairs(equips) do
        idx = idx+1
        if not infos[idx] then
            infos[idx] = {}
        end
        infos[idx].equip = item
    end
    self.itemLayout:setLayoutDatas(infos)
end

--@breif加载消耗品信息
local function loadConsumInfo(self)
    local context = self.context
    local idx = 0
    local infos = {}
    ViewTemplates.setImplements(self.itemLayout, "LayoutImplement", {callback=Handler(self.onUpdateItemsCell1, self), withIdx=false})
    local itemTypes = {const.ItemWelfare,const.ItemChip,const.ItemSpringBox,const.ItemNewBox,
        const.ItemPvtSkill, const.ItemResBox, const.ItemAccObj, const.ItemHWater, const.ItemEquipPart,
        const.ItemEquipStone,const.ItemRefreshStone,const.ItemWashsStone, const.ItemBuild, const.ItemExchange}
    if context:getProperty(const.ProMonthCard) > 0 then
        idx = idx + 1
        if not infos[idx] then
            infos[idx] = {}
        end
        infos[idx].itemtype = const.ItemOther
        infos[idx].itemid = const.ProMonthCard
        infos[idx].itemnum = context:getProperty(const.ProMonthCard)
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
            if not infos[idx] then
                infos[idx] = {}
            end
            infos[idx].itemtype = item.itemtype
            infos[idx].itemid = item.itemid
            infos[idx].itemnum = item.itemnum
        end
    end
    self.itemLayout:setLayoutDatas(infos)
end

--@breif加载碎片信息(包含装备碎片和英雄碎片)
local function loadFragInfo(self)
    local context = self.context
    local idx = 0
    local infos = {}
    ViewTemplates.setImplements(self.itemLayout, "LayoutImplement", {callback=Handler(self.onUpdateItemsCell1, self), withIdx=false})
    local elevels = SData.getData("elevels")
    for eid,_ in pairs(elevels) do
        local cnum = context:getItem(const.ItemEquipFrag, eid)
        if cnum > 0 then
            table.insert(infos, {itemtype=const.ItemEquipFrag, itemid=eid, itemnum=cnum})
        end
    end
    local hinfos = SData.getData("hinfos")
    for hid, _ in pairs(hinfos) do
        local cnum = context:getItem(const.ItemFragment, hid)
        if cnum > 0 then
            table.insert(infos, {itemtype=const.ItemFragment, itemid=hid, itemnum=cnum})
        end
    end
    self.itemLayout:setLayoutDatas(infos)
end

--@breif碎片合成英雄
local function mergeHeroFrag(item)
    local hid = item.itemid
    local hinfo = SData.getData("hinfos", hid)
    local context = GameLogic.getUserContext()
    local heroData = context.heroData
    if heroData:getHeroNum()>=heroData:getHeroMax() then
        display.pushNotice(Localize("noticeHeroPlaceFull"))
        return
    end
    if hinfo.fragNum>0 and hinfo.fragNum<=context:getItem(const.ItemFragment, hid) then
        local rate = hinfo.displayColor and hinfo.displayColor >=5 and 5 or hinfo.rating
        context.heroData:mergeHero(hid,rate)
        display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(const.ItemHero, hid)}))
        local _hero = context.heroData:makeHero(hid)
        NewShowHeroDialog.new({rhero=_hero,shareIdx = _hero.info.rating})
    else
        display.pushNotice(Localize("fragNotEnough"))
    end
end

--@breif碎片合成装备
local function mergeEquipFrag(item)
    local eid = item.itemid
    local fNum = SData.getData("elevels", eid,1).mfrag or 0
    local context = GameLogic.getUserContext()
    local equipData = context.equipData
    if equipData:getEquipNum()>=equipData:getEquipMax() then
        display.pushNotice(Localize("noticeEquipPlaceFull"))
        return
    end
    local cnum = context:getItem(const.ItemEquipFrag, eid)
    if fNum <= cnum then
        local _equip = context.equipData:makeEquip(eid)
        context.equipData:mergeEquip(eid)
        display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(const.ItemEquip, eid)}))
        --TODO 目前rating都是4, 等策划出了新表再改
        _equip.info = {rating = 4}
        _equip.hid = _equip.eid
        NewShowHeroDialog.new({rhero=_equip,rtype = const.ItemEquip, shareIdx=6})
    else
        display.pushNotice(Localize("fragNotEnough"))
    end
end

function BagMainDialog:onInitDialog()
    self.context = GameLogic.getUserContext()
    self:initUI()
    self:initData()
end

function BagMainDialog:initUI()
    self:setLayout("bag_main_dialog.json")
    self:loadViewsTo()
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.tabs = {self.tab1, self.tab2, self.tab3, self.tab4}--标签页
    self.lightTab = {self.img_tabLight1, self.img_tabLight2, self.img_tabLight3, self.img_tabLight4}--标签页高亮图
    for i=1,4 do
        self.lightTab[i]:setVisible(false)
        self.tabs[i]:setScriptCallback(ButtonHandler(self.reloadTab, self, i))
    end
    self.tabs[4]:setVisible(false)--"Other"标签页暂时隐藏, 后续有需要再加上
    self.lightTab[4]:setVisible(false)
    self:reloadTab(tabName.Consum)
    self.btn_itemUse:setScriptCallback(ButtonHandler(self.onClickUse, self))
end

function BagMainDialog:initData()

end

--@brief切换标签页
function BagMainDialog:reloadTab(tab)
    self.itemLayout:removeAllChildren()
    self.oldCell = nil
    if tab == tabName.Other then
        --其他一栏暂时关闭, 日后有需求再加
    elseif tab == tabName.Consum then
        loadConsumInfo(self)
    elseif tab == tabName.Equip then
        loadEquipInfo(self)
    elseif tab == tabName.Frag then
        loadFragInfo(self)
    end
    self.tab = tab--存储当前所选标签页的idx
    self.lightTab[tab]:setVisible(true)--所选变亮
    if self.oldLightTab then
        self.oldLightTab:setVisible(false)
    end
    self.oldLightTab = self.lightTab[tab]
end

--@brief非装备物品的加载
function BagMainDialog:onUpdateItemsCell1(reuseCell, layout, item)
    if not reuseCell then
        reuseCell = layout:createItem(1)
        reuseCell:loadViewsTo()
    end
    if item.itemid ~= reuseCell.displayId or item.itemtype ~= reuseCell.displayMode then
        reuseCell.displayMode = item.itemtype
        reuseCell.displayId = item.itemid
        reuseCell.bg_item:removeAllChildren()
        local cellSize = reuseCell.bg_item.size
        reuseCell:setScriptCallback(ButtonHandler(self.onSelectCell, self, item, reuseCell))
        GameUI.addItemIcon(reuseCell.bg_item, item.itemtype, item.itemid, cellSize[2]/200,cellSize[1]/2, cellSize[2]/2, true)
        GameUI.registerTipsAction(reuseCell, self.view, item.itemtype,  item.itemid)
    end
    reuseCell.lb_itemNum:setString(N2S(item.itemnum))
    return reuseCell
end

--@brief加载装备
function BagMainDialog:onUpdateItemsCell2(reuseCell, layout, item)
    if not reuseCell then
        reuseCell = layout:createItem(1)
        reuseCell:loadViewsTo()
    end
    if item.equip ~= reuseCell.equip then
        reuseCell.equip = item.equip
        reuseCell.bg_item:removeAllChildren()
        local cellSize = reuseCell.bg_item.size
        reuseCell:setScriptCallback(ButtonHandler(self.onSelectCell, self, item, reuseCell))
        GameUI.updateEquipTemplate(reuseCell, item, item.equip, {flagHero=false})
    end
    return reuseCell
end

--@brief选择物品
function BagMainDialog:onSelectCell(item, cell)
    if not item or not cell then
        return
    end
    self.selectItem = item
    --所选物品加亮框
    if self.oldCell then
        self.oldCell.temp:removeFromParent(true)
    end
    local cellSize = {cell.bg_item.size[1], cell.bg_item.size[2]}
    local off = {0, 0}
    if self.tab ~=  tabName.Equip then
        cellSize[1] = cell.bg_item.size[1]*1.25
        cellSize[2] = cell.bg_item.size[2]*1.25
        off[1] = -25
        off[2] = -25
        --左上角的UI展示
        self.node_itemIcon:removeAllChildren(true)
        GameUI.addItemIcon(self.node_itemIcon, item.itemtype, item.itemid, cell.bg_item.size[2]/210,
            cell.bg_item.size[1]/2, cell.bg_item.size[2]/2, true)
        self.lb_itemName:setString(GameLogic.getItemName(item.itemtype, item.itemid))
        self.lb_itemNumNow:setString(Localize("labelCurrent")..N2S(item.itemnum))
        self.lb_itemDesc:setString(GameLogic.getItemDesc(item.itemtype, item.itemid))
    else
        cellSize[1] = cell.bg_item.size[1]*1.1
        cellSize[2] = cell.bg_item.size[2]*1.1
        off[1] = 0
        off[2] = 0
        --左上角的UI展示
        self.node_itemIcon:removeAllChildren(true)
        GameUI.updateEquipTemplate(self.node_itemIcon, item, item.equip, {flagHero=false})
        GameUI.addItemBack(self.node_itemIcon, item.equip.color, 1, 119, 115)
        GameUI.addEquipIcon(self.node_itemIcon, item.equip.eid, 0.9, 119, 115)
        self.lb_itemName:setString(item.equip:getName())
        self.lb_itemNumNow:setString(Localize("labelBeasetSkillCurrentLv")..item.equip.level)
        self.lb_itemDesc:setString(item.equip:getDesc(2))
        self.itemInfo = {}
    end
    cell.temp = ui.sprite("icon/icon_itemFrame_choose.png", {cellSize[1], cellSize[2]})
    display.adapt(cell.temp, off[1], off[2])
    cell:addChild(cell.temp)
    self.oldCell = cell
end

--@brief点击使用按钮的逻辑
function BagMainDialog:onClickUse()
    if not self.selectItem then
        display.pushNotice(Localize("pleaseSelectItem"))
        return
    end
    if self.tab == tabName.Consum then
        self:onUseItem()
    elseif self.tab == tabName.Equip then
        local equip = self.selectItem.equip
        display.showDialog(AlertDialog.new(3, Localize("btnEquipFragCollect"),
            Localizef("alertTextEquipFrag",{name=equip:getName(), num=equip:getFragNum()}),
            {callback=Handler(self.onExplainEquip, self, true)}))
    elseif self.tab == tabName.Frag then
        if self.selectItem.itemtype == const.ItemEquipFrag then
            mergeEquipFrag(self.selectItem)
        elseif self.selectItem.itemtype == const.ItemFragment then
            mergeHeroFrag(self.selectItem)
        end
    elseif self.tab == tabName.Other then
        --其他一栏暂时关闭, 日后有需求再加
    end
    self:reloadTab(self.tab)
end

function BagMainDialog:onUseItem()
    local info = self.selectItem
    if info then
        local params = {context=GameLogic.getUserContext(), parent=self, itemtype=info.itemtype, itemid=info.itemid, itemnum=info.itemnum}
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
            display.pushNotice("cantUseInBaG")
            return
        end
        --使用按钮
        params.onSureCallback = Handler(self.onRealUseItem, self, info)
        local newUseItemDialog = GMethod.loadScript("game.UI.NewDialog.newUseItemDialog")
        display.showDialog(newUseItemDialog.new(params))--{tab = self.tab, item = self.selectItem}
    end
end

function BagMainDialog:onRealUseItem(info, num)
    --物品数据
    local context = self.context
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

    else
        self:onSelectCell(nil)
    end
    return true
end

--装备分解
function BagMainDialog:onExplainEquip(force)
    local equip = self.selectItem.equip
    if not equip then
        display.pushNotice(Localize("noiceNotEquip"))
        return
    end
    local exp = equip:getExpInfos()
    local _lv = equip.level
    if exp>0 or _lv>1 then
        display.pushNotice(Localize("noiceEquipHaveExp"))
        return
    end
    if not force then
        display.showDialog(AlertDialog.new(3, Localize("btnEquipFragCollect"), Localizef("alertTextEquipFrag",{name=equip:getName(), num=equip:getFragNum()}),{callback=Handler(self.onExplainEquip, self, true)}))
    else
        self.context:addCmd({const.CmdEquipAnalysis, equip.idx})
        local rewards={{const.ItemEquipFrag,equip.eid,equip:getFragNum()}}
        GameLogic.addRewards(rewards)
        GameLogic.showGet(rewards)
        self.context.equipData:changeEquipHero(equip, nil)
        self.context.equipData:removeEquip(equip.idx)
    end
end

return BagMainDialog
