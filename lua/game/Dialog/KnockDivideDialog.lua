local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
local KnockDivideDialog = class(DialogViewLayout)
function KnockDivideDialog:onInitDialog()
    self.canClickBtn = false
    self:initUI()
    self:initData()
end

function KnockDivideDialog:initData()
    -- self.enemyIdx = 1
    self.selectIdx = 3
    self.leftIdx = 1
    self.rightIdx = 5
    self.heroModeIdx = {1, 2, 3, 4, 5}
    local function callback(isSuc, data)
        GameUI.setLoadingShow("loading", false, 0)
        if isSuc then
            KnockMatchData:setdEnemys(data)
            self.dEnemys = KnockMatchData:getSortdEnemys()
            self:setFlagEffect()
            self:updateData()
            if self.deleted then
                return
            end
            self:updateUI()
            if not KnockMatchData:checkDivideFlagEffect() then
                self.canClickBtn = true
            end
        end
    end

    local week = KnockMatchData:getWeek()
    GameUI.setLoadingShow("loading", true, 0)
    GameNetwork.request("getGroupPlayers", {wk = week}, callback)
end

function KnockDivideDialog:updateData()
    self.dEnemys = KnockMatchData:getdEnemysAfterBattle(self.enemyIdx)
end

function KnockDivideDialog:initUI()
    self:setLayout("KnockDivideDialog.json")
    self:loadViewsTo()
    self.btn_right.view:setScaleX(-1)
    self.btn_challenge:setScriptCallback(ButtonHandler(self.clickBtnChallenge, self))
    self.btn_rank:setScriptCallback(ButtonHandler(self.clickBtnRank, self))

    self.btn_stage:setScriptCallback(ButtonHandler(self.clickBtnStage, self))
    self.btn_left:setScriptCallback(ButtonHandler(self.clickBtnLeft , self))
    self.btn_right:setScriptCallback(ButtonHandler(self.clickBtnRight , self))
    self.btn_rebornHelp:setScriptCallback(ButtonHandler(self.clickBtnRebornHelp , self))
    self.questionBut:setVisible(false)
    self.nd_gameOver:setVisible(false)
end

function KnockDivideDialog:updateUI()
    self:updateGameOver()
    self.nd_heroModel = {}
    for i=1, 5 do
        self.nd_heroModel[i]= self:addLayout("nd_heroModel", self["nd_hero"..i].view)
        self.nd_heroModel[i]:loadViewsTo()
        self:updateHeroModel(self.dEnemys[i], i)
    end

    local dinfo = KnockMatchData.dinfo
    local score = dinfo.dScore
    local rank = dinfo.dRank
    if rank then
        self.lb_myRanking:setString(rank)
    else
        self.lb_myRanking:setString(Localize("labelNotRank"))
    end
    self.lb_myScore:setString(score)
    local stage, _ = KnockMatchData:getStageByScore(score)
    KnockMatchData:changeStageIcon(self.img_stage, stage)
    local reborn = KnockMatchData:getDivideReborn()
    self.lb_rebornNum:setString(reborn)
    self.lb_rebornNumDes:setString(Localizef("labRebornDes", {num = reborn}))
    local upScore = self:getUpScore()
    self.lb_upScore:setString(upScore)
    self.lb_upScore:setVisible(upScore~=0)
    self.img_upScore:setVisible(upScore~=0)
    local path = "images/pvz/btnGetGrade1.png"
    if upScore < 0 then
        path = "images/pvz/btnGetGrade2.png"
    end
    self.img_upScore:setImage(path)
    self:updateBtnChallengeShow()
    self:updateEnemy()

    --添加奖励
    local function _updateRewardItem(_cell, _tableView, _info)
        if not _info.viewLayout then
            _info.cell = _cell
            _info.viewLayout = self:addLayout("nd_reward", _cell:getDrawNode())
            _info.viewLayout:loadViewsTo(_info)
            local type = checknumber(_info[1])
            local id = checknumber(_info[2])
            local num = checknumber(_info[3])
            GameUI.addItemIcon(_info.nd_heroModel1.view, type, id, 148/200, 90, 90,true,false,{itemNum=num})
        end
    end
    local rwds = clone(KnockMatchData:getdRewardByScore(score))
    local len = #rwds
    local tabview = GameUI.helpLoadTableView(self.nd_rewardBottom,rwds,Handler(_updateRewardItem))
    if len <= 4 then
        tabview.view:setElastic(false)
    end
end

function KnockDivideDialog:updataData()

end

function KnockDivideDialog:updateGameOver()
    local flag = self:reachMaxReborn()
    self.nd_gameOver:setVisible(flag)
end

function KnockDivideDialog:playFlagEffect(node)
    node.img_flagLight:setVisible(true)
    local process = 0
    local speed = 1.5
    local function callback(dt)
        process = process + speed* dt
        if process >=1 then
            process = 1
            node.img_flagLight:setVisible(false)
            node.nd_heroHead.view:setGray(false)
            node.img_pbr.view:setSValue(100)

            self.canClickBtn = true
            UnregActionUpdate(node.img_flagLight.view)
        end
        node.img_flagLight:setProcess(false,process)
    end
    RegActionUpdate(node.img_flagLight.view, Handler(callback, 0.025), 0.025)

    node.img_flag2:setVisible(true)
    local _process = 0
    local function _callback(dt)
        _process = _process + speed* dt
        if _process >=1 then
            _process = 1
            UnregActionUpdate(node.img_flag2.view)
        end
        node.img_flag2:setProcess(false,process)
    end
    RegActionUpdate(node.img_flag2.view, Handler(_callback, 0.025), 0.025)
end

--用来做兼容
function KnockDivideDialog:hideScoreDes(show)
    self.lb_enemyStage:setVisible(show)
    self.lb_enemyStageDes:setVisible(show)
    self.lb_enemyScore:setVisible(show)
    self.lb_enemyFightDes:setVisible(show)
    self.lb_enemyFight:setVisible(show)
    self.labAtk:setVisible(show)
    self.labDef:setVisible(show)
end

function KnockDivideDialog:updateHeroModel(dEnemy, idx)
    local node = self.nd_heroModel[idx]
    if GameLogic.isEmptyTable(dEnemy) then
        node.nd_flag.view:setScale(0.61)
        node.img_flag2:setVisible(false)
        node.img_flagLight.view:setScale(3.05)
        node.img_flagLight:setVisible(false)
        return
    end

    if idx == self.selectIdx then
        node.view:setScale(1.5)
        node.nd_starBottom:setVisible(true)
    else
        node.nd_starBottom:setVisible(false)
    end
    local headId = dEnemy.head
    GameUI.addPlayHead(node.nd_heroHead, {id=headId, scale = 1, x=0,y=0,z=0,blackBack=false, noBlackBack = true})

    local name = dEnemy.name
    local combat = dEnemy.combat
    node.lb_name:setString(name)
    node.lb_combat:setString(combat)
    for i=1, 3 do
        node["img_starGray"..i]:setVisible(true)
        node["img_star"..i]:setVisible(false)
        local star = dEnemy.def.star
        if i<= star then
            node["img_star"..i]:setVisible(true)
        end
    end
    local showGray = false
    local reborn = KnockMatchData:getDivideReborn()
    local flagPath = {"images/pvz/imgPvzFlagGreen.png", "images/pvz/imgPvzFlagPurple.png", "images/pvz/imgPvzFlagRed.png", "images/pvz/imgPvzFlagRed.png"}
    node.img_flag1:setImage(flagPath[reborn+1])
    node.img_flag2:setImage(flagPath[reborn+2])

    local value = 100
    if self:reachMaxReborn() then
        showGray = true
        value = -100
    elseif dEnemy.def.star >= 3 then
        showGray = true
        value = -100
    end
    node.img_pbr.view:setSValue(value)
    node.nd_heroHead.view:setGray(showGray)
    local leftRate = 1-dEnemy.def.destroy/100
    GameUI.setCircleProcess(node.img_pbr.view, leftRate, 0, 1, 0.5, 0.5)
    node.nd_flag.view:setScale(0.61)
    node.img_flag2:setVisible(false)
    node.img_flagLight.view:setScale(3.05)
    node.img_flagLight:setVisible(false)
    if self.showFlagEffect then
        node.img_pbr.view:setSValue(-100)
        node.nd_heroHead.view:setGray(true)
        self:playFlagEffect(node)
    end
end

function KnockDivideDialog:setFlagEffect()
    self.showFlagEffect = KnockMatchData:checkDivideFlagEffect()
end

function KnockDivideDialog:reachMaxReborn()
    local flag = true
    local reborn = KnockMatchData:getDivideReborn()
    if reborn >= 2 then
        for k, v in pairs(self.dEnemys) do
            if v.def.destroy < 100 then
                flag = false
            end
        end
    else
        flag = false
    end
    return flag
end

function KnockDivideDialog:updateEnemy()
    local dEnemy = self.dEnemys[self.selectIdx]
    if GameLogic.isEmptyTable(dEnemy) then
        self:hideScoreDes(false)
        return
    end
    self:hideScoreDes(true)

    local score = dEnemy.score
    local stage, stageName = KnockMatchData:getStageByScore(score)
    self.lb_enemyStage:setString(stageName)
    self.lb_enemyScore:setString(score)

    local atkScore = dEnemy.def.score or 0
    local defScore = dEnemy.atk.score or 0
    local add = atkScore-defScore
    local str = (add>=0) and ("+"..add) or add
    self.labAtk:setString(Localize("labAtk").."+"..atkScore)
    self.labDef:setString(Localize("labDef").."-"..defScore)
    --self.lb_enemyAtk:setString("+17200"..atkScore)
    --self.lb_enemyDef:setString("-17200"..defScore)
    self.lb_enemyFight:setString(str)
end

function KnockDivideDialog:updateBtnChallengeShow()
    local dEnemy = self.dEnemys[self.selectIdx]
    if GameLogic.isEmptyTable(dEnemy) then
        self.btn_challenge.view:setGray(true)
        self.btn_challenge:setEnable(false)
        return
    end
    self.btn_challenge:setEnable(true)
    local reborn = KnockMatchData:getDivideReborn()
    local showGray = false
    if self:reachMaxReborn() then
        showGray = true
    elseif dEnemy.def.star >= 3 then
        showGray = true
    end
    self.btn_challenge.view:setGray(showGray)
end

function KnockDivideDialog:getUpScore()
    local dEnemy = KnockMatchData:getdEnemys()
    local ans = 0
    local score
    for k, v in pairs(dEnemy) do
        if not GameLogic.isEmptyTable(v.atk) then
            score = v.atk.score or 0
            ans = ans - score
        end
        if not GameLogic.isEmptyTable(v.def) then
            score = v.def.score or 0
            ans = ans + score
        end
    end
    return ans
end

function KnockDivideDialog:getHeroModelPos(idx)
    local pos = {-690, -390, 0, 390,  690}
    return pos[idx]
end

function KnockDivideDialog:getHeroModeIdx(pos)
    return self.heroModeIdx[pos]
end

function KnockDivideDialog:clickBtnLeft()
    if self.canChangeHeroModel or (not self.canClickBtn) then
        return
    else
        self.canChangeHeroModel = true
    end
    local node = {}
    local pos = {}
    for i=1, 5 do
        node[i] = self.nd_heroModel[self:getHeroModeIdx(i)]
        pos[i] = self:getHeroModelPos(i)
    end
    local temp = self.heroModeIdx[5]
    self.heroModeIdx[5] = self.heroModeIdx[4]
    self.heroModeIdx[4] = self.heroModeIdx[3]
    self.heroModeIdx[3] = self.heroModeIdx[2]
    self.heroModeIdx[2] = self.heroModeIdx[1]
    self.heroModeIdx[1] = temp
    local time = 0.3
       node[1].view:runAction(ui.action.sequence({{"moveBy", time, pos[2]-pos[1], 0}, {"call", function()
           self.canChangeHeroModel = false
           end}}))
       node[2].view:runAction(ui.action.sequence({ui.action.spawn({ {"moveBy", time, pos[3]-pos[2], 0}, {"scaleTo", time, 1.5, 1.5}}), {"call", function()
               if not GameLogic.isEmptyTable(self.dEnemys[self.selectIdx]) then
                   node[2].nd_starBottom:setVisible(true)
               end
           end}}))
       node[3].view:runAction(ui.action.spawn({{"call", function()
            node[3].nd_starBottom:setVisible(false)
          end}, {"moveBy", time, pos[4]-pos[3], 0}, {"scaleTo", time, 1, 1}}))
       node[4].view:runAction(ui.action.spawn({{"moveBy", time, pos[5]-pos[4], 0}}))
       node[5].view:runAction(ui.action.spawn({{"fadeOut", time}, ui.action.sequence({{"delay",time}, {"call",function()
        node[5].view:setPositionX(pos[1])
       end}, {"fadeIn", 0}}) }))

       self.selectIdx = self.selectIdx - 1
       if self.selectIdx < self.leftIdx then
           self.selectIdx = self.rightIdx
       end
       self:updateBtnChallengeShow()
       self:updateEnemy()
end

function KnockDivideDialog:clickBtnRight()
       if self.canChangeHeroModel or (not self.canClickBtn) then
        return
    else
        self.canChangeHeroModel = true
    end
    local node = {}
    local pos = {}
    for i=1, 5 do
        node[i] = self.nd_heroModel[self:getHeroModeIdx(i)]
        pos[i] = self:getHeroModelPos(i)
    end
    local temp = self.heroModeIdx[1]
    self.heroModeIdx[1] = self.heroModeIdx[2]
    self.heroModeIdx[2] = self.heroModeIdx[3]
    self.heroModeIdx[3] = self.heroModeIdx[4]
    self.heroModeIdx[4] = self.heroModeIdx[5]
    self.heroModeIdx[5] = temp
    local time = 0.3
    node[1].view:runAction(ui.action.spawn({{"fadeOut", time}, ui.action.sequence({{"delay",time}, {"call",function()
        node[1].view:setPositionX(pos[5])
       end}, {"fadeIn", 0}}) }))
       node[2].view:runAction(ui.action.sequence({{"moveBy", time, pos[1]-pos[2], 0}}))
       node[3].view:runAction(ui.action.spawn({{"call", function()
            node[3].nd_starBottom:setVisible(false)
          end}, {"moveBy", time, pos[2]-pos[3], 0}, {"scaleTo", time, 1, 1}}))
       node[4].view:runAction(ui.action.sequence({ui.action.spawn({{"moveBy", time, pos[3]-pos[4], 0}, {"scaleTo", time, 1.5, 1.5}}), {"call", function()
           if not GameLogic.isEmptyTable(self.dEnemys[self.selectIdx]) then
               node[4].nd_starBottom:setVisible(true)
           end
           end} }) )
       node[5].view:runAction(ui.action.sequence({{"moveBy", time, pos[4]-pos[5], 0}, {"call", function()
        self.canChangeHeroModel = false
       end}}))

       self.selectIdx = self.selectIdx + 1
       if self.selectIdx > self.rightIdx then
           self.selectIdx = self.leftIdx
       end
       self:updateBtnChallengeShow()
       self:updateEnemy()
end

function KnockDivideDialog:clickBtnRank()
    AllRankingListDialog.new(11)
end

function KnockDivideDialog:clickBtnChallenge()
    if not self.canClickBtn then
        return
    end
    local dEnemy = self.dEnemys[self.selectIdx]
    if GameLogic.isEmptyTable(dEnemy) then
        return
    end
    local reborn = KnockMatchData:getDivideReborn()
    if self:reachMaxReborn() then
        display.pushNotice(Localize("labReachTopStarNum"))
        return
    end
    if dEnemy.def.star >= 3 then
        display.pushNotice(Localize("labReachTopStarNum"))
        return
    end

    local uid = dEnemy.uid
    local function callback(isSuc, data)
        GameUI.setLoadingShow("loading", false, 0)
        if isSuc then
            --打开拉取信息开关
            GameEvent.sendEvent(GameEvent.openKnockGetInfo)
            GameLogic.removeJumpGuide(const.ActTypePVP)
            local score = dEnemy.score
            local reborn = dEnemy.def.reborn
            local stage, stageName = KnockMatchData:getStageByScore(score)
            local hpPct, atkPct = KnockMatchData:getRebornBuff(reborn, 1)
            data.binfo.pvzData = {uid = uid, reborn = reborn, stage = stage, stageName = stageName, score = score, pos = dEnemy.pos, head = dEnemy.head, hpPct = hpPct, atkPct = atkPct, type = 0, matchType = 0, selectIdx = self.selectIdx}
            GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvz, data = data.binfo})
            -- GameLogic.checkPvpAttack({callback=Handler(GameEvent.sendEvent, GameEvent.EventBattleBegin, {type=const.BattleTypePvz, data = data.binfo})})
        else

        end
    end
    GameUI.setLoadingShow("loading", true, 0)
    GameNetwork.request("beginPvzBattle", {tid = uid, gk = 0}, callback)
end

function KnockDivideDialog:clickBtnStage()
    if not self.canClickBtn then
        return
    end
    local KnockDivideStageDialog = GMethod.loadScript("game.Dialog.KnockDivideStageDialog")
    display.showDialog(KnockDivideStageDialog.new())
end

function KnockDivideDialog:clickBtnRebornHelp()
    if not self.canClickBtn then
        return
    end
    local reborn = KnockMatchData:getDivideReborn()
    local hpPct, atkPct = KnockMatchData:getRebornBuff(reborn, 1)
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
    display.showDialog(AlertDialog.new(0, Localize("labRebornHelp"), Localizef("labRebornHelpDes", {a = atkPct, b = hpPct}) ))
end

function KnockDivideDialog:close()
    display.closeDialog(self.priority)
end

return KnockDivideDialog

