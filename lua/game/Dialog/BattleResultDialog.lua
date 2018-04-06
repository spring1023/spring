local SData = GMethod.loadScript("data.StaticData")
local const = GMethod.loadScript("game.GameLogic.Const")
GMethod.loadScript("game.GameEffect.BattleOverEffect")
BattleResultDialog = class(DialogViewLayout)

function BattleResultDialog:onInitDialog()
    self:setLayout("BattleResultDialog.json")
    local data = self.battleData
    local loser, percent, star = data:computeBattleResult()
    self.loser = loser
    self.star = star or 3
    self.percent = percent
    self.isWin = self.star>0
    local heros = {}
    local weapons = {}
    local hids = {}
    local actHids = {}
    self.heros = heros
    self.weapons = weapons
    self.btn_help:setVisible(false)
    self.btn_help:setEnable(false)
    local function showHelpDialog(aid)
        self.btn_help:setVisible(true)
        self.btn_help:setEnable(true)
        UIeffectsManage:showEffect_guangka(self.btn_help,77,77,1)
        self.btn_help:setScriptCallback(ButtonHandler(function ()
            local ainfo = GameLogic.getUserContext().talentMatch:getMatchInfo(aid)
            display.sendIntent({class="game.Dialog.TalentMatchHelpDialog", params={ainfo=ainfo}})
        end, self))
    end
    local forceDead = self.star==0
    if data.scene.battleParams.useSpecialHero then
        forceDead = false
    end
    GameLogic.dumpCmds(true)
    if data.scene.battleType == const.BattleTypePvt then
        self.isWin = data.isWin
        if not self.isWin then
             self.star = 0
        end
        for _,v in ipairs(data.heros) do
            if type(v) == "table" and v.hero then
                local dead = v.role and v.role.avtInfo.nowHp <= 0
                local alv = v.role and v.role.avtInfo.alevel  or 0
                table.insert(heros,{hid = v.hero.hid, dead = dead, level = v.hero.level, alevel=alv})
                table.insert(actHids, v.hero.hid)
            end
        end
    else
        for _, hero in pairs(data.groups[1].heros) do
            if type(hero) == "table" then
                local dead = hero.avtInfo.nowHp <= 0 or forceDead
                if dead then
                    table.insert(hids, hero.dataIdx)
                end
                table.insert(heros, {hid=hero.sid, dead=dead, level=hero.avtInfo.level, alevel=hero.avtInfo.alevel})
                table.insert(actHids, hero.sid)
            end
        end
    end

    if data.groups[1].witems then
        for _, witem in ipairs(data.groups[1].witems) do
            if witem.use>0 then
                table.insert(weapons,{witem.wid,witem.use})
            end
        end
    end
    self.context.weaponData:costWeapons(weapons)
    music.setBgm(nil)
    --此处处理网络请求
    local hasReward = false
    local scene = data.scene
    local bparams = scene.battleParams
    self.opType = scene.battleType
    if bparams.tryHids then
        self:addLayout("battleUPve")
        self:loadViewsTo()
        self.guangxiao.view:runAction(ui.action.arepeat(ui.action.rotateBy(0.5,90)))
        self.labelHarmLeft:setVisible(false)
        self.labelHarmRight:setVisible(false)
        self.labelHarmValue:setVisible(false)
    elseif scene.battleType==const.BattleTypePvp then
        self:addLayout("battlePvp")
        local mcontext = GameLogic.getUserContext()
        local econtext = GameLogic.getCurrentContext()
        local brokelist = {}
        local replayInfo = scene.replay:encodeData()
        local hlist = {}
        local loseGold = 0
        local stime = GameLogic.getSTime()
        for _, build in pairs(econtext.buildData:getSceneBuilds()) do
            if build.resInfo and build.resInfo[1]>0 and build.resInfo[4]>0 then
                if build.collectResource then
                    local res = build:getResource(true) - build.resInfo[4]
                    if res < 0 then
                        res = 0
                    end
                    table.insert(brokelist, {econtext.uid, build.id, res, stime})
                else
                    loseGold = loseGold+build.resInfo[4]
                    local res = build.extData[1]-build.resInfo[4]
                    if res < 0 then
                        res = 0
                    end
                    table.insert(brokelist, {econtext.uid, build.id, res, build.extData[4]})
                end
            end
        end
        -- for _, hero in ipairs(heros) do
        --     table.insert(hlist, hero.hid)
        --     table.insert(hlist, hero.level)
        -- end
        for _, hero in ipairs(heros) do
            table.insert(hlist, {hero.hid,hero.level,hero.alevel})
        end
        self.gold = bparams.get
        hasReward = true
        self.lock = true
        local sendParams = {hlist=hlist, rversion=1, rtime=stime, syn_id=mcontext:getLastSynId(), uid=mcontext.uid, eid=econtext.uid, stars=self.star, hs=hids, wp=weapons, rv=bparams.isReverge and 1 or 0, destroy=self.percent, broke=brokelist, batinfo=replayInfo, ggold=bparams.get, lgold=-loseGold}
        if bparams.repid then
            sendParams.repid = bparams.repid
        end
        sendParams.actHids = actHids
        mcontext.pvpChance:changeValue(-1, stime)
        self.boxRate = mcontext:computePvpRate(mcontext.pvpChance:getNormalValue(stime))
        local uid=GameLogic.uid
        local sid=GameLogic.getUserContext().sid
        local dlKey="deflog_" .. uid .."_".. sid
        if GEngine.getConfig(dlKey) then--本地已存在
            local deflogData = json.decode(GEngine.getConfig(dlKey))
            for i,data in ipairs(deflogData) do
                if data.id==bparams.repid then
                    data.isRe=1--表示已复仇
                end
            end
            GEngine.setConfig(dlKey, json.encode(deflogData),true)
        end
        GameNetwork.request("pvpresult", sendParams, self.onPvpCallback, self)
        --英雄pvp无重生活动 start
        local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffImmortal)
        if buffInfo[4]~=0 then

        else
            self.context.heroData:costHeros(hids, GameLogic.getSTime())
        end
        self.context.talentMatch:updateTalentMatch(const.TalentMatchPvp, bparams.get)
        --self.context.heroData:costHeros(hids, GameLogic.getSTime())
        --end
        if self.isWin then
            --13 掠夺战，任务ID13，任务类型1004 activeData:finishAct(13)
            GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVP, 1)
            --活动:使用特定英雄赢得一场特定类型战斗
            for _, hero in ipairs(self.heros) do
                GameLogic.getUserContext().activeData:finishActCondition(hero.hid * 10000 + const.ActTypePVP, 1)
            end
        else
            if GameLogic.useTalentMatch then
                showHelpDialog(const.TalentMatchPvp)
            end
        end
        if scene.revenge == true then
            scene.revenge = false
        end
    elseif scene.battleType==const.BattleTypePve then
        if scene.battleParams.stage == const.HeroInfoNewTry then

        else
            if self.isWin then --pve战斗胜利
                local missionId=scene.battleParams.stage
                Plugins:onStat({callKey=4,taskType="Completed",missionId=tostring(missionId)})
                GameLogic.getUserContext().activeData.lastPveMission = missionId
                --活动:使用特定英雄赢得一场特定类型战斗
                for _, hero in ipairs(self.heros) do
                    GameLogic.getUserContext().activeData:finishActCondition(hero.hid * 10000 + const.ActTypePVE, 1)
                end
            else
                Plugins:onStat({callKey=4,taskType="Failed",missionId=tostring(scene.battleParams.stage),cause="打不过"})
            end
            self:addLayout("battlePve")
            hasReward = true
            self.lock = true
            --引导
            local context = GameLogic.getUserContext()
            if context.guide:getCurrentState()<6 then
                while context.guide:getCurrentState()<6 do
                    context.guide:addStep()
                end
                context.heroData = context.bheroData
                context.bheroData = nil
                self.rewardList = {{10,1,1000},{10,1,1000},{10,1,1000}}
                self.lock = nil
                self.noOpen = true
            else
                GameNetwork.request("pveresult",{rtime=GameLogic.getSTime(), idx=bparams.stage, star=self.star, heros=hids, weapons=weapons, actHids=actHids}, self.onPveCallback, self)
                self.context.heroData:costHeros(hids, GameLogic.getSTime())
                if self.isWin then
                    GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVE,1)
                    --13 闯关战，任务ID13，任务类型1005 activeData:finishAct(13)
                end
            end
        end
    elseif scene.battleType == const.BattleTypePvz then
        self.lock = true
        self:addLayout("battlePvz")
        local replayData = json.decode(scene.replay:encodeData())
        replayData.battleParams = scene.battleParams
        local rep = json.encode(replayData)
        local _ucontext = GameLogic.getUserContext()
        local _tcontext = GameLogic.getCurrentContext()
        local pvzData = _tcontext.pvzData

        local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")

        local reborn = pvzData.reborn
        -- 兼容试玩，没有重生buff
        reborn = reborn or 0
        local score = self.battleData:computePvzScore(reborn)
        score = KnockMatchData:getRebornAddScore(reborn, score)

        local uid = _ucontext.uid
        local tid = _tcontext.uid
        local uname = _ucontext:getInfoItem(const.InfoName)
        local ulv = _ucontext:getInfoItem(const.InfoLevel)
        local tname = _tcontext:getInfoItem(const.InfoName)
        local tlv = _tcontext:getInfoItem(const.InfoLevel)

        local thead = pvzData.head
        local uhead = _ucontext:getInfoItem(const.InfoHead)
        local tPos = pvzData.pos
        local week = KnockMatchData:getWeek()

        local matchType = _tcontext.pvzData.matchType
        local uinfos = {name = uname, lv = ulv, head = uhead}
        local tinfos = {name = tname, lv = tlv, head = thead}

        local myHeroList = {}
        local eHeroList = {}
        for _, hero in pairs(data.groups[1].heros) do
            --神兽去掉,显示不下
            if hero.sid<8000 then
                table.insert(myHeroList, {hero.sid,hero.avtInfo.level,hero.avtInfo.alevel})
            end
        end
        for _, hero in pairs(data.groups[2].heros) do
            table.insert(eHeroList, {hero.sid,hero.avtInfo.level,hero.avtInfo.alevel})
        end
        local params = {rep = rep, uheros = myHeroList, theros = eHeroList, uinfos = uinfos, tinfos = tinfos, destroy = self.percent, star = self.star, bagain = reborn, score = score, wps = weapons, tid = tid, oder = tPos, wk = week, gk = matchType}

        local type = _tcontext.pvzData.type
        if type ~= 2 then
            GameNetwork.request("afterPvzBattle", params, self.onPvzCallback, self)
            --触发活动
            if self.isWin and matchType == 0 then
                GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeKnockDivide,1)
            end
        else
            self:loadViewsTo()
            self.nd_battlePvz:setVisible(false)
            if self.lock then
                self.lock = nil
            end
            -- self:onPvzCallback()
        end
    elseif scene.battleType==const.BattleTypePvc then
        self:addLayout("battlePvc")
        self.lock = true
        local hls = {}
        local context = GameLogic.getCurrentContext()

        local sign = GameLogic.getUserContext():getProperty(const.ProUseLayout)
        sign = GameLogic.dnumber(sign, 3)
        local lid = const.LayoutPvp
        if sign[2]>0 then
            lid = const.LayoutPvc
        end
        for i=1, 5 do
            local hero = context.heroData:getHeroByLayout(lid, i, 1)
            if hero then
                local layout = hero.layouts[lid]
                local layoutPos = context.heroData:getHeroLayoutPos(const.LayoutPvc, i)
                table.insert(hls, {context.uid, hero.idx, const.LayoutPvc, i*100000+10000+layoutPos.x*100+layoutPos.y})
                for j=2, 4 do
                    local hero2 = context.heroData:getHeroByLayout(lid, i, j)
                    if hero2 then
                        table.insert(hls, {context.uid, hero2.idx, const.LayoutPvc, i*100000+j*10000})
                    end
                end
            end
        end
        self.aresult = self.context.arena:computeBattleResult(self.isWin,scene.battleParams)
        --参数hidxs,win,history,batid,rveid,uhls,thls,destroy
        --hidx 原布局信息,win 1胜利，0为失败,history 战报信息,batid 战报id,uhls 进攻方英雄数据,thls 防守方英雄数据
        local replayData = json.decode(scene.replay:encodeData())
        replayData.battleParams = {}
        replayData.battleParams.myRank = scene.battleParams.myRank
        replayData.battleParams.eRank = scene.battleParams.eRank
        local replayInfo = json.encode(replayData)
        local myHeroList = {}
        local eHeroList = {}
        for _, hero in pairs(data.groups[1].heros) do
            table.insert(myHeroList, {hero.sid,hero.avtInfo.level,hero.avtInfo.alevel})
        end
        for _, hero in pairs(data.groups[2].heros) do
            table.insert(eHeroList, {hero.sid,hero.avtInfo.level,hero.avtInfo.alevel})
        end
        local params={rveid=scene.battleParams.isRev,hidxs=hls,win=self.isWin and 1 or 0, uhls=myHeroList,thls=eHeroList,history=replayInfo,batid=scene.battleParams.batid}
        params.actHids=actHids
        GameNetwork.request("pvcresult",params, self.onPvcCallback, self)

        if self.isWin then
            GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVC,1)
            --13 竞技场，任务ID13，任务类型1003 activeData:finishAct(13)
            --活动:使用特定英雄赢得一场特定类型战斗
            for _, hero in ipairs(self.heros) do
                GameLogic.getUserContext().activeData:finishActCondition(hero.hid * 10000 + const.ActTypePVC, 1)
            end
        end
    elseif scene.battleType==const.BattleTypePvh then
        self:addLayout("battlePvh")
        self.lock = true
        local context = GameLogic.getCurrentContext()
        local forceLayouts = context.forceLayouts
        local tlv = 0
        local uid = context.uid
        local tnum = 0
        local ahrs = {}
        self.hresult = {magic=0, hp=0}
        local ucontext = GameLogic.getUserContext()
        local pvh,lid
        if scene.battleParams.nightmare then
            pvh = ucontext.npvh
            lid=const.LayoutnPvh
        else
            pvh = ucontext.pvh
            lid=const.LayoutPvh
        end
        if self.isWin then
            self.hresult.magic = context.enemy:getInfoItem(const.InfoScore)
            ucontext:changeRes(const.ResMagic, self.hresult.magic)
            pvh.stage = pvh.stage+1
            --大于18关之后不回血 理论上18关是回血的  出战英雄回血15%
            self.hresult.hp = pvh.stage>18 and 0 or 15
        end
        for i=1, 5 do
            local hl = forceLayouts:getHeroLayout(i)
            if hl then
                local xy = 0
                local lpos = ucontext.heroData:getHeroLayoutPos(lid, i)
                if lpos then
                    xy = lpos.x*1000+lpos.y*10
                end
                table.insert(ahrs, {i*100000000+10000001+xy,uid,hl.hero.idx})
                tlv = tlv+hl.hero.level
                tnum = tnum+1
                local hero = data.groups[1].heros[hl.pos]
                if hero then
                    if not hero.avtInfo or hero.avtInfo.nowHp <= 0 or forceDead then
                        hl.hp = 0
                    else
                        hl.hp = math.floor(100*hero.avtInfo.nowHp/hero.avtInfo.maxHp)+self.hresult.hp
                        if hl.hp>100 then
                            hl.hp = 100
                        end
                    end
                end
            end
        end

        if tnum>0 then
            tlv = math.floor(tlv/tnum)
        end
        local hs = forceLayouts:save()
        local uhrs = {}
        local dhrs = {}
        local econtext = context.enemy
        for lidx, hv in pairs(data.groups[2].heros) do
            local hd = econtext.heroData:getHeroByLayout(lid, lidx, 1)
            table.insert(dhrs, {hd.idx, math.ceil(100*hv.avtInfo.nowHp/hv.avtInfo.maxHp)})
        end
        for k, v in pairs(hs) do
            table.insert(uhrs, {v,uid,k})
        end
        if tlv>pvh.maxLv then
            pvh.maxLv = tlv
        else
            ahrs = {}
        end
        local anger = scene.battleData.groups[1].anger

        if scene.battleParams.nightmare then
            if scene.battleParams.stage<35 then
                anger = math.floor(anger*10)
            else
                anger = 0
            end
            self.context.npvh:changeAnger(anger)
        else
            anger = math.floor(anger*10)
            self.context.pvh:changeAnger(anger)
        end
        if scene.battleParams.nightmare then
            if not self.isWin then
                showHelpDialog(const.TalentMatchPvh)
            end
            GameNetwork.request("npvhresult",{syn_id=GameLogic.getUserContext():getLastSynId(), uhrs=uhrs, dhrs=dhrs,
            aglv=tlv,win=self.isWin and 1 or 0, qid=scene.battleParams.stage,weapons=weapons,ahrs=ahrs,
            sp=anger}, self.onPvhCallback, self)
            self.context.talentMatch:saveTalentMatchPvh()
        else
            GameNetwork.request("pvhresult",{syn_id=GameLogic.getUserContext():getLastSynId(), uhrs=uhrs, dhrs=dhrs,
            aglv=tlv,win=self.isWin and 1 or 0, qid=scene.battleParams.stage,weapons=weapons,ahrs=ahrs,
            sp=anger}, self.onPvhCallback, self)
        end
    elseif scene.battleType==const.BattleTypePvj then
        self:addLayout("battlePvj")
        self:loadViewsTo()
        hasReward = true
        self.lock = true
        self.lab_resultKill:setString(Localize("tmPvjKillNum"))
        self.lab_killNum:setString(Localizef("labelFormatX",{num=scene.battleData.killNum}))
        if scene.battleParams.DRPvj then
            GameNetwork.request("afterdrpvjbattle",{syn_id=GameLogic.getUserContext():getLastSynId(),
            afterpvjbattle = {bparams.index, self.star, scene.battleData.killNum}}, self.onDRPvjCallback, self)
            local tmdata = self.context.talentMatch:getMatchNow(const.TalentMatchPvj)
            if tmdata then
                self.context.talentMatch:updateTalentMatch(const.TalentMatchPvj, scene.battleData.killNum, self.star > 0 and (tmdata.avalue2 + 1) or tmdata.avalue2)
                if self.star == 0 then
                    tmdata.chance = tmdata.chance + 1
                    showHelpDialog(const.TalentMatchPvj)
                end
            end
        else
            GameNetwork.request("afterpvjbattle",{syn_id=GameLogic.getUserContext():getLastSynId(),
            afterpvjbattle = {bparams.index,self.star,weapons,actHids}},self.onPvjCallback, self)
        end
        --self.context.heroData:costHeros(hids, GameLogic.getSTime())
    elseif scene.battleType == const.BattleTypeUPve then
        self:addLayout("battleUPve")
        self:loadViewsTo()
        self.guangxiao.view:runAction(ui.action.arepeat(ui.action.rotateBy(0.5,90)))
        local bdata = data
        local bosslist = {}
        local bsitems = bdata.groups[2].bsitems
        local bossItems = {}
        local process = 0
        local rbefore, rnow, rmax = 0, 0, 0
        local obossList = GameLogic.getUserContext().bosslist
        local boss = SData.getData("upveboss",bparams.index)
        for k,vv in KTIPairs(boss) do
            local nowHp, maxHp
            if bsitems[k] then
                local v=bsitems[k]
                nowHp = math.floor(v.role.avtInfo and v.role.avtInfo.nowHp or 0)
                maxHp = v.role.avtInfo and v.role.avtInfo.maxHp or 100
            else
                --已死亡
                nowHp = 0
                maxHp = obossList[k] and obossList[k][2] or 100
            end
            local beforeHp = obossList[k] and obossList[k][1] or maxHp
            if nowHp > beforeHp then
                nowHp = beforeHp
            end
            rnow = rnow + nowHp
            rmax = rmax + maxHp
            rbefore = rbefore + beforeHp
            process = process + nowHp/maxHp
            table.insert(bosslist, {k, nowHp, maxHp})
            table.insert(bossItems, {bid=vv[1], level=vv[2], now=nowHp, max=maxHp})
        end
        process = 1 - process / KTLen(boss)
        process = math.floor(process*100)
        self.labelHarmValue:setString(math.floor(rbefore-rnow))
        self.displayBossItems = bossItems
        _G["GameNetwork"].request("afterpvlbattle",{syn_id=GameLogic.getUserContext():getLastSynId(), afterpvlbattle = {bparams.index,json.encode(bosslist),rbefore-rnow,weapons,self.loser == 2 and 1 or 0, process}},function(isSuc,data)
            if isSuc then
                log.d("战斗结束")
                local activeData = GameLogic.getUserContext().activeData
                activeData:finishAct(7)
                self.shareParams = {stype="upve", url="http://coz2.moyuplay.com/share1.html"}
            end
        end)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVLE, 1)
    elseif scene.battleType == const.BattleTypeUPvp then
        local bdata = data
        local scoreAll = const.UnionPvlData[bparams.index][3]
        if bdata.allNowHp < 0 then
            bdata.allNowHp = 0
        end
        if bdata.allMaxHp < 1 then
            bdata.allNowHp = 1
            bdata.allMaxHp = 1
        end
        local cid = GameLogic.getUserContext().union.id
        local uid = GameLogic.getUserContext().uid
        local pct = math.ceil(10000*bdata.allNowHp/bdata.allMaxHp)
        pct = bdata.allNowHp<1 and 0 or pct
        local lmid = scene.battleParams.pvldata.lmid
        local duid = scene.battleParams.pvldata.duid
        local score = math.floor((10000-pct)*scoreAll/10000)-math.floor((10000-bdata.allHpPct)*scoreAll/10000)
        -- uinfos 进攻方信息 （[分数,联盟Id,Uid]）
        -- dinfos 防守方信息 （[血量百分比，联盟Id,Uid]）注血量百分比为此次攻打减少的百分比数，为负数，若正数则加血，理论不给加血
        -- wps 超级武器消耗，格式不改
        -- rep 回放所需，战报
        -- blog 无效字段
        -- us 进攻方战报展示信息
        -- ts 防守方战报展示信息
        -- uhero 进攻方英雄列表
        -- thero 防守方英雄列表
        -- mtime 战斗持续时间
        local replayData = json.decode(scene.replay:encodeData())
        replayData.battleParams = scene.battleParams
        local replayInfo = json.encode(replayData)
        --local replayInfo = ""
        --GameLogic.saveReplay("replay_testUPvp.json",replayInfo)
        --replayInfo = ""
        local us=scene.battleParams.us
        local ts=scene.battleParams.ts
        local myHeroList = {}
        local eHeroList = {}
        for _, hero in pairs(data.groups[1].heros) do
            --神兽去掉,显示不下
            if hero.sid<8000 then
                table.insert(myHeroList, {hero.sid,hero.avtInfo.level,hero.avtInfo.alevel})
            end
        end
        for _, hero in pairs(data.groups[2].heros) do
            table.insert(eHeroList, {hero.sid,hero.avtInfo.level,hero.avtInfo.alevel})
        end
        local mtime = replayData.time
        --是否全部打完
        local ends = 0
        local deathNum=scene.battleParams.deathNum or 0
        if deathNum>=29 and bdata.allNowHp<=0 then
            ends=1
        end
        local params= {syn_id=GameLogic.getUserContext():getLastSynId(),ends=ends, uinfos={score,cid,uid},dinfos={pct,lmid,duid,bparams.index},wps=weapons,rep=replayInfo,uhero=myHeroList,thero=eHeroList,mtime=mtime,us=us,ts=ts}
        _G["GameNetwork"].request("atkplayer",params,function(isSuc,data)
            if isSuc then
                log.d("战斗结果")
                self.shareParams = {stype="upvp", url="http://coz2.moyuplay.com/share1.html"}
                --活动53
                local activeData = GameLogic.getUserContext().activeData
                activeData:finishAct(53)
                -- if data.uscore then
                --     self.labelWinValue:setString(data.uscore .. Localize("labelSc"))
                -- else
                --     self.labelWinValue:setString(score .. Localize("labelSc"))
                -- end
            end
        end)
        self:addLayout("battleUPvp")
        self:loadViewsTo()
        self.proHp:setProcess(true,pct/10000)
        if not self.isWin then
            ui.setColor(self.labelWinValue,252,52,52)
            self.labelWin:setString(Localize("labelOpponentdeFailIntegralTips"))
        end
        self.labelWinValue:setString(score .. Localize("labelSc"))
    elseif scene.battleType == const.BattleTypePvt then
        local bdata = data
        --为了先发送开始战斗的cmd
        _G["GameNetwork"].request("pvtafterbattle",{syn_id=GameLogic.getUserContext():getLastSynId(), pvtafterbattle = {self.isWin and 1 or 0,bdata.index,bdata.usedSkill}},function(isSuc,data)
            if isSuc then
                --活动
                self.shareParams = {stype="pvt", url="http://coz2.moyuplay.com/share1.html"}
                local activeData = GameLogic.getUserContext().activeData
                activeData:finishAct(3)
            else

            end
        end)

        local score = bdata.getScore
        self:addLayout("battleTrial")
        self:loadViewsTo()
        if not self.isWin then
            ui.setColor(self.labelWinValue,252,52,52)
            self.labelWin:setString(Localize("labelOpponentdeFailIntegralTips"))
        end
        self.labelWinValue:setString(score .. Localize("labelSc"))
        if self.isWin then
            GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVT, 1)
        end
    elseif scene.battleType == const.BattleTypePvb then
        self:addLayout("battleUPve")
        self:loadViewsTo()
        self.guangxiao.view:runAction(ui.action.arepeat(ui.action.rotateBy(0.5,90)))
        local bdata = data
        local bosslist = {}
        local bsitems = bdata.groups[2].bsitems
        local rbefore, rnow, rmax = 0, 0, 0
        local obossList = GameLogic.getUserContext().bosslist
        local nowHp, maxHp
        local v = bsitems[1]
        nowHp = math.floor(v.role.avtInfo and v.role.avtInfo.nowHp or 0)
        maxHp = v.role.avtInfo and v.role.avtInfo.maxHp or 100
        local beforeHp = maxHp - scene.battleParams.lostHp
        if nowHp > beforeHp then
            nowHp = beforeHp
        end
        rnow = rnow + nowHp
        rmax = rmax + maxHp
        rbefore = rbefore + beforeHp
        self.labelHarmValue:setString(math.floor(rbefore-rnow))
        if self.loser == 2 then
            self.nodeBossTable:setSize(0, 0)
            self.nodeBossTable:removeAllChildren(true)
            self.boxes = {}
            local temp
            local maxBoxNum = 1
            local getBoxNum = 1
            local offx = -374*(maxBoxNum-1)/2
            for i=1,maxBoxNum do
                temp = ui.node(nil, true)
                display.adapt(temp, offx, -60, GConst.Anchor.Center)
                self.nodeBossTable:addChild(temp)
                self.boxes[i] = {back=temp}
                temp = ui.sprite("images/battleBox1.png",{238, 210})
                if i>getBoxNum then
                    temp:setSValue(-100)
                end
                display.adapt(temp, 0, 0, GConst.Anchor.Center)
                self.boxes[i].back:addChild(temp)
                offx = offx+374
                self.boxes[i].box = temp
            end
            hasReward = true
            self.star = 3
            self.lock = true
        else
            self.displayBossItems = {{bid=v.role.avtInfo.id, level=v.role.avtInfo.level, now=nowHp, max=maxHp}}
            self.nodeBossTable:setSize(160, 685)
        end
        local tm = GameLogic.getUserContext().talentMatch:getMatchNow(bparams.aid)
        if tm then
            GameLogic.getUserContext().talentMatch:updateTalentMatch(bparams.aid, rbefore-rnow,
                (self.loser == 2 and bparams.stage or (bparams.stage-1 + (maxHp-nowHp) * 100)))
            if self.loser ~= 2 then
                tm.chance = tm.chance + 1
                showHelpDialog(bparams.aid)
            end
        end
        _G["GameNetwork"].request("aftertpvbbattle",{syn_id=GameLogic.getUserContext():getLastSynId(), aid=bparams.aid, stage=bparams.stage, hp=rbefore-rnow, weapons=weapons, win=self.loser == 2 and 1 or 0},function(isSuc,data)
            if isSuc then
                self.lock = false
                self.rewardList = data.agl
                if data.agl then
                    GameLogic.addRewards(data.agl)
                end
                -- local activeData = GameLogic.getUserContext().activeData
                -- activeData:finishAct(7)
                -- self.shareParams = {stype="upve", url="http://coz2.moyuplay.com/share1.html"}
            end
        end)
        -- GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVLE, 1)
    end
    self:loadViewsTo()
    if hasReward and self.star>0 then
        self.btnBattleWord:setString(Localize("btnRandomReward"))
    else
        self.btnBattleWord:setString(Localize("btnBackBase"))
    end
    if scene.battleType == const.BattleTypePvz then
        local _tcontext = GameLogic.getCurrentContext()
        if _tcontext.pvzData.type == 0 then
            self.btnBattleWord:setString(Localize("labBack"))
        end
    end
    self.btnBattleEnd:setScriptCallback(ButtonHandler(self.onTouchEnd, self))
    --暂且关闭
    if self.btnFriendShare then
        self.btnFriendShare:setVisible(false)
        -- ui.setListener(self.btnFriendShare,function()
        --     if self.shareParams then
        --         Plugins:share(self.shareParams)
        --     end
        -- end)
    end
    -- if scene.battleType == const.BattleTypePvz then
    --     local _tcontext = GameLogic.getCurrentContext()
    --     local type = _tcontext.pvzData.type
    --     if type ~=2 then
    --         self.btnFriendShare:setVisible(true)
    --         local function callback()
    --             Plugins:share(self.shareParams)
    --         end
    --         self.btnFriendShare:setScriptCallback(ButtonHandler(callback))
    --     end
    -- end
end

function BattleResultDialog:onPvpCallback(suc, data)
    if suc then
        self.shareParams = {stype="pvp", url="http://coz2.moyuplay.com/share1.html"}
        self.lock = nil
        local ucontext = self.context
        local bdata = self.battleData
        local scene = bdata.scene
        local bparams = scene.battleParams
        local stime = GameLogic.getSTime()
        self.score = data.gsc
        ucontext:changeRes(const.ResScore, self.score)

        --成就
        local score = ucontext:getInfoItem(const.InfoScore)
        local achieveData = GameLogic.getUserContext().achieveData
        -- achieveData:finish(4,score)
        achieveData:finish(const.ActTypePVPCup,score)

        ucontext:changeResWithMax(const.ResGold, self.gold)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVPGold, self.gold)
        GameLogic.addRewards(data.agl)
        GameLogic.statCrystalRewards("pvp战斗结束奖励", data.agl)
        self.rewardList = data.agl
        if self.rewardList and #(self.rewardList)==0 then
            self.rewardList = nil
        end
        if not self.deleted then
            self.labelChanceLeft:setString(Localizef("labelChanceLeft",{max=ucontext.pvpChance:getMax(stime), num=ucontext.pvpChance:getValue(stime)}))
            self.labelGoldGet:setString(N2S(self.gold))
            self.labelScoreGet:setString(N2S(self.score))
            if self.score<0 then
                self.labelScoreGet:setColor(GConst.Color.Red)
            end
        end

        --活动
        local activeData = ucontext.activeData
        activeData:finishAct(8)
        activeData:finishAct(9,self.gold)

        --获取战报数据
        GameLogic.getUserContext().logData:getLogDatas()
    else
        display.pushNotice("服务器请求错误，请退出游戏重试！")
    end
end

function BattleResultDialog:onPveCallback(suc, data)
    if suc then
        self.shareParams = {stype="pve", url="http://coz2.moyuplay.com/share1.html"}
        self.lock = nil
        local ucontext = self.context
        local pve = ucontext.pve
        local bdata = self.battleData
        local scene = bdata.scene
        local bparams = scene.battleParams
        local stime = GameLogic.getSTime()
        -- pve.etime = data.etime
        if (GameLogic.useTalentMatch and bparams.star == 0) or self.star == 0 then
        else
            pve:changeChance(-1)
        end
        if data.actId then
            ucontext.activeData:updateActRecord(data.actId, const.ActTypeBuffPVE, data.ctime, 1)
        end
        if bparams.star<=self.star then
            pve.stars[bparams.stage] = self.star
            if self.star>0 and bparams.stage==pve.maxIdx then
                --成就
                local achieveData = GameLogic.getUserContext().achieveData
                -- achieveData:finish(3,pve.maxIdx)
                -- 通关普通关卡
                achieveData:finish(const.ActTypePveGK,pve.maxIdx)
                if pve.maxIdx<pve:getPveMaxStage() then
                    pve.maxIdx = pve.maxIdx+1
                    pve.nowIdx = pve.maxIdx
                end
            end
        end

        local rewardList = {}
        local rewardList2 = {}
        local specialList = {}
        local addedRewd = {}
        for i, reward in ipairs(data.agl) do
            rewardList2[i] = {reward[2], reward[3], reward[4]}
            if reward[1]==2 then
                table.insert(rewardList, rewardList2[i])
            else
                table.insert(specialList, rewardList2[i])
            end
            if reward[1]==4 then
                table.insert(addedRewd,reward)
            end
        end
        GameLogic.addRewards(rewardList2)
        GameLogic.statCrystalRewards("pve战斗结束奖励",rewardList2)

        local bgets = {}
        -- 先把金币的显示注释掉，用的时候在拿出来
        -- if data.gold then
        --     ucontext:changeResWithMax(const.ResGold, data.gold)
        --     table.insert(bgets, {const.ItemRes, const.ResGold, data.gold})
        -- else
        --     table.insert(bgets, {const.ItemRes, const.ResGold, 0})
        -- end
        if self.star==3 and bparams.star<3 then
            if bparams.slist then
                for _, item in ipairs(bparams.slist) do
                    table.insert(bgets, item)
                end
            elseif bparams.firstRwds then
                local items = bparams.firstRwds
                for i=1,#items do
                    table.insert(bgets, {items[i][1],items[i][2],items[i][3]})
                end
            end
        end
        self.rewardList = rewardList
        if self.rewardList and #(self.rewardList)==0 then
            self.rewardList = nil
        end
        self.specialList = specialList
        if not self.deleted then
            if not GameLogic.useTalentMatch then
                -- 2018.01.26 达人赛pve不再配额外奖励了
                self.labaddedRewds:setString(Localize("otherGetRewds"))
                for i=1,#addedRewd do
                    GameUI.addItemIcon(self.rewdTableView,addedRewd[i][2],addedRewd[i][3],1,216*i+10,109,true,false,{itemNum=addedRewd[i][4] or 1})
                end
            end
            local buffInfo = ucontext.activeData:getBuffInfo(const.ActTypeBuffPVE)
            self.labelChanceLeft:setString(Localizef("labelChanceLeft",{max=pve:getMaxChance()+buffInfo[4], num=pve:getBattleChance()+buffInfo[4]-buffInfo[5]}))

            local bg = self.nodeRewardBottom
            bg:removeAllChildren(true)
            local temp
            local ox = 0
            for _, item in ipairs(bgets) do
                if item[3]>0 or item[1]~=const.ItemOther then
                    temp = ui.label(N2S(item[3]), General.font1, 55)
                    display.adapt(temp, ox, 0, GConst.Anchor.Left)
                    bg:addChild(temp)
                    ox = ox+temp:getContentSize().width*temp:getScaleX()
                end
                if item[1]==const.ItemOther then
                    if item[2]==1 then
                        temp = ui.sprite("images/pveIconX.png")
                    elseif item[2]==2 then
                        temp = ui.sprite("images/pveIconT.png")
                    end
                    temp:setScale(0.6)
                    display.adapt(temp, ox+40, 0, GConst.Anchor.Center)
                else
                    GameUI.addItemIcon(bg, item[1], item[2], 0.4, ox+40, 0)
                end
                ox = ox+180
            end
            if ox>0 then
                ox = ox-100
            end
            bg:setSize(ox, 0)
        end

        if ucontext.guide:getStep().type == "pve" and self.star>0 then
            ucontext.guide:addStep()
        end
    else
        display.pushNotice("服务器请求错误，请退出游戏重试！")
    end
end

function BattleResultDialog:onPvzCallback(isSuc, data)
    if self.lock then
        self.lock = nil
    end
    if isSuc then
        local _tcontext = GameLogic.getCurrentContext()
        local type = _tcontext.pvzData.type
        local params = {type = type}
        local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
        self.shareParams = {stype = "pvz"}
        self.lock = nil
        local score = math.floor(data.bscore or 0)
        local nrank = data.nrank
        local brank = data.brank
        self.lb_score:setString("+"..score)
        if nrank then
            nrank = nrank + 1
            self.lb_rank:setString(nrank)
            brank = brank or 0
            brank = brank + 1
            if nrank - brank > 0 then
                self.img_rankUp:setVisible(true)
                self.img_rankUp.view:setScale(1.5)
                self.lb_rankUp:setVisible(true)
                self.lb_rankUp:setString(nrank - brank)
            else
                self.img_rankUp:setVisible(false)
                self.lb_rankUp:setVisible(false)
            end
        else
            self.lb_rank:setString(Localize("labelNotRank"))
        end
        if type == 0 then
            params.score = data.nowsc
            params.rank = data.nrank
            self.img_stage:setVisible(true)
            self.img_cup:setVisible(false)
        elseif type == 1 then
            params.score = data.score
            self.lb_rankDes:setVisible(false)
            self.lb_rank:setVisible(false)
            self.img_rankUp:setVisible(false)
            self.lb_rankUp:setVisible(false)
            self.lb_scoreDes:setPosition(900,650)
            self.lb_score:setPosition(960, 650)
            self.img_stage:setVisible(false)
            self.img_cup:setVisible(true)
        end
        KnockMatchData:resetInfoAfterBattle(params)

        --打开获取信息开关
        KnockMatchData:updateNeedRefreshData(1, true)
        GameEvent.sendEvent(GameEvent.showKnockTip)
    end
end

function BattleResultDialog:onPvcCallback(suc, data)
    if suc then
        self.shareParams = {stype="pvc", url="http://coz2.moyuplay.com/share1.html"}
        self.lock = nil
        local ucontext = self.context

        if self.isWin then
            ucontext.arena:refreshRank(data.nrank)
            ucontext.arena:refreshHonor(data.avalue,data.atime)
            --ucontext.arena:refreshEnemys(data.palyers)
        end

        local activeData = GameLogic.getUserContext().activeData
        if data.actId then
            activeData:updateActRecord(data.actId, const.ActTypeBuffPVC, data.ctime, 1)
        end
        activeData:finishAct(11)
        if not self.deleted then
            local buffInfo = activeData:getBuffInfo(const.ActTypeBuffPVC)
            self.labelChanceLeft:setString(Localizef("labelChanceLeft",{max=ucontext.arena:getMaxChance() + buffInfo[4],
                num=ucontext.arena:getCurrentChance() + buffInfo[4] - buffInfo[5]}))
        end
    else
        display.pushNotice("服务器请求错误，请退出游戏重试！")
    end
end

function BattleResultDialog:onPvhCallback(suc, data)
    if suc then
        self.shareParams = {stype="pvh", url="http://coz2.moyuplay.com/share1.html"}
        self.lock = nil
    else
        display.pushNotice("服务器请求错误，请退出游戏重试！")
    end
end

function BattleResultDialog:onPvjCallback(suc, data)
    if suc then
        --活动
        self.shareParams = {stype="pvj", url="http://coz2.moyuplay.com/share1.html"}
        local activeData = GameLogic.getUserContext().activeData
        activeData:finishAct(2)
        self.lock = nil
        local ucontext = self.context
        local bdata = self.battleData
        local scene = bdata.scene
        local bparams = scene.battleParams
        if type(data)=="table" then
            GameLogic.addRewards(data.agl)
            GameLogic.statCrystalRewards("pvj战斗结束奖励",data.agl)
            self.rewardList = data.agl
            if self.rewardList and #(self.rewardList)==0 then
                self.rewardList = nil
            end
            GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVJ,1)
            --活动:使用特定英雄赢得一场特定类型战斗
            for _, hero in ipairs(self.heros) do
                GameLogic.getUserContext().activeData:finishActCondition(hero.hid * 10000 + const.ActTypePVJ, 1)
            end
        end
    else
        display.pushNotice("服务器请求错误，请退出游戏重试！")
    end
end

function BattleResultDialog:onDRPvjCallback(suc, data)
    if suc then
        --活动
        self.shareParams = {stype="pvj", url="http://coz2.moyuplay.com/share1.html"}
        self.lock = nil
        local ucontext = self.context
        local bdata = self.battleData
        local scene = bdata.scene
        local bparams = scene.battleParams
        if type(data)=="table" then
            GameLogic.addRewards(data.agl)
            GameLogic.statCrystalRewards("达人赛pvj战斗结束奖励",data.agl)
            self.rewardList = data.agl
            if self.rewardList and #(self.rewardList)==0 then
                self.rewardList = nil
            end
        end
    else
        display.pushNotice("服务器请求错误，请退出游戏重试！")
    end
end

function BattleResultDialog:enterAnimate()
    self.nodeAnimateNode.view:setScale(0.6)
    self.nodeAnimateNode.view:runAction(ui.action.scaleTo(0.25,1,1))
    local scene = self.battleData.scene
    if scene.battleType == const.BattleTypeUPve or scene.battleType == const.BattleTypePvb or scene.battleParams.tryHids then

    else
        if self.isWin then
            self:showVictory()
        else
            self:showDefeat()
        end
    end
    return 0.25
end

function BattleResultDialog:exitAnimate()
    return 0
end

function BattleResultDialog:showVictory()

    local bg=ui.node({0,0},{255,255,255})
    display.adapt(bg, 0, 0, GConst.Anchor.Center)
    self.nodeVictoryBack:addChild(bg, 2)
    bg:setScaleX(-0.1)
    bg:setScaleY(0.5)
    bg:setOpacity(0)
    bg:runAction(ui.action.scaleTo(0.5,1,1))
    bg:runAction(ui.action.fadeIn(0.5))

    local temp
    temp = ui.sprite("images/victoryLine.png")
    temp:setPosition(0, 0)
    temp:setAnchorPoint(0.5,0.53)
    self.nodeVictoryBack:addChild(temp)
    ui.setBlend(temp, 772, 1)
    temp:setOpacity(0)
    temp:setScale(10)
    temp:runAction(ui.action.fadeIn(0.5))
    temp:runAction(ui.action.arepeat(ui.action.rotateBy(0.5,90)))

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

    self:addPercentAndStar(bg)

    local chibang1 = ui.sprite("images/chibang1.png",{282, 262})
    chibang1:setPosition(-117,36)
    chibang1:setAnchorPoint(1,0.3)
    self.nodeVictoryBack:addChild(chibang1,1)
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
    self.nodeVictoryBack:addChild(chibang2,1)
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
            self.nodeVictoryBack:addChild(p,3)
        end
    end
    bg:runAction(ui.action.sequence({{"delay",20/60},{"call",showPar}}))
    music.play("sounds/battleWin.mp3")
end

function BattleResultDialog:showDefeat()
    local temp

    local bg=ui.node({0,0},{255,255,255})
    display.adapt(bg, 0, 0, GConst.Anchor.Center)
    self.nodeVictoryBack:addChild(bg,2)
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

    self:addPercentAndStar(bg)

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
          self.nodeVictoryBack:addChild(p,3)
        end
        for i,pos in ipairs(parPos2) do
          local p = ui.particle("particles/battleResultEffect1.json")
          p:setPosition(-154,110)
          p:setScale(pos[1])
          p:setRotation(pos[2])
          p:setPositionType(cc.POSITION_TYPE_GROUPED)
          p:setAutoRemoveOnFinish(true)
          self.nodeVictoryBack:addChild(p,3)
        end
    end

    local function delayD(  )
        temp = ui.sprite("images/DEFEAT.png",{423*1.16, 152*1.16})
        display.adapt(temp, 12, 195+100, GConst.Anchor.Center)
        self.nodeVictoryBack:addChild(temp,2)
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
    self.nodeVictoryBack:addChild(p)
    ui.setBlend(p, 770, 1)
    music.play("sounds/battleLose.wav")
end

function BattleResultDialog:addPercentAndStar(bg)
    local temp
    if self.percent then
        temp = ui.label(Localize("labelBattlePercent"), General.font1, 46, {color={255,255,255}})
        display.adapt(temp, 0, 100, GConst.Anchor.Top)
        bg:addChild(temp)

        local pv = self.percent .. "%"
        temp = ui.label(pv, General.font1, 73, {color={140,203,90}})
        display.adapt(temp, 0, 4, GConst.Anchor.Center)
        bg:addChild(temp)
    end
    --战果星星
    local xinPos={{-97,-91},{0,-98},{93,-91}}
    local starNum = self.star
    for i,pos in ipairs(xinPos) do
        if i<= starNum then
            temp = ui.sprite("images/battleStar1.png",{67, 67})
            display.adapt(temp,pos[1],pos[2],GConst.Anchor.Center)
            bg:addChild(temp,2)
        end
    end
end

function BattleResultDialog:onTouchEnd()
    if self.lock then
        return
    end
    local temp, temp2
    if self.rewardList then
        if #self.rewardList>0 then
            music.play("sounds/openBox.mp3")
        end
        for i, reward in ipairs(self.rewardList) do
            self.boxes[i].box:removeFromParent(true)
            if self.boxes[i].rateLabel then
                self.boxes[i].rateLabel:removeFromParent(true)
            end
            temp = ui.sprite("images/battleBox2.png")
            display.adapt(temp, 0, 0, GConst.Anchor.Center)
            self.boxes[i].back:addChild(temp)
            temp:runAction(ui.action.sequence({{"delay",0.8},"remove"}))
            UIeffectsManage:showEffect_BaoXiangOpen(self.boxes[i].back,0,0)
            --TODO 打开动画？
            temp = ui.sprite("images/dialogInfoLight.png",{312, 298})
            temp:setVisible(false)
            display.adapt(temp, 0, 0, GConst.Anchor.Center)
            self.boxes[i].back:addChild(temp)
            temp:runAction(ui.action.sequence({{"delay",0.8},"show"}))

            temp = ui.node(nil, true)
            temp:setVisible(false)
            self.boxes[i].back:addChild(temp)
            GameUI.addItemIcon(temp, reward[1], reward[2], 1, 0, 0)
            temp:runAction(ui.action.sequence({{"delay",0.8},"show"}))

            temp2 = ui.label("", General.font1, 40, {fontW = 300, fontH = 70})
            temp2:setVisible(false)
            display.adapt(temp2, 0, -129, GConst.Anchor.Center)
            self.boxes[i].back:addChild(temp2)
            GameUI.setItemName(temp2, reward[1], reward[2], reward[3])
            temp2:runAction(ui.action.sequence({{"delay",0.8},"show"}))
        end
        self.rewardList = nil
        self.btnBattleWord:setString(Localize("btnBackBase"))
        return
    end
    local loading = GMethod.loadScript("game.Controller.ChangeController")
    loading:startExit(1,self.noOpen)
end

function BattleResultDialog:onEnter()
    local data = self.battleData
    if self.nodeRewardBox then
        self.nodeRewardBox:removeAllChildren(true)
        self.boxes = {}
        local temp
        local maxBoxNum = 3
        local getBoxNum = self.star
        local offx = -374*(maxBoxNum-1)/2
        for i=1,maxBoxNum do
            temp = ui.node(nil, true)
            display.adapt(temp, offx, 0, GConst.Anchor.Center)
            self.nodeRewardBox:addChild(temp)
            self.boxes[i] = {back=temp}
            temp = ui.sprite("images/battleBox1.png",{238, 210})
            if i>getBoxNum then
                temp:setSValue(-100)
            end
            display.adapt(temp, 0, 0, GConst.Anchor.Center)
            self.boxes[i].back:addChild(temp)
            offx = offx+374
            self.boxes[i].box = temp

            if i<=getBoxNum and self.boxRate and self.boxRate > 1 then
                temp = ui.label("X" .. self.boxRate, General.font1, 55, {color={120, 249, 18}})
                display.adapt(temp, 75, -85, GConst.Anchor.RightBottom)
                self.boxes[i].back:addChild(temp)
                self.boxes[i].rateLabel = temp
            end
        end
    elseif self.aresult then
        local arena = self.context.arena
        local aresult = self.aresult

        local liftNum = aresult.changeRank
        self.labelRank:setString(N2S(aresult.rank))
        self.labelStageScore1:setString(N2S(liftNum))
        if liftNum>0 then--上升，已默认

        elseif liftNum==0 then--持平
            ui.setFrame(self.imaRanking.view, "images/rankFlat.png")
            self.labelStageScore1:setVisible(false)
        elseif liftNum<0 then --下降
            ui.setFrame(self.imaRanking.view, "images/rankDecline.png")
            self.labelStageScore1:setColor(cc.c3b(249,64,64))
        end
        if aresult.canGetHonor then
            self.labRevenge:setString(Localizef("labRevenge",{a=aresult.canGetHonor}))
        else
            self.labRevenge:setVisible(false)
        end
    elseif self.hresult then
        if self.hresult.magic>0 then
            self.magiceGet:setVisible(true)
            self.magicIcon:setVisible(true)
            self.labelMagicNum:setString(N2S(self.hresult.magic))
        else
            self.magiceGet:setVisible(false)
            self.magicIcon:setVisible(false)
        end
        if self.hresult.hp>0 then self.labelRecoverNum:setString(Localizef("labelRecoverHp",{percent=self.hresult.hp})) end
    end
    self.nodeHeroTable:removeAllChildren(true)
    --2018.01.26 达人赛pve不再配额外奖励了, 故显示英雄阵容
    if self.battleData.scene.battleType~=const.BattleTypePve or GameLogic.useTalentMatch then
        local infos = {}
        for i=1, 10 do
            infos[i] = {}
        end
        for i, hero in ipairs(self.heros) do
            infos[i] = hero
        end
        local size = self.nodeHeroTable.size
        local ts = self.nodeHeroTable:getSetting("tableSetting")
        local tableView = ui.createTableView(size, ts.isX, {size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, infos=infos, cellUpdate=Handler(self.updateHeroCell, self)})
        display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
        self.nodeHeroTable:addChild(tableView.view)
    end
    if self.displayBossItems then
        self.nodeBossTable:loadTableView(self.displayBossItems, Handler(self.updateBossCell, self))
    end
end
function BattleResultDialog:updateBossCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    if not info.viewLayout then
        info.viewLayout = self:addLayout("bossViews", cell:getDrawNode())
        info.cell = cell
        info.viewLayout:loadViewsTo(info)
        cell:setEnable(false)
    end
    if info.now <= 0 then
        GameUI.addDeathHead(bg,136,173,0,2,2)
    else
        if info.bid < 1000 then
            GameUI.addBuildHead(bg, info.bid, 136, 173, 68, 86, 1, info.level)
        else
            GameUI.addHeroHead2(bg, info.bid, 136, 173, 0, 2, 2)
        end
    end
    local HpProcess=info.imaBossHp
    HpProcess.view:setHValue(-86)
    local hp = info.now / info.max
    HpProcess:setProcess(true, hp)
    info.labelBossHp:setString(math.floor(hp*10000)/100 .. "%")
end

function BattleResultDialog:updateHeroCell(cell, tableView, info)
    local bg,temp
    bg = cell:getDrawNode()
    cell:setEnable(false)

    if info.hid then
        temp = ui.scale9("images/bgCellBack2.9.png", 15, {147, 201})
        ui.setColor(temp, GConst.Color.Black)
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        local head = GameUI.addHeroHead(bg,info.hid,{size={145,195},x=1,y=2,lv=info.alevel})
        if info.dead then
            head:setOpacity(0.5*255)
            temp = ui.sprite("images/deathIcon.png",{96, 74})
            display.adapt(temp, 1, 128, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
        end
        temp=ui.colorNode({147, 42},{0,0,0,127})
        display.adapt(temp, 1,4, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.label(Localizef("labelLevelFormat", {level=info.level}), General.font1, 30, {color={255,255,255}})
        display.adapt(temp, 15, 24, GConst.Anchor.Left)
        bg:addChild(temp)
    else
        temp = ui.sprite("images/dialogCellBackGrayS.png",{151, 208})
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
    end
end

