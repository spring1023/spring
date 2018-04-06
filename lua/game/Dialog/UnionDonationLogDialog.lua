UnionDonationLogDialog = class(DialogViewLayout)
function UnionDonationLogDialog:onInitDialog()
	self:setLayout("UnionDonationLogDialog.json")
    self:loadViewsTo()
    self.title:setString(Localize("btnDonationLogLabel"))
    self:showUI()
end
function UnionDonationLogDialog:showUI()
	-- body
	local allinfo = {}
	self.rankId = 0
	for k,v in ipairs(self.params) do
		if v.donate > 0 then
			local info = {
				icon = v.icon,
				level = v.lv,
				name = v.name,
				vip = v.vip,
				job = v.job,
				power = v.power,
				donationNum = v.donate
			}
			table.insert(allinfo,info)
		end
	end
	table.sort(allinfo,function (a,b)
		return a["donationNum"] > b["donationNum"]
	end)
	if next(allinfo) then
		GameUI.helpLoadTableView(self.sNode,allinfo,Handler(self.cellCallBack,self))
	else
		display.pushNotice(Localize("labelDonationTip"))
	end
end

function UnionDonationLogDialog:cellCallBack(cell, tableView, info)
	-- body
	 if not info.viewLayout then
        info.viewLayout = self:addLayout("scrollNode",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        info.view = cell
        self:updateUI(info)
    end
end
function UnionDonationLogDialog:updateUI(info)
	-- body
	--玩家名字
	info.lvname:setString("Lv:"..info.level.." "..info.name)
	--VIP
	GameUI.addVip(info.vipbg,info.vip,0,0)
	--职位
	info.labelCellJob:setString(Localize("labelCellJob"..info.job))
	--战斗力	
	info.powerNum:setString(tostring(Localize("propertyComb")..info.power))
	--头像
	local head = GameUI.addPlayHead(info.iconNode,{viplv=nil,id=info.icon,scale=1,x=0,y=0,z=1,blackBack = true})
	head:setTouchThrowProperty(true,true)
	--捐献值
	info.donationName:setString(tostring(Localize("labelDonationNum")..":"..info.donationNum))
	--排名
	self.rankId = self.rankId +1
	info.boxNum:setString(self.rankId)
end
