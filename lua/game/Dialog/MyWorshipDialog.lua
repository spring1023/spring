MyWorshipDialog = class(DialogViewLayout)
local SData = GMethod.loadScript("data.StaticData")
function MyWorshipDialog:onInitDialog()
	self:setLayout("MyWorshipDialog.json")
    self:loadViewsTo()
    --帮助的文本
    self.questionTag = "unionApplyLog"
    self.context = GameLogic.getUserContext()
    self:showUI()
end


function MyWorshipDialog:showUI()
	-- body
	local info={}
	local data = SData.getData("preWorship")
	self.sNode:removeAllChildren(true)
	local peopleNum = self.setting.pNum or 0
	if peopleNum >= data[1].number then
		for k,v in ipairs(data) do
			if next(info) then
				break
			end
			local nextData = data[k+1]
			if nextData and nextData.number then
				if peopleNum < nextData.number then
					for i,j in ipairs(v.rwds) do
						table.insert(info,{data=j})
					end
				end
			else
				if peopleNum >= v.number then
					for i,j in ipairs(v.rwds) do
						table.insert(info,{data=j})
					end
				end
			end
		end
	end
	self:updateUI()
	if next(info) then
		self.noWorshipInfo:setVisible(false)
	end
	GameUI.helpLoadTableView(self.sNode,info,Handler(self.cellCallBack,self))
end
function MyWorshipDialog:updateUI()
	--查看奖励
	self.BtnLabel:setString(Localize("labelLookReward"))
	--奖励说明
	self.labelinfo:setString(Localize("labelWorshipedEmail"))
	--今日膜拜
	self.labelday:setString(Localize("labelToDayWorshipedNum"))
	--人次
	self.labelNum:setString(self.setting.pNum or 0)
	--查看奖励
	self.BtnOk:setScriptCallback(ButtonHandler(function ()
		display.closeDialog(self.priority)
		display.showDialog(WorshipToViewRewardDialog.new())
		end))
	self.noWorshipInfo:setString(Localize("labelNoWorshipInfo"))
end

function MyWorshipDialog:cellCallBack(cell, tableView, info)
	-- body	
	 if not info.viewLayout then
        info.viewLayout = self:addLayout("scrollNode",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        info.view = cell
        local cellSize = cell:getContentSize()
        GameUI.addItemIcon(info.view,info.data[1],info.data[2],cellSize.height/200,cellSize.width/2,cellSize.height/2-30,true,false,{itemNum = info.data[3]})
    end
end

