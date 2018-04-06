local TalentMatchHelpDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")
local GameSetting = GMethod.loadScript("game.GameSetting")

function TalentMatchHelpDialog:onInitDialog()
    self:setLayout("TalentMatchHelpDialog.json")
end

function TalentMatchHelpDialog:onEnter()
    self:initUI()
    self:initData()
end

function TalentMatchHelpDialog:initUI()
    self.title:setString(Localize("labelHelp"))
    self.questionBut:setVisible(false)
    -- 截断人物
    local scaleX = self.roleImg.view:getScaleX()
    local scaleY = self.roleImg.view:getScaleY()
    self.roleImg.view:setScale(scaleX)
    local tsize = self.roleImg.view:getTexture():getContentSize()
    self.roleImg.view:setTextureRect(cc.rect(0, 0, tsize.width, tsize.height * scaleY / scaleX),
        false, cc.size(tsize.width, tsize.height * scaleY / scaleX))
    self.btnTryPlay:setScriptCallback(ButtonHandler(self.onTryBattle, self))
    if self.ainfo.aid > const.TalentMatchPvh then
        self.btnSetLayout:setVisible(true)
        -- 怎么设置阵型再想吧，先入口做上去
        self.btnSetLayout:setScriptCallback(ButtonHandler(self.onSetLayout, self))
    else
        self.btnSetLayout:setVisible(false)
    end
    self.effectNode.view:runAction(ui.action.arepeat(ui.action.rotateBy(1, 150)))
end

-- 数据
function TalentMatchHelpDialog:initData()
    --模拟数据
    local showData = self.context.talentMatch:getRecommendData(self.ainfo.aid)
    self.__tryId = showData.qid
    self.__tryHids = showData.hids
    self.layoutHeros:setBusyTableData(showData.hids, Handler(self.onUpdateHeroCell, self))

    -- if matchData.actEndTime > GameLogic.getSTime() then
    self.btnGiftBox:setVisible(true)
    self.btnGiftBox:setScriptCallback(ButtonHandler(self.onBuyActivity, self))

    local redNumCache = GameSetting.getLocalData(self.context.uid, "RedNums") or {}
    if (redNumCache["TM" .. self.ainfo.aid] or 0) < self.ainfo.stime then
        self.redNum = GameUI.addRedNum(self.btnGiftBox,130,130,0,1,1)
        self.redNum:setNum(99)
        GameEvent.bindEvent(self.redNum, "isClickPackage", self, function ()
            local redNumCache2 = GameSetting.getLocalData(self.context.uid, "RedNums") or {}
            if (redNumCache2["TM" .. self.ainfo.aid] or 0) >= self.ainfo.stime then
                self.redNum:removeFromParent(true)
                self.redNum = nil
            end
        end)
    end
    -- else
    --     self.btnGiftBox:setVisible(false)
    -- end
    if self.ainfo.adata.stage == 0 then
        self.labelRewardTips:setString(Localize("labelRuleTips"))
        self.labelRuleDesc:setString(Localize(self.ainfo.adata.descKey or ("labelTMDesc" .. self.ainfo.aid)))
        self.scrollRank:setVisible(false)
    else
        self.labelRewardTips:setString(Localize("btnRewardTips"))
        self.labelRuleDesc:setVisible(false)
        local infos = {{isHeader=1}}
        local aid = self.ainfo.aid
        local rewards = SData.getData("tmRewards", aid * 100 + self.context.talentMatch:getStageByMatch(aid))
        for i, reward in ipairs(rewards) do
            table.insert(infos, {idx=i, data=reward})
        end
        self.scrollRank:setBusyTableData(infos, Handler(self.onUpdateRewardCell, self))
    end
end

function TalentMatchHelpDialog:onUpdateRewardCell(reuseCell, tableView, info)
    if not reuseCell then
        if info.isHeader then
            reuseCell = tableView:createItem(1)
        else
            reuseCell = tableView:createItem(2)
        end
        reuseCell:loadViewsTo()
    end
    if info.isHeader then
        reuseCell.labelRuleDesc:setString(Localize(self.ainfo.adata.descKey or ("labelTMDesc" .. self.ainfo.aid)))
    else
        if info.idx % 2 == 1 then
            reuseCell.backColor:setColor(220, 199, 167)
        else
            reuseCell.backColor:setColor(244, 228, 199)
        end
        GameUI.setTMRewardBox(reuseCell.nodeRewardBox, info.idx)
        reuseCell.labelRankFrom:setString(tostring(info.data.rankFrom))
        if info.data.rankTo > info.data.rankFrom then
            reuseCell.nodeRankTo:setVisible(true)
            reuseCell.labelRankTo:setString(tostring(info.data.rankTo))
        else
            reuseCell.nodeRankTo:setVisible(false)
        end

        ViewTemplates.setImplements(reuseCell.layoutReward, "LayoutImplement", {callback=Handler(self.onUpdateItemCell, self), withIdx=false})--当前奖励
        reuseCell.layoutReward:setLayoutDatas(info.data.rewards)
    end

    return reuseCell
end

-- 数据
function TalentMatchHelpDialog:onUpdateItemCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    if info[1] ~= reuseCell.displayIType or info[2] ~= reuseCell.displayIId then
        reuseCell.displayIType = info[1]
        reuseCell.displayIId = info[2]
        reuseCell:removeAllChildren(true)
        GameUI.addItemIcon(reuseCell, info[1], info[2], reuseCell.size[1]/200,
                           reuseCell.size[1]/2, reuseCell.size[2]/2, true,nil,{itemNum=info[3]})
        GameUI.registerTipsAction(reuseCell, self.view, info[1], info[2], reuseCell.size[1]/2, reuseCell.size[2]/2)
    end
    return reuseCell
end

function TalentMatchHelpDialog:onUpdateHeroCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    local hinfo = reuseCell._heroInfo
    if not hinfo then
        hinfo = {noLv=true}
        reuseCell._heroInfo = hinfo
    end
    GameUI.setNormalIcon(reuseCell.nodeHeroHead, {const.ItemHero, info, 1})
    -- local hero = self.context.heroData:makeHero(info)
    -- GameUI.updateHeroTemplate(reuseCell.nodeHeroHead, hinfo, hero)
    -- reuseCell.nodeHeroHead.view:setScale(reuseCell.nodeHeroHead.size[1]/250)
    -- local rating = hero.info.displayColor and hero.info.displayColor >= 5 and 5 or hero.info.rating
    -- GameUI.addSSR(reuseCell.nodeHeroHead.view, rating, 0.4, 5, 5, 10, GConst.Anchor.LeftBottom)

    GameUI.registerTipsAction(reuseCell, self.view, const.ItemHero, info, reuseCell.size[1]/2, reuseCell.size[2]/2)
    return reuseCell
end

function TalentMatchHelpDialog:onBuyActivity()
    display.sendIntent({class="game.Dialog.TalentMatchGiftDialog", params={ainfo=self.ainfo}})
end

function TalentMatchHelpDialog:onSetLayout()
    --TODO 应该做个配置之类的，不过先不管了
    SetBattleArrDialog.new(self.ainfo.aid-100)
end

function TalentMatchHelpDialog:onTryBattle()
    local aid = self.ainfo.aid
    local tmData = self.context.talentMatch:getMatchNow(aid)
    if not tmData then
        return
    end
    local nowIdx = self.__tryId
    local heros = {}
    for i, hid in ipairs(self.__tryHids) do
        local hero = GameLogic.getUserContext().heroData:makeHero(hid)
        hero.level = hero.info.maxLevel
        hero.mSkillLevel = const.MaxMainSkillLevel
        hero.soldierLevel = const.MaxSoldierLevel
        hero.soldierSkillLevel1 = const.MaxSoldierSkillLevel
        hero.soldierSkillLevel2 = const.MaxSoldierSkillLevel
        hero.awakeUp = hero.info.awake == 1 and const.MaxAwakeLevel or 0
        heros[i] = hero
        hero:getControlData()
    end
    if aid == const.TalentMatchPvp then
        -- PVP试玩
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvp,
            bparams = {tryHids=heros, aid = aid}})
    elseif aid == const.TalentMatchPvj then
        if nowIdx == 0 then
            local maxIdx = KTLen(SData.getData("pvjboss6"))  --最大关卡数
            nowIdx = (tmData.avalue2 + 1) < maxIdx and (tmData.avalue2 + 1) or maxIdx  --当前关卡ID
        end
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvj,
            idx = nowIdx, bparams = {index = nowIdx, DRPvj = true, tryHids=heros, aid=aid}})
    elseif self.ainfo.aid == const.TalentMatchPvh then
        if nowIdx == 0 then
            local maxIdx = KTLen(SData.getData("npvhHero"))-1 --最大关卡数; 先随便写写
            nowIdx = tmData.avalue + 1
            if nowIdx > maxIdx then
                nowIdx = maxIdx
            end
            if SData.getData("npvhHero", nowIdx) == 0 then
                nowIdx = nowIdx - 1
            end
        end
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvh,
            bparams={stage=nowIdx, nightmare=true, tryHids=heros, aid=aid, avgLevel=self.context.heroData:getTopAvgLevel(5)}})
    else
        if nowIdx == 0 then
            local maxIdx = KTLen(SData.getData("godBeastBoss", aid))  --最大关卡数
            nowIdx = (tmData.avalue2 % 100) + 1
            if nowIdx > maxIdx then
                nowIdx = maxIdx
            end
        end
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvb,
            aid=self.ainfo.aid, stage=nowIdx, lostHp=0, bparams = {tryHids=heros, aid=aid}})
    end
end

return TalentMatchHelpDialog
