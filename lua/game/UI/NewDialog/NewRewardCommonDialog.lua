local RewardCommonDialog = class(ViewLayout)

local itemIconSize = 210

function RewardCommonDialog:onCreate()
	local setting = self._setting
    -- if setting then
    --     for k, v in pairs(setting) do
    --         if not self[k] then
    --             self[k] = v
    --         end
    --     end
    -- else
    --     self._setting = {}
    -- end
    -- dump(setting)
    self.priority = display.getDialogPri() + 1
    self:onInitData(setting)
    self:onInitUI()
    self:setSpecilAdapt()
    -- display.showDialog(self.view,true)

    -- music.play("sounds/obtain.mp3")
    -- local node = ui.csbNode("hulu.csb")
end

function RewardCommonDialog:onInitData(datas)
	-- self:initMockData(20)
	if self.mockItems then
		self.itemInfos = self.mockItems
	elseif datas then
        if not datas.rewards then
            self.itemInfos = datas
        else
		    self.itemInfos = datas.rewards;
        end
        self.closeCallBack = datas.callback
	end
end

function RewardCommonDialog:onInitUI()
	self:setLayout("getItem_dialog.json")
	self:loadViewsTo()
	if self.itemInfos and type(self.itemInfos) == "table" then
		self:onInitTableView()
	end
end

function RewardCommonDialog:onInitTableView()
	local itemNum = #self.itemInfos
	self.items = {}
	for i, info in pairs(self.itemInfos) do
		local item = self.layout_list:createItem(1)
		-- GameUI.addBagItemIcon(item, info, {x = 91, y = 91,isTips = true, tipsTarget = self.view})
		local resMode = info[1] or info.type
		local resID = info[2] or info.id 
		local resNum = info[3] or info.num
		local s = item:getContentSize()
		item:loadViewsTo()	
		print(resNum)
		-- GameUI.addItemIcon(item,resMode,resID,1,x = s[1]/2, y = s[2]/2)
		GameUI.addItemIcon(item,resMode,resID,1,0,0,nil,nil,{itemNum = resNum})
		self.items[i] = item
		self.layout_list:addChild(item)
	end
	if itemNum <= 5 then
		self.layout_list:setSize((itemIconSize) * itemNum - (3 - itemNum) * 80, itemIconSize + 150 * 2)
	elseif itemNum > 5  then
		self.layout_list:setSize((itemIconSize) * 5 + 180, (itemIconSize + 180) * 2)
	end

	self.layout_list:resetLayout()


	self.layout_list:setVisible(false)
	-- self.panel_reward_word:setVisible(false)

	-- local panelWordLabel = ui.label("获得物品", General.font3, 160, {color = {0xf9, 0xda, 0x7f}, outColor = {0x4f, 0x24, 0x12}})
	-- display.adapt(panelWordLabel, 500, 100, GConst.Anchor.Center)
	-- panelWordLabel:setScale(1,2.5)
	-- panelWordLabel:setOpacity(0)
	-- self.rewardWord:addChild(panelWordLabel)

	local function showItem()
		-- self.layout_list:setScale(0.5, 0.5)
		self.layout_list:setVisible(true)
        local children = self.layout_list.children or {}
		for _, child in pairs(children) do
			local sx, sy = child:getScale()
			child:setScale(0.5, 0.5)
			local action = ui.action.sequence({
												{"scaleTo", 0.2, sx + 0.1, sy + 0.1},
												{"scaleTo", 0.2, sx - 0.2, sy - 0.2},
												{"scaleTo", 0.2, sx, sy}
												})
			child:runAction(action)
		end
	end

	showItem()
	-- local action = ui.action.spawn({{"fadeTo", 1.5, 255}, {"sequence", {{"delay",20/60},{"show"},{"scaleTo",15/60,1.1,1.1},{"scaleTo",10/60,1.3,1.3},{"call", showItem},{"scaleTo",10/60,1.0,1.0}}}})
	-- panelWordLabel:runAction(action)

end

function RewardCommonDialog:updateItemCell()

end

function RewardCommonDialog:checkAndUpdateUI()

end

function RewardCommonDialog:setSpecilAdapt()
	display.adapt(self.view, 0, 0, GConst.Anchor.Center,{isTest = true, datum = GConst.Anchor.Center,scaleType = GConst.Scale.Width})
end

function RewardCommonDialog:canExit()
	if self.aniSid then
		GMethod.unschedule(self.aniSid)
		self.aniSid = nil
	end
	return true
end

function RewardCommonDialog:initMockData(num)
	local iteminfo = {
		{
			itypes = 1,
			itemids = 3011,
			itempid = 110,
			isequip = false,
			inums = 50,
			selected = false
		},
		{
			itypes = 2,
			itemids = 4,
			itempid = 151,
			isequip = false,
			inums = 50,
			selected = false
		},
		{
			itypes = 2,
			itemids = 1,
			itempid = 148,
			isequip = false,
			inums = 50,
			selected = false
		},
		{
			itypes = 1,
			itemids = 3027,
			itempid = 126,
			isequip = false,
			inums = 50,
			selected = false
		},
		{
			itypes = 1,
			itemids = 3012,
			itempid = 111,
			isequip = false,
			inums = 50,
			selected = false
		},
	}
	local itemsNum = num or 1
	self.mockItems = {}
	for i = 1, itemsNum do
		local info = {}
		local j = (i % 5) + 1
		local item = iteminfo[j]
		for k, v in pairs(item) do
			info[k] = v
		end
		table.insert(self.mockItems, info)
	end
end

function RewardCommonDialog:autoCloseCallback(dialog)
	if dialog and dialog.closeCallBack then
		self:closeCallBack()
	end
end

return RewardCommonDialog
