--关注FACEBOOK对话框
local FacebookDialog = class2("FacebookDialog",function()
    return BaseView.new("FacebookDialog.json",true)
end)

function FacebookDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    GameLogic.addStatLog(12001, 1, 0, 0)
    self:initUI()
    display.showDialog(self)
end

function FacebookDialog:initUI()
    self:loadView("backAndupViews")
    self:loadView("downViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(ButtonHandler(display.closeDialog,self.priority))

    self:showUpViews()
    viewTab.butFollow:setScriptCallback(ButtonHandler(GameLogic.doFollowAction))
end

function FacebookDialog:showUpViews()
	local scNode=ScrollNode:create(cc.size(1770,940), 0, false, true)
    scNode:setScrollEnable(true)
    scNode:setInertia(true)
    scNode:setElastic(true)
    scNode:setClip(true)
    scNode:setScaleEnable(true, 1, 1, 1, 1)
    display.adapt(scNode, 78, 208, GConst.Anchor.LeftBottom)
    self:addChild(scNode)

    local bg=scNode:getScrollNode()

	local oy=0
	local temp
	for i=1,4 do
		temp=ui.label(StringManager.getString("labelFacebook"..i), General.font1, 55, {color={249,234,0}})
        display.adapt(temp, 7, 935-oy, GConst.Anchor.LeftTop)
        bg:addChild(temp)
        oy=oy+20+temp:getContentSize().height
        temp=ui.label(StringManager.getString("labelFacebook"..i.."_des"), General.font2, 40, {color={0,0,0},width = 1700, align=GConst.Align.Left})
        display.adapt(temp, 53, 935-oy, GConst.Anchor.LeftTop)
        bg:addChild(temp)
        oy=oy+20+temp:getContentSize().height
        temp = ui.sprite("images/facebook"..i..".png", {1751,483})
        display.adapt(temp, 26, 935-oy, GConst.Anchor.LeftTop)
        bg:addChild(temp)
        oy=oy+40+483
	end

	scNode:setScrollContentRect(cc.rect(0,940-oy,0,oy))
end
return FacebookDialog
