
local ReplayAgainDialog = class2("ReplayAgainDialog",function()
    return BaseView.new("ReplayAgainDialog.json")
end)

function ReplayAgainDialog:ctor(rid,scene)
    self.rid = rid
    self.scene = scene
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    display.showDialog(self,nil,true)
    self:initUI()
end

function ReplayAgainDialog:initUI()
    local bg = ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.Center, {datum = GConst.Anchor.Center,scale=ui.getUIScale2()})
    self:addChild(bg,1)
    self:loadView("viewMain",bg)
    self:insertViewTo()
    self.butAgain:setListener(function()
        if  self.scene.battleType==const.BattleTypePvc then
            local data = self.scene.battleReplayData
            GameEvent.sendEvent(GameEvent.EventVisitBegin,{isReplay=true,type= const.BattleTypePvc, battleReplayData=data})
        elseif self.scene.battleType==const.BattleTypeUPvp then
            local battleReplayData = json.decode(self.scene.battleReplayData)
            GameEvent.sendEvent(GameEvent.EventBattleBegin, {rid=battleReplayData.rid,isReplay=true,type=const.BattleTypeUPvp,data = battleReplayData.data,bparams = battleReplayData.bparams})
        elseif self.scene.battleType == const.BattleTypePvz then 
            GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvz, isReplay=true, rid = self.rid, gidx = self.gidx})
        else
            GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvp, isReplay=true, rid=self.rid})
        end
    end)

    local bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.LeftBottom, {datum = GConst.Anchor.LeftBottom,scale=ui.getUIScale2()})
    self:addChild(bg,1)
    self:loadView("viewLB",bg)
    self:insertViewTo()
    self.butBackBase:setListener(function()
        GameLogic.setSchedulerScale(1)
        local loading = GMethod.loadScript("game.Controller.ChangeController")
        loading:startExit(1,true)
    end)
    if self.scene.battleType==const.BattleTypeUPvp then
        local bg=ui.node()
        display.adapt(bg, 0, 0, GConst.Anchor.RightBottom, {datum = GConst.Anchor.RightBottom,scale=ui.getUIScale2()})
        self:addChild(bg,1)
        GameEvent.bindEvent(bg,"refreshReplay", self, self.closeSelf)
        self:loadView("viewRB",bg)
        self:insertViewTo()
        self.butReport:setListener(function()
            local battleReplayData = json.decode(self.scene.battleReplayData)
            --战报id
            if battleReplayData.rid then
                ReportDialog.new({lv=battleReplayData.lv,name=battleReplayData.name,headid=battleReplayData.headid,id=battleReplayData.rid,cmode=const.BattleTypeUPvp})
            end
        end)
    end
end

function ReplayAgainDialog:closeSelf()
    GameLogic.setSchedulerScale(1)
    local loading = GMethod.loadScript("game.Controller.ChangeController")
    loading:startExit(1,true)
end

return ReplayAgainDialog