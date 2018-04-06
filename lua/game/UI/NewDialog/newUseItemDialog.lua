local SData = GMethod.loadScript("data.StaticData")

local newUseItemDialog = class(DialogViewLayout)

local sliderSize = {146, 97}
local scrollArea = {950, 97}

function newUseItemDialog:onInitDialog()
    self:setLayout("bag_useItem_dialog.json")
    self:loadViewsTo()
    self:createScorll()
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.btnSure:setScriptCallback(ButtonHandler(self.onSure, self))
    self.btnReduce:setScriptCallback(ButtonHandler(self.onMinusNum, self))
    self.btnAdd:setScriptCallback(ButtonHandler(self.onAddNum, self))
    self.btnAdd.view:setAutoHoldTime(0.5)
    self.btnAdd.view:setAutoHoldTimeTemp(0.1)
    self.btnReduce.view:setAutoHoldTime(0.5)
    self.btnReduce.view:setAutoHoldTimeTemp(0.1)
end

function newUseItemDialog:onEnter()
    local mode = self.mode
    self.nodeItemBack:removeAllChildren(true)
    local cellSize = self.nodeItemBack.size
    GameUI.addItemIcon(self.nodeItemBack.view, self.itemtype, self.itemid, 1, cellSize[1]/2, cellSize[2]/2, true)
    self.labelItemName:setString(GameLogic.getItemName(self.itemtype, self.itemid))
    self.lb_itemNum1:setString(Localize("labelCurrent")..N2S(self.itemnum))
    self.lb_itemDesc:setString(GameLogic.getItemDesc(self.itemtype, self.itemid))
    if mode then
        if mode==-1 then
            self.labelSureWord:setString(Localize("btnGive"))
        else
            self.labelSureWord:setString(Localize("btnUseItem"))
        end
    else
        self.labelSureWord:setString(Localize("wordSell"))
    end
        -- 引导
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "upgradeHero" and context.guide:getStep().type ~= "finish" then
        local btnUse = context.guideHand:showArrow(self.btnSure,130,10,100)
        btnUse:setScaleY(-1)
        local addNum = context.guideHand:showArrow(self.btnAdd,50,10,100,"addNum")
        addNum:setScaleY(-1)
        self.btnUse = btnUse
        self.addNum = addNum
    end
    self:changeUseNum(self.num or 1)
end

function newUseItemDialog:onMinusNum()
    if self.num and self.num>(self.minNum or 1) then
        self:changeUseNum(self.num-1)
    end
end

function newUseItemDialog:onAddNum()
    if self.num and self.num<self.itemnum then
        self:changeUseNum(self.num+1)
    end
end

function newUseItemDialog:changeUseNum(num,isScorll)
    if self.btnUse and self.addNum then
        if num<=0 then
            self.btnUse:setVisible(false)
            self.addNum:setVisible(true)
        else
            self.btnUse:setVisible(true)
            self.addNum:setVisible(false)
        end
    end
    self.num = num
    self.labelUseItemNum:setString("X"..tostring(num))
    local pro = self.num/self.itemnum
    if pro < 0 then
        pro = 0
    elseif pro > 1 then
        pro = 1
    end
    self.img_progress_number:setProcess(true, pro)
    self.btnScorllView:setPositionX(pro*(scrollArea[1]-sliderSize[1]))
    local mode = self.mode
    if mode then
        if mode>0 and mode < 14 or mode == const.ItemChip then
            self.labelItemTotalResult:setString(Localizef("labelPriceFormat2",{num=self.price*num, name=GameLogic.getItemName(mode)}))
        elseif mode==const.ItemWelfare then
            self.labelItemTotalResult:setString(Localizef("labelPriceFormat3",{num=self.price*num, name=GameLogic.getItemName(mode)}))
        end
    else
        self.labelItemTotalResult:setString(Localizef("labelPriceFormat1",{num=self.price*num, name=GameLogic.getItemName(const.ResGold)}))
    end
end

function newUseItemDialog:onSure(force)
    if not self.lock then
        self.lock = true
        if not self.mode or self.mode==const.ResGold then
            if self.price*self.num+self.context:getRes(const.ResGold)>self.context:getResMax(const.ResGold) and not force then
                self.lock = nil
                display.showDialog(AlertDialog.new(3, Localize("alertTitleGoldMax"), Localize("alertTextGoldMax"), {callback=Handler(self.onSure, self, true)}))
                return
            end
        end
    else
        return
    end
    if self.onSureCallback then
        if self.onSureCallback(self.num, self) then
            display.closeDialog(0)
        end
    end
end

function newUseItemDialog:onDelaySure(success)
    if not self.deleted and self.lock then
        if success then
            display.closeDialog(0)
        else
            self.lock = nil
        end
    end
end

function newUseItemDialog:createScorll()
    local scrollNode=ui.scrollNode({scrollArea[1],scrollArea[2]}, 0, true, false)
    display.adapt(scrollNode, 190, 340, GConst.Anchor.LeftBottom)
    self.view:addChild(scrollNode)
    scrollNode:setScrollContentRect(cc.rect(-scrollArea[1],scrollArea[2],scrollArea[1],scrollArea[2]))
    scrollNode:setScriptHandler(Script.createCObjectHandler(self))
    self.scrollNode = scrollNode
    local btnS=ui.sprite("bt/btn_slide.png",{sliderSize[1], sliderSize[2]})
    display.adapt(btnS, 0, 42, GConst.Anchor.Left)
    scrollNode:getScrollNode():addChild(btnS)
    self.btnScorllView=btnS
end

function newUseItemDialog:onEvent(event, etype, x, y)
    if event=="single" then
        if etype == "begin" then
            self.scrollNode:setSingleTouchState(1)
            self.touchX = x
        elseif etype == "move" then
            x = self.touchX + x
        -- elseif etype == "end" then
        --     self.scrollNode:setSingleTouchState(1)
        end
        if x < sliderSize[1]/2 then
            x = sliderSize[1]/2
        elseif x > scrollArea[1] - sliderSize[1]/2 then
            x = scrollArea[1] - sliderSize[1]/2
        end
        -- self.btnScorllView:setPositionX(x-sliderSize[1]/2)
        local minNum = self.minNum or 1
        local num = math.floor(minNum + (x-sliderSize[1]/2)*(self.itemnum-minNum)/(scrollArea[1]-sliderSize[1]))
        if num ~= self.num then
            self:changeUseNum(num, true)
        end
    end
end

return newUseItemDialog