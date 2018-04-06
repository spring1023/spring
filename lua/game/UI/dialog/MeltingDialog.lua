local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
--熔炼对话框
local MeltingDialog = class2("MeltingDialog",function()
    return BaseView.new("MeltingDialog.json",true)
end)

function MeltingDialog:ctor(mode)
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function MeltingDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))
    self.context = GameLogic.getUserContext()
    local alchemys = SData.getData("alchemys")
    local infos = {}
    for i,v in ipairs(alchemys) do
        v.id = i
        infos[i] = {id=i,item = v}
    end
    self:addTableViewProperty("upTableView",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("upTableView")

    local meltData = self.context.meltData
    meltData:initGaEnery()
    local onAlchemy = meltData.onAlchemy
    if not next(onAlchemy) then
        self.mode = 1
    else
        if onAlchemy[3]-GameLogic.getTime()<=0 then
            self.mode = 4
        else
            self.mode = 3
        end
    end
    self:reloadBottom()
end
function MeltingDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local item = info.item
    local icon = GameUI.addItemIcon(bg,item.gtype,item.gid,279/200,140,140,true)
    self:loadView("cellViews",bg)
    self:insertViewTo()
    self.getNum:setString("x" .. item.gnum)
    self.costStone:setString(item.hnum)

    local meltData = self.context.meltData
    if item.blv>self.context.buildData:getMaxLevel(8) then
        self:loadView("tipsLvLabel",bg)
        self:insertViewTo()
        self.labelNeedLv:setString(Localizef("labelNeedLv",{a = item.blv}))
        icon:setSValue(-100)
        self.spiritStone:setSValue(-100)
        ui.setListener(cell,function()
            display.pushNotice(Localizef("labelNeedLv",{a = item.blv}))
        end)
    else
        ui.setListener(cell,function()
            if self.mode == 3 then
                display.pushNotice(Localize("labelIsOnAlchemy"))
            elseif self.mode == 4 then
                display.pushNotice(Localize("labelPleaseReceiveFirst"))
            else
                self.mode = 2
                self:reloadBottom(item)
                --添加选中特效
                if self.xuanZhong then
                    self.xuanZhong:removeFromParent(true)
                    self.xuanZhong=nil
                end
                self.xuanZhong=UIeffectsManage:showEffect_lianjingzhen(1,cell,150,150)
            end
        end)
    end
end

function MeltingDialog:reloadBottom(item)
    if self.bottomNode then
        self.bottomNode:removeFromParent(true)
        self.bottomNode = nil
    end
    self.bottomNode = ui.node()
    self:addChild(self.bottomNode)
    self:loadView("haveViews",self.bottomNode)
    self:insertViewTo()
    self.labelNowHaveValue:setString(self.context:getProperty(const.ProGaStone))
    if self.mode==1 then--未选择时
        self:loadView("unselectedViews",self.bottomNode)
    elseif self.mode==2 then--已选择
        self:loadView("selectedViews",self.bottomNode)
        self:loadView("meltingButViews",self.bottomNode)
        self:insertViewTo()
        self.thingName:setString(GameLogic.getItemName(item.gtype,item.gid))
        GameUI.addItemIcon(self.bottomNode,item.gtype,item.gid,279/200,94+140,159+140,true)
        self.thingNum:setString("x" .. item.gnum)
        self.labelAlchemyCostValue:setString(item.hnum)
        if item.hnum>self.context:getProperty(const.ProGaStone) then
            ui.setColor(self.labelAlchemyCostValue,"red")
        end
        self.timeProcess:setProcess(true,0)
        self.timeProcessValue:setString(Localizet(item.ltime))
        self.butMelting:setListener(function()
            self:beginalchemy(item)
        end)
    elseif self.mode==3 then--熔炼过程中
        if self.xuanZhong then
            self.xuanZhong:removeFromParent(true)
            self.xuanZhong=nil
        end
        local meltData = self.context.meltData
        local item = SData.getData("alchemys",meltData.onAlchemy[1])
        self:loadView("selectedViews",self.bottomNode)
        self:loadView("cancelAndfinishViews",self.bottomNode)
        --添加时钟特效
        UIeffectsManage:showEffect_lianjingzhen(2,self.bottomNode,500,140)

        self:insertViewTo()
        self.thingName:setString(GameLogic.getItemName(item.gtype,item.gid))
        GameUI.addItemIcon(self.bottomNode,item.gtype,item.gid,279/200,94+140,159+140,true)
        self.thingNum:setString("x" .. item.gnum)
        self.labelAlchemyCostValue:setString(item.hnum)
        local function updateProcess()
            local rtime = meltData.onAlchemy[3] - GameLogic.getTime()
            if rtime <=0 then
                self.mode = 4
                self:reloadBottom()
                return
            end
            self.timeProcess:setProcess(true,1-rtime/item.ltime)
            self.timeProcessValue:setString(Localizet(rtime))

            self.crystalNumValue = math.ceil(rtime/900)*2
            self.crystalNum:setString(self.crystalNumValue)
            if self.context:getRes(const.ResCrystal)< self.crystalNumValue then
                ui.setColor(self.crystalNum,"red")
            end
        end
        updateProcess()
        RegTimeUpdate(self.timeProcess,updateProcess,0.1)
        self.butCancel:setListener(function()
            local otherSettings = {callback = function()
                self:chancealchemy()
            end}
            local dl = AlertDialog.new(3,Localize("labelCanCelAlchemy"),Localizef("stringCanCelAlchemy",{a = GameLogic.getItemName(item.gtype,item.gid)}),otherSettings)
            display.showDialog(dl)
        end)
        self.butFinish:setListener(function()
            if self.context:getRes(const.ResCrystal)< self.crystalNumValue then
                local otherSettings = {yesBut="btnEnterShop",callback = function()
                    StoreDialog.new({id=1,closeDialogCallback=function ()
                        ui.setColor(self.crystalNum,255,255,255)
                    end})
                end}
                local dl = AlertDialog.new(2, Localize("alertTitleBuyCrystal"), Localize("alertTextBuyCrystal"),otherSettings)
                display.showDialog(dl)
            else
                local otherSettings = {ctype = const.ResCrystal, cvalue=self.crystalNumValue , callback = function()
                    self:accalchemy()
                end}
                local dl = AlertDialog.new(3,Localize("wordFinish"),Localizef("stringAffirmCostNowC",{a = self.crystalNumValue}),otherSettings)
                display.showDialog(dl)
            end
        end)
    elseif self.mode==4 then--可领取时
        local meltData = self.context.meltData
        local item = SData.getData("alchemys",meltData.onAlchemy[1])
        self:loadView("selectedViews",self.bottomNode)
        self:loadView("receiveButViews",self.bottomNode)
        self:insertViewTo()
        self.thingName:setString(GameLogic.getItemName(item.gtype,item.gid))
        GameUI.addItemIcon(self.bottomNode,item.gtype,item.gid,279/200,94+140,159+140,true)
        self.thingNum:setString("x" .. item.gnum)
        self.labelAlchemyCostValue:setString(item.hnum)
        self.timeProcess:setProcess(true,1)
        self.timeProcessValue:setString(Localizet(item.ltime))
        self.butReceive:setListener(function()
            self:getalchemyreward()
        end)
    end
end
----------------------------------------------------------------------
function MeltingDialog:beginalchemy(item)
    local meltData = self.context.meltData
    local context = self.context
    local gaStone = self.context:getProperty(const.ProGaStone)
    if gaStone<item.hnum then
        display.pushNotice(Localize("labelGaStoneNo"))
        return
    end
    context:addCmd({const.CmdAlchemyBegin,item.id})
    context:changeProperty(const.ProGaStone,-item.hnum)
    meltData.onAlchemy = {item.id,GameLogic.getTime(),GameLogic.getTime()+item.ltime}
    if self.reloadBottom then
        self.mode = 3
        self:reloadBottom()
    end
    -- 日常任务炼金
    GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeGoldChange,1)
end
function MeltingDialog:chancealchemy()
    local meltData = self.context.meltData
    local context = self.context
    context:addCmd({const.CmdAlchemyChance})
    local item = SData.getData("alchemys",meltData.onAlchemy[1])
    meltData.onAlchemy = {}
    context:changeProperty(const.ProGaStone,math.floor(0.8*item.hnum))
    if self.reloadBottom then
        self.mode = 1
        self:reloadBottom()
    end
end
function MeltingDialog:accalchemy()
    if not GameNetwork.lockRequest() then
        return
    end
    local context = self.context
    local meltData = self.context.meltData
    GameNetwork.request("accalchemy",{},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            context:changeRes(const.ResCrystal,-data.usecry)
            GameLogic.statCrystalCost("炼金立即完成",const.ResCrystal,-data.usecry)
            meltData.onAlchemy[3] = GameLogic.getTime()
            if self.reloadBottom then
                self.mode = 4
                self:reloadBottom()
            end
        end
    end)
end
function MeltingDialog:getalchemyreward()
    if not GameNetwork.lockRequest() then
        return
    end
    local context = self.context
    local meltData = self.context.meltData
    GameNetwork.request("getalchemyreward",{},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            GameLogic.showGet(data)
            GameLogic.addRewards(data)
            if self.reloadBottom then
                self.mode = 1
                meltData.onAlchemy = {}
                self:reloadBottom()
            end
        end
    end)
end
return MeltingDialog














