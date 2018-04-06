
--战斗回放界面
local playbackInterface = class2("playbackInterface",function()
    return BaseView.new("playbackInterface.json")
end)

function playbackInterface:ctor()
    local scene = GMethod.loadScript("game.View.Scene")
    self.scene = scene
    scene.view:addChild(self)
    local menu = scene.menu
    menu.view:setVisible(false)
    self:initUI()
end
function playbackInterface:initNode()
    local bg,temp
    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.LeftTop, {datum = GConst.Anchor.LeftTop,scale=ui.getUIScale2()})
    self:addChild(bg,1)
    temp=ui.node()
    display.adapt(temp, 0, -1536, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    self.LeftTopNode=temp

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.Top, {datum = GConst.Anchor.Top,scale=ui.getUIScale2()})
    self:addChild(bg,1)
    temp=ui.node()
    display.adapt(temp, -1024, -1536, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    self.TopNode=temp

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.RightTop, {datum = GConst.Anchor.RightTop,scale=ui.getUIScale2()})
    self:addChild(bg,1)
    temp=ui.node()
    display.adapt(temp, -2048, -1536, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    self.RightTopNode=temp

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.LeftBottom, {datum = GConst.Anchor.LeftBottom,scale=ui.getUIScale2()})
    self:addChild(bg,1)
    temp=ui.node()
    display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    self.LeftBottomNode=temp

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.RightBottom, {datum = GConst.Anchor.RightBottom,scale=ui.getUIScale2()})
    self:addChild(bg,1)
    temp=ui.node()
    display.adapt(temp, -2048, 0, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    self.RightBottomNode=temp
end
function playbackInterface:initUI()
    self:initNode()
    
    self:loadView("LeftTopViews",self.LeftTopNode)
    self:loadView("TopViews",self.TopNode)
    self:loadView("RightTopViews",self.RightTopNode)
    self:loadView("LeftBottomViews",self.LeftBottomNode)
    self:loadView("RightBottomViews",self.RightBottomNode)
    local viewTab = self:getViewTab()
    self:insertViewTo()
    self.rateNum = 1
    self.butRateValue:setString("X" .. self.rateNum)
    self.butRate:setListener(function()
        if self.rateNum<4 then
            self.rateNum = self.rateNum*2
        else
            self.rateNum = 1
        end
        GameLogic.setSchedulerScale(self.rateNum)
        self.butRateValue:setString("X" .. self.rateNum)
    end)
    if self.scene.battleType ~= const.BattleTypePvp then
        self:replayViews()
    end
end

function playbackInterface:replayViews()
    local scene=self.scene
    local menu = scene.menu
    menu.view:setVisible(true)
    local battle =menu.battle
    battle.nodeBattleBottom:setVisible(false)
    battle.nodeBattleTop:setVisible(false)
    battle.nodeBattleRB:setVisible(false)
    self.LeftTopNode:setVisible(false)
    self.RightTopNode:setVisible(false)
end

return playbackInterface
