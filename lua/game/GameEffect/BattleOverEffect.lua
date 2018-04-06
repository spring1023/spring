--战斗结束特效
BattleOverEffect= class2("BattleOverEffect",function()
    return ui.node()
end)
function BattleOverEffect:ctor(vdMode,params)
	self.params = params
	if vdMode then
		self:showVictory()
	else
		self:showDefeat()
	end
end

function BattleOverEffect:showVictory()
	local temp
	temp = ui.sprite("images/victoryLine.png")
	temp:setPosition(0, 0)
	temp:setAnchorPoint(0.5,0.53)
	self:addChild(temp)
	local blend = {}
    blend.src = 772
    blend.dst = 1
    temp:setBlendFunc(blend)
    temp:setOpacity(0)
    temp:runAction(ui.action.fadeIn(0.5))
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(0.5,90)))

	--1034,1174
	local bg=ui.node({0,0},{255,255,255})
	display.adapt(bg, 0, 0, GConst.Anchor.Center)
	self:addChild(bg,2)
	bg:setScaleX(-0.1)
	bg:setScaleY(0.5)
	bg:setOpacity(0)
	bg:runAction(ui.action.scaleTo(0.5,1,1))
	bg:runAction(ui.action.fadeIn(0.5))

	temp = ui.sprite("images/dunpai1.png",{321, 387})
	display.adapt(temp, 0, 0, GConst.Anchor.Center)
	bg:addChild(temp)
	temp = ui.sprite("images/VICTORY.png",{423*1.16, 152*1.16})
	display.adapt(temp, 0, 149+30, GConst.Anchor.Center)
	bg:addChild(temp)
	temp = ui.sprite("images/piaodai1.png",{666, 126})
	display.adapt(temp, 0, -94, GConst.Anchor.Center)
	bg:addChild(temp)
	temp = ui.sprite("images/battleStar2.png",{75, 74})
	display.adapt(temp, -134, -127, GConst.Anchor.LeftBottom)
	bg:addChild(temp)
	temp = ui.sprite("images/battleStar2.png",{74, 74})
	display.adapt(temp, -38, -134, GConst.Anchor.LeftBottom)
	bg:addChild(temp)
	temp = ui.sprite("images/battleStar2.png",{75, 74})
	display.adapt(temp, 56, -127, GConst.Anchor.LeftBottom)
	bg:addChild(temp)

	temp = ui.label(StringManager.getString("战果:"), General.font1, 46, {color={255,255,255}})
	display.adapt(temp, 0, 100, GConst.Anchor.Top)
	bg:addChild(temp)

	temp = ui.label(StringManager.getString("100%"), General.font1, 73, {color={140,203,90}})
	display.adapt(temp, 0, 4, GConst.Anchor.Center)
	bg:addChild(temp)

	--战果星星
	local xinPos={{-97,-91},{0,-98},{93,-91}}
	local starNum = self.params and self.params.star or 3
	for i,pos in ipairs(xinPos) do
		if i<= starNum then
			temp = ui.sprite("images/battleStar1.png",{67, 67})
			display.adapt(temp,pos[1],pos[2],GConst.Anchor.Center)
			bg:addChild(temp,2)
		end
	end
	
	local chibang1 = ui.sprite("images/chibang1.png",{282, 262})
	chibang1:setPosition(-117,36)
	chibang1:setAnchorPoint(1,0.3)
	self:addChild(chibang1,1)
	chibang1:setRotation(-90)
	chibang1:setScale(0.3)
	chibang1:setOpacity(0)
	local function callArep()
		chibang1:runAction(ui.action.arepeat(ui.action.sequence({{"rotateBy",0.5,5},{"rotateBy",1,-15},{"rotateBy",0.5,10}})))	
	end
	chibang1:runAction(ui.action.sequence({{"delay",20/60},{"rotateBy",20/60,90},{"call",callArep}}))
	chibang1:runAction(ui.action.sequence({{"delay",20/60},{"scaleTo",20/60,1,1}}))
	chibang1:runAction(ui.action.sequence({{"delay",20/60},{"fadeIn",10/60}}))

	local chibang2 = ui.sprite("images/chibang1.png",{282, 262})
	chibang2:setFlippedX(true)
	chibang2:setPosition(117,36)
	chibang2:setAnchorPoint(0,0.3)
	self:addChild(chibang2,1)
	chibang2:setRotation(90)
	chibang2:setScale(0.3)
	chibang2:setOpacity(0)
	local function callArep()
		chibang2:runAction(ui.action.arepeat(ui.action.sequence({{"rotateBy",0.5,-5},{"rotateBy",1,15},{"rotateBy",0.5,-10}})))
	end
	chibang2:runAction(ui.action.sequence({{"delay",20/60},{"rotateBy",20/60,-90},{"call",callArep}}))
	chibang2:runAction(ui.action.sequence({{"delay",20/60},{"scaleTo",20/60,1,1}}))
	chibang2:runAction(ui.action.sequence({{"delay",20/60},{"fadeIn",10/60}}))
	local function showPar()
		local parPos={{0,140,1.5},{-337,90,2},{296,24,1.5},{-498,-50,1}}
		for i,pos in ipairs(parPos) do
		  local p = ui.particle("particles/battleResultEffect2.json")
          p:setPosition(pos[1],pos[2])
          p:setScale(pos[3])
	      p:setPositionType(cc.POSITION_TYPE_GROUPED)
		  p:setAutoRemoveOnFinish(true)
          self:addChild(p,3)
		end
	end
	bg:runAction(ui.action.sequence({{"delay",20/60},{"call",showPar}}))
end

function BattleOverEffect:showDefeat()
	local temp

	local bg=ui.node({0,0},{255,255,255})
	display.adapt(bg, 0, 0, GConst.Anchor.Center)
	self:addChild(bg,2)
	local chibang1 = ui.sprite("images/chibang2.png",{282, 262})
	chibang1:setPosition(-117,40)
	chibang1:setAnchorPoint(1,0.3)
	bg:addChild(chibang1)

	local chibang2 = ui.sprite("images/chibang2.png",{282, 262})
	chibang2:setFlippedX(true)
	chibang2:setPosition(117,40)
	chibang2:setAnchorPoint(0,0.3)
	bg:addChild(chibang2)

	temp = ui.sprite("images/dunpai2.png",{321, 387})
	display.adapt(temp, 0, 0, GConst.Anchor.Center)
	bg:addChild(temp)

	temp = ui.sprite("images/piaodai2.png",{666, 126})
	display.adapt(temp, 0, -94, GConst.Anchor.Center)
	bg:addChild(temp)
	temp = ui.sprite("images/battleStar2.png",{75, 74})
	display.adapt(temp, -134, -127, GConst.Anchor.LeftBottom)
	bg:addChild(temp)
	temp = ui.sprite("images/battleStar2.png",{74, 74})
	display.adapt(temp, -38, -134, GConst.Anchor.LeftBottom)
	bg:addChild(temp)
	temp = ui.sprite("images/battleStar2.png",{75, 74})
	display.adapt(temp, 56, -127, GConst.Anchor.LeftBottom)
	bg:addChild(temp)

	temp = ui.label(StringManager.getString("战果:"), General.font1, 46, {color={255,255,255}})
	display.adapt(temp, 0, 100, GConst.Anchor.Top)
	bg:addChild(temp)

	temp = ui.label(StringManager.getString("0%"), General.font1, 73, {color={140,203,90}})
	display.adapt(temp, 0, 4, GConst.Anchor.Center)
	bg:addChild(temp)

	--战果星星
	local xinPos={{-97,-91},{0,-98},{93,-91}}
	for i,pos in ipairs(xinPos) do
		if i<=0 then
			temp = ui.sprite("images/battleStar1.png",{67, 67})
			display.adapt(temp,pos[1],pos[2],GConst.Anchor.Center)
			bg:addChild(temp,2)
		end
	end
	local function showPar()
		local parPos1={{1,32},{0.6,7},{1,-11},{1,56}}
		local parPos2={{1,144},{0.6,119},{1,102},{1,169}}
		for i,pos in ipairs(parPos1) do
		  local p = ui.particle("particles/battleResultEffect1.json")
          p:setPosition(154,110)
          p:setScale(pos[1])
          p:setRotation(pos[2])
	      p:setPositionType(cc.POSITION_TYPE_GROUPED)
		  p:setAutoRemoveOnFinish(true)
          self:addChild(p,3)
		end
		for i,pos in ipairs(parPos2) do
		  local p = ui.particle("particles/battleResultEffect1.json")
          p:setPosition(-154,110)
          p:setScale(pos[1])
          p:setRotation(pos[2])
	      p:setPositionType(cc.POSITION_TYPE_GROUPED)
		  p:setAutoRemoveOnFinish(true)
          self:addChild(p,3)
		end
	end
	
	local function delayD(  )
		temp = ui.sprite("images/DEFEAT.png",{423*1.16, 152*1.16})
		display.adapt(temp, 12, 195+100, GConst.Anchor.Center)
		self:addChild(temp,2)
		temp:setScale(2)
		temp:setOpacity(0)
		temp:runAction(ui.action.moveBy(20/60,0,-100))
		temp:runAction(ui.action.fadeIn(20/60))
		temp:runAction(ui.action.sequence({{"scaleTo",25/60,0.8,0.8},{"scaleTo",3/60,1,1}}))

		bg:runAction(ui.action.sequence({{"delay",20/60},{"call",showPar}}))
	end 
	bg:runAction(ui.action.sequence({{"delay",0.3},{"call",delayD}}))

	local p = ui.particle("particles/battleResultEffect3.json")
    p:setPosition(0,0)
    p:setScale(3)
	p:setPositionType(cc.POSITION_TYPE_GROUPED)
    self:addChild(p)
    local blend = {}
    blend.src = 770
    blend.dst = 1
    temp:setBlendFunc(blend)
end
