local SData = GMethod.loadScript("data.StaticData")
--联盟战斗日志对话框
local UnionBattleLogDialog = class2("UnionBattleLogDialog",function()
    return BaseView.new("UnionBattleLogDialog.json")
end)
function UnionBattleLogDialog:ctor(idx)
    self.idx = idx or 1
    self.dialogDepth=display.getDialogPri()+1

    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self.priority=self.dialogDepth

    self:initUI()

    self:getPvlHistroy()

    display.showDialog(self)
end

function UnionBattleLogDialog:initUI()
    self:addTabView({Localize("titleUnionLog1"),Localize("titleUnionLog2"),Localize("titleUnionLog3")}, {543,149,480,1370,156,"images/dialogTabBack3_",55,271,69,1540,57,43,1324})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.historyBattleShow,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.mScoreShow,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.eScoreShow,self)})
    
end

function UnionBattleLogDialog:historyBattleShow(tab)
    local bg = ui.node()
    local infos={}
    for i,v in ipairs(self.logData) do
        table.insert(infos,{i = i,data=v})
    end
    if #infos<1 then
        self:loadView("notUnionWayLogView",bg)
    else
        self.infosData = infos
        self:addTableViewProperty("logTableview",infos,Script.createBasicHandler(self.callLogCell,self))
        self:loadView("logTableview",bg)
    end
    return bg
end

function UnionBattleLogDialog:mScoreShow(tab)
    local bg = ui.node()
    local infos={}
    for i,v in ipairs(self.mScoreData) do
        table.insert(infos,{idx=i,data=v})
    end
    if #infos<1 then
        self:loadView("notUnionWayLogView",bg)
    else
        self:addTableViewProperty("scoreTableview",infos,Script.createBasicHandler(self.scoreCallCell,self))
        self:loadView("scoreTableview",bg)
    end
    return bg
end

function UnionBattleLogDialog:eScoreShow(tab)
    local bg = ui.node()
    local infos={}
    for i,v in ipairs(self.eScoreData) do
        table.insert(infos,{idx=i,data=v})
    end
    if #infos<1 then
        self:loadView("notUnionWayLogView",bg)
    else
        self:addTableViewProperty("scoreTableview",infos,Script.createBasicHandler(self.scoreCallCell,self))
        self:loadView("scoreTableview",bg)
    end
    return bg
end

function UnionBattleLogDialog:callLogCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    local data = info.data
    local datai = info.i
    --赢为灰色背景，输为红色
    if data.isWin==1 then
        self:loadView("infoViewsGrayBack",bg)
    else
        self:loadView("infoViewsRedBack",bg)
    end
    self:loadView("logInfoViews",bg)
    self:insertViewTo()
    --时间
    self.label_timeAgo:setString(GameLogic.getTimeFormat3(data.time-86400))
    --金杯数
    self.trophyNum:setString(data.unionScore)
    --我方联盟名字
    self.leagueNameMy:setString(data.unionName1)
    --我方得分
    self.scoreMy:setString(data.getScore1)
    --敌方联盟名字
    self.leagueNameHe:setString(data.unionName2)
    self.scoreHe:setString(data.getScore2)
    if data.isReceive==1 then
        --self.butReward:setGray(true)
        --self.butReward:setEnable(false)
        --self.butReward:setVisible(false)
        self.btnGetReward:setString(Localize("btnDetails"))
    elseif data.isReceive==2 then
        self.butReward:setVisible(false)
    end
    info.butReward = self.butReward
    info.labReward = self.btnGetReward
    --领取奖励
    self.butReward:setListener(function()
        --self:getPvlReward(info)
        ReceiveUnionRewardDialog.new({isReceive = data.isReceive,bid=data.bid,callback=function ()
            data.isReceive=1
            info.butReward:setVisible(false)
        end})
    end)

    --我方图标
    local temp = GameUI.addUnionFlag(data.uFlag1)
    bg:addChild(temp)
    temp:setScale(0.46)
    temp:setPosition(813+55,302)
    --敌方图标
    temp = GameUI.addUnionFlag(data.uFlag2)
    bg:addChild(temp)
    temp:setScale(0.46)
    temp:setPosition(995+55,302)
    self.labRanking:setString(data.rank)
    local liftNum=0
    if data.rank>0 then
        local info = self:getBattleRewardInfo(data.rank)
        if info then
            self.labelPBeadNum:setString("X"..info.sarahNum)
            self.labelBoxNum:setString("X"..info.boxNum)
        else
            self.rewardsContNode:setVisible(false)
        end
        self.labRewardsCont2:setVisible(false)        
        if #self.infosData~=datai then
            liftNum = self.infosData[datai+1].data.rank - data.rank
        end
    else
        self.labRanking:setString("-")
        self.rewardsContNode:setVisible(false)
        self.labRewardsCont2:setVisible(true)
    end

    if liftNum>=999 then 
        liftNum=999 
    elseif liftNum<=-999 then 
        liftNum=-999 
    end
    self.labLiftNum:setString(math.abs(liftNum))--排名升降值

    if liftNum>0 then--上升，已默认

    elseif liftNum==0 then--持平
        ui.setFrame(self.imaRanking, "images/rankFlat.png")
        self.labLiftNum:setVisible(false)
    elseif liftNum<0 then --下降
        ui.setFrame(self.imaRanking, "images/rankDecline.png")
        self.labLiftNum:setColor(cc.c3b(249,64,64))
    end 
end

function UnionBattleLogDialog:getBattleRewardInfo(rank)
   if rank<=0 then
        return
   end
   local unionBattleRewards = SData.getData("unionBattleRewards")
   for i,v in ipairs(unionBattleRewards) do
        if rank>=v.maxRank and rank<=v.minRank then
            return v
        end
   end
end

function UnionBattleLogDialog:scoreCallCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    local data = info.data
    self:loadView("scoreInfoViews",bg)
    self:insertViewTo()
    self.rank:setString(info.idx)
    local head=GameUI.addPlayHead(bg,{id=data.headid,scale=0.85,x=240,y=80,z=0,blackBack=true})
    head:setTouchThrowProperty(true, true)
    self.name:setString("lv:"..data.lv.."  "..data.name)
    self.job:setString(Localize("labelCellJob" .. data.job))
    self.score:setString(data.score)
    self.atkNum:setString((data.atkMaxNum-data.atkNum).."/"..data.atkMaxNum)
    --详细战报
    self.butDetailLog:setListener(function()
        UnionBattleDetailLogDialog.new({bid=data.bid,tid=data.uid,atk=data.atk})
    end)
end

function UnionBattleLogDialog:initData(data)
    local logData,scoreMyData,scoreEData = data.his,data.atks,data.defs
    if logData then
        --历史联盟战记录
        self.logData = {}
        for i,v in ipairs(logData.hislist) do
            local isWin=(v[8]>=v[12]) and 1 or 0
            local isReceive = 2--2表示过期
            if logData.rwdlist[tostring(v[1])] then
                isReceive = logData.rwdlist[tostring(v[1])]
            end
            table.insert(self.logData,{bid=v[1],isReceive=isReceive,rank=v[3],time=v[4],isWin=isWin,unionScore=v[2],unionName1=v[6],unionName2=v[10],getScore1=v[8],getScore2=v[12],uFlag1=v[7],uFlag2=v[11]})
        end
        table.sort(self.logData,function(a,b)
            return a.time>b.time
        end)
    end

    if scoreMyData then
        --我方积分
        self.mScoreData = {}
        --s.uid,s.lid,s.lmzw,s.uname,s.ulv,s.zid,s.score,s.hp,s.etime,s.atknum,u.head
        for i,v in ipairs(scoreMyData.plays) do
            table.insert(self.mScoreData,{atk=0,bid=scoreMyData.bid,uid=v[1],headid=v[11],lv=v[5],name=v[4],job=v[3],atkNum=v[10],atkMaxNum=const.UPvpTimes,score=v[7]})
        end
    end
    table.sort(self.mScoreData,function (a,b)
        return a.score>b.score
    end)
    if scoreEData then
        --敌方积分
        self.eScoreData ={}
        for i,v in ipairs(scoreEData.plays) do
            table.insert(self.eScoreData,{atk=0,bid=scoreEData.bid,uid=v[1],headid=v[11],lv=v[5],name=v[4],job=v[3],atkNum=v[10],atkMaxNum=const.UPvpTimes,score=v[7]})
        end
    end
    table.sort(self.eScoreData,function (a,b)
        return a.score>b.score
    end)
    if self.initUI then
        self:changeTabIdx(self.idx)
    end
end

function UnionBattleLogDialog:getPvlHistroy()
    if not GameLogic.getUserContext().union then
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getPvlHistroy",{lid=GameLogic.getUserContext().union.id},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if self.initData then
                self:initData(data)
            end
        end
    end)
end

function UnionBattleLogDialog:getPvlReward(info)
    if not GameLogic.getUserContext().union then
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getPvlReward",{lid=GameLogic.getUserContext().union.id,bid=info.data.bid},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==0 then
                if data.agls and #data.agls>0 then
                    GameLogic.addRewards(data.agls)
                    GameLogic.showGet(data.agls,0.5,true,true)
                    info.isReceive =1
                    info.butReward:setGray(true)
                    info.butReward:setEnable(false)
                    info.butReward:setVisible(false)
                    info.labReward:setString(Localize("labelAlreadyReceive"))
                end
            end
        end
    end)
end

return UnionBattleLogDialog