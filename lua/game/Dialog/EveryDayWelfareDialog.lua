-- Module ID：coz2_4
-- Depiction：每日福利任务
-- Author：XiaoGangMu
-- Create Date：2017-2-18
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

EveryDayWelfareDialog = class(DialogViewLayout)

function EveryDayWelfareDialog:onInitDialog()
    -- self.datas = GameLogic.getUserContext():getProperty(ProDTVersion)
    -- ActiveData:loadWelfare(self.datas)
    self:setLayout("EveryDayWelfareDialog.json")
    self:loadViewsTo()
    self.dialogDepth=display.getDialogPri()+1
    self.labeltitle:setString(Localize("welfareTask"))  --每日福利任务
    self.lbReceivedView = GameUI.addHaveGet(self.view,Localize("labelAlreadyReceive"),1,self.btnReward.view:getPositionX(),self.btnReward.view:getPositionY())
    self.lbReceivedView:setVisible(false)
    self.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))
    self.btnReward:setScriptCallback(Script.createCallbackHandler(self.rewardFunc,self))

    display.showDialog(self)
end
function EveryDayWelfareDialog:onEnter()
    self.context.activeData:refreshWelfare()
    local dt = self.context.activeData.dailyWelfare or {1, const.DTDayMax, 0,0,0, GameLogic.getSTime(), GameLogic.getSTime()}
    local allRwds = SData.getData("dailytask", dt[1])
    ---------------------------------------------
    local infos={}
    for i=1, KTLen(allRwds) do
        infos[i] = {id=i, isGot=false}
        infos[i].awardInfo = allRwds[i]
        if i < dt[2] or (i==dt[2] and dt[7]>=dt[6]) then
            infos[i].isGot = true
        end
    end
    self.tableview:removeAllChildren(true)
    self.tableview:loadTableView(infos, Handler(self.onUpdateCell, self))
    self.cellitem = infos
    --右边的显示
    self:initRightView()
end

function EveryDayWelfareDialog:onQuestion()
    HelpDialog.new("dataQuestionDailyTask")
end

function EveryDayWelfareDialog:onUpdateCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    self:addItem(bg,97,94,0,3,info)
end

function EveryDayWelfareDialog:initRightView()
    -- receivedays=8,今天就是第九天的奖励
    -- local item = self.datas[receivedays+1]
    local dt = self.context.activeData.dailyWelfare or {1, const.DTDayMax, 0,0,0, GameLogic.getSTime(), GameLogic.getSTime()}
    local award = SData.getData("dailytask", dt[1], dt[2])
    if dt[3] == 0 then
        dt[3] = award.conditionId
        dt[4] = award.count
        dt[5] = award.count
    end
    if dt[7] >= dt[6] then
        --已领取
        self.btnReward:setVisible(false)
        self.lbReceivedView:setVisible(true)
    else
        self.btnReward:setVisible(true)
        self.lbReceivedView:setVisible(false)
        self.btnReward:setGray(false)
        if dt[5] < dt[4] and GameLogic.checkConditionCanGo(dt[3]) then
            --去完成
            self.btnReward.view:setHValue(114)
            self.btnName:setString(Localize("buttonGo"))
        else
            self.btnReward.view:setHValue(0)
            --领取当日奖励
            self.btnName:setString(Localize("btnArenaReward"))
            if dt[5] < dt[4] then
                self.btnReward:setGray(true)
            end
        end
    end
    self.awardNum:setString("X" .. award.rwds[1][3])
    -- need 任务需要的完成次数，已经完成的次数
    self.taskInfo:setString(Localizef("labelActFormat" ..tostring(dt[3]) , {a=dt[5]>dt[4] and dt[4] or dt[5], b=dt[4]}))
    if self.awardIcon then
        self.awardIcon:removeFromParent(true)
        self.awardIcon = nil
    end
    self.awardIcon = GameUI.addItemIcon(self.view, award.rwds[1][1], award.rwds[1][2], 2, 1549+221,440+461, false)
end

--[[
    @bg                父节点
    @type             奖励类型
    @id             奖励ID
    @x,y,z            cell的位置
    @mode            奖励的描边
    @table            奖励的信息
]]
function EveryDayWelfareDialog:addItem( bg,x,y,z,mode,info)
    --info
    --[[
        id 天数
        isGot 是否已获取
        awardInfo 奖励配置
    ]]
    local awardInfo = info.awardInfo
    if not info.view then
        info.view = bg
        local temp = ui.sprite("images/everydayrwbg.png")
        display.adapt(temp, x, y, GConst.Anchor.Center)
        bg:addChild(temp,z)

        GameUI.addItemIcon(bg, awardInfo.rwds[1][1], awardInfo.rwds[1][2], 150/200,75+22,75+19,false)
        -- GameUI.addResourceIcon(temp, awardInfo.rwds[1][2], 1, temp:getContentSize().width/2,temp:getContentSize().height/2,1,3)
        
        local dayslab = ui.label(tostring(info.id)..Localize("tmDay"), General.font2, 28, {color={0,0,0}})
        display.adapt(dayslab,20,temp:getContentSize().height-30,GConst.Anchor.Left)
        bg:addChild(dayslab,2)

        local templab = ui.label(tostring(awardInfo.rwds[1][3]), General.font1, 38, {color={255,255,255}})
        display.adapt(templab,temp:getContentSize().width-30,40,GConst.Anchor.Right)
        bg:addChild(templab,2)
        if info.isGot then
            local received = ui.sprite("images/signRedCircle.png")
            display.adapt(received,temp:getContentSize().width/2,temp:getContentSize().height/2, GConst.Anchor.Center)
            bg:addChild(received)
        end
    end
end

function EveryDayWelfareDialog:rewardFunc()
    local dt = self.context.activeData.dailyWelfare
    if dt[7] >= dt[6] then
        return
    end
    if dt[5] < dt[4] then
        GameLogic.doCondition(self.context, dt[3])
    else
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("dailyrwds", {rtime=GameLogic.getSTime()}, self.onReceivedRwd, self)
    end
end

function EveryDayWelfareDialog:onReceivedRwd(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        if data.rwds then
            GameLogic.addRewards(data.rwds)
            GameLogic.showGet(data.rwds)
        end
        local mydt = self.context.activeData.dailyWelfare[2]
        self.context.activeData:finishWelfare()
        GameEvent.sendEvent("refreshTaskRedNum")
        if not self.deleted then
            if self.context.activeData.dailyWelfare and self.context.activeData.dailyWelfare[2] == 1 then
                self:onEnter()
            else
                local item = self.cellitem[mydt]
                local received = ui.sprite("images/signRedCircle.png")
                display.adapt(received, item.view:getContentSize().width/2,item.view:getContentSize().height/2, GConst.Anchor.Center)
                item.view:addChild(received)
                received:setScale(2)
                received:runAction(ui.action.sequence({{"delay",0/60},{"scaleTo",30/60,1,1}}))
                self:initRightView()
            end
        end
    end
end
