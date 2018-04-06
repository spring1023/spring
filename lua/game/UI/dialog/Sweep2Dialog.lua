-- 僵尸来袭扫荡对话框
-- TODO 建议改成新json格式
local SD = GMethod.loadScript("data.StaticData").getData
local Sweep2Dialog = class2("Sweep2Dialog",function()
    return BaseView.new("Sweep2Dialog.json")
end)

-- @brief 扫荡对话框构造方法，自动弹出所以不要再调用display.showDialog
-- @params isMulti 是单次扫荡还是多次扫荡
-- @params pvjData 僵尸来袭逻辑模块的数据层
-- @params stageId 僵尸来袭的具体关卡
function Sweep2Dialog:ctor(isMulti, pvjData, stageId)
    self.isMulti, self.pvjData, self.stageId = isMulti, pvjData, stageId
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initBack()
    display.showDialog(self)
    -- 打开对话框时自动进行一次扫荡
    self:doSweep()
end

-- @brief 仅加载背景显示；
function Sweep2Dialog:initBack()
    self:loadView("backAndupViews")
end

-- @brief 重新加载含背景和奖励的显示
function Sweep2Dialog:initUI()
    self:removeAllChildren(true)
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog, self.dialogDepth))
    self:loadView("views")
    self:initSweepResult()

    --再次扫荡
    self:insertViewTo()
    self.butSetLineup:setScriptCallback(ButtonHandler(self.onSweepAgain, self))
    -- (function()
    --     local num = self:checkSweepNum(self.sweepNum)
    --     if num == 1 then
    --         self:cleanpvjbattle()
    --     elseif num == 0 then
    --         display.showDialog(AlertDialog.new(1, Localize("labelPrompt"), Localizef("labelCrystallSweep",{n = const.PvjSwpBuyNeed*self.sweepNum,m = self.sweepNum}),{cvalue = const.PvjSwpBuyNeed*self.sweepNum,ctype = 4,yesBut="btnYes",callback = function()
    --             self:cleanpvjbattle()
    --         end}))
    --     else
    --         display.closeDialog(self.dialogDepth)
    --     end
    -- end)
end

-- @brief 加载扫荡中的显示，但是好像基本看不到？
function Sweep2Dialog:initSweepResult()
	local bg=ui.node()
	display.adapt(bg,0,0, GConst.Anchor.LeftBottom)
    self:addChild(bg)
    self:loadView("waitSweep",bg)
    self.bg = bg
end

-- @brief 奖励节点
function Sweep2Dialog:callcell(cell, tableView, info)
	local bg = cell:getDrawNode()
    cell:setEnable(false)
    local temp
    local i=self.infoNum+1-info.id
    temp = ui.label(Localizef("labelSweepNumber",{n=i}), General.font1, 50, {color={255,168,0}})
	display.adapt(temp, 0, 236, GConst.Anchor.Left)
	bg:addChild(temp)

    local idx = 0
    for k,v in pairs(self.data) do
        local str
        if v[4] == i then
            idx = idx+1
            local itemNode = ui.node()
            display.adapt(itemNode,250*(idx-1),0, GConst.Anchor.LeftBottom)
            bg:addChild(itemNode)

            --GameUI.addItemIcon(itemNode,2,1,0,0,{scale=1.04})
            GameUI.addItemIcon(itemNode,v[1],v[2],1,100,100,true)

            temp = ui.label(StringManager.getString("x"..v[3]), General.font1, 40, {color={255,255,255}})
            display.adapt(temp, 197, 27, GConst.Anchor.Right)
            itemNode:addChild(temp)
        end
    end
end

-- @brief 展示扫荡结果
function Sweep2Dialog:showResult()
    self.bg:removeAllChildren(true)
    local infos={}
    for i=1,self.infoNum do
        infos[i]={id=i}
    end
    self:addTableViewProperty("sweepResultTableView",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("sweepResultTableView")

    local isBossStage, canSweep, costBase, leftChance, leftFree,
        baseChance, apChance = self.pvjData:computeBattleInfo(self.stageId)
    if not self.isMulti then
        leftChance = 1
    end
    if isBossStage and baseChance <= 0 or apChance <= 0 then
        self.btnSweepAgain:setString(Localize("btnYes"))
        self._displayClose = true
    elseif leftFree > 0 then
        self.btnSweepAgain:setString(Localizef("btnFreeSweepNum", {num = leftChance}))
    else
        self.btnSweepAgain:setString(Localizef("btnSweepNum", {num = leftChance}))
    end
end

-- @brief 点击再扫一次的地方
function Sweep2Dialog:onSweepAgain()
    if self._displayClose then
        display.closeDialog(self.priority)
        return
    end
    local isBossStage, canSweep, costBase, leftChance, leftFree,
        baseChance, apChance = self.pvjData:computeBattleInfo(self.stageId)
    if leftFree == 0 then
        if not self.isMulti then
            leftChance = 1
        end
        display.showDialog(AlertDialog.new(1, Localize("labelPrompt"),
            Localizef("labelCrystallSweep", {n = const.PvjSwpBuyNeed * leftChance, m = leftChance}),
            {cvalue = const.PvjSwpBuyNeed * leftChance, ctype = const.ResCrystal,
            yesBut="btnYes", callback = Handler(self.doSweep, self)}))
    else
        self:doSweep()
    end
end

-- @brief 进行实际扫荡的地方
function Sweep2Dialog:doSweep()
    local stageId = self.stageId
    local isBossStage, canSweep, costBase, leftChance, leftFree,
        baseChance, apChance = self.pvjData:computeBattleInfo(stageId)
    -- 初始化准备扫荡的地方
    self:initUI()
    if GameNetwork.lockRequest() then
        -- 发接口
        local realSweepChance = self.isMulti and leftChance or 1
        local pvjData = self.pvjData
        GameNetwork.request("cleanpvjbattle",{cleanpvjbattle = {stageId, realSweepChance}},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                --活动
                if data.crystal>0 then
                    GameLogic.getUserContext():changeProperty(const.ResCrystal, -data.crystal)
                else
                    GameLogic.getUserContext():changeProperty(const.ProPvjSwpNum, realSweepChance)
                end
                if isBossStage then
                    pvjData.quests[stageId][4] = pvjData.quests[stageId][4] + realSweepChance
                    pvjData.quests[stageId][6] = GameLogic.getSTime()
                end
                GameLogic.getUserContext():setProperty(const.ProPvjSwpTime, GameLogic.getSTime())
                pvjData.ctime = data.rftime
                pvjData.actnum = data.actnum
                GameLogic.addRewards(data.agl)
                GameLogic.statCrystalRewards("扫荡获得",data.agl)
                --活动
                local activeData = GameLogic.getUserContext().activeData
                activeData:finishAct(2, realSweepChance)
                GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVJ, realSweepChance)
                if self.showResult then
                    self.infoNum = realSweepChance
                    self.data = data.agl
                    self:showResult()
                end
            end
        end)
    end
end

return Sweep2Dialog
