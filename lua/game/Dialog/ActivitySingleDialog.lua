local ActivitySingleDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")

function ActivitySingleDialog:onInitDialog()
    self:setLayout("ActivitySingleDialog.json")
    self.view:setPositionY(self.view:getPositionY() - 30 * self.view:getScaleY())
end

function ActivitySingleDialog:onEnter()
    self:initUI()
    self:initData()
    ActivityLogic.checkActNew(self.actId, self.act, true)
end

function ActivitySingleDialog:initUI()
    local title = Localize(self.act.menuName or self.act.actLeftTitle or self.act.actTitle or ("actName" .. self.actId))
    self.title:setString(title)
    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    local tmp = ui.node()
    GameEvent.bindEvent(tmp, "refreshEggDialog", self, self.onRefreshData)
    self.view:addChild(tmp)
end

function ActivitySingleDialog:onRefreshData()
    if not ActivityLogic.checkActVisible(self.act) and not self.deleted then
        display.closeDialog(self.priority)
    end
end

function ActivitySingleDialog:onPurchaseOver()
    if not self.deleted then
        if GameLogic.purchaseLock or self.context.activeData:checkPurchaseLimit(self.actId, 1) then
            self.nodeBuyLong.btnBuy:setGray(true)
        else
            self.nodeBuyLong.btnBuy:setGray(false)
        end
    end
end
-- 数据
function ActivitySingleDialog:initData()
    local rwd = self.context.activeData:getConfigableRwds(self.actId, 1)
    -- 先不写逻辑了，把界面加出来吧
    if rwd.atype == 2 then
        self.nodeBuyLong:lazyload()
        local percent = rwd.percent or 100
        if rwd.discount then
            percent = 10000 / rwd.discount
        end
        local product = Plugins.storeKeys[rwd.goodsid or 1]
        local newPriceNum = Plugins.storeItems[product]
        local newPriceSafe = Plugins.storeItemsSafe[product]
        local newPrice = GameLogic.getOldPrice(newPriceNum, 100, newPriceSafe)
        local oldPrice = GameLogic.getOldPrice(newPriceNum, percent, newPriceSafe)

        self.nodeBuyLong.labelLeftPrice:setString(oldPrice)
        self.nodeBuyLong.labelRightPrice:setString(newPrice)
        self.nodeBuyLong.labelPercent:setString(math.floor(percent + 0.5) .. "%")
        self.nodeBuyLong.btnBuy:setScriptCallback(ButtonHandler(GameLogic.doPurchaseLogic,
            {storeIdx=rwd.goodsid or 1, dialog=self, preType=3, actId=self.actId, rwdIdx=1, button=self.nodeBuyLong.btnBuy}))
        -- if GameLogic.purchaseLock or self.context.activeData:checkPurchaseLimit(self.actId, 1) then
        --     self.nodeBuyLong.btnBuy:setGray(true)
        -- end
    end
    local vt = self.act.viewTemplates
    if vt.left == "cityMode" then
        local item = self.leftNode:createItemWithId("cityGift")
        self.leftNode:addChild(item)
    elseif vt.left == "expMode" then
        local item = self.leftNode:createItemWithId("expGift")
        self.leftNode:addChild(item)
    elseif type(vt.left) == "number" then
        local hinfoNew = SData.getData("heroInfoNew", vt.left)
        GameUI.addHeroFeature(self.leftNode, vt.left, 1, self.leftNode.size[1]/2+45,
            self.leftNode.size[2]/2+20, 0, true, 0, hinfoNew.flip==1)
    end
    self.pageId = 1

    ActivityLogic.loadPageViewTemplates(self.view, self, self, vt)
    -- self.labelDesc:setString(Localize("labelDesc" .. self.actId))
    ViewTemplates.setImplements(self.itemTable, "LayoutImplement", {callback=Handler(self.onUpdateNormalItem, self), withIdx=false})
    self.itemTable:setLayoutDatas(rwd.items)
end

function ActivitySingleDialog:onUpdateNormalItem(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    GameUI.setNormalIcon(reuseCell, info, false, true)
    GameUI.registerTipsAction(reuseCell, self.view, info[1], info[2])
    return reuseCell
end

return ActivitySingleDialog
