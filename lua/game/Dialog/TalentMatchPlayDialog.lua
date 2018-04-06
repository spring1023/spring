local TalentMatchPlayDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local GameSetting = GMethod.loadScript("game.GameSetting")

function TalentMatchPlayDialog:onInitDialog()
    self:setLayout("TalentMatchPlayDialog.json")

    RegTimeUpdate(self.labelLeftTime.view, Handler(self.onUpdate, self), 0.5)
end

-- function TalentMatchPlayDialog:onQuestion()
--     display.sendIntent({class="game.Dialog.TalentMatchUpgradeDialog", params={ainfo=self.ainfo}})
-- end

function TalentMatchPlayDialog:onEnter()
    memory.loadSpriteSheetRelease("images/rankNums.plist", false)
    self:initUI()
    self:initData()
    if self.rankData then
        self.ainfo.__previousMatchData[1] = nil
        self.ainfo.__previousMatchData[2] = nil
        local atype = self.ainfo.aid
        if atype >= 104 then
            atype = 104
        end
        GameSetting.setLocalData(self.context.uid, "PreMatchInfo" .. atype, self.ainfo.__previousMatchData)
    end
end

function TalentMatchPlayDialog:onExit()
    memory.releasePlist("images/rankNums.plist", false)
end

function TalentMatchPlayDialog:initUI()

    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    -- self.btnQuestion:setScriptCallback(ButtonHandler(self.onQuestion, self))
    self.nodeStageIcon:setScriptCallback(ButtonHandler(display.sendIntent,
        {class="game.Dialog.TalentMatchStageDialog", params={ainfo=self.ainfo}}))
    local adata = self.ainfo.adata
    if adata.rankBg then
        self.imgRankBanner:setImage(adata.rankBg, 0)
    else
        self.imgRankBanner:setImage("images/matchs/bannerMatch" .. self.ainfo.aid .. ".png", 0)
    end
    -- if adata.stage == 0 then
    --     self.nodeStageIcon:setVisible(false)
    -- elseif self.rankData then
    --     self.nodeStageIcon:setVisible(true)
    --     local gid = self.ainfo.__previousMatchData[2]
    --     local gstage = math.floor(gid / 1000000) % 100
    --     if gstage == 0 then
    --         gstage = self.context.talentMatch:getStage(adata.stage)
    --     end
    --     GameUI.setTMStageIcon(self.nodeStageIcon, adata.stage, gstage)
    -- else
    --     -- self.effectNode.view:runAction(ui.action.arepeat(ui.action.rotateBy(1, 150)))
    --     -- GameUI.setTMStageIcon(self.iconQuestion, adata.stage, 9)
    --     local stage = self.context.talentMatch:getStage(adata.stage)
    --     local stage2 = GameSetting.getLocalData(self.context.uid, "localStage" .. adata.stage)
    --     if not stage2 then
    --         stage2 = stage
    --         GameSetting.setLocalData(self.context.uid, "localStage" .. adata.stage, stage)
    --     end
    --     if stage2 and stage2 < stage and stage2 > 0 then
    --         stage = stage2
    --     end
    --     self.nodeStageIcon:setVisible(true)
    --     GameUI.setTMStageIcon(self.nodeStageIcon, adata.stage, stage)
    -- end
    self.nodeStageIcon:setVisible(false)
    if adata.rankTitle then
        self.rankTitle:setString(Localize(adata.rankTitle))
    else
        self.rankTitle:setString(Localize("labelRankList"))
    end

    self.labelMatchName:setString(Localize(adata.nameKey))
    if self.rankData then
        self.btnBattle:setVisible(false)
        self.btnHelp:setVisible(false)
    else
        self.btnBattle:setScriptCallback(ButtonHandler(self.onBattle, self))
        self.btnHelp:setScriptCallback(ButtonHandler(self.onHelp, self))
        self.btnBattle:setVisible(false)

        local redNumCache = GameSetting.getLocalData(self.context.uid, "RedNums") or {}
        if (redNumCache["TM" .. self.ainfo.aid] or 0) < self.ainfo.stime then
            self.redNum = GameUI.addRedNum(self.btnHelp,310,85,0,1,1)
            self.redNum:setNum(99)
            GameEvent.bindEvent(self.redNum, "isClickPackage", self, function ()
                local redNumCache2 = GameSetting.getLocalData(self.context.uid, "RedNums") or {}
                if (redNumCache2["TM" .. self.ainfo.aid] or 0) >= self.ainfo.stime then
                    self.redNum:removeFromParent(true)
                    self.redNum = nil
                end
            end)
        end
        if (redNumCache["TMMatch" .. self.ainfo.aid] or 0) <= self.ainfo.etime then
            redNumCache["TMMatch" .. self.ainfo.aid] = self.ainfo.etime
            GameSetting.setLocalData(self.context.uid, "RedNums", redNumCache)
            GameEvent.sendEvent("RefreshTMRedNum")
        end
    end
    -- self.myRankNode:setVisible(false)
    self:onUpdate(0)
end

function TalentMatchPlayDialog:onHelp()
    display.sendIntent({class="game.Dialog.TalentMatchHelpDialog", params={ainfo=self.ainfo}})
end

function TalentMatchPlayDialog:onBattle()
    if self.deleted then
        return
    end
    local aid = self.ainfo.aid
    local tmData = self.context.talentMatch:getMatchNow(self.ainfo.aid)
    if self.ainfo.aid == const.TalentMatchPvp then
        GameLogic.jumpCondition(const.ActTypePVP)
    elseif self.ainfo.aid == const.TalentMatchPvj then
        local maxIdx = KTLen(SData.getData("pvjboss6"))  --最大关卡数
        local nowIdx = tmData.avalue2 + 1 --当前关卡ID
        local maxChance = SData.getData("tmInfos", aid).times
        if nowIdx > maxIdx then
            display.pushNotice(Localize("DRPvjClearance"))
        elseif tmData.chance >= maxChance then
            display.pushNotice(Localize("timesNotEnough"))
        else
            local stage = SData.getData("pvjboss6", nowIdx)
            GameEvent.sendEvent(GameEvent.EventBattleBegin, {type = const.BattleTypePvj, idx = nowIdx, showStoryIdx=stage.storyIdx, bparams = {index = nowIdx, DRPvj = true}})
        end
    elseif self.ainfo.aid == const.TalentMatchPvh then
        --做个翻译
        if not self.context.npvh then
            local data={htime=tmData.ltime, inum=math.floor(tmData.avalue2/10)%10, hlv=0, pid=tmData.avalue, exits=(1-math.floor(tmData.avalue2%10)), maxlv=0, hnum=0, sp=math.floor(tmData.avalue2/100)%1000}
            self.context:loadNightWarePvh(data)
        end
        if self.context.npvh:isInNightmareBattle() then
            display.sendIntent{class="game.Dialog.NightmareDialog", params={nightmare=true}}
        else
            display.showDialog(PvhDialog.new{nightmare=true})
        end
    else
        local maxIdx = KTLen(SData.getData("godBeastBoss", aid))  --最大关卡数
        local nowIdx = (tmData.avalue2 % 100) + 1
        local maxChance = SData.getData("tmInfos", aid).times
        if nowIdx > maxIdx then
            display.pushNotice(Localize("DRPvjClearance"))
        elseif tmData.chance >= maxChance then
            display.pushNotice(Localize("timesNotEnough"))
        else
            GameLogic.checkCanGoBattle(const.BattleTypePvb, Handler(GameEvent.sendEvent, GameEvent.EventBattleBegin,
                {type=const.BattleTypePvb, aid=aid, stage=nowIdx, lostHp=math.floor(tmData.avalue2 / 100)}), aid)
        end
    end
end

function TalentMatchPlayDialog:onRefreshDatas(matchData)
    if self.deleted then
        return
    end
    if matchData then
        -- 分类型，先临时写一下
        if not self.rankData then
            self.btnBattle:setVisible(true)
        end
        if self.ainfo.aid == const.TalentMatchPvp then
            self.labelBtnBattle:setString(Localize("btnBattleStart"))

            local bgNode = ui.scrollNode(self.playRoleNode.size, 0, false, false, {clip=true, scroll=false})
            display.adapt(bgNode, 0, 0, GConst.Anchor.LeftBottom)
            self.playRoleNode:addChild(bgNode)

            local tmp = ui.sprite("images/storeIconItem9.png")
            display.adapt(tmp, self.playRoleNode.size[1]/2 + 90, self.playRoleNode.size[2]/2 - 40, GConst.Anchor.Center)
            tmp:setScale(2.3)
            bgNode:addChild(tmp)

            -- memory.loadSpriteSheetRelease("images/background/loadingChange1.plist", true)
            -- local temp = ui.node()
            -- local temp1
            -- temp1 = ui.sprite("lvdaiLeft0.png")
            -- temp1:setPosition(956, 643)
            -- temp1:setAnchorPoint(0,0)
            -- temp:addChild(temp1)
            -- temp1 = ui.sprite("wali0.png")
            -- temp1:setPosition(947, 600)
            -- temp1:setAnchorPoint(0,0)
            -- temp:addChild(temp1)
            -- temp1=ui.sprite("lvdaiRight0.png")
            -- temp1:setPosition(956, 581)
            -- temp1:setAnchorPoint(0,0)
            -- temp:addChild(temp1)
            -- display.adapt(temp, -870, -560)
            -- bgNode:addChild(temp)

            self.labelBattleProgress:setString(Localizef("labelTMPvpProgress", {a=matchData.avalue}))
            self.lab_diffcult:setVisible(false)
        elseif self.ainfo.aid == const.TalentMatchPvj then
            local max = SData.getData("tmInfos", const.TalentMatchPvj).times
            local maxIdx = KTLen(SData.getData("pvjboss6"))  --最大关卡数,表名暂用pvj的
            local nowIdx = (matchData.avalue2 + 1) < maxIdx and (matchData.avalue2 + 1) or maxIdx  --当前关卡ID
            if not self.rankData then
                self.labelBtnBattle:setString(Localizef("btnBattleStartChance", {a=max-matchData.chance, b=max}))
            end
            local bgNode = ui.scrollNode(self.playRoleNode.size, 0, false, false, {clip=true, scroll=false})
            display.adapt(bgNode, 0, 0, GConst.Anchor.LeftBottom)
            self.playRoleNode:addChild(bgNode)

            local imgIdx = SData.getData("pvjboss6", nowIdx).pic
            --
            local imgInfo = {
                {0, -50, 0.65, "images/pvePlotPerson6.png"},
                {0, 0, 1.2, "images/roles/heroFeature9005.png"},
                {-50, -50, 1.2, "images/roles/heroFeature9004.png"},
                {-50, -50, 1.2, "images/roles/heroFeature9003.png"}} --{px,py,scale}
            local tmp = ui.sprite(imgInfo[imgIdx][4])
            tmp:setScale(imgInfo[imgIdx][3])
            display.adapt(tmp, self.playRoleNode.size[1]/2+imgInfo[imgIdx][1], self.playRoleNode.size[2]/2+imgInfo[imgIdx][2], GConst.Anchor.Center)
            bgNode:addChild(tmp)
            self.labelBattleProgress:setString(Localizef("labelTMPvjProgress", {a=nowIdx, b=maxIdx}))
            local difficulty = SData.getData("pvjboss6", nowIdx).difficulty
            self.lab_diffcult:setString(Localize("nightmareStage"..difficulty))
        elseif self.ainfo.aid == const.TalentMatchPvh then
            self.labelBtnBattle:setString(Localize("btnBattleStart"))
            local bgNode = ui.scrollNode(self.playRoleNode.size, 0, false, false, {clip=true, scroll=false})
            display.adapt(bgNode, 0, 0, GConst.Anchor.LeftBottom)
            self.playRoleNode:addChild(bgNode)

            GameUI.addHeroFeature(bgNode, 4009, 1, 400, 460, 0, true):setOpacity(140)
            GameUI.addHeroFeature(bgNode, 4012, 1, 225, 145, 0, true)

            self.labelBattleProgress:setString(Localizef("labelTMPvjProgress2", {a=self.context.talentMatch:getDisplayTMPvhStage(matchData.avalue + 1)}))
            self.lab_diffcult:setVisible(false)
        else
            local bgNode = ui.scrollNode(self.playRoleNode.size, 0, false, false, {clip=true, scroll=false})
            display.adapt(bgNode, 0, 0, GConst.Anchor.LeftBottom)
            self.playRoleNode:addChild(bgNode)
            local path = {}
            local text
            local bid, offX, offY = 0, 0, 0
            if self.ainfo.aid == 104 then
                path[1] = "images/roles/jobIcon2.png"
                path[2] = "images/roles/jobIcon4.png"
                path[3] = "images/roles/jobIcon7.png"
                text = Localizef("jobDamageUp", {num = SData.getData("hbuff", 5, 8013).dmg or 0})
                bid = 8010
            elseif self.ainfo.aid == 105 then
                path[1] = "images/roles/jobIcon1.png"
                path[2] = "images/roles/jobIcon6.png"
                text = Localizef("jobDamageUp", {num = SData.getData("hbuff", 5, 8053).dmg or 0})
                bid = 8050
            elseif self.ainfo.aid == 106 then
                path[1] = "images/roles/jobIcon3.png"
                path[2] = "images/roles/jobIcon5.png"
                text = Localizef("jobDamageUp", {num = SData.getData("hbuff", 5, 8073).dmg or 0})
                bid = 8070
                offX = 100
            end
            GameUI.addHeroFeature(bgNode, bid, 1, self.playRoleNode.size[1]/2+offX, self.playRoleNode.size[2]/2+offY, 0, true)
            for i=1,#path do
                local temp = ui.sprite(path[i], {92, 92})
                display.adapt(temp, 480-i*100, 0, GConst.Anchor.LeftBottom)
                bgNode:addChild(temp)
            end
            local btn_tips = ui.button({100*#path, 100}, nil, {})
            display.adapt(btn_tips, 460-#path*100, 0, GConst.Anchor.LeftBottom)
            bgNode:addChild(btn_tips)
            GameUI.registerTipsAction(btn_tips, self.view, 0, 0, btn_tips:getContentSize().width/2, btn_tips:getContentSize().height/2, text)
            local btn_info = ui.button({67, 62}, nil, {image = "images/btnInfo2.png"})
            display.adapt(btn_info, 30, 645, GConst.Anchor.LeftBottom)
            bgNode:addChild(btn_info)

            local max = SData.getData("tmInfos", self.ainfo.aid).times or 5
            local maxIdx = KTLen(SData.getData("godBeastBoss", self.ainfo.aid))  --最大关卡数
            local nowIdx = ((matchData.avalue2%100) + 1) < maxIdx and ((matchData.avalue2 % 100) + 1) or maxIdx  --当前关卡ID
            if not self.rankData then
                self.labelBtnBattle:setString(Localizef("btnBattleStartChance", {a=max-matchData.chance, b=max}))
            end
            local difficulty = SData.getData("godBeastBoss", self.ainfo.aid, nowIdx).difficulty
            self.lab_diffcult:setString(Localize("nightmareStage"..difficulty))
            self.labelBattleProgress:setString(Localizef("labelTMPvjProgress", {a=nowIdx, b=maxIdx}))
            local hero = GameLogic.getUserContext().heroData:makeHero(bid)
            btn_info:setScriptCallback(ButtonHandler(function ()
                display.showDialog(BeastInfoNewDialog.new({hero = hero, path = path, text = text, aid = self.ainfo.aid, nowIdx = nowIdx}))
            end))
            local lab_level = ui.label(Localizef("labelFormatLevel", {level = SData.getData( "godBeastBoss",self.ainfo.aid,nowIdx).lv}), General.font1, 50)
            display.adapt(lab_level, 10, 0, GConst.Anchor.LeftBottom)
            bgNode:addChild(lab_level)
        end
        if self.rankData then
            self:onRefreshRankDatas({rankData=self.rankData, myRankData=self.myRankData})
        else
            self.context.talentMatch:getMatchRank(self.ainfo.aid, matchData.group, Handler(self.onRefreshRankDatas, self))
        end
        -- local adata = self.ainfo.adata
        -- if adata.stage ~= 0 and not self.rankData then
        --     local stage = self.context.talentMatch:getStage(adata.stage)
        --     if stage > 1 and stage > (GameSetting.getLocalData(self.context.uid, "localStage" .. adata.stage) or 0) then
        --         -- 放动画？
        --         local cp, icon, x, y, darkBg, oscale, label
        --         local state = 0
        --         local function doAnimate4()
        --             -- 移除动画
        --             if state == 1 then
        --                 darkBg:runAction(ui.action.sequence({{"fadeTo",0.2, 0}, "remove"}))
        --                 icon:runAction(ui.action.sequence({{"delay", 0}, {"moveTo", 0.2, x, y}}))
        --                 icon:runAction(ui.action.sequence({{"delay", 0}, {"scaleTo", 0.2, oscale, oscale}}))
        --                 display.closeDialog(self.priority + 1)
        --                 state = 2
        --                 label:runAction(ui.action.sequence({{"fadeOut", 0.2}, "remove"}))
        --                 GameSetting.setLocalData(self.context.uid, "localStage" .. adata.stage, stage)
        --             end
        --         end
        --         local function doAnimate()
        --             cp = self.nodeStageIcon.view:convertToNodeSpace(cc.p(display.winSize[1]/2, display.winSize[2]/2))
        --             icon = self.nodeStageIcon.__icon
        --             x, y = icon:getPosition()
        --             oscale = icon:getScaleX()
        --             icon:runAction(ui.action.easeSineOut(ui.action.moveTo(0.12, cp.x, cp.y)))
        --             icon:runAction(ui.action.sequence({
        --                 {"easeSineOut", {"scaleTo", 0.12, 7, 7}},
        --                 {"easeSineIO", {"scaleTo", 0.08, 2, 2}},
        --                 {"easeSineIn", {"scaleTo", 0.04, 4, 4}},
        --                 {"actionShake", 1, 20, 20}
        --             }))
        --             icon:runAction(ui.action.fadeIn(0.2))
        --             icon:runAction(ui.action.sequence({{"delay", 0.24}}))
        --             darkBg = ui.colorNode({4098, 3072}, {0, 0, 0, 0})
        --             display.adapt(darkBg, cp.x, cp.y, GConst.Anchor.Center)
        --             self.nodeStageIcon.view:addChild(darkBg, -1)
        --             darkBg:runAction(ui.action.fadeTo(0.2, 128))
        --             -- local x, y = self.nodeStageIcon.view:getPosition()
        --             --
        --             display.addTempLayer(doAnimate4)
        --         end
        --         local function doAnimate2()
        --             local animate = ui.simpleCsbEffect("UICsb/match/matchStage.csb", false, 0)
        --             animate:setScale(4)
        --             display.adapt(animate, cp.x, cp.y, GConst.Anchor.Center)
        --             self.nodeStageIcon.view:addChild(animate, 3)
        --             animate:runAction(ui.action.sequence({{"delay", 4}, "remove"}))

        --             label = ui.label(Localize("descTmIcon" .. adata.stage .. "_" .. stage), General.font1, 60)
        --             label:setScale(2)
        --             label:setOpacity(0)
        --             display.adapt(label, cp.x, cp.y - 450, GConst.Anchor.Center)
        --             self.nodeStageIcon.view:addChild(label, 3)
        --             label:runAction(ui.action.sequence({{"delay",0.2}, {"fadeIn", 0.4}}))
        --         end
        --         local function doAnimate3()
        --             GameUI.setTMStageIcon(self.nodeStageIcon, adata.stage, stage)
        --             icon = self.nodeStageIcon.__icon
        --             icon:setPosition(cp.x, cp.y)
        --             icon:setScale(4)
        --             state = 1
        --         end
        --         self.nodeStageIcon.view:runAction(ui.action.sequence({{"delay", 0.1}, {"call", doAnimate},
        --             {"delay", 0.2+0.5}, {"call", doAnimate2}, {"delay", 0.5}, {"call", doAnimate3}}))
        --     end
        -- end
    else
        -- 干脆直接关掉吧？
        display.closeDialog(self.priority)
    end
end

-- @brief 因为人数有限制所以肯定是全拉
-- @change: TODO 2018/2/28 因为改成全部人在同一个榜凑热闹所以这些逻辑都要改改
function TalentMatchPlayDialog:onRefreshRankDatas(rankDatas)
    self.rankTable:setLazyTableData(rankDatas.rankData, Handler(self.onUpdateRankCell, self), 0)
    GameUI.registerVisitBack(self, self.rankTable)
    if not rankDatas.myRankData then
        -- self.myRankNode:setVisible(false)
    else
        self.rankTable:locationIndex(rankDatas.myRankData.rank)
        if self.rankData then
            -- and rankDatas.myRankData.rank <= 10 then
            display.pushNotice(Localize("labelClaimNotice"))
            self.context.logData:getEmailDatas()
        end
    end
end

function TalentMatchPlayDialog:onUpdateRankCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    -- 通用排行数字
    GameUI.setRankNumber(reuseCell.playerRank, info.rank)
    -- 通用框逻辑，TODO 封装一下
    GameUI.setAngleView(reuseCell.imgSpecialLeft, 1, 75)
    GameUI.setAngleView(reuseCell.imgSpecialRight, 4, 75)
    reuseCell.imgSpecialLeft:setVisible(info.rank <= 3)
    -- 自己，醒目绿？
    if info.id == self.context.uid then
        info.name = self.context:getInfoItem(const.InfoName)
        info.head = self.context:getInfoItem(const.InfoHead)
        info.level = self.context:getInfoItem(const.InfoLevel)
        ui.setColor(reuseCell.imgBackColor, 207, 255, 186)
        ui.setColor(reuseCell.imgSpecialLeft, 174, 227, 151)
        ui.setColor(reuseCell.imgSpecialRight, 174, 227, 151)
    elseif info.rank == 1 then --第一名
        ui.setColor(reuseCell.imgBackColor, 235, 211, 146)
        ui.setColor(reuseCell.imgSpecialLeft, 230, 189, 63)
        ui.setColor(reuseCell.imgSpecialRight, 230, 189, 63)
    elseif info.rank == 2 then --第二名
        ui.setColor(reuseCell.imgBackColor, 196, 209, 218)
        ui.setColor(reuseCell.imgSpecialLeft, 149, 194, 215)
        ui.setColor(reuseCell.imgSpecialRight, 149, 194, 215)
    elseif info.rank == 3 then--第三名
        ui.setColor(reuseCell.imgBackColor, 215, 180, 146)
        ui.setColor(reuseCell.imgSpecialLeft, 203, 149, 86)
        ui.setColor(reuseCell.imgSpecialRight, 203, 149, 86)
    else
        ui.setColor(reuseCell.imgBackColor, 255, 241, 211)
        ui.setColor(reuseCell.imgSpecialRight, 229, 214, 182)
    end
    if info.rewardId == 0 or self.rankData then
        reuseCell.imgSpecialRight:setVisible(false)
        reuseCell.nodeRewardBox:setVisible(false)
        if self.ainfo.adata.stage == 0 or self.rankData then
            reuseCell.nodeRankInfo:setPositionX(1340)
        else
            reuseCell.nodeRankInfo:setPositionX(1089)
        end
    else
        reuseCell.imgSpecialRight:setVisible(true)
        reuseCell.nodeRewardBox:setVisible(true)
        GameUI.setTMRewardBox(reuseCell.nodeRewardBox, info.rewardId)
        local newRewards = {}
        if info.otherReward then
            table.insert(newRewards, info.otherReward)
        end
        for _, reward in ipairs(info.rewards) do
            table.insert(newRewards, reward)
        end
        reuseCell.nodeRewardBox:setScriptCallback(ButtonHandler(display.sendIntent,
            {class="game.Dialog.TalentMatchBoxDialog", params={
                rewards=newRewards, titleName=Localize("titleTMBox" .. info.rewardId)}}))
        if info.otherReward then
            reuseCell.nodeSpecialAct:setVisible(true)
            GameUI.setNormalIcon(reuseCell.nodeSpecialAct, info.otherReward, true)
        else
            reuseCell.nodeSpecialAct:setVisible(false)
        end
    end

    local headInfo = reuseCell._headInfo
    if not headInfo then
        headInfo = {headScale=1, isLeft=true, notBlack=true, back=ui.node()}
        display.adapt(headInfo.back, reuseCell.playerHead.size[1]/2, reuseCell.playerHead.size[2]/2)
        reuseCell.playerHead:addChild(headInfo.back)
        headInfo.back:setScale(reuseCell.playerHead.size[1] / 150)
        reuseCell._headInfo = headInfo
    end
    headInfo.iconType = info.head
    headInfo.level = info.level
    GameUI.updateUserHeadTemplate(headInfo.back, headInfo)

    reuseCell.playerName:setString(info.name)

    -- 分类型，先临时写一下
    if self.ainfo.aid == 101 then
        GameUI.setNormalIcon(reuseCell.rankImgIcon, {const.ItemRes, const.ProGold}, true)
        reuseCell.rankLabel:setString(tostring(info.avalue))
    elseif self.ainfo.aid == 102 then
        GameUI.setNormalIcon(reuseCell.rankImgIcon, "images/matchs/zombie.png")
        reuseCell.rankLabel:setString(tostring(info.avalue))
    elseif self.ainfo.aid == 103 then
        GameUI.setNormalIcon(reuseCell.rankImgIcon, "images/matchs/hero.png")
        reuseCell.rankLabel:setString(tostring(self.context.talentMatch:getDisplayTMPvhStage(info.avalue+1)))
    else
        GameUI.setNormalIcon(reuseCell.rankImgIcon, "images/matchs/mythical.png")
        reuseCell.rankLabel:setString(tostring(info.avalue))
    end
    GameUI.registerVisitButton(reuseCell.btnVisitUser, self, tableView, reuseCell.playerName, info)
    return reuseCell
end

-- 数据
function TalentMatchPlayDialog:initData()
    if self.rankData then
        self:onRefreshDatas(self.myRankData)
    else
        self.context.talentMatch:getMatchNow(self.ainfo.aid, Handler(self.onRefreshDatas, self))
    end
end

function TalentMatchPlayDialog:onUpdate(diff)
    local stime = GameLogic.getSTime()
    if self.rankData then
        self.labelLeftTime:setVisible(false)
    elseif self.ainfo.etime <= stime then
        display.closeDialog(self.priority)
    else
        self.labelLeftTime:setString(Localize("labelEndTime") .. Localizet(self.ainfo.etime - stime))
    end
end

return TalentMatchPlayDialog
