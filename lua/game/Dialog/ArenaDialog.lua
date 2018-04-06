local const = GMethod.loadScript("game.GameLogic.Const")

ArenaDialog = class(DialogViewLayout)

function ArenaDialog:onInitDialog()
    self:setLayout("ArenaDialog.json")
    self:loadViewsTo()
    self.title:setString(Localize("titleArenaMain"))
end
function ArenaDialog:onEnter()
    local context = self.context
    self.questionTag = "dataQuestionArena"
    self:getArenaData()
end
function ArenaDialog:initVews()
    local layout = self:addLayout("baseViews", self.view)
    layout:loadViewsTo(self)

    self.btnRefresh:setScriptCallback(ButtonHandler(self.onRefresh, self))
    self.btnShop:setScriptCallback(ButtonHandler(StoreDialog.new, {stype="honor"}))
    self.btnRank:setScriptCallback(ButtonHandler(AllRankingListDialog.new, 5))
    self.btnAdd:setScriptCallback(ButtonHandler(self.addChance, self))
    self.btnLog:setScriptCallback(ButtonHandler(PvcLogDialog.new))
    local rNode = ui.node()
    self.view:addChild(rNode)
    RegTimeUpdate(rNode, Handler(self.update, self), 0.1)
    local bNode = ui.node()
    self.view:addChild(bNode)
    GameEvent.bindEvent(bNode,"refreshArenaDialog", self, self.reloadDialogs)
end
function ArenaDialog:onRefresh(force)
    --刷新一次5s等待时间
    if self.waitTime then
        local t = self.waitTime - GameLogic.getSTime()
        if t>0 then
            display.pushNotice(Localizef("noticeWait",{a=t}))
            return
        end
    end
    if GameNetwork.lockRequest() then
        self.waitTime = GameLogic.getSTime()+5
        self.btnRefresh:setGray(true)
        GameNetwork.request("pvcrefresh",{nrank=self.context.arena:getCurrentRank()},self.onRefreshEnemys,self)
    end
end

function ArenaDialog:onRefreshEnemys(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        self.context.arena:loadEnemys(data)
        if not self.deleted then
            self:reloadDialogs()
        end
    end
end

function ArenaDialog:onChallenge(eidx)
    local arena = self.context.arena
    if arena:getCurrentChance()>0 then
        local enemy = arena:getEnemyInfo(eidx)
        local batid=0
        if enemy.isRevenge then
            batid = enemy.batid
        end
        GameLogic.checkCanGoBattle(const.BattleTypePvc,function()
            if not GameNetwork.lockRequest() then
                return
            end
            local myHeroList = {}
            local context = GameLogic.getUserContext()
            local sign = context:getProperty(const.ProUseLayout)
            sign = GameLogic.dnumber(sign,3)
            for i=1,5 do
                local hero
                if sign[2]>0 then
                    hero = context.heroData:getHeroByLayout(const.LayoutPvc, i, 1)
                else
                    hero = context.heroData:getHeroByLayout(const.LayoutPvp, i, 1)
                end
                if hero then
                    table.insert(myHeroList,{hero.hid,hero.level,hero.awakeUp})
                end
            end
            GameNetwork.request("pvcBeginBattle", {tid=enemy.uid,nrank=enemy.rank,batid=batid,uhls=myHeroList}, function(isSuc,data)
                GameNetwork.unlockRequest()
                --dict(code=0,batid=rid,sdata=sdata)
                if isSuc then
                    if data.code==1 then
                        display.pushNotice(Localize("noticeRefreshEnemys"))
                    elseif data.code==2 then
                        display.pushNotice(Localize("labBattling"))
                    else
                        arena:resetChanceData(data.battime)
                        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvc,isRev=enemy.isRevenge and 1 or 0, batid=data.batid,myRank=arena:getCurrentRank(),bparams={uid=enemy.uid,rank=enemy.rank}, isPrepare=true, havePvcData=data.sdata})
                    end
                end
            end)
        end)
    end
end

function ArenaDialog:addChance()
    if GameNetwork.lockRequest() then
        GameNetwork.unlockRequest()
        local arena = self.context.arena
        local ctype, cvalue, cnum = arena:getBuyPrice()
        if cnum<=0 then
            display.showDialog(AlertDialog.new(3,Localize("labelBuyTimeNoEnough"),Localize("stringBuyTimeNoEnough"),{yesBut="labelSeeSpPerwor", callback=function()
                display.showDialog(VIPDialog.new())
            end}))
            return
        end
        display.showDialog(AlertDialog.new(1,Localize("alertTitleBuyChance"),Localizef("alertTextBuyChance2",{num=cnum}),{ctype=ctype, cvalue=cvalue, callback=Handler(self.onBuyChance, self)}))
    end
end

function ArenaDialog:onBuyChance()
    GameNetwork.request("pvcbuy", nil, function (isSuc,data)
        if isSuc and data then
            local context = GameLogic.getUserContext()
            local arena = self.context.arena
            arena:finishBuyChance()
            arena:resetChanceData(data.battime)
            if not self.deleted then
                local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffPVC)
                self.remainTimesValue:setString((arena:getCurrentChance()+buffInfo[4]-buffInfo[5]).."/"..(arena:getMaxChance()+buffInfo[4]))
                if arena:getCurrentChance()>0 then
                    ui.setColor(self.remainTimesValue.view,"white")
                else
                    ui.setColor(self.remainTimesValue.view,"red")
                end
                self:reloadDialogs()
            end
        end
    end)
end

local _arenaBackColors = {{187, 207, 190}, {197, 207, 185}, {195, 185, 207}, {204, 123, 123}}

function ArenaDialog:reloadDialogs()
    if not self.inited then
        self.inited= true
        self:initVews()
    end
    local arena = self.context.arena
    self.labRank:setString(Localize("labelMyRanking"))
    self.rankValue:setString(N2S(arena:getCurrentRank()))
    self.labelProcessFull:setVisible(false)
    self.labelProcessFull:setString(Localize("labelFull"))


    local stage = arena:getCurrentStage()
    if stage ==1 then
        self.labArenaStageNext:setVisible(false)
    else
        local a = arena:getStageMinRank(stage-1)
        self.labArenaStageNext:setString(Localizef("labArenaStageNext",{a=a,b=stage-1}))
    end
    GameUI.addArenaStageIcon2(self.view, stage, 1, 267, 661, 0)
    self.labelStage:setString(Localizef("labArenaStage",{n=stage}))
    local infos = arena:getHonorInfos()
    self.labHonorcoinProduct:setString(Localizef("labHonorcoinProduct",{a=infos.speed}))
    self.labHonorcoinMax:setString(Localizef("labHonorcoinMax",{a=infos.honorMax}))
    self.labHonorcoinHave:setString(Localizef("labHonorcoinHave",{a=infos.honorHave,b=infos.honorMax}))
    if infos.time then
        self.labProductTime:setString(Localizef("labProductTime",{a=Localizet(infos.time*60)}))
    else
        self.labProductTime:setString(Localize("labelFull"))
    end
    if infos.honorNextMax then
        self.labStageTips:setString(Localizef("labStageTips",{a=stage-1,b=infos.honorNextMax}))
    else
        self.labStageTips:setVisible(false)
    end
    local a=infos.honorHave
    local b=infos.honorMax
    if a>b then
        a=b
        self.labelProcessFull:setVisible(true)
    end
    self.gradeProcess:setProcess(true,a/b)
    local scal = 1.6*(a/b)
    if self.gradeProcessEffectBg then
        self.gradeProcessEffectBg:removeAllChildren(true)
        UIeffectsManage:showEffect_arenaprogress(self.gradeProcessEffectBg,212,25,1,scal)
    end

    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffPVC)
    if arena:getCurrentChance()>0 then
        self.remainTimes:setString(Localize("labelSurplusNume2"))
        ui.setColor(self.remainTimesValue.view,"white")
        self.remainTimesValue:setString((arena:getCurrentChance()+buffInfo[4]-buffInfo[5]).."/"..(arena:getMaxChance()+buffInfo[4]))
        self.btnAdd:setVisible(false)
    else
        self.remainTimes:setString(Localize("labRecoveryTime"))
        ui.setColor(self.remainTimesValue.view,"red")
        self.remainTimesValue:setString(Localizef("labMinute2",{a=math.ceil((7200-(GameLogic.getSTime()-infos.lastChallengeTime)%7200)/60)}))
        self.btnAdd:setVisible(true)
    end

    local bg = self.nodeArenaMain
    bg:removeAllChildren(true)
    local temp
    --自己正在被打
    if arena:getMyState() then
        local viewLayout=self:addLayout("myBattingViews",bg.view)
        viewLayout:loadViewsTo(self)
        self.labMyBattling:setString(Localizef("labMyBattling",{a="xx",b="12:00"}))
    else
        for i=1,3 do
            local arena = self.context.arena
            local enemy = arena:getEnemyInfo(i)
            local enemyNode = ui.node()
            display.adapt(enemyNode, 20+i*494, 30, GConst.Anchor.LeftBottom)
            bg:addChild(enemyNode)

            temp = ui.sprite("images/heroBackGrayAlpha.png",{497, 918})
            display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
            enemyNode:addChild(temp)

            temp = ui.scale9("images/bgWhiteGrid2.9.png", 20, {473, 896})
            ui.setColor(temp, _arenaBackColors[i])
            display.adapt(temp, 11+473/2, 23+896/2, GConst.Anchor.Center)
            enemyNode:addChild(temp)

            temp = ui.sprite("images/dialogBack_3_repeat.png")
            ui.setColor(temp, _arenaBackColors[i])
            local texture = temp:getTexture()
            texture:setTexParameters(gl.NEAREST, gl.NEAREST, gl.REPEAT, gl.REPEAT)
            temp:setTextureRect(cc.rect(0, 0, 473, 896))
            temp:setOpacity(25)
            display.adapt(temp, 11+473/2, 23+896/2, GConst.Anchor.Center)
            enemyNode:addChild(temp)

            temp = ui.label("", General.font1, 40, {color={255,255,255}})
            display.adapt(temp, 64, 885, GConst.Anchor.Left)
            enemyNode:addChild(temp,2)
            if enemy.rank and enemy.rank>0 then
                temp:setString(Localizef("labelRanking2",{a=enemy.rank}))
            else
                temp:setString(Localize("labelNotRank"))
            end
            temp = ui.label("", General.font1, 40, {color={255,255,255}, fontW = 450, fontH = 60})
            display.adapt(temp, 64, 825, GConst.Anchor.Left)
            enemyNode:addChild(temp,2)

            local ProCombat = enemy.combat or 0
            temp:setString(Localizef("propertyCombValue", {num = ProCombat}))

            temp = ui.button({317, 114},nil, {image="images/btnGreen.png"})--进入竞技场
            display.adapt(temp, 247,95, GConst.Anchor.Center)
            enemyNode:addChild(temp)
            local btnChallenge = temp
            local but=temp:getDrawNode()
            temp = ui.label(StringManager.getString("btnChallenge"), General.font1, 45, {color={255,255,255}})
            display.adapt(temp, 158,70,GConst.Anchor.Center)
            but:addChild(temp)
            local labChallenge =temp

            --全部加到按钮的节点上
            local butEnemy = ui.button({416,635},nil,{})
            display.adapt(butEnemy, 40, 160, GConst.Anchor.LeftBottom)
            enemyNode:addChild(butEnemy,10)
            temp = ui.sprite("images/dialogBackArena.png",{416, 635})
            display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
            butEnemy:getDrawNode():addChild(temp)
            GameUI.addHeroFeature(butEnemy:getDrawNode(), enemy.hid, 0.7, 207, 327, 2, true)
            temp = ui.sprite("images/dialogItemNameShadow.png",{371, 74})
            display.adapt(temp, 23, 72, GConst.Anchor.LeftBottom)
            butEnemy:getDrawNode():addChild(temp,2)
            temp = ui.label(StringManager.getString(enemy.name), General.font5, 50, {color={255,255,255}})
            display.adapt(temp, 207, 116, GConst.Anchor.Center)
            butEnemy:getDrawNode():addChild(temp,2)
            --是否可复仇
            if enemy.isRevenge then
                temp = ui.label(Localizef("labelArenaGetHonorcoin",{num=infos.canGetHonor}), General.font1, 35, {color={255,255,255}})
                display.adapt(temp,180, 50, GConst.Anchor.Center)
                butEnemy:getDrawNode():addChild(temp,2)
                GameUI.addResourceIcon(butEnemy:getDrawNode(), 60, 0.6, 325,50,10)
                btnChallenge:setHValue(-78)
                labChallenge:setString(Localize("btnRevenge"))
            else
                btnChallenge:setHValue(0)
                labChallenge:setString(Localize("btnChallenge"))
            end
            --正在被打中
            local isBattling = enemy.isBattling
            if isBattling then
                temp = ui.sprite("images/dialogItemNameShadow2.png",{371, 88})
                display.adapt(temp, 207, 320, GConst.Anchor.Center)
                butEnemy:getDrawNode():addChild(temp,2)
                temp = ui.label(Localize("labBattling"), General.font1, 50, {color={255,255,255}})
                display.adapt(temp, 207, 320, GConst.Anchor.Center)
                butEnemy:getDrawNode():addChild(temp,2)
                btnChallenge:setGray(true)
            end
            local function callChallenge()
                if isBattling then
                    display.pushNotice(Localize("labBattling"))
                elseif arena:getCurrentChance()<=0 then
                    display.pushNotice(Localize("stringChangeNotEnough"))
                else
                    self:onChallenge(i)
                end
            end
            if arena:getCurrentChance()<=0 then
                btnChallenge:setGray(true)
            else
                btnChallenge:setGray(false)
            end
            btnChallenge:setListener(callChallenge)
            butEnemy:setListener(function()
                SeeArenaArrDialog.new(i,enemy,callChallenge)
            end)
        end
    end
end

function ArenaDialog:getArenaData()
    if self.context.arena:getEnemysLockState() then
        if self.context.arena:isInited() and not self.deleted then
            self:reloadDialogs()
        end
        return
    end
    if not self.inRefresh then
        self.inRefresh = true
        GameNetwork.request("pvcinfo", {hid=self:getHid()}, function (isSuc,data)
            self.inRefresh = nil
            if isSuc and data then
                self.context.arena:loadArenaData(data)
                if not self.deleted then
                    local curStage = self.jumpType or 0
                    if curStage>0 then
                        local _stage = self.context.arena:getCurrentStage()
                        local vip = self.context:getInfoItem(const.InfoVIPlv)
                        local userLv = self.context:getInfoItem(const.InfoLevel)
                        GameLogic.addStatLog(11501,vip,userLv,_stage)
                    end
                    self:reloadDialogs()
                end
            end
        end)
    end
end

--当前等级最高的英雄ID（优先取出战竞技场的英雄）
function ArenaDialog:getHid()
    local context= GameLogic.getUserContext()
    local heros={}
    for i=1,5 do
        local hero = context.heroData:getHeroByLayout(const.LayoutPvc, i, 1)
        if hero then
            table.insert(heros,hero)
        end
    end
    local allHeros =nil
    if #heros==0 then
        allHeros = context.heroData:getAllHeros()
    end
    if allHeros then
        for i,hero in pairs(allHeros) do
            table.insert(heros,hero)
        end
    end
    if #heros>=2 then
        table.sort(heros,function(a,b)
            return a.level>b.level
        end)
    end
    return heros[1] and heros[1].hid or 0
end

function ArenaDialog:update(diff)
    if self.waitTime and self.waitTime<=GameLogic.getSTime() then
        self.waitTime = nil
        self.btnRefresh:setGray(false)
    end
    --20秒刷新对手状态
    if self.context.arena:isInited() then
        if not self.waitTime20 then
            self.waitTime20=GameLogic.getSTime()+20
        end
        if self.waitTime20<=GameLogic.getSTime() then
            self.waitTime20=nil
            local tid1=self.context.arena:getEnemyInfo(1).uid
            local tid2=self.context.arena:getEnemyInfo(2).uid
            local tid3=self.context.arena:getEnemyInfo(3).uid
            GameNetwork.request("getpvcnow", {tid1=tid1, tid2=tid2, tid3=tid3}, function(isSuc,data)
                if isSuc then
                    self.context.arena:refreshEnemysState(data.state1,data.state2,data.state3)
                    --self.context.arena:refreshHonor(data.avalue,data.atime)
                end
            end)
        end
    end
end
