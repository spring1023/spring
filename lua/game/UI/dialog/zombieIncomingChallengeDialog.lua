local const = GMethod.loadScript("game.GameLogic.Const")
local SD = GMethod.loadScript("data.StaticData").getData
--僵尸来袭挑战对话框
local zombieIncomingChallengeDialog = class2("zombieIncomingChallengeDialog",function()
    return BaseView.new("zombieIncomingChallengeDialog.json")
end)

function zombieIncomingChallengeDialog:ctor(index, params)
    self.index,self.params = index, params
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    display.showDialog(self,true,true)
    self:initBack()
    RegActionUpdate(self, Handler(self.updateMy, self, 0.5), 0.5)
end

function zombieIncomingChallengeDialog:onQuestion()
    HelpDialog.new("dataQuestionZomInClg")
end

function zombieIncomingChallengeDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth-1))
    viewTab.butBack:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))
    self:loadView("leftViews")
    self:loadView("rightviews")
    self:loadView("downViews")
    self:randomRewardViews()
end
function zombieIncomingChallengeDialog:randomRewardViews()
    --可获得奖励
    --显示优先级：装备碎片>部件材料>锻造石>资源
    -- 若奖励超过5个，有金币的话不显示金币，其次是锻造石，再者是 材料（按顺序）
    local rewardall = SD("pvjitem",self.index)
    local rewardList = {}
    for k,v in pairs(rewardall) do
        table.insert(rewardList,v)
    end
    local showList = {}
    local odList = {8,1,2,10,-1,-2}
    for i,rtype in ipairs(odList) do
        local idx = 1
        for i=1,#rewardList do
            local r = rewardList[idx]
            if r then
                if rtype>0 then
                    if rtype == 10 then
                        if r.itemtype == rtype and r.itemid ~= const.ResGold then
                            table.insert(showList,table.remove(rewardList,idx))
                        else
                            idx = idx+1
                        end
                    else
                        if r.itemtype == rtype then
                            table.insert(showList,table.remove(rewardList,idx))
                        else
                            idx = idx+1
                        end
                    end
                else
                    if rtype == -1 then
                        if r.itemid ~= const.ResGold then
                            table.insert(showList,table.remove(rewardList,idx))
                        else
                            idx = idx+1
                        end
                    else
                        table.insert(showList,table.remove(rewardList,idx))
                    end
                end
            end
        end
    end
    for i,v in ipairs(showList) do
        if i<=5 then
            GameUI.addItemIcon(self,v.itemtype,v.itemid,1,777+(i-1)*220+99,772+99,true)
        end
    end
    self:initOther()
end

function zombieIncomingChallengeDialog:initOther()
    self:insertViewTo()
    --BOSS名称
    self.titleZombieIncomingChallenge:setString(Localize("dataPvjPassName" .. self.index))
    --boss头像
    local bossSet = SD("pvjboss",self.index)
    local bossIdx
    for i=1,5 do
        local set = bossSet["boss"..i]
        if not set then
            break
        end
        bossIdx = i
    end
    local boss = bossSet["boss"..bossIdx]
    local id = boss[KTLen(boss)]
    local scal=1.3
    if id>8000 and id<9000 then
        id = math.floor(id/10)*10
    end
    GameUI.addHeadIcon(self,id,scal,285+231/2,472+276/2,3)

    local HeroData = GMethod.loadScript("game.GameLogic.HeroData")
    local hm = HeroData.new():makeHero(id)
    hm.level = bossSet.lv
    local hd = hm:getHeroData()

    --生命
    self.labelBossLifeValue:setString(hd.hp)

    --攻击
    self.labelBossAttackValue:setString(hd.atk)

    --星级
    for j=1,3 do
        if j>self.params.quests[self.index][2] then
            self["battleStar"..j]:setSValue(-100)
        end
    end
    self.butAddPower:setScriptCallback(ButtonHandler(self.onBuyAP, self))
    self.butChallenge:setScriptCallback(ButtonHandler(self.onAttack, self))
    self.butSweep:setScriptCallback(ButtonHandler(self.onSweep, self, false))
    self.butSweepThree:setScriptCallback(ButtonHandler(self.onSweep, self, true))
    self.butBuy:setScriptCallback(ButtonHandler(self.onBuyChance, self))
    self:updateMy(0)
end

function zombieIncomingChallengeDialog:onBuyAP()
    UsePhysicalAgentsDialog.new(self.params)
end

function zombieIncomingChallengeDialog:doSweep(isMulti)
    Sweep2Dialog.new(isMulti, self.params, self.index)
end

-- @brief 调用僵尸来袭挑战的按钮回调
function zombieIncomingChallengeDialog:onAttack()
    local isBossStage, canSweep, costBase, leftChance, leftFree,
        baseChance, apChance = self.params:computeBattleInfo(self.index)
    if baseChance <= 0 then
        display.pushNotice(Localize("stringTrial3"))
    elseif apChance <= 0 then
        display.pushNotice(Localize("stringPhysicalNotEnough"))
    else
        display.closeDialog()
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=6,idx=self.index,bparams = {index = self.index}})
    end
end

-- @brief 扫荡按钮回调事件
-- @params isMulti 是中间的单次按钮还是右侧的多次按钮
function zombieIncomingChallengeDialog:onSweep(isMulti)
    local isBossStage, canSweep, costBase, leftChance, leftFree,
        baseChance, apChance = self.params:computeBattleInfo(self.index)
    if not canSweep then
        display.pushNotice(Localize("stringUnderStart"))
    elseif baseChance <= 0 then
        display.pushNotice(Localize("stringTrial3"))
    elseif apChance <= 0 then
        display.pushNotice(Localize("stringPhysicalNotEnough"))
    elseif leftChance > 0 then
        --当免费扫荡为0走这里
        if leftFree == 0 then
            if not isMulti then
                leftChance = 1
            end
            display.showDialog(AlertDialog.new(1, Localize("labelPrompt"),
                Localizef("labelCrystallSweep", {n = const.PvjSwpBuyNeed * leftChance, m = leftChance}),
                {cvalue = const.PvjSwpBuyNeed * leftChance, ctype = const.ResCrystal,
                yesBut="btnYes", callback = Handler(self.doSweep, self, isMulti)}))
        else
            self:doSweep(isMulti)
        end
    end
end

-- @brief 购买次数按钮回调事件
function zombieIncomingChallengeDialog:onBuyChance()
    if self.params.quests[self.index][5]>=10 then
        display.pushNotice(Localize("stringCantBuyTimes"))
    else
        local num = self.params.quests[self.index][5]
        local cost = 50
        if num == 1 then
            cost =100
        elseif num>1 then
            cost =150
        end

        local otherSetting = {cvalue = cost,ctype = const.ResCrystal,callback = function()
            local context = GameLogic.getUserContext()
            context:changeRes(const.ResCrystal, -cost)
            GameLogic.statCrystalCost("僵尸来袭购买挑战次数消耗",const.ResCrystal, -cost)
            self:resetquesttimes()
        end}
        local dl = AlertDialog.new(1,Localize("labelBuyTimes"),Localizef("stringButAffirm",{cost = cost,num = num}),otherSetting)
        display.showDialog(dl)
    end
end

-- @brief 调用每0.5秒刷新一次UI显示的回调
function zombieIncomingChallengeDialog:updateMy(diff)
    local isBossStage, canSweep, costBase, leftChance, leftFree,
        baseChance, apChance = self.params:computeBattleInfo(self.index)

    self.labelPhysicalExertionValue:setString(tostring(costBase))
    self.labelaAddNum:setString(self.params:getAP().."/" .. const.MaxPvjPoint)

    if isBossStage then
        self.labelTodaySurplusNum:setString(baseChance .."/3")
        self.butBuy:setVisible(baseChance <= 0)
        self.labelTodaySurplus:setVisible(true)
        self.labelTodaySurplusNum:setVisible(true)
        if self.params.quests[self.index][5] >= 10 then
            self.butBuy:setGray(true)
        else
            self.butBuy:setGray(false)
        end
    else
        self.labelTodaySurplus:setVisible(false)
        self.labelTodaySurplusNum:setVisible(false)
        self.butBuy:setVisible(false)
    end
    self.butChallenge:setGray(baseChance <= 0 or apChance <= 0)
    self.butSweep:setGray(not canSweep or apChance <= 0 or baseChance <= 0)
    self.butSweepThree:setGray(not canSweep or apChance <= 0 or baseChance <= 0)

    --maxNum:当前免费扫荡次数剩余
    self.labelFree:setString(Localize("labelResidueFreeSweepNum") .. leftFree)
    if leftFree <= 0 then
        self.btnSweep:setString(Localizef("btnSweepNum", {num = 1}))
        self.btnSweepThree:setString(Localizef("btnSweepNum",{num = leftChance}))
    else
        --免费扫荡
        self.btnSweep:setString(Localizef("btnFreeSweepNum", {num = 1}))
        self.btnSweepThree:setString(Localizef("btnFreeSweepNum", {num = leftChance}))
    end
end

---------------------------------------------------------------------------------

function zombieIncomingChallengeDialog:resetquesttimes()
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdPvjReset,self.index})
    self.params.quests[self.index][5] = self.params.quests[self.index][5]+1
    self.params.quests[self.index][4] = 0
end

return zombieIncomingChallengeDialog
