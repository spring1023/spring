
local SData = GMethod.loadScript("data.StaticData")
--联盟战斗对话框
local UnionBattleDialog = class2("UnionBattleDialog",function()
    return BaseView.new("UnionBattleDialog.json",true)
end)

function UnionBattleDialog:ctor(index,params,canReward)
	self.index,self.params,self.canReward = index,params,canReward
    self:initUI()
    display.showDialog(self)
end
function UnionBattleDialog:onQuestion()
    HelpDialog.new("dataQuestionUnBat")
end
function UnionBattleDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,display.getDialogPri()+1))
    self:loadView("leftViews")
    self:loadView("rightViews")
    self:insertViewTo()
    --伤害排行
    self.butDamageRank:setListener(function()
    	UnionDamageRankDialog.new(self.index)
    end)
    --领取奖励   挑战
    local params = self.params
    self.butReceiveReward:setListener(function()
    	if self.index == params.index then
    		print("挑战")
            if self.params.pvl_cyc then
                if 2-self.params.attackNum+self.params.pvl_buy>0 then
                    self:beginpvlbattle()
                else
                    print("次数不足")
                    display.pushNotice(Localize("stringTrial3"))
                end
            else
                print("请刷新")
                display.pushNotice(Localize("labelLeaguePve1"))
            end
    	else
    		print("领取奖励")
            local rewards = self.params.rewards[self.index]
            if rewards[1]<=0 and rewards[2]<=0 and rewards[3]<=0 then
                display.pushNotice(Localize("stringUnionBattleNotice"))
            else
                UnionBoxDialog.new(self.index,self.params)
            end
    	end
    end)

    if self.index == params.index then
        --挑战
        self.labelLastkill:setVisible(false)
        self.labelNameKill:setVisible(false)
        self.iconAttack:setVisible(false)
    	self.btnReceiveReward:setString(SG("btnChallenge"))
    else
        --领取奖励
    	self.btnReceiveReward:setString(SG("btnReceiveReward"))
        self.labelNameKill:setString(params.rewards[self.index][4])
    end

    local bosslist = self.params.bosslist or ""
    local bossData = SData.getData("upveboss",self.index)

    local id = bossData[1][1]
    local rthead
    if id<100 then
        rthead = GameUI.addBuildHead(self.bossNode,id,224,200,162,190,1,bossData[1][2])
    else
        local context = GameLogic.getUserContext()
        local hero = context.heroData:makeHero(id)
        rthead = ui.shlNode({200,200})
        display.adapt(rthead,150,173,GConst.Anchor.Center)
        self.bossNode:addChild(rthead)
        rthead:setScale(0.7)
        GameUI.updateHeroTemplate(rthead, {noLv = true}, hero)
    end

    --左边boss头像
    local id = bossData[1][1]
    if id<100 then
        GameUI.addBuildHead(self,id,467,402,189+233,386+201,2,bossData[1][2])
    else
        --GameUI.addHeadIcon(self,id, 2, 189+233,386+201, 2)

        local context = GameLogic.getUserContext()
        local hero = context.heroData:makeHero(id)
        local headNode = ui.node({200,200})
        display.adapt(headNode,189+195,386+201,GConst.Anchor.Center)
        self:addChild(headNode)
        headNode:setScale(1.5)
        GameUI.updateHeroTemplate(headNode, {noLv = true}, hero)
    end

    self.labelOutpost:setString(Localize("dataPvlPassName" .. self.index))
    --右上boss血条
    local p = bosslist[1] and bosslist[1][1] and bosslist[1][2] and (tonumber(bosslist[1][1])/tonumber(bosslist[1][2])) or 1
    self.bossMainHp:setProcess(true,p)
    self.labelBossNodeProcessValue:setString(math.ceil(p*100) .. "%")

    --右上boss头像
    if bosslist[1] and bosslist[1][1] and tonumber(bosslist[1][1]) and tonumber(bosslist[1][1])<=0 or self.index ~= params.index  then
        --已消灭字
        temp = ui.label(SG("labelDeath"), General.font1, 40,{color = {255,255,255}})
        display.adapt(temp,126,38,GConst.Anchor.Left)
        self.bossNode:addChild(temp,10)
        self.labelBossNodeProcessValue:setVisible(false)
        self.bossMainHp:setProcess(true,0)
        self.bossHpImg:setSValue(-100)
        rthead:setSValue(-100)
    end
    --右下四个
    for i=1,4 do
    	local node = ui.node()
    	node:setPosition(543+260*i,276)
    	self:addChild(node)
    	--框
    	local temp = ui.sprite("images/smallMonsterBack2.png",{183,179})
    	display.adapt(temp,15,25,GConst.Anchor.LeftBottom)
    	node:addChild(temp)
    	

        local mtype
        local idx = i+1
        if bossData[idx] then
            if bosslist[idx] and bosslist[idx][1] and tonumber(bosslist[idx][1]) and tonumber(bosslist[idx][1])<=0 or self.index ~= params.index then
                --死
                --死亡图片
                local temp = ui.sprite("images/iconDeath.png",{158,216})
                display.adapt(temp,25,-5,GConst.Anchor.LeftBottom)
                node:addChild(temp)
                --血条框
                temp = ui.sprite("images/proBack4.png",{167,37})
                display.adapt(temp,24,-18,GConst.Anchor.LeftBottom)
                node:addChild(temp, 1)
                --红心
                temp = ui.sprite("images/hp2.png",{64,57})
                display.adapt(temp,-10,-19,GConst.Anchor.LeftBottom)
                node:addChild(temp, 1)
                temp:setSValue(-100)
                --已消灭字
                temp = ui.label(SG("labelDeath"), General.font1, 30,{color = {255,255,255}})
                display.adapt(temp,65,0,GConst.Anchor.Left)
                node:addChild(temp, 1)
            else
                --BOSS
                --boss头像
                local id = bossData[idx][1]
                if id<100 then
                    GameUI.addBuildHead(node,id,150,150,106,115,1,bossData[idx][2])
                else
                    local context = GameLogic.getUserContext()
                    local hero = context.heroData:makeHero(id)
                    local rthead = ui.shlNode({204,204})
                    display.adapt(rthead,93,105,GConst.Anchor.Center)
                    node:addChild(rthead)
                    rthead:setScale(0.7)
                    GameUI.updateHeroTemplate(rthead, {noLv = true}, hero)
                end
                --血条框
                temp = ui.sprite("images/proBack4.png",{167,37})
                display.adapt(temp,24,-18,GConst.Anchor.LeftBottom)
                node:addChild(temp, 1)
                --血条
                local p = bosslist[idx] and bosslist[idx][1] and bosslist[idx][2] and tonumber(bosslist[idx][1])/tonumber(bosslist[idx][2]) or 1
                temp = ui.sprite("images/proFillerGreen.png",{163,31})
                display.adapt(temp,24,-15,GConst.Anchor.LeftBottom)
                node:addChild(temp, 1)
                temp:setProcess(true,p)
                --红心
                temp = ui.sprite("images/hp2.png",{64,57})
                display.adapt(temp,-10,-19,GConst.Anchor.LeftBottom)
                node:addChild(temp, 1)
                --血量百分比
                temp = ui.label(math.ceil(p*100) .. "%", General.font1, 30,{color = {255,255,255}})
                display.adapt(temp,105,0,GConst.Anchor.Center)
                node:addChild(temp, 1)
            end
        else
            --锁
            temp = ui.sprite("images/iconUnionLock.png",{139,166})
            display.adapt(temp,35,37,GConst.Anchor.LeftBottom)
            node:addChild(temp)
        end

        --小框
        temp = ui.sprite("images/smallMonsterBack1.png",{214,216})
        display.adapt(temp,0,0,GConst.Anchor.LeftBottom)
        node:addChild(temp)
    end

end
---------------------------------------------------------------------------------------------------------
function UnionBattleDialog:beginpvlbattle()
    local idx = self.index
    local params = self.params
    if GameLogic.getTime()-GameLogic.getUserContext().union.enterTime<86400 then
        display.pushNotice(Localize("stringCantUnionPve"))
        return
    end

    GameLogic.checkCanGoBattle(const.BattleTypeUPve,function()

        if not GameNetwork.lockRequest() then
            return
        end
        _G["GameNetwork"].request("beginpvlbattle",{beginpvlbattle = {idx}},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                print("开始战斗")
                --活动
                if data == 10 then
                    display.pushNotice(Localize("stringcantUnionMap"))
                elseif data == 21 then
                    display.pushNotice(Localize("noticePvbFinish"))
                else
                    display.closeDialog()
                    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=7, idx=idx, bparams=params})
                end
            else

            end
        end)

    end)
end

return UnionBattleDialog
