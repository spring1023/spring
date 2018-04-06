
local const = GMethod.loadScript("game.GameLogic.Const")
local GuideOrData = class()
function GuideOrData:ctor(context)
    self.context = context
    self.key = "guideOr_" .. context.sid .."_" .. context.uid
    self.pvzGuide = GEngine.getConfig("isKnockDivide"..context.sid..context.uid)
    self.tmGuide = GEngine.getConfig("TalentMatch"..context.sid..context.uid)
end

function GuideOrData:getStep()
    local step = GEngine.getConfig(self.key) or 0
    return step
end

function GuideOrData:setStep(step)
    GEngine.setConfig(self.key,step,true)
    if step then
        Plugins:onStat({callKey=5,eventId="guide",params={["step" .. (step or 0)]=1}})
        Plugins:onFacebookStat("PreTutorial", 100+step)
    end
end

function GuideOrData:getStepByKey(key)
	key = key.. self.context.sid .."_" .. self.context.uid
	local step = GEngine.getConfig(key)
	return step
end

function GuideOrData:setStepByKey(key, step)
	key = key.. self.context.sid .."_" .. self.context.uid
	GEngine.setConfig(key, step, true)
end

return GuideOrData
