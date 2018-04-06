
local SData = GMethod.loadScript("data.StaticData")
local const = GMethod.loadScript("game.GameLogic.Const")
--英雄试炼对话框
local HeroTrialDialog = class2("HeroTrialDialog",function()
    return BaseView.new("HeroTrialDialog.json")
end)

function HeroTrialDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initBack()
    self:initUI()
    display.showDialog(self)
    --挑战次数
    self.allCNum = const.TrialCGTimes
    self:getallpvt()
end

function HeroTrialDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))
end

function HeroTrialDialog:onQuestion()
    HelpDialog.new("dataQuestionHeroTrial")
end

function HeroTrialDialog:initUI()
    if self.mainNode then
        self.mainNode:removeFromParent(true)
    end
    self.mainNode = ui.node()
    self:addChild(self.mainNode)
    self:loadView("leftViews",self.mainNode)
    GameUI.addItemIcon(self.mainNode,10,const.ResTrials,0.4,490,694,false)
    self:loadView("rightViews",self.mainNode)
    self:insertViewTo()

    self.labelMyRankingValue:setVisible(false)
    self.labelMyIntegralValue:setVisible(false)
    self.labelChallengeChanceValue:setVisible(false)
    self.labelEveryDayValue:setVisible(false)

    --排行榜
    self.butRank:setListener(function()
        AllRankingListDialog.new(3)
    end)

    self.butBuyNum:setListener(function()
        print("购买")
        if self.allCNum-self.params.cnum+self.params.bnum>0 then
            print("挑战次数不为0")
            display.pushNotice(Localize("stringTrial1"))
        return
        end

        local num = GameLogic.getUserContext():getVipPermission("pvts")[2]
        local remainNum = const.TrialBuyTimes+num-self.params.bnum
        if remainNum<=0 then
            print("达到购买上限")
            display.pushNotice(Localize("stringTrial2"))
            return
        end
        display.showDialog(AlertDialog.new(1,Localize("alertTitleNormal"),Localizef("stringSureBuyTrialTimes",{a=remainNum}),{ctype=const.ResCrystal, cvalue=200,callback=function()
            self:buypvttimes()
        end}))
        return
    end)
    self.butBuyNum:setVisible(false)

    self.butSetLineup:setListener(function()
        print("设置阵容")
        HeroTrialLineupDialog.new()
    end)

    self.butReplace:setListener(function()
        print("换一批")
        display.showDialog(AlertDialog.new(1,Localize("alertTitleNormal"),Localize("labelSureReplace"),{ctype=const.ResGold, cvalue=self.refreshGold,callback=function()
            if self.pvtmatch then
                self:pvtmatch()
            end
        end}))
    end)

    local majorCityLv = GameLogic.getUserContext().buildData:getMaxLevel(const.Town)
    self.refreshGold = 4500
    if majorCityLv >= 8 then
        self.refreshGold = 6000+(majorCityLv-8)*2000
    end
    self.labelReplaceCost:setString(self.refreshGold)

    --试炼商店
    self.butTrialShop:setListener(function()
        print("试炼商店")
        StoreDialog.new({stype="equip",idx=3,pri=display.getDialogPri()+1})
    end)

    --战斗记录

    self.butBattleRecord:setListener(function()
        if not self.params then
            return
        end
        self.butBattleRecordRedPoint:setVisible(false)

        --把lastlg设置到看过的
        local templogid = 0
        for k,v in pairs(self.params.battlelog) do
        if k~="lastlg" then
                for i,value in ipairs(v) do
                    if value[1]>templogid then
                        templogid= value[1]
                    end
                end
            end
        end
        self.params.battlelog.lastlg = templogid
        HeroTrialBattleLogDialog.new(self.params)
    end)
end

function HeroTrialDialog:reloadUI()
    self.labelMyRankingValue:setVisible(true)
    self.labelMyIntegralValue:setVisible(true)
    self.labelChallengeChanceValue:setVisible(true)
    self.labelEveryDayValue:setVisible(true)
    --我的排名
    self.labelMyRankingValue:setString(self.params.rk<0 and Localize("labelNotTop") or self.params.rk+1)
    self.labelMyIntegralValue:setString(self.params.sc)
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffPVT)
    local cnum = self.allCNum - self.params.cnum + self.params.bnum + buffInfo[4] - buffInfo[5]
    local cmax = self.allCNum + buffInfo[4]
    self.labelChallengeChanceValue:setString(cnum .. "/" .. cmax)
    if cnum <= 0 then
        ui.setColor(self.labelChallengeChanceValue,"red")
    end
    local canReward
    local resPvtSet = SData.getData("AllRankConfig",3)
    for i,v in ipairs(resPvtSet) do
        if v.minrk<=self.params.rk+1 and self.params.rk+1<=v.maxrk then
            canReward = v.drewards
            break
        end
    end

    --每天
    local AllRankRewards = SData.getData("AllRankRewards")
    for k,v in pairs(AllRankRewards) do
        if v.id == canReward then
            canReward = v.gnum
        end
    end
    self.labelEveryDayValue:setString(canReward or 0)
    if self.allCNum-self.params.cnum+self.params.bnum>0 then
        self.butBuyNum:setVisible(false)
    else
        self.butBuyNum:setVisible(true)
    end

    self.butBattleRecordRedPoint:setVisible(false)
    for k,v in pairs(self.params.battlelog) do
        if k~="lastlg" then
            for i,value in ipairs(v) do
                if value[1]>self.params.battlelog.lastlg then
                    self.butBattleRecordRedPoint:setVisible(true)
                else
                    
                end
            end
        end
    end
end

function HeroTrialDialog:reloadHero()
    if self.butGoChallengeArr then
        self.butGoChallengeArr = nil
    end
    --刷新金币变红
    if GameLogic.getUserContext():getRes(const.ResGold)<self.refreshGold then
        ui.setColor(self.labelReplaceCost,"red")
    end

    if self.heroNode then
        self.heroNode:removeAllChildren(true)
    else
        self.heroNode = ui.node()
        self.mainNode:addChild(self.heroNode)
    end

    local bg,temp
    for i=1,3 do
        bg=ui.node()
        display.adapt(bg, 618+(i-1)*462, 324, GConst.Anchor.LeftBottom)
        self.heroNode:addChild(bg)

        self:loadView("nodeViews1",bg)

        local but=ui.button({463,701},nil,{})
        display.adapt(but,0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(but)
        self.butLookChallenge=but

        local player = self.params.player["player"..i]
        local butNode=but:getDrawNode()
        self:loadView("nodeViews2",butNode)

        local heros = {}
        for i,v in ipairs(player.hinfo) do
            local num = math.floor(v[2]/10000)
            local idx = math.floor(num/10)
            local t = num%10

            if t == 1 then
                table.insert(heros,v)
            end
        end


        local spe = GameLogic.getMax(heros,4)

        local mrid = math.random(1001,1003)
        GameUI.addHeroFeature(butNode, spe and spe[3] or mrid, 0.6,232,350,0,true)
        self:insertViewTo()
        
        self.labelRankingValue:setString(player.uinfo[4]<0 and Localize("labelNotTop") or player.uinfo[4]+1)
        self.labelPlayerName:setString(player.uinfo[2])
        self.labelWinIntegralValue:setString(player.getscore)
        local ProCombat = player.uinfo[6] or 0
        self.lb_power:setString(Localizef("propertyCombValue", {num = ProCombat}))

        self.butChallenge:setListener(function()
            print("挑战")
            self:pvtbeginbattle(i)
        end)

        if not self.butGoChallengeArr then
            self.butGoChallengeArr = {}
        end
        table.insert(self.butGoChallengeArr,self.butChallenge)
        local cantAttack = self.allCNum-self.params.cnum+self.params.bnum<=0
        self.cantAttack=cantAttack
        if cantAttack then
            self.butChallenge:setGray(true)
        end
        but:setListener(function()
            HeroTrialSeeDialog.new(player,self,function()
                print("挑战")
                if not self.pvtbeginbattle then
                    print("对话框已经关闭")
                    return
                end
                self:pvtbeginbattle(i)
            end)
        end)
    end
end

function HeroTrialDialog:updateMy(diff)
    if self.labelMyRankingValue then
        self.labelMyRankingValue:setString(self.params.rk<0 and Localize("labelNotTop") or self.params.rk+1)
    end
    if self.labelMyIntegralValue then
        self.labelMyIntegralValue:setString(self.params.sc)
    end
    if self.labelChallengeChanceValue then
        local cnum = self.allCNum-self.params.cnum+self.params.bnum
        self.labelChallengeChanceValue:setString(cnum .. "/" .. self.allCNum)
        if cnum<=0 then
            ui.setColor(self.labelChallengeChanceValue,"red")
        else
            ui.setColor(self.labelChallengeChanceValue,"white")
        end
    end

    if self.butGoChallengeArr then
        local sign = true
        if self.allCNum-self.params.cnum+self.params.bnum>0 then
            sign = false
        end
        self.cantAttack=sign
        for i,v in ipairs(self.butGoChallengeArr) do
            v:setGray(sign)
        end
    end

    if self.labelReplaceCost then
        local majorCityLv = GameLogic.getUserContext().buildData:getMaxLevel(const.Town)
        if majorCityLv >= 8 then
            self.refreshGold = 6000+(majorCityLv-8)*2000
        end
        self.labelReplaceCost:setString(self.refreshGold)
    end

end

---------------------------------------------------------------------------------

function HeroTrialDialog:getallpvt()
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getallpvt",{},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            GameLogic.getUserContext().pvtdata = data
            self.params = data
            if data.actInfo then
                GameLogic.getUserContext().activeData:setActRecord(data.actInfo[1], const.ActTypeBuffPVT, data.actInfo[2], data.actInfo[4])
            end
            if self.initUI then
                self:reloadUI()
                self:reloadHero()
                RegActionUpdate(self, Handler(self.updateMy, self, 0.25), 0.25)
            end
        end
    end)
end

function HeroTrialDialog:pvtmatch()
    if not GameNetwork.lockRequest() then
        return
    end
    local refreshGold = self.refreshGold
    if not refreshGold or refreshGold < 0 then
        return
    end
    GameLogic.getUserContext():changeRes(const.ResGold,-refreshGold)
    _G["GameNetwork"].request("pvtmatch",{syn_id=GameLogic.getUserContext():getLastSynId(), pvtmatch = {1}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            self.params.player = data
            if self.initUI then
                self:reloadHero()
            end
        end
    end)
end

function HeroTrialDialog:pvtbeginbattle(i)
    if self.allCNum-self.params.cnum+self.params.bnum<=0 then
        print("挑战次数不足")
        display.pushNotice(Localize("stringTrial3"))
        return
    end
    for i=1,3 do
        local hero = GameLogic.getUserContext().heroData:getHeroByLayout(const.LayoutPvtAtk,i,1)
        if not hero then
            display.pushNotice(Localize("stringHeroTrialNotice2"))
            return
        end
    end
    if self.clicked then
        return
    end
    self.clicked = true
    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=5,pvtdata = self.params,idx = i, isPrepare=true})
    display.closeDialog()
end

function HeroTrialDialog:buypvttimes()
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdPvtBTimes})
    self.params.bnum = self.params.bnum+1
    GameLogic.getUserContext():changeRes(const.ResCrystal,-200)
    GameLogic.statCrystalCost("试炼购买挑战次数消耗",const.ResCrystal,-200)
    if self.initUI then
        self.butBuyNum:setVisible(false)
    end
end

function HeroTrialDialog:getpvtreward()
    if self.params.reward==0 then
        print("试炼币为0，不可领取")
    end

    _G["GameNetwork"].request("getpvtreward",{},function(isSuc,data)
        if isSuc then
            print("领取成功")
            self.params.reward = 0
        end
    end)
end
return HeroTrialDialog
