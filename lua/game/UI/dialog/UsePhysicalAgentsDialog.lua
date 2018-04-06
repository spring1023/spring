local const = GMethod.loadScript("game.GameLogic.Const")
--使用体力药剂对话框
local UsePhysicalAgentsDialog = class2("UsePhysicalAgentsDialog",function()
    return BaseView.new("UsePhysicalAgentsDialog.json")
end)

function UsePhysicalAgentsDialog:ctor(params,callback)
    self.params,self.callback = params,callback
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self.context = GameLogic.getUserContext()
    self:initUI()
    display.showDialog(self)
    GameEvent.bindEvent(self,"refreshDialog",self,function()
        self:initItemViews()
    end)
    RegActionUpdate(self, Handler(self.updateMy, self, 0.5), 0.5)
end

function UsePhysicalAgentsDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:loadView("views")
    self:insertViewTo()
    self:initItemViews()

    self.butGotoStore:setListener(function()
        StoreDialog.new({stype="equip",idx=2,pri=display.getDialogPri()+1})
    end)
end

function UsePhysicalAgentsDialog:updateMy(diff)
    self.labelSweepValue:setString(self.params:getAP(GameLogic.getSTime()).."/240")
end

function UsePhysicalAgentsDialog:initItemViews()
    if not self.infos then
        self.infos = {}
        for i=1, 4 do
            self.infos[i] = {}
        end
    end
    local idx = 0
    for i=1, 4 do
        local num = self.context:getItem(const.ItemHWater, i)
        if num>0 then
            idx = idx+1
            self.infos[idx].id = i
            self.infos[idx].num = num
        end
    end
    for i=idx+1, 4 do
        self.infos[i].num = 0
    end
    if not self.tableView then
        self.tableView = ui.node()
        self:addChild(self.tableView)
        local bg
        for i, info in ipairs(self.infos) do
            bg = ui.button({185,185},nil,{})
            display.adapt(bg,243+(i-1)*290,404, GConst.Anchor.Center)
            self.tableView:addChild(bg)
            self:updateHWaterCell(bg, self.tableView, info)
        end
    else
        for _,info in ipairs(self.infos) do
            self:updateHWaterCell(info.view, self.tableView, info)
        end
    end
    local isempty = true
    for i,v in ipairs(self.infos) do
        if v.num<=0 then

        else
            isempty = false
        end
    end
    self.stringNoQYG:setVisible(isempty)
end

function UsePhysicalAgentsDialog:updateHWaterCell(cell, tableView, info)
    local bg= cell:getDrawNode()
    if not info.view then
        cell:setAutoHoldTime(0.5)
        cell:setAutoHoldTimeTemp(0.1)
        info.view = cell
        cell:setScriptCallback(ButtonHandler(self.onHWaterAction, self, info))
        local temp = ui.label("", General.font1, 40, {color={255,255,255}, size={200, 100}})
        display.adapt(temp, 92, -12, GConst.Anchor.Top)
        bg:addChild(temp, 1)
        info.nameLabel = temp
    end
    if info.id ~= info.displayId then
        info.displayId = info.id
        if info.itemView then
            info.itemView:removeFromParent(true)
            info.itemView = nil
            info.numLabel = nil
        end
        info.itemView, info.numLabel = GameUI.addItemIcon(bg, const.ItemHWater, info.id, 0.934, 92, 92, true, false, {itemNum=info.num})
        info.nameLabel:setString(StringManager.getString("dataItemName" .. const.ItemHWater .. "_" .. info.id))
    end
    if info.num==0 then
        cell:setVisible(false)
    else
        info.numLabel:setString(tostring(info.num))
        cell:setVisible(true)
    end
end

function UsePhysicalAgentsDialog:onHWaterAction(info)
    if info.num>0 and info.id>0 then
        self.context:useOrSellItem(const.ItemHWater, info.id, 1)
        self:initItemViews()
    end
end

return UsePhysicalAgentsDialog
