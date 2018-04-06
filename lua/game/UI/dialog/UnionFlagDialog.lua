--联盟旗帜对话框
local UnionFlagDialog = class2("UnionFlagDialog",function()
    return BaseView.new("UnionFlagDialog.json")
end)

function UnionFlagDialog:ctor(ps1,ps2,ps3,callback)
    self.callback = callback
    self.ps1,self.ps2,self.ps3 = ps1,ps2,ps3
    self.priority = display.getDialogPri()+1
    display.showDialog(self,true,true)
    self.tMoney = 0
    self.eMoney = 0
    self.allMoney = 0
    if GameLogic.getUserContext().union then
        self:getleaguepic()
    else
        self:initUI()
    end
end

function UnionFlagDialog:initUI()
    self:removeAllChildren(true)
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog))
    self:insertViewTo()
    self.butBack:setListener(function()
        display.closeDialog(self.priority)
    end)


    self:loadView("leftLabelViews")
    self:loadView("rightViews")

    --联盟建筑
    GameUI.addBuildHead(self,2,355,269,1682,515,2,1)

    self:insertViewTo()

    --保存按钮
    self.butKeep:setListener(function()
        display.closeDialog(self.priority)
        self.callback(self.ps1,self.ps2,self.ps3,self.allMoney)
    end)
    self:initRightFlags(1,1,1)
    

    local infos = {}

    for i=1,32 do
        infos[i] = {id = i,}
        if i>20 then
            infos[i] = {id = i+70-20,}
        end
    end
    
    self.infos1 = infos

    for i=1,3 do
        local temp = ui.scale9("images/bgWhite.9.png", 20, {1268,249})
        temp:setColor(cc.c3b(188, 184, 165))
        temp:setOpacity(165)
        display.adapt(temp, 104 , 919-380*(i-1), GConst.Anchor.LeftBottom)
        self:addChild(temp)
        temp = ui.sprite("images/choseTriangle.png", {54,40})
        display.adapt(temp,704 , 920-380*(i-1)+214, GConst.Anchor.LeftBottom)
        self:addChild(temp)
    end

    self:addTableViewProperty("tableView1",infos,function(...)
        self:callCell1(...)
    end)
    self:addTableViewCall("tableView1","locationEnd",Script.createBasicHandler(self.callLocationEnd1,self))
    self:loadView("tableView1")
    
    local tableView1=self:getTableView("tableView1")
    tableView1:setLocation(625)
    tableView1:startLocation(self.ps1>70 and self.ps1-70+20 or self.ps1)
    local infos = {}
    for i=1,13 do
        infos[i] = {id = i,}
    end
    self.infos2 = infos
    self:addTableViewProperty("tableView2",infos,function(...)
        self:callCell2(...)
    end)
    self:addTableViewCall("tableView2","locationEnd",Script.createBasicHandler(self.callLocationEnd2,self))
    self:loadView("tableView2")
    local tableView2=self:getTableView("tableView2")
    tableView2:setLocation(625)
    tableView2:startLocation(self.ps2)
    local infos = {}
    for i=1,25 do
        infos[i] = {id = i}
        if i>9 then
            infos[i] = {id = i+70-9}
        end
    end
    self.infos3 = infos
    self:addTableViewProperty("tableView3",infos,function(...)
        self:callCell3(...)
    end)
    self:addTableViewCall("tableView3","locationEnd",Script.createBasicHandler(self.callLocationEnd3,self))
    self:loadView("tableView3")
    self:insertViewTo()
    local tableView3=self:getTableView("tableView3")
    tableView3:setLocation(625)
    tableView3:startLocation(self.ps3>70 and self.ps3-70+9 or self.ps3)

    self.topCostValue:setVisible(false)
    self.topCost:setVisible(false)

    --三个 选择框的字
    local idx = self.ps1>70 and self.ps1-70+20 or self.ps1
    self.labelStyleValue:setString(idx .. "/32")
    local idx = self.ps2>70 and self.ps2-70+20 or self.ps2
    self.labelBackValue:setString(idx .. "/13")
    local idx = self.ps3>70 and self.ps3-70+20 or self.ps3
    self.labelFrameValue:setString(idx .. "/25")

end

function UnionFlagDialog:callCell1(cell, tableView, info)
    local id = info.id
    local bg = cell:getDrawNode()

    local temp = GameUI.addFlag1(id)
    bg:addChild(temp)
    temp:setPosition(126,123)

    if self.toppic and self.toppic[id] then
        
    elseif id>70 then
        temp = ui.sprite("images/btnHeroLockOn.png",{71,84})
        temp:setLValue(16)
        temp:setSValue(-100)
        display.adapt(temp,126,123,GConst.Anchor.Center)
        bg:addChild(temp)
    end
    ui.setListener(cell,function()
        local tableView1=self:getTableView("tableView1")
        tableView1:locationByI(id>70 and id-70+20 or id,true)
    end)
end

function UnionFlagDialog:callLocationEnd1(i)
    print(1,i)
    self.ps1 = self.infos1[i].id
    local id = self.ps1
    self:initRightFlags()
    if self.toppic and self.toppic[id] or id<=70 then
        self.tMoney = 0
        self.topCostValue:setVisible(false)
        self.topCost:setVisible(false)
    elseif id>70 then
        self.tMoney = 500
        self.topCostValue:setVisible(true)
        self.topCost:setVisible(true)
        self.topCostValue:setString(self.tMoney)
    end
    self:countAllMoney()
    self.labelStyleValue:setString(i .. "/32")
end

function UnionFlagDialog:callCell2(cell, tableView, info)
    local id = info.id
    local bg = cell:getDrawNode()
    local temp = GameUI.addFlag2(id)
    bg:addChild(temp)
    temp:setPosition(126,123)

    ui.setListener(cell,function()
        local tableView2=self:getTableView("tableView2")
        tableView2:locationByI(id,true)
    end)
end
function UnionFlagDialog:callLocationEnd2(i)
    print(2,i)
    self.ps2 = i
    self:initRightFlags()
    self.labelBackValue:setString(i .. "/13")
end

function UnionFlagDialog:callCell3(cell, tableView, info)
    local bg = cell:getDrawNode()
    local temp = GameUI.addFlag3(info.id)
    local id = info.id
    bg:addChild(temp)
    temp:setPosition(126,103)
    if self.endpic and self.endpic[id] then

    elseif id>70 then
        temp = ui.sprite("images/btnHeroLockOn.png",{71,84})
        temp:setLValue(16)
        temp:setSValue(-100)
        display.adapt(temp,126,103,GConst.Anchor.Center)
        bg:addChild(temp)
    end

    ui.setListener(cell,function()
        local tableView3=self:getTableView("tableView3")
        tableView3:locationByI(id>70 and id-70+9 or id,true)
    end)

end

function UnionFlagDialog:callLocationEnd3(i)
    print(3,i)
    self.ps3 = self.infos3[i].id
    local id = self.ps3
    self:initRightFlags()
    if self.endpic and self.endpic[id] or id<=70 then
        self.eMoney = 0
        self.endCostValue:setVisible(false)
        self.endCost:setVisible(false)
    elseif id>70 then
        self.eMoney = 1000
        self.endCostValue:setVisible(true)
        self.endCost:setVisible(true)
        self.endCostValue:setString(self.eMoney)
    end
    self:countAllMoney()
    self.labelFrameValue:setString(i .. "/25")
end

function UnionFlagDialog:initRightFlags()
    if self.rightNode then
        self.rightNode:removeFromParent(true)
        self.rightNode = nil
    end
    self.rightNode = ui.node()
    self:addChild(self.rightNode)

    local temp = GameUI.addUnionFlag(self.ps1,self.ps2,self.ps3)
    self.rightNode:addChild(temp)
    temp:setPosition(1700,968)

    temp = GameUI.addUnionFlag(self.ps1,self.ps2,self.ps3)
    self.rightNode:addChild(temp)
    temp:setPosition(1695,632)
    temp:setScale(0.35)

    GameLogic.keepOnline()
end

function UnionFlagDialog:countAllMoney()
    self.allMoney = self.tMoney+self.eMoney
end
------------------------------------------------------------------------------
function UnionFlagDialog:getleaguepic()
    _G["GameNetwork"].request("getleaguepic",{getleaguepic={GameLogic.getUserContext().union.id}},function(isSuc,data)
        if isSuc then
            print_r(data)
            self.toppic = {}
            self.endpic = {}
            for i,v in ipairs(data.toppic) do
                self.toppic[v] = true
            end
            for i,v in ipairs(data.endpic) do
                self.endpic[v] = true
            end

            if self.initUI then
                self:initUI()
            end
        end
    end)
end








return UnionFlagDialog













