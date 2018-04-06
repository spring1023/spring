local ActivityMultiDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")

function ActivityMultiDialog:onInitDialog()
    self:setLayout("ActivityMultiGiftDialog.json")
end

function ActivityMultiDialog:onEnter()
    self:initUI()
    self:initData()
    ActivityLogic.checkActNew(self.actId, self.act, true)
end

function ActivityMultiDialog:initUI()
    local title = Localize(self.act.menuName or self.act.actLeftTitle or self.act.actTitle or ("actName" .. self.actId))
    self.title:setString(title)

    self.btnCloseBack:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.btnQuestion:setScriptCallback(ButtonHandler(self.onMoreGift, self))
    self.questionNode:setVisible(false)
    local tmp = ui.node()
    GameEvent.bindEvent(tmp, "refreshEggDialog", self, self.onRefreshData)
    self.view:addChild(tmp)

    self.pageId = 1
    local vt = self.act.viewTemplates
    if vt then
        ActivityLogic.loadPageViewTemplates(self.view, self, self, vt)
    end
end

function ActivityMultiDialog:onRefreshData()
    if not self.deleted then
        if not ActivityLogic.checkActVisible(self.act) then
            display.closeDialog(self.priority)
        else
            self:onRefreshTable()
        end
    end
end

function ActivityMultiDialog:onMoreGift()
    display.sendIntent({class="game.Dialog.ActivityMoreGiftDialog", params={actId=self.actId, act=self.act, initGift=self.__initGift}})
end

function ActivityMultiDialog:onUpdate(diff)
    local leftTime = self.__endTime - GameLogic.getSTime()
    if leftTime < 0 then
        display.closeDialog(self.priority)
    else
        self.labelLeftTime:setString(StringManager.getFormatTime(leftTime))
    end
end

function ActivityMultiDialog:initData()
    local endTime = self.act.actEndTime --matchData.actEndTime or
    self.__endTime = endTime
    RegTimeUpdate(self.labelLeftTime.view, Handler(self.onUpdate, self), 0.5)
    self:onUpdate(0)
    ViewTemplates.setImplements(self.giftTableView, "LayoutImplement", {callback=Handler(self.onUpdateGiftCell, self), withIdx=false})
    self:onRefreshTable()
end

-- 数据
function ActivityMultiDialog:onUpdateGiftCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    -- GameUI.setNormalIcon(reuseCell.nodeIcon, info.icon)
    local incPercent = info.percent
    if info.percent and info.percent > 0 then
        reuseCell.nodePercent:setVisible(true)
        reuseCell.labelPercentNum:setString("+" .. (incPercent - 100) .. "%")
        reuseCell.labelName:setPositionX(330)
    elseif info.discount and info.discount < 100 then
        reuseCell.nodePercent:setVisible(true)
        reuseCell.labelPercentNum:setString(Localizef("labelSaleOff", {percent=100-info.discount}))
        incPercent = 10000 / info.discount
        reuseCell.labelName:setPositionX(330)
    else
        reuseCell.nodePercent:setVisible(false)
        reuseCell.labelName:setPositionX(287.5)
    end
    ViewTemplates.setImplements(reuseCell.itemLayout, "LayoutImplement", {callback=Handler(self.onUpdateRewardCell, self), withIdx=false})
    reuseCell.itemLayout:setLayoutDatas(info.rewards)
    reuseCell.btnGo:setScriptCallback(ButtonHandler(self.onBuyGift, self, info))
    if info.atype == 2 then
        local product = Plugins.storeKeys[info.storeIdx or 1]
        local newPriceNum = Plugins.storeItems[product]
        local newPriceSafe = Plugins.storeItemsSafe[product]
        local newPrice = GameLogic.getOldPrice(newPriceNum, 100, newPriceSafe)
        local oldPrice = GameLogic.getOldPrice(newPriceNum, (incPercent or 100), newPriceSafe)

        reuseCell.labelLeftPrice:setString(oldPrice)
        reuseCell.iconLeftPrice:setVisible(false)

        GameUI.addRedLine(reuseCell.layoutSale, true)

        reuseCell.labelRightPrice:setString(newPrice)
        reuseCell.iconRightPrice:setVisible(false)
    elseif info.atype == 3 then
        reuseCell.labelLeftPrice:setString(tostring(math.floor(info.costs[1][3] * incPercent / 100 + 0.5)))
        reuseCell.iconLeftPrice:setVisible(true)
        GameUI.setNormalIcon(reuseCell.iconLeftPrice, {info.costs[1][1], info.costs[1][2]}, true)

        GameUI.addRedLine(reuseCell.layoutSale, true)

        reuseCell.iconRightPrice:setVisible(true)
        reuseCell.labelRightPrice:setString(tostring(math.floor(info.costs[1][3])))
        GameUI.setNormalIcon(reuseCell.iconRightPrice, {info.costs[1][1], info.costs[1][2]}, true)
    end
    if info.buyCount >= info.maxCount then
        reuseCell.btnGo:setVisible(false)
        if not reuseCell.__haveGet then
            local x, y = reuseCell.btnGo:getPosition()
            reuseCell.__haveGet = GameUI.addHaveGet(reuseCell.btnGo.view:getParent(),
                Localize("labelItemSelled"), 0.5, x, y, 0)
        end
    else
        if reuseCell.__haveGet then
            reuseCell.__haveGet:removeFromParentAndCleanup(true)
            reuseCell.__haveGet = nil
        end
        reuseCell.btnGo:setVisible(true)
        if info.atype == 2 and (GameLogic.purchaseLock or self.context.activeData:checkPurchaseLimit(self.actId, info.idx)) then
            reuseCell.btnGo:setGray(true)
        else
            reuseCell.btnGo:setGray(false)
        end
    end
    reuseCell.labelLeftChance:setString(Localizef("actRightSum170416", {a=info.maxCount-info.buyCount, b=info.maxCount}))
    local vt = self.act.viewTemplates and self.act.viewTemplates.pages and self.act.viewTemplates.pages[info.idx]
    if vt and vt.key then
        reuseCell.labelName:setString(Localize(vt.key))
    end

    return reuseCell
end

-- 数据
function ActivityMultiDialog:onUpdateRewardCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    if info[1] ~= reuseCell.displayIType or info[2] ~= reuseCell.displayIId then
        reuseCell.displayIType = info[1]
        reuseCell.displayIId = info[2]
        GameUI.setNormalIcon(reuseCell.itemBack, info)
        GameUI.registerTipsAction(reuseCell.itemBack, self.view, info[1], info[2])
    end
    reuseCell.labelName:setString(Localizef("labelNormalFormatX", {a=GameLogic.getItemName(info[1], info[2]), b=info[3]}))
    return reuseCell
end

function ActivityMultiDialog:onRefreshTable()
    if not self.deleted then
        local act = self.act
        local infos = {}
        local ioff = 0
        local srwd = self.context.activeData:getConfigableRwds(self.actId, 1)
        self.questionNode:setVisible(false)

        local vts = self.act.viewTemplates and self.act.viewTemplates.pages or {}
        if srwd.multiControl then
            local rewardRecord = self.context.activeData:getActRwd(self.actId, srwd.rwdId)
            if rewardRecord[1] > 0 then
                ioff = rewardRecord[1] * 3 - 2
            else
                local randoms = {}
                local randoms2 = {}
                local randoms3 = {}
                local _map2 = {}
                for _, hero in pairs(self.context.heroData:getAllHeros()) do
                    _map2[hero.hid] = 1
                end
                ioff = 2
                while true do
                    local rwd = self.context.activeData:getConfigableRwds(self.actId, ioff)
                    if rwd then
                        if vts[ioff] and vts[ioff].hid and not _map2[vts[ioff].hid] then
                            local hinfo = SData.getData("hinfos", vts[ioff].hid)
                            if (hinfo.displayColor or hinfo.rating or 0) >= 5 then
                                table.insert(randoms2, ioff)
                            else
                                table.insert(randoms, ioff)
                            end
                        end
                        table.insert(randoms3, ioff)
                        ioff = ioff + 3
                    else
                        break
                    end
                end
                local seed = act.actStartTime + self.context.uid + (act.actSeed or 0)
                local rd = RdUtil.new(seed)
                if #randoms == 0 then
                    randoms = randoms2
                end
                if #randoms == 0 then
                    randoms = randoms3
                end
                ioff = randoms[rd:randomInt(#randoms)]
                if not ioff then
                    ioff = 1
                else
                    ioff = ioff-1
                end
                self.questionNode:setVisible(true)
                self.btnQuestion:setVisible(true)
                self.__initGift = (ioff+2)/3
            end
        end
        for i=1, 3 do
            local rwd = self.context.activeData:getConfigableRwds(self.actId, i+ioff)
            local info = {percent=rwd.percent, discount=rwd.discount, maxCount=rwd.max}
            info.rewards = rwd.items
            info.nameKey = ""
            info.atype = rwd.atype
            info.costs = rwd.costs
            info.storeIdx = rwd.goodsid
            info.buyCount = self.context.activeData:getActRwd(self.actId, rwd.rwdId)[1]
            if info.buyCount > 0 then
                self.questionNode:setVisible(false)
            end
            info.idx = i+ioff
            table.insert(infos, info)
        end
        self.giftTableView:setLayoutDatas(infos)

        local vt = vts[1+ioff]
        if self.dontShow then
            vt = nil
        end
        if vt and vt.hid then
            self.btnHeroInfo:setVisible(true)
            self.btnHeroInfo:setScriptCallback(ButtonHandler(GameUI.showHeroDialog, const.ItemHero, vt.hid))

            local hinfo = SData.getData("hinfos", vt.hid)
            local hinfoNew = SData.getData("heroInfoNew", vt.hid)
            local word = ""
            if hinfoNew.giftWord then
                word = Localize(hinfoNew.giftWord)
            end
            word = Localizef("labelFormatGiftWord", {
                name=GameLogic.getItemName(const.ItemHero, vt.hid), word=word})
            local sound = nil
            display.showDialog(StoryDialog.new({customStory={{
                pid=vt.hid, pos=0, ptype=2, text=word, flip=hinfoNew.flip,
                adapt=2, hasSSR=(hinfo.displayColor == 5 and 5 or hinfo.rating),
                callback=Handler(function ()
                    local guankaId = SData.getData("heroInfoNew")[vt.hid].guankaId
                    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=2,ptype=true,
                    idx=guankaId,bparams={stage = const.HeroInfoNewTry, id = vt.hid, from="ActMulti",
                    initParams = {act = self.act, actId = self.actId, dontShow = true}}})
                end, self)
            }}}), true, true)
        else
            self.btnHeroInfo:setVisible(false)
        end
    end
end

function ActivityMultiDialog:onBuyGift(info)
    GameLogic.doActAction(self.context, self.actId, info.idx, self)
end

function ActivityMultiDialog:onTreasureAction(idx)
    local rwd = self.context.activeData:getConfigableRwds(self.actId, idx)
    GameLogic.doPurchaseLogic({storeIdx=rwd.goodsid or 1, dialog=self, callback=Handler(self.onPurchaseOver, self),
        preType=3, actId=self.actId, rwdIdx=idx})
end

function ActivityMultiDialog:onPurchaseOver(suc, data)
    if GameLogic.purchaseLock then
        self:onRefreshTable()
    end
end

return ActivityMultiDialog
