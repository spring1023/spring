
local SData = GMethod.loadScript("data.StaticData")
--排行榜
local AllRankingListDialog = class2("AllRankingListDialog",function()
    return BaseView.new("AllRankingListDialog.json")
end)

function AllRankingListDialog:ctor(index)
    self.rankInfos = self:getRankInfos()
    -- 限时活动排行榜特殊处理
    self.actRank = GameLogic.getUserContext().activeData:getRankData()
    -- 规则还可能再调所以先这么写
    if not index or (index == 7 or index == 1 or index == 2 or index == 3 or index == 5 or index == 10) then
        self.showOrder = {7, 1, 2, 3, 5}
        if not GameLogic.useTalentMatch then
            table.insert(self.showOrder, 10)
        end
    else
        self.showOrder = {index}
        if index == 6 then
            self.rankInfos[6].subCells = self.actRank
        end
    end
    self.uid = GameLogic.uid
    local context = GameLogic.getUserContext()
    self.sid = context.mergeSid or context.sid or 1
    if GameLogic.getUserContext().union then
        self.cid = GameLogic.getUserContext().union.id--联盟id
    else
        self.cid = 0
    end
    memory.loadSpriteSheetRelease("images/rankNums.plist", true)

    self.index = index or 7 --显示对应的排行榜,主界面默认进入“战力排行榜”
    self.moveToWorship = 0--用于声望膜拜后的scorll滚动
    self.dialogDepth = display.getDialogPri()+1
    self.priority = self.dialogDepth
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp = viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,0))
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))
    self:getRankRewardTime()
    display.showDialog(self)
end

-- @把排行榜数据缓存在context里，避免重复请求排行榜
function AllRankingListDialog:getRankInfos()
    local context = GameLogic.getUserContext()
    if not context.rankInfos then
        -- 排行榜模块
        local _rankInfos = {}

        _rankInfos[1] = {id="labTopPlayer", name="PvPScore", name2="pvprk", subCells={"region"},
            viewFunc = "UserPvp", cellName = "cellViews_topPlayer", timeKey="pvp", timeId=181} --顶级玩家榜
        _rankInfos[2] = {id="labUnionCup", name="PvlRankDay", name2="pvlrk", subCells={"region", "world"},
            viewFunc = "UnionPvp", cellName = "cellViews_unionCup", isUnion = true, timeKey="pvl", timeId=182} --联盟金杯榜
        _rankInfos[3] = {id="labHeroTrial", name="PvtRank", name2="pvtrk", subCells={"region"},
            viewFunc = "UserPvt", cellName = "cellViews_heroTrial", timeKey="pvt", timeId=183} --英雄试炼榜
        _rankInfos[4] = {id="labUnionCopy", name="PvbRank", name2="pvbrk", subCells={"region", "world"},
            viewFunc = "UnionPve", cellName = "cellViews_unionCopy", isUnion=true, timeKey="pvb", timeId=184} --联盟副本榜
        _rankInfos[5] = {id="labArena", name="PvcRankNew", name2="PvcrkNew", subCells={"region"},
            viewFunc = "UserPvc", cellName = "cellViews_arena", timeKey="pvc", timeId=185} --竞技场榜
        _rankInfos[6] = {id="labActLimit", name="ActRank", name2="actrk", subCells={},
            viewFunc = "UserAct", cellName = "cellViews_actLimit", requestFunc="getActRankRequest"} --限时活动榜
        _rankInfos[7] = {id="labCombat", name="CombRank", name2="combrk", subCells={"region"},
            viewFunc = "UserCombat", cellName = "cellViews_combat"} --战力排行榜
        _rankInfos[8] = {id="labArenaBox", name="PvcRankShop", name2="PvcrkShop", subCells={"region"},
            viewFunc = "UserBox", cellName = "cellViews_arena"} --竞技场宝箱
        _rankInfos[9] = {id="btnUnionWelfareRank", name="WelRank", name2="welrk", subCells={"region"},
            viewFunc = "UnionWelfare", cellName = "cellViews_unionWelfare", isUnion=true} --联盟福利榜
        _rankInfos[10] = {id="labelPrestigeRank", name="PopRank", name2="poprk", subCells={"region"},
            viewFunc = "UserPopular", cellName = "cellViews_prestige", requestFunc="getPopularRankRequest"} --声望排行榜
        _rankInfos[11] = {id="labKnockDivideRankTitle", name="PvzRank", name2="PvzRank", subCells={"region"},
            viewFunc = "UserPvz", cellName = "cellViews_knockDivide", requestFunc="getPvzRankRequest"} --小组赛排行榜
        context.rankInfos = _rankInfos
    end
    local stime = GameLogic.getSTime()
    for _, rankInfo in pairs(context.rankInfos) do
        if not rankInfo.datas then
            rankInfo.datas = {}
            rankInfo.expires = {}
        else
            for k, v in pairs(rankInfo.expires) do
                if v <= stime then
                    rankInfo.datas[k] = nil
                end
            end
        end
    end
    return context.rankInfos
end

function AllRankingListDialog:onQuestion()
    HelpDialog.new("dataQuestionRank")
end
--主要是init左侧的滚动tabView
function AllRankingListDialog:initUI()
    local viewsNode=ui.node()
    display.adapt(viewsNode,0,0)
    self:addChild(viewsNode)
    self.viewsNode=viewsNode

    local topNode=ui.node()
    display.adapt(topNode,0,0)
    self:addChild(topNode)
    self.topNode=topNode

    self:loadView("leftViewsBack")
    local infos={}
    for i=1,#self.showOrder do
        local id=self.showOrder[i]
        if self.rankInfos[id] then
            table.insert(infos,{idx=i,id=id,name=self.rankInfos[id].id})
            if id == self.index then
                self.firstIdx = i
            end
        end
    end
    if not self.firstIdx then
        self.firstIdx = 1
    end
    self:addTableViewProperty("leftTableView",infos,Script.createBasicHandler(self.onUpdateLeftRank, self))
    self:loadView("leftTableView")
    local viewTab = self:getViewTab()
    if self.firstIdx > 1 then
        viewTab.leftTableView:moveAndScaleToCenter(1, 156, 871-self.firstIdx*206, 0.01)
    end

    self.butTableView=self:getTableView("leftTableView")
    self:chooseLeftRank(self.firstIdx, self.index, self.firstButBack)
    if self.firstIdx > 1 then
        viewTab.leftTableView:moveAndScaleToCenter(1, 156, 871-self.firstIdx*206, 0.01)
    end
end

function AllRankingListDialog:onUpdateLeftRank(cell, tableView, info)
    local bg = cell:getDrawNode()
    local i=info.id
    self:loadView("butInfoCellViews",bg)  --左侧的每个cell单元
    local viewTab = self:getViewTab()
    viewTab.rankName:setString(StringManager.getString(info.name))
    --local butBack=viewTab.butBack
    if i==self.index then
        self.firstButBack=cell
        self.firstIdx = info.idx
    end
    local function butCall()
        self:chooseLeftRank(info.idx, i, cell)
    end
    cell:setScriptCallback(ButtonHandler(butCall))
end

function AllRankingListDialog:chooseLeftRank(idx, id, cell)
    self.index = id
    local i = idx
    local scells = self.rankInfos[id].subCells
    local subLen = #scells
    --选中加白框表示为选中状态, 选中变为绿色
    if self.checkedButBack then
        self.checkedButBack:removeFromParent(true)
    end
    local chosed = ui.scale9("images/bgWhite.9.png", 20, {472, 189})
    chosed:setCustomPoint(3, 0.984, 1, 1, 1)          --设置白框的倾斜效果
    display.adapt(chosed, 221, 80, GConst.Anchor.Center)
    cell:getDrawNode():addChild(chosed)
    self.checkedButBack = chosed

    local subNode, viewTab
    if not GameLogic.useTalentMatch then
        local nodeH = 168 * subLen
        subNode = self.butTableView:addNode(i, nodeH, -1)
        self:loadView("actNodeBack", subNode)
        viewTab = self:getViewTab()
        viewTab.colorBack:setScaleY(subLen)
    end

    ----------------------------------------
    local btnNode
    local selectBtn = {}
    if not GameLogic.useTalentMatch then
        for i, scell in ipairs(scells) do
            btnNode = ui.node({392,115})
            display.adapt(btnNode, 0, 57-168*i, GConst.Anchor.Center)
            subNode:addChild(btnNode)
            self:loadView("actNodeBtn", btnNode)
            if scell == "region" then
                viewTab.btnRegion:setString(Localize("btnRegion"))
            elseif scell == "world" then
                viewTab.btnRegion:setString(Localize("btnWorld"))
            else
                viewTab.btnRegion:setString(Localize(scell.actData.actLeftTitle))
            end
            if not selectBtn[i] then
                selectBtn[i] = viewTab.butRegion
            end
            viewTab.butRegion:setTouchThrowProperty(true, true)
        end
    end

    self.xuanzhong = nil
    local function changChecked(i)
        self.viewsNode:removeAllChildren(true)
        self:scrollTo()
        if self.xuanzhong then
            self.xuanzhong:removeFromParent(true)
        end

        for k=1, subLen do
            if i == k then
                if not GameLogic.useTalentMatch then
                    self:loadView("xuanzhongView", selectBtn[i]:getDrawNode())
                end
                if scells[i] == "region" then
                    self:getRankData(self.index, "region") --区域榜
                elseif scells[i] == "world" then
                    self:getRankData(self.index, "world") --世界榜
                else
                    self.actRankIdx = scells[i].actData.actRankIdx
                    self.actRankData = scells[i].actData
                    self:getRankData(self.index, scells[i].actId) --限时活动
                end
            end
        end
        if not GameLogic.useTalentMatch then
            self.xuanzhong = viewTab.xuanzhong
        end
    end
    if not GameLogic.useTalentMatch then
        for i=1, subLen do
            selectBtn[i]:setScriptCallback(Script.createCallbackHandler(changChecked, i))
        end
    end
    changChecked(1)
end

function AllRankingListDialog:scrollTo(px,py)
    if self.seeOperationNode then
        self.seeOperationNode:removeFromParent(true)
        self.seeOperationNode=nil
    end
end

function AllRankingListDialog:seeOperationViews(i,posX,posH,data)
    local upLimitH=940
    local downLimitH=370
    local cursorH=0
    if posH<downLimitH then
        cursorH=posH-downLimitH
        posH=downLimitH
    elseif posH>upLimitH then
        cursorH=posH-upLimitH
        posH=upLimitH
    end
    if cursorH>56 then
        cursorH=56
    elseif cursorH<-66 then
        cursorH=-66
    end
    if self.seeOperationNode then
        self.seeOperationNode:removeFromParent(true)
        self.seeOperationNode=nil
        if self.seeIdx==i then
            self.seeIdx=nil
            return
        end
    end
    self.seeIdx=i
    local seeNode=ui.button({443,240},nil,{image =nil,priority=-3,actionType=0})
    display.adapt(seeNode,60+posX,posH, GConst.Anchor.Left)
    self:addChild(seeNode,3)

    self.seeOperationNode=seeNode
    display.setNodeTouchRemove(self,"seeOperationNode")
    self:loadView("seeNodeViews",seeNode:getDrawNode())
    local viewTab=self:getViewTab()
    viewTab.imaCursor:setPositionY(120+cursorH)
    local str = data[3]
    if self.index==10 then
        str = data[2]
    end
    viewTab.labName:setString(StringManager.getString(str))
    viewTab.butVisit:setListener(function()
        --参观联盟或玩家
        if self.index==2 or self.index==4 or self.index==9 then
            self:showUnion(data[7])
        else
            GameEvent.sendEvent(GameEvent.EventVisitBegin,{type = const.VisitTypeUn, uid = data[6]})
        end
    end)
end

-- 刷新顶端显示

-- @brief 顶级玩家榜
function AllRankingListDialog:showTopUserPvp(rankInfo, rwName)
    self:loadView("upViews_topPlayer", self.topNode)
    local viewTab = self:getViewTab()
    local dt = rankInfo.rewardTime - GameLogic.getTime()
    viewTab.labRewardTime:setString(Localizet(dt))
    local datas = rankInfo.datas[rwName]
    local rankNum = self.__myRank or 10000

    local drewardsID = nil
    local srewardsID = nil
    local topRankDatas = SData["AllRankConfig"][1]
    for i,tab in KTIPairs(topRankDatas) do
        if rankNum >= tab["minrk"] and rankNum <= tab["maxrk"] then
            drewardsID = tab["drewards"]
            srewardsID = tab["srewards"]
            break
        end
    end
    if not drewardsID then--超出了最大排名奖励
        drewardsID = topRankDatas[KTLen(topRankDatas)]["drewards"]
        srewardsID = topRankDatas[KTLen(topRankDatas)]["srewards"]
    end

    local srewardsNum=0
    for i,tab in KTIPairs(SData["AllRankRewards"]) do
        if tab["id"] == drewardsID then
            local x = viewTab.labRankAward:getPositionX()+viewTab.labRankAward:getContentSize().width+90
            GameUI.addItemIcon(self.topNode, tab["gtype"], tab["gid"], 0.65, x, 1286)
            viewTab.labRankAwardNum:setString(tostring(tab["gnum"]))
        end
        if tab["id"] == srewardsID then
            srewardsNum = srewardsNum+1
            if srewardsNum == 1 then
                viewTab.labCompetitionSeason:setVisible(true)
                viewTab.labCompetitionSeasonNum:setVisible(true)
                local x = viewTab.labCompetitionSeason:getPositionX()+viewTab.labCompetitionSeason:getContentSize().width+90
                GameUI.addItemIcon(self.topNode, tab["gtype"], tab["gid"], 0.65, x, 1115)
                viewTab.labCompetitionSeasonNum:setString(tostring(tab["gnum"]))
            elseif srewardsNum == 2 then
                local x = viewTab.labCompetitionSeason:getPositionX()+viewTab.labCompetitionSeason:getContentSize().width+400
                GameUI.addItemIcon(self.topNode, tab["gtype"], tab["gid"], 0.65, x, 1115)
                viewTab.labCompetitionSeasonNum2:setVisible(true)
                viewTab.labCompetitionSeasonNum2:setString(tostring(tab["gnum"]))
            end
        end
    end
    viewTab.butTopPlayerRewardExplain:setScriptCallback(ButtonHandler(RewardDescription.new, 5))
    viewTab.butChallenge:setScriptCallback(ButtonHandler(display.showDialog, PlayInterfaceDialog))
end

-- @brief 联盟金杯榜
function AllRankingListDialog:showTopUnionPvp(rankInfo, rwName)
    self:loadView("upViews_unionCup",self.topNode)
    local logo
    if GEngine.rawConfig.logoSpecial then
        logo = ui.sprite(GEngine.rawConfig.logoSpecial[1])
    elseif GEngine.rawConfig.logoSpecialQianxun then
        local language = General.language
        logo = ui.sprite(GEngine.rawConfig.logoSpecialQianxun[1][language])
    elseif General.language == "CN" or General.language == "HK" then
        logo = ui.sprite("images/coz2logo3.png")
    else
        logo = ui.sprite("images/coz2logo3_2.png")
    end
    display.adapt(logo, 374, 1236, GConst.Anchor.Center)
    logo:setScale(0.6)
    self.topNode:addChild(logo)

    local viewTab=self:getViewTab()
    local dt = rankInfo.rewardTime - GameLogic.getTime()
    viewTab.labRewardTime:setString(Localizet(dt))
    viewTab.butRewardExplain:setScriptCallback(ButtonHandler(RewardDescription.new, 1))
end

-- @brief 试炼榜
function AllRankingListDialog:showTopUserPvt(rankInfo, rwName)
    self:loadView("upViews_heroTrial", self.topNode)
    local viewTab = self:getViewTab()
    local dt = rankInfo.rewardTime - GameLogic.getTime()
    viewTab.labHeroTrialDescribe:setString(Localize("labHeroTrialDescribe") .. Localizet(dt))
    local function callChange()
        if GameLogic.getUserContext().buildData:getMaxLevel(const.Town) < const.HeroTrialLimit  then
            display.pushNotice(Localize("stringHeroTrialNotice"))
        else
            HeroTrialDialog.new()
        end
    end
    self.trailRankRewardNum = viewTab.labelRankReWardNum

    local rewardCoin = 0
    if self.__myRank then
        local rewardsV = SData.getData("AllRankRewards")
        local rewardsK = SData.getData("AllRankConfig")
        for k,v in ipairs(rewardsK[3]) do
            if self.__myRank and v.maxrk and v.minrk and self.__myRank >= v.minrk and self.__myRank <= v.maxrk then
                rewardCoin = rewardsV[60+k].gnum
            end
        end
    end
    self.trailRankRewardNum:setString(tostring(rewardCoin))
    viewTab.butChallenge:setScriptCallback(ButtonHandler(callChange))
    viewTab.butSeeReward:setScriptCallback(ButtonHandler(function()
        RewardDescription.new(6, {rank=self.__myRank})
    end))
end

-- @brief 联盟副本榜
function AllRankingListDialog:showTopUnionPve(rankInfo, rwName)
    self:loadView("upViews_unionCopy", self.topNode)
    local viewTab = self:getViewTab()
    local dt = rankInfo.rewardTime - GameLogic.getTime()
    viewTab.labRewardTime:setString(Localizet(dt))
    if GameLogic.useTalentMatch then
        viewTab.labRewardTime:setVisible(false)
        viewTab.labRewardTimeTips:setVisible(false)
    end
end

-- @brief 竞技场榜
function AllRankingListDialog:showTopUserPvc(rankInfo, rwName)
    self:loadView("upViews_arena", self.topNode)
    local viewTab = self:getViewTab()
    local dt = rankInfo.rewardTime - GameLogic.getTime()
    viewTab.labRewardTime:setString(Localizet(dt))
    viewTab.butChallenge:setScriptCallback(ButtonHandler(GameLogic.doCondition,
        GameLogic.getUserContext(), const.ActTypePVC))
    if GameLogic.useTalentMatch then
        viewTab.labRewardTime:setVisible(false)
        viewTab.labRewardTimeTips:setVisible(false)
    end
end

-- @brief 活动榜
function AllRankingListDialog:showTopUserAct(rankInfo, rwName)
    local acts = self.actRankData
    self:loadView("upViews_actLimitTime", self.topNode)
    local endTime = acts.actEndTime
    local viewTab = self:getViewTab()
    local dt = endTime - GameLogic.getTime()
    viewTab.labelLeftTime:setString(Localize("labelTimeCount") .. Localizet(dt))

    local rwd = GameLogic.getUserContext().activeData:getConfigableRwds(acts.actId, 1)
    if rwd and rwd.conditions[1][1] == const.ActTypeRankCombat then
        viewTab.labactLimitDescribe:setString(Localize("activityDesc17031706"))
        ui.setFrame(viewTab.imgTopIcon, "images/otherIcon/iconActivity40001.png")
    end
    viewTab.butRewardExplain:setListener(function()
          RewardDescription.new(3, datas)
    end)
end

-- @brief 战力榜
function AllRankingListDialog:showTopUserCombat(rankInfo, rwName)
    self:loadView("upViews_combat", self.topNode)
    local viewTab = self:getViewTab()
    -- 这里理论上把节点删掉更正常吧？
    viewTab.labelLeftTime:setVisible(false)
end

-- @brief 宝箱榜
function AllRankingListDialog:showTopUserBox(rankInfo, rwName)
    self:loadView("upViews_arenaBox", self.topNode)
    local viewTab = self:getViewTab()
    viewTab.butChallenge:setScriptCallback(ButtonHandler(function ()
        GameLogic.getUserContext().arena:initData(function ()
            display.closeDialog(self.priority)
            StoreDialog.new({stype="honor"})
        end)
    end))
end

-- @brief 联盟福利榜
function AllRankingListDialog:showTopUnionWelfare(rankInfo, rwName)
    self:loadView("upViews_welfare", self.topNode)
    local viewTab = self:getViewTab()
    viewTab.rankingWelfareInfo:setString(Localize("labelWelfareUpDec"))
end

-- @brief 声望排行榜
function AllRankingListDialog:showTopUserPopular(rankInfo, rwName)
    GameLogic.getUserContext():refreshWorshipTime()
    self:loadView("upViews_prestige", self.topNode)
    local viewTab = self:getViewTab()
    local curWorshipTime = GameLogic.getUserContext():getProperty(const.ProHficNum)
    viewTab.upinfo:setString(Localize("labelWorshipUpDec"))
    viewTab.worshipNumLabel:setString(Localize("labelWorshipTime"))
    viewTab.nextWorshipLabel:setString(Localize("labelNextWorshipCost"))
    viewTab.butMyWorship:setScriptCallback(ButtonHandler(function ()
            local num = 0
            local datas = rankInfo.datas[rwName]
            if datas and datas.data and datas.data[4] then
                num = datas.data[4]
            end
            display.showDialog(MyWorshipDialog.new({setting = {pNum = num}}))
        end))
    if curWorshipTime>=10 then
        viewTab.worshipNum:setString(Localize("labelTimeFinish"))
        viewTab.nextWorshipNum:setString(0)
    else
        local nextCost = SData.getData("preWorship")[curWorshipTime+1].gnum
        viewTab.worshipNum:setString(Localizef("aDivideB", {a=curWorshipTime, b=10}))
        viewTab.nextWorshipNum:setString(nextCost)
    end
end

-- @brief 小组赛榜
function AllRankingListDialog:showTopUserPvz(rankInfo, rwName)
    self:loadView("upViews_knockDivide", self.topNode)
    local viewTab = self:getViewTab()
    local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
    local leftTime = KnockMatchData:getDivideLeftTime()
    if leftTime < 0 then
        leftTime = 0
    end
    local a = math.floor(leftTime/(60*60*24))
    local b = math.ceil((leftTime-(60*60*24*a))/(60*60))
    viewTab.lb_desc:setString(Localizef("labKnockDivideRankDec", {a = const.KnockDivideRank}))
    viewTab.lb_time:setString(Localizef("labKnockDivideRankTime", {a = a, b = b}))
end

function AllRankingListDialog:showRank(rwName)   --rwName world or region
    self.viewsNode:removeAllChildren(true)
    self:scrollTo()

    local rankInfo = self.rankInfos[self.index]
    local datas = rankInfo.datas[rwName] or {}
    local isUnion = rankInfo.isUnion
    local infos = {}
    rankInfo.__cellName = rankInfo.cellName
    rankInfo.__setCellData = self["setData" .. rankInfo.viewFunc]
    if rankInfo.viewFunc == "UnionWelfare" then
        local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWelfare)
        local wNum = 1
        if buffInfo[4]~=0 then
            wNum = buffInfo[4]/20
        end
        self.__welfareNum = wNum
    elseif rankInfo.viewFunc == "UserAct" then
        local rwd = GameLogic.getUserContext().activeData:getConfigableRwds(self.actRankData.actId, 1)
        if rwd and rwd.conditions[1][1] == const.ActTypeRankCombat then
            rankInfo.__cellName = "cellViews_combat"
            rankInfo.__setCellData = self.setDataUserCombat
        end
    end
    self.__myRank = nil
    for i=1, #datas do
        local data = datas[i]
        infos[i] = {id=i, data=data, rwName=rwName}
        if (isUnion and data[7] == self.cid and (rwName ~= "world" or (data[9] or 1) == self.sid)) or
            (not isUnion and data[6] == self.uid) then
            --自己的
            self.__myRank = data[1]
            self.__myRankIdx = i

            if rankInfo.isUnion then
                local selfNode = ui.node()
                display.adapt(selfNode, 610, 58)
                self.viewsNode:addChild(selfNode, 2)
                self:loadView("infoCellLine", selfNode)
                self:loadView("infoCellBack", selfNode)
                self:onUpdateRightCell(rankInfo, selfNode, nil, data)
            end
        end
    end
    -- 刷新上方显示
    self.topNode:removeAllChildren(true)
    self["showTop" .. rankInfo.viewFunc](self, rankInfo, rwName)
    -- 刷新数据显示
    if not rankInfo.isUnion then
        self:addTableViewProperty("rightTableViewUser", infos, Handler(self.onUpdateRightCell, self, rankInfo))
        self:addTableViewProperty2("rightTableViewUser", infos, Handler(self.scrollTo, self))
        self:loadView("rightViewsBack", self.viewsNode)
        self:loadView("rightTableViewUser", self.viewsNode)
    else
        self:addTableViewProperty("rightTableView", infos, Handler(self.onUpdateRightCell, self, rankInfo))
        self:addTableViewProperty2("rightTableView", infos, Handler(self.scrollTo, self))
        self:loadView("rightTableView", self.viewsNode)
    end
end

-- 显示查看页面
function AllRankingListDialog:showUnionOperationViews(params)
    local cell = params[1]
    local info = params[2]
    local data = params[3]
    local x = info.unionName:getPositionX() + info.unionName:getContentSize().width
    local pos = cell:convertToWorldSpace(cc.p(x,100))
    local pos2 = self:convertToNodeSpace(pos)
    self:seeOperationViews(info.id, pos2.x, pos2.y, data)
end
function AllRankingListDialog:showUserOperationViews(params)
    local cell = params[1]
    local info = params[2]
    local data = params[3]
    local x = info.playerName:getPositionX() + info.playerName:getContentSize().width
    local pos = cell:convertToWorldSpace(cc.p(x,100))
    local pos2 = self:convertToNodeSpace(pos)
    self:seeOperationViews(info.id, pos2.x, pos2.y, data)
end

-- 通用设置联盟有关信息
function AllRankingListDialog:normalSetUnionData(viewTab, data, bg)
    local flag = GameUI.addUnionFlag(tonumber(data[2]))
    display.adapt(flag, 260+78, 19+62)
    flag:setScale(0.46)
    bg:addChild(flag,2)
    viewTab.labRanking:setString(data[1])--排名
    viewTab.unionName:setString(StringManager.getString(data[3]))--名字
    viewTab.labPass:setString(data[5].."/"..data[4])--成员

    if data[1] == 1 then --第一名
        self:loadView("infoCellBack_1", bg)
    elseif data[1] == 2 then --第二名
        self:loadView("infoCellBack_2", bg)
        viewTab.imaRankNumberBox:setHValue(13)
    elseif data[1] == 3 then--第三名
        self:loadView("infoCellBack_3", bg)
        ui.setFrame(viewTab.imaRankNumberBox, "images/rankNumberBox2.png")
    else
        viewTab.imaRankNumberBox:setSValue(-100)
    end

    local liftNum = data[8]
    if liftNum >= 999 then liftNum = 999
    elseif liftNum <= -999 then liftNum = -999 end
    viewTab.labLiftNum:setString(math.abs(liftNum))--排名升降值

    if liftNum>0 then--上升，已默认

    elseif liftNum==0 then--持平
        ui.setFrame(viewTab.imaRanking, "images/rankFlat.png")
        viewTab.imaRanking:setPositionY(75)
        viewTab.labLiftNum:setVisible(false)
    elseif liftNum<0 then --下降
        ui.setFrame(viewTab.imaRanking, "images/rankDecline.png")
        viewTab.labLiftNum:setColor(cc.c3b(249,64,64))
    end
end

function AllRankingListDialog:normalSetUserData(viewTab, data, bg, isSelf)

    -- 通用排行数字
    GameUI.setRankNumber(viewTab.playerRank, data[1])
    -- 通用框逻辑，TODO 封装一下
    GameUI.setAngleView(viewTab.imgSpecialLeft, 1, 75)
    GameUI.setAngleView(viewTab.imgSpecialRight, 4, 75)
    viewTab.imgSpecialLeft:setVisible(data[1] <= 3)
    -- 自己，醒目绿？
    if data[6] == self.uid then
        local context = GameLogic.getUserContext()
        data[3] = context:getInfoItem(const.InfoName)
        data[2] = context:getInfoItem(const.InfoLevel)
        data[7] = context:getInfoItem(const.InfoHead)
        ui.setColor(viewTab.imgBackColor, 207, 255, 186)
        ui.setColor(viewTab.imgSpecialLeft, 174, 227, 151)
        ui.setColor(viewTab.imgSpecialRight, 174, 227, 151)
    elseif data[1] == 1 then --第一名
        ui.setColor(viewTab.imgBackColor, 235, 211, 146)
        ui.setColor(viewTab.imgSpecialLeft, 230, 189, 63)
        ui.setColor(viewTab.imgSpecialRight, 230, 189, 63)
    elseif data[1] == 2 then --第二名
        ui.setColor(viewTab.imgBackColor, 196, 209, 218)
        ui.setColor(viewTab.imgSpecialLeft, 149, 194, 215)
        ui.setColor(viewTab.imgSpecialRight, 149, 194, 215)
    elseif data[1] == 3 then--第三名
        ui.setColor(viewTab.imgBackColor, 215, 180, 146)
        ui.setColor(viewTab.imgSpecialLeft, 203, 149, 86)
        ui.setColor(viewTab.imgSpecialRight, 203, 149, 86)
    else
        ui.setColor(viewTab.imgBackColor, 255, 241, 211)
        ui.setColor(viewTab.imgSpecialRight, 229, 214, 182)
    end

    local headInfo = {headScale=1, isLeft=true, notBlack=true, back=ui.node()}
    display.adapt(headInfo.back, 61, 79)
    viewTab.playerHead:addChild(headInfo.back)
    headInfo.back:setScale(123 / 150)
    headInfo.iconType = data[7]
    headInfo.level = data[2]
    GameUI.updateUserHeadTemplate(headInfo.back, headInfo)

    viewTab.playerName:setString(data[3])
    viewTab.dotteLine:setVisible(data[1] >= 201 and data[6] == self.uid)

    -- -- viewTab.labRanking:setString(tostring(data[1]))--排名
    -- -- viewTab.playerLv:setString(tostring(data[2]))--等级
    -- viewTab.playerName:setString(data[3])--名字
    -- viewTab.playerName:setPositionY(85)
    -- -- 现在不跨服，加这个是不是有点问题？
    -- -- if viewTab.serverName then
    -- --     viewTab.serverName:setString(tostring(data[5]))--服务器
    -- -- end

    -- viewTab.playerRank:removeAllChildren(true)
    -- if data[1] > 3 then
    --     local _nstr = tostring(data[1])
    --     local _ox = 0
    --     local _os = 1
    --     local temp
    --     if _nstr:len() < 4 then
    --         _os = 1.3
    --     end
    --     for i=1, _nstr:len() do
    --         temp = ui.sprite("images/ranks/number_" .. _nstr:sub(i, i) .. ".png")
    --         temp:setScale(_os * 1.25)
    --         display.adapt(temp, _ox, 0, GConst.Anchor.Left)
    --         viewTab.playerRank:addChild(temp)
    --         _ox = _ox + temp:getContentSize().width * _os * 1.25
    --     end
    --     viewTab.playerRank:setContentSize(cc.size(_ox, 0))
    -- else
    --     viewTab.playerRank:setContentSize(cc.size(0, 0))
    --     local temp
    --     if data[1] == 1 then
    --         temp = ui.sprite("images/ranks/gold.png")
    --     elseif data[1] == 2 then
    --         temp = ui.sprite("images/ranks/silver.png")
    --     else
    --         temp = ui.sprite("images/ranks/copper.png")
    --     end
    --     temp:setScale(1.25)
    --     display.adapt(temp, 0, 0, GConst.Anchor.Center)
    --     viewTab.playerRank:addChild(temp)
    -- end
    -- if isSelf then
    --     self:setAngleView(viewTab.imgSpecialLeft, 3, 0.0875)
    --     self:setAngleView(viewTab.imgSpecialRight, 2, 0.1643)
    --     ui.setColor(viewTab.imgSpecialLeft, 205, 216, 178)
    --     ui.setColor(viewTab.imgSpecialRight, 205, 216, 178)
    -- else
    --     self:setAngleView(viewTab.imgSpecialLeft, 1, 0.2236)
    --     self:setAngleView(viewTab.imgSpecialRight, 4, 0.1823)
    --     viewTab.imgSpecialLeft:setVisible(data[1] <= 3)
    --     if data[1] == 1 then --第一名
    --         ui.setColor(viewTab.imgBackColor, 235, 211, 146)
    --         ui.setColor(viewTab.imgSpecialLeft, 230, 189, 63)
    --         ui.setColor(viewTab.imgSpecialRight, 230, 189, 63)
    --     elseif data[1] == 2 then --第二名
    --         ui.setColor(viewTab.imgBackColor, 196, 209, 218)
    --         ui.setColor(viewTab.imgSpecialLeft, 149, 194, 215)
    --         ui.setColor(viewTab.imgSpecialRight, 149, 194, 215)
    --     elseif data[1] == 3 then--第三名
    --         ui.setColor(viewTab.imgBackColor, 215, 180, 146)
    --         ui.setColor(viewTab.imgSpecialLeft, 203, 149, 86)
    --         ui.setColor(viewTab.imgSpecialRight, 203, 149, 86)
    --     else
    --         ui.setColor(viewTab.imgBackColor, 255, 241, 211)
    --         ui.setColor(viewTab.imgSpecialRight, 229, 214, 182)
    --     end
    -- end
end

function AllRankingListDialog:setDataUnionPve(viewTab, data, bg)
    self:normalSetUnionData(viewTab, data, bg)
    local g = math.floor(tonumber(data[6])/1000)
    local p = tonumber(data[6])%1000
    viewTab.labCopyChallenge:setString(Localize("labCopyChallenge") .. g .. Localize("labCopyChallenge2"))
    viewTab.labChallengeProcess:setString(Localize("labChallengeProcess") .. p .. "%")
end

function AllRankingListDialog:setDataUnionWelfare(viewTab, data, bg)
    self:normalSetUnionData(viewTab, data, bg)
    viewTab.labIntegral:setString(tostring(math.ceil(data[6] * self.__welfareNum))) --福利积分
end

function AllRankingListDialog:setDataUnionPvp(viewTab, data, bg)
    self:normalSetUnionData(viewTab, data, bg)
    viewTab.labIntegral:setString(tostring(data[6])) --金杯积分
end

function AllRankingListDialog:onUpdateRightCell(rankInfo, cell, tableView, info)
    local data
    local bg
    local viewTab = self:getViewTab()
    if not tableView then
        data = info
        bg = cell
    else
        data = info.data
        bg = cell:getDrawNode()
        if rankInfo.isUnion then
            self:loadView("infoCellBack",bg)
        else
            self:loadView("cellViewUser", bg)
        end
    end
    self:loadView(rankInfo.__cellName, bg)
    if tableView then
        if rankInfo.isUnion then
            info.unionName = viewTab.unionName
        else
            info.playerName = viewTab.playerName
        end
    end
    rankInfo.__setCellData(self, viewTab, data, bg, not tableView)
    if tableView then
        if rankInfo.isUnion then
            if info.rwName ~= "world" and data[7] ~= self.cid then
                cell:setScriptCallback(ButtonHandler(self.showUnionOperationViews, self, {cell, info, data}))
            end
        else
            if info.rwName~="world" and data[6] ~= self.uid then
                cell:setScriptCallback(ButtonHandler(self.showUserOperationViews, self, {cell, info, data}))
            end
        end
    end
end

function AllRankingListDialog:setDataUserPvz(viewTab, data, bg, isSelf)
    self:normalSetUserData(viewTab, data, bg, isSelf)
    viewTab.labIntegral:setString(data[4])--积分
    -- viewTab.playerLvBack:setVisible(false)
    -- viewTab.playerLv:setVisible(false)
    local score = data[4]
    local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
    local stage = KnockMatchData:getStageByScore(score)
    KnockMatchData:changeStageIcon(viewTab.img_stage, stage)
end

function AllRankingListDialog:btnWorshipCallback(info)
    --判断是否可以点
    --display.pushNotice(Localize("labelWorshipNumOut"))
    if info.worshipTime>=const.MaxPreWorshipTime then
        display.pushNotice(Localize("labelNotWorshipNum"))
        return
    end
    self.moveToWorship = info.id
    local pNum = self:getPerstigeData(info.worshiped,info.worship)
    local time = info.worshipTime
    local surTime = const.MaxPreWorshipTime-time
    local diamonNum = info.diamonNum

    display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"), Localizef("labelDialogWorshipInfo",{a = pNum,b = time,c = surTime,d=diamonNum}),{cvalue = diamonNum,ctype = 4,yesBut="btnYes",callback = function()
        --膜拜的逻辑
        if not GameNetwork.lockRequest() then
            return
        end
        _G["GameNetwork"].request("getClanPopular",{tid=info.uid},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                if data.code ==2 then
                    display.pushNotice("labelNotWorshipNum")
                elseif data.code==3 then
                    display.pushNotice("labelDiamondInsufficient")
                elseif data.code ==0 then
                    self.rankInfos[10].datas["region"][self.moveToWorship][4] = self.rankInfos[10].datas["region"][self.moveToWorship][4]+1
                    GameLogic.getUserContext():changeProperty(const.ProPopular,data.addPopular)
                    GameLogic.getUserContext():changeProperty(const.ProHficNum,1)
                    GameLogic.getUserContext():changeProperty(const.ResCrystal,-data.crystal)
                    GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeMobai,1)
                    display.pushNotice(Localizef("noticeGetItem",{name=data.addPopular..Localize("dataResName1040")}))
                    self:showRank("region")
                end
            end
        end)
    end}))
end

function AllRankingListDialog:getPerstigeData(num1,num2)
    local y = (0.6*num1-num2)*0.01
    local n = const.MinWorshipEarnings
    local x = math.floor(math.max(y,n))
    return x
end

function AllRankingListDialog:setDataUserPopular(viewTab, data, bg, isSelf)
    self:normalSetUserData(viewTab, data, bg, isSelf)
    viewTab.playerName:setPositionY(120)
    local context = GameLogic.getUserContext()
    local items = {}
    local pData = SData.getData("preWorship")
    local curWorshipTime = context:getProperty(const.ProHficNum)
    local diamondNum = 0
    if curWorshipTime >= const.MaxPreWorshipTime then
        viewTab.butWorship:setGray(true)
        viewTab.getPrestigeNum:setVisible(false)
    else
        diamondNum = pData[curWorshipTime+1].gnum
    end
    if isSelf or data[6] == self.uid then
        viewTab.butWorship:setVisible(false)
        viewTab.butWorship:setEnable(false)
        viewTab.getPrestigeNum:setVisible(false)
        viewTab.imgSpecialRight:setVisible(false)
    else
        local preNum = self:getPerstigeData(data[5], context:getProperty(const.ProPopular))
        items = {id = data[1],uid = data[6],worship=context:getProperty(const.ProPopular),worshiped=data[5],worshipTime=curWorshipTime,diamonNum=diamondNum}
        viewTab.getPrestigeNum:setString(Localizef("labelGetPrestigeRew",{a = preNum}))--获得xx声望

        viewTab.butWorship:setScriptCallback(Script.createCallbackHandler(self.btnWorshipCallback,self,items))
        viewTab.butWorship:setTouchThrowProperty(true,true)
    end
    viewTab.labelPrestige:setString(Localize("dataResName1040")..":"..data[5])
    viewTab.todayWorship:setString(Localize("labelToDayWorship"))--今日膜拜
    viewTab.todayWorshipNum:setString(data[4])
end

function AllRankingListDialog:setDataUserPvt(viewTab, data, bg, isSelf)
    self:normalSetUserData(viewTab, data, bg, isSelf)
    viewTab.labIntegral:setString(data[4])--积分
end

function AllRankingListDialog:setDataUserPvp(viewTab, data, bg, isSelf)
    self:normalSetUserData(viewTab, data, bg, isSelf)
    viewTab.labIntegral:setString(data[4]) --金杯数
end

function AllRankingListDialog:addArenaBox(bg,data)
    local snum = data[4]
    local bnums={math.floor(snum/100000/100000),math.floor(snum/100000)%100000,snum%100000}
    for i=1,3 do
        GameUI.addArenaBoxIcon(bg, i, 0.3, 760+210*(i-1), 88, 1)
        local temp = ui.label(bnums[i], General.font2, 40, {color={98,53,11}})
        display.adapt(temp,810+210*(i-1),95,GConst.Anchor.Left)
        bg:addChild(temp,1)
    end
end

function AllRankingListDialog:setDataUserPvc(viewTab, data, bg, isSelf)
    self:normalSetUserData(viewTab, data, bg, isSelf)
    viewTab.imgSpecialRight:setVisible(false)
end

function AllRankingListDialog:setDataUserBox(viewTab, data, bg, isSelf)
    self:normalSetUserData(viewTab, data, bg, isSelf)
    viewTab.imgSpecialRight:setVisible(false)
    self:addArenaBox(bg, data)
end

function AllRankingListDialog:setDataUserCombat(viewTab, data, bg, isSelf)
    self:normalSetUserData(viewTab, data, bg, isSelf)
    viewTab.labIntegral:setString(data[4])--战斗力
    viewTab.propertyComb:setString(Localize("propertyComb"))
end

function AllRankingListDialog:setDataUserAct(viewTab, data, bg, isSelf)
    self:normalSetUserData(viewTab, data, bg, isSelf)
    GameUI.addResourceIcon(bg, 4, 1, 1308, 86,0,2)
    viewTab.labIntegral:setString(data[4])--获得宝石数量
end

----------------------------------------------------------------------------------------------------------------
--@brief 获取联盟排行榜请求
function AllRankingListDialog:getUnionRankRequest(rankInfo, rwName)
    local aName = "getRankData_union"
    if rwName == "world" then
        local params = {
            mode = rankInfo.name .. 0,
            grm = rankInfo.name2 .. 0,
            cid = self.cid
        }
        return "getRankData_union_world", params
    else
        local params = {
            mode = rankInfo.name .. self.sid,
            grm = rankInfo.name2 .. self.sid,
            cid = self.cid
        }
        return "getRankData_union", params
    end
end

-- @brief 获取声望榜
function AllRankingListDialog:getPopularRankRequest(rankInfo, rwName)
    local params = {
        mode = rankInfo.name .. self.sid,
        grm = rankInfo.name2 .. self.sid,
        uid = self.uid
    }
    return "getRankPopular", params
end

-- @brief 获取末日争霸
function AllRankingListDialog:getPvzRankRequest(rankInfo, rwName)
    local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
    local week = KnockMatchData:getMatchWeek()
    local wk1 = week%2
    local wk2 = (week+1)%2
    local params = {
        mode = rankInfo.name .. "_" .. self.sid .. "_" .. wk1,
        grm = rankInfo.name2 .. "_" .. self.sid .. "_" .. wk2,
        uid = self.uid
    }
    return "getRankData", params
end

-- @brief 获取活动
function AllRankingListDialog:getActRankRequest(rankInfo, rwName)
    local params = {
        mode = rankInfo.name .. self.sid .. "_" .. rwName .. "_" .. self.actRankIdx,
        grm = rankInfo.name2 .. self.sid .. "_" .. rwName .. "_" .. self.actRankIdx,
        uid = self.uid
    }
    return "getRankData", params
end

function AllRankingListDialog:getRankData(index, rwName)
    local rankInfo = self.rankInfos[index]
    if rankInfo.datas[rwName] then
        if self.showRank and index == self.index then
            self:showRank(rwName)
        end
        return
    end
    local aName = "getRankData"
    local param = {}
    if rankInfo.requestFunc and self[rankInfo.requestFunc] then
        aName, param = self[rankInfo.requestFunc](self, rankInfo, rwName)
    else
        if rankInfo.isUnion then
            aName, param = self:getUnionRankRequest(rankInfo, rwName)
        else
            param = {
                mode = rankInfo.name .. self.sid,
                grm = rankInfo.name2 .. self.sid,
                uid = self.uid
            }
        end
    end
    GameUI.setLoadingShow("wifi", true, 0)
    _G["GameNetwork"].request(aName, param, function(isSuc, datas)
        GameUI.setLoadingShow("wifi", false, 0)
        if isSuc then
            rankInfo.datas[rwName] = datas
            local etime = GameLogic.getSTime() + 300
            rankInfo.expires[rwName] = etime
            if aName == "getRankPopular" then
                for _, data in ipairs(datas) do
                    data[2], data[3] = data[3], data[2]
                end
            end
            if self.showRank and index == self.index then
                self:showRank(rwName)
            end
        end
    end)
end

--排行榜奖励时间刷新，如果已经有时间就不要重新去拉了
function AllRankingListDialog:getRankRewardTime()
    local skipRequest = true
    local stime = GameLogic.getSTime()
    local _rankInfos = self.rankInfos
    local rankList = GameLogic.getUserContext().rankList
    for _, rankInfo in pairs(_rankInfos) do
        if rankInfo.timeKey then
            if rankList and rankList[rankInfo.timeId] then
                rankInfo.rewardTime = rankList[rankInfo.timeId][2]
            end
            if not rankInfo.rewardTime or rankInfo.rewardTime < stime then
                skipRequest = false
                break
            end
        end
    end
    if skipRequest then
        self:initUI()
        return
    end
    GameUI.setLoadingShow("wifi", true, 0)
    local context = GameLogic.getUserContext()
    local sid = context.mergeSid or context.sid or 1
    _G["GameNetwork"].request("getRankList2",{uid=self.uid, sid = sid},function(isSuc,data)
        GameUI.setLoadingShow("wifi", false, 0)
        if isSuc then
            for _, rankInfo in pairs(_rankInfos) do
                if rankInfo.timeKey and data[rankInfo.timeKey] then
                    rankInfo.rewardTime = data[rankInfo.timeKey][2]
                    if rankList then
                        rankList[rankInfo.timeId] = data[rankInfo.timeKey]
                    end
                end
            end
            if self.initUI then
                self:initUI()
            end
        end
    end)
end

function AllRankingListDialog:showUnion(lid)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getleagueinfo",{getleagueinfo={lid}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==2 then
                display.pushNotice(Localize("stringNOUnion"))
                return
            else
                UnionInfoDialog.new(data)
            end
        end
    end)
end
return AllRankingListDialog
