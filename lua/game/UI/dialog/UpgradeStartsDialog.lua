--英雄升星对话框
local UpgradeStartsDialog = class2("UpgradeStartsDialog",function()
    return BaseView.new("UpgradeStartsDialog.json")
end)

function UpgradeStartsDialog:ctor(parmas)
    self.parmas=parmas
   	self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function UpgradeStartsDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:loadView("allViews")
    local infos=self.parmas
    viewTab.hpOld:setString(infos.oldHp)
    viewTab.hpNew:setString(infos.newHp)
    viewTab.dpsOld:setString(infos.oldDps)
    viewTab.dpsNew:setString(infos.newDps)
    viewTab.maxLvOld:setString(infos.oldMaxLv)
    viewTab.maxLvNew:setString(infos.newMaxLv)
    self:initUpViews()
end

function UpgradeStartsDialog:initUpViews()
    local infos=self.parmas
    local hid=infos.hid
    GameUI.addHeadIcon(self, hid, 1, 388, 647)
    GameUI.addHeadIcon(self, hid, 1, 838, 647)
    local temp
    local startsNum=infos.maxStar
    local oldMaxNum=infos.oldStar
    local newMaxNum=infos.newStar
    local ox=math.floor((12-startsNum)/4)*50
    for i=1,startsNum do
        local k=i
        local oy=0
        if i>startsNum/2 then
            k=i-startsNum/2
            oy=52
        end
        temp = ui.sprite("images/heroStarIcon.png",{38, 54})
        display.adapt(temp, 251+ox+(k-1)*50, 463-oy, GConst.Anchor.LeftBottom)
        self:addChild(temp)
        if i>oldMaxNum then
            temp:setSValue(-100)
        end
    end
    for i=1,startsNum do
        local k=i
        local oy=0
        if i>startsNum/2 then
            k=i-startsNum/2
            oy=52
        end
        temp = ui.sprite("images/heroStarIcon.png",{38, 54})
        display.adapt(temp, 699+ox+(k-1)*50, 463-oy, GConst.Anchor.LeftBottom)
        self:addChild(temp)
        if i>newMaxNum then
            temp:setSValue(-100)
        end
    end
end

return UpgradeStartsDialog