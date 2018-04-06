local SData = GMethod.loadScript("data.RewardDescriptionConfig")
local SData2 = GMethod.loadScript("data.StaticData")
--奖励说明
local RewardDescription = class2("RewardDescription",function()
    return BaseView.new("RewardDescription.json")
end)

function RewardDescription:ctor(mode,prams)
    --1金杯奖励说明 2试炼奖励说明 3限时活动
    --4淘汰赛活动 5顶级玩家奖励说明 6试炼奖励说明(新)
    self.mode=mode
    self.prams=prams
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,0))
    display.showDialog(self)

    self:initUI()
end

function RewardDescription:initUI()
    if self.mode==1 then
        self:loadView("unionCup_upViews")
        self:loadView("unionCup_downViews")
        local viewTab = self:getViewTab()

        local rewards=SData2.getData("unionBattleRewards")
        viewTab.titleCupExplain:setString(StringManager.getString("unionCupTitle"))
        viewTab.labelRankNum:setString(StringManager.getString("unionCupRank"))
        viewTab.labelReward2:setString(StringManager.getString("unionCupReward"))

        local infos={}
        for i,v in ipairs(rewards) do
            table.insert(infos,{id=i,data=v})
        end
        self:addTableViewProperty("unionCupTableView",infos,Script.createBasicHandler(self.callCell,self))
        self:loadView("unionCupTableView")
    elseif self.mode == 6 then
        self:loadView("heroTrail_upViews")
        self:loadView("heroTrail_downViews")
        local viewTab = self:getViewTab()
        local rewardsV=SData2.getData("AllRankRewards")
        local rewardsK=SData2.getData("AllRankConfig")
        viewTab.titleheroTrailExplain:setString(StringManager.getString("heroTrailTitle"))
        viewTab.labelheroTrailRankNum:setString(StringManager.getString("unionCupRank"))   --排名
        --顶级玩家榜每日奖励
        viewTab.labelheroTrailDailyReward:setString(StringManager.getString("heroTrailDR"))
        --顶级玩家榜赛季奖励
        viewTab.labelheroTrailWeeklyReward:setString(StringManager.getString("heroTrailWR"))
        --添加奖励 奖励范围在AllRankConfig[1] 奖励内容在AllRankRewards
        local infos={}
        for i=1,17 do
            table.insert(infos,{id=i,maxRank=rewardsK[3][i].maxrk,minRank=rewardsK[3][i].minrk,
                                numD=rewardsV[60+i].gnum,numW=rewardsV[i+77].gnum
                       })
        end
        self:addTableViewProperty("heroTrailTableView",infos,Script.createBasicHandler(self.heroTrailCallCell,self))
        self:loadView("heroTrailTableView")
    elseif self.mode == 5 then
        self:loadView("topPlayer_upViews")
        self:loadView("topPlayer_downViews")
        local viewTab = self:getViewTab()
        local rewardsV=SData2.getData("AllRankRewards")
        local rewardsK=SData2.getData("AllRankConfig")
        viewTab.titleTopPlayerExplain:setString(StringManager.getString("labTopPlayer"))
        viewTab.labelTopPlayerRankNum:setString(StringManager.getString("unionCupRank"))   --排名
        viewTab.labelTopPlayerDailyReward:setString(StringManager.getString("10_title"))   --顶级玩家榜每日奖励
        viewTab.labelTopPlayerWeeklyReward:setString(StringManager.getString("11_title"))  --顶级玩家榜赛季奖励
        --添加奖励 奖励范围在AllRankConfig[1] 奖励内容在AllRankRewards
        local infos={}
        for i=1,20 do
            table.insert(infos,{id=i,maxRank=rewardsK[1][i].maxrk,minRank=rewardsK[1][i].minrk,
                                numD=rewardsV[i].gnum,numW=rewardsV[i+40].gnum
                       })
        end
        self:addTableViewProperty("topPlayerTableView",infos,Script.createBasicHandler(self.topPlayCallCell,self))
        self:loadView("topPlayerTableView")
    elseif self.mode == 4 then
        self:loadView("knockOut_upViews")
        self:loadView("knockOut_downViews")
        local viewTab = self:getViewTab()

        local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
        local rewardsInfo = KnockMatchData:getOutRewardConfig()
        local infos = {}
        for i, v in ipairs(rewardsInfo) do
            local rank = v.rank
            local lv = KnockMatchData:getStatueLvByRank(rank)
            if not GameLogic.useTalentMatch then
                local _statue = {186, lv, 1}
                _statue.isStatue = true
                table.insert(v.rewards, 1, _statue)
            end
            table.insert(infos, {id=i, data = v})
        end
        viewTab.labelLookReward:setString(Localize("labKnockRewardTitle"))
        viewTab.lb_title:setString(Localize("labKnockRewardDes"))
        viewTab.labelRankNum:setString(StringManager.getString("labKnockRankDes"))
        viewTab.labelReward2:setString(StringManager.getString("labKnockRewardDes2"))
        self:addTableViewProperty("knockOutTableView",infos,Script.createBasicHandler(self.updateKnockOrewardCell,self))
        self:loadView("knockOutTableView")
    elseif self.mode==2 then
        self:initTestReward()
        self:loadView("test_upViews")
        self:loadView("test_downViews")
        local viewTab = self:getViewTab()
        viewTab.labelTestExplain2:setString(Localize("labelNotTestExplain2"))
        if self.prams.rank then
            viewTab.labelTestExplain2:setString(Localizef("labelTestExplain2",{a=self.prams.rank,b=self.testReward[1],c=self.testReward[2]}))
        end
    elseif self.mode==3 then
        -- self:initTestReward()
        local context = GameLogic.getUserContext()
        local actRank = context.activeData:getRankData()
        for j=1,#actRank do
            if actRank[j].actId == self.prams then
                local actData = actRank[j].actData
                local rwdLen = #actData.rwds
                local infos = {}
                local pages = actData.pages or actData.viewTemplates.pages
                for i=1,rwdLen do
                    infos[i] = {id=i}
                    local rwd = context.activeData:getConfigableRwds(self.prams,i)
                    infos[i].items = rwd.items
                    local mi = #pages
                    infos[i].key = pages[i > mi and mi or i].key
                    infos[i].a = rwd.conditions[1][2]
                    infos[i].b = rwd.conditions[1][3]
                end
                self:addTableViewProperty("actLimitTabViews",infos,Script.createBasicHandler(self.onUpdateCell,self))
                self:loadView("actLimitTabViews")
            end
        end
    end
end

function RewardDescription:onUpdateCell( cell, tableView, info )
    local bg = cell:getDrawNode()
    self:loadView("actLimitCellBack",bg)
    -- for i,v in KTIPairs(info.items) do
    --     GameUI.addItemIcon(bg,v[1],v[2],1,230*i-100,130,true,false,{itemNum=v[3]})
    -- end
    local viewTab = self:getViewTab()
    viewTab.labelInfo:setString(Localizef(info.key, {a=info.a, b=info.b}))

    self:addTableViewProperty("actLimitTabViewsitem",info.items,Script.createBasicHandler(self.onUpdateItemInner,self))
    self:loadView("actLimitTabViewsitem",bg)
    local itemView = self:getTableView("actLimitTabViewsitem")
    itemView.view:setTouchThrowProperty(true, true)
    itemView.view:setElastic(false)
end

function RewardDescription:onUpdateItemInner(cell, tableView, info)
    local view = cell:getDrawNode()
    view:removeAllChildren(true)

    local cellSize = cell:getContentSize()
    GameUI.addItemIcon(view,info[1],info[2],cellSize.height/230,cellSize.width/2,cellSize.height/2,true,false)
    local bNum=ui.label("X"..info[3], General.font1, math.ceil(36*cellSize.height/230), {color={255,255,255}})
    display.adapt(bNum, cellSize.width/2+90*cellSize.height/230, 40*cellSize.height/230, GConst.Anchor.Right)
    view:addChild(bNum)
    GameUI.registerTipsAction(cell, self, info[1], info[2])
end

function RewardDescription:initTestReward()
    local rewards=SData["testDescription"]
    local rank
    if self.prams and self.prams.rank then
        rank=self.prams.rank
    else
        return
    end
    for k,v in pairs(rewards) do
        local r=string.split(k,"~")
        if rank>=tonumber(r[1]) then
            if r[2]=="" then
                self.testReward=v
                return
            elseif rank<=tonumber(r[2]) then
                self.testReward=v
                return
            end
        end
    end
end

-- @brief: 英雄试炼排行榜奖励的单元cell
-- @author: aoyue 2017.12.12
function RewardDescription:heroTrailCallCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    if info.id%2==0 then
        self:loadView("heroTrailCellBack",bg)
    end
    self:loadView("heroTrailCellInfo",bg)
    local viewTab = self:getViewTab()

    if info.maxRank== info.minRank then
        viewTab.labelNumMin:setString(info.maxRank)
        viewTab.rankNumberBox2:setVisible(false)
        viewTab.labelNumMax:setVisible(false)
        viewTab.labLine:setVisible(false)
    else
        viewTab.labelNumMin:setString(info.minRank)
        viewTab.labelNumMax:setString(info.maxRank)
        viewTab.labLine:setString("-")

        viewTab.rankNumberBox1:setPositionX(208-100)
        viewTab.rankNumberBox2:setPositionX(208+100)
        viewTab.labelNumMin:setPositionX(208-100)
        viewTab.labelNumMax:setPositionX(208+100)
    end

    viewTab.labelDailyNum:setString(info.numD)
    viewTab.labelWeeklyNum:setString(info.numW)
end

-- @brief: 顶级玩家排行榜奖励的单元cell
-- @author: aoyue 2017.12.12
function RewardDescription:topPlayCallCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    if info.id%2==0 then
        self:loadView("topPlayerCellBack",bg)
    end
    self:loadView("topPlayerCellInfo",bg)
    local viewTab = self:getViewTab()

    if info.maxRank== info.minRank then
        viewTab.labelNumMin:setString(info.maxRank)
        viewTab.rankNumberBox2:setVisible(false)
        viewTab.labelNumMax:setVisible(false)
        viewTab.labLine:setVisible(false)
    else
        viewTab.labelNumMin:setString(info.minRank)
        viewTab.labelNumMax:setString(info.maxRank)
        viewTab.labLine:setString("-")

        viewTab.rankNumberBox1:setPositionX(208-100)
        viewTab.rankNumberBox2:setPositionX(208+100)
        viewTab.labelNumMin:setPositionX(208-100)
        viewTab.labelNumMax:setPositionX(208+100)
    end

    viewTab.labelDailyNum:setString(info.numD)
    viewTab.labelWeeklyNum:setString(info.numW)
end

function RewardDescription:callCell(cell, tableView, info)
    local data = info.data
    local bg = cell:getDrawNode()
    if info.id%2==0 then
        self:loadView("unionCupCellBack",bg)
    end
    self:loadView("unionCupCellInfo",bg)
    local viewTab = self:getViewTab()

    if data.maxRank== data.minRank then
        viewTab.labelNum1:setString(data.maxRank)
        viewTab.rankNumberBox2:setVisible(false)
        viewTab.labelNum2:setVisible(false)
        viewTab.labLine:setVisible(false)
    else
        viewTab.labelNum1:setString(data.maxRank)
        viewTab.labelNum2:setString(data.minRank)
        viewTab.labLine:setString("-")

        viewTab.rankNumberBox1:setPositionX(208-100)
        viewTab.rankNumberBox2:setPositionX(208+100)
        viewTab.labelNum1:setPositionX(208-100)
        viewTab.labelNum2:setPositionX(208+100)
    end

    viewTab.labelPBeadNum:setString(data.sarahNum)
    viewTab.labelBoxNum:setString(data.boxNum)
end

function RewardDescription:updateKnockOrewardCell(cell, tableView, info)
    local data = info.data
    local bg = cell:getDrawNode()
    local rank = data.rank
    local rewards = data.rewards or {}
    local len = #rewards
    if info.id %2 == 0 then
        self:loadView("KnockOutCellBack",bg)
    end
    self:loadView("KnockOutCellInfo", bg)
    local viewTab = self:getViewTab()
    local rankName = Localize("labKnockOutReward"..rank)
    viewTab.lb_rank:setString(rankName)

    local function _refreshReward(_cell, _tableView, _info)
        local _bg = _cell:getDrawNode()
        self:loadView("knockOutCellReward", _bg)
        local _viewTab = self:getViewTab()
        local type = _info[1]
        local id = _info[2]
        local num = _info[3]
        local isStatue = _info.isStatue
        if isStatue then
            local img_bg = ui.sprite("images/pvz/imgPvzStageIcon.png")
            display.adapt(img_bg, 74, 73, GConst.Anchor.Center)
            _viewTab.nd_icon:getDrawNode():addChild(img_bg)
            local bid = _info[1]
            local lv = _info[2]
            local newBuild = Build.new(type, lv)
            local vs = 5
            local hpAct = SData2.getData("bdatas")[50106][lv].hpRate.."%"
            newBuild:addBuildView(_viewTab.nd_icon:getDrawNode(), 74, 53, 80, 80, vs)
            local size = _viewTab.nd_icon:getContentSize()
            _viewTab.nd_icon:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self, _viewTab.nd_icon, size.width/2, size.height/2, Localizef("labKnockOutStatueTip", {a = hpAct})}))
            _viewTab.nd_icon:setTouchThrowProperty(true, true)
        else
            GameUI.addItemIcon(_viewTab.nd_icon:getDrawNode(), type, id, 148/200, 74, 74,true,false)
            local size = _viewTab.nd_icon:getContentSize()
            local tips = GameLogic.getItemDesc(type, id)
            _viewTab.nd_icon:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self, _viewTab.nd_icon, size.width/2, size.height/2, tips}))
            _viewTab.nd_icon:setTouchThrowProperty(true, true)
        end
        _viewTab.lb_num:setString(num)

    end
    self:addTableViewProperty("knockOutCellTableView",rewards,Script.createBasicHandler(_refreshReward))
    self:loadView("knockOutCellTableView", bg)

    local tab = self:getTableView("knockOutCellTableView")
    tab.view:setTouchThrowProperty(true, true)
    if len <= 3 then
        tab.view:setElastic(false)
    end

end

return RewardDescription
