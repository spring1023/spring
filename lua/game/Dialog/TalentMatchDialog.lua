local TalentMatchDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local GameSetting = GMethod.loadScript("game.GameSetting")

function TalentMatchDialog:onInitDialog()
    self:setLayout("TalentMatchDialog.json")
end

function TalentMatchDialog:onEnter()
    self:initUI()
    self:initData()
end

function TalentMatchDialog:initUI()
    self.title:setString(Localize("titleTalentMatch"))
    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.btnQuestion:setScriptCallback(ButtonHandler(HelpDialog.new, "dataQuestionTalentMatch"))
    RegTimeUpdate(self.title.view, Handler(self.onUpdate, self), 0.5)
end

-- 数据
function TalentMatchDialog:initData()
    local infos = self.context.talentMatch:getAllMatchInfos()
    for _, ainfo in ipairs(infos) do
        if ainfo.inMatch then
            ainfo.__order = 1000000000
            if ainfo.etime == 0 then
                ainfo.__order = 1000000000
            end
        else
            ainfo.__order = 1 * 1000000000 + ainfo.stime
        end
        if ainfo.bidEnter then
            ainfo.__order = ainfo.__order + 2000000000
        end
        if ainfo.adata.order then
            ainfo.__order = ainfo.adata.order + ainfo.__order
        end
    end
    GameLogic.mySort(infos, "__order")
    local _lmap = false
    local i = 1
    while i <= #infos do
        if infos[i].aid > const.TalentMatchPvh then
            if _lmap then
                table.remove(infos, i)
                i = i - 1
            else
                _lmap = true
            end
        end
        if i > 4 then
            table.remove(infos, i)
            i = i - 1
        end
        i = i + 1
    end
    self.matchTableView:setLazyTableData(infos, Handler(self.onUpdateMatchCell, self), 0)

    -- 默认关闭
    self.btnRewardBox:setVisible(false)
    -- local randomBoxAid = {}
    -- for _, info in ipairs(infos) do
    --     if info.inMatch and not info.bidEnter then
    --         table.insert(randomBoxAid, info.aid)
    --     end
    -- end
    -- if randomBoxAid[1] then
    --     self._randomBoxAid = randomBoxAid
    --     self.btnRewardBox:setVisible(true)
    --     self.effectNode2.view:runAction(ui.action.arepeat(ui.action.rotateBy(1, 150)))
    --     self.btnRewardBox:setScriptCallback(ButtonHandler(self.onRandomBox, self))
    -- end
end

function TalentMatchDialog:onRandomBox()
    local _aidx = math.random(1, #self._randomBoxAid)
    display.sendIntent({class="game.Dialog.TalentMatchGiftDialog", params={
        ainfo=self.context.talentMatch:getMatchInfo(self._randomBoxAid[_aidx])}})
end

function TalentMatchDialog:onUpdate(diff)
    self.matchTableView:refreshLazyTable()
    if self.__needRefresh then
        self:initData()
        self.__needRefresh = nil
    end
end

function TalentMatchDialog:onUpdateMatchCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    if info.aid ~= reuseCell.displayAid then
        reuseCell.displayAid = info.aid
        reuseCell.labelName:setString(Localize(info.adata.nameKey))
        reuseCell.nodeStageImg:removeAllChildren(true)
        local tmp = ui.sprite(info.adata.img, reuseCell.nodeStageImg.size)
        display.adapt(tmp, 0, 0, GConst.Anchor.LeftBottom)
        reuseCell.nodeStageImg:addChild(tmp)
        reuseCell.displayImg = tmp
        reuseCell.displayState = nil
    end
    -- 这里即时刷新状态
    local stime = GameLogic.getSTime()
    local _state = 0

    if info.stime <= stime and (info.etime == 0 or info.etime > stime) then
        if info.etime == 0 then
            reuseCell.labelLeftTime:setString("---")
        else
            reuseCell.labelLeftTime:setString(Localizet(info.etime - stime))
        end
    elseif info.stime > stime then
        _state = 1
        reuseCell.labelLeftTime:setString(Localizet(info.stime - stime))
    else
        _state = 2
        if info.etime == stime then
            self.__needRefresh = true
        end
    end
    if info.bidEnter then
        _state = _state + 3
    else
        if not info.__previousMatchData then
            local atype = info.aid
            if atype >= 104 then
                atype = 104
            end
            info.__previousMatchData = GameSetting.getLocalData(self.context.uid, "PreMatchInfo" .. atype) or {}
        end
        if info.__previousMatchData[1] then
            if info.etime <= info.__previousMatchData[1] then
                info.__previousSkip = true
            elseif info.__previousMatchData[1] + info.adata.disTime < stime then
                info.__previousMatchData[1] = nil
                info.__previousMatchData[2] = nil
            else
                _state = _state + 6
                info.__previousSkip = false
            end
        end
    end
    if reuseCell.displayState ~= _state then
        reuseCell.displayState = _state
        reuseCell.displayImg:setSValue(0)
        if _state % 3 == 0 then
            -- reuseCell.displayImg:setSValue(0)
            reuseCell.imgLeftTimeBack:setImage("images/matchs/info_open.png", 22)
            reuseCell.labelLeftTimeName:setString(Localize("labelEndTime"))
            local context = GameLogic.getUserContext()
            local tmStep = context.guideOr:getStepByKey("TalentMatch") or 0
            if tmStep <= 1 and not self.guideArrow then
                if reuseCell.displayAid == const.TalentMatchPvp then
                    self.guideArrow = context.guideHand:showArrow(reuseCell.displayImg, reuseCell.displayImg:getContentSize().width/2, reuseCell.displayImg:getContentSize().height/2, 20)
                    self.guideAreaId = reuseCell.displayAid
                elseif reuseCell.displayAid == const.TalentMatchPvb then
                    self.guideArrow = context.guideHand:showArrow(reuseCell.displayImg, reuseCell.displayImg:getContentSize().width/2, reuseCell.displayImg:getContentSize().height/2, 20)
                    self.guideAreaId = reuseCell.displayAid
                end
            end
        else
            if self.guideArrow then
                self.guideArrow:removeFromParent(true)
                self.guideArrow = nil
            end
            -- reuseCell.displayImg:setSValue(-100)
            reuseCell.imgLeftTimeBack:setImage("images/matchs/info_red.png", 22)
            reuseCell.labelLeftTimeName:setString(Localize("labelStartTime"))
        end
        if _state >= 3 and _state < 6 then
            reuseCell.displayImg:setSValue(-100)
            reuseCell.imgLeftTimeBack:setSValue(-100)
            reuseCell.backColor1:setSValue(-100)
            reuseCell.backColor2:setColor(120, 120, 120)
            reuseCell.labelNeedLevel:setVisible(true)
            reuseCell.labelNeedLevel:setString(Localizef("labelNeedLevel1", {level=info.adata.needLevel}))
        else
            reuseCell.displayImg:setSValue(0)
            reuseCell.imgLeftTimeBack:setSValue(0)
            reuseCell.backColor1:setSValue(20)
            reuseCell.backColor2:setColor(118, 202, 223)
            reuseCell.labelNeedLevel:setVisible(false)
            if _state >= 6 then
                if info.__previousMatchData[1] + 10*60 >= stime then
                    reuseCell.labelLeftTimeName:setString(Localize("labelSeasonEnd"))
                else
                    reuseCell.labelLeftTimeName:setString(Localize("labelLastSeasonRank"))
                end
                reuseCell.bnode2:setVisible(false)
            else
                reuseCell.bnode2:setVisible(true)
            end
        end
    end
    -- if info.adata.stage > 0 then
    --     reuseCell.btnMatchStage:setVisible(true)
    --     reuseCell.btnMatchStage:setScriptCallback(display.sendIntent, {class="game.Dialog.TalentMatchUpgradeDialog", params={ainfo=info}})
    --     reuseCell.effectNode.view:runAction(ui.action.arepeat(ui.action.rotateBy(1, 150)))
    --     GameUI.setTMStageIcon(reuseCell.stageIcon, info.adata.stage, 9)
    -- else
    reuseCell.btnMatchStage:setVisible(false)
    -- end
    reuseCell.imgRed:setVisible(self.context.talentMatch:showRedTip(info.aid))
    reuseCell:setScriptCallback(ButtonHandler(self.onEnterMatch, self, info))
    return reuseCell
end

function TalentMatchDialog:onGetNewRankData(ainfo, suc, data)
    GameNetwork.unlockRequest()
    if suc then
        if not data[1] then
            -- display.pushNotice(Localize("已过期"))
            ainfo.__previousMatchData[1] = nil
            ainfo.__previousMatchData[2] = nil

            local atype = ainfo.aid
            if atype >= 104 then
                atype = 104
            end
            GameSetting.setLocalData(self.context.uid, "PreMatchInfo" .. atype, ainfo.__previousMatchData)
        else
            local newData = {}
            local myRankData = nil
            for i, nd in ipairs(data) do
                local nd2 = {rank=nd[1], id=nd[2], head=nd[3], level=nd[4], name=nd[5], avalue = nd[6], avalue2 = nd[7]}
                table.insert(newData, nd2)
                if nd[2] == self.context.uid then
                    myRankData = nd2
                end
            end
            display.sendIntent({class="game.Dialog.TalentMatchPlayDialog", params={ainfo=ainfo, rankData=newData, myRankData=myRankData}})
        end
    end
end

function TalentMatchDialog:onEnterMatch(info)
    local ainfo = self.context.talentMatch:getMatchInfo(info.aid)
    local stime = GameLogic.getSTime()
    if ainfo.adata.needLevel > self.context.buildData:getTownLevel() then
        display.pushNotice(Localizef("labelNeedLevel1", {level=ainfo.adata.needLevel}))
    elseif info.__previousMatchData[1] and not info.__previousSkip then
        if info.__previousMatchData[1] + 10*60 >= stime then
            display.pushNotice(Localize("labelSeasonEndTips"))
            return
        end
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("tmrank", {aid=info.aid, gid=info.__previousMatchData[2], asid=info.__previousMatchData[1]},
            self.onGetNewRankData, self, info)
    elseif ainfo.stime <= stime and (ainfo.etime == 0 or ainfo.etime > stime) then
        display.sendIntent({class="game.Dialog.TalentMatchPlayDialog", params={ainfo=ainfo}})
    else
        display.pushNotice(Localize("labMatchOver"))
    end
    if self.guideArrow and info.aid == self.guideAreaId then
        local tmStep = GameLogic.getUserContext().guideOr:getStepByKey("TalentMatch")
        self.guideArrow:removeFromParent(true)
        self.guideArrow = nil
        self.guideAreaId = nil
        GameLogic.getUserContext().guideOr:setStepByKey("TalentMatch", tmStep+1)
    end
end

return TalentMatchDialog
