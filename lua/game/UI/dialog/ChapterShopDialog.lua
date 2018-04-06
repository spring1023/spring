local const = GMethod.loadScript("game.GameLogic.Const")
local SD = GMethod.loadScript("data.StaticData").getData
--章节商店对话框
local ChapterShopDialog = class2("ChapterShopDialog",function()
    return BaseView.new("ChapterShopDialog.json")
end)

function ChapterShopDialog:ctor(idx,params,callback)
    self.idx,self.params,self.callback = idx,params,callback
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function ChapterShopDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:loadView("views")
    self:initRewardViews()
    self:loadView("sureButton")
    local function showAlreadyBuy()
        viewTab.butSure:removeFromParent(true)
        self:loadView("alreadyBuyView")
        if self.callback then
            self.callback()
        end
    end
    viewTab.titleChapterShop:setString(Localize("dataPvjBoxName" .. self.idx))
    viewTab.butSure:setListener(function()
        local otherSetting = {ctype = const.ResCrystal,cvalue = const.PvjStoreCost[self.idx],callback = function()
            showAlreadyBuy()
            self:buypvjshop()
        end}
        local dl = AlertDialog.new(1,Localize("alertTitleNormal"),Localize("stirngNormalAlert"),otherSetting)
        display.showDialog(dl)
    end)
    viewTab.btnSureCrystal:setString(const.PvjStoreCost[self.idx])
    if GameLogic.getUserContext():getRes(const.ResCrystal)<const.PvjStoreCost[self.idx] then
        ui.setColor(viewTab.btnSureCrystal,"red")
    end
    if self.params.shops[self.idx] and self.params.shops[self.idx][3] == 1 then
        showAlreadyBuy()
    end
    self.cost = const.PvjStoreCost[self.idx]
    viewTab.labelGetItemTips:setString(Localizef("labelGetItemTips",{num = self.cost}))
end
function ChapterShopDialog:initRewardViews()
	local pos={{103,894},{679,894},{103,672},{679,672},{103,450},{679,450},{103,229},{679,229}}
	local bg,temp
    local giftContent = SD("pvjstore",self.idx)
    self.giftContent = giftContent
    local i = 0
	for k,v in pairs(giftContent) do
        i=i+1
		bg = ui.node()
        display.adapt(bg,pos[i][1],pos[i][2], GConst.Anchor.LeftBottom)
        self:addChild(bg)
        --添加物品
        GameUI.addItemIcon(bg,v.itemtype,v.itemid,1,100,100,true)
        --物品名称
        local name = GameLogic.getItemName(v.itemtype,v.itemid)

        temp = ui.label(StringManager.getString(name), General.font1, 45, {color={255,255,255}})
		display.adapt(temp, 222, 183, GConst.Anchor.LeftTop)
		bg:addChild(temp)
		temp = ui.label(StringManager.getString("x"..v.itemnum), General.font1, 45, {color={255,255,255}})
		display.adapt(temp, 222, 115, GConst.Anchor.LeftTop)
		bg:addChild(temp)
	end
end

----------------------------------------------------------------------
function ChapterShopDialog:buypvjshop()
    music.play("sounds/buy.mp3")
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdPvjBShop,self.idx})
    local reward = {}
    local i = 0
    for k,v in pairs(self.giftContent) do
        i = i+1
        reward[i] = {v.itemtype,v.itemid,v.itemnum}
    end
    GameLogic.addRewards(reward)
    GameLogic.getUserContext():changeRes(const.ResCrystal,-self.cost)
    GameLogic.statCrystalCost("僵尸来袭章节商店购买资源消耗",const.ResCrystal,-self.cost)
    self.params.shops[self.idx] = {self.idx,1,1}
end


return ChapterShopDialog
