local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockDivideReportDialog = class(DialogViewLayout)
function KnockDivideReportDialog:onInitDialog()
    self.canClickBtn = false
    self:initUI()
    self:initData()
end

function KnockDivideReportDialog:initData()
    self.selectTitle = self.tid or 1
    self.noLog = {false, false, false}
    self:getTodayReport()
end

function KnockDivideReportDialog:getTodayReport()
    local function callback(flag, data)
        KnockMatchData:updateReport(flag, data, 1)
        self:getPreReport()
    end
    if KnockMatchData:checkNeedRefreshData(3) then
        GameUI.setLoadingShow("loading", true, 0)
        local week = KnockMatchData:getWeek()
        GameNetwork.request("getPvzGReport", {wk = week, gk = 0}, function(isSuc, data)
            if isSuc then
                callback(true, data)
            end
        end)
    else
        callback(false)
    end
end

function KnockDivideReportDialog:getPreReport()
    local function callback(flag, data)
        GameUI.setLoadingShow("loading", false, 0)
        KnockMatchData:updateReport(flag, data, 2)
        self.canClickBtn = true
        if self.deleted then
            return
        end
        self:updateUI()
    end
    if KnockMatchData:checkNeedRefreshData(4) then
        local week = KnockMatchData:getWeek()
        week = (week == 0) and 6 or (week-1)
        GameNetwork.request("getPvzGReport", {wk = week}, function(isSuc, data)
            if isSuc then
                callback(true, data)
            end
        end)
    else
        callback(false)
    end
end

function KnockDivideReportDialog:initUI()
    self:setLayout("KnockDivideReportDialog.json")
    self:loadViewsTo()

    self.btn_preTitle:setScriptCallback(ButtonHandler(self.clickBtnPreTitle, self))
    self.btn_nowTitle:setScriptCallback(ButtonHandler(self.clickBtnNowTitle, self))
    self.btn_rewardTitle:setScriptCallback(ButtonHandler(self.clickBtnRewardTitle, self))
    self.questionBut:setVisible(false)

    if GameLogic.useTalentMatch then
        self.btn_rewardTitle:setVisible(false)
    end
end

function KnockDivideReportDialog:updateUI()
    self:updateReportUI(1)
    self:updateReportUI(2)
    self:updateRewardUI()
    self:showTitle(self.selectTitle)
end

function KnockDivideReportDialog:updateReportUI(type)
    local reports = clone(KnockMatchData:getReport())
    if type == 1 then
        local nReport = {}
        for k, v in pairs(reports.nReport) do
            nReport[k] = v
        end
        if GameLogic.isEmptyTable(nReport) then
            self.noLog[1] = true
        end
        GameUI.helpLoadTableView(self.nd_nowReport,nReport,Handler(self.updateReportItem,self))
    elseif type == 2 then
        local yReport = {}
        for k, v in pairs(reports.yReport) do
            yReport[k] = v
        end
        if GameLogic.isEmptyTable(yReport) then
            self.noLog[2] = true
        end
        GameUI.helpLoadTableView(self.nd_preReport,yReport,Handler(self.updateReportItem,self))
    end

end

function KnockDivideReportDialog:updateRewardUI(idx)
    local rewardInfos = clone(KnockMatchData:getdRewardInfo())
    if GameLogic.isEmptyTable(rewardInfos) then
        self.noLog[3] = true
    end
    if not self.scrReward then
        self.scrReward = GameUI.helpLoadTableView(self.nd_getReward,rewardInfos,Handler(self.updateRewardItem,self))
    else
        self.scrReward.view:removeFromParent()
        self.scrReward = GameUI.helpLoadTableView(self.nd_getReward,rewardInfos,Handler(self.updateRewardItem,self))
    end
end

function KnockDivideReportDialog:updateReportItem(cell,tableView,info)
    -- body
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("nd_itemReport",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        local ucontext = GameLogic.getUserContext()
        local uid = ucontext.uid
        local _uid = info[1]

        local reborn = info[2]
        local starIdx = info[10]
        local rate = info[11]
        local score = info[3]
        local uinfos = json.decode(info[8])
        local tinfos = json.decode(info[9])
        local uheros = json.decode(info[6])
        local theors = json.decode(info[7])

        local _heros = theors
        local _info = tinfos
        local sign = "+"
        if uid == _uid then
            info.img_atkBg:setColor({210, 165, 126})
            info.img_atkBg.view:setOpacity(191)

            info.img_atk.view:setTexture("images/pvz/imgPvzAtk.png")
        else
            _heros = uheros
            _info = uinfos
            sign = "-"
            info.img_atkBg:setColor({201, 188, 159})
            info.img_atkBg.view:setOpacity(127)
            info.img_atk.view:setTexture("images/pvz/imgPvzDef.png")
        end
        local lv = _info.lv
        info.lb_lv:setString(_info.lv)
        info.lb_name:setString(_info.name)
        local len = #_heros
        for i=1, 5 do
            if i > len then
                info["nd_heroModel"..i]:setVisible(false)
            else
                info["nd_heroModel"..i]:setVisible(true)
                local lv = _heros[i][2]
                info["lb_lv"..i]:setString("Lv:"..lv)
                GameUI.addHeroHead2(info["nd_heroModelBottom"..i].view, _heros[i][1], 110, 152, 0, -16, 0, {lv = _heros[i][3]})

            end
        end
        for i=1, 3 do
            info["img_star"..i]:setVisible(false)
            if i >= starIdx then
                info["img_star"..i]:setVisible(true)
            end
        end
        info.lb_process:setString(rate.."%")
        info.lb_getScore:setString(sign..score)
        info.lb_reborn:setString(reborn)
        for i=1, 3 do
            info["img_star"..i]:setVisible(false)
            if i <= starIdx then
                info["img_star"..i]:setVisible(true)
            end
        end
        info.btn_replay:setScriptCallback(ButtonHandler(self.replay, self, {rid = info[12], gidx = info[13], gk = 0}))
    end
end

function KnockDivideReportDialog:replay(params)
    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvz, isReplay=true, rid = params.rid, gidx = params.gidx, gk = params.gk})
end

function KnockDivideReportDialog:updateRewardItem(cell, tableView, info)
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("nd_itemReward",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        local time = info[7]
        local destroy = info.destroy
        -- local score = info.sco
        time = GameLogic.getTimeFormat4(time)
        info.lb_time:setString(time)
        local rank = info[6] +1
        local score = info[4]
        local gnum = info[9]
        info.lb_rank:setString(rank)
        info.lb_getScore:setString(score)
          --段位icon
        local stage = KnockMatchData:getStageByScore(score)
        KnockMatchData:changeStageIcon(info.img_atk, stage)
          --添加奖励
          local function _updateRewardItem(_cell, _tableView, _info)
              if not _info.viewLayout then
                  _info.cell = _cell
                  _info.viewLayout = self:addLayout("nd_reward", _cell:getDrawNode())
                  _info.viewLayout:loadViewsTo(_info)
              end
            local type = checknumber(_info[1])
            local id = checknumber(_info[2])
            local num = checknumber(_info[3])
            GameUI.addItemIcon(_info.nd_heroModel1.view, type, id, 148/200, 90, 90,true,false,{itemNum=num})

          end
          local rwds = clone(KnockMatchData:getdRewardByScore(score))
        local tab = GameUI.helpLoadTableView(info.nd_rewardBottom,rwds,Handler(_updateRewardItem))
        tab.view:setTouchThrowProperty(true, true)
        local len = #rwds
        if len <= 4 then
            tab.view:setElastic(false)
        end
        local flag = (info[8]~= 0)
        info.btn_getReward.view:setGray(flag)
        if flag then
            info.lb_getReward:setString(Localize("labelRecived"))
        else
            info.lb_getReward:setString(Localize("btnArenaReward"))
        end
        info.btn_getReward:setScriptCallback(ButtonHandler(self.doReward, self, info))
    end
end

function KnockDivideReportDialog:doReward(info)
    --屏蔽连点
    if self.notCanClickDoReward then
        return
    end
    local function callback(isSuc, data)
        self.notCanClickDoReward = nil
        GameUI.setLoadingShow("loading", false, 0)
        local code = data.code
        if isSuc then
            if code == 0 then
                local _info = KnockMatchData:getRewardByIdx(info.idx)
                _info[8] = 1
                local uid = _info[1]
                KnockMatchData:doReward(uid)
                --播放 领奖动画
                GameLogic.addRewards(data.rwds)
                GameLogic.showGet(data.rwds, 0, true, true)
                info.btn_getReward:setGray(true)
                info.lb_getReward:setString(Localize("labelRecived"))
                GameEvent.sendEvent(GameEvent.KonckRefreshReward)
                self:updateRewardUI()
            elseif code == 1 then
                display.pushNotice(Localize("labMatchOutDate"))
            elseif code == 2 then
                display.pushNotice(Localize("noticeReceiveFail2"))
            end
        end
    end
    local gnum = info[9]
    local sid = info[3]
    local week = info[2]
    local flag = info[8]
    if flag ~= 0 then
        display.pushNotice(Localize("noticeRewardState1"))
        return
    end
    self.notCanClickDoReward = true
    GameUI.setLoadingShow("loading", true, 0)
    GameNetwork.request("openPvzGRewards", {gnum = gnum, wk = week, sid = sid}, callback)
end

function KnockDivideReportDialog:clickBtnPreTitle()
    if not self.canClickBtn then
        return
    end
    self:showTitle(2)
end

function KnockDivideReportDialog:clickBtnNowTitle()
     if not self.canClickBtn then
        return
    end
    self:showTitle(1)
end

function KnockDivideReportDialog:clickBtnRewardTitle()
    self:showTitle(3)
end

function KnockDivideReportDialog:showTitle(idx)
    local name1 = {"nd_nowReport", "nd_preReport", "nd_getReward"}
    local name2 = {"img_nowTitle", "img_preTitle", "img_rewardTitle"}
    for i=1, 3 do
        self[name1[i]]:setVisible(false)
        self[name2[i]].view:setTexture("images/dialogTabBack3_2.png")
    end
    self[name1[idx]]:setVisible(true)
    self[name2[idx]].view:setTexture("images/dialogTabBack3_1.png")
    if self.noLog[idx] then
        self.nd_noLog:setVisible(true)
    else
        self.nd_noLog:setVisible(false)
    end
    if idx == 3 then
        self.lb_noReport:setString(Localize("labKnockNoReward"))
    else
        self.lb_noReport:setString(Localize("labKnockNoReport"))
    end
end

return KnockDivideReportDialog
