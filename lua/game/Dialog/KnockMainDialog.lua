local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockMainDialog = class(DialogViewLayout)

local ONE_HOUR = 3600
local ONE_DAY = 86400
function KnockMainDialog:onInitDialog()
   self:initUI()
   self:initData()
   self:checkGuide()
end

function KnockMainDialog:initData()
    self.context = GameLogic.getUserContext()
    self.isStart = false            --开赛
    self.dMatchFlag = 0                  --小组赛标志
    self.oMatchFlag = 0                  --淘汰赛标志
    self.isPlayer = false           --参赛
    self.isLoser = false            --战败
    self.enemy = {}                 --对手
    self.ranking = 0                --排名
    self:getDivideServerData()
end

function KnockMainDialog:getDivideServerData()
    if KnockMatchData:checkNeedRefreshData(1) then
        GameNetwork.lockRequest()
        GameUI.setLoadingShow("loading", true, 0)
        local wk = KnockMatchData:getWeek()
        GameNetwork.request("getPvzUInfos", {wk = wk}, self.updateData, self)
    else
        self:updateData()
    end
end

function KnockMainDialog:updateData(isSuc, data)
    GameNetwork.unlockRequest()
    if isSuc then
        GameUI.setLoadingShow("loading", false, 0)
        KnockMatchData:initDivideDataWithServer(data)
        GameEvent.sendEvent(GameEvent.showKnockTip)
    end
    if self.deleted then
        return
    end
    self:updateUI()
end

function KnockMainDialog:initUI()
    self:setLayout("KnockMainDialog.json")
    self:loadViewsTo()

    self.lb_divideTime:setVisible(false)
    self.lb_outTime:setVisible(false)
    self.img_whiteBg:setColor({169, 191, 202})

    self.btn_divideShowReport:setScriptCallback(ButtonHandler(self.clickDivideBtnReport, self))
    self.btn_boxEff:setScriptCallback(ButtonHandler(self.clickDivideBtnEffect, self))

    self.btn_divideStart:setScriptCallback(ButtonHandler(self.clickDivideBtnStart, self))
    self.btn_divideHelp:setScriptCallback(ButtonHandler(self.clickDivideBtnDivideHelp, self))
    self.btn_rankDes1:setScriptCallback(function ()
        local KnockDivideStageDialog = GMethod.loadScript("game.Dialog.KnockDivideStageDialog")
        display.showDialog(KnockDivideStageDialog.new())
    end)

    self.btn_outStart:setScriptCallback(ButtonHandler(self.clickOutBtnStart, self))
    self.btn_outHelp:setScriptCallback(ButtonHandler(self.clickOutBtnHelp, self))
    self.btn_rankDes2:setScriptCallback(function ()
        RewardDescription.new(4)
    end)

    self.btn_close:setScriptCallback(ButtonHandler(self.close, self))
    GameEvent.bindEvent(self.btn_boxEff.view, GameEvent.KonckRefreshReward, self, self.updateDivideDes)
end

function KnockMainDialog:updateUI()
    self:clearRegTimeUpdate()
    self:updateDivideTitle()
    self:updatedivideTimeScheduler()
    self:updateDivideDes()
    self:updateOutTitle()
    self:updateOutTimeScheduler()
    self:updateOutDes()
end

function KnockMainDialog:clearRegTimeUpdate()
    if self.lb_divideTime.view then
        UnregTimeUpdate(self.lb_divideTime.view)
    end
    if self.lb_outTime.view then
        UnregTimeUpdate(self.lb_outTime.view)
    end
end

function KnockMainDialog:updateDivideTitle()

end

--flag:1、未开赛 2、对战 3、休战 4、新服 已结束
function KnockMainDialog:isDivideStart()
    local flag = 1
    local startTime = KnockMatchData:getTimeConfigs()
    local nowTime = GameLogic.getSTime()
    local endTime,isOver
    local _startTime = GameLogic.getUnionBattleTime()[1]
    local _endTime = GameLogic.getUnionBattleTime()[2]
    if GameLogic.useTalentMatch then
        local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffKnockMatch)
        startTime=buffInfo[2]
        endTime=(buffInfo[2]+buffInfo[3])/2-1800
        isOver=nowTime>endTime
    end
    local leftTime = nowTime - startTime
    if GameLogic.useTalentMatch then
        --活动时间内
        if leftTime>=0 and not isOver then
            if(nowTime>=_startTime) and (nowTime<=_endTime) then
                flag = 3
            else
                flag = 2
            end
        elseif isOver then
            flag = 4
        else
            leftTime=-leftTime
        end
    else
        if leftTime >= 0 then
            if (nowTime>=_startTime) and (nowTime<=_endTime) then
                flag = 3
            else
                flag = 2
            end
        else
            leftTime = -leftTime
        end
    end
    return flag, leftTime
end

function KnockMainDialog:updatedivideTimeScheduler()
    local function callback()
        local dinfo = KnockMatchData:getDinfo()
        local flag, leftTime = self:isDivideStart()
        --1、如果有状态转换，刷新数据；
        if (self.dMatchFlag~=0) and (flag~=self.dMatchFlag) then
            self.dMatchFlag = 0
            KnockMatchData:updateNeedRefreshData(1, true)
            self:getDivideServerData()
        else
            self.dMatchFlag = flag
        end

        local timeStr
        if flag==1 then
            timeStr = Localizet(leftTime)
            self.lb_divideTime:setString(timeStr)
            self.lb_divideTime:setVisible(true)
        elseif flag == 2 then
            if dinfo.dFlag ~= 3 then
                leftTime = GameLogic.getUnionBattleTime()[2] - GameLogic.getSTime()
            else
                leftTime = GameLogic.getUnionBattleTime()[1] - GameLogic.getSTime()
            end
            timeStr = Localizet(leftTime)
            self.lb_divideTime:setString(timeStr)
            self.lb_divideTime:setVisible(true)
        elseif flag == 3 then
            leftTime = GameLogic.getUnionBattleTime()[2] - GameLogic.getSTime()
            timeStr = Localizet(leftTime)
            self.lb_divideTime:setString(timeStr)
            self.lb_divideTime:setVisible(true)
        elseif flag == 4 then
            self.nd_divideTime:setVisible(false)
        end
    end
    callback()
    RegTimeUpdate(self.lb_divideTime.view, callback, 1)
end

function KnockMainDialog:updateMatchNum()
    local flag, leftTime = self:isDivideStart()
    local _startTime = GameLogic.getUnionBattleTime()[1]
    local nowTime = GameLogic.getSTime()
    local matchNum = KnockMatchData:getMatchNumber()

    --如果处于休战期，判断是后半个休战期，轮次显示之前的
    if flag == 3 and (nowTime >= (_startTime + 1800)) then
        matchNum = matchNum-1
    end
    self.lb_divideNumDes3:setString(Localizef("labKnockRound", {num = matchNum}))

end

function KnockMainDialog:updateDivideDes()
    self.btn_boxEff:setVisible(false)
    self.nd_divideDes1:setVisible(false)
    self.nd_divideDes2:setVisible(false)
    self.nd_divideDes3:setVisible(false)
    self.nd_divideStart:setVisible(false)
    self.btn_divideStart:setVisible(false)
    self.btn_divideStart.view:setGray(false)
    self.btn_divideShowReport:setVisible(false)

    local dinfo = KnockMatchData:getDinfo()
    local matchNum = KnockMatchData:getMatchNumber()
    local flag, leftTime = self:isDivideStart()
    if flag==1 then --未开赛
        self.nd_divideDes1:setVisible(true)
        if dinfo.dFlag ~= 1 then --报名
            self.nd_divideStart:setVisible(true)
        else
            self.btn_divideStart:setVisible(true)
        end
        if GameLogic.useTalentMatch then
            self.divideBg:setSValue(-100)
        end
        self.lb_divideTimeDes:setString(Localize("labKnocktimer"))
    elseif flag == 2 then --开赛
        if dinfo.dFlag == 1 then
            self.nd_divideDes1:setVisible(true)
            self.lb_divideDes1:setString(Localizef("labKnockRound", {num = matchNum}))
            self.btn_divideStart:setVisible(true)
            self.lb_divideTimeDes:setString(Localize("labKnockNext"))
        elseif dinfo.dFlag == 2 then
            self.nd_divideDes1:setVisible(true)
            self.lb_divideDes1:setString(Localizef("labKnockRound", {num = matchNum}))
            self.btn_divideStart:setVisible(false)
            self.nd_divideStart:setVisible(true)
            self.lb_divideStart:setString(Localize("btnClickStart"))
            self.lb_divideTimeDes:setString(Localize("labKnockNext"))
        elseif dinfo.dFlag == 3 then
            self.nd_divideDes3:setVisible(true)
            self.btn_divideStart:setVisible(true)
            self.nd_divideStart:setVisible(false)
            self.lb_divideStart:setString(Localize("btnClickChallenge"))
            self.lb_divideTimeDes:setString(Localize("labNowOvering"))
            self.lb_divideNumDes3:setString(Localizef("labKnockRound", {num = matchNum}))
            self.lb_divideScore3:setString(Localizef("labKnockTodayScore", {num = dinfo.dScore}))
            self.lb_divideRank3:setString(Localizef("labKnockTodayRank", {num =  dinfo.dRank}))
            -- self.img_stage:setTexture("")
            local reborn = dinfo.dEnemy[1].def.reborn
            self.lb_divideReborn:setString(reborn)
            local stage = KnockMatchData:getStageByScore(dinfo.dScore)
            KnockMatchData:changeStageIcon(self.img_stage, stage)
            -- local path = KnockMatchData:getStageIconPath(stage)
            -- self.img_stage.view:setTexture(path)
            local _dEnemy = KnockMatchData:getdEnemys()
            for i=1, 5 do
                if not GameLogic.isEmptyTable(_dEnemy[i]) then
                    local destroy = _dEnemy[i].def.destroy
                    self["nd_dividePbr"..i]:setVisible(true)
                    self["pbr_divide"..i]:setProcess(false, 1-(destroy/100))
                else
                    self["nd_dividePbr"..i]:setVisible(false)
                end
            end
        end
        self:addDivideReportEffect()

    elseif flag == 3 then --休战
        if dinfo.dFlag == 1 then
            self.nd_divideDes2:setVisible(true)
            self.lb_divideDes2:setString(Localize("labNowOver"))
            self.lb_divideNumDes2:setString(Localizef("labKnockRound", {num = matchNum}))
            self.btn_divideStart:setVisible(true)
            self.nd_divideStart:setVisible(false)
            self.lb_divideTimeDes:setString(Localize("labKnockNext"))

        elseif dinfo.dFlag == 2 then
            self.nd_divideDes2:setVisible(true)
            self.lb_divideDes2:setString(Localize("labNowOver"))
            self.lb_divideNumDes2:setString(Localizef("labKnockRound", {num = matchNum}))
            self.nd_divideStart:setVisible(true)
            self.lb_divideTimeDes:setString(Localize("labKnockNext"))

        elseif dinfo.dFlag == 3 then
            self.nd_divideDes3:setVisible(true)
            self.lb_divideNumDes3:setString(Localizef("labKnockRound", {num = matchNum}))
            self.lb_divideScore3:setString(Localizef("labKnockTodayScore", {num = dinfo.dScore}))
            self.lb_divideRank3:setString(Localizef("labKnockTodayRank", {num =  dinfo.dRank}))

            self.btn_divideStart:setVisible(true)
            self.btn_divideStart.view:setGray(true)
            self.nd_divideStart:setVisible(false)
            self.lb_divideStart:setString(Localize("btnClickChallenge"))
            self.lb_divideTimeDes:setString(Localize("labKnockNext"))

        end
        self:addDivideReportEffect()
    elseif flag == 4 then --新服已结束
        self.nd_divideDes2:setVisible(true)
        self.lb_divideNumDes2:setVisible(false)
        self.lb_divideDes2:setString(Localize("labNowOver"))
        self.lb_divideDes2:setPosition(-8,5)
        self:addDivideReportEffect()
        if GameLogic.useTalentMatch then
            self.divideBg:setSValue(-100)
        end
    end
    self:updateMatchNum()
end

function KnockMainDialog:addDivideReportEffect()
    local flag = KnockMatchData:canGetDivideReward()
    if flag then
        local node = ui.csbNode("UICsb/KnockDivideBox.csb")
        local action = ui.csbTimeLine("UICsb/KnockDivideBox.csb")
        node:runAction(action)
        display.adapt(node, 100, 100, GConst.Anchor.Center)
        action:gotoFrameAndPlay(0,true)
        self.btn_boxEff.view:getDrawNode():addChild(node)
    end
    self.btn_boxEff:setVisible(flag)
    self.btn_divideShowReport:setVisible(not flag)
    if GameLogic.useTalentMatch then
        local buff = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffKnockMatch)
        if GameLogic.getSTime() >= (buff[2] + buff[3]) / 2 then
            self.lb_divideShowReport:setString(Localize("labelRankList"))
            self.btn_divideShowReport:setScriptCallback(ButtonHandler(AllRankingListDialog.new, 11))
        end
    end
end

function KnockMainDialog:clickDivideBtnReport()
    local KnockDivideReportDialog = GMethod.loadScript("game.Dialog.KnockDivideReportDialog")
    display.showDialog(KnockDivideReportDialog.new())
end

function KnockMainDialog:clickDivideBtnEffect()
    local KnockDivideReportDialog = GMethod.loadScript("game.Dialog.KnockDivideReportDialog")
    display.showDialog(KnockDivideReportDialog.new({tid = 3}))

end

function KnockMainDialog:clickDivideBtnStart()
    local dinfo = KnockMatchData:getDinfo()
    local matchNum = KnockMatchData:getMatchNumber()
    local flag, leftTime = self:isDivideStart()

    local function callback(isSuc, data)
        if isSuc then
            if self.deleted then
                return
            end
            --打开拉取信息开关
            KnockMatchData:joindMatch()
            GameEvent.sendEvent(GameEvent.openKnockGetInfo)
            GameEvent.sendEvent(GameEvent.showKnockTip)
            self:deleteArrow()
            -- KnockMatchData:setDivideGuideStep(4)
            KnockMatchData:setDivideGuideStep(100)
            self:updateUI()
            display.showDialog(AlertDialog.new(0, Localize("labKnockDivideName"), Localize("labJoinKnockDivide") ))
        end
    end
    if flag == 1 then    --赛季未开始
        if dinfo.dFlag == 1 then
            GameNetwork.request("joinPvzBattle", {wk = KnockMatchData:getWeek()}, callback)
        end
    elseif flag == 2 then
        if dinfo.dFlag == 1 then
            GameNetwork.request("joinPvzBattle", {wk = KnockMatchData:getWeek()}, callback)
        elseif dinfo.dFlag == 3 then
            self:jumpToDivideDialog()
        end
    elseif flag == 3 then
        if dinfo.dFlag == 1 then
            GameNetwork.request("joinPvzBattle", {wk = KnockMatchData:getWeek()}, callback)
        elseif dinfo.dFlag == 3 then
            display.pushNotice(Localize("labNowOver"))
        end
    end

    local step = KnockMatchData:getDivideGuideStep()
    if step then
        if step == 2 then
            self:deleteArrow()
            -- KnockMatchData:setDivideGuideStep(4)
            KnockMatchData:setDivideGuideStep(100)
        elseif step == 3 then
            self:deleteArrow()
            -- KnockMatchData:setDivideGuideStep(4)
            KnockMatchData:setDivideGuideStep(100)
        elseif step == 4 then
            self:deleteArrow()
            KnockMatchData:setDivideGuideStep(100)
        elseif step == 5 then
            self:deleteArrow()
            KnockMatchData:setDivideGuideStep(100)
        end
    end
end

function KnockMainDialog:clickDivideBtnDivideHelp()
    HelpDialog.new(Localize("KnockDivideHelp"))
    local step = KnockMatchData:getDivideGuideStep()
    if step == 1 then
        KnockMatchData:setDivideGuideStep(2)
        self:checkGuide()
    end
end

function KnockMainDialog:jumpToDivideDialog()
    local KnockDivideDialog = GMethod.loadScript("game.Dialog.KnockDivideDialog")
    display.showDialog(KnockDivideDialog.new())
end


function KnockMainDialog:isOutStart()
    local flag = 1
    local startTime = KnockMatchData:getOutStartTime()
    local nowTime = GameLogic.getSTime()
    local endTime
    local _startTime = GameLogic.getUnionBattleTime()[1]
    local _endTime = GameLogic.getUnionBattleTime()[2]
    if GameLogic.useTalentMatch then
        local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffKnockMatch)
        startTime=(buffInfo[2]+buffInfo[3])/2+1800
        endTime=buffInfo[3]
    end
    local leftTime = nowTime - startTime
    if leftTime >= 0 then
        if (nowTime>=_startTime) and (nowTime<=_endTime) then
            flag = 3
        else
            flag = 2
        end
    else
        leftTime = -leftTime
    end
    return flag, leftTime
end

function KnockMainDialog:updateOutTitle()

end

--flag:1、未开赛 2、对战 3、休战
function KnockMainDialog:updateOutTimeScheduler()
    self.nd_outTime:setVisible(false)
    local function callback()
        local dinfo = KnockMatchData:getOinfo()
        local flag, leftTime = self:isOutStart()
        local timeStr
        self.nd_outTime:setVisible(true)
        if flag==1 then
            timeStr = Localizet(leftTime)
            self.lb_outTime:setString(timeStr)
            self.lb_outTime:setVisible(true)
        elseif flag == 2 then
            self.nd_outTime:setVisible(false)
        elseif flag == 3 then
            leftTime = GameLogic.getUnionBattleTime()[2] - GameLogic.getSTime()
            timeStr = Localizet(leftTime)
            self.lb_outTime:setString(timeStr)
            self.lb_outTime:setVisible(true)
        end
    end
    callback()
    RegTimeUpdate(self.lb_outTime.view, callback, 1)
end

function KnockMainDialog:updateOutDes()
    local oinfo = KnockMatchData:getOinfo()
    local oFlag = oinfo.oFlag
    local flag, leftTime = self:isOutStart()
    local num = KnockMatchData:getMatchNumber()
    local _num = self:getOutMatchNum()
    self.lb_outStart:setString(Localize("labClickLook"))
    self.lb_outTimeDes:setString(Localize("labKnocktimer"))
    if flag == 1 then
        self.nd_outDes1:setVisible(true)
        if GameLogic.useTalentMatch then
            self.outBg:setSValue(-100)
        end
        self.lb_outDes1:setString(Localize("labKnockBeforeMajorMatch"))
    elseif flag ==2 then
        local week = KnockMatchData:getWeek()
        if week == 1 then
            self.nd_outDes1:setVisible(true)
            self.lb_outDes1:setString(Localize("labKnockGoToGamble"))
        elseif oFlag == 1 then
            self.nd_outDes4:setVisible(true)
            self.lb_outDes4:setString(Localizef("labKnockMajorMatch", {num = _num}))
        elseif oFlag == 2 then
            local oEnemy = oinfo.oEnemy
            if oinfo.noEnemy then
                self.nd_outDes6:setVisible(true)
                self.lb_outDes6:setString(Localize("labOutNoneEnemy"))
            else
                self.nd_outDes3:setVisible(true)
                self.lb_OutEnemyLv:setString(oEnemy.lv)
                self.lb_outEnemyName:setString(oEnemy.name)
                self.lb_outEnemyScore:setString(oEnemy.score)
                self.lb_outStart:setString(Localize("btnClickChallenge"))
                GameUI.addPlayHead(self.nd_heroIcon, {id=oEnemy.head, scale = 1.1, x=0,y=0,z=0,blackBack=true, noBlackBack = false})
            end
        elseif oFlag == 3 then
            self.nd_outDes2:setVisible(true)
            self.lb_outDes2:setString(Localize("labKnockRank"))
            self.lb_outDes12:setString(Localizef("labKnockStrong", {num = oinfo.oRank}))
        end
    elseif flag == 3 then
        self.nd_outDes5:setVisible(true)
        self.lb_outDes52:setString(Localizef("labKnockBeforeStrongMajorMatch", {num = _num}))
    end
end

function KnockMainDialog:clickOutBtnStart()
    -- self:jumpToOutSecondDialog()
    -- do return end
    local oinfo = KnockMatchData:getOinfo()
    local oFlag = oinfo.oFlag
    local groupId = oinfo.groupId
    local flag, leftTime = self:isOutStart()
    if flag == 1 then
        local str = Localize("labKnockBeforeMajorMatch")
        display.pushNotice(str)
    elseif flag == 2 then
        if oFlag == 1 then
            self:jumpToOutDialog()
        elseif oFlag == 2 then
            if oinfo.noEnemy then
                self:jumpToOutSecondDialog(groupId)
            else
                local week = KnockMatchData:getWeek()
                if week == 1 then
                    self:jumpToOutSecondDialog(groupId)
                else
                    self:jumpToOutMajorDialog()
                end
            end
        elseif oFlag == 3 then
            if KnockMatchData:checkInEight() then
                self:jumpToOutSecondDialog()
            else
                self:jumpToOutDialog()
            end
        end
    elseif flag == 3 then
        local num = self:getOutMatchNum()
        local str = Localizef("labKnockBeforeStrongMajorMatch", {num = num})
        display.pushNotice(str)
    end
end

function KnockMainDialog:getOutMatchNum()
    local num = checknumber(KnockMatchData:getMatchNumber())
    local numArr = {64, 32, 16, 8, 4, 2, 1}
    return numArr[num]
end

function KnockMainDialog:clickOutBtnHelp()
    HelpDialog.new("KnockOutHelp")
end

function KnockMainDialog:jumpToOutSecondDialog()
    -- self:jumpToOutInviteDialog()
    -- do return end
    local oinfo = KnockMatchData:getOinfo()
    local groupId = oinfo.groupId
    local KnockOutSecondDialog = GMethod.loadScript("game.Dialog.KnockOutSecondDialog")
    display.showDialog(KnockOutSecondDialog.new({groupId = groupId}))
end

function KnockMainDialog:jumpToOutDialog()
    local KnockOutDialog = GMethod.loadScript("game.Dialog.KnockOutDialog")
    display.showDialog(KnockOutDialog.new())
end

function KnockMainDialog:jumpToOutMajorDialog()
    local oinfo = KnockMatchData:getOinfo()
    local tid = oinfo.oEnemy.uid
    local KnockOutMajorDialog = GMethod.loadScript("game.Dialog.KnockOutMajorDialog")
    display.showDialog(KnockOutMajorDialog.new({tid = tid}))
end

function KnockMainDialog:jumpToFamousManDialog()
    local KnockFamousDialog = GMethod.loadScript("game.Dialog.KnockFamousDialog")
    display.showDialog(KnockFamousDialog.new())
end

function KnockMainDialog:jumpToOutInviteDialog()
    local KnockOutInviteDialog = GMethod.loadScript("game.Dialog.KnockOutInviteDialog")
    display.showDialog(KnockOutInviteDialog.new())
end

function KnockMainDialog:jumpToPlayerDialog()
    local KnockOutPlayerDialog = GMethod.loadScript("game.Dialog.KnockOutPlayerDialog")
    display.showDialog(KnockOutPlayerDialog.new())
end

function KnockMainDialog:jumpToOutReport()
    local KnockOutReportDialog = GMethod.loadScript("game.Dialog.KnockOutReportDialog")
    display.showDialog(KnockOutReportDialog.new({params = {isOwn = true}}))
end

function KnockMainDialog:checkGuide()
    local step = KnockMatchData:getDivideGuideStep()
    if not step then
        return
    end
    if step == 1 then
        self:addArrow(self.btn_divideHelp.view)
    elseif step == 2 then
        if KnockMatchData:checkCanJoinDivide() then
            local time = KnockMatchData:getCanStartFightTime()
            KnockMatchData:setDivideGuideTime(time)
            self:addArrow(self.btn_divideStart.view)
        else
            self:addArrow(self.lb_divideTime.view)
            self.guideSid = GMethod.schedule(function()
                self:deleteArrow()
                GMethod.unschedule(self.guideSid)
                self.guideSid = nil
                local context = GameLogic.getUserContext()
                local function callback()
                    KnockMatchData:setDivideGuideStep(100)
                end
                display.showDialog(StoryDialog.new({context=context,storyIdx=307, callback = callback}),false,true)
            end, 4, false)
        end
    elseif step == 3 then
        self:addArrow(self.btn_divideStart.view)
    elseif step == 4 then
        KnockMatchData:setDivideGuideStep(5)
        if KnockMatchData:checkCanStartFight() then
            self:addArrow(self.btn_divideStart.view)
        end
    elseif step == 5 then
        if KnockMatchData:checkCanStartFight() then
            self:addArrow(self.btn_divideStart.view)
        end
    end
end

function KnockMainDialog:addArrow(node)
    self:deleteArrow()
    local size = node:getContentSize()
    local context = GameLogic.getUserContext()
    self.guideKnockArrow = context.guideHand:showArrow(node, size.width/2, size.height/2, 20)
end

function KnockMainDialog:deleteArrow()
    if self.guideKnockArrow then
        self.guideKnockArrow:removeFromParent()
    end
    self.guideKnockArrow = nil
end

function KnockMainDialog:clearScheduler()
    if self.guideSid then
        GMethod.unschedule(self.guideSid)
        self.guideSid = nil
    end
end

function KnockMainDialog:close()
    display.closeDialog(self.priority)
    self:deleteArrow()
    self:clearScheduler()
end

return KnockMainDialog
