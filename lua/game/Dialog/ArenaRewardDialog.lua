ArenaRewardDialog = class(DialogViewLayout)

local AStageListTab = class(DialogTabLayout)

function AStageListTab:create()
    self:setLayout("ArenaStageList.json")
    self:loadViewsTo()
    local infos = self:getContext().arena:getAllStages()
    local ts = self.nodeStageTable:getSetting("tableSetting")
    local size = self.nodeStageTable.size
    local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=infos, cellUpdate=Handler(self.updateRewardCell, self)})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
    self.nodeStageTable.view:addChild(tableView.view)
    self.infos = infos
    self.tableView = tableView
    local ti = #infos
    for i,info in ipairs(infos) do
        if info.state==2 then
            ti = i-1
            break
        end
    end
    local y = ts.oy+(ts.sy+ts.dy)*(ti-1)+ts.sy/2
    tableView:refreshItem(-1, 0, y+size[2])
    tableView.view:moveAndScaleToCenter(1, size[1]/2, size[2]-y,0.1)
    return self.view
end

function AStageListTab:updateRewardCell(cell, tableView, info)
    if not info.viewLayout then
        info.viewLayout = self:addLayout("arenaRewardCell",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        if info.reward.gtype==10 then
            info.icon = GameUI.addResourceIcon(info.nodeRewardContent.view, info.reward.gid, 1, 50, 50)
        else
            info.icon = GameUI.addHeadIcon(info.nodeRewardContent.view,info.reward.gid,0.5,50,50)
        end
        info.btnReward:setScriptCallback(ButtonHandler(self.onGetReward, self, info))
        info.imgBack = info.imgBack.view
        info.cell = cell
    end
    info.labelStageName:setString(Localize("dataArenaStageName" .. info.id))
    info.labelNeedScoreNum:setString(N2S(info.reward.score))
    info.labelRewardNum:setString(N2S(info.reward.gnum))
    if info.state==2 then
        ui.setColor(info.imgBack,255,243,215)
        info.btnReward:setVisible(false)
        if not info.labelRewardGot then
            info.labelRewardGot = GameUI.addHaveGet(info.cell:getDrawNode(),Localize("labelAlreadyReceive"),1,1635,153,2)
        end
        info.labelRewardGot:setVisible(true)
    else
        info.icon:setSValue(0)
        if info.state==1 then
            ui.setColor(info.imgBack,138,199,196)
            info.btnReward:setVisible(true)
        else
            info.icon:setSValue(-100)
            ui.setColor(info.imgBack,171,171,171)
            info.btnReward:setVisible(false)
        end
        if info.labelRewardGot then
            info.labelRewardGot:setVisible(false)
        end
    end
end

function AStageListTab:onGetReward(info)
    if GameNetwork.lockRequest() then
        GameNetwork.request("pvcreward",nil,self.onResponseGetReward,self)
    end
end

function AStageListTab:onResponseGetReward(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        GameLogic.addRewards(data.agls)
        GameLogic.statCrystalRewards("竞技场段位奖励",data.agls)
        local arena = self:getContext().arena
        arena.stage = arena.stage+1
        if not self:getDialog().deleted then
            for i,info in ipairs(self.infos) do
                if info.state==1 then
                    info.state = 2
                    self:updateRewardCell(nil, self.tableView, info)
                    local info2 = self.infos[i-1]
                    if info2 and info2.reward.score<=arena:getCurrentScore() then
                        info2.state = 1
                        self:updateRewardCell(nil, self.tableView, info2)
                    end
                    break
                end
            end
        end
    end
end

local MyStageTab = class(DialogTabLayout)

function MyStageTab:create()
    self:setLayout("ArenaMyStage.json")
    self:loadViewsTo()
    local arena = self:getContext().arena
    local lv = arena:computeLevelByScore()
    local set = {{1,6},{7,12},{13,18},{19,25}}
    local color
    for i,v in ipairs(set) do
        if v[1]<=lv and lv<=v[2] then
            color = i
            break
        end
    end
    self.labelCurrentAStage:setString(arena:getStageName())
    GameUI.setHeroNameColor(self.labelCurrentAStage, color)
    ui.setFrame(self.stageBack.view, "images/arenaStrip" .. color .. ".png")
    self.labelWinNum:setString(N2S(arena:getTotalWin()))
    self.labelLoseNum:setString(N2S(arena:getTotalLose()))
    self.labelCurrentAScore:setString(N2S(arena:getCurrentScore()))
    self.gradeProcess:setProcess(true, arena:getScoreProgress())
    local nscore = arena:getNextScore()
    if nscore == 0 then
        self.labelUpgradeLeft:setString(Localize("labelLevelMax"))
        self.labelUpgradeLeftNum:setString("")
    else
        self.labelUpgradeLeft:setString(Localize("labelUpgradeLeft"))
        self.labelUpgradeLeftNum:setString(N2S(nscore-arena:getCurrentScore()))
    end
    return self.view
end

function ArenaRewardDialog:onInitDialog()
    self:setLayout("ArenaRewardDialog.json")
    self:loadViewsTo()

    self.title:setString(Localize("labelAStageReward"))
    self.questionBut:setVisible(false)
    self.backBut:setVisible(true)
    self.backBut:setScriptCallback(ButtonHandler(self.onBack, self))
    local tab = DialogTemplates.createTabView(self.nodeRewardTab.view, {Localize("tabAStageList"), Localize("tabMyStage")}, {AStageListTab.new(self), MyStageTab.new(self)}, self.nodeRewardTab:getSetting("tabSetting"), {viewBg=self.view})
    tab:changeTab(self.initIdx or 1)
    self.tab = tab
end

function ArenaRewardDialog:onBack()
    display.closeDialog(0)
    display.showDialog(ArenaDialog.new({parent=self.parent, context=self.context}))
end
