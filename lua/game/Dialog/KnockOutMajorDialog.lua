local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockOutMajorDialog = class(DialogViewLayout)
function KnockOutMajorDialog:onInitDialog()
	self.canClickBtn = false
    self:initUI()
    self:initData()
end

function KnockOutMajorDialog:initUI()
	self:setLayout("KnockOutMajorDialog.json") 
    self:loadViewsTo()
    
    self.btn_report:setScriptCallback(ButtonHandler(self.onClickBtnReport,self))
    self.btn_match:setScriptCallback(ButtonHandler(self.onClickBtnMatch,self))
    self.btn_challenge:setScriptCallback(ButtonHandler(self.onClickBtnChallenge,self))
    self.closeBut:setScriptCallback(ButtonHandler(self.closeDialog, self))
    self.questionBut:setScriptCallback(ButtonHandler(self.onQuestion,self))
end

function KnockOutMajorDialog:initData()
	local function callback(isSuc, data)
		GameUI.setLoadingShow("loading", false, 0)
    	if isSuc then 
    		self.canClickBtn = true
    		self:updateData(data)
    	end
    end
    GameUI.setLoadingShow("loading", true, 0)
    GameNetwork.request("getKoutPlayerDesc", {tid = self.tid}, callback)
	
end

function KnockOutMajorDialog:updateData(data)
	-- 对手信息[star,destroy,score,bagain,bscore] 星星，摧毁度，分数，重生，小组赛积分
	self.tscore = data.tscore
	self.uscore = data.uscore
	 -- [uid,name,elv,viplv,head,combat,lpic,lname,lid] 用户Id，昵称，等级，VIP，头像，战力，联盟图标，联盟名字，联盟Id
	self.enemyInfo = data.uinfo
	self.hlist = {}
	--排除助战英雄，v[15]%10 == 1
	for k, v in pairs(data.hlist) do
		if v[15]%10 == 1 then 
			table.insert(self.hlist, v)
		end
	end
	local ucontext = GameLogic.getUserContext()

	local name = ucontext:getInfoItem(const.InfoName)
	local lv = ucontext:getInfoItem(const.InfoLevel)
	local head = ucontext:getInfoItem(const.InfoHead)
	self.ownInfo = {uid = ucontext.uid, name = name , lv = lv, head = head}
	if self.deleted then 
		return
	end
	self:updateUI()
end

function KnockOutMajorDialog:onQuestion()
    HelpDialog.new("pvzChallengeQuestion")
end

function KnockOutMajorDialog:updateUI()
	self:updateRebornTip()
	self:updateTitle()
	self:updateOwnModel()
	self:updateEnemyModel()
	self:updateShowWin()
	self:updateEnemyHeros()
end

function KnockOutMajorDialog:updateRebornTip()
	local reborn = self.tscore[4]	
	local hpPct, atkPct = KnockMatchData:getRebornBuff(reborn, 2)
	if hpPct <= 1 then 
		hpPct = 0
	else
		hpPct = ((hpPct-1)*100).."%"
	end
	if atkPct <= 1 then 
		atkPct = 0
	else
		atkPct = ((atkPct-1)*100).."%"
	end
	local x, y = self.btn_ownReborn.view:getPosition()
    self.btn_ownReborn.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self.view, self.btn_ownReborn.view, x, y, Localizef("labPvzRebornBuffTip", {a = reborn, b= hpPct, c = atkPct})}))
    
    reborn = self.uscore[4]
    hpPct, atkPct = KnockMatchData:getRebornBuff(reborn, 2)
    if hpPct <= 1 then 
		hpPct = 0
	else
		hpPct = ((hpPct-1)*100).."%"
	end
	if atkPct <= 1 then 
		atkPct = 0
	else
		atkPct = ((atkPct-1)*100).."%"
	end
    x, y = self.btn_enemyReborn.view:getPosition()
    self.btn_enemyReborn.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self.view, self.btn_enemyReborn.view, x, y, Localizef("labPvzRebornBuffTip", {a = reborn, b= hpPct, c = atkPct})}))
end

function KnockOutMajorDialog:updateTitle()
	local week = KnockMatchData:getWeek()
	week = (week>0) and week or 7
	local arr = {64, 64, 32, 16, 8, 4, 2}
	self.lb_title:setString(Localize("labKnockOut"..arr[week]))
end

function KnockOutMajorDialog:updateOwnModel()
	local head = self.ownInfo.head
	local name = self.ownInfo.name
	local lv = self.ownInfo.lv
	local score = self.uscore[3]
	local destroy = self.uscore[2]
	local star = self.uscore[1]
	local reborn = self.tscore[4]
	local destroyStr = destroy.."%"
	local pbrDes = Localizef("labDestroyDegree", {num = destroyStr})
    GameUI.addPlayHead(self.nd_ownHead, {id=head, scale = 1.3, x=0,y=0,z=0,blackBack=true, noBlackBack = false})
    self.lb_ownName:setString(name)
    self.lb_ownLv:setString(lv)
    self.lb_ownScore:setString(score)
    self.pbr_own:setProcess(true, destroy/100)
    self.lb_ownPbrDes:setString(pbrDes)

    if reborn > 0 then 
		self.btn_ownReborn:setVisible(true)
	else
		self.btn_ownReborn:setVisible(false)
	end
    for i=1, 3 do 
    	self["img_ownGray"..i]:setVisible(true)
    	self["img_ownStar"..i]:setVisible(false)
    	if i <= star then 
    		self["img_ownStar"..i]:setVisible(true)
    	end
    end
end

function KnockOutMajorDialog:updateEnemyModel()
	local head = self.enemyInfo[5]
	local name = self.enemyInfo[2]
	local lv = self.enemyInfo[3]
	local score = self.tscore[3]
	local destroy = self.tscore[2]
	local destroyStr = destroy.."%"
	local pbrDes = Localizef("labDestroyDegree", {num = destroyStr})
	local star = self.tscore[1]
	local reborn =self.uscore[4]

	self.lb_enemyName:setString(name)
	self.lb_enemyLv:setString(lv)
	self.lb_enemyScore:setString(score)
	self.pbr_enemy:setProcess(true, destroy/100)
	self.lb_enemyPbrDes:setString(pbrDes)
    GameUI.addPlayHead(self.nd_enemyHead, {id=head, scale = 1.3, x=0,y=0,z=0,blackBack=true, noBlackBack = false})

    if reborn > 0 then 
		self.btn_enemyReborn:setVisible(true)
	else
		self.btn_enemyReborn:setVisible(false)
	end
    for i=1, 3 do
    	self["img_enemyGray"..i]:setVisible(true)
    	self["img_enemyStar"..i]:setVisible(false)
    	if i <= star then 
    		self["img_enemyStar"..i]:setVisible(true)
    	end
    end
end

function KnockOutMajorDialog:getPosByNum(num)
	local pos = {}
	pos[1] = {1024}
	pos[2] = {829, 1219}
	pos[3] = {634, 1024, 1414}
	pos[4] = {439,829, 1219, 1609}
	pos[5] = {244, 634, 1024, 1414, 1804}
	return pos[num], 568
end

function KnockOutMajorDialog:updateEnemyHeros()
	for i=1, 5 do
		self["nd_heroModel"..i]:setVisible(false)
	end
	local idx = 1
	local len = #self.hlist
	for k, v in ipairs(self.hlist) do
		self:updateHeroModel(idx, v)
		idx = idx + 1
	end
	local xPos, y = self:getPosByNum(len)
	for k, v in ipairs(self.hlist) do
		self["nd_heroModel"..k]:setPosition(xPos[k], y)
	end
end

-- [idx,hid,level,exp,starup,awakeup,mskilllevel,bskill1,bskill2,bskill3,sdlevel,sdsklv,hflag,htime,lstate ] 英雄唯一Id，英雄Id，等级，经验，星级，觉醒，主技能，被动技1，被动技2，被动技3，佣兵等级，佣兵技能，英雄状态，复活时间，英雄台位置
function KnockOutMajorDialog:updateHeroModel(idx, data)
	local node = self["nd_heroModel"..idx]
	node:setVisible(true)
	local lv = data[3]
	local id = data[2]
	local scale = 0.6
	local x = 0
	local y = 30
	local z = 0
	local centerMode = true
	local amode = data[6]
	GameUI.addHeroFeature(node, id, scale, x, y, z, centerMode, amode)
	self["lb_lv"..idx]:setString(lv)
	self["lb_lv"..idx].view:setLocalZOrder(10)
end

function KnockOutMajorDialog:updateShowWin()
	local score1 = self.uscore[3]
	local score2 = self.uscore[5]
	local _score1 = self.tscore[3]
	local _score2 = self.tscore[5]
	local flag = true
	if score1 < _score1 then 
		flag = false
	elseif score1 == _score1 then 
		if _score2 > score2 then 
			flag = false
		end
	end
	self.img_ownWin:setVisible(flag)
	self.img_enemyWin:setVisible(not flag)
end

function KnockOutMajorDialog:onClickBtnReport()
	if not self.canClickBtn then 
		return
	end
	local KnockOutReportDialog = GMethod.loadScript("game.Dialog.KnockOutReportDialog")
    display.showDialog(KnockOutReportDialog.new({params = {isOwn = true}}))
end

function KnockOutMajorDialog:onClickBtnMatch()
	if not self.canClickBtn then 
		return
	end
	local oinfo = KnockMatchData:getOinfo()
    local groupId = oinfo.groupId
    local season = KnockMatchData:getMatchWeek()
    
    local KnockOutSecondDialog = GMethod.loadScript("game.Dialog.KnockOutSecondDialog")
    display.showDialog(KnockOutSecondDialog.new({groupId = groupId}))
end

function KnockOutMajorDialog:onClickBtnChallenge()
	if not self.canClickBtn then 
		return
	end
	local function callback(isSuc, data)
		if isSuc then
			GameUI.setLoadingShow("loading", false, 0)
			--打开拉取信息开关
			GameEvent.sendEvent(GameEvent.openKnockGetInfo)
		    GameLogic.removeJumpGuide(const.ActTypePVP)
		    local uid = self.enemyInfo[1]
		    local score = self.tscore[3]
		    local reborn = self.uscore[4]
		    local head = self.enemyInfo[5]
		    local hpPct, atkPct = KnockMatchData:getRebornBuff(reborn, 2)
		    data.binfo.pvzData = {uid = uid, reborn = reborn, score = score, head = self.enemyInfo[5], combat = data.binfo.combat, hpPct = hpPct, atkPct = atkPct, type = 1, matchType = 1}
		    -- GameLogic.checkPvpAttack({callback=Handler(GameEvent.sendEvent, GameEvent.EventBattleBegin, {type=const.BattleTypePvz, data = data.binfo})})
		    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvz, data = data.binfo})

		else

		end
	end
	local tid = self.enemyInfo[1]
	GameUI.setLoadingShow("loading", true, 0)
	GameNetwork.request("beginPvzBattle", {tid = tid, gk = 1}, callback)
end

function KnockOutMajorDialog:closeDialog()
    display.closeDialog()
    local KnockMainDialog = GMethod.loadScript("game.Dialog.KnockMainDialog")
    display.showDialog(KnockMainDialog.new())
end

return KnockOutMajorDialog

