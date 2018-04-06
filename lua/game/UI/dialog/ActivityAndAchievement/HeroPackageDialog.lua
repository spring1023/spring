
--英雄礼包对话框
local HeroPackageDialog = class2("HeroPackageDialog",function()
    return BaseView.new("HeroPackageDialog.json")
end)
function HeroPackageDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end
function HeroPackageDialog:initUI()
    local context = GameLogic.getUserContext()
    local params = context.activeData.limitActive[104]
    self.context,self.params = context,params

    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab = viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))

    self:loadView("allViews")

    local item = params[3]
    local idx = 0
    for i=1,4 do
    	for j=1,2 do
            idx = idx+1
            local reward = item[idx]
            if not reward then
                break
            end
	    	local itemNode=ui.node()
	    	display.adapt(itemNode, 103+(j-1)*575, 899-(i-1)*221, GConst.Anchor.LeftBottom)
	    	self:addChild(itemNode)
	    	GameUI.addItemIcon(itemNode,reward[1],reward[2],1,103,103,true)
	    	self:loadView("itemNodeViews",itemNode) 
            self:insertViewTo()
            self.rname:setString(GameLogic.getItemName(reward[1],reward[2]))
            self.rnum:setString("x" .. reward[3])
    	end
    end
    self:insertViewTo()
    local tstr = Localizet(params[2]-GameLogic.getSTime())
    self.stringHeroPackageDes:setString(Localizef("stringHeroPackageDes",{a = tstr, b = "$9.99"}))
    RegTimeUpdate(self.stringHeroPackageDes,function()
        local tstr = params[2]-GameLogic.getSTime()
        if tstr<0 then
            display.closeDialog(self.dialogDepth)
        else
            self.stringHeroPackageDes:setString(Localizef("stringHeroPackageDes",{a = Localizet(tstr), b = "$9.99"}))
        end
    end, 0.5)

    if params[5] == 1 then
        self.butPrice:setVisible(false)
        if params[4] == 0 then
            self.butReceive:setListener(function()
                print("领取")
                self:gethgiftreward()
            end)
        else
            self.butReceive:setEnable(false)
            self.butReceive:setGray(true)
            self.btnReceive:setString(Localize("labelAlreadyReceive"))
        end
    else
        self.butReceive:setVisible(false)
        self.butPrice:setListener(function()
            print("充值")
            local params = {callback = function()
                self:rechargeTest()
            end}
            Plugins:purchase(params)
        end)
    end
end
----------------------------------------------------------------------
function HeroPackageDialog:gethgiftreward()
    if not GameNetwork.lockRequest() then
        return
    end
    local params = self.params
    GameNetwork.request("gethgiftreward",{},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            params[4] = 1
            GameLogic.addRewards(data)
            GameLogic.statCrystalRewards("英雄礼包奖励",data)
            Plugins:onStat({callKey=5,eventId="activity_104",params={personNum=1}})
            GameLogic.showGet(data)
            if self.initUI then
                display.closeDialog(0)
            end
        end 
    end)
end

function HeroPackageDialog:rechargeTest()
    if not GameNetwork.lockRequest() then
        return
    end
    local params = self.params
    GameNetwork.request("rechargeTest",nil,function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            params[5] = 1
            display.pushNotice(Localize("labelTopupSucceed"))
            if self.initUI then
                display.closeDialog(0)
            end
        end 
    end)
end

return HeroPackageDialog













