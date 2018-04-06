--进攻,防守日志和收件箱对话框
local PvcLogDialog = class2("PvcLogDialog",function()
    return BaseView.new("PvcLogDialog.json")
end)

function PvcLogDialog:ctor(index)
    self.index=index or 1
    self:initUI()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function PvcLogDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,0))
    self:addTabView({"btnDefenceLog","btnOffensiveLog"}, {543,149,480,1370,156,"images/dialogTabBack3_",55,271,69,1540,57,43,1324})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.DefenceLog,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.OffensiveLog,self)})

    self:changeTabIdx(self.index)
end


function PvcLogDialog:canChangeTab(change)
    change()
end
--防守日志
function PvcLogDialog:DefenceLog(tab)
    local bg, temp
    bg = ui.node({0,0},true)
    self:loadView("LogupViews",bg)

    local atkLogData=GameLogic.getUserContext().arena.desLogData
    local infos={}
    for i=1,#atkLogData do
        infos[i]={id=i,datas=atkLogData[i]}
    end

    self:addTableViewProperty("LogTableView1",infos,Script.createBasicHandler(self.callCellDefenceLog,self))
    self:addTableViewProperty2("LogTableView1",infos,Script.createBasicHandler(self.scroll1,self))
    self:loadView("LogTableView1",bg)
    if #infos==0 then
        self:loadView("notInfoViews",bg)
        local viewTab=self:getViewTab()
        viewTab.labOpponent:setVisible(false)
        viewTab.labResult:setVisible(false)
        viewTab.talkInfo:setString(StringManager.getString("labelTalkInfo1"))
    end
    return bg
end
function PvcLogDialog:callCellDefenceLog(cell, tableView, info)
    local data=info.datas
    local tinfo = json.decode(data.uinfo)
    local thls = json.decode(data.uhls)

    local bg = cell:getDrawNode()
    self:loadView("LogCellViews",bg)
    local viewTab=self:getViewTab()
    local res = GameUI.addResourceIcon(bg, 60, 0.65, 1173, 276)
    if data.isWin>0 then--胜利，取反显示
        self:loadView("LogCellBack2",bg)
        viewTab.labelVD:setString(StringManager.getString("labFail"))
    else--失败
        self:loadView("LogCellBack1",bg)
        viewTab.labelVD:setString(StringManager.getString("labSuccess"))
    end

    viewTab.labPlayerName:setString(StringManager.getString(tinfo[1]))
    viewTab.labPlayerLv:setString(StringManager.getString(tinfo[2]))
    viewTab.labUnionName:setString(StringManager.getString(tinfo[4]))

    viewTab.labelRanking2:setString(Localizef("labelRanking2",{a=data.urank}))
    if data.canGetHonor>0 then
        viewTab.labelGetHohor:setString(Localizef("labRevenge2",{a=data.canGetHonor}))
    else
        viewTab.labelGetHohor:setVisible(false)
        res:setVisible(false)
    end

    if tinfo[5]==0 then--未加入联盟
        viewTab.labUnionName:setVisible(false)
    else
        local unionFlag=GameUI.addUnionFlag(tonumber(tinfo[5]))
        display.adapt(unionFlag, 52, 276, GConst.Anchor.Center)
        unionFlag:setScale(0.16)
        bg:addChild(unionFlag)
    end
    if thls then
        for i, v in ipairs(thls) do
            local hid=v[1]
            local lv=v[2]
            local alv=v[3]
            local heroNode=ui.node()
            display.adapt(heroNode, 36+(i-1)*132, 87, GConst.Anchor.Center)
            bg:addChild(heroNode)
            self:loadView("heroNodeBack",heroNode)

            GameUI.addHeroHead(heroNode,hid,{x=3,y=0,size={115,160},lv=alv})
            local lvBack=ui.colorNode({113,27},{0,0,0,127})
            display.adapt(lvBack, 60, 17, GConst.Anchor.Center)
            heroNode:addChild(lvBack)
            local labelLv=ui.label("Lv"..lv, General.font1, 25, {color={255,255,255}})
            display.adapt(labelLv, 60, 2, GConst.Anchor.Bottom)
            heroNode:addChild(labelLv)
        end
    end
    
    if thls and #thls>0 then
        viewTab.labNotHeros:setVisible(false)
    else
        viewTab.labNotHeros:setVisible(true)
    end

    local upRank = data.uprank*(-1)
    viewTab.labelUpRank:setString(upRank)

    if upRank>0 then--上升，已默认
        viewTab.labelUpRank:setColor(cc.c3b(118,249,12))
    elseif upRank==0 then--持平
        ui.setFrame(viewTab.imaRanking, "images/rankFlat.png")
        viewTab.labelUpRank:setVisible(false)
    elseif upRank<0 then --下降
        ui.setFrame(viewTab.imaRanking, "images/rankDecline.png")
        viewTab.labelUpRank:setColor(cc.c3b(249,64,64))
    end
    self:loadView("DefenceButs",bg)
    local dt=GameLogic.getTime()-data.btime
    viewTab.labTime:setString(StringManager.getString(Localizet(dt)))
    if dt>const.LogPlaybackTime*24*60*60 then
        viewTab.butBackPaly:setVisible(false)
        local temp = ui.label(StringManager.getString("labNotPlayback"), General.font2, 30, {color={0,0,0}})
        display.adapt(temp, 1734-170, 233, GConst.Anchor.Left)
        bg:addChild(temp)
    end
    --回放
    viewTab.butBackPaly:setListener(function()
        self:getReplayData(data,true)
    end)

    --复仇
    local function onReverge()
        self:onChallenge(data)
    end
    viewTab.butRevenge:setListener(onReverge)

    --复仇过了，无法复仇了
    if data.rev>0 then
        viewTab.butRevenge:setVisible(false)
        local temp = ui.label(StringManager.getString("btnRevenge2"), General.font2, 30, {color={0,0,0}})
        display.adapt(temp, 1734-170, 80, GConst.Anchor.Left)
        bg:addChild(temp)
    end

end
--滚动就删除联盟操作的节点
function PvcLogDialog:scroll1(px,py)
   if self.bubbleBut1 then
        self.bubbleBut1:removeFromParent(true)
        self.bubbleBut1=nil
   end
end
function PvcLogDialog:scroll2(px,py)
   if self.bubbleBut2 then
        self.bubbleBut2:removeFromParent(true)
        self.bubbleBut2=nil
   end
end
--进攻日志
function PvcLogDialog:OffensiveLog(tab)
    local bg, temp
    bg = ui.node({0,0},true)
    self:loadView("LogupViews",bg)
    local atkLogData=GameLogic.getUserContext().arena.atkLogData
    local infos={}
    for i=1,#atkLogData do
        infos[i]={id=i,datas=atkLogData[i]}
    end
    self:addTableViewProperty("LogTableView2",infos,Script.createBasicHandler(self.callCellOffensiveLog,self))
    self:addTableViewProperty2("LogTableView2",infos,Script.createBasicHandler(self.scroll2,self))
    self:loadView("LogTableView2",bg)

    if #infos==0 then
        self:loadView("notInfoViews",bg)
        local viewTab=self:getViewTab()
        viewTab.labOpponent:setVisible(false)
        viewTab.labResult:setVisible(false)
        viewTab.talkInfo:setString(StringManager.getString("labelTalkInfo2"))
    end
    return bg
end
function PvcLogDialog:callCellOffensiveLog(cell, tableView, info)
    local data=info.datas
    local bg = cell:getDrawNode()
    self:loadView("LogCellViews",bg)
    local viewTab=self:getViewTab()
    local tinfo = json.decode(data.tinfo)
    local thls = json.decode(data.thls)
    if data.isWin>0 then--胜利
        self:loadView("LogCellBack1",bg)

        viewTab.labelVD:setString(StringManager.getString("labSuccess"))
    else--失败
        self:loadView("LogCellBack2",bg)
        viewTab.labelVD:setString(StringManager.getString("labFail"))
    end

    viewTab.labPlayerName:setString(StringManager.getString(tinfo[1]))
    viewTab.labPlayerLv:setString(StringManager.getString(tinfo[2]))
    viewTab.labUnionName:setString(StringManager.getString(tinfo[4]))

    viewTab.labelRanking2:setString(Localizef("labelRanking2",{a=data.trank}))
    viewTab.labelGetHohor:setVisible(false)
    if tinfo[5]==0 then--未加入联盟
        viewTab.labUnionName:setVisible(false)
    else
        local unionFlag=GameUI.addUnionFlag(tonumber(tinfo[5]))
        display.adapt(unionFlag, 52, 276, GConst.Anchor.Center)
        unionFlag:setScale(0.16)
        bg:addChild(unionFlag)
    end
    if thls then
        for i, v in ipairs(thls) do
            local hid=v[1]
            local lv=v[2]
            local alv=v[3]
            local heroNode=ui.node()
            display.adapt(heroNode, 36+(i-1)*132, 87, GConst.Anchor.Center)
            bg:addChild(heroNode)
            self:loadView("heroNodeBack",heroNode)

            GameUI.addHeroHead(heroNode,hid,{x=3,y=0,size={115,160},lv=alv})
            local lvBack=ui.colorNode({113,27},{0,0,0,127})
            display.adapt(lvBack, 60, 17, GConst.Anchor.Center)
            heroNode:addChild(lvBack)
            local labelLv=ui.label("Lv"..lv, General.font1, 25, {color={255,255,255}})
            display.adapt(labelLv, 60, 2, GConst.Anchor.Bottom)
            heroNode:addChild(labelLv)
        end
    end
    if thls and #thls>0 then
        viewTab.labNotHeros:setVisible(false)
    else
        viewTab.labNotHeros:setVisible(true)
    end

    local upRank = data.uprank
    viewTab.labelUpRank:setString(upRank)

    if upRank>0 then--上升，已默认
        viewTab.labelUpRank:setColor(cc.c3b(118,249,12))
    elseif upRank==0 then--持平
        ui.setFrame(viewTab.imaRanking, "images/rankFlat.png")
        viewTab.labelUpRank:setVisible(false)
    elseif upRank<0 then --下降
        ui.setFrame(viewTab.imaRanking, "images/rankDecline.png")
        viewTab.labelUpRank:setColor(cc.c3b(249,64,64))
    end


    self:loadView("OffensiveButs",bg)
    local dt=GameLogic.getTime()-data.btime
    viewTab.labTime:setString(StringManager.getString(Localizet(dt)))
    if dt>const.LogPlaybackTime*24*60*60 then
        viewTab.butBackPaly:setVisible(false)
        local temp = ui.label(StringManager.getString("labNotPlayback"), General.font2, 30, {color={0,0,0}})
        display.adapt(temp, 1734-170, 233, GConst.Anchor.Left)
        bg:addChild(temp)
    end
    --回放
    viewTab.butBackPaly:setListener(function()
        self:getReplayData(data)
    end)
end




function PvcLogDialog:showUnion(uid)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getleagueinfo",{getleagueinfo={uid*(-1)}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if type(data) == "number" then
                if data == 2 then
                    display.pushNotice(Localize("stringNOUnion"))
                end
                return
            else
                UnionInfoDialog.new(data)
            end
        end
    end)
end

function PvcLogDialog:onChallenge(infos)
    local arena =GameLogic.getUserContext().arena
    if arena:getCurrentChance()>0 then
        GameLogic.checkCanGoBattle(const.BattleTypePvc,function()
            if not GameNetwork.lockRequest() then
                return
            end
            local myHeroList = {}
            local context = GameLogic.getUserContext()
            local sign = context:getProperty(const.ProUseLayout)
            sign = GameLogic.dnumber(sign,3)
            for i=1,5 do
                local hero
                if sign[2]>0 then
                    hero = context.heroData:getHeroByLayout(const.LayoutPvc, i, 1)
                else
                    hero = context.heroData:getHeroByLayout(const.LayoutPvp, i, 1)
                end
                if hero then
                    table.insert(myHeroList,{hero.hid,hero.level,hero.awakeUp})
                end
            end
            GameNetwork.request("pvcBeginBattle", {tid=infos.uid,nrank=0,batid=infos.cid,uhls=myHeroList}, function(isSuc,data)
                GameNetwork.unlockRequest()
                --dict(code=0,batid=rid,sdata=sdata)
                if isSuc then
                    if data.code==1 then
                        display.pushNotice(Localize("noticeRefreshEnemys"))
                    elseif data.code==2 then
                        display.pushNotice(Localize("labBattling"))
                    else
                        arena:resetChanceData(data.battime)
                        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=3,isRev=1, batid=data.batid,myRank=arena:getCurrentRank(),bparams={uid=infos.tid,rank=infos.trank}, isPrepare=true, havePvcData=data.sdata})
                    end
                end
             end)
        end)
    else
        display.pushNotice(Localize("stringChangeNotEnough"))
    end
end

function PvcLogDialog:getReplayData(infos,isDes)
    if not GameNetwork.lockRequest() then
        return
    end
    local arena =GameLogic.getUserContext().arena
    GameNetwork.request("pvchistory", {rid=infos.cid}, function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            --dump(data)
            if data.replay=="" then
                display.pushNotice(Localize("labNotPlayback"))
            else
                local bdata = json.decode(data.replay)
                GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvc, isReplay=true, battleReplayData=bdata})
            end
        end
    end)

end

return PvcLogDialog
