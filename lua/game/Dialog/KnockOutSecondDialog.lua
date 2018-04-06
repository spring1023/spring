local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockOutSecondDialog = class(DialogViewLayout)
function KnockOutSecondDialog:onInitDialog()
	self.canClickBtn = false
	self.canClickPlayer = false
    self:initUI()
    self:initData()
    self.questionBut:setVisible(false)
    self.backBut:setVisible(false)
end

function KnockOutSecondDialog:initUI()
	self:setLayout("KnockOutSecondDialog.json")
    self:loadViewsTo()
    self.playerItems = {}
    self.playerInfo = {}
    self.btnItems = {}
    for i=1, 15 do
    	self.playerItems[i] = self:addLayout("nd_playerItem", self["btn_player"..i].view:getDrawNode())
    	self.playerItems[i]:loadViewsTo()
	    self["nd_player"..i].view:setLocalZOrder(10)
	    self.playerItems[i].nd_player:setVisible(false)
	    self.playerItems[i].lb_none:setVisible(true)
   		self.playerItems[i].img_noPlayer:setVisible(false)
   		self.playerItems[i].img_noPlayer.view:setScale(1.3)

    	self.img_crown:setVisible(false)
    	local path = "images/pvz/imgPvzOutHeroBg1.png"
	    if self.season then
	    	path = "images/pvz/imgPvzOutHeroBg2.png"
	    	self.img_crown:setVisible(true)
	    end
    	self.img_player15:setImage(path)
    	self.btnItems[i] = self:addLayout("nd_challenge", self["nd_player"..i].view)
    	self.btnItems[i]:loadViewsTo()
	    self.btnItems[i].btn_challenge:setScriptCallback(ButtonHandler(self.clickBtnChallenge,self, i))
	    self["btn_player"..i]:setScriptCallback(ButtonHandler(self.onClickPlayer, self, i))
	    --初始化不显示
	    if i<=14 then
		    self["img_road"..i]:setVisible(false)
	    end
	    self.playerItems[i]:setVisible(false)
	    self.btnItems[i].btn_challenge:setVisible(false)
    end
    self.questionBut:setScriptCallback(ButtonHandler(self.onQuestion,self))
    self.backBut:setScriptCallback(ButtonHandler(self.onBack,self))
    self.closeBut:setScriptCallback(ButtonHandler(self.closeDialog,self))
    self.btn_famous:setScriptCallback(ButtonHandler(self.jumpToFamousDialog , self))
end

function KnockOutSecondDialog:initData()
	-- [uid,oder,urank,stat,name,head,elv,combat]
	local groupId = self.groupId or 0
	local wk = self.wk or KnockMatchData:getWeek()
	local season = self.season or KnockMatchData:getMatchWeek()
	local function callback(isSuc, data)
		GameNetwork.unlockRequest()
		GameUI.setLoadingShow("loading", false, 0)
		if isSuc then
			self.players = data.players
			self.score = data.scores
			self:updateData()
			if self.deleted then
				return
			end
			self:updateUI()
			KnockMatchData:updateSelectGroupId(groupId)
		else

		end
	end
	if not GameNetwork.lockRequest() then
		return
	end
	GameUI.setLoadingShow("loading", true, 0)
    GameNetwork.request("getKoutPlayers", {wk = wk, groupId = groupId, sid = season}, callback)
end

function KnockOutSecondDialog:updateData()
	for k, v in pairs(self.players) do
		local posId = self:getPosId(v[2], v[3])
		-- dump({v[1],v[2], v[3], posId})
		for _k, _v in pairs(posId) do
			self.playerInfo[_v] = v
		end
	end
	--{info = {}, dataIdx, uiIdx}
	self.oEnemy = self:getEnemy()
end

--返回按钮显示：1、非8强；
function KnockOutSecondDialog:updateBtnBack()
	local week = KnockMatchData:getMatchWeek()
	local flag = true
	if KnockMatchData:checkInEight() then
		flag = false
	end
	self.backBut:setVisible(flag)
end

function KnockOutSecondDialog:updateUI()
	for k, v in pairs(self.players) do
		local posId = self:getPosId(v[2], v[3])
		self:updatePlayerModel(v, posId)
	end
	self:updateRoad()

	self:updateBtnBack()
	local week = KnockMatchData:getMatchWeek()
	if week <=1 then
		self.btn_famous:setGray(true)
	end
	if KnockMatchData:checkInEight() then
		self.lb_title:setString(Localize("labMajorMatch"))
		self.img_cup:setVisible(true)
	else
		if self.groupId then
			self.lb_title:setString(Localize("LabGroup"..self.groupId))
		else
			self.lb_title:setString(Localize("labMajorMatch"))
		end
		self.btn_famous:setVisible(false)
		self.img_cup:setVisible(false)
	end
	for i=1, 15 do
		local uiIdx =self:getHeroModelUIIdx(i)
		-- self.btnItems[uiIdx].btn_challenge:setVisible(false)
		if i<=14 then
			self["img_road"..i]:setVisible(true)
		end
		self.playerItems[i]:setVisible(true)
	    -- self.playerItems[i].nd_player:setVisible(true)
	end
	local uid = GameLogic.getUserContext().uid
	for i = 1, 14 do
		local enemyPos = self:getEnemyIdx(i)
		local maxIdx = self:getOwnMaxIdx()
		if (not GameLogic.isEmptyTable(self.playerInfo[i])) and (uid == self.playerInfo[i][1]) and  (maxIdx == i) and (not self.season) then 	
			local oFlag = KnockMatchData:getOinfo().oFlag
			local week = KnockMatchData:getWeek()
			if (oFlag == 2) and (week~=1) then
				local uiIdx =self:getHeroModelUIIdx(enemyPos)
				self.btnItems[uiIdx].btn_challenge:setVisible(true)
				if not GameLogic.isEmptyTable(self.playerInfo[enemyPos]) then
					self.btnItems[uiIdx].btn_challenge:setGray(false)
				else
					self.btnItems[uiIdx].btn_challenge:setGray(true)
				end
			end
		end
	end
	if self.season then
		for i=1, 15 do
			self["btn_player"..i]:setEnable(false)
		end
	else
	    self.questionBut:setVisible(true)
	end
	self:updateNoPlayerImage()
end

function KnockOutSecondDialog:updateNoPlayerImage()
	local maxRw = 1
	for k, v in pairs(self.players) do
		local rw = v[3]
		if KnockMatchData:checkInEight() or self.season then
			rw = rw*8
		end
		rw = 64/rw
		local _mod = 1
		for i=1, 4 do
			if math.pow(2, i-1) == rw then
				_mod = i
				break
			end
		end
		if _mod > maxRw then
			maxRw = _mod
		end
	end
	local arr = {8, 12, 14, 15}
	local maxIdx = arr[maxRw]

	for i = maxIdx+1, 15 do
		local uiIdx =self:getHeroModelUIIdx(i)
   		self.playerItems[uiIdx].img_noPlayer:setVisible(true)
	    self.playerItems[uiIdx].lb_none:setVisible(false)
	end
end

--rw跟后端的计算方式不一样，要做转换
function KnockOutSecondDialog:getPosId(pos, rw)
	if KnockMatchData:checkInEight() or self.season then
		rw = rw*8
	end
	rw = 64/rw

	local _mod = 1
	for i=1, 4 do
		if math.pow(2, i-1)==rw then
			_mod = i
			break
		end
	end
	rw = _mod
	local idx = 0
	local posId = {}
	for i=1, rw do
		local num = math.floor( (pos-1)/math.pow(2, i-1) ) + 1 + idx
		table.insert(posId, num)
		idx = idx + math.pow(2, 4-i)
	end
	return posId
end

function KnockOutSecondDialog:updatePlayerModel(info, posArr)
	for k, v in pairs(posArr) do
		local idx = self:getHeroModelUIIdx(v)
		local node = self.playerItems[idx]
		local uid = info[1]
		local lv = info[7]
		local name = info[5]
		local score = self:getScoreByPos(v)
		node.lb_name:setString(name)
	    node.lb_score:setString(score)
		node.lb_lv:setString(lv)
		node.nd_player:setVisible(true)
	    node.lb_none:setVisible(false)
	    node.nd_playerModel.view:setScale(0.6)
    	GameUI.addPlayHead(node.nd_playerModelBottom, {id=info[6], scale = 0.9, x=0,y=0,z=0,blackBack=false, noBlackBack = false, noBut = true}) 	
    	if self.season then
    		node.nd_score:setVisible(false)
    		node.lb_name:setPosition(-12, -60)
    	else
    		node.nd_score:setVisible(true)
    		node.lb_name:setPosition(-12, -40)
    	end
	end

end

function KnockOutSecondDialog:getScoreByPos(pos)
	local score = 0
	for k, v in pairs(self.score) do
		if v[1] == pos then
			score = v[2]
			break
		end
	end
	return score
end

--获取每个玩家晋级后的下标
function KnockOutSecondDialog:getNextPosIdx(idx)
	local arr = {9, 9, 10, 10, 11, 11, 12, 12, 13, 13, 14, 14, 15, 15}
	return arr[idx]
end

function KnockOutSecondDialog:getEnemyIdx(idx)
	local arr = {2, 1, 4, 3, 6, 5, 8, 7, 10, 9, 12, 11, 14, 13}
	return arr[idx]
end

--拼图的时候 UI 没有按照正确的格式，这里做个转换
function KnockOutSecondDialog:getHeroModelUIIdx(idx)
	local arr = {1, 2, 3, 4, 8, 9, 10, 11, 5, 6, 12, 13, 7, 14, 15}
	return arr[idx]
end

function KnockOutSecondDialog:getHeroModelDataIdx(idx)
	local arr = {1, 2, 3, 4, 9, 10, 13, 5, 6, 7, 8, 11, 12, 14, 15}
	return arr[idx]
end

function KnockOutSecondDialog:getOwnMaxIdx()
	local ucontext = GameLogic.getUserContext()
	local uid = ucontext.uid
	local myPos = {}
	local enemyPos = {}
	for k, v in pairs(self.playerInfo) do
		if checknumber(v[1]) == uid then
			table.insert(myPos, k)
		end
	end
	local maxIdx = 1
	if not GameLogic.isEmptyTable(myPos) then
		for k, v in pairs(myPos) do
			if v>=maxIdx then
				maxIdx = v
			end
		end
	end
	return maxIdx
end

function KnockOutSecondDialog:getEnemy()
	local maxIdx = self:getOwnMaxIdx()
	local enemyIdx = self:getEnemyIdx(maxIdx)
	local enemyInfo = self.playerInfo[enemyIdx]
	return enemyInfo
end

function KnockOutSecondDialog:jumpToFamousDialog()
	local week = KnockMatchData:getMatchWeek()
	if week <= 1 then
		display.pushNotice(Localize("labNoFamousMan"))
	else
		local KnockFamousDialog = GMethod.loadScript("game.Dialog.KnockFamousDialog")
	    display.showDialog(KnockFamousDialog.new())
	end
end

function KnockOutSecondDialog:onQuestion()
    RewardDescription.new(4)
    -- HelpDialog.new("pvzMajorMatchQuestion")
end

function KnockOutSecondDialog:onBack()
    display.closeDialog(self.priority)
	local KnockOutDialog = GMethod.loadScript("game.Dialog.KnockOutDialog")
    display.showDialog(KnockOutDialog.new())
end

function KnockOutSecondDialog:getWeekByUid(uid)
	local data = {}	
	local rw = 0
	for k, v in pairs(self.players) do
		if v[1] == uid then
			rw = v[3]
			break
		end
	end
	local idx =  1
	local arr = {{2,3,4}, {5,6,0, 0}}
	if KnockMatchData:checkInEight() then
		idx = 2
	else
		rw = rw/8
	end
	for i=1, 4 do
		if math.pow(2, (4-i)) == rw then
			rw = i
			break
		end
	end
	-- dump({uid, idx, rw, arr[idx][rw]})
	return arr[idx][rw]
end

function KnockOutSecondDialog:onClickPlayer(idx)
	local _idx = self:getHeroModelDataIdx(idx)
	local data = self.playerInfo[_idx]

	if not GameLogic.isEmptyTable(data) then
		local uid = data[1]
		local KnockOutPlayerDialog = GMethod.loadScript("game.Dialog.KnockOutPlayerDialog")
		local week = self:getWeekByUid(uid)
	    display.showDialog(KnockOutPlayerDialog.new({tid = uid, wk = week}))
	end
end

function KnockOutSecondDialog:clickBtnChallenge(idx)
	local dataIdx = self:getHeroModelDataIdx(idx)
	local enemyInfo = self.playerInfo[dataIdx]
	if GameLogic.isEmptyTable(enemyInfo) then
		display.pushNotice(Localize("labNoEnemy"))
		return
	end
	local tid = enemyInfo[1]
	local KnockOutMajorDialog = GMethod.loadScript("game.Dialog.KnockOutMajorDialog")
	display.showDialog(KnockOutMajorDialog.new({tid = tid}))

end

function KnockOutSecondDialog:updateRoad()
	local _num = 14
	for i=1, _num do
		local rotation = 0
		local scaleX = 1
		local scaleY = 1
		local order = 2
		local path = "images/pvz/imgPvzOutLine2.png"
		local pathIdx = 2
		local nextPos = self:getNextPosIdx(i)
		if GameLogic.isEmptyTable(self.playerInfo[i]) or GameLogic.isEmptyTable(self.playerInfo[nextPos]) then

		else
			local uid = self.playerInfo[i][1]
			local _uid = self.playerInfo[nextPos][1]
			if uid == _uid then
				pathIdx = 1
			end
		end

		local uiIdx = self:getHeroModelUIIdx(i)

		local _mod = uiIdx%2
		if uiIdx<=6 then
			if ((pathIdx == 1) and (_mod~=0)) or ((pathIdx == 2) and (_mod == 0)) then
				scaleX = -1
				rotation = 180
			end
		elseif uiIdx == 7 or uiIdx == 14 then
			if((pathIdx == 2 and (_mod~=0)) or (pathIdx == 1) and (_mod == 0)) then
				scaleX = 1
				rotation = 270
			end
			if((pathIdx == 1 and (_mod~=0)) or (pathIdx == 2) and (_mod == 0)) then
				scaleX = -1
				rotation = 90
			end
		elseif uiIdx>=8 and uiIdx <= 13 then
			if ((pathIdx == 2) and (_mod==0)) or ((pathIdx == 1 ) and (_mod ~= 0)) then
				scaleX = -1
			end
			if((pathIdx == 1) and (_mod==0)) or ((pathIdx == 2) and (_mod ~= 0) ) then
				scaleX = 1
				rotation = 180
			end
		end
		if pathIdx == 1 then
			order = 3
			path = "images/pvz/imgPvzOutLine1.png"
		elseif pathIdx == 2 then
			order = 2
			path = "images/pvz/imgPvzOutLine2.png"
		end
		local node= self["img_road"..uiIdx].view
		local node2 = self["nd_road"..uiIdx].view
		node:setTexture(path)
		node:setRotation(rotation)
		node:setScaleX(scaleX)
		node2:setLocalZOrder(order)
	end
end

function KnockOutSecondDialog:closeDialog()
	display.closeDialog()
    local KnockMainDialog = GMethod.loadScript("game.Dialog.KnockMainDialog")
    display.showDialog(KnockMainDialog.new())
end
return KnockOutSecondDialog