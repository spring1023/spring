--联盟战得分一览对话框
local UnionBattleScoreListDialog = class2("UnionBattleScoreListDialog",function()
    return BaseView.new("UnionBattleScoreListDialog.json")
end)
function UnionBattleScoreListDialog:ctor(params)
    self.params = params
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end
function UnionBattleScoreListDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:showScoreListView()
end

function UnionBattleScoreListDialog:showScoreListView()
    local play = clone(self.params.play1)
    play = GameLogic.mySort(play,7,true)

	self:loadView("backViews")
	local infos={}
    for i=1,#play do
        infos[i]={id=i,item = play[i]}
    end
    self:addTableViewProperty("scoreTableview",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("scoreTableview")
end
function UnionBattleScoreListDialog:callcell(cell, tableView, info)
    local item = info.item
	local bg = cell:getDrawNode()
    cell:setEnable(false)
    if info.id%2==1 then
    	self:loadView("infoViewsBack",bg)
    end
    self:loadView("infoViews",bg)
    self:insertViewTo()
    self.xuhao:setString(info.id)
    self.name:setString(item[5])
    self.score:setString(item[7])
    --item[9]
    local atkNum = item[10]
    self.atkNum:setString((const.UPvpTimes-atkNum) .. "/" .. const.UPvpTimes)
    if const.UPvpTimes-atkNum>0 then
        ui.setColor(self.atkNum,"white")
    else
        ui.setColor(self.atkNum,"red")
    end
end
return UnionBattleScoreListDialog
