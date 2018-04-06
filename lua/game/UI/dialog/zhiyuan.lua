local zhiyuan = class(DialogViewLayout)
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")


function zhiyuan:onInitDialog(params)
    self.params = params
    self.context = GameLogic.getUserContext()
    self.state = nil  --不可领取  1可领取
    self:initUI()
    self:initData()
end

function zhiyuan:initUI()
    self:setLayout("zhiyuan.json")
    self:loadViewsTo()
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.btn_receive:setScriptCallback(ButtonHandler(self.OnRecieveClick, self))
    self.lab_receive:setString(Localize("labelRecive"))
    self.lab_supportReward:setString(Localize("labelSupportReward"))
    self.lab_nextReceiveTime:setString(Localize("nextReceiveTime"))
    self.lab_curReward:setString(Localize("currentReward"))
    self:finRewardStrSet()

    ViewTemplates.setImplements(self.bottom, "LayoutImplement", {callback=Handler(self.onUpdateItemsCell1, self), withIdx=false})--当前奖励
    ViewTemplates.setImplements(self.bottom2, "LayoutImplement", {callback=Handler(self.onUpdateItemsCell2, self), withIdx=false})--最终奖励

    self:update()
    RegTimeUpdate(self.lab_receive.view, function()
        self:update()
    end, 1)
end

function zhiyuan:initData()
    self:updateData()
end

function zhiyuan:updateData()
    self:CurReward()
    self:FinReward()
end

function zhiyuan:finRewardStrSet()
    local num = #(SData.getData("olrwdt")) - self.context:getProperty(const.ProOnlineCount)--奖励表的长度(即每日支援奖励的最高次数)减去当前次数
    local finRewardStr = Localizef("finalReward", {n=num})
    self.lab_finReward:setString(finRewardStr)
end

function zhiyuan:OnRecieveClick()
    if self.receiveNum == #(SData.getData("olrwdt")) then
        self.lab_nextReceiveTime:setString(Localize("labelAllReceiveToday"))
    else
        if self.state == 1 then
            self:onlinerewards()
        end
    end
end

function zhiyuan:CurReward()--当前奖励
    local infosCurReward = {}
    self.infosCurReward = infosCurReward
    self.lab_nextReceiveTip:setVisible(false)
    local num = self.context:getProperty(const.ProOnlineCount) --当前领取次数
    if num>=#SData.getData("olrwdt") then
        num = #SData.getData("olrwdt")-1
        self.lab_nextReceiveTip:setVisible(true)
        self.lab_nextReceiveTip:setString(Localize("labelOverTip"))
    end
    self.receiveNum = num
    local rwds = SData.getData("olrwdt",num + 1).rwds
    for i=1,#rwds do
        local rwd = rwds[i]
        table.insert(infosCurReward, {id = i, resMode = rwd[1], resID = rwd[2], resNum = rwd[3]})
    end
    self.bottom:setLayoutDatas(infosCurReward)
end

function zhiyuan:FinReward()--最终奖励
    local infosFinReward = {}
    self.infosFinReward = infosFinReward
    local length = #(SData.getData("olrwdt"))--获取奖励表的长度,即最终奖励是第几次
    local rwds = SData.getData("olrwdt",length).rwds
    for i=1,#rwds do
        local rwd = rwds[i]
        table.insert(infosFinReward, {id = i, resMode = rwd[1], resID = rwd[2], resNum = rwd[3]})
    end
    self.bottom2:setLayoutDatas(infosFinReward)
end

function zhiyuan:onUpdateItemsCell1(reuseCell, layout, item)
    if not reuseCell then
        reuseCell = layout:createItem(1)
        reuseCell:loadViewsTo()
    end
    if item.resID ~= reuseCell.displayId or item.resMode ~= reuseCell.displayMode then
        reuseCell.displayMode = item.resMode
        reuseCell.displayId = item.resID
        reuseCell.bg_item:removeAllChildren()
        local cellSize = reuseCell.bg_item.size
        GameUI.addItemIcon(reuseCell.bg_item, item.resMode, item.resID, cellSize[2]/200,cellSize[1]/2, cellSize[2]/2, true, false)
        GameUI.registerTipsAction(reuseCell, self.view, item.resMode,  item.resID)
    end
    reuseCell.lab_itemNum:setString(N2S(item.resNum))
    return reuseCell
end

function zhiyuan:onUpdateItemsCell2(reuseCell, layout, item)
    if not reuseCell then
        reuseCell = layout:createItem(1)
        reuseCell:loadViewsTo()
    end
    if item.id ~= reuseCell.displayId then
        reuseCell.displayId = item.id
        reuseCell.bg_item2:removeAllChildren()
        local cellSize = reuseCell:getContentSize()
        GameUI.addItemIcon(reuseCell.bg_item2, item.resMode, item.resID, cellSize[2]/200,cellSize[1]/2, cellSize[2]/2, true, false)
        GameUI.registerTipsAction(reuseCell, self.view, item.resMode,  item.resID)
    end
    reuseCell.lab_itemNum2:setString(N2S(item.resNum))
    return reuseCell
end



--倒计时的控制
function zhiyuan:update()
    if not self.context then
        return
    end
    local num = self.context:getProperty(const.ProOnlineCount) --次数
    self.receiveNum = num
    local getTime = self.context:getProperty(const.ProOnlineTime) --时间

    --计算跨天
    local stime = GameLogic.getSTime()
    if math.floor((stime-const.InitTime)/86400) > math.floor((getTime-const.InitTime)/86400) then
        num = 0
        getTime = 0
        self.context:setProperty(const.ProOnlineCount, 0)
        self.context:setProperty(const.ProOnlineTime, stime)
        self.btn_receive:setVisible(true)
        self.lab_receive:setVisible(true)
    end

    local allDatas = SData.getData("olrwdt")
    local state = 0
    if num < #allDatas then
        local dtime = GameLogic.getSTime() - getTime
        local ntime = allDatas[num+1].time
        if ntime - dtime <= 0 then
            state = 1
        else
            state = 0
        end
        self.rtime = ntime-dtime
    else
        state = 0
        self.rtime = nil
        self.btn_receive:setVisible(false)
    end
    if self.state ~= state then
        self.state = state
        if state == 1 then
            self.btn_receive:setEnable(true)
            self.btn_receive:setGray(false)
            self.lab_nextReceiveTime:setVisible(false)
        else
            self.btn_receive:setEnable(false)
            self.btn_receive:setGray(true)
        end
    end
    if self.rtime and self.rtime > 0 then
        self.lab_nextReceiveTime:setVisible(true)
        self.lab_nextReceiveTime:setString(Localizef("nextReceiveTime", {time=Localizet(self.rtime)}))
    else
        self.lab_nextReceiveTime:setVisible(false)
    end
    self:finRewardStrSet()
end

function zhiyuan:onlinerewards()
    if not GameNetwork.lockRequest() then
        return
    end
    local context = self.context
    GameNetwork.request("onlinerewards",{},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            GameLogic.addRewards(data)
            GameLogic.statCrystalRewards("在线奖励",data)
            GameLogic.showGet(data,nil,false,false)
            context:changeProperty(const.ProOnlineCount,1)
            context:setProperty(const.ProOnlineTime,GameLogic.getTime())
            if not self.deleted then
                self:CurReward()
                self:update()
            end
        end
    end)
end

return zhiyuan

