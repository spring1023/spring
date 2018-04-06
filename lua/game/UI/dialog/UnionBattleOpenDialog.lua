--联盟战对话框
local UnionBattleOpenDialog = class2("UnionBattleOpenDialog",function()
    return BaseView.new("UnionBattleOpenDialog.json")
end)
function UnionBattleOpenDialog:ctor(data)
    self.data = data
    self.dialogDepth=display.getDialogPri()+1

    self.priority=self.dialogDepth

    display.showDialog(self)
    self:initBack()
    self:initData(data)
    self:initUI()
end

function UnionBattleOpenDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))
end

function UnionBattleOpenDialog:onQuestion()
    HelpDialog.new("dataQuestionUnBatOp")
end

function UnionBattleOpenDialog:initUI()
    if self.mainNode then
        self.mainNode:removeFromParent(true)
        self.mainNode = nil
    end
    self.mainNode = ui.node()
    self:addChild(self.mainNode)
	self:loadView("leftViews",self.mainNode)
    self:loadView("rightViews",self.mainNode)
    self:insertViewTo()
    self.label_boxLvValue:setString(Localize("label_baseRewardNum")..self.boxNum)
    if self.state==1 then
        self.butJoinBattle:setHValue(-79)
        self.btnUnionVSBiasRight:setString(Localize("labelQuitBattle"))
    else
        self.butJoinBattle:setHValue(0)
        self.btnUnionVSBiasRight:setString(Localize("btnUnionVSBiasRight"))
    end
    --参战
    self.butJoinBattle:setListener(function()
        if GameLogic.getUserContext().buildData:getMaxLevel(const.Town)>0 then
            UnionVSBias.new(function(t)
                self:setpvlstate(t,GameLogic.getUserContext().uid)
            end)
        else
            display.pushNotice(Localize("stringGoUnionWayLimit"))
        end
    end)
    if self.job<4 then
        self.butLayout:setGray(true)
    end
    --布阵
    self.butLayout:setListener(function()
        if self.job<4 then
            display.pushNotice(Localize("noticeLineup"))
        else
            UnionBattleLineupInterface.new({isTruce=true})
        end
    end)
    --奖励记录
    self.butRewardLog:setListener(function()
        UnionBattleAssignRewardsDialog.new()
    end)
    --对战日志
    self.butBattleLog:setListener(function()
        UnionBattleLogDialog.new()
    end)

    if self.atkPersonNum<10 then
        self.label_warScale:setString(Localize("labelGoWarNoEnough"))
    else
        self.label_warScale:setVisible(false)
    end
    self.labelTime:setVisible(false)
    if self.isStopBattle then
        self.label_warScale:setString(Localize("stringUnionBattleTime"))
        self.labelTime:setVisible(true)
        local t=GameLogic.getUnionBattleTime()[2] - GameLogic.getSTime()
        self.labelTime:setString(Localizet(t))
        self.butJoinBattle:setVisible(false)
        self.butLayout:setVisible(false)
    end

    local infos={}
    for i,v in ipairs(self.unionInfos) do
        table.insert(infos,{data=v})
    end
    self:addTableViewProperty("infoTableView",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("infoTableView",self.mainNode)
end

function UnionBattleOpenDialog:callcell(cell, tableView, info)
	local bg = cell:getDrawNode()
    cell:setEnable(false)
	self:loadView("infoJoinBattleViews",bg)
    if self.job >= 4 then
        self:loadView("infoViews1",bg)
    else
        self:loadView("infoViews",bg)
    end
    self:insertViewTo(info)
    local data = info.data
    local head = GameUI.addPlayHead(bg,{id=data.headid,scale=0.9,x=100,y=103,z=0,blackBack=true})
    head:setTouchThrowProperty(true, true)
    info.name:setString("lv:"..data.lv.."  "..data.name)
    GameUI.addVip(bg,data.vip,580,110,1)
    info.labJob:setString(Localize("labelCellJob" .. data.job))
    info.labBattlePower:setString(Localize("propertyComb")..data.battlePower)
    info.labContribution:setString(Localize("labelContribution")..data.contribution)
    if data.state==1 then
        if self.job < 4 then
            ui.setColor(info.labState, 31, 255, 10)
        end
        if info.btnjobState then
            info.btnjobState:setHValue(0)
        end
        info.labState:setString(Localize("btnUnionBattleing"))
    else
        if self.job < 4 then
            ui.setColor(info.labState, "red")
        end
        if info.btnjobState then
            info.btnjobState:setHValue(-78)
        end
        info.labState:setString(Localize("btnUnionBattleing2"))
    end
    if data.uid==GameLogic.getUserContext().uid then
        self.labelState = info.labState
        if info.btnjobState then
            self.buttonState = info.btnjobState
        end
    end
    if info.btnjobState then
        info.btnjobState:setListener(function()
            if data.state==1 then
                data.state = 0
                info.labState:setString(Localize("btnUnionBattleing2"))
                info.btnjobState:setHValue(-78)
                self:setpvlstate(0,data.uid)
            else
                data.state = 1
                info.labState:setString(Localize("btnUnionBattleing"))
                info.btnjobState:setHValue(0)
                self:setpvlstate(1,data.uid)
            end
        end)
    end
end

function UnionBattleOpenDialog:setpvlstate(t,uid)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("setpvlstate",{setpvlstate={t,uid}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if data.code==0 then
            print("设置成功")

            if not self.deleted and uid == GameLogic.getUserContext().uid then
                self.state = t
                if t==1 then
                    if self.butJoinBattle then 
                        self.butJoinBattle:setHValue(-79)
                    end
                    if self.buttonState then
                        self.buttonState:setHValue(0)
                    end
                    if self.btnUnionVSBiasRight then
                        self.btnUnionVSBiasRight:setString(Localize("labelQuitBattle"))
                    end
                    if self.labelState then
                        if self.job < 4 then
                            ui.setColor(self.labelState, 31, 255, 10)
                        end
                        self.labelState:setString(Localize("btnUnionBattleing"))
                    end
                else
                    if self.butJoinBattle then 
                        self.butJoinBattle:setHValue(0)
                    end
                    if self.buttonState then
                        self.buttonState:setHValue(-79)
                    end
                    if self.btnUnionVSBiasRight then
                        self.btnUnionVSBiasRight:setString(Localize("btnUnionVSBiasRight"))
                    end
                    if self.labelState then
                        if self.job < 4 then
                            ui.setColor(self.labelState, "red")
                        end
                        self.labelState:setString(Localize("btnUnionBattleing2"))
                    end
                end
            end
        end
    end)
end

function UnionBattleOpenDialog:initData(data)
   self.unionInfos={}
   --宝箱数
   self.isStopBattle = data.isStopBattle
   self.boxNum=data.boxes or 0
   self.atkPersonNum = 0
   if data.plays then
        for i,v in ipairs(data.plays) do
            local info={uid=v[11],headid=v[1],lv=v[2],name=v[3],job=v[5],vip=v[4],battlePower=v[6],contribution=v[7],state=v[14],jionTime=v[15]}
            table.insert(self.unionInfos,info)
            if info.uid==GameLogic.getUserContext().uid then
                self.job=info.job
                self.state = info.state
                self.jionTime = info.jionTime
            end
            if info.state==1 then
                self.atkPersonNum = self.atkPersonNum+1
            end
        end
   end
end

return UnionBattleOpenDialog



