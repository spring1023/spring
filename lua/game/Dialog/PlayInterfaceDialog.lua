local const = GMethod.loadScript("game.GameLogic.Const")
PlayInterfaceDialog = class(DialogViewLayout)

function PlayInterfaceDialog:onInitDialog()
    local context = GameLogic.getUserContext()
    self:setLayout("PlayInterfaceDialog.json")
    self:loadViewsTo()
    self.resScoreNum:setString(N2S(self.context:getRes(const.ResScore)))
    self.btnScore:setScriptCallback((ButtonHandler(AllRankingListDialog.new,1)))
    self.closeBut:setScriptCallback(display.closeDialog, 0)
    self.btnBattleArr:setScriptCallback(ButtonHandler(self.onSetBattleLayout, self))
    self.btnPvp:setScriptCallback(ButtonHandler(self.onPvpBattle, self))
    self.btnArena:setScriptCallback(ButtonHandler(function()
        self:onHeroTrialBattle()
        if self.btnArena.smallHand then
            self.btnArena.smallHand:removeFromParent(true)
            self.btnArena.smallHand = nil
            context.guideOr:setStep(context.guideOr:getStep()+1)
        end
    end))
    --引导
    if context.guide:getStep().type ~= "finish" then
        self.btnPvp:setScriptCallback(ButtonHandler(function()
            display.pushNotice(Localize("stringPleaseGuideFirst"))
        end))
    end
    --其他引导
    local step = context.guideOr:getStep()
    if step == 52 then
        self.btnArena.smallHand = context.guideHand:showHandSmall(self.btnArena.view,442,398,0)
    end

    if self.source and self.source == "talentMatch" then
        self.guideOther = GameLogic.getJumpGuide(const.ActTypePVP,self.btnPvp,633,393)
    else
        self.guideOther = nil
    end

    self.dotPos=self:getConfig("dotPos")
    self.guanKaPos=self:getConfig("guanKaPos")
    self.iconSize=self:getConfig("iconSize")
end

function PlayInterfaceDialog:onEnter()
    self:loadPveData()
    local context = self.context
    local cost = context:getPvpCost()
    self.labelMatchCost:setString(N2S(cost))
    if cost>context:getRes(const.ResGold) then
        self.labelMatchCost:setColor(GConst.Color.Red)
    else
        self.labelMatchCost:setColor(GConst.Color.White)
    end
    if context.buildData:getMaxLevel(const.Town) < const.HeroTrialLimit then
        self.btnArena.view:setBackgroundSound("sounds/lock.mp3")
    else
        self.lockIcon:setVisible(false)
    end
    local lastMissionId = context.activeData.lastMissionId
    context.activeData.lastMissionId = nil
    GameLogic.doRateGuide("pve", lastMissionId)

    local pvpChance = context.pvpChance
    local lnum = pvpChance:getValue()
    local pnum = pvpChance:getNormalValue()
    self.lbPvpChanceNum:setString(lnum .. "/" .. pvpChance:getMax())
    if lnum <= 0 then
        ui.setColor(self.lbPvpChanceNum, GConst.Color.Red)
    else
        ui.setColor(self.lbPvpChanceNum, GConst.Color.White)
    end
    local rate = context:computePvpRate(pnum+1)
    if rate > 1 then
        self.imgPvpBoxNum:setVisible(true)
        self.lbPvpBoxNum:setVisible(true)
        self.lbPvpBoxNum:setString("X" .. rate)
    else
        self.imgPvpBoxNum:setVisible(false)
        self.lbPvpBoxNum:setVisible(false)
    end
    self.btnPvpQuestion:setScriptCallback(ButtonHandler(self.onPvpQuestion, self))
    local buffInfo = context.activeData:getBuffInfo(const.ActTypeBuffPVT)
    if buffInfo[4] > 0 then
        local text = Localize("activity")
        GameUI.addCornerSgin( self.btnArena.view:getDrawNode(),text,1.43,65,713)
    end
    buffInfo = context.activeData:getBuffInfo(const.ActTypeBuffPVE)
    if buffInfo[4] > 0 then
        local text = Localize("activity")
        GameUI.addCornerSgin( self.view,text,1.43,64,1467)
    end
    self.butAddChanceNum:setScriptCallback(ButtonHandler(self.buyPvpChanceNum, self))

end

-- 内置说明对话框
local PvpIntroDialog = class(DialogViewLayout)

function PvpIntroDialog:onInitDialog()
    self:setLayout("OtherIntroDialog.json")
    self:loadViewsTo()
end

function PvpIntroDialog:onEnter()
    self.title:setString(Localize("titlePvpIntro"))
    self.subTitle:setVisible(false)
    self.content:setString(Localize("textPvpIntro"))

    local x, y = self.tableView:getPosition()
    self.tableView:setSize(self.tableView.size[1], y)
    if self.realTableView then
        self.realTableView.view:removeFromParent(true)
    end
    local infos = {}
    local rates = const.PvpBoxRates
    local last = 0
    local max = const.MaxPvpChance
    local rlen = KTLen(rates)
    for i=1, rlen do
        local rate = rates[i]
        table.insert(infos, {idx=rlen-i+1, text1=Localizef("labelRankRange", {a=last+1, b=rate[1]}), text2=Localizef("labelRewardRate", {a=rate[2]})})
        last = rate[1]
    end
    local updateFunc = Handler(self.onUpdateIntrolCell, self)
    self.realTableView = self.tableView:loadTableView(infos, updateFunc)
    updateFunc(self.tableHeader.view, self.realTableView, {idx=0, text1=Localize("labelRankRange0"), text2=Localize("labelRewardRate0")})
end

--增加购买pvp挑战次数
function PlayInterfaceDialog:buyPvpChanceNum()
    local context = self.context
    local pvpChance = context.pvpChance
    local stime = GameLogic.getSTime()
    local buyedCount, _ = pvpChance:getBuyedChance(stime)
    local maxBuyNum = pvpChance:getBuyedChanceMax()
    if buyedCount >= maxBuyNum then
        display.pushNotice(Localize("noticeBuyPvpChance"))
    else
        local buyedChance = pvpChance:getCanBuyChance(buyedCount+1)
        local addNum = buyedChance.addNum
        local ct = buyedChance.ctype
        local cv = buyedChance.cvalue
        local otherSettings={ctype=ct, cvalue=cv, callback=function()
            --蛋疼跨天容错处理
            local stime2 = GameLogic.getSTime()
            local buyedCount2, _ = pvpChance:getBuyedChance(stime2)
            if buyedCount2 ~= buyedCount then
                return self:buyPvpChanceNum()
            end

            if context:getRes(ct)<cv then
                local dialog = AlertDialog.new({ctype=ct, cvalue=cv})
                if not dialog.deleted then
                    display.showDialog()
                end
            else
                context:changeRes(ct, -cv)
                pvpChance:buyChance(stime2)
                if not self.deleted then
                    local lnum = pvpChance:getValue()
                    self.lbPvpChanceNum:setString(lnum .. "/" .. pvpChance:getMax())
                end
            end
        end}
        display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"), Localizef("alertTextBuyPvpChance",{a=addNum,b=maxBuyNum-buyedCount}),otherSettings))
    end
end

function PvpIntroDialog:onUpdateIntrolCell(cell, tableView, info)
    local bg = cell
    if bg.getDrawNode then
        bg = bg:getDrawNode()
    end

    if not info.viewLayout then
        info.viewLayout = self:addLayout("introType2", bg)
        info.viewLayout:loadViewsTo(info)
    end
    info.colorBack:setVisible((info.idx % 2) == 0)
    info.labelText1:setString(info.text1)
    info.labelText2:setString(info.text2)
end

function PlayInterfaceDialog:onPvpQuestion()
    display.showDialog(PvpIntroDialog)
end

function PlayInterfaceDialog:onSetBattleLayout()
    --GameLogic.getJumpGuide(const.ActTypePVE)
    if self.context.guide:getStep().type == "finish" then
        SetBattleArrDialog.new(1)
    else
        display.pushNotice(Localize("stringPleaseGuideFirst"))
    end
end

function PlayInterfaceDialog:onPvpBattle()
    GameLogic.removeJumpGuide(const.ActTypePVP)
    if self.source and self.source == "talentMatch" then
        GameLogic.checkPvpAttack({callback=Handler(GameEvent.sendEvent, GameEvent.EventBattleBegin, {type=const.BattleTypePvp, bparams = {source = self.source}})})
    else
        GameLogic.checkPvpAttack({callback=Handler(GameEvent.sendEvent, GameEvent.EventBattleBegin, {type=const.BattleTypePvp})})
    end
end

function PlayInterfaceDialog:onRequestBuyChance()
    local bchance,buyTimes,cost,addNum = self.context.pve:getBuyedChance()
    local info = {cost=cost,addNum=addNum}
    if buyTimes<=0 then
        print("购买次数不足")
        local viplv = self.context:getInfoItem(const.InfoVIPlv)
        if viplv>=const.MaxVipLV then
            display.pushNotice(Localize("pveBattleTimesNotBuyOver"))
        else
            display.pushNotice(Localizef("pveBattleTimesNotBuy",{num=bchance}))
        end
        return
    end
    -- 判断宝石是否足够
    local crystal = self.context:getRes(const.ResCrystal)
    if crystal<cost then
        display.showDialog(AlertDialog.new({ctype=const.ResCrystal}))
        return
    end
    if GameNetwork.lockRequest() then
        GameNetwork.request("pvereset",nil, self.onResponsePveReset, self,info)
    end
end

function PlayInterfaceDialog:onResponsePveReset(info,isSuc, data)
    GameNetwork.unlockRequest()
    if isSuc then
        self.context:changeRes(const.ResCrystal, -info.cost)
        self.context.pve:changeChance(info.addNum)
        self.context.pve:resetChance()
    end
end

function PlayInterfaceDialog:onHeroTrialBattle()
    if self.context.buildData:getMaxLevel(const.Town) < const.HeroTrialLimit then
        display.pushNotice(Localize("stringHeroTrialNotice"))
    else
        HeroTrialDialog.new()
    end
end

function PlayInterfaceDialog:loadPveData()
    -- 之前的背景没有改，屏蔽了滑动事件
    local map = ScrollNode:create(cc.size(2048,825), 1, true, false)
    map:setScrollEnable(false)
    map:setInertia(true)
    map:setInertiaCoefficient(0.985)--设置惯性系数
    map:setClip(true)
    map:setScaleEnable(true,1,1,1,1)
    map:setScriptHandler(Script.createCObjectHandler(self))
    self.pveMap = map
    local mapNumber=0.3
    map:setScrollContentRect(cc.rect(0,0,5344*mapNumber,825))
    display.adapt(map,0,711, GConst.Anchor.LeftBottom)
    local bg2 = ui.node()
    bg2:addChild(map)
    self:addChild(bg2, -1)
    local mapview=map:getScrollNode()
    local temp
    for i=1,mapNumber+math.ceil(mapNumber/3) do
        temp = ui.spriteBlock("images/dialogBackBattle.png",{4096, 825},{4,1})
        display.adapt(temp,0+(i-1)*4095, 0, GConst.Anchor.LeftBottom)
        mapview:addChild(temp)
    end
    if not self.context.pve.inited then
        self:requestPveDatas()
    else
        self:initIndex()
    end
end

function PlayInterfaceDialog:loadPveView()
    self:addLayout("Pagesbtn")
    self:loadViewsTo()
    local maxPoint = math.ceil(self.context.pve:getMyMaxStage()/6) or 30
    self.maxPoint = maxPoint
    self.btnPrevious:setScriptCallback(ButtonHandler(function ()
        self.needbreak = false
        self.btnNext:setVisible(true)
        self.chapterId = self.chapterId-1
        if self.chapterId<=1 then
            self.chapterId = 1
        end
        self:reloadPvechapter()
    end))
    self.btnNext:setScriptCallback(ButtonHandler(function ()
        self.needbreak = false
        self.btnPrevious:setVisible(true)
        self.chapterId = self.chapterId+1
        if self.chapterId>self.maxPoint then
            if self.canAttackLv then
                display.pushNotice(Localizef("needLvunlock",{lv=self.canAttackLv}))
            else
                display.pushNotice(Localize("pleasePassThisChapter"))
            end
        end
        if self.chapterId>= self.maxPoint then
            self.chapterId = self.maxPoint
        end
        self:reloadPvechapter()
    end))
    RegTimeUpdate(self.recoveryTime.view, Handler(self.updateRecoverTime, self), 0.5)
    -- 购买次数
    -- self.btnBuyBatterTimes:setScriptCallback(Handler(self.onRequestBuyChance, self))
    self.btnBuyBatterTimes:setScriptCallback(Handler(function ()
        local bchance,buyTimes,cost = self.context.pve:getBuyedChance()
        if buyTimes <=0 then
            local viplv = self.context:getInfoItem(const.InfoVIPlv)
            if viplv>=const.MaxVipLV then
                display.pushNotice(Localize("pveBattleTimesNotBuyOver"))
            else
                display.pushNotice(Localizef("pveBattleTimesNotBuy",{num=bchance}))
            end
            return
        end
        local t=0
        --5月2号2点
        local endTime = 1493704800
        if GameLogic.getSTime()<endTime then
            t=endTime - GameLogic.getSTime()
        end
        local text = Localizef("butPveSure",{num=buyTimes,time=Localizet(t)})
        display.showDialog(AlertDialog.new(1, Localize("buyPveBatter"), text, {ctype=const.ResCrystal, cvalue=cost, callback=Handler(self.onRequestBuyChance, self)}))
    end))
    if self.context.guide:getStep().type ~= "finish" then
        self.btnBuyBatterTimes:setScriptCallback(ButtonHandler(function()
            display.pushNotice(Localize("stringPleaseGuideFirst"))
        end))
    end
    self:reloadPvechapter()
end

--刷新pve挑战次数
function PlayInterfaceDialog:updateRecoverTime( ... )
    local pve = self.context.pve
    local recoveryTime = pve:getRecoveryTime()
    local chance = pve:getBattleChance()
    local maxChance = pve:getMaxChance()
    local buffInfo = self.context.activeData:getBuffInfo(const.ActTypeBuffPVE)
    if chance >= maxChance then
        self.recoveryTime:setVisible(false)
    else
        self.recoveryTime:setVisible(true)
        local time = GameLogic.getTimeFormat2(recoveryTime)
        self.recoveryTime:setString(Localizef("nextRecoveryTime",{time=time}))
    end

    self.pveTimes:setString(Localizef("labPveTimes",{a=chance+buffInfo[4]-buffInfo[5],b=maxChance+buffInfo[4]}))
end

function PlayInterfaceDialog:reloadPvechapter()
    local chapterId = self.chapterId
    if chapterId<=1 then
        self.btnPrevious:setVisible(false)
    end
    if chapterId>=self.maxPoint then
        self.btnNextImg.view:setSValue(-100)
    else
        self.btnNextImg.view:setSValue(0)
    end
    if chapterId == 30 then
        self.btnNext:setVisible(false)
    end
    -- 章节名称
    self.labelPve:setString(Localize("labelPve")..chapterId..":  "..Localize("pveChapterName"..chapterId))
    local btnIcon = chapterId%6
    local btnBg = math.ceil(chapterId/6)
    if btnBg == 0 then btnBg = 5 end
    if btnIcon == 0 then btnIcon = 6 end
    if not self.chapterNode then
        self.chapterNode = ui.node({0,0},true)
        self.pveMap:getScrollNode():addChild(self.chapterNode)
    end
    local bg = self.chapterNode
    bg:removeAllChildren(true)
    local but,temp
    local sizes = self.iconSize
    local info = {}
    local posId = 1+chapterId%3
    local guanKaPos = self.guanKaPos[posId]
    -- 小白点
    local dotPos = self.dotPos[posId]
    for i=1,#dotPos do
        local point = ui.sprite("images/pvePoint.png",{26, 26})
        display.adapt(point, dotPos[i][1], dotPos[i][2], GConst.Anchor.Center)
        bg:addChild(point)
    end
    for i=1,6 do
        if self.needbreak then
            break
        end
        but = ui.button({163,163}, nil, {})
            display.adapt(but, guanKaPos[i][1], guanKaPos[i][2], GConst.Anchor.Center)
            bg:addChild(but)
            info.but = but
        temp = ui.label(" ", General.font1, 32,{color={255,0,0}})
            display.adapt(temp, 163/2, 0, GConst.Anchor.Center)
            but:getDrawNode():addChild(temp,4)
            info.lablv = temp
        temp = ui.label(chapterId.."--"..i, General.font1, 50,{color={100,255,0}})
            display.adapt(temp, 163/2, 245, GConst.Anchor.Center)
            but:getDrawNode():addChild(temp)
            info.label = temp
        temp = ui.sprite("images/pveCheckState1.png",{116, 116})
            display.adapt(temp,163/2,163/2+6, GConst.Anchor.Center)
            temp:setSValue(-100)
            temp:setLValue(-40)
            but:getDrawNode():addChild(temp)
            info.cheCheckState = temp
        temp = ui.sprite("images/btnHeroLockOn.png",{74, 88})
            display.adapt(temp, 47, 45, GConst.Anchor.LeftBottom)
            temp:setSValue(-100)
            but:getDrawNode():addChild(temp,3)
            info.lock = temp
        temp = ui.sprite("images/329pvebuttrn"..btnBg..".png", sizes[btnBg])
            if btnBg==5 then
                display.adapt(temp, 163/2, 163/2+9, GConst.Anchor.Center)
            elseif chapterId == 4 then
                display.adapt(temp, 163/2-1, 163/2+4, GConst.Anchor.Center)
            else
                display.adapt(temp, 163/2, 163/2, GConst.Anchor.Center)
            end
            temp:setSValue(-100)
            but:getDrawNode():addChild(temp)
            info.btnBg = temp
            temp = ui.sprite("images/329pveicon"..btnIcon..".png",{97, 91})
            display.adapt(temp, 163/2, 163/2+6, GConst.Anchor.Center)
            temp:setSValue(-100)
            but:getDrawNode():addChild(temp)
            temp:setVisible(false)
            info.btnIcon = temp
        info.stars = {}
            temp = ui.sprite("images/dialogStar2_2.png",{50, 54})
            display.adapt(temp, 23, 162, GConst.Anchor.Center)
            temp:setRotation(-10)
            but:getDrawNode():addChild(temp,4)
            info.stars[1] = temp
            temp = ui.sprite("images/dialogStar1_2.png",{57, 61})
            display.adapt(temp,80, 182, GConst.Anchor.Center)
            but:getDrawNode():addChild(temp,4)
            info.stars[2] = temp
            temp = ui.sprite("images/dialogStar2_2.png",{50, 54})
            display.adapt(temp, 137, 162, GConst.Anchor.Center)
            temp:setRotation(10)
            temp:setFlippedX(true)
            but:getDrawNode():addChild(temp,4)
            info.stars[3] = temp
            temp = ui.sprite("images/dialogStar2_1.png",{50, 54})
            display.adapt(temp, 23, 162, GConst.Anchor.Center)
            temp:setRotation(-10)
            but:getDrawNode():addChild(temp,4)
            info.stars[4] = temp
            temp = ui.sprite("images/dialogStar1_1.png",{57, 61})
            display.adapt(temp,80, 182, GConst.Anchor.Center)
            but:getDrawNode():addChild(temp,4)
            info.stars[5] = temp
            temp = ui.sprite("images/dialogStar2_1.png",{50, 54})
            display.adapt(temp,137, 162, GConst.Anchor.Center)
            temp:setRotation(10)
            temp:setFlippedX(true)
            but:getDrawNode():addChild(temp,4)
            info.stars[6] = temp
        for i=1,6 do
            info.stars[i]:setVisible(false)
        end
        self:checkBtnStates(chapterId,i,info)
    end
end

---检查每个按钮的状态
function PlayInterfaceDialog:checkBtnStates(chapterId,pointId,info)
    local context = GameLogic.getUserContext()
    local pveId = (chapterId-1)*6+pointId
    local states = context.pve:getDetail(pveId)
    if states.canAttack then
        info.lock:setVisible(false)
        info.btnIcon:setVisible(true)
        info.btnBg:setSValue(0)
        if not states.attacked then
            GameLogic.getJumpGuide(const.ActTypePVE,info.but,80,116)
        end
    end
    local lv = self.context:getInfoItem(const.InfoLevel)
    if lv<states.needlv then
        info.lock:setVisible(true)
        info.btnBg:setSValue(-100)
        info.btnIcon:setVisible(false)
        info.lablv:setString(Localizef("needLvunlock",{lv=states.needlv}))
    end
    if states.attacked then
        info.btnIcon:setSValue(0)
        for i=1,3 do
            info.stars[i]:setVisible(true)
        end
    end
    for i=1,states.star do
        info.stars[i+3]:setVisible(true)
    end
    if not states.attacked and states.canAttack then
        info.label:setVisible(true)
    else
        info.label:setVisible(false)
    end
    if states.special then
        info.lock:setVisible(false)
        info.btnIcon:setVisible(false)
        local temp
        if states.special[1]==const.ItemOther then
            if states.special[2]==1 then
                temp = ui.sprite("images/pveIconX.png")
            elseif states.special[2]==2 then
                temp = ui.sprite("images/pveIconT.png")
            end
            temp:setScale(0.9)
            display.adapt(temp, 82, 85, GConst.Anchor.Center)
            info.but:getDrawNode():addChild(temp)
        else
            temp = GameUI.addHeroHeadCircle2(info.but:getDrawNode(), states.special[2], 0.6, 82, 85, 1)
        end
        if not states.attacked then
            temp:setSValue(-100)
        end
    end
    info.label:setString(Localize("dataPvePassName"..pveId))
    info.but:setScriptCallback(ButtonHandler(self.onSelectPveChaoter, self, states,pveId))
    if pointId == 1 and lv<states.needlv then
        self.maxPoint = self.maxPoint-1
        self.chapterId = self.maxPoint
        self:reloadPvechapter()
        self.needbreak = true
        self.canAttackLv = states.needlv
    end
    --引导self.guanKaPos[pveId][1]
    if pveId<=6 and pveId==context.pve:getMyMaxStage() then
        if not self.source then
            local pos =  self.guanKaPos[1+chapterId%3]
            local arrow = context.guideHand:showArrow(self.view, pos[pveId][1],pos[pveId][2]+650, 50)
            arrow:setScaleY(-1)
        end
    end
    if context.guide:getStep().type ~= "finish" and pveId>1 then
        info.but:setScriptCallback(ButtonHandler(function()
            display.pushNotice(Localize("stringPleaseGuideFirst"))
        end))
    end
end

-- 章节按钮
function PlayInterfaceDialog:onSelectPveChaoter(states,idx)
    local lv = self.context:getInfoItem(const.InfoLevel)
    if lv < states.needlv then
        display.pushNotice(Localizef("unlockPveBatter",{lv=states.needlv}))
        return
    end
    PveInfoDialog.new({states=states,idx=idx})
end

function PlayInterfaceDialog:showArrow()
    local context = GameLogic.getUserContext()
    local arrow = context.guideHand:showArrow(self.closeBut,95,0,3)
    arrow:setScaleY(-1)
end

function PlayInterfaceDialog:canExit()
    --引导
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "searchX" then
        context.guide:addStep()
    end
    return true
end

-- 拉取pve数据
function PlayInterfaceDialog:requestPveDatas()
    GameNetwork.request("getpvedata",{},Handler(self.onResponsePveData, self))
end

function PlayInterfaceDialog:onResponsePveData(suc, data)
    if suc then
        local context = self.context
        if context and context.pve then
            context.pve:loadPveData(data)
            self:initIndex()
        end
    end
end

function PlayInterfaceDialog:initIndex( ... )
    local isReceiveDoraemon = GameLogic.getUserContext():getProperty(const.ProGuideHero)
    local pvedata = GameLogic.getUserContext().pve
    local isNavice = GEngine.getConfig("OpenReceiveDoraemon"..GameLogic.getUserContext().uid)
    if isReceiveDoraemon<1 and pvedata.stars[6] and pvedata.stars[6]>0 and isNavice then
        local ReceiveDoraemon = GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.ReceiveDoraemon")
        display.showDialog(ReceiveDoraemon.new())
    end
    if not self.deleted then
        -- self:reloadPveDatas()
        if self.index then
            self.chapterId = math.ceil(self.index.stage/6)
            if self.index.attacked and self.index.stage%6==0 then
                self.chapterId = self.chapterId + 1
            end
        else
            self.chapterId = math.ceil(self.context.pve:getMyMaxStage()/6)
        end
        if self.chapterId<=0 then
            self.chapterId = 1
        elseif self.chapterId>=30 then
            self.chapterId=30
        end
        self:loadPveView()
    end
end
