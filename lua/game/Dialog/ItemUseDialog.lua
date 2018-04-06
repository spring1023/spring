local SData = GMethod.loadScript("data.StaticData")

ItemUseDialog = class(DialogViewLayout)

function ItemUseDialog:onInitDialog()
    self:setLayout("ItemUseDialog.json")
    if self.mode >= const.ItemNewBox and self.mode ~= const.ItemChip and self.mode~=const.ItemWelfare then
        self:addLayout("mode2")
    else
        self:addLayout("mode1")
    end
    self:loadViewsTo()
    self:createScorll()
    self.btnSure:setScriptCallback(ButtonHandler(self.onSure, self))
    self.btnReduce:setScriptCallback(ButtonHandler(self.onMinusNum, self))
    self.btnAdd:setScriptCallback(ButtonHandler(self.onAddNum, self))
    self.btnAdd.view:setAutoHoldTime(0.5)
    self.btnAdd.view:setAutoHoldTimeTemp(0.1)
    self.btnReduce.view:setAutoHoldTime(0.5)
    self.btnReduce.view:setAutoHoldTimeTemp(0.1)
end

function ItemUseDialog:onEnter()
    local mode = self.mode
    self.nodeItemBack:removeAllChildren(true)

    GameUI.addItemIcon(self.nodeItemBack.view, self.itemtype, self.itemid, 1, 0, 0, true)
    self.labelItemName:setString(GameLogic.getItemName(self.itemtype, self.itemid))
    if mode then
        if mode==-1 then
            self.title:setString(Localize("titleSureGive"))
            self.labelSureWord:setString(Localize("btnGive"))
            self.labelUseInfo:setString("")
            self.labelUseResult:setString("")
        elseif mode==const.ItemNewBox or mode==const.ItemSpringBox then
            self.title:setString(Localize("titleSureUse"))
            self.labelSureWord:setString(Localize("btnUseItem"))
            self.labelUseInfo:setString(GameLogic.getItemDesc(self.itemtype, self.itemid))
            -- self.labelUseInfo:setString(Localize("couldGetFromNewBox").. "\n" .. GameLogic.getItemsNameByGroup(self.itemtype, self.itemid))
        else
            self.title:setString(Localize("titleSureUse"))
            self.labelSureWord:setString(Localize("btnUseItem"))
            if mode==0 then
                self.labelUseInfo:setString("")
                self.labelUseResult:setString("")
            elseif mode==const.ItemWelfare then
                self.labelUseInfo:setString(Localize("labelSellPrice4"))
                self.labelUseResult:setString(Localizef("labelPriceFormat",{num=self.price, name=GameLogic.getItemName(mode)}))
            else
                self.labelUseInfo:setString(Localize("labelSellPrice2"))
                self.labelUseResult:setString(Localizef("labelPriceFormat",{num=self.price, name=GameLogic.getItemName(mode)}))
            end
        end
    else
        self.labelUseInfo:setString(Localize("labelSellPrice1"))
        self.labelUseResult:setString(Localizef("labelPriceFormat",{num=self.price, name=GameLogic.getItemName(const.ResGold)}))
        self.title:setString(Localize("titleSureSell"))
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

function ItemUseDialog:onMinusNum()
    if self.num and self.num>(self.minNum or 1) then
        self:changeUseNum(self.num-1)
    end
end

function ItemUseDialog:onAddNum()
    if self.num and self.num<self.itemnum then
        self:changeUseNum(self.num+1)
    end
end

function ItemUseDialog:changeUseNum(num,isScorll)
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
    self.labelUseItemNum:setString(tostring(num))
    self.labelItemNum:setString(tostring(num) .. "/" .. self.itemnum)
    if not isScorll then
        if self.itemnum < 1 then
            self.btnScorllView:setPositionX(0)
        else
            local minNum = self.minNum or 1
            self.btnScorllView:setPositionX((num-minNum)*(899-129)/(self.itemnum-minNum))
        end
    end
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

function ItemUseDialog:onSure(force)
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

function ItemUseDialog:onDelaySure(success)
    if not self.deleted and self.lock then
        if success then
            display.closeDialog(0)
        else
            self.lock = nil
        end
    end
end

function ItemUseDialog:createScorll()
    local scrollNode=ui.scrollNode({899,90}, 0, true, false)
    display.adapt(scrollNode, 249, 284, GConst.Anchor.LeftBottom)
    self.view:addChild(scrollNode)
    scrollNode:setScrollContentRect(cc.rect(-899+137-8,0,899,80))
    scrollNode:setScriptHandler(Script.createCObjectHandler(self))
    self.scrollNode = scrollNode
    local btnS=ui.sprite("images/btnScorll.png",{137, 80})
    display.adapt(btnS, 0, 42, GConst.Anchor.Left)
    scrollNode:getScrollNode():addChild(btnS)
    self.btnScorllView=btnS
end

function ItemUseDialog:onEvent(event, etype, x, y)
    if event=="single" then
        if etype == "begin" then
            self.scrollNode:setSingleTouchState(1)
            self.touchX = x
        elseif etype == "move" then
            x = self.touchX + x
        -- elseif etype == "end" then
        --     self.scrollNode:setSingleTouchState(1)
        end
        if x < 129/2 then
            x = 129/2
        elseif x > 899 - 129/2 then
            x = 899 - 129/2
        end
        self.btnScorllView:setPositionX(x-129/2)
        local minNum = self.minNum or 1
        local num = math.floor(minNum + (x-129/2)*(self.itemnum-minNum)/(899-129))
        if num ~= self.num then
            self:changeUseNum(num, true)
        end
    end
end
