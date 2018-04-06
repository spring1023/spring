--英雄试炼战斗记录对话框
local HeroTrialBattleLogDialog = class2("HeroTrialBattleLogDialog",function()
    return BaseView.new("HeroTrialBattleLogDialog.json")
end)

function HeroTrialBattleLogDialog:ctor(params)
    self.params = params
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    display.showDialog(self)
    self:initBack()
end

function HeroTrialBattleLogDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))

    self:logView()
end
function HeroTrialBattleLogDialog:logView()
    local allLog = {}
    for k,v in pairs(self.params.battlelog) do
        if k~="lastlg" then
            for i,l in ipairs(v) do
                local sc= math.abs(l[4])
                local str = Localizef("string" .. k .. l[3],{name = l[2],score = sc})
                local time = l[5]
                table.insert(allLog,{k,str,time,l[3]})
            end
        end
    end

    allLog = GameLogic.mySort(allLog,3,true)



    local infos={}
    for i=1,#allLog do 
        infos[i]=allLog[i]
    end
    self:addTableViewProperty("logTableView",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("logTableView")
end
function HeroTrialBattleLogDialog:callcell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)

    self:loadView("logViews",bg)
    self:insertViewTo()
    self.labelBattleLog:setString(info[2])

    local tstr = Localizet(GameLogic.getTime()-info[3])
    tstr = Localizef("timeAgo2",{time = tstr})

    self.labelBattleLogTime:setString(tstr)
    if info[1] == "deflog" then
        if info[4] == 1 then
            self:loadView("failLogBack",bg)
        end
    else
        if info[4] == 0 then
            self:loadView("failLogBack",bg)
        end
    end
end
return HeroTrialBattleLogDialog
