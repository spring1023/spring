local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockOutDialog = class(DialogViewLayout)

function KnockOutDialog:onInitDialog()
   self:initUI()
   self:initData()
end

function KnockOutDialog:initData()

end

function KnockOutDialog:initUI()
	self:setLayout("KnockOutDialog.json") 
    self:loadViewsTo()
    for i=1, 8 do 
    	self["btn_group"..i]:setScriptCallback(ButtonHandler(self.showGropDialog, self, {groupId = i}))
    end
    self.btn_famous:setScriptCallback(ButtonHandler(self.jumpToFamousDialog , self))
    self.closeBut:setScriptCallback(ButtonHandler(self.closeDialog , self))
    self.questionBut:setScriptCallback(ButtonHandler(self.clickOutBtnHelp, self))

end

function KnockOutDialog:updateUI()

end

function KnockOutDialog:updateData()	
    self:updateUI()
end

function KnockOutDialog:clickOutBtnHelp()
    RewardDescription.new(4)
    -- HelpDialog.new("pvzMajorMatchQuestion")
end


function KnockOutDialog:showGropDialog(params)
	local KnockOutSecondDialog = GMethod.loadScript("game.Dialog.KnockOutSecondDialog")
    display.showDialog(KnockOutSecondDialog.new({groupId = params.groupId}))
end

function KnockOutDialog:jumpToFamousDialog()
	local KnockFamousDialog = GMethod.loadScript("game.Dialog.KnockFamousDialog")
    display.showDialog(KnockFamousDialog.new())
end

function KnockOutDialog:closeDialog()
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffKnockMatch)
    if GameLogic.useTalentMatch and GameLogic.getSTime()>buffInfo[3]-1800 then
        display.closeDialog(self.priority)
        return
    end
    display.closeDialog()
    local KnockMainDialog = GMethod.loadScript("game.Dialog.KnockMainDialog")
    display.showDialog(KnockMainDialog.new())
end

return KnockOutDialog