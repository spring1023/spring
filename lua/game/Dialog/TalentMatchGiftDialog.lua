local TalentMatchGiftDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")
local GameSetting = GMethod.loadScript("game.GameSetting")

function TalentMatchGiftDialog:onInitDialog()
    self:setLayout("ActivityMultiGiftDialog.json")
end

function TalentMatchGiftDialog:onEnter()
    self.heroShowed = false
    self:initUI()
    self:initData()
end

function TalentMatchGiftDialog:initUI()
    self.title:setString(Localize("labelTMGift"))
    self.btnCloseBack:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.questionNode:setVisible(true)
    self.btnQuestion:setScriptCallback(ButtonHandler(self.onMoreGift, self))
    ViewTemplates.setImplements(self.giftTableView, "LayoutImplement", {callback=Handler(self.onUpdateGiftCell, self), withIdx=false})
end

function TalentMatchGiftDialog:onMoreGift()
    display.sendIntent({class="game.Dialog.TalentMatchMoreGiftDialog", params={ainfo=self.ainfo}})
end

function TalentMatchGiftDialog:onUpdate(diff)
    local leftTime = self.__endTime - GameLogic.getSTime()
    if leftTime < 0 then
        display.closeDialog(self.priority)
    else
        self.labelLeftTime:setString(StringManager.getFormatTime(leftTime))
    end
end

function TalentMatchGiftDialog:initData()
    self.context.talentMatch:getMatchNow(self.ainfo.aid, Handler(self.onInitData, self))
    local endTime = self.ainfo.etime --matchData.actEndTime or
    self.__endTime = endTime
    RegTimeUpdate(self.labelLeftTime.view, Handler(self.onUpdate, self), 0.5)
    self:onUpdate(0)
    local tmp = ui.node()
    GameEvent.bindEvent(tmp, "TalentMatchGift", self, self.onRefreshTable)
    self.view:addChild(tmp)
end

function TalentMatchGiftDialog:onInitData(matchData)
    if not self.deleted and matchData then
        -- 没有则自动触发；放在这里面触发
        if matchData.triggleActId == 0 then
            self.context.talentMatch:addTriggerGift(self.ainfo.aid)
        end
        self:onRefreshTable()

        local redNumCache = GameSetting.getLocalData(self.context.uid, "RedNums") or {}
        if (redNumCache["TM" .. self.ainfo.aid] or 0) < self.ainfo.stime then
            redNumCache["TM" .. self.ainfo.aid] = self.ainfo.stime + 1
            GameSetting.setLocalData(self.context.uid, "RedNums", redNumCache)
            GameEvent.sendEvent("isClickPackage")
        end
    end
end

-- 数据
function TalentMatchGiftDialog:onUpdateGiftCell(reuseCell, tableView, info)
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
    else
        reuseCell.nodePercent:setVisible(false)
        reuseCell.labelName:setPositionX(287.5)
    end
    reuseCell.labelName:setString(Localize(info.nameKey))
    ViewTemplates.setImplements(reuseCell.itemLayout, "LayoutImplement", {callback=Handler(self.onUpdateRewardCell, self), withIdx=false})
    reuseCell.itemLayout:setLayoutDatas(info.rewards)
    reuseCell.btnGo:setScriptCallback(ButtonHandler(self.onBuyGift, self, info))
    reuseCell.labelLeftPrice:setString(tostring(math.floor(info.cost * incPercent / 100)))
    GameUI.setNormalIcon(reuseCell.iconLeftPrice, {const.ItemRes, const.ResCrystal}, true)

    GameUI.addRedLine(reuseCell.layoutSale, true)

    reuseCell.labelRightPrice:setString(tostring(math.floor(info.cost)))
    GameUI.setNormalIcon(reuseCell.iconRightPrice, {const.ItemRes, const.ResCrystal}, true)
    -- reuseCell.labelPrice:setString(Plugins.storeItems[Plugins.storeKeys[info.storeIdx]])
    if info.buyCount >= info.maxCount then
        reuseCell.btnGo:setGray(true)
    else
        reuseCell.btnGo:setGray(false)
    end
    reuseCell.labelLeftChance:setString(Localizef("actRightSum170416", {a=info.maxCount-info.buyCount, b=info.maxCount}))
    -- if info.buyCount >= info.maxCount then
    --     reuseCell.labelLeftChance:setColor(187, 35, 35)
    -- else
    --     reuseCell.labelLeftChance:setColor(116, 227, 42)
    -- end
    return reuseCell
end

-- 数据
function TalentMatchGiftDialog:onUpdateRewardCell(reuseCell, tableView, info)
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

function TalentMatchGiftDialog:onRefreshTable()
    if not self.deleted then
        local matchData = self.context.talentMatch:getMatchNow(self.ainfo.aid)
        local infos = {}
        local buyMask = matchData.actBuyMask or 0
        -- 等数据中
        local giftId1 = math.floor(matchData.triggleActId / 10)
        local giftId2 = matchData.triggleActId % 10
        local gift = SData.getData("tmPack", giftId1, giftId2)
        for i=1, 3 do
            local ginfo = SData.getData("heroPack", gift.packId, i)
            local info = {percent=ginfo.percent, cost=ginfo.cost, nameKey=ginfo.nameKey, maxCount=ginfo.max}
            info.rewards = ginfo.rwds
            info.buyCount = buyMask % 10
            info.realGiftId = matchData.triggleActId * 100 + i
            info.idx = i
            buyMask = math.floor(buyMask/10)
            table.insert(infos, info)
        end
        self.giftTableView:setLayoutDatas(infos)

        local showData, _map2 = self.context.talentMatch:getRecommendData(self.ainfo.aid)
        local hasMore = false
        for _, hid in ipairs(showData.hids) do
            local sdata = SData.getData("tmPack", hid, giftId2)
            if sdata and sdata.isOpen == 1 and hid ~= giftId1 then
                hasMore = true
                break
            end
        end
        if matchData.actBuyMask > 0 or not hasMore then
            self.questionNode:setVisible(false)
        end
        self.btnHeroInfo:setVisible(true)
        self.btnHeroInfo:setScriptCallback(ButtonHandler(GameUI.showHeroDialog, const.ItemHero, giftId1))
        self.labelNoticeOther:setString(Localizef("labelTipsItems",{a=self.context:getItem(const.ItemFragment, giftId1),b=1500}))
        if self.heroShowed ~= giftId1 and not self.dontShow then
            self.heroShowed = giftId1
            local hinfo = SData.getData("hinfos", giftId1)
            local hinfoNew = SData.getData("heroInfoNew", giftId1)
            local word = ""
            if hinfoNew.giftWord then
                word = Localize(hinfoNew.giftWord)
            end
            word = Localizef("labelFormatGiftWord", {
                name=GameLogic.getItemName(const.ItemHero, giftId1), word=word})
            local sound = nil
            display.showDialog(StoryDialog.new({customStory={{
                pid=giftId1, pos=0, ptype=2, text=word, flip=hinfoNew.flip,
                adapt=2, hasSSR=(hinfo.displayColor == 5 and 5 or hinfo.rating),
                callback=Handler(function ()
                    local guankaId = SData.getData("heroInfoNew")[giftId1].guankaId
                    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=2,ptype=true,
                    idx=guankaId,bparams={stage = const.HeroInfoNewTry, id = giftId1, from="tmGift",
                    initParams={ainfo=self.ainfo,dontShow = true}}})
                end, self)
            }}}), true, true)
        end
    end
end

function TalentMatchGiftDialog:onBuyGift(info, force)
    local matchData = self.context.talentMatch:getMatchNow(self.ainfo.aid)
    if not matchData or info.buyCount >= info.maxCount then
        display.pushNotice(Localize("labelBuyTimeNoEnough"))
        return
    end
    if not force then
        local dialog = AlertDialog.new(1, Localize("alertTitleNormal"), Localize("alertTextBuyGift"),
            {ctype=const.ResCrystal, cvalue=info.cost, callback=Handler(self.onBuyGift, self, info, true)})
        display.showDialog(dialog)
        return
    end
    if self.context:getProperty(const.ProCrystal) < info.cost then
        display.showDialog(AlertDialog.new)
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end

    -- GameLogic.doPurchaseLogic({storeIdx=info.storeIdx, callback=Handler(self.onPurchaseOver, self),
    --     preType=5, actId=self.ainfo.aid, rwdIdx=info.realGiftId
    GameNetwork.request("tmgift", {aid=self.ainfo.aid, giftId=info.realGiftId}, self.onPurchaseOver, self)
end

function TalentMatchGiftDialog:onPurchaseOver(suc, data)
    GameNetwork.unlockRequest()
    if data.code == 0 then
        if data.rwds then
            GameLogic.addRewards(data.costs)
            GameLogic.addRewards(data.rwds)
            GameLogic.getUserContext().talentMatch:updateMatchPurchase(data.matchId, data.giftId)
            GameLogic.showHeroRewsUieffect(data.rwds)
            GameLogic.showGet(data.rwds)
            if not self.deleted then
                self:onRefreshTable()
            end
        end
    elseif data.code == 3 then
        display.pushNotice(Localize("activeTimeOver"))
        -- 显示错误提示
    else
        display.pushNotice(Localize("noticeReceiveFail" .. data.code))
    end
end

return TalentMatchGiftDialog
