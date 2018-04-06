local WarReportOut = class2("WarReportOut",function()
    return BaseView.new("WarReportOut.json",true)
end)

function WarReportOut:ctor(data)
    self.params = data
    self:initUI()
    display.showDialog(self)
end

function WarReportOut:initUI()
    self:loadView("backView")
    self:insertViewTo()
    self.butSure:setListener(function()
        display.closeDialog(0)
    end)
    self.butClose:setListener(function()
        display.closeDialog(0)
    end)
    --根据时间排序
    table.sort(self.params,function(a,b) return a[2]>b[2] end)

    local infos = {}
    local cupNum = 0
    for i,v in ipairs(self.params) do
        infos[i] = v
        cupNum = cupNum+v[3]
    end
    --奖杯取反,表示为自己的奖杯变化
    if cupNum~=0 then
        cupNum=-cupNum
    end
    if cupNum>=0 then
        self.labelCupValue:setString("+"..cupNum)
    else
        self.labelCupValue:setString(cupNum)
    end
    self:addTableViewProperty("infoTableView",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("infoTableView")
end

function WarReportOut:callcell(cell, tableView, info)
    local v = info
    local bg = cell:getDrawNode()
    self:loadView("cellView",bg)
    self:insertViewTo()
    local params = {id = v[1][6], x = 120, y = 75, scale = 0.6, blackBack = true, noBut = true}
    GameUI.addPlayHead(bg,params)
    if v[1][5]>0 then
        local unionFlag=GameUI.addUnionFlag(v[1][5])
        display.adapt(unionFlag, 259, 40, GConst.Anchor.Center)
        unionFlag:setScale(0.16)
        bg:addChild(unionFlag)
        self.lbUname:setString(v[1][4])
    else
        self.lbUname:setString("")
    end
    self.lbLv:setString(v[1][2])
    self.lbName:setString(v[1][1])
    local time = GameLogic.getSTime()-v[2]
    self.lbTime:setString(Localizef("timeAgo2",{time=Localizet(time)}))
end

return WarReportOut
