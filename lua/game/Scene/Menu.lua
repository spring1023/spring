local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local GameSetting = GMethod.loadScript("game.GameSetting")
local IllustrationDialog = GMethod.loadScript("game.UI.NewDialog.NewIllustrationDialog")
GMethod.loadScript("game.GameUI")

local Menu = {}

function Menu:init()
    self.view = ui.touchNode(display.winSize, -4, false)
    self.view:setGroupMode(true)
    local temp = ui.sprite("images/background/sceneUp.png", {display.winSize[1], display.winSize[2]})
    display.adapt(temp, 0, 0)
    self.view:addChild(temp)
    self.res = {}
    self.checkEntry = GMethod.schedule(function()
        self:checkOperationTime()
    end, 1)
end

function Menu:checkOperationTime()
    if GameLogic.inError then
        GMethod.unschedule(self.checkEntry)
        self.checkEntry = nil
        return
    end
    local nowSTime = GameLogic.getSTime()
    local ucontext = GameLogic.getUserContext()
    if ucontext then
        -- 增加自动刷新登录活动的功能
        ucontext.activeData:refreshLoginAct()
        local cstat = ucontext:getCmdStat()
        if cstat.maxIdx > cstat.lastIdx then
            if not cstat.lastResponseTime then
                cstat.lastResponseTime = nowSTime
            end
            -- if cstat.sendedIdx > cstat.lastIdx then
            --     print("test sended idx")
            -- end
            if nowSTime > cstat.lastResponseTime + 300 and cstat.sendedIdx > cstat.lastIdx then
                GameLogic.doErrorHandler(3, "Error in Menu:checkOperationTime, type 0, responseTime more than 300")
                return
            else
                if not cstat.lastRetryTime then
                    cstat.lastRetryTime = nowSTime
                end
                if nowSTime > cstat.lastRetryTime + 60 then
                    GameLogic.dumpCmds(true)
                    cstat.lastRetryTime = nowSTime
                end
            end
        else
            cstat.lastResponseTime = nil
        end
        if not cstat.lastTryTime then
            cstat.lastTryTime = nowSTime
        end
        if nowSTime > cstat.lastTryTime + 15 then
            GameLogic.dumpCmds()
            cstat.lastTryTime = nowSTime
        end
        if cstat.dirty then
            local save = {sidx = cstat.lastIdx + 1, eidx = cstat.maxIdx, cmds=cstat.cachedCmds, gs=cstat.goldStat, syntime=nowSTime}
            if #save.cmds == 0 then
                GEngine.setConfig("cmds_data_" .. GameLogic.uid, "", true)
                GEngine.setConfig("last_syn_uid", 0, true)
            else
                GEngine.setConfig("cmds_data_" .. GameLogic.uid, json.encode(save), true)
                GEngine.setConfig("last_syn_uid", GameLogic.uid, true)
            end
            GEngine.saveConfig()
            cstat.dirty = nil
        end
        if not GameLogic.lastSTime then
            GameLogic.lastSTime = nowSTime
        end
        if GameLogic.lastSTime < nowSTime - 1800 or GameLogic.lastSTime > nowSTime + 30 then
            GameLogic.doErrorHandler(2)
            return
        else
            GameLogic.lastSTime = nowSTime
        end
        GameSetting.saveLocalData()
        ucontext.logData:update(1)
    end
    if GameLogic.operationTime then
        if nowSTime - GameLogic.operationTime > 1800 or nowSTime < GameLogic.operationTime - 60 then
            GameLogic.operationTime = nowSTime
            GameLogic.doErrorHandler(1)
            return
        end
        -- 如果上一次请求达到5分钟，且不到半小时，且其他请求在批量接口之后，则
        if GameLogic.lastNetworkTime and nowSTime - GameLogic.lastNetworkTime >= 300 and nowSTime - GameLogic.lastNetworkTime <= 1800 then
            ucontext:addCmd({const.CmdUpgradeUlv, 0})
            GameLogic.lastNetworkTime = nil
            GameLogic.lastCmdTime = nowSTime
            return
        end
        if GameLogic.lastCmdTime then
            -- 特别增加一个处理，批量接口的传输判断，如果30分钟内没有发送批量接口的话，则掉线处理
            if nowSTime - GameLogic.lastCmdTime > 60*30 then
                GameLogic.lastCmdTime = nowSTime
                GameLogic.doErrorHandler(1)
                return
            end
        end
    end
end

function Menu:initChatRoom()
    local ChatRoom=GMethod.loadScript("game.UI.interface.ChatRoom")
    local bg=ui.node({display.winSize[1],display.winSize[2]})
    if self.chatRoom then
        self.chatRoom:removeFromParent(true)
        self.chatRoom = nil
    end
    local temp=ChatRoom.new()
    display.adapt(temp, 0, 0,GConst.Anchor.LeftTop,{scale=ui.getUIScale2()})
    bg:addChild(temp)
    self.chatRoom = temp
    self.view:addChild(bg,10)
    if self.scene.sceneType~="operation" then
        self.chatRoom:setVisible(false)
    end
    self:initBarrage()
end
--==============================--
--desc:跑马灯相关
--author:aoyue
--time:2018-01-15 04:36:01
--@return
--==============================--
function Menu:initBarrage()
    if GameLogic.useTalentMatch then
        return
    end
    local Barrage=GMethod.loadScript("game.View.Barrage")
    local size={1000, 100}
    local bg = ui.scrollNode(size,0,false,false)
    display.adapt(bg,50,-150,GConst.Anchor.Top, {scale=ui.getUIScale2()})
    if self.barrage then
        self.barrage:removeFromParent(true)
        self.barrage=nil
    end
    local barrage=Barrage.new()
    display.adapt(barrage,size[1]/2,size[2]/2,GConst.Anchor.Center)
    bg:addChild(barrage)
    self.barrage=barrage
    bg=display.addLayer(bg,20,5)
    bg:setTouchPriority(100)
end
function Menu:hideAll()
    self.view:setVisible(true)
    if self.chatRoom then
        self.chatRoom:setVisible(false)
    end
    local ops = self.ops
    if ops then
        self.ops:setVisible(false)
    end
    local battle = self.battle
    if self.replayMenu then
        self.replayMenu:removeFromParent(true)
        self.replayMenu = nil
    end
    if battle then
        if type(battle) == "table" then
            self.battle.view:removeFromParent(true)
            self.battle = nil
        elseif type(battle) == "userdata" then
            self.battle:removeFromParent(true)
            self.battle = nil
        end
    end
    if self.visit then
        self.visit.view:removeFromParent(true)
        self.visit = nil
    end
    LogicEffects.setBufferUse(false)
end

function Menu:initOperation()
    --playbackInterface.new()
    local ops = ViewLayout.new()
    ops:setLayout("MainMenu.json")
    display.adapt(ops.view, 0, 0)
    self.view:addChild(ops.view)
    ops:loadViewsTo()
    self.ops = ops
    self.opsData = {}
    if not ops.nodeActivity then
        ops.nodeActivity = ui.node()
        display.adapt(ops.nodeActivity, 20, 100)
        ops.view:addChild(ops.nodeActivity)
    end
    -- 做个兼容
    if not ops.nodeActivityRight then
        ops.nodeActivityRight = ui.node()
        display.adapt(ops.nodeActivityRight, 425, -81)
        ops.nodeUserRes:addChild(ops.nodeActivityRight)
    end
    if ops.btnFace then
        ops.btnFace:setVisible(false)
    end
    if ops.btnPackCode then
        ops.btnPackCode:setVisible(false)
    end
    if not ops.nodeFunctionModule then
        ops.nodeFunctionModule = ui.node()
        display.adapt(ops.nodeFunctionModule, 108, 18)
        ops.view:addChild(ops.nodeFunctionModule)
    end

    self:initRightBottomFunction()
    self:VisibleFunctionModule(false)

    --ops.nodeGiftNotice:setVisible(false)
    ops.nodeStoreNotice:setVisible(false)
    ops.btnMap:setScriptCallback(ButtonHandler(display.showDialog, PlayInterfaceDialog))
    -- ops.btnHero:setScriptCallback(ButtonHandler(display.showDialog, HeroMainDialog))
    ops.btnHero:setScriptCallback(ButtonHandler(IllustrationDialog.new()))

    -- 达人赛
    if GameLogic.useTalentMatch then
        ops.btnTalent:setScriptCallback(ButtonHandler(
            function()
                if GameLogic.getUserContext().guide:getStep().type ~= "finish" then
                    display.pushNotice(Localize("stringPleaseGuideFirst"))
                    return
                end
                local tmStep = GameLogic.getUserContext().guideOr:getStepByKey("TalentMatch") or 0
                if ops.btnTalent.guideArrow and tmStep <= 0 then
                    ops.btnTalent.guideArrow:removeFromParent(true)
                    ops.btnTalent.guideArrow = nil
                    GameLogic.getUserContext().guideOr:setStepByKey("TalentMatch", tmStep+1)
                end
                display.sendIntent({class="game.Dialog.TalentMatchDialog"})
            end
        ))
        -- 达人赛红点逻辑有关
        local function checkShowTip()
            local showTip = GameLogic.getUserContext().talentMatch:showRedTip()
            ops.img_knockTTip:setVisible(showTip)
        end
        checkShowTip()
        GameEvent.bindEvent(ops.img_knockTTip.view, "RefreshTMRedNum", self, checkShowTip)
        local nowTime = GameLogic.getSTime()
        local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffKnockMatch)
        local startTime=buffInfo[2]
        local endTime=buffInfo[3]+86400*3
        if nowTime<endTime then--buffInfo[4] ~= 0 then
            -- 英雄角逐
            self.flag1121=true
            local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
            local function showKnockMatch()
                if nowTime<buffInfo[3]-1800 then
                    local context = GameLogic.getUserContext()
                    local guideKnockArrow = context.guideHand.handArr["knockGuide"]
                    local _step = KnockMatchData:getDivideGuideStep()
                    if guideKnockArrow and _step and (_step == 4 or _step == 1)then
                        guideKnockArrow:removeFromParent()
                    end
                    if guideKnockArrow and _step == 1 then
                        context.guideHand.handArr["knockGuide"] = nil
                    end
                    KnockMatchData:initData()
                else
                    local KnockOutDialog = GMethod.loadScript("game.Dialog.KnockOutDialog")
                    display.showDialog(KnockOutDialog.new())
                end
            end
            ops.btnKnock:setVisible(true)
            ops.btnKnock:setPosition(285,-244)
            ops.btnKnock:setScriptCallback(ButtonHandler(showKnockMatch))
            local function addArrow()
                local context = GameLogic.getUserContext()
                context.guideHand:showArrow(ops.btnKnock, 107, 180, 20, "knockGuide")
            end
            GameEvent.bindEvent(ops.btnKnock.view,GameEvent.addKncokGuide, self, addArrow)
            local function checkShowTip()
                local showTip = KnockMatchData:showRedTip()
                ops.img_knockTip:setVisible(showTip)
            end
            checkShowTip()
            GameEvent.bindEvent(ops.img_knockTip.view,GameEvent.showKnockTip, self, checkShowTip)

            if ops.imgMatch then
                ops.imgMatch:setImage("images/pvz/imgPvzEmperor.png", 0, nil, nil, true)
            end
        else
            ops.btnKnock:setVisible(false)
        end
    else
        -- 英雄角逐
        local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
        local function showKnockMatch()
            local context = GameLogic.getUserContext()
            local guideKnockArrow = context.guideHand.handArr["knockGuide"]
            local _step = KnockMatchData:getDivideGuideStep()
            if guideKnockArrow and _step and (_step == 4 or _step == 1)then
                guideKnockArrow:removeFromParent()
            end
            if guideKnockArrow and _step == 1 then
                context.guideHand.handArr["knockGuide"] = nil
            end
            KnockMatchData:initData()
        end
        ops.btnKnock:setScriptCallback(ButtonHandler(showKnockMatch))
        local function addArrow()
            local context = GameLogic.getUserContext()
            context.guideHand:showArrow(ops.btnKnock, 107, 180, 20, "knockGuide")
        end
        GameEvent.bindEvent(ops.btnKnock.view,GameEvent.addKncokGuide, self, addArrow)
        local function checkShowTip()
            local showTip = KnockMatchData:showRedTip()
            ops.img_knockTip:setVisible(showTip)
        end
        checkShowTip()
        GameEvent.bindEvent(ops.img_knockTip.view,GameEvent.showKnockTip, self, checkShowTip)

        if ops.imgMatch then
            ops.imgMatch:setImage("images/pvz/imgPvzEmperor.png", 0, nil, nil, true)
        end
    end
    -- local logData = GameLogic.getUserContext().logData
    -- logData:init()
    -- local function showLogDialog()
    --     LogDialog.new(logData:getOpenIndex(),logData.datas)
    -- end
    --ops.btnMsgs:setScriptCallback(ButtonHandler(showLogDialog))

    --ops.btnRank:setScriptCallback(ButtonHandler(AllRankingListDialog.new))
    local function _deleteArrow()
        local context = GameLogic.getUserContext()
        context.guideHand:removeHand("youthDayStatueGuide")
        ops.btnStore.handOr = nil
    end
    ops.btnStore:setScriptCallback(ButtonHandler(StoreDialog.new))
    GameEvent.bindEvent(ops.btnStore.view,GameEvent.DelYouthDayGuide, self, _deleteArrow)

    --商店角标
    local redNum = GameUI.addRedNum(ops.btnStore,0,140,0,0.8,10000)
    GameEvent.bindEvent(redNum,"refreshStoreRedNum",redNum,function()    --node,events,target,callback
        local context = GameLogic.getUserContext()
        local d = context.buildData
        d:reloadCanBuildNum()
        if GameLogic.useTalentMatch then
            d.canBuildNum[8] = 0
        end
        local num = d:getCanBuildNum()+GameLogic.checkVipSheild()   --建筑+盾
        redNum:setNum(num)
    end)
    GameEvent.sendEvent("refreshStoreRedNum")
    --任务按钮
    --ops.btnTask.view:setFlippedX(true)
    --ops.btnTask:setScriptCallback(ButtonHandler(AchievementDialog.new))
    -- if DEBUG.DEBUG_REPLAY2 then
    --     ops.btnTask:setScriptCallback(ButtonHandler(function()
    --         GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvp, isReplay=true})
    --     end))
    -- end
    --任务角标提示
    local redNum = GameUI.addRedNum(ops.btnTask:getDrawNode(),-20,80,0,0.8,99)
    GameEvent.bindEvent(redNum,"refreshTaskRedNum",redNum,function()
        local context = GameLogic.getUserContext()
        local num = context.activeData:getNotRewardDaily()+context.achieveData:getNotReward()
        --活动的num
        local d = context.activeData
        local num2 = d:getNotRewardHot()
        num2 = num2 + context.activeData:getNotRewardLimit101()
        local num3 = 0

        if not GameLogic.useTalentMatch then
            num3 = d:getNotRewardDailyTask()
            local dtinfo = context.activeData:getDailyTaskDtinfo()
            local stime = GameLogic.getSTime()
            local dtime = dtinfo[1]
            if (math.floor((stime-const.InitTime)/86400) > math.floor((dtime-const.InitTime)/86400)) then
                num3 = 0
            end
        end
        redNum:setNum(num+num2+num3)
        self.taskRedNum = num+num2+num3
    end)
    GameEvent.sendEvent("refreshTaskRedNum")
    --许愿池红点
    if GameLogic.useTalentMatch then
        local redNum = GameUI.addRedNum(ops.btnWishes:getDrawNode(),-20,80,0,0.8,99)
        GameEvent.bindEvent(redNum,"refreshWishesRedNum",redNum,function()
            local context = GameLogic.getUserContext()
            local num = context:getFreeHeroChance(GameLogic.getSTime())
            --活动的num
            redNum:setNum(num)
        end)
        GameEvent.sendEvent("refreshWishesRedNum")
    end
    ops.btnAddBuilder:setScriptCallback(ButtonHandler(StoreDialog.new,"builder"))
    ops.btnAddShield:setScriptCallback(ButtonHandler(StoreDialog.new,5))
    if GameLogic.useTalentMatch then
        ops.btnAddRes5:setScriptCallback(ButtonHandler(StoreDialog.new, {id=1, guideBuyBlack=1}))
        ops.btnAddRes8:setScriptCallback(ButtonHandler(StoreDialog.new, {id=1, guideBuyBlack=1}))
    else
        ops.btnAddRes5:setScriptCallback(ButtonHandler(BeercupDialog.new,{rtype=const.ResSpecial}))
        ops.btnAddRes8:setScriptCallback(ButtonHandler(BeercupDialog.new,{rtype=const.ResZhanhun}))
    end
    ops.btnAddRes4:setScriptCallback(ButtonHandler(StoreDialog.new, 1))
    if not GameLogic.useTalentMatch then
        self.btnAddRes8Effect=UIeffectsManage:showEffect_duijiuanniu(ops.btnAddRes8,50,50)
        self.btnAddRes8Effect:setVisible(false)
        self.res8FreeNum=GameUI.addRedNum(ops.btnAddRes8,0,50,0,0.8,10)
        self.res8FreeNum:setScale(0.8)
        self.res8FreeNum:setNum(0)
        self.btnAddRes5Effect=UIeffectsManage:showEffect_duijiuanniu(ops.btnAddRes5,50,50)
        self.btnAddRes5Effect:setVisible(false)
        self.res5FreeNum=GameUI.addRedNum(ops.btnAddRes5,0,50,0,0.8,10)
        self.res5FreeNum:setScale(0.8)
        self.res5FreeNum:setNum(0)
    end
    ops.nodeActivity:setVisible(false)
    ops.nodeActivityRight:setVisible(false)

    local context = GameLogic.getUserContext()
    if not GameLogic.useTalentMatch then
        local vipRedNumNode = ui.node({20,20})
        display.adapt(vipRedNumNode,190,38,GConst.Anchor.RightTop)
        ops.butVipAdd:addChild(vipRedNumNode,100)
        self.butVipRedNum = GameUI.addRedNum(vipRedNumNode,0,0,0,1,99)
        vipRedNumNode:setScale(0.75)
        self.butVipRedNum:setNum(0)
        ops.butVipAdd:setScriptCallback(ButtonHandler(function ()
            -- body
            display.showDialog(VIPDialog.new())
        end))
    end
    for i=1, 10 do
        local k = "nodeRes" .. i .. "Icon"
        if ops[k] then
            GameUI.addResourceIcon(ops[k], i, 1, 0, 0)
            self.res[i] = {value=-1, valueLabel=ops["labelRes" .. i]}
            if i==const.ResGold or i==const.ResBuilder then
                self.res[i].max = 0
                self.res[i].maxLabel = ops["labelRes" .. i .. "Max"]
                self.res[i].filler = ops["fillerRes" .. i]
            end
        end
    end
    self.res[const.ResExp] = {value=-1, max=0, valueLabel=ops["labelRes" .. const.ResExp], filler=ops["fillerRes" .. const.ResExp]}

    -- 初始化推广码数据
    do
        local plays = GameLogic.tlist or {}
        local crystal = 0
        for i=1, #plays do
            crystal = crystal + math.floor(plays[i][6]*0.2)
        end
        GameLogic.CacheGemPoolData(crystal)
        GameLogic.CacheSplitData(plays)
    end
end

function Menu:initFacebooFriends(callback)
    if not GEngine.getConfig("haveBindFb") or GEngine.getConfig("haveBindFb")~= 1 then
        if callback then
            callback()
        end
        return
    end
    local context = GameLogic.getUserContext()
    if context.fbFriends then
        if callback then
            callback()
        end
        return
    end
    Plugins:getFriends(function (fbFriends)
        if #fbFriends == 0 then
            if callback then
                callback()
            end
            return
        end
        local fbFriendsList={}
        for i,fb in ipairs(fbFriends) do
            table.insert(fbFriendsList,fb.id)
        end
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("fbfriends",{svid=context.sid,friends =fbFriendsList},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                local context = GameLogic.getUserContext()
                context.fbFriends = data.flist
                local idx = 0
                local addHurt = 0
                local adds=GEngine.getSetting("pvbHurtAddSet") or {}
                --flist：[[uid,name,lid,fbid,elv,head]]
                for i,v in ipairs(data.flist) do
                    if context.union and tonumber(v[3]) == context.union.id then
                        idx = idx+1
                        local add = adds[idx] or 0
                        v[20] = add
                        addHurt = addHurt+add
                    end
                end
                context.pvbHurtAdd = addHurt
                if callback then
                    callback()
                end
            end
        end)
    end)
end

function Menu:doActivity(v)
    if v==51 then
        display.showDialog(FirstChargePackageDialog)
    elseif v == 52 then
        if GameLogic.useTalentMatch then
            local randomBoxAid = {}
            local context = GameLogic.getUserContext()
            for aid = 101, 106 do
                local info = context.talentMatch:getMatchInfo(aid)
                if info.inMatch and info.adata.needLevel <= context.buildData:getTownLevel() then
                    table.insert(randomBoxAid, info.aid)
                end
            end
            if randomBoxAid[1] then
                local _aidx = math.random(1, #randomBoxAid)
                display.sendIntent({class="game.Dialog.TalentMatchGiftDialog", params={
                    ainfo=context.talentMatch:getMatchInfo(randomBoxAid[_aidx])}})
            end
        end
    -- 推广码
    elseif v == 57 then
        -- SpreadAndRewardDialog.new()
        local dialog = ActivityListDialog.new({menuActType = 5, actType = 4})
        if dialog then
            display.showDialog(dialog)
        end
    elseif v==101 then
        EverydayTreasureDialog.new()
    -- 旧FB
    elseif v == 200 then
        if GameLogic.getUserContext():getProperty(const.ProFBFollow) then
            CommunityDialog.new()
            GEngine.setConfig("localRedNode", Localize("communityRedNode"), true)
            GEngine.saveConfig()
        else
            if not cc.FileUtils:getInstance():isFileExist("images/facebook2.png") then
                GameLogic.doFollowAction()
            else
                FacebookDialog.new()
            end
        end
    else
        local context = GameLogic.getUserContext()
        local actGroup = context.activeData:getConfigableGroups()[v]
        if actGroup then
            display.showDialog(ActivityListDialog.new({menuActType = actGroup.actGroup}))
            if v == 40000 then
                GameLogic.addStatLog(21001, 1, 0, 0)
            end
            return
        end
        local act = context.activeData:getConfigableActs()[v]
        if act then
            local menuActType = ActivityLogic.menuActType(act)
            if act.actType == 6 then
                TwoFirstFlushDialog.new(v)
            else
                if act.actTemplate == "monthCard" then
                    display.sendIntent({class="game.Dialog.ActivityMonthCardDialog", params={act=act, actId=v}})
                elseif act.actTemplate == "single" then
                    display.sendIntent({class="game.Dialog.ActivitySingleDialog", params={act=act, actId=v}})
                elseif act.actTemplate == "multi" then
                    display.sendIntent({class="game.Dialog.ActivityMultiDialog", params={act=act, actId=v}})
                else
                    display.showDialog(ActivityListDialog.new({actId=v, menuActType = ActivityLogic.menuActType(act)}))
                end
            end
        end
    end
end

function Menu:VisibleFunctionModule(vis)
    if self.ops.nodeFunctionModule then
        self.ops.nodeFunctionModule:setVisible(vis)
    end
end

--右下方的收缩条逻辑
function Menu:initRightBottomFunction()
    local ops = self.ops
    self.showFunctionId = {}
    -- table.insert(self.showFunctionId,{id = 10001,images = "images/otherIcon/iconActivity40001.png",text = "xxx",off={-100,20},size={227*0.7,220*0.7}})
    -- table.insert(self.showFunctionId,{id = 10001,images = "images/otherIcon/iconActivity40001.png",text = "xxx",off={0,20},size={227*0.7,220*0.7}})
    if GameLogic.useTalentMatch then
        local noticeAct
        local context = GameLogic.getUserContext()
        local actsData = context.activeData:getConfigableActs()
        local actsGroupType = context.activeData:getConfigableGroupsByType()
        for aid, act in pairs(actsData) do
            local alive, etime, redNum = true, 0, 0
            -- 当处于活动时间内时
            if ActivityLogic.checkActVisible(act) then
                etime = act.actEndTime
                redNum = context.activeData:getRedNum(aid, true)
            -- 当活动有配置预热时间时
            elseif act.actPreTime and act.actPreTime <= stime and act.actStartTime > stime then
                etime = act.actStartTime
            else
                alive = false
            end
            if alive then
                local atype = ActivityLogic.menuActType(act)
                if actsGroupType[atype] and actsGroupType[atype]["menuBottom"] then
                    noticeAct = actsGroupType[atype]
                end
            end
        end
        if noticeAct then
            table.insert(self.showFunctionId, {id=10010, images="images/otherIcon/iconNotice.png", name="actName170710", off={-20,0,0}})
        end
    end
    table.insert(self.showFunctionId,{id = 10001,images = "images/btnCustomerHelp1.png",name = "btnSet",off={-10,0,0},size={156*0.8,134*0.9}})

    -- 未来的程序大爷, 就不要在这两行之间做什么table.insert操作了
    local iconBeforTask = #self.showFunctionId
    table.insert(self.showFunctionId,{id = 10002,images = "images/btnMTask.png",name = "btnTask",off={0,0,0},size={142*0.8,161*0.9}})

    table.insert(self.showFunctionId,{id = 10012,images = "images/btnMHistory.png",name = "btnBag",off={0,0,0}})
    table.insert(self.showFunctionId,{id = 10003,images = "images/btnMHistory.png",name = "btnMsgs",off={0,0,0}})
    if GameSetting.shareConfig==1 then
        table.insert(self.showFunctionId,{id = 10004,images = "images/btnMBattle.png",name = "btnRank",off={0,0,0}})
    end
    if not GameLogic.useTalentMatch then
        table.insert(self.showFunctionId,{id = 10005,images = "images/otherIcon/iconActivity40001.png",name = "dataProsName13",off={0,0,0},size={227*0.7,220*0.8}})
        table.insert(self.showFunctionId,{id = 10006,images = "images/otherIcon/iconActivity40002.png",name = "dataResName1040",off={0,0,0},size={142*0.8,174*0.9}})
    else
        table.insert(self.showFunctionId, {id=10011, images="images/otherIcon/iconHeroExtract.png", name="btnExtracthero", off={0,0,0}})
    end
    -- 增加一个测试的对话框用于显示网页
    --table.insert(self.showFunctionId,{id = 10000,images = "images/btnMHistory.png",name = "TEST",off={0,0,0},size={167*0.8,176*0.8}})

    local functionNum = #self.showFunctionId
    local sx=180*functionNum+150
    if functionNum<=1 then
        sx = 0
    end
    ops.guideX = -sx+150+180*(iconBeforTask+0.5)

    if ops.nodeFunctionModule then
        ops.nodeFunctionModule:removeAllChildren(true)
    end

    GameEvent.bindEvent(self.view,"OCItem", self, function (p)
        self:showFunctionModule(p)
    end)

    local scrollNode=ui.scrollNode({sx,155}, 0, false, false)
    display.adapt(scrollNode, 0, 0, GConst.Anchor.RightBottom)
    ops.nodeFunctionModule:addChild(scrollNode,1)
    self.allFunctionView = scrollNode
    scrollNode:setInertia(false)
    scrollNode:setElastic(false)
    self.rightBottomScrollView=scrollNode:getScrollNode()

    local temp = ui.scale9("images/proBack2_2.png", {30, 60, 30, 60},{sx, 140})
    display.adapt(temp,0,0,GConst.Anchor.RightBottom)
    --temp:setOpacity(190)
    ops.nodeFunctionModule:addChild(temp)
    ops.menuFunctionBack = temp

    local but = ui.button({124,120}, nil, {})
    display.adapt(but, 70, 70, GConst.Anchor.Center)
    self.rightBottomScrollView:addChild(but,2)
    local btnImg = ui.sprite("images/newBtnNext.png",{49,80})
    display.adapt(btnImg,62,60,GConst.Anchor.Center)
    but:getDrawNode():addChild(btnImg)
    but:setScaleX(-1)
    ops.btnFunctionOc = but
    ops.btnFunctionOc:setScriptCallback(ButtonHandler(self.showFunctionModule,self,nil))

    self.redButNum = GameUI.addRedNum(self.rightBottomScrollView,0,100,0,0.8,99)
    self.redButNum:setVisible(false)

    for k,v in ipairs(self.showFunctionId) do
        --local bg = ops.nodeFunctionModule
        --if k>1 then
        local bg = self.rightBottomScrollView
        --end
        local imgName = v.images
        local bt = ui.button({150,150},nil,{})
        display.adapt(bt,180*k+v.off[1]+125,0+v.off[2],GConst.Anchor.RightBottom)

        local img = ui.sprite(imgName,v.size or {150,150})
        display.adapt(img,75,75,GConst.Anchor.Center)
        bt:getDrawNode():addChild(img)
        if v.id == 10001 then
            ops.btnSet = bt
        end
        if v.id == 10002 then
            ops.taskGuide = ops.nodeFunctionModule
            ops.btnTask = bt
            img:setFlippedX(true)
        end
        if v.id == 10003 then
            ops.btnMsgs = bt
        end
        if v.id == 10004 then
            ops.btnRank = bt
        end
        if v.id == 10006 then
            GameEvent.bindEvent(bt:getDrawNode(),"prestigeBtnRedNum",self,function ()
                local _n = GameLogic.getPrestigeRedNum()
                self.presOldRedNum = GEngine.getConfig("oldRedNum" .. GameLogic.getUserContext().uid) or 0
                self.presRedNum = _n - self.presOldRedNum
                if self.presRedNum < 0 then
                    self.presRedNum = 0
                end
            end)

            GameEvent.sendEvent("prestigeBtnRedNum")
        end
        if v.id == 10011 then
            ops.btnWishes=bt
        end
        if v.id == 10012 then
            ops.btnBag = bt
        end
        local _label = ui.label(Localize(v.name),General.font1, 30,{fontW=150,fontH=80})
        display.adapt(_label,75,v.off[3],GConst.Anchor.Bottom)
        bt:getDrawNode():addChild(_label)
        bt:setScriptCallback(ButtonHandler(self.doFunctionEntrance,self,v.id))
        bg:addChild(bt,2)
    end

    ops.btnFunctionOcState = true
    if functionNum == 0 or functionNum==1 then
        ops.menuFunctionBack:setVisible(false)
        ops.btnFunctionOc:setVisible(false)
    end
end

local TestHelpDialog = class(DialogViewLayout2)
function TestHelpDialog:onPvpReplay()
    local id = self.textBox:getText()
    local numId = tonumber(id)
    local sid = self.serverBox:getText()
    local numSid = tonumber(sid)
    if numId and numSid then
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("replaycheck",{rid = numId, sid=numSid, mode="pvp"},function(isSuc, data)
            GameNetwork.unlockRequest()
            if data.code == 0 then
                GameLogic.saveReplay("replay_" .. numId ..".json", data.jlist)
                GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvp, isReplay=true, rid=numId})
            else
                display.pushNotice("回放不存在")
            end
        end)
    end
end

function TestHelpDialog:onPvcReplay()
    local id = self.textBox:getText()
    local numId = tonumber(id)
    local sid = self.serverBox:getText()
    local numSid = tonumber(sid)
    if numId and numSid then
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("replaycheck",{rid = numId, sid=numSid, mode="pvc"},function(isSuc, data)
            GameNetwork.unlockRequest()
            if data.code == 0 then
                GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=const.BattleTypePvc, isReplay=true, battleReplayData=json.decode(data.jlist)})
            else
                display.pushNotice("回放不存在")
            end
        end)
    end
end

function TestHelpDialog:enterAnimate()
    return 0
end

function TestHelpDialog:exitAnimate()
    return 0
end

function TestHelpDialog:onPvlReplay()
    local id = self.textBox:getText()
    local numId = tonumber(id)
    local sid = self.serverBox:getText()
    local numSid = tonumber(sid)
    if numId and numSid then
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("replaycheck",{rid = numId, sid=numSid, mode="pvl"},function(isSuc, data)
            GameNetwork.unlockRequest()
            if data.code == 0 then
                local reData = json.decode(data.jlist)
                local battleParams = reData.battleParams
                battleParams.isReplay = data.jlist
                GameEvent.sendEvent(GameEvent.EventBattleBegin,{rid=numId,isReplay=true,type = 8, data=reData.foeData,bparams=battleParams})
            else
                display.pushNotice("回放不存在")
            end
        end)
    end
end

function TestHelpDialog:onInitDialog()
    self:setLayout({type="dialog",sx=1788,sy=1350,template=2, views={{id="webBack", type="node",sx=1744,sy=1185,x=22,y=22,anchor="LeftBottom"}}})
    self.title:setString("网页测试")
    self.priority = 1
    self:loadViewsTo()

    local testUid = GameLogic.getUserContext().uid
    if testUid == 96153 or testUid == 81022 or testUid == 103411 then
        self.title:setString("回放测试")

        local bg = self.webBack.view
        local temp, but

        temp = ui.label("输入回放ID", General.font1, 50, {color={255,255,255},width=800,align=GConst.Align.Left})
        display.adapt(temp, 185, 820, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        local textBox = ui.textBox({760, 84}, StringManager.getString("输入回放ID"), General.font6, 40, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
        display.adapt(textBox, 203, 760, GConst.Anchor.Left)
        bg:addChild(textBox)
        self.textBox = textBox

        temp = ui.label("输入服务器ID", General.font1, 50, {color={255,255,255},width=800,align=GConst.Align.Left})
        display.adapt(temp, 185, 620, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        textBox = ui.textBox({760, 84}, StringManager.getString("输入服务器ID"), General.font6, 40, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
        display.adapt(textBox, 203, 560, GConst.Anchor.Left)
        bg:addChild(textBox)
        self.serverBox = textBox

        temp=ui.button({361, 141},self.onPvpReplay,{cp1=self, image="images/btnGreen.png"})
        display.adapt(temp, 362, 154, GConst.Anchor.Center)
        bg:addChild(temp)
        but = temp:getDrawNode()
        temp = ui.label("PVP回放", General.font1, 55)
        display.adapt(temp, 180, 84, GConst.Anchor.Center)
        but:addChild(temp)

        temp=ui.button({361, 141},self.onPvcReplay,{cp1=self, image="images/btnGreen.png"})
        display.adapt(temp, 762, 154, GConst.Anchor.Center)
        bg:addChild(temp)
        but = temp:getDrawNode()
        temp = ui.label("PVC回放", General.font1, 55)
        display.adapt(temp, 180, 84, GConst.Anchor.Center)
        but:addChild(temp)

        temp=ui.button({361, 141},self.onPvlReplay,{cp1=self, image="images/btnGreen.png"})
        display.adapt(temp, 1162, 154, GConst.Anchor.Center)
        bg:addChild(temp)
        but = temp:getDrawNode()
        temp = ui.label("PVL回放", General.font1, 55)
        display.adapt(temp, 180, 84, GConst.Anchor.Center)
        but:addChild(temp)

    elseif ccexp.WebView then
        local webView = ccexp.WebView:create()
        webView:setContentSize(cc.size(self.webBack.size[1], self.webBack.size[2]))
        display.adapt(webView, 0, 0)
        self.webBack.view:addChild(webView)
        local url = "http://www.moyuplay.com/gamepage/coz2/ac1.html"
        local deviceInfo = json.decode(Native:getDeviceInfo())
        local language = "EN"
        if General.language == "CN" or General.language == "HK" then
            language = "CN"
        end
        local tab = os.date("*t",GameLogic.getSTime())
        local time=tab.year.."/"..tab.month.."/"..tab.day.."/"..tab.hour.."/"..tab.min.."/"..tab.sec
        local params = {rd=math.random(1, 999999), fte=time, game=Localize("GameName")}
        params.gvn = GEngine.rawConfig.version
        params.sne = Localize("dataServerName"..GameLogic.getUserContext().sid)
        params.uid = GameLogic.getUserContext().uid
        params.une = GameLogic.getUserContext():getInfoItem(const.InfoName)
        params.uvl = GameLogic.getUserContext():getInfoItem(const.InfoVIPlv)
        params.upe = (GameLogic.getUserContext().info[20] or 0)
        params.language = language
        params.dv = deviceInfo.model
        params.did = deviceInfo.deviceId
        params.sym = deviceInfo.version
        webView:loadURL(url .. "?" .. GameLogic.urlencode(params))
        webView:setScalesPageToFit(true)
        webView:setOnShouldStartLoading(Handler(self.onShouldStartLoading, self))
    end
end

function TestHelpDialog:onShouldStartLoading(webView, url)
    if url:find("usebrowse=1") then
        Native:openURL(url)
        return false
    elseif url:find("sendemail=1") then
        Plugins:feedback()
        return false
    end
    return true
end

function Menu:doFunctionEntrance(id)
    local context = GameLogic.getUserContext()
    if context.guide:getCurrentState() == 14 and id ~= 10002 then
        display.pushNotice(Localize("stringPleaseGuideFirst"))
        return
    end
    if id == 10001 then
       -- display.showDialog(TestHelpDialog.new())
        --display.showDialog(TrigglesBagDialog.new({id = 170401}))
        SystemSetDialog.new()
        --CommunityDialog.new()
    elseif id == 10002 then
        local dtid = GEngine.getConfig("taskId")
        -- TODO 兼容一下，不要超过最大数量
        if GameLogic.useTalentMatch and dtid and dtid > 2 then
            dtid = 2
        end
        AchievementDialog.new(dtid)
    elseif id == 10003 then
        local logData=GameLogic.getUserContext().logData
        LogDialog.new(logData:getOpenIndex(),logData.datas)
    elseif id == 10004 then
        AllRankingListDialog.new()
    elseif id == 10005  then
        display.showDialog(StrongerDialog.new())
    elseif id == 10006  then
        display.showDialog(PrestigeDialog.new())
    -- 增加一个测试对话框
    elseif id == 10000 then
        display.showDialog(TestHelpDialog.new())
    elseif id == 10007 then
        display.showDialog(HeroMainDialog.new({initTag="storage"}))
    elseif id == 10010 then
        local dialog = ActivityListDialog.new({menuActType = 6})
        if dialog and not dialog.deleted then
            display.showDialog(dialog)
        end
    elseif id == 10011 then
        GameLogic.doCondition(GameLogic.getUserContext(), const.ActTypeWishGet)
    elseif id == 10012 then
        local BagMainDialog = GMethod.loadScript("game.UI.NewDialog.bag_main_dialog")
        display.showDialog(BagMainDialog.new())
    end
end

function Menu:showFunctionModule(logo)
    local ops = self.ops
    if logo then
      if not ops.btnFunctionOcState then
        return
      end
    end

    ops.btnFunctionOcState = not ops.btnFunctionOcState
    if ops.btnFunctionOcState then
        local focusItem = self.scene.controller.focusItem
        if focusItem then
            focusItem:setFocus(false)
        end
    end

    local bg = self.rightBottomScrollView
    local functionNum = #self.showFunctionId
    local mx = 0
    local context = GameLogic.getUserContext()

    local speed = 800*(functionNum-1)
    local function moveView(diff)
        local curPos = bg:getPositionX()
        mx = mx + speed*diff
        if ops.btnFunctionOcState then
             if curPos==0 then
                curPos=(functionNum-1)*180
            end
            curPos = curPos - speed*diff
            if curPos < 0 then
                UnregTimeUpdate(bg)
                bg:setPositionX(0)
                ops.menuFunctionBack:setContentSize(cc.size(180*functionNum+150, 140))
                ops.btnFunctionOc:setScaleX(-1)
                self.redButNum:setVisible(false)
                if context.guide:getCurrentState() == 14 then
                    self.taskGuideHand:setPosition(ops.guideX,125)
                end
                return
            end
            self.allFunctionView:setContentSize(cc.size(180*functionNum+150, 155))
            bg:setPositionX(curPos)
            ops.menuFunctionBack:setContentSize(cc.size(180+mx, 140))
        else
            curPos = curPos + speed*diff
            if curPos > (functionNum-1)*180 then
                UnregTimeUpdate(bg)
                bg:setPositionX(0)
                ops.menuFunctionBack:setContentSize(cc.size(139, 140))
                self.allFunctionView:setContentSize(cc.size(139, 155))
                ops.btnFunctionOc:setScaleX(1)
                self:refreshFunctionRedNum()
                if context.guide:getCurrentState() == 14 then
                    self.taskGuideHand:setPosition(-90,125)
                end
                return
            end
            bg:setPositionX(curPos)
            ops.menuFunctionBack:setContentSize(cc.size(180*functionNum+100 - mx, 140))
        end
    end
    RegTimeUpdate(bg, moveView, 0.025)
end

function Menu:refreshFunctionRedNum()
    -- body
    if self.ops.btnFunctionOcState~=nil and not self.ops.btnFunctionOcState then
        local _num = GameLogic.getUserContext().logData:getRedNum() + self.taskRedNum
        if GameLogic.useTalentMatch then
            _num = _num + GameLogic.getUserContext():getFreeHeroChance()
        end
        if _num > 0 then
            if _num>99 then
                _num = 99
            end
            self.redButNum:setNum(_num)
            self.redButNum:setVisible(true)
            self.redButNum:setScale(0.8)
        end
    end
end

-- @brief 刷新所有活动（左上）
function Menu:updateActivitys()
    local context=GameLogic.getUserContext()
    local ops = self.ops
    local limitActive = context.activeData.limitActive
    local hotData = context.activeData.hotData
    local stime = GameLogic.getSTime()
    if not ops.menuActs then
        ops.menuActs = {}
        ops.menuActsList = {}
        ops.menuActsListRight = {}
    end
    local hasChange = false
    local menuActs = ops.menuActs
    local menuPris = {}
    -- menuActs[101] = limitActive[101] or 0
    --特定需要显示的
    -- 这个是首充礼包
    for _,v in pairs (hotData) do
        if v.atype == 51 and v.isget < 1 then
            if not menuActs[51] then
                menuActs[51] = {__order=1, actId=51, alive=true, menuIconEffect=2}
                table.insert(ops.menuActsList, menuActs[51])
            else
                menuActs[51].alive = true
            end
            -- 是否见过看过首充礼包了
            local isOpenFirstCharge = GEngine.getConfig("OpenFirstCharge"..GameLogic.getUserContext().uid)
            if v.gnum >= v.anum or not isOpenFirstCharge then
                menuActs[51].num = 1
            else
                menuActs[51].num = 0
            end
        end
    end
    if GameLogic.useTalentMatch then
        local sstime = math.floor((stime - const.InitTime) / 3600)
        if self.__tmGiftRefresh ~= sstime then
            self.__tmGiftRefresh = sstime
            local wk = GameLogic.getWeek(stime)
            if wk == 1 or wk == 3 or wk == 5 then
                self.__tmGiftEndTime = math.floor((stime-const.InitTime)/86400)*86400+86400+const.InitTime
            else
                self.__tmGiftEndTime = nil
            end
        end
        if self.__tmGiftEndTime and self.__tmGiftEndTime > stime then
            if not menuActs[52] then
                menuActs[52] = {__order=20, actId=52, alive=true, menuIconEffect=2,
                menuIcon="images/matchs/actBox.png",
                num=0}
                table.insert(ops.menuActsList, menuActs[52])
            else
                menuActs[52].alive = true
            end
        end
    end
    -- 强制先加一波FB按钮；之后换长线
    -- if GEngine.rawConfig.noCommunity ~= 1 and gameSetting.shareConfig ~= 0 then
    --     local vaid = 200
    --     if not menuActs[vaid] then
    --         menuActs[vaid] = {__order=1, actId=vaid, alive=true, menuIconEffect=3,
    --             menuIcon="images/otherIcon/iconFacebook.png", menuIconSize={129, 134},
    --             posRight = 1
    --         }
    --         table.insert(ops.menuActsListRight, menuActs[vaid])
    --     else
    --         menuActs[vaid].alive = true
    --     end
    --     if Localize("communityRedNode") ~= GEngine.getConfig("localRedNode") then
    --         menuActs[vaid].num = 1
    --     else
    --         menuActs[vaid].num = 0
    --     end
    -- end
    -- 伪装地加一波推广码并注释
    -- if GEngine.rawConfig.noCommunity ~= 1 and gameSetting.shareConfig ~= 0 then
    --     local vaid = 57
    --     if not menuActs[vaid] then
    --         menuActs[vaid] = {__order=2, actId=vaid, alive=true, menuIconEffect=1,
    --             menuIcon="images/otherIcon/iconActivity57.png", menuIconSize={169, 102},
    --             posRight = 1
    --         }
    --         table.insert(ops.menuActsListRight, menuActs[vaid])
    --     else
    --         menuActs[vaid].alive = true
    --     end
    --     menuActs[vaid].num = GameLogic.getSpreadAndRewardRedNum()
    -- end
    local actsGroup = context.activeData:getConfigableGroups()
    local actsGroupType = context.activeData:getConfigableGroupsByType()
    for aid, agroup in pairs(actsGroup) do
        if menuActs[aid] then
            menuActs[aid].num = 0
            menuActs[aid].etime = 0
        end
    end
    local actsData = context.activeData:getConfigableActs()
    for aid, act in pairs(actsData) do
        local alive, etime, redNum = true, 0, 0
        -- 当处于活动时间内时
        if ActivityLogic.checkActVisible(act) then
            etime = act.actEndTime
            redNum = context.activeData:getRedNum(aid, true)
        -- 当活动有配置预热时间时
        elseif act.actPreTime and act.actPreTime <= stime and act.actStartTime > stime then
            etime = act.actStartTime
        else
            alive = false
        end
        if alive then
            if act.menuOrder then
                if not menuActs[aid] then
                    menuActs[aid] = {__order=act.menuOrder, actId=aid, alive=true,
                        menuIcon = act.menuIcon, menuIconSize = act.menuIconSize,
                        menuIconScale = act.menuIconScale,
                        ox = act.ox, oy = act.oy
                    }
                    table.insert(ops.menuActsList, menuActs[aid])
                else
                    menuActs[aid].alive = true
                end
                menuActs[aid].num = redNum
                menuActs[aid].etime = etime
                if act.menuPri then
                    local preAct = menuPris[act.menuPri[1]]
                    if not preAct then
                        menuPris[act.menuPri[1]] = act
                    elseif preAct.menuPri[2] > act.menuPri[2] then
                        menuPris[act.menuPri[1]] = act
                        menuActs[preAct.actId].alive = false
                    else
                        menuActs[aid].alive = false
                    end
                end
            end
            local atype = ActivityLogic.menuActType(act)
            -- 屏蔽通用活动，虽然不知道为啥
            if GameSetting.shareConfig == 0 and atype == 1 then
                atype = nil
            end
            if atype and actsGroupType[atype] then
                local agroup = actsGroupType[atype]
                local agid = agroup.menuActId
                if agid then
                    if not menuActs[agid] then
                        menuActs[agid] = {__order=agroup.menuOrder, actId=agid, alive=true, num=0, etime=0,
                            menuIcon = agroup.menuIcon, menuIconSize = agroup.menuIconSize,
                            menuIconScale = agroup.menuIconScale, menuIconEffect = agroup.menuIconEffect,
                            ox = agroup.ox, oy = agroup.oy, hiddenTime = agroup.hiddenTime
                        }
                        if agroup.menuOrder then
                            table.insert(ops.menuActsList, menuActs[agid])
                        else
                            table.insert(ops.menuActsListRight, menuActs[agid])
                            menuActs[agid].__order = agroup.menuRightOrder or 3
                            menuActs[agid].posRight = 1
                        end
                    else
                        menuActs[agid].alive = true
                    end
                    menuActs[agid].num = menuActs[agid].num + redNum
                    if menuActs[agid].etime == 0 or (etime > 0 and menuActs[agid].etime > etime) then
                        menuActs[agid].etime = etime
                    end
                end
            end
        end
    end
    for aid, actInfo in pairs(menuActs) do
        if actInfo.alive then
            actInfo.alive = false
            if not actInfo.button or tolua.isnull(actInfo.button) then
                local bg = ops.nodeActivity
                if actInfo.posRight == 1 then
                    bg = ops.nodeActivityRight
                end
                local but = ui.button({150,150}, nil, {})
                bg:addChild(but)
                local imgKey = actInfo.menuIcon or ("images/otherIcon/iconActivity".. aid ..".png")
                local temp
                -- 临时改一下
                if imgKey == "UICsb/acts/xmas.csb" then
                    imgKey = "UICsb/acts/xmasIcon.csb"
                    actInfo.menuIconScale = 0.8
                elseif imgKey == "images/otherIcon/iconActivity70000.png" then
                    actInfo.menuIconSize = {130, 130}
                end
                if cc.FileUtils:getInstance():isFileExist(imgKey) then
                    -- 用CSB做节点
                    if imgKey:find(".csb") then
                        temp = ui.simpleCsbEffect(imgKey, true, 0)
                        temp:setScale(actInfo.menuIconScale or 1)
                    else
                        temp = ui.sprite(imgKey, actInfo.menuIconSize or {150,150}, true)
                    end
                    display.adapt(temp, 75+(actInfo.ox or 0), 75+(actInfo.oy or 0), GConst.Anchor.Center)
                    but:getDrawNode():addChild(temp)
                end
                actInfo.button = but
                actInfo.redNum = GameUI.addRedNum(but, 100, 70, 3, 0.8, 10000)
                temp = ui.label("", General.font1, 28, {color={105,245,57}})
                display.adapt(temp, 75, 10, GConst.Anchor.Center)
                but:getDrawNode():addChild(temp, 1)
                actInfo.leftTimeLabel = temp
                but:setScriptCallback(ButtonHandler(self.doActivity, self, actInfo.actId))
                -- 加特效
                if actInfo.menuIconEffect == 1 then
                    UIeffectsManage:showEffect_duijiuanniu(but, 50, 60)
                elseif actInfo.menuIconEffect == 2 then
                    UIeffectsManage:showEffect_shouchonganniu(but, 85, 70, nil, 0.48)
                elseif actInfo.menuIconEffect == 3 then
                    UIeffectsManage:showEffect_facebook(but:getDrawNode(), 75, 85)
                end
                hasChange = true
            end
            if not actInfo.etime or actInfo.etime <= stime or actInfo.hiddenTime then
                actInfo.leftTimeLabel:setVisible(false)
            else
                actInfo.leftTimeLabel:setVisible(true)
                actInfo.leftTimeLabel:setString(Localizet(actInfo.etime - stime))
            end
            actInfo.redNum:setNum(actInfo.num)
        else
            if actInfo.button and not tolua.isnull(actInfo.button) then
                actInfo.button:removeFromParent(true)
                actInfo.button = nil
                hasChange = true
            end
            menuActs[aid] = nil
        end
    end
    if hasChange then
        local j = 1
        local olist = ops.menuActsList
        while j <= #olist do
            if not olist[j].button then
                table.remove(olist, j)
            else
                j = j + 1
            end
        end
        GameLogic.mySort(olist, "__order")
        for j, actInfo in ipairs(olist) do
            display.adapt(actInfo.button, (j-1)*180, 0, GConst.Anchor.LeftBottom)
            if GameLogic.useTalentMatch and j > 3 then
                actInfo.button:setVisible(false)
            else
                actInfo.button:setVisible(true)
            end
        end
        -- 右侧
        j = 1
        olist = ops.menuActsListRight
        while j <= #olist do
            if not olist[j].button then
                table.remove(olist, j)
            else
                j = j + 1
            end
        end
        GameLogic.mySort(olist, "__order")
        for j, actInfo in ipairs(olist) do
            display.adapt(actInfo.button, (1-j)*170 - 15, 0, GConst.Anchor.Center)
        end
    end
end

function Menu:initBattle()
    local battle = ViewLayout.new()
    battle:setLayout("BattleMenu.json")
    display.adapt(battle.view, 0, 0)
    self.view:addChild(battle.view)
    battle:loadViewsTo()
    self.battle = battle
    self.battleData = self.scene.battleData

    battle.btnEndBattle:setScriptCallback(ButtonHandler(self.exitBattleScene, self))

    local temp
    local node = battle.nodeBattleBottom.view
    battle.angerProcess:setScaleProcess(true,0)
    battle.butAutoBattle:setGray(true)
    for i=1,10 do
        temp = ui.sprite("images/angerSanJiao.png",{14,12})
        display.adapt(temp, 160*i-5, 28+11, GConst.Anchor.LeftBottom)
        node:addChild(temp)
        if i~=10 then
            temp = ui.sprite("images/angerSuTiao.png",{3,18})
            display.adapt(temp, 160*i+80, 26, GConst.Anchor.LeftBottom)
            node:addChild(temp)
        end
    end
    self.realStart = false
end

--TODO 之后加的时候，战斗场景一定要是context和econtext
function Menu:initBattleData()
    local battle = self.battle
    local bdata = self.scene.battleData
    local context = GameLogic.getCurrentContext()
    local ucontext = GameLogic.getUserContext()
    local name = context:getInfoItem(const.InfoName)
    if name=="" then
        name = "TEST" .. (context.uid or 0)
    end
    --TODO 初始化对手头像/名字/等级 等逻辑
    battle.nodeLeftHead:removeAllChildren(true)
    battle.nodeRightHead:removeAllChildren(true)
    battle.leftHead = {headScale=0.92,isLeft=true, name=name, iconType=200101, level=context:getInfoItem(const.InfoLevel)}
    battle.rightHead = nil

    battle.nodeBattlePercent:setVisible(false)
    battle.btnBattleNext:setVisible(false)
    local scene = self.scene
    if scene.battleType==const.BattleTypePvp then
        battle:addLayout("battlePvp")
        battle:loadViewsTo()
        battle.labelBattleGetScore:setString(N2S(scene.battleParams.winScore))
        battle.labelBattleLoseScore:setString(N2S(scene.battleParams.loseScore))
        if not scene.revenge then--复仇不显示下一个
            battle.btnBattleNext:setVisible(true)
        end
        battle.btnBattleNext:setScriptCallback(ButtonHandler(self.nextPvpBattle, self))
        local cost = ucontext:getPvpCost()
        battle.labelGoldNextCost:setString(N2S(cost))
        if cost<=ucontext:getRes(const.ResGold) then
            battle.labelGoldNextCost:setColor(GConst.Color.White)
        else
            battle.labelGoldNextCost:setColor(GConst.Color.Red)
        end
        battle.leftHead.iconType = context:getInfoItem(const.InfoHead) or 200101
        if battle.leftHead.iconType < 100101 then
            battle.leftHead.iconType = 200101
        end
    elseif scene.battleType==const.BattleTypePve then
        -- local isShow = GEngine.getConfig("sixthGuanGuide"..ucontext.uid) or 0
        -- if GameLogic.useTalentMatch and scene.battleParams.from and scene.battleParams.from == "PveGuide" and isShow < 1 then
        --     display.showDialog(StoryDialog.new({ucontext=ucontext,storyIdx=309,heroId=3005, callback=function ()
        --         GEngine.setConfig("sixthGuanGuide"..ucontext.uid, 1, true)
        --         GEngine.saveConfig()
        --     end}),false,true)
        -- end
        battle.leftHead.noHead=true
        battle.leftHead.name = Localize("dataPvePassName" .. scene.battleParams.stage)
        battle:addLayout("battlePve")
        battle:loadViewsTo()
        if scene.battleParams.stage==const.HeroInfoNewTry then
            battle.leftHead.name=Localize("labelHeroInfoTry")
            battle.labelBattleGetGold:setVisible(false)
            battle.labelBattleGetBeercup:setVisible(false)
            battle.labelBattleGetZhanhun:setVisible(false)
            battle.labelBattleGetExp:setVisible(false)
            battle.iconBattleGetGold:setVisible(false)
            battle.iconBattleGetBeercup:setVisible(false)
            battle.iconBattleGetZhanhun:setVisible(false)
            battle.iconBattleGetExp:setVisible(false)
            bdata.time = nil
        elseif scene.battleParams.stage==0 then
            battle.nodePveGet:setVisible(false)
            battle.nodeBattleTop:setVisible(false)
            bdata.time = nil
        else
            battle.labelBattleGetGold:setVisible(false)
            battle.labelBattleGetBeercup:setVisible(false)
            battle.labelBattleGetZhanhun:setVisible(false)
            battle.labelBattleGetExp:setVisible(false)
            battle.iconBattleGetGold:setVisible(false)
            battle.iconBattleGetBeercup:setVisible(false)
            battle.iconBattleGetZhanhun:setVisible(false)
            battle.iconBattleGetExp:setVisible(false)
            if scene.battleParams.firstRwds then
                battle.labelAvailable:setString(Localize("labelAvailable"))
                local items = scene.battleParams.firstRwds
                local bg = battle.nodePveGet
                for i=1,#items do
                    GameUI.addItemIcon(bg,items[i][1],items[i][2],0.4,86,293-i*89)
                    local labNum = ui.label(tostring(items[i][3]), General.font1, 38)
                    display.adapt(labNum, 132, 293-i*89, GConst.Anchor.Left)
                    bg:addChild(labNum)
                end
            end
        end
    elseif scene.battleType==const.BattleTypePvc then
        local econtext = context.enemy
        battle.leftHead = {headScale=0.92,isLeft=true, name=context:getInfoItem(const.InfoName), iconType=context:getInfoItem(const.InfoHead), level=context:getInfoItem(const.InfoLevel)}
        battle.rightHead = {headScale=0.92,name=econtext:getInfoItem(const.InfoName), iconType=econtext:getInfoItem(const.InfoHead), level=econtext:getInfoItem(const.InfoLevel)}
        if scene.sceneType=="prepare" then
            battle:addLayout("preparePvc")
            bdata.time = 180
            battle.nodeBattleBottom:setVisible(false)
        else
            battle:addLayout("battlePvc")
            bdata.time = 180
            bdata.state = 1
            self.realStart = true
        end
        battle:loadViewsTo()
        -- local score = econtext:getInfoItem(const.InfoScore)
        -- battle.labelBattleEScore:setString(N2S(score))
        -- score = context:getInfoItem(const.InfoScore)
        -- battle.labelBattleUScore:setString(N2S(score))
        local eRank = scene.battleParams.eRank or 0
        local myRank = scene.battleParams.myRank or 0
        battle.labelBattleEScore:setString(N2S(eRank))
        battle.labelBattleUScore:setString(N2S(myRank))
        if scene.sceneType=="prepare" then
            battle.btnBattleStart:setScriptCallback(ButtonHandler(self.startBattle, self))
        end
    elseif scene.battleType == const.BattleTypePvz then
        battle:addLayout("battlePvz")
        battle:loadViewsTo()
        local enemyData = context.enemyData
        battle.leftHead = {headScale=0.92,isLeft=true, name=enemyData.name, iconType=enemyData.head, level=enemyData.lv}
        battle.rightHead = {headScale=0.92,name=context:getInfoItem(const.InfoName), iconType=context:getInfoItem(const.InfoHead), level=context:getInfoItem(const.InfoLevel)}

        local tcontext = GameLogic.getCurrentContext()
        local reborn = tcontext.pvzData.reborn
        local stage = tcontext.pvzData.stage
        local stageName = tcontext.pvzData.stageName
        local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")

        battle.nd_reborn:setVisible(false)
        battle.nd_stage:setVisible(false)
        battle.labelBattlePercentDes:setVisible(false)
        battle.lb_battleScoreDes:setVisible(false)
        battle.lb_battleScore:setVisible(false)


        local type = tcontext.pvzData.type
        if type == 0 then
            battle.nd_reborn:setVisible(true)
            battle.nd_stage:setVisible(true)
            battle.lb_battleScoreDes:setVisible(true)
            battle.lb_battleScore:setVisible(true)
            KnockMatchData:changeStageIcon(battle.img_stage, stage)
            -- local path = KnockMatchData:getStageIconPath(stage)
            -- battle.img_stage.view:setTexture(path)
            battle.lb_scoreDes:setString(stageName)
        elseif type == 1 then
            battle.nd_reborn:setVisible(true)
            battle.nd_stage:setVisible(false)
            battle.lb_battleScoreDes:setVisible(true)
            battle.lb_battleScore:setVisible(true)
        elseif type == 2 then
            battle.nd_reborn:setVisible(false)
            battle.nd_stage:setVisible(false)
            battle.labelBattlePercentDes:setVisible(true)
        end
        battle.lb_reborn:setString(reborn)
        battle.lb_rebornDes:setString(Localizef("labRebornDes", {num = reborn}))
    elseif scene.battleType==const.BattleTypePvh then
        local econtext = context.enemy
        battle.leftHead = {headScale=0.92,isLeft=true, name=ucontext:getInfoItem(const.InfoName), iconType=ucontext:getInfoItem(const.InfoHead), level=ucontext:getInfoItem(const.InfoLevel)}
        battle.rightHead = {headScale=0.92,name=econtext:getInfoItem(const.InfoName), iconType=econtext:getInfoItem(const.InfoHead), level=econtext:getInfoItem(const.InfoLevel)}
        if scene.sceneType=="prepare" then
            battle:addLayout("preparePvh")
            bdata.time = 180
            battle.nodeBattleBottom:setVisible(false)
        else
            battle:addLayout("battlePvh")
            bdata.time = 180
            bdata.state = 1
            self.realStart = true
        end
        battle:loadViewsTo()
        if econtext:getInfoItem(const.InfoScore) == 0 then
            battle.labelBattleMagic:setVisible(false)
            battle.nodeBattleMagic:setVisible(false)
        else
            battle.labelBattleMagic:setString(N2S(econtext:getInfoItem(const.InfoScore)))
        end
        if self.scene.battleParams.nightmare then
            battle.nodeBattleRT:setVisible(false)
            if scene.sceneType == "prepare" then
                battle.btnInspire:setVisible(false)
            end
        end
        if scene.sceneType=="prepare" then
            battle.btnBattleStart:setScriptCallback(ButtonHandler(self.startBattle, self))
            battle.btnInspire:setScriptCallback(ButtonHandler(self.onInspireBattle, self))
            self:reloadInspireData()
        end
    elseif scene.battleType==const.BattleTypePvj then
        battle.leftHead = {headScale=0.92,isLeft=true, name=ucontext:getInfoItem(const.InfoName), iconType=ucontext:getInfoItem(const.InfoHead), level=ucontext:getInfoItem(const.InfoLevel)}
        battle.rightHead = {headScale=0.92,name=Localize("dataPvjPassName" .. scene.battleParams.index), noHead=true}
        battle:addLayout("battlePvj")
        battle:loadViewsTo()
        battle.nodeBattleBottom:setVisible(false)
        battle.btnBattleStart:setScriptCallback(ButtonHandler(self.startBattle, self))
        battle.butRate:setVisible(false)
        battle.timeValue2:setVisible(false)

        if scene.battleParams.DRPvj then
            battle.rateNum = 1
            battle.butRateValue:setString("X" .. battle.rateNum)
            bdata.time = 3
            battle.timeValue2.isShow = true
            local function changeSpeed()
               if battle.rateNum<4 then
                    battle.rateNum = battle.rateNum*2
                else
                    battle.rateNum = 1
                end
                GameLogic.setSchedulerScale(battle.rateNum)
                battle.butRateValue:setString("X" .. battle.rateNum)
            end
            battle.butRate:setScriptCallback(ButtonHandler(changeSpeed, self))
            battle.timeValue2:setVisible(true)
            battle.btnBattleStart:setVisible(false)
            battle.rightHead.name = ""
            -- self:startBattle(self)
        end

        if ucontext.guide:getStep().type == "pvj" then
            local w = display.winSize[1]
            local h = display.winSize[2]
            local but = ui.button(display.winSize, nil, {actionType = 0})
            display.adapt(but, 0, 0)
            self.view:addChild(but, 10000)
            self.camara = but
            local temp = ui.colorNode({w, h/8}, {0, 0, 0, 255})
            temp:setPosition(0, h*7/8)
            but:addChild(temp)
            temp = ui.colorNode({w, h/8}, {0, 0, 0, 255})
            temp:setPosition(0, 0)
            but:addChild(temp)
        end
    elseif scene.battleType == const.BattleTypeUPve then
        battle.leftHead = {headScale=0.92,isLeft=true,name = ucontext:getInfoItem(const.InfoName),iconType=ucontext:getInfoItem(const.InfoHead), level=ucontext:getInfoItem(const.InfoLevel)}
        battle.rightHead = {headScale=0.92,name=Localize("dataPvjPassName" .. scene.battleParams.index), noHead=true}
        battle:addLayout("battleUPve")
        battle:loadViewsTo()
        battle.butRateValue:setVisible(false)
        battle.butRate:setVisible(false)
        battle.butRate:setEnable(false)
        battle.lab_lv:setVisible(false)
    elseif scene.battleType == const.BattleTypeUPvp then
        battle.leftHead = {headScale=0.92,isLeft=true, name=ucontext:getInfoItem(const.InfoName), iconType=ucontext:getInfoItem(const.InfoHead), level=ucontext:getInfoItem(const.InfoLevel)}
        battle.rightHead = {headScale=0.92,name=context:getInfoItem(const.InfoName), iconType=context:getInfoItem(const.InfoHead), level=context:getInfoItem(const.InfoLevel)}
        battle:addLayout("battleUPvp")
        battle:loadViewsTo()
        local x,y = battle.nodeBattleTop:getPosition()
        battle.nodeBattleTop:setPosition(x,y-90*ui.getUIScale2())
        local pvldata = scene.battleParams.pvldata
        local addlv = pvldata.addlv
        battle.labelLeftHp:setString(SG("label_addHp").."+" .. 5*addlv[1] .. "%")
        battle.labelLeftHarm:setString(SG("label_addDmg").."+" .. 5*addlv[2] .. "%")
        battle.labelRightHp:setString(SG("label_addHp").."+" .. 5*addlv[3] .. "%")
        battle.labelRightHarm:setString(SG("label_addDmg").."+" .. 5*addlv[4] .. "%")

        battle.nodeLeftHead.view:setPositionY(362)
        battle.nodeRightHead.view:setPositionY(362)
    elseif scene.battleType == const.BattleTypePvb then

        battle.leftHead = nil
        --{headScale=0.92,isLeft=true,name = ucontext:getInfoItem(const.InfoName),iconType=ucontext:getInfoItem(const.InfoHead), level=ucontext:getInfoItem(const.InfoLevel)}
        battle.rightHead = nil
        --{headScale=0.92,name=Localize("dataPvjPassName" .. scene.battleParams.index), noHead=true}
        battle:addLayout("battleUPve")
        battle:loadViewsTo()
        battle.rateNum = 1
        battle.butRateValue:setString("X" .. battle.rateNum)
        local function changeSpeed()
            if battle.rateNum<4 then
                battle.rateNum = battle.rateNum*2
            else
                battle.rateNum = 1
            end
            GameLogic.setSchedulerScale(battle.rateNum)
            battle.butRateValue:setString("X" .. battle.rateNum)
        end
        battle.butRate:setScriptCallback(ButtonHandler(changeSpeed, self))
        local bossLv = SData.getData("godBeastBoss", scene.battleParams.aid, scene.battleParams.stage).lv
        battle.lab_lv:setString(Localizef("labelFormatLevel", {level = bossLv}))
    end
    GameUI.updateUserHeadTemplate(battle.nodeLeftHead.view, battle.leftHead)
    if battle.rightHead then
        battle.rightHead.lvRT=true
    end
    GameUI.updateUserHeadTemplate(battle.nodeRightHead.view, battle.rightHead)

    if bdata.time then
        if bdata.state==0 then
            battle.labelTimeLeft:setString(Localize("labelBattleStart"))
        else
            battle.labelTimeLeft:setString(Localize("labelBattleEnd"))
        end
        battle.labelTimeValue:setString(Localizet(bdata.time))
    else
        battle.labelTimeLeft:setVisible(false)
        battle.labelTimeValue:setVisible(false)
    end
    self.selectedItem = nil
    if scene.isBattle then
        local dd = ucontext
        if context.enemy then
            dd = context
        end
        bdata:initMenuDatas(dd)
        battle.angerProcess:setScaleProcess(true, 0)
        battle.labelDouqiValue:setString(Localizef("aDivideB", {a=0, b=10}))
        local temp
        temp = ui.node()
        display.adapt(temp, 0, 0)
        battle.nodeBattleBottom:addChild(temp)
        local bg = temp
        local mgroup = bdata.groups[1]
        local oox,hnum = 0,5

        if scene.battleType == const.BattleTypeUPvp then
            oox,hnum = -76,6
            battle.butAutoBattle:setVisible(false)
        elseif scene.battleType == const.BattleTypePve and scene.battleParams.stage==const.HeroInfoNewTry then
            oox,hnum = 0, scene.battleParams.hnum or 1
            battle.butAutoBattle:setVisible(false)
        else
            --自动战斗按钮
            battle.butAutoBattle:setScriptCallback(ButtonHandler(function()
                print("自动战斗")
                local cmd = {t=CMDTYPE.autoBT}
                self.scene.replay:addCmd(cmd)
            end))
            battle.butAutoBattle:setGray(true)
            local stage = self.scene.battleParams.stage
            if stage and stage == 0 then
                battle.butAutoBattle:setVisible(false)
            end
            local context = GameLogic.getUserContext()
            if context:getInfoItem(const.InfoLevel)<5 then
                battle.butAutoBattle:setVisible(false)
            end
            if scene.battleType == const.BattleTypePvh then
                battle.angerProcess:setScaleProcess(true, mgroup.anger / 10)
                battle.labelDouqiValue:setString(Localizef("aDivideB", {a=tostring(math.floor(mgroup.anger*2)/2), b=10}))
            end
        end
        if mgroup.hitems then
            battle.heroBut={}--英雄按钮
            battle.godBut={}--天神技按钮
            for i=1, hnum do
                local item = {idx=i, groupData=mgroup}
                temp=ui.button({178, 245}, self.onTouchHero,{cp1=self, cp2=item})
                display.adapt(temp, 135+202*i+oox,198,GConst.Anchor.Center)
                bg:addChild(temp)
                battle.heroBut[i]=item
                item.view = temp:getDrawNode()
                GameUI.updateBattleHeroTemplate(item)

                local hero = mgroup.hitems[i].hero
                if hero and (hero.awakeUp>=5 or hero.hid == 8103 and hero.awakeUp>0) then
                    local but = ui.button({120,120},nil,{})
                    display.adapt(but, 135+202*i+oox,450,GConst.Anchor.Center)
                    bg:addChild(but, -1)
                    but:setVisible(false)
                    but:setListener(function()
                        local context = GameLogic.getUserContext()
                        if context.guide:getStep().type == "pauseForGodSkill" and context.guide:getStepState() == 1 then
                            context.guide:setStepState(2)
                            context.guideHand:removeHand()
                            display.removeGuide()
                        end

                        --天神技使用
                        local cmd = {t=CMDTYPE.useGSK,ps={mgroup.hitems[i].hpos}}
                        self.scene.replay:addCmd(cmd)
                        hero.releasedGodSkill = hero.sid
                    end)
                    local _sptime = hero.awakeStat and hero.awakeStat.skills[5].data.cd or 0
                    if scene.battleType==const.BattleTypePve and (scene.battleParams.stage==const.HeroInfoNewTry or GameLogic.getUserContext().guide:getStep().type ~= "finish") then
                        _sptime = 0
                    end
                    --local as = hero:getAwakeSkill(hero.awakeUp)
                    --显示天神技图标
                    local as = hero:getAwakeSkill(5)
                    if hero.hid == 4031 then
                        but.heroState = hero.heroState
                    end
                    but.image = GameUI.addSkillIcon(but:getDrawNode(), 5, as.id, 1/3, 60, 60, 0)
                    temp = ui.sprite("images/iconGodSkillBack.png")
                    display.adapt(temp, 60, 60, GConst.Anchor.Center)
                    but:getDrawNode():addChild(temp)
                    --temp:setVisible(false)
                    --天神技进度
                    local sp = ui.scale9("images/proBack1_2.png", 27, {120, 120})
                    local timePro = cc.ProgressTimer:create(sp)
                    display.adapt(timePro, 60, 60, GConst.Anchor.Center)
                    but:getDrawNode():addChild(timePro)
                    timePro:setReverseDirection(true)
                    timePro.time = 0
                    timePro.sptime = _sptime
                    battle.godBut[i] = {but = but,used = false,canSkill=temp,timePro=timePro}
                end
            end
            if scene.battleType <= const.BattleTypePve or scene.battleType == const.BattleTypePvt or scene.battleType >= const.BattleTypeUPve then
                self:onTouchHero(battle.heroBut[1])
            end
        end
        if mgroup.witems then
            battle.weaponButs = {}
            for i,witem in ipairs(mgroup.witems) do
                local item = {idx=i, witem=witem, wid=witem.wid}
                local pyx = 0
                temp=ui.button({160,221},self.onTouchWeapon,{cp1=self, cp2=item})
                display.adapt(temp, 1395+181*(i-1)+160/2+pyx, 76+221/2, GConst.Anchor.Center)
                bg:addChild(temp)
                battle.weaponButs[i]=item
                item.view = temp:getDrawNode()
                GameUI.updateBattleWeaponTemplate(item)
            end
        end
        local egroup = bdata.groups[2]
        if egroup.hitems then
            temp = ui.node()
            temp:setScale(0.9)
            display.adapt(temp, 40, 0)
            battle.nodeBattleRT:addChild(temp)
            bg = temp
            battle.eheroBut = {}
            for i=1,5 do
                if egroup.hitems[i] then
                    local item = {idx=i, groupData=egroup}
                    temp=ui.node({146, 202}, true)
                    display.adapt(temp, 353, 12-(i-1)*207,GConst.Anchor.LeftBottom)
                    bg:addChild(temp)
                    battle.eheroBut[i]=item
                    item.view = temp
                    GameUI.updateEnemyHeroTemplate(item)
                end
            end
        end

        if egroup.bsitems then
            battle.ebossBut = {}
            local bg =battle.nodeBattleRT
            local index=0
            for i=1,10 do
                if egroup.bsitems[i] then
                    local v=egroup.bsitems[i]
                    index=index+1
                    local item = {idx = index, groupData = egroup, role = v.role}
                    battle.ebossBut[index] = item
                    local temp = ui.node({146,202},true)
                    display.adapt(temp,236,412-130*index,GConst.Anchor.Center)
                    bg:addChild(temp)
                    item.view = temp
                    GameUI.updateBattleBossTemplate(item)
                end
            end
        end
        local function updateBattle(_, diff)
            bdata:updateBattle(diff)
        end
        scene.replay:addUpdateObj({update=updateBattle})
    end

    --引导
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "pvj" then
        battle:setVisible(false)
        music.setBgm("music/battleDefence.mp3")
        scene.mapView:getBatch():setVisible(false)
    end
end

--远征鼓舞逻辑
function Menu:reloadInspireData()
    local battle = self.battle
    local context = GameLogic.getUserContext()
    local pvh = self.scene.battleParams.nightmare and context.npvh or context.pvh
    local _,cost,percent = pvh:getInspireData()
    if cost>0 then
        battle.nodeCostItem:setVisible(true)
        battle.labelCostNum:setString(N2S(cost))
        if cost>context:getRes(const.ResCrystal) then
            battle.labelCostNum:setColor(GConst.Color.Red)
        else
            battle.labelCostNum:setColor(GConst.Color.White)
        end
    else
        battle.nodeCostItem:setVisible(false)
    end
    battle.labelInpireEffect:setString(Localizef("labelInspireEffect",{percent=percent}))
end

function Menu:onInspireBattle()
    local battle = self.battle
    local context = GameLogic.getUserContext()
    local pvh = self.scene.battleParams.nightmare and context.npvh or context.pvh
    local _,cost,percent = pvh:getInspireData()
    if cost==0 then
        --弹出鼓舞次数已满提示？
        display.pushNotice(Localize("stringInspireFull"))
        return
    end
    if cost>context:getRes(const.ResCrystal) then
        display.pushNotice(Localizef("noticeItemNotEnough",{name=Localize("dataResName" .. const.ResCrystal)}))
        return
    end
    local battle = self.battle
    local inum,cost,_ = pvh:getInspireData()
    pvh.inum = inum+1
    context:changeRes(const.ResCrystal, -cost)
    GameLogic.statCrystalCost("远征鼓舞消耗",const.ResCrystal, -cost)
    if self.scene.battleParams.nightmare then
        context:addCmd({const.CmdnPvhInspire})
        context.talentMatch:saveTalentMatchPvh()
    else
        context:addCmd({const.CmdPvhInspire})
    end
    if battle then
        self:reloadInspireData()
    end
    local inum,cost,percent = pvh:getInspireData()
    display.pushNotice(Localizef("noticeInspireSuccess",{num=percent}))
    UIeffectsManage:showEffect_GuWu(self.battle.btnInspire.view,150,150,10)
    music.play("sounds/inspire.mp3")
end

function Menu:onTouchHero(item)
    if self.scene.replay.locked then
        return
    end
    if item then
        local groupData = item.groupData
        local hitem = groupData.hitems[item.idx]
        if not hitem.hpos then
            return
        end
        local hero = groupData.heros[hitem.hpos]
        if hero and type(hero) ~= "number" then
            if type(hero) ~= "table" then
                GameLogic.otherGlobalInfo = {"hero in batlle", hero, hitem.hpos}
            end
            if not hero.deleted then
                --此处应该需要加到replay逻辑中？
                --引导
                local context = GameLogic.getUserContext()
                if context.guide:getStep().type == "pauseForSkill" and context.guide:getStepState() == 1 then
                    --context.guide:addStep()
                    context.guideHand:removeHand()
                    display.removeGuide()
                    context.guide:addStep()
                    --先不要了
                    -- local guideArrow=context.guideHand:showArrow(self.battle.nodeBattleBottom.view,1600,53,20)
                    -- display.showDialog(StoryDialog.new({context=context,storyIdx=301,callback=function()
                    --     context.guide:addStep()
                    --     guideArrow:removeFromParent(true)
                    -- end}),false,true)
                elseif groupData.showGuide == 2 then
                    groupData.showGuide = 3
                    context.guideHand:removeHand()
                end
                local cmd = {t=CMDTYPE.useSK, ps={hitem.hpos}}
                self.scene.replay:addCmd(cmd)
            end
            return
        end
    end
    self:selectItem(item)
end

function Menu:selectItem(item)
    if item==self.selectedItem then
        return
    end
    if self.selectedItem then
        self.selectedItem.selected = nil
    end
    self.selectedItem = item
    if self.selectedItem then
        self.selectedItem.selected = true
    end
end

function Menu:onTouchWeapon(item)
    if self.scene.replay.locked then
        return
    end
    if item and item.witem.use>=item.witem.num then
        return
    end
    self:selectItem(item)
end

function Menu:nextPvpBattle()
    if self.scene.replay.locked then
        return
    end
    local context = GameLogic.getUserContext()
    local cost = context:getPvpCost()
    if cost>context:getRes(const.ResGold) then
        display.showDialog(AlertDialog.new({ctype=const.ResGold, cvalue=cost, callback=Handler(self.nextPvpBattle, self)}))
    else
        UnregUpdate(self.view)
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=1})
    end
end

function Menu:exitBattleScene()
    local function onExit()
        if not self.realStart then
            local loading = GMethod.loadScript("game.Controller.ChangeController")
            loading:startExit(1)
        else
            self:endBattle()
        end
    end
    if self.scene.battleType==const.BattleTypePvc and not self.realStart then
        display.showDialog(AlertDialog.new(3, StringManager.getString("btnGiveup"), StringManager.getString("alertTextGiveup"), {callback=function()
           self:pvcResult()
           onExit()
        end}))
    else
        onExit()
    end
end

--退出战斗，请求下
function Menu:pvcResult()
    local scene = self.scene
    local data = self.battleData
    local replayInfo = ""
    local myHeroList = {}
    local eHeroList = {}
    for _, hero in pairs(data.groups[1].heros) do
        table.insert(myHeroList, {hero.sid,hero.avtInfo.level,hero.avtInfo.alevel})
    end
    for _, hero in pairs(data.groups[2].heros) do
        table.insert(eHeroList, {hero.sid,hero.avtInfo.level,hero.avtInfo.alevel})
    end
    local params={rveid=scene.battleParams.isRev,hidxs={},win=0, uhls=myHeroList,thls=eHeroList,history=replayInfo,batid=scene.battleParams.batid}
    GameNetwork.request("pvcresult",params, nil)
end

--切换完毕后执行
function Menu:onChangeOver()
    local scene = self.scene
    local context = GameLogic.getUserContext()
    if not GEngine.rawConfig.DEBUG_BATTLE then
        if scene.isBattle and scene.battleType==const.BattleTypePve and scene.battleParams.story1 then
            self.battle:setVisible(false)
            self.battle.hide = true
            local eventName = "InitComic"
            if scene.battleParams.comics then
                GameEvent.registerEvent(eventName, self, self.onChangeOver)
                local cid = table.remove(scene.battleParams.comics, 1)
                if #scene.battleParams.comics == 0 then
                    scene.battleParams.comics = nil
                end
                display.showDialog(ComicDialog.new(cid, nil, nil, eventName), true, true, 255)
            else
                GameEvent.unregisterEvent(eventName, self)
                if context.guide:getStep().type == "comic" then
                    GameLogic.statForSnowfish("tutorialstarts")
                    context.guide:addStep()
                end
                local hid = nil
                for i=1, 5 do
                    local hero = context.heroData:getHeroByLayout(const.LayoutPvp, i, 1)
                    if hero and hero:isAlive(scene.startTime) then
                        if not hid or hero.hid>hid then
                            hid = hero.hid
                        end
                    end
                end
                display.showDialog(StoryDialog.new({context=context,storyIdx=scene.battleParams.story1,heroId=hid, callback=Handler(self.finishPveStory, self)}),false,true)
            end
            return
        end
    end
    self:finishPveStory()
end

function Menu:finishPveStory()
    self.inCount = true

    local scene = self.scene
    local context = GameLogic.getUserContext()

    --引导
    if scene.isBattle then
        if self.battle.hide then
            self.battle:setVisible(true)
            self.battle.hide = nil
        end
        if context.guide:getStep().type == "story" then
            context.guide:addStep()
        end
        self.showGuide = nil
        if scene.battleType==const.BattleTypePve then
            local stage = scene.battleParams.stage
            if context.guide:getStep().type == "putHero" then
                context.guideHand:showHandBig(self.scene.objs,1000000,"putHero")
                display.pushGuide(Localize("stringPutHero"))
            elseif stage and stage<=3 and context.pve:getMyMaxStage()<=3 then
                context.guideHand:showHandBig(self.scene.objs,1000000,"pve")
                display.pushGuide(Localize("stringPutHero"))
                self.showGuide = true
                self.showPushNum = 0
                if context.guide:getStep().type == "pve" then
                    local setting = GEngine.getSetting("guidePveScale" .. stage)
                    if setting then
                        local sizeX, sizeY = 4096, 3072
                        local smin = display.getScalePolicy(sizeX, sizeY)[GConst.Scale.Big]
                        self.scene.scroll:moveAndScaleToCenter(setting[1] * smin, setting[2], setting[3], setting[4])
                    end
                end
            end
        end
    end
    if scene.sceneType=="operation" or scene.sceneType=="visit" then
        music.setBgm("music/operation.mp3")
    elseif scene.sceneType=="battle" and scene.inHVH then
        music.setBgm("music/battleAttack.mp3")
    end
    if scene.sceneType == "operation" then
        --引导
        if context.guide:getStep().type == "searchX" then
            self:banBut()
            display.showDialog(PlayInterfaceDialog)
        end
    end
end

function Menu:endBattle(force)
    local bdata = self.battleData
    if GEngine.rawConfig.DEBUG_REPLAY or GEngine.rawConfig.DEBUG_EFFECT or GEngine.rawConfig.DEBUG_ACTION then
        self.battleData.state = 2
        return
    end

    local scene = self.scene
    local bdata = scene.battleData
    if bdata.state~=2 then

        local _,_,star = bdata:computeBattleResult()
        if not force then
            local title, text
            if star==0 then
                if self.scene.battleType==const.BattleTypePvh then
                    text = Localize("alertTextGiveupPvh")
                else
                    text = Localize("alertTextGiveup")
                end
                title = Localize("btnGiveup")
            else
                title = Localize("alertTitleNormal")
                text = Localizef("alertTextExitBattle")
            end
            display.showDialog(AlertDialog.new(4,title,text,{callback=Handler(self.endBattle, self, true)}))
            return
        end
        bdata.state = 2

        if self.showGuide then
            display.removeGuide()
            GameLogic.getUserContext().guideHand:removeHand("pve")
        end
        --直接进入结束时
        self.replayOver = true
        self:updateBattle(0.025)
        self.scene.replay:stopUpdate()
        if self.scene.replay.isReplay then
            return
        end
        local function hideBattle()
            self.battle:setVisible(false)
        end
        self.battle.view:runAction(ui.action.sequence({{"delay", GEngine.getSetting("battleEndDelay")},{"call",hideBattle}, {"call", Handler(self.showEndResult, self)}}))
    end
end

function Menu:showEndResult()
    local scene = self.scene
    local bdata = scene.battleData
    local context = GameLogic.getUserContext()
    local _,_,star = bdata:computeBattleResult()
    if scene.battleType==const.BattleTypePve and scene.battleParams.story2 and star==3 then
        local hid = nil
        for i=1, 5 do
            local hero = bdata.groups[1].heros[i]
            if hero then
                if not hid or hero.sid>hid then
                    hid = hero.sid
                end
            end
        end
        display.showDialog(StoryDialog.new({context=context,storyIdx=scene.battleParams.story2,heroId=hid, callback=Handler(self.finishPveStory2, self)}),false,true)
        return
    end
    self:finishPveStory2()
end

function Menu:finishPveStory2()
    local scene = self.scene
    local bdata = scene.battleData
    local context = GameLogic.getUserContext()
    local _,_,star = bdata:computeBattleResult()

    if context.guide:getCurrentState()<6 then
        while context.guide:getCurrentState()<6 do
            context.guide:addStep()
        end
        context.heroData = context.bheroData
        context.bheroData = nil
        local loading = GMethod.loadScript("game.Controller.ChangeController")
        loading:startExit()
        return
    elseif context.guide:getStep().type == "pvj" then
        context.guide:addStep()
        local loading = GMethod.loadScript("game.Controller.ChangeController")
        loading:startExit()
        self.camara:removeFromParent(true)
        self.camara = nil
        self.guideAnimate = nil
        return
    end
    GameLogic.setSchedulerScale(1)
    if DEBUG.DEBUG_REPLAY2 then
        local loading = GMethod.loadScript("game.Controller.ChangeController")
        loading:startExit(1)
        return
    end
    display.showDialog(BattleResultDialog.new({battleData = bdata}))
end

function Menu:onInitAfterGuide()
    if self.initedAfterGuide then
        return
    end
    self.initedAfterGuide = true
    if GameLogic.useTalentMatch then
        local stime = GameLogic.getSTime()
        local context = GameLogic.getUserContext()
        local actsData = context.activeData:getConfigableActs()
        -- 这里来进行月卡和资源礼包的处理
        local lastState = context:getProperty(const.ProSpecialNewState)
        local lastAct = context:getProperty(const.ProSpecialNewAct)
        -- 表示上次已触发过活动；需要检测该活动是否完成
        if lastAct > 0 then
            local curAct = actsData[lastAct]
            if not curAct or not ActivityLogic.checkActVisible(curAct) then
                lastAct = 0
            end
        end
        for ftId = 1, 4 do
            if lastAct == 0 then
                local ok = (ftId ~= 1 or context.vips[5][2] <= stime)
                if bit.band(lastState, bit.lshift(1, ftId-1)) == 0 and ok then
                    local triggerAct = context.activeData:forceTriggerAct(const.ProSpecialNewState, ftId)
                    if triggerAct then
                        lastState = bit.bor(lastState, bit.lshift(1, ftId-1))
                        lastAct = triggerAct.actId
                        context:setProperty(const.ProSpecialNewState, lastState)
                        context:setProperty(const.ProSpecialNewAct, lastAct)
                        context:addCmd({const.CmdActTriggleInit, const.ProSpecialNewState, lastState})
                        context:addCmd({const.CmdActTriggleInit, const.ProSpecialNewAct, lastAct})
                    end
                end
            end
        end
    end
end

function Menu:reloadOperation()
    self:hideAll()
    if not self.ops then
        self:initOperation()
    else
        self.ops:setVisible(true)
    end
    if self.chatRoom then
        self.chatRoom:setVisible(true)
    end
    RegTimeUpdate(self.view, Handler(self.updateOperation, self), 0.2)
end

function Menu:reloadBattle()
    self:hideAll()
    GameEvent.unregisterEvent(GameEvent.EventBattleTouch, self)
    LogicEffects.setBufferUse(true)
    if self.scene.battleType == 5 then  --英雄试炼通过   HeroTrialBattleInterface
        self.battle = HeroTrialBattleInterface.new(self)
        UnregTimeUpdate(self.view)
    else
        if not self.battle then
            self:initBattle()
        else
            self.battle:setVisible(true)
        end
        self:initBattleData()
        if self.scene.isBattle then
            RegTimeUpdate(self.view, Handler(self.updateBattle, self), 0)
            GameEvent.registerEvent(GameEvent.EventBattleTouch, self, self.onBattleTouch)
        else
            RegTimeUpdate(self.view, Handler(self.updatePrepare, self), 0.2)
        end
    end
    if self.scene.battleParams.isReplay then
        self.replayMenu = playbackInterface.new()
        self.replayMenu.butBackBase:setListener(function()
            GameLogic.setSchedulerScale(1)
            local loading = GMethod.loadScript("game.Controller.ChangeController")
            loading:startExit(1,true)
        end)
    end
end

function Menu:reloadVisit()
    self:hideAll()
    GameEvent.unregisterEvent(GameEvent.EventBattleTouch, self)
    if not self.visit then
        self:initVisit()
    else
        self.visit:setVisible(true)
    end
    self:initVisitData()
end

function Menu:initVisit()
    local visit = ViewLayout.new()
    visit:setLayout("VisitMenu.json")
    display.adapt(visit.view, 0, 0)
    self.view:addChild(visit.view)
    visit:loadViewsTo()
    self.visit = visit
end
function Menu:initVisitData()
    local visit = self.visit
    local context = GameLogic.getCurrentContext()
    local ucontext = GameLogic.getUserContext()
    visit.nodeRightHead:removeAllChildren(true)

    visit.rightHead = {headScale=0.92,name=context:getInfoItem(const.InfoName), iconType=context:getInfoItem(const.InfoHead), level=context:getInfoItem(const.InfoLevel),lvRT=true}
    GameUI.updateUserHeadTemplate(visit.nodeRightHead.view, visit.rightHead)
    visit.resScoreValue2:setString(context:getRes(const.ResScore))
    visit.butBackBase:setScriptCallback(ButtonHandler(function()
        local loading = GMethod.loadScript("game.Controller.ChangeController")
        loading:startExit(1)
    end))
    GameUI.addResourceIcon(visit.nodeRes1, const.ResGold, 84/100, 42, 42,0)
    local gValue=ucontext:getRes(const.ResGold)
    local gMaxValue=ucontext:getResMax(const.ResGold)
    visit.resGoldValue:setString(gValue)
    visit.resGoldMax:setString(Localizef("labelMaxStorage",{max = gMaxValue}))
    visit.resScoreValue:setString(ucontext:getRes(const.ResScore))
    visit.imaProcess.view:setProcess(true,gValue/gMaxValue)
    if self.scene.haveSatrtBattleData then
        visit.startBattle:setScriptCallback(ButtonHandler(function ()
            self:beginpvlatk(self.scene.haveSatrtBattleData)
        end))
        if GameLogic.getToday()<self.scene.haveSatrtBattleData.jionTime then
            visit.startBattle:setVisible(false)
        end
    else
        visit.startBattle:setVisible(false)
    end
    --上方英雄
    local heros = {}
    for i=1,5 do
        local hero = context.heroData:getHeroByLayout(const.LayoutPvp, i, 1)
        if hero then
            table.insert(heros,hero)
        end
    end
    --913,1335, 左下角
    local heroNum=#heros
    local startX=913-(heroNum-1)*(215/2)-1024
    for i=1,heroNum do
        local but = ui.button({192/0.8,186/0.8},nil,{})
        local heroNode = but:getDrawNode()
        display.adapt(but,startX+(i-1)*215,-201,GConst.Anchor.LeftBottom)
        visit.nodeVisitT:addChild(but)
        GameUI.updateHeroTemplate(heroNode, {}, heros[i], {flagEquip = true})
        but:setScale(0.8)
        but:setListener(function()
            display.showDialog(HeroMainDialog.new({initTag="info",dialogParam=heros[i].idx,context = context}))
        end)
    end
end

--将菜单的操作逻辑改放到Menu实现里
function Menu:onBattleTouch(event, params)
    if self.scene.replay.locked then
        return
    end
    if self.scene.replay.isReplay then
        return
    end
    local gx, gy = params.gx, params.gy
    local gridx = math.floor(gx)
    local gridy = math.floor(gy)
    local item = self.selectedItem
    local bdata = self.scene.battleData
    local battle = self.battle
    local replay = self.scene.replay
    if item then
        local context = GameLogic.getUserContext()
        local gtype = context.guide:getStep().type
        if (gtype == "pauseForSkill" or gtype == "pauseForGodSkill") and context.guide:getStepState() == 1 then
            return
        end

        if item.witem then  --这是武器
            local witem = item.witem
            if witem.use<witem.num then
                local cmd = {}
                cmd.t = CMDTYPE.addSW
                cmd.ps = {item.idx,gx,gy}
                replay:addCmd(cmd)
            else
                display.pushNotice(Localize("noticeWeaponEmpty"))
            end
            return
        else --这是英雄
            local groupData = item.groupData
            local hitem = groupData.hitems[item.idx]
            local hero = groupData.heros[hitem.hpos]
            if self.scene.battleType == const.BattleTypePvb then
                if gx<10 then
                    gx = 10
                elseif gx>31 then
                    gx = 31
                end
                if gy<1 then
                    gy = 1
                elseif gy>40 then
                    gy = 40
                end
            else
                if gx<-1 then
                    gx = -1
                elseif gx>42 then
                    gx = 42
                end
                if gy<-1 then
                    gy = -1
                elseif gy>42 then
                    gy = 42
                end
            end
            gridx = math.floor(gx)
            gridy = math.floor(gy)
            if not hero then
                if self.scene.mapView.checkGridEmpty(gridx,gridy) and not self.scene.map.getGridObj(gridx, gridy) then
                    local cmd = {}
                    cmd.t = CMDTYPE.addHero
                    cmd.ps = {item.idx,gx,gy}
                    replay:addCmd(cmd)

                    --为了UI显示
                    groupData.heros[hitem.hpos] = 1
                    groupData.uiReady = groupData.uiReady-1

                    local nhitem
                    local nidx
                    local allNum = 5
                    if self.scene.battleType==const.BattleTypeUPvp then
                        allNum = 6
                    end

                    for i=1, allNum-1 do
                        nidx = item.idx+i
                        if nidx > allNum then
                            nidx = nidx - allNum
                        end
                        nhitem = groupData.hitems[nidx]
                        if nhitem and nhitem.hpos and not groupData.heros[nhitem.hpos] then
                            nhitem = battle.heroBut[nidx]
                            break
                        else
                            nhitem = nil
                        end
                    end
                    self:onTouchHero(nhitem)

                    --引导
                    local context = GameLogic.getUserContext()
                    local step = context.guide:getStep()
                    if step.type == "putHero" then
                        context.guide:addStep()
                        display.removeGuide()
                    elseif context.guide:getCurrentState()<=6 then
                        if groupData.uiReady <= 0 then
                            context.guideHand:removeHand("putHero")
                        end
                    end

                    if self.showGuide then
                        if self.showPushNum == 0 then
                            display.removeGuide()
                            groupData.showGuide = 1
                        end
                        self.showPushNum = self.showPushNum + 1
                        if groupData.uiReady <= 0 then
                            context.guideHand:removeHand("pve")
                        end
                    end
                else
                    display.pushNotice(Localize("noticeBattleRange"))
                    GameEvent.sendEvent(GameEvent.EventBuildMove)
                end
                return
            end
        end
    end
    local groupData = bdata.groups[1]
    if groupData.ready==0 and self.scene.battleType~=const.BattleTypePvj then
        display.pushNotice(Localize("noticeHeroAllOut"))
    end
end

function Menu:updateOperation(diff)
    local loading = GMethod.loadScript("game.Controller.LoadingGameController")
    if not loading.changeOver then
        return
    end
    local context = GameLogic.getUserContext()
    context.heroData:refreshAllCombatData()
    --充值奖励拉取
    if GameLogic.needReloadRewards and not self.lockReloadSend then
        GameLogic.forReloadRewardsTime = GameLogic.forReloadRewardsTime + diff
        if GameLogic.forReloadRewardsTime > GameLogic.forReloadRewardsTimeAll then
            self.lockReloadSend = true
            if GameLogic.forReloadRewardsTimeAll == 0 then
                GameLogic.forReloadRewardsTimeAll = 5
            elseif GameLogic.forReloadRewardsTimeAll < 7 then
                GameLogic.forReloadRewardsTimeAll = GameLogic.forReloadRewardsTimeAll + 1
            elseif GameLogic.forReloadRewardsTimeAll == 7 then
                GameLogic.forReloadRewardsTimeAll = 10
            else
                GameLogic.forReloadRewardsTimeAll = GameLogic.forReloadRewardsTimeAll*2
            end
            if GameLogic.forReloadRewardsTimeAll > 120 then
                self.lockReloadSend = false
                GameLogic.needReloadRewards = nil
                GameLogic.forReloadRewardsTime = nil
                GameLogic.forReloadRewardsTimeAll = 0
                --如果发了tapjoy 判断data中没有得到tapjoy返回的请求 那就继续拉取
                if GameLogic.openAds then
                    self.needReloadRewards = true
                end
            else
                GameNetwork.request("getRewards",{uid = context.uid},function(suc,data)
                    self.lockReloadSend = false
                    if suc and data.code==0 and data.rewards and #data.rewards>0 then
                        --如果发了tapjoy 判断data中没有得到tapjoy返回的请求 那就继续拉取
                        GameLogic.purchaseLock = nil
                        GameLogic.purchaseTry = nil
                        GameLogic.addBuyedRes(data.rewards)
                        if GameLogic.openAds then

                        else
                            GameLogic.needReloadRewards = nil
                            GameLogic.forReloadRewardsTime = nil
                            GameLogic.forReloadRewardsTimeAll = 0
                        end
                    elseif suc and data.code == 0 and GameLogic.purchaseTry and (GameLogic.forReloadRewardsTime or 10) >= 10 then
                        GameLogic.purchaseLock = nil
                        GameLogic.purchaseTry = nil
                    end
                end)
            end
        end
    end

    -- 弹出奖励提示
    GameLogic.showGetList()
    local guideFinished = context.guide:getStep().type == "finish"
    if guideFinished then
        --引导
        --登录战报
        local active = context.activeData
        local data = active.dhActive[51]
        local isReceive = (data and data[3]>=1 or false)
        if isReceive and (data[4]==1) and (context:getProperty(10000+const.ProTwoFirstFlushAct)==0) then
            context.activeData:finishActCondition(const.FirstFlushGiftBag,1)
        end
        if display.getDialogPri()==0 and (context:getProperty(10000+const.ProTwoFirstFlushAct)==1) then
            local actsData = context.activeData:getConfigableActs()
            for _,v in pairs(actsData) do
                if v and (v.actType == 6) and ActivityLogic.checkActVisible(v) then
                    context:setProperty(10000+const.ProTwoFirstFlushAct,2)
                    self:doActivity(v.actId)
                end
            end
        end
        if context.replays and not self.WarReportOutIsOpend and display.getDialogPri() == 0 then
            WarReportOut.new(context.replays)
            self.WarReportOutIsOpend=true
        end
        --判断是否要打开每日登陆
        if not self.SignRewardDialogIsOpend and display.getDialogPri() == 0 then
            local activeData = context.activeData
            if activeData.dhActive[12] and activeData.dhActive[12][4] == 0 or not activeData.dhActive[12] then
                SignRewardDialog.new()
                self.SignRewardDialogIsOpend=true
            end
        end

        if display.getDialogPri()==0 then
            GameEvent.sendEvent("prestigeBtnRedNum")
            GameEvent.sendEvent("refreshWishesRedNum")
            if self.presRedNum and self.presRedNum>0 then
                GEngine.setConfig("oldRedNum" .. GameLogic.getUserContext().uid, self.presOldRedNum+self.presRedNum,true)
                display.showDialog(PrestigeDialog.new({setting={redNum=self.presOldRedNum}}))
            end
        end

        --if display.getDialogPri()==0 then
            --这里是功能型礼包的触发
            --总是在判断有没有可以触发的礼包，要是有的话便弹出提示框
            --根据配置的参数，来限制礼包的显隐
            -- self.checkTriggerBag()
            local triggerId = GEngine.getConfig(tostring("myTriggle1_"..context.uid))
            if triggerId and triggerId~=0 then
                GEngine.setConfig(tostring("myTriggle1_"..context.uid),0)
                -- local hadOpenTrigglesBagDialog = GEngine.getConfig("OpenTrigglesBagDialog"..GameLogic.getUserContext().uid)
                -- if not hadOpenTrigglesBagDialog then
                --     display.showDialog(TrigglesBagDialog.new({id = triggerId}))
                -- end
                local OpenTrigglesBagDialog = GameLogic.getUserContext():getProperty(const.OpenTrigglesBagDialog)
                if OpenTrigglesBagDialog < 1 then
                    display.showDialog(TrigglesBagDialog.new({id = triggerId}))
                end
            end
        --end

        -- 新手引导完成，弹出随机礼包
        if not self.PackageOpend and display.getDialogPri() == 0 then
            local curActs = self.ops.menuActsList
            if curActs and #curActs > 0 then
                local stime = GameLogic.getSTime()
                local newCurActs = {}
                for _, act in ipairs(curActs) do
                    table.insert(newCurActs, act.actId)
                end
                local activityID = 0
                -- 优先弹出首充礼包
                local __priMap = {}
                local _firstMax = 2
                if GameLogic.useTalentMatch then
                    _firstMax = 1
                end
                local actsData = context.activeData:getConfigableActs()
                if (GEngine.getConfig("firstShowed" .. context.uid) or 0) < _firstMax then
                    __priMap[51] = 100
                end
                for aid, act in pairs(actsData) do
                    if not __priMap[aid] then
                        if act.firstPri then
                            if not GEngine.getConfig("firstShowed" .. aid) then
                                __priMap[aid] = act.firstPri
                            end
                        elseif act.popPri then
                            __priMap[aid] = act.popPri
                        end
                    end
                    if (act.actType == 4 or act.actTemplate or act.actGroup == 6) and ActivityLogic.checkActVisible(act) then
                        table.insert(newCurActs, aid)
                    end
                end

                -- 此处逻辑，在最大pri里随机一个对话框
                local __priority = 0
                local newPackage = {}

                for _, v in ipairs(newCurActs) do
                    if (__priMap[v] or 0) > __priority then
                        newPackage = {v}
                        __priority = (__priMap[v] or 0)
                    elseif (__priMap[v] or 0) == __priority then
                        table.insert(newPackage, v)
                    end
                end

                if __priority > 0 then
                    activityID = newPackage[math.random(#newPackage)]
                end

                --老玩家回归活动(7天未登录且主城等级大于3级,只触发一次)
                local dtime = context.lastSynTime--上次同步时间
                local leaveDays = math.floor((stime-const.InitTime)/(86400)) - math.floor((dtime-const.InitTime)/(86400))
                local mainCitylv = context:getInfoItem(const.InfoTownLv)
                if leaveDays >= 7 and mainCitylv >= 3 and leaveDays > context:getProperty(40000+leaveDays)then
                    context:setProperty(40000+leaveDays, leaveDays)
                    context.activeData:finishActConditionOnce(const.ActStatLeaveDays,leaveDays)
                end

                --玩家VIP等级触发活动
                local vipLv = context:getInfoItem(const.InfoVIPlv)
                context.activeData:finishActConditionOnce(const.ActStatUserVip,vipLv)
                --玩家等级触发活动
                local userLv = context:getInfoItem(const.InfoLevel)
                context.activeData:finishActConditionOnce(const.ActStatUserLevel,userLv)
                --邀请码被填次数活动
                GameLogic.getUserContext().activeData:finishActConditionTlist(GameLogic.tlist)

                self.PackageOpend = true
                if activityID > 0 then
                    if activityID == 51 then
                        GEngine.setConfig("firstShowed" .. context.uid,
                            (GEngine.getConfig("firstShowed" .. context.uid) or 0) + 1, true)
                        GEngine.saveConfig()
                    elseif actsData[activityID] and actsData[activityID].firstPri then
                        GEngine.setConfig("firstShowed" .. activityID, 1, true)
                        GEngine.saveConfig()
                    end
                    self:doActivity(activityID)
                end
            end
            if not GEngine.getConfig("notificationSeted") then
                GEngine.setConfig("notificationSeted", 1, true)
                Native:openURL("notification")
            end
            context.heroData:setAllCombatData()
        end
        if display.getDialogPri()==0 then
            if not GameLogic.useTalentMatch then
                local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
                KnockMatchData:checkDivideGuide()
                KnockMatchData:checkOutGuide()
            end
            local selfTime = self.__dayTime or 0
            if selfTime < GameLogic.getToday() then
                self.__dayTime = GameLogic.getToday()
                local stime = GameLogic.getSTime()
                --每日任务跨天刷新
                if not GameLogic.useTalentMatch then
                    local dtinfo = context.activeData:getDailyTaskDtinfo()
                    local dtime = dtinfo[1]
                    if (math.floor((stime-const.InitTime)/86400) > math.floor((dtime-const.InitTime)/86400)) then
                        context.activeData:refreshDailyTask()
                    end
                    --跨天时检查VIP礼包的状态,
                    dtime = context:getProperty(const.ProBuyVipPkgTime1)
                    if (math.floor((stime-const.InitTime)/86400) > math.floor((dtime-const.InitTime)/86400)) then
                        context:setProperty(const.ProBuyVipPkg1, 0)
                    end
                end
            end
        end
    end
    --自动满仓活动start
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffFillVault)
    if buffInfo[4]~=0 and buffInfo[5]==0  then
        GameLogic.doActAction(context, buffInfo[1], 1)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeBuffFillVault)
    end
    --自动满仓活动end
    local ops = self.ops
    local opsData = self.opsData
    if context then
        -- 根据状态确定是否需要给VIP图标加上红点
        if not GameLogic.useTalentMatch then
            if (context:getProperty(const.ProBuyVipPkg1)==0) and (context:getInfoItem(const.InfoVIPlv)>0) then
                self.butVipRedNum:setNum(1)
            else
                self.butVipRedNum:setNum(0)
            end
        end
        local name = context:getInfoItem(const.InfoName)
        if name~=opsData.name then
            opsData.name = name
            ops.labelName:setString(name)
        end
        local lv = context:getInfoItem(const.InfoLevel)
        if lv~=opsData.level then
            if opsData.level then
                local scene = GMethod.loadScript("game.View.Scene")
                UIeffectsManage:showEffect_jinyingtishen(self.view,display.winSize[1]/2,display.winSize[2]/2,lv)
            end
            opsData.level = lv
            ops.labelLevel:setString(N2S(lv))
        end
        local bg=ops.nodeUserInfo
        local viplv = context:getInfoItem(const.InfoVIPlv)
        if not GameLogic.useTalentMatch then
            if viplv ~= opsData.viplv then
                opsData.viplv = viplv
                if ops.vip then
                    ops.vip:removeFromParent(true)
                    ops.vip = nil
                end
                ops.vip=GameUI.addMenuVip(ops.butVipAdd,viplv,0,0,1,{scale=0.95})
            end
        else
            ops.lb_powerDes:setPositionY(350)
            ops.lb_power:setPositionY(350)
        end
        local headid = context:getInfoItem(const.InfoHead)
        if headid ~= opsData.headid then
            opsData.headid = headid
            if ops.herdBack then
                ops.herdBack:removeFromParent(true)
            end
            ops.herdBack=GameUI.addPlayHead(bg,{viplv=viplv,id=headid,scale=1,x=112,y=389,z=1,blackBack = true})
            ops.herdBack:setScriptCallback(ButtonHandler(LordHeadDialog.new))
            if headid%10==1 then
                ops.headLvBack.view:setSValue(-100)
            elseif headid%10==2 or headid % 10 > 4 then
                ui.setFrame(ops.headLvBack.view, "images/headLvBack.png")
                ops.headLvBack.view:setSValue(0)
            elseif headid%10==3 then
                ui.setFrame(ops.headLvBack.view, "images/headLvBack3.png")
                ops.headLvBack.view:setSValue(0)
            elseif headid%10==4 then
                ui.setFrame(ops.headLvBack.view, "images/headLvBack4.png")
                ops.headLvBack.view:setSValue(0)
            end
        end
        --刷新战斗力
        local ProCombat = context:getProperty(const.ProCombat)
        ops.lb_power:setString(ProCombat)
        if context.enterData then
            local sv = context.enterData.ustate[1]
            sv = StringManager.getTimeString(sv-GameLogic.getSTime())
            if sv~=opsData.shield then
                opsData.shield = sv
                ops.labelShieldTime:setString(sv)
            end
        end
        for resId, res in pairs(self.res) do
            local value = context:getRes(resId)
            if res.max then
                local max = context:getResMax(resId)
                if max==0 then
                    max = value
                end
                if max~=res.max or value~=res.value then
                    if res.filler then
                        res.filler:setProcess(true, value/max)
                    end
                    if res.maxLabel then
                        res.maxLabel:setString(StringManager.getFormatString("labelMaxStorage",{max=N2S(max)}))
                        if res.value==-1 then
                            res.valueLabel:setString(N2S(value))
                        else
                            local from = res.value
                            local to = value
                            local label = res.valueLabel
                            local ct = 0
                            local function updateLabel()
                                ct = ct + 1
                                label:setString(N2S(math.floor(ct*(to-from)/20+from)))
                            end
                            res.valueLabel.view:runAction(ui.action.arepeat(ui.action.sequence({{"call", updateLabel},{"delay",0.06}}), 20))
                            -- self.numAni:runAnimate(res.valueLabel,tonumber(res.value),tonumber(value))
                            if resId == const.ResGold then
                                local view = ops.nodeRes1Icon.view
                                local vtag = 101
                                local vaction = view:getActionByTag(vtag)
                                if not vaction then
                                    vaction = ui.action.sequence({{"scaleTo",0.16,1.4,1.4},{"scaleTo",0.08,0.8,0.8},{"scaleTo",0.08,1,1}})
                                    vaction:setTag(vtag)
                                    view:runAction(vaction)
                                end
                            end
                        end
                    elseif res.valueLabel then
                        res.valueLabel:setString(value .. "/" .. max)
                    end
                    res.value = value
                    res.max = max
                end
            elseif value~=res.value then
                res.valueLabel:setString(N2S(value))
                res.value = value
            end
        end
        if not GameLogic.useTalentMatch then
            if self.btnAddRes5Effect then
                self.btnAddRes5Effect:setVisible(context:getRes(const.ResBeercup)>0)
            end
            if self.btnAddRes8Effect then
                self.btnAddRes8Effect:setVisible(context:getRes(const.ResBeercup)>0)
            end
            if GameLogic.getUserContext():getProperty(const.ProDJCount)==0 or GameLogic.getToday()>GameLogic.getUserContext():getProperty(const.ProDJTime) then
                self.res5FreeNum:setNum(1)
            else
                self.res5FreeNum:setNum(0)
            end
            if GameLogic.getUserContext():getProperty(const.ProDJCount2)==0 or GameLogic.getToday()>GameLogic.getUserContext():getProperty(const.ProDJTime2) then
                self.res8FreeNum:setNum(1)
            else
                self.res8FreeNum:setNum(0)
            end
        end
        --引导
        if self.chatRoom then
            self.chatRoom:setVisible(self.shouldShowChatRoom)
        end
        local stime = GameLogic.getSTime()
        if context.guide.showFinish and self.__lastUpdateTime ~= stime then
            self:onInitAfterGuide()
            self.__lastUpdateTime = stime
            ops.nodeActivity:setVisible(true)
            ops.nodeActivityRight:setVisible(true)
            self:updateActivitys(true)
            if not ops.heroRedNum then
                ops.heroRedNum = GameUI.addRedNum(ops.btnHero,-20,120,3,0.8,10000)
                ops.heroRedNum:setNum(0)
            else
                local num = context:getFreeHeroChance(GameLogic.getSTime())+context:getFragHero()
                ops.heroRedNum:setNum(num)
            end
            if context.lockRate and context.lockRate < stime then
                context.lockRate = nil
                context.activeData:finishTcodeAct()
            end
            if GameLogic.useTalentMatch then
                context.activeData:refreshMonthCard()
            end
            --跑马灯
            if self.barrage then
                self.barrage:checkBarrage()
                self.barrage:requestBarrage()
            end
        end
        if display.getDialogPri() == 0 then
            local gstep = context.guide:getStep()
            if gstep.type == "buyBuild" then
                if context.guide:getStepState() == 0 then
                    if context.buildData:getBuildNum(gstep.id) >= gstep.num and context.buildData:getMaxLevel(gstep.id) > 0 then
                        context.guide:addStep()
                    else
                        context.guide:setStepState(1)
                        self:banBut()
                        display.showDialog(StoryDialog.new({context=context,storyIdx=gstep.storys[1], callback=Handler(function()
                            self:buyBuildShow()
                        end)}),false,true)
                    end
                elseif context.guide:getStepState() == 1 then
                    self:refreshBuildHand(gstep.id)
                end
            elseif gstep.type == "pvj" then
                if context.guide:getStepState()<1 then
                    context.guide:setStepState(1)
                    self:banBut()
                    display.showDialog(StoryDialog.new({context=context, storyIdx=gstep.story, callback=Handler(self.guideBattle, self)}), false, true)
                end
            elseif gstep.type == "exHero1" then
                if context.guide:getStepState() == 0 then
                    self:banBut()
                    context.guide:setStepState(1)
                    display.showDialog(StoryDialog.new({context=context, storyIdx=gstep.storys[1], callback=Handler(self.exHero1Show, self)}), false, true)
                end
            elseif gstep.type == "selectHero" then
                if context.guide:getStepState() == 0 then
                    self:banBut()
                    context.guide:setStepState(1)
                    display.showDialog(StoryDialog.new({context=context, storyIdx=gstep.story, callback=Handler(self.guideSelectHero, self)}), false, true)
                elseif context.guide.buyBuildShow then
                    self:refreshBuildHand(gstep.bid)
                end
            elseif gstep.type == "pve" then
                if context.guide:getStepState() == 0 then
                    self:banBut()
                    context.guide:setStepState(1)
                    display.showDialog(StoryDialog.new({context=context, storyIdx=gstep.story, callback=Handler(self.guidePve, self)}), false, true)
                end
            elseif gstep.type == "upgradeHero" then
                if context.guide:getStepState() == 0 then
                    self:banBut()
                    context.guide:setStepState(1)
                    display.showDialog(StoryDialog.new({context=context, storyIdx=gstep.story, callback=Handler(self.guideUpgradeHero, self)}),false,true)
                end
            elseif context.guide:getStep().type == "upgradeTown" then
                if context.guide:getStepState() == 0 then
                    self:banBut()
                    --防止升级未完成关闭游戏,再登录进来还在建造中
                    if GameLogic.getUserContext().buildData:getBuild(gstep.id).worklist then
                        self:guideUpgradeTown()
                    else
                        context.guide:setStepState(1)
                        display.showDialog(StoryDialog.new({context=context,storyIdx=gstep.story,callback=Handler(self.guideUpgradeTown, self)}),false,true)
                    end
                elseif context.guide.buyBuildShow then
                    self:refreshBuildHand(gstep.id)
                end
            elseif context.guide:getStep().type == "task" then
                if context.guide:getStepState() == 0 then
                    self:banBut()
                    context.guide:setStepState(1)
                    display.showDialog(StoryDialog.new({context=context, storyIdx=gstep.story, callback=Handler(self.guideTask, self)}),false,true)
                end
            elseif context.guide:getStep().type == "finish" then
                if not context.guide.showFinish then
                    context.guide.showFinish = true
                    self:showFinish()
                end
            end
        end
        if ops.btnMap and ops.btnMap.arrow then
            if display.getDialogPri() == 0 then
                ops.btnMap.arrow:setVisible(true)
            else
                ops.btnMap.arrow:setVisible(false)
            end
        end

        local lv = context.buildData:getMaxLevel(const.Town)
        if GameLogic.useTalentMatch then
            self.ops.btnTalent:setVisible(lv>=4)
            if self.flag1121 then self.ops.btnKnock:setVisible(lv>=5) end
        else
            self.ops.btnKnock:setVisible(lv>=5)
        end
        --其他引导
        if display.getDialogPri() == 0 then
            local step = context.guideOr:getStep()
            if step%10 == 1 then
                local stid = math.floor(step/10)*2-1+200
                local function setStep()
                    step = step+1
                    context.guideOr:setStep(step)
                end
                display.showDialog(StoryDialog.new({context=context,storyIdx=stid,callback=Handler(setStep)}),false,true)
            elseif step%10 == 2 then
                local tbg
                if math.floor(step/10) == 5 then
                    tbg = ops.btnMap
                else
                    tbg = ops.btnStore
                end
                if not ops.btnStore.handOr then
                    ops.btnStore.handOr = context.guideHand:showHandSmall(tbg,108,136,0)
                end
            elseif step%10 == 4 then
                local stid = math.floor(step/10)*2+200
                local function setStep()
                    step = step+1
                    context.guideOr:setStep(step)
                    for i,v in ipairs(self.scene.builds) do
                        v:setFocus(false)
                    end
                end
                display.showDialog(StoryDialog.new({context=context,storyIdx=stid,callback=Handler(setStep)}),false,true)
            else
                local YouthDayData = GMethod.loadScript("game.GameLogic.YouthDayData")
                if ops.btnStore.handOr and (not YouthDayData:checkGuide(1)) then
                    ops.btnStore.handOr:removeFromParent(true)
                    ops.btnStore.handOr = nil
                end
            end
            if GameLogic.useTalentMatch then
                -- TODO 达人赛引导要咋搞
                -- 理论上要加上玩家主城等级判断以及赛事是否开启判断
                local tmStep = context.guideOr:getStepByKey("TalentMatch") or 0
                if context.guide:getStep().type == "finish" and tmStep <= 0 and not ops.btnTalent.guideArrow then
                    ops.btnTalent.guideArrow=context.guideHand:showArrow(ops.btnTalent, 107, 180, 20)
                    display.showDialog(StoryDialog.new({context=context,storyIdx=911}),false,true)
                end
            else
                --分组赛
                local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
                local _step = KnockMatchData:getDivideGuideStep()
                local guideKnockArrow = context.guideHand.handArr["knockGuide"]

                if _step and _step == 4 and not guideKnockArrow and KnockMatchData:checkCanStartFight() then
                    local function callback()
                        GameEvent.sendEvent(GameEvent.addKncokGuide, self)
                    end
                    context.guideHand.handArr["knockGuide"] = true
                    display.showDialog(StoryDialog.new({context=context,storyIdx=308, callback = callback}),false,true)
                end
            end
            local YouthDayData = GMethod.loadScript("game.GameLogic.YouthDayData")
            if (not self.ops.btnStore.handOr) and YouthDayData:checkGuide(1) then
                if (not context.guideHand.hand) and GameLogic.isEmptyTable(context.guideHand.handArr) then
                    YouthDayData:setGuideStep(1)
                    self.ops.btnStore.handOr = context.guideHand:showArrow(self.ops.btnStore,108,136,20, "youthDayStatueGuide")
                end
            end
        else
            if ops.btnStore.handOr then
                ops.btnStore.handOr:removeFromParent(true)
                ops.btnStore.handOr = nil
            end
        end
        --日志提醒
        if not ops.logRedNum then
            ops.logRedNum = GameUI.addRedNum(ops.btnMsgs,-20,80,0,0.8,99)
        end
        local num = context.logData:getRedNum()
        ops.logRedNum:setNum(num)
        self:refreshFunctionRedNum()
        -- GameEvent.sendEvent("spreadAndRewardRedNum")
        --零点20分之后，要同步一次排名数据
        local _ucontext = GameLogic.getUserContext()
        local zeroTime = GameLogic.getToday()
        local nowTime = GameLogic.getSTime()
        local syncTime = _ucontext.syncRankListTime
        if (syncTime < zeroTime + 1200) and (nowTime >= zeroTime + 1200) then
            _ucontext.syncRankListTime = nowTime
            GameNetwork.request("getRankList2", {uid=_ucontext.uid, sid = _ucontext.sid},function(isSuc,data)
                if isSuc then
                    local set = {pvp=181,pvl=182,pvt=183,pvb=184,pvc=185, pvzg = 187, pvzk = 186}
                    _ucontext.rankList = {}
                    for k,v in pairs(data) do
                        local id = set[k]
                        _ucontext.rankList[id] = v
                    end
                end
            end)
        end
    end
end

function Menu:banBut()
    local ops = self.ops
    ops.btnMap:setScriptCallback(ButtonHandler(function()
        display.pushNotice(Localize("stringPleaseGuideFirst"))
    end))
    ops.btnStore:setScriptCallback(ButtonHandler(function()
        display.pushNotice(Localize("stringPleaseGuideFirst"))
    end))
    ops.btnHero:setScriptCallback(ButtonHandler(function()
        display.pushNotice(Localize("stringPleaseGuideFirst"))
    end))
    self:VisibleFunctionModule(false)
    --ops.btnTask:setVisible(false)
    --ops.btnRank:setVisible(false)
    --ops.btnMsgs:setVisible(false)
    --ops.btnGift:setVisible(false)
    --ops.btnBetaActivity:setVisible(false)
    self.shouldShowChatRoom = false
    if self.scene.onlineReward then
        self.scene.onlineReward:setVisible(false)
    end
    local gstate = GameLogic.getUserContext().guide:getCurrentState()
    ops.nodeUserRes:setVisible(true)
    ops.btnStore:setVisible(gstate >= 6)
    --ops.btnTask:setVisible(gstate >= 14)
    --ops.btnMsgs:setVisible(gstate >= 14)
    --ops.btnRank:setVisible(gstate >= 14)
    if gstate >= 14 then
        self:VisibleFunctionModule(true)
    end
    ops.btnHero:setVisible(gstate >= 9)
    ops.btnMap:setVisible(gstate >= 11)
    ops.nodeOpsTop:setVisible(gstate >= 14)
    ops.nodeUserInfo:setVisible(gstate >= 14)
end

function Menu:exHero1Show()
    local ops = self.ops
    self:banBut()
    -- ops.btnHero:setScriptCallback(ButtonHandler(display.showDialog, HeroMainDialog))
    ops.btnHero:setScriptCallback(ButtonHandler(IllustrationDialog.new()))
    GameLogic.getUserContext().guideHand:showArrow(ops.btnHero,86,136,0,"exHero1")
end

function Menu:refreshBuildHand(bid)
    local context = GameLogic.getUserContext()
    if not context.guide.buyBuildShow then
        for _, build in pairs(self.scene.builds) do
            if build.bid == bid then
                if context.guide:getStep().type ~= "buyBuild" or build.worklist then
                    context.guide.buyBuildShow = build
                    break
                end
            end
        end
    end
    local v = context.guide.buyBuildShow
    if v then
        if v.vstate then
            if not v.vstate.focus then
                if not context.guideHand.handArr["buyBuild"] then
                    local x = v.vstate.view:getContentSize().width/2
                    local y = v.vstate.view:getContentSize().height
                    context.guideHand:showArrow(v.vstate.upNode,x,y,10000,"buyBuild")
                end
            else
                context.guideHand:removeHand("buyBuild")
            end
        end
    end
end

function Menu:guideSelectHero()
    local context = GameLogic.getUserContext()
    self:refreshBuildHand(context.guide:getStep().bid)
    context.guide:setStepState(2)
end

function Menu:buyBuildShow()
    local context = GameLogic.getUserContext()
    local ops = self.ops
    ops.btnStore:setScriptCallback(ButtonHandler(StoreDialog.new))
    local context = GameLogic.getUserContext()
    context.guideHand:showArrow(ops.btnStore,108,136,0,"buyBuild")
end

function Menu:pstory2Show()
    local ops = self.ops
    local context = GameLogic.getUserContext()
    local pstep = context.guide:getStep()
    if pstep.type == "buyBuild" and pstep.storys[3] then
        display.showDialog(StoryDialog.new({context=context,storyIdx=pstep.storys[3]}),false,true)
    end
end

function Menu:guidePve()
    local ops = self.ops
    ops.btnMap:setScriptCallback(ButtonHandler(display.showDialog, PlayInterfaceDialog))
    local context = GameLogic.getUserContext()
    if not ops.btnMap.arrow then
        ops.btnMap.arrow = context.guideHand:showArrow(ops.btnMap,108,200)
    end
end

function Menu:guideBattle()
    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=6,idx=0,bparams = {index = 0}})
end

function Menu:guideUpgradeHero()
    local ops = self.ops
    if ops.btnMap.arrow then
        ops.btnMap.arrow:removeFromParent(true)
        ops.btnMap.arrow = nil
    end
    local context = GameLogic.getUserContext()
    ops.btnHero:setScriptCallback(ButtonHandler(display.showDialog, HeroMainDialog))
    context.guideHand:showArrow(ops.btnHero,86,136,0,"upgradeHeroArrow")
end

function Menu:guideUpgradeTown()
    local context = GameLogic.getUserContext()
    context.guide:setStepState(2)
    self:refreshBuildHand(context.guide:getStep().id)
end

function Menu:guideTask()
    local ops = self.ops
    --ops.btnTask:setVisible(true)
    local context = GameLogic.getUserContext()

    self.taskGuideHand = context.guideHand:showArrow(ops.taskGuide,-90,125,0)
    self:showFunctionModule(true)
end

function Menu:showFinish()
    local context = GameLogic.getUserContext()
    local ops = self.ops
    ops.btnMap:setScriptCallback(ButtonHandler(display.showDialog, PlayInterfaceDialog))
    ops.btnStore:setScriptCallback(ButtonHandler(StoreDialog.new))
    ops.btnHero:setScriptCallback(ButtonHandler(display.showDialog, HeroMainDialog))
    --ops.btnTask:setVisible(true)
    --ops.btnRank:setVisible(true)
    --ops.btnMsgs:setVisible(true)
    self:VisibleFunctionModule(true)
    self:updateActivitys(true)
    self.shouldShowChatRoom = true
    if self.scene.onlineReward then
        self.scene.onlineReward:setVisible(true)
    end
    local allHeros = context.heroData:getAllHeros()
    for _,v in pairs(allHeros) do
        context.heroData:setCombatData(v)
    end
end

function Menu:startBattle()
    if DEBUG.DEBUG_REPLAY2 then
        GameLogic.setSchedulerScale(DEBUG.DEBUG_REPLAY2)
    end
    if not self.scene.isBattle then
        if GameNetwork.checkRequest() then
            return
        end
        --即此处为竞技场/远征的准备就绪，故在此处保存阵型
        local scene = self.scene
        local context = GameLogic.getCurrentContext()
        local builds = context.buildData:getSceneBuilds()
        local lid
        if scene.battleType==const.BattleTypePvc then
            music.play("sounds/arenaLoad.wav")
            lid = const.LayoutPvc
            for _, build in pairs(builds) do
                if build.lidx then
                    context.heroData:changeHeroLayoutPos(lid, build.lidx, build.vstate.bgx, build.vstate.bgy)
                end
            end
        elseif scene.battleType==const.BattleTypePvh then
            lid = self.scene.battleParams.nightmare and const.LayoutnPvh or const.LayoutPvh
            for _, build in pairs(builds) do
                if build.lidx then
                    context.forceLayouts:changeHeroLayoutPos(build.lidx, build.vstate.bgx, build.vstate.bgy)
                end
            end
        end
        GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=scene.battleType, bparams=scene.battleParams})
        return
    end
    local bdata = self.scene.battleData
    if bdata.state==0 then
        --统计pve关卡
        if self.scene.battleType==const.BattleTypePve then
            Plugins:onStat({callKey=4,taskType="Begin",missionId=tostring(self.scene.battleParams.stage)})
        end
        local battle = self.battle
        bdata.state = 1
        bdata.time = 180
        if self.scene.battleType==const.BattleTypePvj and self.scene.battleParams.DRPvj then
            battle.timeValue2.isShow = false
            battle.timeValue2:setVisible(false)
            battle.labelTimeValue:setVisible(true)
        end
        if self.scene.battleParams.stage==0 then
            bdata.time = nil
        end
        battle.labelTimeLeft:setString(Localize("labelBattleEnd"))
        battle.labelEndWord:setString(Localize("btnGiveup"))
        battle.btnBattleNext:setVisible(false)
        local _,p,_ = bdata:computeBattleResult()
        if p then
            battle.nodeBattlePercent:setVisible(true)
        end
        if not self.scene.battleParams.isReplay then
            battle.nodeBattleBottom:setVisible(true)
        end
        if battle.btnBattleStart then
            battle.btnBattleStart:setVisible(false)
            if self.scene.battleParams.DRPvj then
                battle.butRate:setVisible(true)
            end
            -- 初始化boss放出
            bdata.startIndex = 1
            bdata.isAddBoss = true
            bdata.utime = 0
            bdata.addNum = 0
            self.realStart = true
        end

        --战斗时背景音乐
        if self.scene.battleType==const.BattleTypePve then
            music.setBgm("music/battlePrepare.mp3")
        elseif self.scene.battleType==const.BattleTypePvj or self.scene.battleType==const.BattleTypePvc or self.scene.battleType==const.BattleTypePvh then
            music.setBgm("music/battleDefence.mp3")
        elseif self.scene.battleType==const.BattleTypePvt then
            music.setBgm("music/battlePrepare.mp3")
        else
            music.setBgm("music/battleAttack.mp3")
        end
        GameEvent.sendEvent(GameEvent.EventBuildMove)
    end
end

--PVP战斗需要更新资源显示
function Menu:updatePvpBattle(diff)
    local scene = self.scene
    local bdata = scene.battleData
    local battle = self.battle
    local params = scene.battleParams
    local gv0 = math.ceil(params.get)
    local gv = scene.battleParams.cget-gv0
    if bdata.get~=gv then
        bdata.get = gv
        battle.labelBattleGetGold:setString(N2S(gv))
    end
    if bdata.state>0 then
        if not bdata.shield then
            bdata.shield = 0
        end
        local np, ns = 40, 1
        if bdata.shield==1 then
            np, ns = 90, 2
        end
        if bdata.percent >= np and bdata.shield<ns then
            bdata.shield = ns
            display.pushNotice(Localizef("noticePvpShield",{percent=np, num=ns}))
        end
    end
    gv = params.base+gv0
    if gv>params.max then
        gv = params.max
    end
    if bdata.base~=gv then
        local view = battle.nodeBattleResGold.view
        local vtag = 11
        local vaction = view:getActionByTag(vtag)
        if not vaction and bdata.base then
            vaction = ui.action.sequence({{"scaleTo",0.16,1.4,1.4},{"scaleTo",0.08,0.8,0.8},{"scaleTo",0.08,1,1}})
            vaction:setTag(vtag)
            view:runAction(vaction)
        end
        bdata.base = gv
        battle.labelBattleResGold:setString(N2S(gv))
        battle.fillerBattleResGold:setProcess(true, bdata.base/params.max)
    end
end

-- 僵尸来袭需要自动添加BOSS进攻
function Menu:updatePvjBattle(diff)
    local scene = self.scene
    local bdata = scene.battleData
    local battle = self.battle
    local groupData = bdata.groups[2]
    if self.camara and self.inCount then
        if not self.guideAnimate then
            self.guideAnimate = {0, 0, 0}
        end
        if self.guideAnimate[1] == 0 then
            local setting = GEngine.getSetting("guidePvjScale1")
            self.guideAnimate[4] = setting
            local sizeX, sizeY = 4096, 3072
            local smin = display.getScalePolicy(sizeX, sizeY)[GConst.Scale.Big]
            self.scene.scroll:moveAndScaleToCenter(setting[1] * smin, setting[2], setting[3], setting[4])
            self.guideAnimate[1] = 1
            self.guideAnimate[2] = smin
            bdata.time = setting[4]
        elseif self.guideAnimate[1] == 2 then
            if not self.guideAnimate[5].deleted then
                local setting = self.guideAnimate[4]
                local px, py = self.guideAnimate[5].V.view:getPosition()
                if self.guideAnimate[3] < setting[6] then
                    self.guideAnimate[3] = self.guideAnimate[3] + diff
                    if self.guideAnimate[3] > setting[6] then
                        self.guideAnimate[3] = setting[6]
                    end
                end
                local scale = self.guideAnimate[2] * (setting[1] + (self.guideAnimate[3]/setting[6])*(setting[5]-setting[1]))
                self.scene.scroll:moveAndScaleToCenter(scale, px, py, 0.01)
            end
        end
    end
    if bdata.state == 1 then
        if bdata.isAddBoss then
            if not bdata.showPvjNotice and not self.guideAnimate then
                display.pushNotice(Localizef("stringPvjZbGo",{a=bdata.startIndex}))
                bdata.showPvjNotice = true
            end

            bdata.utime = bdata.utime+diff
            if bdata.utime>=0.5 then
                bdata.utime = bdata.utime-0.5
                local items = bdata.readyHeros[bdata.startIndex]
                if not items then
                    return
                end
                bdata.addNum = bdata.addNum+1
                local item = items[bdata.addNum]
                -- 神兽来袭的话做个最小/最大间隔处理？
                if bdata.addNum == 1 then
                    if item.hero.hid < 9000 then
                        local diss = {0}
                        local ml = 0
                        local dl = #items
                        for i = 2, dl do
                            local rl = math.random()*6+2
                            ml = ml + rl
                            table.insert(diss, ml)
                        end
                        ml = ml/2 + math.random()*8 - 4
                        for i=1, dl do
                            diss[i] = diss[i] - ml
                        end
                        for i=1, dl do
                            local rl = math.random(1, dl)
                            if i ~= rl then
                                diss[i], diss[rl] = diss[rl], diss[i]
                            end
                        end
                        self.__randomRange = diss
                    else
                        self.__randomRange = nil
                    end
                end
                if not item then
                    bdata.isAddBoss = false
                else
                    --引导
                    if self.guideAnimate then
                        local initPos = item.hero.initPos
                        local sinfo = item.sinfo
                        local sdata = item.sdata
                        local person = PersonUtil.newPersonData(sinfo,sdata,{id=item.hero.info.sid,level=item.hero.soldierLevel})
                        groupData.ready = groupData.ready-1
                        local setting = GEngine.getSetting("guidePvjPersonAH")
                        person.atk = person.atk*setting[1]
                        person.hp = person.hp*setting[2]
                        local newSoldier = PersonUtil.C({person=person, state=AvtControlerState.BATTLE, group=2})
                        newSoldier.flagShowAppear = true
                        local gx, gy = self.scene.map.convertToGrid(self.guideAnimate[4][2], self.guideAnimate[4][3])
                        if self.guideAnimate[1] == 1 then
                            self.guideAnimate[5] = newSoldier
                            self.guideAnimate[1] = 2
                            newSoldier:addToScene(self.scene, gx, gy)
                        else
                            newSoldier:addToScene(self.scene, gx + (self.scene.replay.rd:random2()-0.5)*3, gy + (self.scene.replay.rd:random2()-0.5)*3)
                        end
                    else
                        local person = item.hero:getControlData()
                        GameLogic.addSpecialBattleBuff(item.hero, person, 2, self.scene)
                        item.role = PersonUtil.C({person=person, state=AvtControlerState.BATTLE, group=2})
                        local initPos = item.hero.initPos
                        item.role.flagShowAppear = true
                        local gx, gy
                        if self.__randomRange then
                            if initPos[3] == 3 or initPos[3] == 6 then
                                gx = initPos[1] + self.__randomRange[bdata.addNum]
                                gy = initPos[2] + math.random() * 2 - 1
                            else
                                gx = initPos[1] + math.random() * 2 - 1
                                gy = initPos[2] + self.__randomRange[bdata.addNum]
                            end
                        else
                            gx, gy = initPos[1]+self.scene.replay.rd:random2(), initPos[2]+self.scene.replay.rd:random2()
                            if initPos[3] == 3 or initPos[3] == 6 then
                                gx = initPos[1]+math.random(-4,4)
                            elseif initPos[3] == 1 or initPos[3] == 4 then
                                gy = initPos[2]+math.random(-4,4)
                            end
                        end
                        item.role:addToScene(self.scene,gx,gy,initPos[3])
                        groupData.ready = groupData.ready-1

                        local sinfo = item.sinfo
                        local sdata = item.sdata
                        local person = PersonUtil.newPersonData(sinfo,sdata,{id=item.hero.info.sid,level=item.hero.soldierLevel})
                        local function addSoldier()
                            local newSoldier = PersonUtil.C({person=person, state=AvtControlerState.BATTLE, group=2})
                            newSoldier.flagShowAppear = true
                            local gx, gy = initPos[1], initPos[2]
                            if initPos[3] == 3 or initPos[3] == 6 then
                                gx = initPos[1]+math.random(-4,4)
                            elseif initPos[3] == 1 or initPos[3] == 4 then
                                gy = initPos[2]+math.random(-4,4)
                            end
                            newSoldier:addToScene(self.scene,gx,gy)
                        end
                        for i=1, sdata.num do
                            self.scene.replay:addDelay(addSoldier, i*0.1)
                        end
                    end
                end
            end
        else
            if groupData.deadTroops>=groupData.totalTroops and groupData.tempTroops<=0 then
                bdata.isAddBoss = true
                bdata.addNum = 0
                bdata.showPvjNotice = nil
                bdata.startIndex = bdata.startIndex+1
            end
        end
    end
    battle.labelMonsterNum:setString(N2S(groupData.ready))
    battle.lab_resultKill:setString(Localize("tmPvjKillNum"))
    battle.lab_killNum:setString(Localizef("labelFormatX",{num = bdata.killNum}))
end
--显示获得星星动画
function Menu:showGetStar(view,isReplay)
    local nodeBattlePercent=self.battle.nodeBattlePercent.view
    local endSca=1
    if isReplay then
        nodeBattlePercent=self.replayMenu.LeftTopNode
        endSca=view:getScaleX()
    end
    local endPos={view:getPositionX(),view:getPositionY()}
    local point= nodeBattlePercent:convertToNodeSpace(cc.p(display.winSize[1]/2,display.winSize[2]/2))
    local initPos={point.x,point.y}
    view:setPosition(initPos[1],initPos[2])
    view:setScale(3)
    view:setOpacity(127)
    view:runAction(ui.action.fadeTo(0.5,255))
    view:runAction(ui.action.sequence({{"scaleTo",0.5,4,4},{"scaleTo",0.5,endSca,endSca}}))
    view:runAction(ui.action.sequence({{"delay",0.5},{"easeSineOut",{"moveTo",0.5,endPos[1],endPos[2]}}}))
end
--此处最好只处理UI显示
function Menu:updateBattle(diff)
    if self.scene.replay and self.scene.replay.isReplay and self.inCount then
        local rm = self.replayMenu
        local replay = self.scene.replay
        local bdata = self.scene.battleData
        if self.replayOver then
            self.replayOver = nil
        else
            if replay.locked then
                return
            end
        end
        replay:update(diff)
        if replay.remainTime then
            rm.lbRemainTime:setString(Localizet(replay.remainTime))
        else
            rm.lbRemainTime:setString(Localizet(replay.playTime))
        end
        rm.lbRemainTime:setVisible(true)
        local ucontext = bdata.replayUcontext
        local econtext = GameLogic.getCurrentContext()
        rm.labelAtkGValue:setString(ucontext:getInfoItem(const.InfoName))
        rm.labelDefGValue:setString(econtext:getInfoItem(const.InfoName))
        rm.labelAtkGValue:setVisible(true)
        rm.labelDefGValue:setVisible(true)

        local loser, percent, star = bdata:computeBattleResult()
        if percent then
            if percent~=bdata.percent then
                rm.lbPetValue:setString(percent .. "%")
                bdata.percent = percent
            end
            if star~=bdata.star then
                bdata.star = star
                for i=1, 3 do
                    local view = rm["nodeStar" .. i]
                    if star>=i and not rm["showStared"..i] then
                        rm["showStared"..i]=true
                        self:showGetStar(view,true)
                    end
                    view:setVisible(star>=i)
                end
            end
        end
        if replay.isBattleEnd then
            GameLogic.setSchedulerScale(1)
            self.replayMenu:setVisible(false)
            ReplayAgainDialog.new(self.scene.battleParams.replayId,self.scene)
        end
        return
    end

    if GEngine.rawConfig.DEBUG_OBJECT then
        local battle = self.battle
        if not battle.forLogTime then
            battle.forLogTime = 0
        end
        battle.forLogTime = battle.forLogTime+diff
        if battle.forLogTime>2 then
            battle.forLogTime = 0
        end
    end
    if GEngine.rawConfig.DEBUG_REPLAY then
        if not forWhile then
            local t = os.time()
            local at = 0
            while self.battleData.state<2 and self.inCount do
                forWhile = true
                self:updateBattle(0.025)
            end
        end
    end

    --引导
    local context = GameLogic.getUserContext()
    local gtype = context.guide:getStep().type
    if (gtype == "pauseForSkill" or gtype == "pauseForGodSkill") and context.guide:getStepState() == 1 then
        self.scene.replay.ustime = socket.gettime()
        return
    end

    local bdata = self.battleData
    if bdata.state>=2 then
        return
    end
    local battle = self.battle
    local scene = self.scene
    do
        local rdiff = diff
        local replay = scene.replay
        if replay and self.inCount then
            if replay.locked then
                return
            end
            rdiff = replay:update(diff)
        end
        if bdata.state>0 then
            local loser, percent, star = bdata:computeBattleResult()
            if percent then
                if percent~=bdata.percent then
                    battle.labelBattlePercent:setString(percent .. "%")
                    bdata.percent = percent
                    if scene.battleType == const.BattleTypePvz then
                        local reborn = bdata.scene.battleParams.foeData.pvzData.reborn
                        --兼容试玩，没有重生buff
                        reborn = reborn or 0
                        local _, score = bdata:computePvzScore(reborn)
                        battle.lb_battleScore:setString("+"..score)
                    end
                end
                if star~=bdata.star then
                    bdata.star = star
                    for i=1, 3 do
                        local view = battle["nodeStar" .. i].view
                        if star>=i and not battle["showStared"..i] then
                            battle["showStared"..i]=true
                            self:showGetStar(view)
                        end
                        view:setVisible(star>=i)
                    end
                end
            end
            local groupData = bdata.groups[1]
            battle.angerProcess:setScaleProcess(true, groupData.anger/10)
            local ProcessScal=math.floor(groupData.anger/0.5)/20*(1600/449)
            if ProcessScal>(battle.ProcessScal or 0) then
                battle.angerProcess22.view:setScaleX(ProcessScal)
                if not battle.aNode then
                    local temp=ui.node()
                    display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
                    battle.nodeBattleBottom.view:addChild(temp,3)
                    battle.aNode=temp
                end
                UIeffectsManage:showEffect_nengLiangTiao(1,battle.angerProcess22.view,ProcessScal,battle.aNode,math.floor(groupData.anger*2)/2)
            elseif ProcessScal<(battle.ProcessScal or 0) then
                if battle.aNode then
                    battle.aNode:removeAllChildren()
                end
                battle.angerProcess22.view:stopAllActions()
                battle.angerProcess22.view:setScaleX(ProcessScal)
            end
            battle.ProcessScal=ProcessScal

            battle.labelDouqiValue:setString(Localizef("aDivideB", {a=tostring(math.floor(groupData.anger*2)/2), b=10}))
            if groupData.anger>=10 and not battle.effNode2 then
                local effNode2=ui.node()
                display.adapt(effNode2, 80, 40, GConst.Anchor.Left)
                battle.nodeBattleBottom.view:addChild(effNode2,3)
                battle.effNode2=effNode2
                UIeffectsManage:showEffect_nengLiangTiao(2,effNode2)
            elseif groupData.anger<10 and battle.effNode2 then
                battle.effNode2:removeFromParent(true)
                battle.effNode2=nil
            end
            if loser>0 and bdata.state==1 then
                self.isWin = (loser==2)
                self:endBattle(true)
            end
            --天神技能按钮
            for i,v in pairs(battle.godBut) do
                local hpos = groupData.hitems[i].hpos
                local hero = groupData.heros[hpos]
                if hero and type(hero) == "table" and not hero.deleted and not hero.releasedGodSkill then
                    v.but:setVisible(true)
                    if hero.sid == 4031 then
                        local asId, godSkillId
                        if hero.heroState ~= v.but.heroState then
                            v.but.heroState = hero.heroState
                            if hero.heroState == 0 then
                                godSkillId = 40312
                            elseif hero.heroState == 1 then
                                godSkillId = 4031
                            end
                            asId = SData.getData("adatas",godSkillId,5).skill
                            v.but.image:removeFromParent(true)
                            v.but.image = GameUI.addSkillIcon(v.but:getDrawNode(), 5, asId, 1/3, 60, 60, 0)
                        end
                    end
                    v.timePro.time = v.timePro.time+diff
                    local progress = 1-v.timePro.time/v.timePro.sptime
                    if progress <= 0 then
                        progress = 0
                        v.but:setEnable(true)
                        v.canSkill:setVisible(true)
                    else
                        v.but:setEnable(false)
                    end
                    v.timePro:setPercentage(progress*100)
                    if context.guide:getStep().type == "pauseForGodSkill" and context.guide:getStepState() == 0 then
                        v.gtime = (v.gtime or 0)+rdiff
                        if v.gtime >= GMethod.loadConfig("configs/settings.json").guideGodTime then
                            context.guideHand:showArrow(v.but,60,136,20)
                            display.pushGuide(Localize("stringClickUseGodSkill"))
                            context.guide:setStepState(1)
                        end
                    end
                else
                    v.but:setVisible(false)
                end
            end
        end
        if scene.battleType==const.BattleTypePvp then
            self:updatePvpBattle(rdiff)
        elseif scene.battleType==const.BattleTypePvj then
            self:updatePvjBattle(rdiff)
        end
        for _,hbut in ipairs(battle.heroBut) do
            GameUI.updateBattleHeroTemplate(hbut)
        end
        if battle.weaponButs then
            for _, wbut in ipairs(battle.weaponButs) do
                GameUI.updateBattleWeaponTemplate(wbut)
            end
        end
        if battle.eheroBut then
            for _,hbut in ipairs(battle.eheroBut) do
                GameUI.updateEnemyHeroTemplate(hbut)
            end
        end
        if battle.ebossBut then
            for i,v in ipairs(battle.ebossBut) do
                GameUI.updateBattleBossTemplate(v)
            end
        end
        if battle.labelBossHarmValue then
            --boss伤害
            battle.labelBossHarmValue:setString(math.floor(bdata.bossDamageValue))
        end
        if battle.processAllHp then
            battle.processAllHp:setProcess(true,bdata.allNowHp/bdata.allMaxHp)
        end
        if battle.butAutoBattle then
            battle.butAutoBattle:setGray(not bdata.groups[1].isAuto)
        end
    end
end

--准备页面仅用于倒计时
function Menu:updatePrepare(diff)
    local bdata = self.battleData
    local battle = self.battle
    local scene = self.scene
    if bdata.time then
        bdata.time = bdata.time-diff
        if bdata.time<=0 then
            self:startBattle()
            bdata.time = nil
        end
        if bdata.time then
            battle.labelTimeValue:setString(Localizet(bdata.time))
        else
            battle.labelTimeValue:setString("")
        end
    end
end

function Menu:beginpvlatk(params)
    if params.atknum>=const.UPvpTimes then
        display.pushNotice(Localize("stringUPvpNotEnough"))
        return
    end
    local nowItemIdx = params.nowItemIdx
    local uid = params.uid
    local cid = params.unionId
    local deathNum = params.deathNum
    GameLogic.checkCanGoBattle(const.BattleTypeUPvp,function()
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("beginpvlbt", {lid=cid,tid=uid},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                --code 10.有盟友在战斗中 11.未设置参战状态不允许攻打 12.你已经被退出该联盟
                if data.code == 10 then
                    display.pushNotice(Localize("stringcantUnionMap"))
                elseif data.code == 11 then

                elseif data.code == 12 then

                else
                    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=8,data = data,bparams = {deathNum=deathNum,index = nowItemIdx,pvldata = {lmid=cid,duid=uid,addlv=params.addlv,destroyDebuffs=params.destroyDebuffs}}})
                end
            else

            end
        end)
    end)
end

return Menu
