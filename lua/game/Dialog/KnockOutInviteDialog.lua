local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockOutInviteDialog = class(DialogViewLayout)
function KnockOutInviteDialog:onInitDialog()
    self:initUI()
    self:initData()
end

function KnockOutInviteDialog:initUI()
	self:setLayout("KnockOutInviteDialog.json") 
    self:loadViewsTo()

    self.btn_go:setScriptCallback(ButtonHandler(self.onClickBtnGo,self))
    self.img_go.view:setHValue(114)
end

function KnockOutInviteDialog:initData()
	self.mRank = self.mRank or 64
	self.time = KnockMatchData:getDivideEndTime()
	self:updateData()
end

function KnockOutInviteDialog:updateData()
	self:updateUI()
end

function KnockOutInviteDialog:updateUI()
	local timestr = GameLogic.getTimeFormat4(self.time)
	self.lb_des:setString(Localizef("labCongratilateInvitationDes", {time = timestr}))
	self.lb_matchTitle:setString(Localize("labKnockOut"..self.mRank))

	local sTime = GameLogic.getSTime()
	local startTime = KnockMatchData:getOutStartTime()
	local leftTime = sTime-startTime
	local flag = (leftTime < 0)
	if flag then 
		leftTime = GameLogic.getTimeFormat4(leftTime)
		self.lb_time:setString(leftTime)
	else

	end
	self.lb_leftTimeDes:setVisible(flag)
	self.lb_time:setVisible(flag)
	self.lb_leftTimeDes2:setVisible(not flag)
	self:updateHeroModel()
	self:addHero()
end

function KnockOutInviteDialog:updateHeroModel()
	local context = GameLogic.getUserContext()

	local head = context:getInfoItem(const.InfoHead)
	local lv = context:getInfoItem(const.InfoLevel)
	local name = context:getInfoItem(const.InfoName)
	self.lb_lv:setString(lv)
	self.lb_name:setString(name)
    GameUI.addPlayHead(self.nd_playerBotton, {id=head, scale = 1.1, x=0,y=0,z=0,blackBack=true, noBlackBack = true})
    local flag = GameLogic.isEmptyTable(context.union)
    if not flag then
    	local id = context.union.id
	    local flagId = context.union.flag
	    local ps1 = math.floor(flagId/10000)
	    local ps2 = math.floor((flagId%10000)/100)
	    local ps3 = flagId%10000%100
	    local nd_flag = GameUI.addUnionFlag(ps1, ps2, ps3)
	    nd_flag:setScale(0.2)
	    self.nd_union:addChild(nd_flag)
	    local unionName = context.union.name
	    self.lb_unionName:setString(unionName)
	    --self.lb_unionId:setString(id)
	    self.labelUnionID:setString(Localize("labelUnionID")..id)
    end
    self.nd_union:setVisible(not flag)
    self.lb_unionName:setVisible(not flag)
    self.labelUnionID:setVisible(not flag)
    
end

function KnockOutInviteDialog:addHero()
	local shadow = ui.sprite("images/pvz/imgPvzShadow.png")
    display.adapt(shadow, 0, -100, GConst.Anchor.Bottom)

	local man = ui.sprite("images/pvePlotPerson1.png")
    display.adapt(man, 0, 0, GConst.Anchor.Bottom)
    man:setScale(0.6)

	self.nd_heroBottom:addChild(shadow)
	self.nd_heroBottom:addChild(man)
end

function KnockOutInviteDialog:onClickBtnGo()
	display.closeDialog()
    KnockMatchData:initData()
end

return KnockOutInviteDialog