local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockOutPlayerDialog = class(DialogViewLayout)
function KnockOutPlayerDialog:onInitDialog()
	self.canClickBtn = false
    self:initUI()
    self:initData()
end

function KnockOutPlayerDialog:initUI()
	self:setLayout("KnockOutPlayerDialog.json") 
    self:loadViewsTo()
    self.btn_gamble:setScriptCallback(ButtonHandler(self.onClickBtnGamble, self))
    self.btn_challenge:setScriptCallback(ButtonHandler(self.onClickBtnChallenge, self))
    self.btn_report:setScriptCallback(ButtonHandler(self.onClickBtnReport, self))
end

function KnockOutPlayerDialog:initData()
	-- [uid,name,elv,viplv,head,combat,lpic,lname,lid]
	-- [idx,hid,level,exp,starup,awakeup,mskilllevel,bskill1,bskill2,bskill3,sdlevel,sdsklv,hflag,htime,lstate ]
	local function callback(isSuc, data)
		GameUI.setLoadingShow("loading", false, 0)
		if isSuc then 
			self:updateData(data)
		end
	end
	GameUI.setLoadingShow("loading", true, 0)
    GameNetwork.request("getKoutPlayerDesc", {tid = self.tid}, callback)
end

function KnockOutPlayerDialog:updateData(data)
	self.canClickBtn = true
	self.crystal = data.crystal or 0
	self.hlist = data.hlist
	self.uinfo = data.uinfo
	local ucontext = GameLogic.getUserContext()
	self.lastGambleTime = ucontext:getProperty(const.ProPvzACrystalTime)
	self.gambleNum = ucontext:getProperty(const.ProPvzACrystalNum)/const.ProPvzGambleNum
	self:resetGambleNum()

	if self.deleted then 
		return
	end
	self:updateUI()
end

function KnockOutPlayerDialog:updateUI()
	self:updateVip()
    self:updateUnion()
    self:updateHeros()
    self:updateGameble()
end

function KnockOutPlayerDialog:updateVip()
	local viplv = self.uinfo[4]
	GameUI.addVip(self.nd_vipBottom.view, viplv, 0, 0, 0)
end

function KnockOutPlayerDialog:updateUnion()
	local head = self.uinfo[5]
	local combat = self.uinfo[6]
	local name = self.uinfo[2]
	local lv = self.uinfo[3]
	local lname = self.uinfo[8]
	local lid = self.uinfo[9]
	local lpic = self.uinfo[7]
	if lid and lid ~= 0 then 
		self.lb_unionNameNo:setVisible(false)
		self.lb_unionName:setString(lname)
	    self.labelUnionID:setString(Localize("labelUnionID")..lid)

	    local ps1 = math.floor(lpic/10000)
	    local ps2 = math.floor((lpic%10000)/100)
	    local ps3 = lpic%10000%100
    	local nd_flag = GameUI.addUnionFlag(ps1, ps2, ps3)
    	nd_flag:setScale(0.2)
	    self.nd_union:addChild(nd_flag)
	else
		self.lb_unionName:setVisible(false)
		self.lb_unionNameNo:setString(Localize("wordNone"))
		self.labelUnionID:setString(Localize("labelUnionID")..Localize("wordNone"))
	end
    self.lb_combat:setString(Localizef("labPvzCombat", {num = combat}))
    self.lb_name:setString(name)
    self.lb_lv:setString(lv)
    GameUI.addPlayHead(self.nd_playerBottom, {id=head, scale = 1.1, x=0,y=0,z=0,blackBack=true, noBlackBack = false})
end

function KnockOutPlayerDialog:updateHeros()
	local info = clone(self.hlist)
	local _info = {}
	--排除助战英雄
	for k, v in pairs(info) do
		if v[15]%10 == 1 then 
			table.insert(_info, v)
		end
	end
	local tabview = GameUI.helpLoadTableView(self.nd_hero, _info, Handler(self.updateHeroItem, self))
	tabview.view:setElastic(false)
end

function KnockOutPlayerDialog:updateHeroItem(cell,tableView,info)
	if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("nd_heroItem",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        local lv = info[3]
        info.lb_lv:setString(lv)
        GameUI.addHeroHead2(info.nd_heroModelBottom.view, info[2], 158, 216, 0, 0, 0, {lv = info[3]})
    end
end

function KnockOutPlayerDialog:updateGameble()
	self.lb_money:setString(self.crystal)
	local flag = (self.gambleNum >= const.ProPvzGambleMaxCount)
	self.btn_gamble:setGray(flag)
	self.img_gambleFrame:setVisible(not flag)
	self.lb_gameDes:setVisible(not flag)
end

--防止夸赛季在线
function KnockOutPlayerDialog:resetGambleNum()
	local ucontext = GameLogic.getUserContext()
	local lastGambleTime = ucontext:getProperty(const.ProPvzACrystalTime)
	local nowTime = GameLogic.getSTime()
	local week = KnockMatchData:getMatchWeek(lastGambleTime)
	local _week = KnockMatchData:getMatchWeek()
	if week < _week then 
		local context = GameLogic.getUserContext()
		local gambleCry = context:getProperty(const.ProPvzACrystalNum)

		context:changeProperty(const.ProPvzACrystalNum, -gambleCry)
		self.gambleNum = 0
	end
end

function KnockOutPlayerDialog:onClickBtnGamble()
	if not self.canClickBtn then 
		return
	end
	local wk = KnockMatchData:getWeek()
	if wk ~= 1 then 
		display.pushNotice(Localize("labGambleOnlyMonday"))
		return
	end
	if self.gambleNum >= const.ProPvzGambleMaxCount then 
		display.pushNotice(Localize("labReachMaxGambleNum"))
		return
	end
	local function _callback()
		local function callback(isSuc, data)
			GameUI.setLoadingShow("loading", false, 0)
			if isSuc then
				if data.code == 0 then 
					display.pushNotice(Localize("labGambleSuccess"))
					local context = GameLogic.getUserContext()
					context:changeProperty(const.ProCrystal, -const.ProPvzGambleNum)

					local nowTime = GameLogic.getSTime()
					context:changeProperty(const.ProPvzACrystalTime, nowTime)
					local gambleCry = context:getProperty(const.ProPvzACrystalNum)
					context:changeProperty(const.ProPvzACrystalNum, const.ProPvzGambleNum)

					self.crystal = self.crystal + const.ProPvzGambleNum
					self.gambleNum = self.gambleNum + 1
					self:updateGameble()
				else
					display.pushNotice(Localize("labReachMaxGambleNum"))
				end
			end
		end
		GameUI.setLoadingShow("loading", true, 0)
		GameNetwork.request("allinCrystal", {tid = self.uinfo[1], wk = wk}, callback)
	end	
	local count = self.gambleNum
	local ans = const.ProPvzGambleMaxCount
	display.showDialog(AlertDialog.new({ctype = const.ResCustom, title = Localize("labGamble"), text = Localizef("labGambleDes", {num = 100, a = count, b = ans}), value = 100, callback = _callback} ))
end

function KnockOutPlayerDialog:onClickBtnChallenge()
	if not self.canClickBtn then 
		return
	end
	local function callback(isSuc, data)
		GameUI.setLoadingShow("loading", false, 0)
		if isSuc then
			--打开拉取信息开关
			GameEvent.sendEvent(GameEvent.openKnockGetInfo)
		    GameLogic.removeJumpGuide(const.ActTypePVP)
		    local uid = self.uinfo[1]
		    -- local score = self.tscore[3]
		    -- local reborn = self.tscore[4]
		    local head = self.uinfo[5]
		    local hpPct, atkPct = KnockMatchData:getRebornBuff(nil, 3)
		    data.binfo.pvzData = {uid = uid, head = head, hpPct = hpPct, atkPct = atkPct, type = 2, matchType = 1}
		    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvz, data = data.binfo})
		else

		end
	end
	local tid = self.uinfo[1]
	GameUI.setLoadingShow("loading", true, 0)
	GameNetwork.request("beginPvzBattle", {tid = tid, gk = 1}, callback)
end

function KnockOutPlayerDialog:onClickBtnReport()
	if not self.canClickBtn then 
		return
	end
	local tid = self.uinfo[1]
	local KnockOutReportDialog = GMethod.loadScript("game.Dialog.KnockOutReportDialog")
    display.showDialog(KnockOutReportDialog.new({isOwn = false, wk = self.wk, tid = tid}))
end

return KnockOutPlayerDialog