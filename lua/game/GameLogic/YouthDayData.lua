local SData = GMethod.loadScript("data.StaticData")

local YouthDayData = {
	
}

function YouthDayData:finishAct()
	local context = GameLogic.getUserContext()
	local num = context:getProperty(const.ProBuyYouthDayStatue)
	local step = self:getGuideStep()
	if (num == 0) and (not step) then
		self.finishStatue = true
		self:setGuideStep(1)
	end
	context:changeProperty(const.ProBuyYouthDayStatue, 1)
end

function YouthDayData:setGuideStep(step)
	if self.guideStep and self.guideStep > 2 then
		return
	end
	self.guideStep = step
	local context = GameLogic.getUserContext()
	context.guideOr:setStepByKey("youthDayStatue", step)
end

function YouthDayData:getGuideStep()
	local context = GameLogic.getUserContext()
	if not self.guideStep then
	    self.guideStep = context.guideOr:getStepByKey("youthDayStatue")
	end
	return self.guideStep
end

function YouthDayData:checkFinishAct()
	local flag = self.finishStatue
	if not flag then
		local context = GameLogic.getUserContext()
		local num = context:getProperty(const.ProBuyYouthDayStatue)
		flag = (num > 0)
	end
	return flag
end

function YouthDayData:checkGuide(step)
	if not self:checkFinishAct() then
		return
	end
	local _step = self:getGuideStep()
	if (step==1) and (_step==1) then --指向商店入口
		return true
	elseif (step==2) and ((_step==1) or (_step==2)) then--指向神像入口
		return true
	end
end

function YouthDayData:getRebornBuff()
	local hpPct = 0
	local atkPct = 0
    local blv = 1
	local bid = 188
    local bsetting = BU.getBSetting(bid)
    bdata = SData.getData("bdatas", bsetting.bdid, blv)

    hpPct = bdatas.hpRate or 0
    atkPct = bdatas.atkRate or 0
	return hpPct, atkPct
end

function YouthDayData:canAddStatue(bid)
	local ucontext = GameLogic.getUserContext()
	local cbuilds = ucontext.buildData
    local bnum = cbuilds:getBuildNum(bid)
    --主城等级
    local tlevel = cbuilds:getMaxLevel(1)
    local bsetting = BU.getBSetting(bid)
    local binfo = SData.getData("binfos", bsetting.bdid)
    local max = binfo.levels[tlevel]

    local flag = false
    if self:checkFinishAct() and (bnum < max) then
    	flag = true
    end
    return flag
end

return YouthDayData