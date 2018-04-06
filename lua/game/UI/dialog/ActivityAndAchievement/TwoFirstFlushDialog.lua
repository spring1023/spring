-- 二次首冲礼包
local TwoFirstFlushDialog = class2("TwoFirstFlushDialog",function()
    return BaseView.new("TwoFirstFlushDialog.json")
end)

function TwoFirstFlushDialog:ctor(actId)
	if not actId then
    	return
    end
    self.context = GameLogic.getUserContext()
    self.dialogDepth=display.getDialogPri()+1
    self.id = actId    
    self:initData()
    self:findShowTime()
    self:initUI()
    self:updateBtnUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
    local bNode=ui.node()
    self:addChild(bNode)
    GameEvent.bindEvent(bNode, Event.EventDialogClose, self, self.updateBtnUI)
end
function TwoFirstFlushDialog:initData()
	-- body
	self.info = self:getRewordData()
	self:loadView("centerViews")
    self.viewTab=self:getViewTab()
end
function TwoFirstFlushDialog:initUI()
	self.viewTab.butClose:setScriptCallback(ButtonHandler(function ()
		-- body
		display.closeDialog(self.priority)
	end,self))
	GameUI.addHeroFeature(self.viewTab.heroFerture, 4014, 1.0, 0, 0, 0, true)
    self.viewTab.title:setString(Localize("labelLimitBossTitle"))
	self.viewTab.labelDesc:setString(Localize("labelTwoChargeTips"))
    for k,v in ipairs(self.info) do
        local itemNode=ui.node()
        display.adapt(itemNode, k*220, 0, GConst.Anchor.LeftBottom)
        self.viewTab.scrollNode:addChild(itemNode)
        local temp = ui.sprite("images/energyBlockBack.png", {200, 200})
	    display.adapt(temp, 150, 150, GConst.Anchor.Center)
	    itemNode:addChild(temp)
	    GameUI.addItemIcon(itemNode,v.item[1],v.item[2],1,150,150,true,false)
	    local labelItemx = ui.label("",1,42)
        display.adapt(labelItemx, 240,70, GConst.Anchor.Right)
        itemNode:addChild(labelItemx)
        labelItemx:setString("X" .. v.item[3])
    end
end
function TwoFirstFlushDialog:getRewordData()
	local allItem = self.context.activeData:getConfigableRwds(self.id, 1)
	local infos = {}
	for i, item in KTIPairs(allItem.items) do
        infos[i] = {idx=i, item=item}
    end
    return infos
end

function TwoFirstFlushDialog:findShowTime()
	local actsData = GameLogic.getUserContext().activeData:getConfigableActs()
	if actsData and next(actsData) and actsData[self.id] then
		local time = GameLogic.getSTime()
		local stime = actsData[self.id].actEndTime - time
		if stime<=0 then
			self.time = 0
			self.viewTab.labelLeftTime:setVisible(false)
		else
			self.time = stime
			self.viewTab.labelLeftTime:setString(Localize("labelActRemainTime")..Localizet(self.time))
		end
	end
end

function TwoFirstFlushDialog:updateBtnUI()	
	local str = ""
	local isOpen = false
	local state = self.context.activeData:checkActRewardState(self.id, 1)
	if state == GameLogic.States.Finished then
		str = Localize("btnReceive")
		isOpen = true
	else
		str = Localize("buttonGo")	
		isOpen = false	
	end
	self.viewTab.btnLabel:setString(str)
	self.viewTab.btnBuy:setScriptCallback(ButtonHandler(function ()
		-- body
		if isOpen then
			print(self.id)
			GameLogic.doActAction(self.context, self.id, 1, self)
			display.closeDialog(self.priority)
		else
			StoreDialog.new(1)
		end			
	end,self))	
end

return TwoFirstFlushDialog
