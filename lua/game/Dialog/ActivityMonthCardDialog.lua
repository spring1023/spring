local ActivityMonthCardDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")

function ActivityMonthCardDialog:onInitDialog()
    self:setLayout("ActivityMonthCardDialog.json")
    self.view:setPositionY(self.view:getPositionY() - 30 * self.view:getScaleY())
end

function ActivityMonthCardDialog:onEnter()
    self:initUI()
    self:initData()
    ActivityLogic.checkActNew(self.actId, self.act, true)
end

function ActivityMonthCardDialog:initUI()
    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))

    GameUI.addHeroFeature(self.leftNode, 4019, self.leftNode.size[1]/690, self.leftNode.size[1]/2,
        self.leftNode.size[2]/2, 0, true):setFlippedX(true)
    memory.loadSpriteSheetRelease("images/rankNums.plist", true)

    local tmp = ui.node()
    GameEvent.bindEvent(tmp, "refreshEggDialog", self, self.onRefreshData)
    self.view:addChild(tmp)
end

function ActivityMonthCardDialog:onRefreshData()
    if not ActivityLogic.checkActVisible(self.act) and not self.deleted then
        display.closeDialog(self.priority)
    end
end

function ActivityMonthCardDialog:onPurchaseOver()
    if not self.deleted then
        if GameLogic.purchaseLock then
            self.btnBuy:setGray(true)
        else
            self.btnBuy:setGray(false)
        end
    end
end

-- 数据
function ActivityMonthCardDialog:initData()
    local rwd = self.context.activeData:getConfigableRwds(self.actId, 1)
    -- 先不写逻辑了，把界面加出来吧
    local product = Plugins.storeKeys[7]
    local newPriceNum = Plugins.storeItems[product]
    local newPriceSafe = Plugins.storeItemsSafe[product]
    local newPrice = GameLogic.getOldPrice(newPriceNum, 100, newPriceSafe)

    local percent = rwd.percent or 100
    if rwd.discount then
        percent = 10000 / rwd.percent
    end
    local oldPrice = GameLogic.getOldPrice(newPriceNum, percent, newPriceSafe)

    self.labelLeftPrice:setString(oldPrice)
    self.labelRightPrice:setString(newPrice)
        -- self.nodeBuyLong.labelPercent:setString(((rwd.discount or 1) * 100) .. "%")
    self.btnBuy:setScriptCallback(ButtonHandler(GameLogic.doPurchaseLogic,
            {storeIdx=7, dialog=self, preType=0, actId=0, rwdIdx=0, button=self.btnBuy}))
    if GameLogic.purchaseLock then
        self.btnBuy:setGray(true)
    end
    GameUI.setRankNumber(self.btnNumber, rwd.showNum or 13400)
end

return ActivityMonthCardDialog
