
local SData = GMethod.loadScript("data.StaticData")
--联盟宝箱对话框
local UnionBoxDialog = class2("UnionBoxDialog",function()
    return BaseView.new("UnionBoxDialog.json",true)
end)

function UnionBoxDialog:ctor(index,params)
	self.index,self.params = index,params
    self:initUI()
    display.showDialog(self)
end
function UnionBoxDialog:onQuestion()
    HelpDialog.new("dataQuestionUnBox")
end
function UnionBoxDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,display.getDialogPri()+1))
    self:loadView("leftViews")
    self:loadView("rightViews")
    self:insertViewTo()

    --左边头像
    local bsdata = SData.getData("upveboss",self.index,1)
    local id = bsdata[1]
    local lv = bsdata[2]
    if id<100 then
        GameUI.addBuildHead(self,id,467,402,189+233,360+201,2, lv)
    else
        --boss头像
        local context = GameLogic.getUserContext()
        local hero = context.heroData:makeHero(id)
        local headNode = ui.node({200,200})
        display.adapt(headNode,189+195,386+201,GConst.Anchor.Center)
        self:addChild(headNode)
        headNode:setScale(1.5)
        GameUI.updateHeroTemplate(headNode, {noLv = true}, hero)
    end
    self.labelOutpost:setString(Localize("dataPvlPassName" .. self.index))

    local rewards = self.params.rewards[self.index]
    --宝箱1
    self.labelLeftx6:setString("x".. rewards[1])
    if rewards[1]<=0 then
    	self.butLeft:setEnable(false)
    	self.butLeft:setGray(true)
    	self.rewardBox1:setSValue(-100)
    end
    --2
    self.labelCenterx6:setString("x".. rewards[2])
    if rewards[2]<=0 then
    	self.butCenter:setEnable(false)
    	self.butCenter:setGray(true)
    	self.rewardBox2:setSValue(-100)
    end
    --3
    self.labelRightx6:setString("x".. rewards[3])
    if rewards[3]<=0 then
    	self.butRight:setEnable(false)
    	self.butRight:setGray(true)
    	self.rewardBox3:setSValue(-100)
    end

    local bt = {self.butLeft,self.butCenter,self.butRight}
    self.bt = bt
    for i,v in ipairs(bt) do
    	v:setListener(function()
    		self:getpvlaward(i-1)
    	end)
    end

end


function UnionBoxDialog:getpvlaward(i)
    if not GameNetwork.lockRequest() then
        return
    end
	_G["GameNetwork"].request("getpvlaward",{getpvlaward = {self.index,i}},function(isSuc,data)
        GameNetwork.unlockRequest()
		if isSuc then
			print("领取成功")
			self.params.rewards[self.index][i+1] = 0
			self.bt[i+1]:setEnable(false)
			self.bt[i+1]:setGray(true)
			self["rewardBox" .. i+1]:setSValue(-100)
            GameLogic.addRewards(data)
            GameLogic.statCrystalRewards("联盟副本宝箱奖励",data)
            GameLogic.showGet(data,nil,true,true)
		end
	end)
end
return UnionBoxDialog
