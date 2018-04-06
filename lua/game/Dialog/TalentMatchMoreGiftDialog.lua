local TalentMatchMoreGiftDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")

function TalentMatchMoreGiftDialog:onInitDialog()
    self:setLayout("TalentMatchMoreGiftDialog.json")
end

function TalentMatchMoreGiftDialog:onEnter()
    self.title:setString(Localize("labelMoreGift"))
    self.btnChoose:setScriptCallback(ButtonHandler(self.onSaveChoose, self))
    GameUI.setNormalIcon(self.iconRes, {const.ItemRes, const.ResCrystal}, true)
    self:initData()
    -- self.boxTableView:setLazyTableData(self.rewards, Handler(self.onUpdateItemCell, self), 0)
end

function TalentMatchMoreGiftDialog:initData()
    local items = {}
    local showData, _map2 = self.context.talentMatch:getRecommendData(self.ainfo.aid)
    local matchData = self.context.talentMatch:getMatchNow(self.ainfo.aid)
    local actId = matchData.triggleActId
    local nowHid = math.floor(actId/10)
    local nowHtype = actId % 10
    table.insert(items, {hid=nowHid, htype=nowHtype, data=SData.getData("tmPack", nowHid, nowHtype)})
    self.initInfo = items[1]
    for _, hid in ipairs(showData.hids) do
        local sdata = SData.getData("tmPack", hid, nowHtype)
        if sdata and sdata.isOpen==1 and hid ~= nowHid then --and not _map2[hid]
            table.insert(items, {hid=hid, htype=nowHtype, data=sdata})
        end
    end
    -- 养成礼包也加进去……感觉有点怪啊
    -- for _, hid in ipairs(showData.hids) do
    --     local sdata = SData.getData("tmPack", hid, 2)
    --     if sdata and sdata.isOpen == 1 and (hid ~= nowHid or nowHtype ~= 2) and _map2[hid] then
    --         table.insert(items, {hid=hid, htype=2, data=SData.getData("tmPack", hid, 2)})
    --     end
    -- end

    self.giftTableView:setBusyTableData(items, Handler(self.onUpdateGiftCell, self))
    self:onChooseOtherGift(items[1])
end

function TalentMatchMoreGiftDialog:onChooseOtherGift(info)
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
            self.labelOk:setString(tostring(info.data.exchange))
            self.iconRes:setVisible(true)
        end
        self.btnChoose:setGray(self.selectInfo == self.initInfo)
    end
end

function TalentMatchMoreGiftDialog:onSaveChoose(force)
    if self.selectInfo ~= self.initInfo then
        if not force then
            local dialog = AlertDialog.new(1, Localize("alertTitleNormal"),
                Localizef("alertTextExchangeGift", {num=self.selectInfo.data.exchange}),
                {ctype=const.ResCrystal, cvalue=self.selectInfo.data.exchange,
                callback=Handler(self.onSaveChoose, self, true)})
            display.showDialog(dialog)
            return
        end
        self.context.talentMatch:addTriggerGift(self.ainfo.aid, self.selectInfo.hid * 10 + self.selectInfo.htype)
        self.initInfo = self.selectInfo
        display.closeDialog(self.priority)
        GameEvent.sendEvent("TalentMatchGift")
    end
end

function TalentMatchMoreGiftDialog:onUpdateGiftCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
        ViewTemplates.setImplements(reuseCell.layoutItems, "LayoutImplement", {callback=Handler(self.onUpdateItemCell, self), withIdx=false})
        reuseCell.nodeRewards:setScriptCallback(ButtonHandler(self.onChooseOtherGift, self, info))
    end
    info.reuseCell = reuseCell
    local data = info.data
    local ndata = SData.getData("heroPack", data.packId, 1)
    reuseCell.itemName:setString(Localize(ndata.nameKey))
    reuseCell.layoutItems:setLayoutDatas(ndata.rwds)
    reuseCell.backColor:setSize(reuseCell.backColor.size[1], reuseCell.layoutItems.size[2])
    reuseCell.nodeRewards:setSize(reuseCell.backColor.size[1], reuseCell.layoutItems.size[2])
    return reuseCell
end

-- 数据
function TalentMatchMoreGiftDialog:onUpdateItemCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    GameUI.setNormalIcon(reuseCell.itemIcon, info)
    GameUI.registerTipsAction(reuseCell.itemIcon, self.view, info[1], info[2])
    reuseCell.labelNumber:setString(Localizef("labelFormatX", {num=info[3]}))
    reuseCell.labelName:setString(GameLogic.getItemName(info[1], info[2]))
    -- if info[1] ~= reuseCell.displayIType or info[2] ~= reuseCell.displayIId then
    --     reuseCell.displayIType = info[1]
    --     reuseCell.displayIId = info[2]
    --     reuseCell.iconNode:removeAllChildren(true)
    --     GameUI.addItemIcon(reuseCell.iconNode, info[1], info[2], reuseCell.iconNode.size[1]/200,
    --         reuseCell.iconNode.size[1]/2, reuseCell.iconNode.size[2]/2, true)
    --     GameUI.registerTipsAction(reuseCell.iconNode, self.view, info[1], info[2], reuseCell.size[1]/2, reuseCell.size[2]/2)
    -- end
    -- reuseCell.labelName:setString(GameLogic.getItemName(info[1], info[2]))
    -- reuseCell.labelNum:setString(Localizef("labelFormatX", {num=info[3]}))
    return reuseCell
end

return TalentMatchMoreGiftDialog
