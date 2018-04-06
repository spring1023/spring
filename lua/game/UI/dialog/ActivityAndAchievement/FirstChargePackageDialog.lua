local FirstChargePackageDialog = class(DialogViewLayout)
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

function FirstChargePackageDialog:onInitDialog()
    self.context = GameLogic.getUserContext()
    self:initUI()
    self:initData()
    GEngine.setConfig("OpenFirstCharge"..GameLogic.getUserContext().uid,1,false)
    self.view:setPositionY(self.view:getPositionY() - 30 * self.view:getScaleY())
end

function FirstChargePackageDialog:initUI()
    self:setLayout("FirstChargePackageDialog.json")
    self:loadViewsTo()
    self.title:setString(Localize("titleFirstChargePackage"))
    self.lab_desc:setString(Localize("labelChargeTips"))
    self.lab_clickPlay:setString(Localize("labelClickTry"))
    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.btn_clickPlay:setScriptCallback(ButtonHandler(self.OnDemoClick, self))

    ViewTemplates.setImplements(self.layout, "LayoutImplement", {callback=Handler(self.onUpdateItemsCell, self), withIdx=false})
    self:eventBack()
end

function FirstChargePackageDialog:initData()
    self:showReward()
    local cellSize = self.node_heroFeature.size
    GameUI.addHeroFeature(self.node_heroFeature, self.heroId, 0.8, cellSize[1]/2, cellSize[2]/2, 0, true)
    self.data = self:getAllInfoData()
    local bNode=ui.node()
    self:addChild(bNode)
    GameEvent.bindEvent(bNode, "FirstPackage", self, self.eventBack)
    local discount = SData.getData("firstCharge", 1)
    --TODO 获取当前国家的最小钻石购买项的价格newPriceNum,暂时写成6
    local firstProduct = GameLogic.getFirstPurchase()
    local newPriceNum = Plugins.storeItems[firstProduct]
    local newPriceSafe = Plugins.storeItemsSafe[firstProduct]
    self._firstBuyItem = firstProduct
    local newPrice = GameLogic.getOldPrice(newPriceNum, 100, newPriceSafe)
    local oldPrice = GameLogic.getOldPrice(newPriceNum, discount*100, newPriceSafe)
    self.labelPercent:setString((discount*100).."%")
    self.labelLeftPrice:setString(oldPrice)
    self.labelRightPrice:setString(newPrice)
end

function FirstChargePackageDialog:showReward()
    local rwds = {}
    local infosFinReward = {}
    local rewardConfig = SData.getData("activeReward")
    for i,v in ipairs(rewardConfig) do
        if v.atype == 51 then
            table.insert(rwds,v)
        end
    end
    for i=1,#rwds do
        local rwd = rwds[i]
        if rwd.gtype == 9 then
            self.heroId = rwd.gid
        end
        table.insert(infosFinReward, {resMode = rwd.gtype, resID = rwd.gid, resNum = rwd.gnum})
    end
    self.layout:setLayoutDatas(infosFinReward)
end

function FirstChargePackageDialog:onUpdateItemsCell(reuseCell, layout, item)
    if not reuseCell then
        reuseCell = layout:createItem(1)
        reuseCell:loadViewsTo()
    end
    if item.resID ~= reuseCell.displayId or item.resMode ~= reuseCell.displayMode then
        reuseCell.displayMode = item.resMode
        reuseCell.displayId = item.resID
        reuseCell.itemPic:removeAllChildren()
        local cellSize = reuseCell.itemPic.size
        GameUI.addItemIcon(reuseCell.itemPic, item.resMode, item.resID, cellSize[2]/200,cellSize[1]/2, cellSize[2]/2, true, false)
        GameUI.registerTipsAction(reuseCell, self.view, item.resMode,  item.resID)
    end
    reuseCell.itemNum:setString("X"..item.resNum)
    return reuseCell
end

function FirstChargePackageDialog:getAllInfoData()
    local allData = SData.getData("heroInfoNew")
    local data = {}
    for k,v in KTPairs(allData) do
        if not data[k] then
            data[k] = {}
        end
        data[k] = v
    end
    return data
end

function FirstChargePackageDialog:OnDemoClick()
    --点击试玩
    local guankaId=self.data[self.heroId].guankaId
    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=2,ptype=true,idx=guankaId,bparams={stage = const.HeroInfoNewTry, id = self.heroId, from="FirstCharge"}})
end

function FirstChargePackageDialog:eventBack()
    if self.deleted then
        return
    end
    local data = GameLogic.getUserContext().activeData.dhActive[51]
    local isReceive = (data and data[3]>=1 or false)
    if isReceive ~= self.isReceive then
        self.isReceive = isReceive
        if isReceive then
            self.nodeReceive:setVisible(true)
            self.nodeBuyLong:setVisible(false)
            self.btnReceive.view:setBackgroundSound("sounds/receive.mp3")
            self.btnReceive:setScriptCallback(ButtonHandler(self.onReceive, self))
        else
            self.nodeReceive:setVisible(false)
            self.nodeBuyLong:setVisible(true)
            self.btnBuy:setScriptCallback(ButtonHandler(self.onBuy, self))
        end
    end
end

function FirstChargePackageDialog:onBuy()
    GameLogic.doPurchaseLogic({product=self._firstBuyItem, dialog=self, preType=4, actId=0, button=self.btnBuy})
end

function FirstChargePackageDialog:onReceive()
    GameLogic.getactreward(51,1,function()
        if not self.deleted then
            if self.callback then
                self.callback()
            end
            display.closeDialog(self.priority)
        end
    end)
end

return FirstChargePackageDialog
