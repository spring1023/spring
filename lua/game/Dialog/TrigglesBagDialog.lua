--触发型活动的提示页面

TrigglesBagDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")

function TrigglesBagDialog:onInitDialog()
    self:setLayout("TrigglesBagDialog.json")
    self:loadViewsTo()
    self.title:setString(Localize("labelTriggerInfoTitle"))
    self.triggerId = self.id or nil
    if not self.triggerId then
        return
    end
    self:findShowTime()
    self:initDialogUI()
end

function TrigglesBagDialog:onEnter()
    GameLogic.getUserContext():setProperty(const.OpenTrigglesBagDialog, 1)
end

function TrigglesBagDialog:onExit()
    GameLogic.getUserContext():setProperty(const.OpenTrigglesBagDialog, 0)
end

function TrigglesBagDialog:findShowTime()
    local actsData = GameLogic.getUserContext().activeData:getConfigableActs()
    if actsData and next(actsData) and actsData[self.id] then
        local time = GameLogic.getSTime()
        local stime = actsData[self.id].actEndTime - time
        if stime<=0 then
            self.time = 0
            self.labelLeftTime:setVisible(false)
        else
            self.time = stime
            self.labelLeftTime:setString(Localize("labelActRemainTime")..Localizet(self.time))
        end
    end
end

function TrigglesBagDialog:initDialogUI()
    self.buttonGo:setScriptCallback(ButtonHandler(self.btnGoCallBack,self))
    self.labelGo:setString(Localize("labelGo"))
    self.upNodeTitle:setString(Localize("labelTriggerInfoSubTitle"))
    self.upNodeInfo:setString(Localize("labelTriggerInfoDesc"))
    self.trigglesBagTitle:setString(Localize("labelTiggerActivityRulesTitle"))
    self.trigglesInfo:setString(Localize("labelTiggerActivityRulesInfo"))

    local logo
    if GEngine.rawConfig.logoSpecial then
        logo = ui.sprite(GEngine.rawConfig.logoSpecial[1])
    elseif GEngine.rawConfig.logoSpecialQianxun then
        local language = General.language
        logo = ui.sprite(GEngine.rawConfig.logoSpecialQianxun[1][language])
    elseif General.language == "CN" or General.language == "HK" then
        logo = ui.sprite("images/coz2logo3.png")
    else
        logo = ui.sprite("images/coz2logo3_2.png")
    end
    display.adapt(logo, 0, 0, GConst.Anchor.Center)
    logo:setScale(0.4)
    self.logo1:addChild(logo)
end

function TrigglesBagDialog:btnGoCallBack()
    local id = self.triggerId
    display.closeDialog(self.priority)
    display.showDialog(ActivityListDialog.new({menuActType = 2,actType = 4,actId=id}))
end
