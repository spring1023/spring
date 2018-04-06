--进攻,防守日志和收件箱对话框
local LogDialog = class2("LogDialog",function()
    return BaseView.new("LogDialog.json")
end)

function LogDialog:ctor(index,datas,redNum)
    self.index=index
    self.datas=datas
    -- dump(self.datas)
    --redNum:setNum(0)
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth

    local uid=GameLogic.getUserContext().uid
    local sid=GameLogic.getUserContext().sid or 1
    self.eKey="email_" .. uid .."_".. sid
    self.alKey="atklog_" .. uid .."_".. sid
    self.dlKey="deflog_" .. uid .."_".. sid

    self:initUI()
    display.showDialog(self)
end

function LogDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:addTabView({"btnDefenceLog","btnOffensiveLog","btnInbox"}, {543,149,480,1370,156,"images/dialogTabBack3_",55,271,69,1540,57,43,1324})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.DefenceLog,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.OffensiveLog,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.Inbox,self)})
     
    self:changeTabIdx(self.index)
end
function LogDialog:removeBubble()
    if self.bubbleBut1 then
        self.bubbleBut1:removeFromParent(true)
        self.bubbleBut1 = nil
    end
    if self.bubbleBut2 then
        self.bubbleBut2:removeFromParent(true)
        self.bubbleBut2 = nil
    end
end

function LogDialog:canChangeTab(change)
    change()
    self:removeBubble()
end
--防守日志
function LogDialog:DefenceLog(tab)
    self:removeBubble()
    local bg, temp
    bg = ui.node({0,0},true)
    self:loadView("LogupViews",bg)
    local atkLogData=self.datas["deflog"]
    
    local changed=false
    local infos={}
    for i=1,#atkLogData do
        infos[i]={id=i,datas=atkLogData[i]}
        if not atkLogData[i].isSeed then
            atkLogData[i].isSeed=true
            changed=true
        end
    end
    if changed then
        GameLogic.getUserContext().logData:changeRedNum("deflog")
        GEngine.setConfig(self.dlKey, json.encode(atkLogData),true)
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
function LogDialog:callCellDefenceLog(cell, tableView, info)

    local data=info.datas

    local bg = cell:getDrawNode()

    self:loadView("LogCellViews",bg)
    local viewTab=self:getViewTab()

    GameUI.addResourceIcon(bg, "7", 0.65, 973, 316)
    GameUI.addResourceIcon(bg, "7", 0.65, 1499, 87)
    GameUI.addResourceIcon(bg, "1", 0.65, 85, 42)

    if data.stars>0 then--失败
        self:loadView("LogCellBack2",bg)
        viewTab.labelVD:setString(StringManager.getString("labDefenseFail"))
    else--胜利
        self:loadView("LogCellBack1",bg)
        viewTab.labelVD:setString(StringManager.getString("labDefenseSuccess"))
    end
    for i=1,3 do
            local  battleStar = ui.sprite("images/battleStar1.png",{59,59})
            display.adapt(battleStar,1359+(i-1)*67,186,GConst.Anchor.LeftBottom)
            bg:addChild(battleStar,1)
            if i>data.stars then--不到设灰色
                battleStar:setSValue(-100)
            end
    end
    viewTab.labPlayerLv:setString(StringManager.getString(data.plv))
    viewTab.labPlayerName:setString(StringManager.getString(data.tname))
    viewTab.labUnionName:setString(StringManager.getString(data.cname))
    viewTab.labTrophyCount:setString(StringManager.getString(data.tscore))
    viewTab.labTime:setString(StringManager.getString(data.ttime))
    viewTab.labGoldNum:setString(StringManager.getString(data.gold))
    viewTab.labDestroy:setString(StringManager.getString(data.destroy.."%"))
    local gsc=data.gsc--被打金杯数
    if gsc~=0 then
        gsc=-gsc
    end
    viewTab.labGetTrophyCount:setString(StringManager.getString(gsc))


    if data.ftag==0 then--未加入联盟
        viewTab.labUnionName:setVisible(false)
    else
        local unionFlag=GameUI.addUnionFlag(tonumber(data.ftag))
        display.adapt(unionFlag, 52, 276, GConst.Anchor.Center)
        unionFlag:setScale(0.16)
        bg:addChild(unionFlag)
    end
    if data.slist[1] and type(data.slist[1])=="table" then
        local thls = data.slist
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
    else
        local length=#data.slist--兼容前面的
        if length%2==1 then
            length=length-1
        end
        for i=1,length,2 do
            if i<=10 then --限制不超过5个英雄，格式{hid,lv,hid,lv....}
                local heroNode=ui.node()
                display.adapt(heroNode, 36+(i-1)/2*132, 87, GConst.Anchor.Center)
                bg:addChild(heroNode)
                self:loadView("heroNodeBack",heroNode)
                local hid=data.slist[i]
                local lv=data.slist[i+1]
                local alv = data.slist[i+2] or 0
                GameUI.addHeroHead(heroNode,hid,{x=3,y=0,size={115,160},lv=alv})
                local lvBack=ui.colorNode({113,27},{0,0,0,127})
                display.adapt(lvBack, 60, 17, GConst.Anchor.Center)
                heroNode:addChild(lvBack)
                local labelLv=ui.label("Lv："..lv, General.font1, 25, {color={255,255,255}})
                display.adapt(labelLv, 60, 2, GConst.Anchor.Bottom)
                heroNode:addChild(labelLv)
            end
        end
    end
    self:loadView("DefenceButs",bg)
    local dt=GameLogic.getTime()-data.ttime
    viewTab.labTime:setString(StringManager.getString(Localizet(dt)))
    if dt>const.LogPlaybackTime*24*60*60 then--3天
        viewTab.butBackPaly:setVisible(false)
        local temp = ui.label(StringManager.getString("labNotPlayback"), General.font2, 30, {color={0,0,0}})
        display.adapt(temp, 1734-170, 233, GConst.Anchor.Left)
        bg:addChild(temp)

        viewTab.butRevenge:setVisible(false)
    end
    --回放
    --viewTab.butBackPaly:setScriptCallback(Script.createCallbackHandler(display.pushNotice,"此功能未开放！"))
    viewTab.butBackPaly:setListener(function()
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvp, isReplay=true, rid=data.id})
    end)

    local function onGotoReverge()
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("revengepvh", {revengepvh = {data.uid}}, function(isSuc,rcdata)
            GameNetwork.unlockRequest()
            if isSuc then
                if type(rcdata) == "number" then
                    display.pushNotice(Localize("labelCantRevenge" .. rcdata))
                else
                    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvp, pvpData=rcdata, bparams = {repid = data.id}})
                end
            end
        end)
    end
    --复仇
    local function onReverge()
        if GameNetwork.checkRequest() then
            return
        end
        if tonumber(data.isRe)~=0 then
            display.pushNotice(Localize("btnRevenge2"))
        else
            GameLogic.checkPvpAttack({goldChecked=true, goldCost=true, callback=onGotoReverge})
        end
    end
    viewTab.butRevenge:setListener(onReverge)

    --复仇过了，无法复仇了
    if tonumber(data.isRe)~=0 then
        viewTab.butRevenge:setVisible(false)
        local temp = ui.label(StringManager.getString("btnRevenge2"), General.font2, 30, {color={0,0,0}})
        display.adapt(temp, 1734-170, 80, GConst.Anchor.Left)
        bg:addChild(temp)
    end
    --视屏分享按钮
    --viewTab.butSharedVision:setScriptCallback(Script.createCallbackHandler(display.pushNotice,"此功能未开放！"))
    --暂时关闭
    viewTab.butSharedVision:setVisible(false)

    local uid = data.uid
    ui.setListener(cell,function()
        local pos=cell:convertToWorldSpace(cc.p(700,190))
        local pos2=self:convertToNodeSpace(pos)
        if self.bubbleBut1 then
            self.bubbleBut1:removeFromParent(true)
            self.bubbleBut1 = nil
            if self.seeIdx==info.id then
                self.seeIdx=nil
                return
            end
        end
        self.seeIdx=info.id
        local content = {{Localize("btnVisit"),function()
            GameEvent.sendEvent(GameEvent.EventVisitBegin,{type = const.VisitTypeUn, uid = uid})
        end},{Localize("labelLookUnion"),function()
            self:showUnion(uid)
        end}}

        self.bubbleBut1 = GameUI.bubbleBut(self,{pos2.x,pos2.y},{856,496},content)
        display.setNodeTouchRemove(self,"bubbleBut1")
    end)
end
--滚动就删除联盟操作的节点
function LogDialog:scroll1(px,py)
   if self.bubbleBut1 then
        self.bubbleBut1:removeFromParent(true)
        self.bubbleBut1=nil
   end
end
function LogDialog:scroll2(px,py)
   if self.bubbleBut2 then
        self.bubbleBut2:removeFromParent(true)
        self.bubbleBut2=nil
   end
end
--进攻日志
function LogDialog:OffensiveLog(tab)
    self:removeBubble()
    local bg, temp
    bg = ui.node({0,0},true)
    self:loadView("LogupViews",bg)
    local atkLogData=self.datas["atklog"]
    local changed=false
    local infos={}
    for i=1,#atkLogData do
        infos[i]={id=i,datas=atkLogData[i]}
        if not atkLogData[i].isSeed then
            atkLogData[i].isSeed=true
            changed=true
        end
    end
    if changed then
        GameLogic.getUserContext().logData:changeRedNum("atklog")
        GEngine.setConfig(self.alKey, json.encode(atkLogData),true)
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
function LogDialog:callCellOffensiveLog(cell, tableView, info)

    local data=info.datas

    local bg = cell:getDrawNode()

    self:loadView("LogCellViews",bg)
    local viewTab=self:getViewTab()

    GameUI.addResourceIcon(bg, "7", 0.65, 973, 316)
    GameUI.addResourceIcon(bg, "7", 0.65, 1499, 87)
    GameUI.addResourceIcon(bg, "1", 0.65, 85, 42)

    if data.stars>0 then--胜利
        self:loadView("LogCellBack1",bg)

        viewTab.labelVD:setString(StringManager.getString("labSuccess"))
    else--失败
        self:loadView("LogCellBack2",bg)
        viewTab.labelVD:setString(StringManager.getString("labFail"))
    end
    for i=1,3 do
        local  battleStar = ui.sprite("images/battleStar1.png",{59,59})
        display.adapt(battleStar,1359+(i-1)*67,186,GConst.Anchor.LeftBottom)
        bg:addChild(battleStar,1)
        if i>data.stars then--不到设灰色
            battleStar:setSValue(-100)
        end
    end

    viewTab.labPlayerLv:setString(StringManager.getString(data.plv))
    viewTab.labPlayerName:setString(StringManager.getString(data.tname))
    viewTab.labUnionName:setString(StringManager.getString(data.cname))
    viewTab.labTrophyCount:setString(StringManager.getString(data.tscore))
   
    viewTab.labGoldNum:setString(StringManager.getString(data.gold))
    viewTab.labDestroy:setString(StringManager.getString(data.destroy.."%"))
    viewTab.labGetTrophyCount:setString(StringManager.getString(data.gsc))

    if data.ftag==0 then--未加入联盟
        viewTab.labUnionName:setVisible(false)
    else
        local unionFlag=GameUI.addUnionFlag(tonumber(data.ftag))
        display.adapt(unionFlag, 52, 276, GConst.Anchor.Center)
        unionFlag:setScale(0.16)
        bg:addChild(unionFlag)
    end
    if data.slist[1] and type(data.slist[1])=="table" then
        local thls = data.slist
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
    else
        local length=#data.slist--兼容前面的
        if length%2==1 then
            length=length-1
        end
        for i=1,length,2 do
            if i<=10 then --限制不超过5个英雄，格式{hid,lv,hid,lv....}
                local heroNode=ui.node()
                display.adapt(heroNode, 36+(i-1)/2*132, 87, GConst.Anchor.Center)
                bg:addChild(heroNode)
                self:loadView("heroNodeBack",heroNode)
                local hid=data.slist[i]
                local lv=data.slist[i+1]
                GameUI.addHeroHead(heroNode,hid,{x=3,y=0,size={115,160}})
                local lvBack=ui.colorNode({113,27},{0,0,0,127})
                display.adapt(lvBack, 60, 17, GConst.Anchor.Center)
                heroNode:addChild(lvBack)
                local labelLv=ui.label("Lv"..lv, General.font1, 25, {color={255,255,255}})
                display.adapt(labelLv, 60, 2, GConst.Anchor.Bottom)
                heroNode:addChild(labelLv)
            end
        end
    end
    self:loadView("OffensiveButs",bg)
    local dt=GameLogic.getTime()-data.ttime
    viewTab.labTime:setString(StringManager.getString(Localizet(dt)))
    if dt>const.LogPlaybackTime*24*60*60 then
        viewTab.butBackPaly:setVisible(false)
        local temp = ui.label(StringManager.getString("labNotPlayback"), General.font2, 30, {color={0,0,0}})
        display.adapt(temp, 1734-170, 233, GConst.Anchor.Left)
        bg:addChild(temp)
    end
    --回放
    --viewTab.butBackPaly:setScriptCallback(Script.createCallbackHandler(display.pushNotice,"此功能未开放！"))
    viewTab.butBackPaly:setListener(function()
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvp, isReplay=true, rid=data.id})
    end)
    --分享
    --viewTab.butSharedVision:setScriptCallback(Script.createCallbackHandler(display.pushNotice,"此功能未开放！"))
    --暂时关闭
    viewTab.butSharedVision:setVisible(false)
    local uid = data.uid
    ui.setListener(cell,function()
        local pos=cell:convertToWorldSpace(cc.p(700,190))
        local pos2=self:convertToNodeSpace(pos)
        if self.bubbleBut2 then
            self.bubbleBut2:removeFromParent(true)
            self.bubbleBut2 = nil
            if self.seeIdx==info.id then
                self.seeIdx=nil
                return
            end
        end
        self.seeIdx=info.id
        local content = {{Localize("btnVisit"),function()
            GameEvent.sendEvent(GameEvent.EventVisitBegin,{type = const.VisitTypeUn, uid = uid})
        end},{Localize("labelLookUnion"),function()
            self:showUnion(uid)
        end}}

        self.bubbleBut2 = GameUI.bubbleBut(self,{pos2.x,pos2.y},{856,496},content)
        display.setNodeTouchRemove(self,"bubbleBut2")
    end)
end
function LogDialog:getEmailShowId(data)
    local showId=0
    local emailDatas=self:getEmailDatas()
    for i=1,#emailDatas do
        if emailDatas[i].id==data.id then
            showId=i
            break
        end
    end
    return showId
end
function LogDialog:getEmailDatas(changData)
    if changData then--进入奖励对话框，数据发生改变
        if not changData.isSeed then
            changData.isSeed=true
            GameLogic.getUserContext().logData:changeRedNum("email")
        end
        local index
        for i,data in ipairs(self.datas["inbox"]) do
            if data.id==changData.id then
                self.datas["inbox"][i]=changData
                index=i
                break
            end
        end
        if changData.icon==0 then--删除特殊邮件
            table.remove(self.datas["inbox"],index)        
        end
        GEngine.setConfig(self.eKey, json.encode(self.datas["inbox"]),true)
    end
    local inboxData=json.decode(GEngine.getConfig(self.eKey))

    local inboxData_new={}
    local idex=0
    --按照附件，未读，特殊，已读显示
    for i,data in ipairs(inboxData) do
        if data.icon==1 then
            idex=idex+1
            inboxData_new[idex]=data
        end
    end
    for i,data in ipairs(inboxData) do
        if data.icon==2 then
            idex=idex+1
            inboxData_new[idex]=data
        end
    end
    for i,data in ipairs(inboxData) do
        if data.icon==4 then
            idex=idex+1
            inboxData_new[idex]=data
        end
    end
    for i,data in ipairs(inboxData) do
        if data.icon==3 then
            idex=idex+1
            inboxData_new[idex]=data
        end
    end
    return inboxData_new
end
function LogDialog:Inbox(tab)
    self:removeBubble()
    local bg, temp
    bg = ui.node({0,0},true)
    if not self.inboxNode then
        self.inboxNode=bg
    else
        self.inboxNode:removeAllChildren(true)
    end
    local inboxData=self:getEmailDatas( )
    local infos={}
    for i=1,#inboxData do
        infos[i]={id=i,datas=inboxData[i]}
    end
    self:addTableViewProperty("InboxTableView",infos,Script.createBasicHandler(self.callCellInbox,self))
    self:loadView("InboxTableView",self.inboxNode)
    self.inboxTableView=self:getTableView("InboxTableView")
    if #infos==0 then
        self:loadView("notInfoViews",self.inboxNode)
        local viewTab=self:getViewTab()
        viewTab.talkInfo:setString(StringManager.getString("labelTalkInfo3"))
    end
    return self.inboxNode
end
function LogDialog:callCellInbox(cell, tableView, info)
    local data=info.datas
    local bg = cell:getDrawNode()
    cell:setEnable(true)
    self:loadView("InboxCellBack",bg)
    self:loadView("InboxCellViews",bg)
    local viewTab = self:getViewTab()
    local str
    if data.isPackCodeEmail then
        str=data.title[1]
    else
        str=StringManager.getFormatString(data.rid.."_title",{a=data.title[1],b=data.title[2],c=data.title[3],d=data.title[4],e=data.title[5],f=data.title[6]})
    end
    viewTab.labTitle:setString(str)--标题

    local str
    if data.tname=="" then
        if data.rid >= 30 then
            str = Localize("1_sender")
        else
            str = Localize(data.rid .. "_sender")
        end
    else
        str=data.tname
    end
    viewTab.labPlayerName:setString(str)--玩家名字

    local dt=GameLogic.getTime()-data.time
    viewTab.labSendTime:setString(StringManager.getString(Localizet(dt)))--时间

    local iconI=data.icon--1附件，2未读，3已读,4特殊
    if iconI==1 then
        ui.setFrame(viewTab.iconInbox, "images/iconInbox1.png")
    elseif iconI==2 then
        ui.setFrame(viewTab.iconInbox, "images/iconInbox2.png")
    elseif iconI==3 then
        self:loadView("InboxCellBack2",bg)
        ui.setFrame(viewTab.iconInbox, "images/iconInbox3.png")
    end
    if data.isUnionEmail then
        cell:setScriptCallback(Script.createCallbackHandler(EmailUnionDialog.new,self,data))
    else
        cell:setScriptCallback(Script.createCallbackHandler(EmailDialog.new,self,data))
    end
end

function LogDialog:showUnion(uid)
    if not GameNetwork.lockRequest() then
        return
    end
     _G["GameNetwork"].request("getleagueinfo",{getleagueinfo={(uid or 0)*(-1)}},function(isSuc,data)
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


return LogDialog
