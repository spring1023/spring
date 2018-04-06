WorshipToViewRewardDialog = class(DialogViewLayout)
local SData = GMethod.loadScript("data.StaticData")
function WorshipToViewRewardDialog:onInitDialog()
	self:setLayout("WorshipToViewRewardDialog.json")
    self:loadViewsTo()
    --帮助的文本
    --self.questionTag = "unionApplyLog"
    self.context = GameLogic.getUserContext()
    self:showUI()
end
function WorshipToViewRewardDialog:showUI()
	-- body
	--local data = self.params
	self.worshiplatitle:setString(Localize("labelWorshipLATitle"))
	self.pNode:removeAllChildren(true)
	local info={}
	local data = SData.getData("preWorship")

	for k,v in ipairs(data) do
		local minValue = v.number
		local maxValue = minValue
		if minValue and v.rwds then
			local nextData = data[k+1]			
			if nextData and nextData.number then
				maxValue = nextData.number-1
			end
			local rws = {}
			for i,j in ipairs(v.rwds) do
				table.insert(rws,{data=j})
			end
			table.insert(info,{item={min=minValue,max=maxValue,rws=rws}})
		end		
	end
	local tabelView = GameUI.helpLoadTableView(self.pNode,info,Handler(self.cellCallBack,self))
	tabelView.view:setTouchThrowProperty(true,true)
end
function WorshipToViewRewardDialog:cellCallBack(cell, tableView, info)
	-- body
	if not info.viewLayout then
        info.viewLayout = self:addLayout("pScrollNode",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        info.view = cell
        --人次
        if info.item.max ==info.item.min then
        	info.piecewiseLabel:setString(info.item.max..Localize("labelPeopleNum")..Localize("labelAbove"))
        else
			info.piecewiseLabel:setString(info.item.min.."~"..info.item.max..Localize("labelPeopleNum"))
		end
		info.sNode:removeAllChildren(true)
		local tabelView = GameUI.helpLoadTableView(info.sNode,info.item.rws,Handler(self.cell1CallBack,self))
    	tabelView.view:setTouchThrowProperty(true,true)
    end
end

function WorshipToViewRewardDialog:cell1CallBack(cell, tableView, info)
	-- body
	 if not info.viewLayout then
        info.viewLayout = self:addLayout("sScrollNode",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        info.view = cell
        local cellSize = cell:getContentSize()
        GameUI.addItemIcon(info.cellNode,info.data[1],info.data[2],cellSize.height/200,cellSize.width/2,cellSize.height/2-20,true,false,{itemNum = info.data[3]})
    end
end