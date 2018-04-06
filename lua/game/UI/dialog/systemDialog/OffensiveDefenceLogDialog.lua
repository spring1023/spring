--进攻防守日志和收件箱对话框
local OffensiveDefenceLogDialog = class2("OffensiveDefenceLogDialog",function()
    return BaseView.new("OffensiveDefenceLogDialog.json")
end)

function OffensiveDefenceLogDialog:ctor()
	self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function OffensiveDefenceLogDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    
    self:addTabView({"防守日志","进攻日志","收件箱"}, {543,149,480,1370,156,"images/dialogTabBack3_",55,271,69,1540,57,43,1324})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.DefenceLog,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.OffensiveLog,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.Inbox,self)})
     
    self:changeTabIdx(1)
end

function OffensiveDefenceLogDialog:OffensiveLog(tab)
    local bg, temp
    bg = ui.node({0,0},true)
    local infos={}
    for i=1,8 do
        infos[i]={id=i}
    end
    self:addTableViewProperty("LogTableView",infos,Script.createBasicHandler(self.callCellOffensiveLog,self))
    self:loadView("LogTableView",bg)
    return bg
end
function OffensiveDefenceLogDialog:callCellOffensiveLog(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)

    if info.id==2 then  --失败
        self:loadView("LogCellBack2",bg)
    else --胜利
        self:loadView("LogCellBack1",bg)
    end
    self:loadView("LogCellViews",bg)
    local unionFlag=GameUI.addUnionFlag(1,1,1)
    display.adapt(unionFlag, 52, 276, GConst.Anchor.Center)
    unionFlag:setScale(0.16)
    bg:addChild(unionFlag)
    for i=1,5 do
        local heroNode=ui.node()
        display.adapt(heroNode, 36+(i-1)*132, 87, GConst.Anchor.Center)
        bg:addChild(heroNode)
        self:loadView("heroNodeBack",heroNode)
        GameUI.addHeroHead(heroNode,4010,{x=3,y=0,size={115,160}})
    end
    local viewTab=self:getViewTab()
    if info.id==2 then  --失败
        viewTab.labelVD:setString(StringManager.getString("您失败了"))
        viewTab.labelVD:setColor(cc.c3b(228,47,47))
    else --胜利
        viewTab.labelVD:setString(StringManager.getString("您胜利了"))

        for i=1,3 do
            local  battleStar = ui.sprite("images/battleStar1.png",{59,59})
            display.adapt(battleStar,1359+(i-1)*67,186,GConst.Anchor.LeftBottom)
            bg:addChild(battleStar,1)
            if i==3 then--不到设灰色
                battleStar:setSValue(-100)
            end
        end
    end
    self:loadView("OffensiveButs",bg)
    
end
function OffensiveDefenceLogDialog:DefenceLog(tab)
    local bg, temp
    bg = ui.node({0,0},true)
    self:loadView("LogupViews",bg)
    local infos={}
    for i=1,8 do
        infos[i]={id=i}
    end
    self:addTableViewProperty("LogTableView",infos,Script.createBasicHandler(self.callCellDefenceLog,self))
    self:loadView("LogTableView",bg)
    return bg
end
function OffensiveDefenceLogDialog:callCellDefenceLog(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)

    if info.id==2 then  --失败
        self:loadView("LogCellBack2",bg)
    else --胜利
        self:loadView("LogCellBack1",bg)
    end
    self:loadView("LogCellViews",bg)
    local unionFlag=GameUI.addUnionFlag(1,1,1)
    display.adapt(unionFlag, 52, 276, GConst.Anchor.Center)
    unionFlag:setScale(0.16)
    bg:addChild(unionFlag)
    for i=1,5 do
        local heroNode=ui.node()
        display.adapt(heroNode, 36+(i-1)*132, 87, GConst.Anchor.Center)
        bg:addChild(heroNode)
        self:loadView("heroNodeBack",heroNode)
        GameUI.addHeroHead(heroNode,4010,{x=3,y=0,size={115,160}})
    end
    local viewTab=self:getViewTab()
    if info.id==2 then  --失败
        viewTab.labelVD:setString(StringManager.getString("您防守成功了"))
        viewTab.labelVD:setColor(cc.c3b(228,47,47))
    else --胜利
        viewTab.labelVD:setString(StringManager.getString("您防守胜利了"))
        
        for i=1,3 do
            local  battleStar = ui.sprite("images/battleStar1.png",{59,59})
            display.adapt(battleStar,1359+(i-1)*67,186,GConst.Anchor.LeftBottom)
            bg:addChild(battleStar,1)
            if i==3 then--不到设灰色
                battleStar:setSValue(-100)
            end
        end
    end
    self:loadView("DefenceButs",bg)
end

function OffensiveDefenceLogDialog:Inbox(tab)
    local bg, temp
    bg = ui.node({0,0},true)
    local infos={}
    for i=1,8 do
        infos[i]={id=i}
    end
    self:addTableViewProperty("InboxTableView",infos,Script.createBasicHandler(self.callCellInbox,self))
    self:loadView("InboxTableView",bg)
    return bg
end
function OffensiveDefenceLogDialog:callCellInbox(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    self:loadView("InboxCellBack",bg)
    self:loadView("InboxCellViews",bg)
    local viewTab = self:getViewTab()
    if info.id==2 then  --已读
        self:loadView("InboxCellBack2",bg)
        ui.setFrame(viewTab.iconInbox, "images/iconInbox3.png")
    elseif info.id>2 then--附件
        ui.setFrame(viewTab.iconInbox, "images/iconInbox2.png")
    end
end
return OffensiveDefenceLogDialog