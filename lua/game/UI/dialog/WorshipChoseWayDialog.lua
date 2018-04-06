
local const = GMethod.loadScript("game.GameLogic.Const")
--选择膜拜方式对话框
local WorshipChoseWayDialog = class2("WorshipChoseWayDialog",function()
    return BaseView.new("WorshipChoseWayDialog.json",true)
end)

function WorshipChoseWayDialog:ctor(uid)
    self.uid = uid
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function WorshipChoseWayDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))

    self:loadView("leftViews")
    self:loadView("rightViews")
    self:insertViewTo()
    GameUI.addItemIcon(self.iconNode,10,const.ResGold,0.35,29,33,false)
    GameUI.addItemIcon(self,9,3000,314/200,201+157,424+157,true)
    GameUI.addItemIcon(self,9,3000,314/200,825+157,424+157,true)
    self:insertViewTo()
    self.getNum1:setString("x" .. 1)
    self.getNum2:setString("x" .. 2)
    self.getStr1:setString(Localize("labelGet") .. GameLogic.getItemName(9,3000) .. "x" .. 1)
    self.getStr2:setString(Localize("labelGet") .. GameLogic.getItemName(9,3000) .. "x" .. 2)
    self.cost = 50000
    self.labelCostNum:setString(self.cost)
    if GameLogic.getUserContext():getRes(const.ResGold)< self.cost then
        ui.setColor(self.labelCostNum,"red")
    end

    self.butWorshipWay1:setListener(function()
        self:visitlmember(1)
    end)
    self.butWorshipWay2:setListener(function()
        self:visitlmember(2)
    end)
end
------------------------------------------------------------------------------------------
function WorshipChoseWayDialog:visitlmember(wtype)
    local num = 0
    local time = GameLogic.getUserContext():getProperty(const.ProVisitTime)
    if GameLogic.getSTime()-time>GameLogic.getRtime() then
        num = 1
    end
    if num<=0 then
        display.pushNotice(Localize("labelNotWorshipNum"))
        return
    end
    local cost = self.cost
    if wtype == 2 and GameLogic.getUserContext():getRes(const.ResGold)<cost then
        display.showDialog(AlertDialog.new({ctype=const.ResGold, cvalue=cost, callback=Handler(self.visitlmember, self, wtype)}))
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("visitlmember",{visitlmember = {self.uid,wtype}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            display.pushNotice(Localizef("labelWorshipSucReward",{a = GameLogic.getItemName(9,3000) .. "x" .. wtype}))
            GameLogic.addRewards(data)
            GameLogic.statCrystalRewards("膜拜成功奖励",data)
            GameLogic.getUserContext():setProperty(const.ProVisitTime,GameLogic.getTime())
            if wtype == 2 then
                GameLogic.getUserContext():changeRes(const.ResGold,-cost)
            end
            display.closeDialog(0)
        end
    end)
end
return WorshipChoseWayDialog














