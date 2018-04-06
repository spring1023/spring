
local const = GMethod.loadScript("game.GameLogic.Const")
--膜拜对话框
local WorshipDialog = class2("WorshipDialog",function()
    return BaseView.new("WorshipDialog.json",true)
end)

function WorshipDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
    self:commobaireward()
end

function WorshipDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))

    self:loadView("allViews")
    self:insertViewTo()
    GameUI.addItemIcon(self.iconNode,10,const.ResGold,0.27,29,33,false)
    local num = 0
    local time = GameLogic.getUserContext():getProperty(const.ProVisitTime)
    if GameLogic.getTime()-time>GameLogic.getRtime() then
        num = 1
    end
    self.daySurplusTime:setString(Localizef("labelDaySurplusWorshipTime",{a = num}))
    self.labelAllCanRewardValue:setString("")
    self.butReceive:setListener(function()
        self:getmobaireward()
    end)
end

function WorshipDialog:commobaireward()
    GameLogic.dumpCmds()
    GameNetwork.request("commobaireward",{},function(isSuc,data)
        if isSuc then
            if self.labelAllCanRewardValue then
                self.labelAllCanRewardValue:setString(data.mrwd)
                self.mrwd = data.mrwd
            end
        end
    end)
end

function WorshipDialog:getmobaireward()
    local mrwd = self.mrwd
    if not mrwd then
        return
    end 
    if mrwd<=0 then
        display.pushNotice(Localize("labelYouNoReward"))
        return
    end
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdMobaiReward})
    context:changeResWithMax(const.ResGold,mrwd)
    GameLogic.showGet({{10,const.ResGold,mrwd}})
    display.closeDialog(0)
end

return WorshipDialog










