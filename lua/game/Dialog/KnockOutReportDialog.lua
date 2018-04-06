local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockOutReportDialog = class(DialogViewLayout)
function KnockOutReportDialog:onInitDialog()
    self.canClickBtn = false
    self:initUI()
    self:initData()
end

function KnockOutReportDialog:initUI()
    self:setLayout("KnockOutReportDialog.json")
    self:loadViewsTo()
    self.questionBut:setVisible(false)
end

function KnockOutReportDialog:initData()
    if self.params then
        self.isOwn = self.params.isOwn
    end
    local ucontext = GameLogic.getUserContext()
    local uid = ucontext.uid
    local wk = self.wk or KnockMatchData:getWeek()
    local tid = self.tid
    if self.isOwn then
        tid = uid
    else

    end
    -- dump({tid, wk})
    GameUI.setLoadingShow("loading", true, 0)
    GameNetwork.request("getPvzGReport", {tid = tid, wk = wk, gk = 1}, function(isSuc, data)
        -- dump(data)
        GameUI.setLoadingShow("loading", false, 0)
        if isSuc then
            KnockMatchData:updateOutReport(true, data, 1)
            self:updateData()
        end
    end)
end

function KnockOutReportDialog:updateData()
    local type = 1
    if not self.isOwn then
        -- type = 2
    end
    self.reportInfo = clone(KnockMatchData:getOutReport(type))
    if self.deleted then
        return
    end
    self:updateUI()
end

function KnockOutReportDialog:updateUI()
    local reportInfo = self.reportInfo
    GameUI.helpLoadTableView(self.nd_reportBottom,reportInfo,Handler(self.updateReportItem,self))
end

function KnockOutReportDialog:updateReportItem(cell,tableView,info)
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("nd_reportItemBottom",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        local uhead = info.uinfo.head
        local ulv = info.uinfo.lv
        local uname = info.uinfo.name
        local ucombat = info.uinfo.combat
        local uid = info.uinfo.uid
        local score = info.score
        local destroy = info.destroy
        local reborn = info.reborn
        local star = info.star
        info.lb_ownName:setString(uname)
        info.lb_ownLv:setString(ulv)
        info.lb_ownCombat:setString(ucombat)
        GameUI.addPlayHead(info.nd_ownBottom, {id=uhead, scale = 1.1, x=0,y=0,z=0,blackBack=true, noBlackBack = false})

        local uheros = info.uheros
        local tab = GameUI.helpLoadTableView(info.nd_ownHeroBottom,uheros,Handler(self.updateHeroItem,self))
        tab.view:setElastic(false)
        tab.view:setTouchThrowProperty(true, true)


        local thead = info.tinfo.head
        local tlv = info.tinfo.lv
        local tname = info.tinfo.name
        local tcombat = info.tinfo.combat
        local tid = info.tinfo.uid
        info.lb_enemyName:setString(tname)
        info.lb_enemyLv:setString(tlv)
        info.lb_enemyCombat:setString(tcombat)
        GameUI.addPlayHead(info.nd_enemyBottom, {id=thead, scale = 1.1, x=0,y=0,z=0,blackBack=true, noBlackBack = false})
        local theros = info.theros
        local tab = GameUI.helpLoadTableView(info.nd_enemyHeroBottom,theros,Handler(self.updateHeroItem,self))
        tab.view:setElastic(false)
        tab.view:setTouchThrowProperty(true, true)

        local str = destroy.."%"
        info.lb_speed:setString(str)
        info.lb_score:setString(score)
        for i=1, 3 do
            info["img_star"..i]:setVisible(false)
            info["img_grayStar"..i]:setVisible(true)
            if i<= star then
                info["img_star"..i]:setVisible(true)
            end
        end

        local path = "images/pvz/imgWhiteBg2.png"
        local color = {155, 172, 165}
        if self.tid == tid then
            color = {196, 153, 137}
        end
        info.img_bg:setImage(path, 10, 1940, 510)
        info.img_bg:setColor(color)
        info.img_bg.view:setLocalZOrder(-1)
        info.lb_reborn:setString(reborn)
        if reborn > 0 then
            info.btn_reborn:setVisible(true)
            local x, y = info.btn_reborn.view:getPosition()
            local hpPct, atkPct = KnockMatchData:getRebornBuff(reborn, 2)
            if hpPct <= 1 then
                hpPct = 0
            else
                hpPct = ((hpPct-1)*100).."%"
            end
            if atkPct <= 1 then
                atkPct = 0
            else
                atkPct = ((atkPct-1)*100).."%"
            end
            info.btn_reborn.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self.view, info.btn_reborn.view, x-128, y-10, Localizef("labPvzRebornBuffTip", {a = reborn, b = hpPct, c = atkPct})}))
        else
            info.btn_reborn:setVisible(false)
        end
        info.btn_replay:setScriptCallback(ButtonHandler(self.onClickReplay, self, {rid = info.rid, gidx = info.gidx, gk = 1}))
    end
end

function KnockOutReportDialog:updateHeroItem(cell,tableView,info)
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("nd_heroModelBottom",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        GameUI.addHeroHead2(info.nd_heroBottom.view, info[1], 118, 156, 0, 0, 0, {lv = info[3]})
        info.lb_lv:setString("Lv:"..info[2])
    end
end

function KnockOutReportDialog:onClickReplay(params)
    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvz, isReplay=true, rid = params.rid, gidx = params.gidx, gk = params.gk})

end

return KnockOutReportDialog
