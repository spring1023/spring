local GuideHand = class()

function GuideHand:ctor()
	self.configs = GMethod.loadConfig("configs/ui/dialogViewsConfig/GuideHand.json")
    self.handArr = {}
end

function GuideHand:createArrow()
    local bg = ui.sprite("images/guideArrow1.png")
    bg:setAnchorPoint(0.5,0)
    bg:runAction(ui.action.arepeat(ui.action.sequence({
        {"easeSineIO", {"scaleTo", 0.42, 1, 0.75}},
        {"easeSineIO", {"scaleTo", 0.33, 1, 1}},
        {"spawn", {{"scaleTo", 0.42, 1, 1.15}, {"moveBy", 0.42, 0, 38}}},
        {"spawn", {{"scaleTo", 0.25, 1, 1.1}, {"moveBy", 0.25, 0, 8}}},
        {"spawn", {{"scaleTo", 0.25, 1, 1}, {"moveBy", 0.25, 0, -46}}}
    })))
    bg:setGlobalZOrder(10)
    for i=1, 2 do
        local temp = ui.sprite("images/guideArrow2.png")
        ui.setColor(temp, {255, 73, 0})
        ui.setBlend(temp, 1, 1)
        display.adapt(temp, 0, 0)
        bg:addChild(temp)
        temp:setOpacity(0)
        temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeIn", 0.42}, {"fadeOut", 0.33}, {"delay", 0.92}})))
        temp:setGlobalZOrder(11)
    end
    return bg
end

function GuideHand:showArrow(bg,x,y,z,key)
    if GEngine.rawConfig.DEBUG_BATTLE then
        return
    end
    local tbg = ui.node()
	local temp= self:createArrow()
    temp:setPosition(0, 0)
    tbg:addChild(temp)
	tbg:setPosition(x,y)
	bg:addChild(tbg,z or 0)
    tbg.keyrem = 1
    if key then
        self.handArr[key] = tbg
    else
        self.hand = tbg
    end
    return tbg
end
function GuideHand:showHandBig(bg,z,key)
    if GEngine.rawConfig.DEBUG_BATTLE then
        return
    end
	local hand=ui.sprite("images/guideHandBig.png", {531,555})
	hand:setAnchorPoint(0.06,0.94)

    hand.keyrem = 1
    if key then
        self.handArr[key] = hand
    else
        self.hand = hand
    end
    local positions={}
    if key == "putHero" then
        positions = GMethod.loadConfig("configs/settings.json").guidePoint1
    else
        positions = GMethod.loadConfig("configs/settings.json").guidePoint2
    end
    hand:setPosition(positions[1][1], positions[1][2])
    bg:addChild(hand,(z or 0)+10)
    local index = 1
    local function setPos()
        local x,y=positions[index][1],positions[index][2]
        local temp
        temp=ui.sprite("images/guangquan2.png")
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(x,y)
        bg:addChild(temp,z or 0)
        temp:setScaleX(1)
        temp:setScaleY(0.75)
        temp:setOpacity(0.8*255)
        temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",20/60,1.2,0.9}}))
        temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",20/60,0},"remove"}))
        temp=ui.sprite("images/guangquan2.png")
        temp:setAnchorPoint(0.5, 0.5)
        temp:setPosition(x,y)
        bg:addChild(temp,z or 0)
        temp:setScaleX(0.6)
        temp:setScaleY(0.45)
        temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",20/60,0.8,0.6}}))
        temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",20/60,0},"remove"}))
        temp=ui.sprite("images/guangquan2.png")
        temp:setAnchorPoint(0.5,0.5)
        temp:setPosition(x,y)
        bg:addChild(temp,z or 0)
        temp:setScaleX(0.3)
        temp:setScaleY(0.2)
        temp:runAction(ui.action.sequence({{"delay",5/60},{"scaleTo",20/60,0.38,0.28}}))
        temp:runAction(ui.action.sequence({{"delay",5/60},{"fadeTo",20/60,0},"remove"}))
    end
    local function movePos()
        index = index%(#positions) + 1
        local x,y=positions[index][1],positions[index][2]
        hand:runAction(ui.action.moveTo(0.3,x,y))
    end
    hand:runAction(ui.action.arepeat(ui.action.sequence({{"call",setPos},"show",{"scaleTo",10/60,0.9,0.9},{"scaleTo",6/60,1,1}, {"call", movePos}, {"delay",0.3}})))
	return hand
end
function GuideHand:showHandSmall(bg,x,y,z,key)
    if GEngine.rawConfig.DEBUG_BATTLE then
        return
    end

	local temp=ui.sprite("images/guideHandSmall.png", {100,109})
	temp:setAnchorPoint(0,1)
	temp:setPosition(x,y)
	bg:addChild(temp,z or 0)
    temp.keyrem = 1
    if key then
        self.handArr[key] = temp
    else
        self.hand = temp
    end
    --temp:runAction(ui.action.arepeat(ui.action.easeSineIn(ui.action.sequence({{"moveBy",0.3,0,30},{"moveBy",0.3,0,-30}}))))
	temp:runAction(ui.action.arepeat(ui.action.sequence({{"scaleTo",10/60,0.9,0.9},{"scaleTo",6/60,1,1}})))
    

    return temp
end

function GuideHand:removeHand(key)
    if GEngine.rawConfig.DEBUG_BATTLE then
        return
    end
    if key then
        if self.handArr[key] then
            if self.handArr[key].keyrem then
                self.handArr[key]:removeFromParent(true)
            end
            self.handArr[key] = nil
        end
    else
        if self.hand then
            if self.hand.keyrem then
                self.hand:removeFromParent(true)
            end
            self.hand = nil
        end
    end
end


return GuideHand
