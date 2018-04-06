--分配奖励对话框
local UnionBattleAssignRewardsDialog = class2("UnionBattleAssignRewardsDialog",function()
    return BaseView.new("UnionBattleAssignRewardsDialog.json")
end)
function UnionBattleAssignRewardsDialog:ctor(isLog)
    self.isLog =isLog
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initBack()
    self:getRewardsLogData()

    display.showDialog(self)
end

function UnionBattleAssignRewardsDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.title:setString("")
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
end

function UnionBattleAssignRewardsDialog:onQuestion()
    HelpDialog.new("dataQuestionUnionInfo")
end

function UnionBattleAssignRewardsDialog:initUI()
	self:loadView("topViews")
    self:insertViewTo()
    self.label_baseRewardNum:setString(Localize("label_baseRewardNum")..self.logBoxNum)
    
    local isLog=self.isLog
    local function changeViews()
            isLog = not isLog
            if isLog then
                self.nodeLog:setVisible(true)
                self.nodeAssign:setVisible(false)
                self.title:setString(Localize("btnRewardLog"))
                self.btnAssignReward:setString(Localize("btnAssignReward"))
                self.stringAssign:setVisible(false)
            else
                self.nodeLog:setVisible(false)
                self.nodeAssign:setVisible(true)
                self.title:setString(Localize("btnAssignReward"))
                self.btnAssignReward:setString(Localize("btnRewardLog"))
                self.stringAssign:setVisible(true)
            end
    end
    self:initLog()
    self:initAssign()
    self.butAssignReward:setScriptCallback(Script.createCallbackHandler(changeViews))
    changeViews()
    if GameLogic.getUserContext().union and GameLogic.getUserContext().union.job==5 then
        self.butAssignReward:setVisible(true)
    else
        self.butAssignReward:setVisible(false)
    end
end

--记录
function UnionBattleAssignRewardsDialog:initLog()
    local bg = ui.node()
    self:addChild(bg)
    self.nodeLog = bg
    local infos ={}
    for i,v in ipairs(self.rewardsLog) do
        table.insert(infos,{data=v})
    end
    self:addTableViewProperty("infoTableView",infos,Script.createBasicHandler(self.callcellLog,self))
    self:loadView("infoTableView",bg)
end

function UnionBattleAssignRewardsDialog:callcellLog(cell, tableView, info)
    local data = info.data
	local bg = cell:getDrawNode()
    cell:setEnable(false)
    self:loadView("infoViews",bg)
    self:insertViewTo()
    local head = GameUI.addPlayHead(bg,{id=data.headid,scale=0.8,x=100,y=90,z=0,blackBack=true})
    head:setTouchThrowProperty(true, true)
    self.name:setString("lv:"..data.lv.."  "..data.name)
    self.job:setString(Localize("labelCellJob" .. data.job))
    if data.job<=0 then
        self.job:setVisible(false)
    end
    self.labValue:setString(Localize("labelContribution")..data.contribute)
    self.labBoxnNum:setString("X"..data.box)
    self.labTime:setString(GameLogic.getTimeFormat3(data.time))
end

--分配
function UnionBattleAssignRewardsDialog:initAssign()
    local bg = ui.node()
    self:addChild(bg)
    self.nodeAssign = bg

    self:loadView("assignBottomViews",bg)
    self:insertViewTo()
    local function getAssign(way)
        local tab = {}
        if way==1 then
            tab =self.assign1
        elseif way==2 then
            tab =self.assign2
        elseif way==3 then
            tab =self.assign3
        end
        for k,v in pairs(self.boxRewards) do
            self.boxRewards[k]=0
        end
        for k,v in pairs(tab) do
            self.boxRewards[k]=v
        end
        self:refreshBoxViews()
    end
    self.butAssignWay1:setScriptCallback(Script.createCallbackHandler(getAssign,1))
    self.butAssignWay2:setScriptCallback(Script.createCallbackHandler(getAssign,2))
    self.butAssignWay3:setScriptCallback(Script.createCallbackHandler(getAssign,3))
    self.butAssignSure:setScriptCallback(Script.createCallbackHandler(self.sureAssign,self))

    self.boxViews={}
    local infos ={}
    for i,v in ipairs(self.assignData) do
        table.insert(infos,{data=v})
    end
    self:addTableViewProperty("assignTableView",infos,Script.createBasicHandler(self.callcellAssign,self))
    self:loadView("assignTableView",bg)
end

function UnionBattleAssignRewardsDialog:refreshBoxViews()
    for k,v in pairs(self.boxViews) do
        local num = self.boxRewards[k] or 0
        v:setString(num)
    end
end

function UnionBattleAssignRewardsDialog:callcellAssign(cell, tableView, info)
    local data = info.data

    local bg = cell:getDrawNode()
    cell:setEnable(false)
    self:loadView("assignViews",bg)
    self:insertViewTo()
    GameUI.addPlayHead(bg,{id=data.headid,scale=0.8,x=100,y=90,z=0,blackBack=true})

    self.name:setString("lv:"..data.lv.."  "..data.name)
    self.job:setString(Localize("labelCellJob" .. data.job))
    if data.job<=0 then
        self.job:setVisible(false)
    end
    self.labValue:setString(Localize("labelContribution")..data.contribute)
    self.boxNum:setString(self.boxRewards[data.uid] or 0)
    self.boxViews[data.uid]=self.boxNum

    local function changeBox(num)
        local oldBox = self.boxRewards[data.uid]
        self.boxRewards[data.uid] =self.boxRewards[data.uid]+num
        if num<0 then
            if self.boxRewards[data.uid]<0 then
                self.boxRewards[data.uid] =0
            end
        end
        if num>0 then
            local allBoxNum = 0
            for k,v in pairs(self.boxRewards) do
                allBoxNum = allBoxNum + v
            end
            if allBoxNum>self.logBoxNum then
                self.boxRewards[data.uid] = oldBox
            end
        end
        self.boxViews[data.uid]:setString(self.boxRewards[data.uid])
    end
    self.butReduce:setScriptCallback(Script.createCallbackHandler(changeBox,-1))
    self.butAdd:setScriptCallback(Script.createCallbackHandler(changeBox,1))
    self.butAdd:setAutoHoldTime(0.5)
    self.butAdd:setAutoHoldTimeTemp(0.1)
    self.butReduce:setAutoHoldTime(0.5)
    self.butReduce:setAutoHoldTimeTemp(0.1)
end

function UnionBattleAssignRewardsDialog:initData(data)
    --奖励记录
    self.logBoxNum=data.box
    self.rewardsLog={}
    if data.sharebox then
        --用户Id，头像，等级，名字，vip等级，联盟职位(0不显示)，联盟贡献，分配的宝箱数，分配时间
        for i,v in ipairs(data.sharebox) do
            table.insert(self.rewardsLog,{uid=v[1],headid=v[2],lv=v[3],name=v[4],vip=v[5],job=v[6],contribute=v[7],box=v[8],time=v[9]})
        end
        table.sort(self.rewardsLog,function (a,b)
            return a.time>b.time
        end)
    end
    self.assignData={}
    --存放玩家获得宝箱数
    self.boxRewards={}
    self.allContribute = 0
    if data.plays then
        for i,v in ipairs(data.plays) do
            local info = {box=0,uid=v[11],headid=v[1],lv=v[2],name=v[3],vip=v[4],job=v[5],contribute=v[7]}
            table.insert(self.assignData,info)
            self.allContribute = self.allContribute+v[7]
            self.boxRewards[info.uid] = 0
        end
        table.sort(self.assignData,function (a,b)
           return a.contribute>b.contribute
        end)
        self:assign()
    end

    if self.initUI then
        self:initUI()
    end
end

function UnionBattleAssignRewardsDialog:getRewardsLogData()
    if not GameLogic.getUserContext().union then
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("getShareClanBox", {lid=GameLogic.getUserContext().union.id},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if self.initData then
                self:initData(data)
            end
        end
    end)
end

function UnionBattleAssignRewardsDialog:sureAssign()
    local ushare ={}
    for k,v in pairs(self.boxRewards) do
        if v>0 then
            table.insert(ushare,{k,v})
        end
    end
    if #ushare==0 then
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("shareClanBox", {ushare=ushare},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==0 then
                display.pushNotice(Localize("noticeAssign0"))
                GameLogic.getUserContext().logData:getEmailDatas()
                if self.refreshBoxViews then
                    for k,v in pairs(self.boxRewards) do
                        self.logBoxNum = self.logBoxNum -v
                        self.boxRewards[k] = 0
                    end
                    if self.label_baseRewardNumValue then
                        self.label_baseRewardNumValue:setString(self.logBoxNum)
                    end
                    self:assign()
                    self:refreshBoxViews()
                end
            elseif data.code==1 then
                display.pushNotice(Localize("noticeAssign1"))
            elseif data.code==2 then
                display.pushNotice(Localize("noticeAssign2"))
            end
        end
    end)
end

--分配奖励
function UnionBattleAssignRewardsDialog:assign()
    local allBoxNum = self.logBoxNum
    local personNum = #self.assignData
    --默认分配
    self.assign1={}
    local num=math.floor(allBoxNum/personNum)
    local surplusNum=allBoxNum%personNum
    for i,v in ipairs(self.assignData) do
        self.assign1[v.uid]=num
        if i<=surplusNum then
            self.assign1[v.uid]=self.assign1[v.uid]+1
        end
    end
    --贡献分配
    self.assign2={}
    local aNum2 = allBoxNum
    for i,v in ipairs(self.assignData) do
        if self.allContribute<=0 or aNum2<=0 then
            break
        else
            local num2=math.ceil(v.contribute/self.allContribute*allBoxNum)
            if aNum2 < num2 then
                num2 = aNum2
                aNum2 =0
            else
                aNum2 = aNum2 -num2
            end
            self.assign2[v.uid]=(self.assign2[v.uid] or 0)+num2
        end
    end
    --职位分配
    self.assign3={}
    local aNum3 = allBoxNum
    local jb={4,2,1}
    while aNum3>0 do
        for i,v in ipairs(self.assignData) do
            local num3 = 0
            if v.job==5 then
                num3=jb[1]
            elseif v.job==4 then
                num3=jb[2]
            elseif v.job==3 then
                num3=jb[3]
            end
            if aNum3<num3 then
                num3 =aNum3
                aNum3 = 0
            else
                aNum3 = aNum3-num3
            end
            if num3>0 then
                self.assign3[v.uid]=(self.assign3[v.uid] or 0)+num3
            end
        end
    end
end

return UnionBattleAssignRewardsDialog



