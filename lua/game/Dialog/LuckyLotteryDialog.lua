local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

LuckyLotteryDialog = class(DialogViewLayout)

function LuckyLotteryDialog:onInitDialog()
    self:setLayout("LuckyLotteryDialog.json")
    self:loadViewsTo()
    music.play("sounds/luckyLotteryBack.mp3")
    self.closeBut:setScriptCallback(display.closeDialog, 0)
    self.questionBut:setScriptCallback(self.onQuestion, self)
    self.getRes=GameUI.addResourceIcon(self.nodeSpecialIcon, const.ResSpecial, 1.44, 80, 80,4)
    GameUI.addResourceIcon(self.nodeSpecialIcon2, const.ResSpecial, 0.78, 44, 44)
    GameUI.addResourceIcon(self.nodeCrystalIcon, const.ResCrystal, 0.92, 50, 50)
    self.btnLottery:setScriptCallback(self.onLottery, self)
    self.btnGetReward:setScriptCallback(self.onReward, self)
end

function LuckyLotteryDialog:onQuestion()
    HelpDialog.new("dataQuestionLuckyLottery")
end

function LuckyLotteryDialog:onEnter()
    self:refreshLuckCount(true)
    self:initTurnTable()
end

function LuckyLotteryDialog:onExit()
    local p = self.parent
    if p and p.refreshLuck then
        local pd = p:getDialog()
        if pd and not pd.deleted then
            p:refreshLuck()
            p:refreshHeros()
        end
    end
end

function LuckyLotteryDialog:refreshLuckCount(isFirst)
    local context = self.context
    local count = context:getProperty(const.ProLuckCount)
    self.labelLotteryCount:setString(Localizef("labelLotteryCount",{num=count}))
    local costData = SData.getData("constsNew", const.LuckyLotteryCostKey).data
    local baseData = SData.getData("constsNew", const.LuckyLotteryBaseKey).data
    local mcount = KTLen(baseData)
    local ccost = 0
    if count>=mcount then
        self.btnLottery:setGray(true)
        self.labelSpecialNum:setString(N2S(baseData[mcount]))
        ccost = costData[mcount]
    else
        self.btnLottery:setGray(false)
        self.labelSpecialNum:setString(N2S(baseData[count+1]))
        ccost = costData[count+1]
    end
    if not isFirst then
        music.play("sounds/LuckyLottery.mp3")
        local ls=self.labelSpecialNum.view:getScaleX()
        self.labelSpecialNum.view:runAction(ui.action.sequence({{"scaleTo",0,ls*0.8,ls*0.8},{"scaleTo",0.2,ls*1.2,ls*1.2},{"scaleTo",0.2,ls*0.8,ls*0.8},{"scaleTo",0.1,ls*1,ls*1}}))
        self.getRes:runAction(ui.action.sequence({{"scaleTo",0,1.44*0.8,1.44*0.8},{"scaleTo",0.2,1.44*1.2,1.44*1.2},{"scaleTo",0.2,1.44*0.8,1.44*0.8},{"scaleTo",0.1,1.44*1,1.44*1}}))
    end
    self.labelCrystalCost:setString(N2S(ccost))
    if ccost>context:getRes(const.ResCrystal) then
        self.labelCrystalCost:setColor(GConst.Color.Red)
    end
    local stat = context:getProperty(const.ProLuckReward)
    self.labelAllReward:setString(Localizef("labelLotteryReward",{num=stat}))
    self.btnGetReward:setGray(stat<=0)
end

-- local _lotteryGridPos = {
--     {825,842},{939,777},{1006,667},{1011,537},
--     {946,413},{824,340},{688,340},{570,413},
--     {507,537},{513,667},{579,777},{688,842}
-- }
local _lotteryGridPos = {
    {560,334},{642,382},{689,468},{686,559},{639,636},{559,681},
    {467,681},{389,636},{341,559},{339,468},{384,382},{465,334}
}
local lampPos={
    {513,1012},{646,994},{752,947},{854,869},{929,768},{977,650},
    {989,519},{972,405},{922,289},{855,203},{752,123},{644,77},
    {514,59},{385,76},{276,121},{183,191},{102,292},{54,406},
    {36,532},{51,652},{97,769},{174,871},{272,947},{389,996}
}
local _lotteryRates = {2,4,2,1,2,10,2,1,2,4,2,1}
function LuckyLotteryDialog:initTurnTable()
    local xznode=ui.node()
    xznode:setPosition(-75,36+25)
    self.view:addChild(xznode)
    local lampNode=ui.node()
    lampNode:setPosition(-75,36+25)
    self.view:addChild(lampNode,4)

    local lotteryGrids={}
    local pointer={}
    local temp
    for i,pos in ipairs(_lotteryGridPos) do  --12个选中状态
        temp = ui.sprite("images/dialogItemSelectLottery.png",{547, 252})
        display.adapt(temp, 517,524+12, GConst.Anchor.RightTop)
        --temp:setAnchorPoint(0.48,0.03)
        xznode:addChild(temp)
        temp:setRotation(30*(i+3))
        lotteryGrids[i]=temp
        temp:setOpacity(0)
        if i%3==1 then
            temp:runAction(ui.action.arepeat(ui.action.sequence({{"fadeIn",0.25},{"fadeOut",0.25},{"delay",1}})))
        elseif i%3==2 then
            temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0.5},{"fadeIn",0.25},{"fadeOut",0.25},{"delay",0.5}})))
        else
            temp:runAction(ui.action.arepeat(ui.action.sequence({{"delay",1},{"fadeIn",0.25},{"fadeOut",0.25}})))
        end
    end
    self.grids = lotteryGrids
    self.xznode = xznode
    local lamps={}
    for i,pos in ipairs(lampPos) do
        local index=i%2+1
        temp = ui.sprite("images/dialogBackLamp"..index..".png")
        display.adapt(temp, pos[1],pos[2], GConst.Anchor.Center)
        lampNode:addChild(temp,4)
        lamps[i]=temp
        local function changeLamp()
            if index==1 then
                index=2
                lamps[i]:setScale(55/83)
            elseif index==2 then
                index=1
                lamps[i]:setScale(83/55)
            end
            ui.setFrame(lamps[i], "images/dialogBackLamp" .. index .. ".png")
        end
        lamps[i]:runAction(ui.action.arepeat(ui.action.sequence({{"delay",0.2},{"call",changeLamp}})))
    end
end

function LuckyLotteryDialog:onReward(force)
    local context = self.context
    local reward = context:getProperty(const.ProLuckReward)
    if reward>0 then
        if force then
            --music.play("sounds/getit.mp3")
            context:getLotteryReward()
            GameLogic.showGet({{const.ItemRes,const.ResSpecial,reward}},0,true,true)
            display.closeDialog(0)
        else
            display.showDialog(AlertDialog.new(3,Localize("btnLuckyLottery"),Localize("alertTextLuckyLottery"),{callback=Handler(self.onReward, self, true)}))
        end
    else
        display.pushNotice(Localize("stringNoLuckReward"))
    end
end

function LuckyLotteryDialog:onLottery()
    local context = self.context
    local count = context:getProperty(const.ProLuckCount)
    local costData = SData.getData("constsNew", const.LuckyLotteryCostKey).data
    local baseData = SData.getData("constsNew", const.LuckyLotteryBaseKey).data
    local mcount = KTLen(baseData)
    if count>=mcount then
        display.pushNotice(Localize("stringHaveUserAllLucky"))
        return
    end
    if self.rotateAnimate then
        return
    end
    local ccost = costData[count+1]
    if ccost>context:getRes(const.ResCrystal) then
        display.showDialog(AlertDialog.new({ctype=const.ResCrystal, cvalue=ccost}))
        return
    end
    
    for _, ss in ipairs(self.grids) do
        ss:stopAllActions()
        ss:setOpacity(0)
    end
    local rate = context:lotterySpecial()
    local idx = math.random(12)
    for i=1, 12 do
        idx = (idx%12)+1
        if _lotteryRates[idx]==rate then
            break
        end
    end
    self.rotateAnimate = {target=idx, cur=1, ct=0, spd=0.12, tt=0}
    self.grids[1]:setOpacity(255)
    RegUpdate(self.xznode, Handler(self.onRotateStep, self), 0)
end

--一个初始加速，然后匀速，然后减速，最后严重减速的动画
function LuckyLotteryDialog:onRotateStep(diff)
    local r = self.rotateAnimate
    if not r then
        UnregUpdate(self.xznode)
        return
    end
    r.ct = r.ct+diff
    if r.ct>=r.spd then
        music.play("sounds/LuckyLottery.mp3")
        r.ct = r.ct-r.spd
        self.grids[r.cur]:setOpacity(0)
        r.cur = (r.cur%12)+1
        self.grids[r.cur]:setOpacity(255)
        r.tt = r.tt+1
        if r.tt<10 then
            r.spd = r.spd-0.01
        elseif r.tt>80 then
            if not r.lt then
                r.lt = r.target+36-r.cur
                if r.lt>30 then
                    r.lt = r.lt-12
                end
                r.mt = r.lt
            end
            r.lt = r.lt-1
            if r.lt==3 then
                r.spd = 0.5
            elseif r.lt==2 then
                r.spd = 0.75
            elseif r.lt==1 then
                r.spd = 1
            elseif r.lt==0 then
                self.rotateAnimate = nil
                self:refreshLuckCount()
            else
                r.spd = r.spd+0.01
            end
        end
    end
end
