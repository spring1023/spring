local ShowHeroMainDialog = GMethod.loadScript("game.Dialog.ShowHeroMainDialog")

local HeroExtractNewTabAction= class()

function HeroExtractNewTabAction:ctor(params)
    self.priority = display.getDialogPri()+1
    local bg = ui.touchNode({2048,1536}, 0, true)
    display.adapt(bg, 0, 0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})
    self.view =bg
    self.params = params
    self.rtype = params.rtype
    self:onInitDialog()
end

function HeroExtractNewTabAction:onInitDialog()
    display.showDialog(self,false,true)
    local hnum = #self.params.heros.heros
    if self.rtype==6 or self.rtype==7 then
        self:showGetHeros4()
    elseif hnum==1 then
        self:showGetHeros()
    elseif hnum==6 then
        self:showGetHeros3()
    else
        self:showGetHeros2()
    end
end

function HeroExtractNewTabAction:showGetHeros()
    local node,action
    local addHeroLayer = function ()
    	display.closeDialog(self.priority)
        ShowHeroDialog.new({params=self.params})
    end
    node = ui.csbNode("UICsb/c_0.csb")
    display.adapt(node,347,770,GConst.Anchor.Center)
    ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),-5,10,1)
    self.view:addChild(node,1000)
    action = ui.csbTimeLine("UICsb/c_0.csb")
    node:runAction(action)
    action:gotoFrameAndPlay(0,false)
    action:setFrameEventCallFunc(function(frame)
        if frame:getEvent() == "addLayer" then
            addHeroLayer()
        elseif frame:getEvent() == "remove" then
            node:removeFromParent(true)
        end
    end)
end

function HeroExtractNewTabAction:showGetHeros2()
    local node,action

    local addHeroLayer = function ()
    	display.closeDialog(self.priority)
        ShowHeroDialog.new({params=self.params})
    end
    node = ui.csbNode("UICsb/b_0.csb")
    display.adapt(node,1002,791,GConst.Anchor.Center)
    ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),17,16,2)
    self.view:addChild(node,1000)
    action = ui.csbTimeLine("UICsb/b_0.csb")
    node:runAction(action)
    action:gotoFrameAndPlay(0,false)
    action:setFrameEventCallFunc(function(frame)
        if frame:getEvent() == "addLayer" then
            addHeroLayer()
            node:removeFromParent(true)
        end
    end)
end

function HeroExtractNewTabAction:showGetHeros3()
    local node,action

    local addHeroLayer = function ()
    	display.closeDialog(self.priority)
        ShowHeroDialog.new({params=self.params})
    end

    local action2 = function ()
        node = ui.csbNode("UICsb/a_3.csb")
        display.adapt(node,1002,764,GConst.Anchor.Center)
        ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),72-51,57-5,3)
        self.view:addChild(node,1000)
        action = ui.csbTimeLine("UICsb/a_3.csb")
        node:runAction(action)
        action:gotoFrameAndPlay(10,75,false)
        action:setFrameEventCallFunc(function(frame)
            if frame:getEvent() == "action2" then
                node:removeFromParent(true)
            elseif frame:getEvent() == "addHeroLayer" then
                addHeroLayer()
            end
        end)
    end

    node = ui.csbNode("UICsb/a_0.csb")
    display.adapt(node,1002,764,GConst.Anchor.Center)
    ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),72-51,57-5,3)
    node:getChildByName("Men_9_1"):setVisible(false)
    self.view:addChild(node,1000)
    action = ui.csbTimeLine("UICsb/a_0.csb")
    node:runAction(action)
    action:gotoFrameAndPlay(0,81,false)
    action:setFrameEventCallFunc(function(frame)
        node:removeFromParent(true)
        if frame:getEvent() == "action1" then
            action2()
        end
    end)
end

function HeroExtractNewTabAction:showGetHeros4()
    local node,action

    local addHeroLayer = function ()
    	display.closeDialog(self.priority)
        ShowHeroDialog.new({params=self.params})
    end

    local action2 = function ()
        node = ui.csbNode("UICsb/a_3.csb")
        display.adapt(node,347,764,GConst.Anchor.Center)
        ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),72-51,57-5,4)
        self.view:addChild(node,1000)
        action = ui.csbTimeLine("UICsb/a_3.csb")
        node:runAction(action)
        action:gotoFrameAndPlay(10,75,false)
        action:setFrameEventCallFunc(function(frame)
            if frame:getEvent() == "action2" then
                node:removeFromParent(true)
            elseif frame:getEvent() == "addHeroLayer" then
                addHeroLayer()
            end
        end)
    end

    node = ui.csbNode("UICsb/a_0.csb")
    display.adapt(node,347,764,GConst.Anchor.Center)
    ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),72-51,57-5,4)
    node:getChildByName("Men_9_1"):setVisible(false)
    self.view:addChild(node,1000)
    action = ui.csbTimeLine("UICsb/a_0.csb")
    node:runAction(action)
    action:gotoFrameAndPlay(0,81,false)
    action:setFrameEventCallFunc(function(frame)
        node:removeFromParent(true)
        if frame:getEvent() == "action1" then
            action2()
        end
    end)
end
return HeroExtractNewTabAction