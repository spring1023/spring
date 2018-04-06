
local RewardPreview = class(DialogViewLayout)
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

function RewardPreview:onInitDialog()
    self.context = GameLogic.getUserContext()
    self:initUI()
end

function RewardPreview:initUI()
    self:setLayout("DailyActiveReward.json")
    self:loadViewsTo()
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    if self.boxState == 1 then
        self.btn_receive:setEnable(false)
        self.btn_receive:setGray(true)
    else
        self.btn_receive:setEnable(true)
        self.btn_receive:setGray(false)
    end
    self.btn_receive:setScriptCallback(ButtonHandler(self.OnRecieveClick, self))
    self.lab_supportReward:setString(Localize("titleGetRewards"))
    self.lab_receive:setString(Localize("labelRecive"))
    ViewTemplates.setImplements(self.bottom, "LayoutImplement", {callback=Handler(self.onUpdateItemsCell1, self), withIdx=false})--当前奖励
    self:initData()
end

function RewardPreview:initData()
    self:boxReward()
end

function RewardPreview:OnRecieveClick()
    local context = GameLogic.getUserContext()
    local achData = context:getAchsData()[self.boxType+1]
    local sdata = SData.getData("activerwds", self.boxType+1, self.boxIndex)
    if bit.band(achData[5], bit.lshift(1, self.boxIndex-1)) > 0 then
        return
    elseif achData[3] < sdata.active then
        display.pushNotice(Localizef("actRwdsSpanDay"))
        display.closeDialog(self.priority)
    end
    local rwds = sdata.rwds
    GameLogic.addRewards(rwds)
    for i,v in ipairs(rwds) do
        display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(v[1],v[2]) .. "x" .. v[3]}))
    end
    local stime = GameLogic.getSTime()
    achData[5] = bit.bor(achData[5], bit.lshift(1, self.boxIndex-1))
    self.context:addCmd({const.CmdGetAchNumReward, self.boxIndex, self.boxType, stime})
    GameEvent.sendEvent("refreshAfterReceive")
    -- self.btn_receive:setEnable(false)
    -- self.btn_receive:setGray(true)
    display.closeDialog(self.priority)
end

function RewardPreview:boxReward()--当前奖励
    local boxReward = {}
    local rwds = SData.getData("activerwds", self.boxType+1, self.boxIndex).rwds
    for i,v in ipairs(rwds) do
        table.insert(boxReward, {id = i, resMode = v[1], resID = v[2], resNum = v[3]})
    end
    self.bottom:setLayoutDatas(boxReward)
end

function RewardPreview:onUpdateItemsCell1(reuseCell, layout, item)
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
    reuseCell.cell_desc:setString(N2S(item.resNum))
    return reuseCell
end

return RewardPreview