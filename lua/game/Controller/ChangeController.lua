--[[
加载场景过度界面
--]]

local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local Loading = {}
local changeConfig = GMethod.loadConfig("configs/changes.json")

function Loading:startChange(ctype)
    self.loadingView = GMethod.loadScript("game.View.Changing")
    local btype
    --self.loadingView:setPercent(0)
    if type(ctype)=="table" then
        self.params = ctype
        ctype = changeConfig.start or 1
        if self.params.type and changeConfig["start" .. self.params.type] then
            btype=self.params.type
            ctype = changeConfig["start" .. self.params.type]
        end
        self.isPrepare = self.params.isPrepare
    end
    display.closeDialog(-1)
    self.loadingView:show(ctype,btype,false,self.params and self.params.isReplay)
    if GameLogic.getUserContext().guide:getStep().type == "finish" then
        self.loadingView:setExitCallback(ButtonHandler(self.onExit, self))
    else
        self.loadingView:setExitCallback(nil)
    end
    if self.params.type==const.BattleTypePvc then
        self.loadingView:setExitCallback(nil)
    end
    self.isExit = false
    self:startLoading()
    display.removeGuide()
end

function Loading:onExit()
    self.loadingView:setExitCallback(nil)
    self.isExit = true
    if self.loadingEntry then
        GMethod.unschedule(self.loadingEntry)
        self.loadingEntry = nil
    end
    self.params = nil
    self:startLoading()
    self.asynctotal = 0
end

function Loading:startExit(ctype,noOpen)
    self.loadingView = GMethod.loadScript("game.View.Changing")
    --self.loadingView:setPercent(0)
    local scene = GMethod.loadScript("game.View.Scene")
    local btype = scene.battleType or scene.visitBattleType
    display.closeDialog(-1)

    local cctype = changeConfig.exit or 2
    if btype and changeConfig["exit" .. btype] then
        cctype = changeConfig["exit" .. btype]
    end
    self.loadingView:show(cctype,btype,true,self.params and self.params.isReplay)
    self.loadingView:setExitCallback(nil)
    self.isExit = true

    --进入前面的界面
    if GameLogic.getUserContext().guide:getStep().type ~= "finish" then
        noOpen = true
    end
    if not noOpen then
        if scene.battleParams and scene.battleParams.tryHids then
            local ainfo = GameLogic.getUserContext().talentMatch:getMatchInfo(scene.battleParams.aid)
            if ainfo.inMatch then
                display.sendIntent({class="game.Dialog.TalentMatchHelpDialog", params={ainfo=ainfo}})
            end
        elseif btype == const.BattleTypePvp and not scene.battleParams.repid then
            display.showDialog(PlayInterfaceDialog.new({source = scene.battleParams.source}))
        elseif btype == const.BattleTypePve then
            if scene.battleParams.stage == const.HeroInfoNewTry then
                if scene.battleParams.from == "FirstCharge" then
                    display.showDialog(FirstChargePackageDialog.new())
                elseif scene.battleParams.from == "tmGift" then
                    display.sendIntent({class="game.Dialog.TalentMatchGiftDialog", params=scene.battleParams.initParams})
                elseif scene.battleParams.from == "ActMulti" then
                    display.sendIntent({class="game.Dialog.ActivityMultiDialog", params=scene.battleParams.initParams})
                else
                    local _hero = GameLogic.getUserContext().heroData:makeHero(self.params.bparams.id)
                    display.showDialog(HeroInfoNewDialog.new({hero = _hero}))
                end
            else
                display.showDialog(PlayInterfaceDialog.new({index=scene.battleParams}))
                local data = GameLogic.getUserContext().pve
                if scene.battleParams.from == "PveGuide" and data.stars[6] and data.stars[6]>0 then
                    local ReceiveDoraemon = GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.ReceiveDoraemon")
                    display.showDialog(ReceiveDoraemon.new())
                end
            end
        elseif btype == const.BattleTypePvc then
            display.showDialog(ArenaDialog.new())
        elseif btype == const.BattleTypePvh then
            if scene.battleParams.nightmare then
                display.sendIntent{class="game.Dialog.NightmareDialog", params={nightmare=true}}
            else
                display.showDialog(PvhMapDialog.new{nightmare=scene.battleParams.nightmare})
            end
        elseif btype == const.BattleTypePvj then
            if scene.battleParams.DRPvj then
                local ainfo = GameLogic.getUserContext().talentMatch:getMatchInfo(const.TalentMatchPvj)
                display.sendIntent({class="game.Dialog.TalentMatchPlayDialog", params={ainfo=ainfo}})
            else
                zombieIncomingDialog.new(nil,nil,scene.battleParams.index)
            end
        elseif btype == const.BattleTypeUPve then
            UnionMapDialog.new()
        elseif btype == const.BattleTypeUPvp then
            GameLogic.unionBattle()
        elseif btype == const.BattleTypePvt then
            HeroTrialDialog.new()
        elseif btype == const.BattleTypePvz then
            local type = scene.battleParams.foeData.pvzData.type
            local selectIdx = scene.battleParams.foeData.pvzData.selectIdx
            if type == 0 then --小组赛
                local KnockDivideDialog = GMethod.loadScript("game.Dialog.KnockDivideDialog")
                display.showDialog(KnockDivideDialog.new({enemyIdx = selectIdx}))
            elseif type == 1 then --淘汰赛打人
                local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
                local oinfo = KnockMatchData:getOinfo()
                local tid = oinfo.oEnemy.uid
                local KnockOutMajorDialog = GMethod.loadScript("game.Dialog.KnockOutMajorDialog")
                display.showDialog(KnockOutMajorDialog.new({tid = tid}))
            elseif type == 2 then  --淘汰赛试玩
                local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
                local KnockOutSecondDialog = GMethod.loadScript("game.Dialog.KnockOutSecondDialog")
                display.showDialog(KnockOutSecondDialog.new({groupId = KnockMatchData.selectGroupId}))
            end
        elseif btype == const.BattleTypePvb then
            local ainfo = GameLogic.getUserContext().talentMatch:getMatchInfo(scene.battleParams.aid)
            display.sendIntent({class="game.Dialog.TalentMatchPlayDialog", params={ainfo=ainfo}})
        end
    end
    self:startLoading()
    display.removeGuide()
end

function Loading:transEquipData(eq)
    return GameLogic.transEquipData(eq)
end

function Loading:getReplay()
    if DEBUG.DEBUG_REPLAY2 then
        self.params.rid = 1
    end
    self.scene.battleParams.replayId = self.params.rid
    self.scene.battleParams.isReplay = GameLogic.getReplay("replay_" .. self.params.rid ..".json")
    if self.scene.battleParams.isReplay then
        local rdata = json.decode(self.scene.battleParams.isReplay)
        local foeData = rdata.foeData
        local vtime = rdata.vtime
        if vtime then
            self.scene.startTime = vtime
        end
        self:getDataOver(self.loadingEntry, true, foeData)
    else
        self.locked = true
        GameNetwork.request("replayinfo",{replayid = self.params.rid},function(lentry, isSuc, data)
            if self.loadingEntry ~= lentry then
                return
            end
            self.locked = false
            if isSuc then
                local data = data.replay
                if not data or data == "" then
                    display.pushNotice(Localize("labNotPlayback"))
                    self:startExit(1,true)
                else
                    GameLogic.saveReplay("replay_" .. self.params.rid ..".json",data)
                    self.scene.battleParams.isReplay = data
                    local rdata = json.decode(data)
                    data = rdata.foeData
                    if rdata.vtime then
                        self.scene.startTime = rdata.vtime
                    end
                    self:getDataOver(lentry, isSuc, data)
                end
            else
                self.step = self.step-1
            end
        end, self.loadingEntry)
    end
end

function Loading:getDataOver(lentry, isSuc, data)
    if self.loadingEntry ~= lentry then
        return
    end
    self.locked = false
    if isSuc then
        if not data and self.params.bparams and self.params.bparams.tryHids then
            local ucontext = GameLogic.getUserContext()
            GameLogic.setCurrentContext(ucontext)
            local scene = self.scene
            scene.battleParams.winScore=0
            scene.battleParams.loseScore=0
            scene.battleParams.resPercents={0,0,0}
            scene.battleParams.max = ucontext:getResMax(const.ResGold)
            scene.battleParams.base = ucontext:getRes(const.ResGold)
            scene.battleParams.get = 0
            scene.battleParams.cget = 0
            return
        end
        local context = GameLogic.newContext(data.uid)
        local uinfo = data.uinfo
        if not uinfo then
            self.step = self.step-1
            return
        end
        self.scene.battleData.foeData = clone(data)
        data.info = {uinfo[1],0,0,0,0,uinfo[2],0,0,1,0,1,1,uinfo[4],uinfo[5]}
        data.properties = {}
        data.bexts = data.exts
        data.layouts = {}
        for i, build in ipairs(data.builds) do
            build[2], build[3] = build[3], build[2]
            data.layouts[i] = {build[1], build[4], build[5], 0, 0, 0, 0}
        end
        data.wlist = data.wlist or {}
        data.armors = data.armors or {}
        data.hbskills = data.hbskills or {}
        if data.heros then
            data.hlayouts = {}
            for i, hero in ipairs(data.heros) do
                local lstate = hero[13]
                local newHero = {hero[1],hero[2],hero[3],hero[4],hero[5],
                    hero[6],hero[7],hero[8],hero[9],hero[10],hero[11],
                    hero[12],0,0,hero[14]
                }
                data.heros[i] = newHero
                table.insert(data.hlayouts,{hero[1],10,lstate})
            end
        end
        data.equips = self:transEquipData(data.equips)
        context:loadContext(data)
        GameLogic.setCurrentContext(context)
        if self.params and self.params.type==const.BattleTypePvp then
            local ucontext = GameLogic.getUserContext()
            local pvp = data.pzpvp
            local scene = self.scene
            scene.battleParams = scene.battleParams or {}
            scene.battleParams.winScore=pvp[4]
            scene.battleParams.loseScore=pvp[5]
            scene.battleParams.resPercents={pvp[1],pvp[2],pvp[3]}
            scene.battleParams.max = ucontext:getResMax(const.ResGold)
            scene.battleParams.base = ucontext:getRes(const.ResGold)
            scene.battleParams.get = 0
            scene.battleParams.cget = 0
        end
    else
        self.step = self.step-1
    end
end

function Loading:getArenaDataOver2(lentry, isSuc, replayData)
    if self.loadingEntry ~= lentry then
        return
    end
    self.locked = false
    if isSuc then
        local scene = self.scene
        --是返回基地
        if self.isExit then
            return
        end
        scene.battleParams.isReplay = json.encode(replayData)
        if replayData.vtime then
            scene.startTime = replayData.vtime
        end
        scene.battleParams.myRank = replayData.battleParams.myRank or 0
        scene.battleParams.eRank = replayData.battleParams.eRank or 0

        local mcontext = GameLogic.newContext(1)
        local econtext = GameLogic.newContext(2)
        mcontext.enemy = econtext
        econtext.enemy = mcontext
        local edata = replayData.foeData
        local mdata = replayData.myData

        mcontext:loadContext(mdata)
        econtext:loadContext(edata)

        GameLogic.setCurrentContext(mcontext)
    else
        self.step = self.step-1
    end
end

function Loading:getArenaDataOver(lentry, isSuc, data)
    if self.loadingEntry ~= lentry then
        return
    end
    self.locked = false
    if isSuc then
        local ucontext = GameLogic.getUserContext()
        local scene = self.scene
        --是返回基地
        if self.isExit then
            return
        end
        scene.battleParams.isRev = self.params.isRev or 0
        scene.battleParams.batid = self.params.batid
        scene.battleParams.myRank = self.params.myRank or 0
        scene.battleParams.eRank = scene.battleParams.rank or 0

        local mcontext = GameLogic.newContext(ucontext.uid)
        local econtext = GameLogic.newContext(scene.battleParams.uid)
        mcontext.enemy = econtext
        econtext.enemy = mcontext
        local mdata = {builds={}, layouts={}, bexts={}, wlist={}, armors={}}
        local edata = {builds={}, layouts={}, bexts={}, wlist={}, armors={}}
        mdata.info = {ucontext:getInfoItem(const.InfoName),0,0,0,0,ucontext:getInfoItem(const.InfoLevel),0,0,1,0,0,0,ucontext:getInfoItem(const.InfoHead)}
        mdata.properties={{const.ProUseLayout,ucontext:getProperty(const.ProUseLayout)}}
        edata.info = {data.uinfo[1],0,0,0,0,data.uinfo[2],0,0,1,0,1,1,data.uinfo[4],data.uinfo[5]}
        --从当前数值初始化己方初始布阵；如果出战台数量发生变化则重置位置
        local uhdata = ucontext.heroData
        local outNum = #(uhdata.bases)
        local initPos = uhdata:getHVHLayouts(const.LayoutPvc, outNum)
        --英雄台初始化
        for i=1, outNum do
            mdata.builds[i] = {i, const.HeroBase, uhdata.bases[i].level}
            mdata.layouts[i] = {i, initPos[i].x, initPos[i].y, 0, 0, 0, 0}
        end
        --主基地初始化
        local mbidx = 100
        table.insert(mdata.builds, {mbidx, const.Town, ucontext.buildData:getMaxLevel(const.Town)})
        table.insert(mdata.layouts, {mbidx, 19, 1, 0, 0, 0, 0})
        table.insert(mdata.bexts,{mbidx, 0, 0})
        mcontext:loadContext(mdata)
        mcontext.heroData = ucontext.heroData
        mcontext.weaponData = ucontext.weaponData

        edata.heros = {}
        edata.hlayouts = {}
        edata.hbskills = {}
        edata.equips = self:transEquipData(data.equips)
        local bidx
        for _,v in ipairs(data.heros) do
            local hero = {v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],v[9],v[10],v[11],v[12],0,0,v[14]}
            local hlayout = {v[1],const.LayoutPvc,v[13]}
            table.insert(edata.heros,hero)
            table.insert(edata.hlayouts,hlayout)
            if math.floor(v[13]/10000)%10==1 then
                bidx = math.floor(v[13]/100000)
                if bidx<=5 then
                    local xy = v[13]%10000
                    table.insert(edata.builds,{bidx, const.HeroBase, 1})
                    table.insert(edata.layouts,{bidx, 36-math.floor(xy/100),36-xy%100,0,0,0,0})
                end
            end
        end
        table.insert(edata.builds, {mbidx, const.Town, data.uinfo[3]})
        table.insert(edata.layouts, {mbidx, 19, 37, 0, 0, 0, 0})
        table.insert(edata.bexts,{mbidx, 0, 0})

        scene.battleParams.foeData = edata
        scene.battleParams.myData = mdata

        econtext:loadContext(edata)
        GameLogic.setCurrentContext(mcontext)
    else
        self.step = self.step-1
    end
end

function Loading:loadArenaBattleData()
    --不需要对context做更改
    self.locked = false
end

function Loading:getPvhDataOver(lentry, suc, data)
    if self.loadingEntry ~= lentry then
        return
    end
    self.locked = false
    if suc then
        local lid=self.params.bparams.nightmare and const.LayoutnPvh or const.LayoutPvh
        local ucontext = GameLogic.getUserContext()
        local scene = self.scene

        local mcontext = GameLogic.newContext(ucontext.uid)
        local econtext = GameLogic.newContext(1)
        mcontext.enemy = econtext
        econtext.enemy = mcontext
        mcontext.nightmare=self.params.bparams.nightmare
        local mdata = {builds={}, layouts={}, bexts={}, wlist={}, armors={}}
        local edata = {builds={}, layouts={}, bexts={}, wlist={}, armors={}}
        mdata.info = {"",0,0,0,0,1,0,0,1,0}
        if self.params.bparams.nightmare then
            edata.info = {"",0,0,0,0,self.params.stage,0,0,1,0,1,1,200101,nil}
        else
            edata.info = {data.hwtxt.uinfo[1],0,data.ms,0,0,data.hwtxt.uinfo[2],0,0,1,0,1,1,data.hwtxt.uinfo[4],data.hwtxt.uinfo[5]}
        end

        --从当前数值初始化己方初始布阵；如果出战台数量发生变化则重置位置
        local uhdata = ucontext.heroData
        if self.params.bparams.nightmare then
            mcontext.forceLayouts = uhdata:getnPvhForceLayouts()
        else
            mcontext.forceLayouts = uhdata:getPvhForceLayouts()
        end
        local outNum = #(uhdata.bases)
        if self.params.bparams.tryHids then
            outNum = 5
        end
        local initPos = uhdata:getHVHLayouts(lid, outNum)
        for i=1, outNum do
            mdata.builds[i] = {i, const.HeroBase, uhdata.bases[i] and uhdata.bases[i].level or 1}
            mdata.layouts[i] = {i, initPos[i].x, initPos[i].y, 0, 0, 0, 0}
        end
        local mbidx = 100
        table.insert(mdata.builds, {mbidx, const.Town, ucontext.buildData:getMaxLevel(const.Town)})
        table.insert(mdata.layouts, {mbidx, 19, 1, 0, 0, 0, 0})
        table.insert(mdata.bexts,{mbidx, 0, 0})
        mcontext:loadContext(mdata)
        mcontext.heroData = ucontext.heroData
        mcontext.weaponData = ucontext.weaponData

        edata.heros = {}
        edata.hlayouts = {}
        edata.hbskills = {}
        edata.armors={}

        local bidx
        local hpmap = {}
        for _, v in ipairs(data.hhp) do
            hpmap[v[1]] = v[2]
        end
        local heroData,townLv,townArmor
        if self.params.bparams.nightmare then
            heroData,townLv,townArmor=self:getnPvhEnemyData()
            edata.equips={}
        else
            heroData=data.hwtxt.heros
            edata.equips = self:transEquipData(data.hwtxt.equips)
        end
        for _,v in ipairs(heroData) do
            --h.idx,h.hid,h.level,h.exp,h.starup,h.awakeup,h.mskilllevel,h.bskill1,h.bskill2,h.bskill3,h.sdlevel,h.sdsklv,l.lat,h.sdsklv2
            local hero = {v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],v[9],v[10],v[11],v[12],0,0,v[14]}
            table.insert(edata.heros,hero)
            bidx = math.floor(v[13]/100000000)
            local xy = math.floor((v[13]%100000)/10)
            if v[13]%10==1 then
                table.insert(edata.builds,{bidx, const.HeroBase, 1})
                table.insert(edata.layouts,{bidx, 36-math.floor(xy/100),36-xy%100,0,0,0,0})
            end
            local hlayout = {v[1],lid,v[13]%10+xy*10+(hpmap[v[1]] or 0)*100000+bidx*100000000}
            table.insert(edata.hlayouts,hlayout)
        end
        local temp
        if self.params.bparams.nightmare then
            temp=townLv
        else
            temp=data.hwtxt.uinfo[3]
        end
        table.insert(edata.builds, {mbidx, const.Town, temp or ucontext.buildData:getMaxLevel(const.Town)})
        table.insert(edata.armors, {mbidx,townArmor})
        table.insert(edata.layouts, {mbidx, 19, 37, 0, 0, 0, 0})
        table.insert(edata.bexts,{mbidx, 0, 0})
        econtext:loadContext(edata)
        GameLogic.setCurrentContext(mcontext)
    else
    end
end
--==============================--
--desc:计算等级最高5个英雄的平均等级 获取噩梦远征对手数据
--time:2018-01-25 11:16:39
--@return
--==============================--
function Loading:getnPvhEnemyData()
    local heroData={}
    local stageInfo=SData.getData("npvhStage",self.scene.battleParams.stage)
    local heroInfo=SData.getData("npvhHeroInfo")
    local key=0
    local level=math.floor(self.params.bparams.avgLevel*stageInfo.mul)
    level=level<=200 and level or 200
    for k,v2 in ipairs(heroInfo) do
        if level>v2.lvMin and level<=v2.lvMax then
            key=k
            break
        end
    end
    self.scene.battleParams.mul=heroInfo[key].mul
    for _,v in ipairs(stageInfo.hero) do
        --1 idx,2 hid ,3 level ,4 exp ,5 star ,6 觉醒 ,7 h.mskilllevel ,8 h.bskill1,9 h.bskill2,
        --10 h.bskill3,11 h.sdlevel ,12 h.sdsklv
        local awake=SData.getData("hinfos",v[2]).awake==0 and 0 or heroInfo[key].awakeup
        local hero={v[1],v[2],level,0,heroInfo[key].starup,awake,
                    heroInfo[key].mskilllevel,0,0,0,heroInfo[key].sdlevel,0,v[3],0}
        table.insert(heroData,hero)
    end
    return heroData,heroInfo[key].townlv,heroInfo[key].armor
end
function Loading:preparePvt()
    self.locked = false

    local pvtdata = self.params.pvtdata
    local mdata = {builds={}, layouts={}, bexts={}, wlist={}, armors={}}
    local edata = {builds={}, layouts={}, bexts={}, wlist={}, armors={}}
    local ucontext = GameLogic.getUserContext()

    mdata.info = {123,0,0,0,0,1,0,0,1,0}
    edata.info = mdata.info

    --初始化自己一方的英雄以及英雄台
    local bases = ucontext.heroData.bases
    local blevels = {}
    for _, base in ipairs(bases) do
        table.insert(blevels, {base.level})
    end
    --从当前数值初始化己方初始布阵；如果出战台数量发生变化则重置位置
    local outNum = 3
    if outNum>#blevels then outNum = #blevels end
    local initPos = ucontext.heroData:getHVHLayouts(const.LayoutPvtAtk, outNum)
    GameLogic.mySort(blevels, 1, true)
    for i=1, 3 do
        if blevels[i] then
            mdata.builds[i] = {i, const.HeroBase, blevels[i][1]}
            mdata.layouts[i] = {i, initPos[i].x, initPos[i].y, 0, 0, 0, 0}
        end
    end
    --创建一个已方的镜像
    local mcontext = GameLogic.newContext(ucontext.uid)
    mcontext:loadContext(mdata)
    mcontext.heroData = ucontext.heroData

    local dplay = pvtdata.player["player"..self.params.idx]
    pvtdata.idx = self.params.idx

    -- dplay.hinfo = {
    --     {1,111610,4001,50,3,0,5,0,0,0,10,0,0},
    --     {2,212010,4002,50,3,0,5,0,0,0,10,0,0},
    --     {3,312410,4003,50,3,0,5,0,0,0,10,0,0},
    --     {4,412010,4004,50,3,0,5,0,0,0,10,0,0},
    --     {5,512410,4005,50,3,0,5,0,0,0,10,0,0},
    --     {6,612010,4006,50,3,0,5,0,0,0,10,0,0},
    --     {7,712410,4007,50,3,0,5,0,0,0,10,0,0},
    --     {8,812010,4008,50,3,0,5,0,0,0,10,0,0},
    --     {9,912410,4009,50,3,0,5,0,0,0,10,0,0},
    -- }

    edata.heros = {}
    edata.hlayouts = {}
    edata.hbskills = {}
    edata.equips = self:transEquipData(dplay.equips)
    local bidx = 0
    for i,v in ipairs(dplay.hinfo) do
        --   heros = [[idx, hid,等级,经验0,升星数,觉醒等级,主动技等级, 被动1, 2 ,3  士兵等级,士兵天赋等级,是否锁定0,恢复时间0, 士兵第二天赋等级]]
        local hero = {v[1],v[3],v[4],0,v[5],v[6],v[7],v[8],v[9],v[10],v[11],v[12],0,0,v[22]}
        --hlayouts = [[英雄idx, lid（比如试炼防御就是60），lvalue（布阵信息）]]
        local hlayout = {v[1],const.LayoutPvtDef,v[2]}
        table.insert(edata.heros,hero)
        table.insert(edata.hlayouts,hlayout)
        if math.floor(v[2]/10000)%10==1 then
            bidx = math.floor(v[2]/100000)
            if bidx<=3 then
                local xy = v[2]%10000
                table.insert(edata.builds,{bidx, const.HeroBase, 1})
                table.insert(edata.layouts,{bidx, 36-math.floor(xy/100),36-xy%100,0,0,0,0})
            end
        end
    end
    local econtext = GameLogic.newContext(dplay.uinfo[1])
    econtext:loadContext(edata)
    mcontext.pvtdata = pvtdata
    mcontext.dplay = dplay
    mcontext.enemy = econtext
    econtext.enemy = mcontext
    GameLogic.setCurrentContext(mcontext)
end

function Loading:beginPvtOver(lentry, isSuc, data)
    if self.loadingEntry ~= lentry then
        return
    end
    self.locked = false
    if isSuc then
        GameLogic.getCurrentContext().pvtdata.cnum = GameLogic.getCurrentContext().pvtdata.cnum+1
    else
        self.step = self.step-1
    end
end

function Loading:beginUnionPveOver(lentry, isSuc, data)
    if self.loadingEntry ~= lentry then
        return
    end
    self.locked = false
    if isSuc then
        local context = GameLogic.newContext(data.uid)
        local uinfo = data.uinfo
        data.info = {uinfo[1],0,0,0,0,uinfo[2],0,0,1,0}
        data.properties = {}
        data.bexts = data.exts
        data.layouts = {}
        for i, build in ipairs(data.builds) do
            build[2], build[3] = build[3], build[2]
            data.layouts[i] = {build[1], build[4], build[5], 0, 0, 0, 0}
        end
        data.wlist = {}
        data.armors = {}
        data.hbskills = {}
        data.equips = self:transEquipData(data.equips)

        local bossData = SData.getData("upveboss",self.params.idx)

        data.heros = {}
        for i,v in ipairs(bossData) do
            if v[1]>1000 then
                --   heros = [[idx, hid,等级,经验0,升星数,觉醒等级,主动技等级, 被动1, 2 ,3  士兵等级,士兵天赋等级,是否锁定0,恢复时间0，士兵第二天赋等级]]
                local hero = {i,v[1],v[2],0,0,0,v[3],0,0,0,1,1,0,0,0}
                table.insert(data.heros,hero)
            end
        end


        if data.heros then
            data.hlayouts = {}
            for i, hero in ipairs(data.heros) do
                local newHero = {hero[1],hero[2],hero[3],hero[4],hero[5],
                    hero[6],hero[7],hero[8],hero[9],hero[10],hero[11],
                    hero[12],0,0,hero[15]
                }
                data.heros[i] = newHero
                table.insert(data.hlayouts,{hero[1],10,i*10+1})
            end
        end
        context:loadContext(data)
        GameLogic.setCurrentContext(context)
    else
        self.step = self.step-1
    end
end

function Loading:initPvj()
    self.locked = false
    local context = GameLogic.getUserContext()
    GameLogic.setCurrentContext(context)

    local edata = {builds={}, layouts={}, bexts={}, wlist={}, armors={}, hlayouts={}, hbskills={} }
    edata.heros = {}

    local scene = self.scene
    scene.battleData.readyHeros = {}
    local passIdx = self.params.idx
    local passSet = SData.getData("pvjboss",passIdx)
    if scene.battleParams.DRPvj then
        passSet = SData.getData("pvjboss6",passIdx)
    end
    local ptArr = { {20,0,3}, {0,20,4}, {20,40,6}, {40,20,1}}

    if passIdx == 0 then
        passSet = {actSkill=1,atk1={1,1,1,1,1,1},atk3={1,1,1,1,1,1},awark=0,boss1={9002,9006,9002,9006,9002,9006},
            hp1={1,1,1,1,1,1},lv=1,passive=0,soldierLv=1,soldierSkill=0,star=0}
    end
    for i=1,5 do
        local set = passSet["boss" .. i]
        if not set then
            break
        end
        for j,v in ipairs(set) do
            --   heros = [[idx, hid,等级,经验0,升星数,觉醒等级,主动技等级, 被动1, 2 ,3  士兵等级,
            --   士兵天赋等级,是否锁定0,恢复时间0, 士兵第二天赋等级]]
            local hero = {i*10+j,v,passSet.lv,0,passSet.star,passSet.awark,passSet.actSkill,0,0,0,passSet.soldierLv,
                passSet.soldierSkill,0,0,0}
            table.insert(edata.heros,hero)
        end
    end
    local econtext = GameLogic.newContext(1)
    econtext:loadContext(edata)

    for i=1,5 do
        local set = passSet["boss" .. i]
        if not set then
            break
        end
        local initPos = ptArr[math.random(4)]
        for j,v in ipairs(set) do
            if not scene.battleData.readyHeros[i] then
                scene.battleData.readyHeros[i] = {}
            end
            local hero = econtext.heroData:getHero(i*10+j)
            scene.battleData.groups[2].ready = scene.battleData.groups[2].ready+1
            scene.battleData.readyHeros[i][j] = {hero = hero,sinfo=hero:getSoldierInfo(),sdata = hero:getSoldierData()}
            hero.initPos = initPos
        end
    end
end

function Loading:loadPvbData()
    self.locked = false
    local ucontext = GameLogic.getUserContext()
    local scene = self.scene

    scene.battleParams.aid = self.params.aid
    scene.battleParams.stage = self.params.stage
    scene.battleParams.lostHp = self.params.lostHp

    local ebossData = SData.getData("godBeastBoss", self.params.aid, self.params.stage)

    local econtext = GameLogic.newContext(1)
    local edata = {}
    edata.info =  {"",0,0,0,0,1,0,0,1,0}
    edata.properties = {}
    edata.builds = {}
    edata.bexts = {}
    edata.layouts = {}
    edata.wlist = {}
    edata.armors = {}
    edata.hbskills = {}
    edata.equips = {}
    edata.heros = {}
    edata.hlayouts = {}

    -- 魔幻地设置居中的神兽坐标
    edata.builds[1] = {1, const.HeroBase, 1}
    edata.layouts[1] = {1, 18, 19, 0, 0, 0, 0}
    edata.heros[1] = {1, ebossData.gbId, 1, 0, 0, 0, ebossData.actSkill, 0, 0, 0, 1, 0, 0, 0, 0}
    edata.hlayouts[1] = {1, const.LayoutUPve, 11}
    econtext:loadContext(edata)
    GameLogic.setCurrentContext(econtext)
    econtext.heroData:getHero(1).forceData = {idx=1, level=ebossData.lv, hp=ebossData.hp, atk=ebossData.atk, lostHp=self.params.lostHp}
end

function Loading:getUnVisitOver(lentry, isSuc, data)
    if self.loadingEntry ~= lentry then
        return
    end
    local context = GameLogic.getUserContext()
    GameLogic.setCurrentContext(context)

    if isSuc then
        if self.params.haveSatrtBattleData then
            self.scene.haveSatrtBattleData = self.params.haveSatrtBattleData
        end
        if self.params.inBattle then
            self.scene.visitBattleType = const.BattleTypeUPvp
        end
        local context = GameLogic.newContext(self.params.uid)
        data.id = context.uid
        context:loadContext(data)
        GameLogic.setCurrentContext(context)
        GameNetwork.request("getRankList",{uid = self.params.uid},function(lentry, isSuc, data)
            if self.loadingEntry ~= lentry then
                return
            end
            self.locked = false
            if isSuc then
                local set = {pvp=181,pvl=182,pvt=183,pvb=184,pvc=185}
                context.rankList = {}
                for k,v in pairs(data) do
                    local id = set[k]
                    context.rankList[id] = v
                end
            else
                self.step = self.step-1
            end
        end, self.loadingEntry)
    else
        self.step = self.step-1
    end
end

function Loading:getPvzReplay()
    self.scene.battleParams.replayId = self.params.rid
    self.scene.battleParams.isReplay = GameLogic.getReplay("replay_" .. self.params.rid ..".json")
    if self.scene.battleParams.isReplay then
        local rdata = json.decode(self.scene.battleParams.isReplay)
        local vtime = rdata.vtime
        if vtime then
            self.scene.startTime = vtime
        end
        local data = rdata.battleParams.foeData
        self:getPvzOver(data)
    else
        self.locked = true
        -- dump({self.params.rid, self.params.gidx, self.params.gk})
        GameNetwork.request("pvzReplay", {rid = self.params.rid, gidx = self.params.gidx, gk = self.params.gk}, function(isSuc,data)
            self.locked = false
            if isSuc and self.params and self.params.rid then
                if data.rep=="" then
                    display.pushNotice(Localize("labNotPlayback"))
                    self:startExit(1, true)
                else
                    local rep = data.rep
                    local replayData = json.decode(rep)
                    GameLogic.saveReplay("replay_"..self.params.rid..".json", rep)
                    self.scene.battleParams.isReplay = rep
                    if replayData.vtime then
                        self.scene.startTime = replayData.vtime
                    end
                    local _data = replayData.battleParams.foeData
                    self:getPvzOver(_data)
                end
            end
        end)
    end
end

function Loading:getPvzOver(data)
    self.locked = false
    --针对战斗而言：uinfo 是服务端传过来的防守方的信息, 再创建一个自己的信息作为攻击者
    local econtext
    local context = GameLogic.newContext(data.uid)
    if not self.params.isReplay then
        self.scene.battleParams.foeData = clone(data)
        local _context = GameLogic.getUserContext()
        local _uid = _context.uid
        local _name = _context:getInfoItem(const.InfoName)
        local _lv = _context:getInfoItem(const.InfoLevel)
        local _head = _context:getInfoItem(const.InfoHead)
        econtext = {name = _name, lv = _lv, head = _head, uid = _uid}
        context.enemyData = econtext
        self.scene.battleParams.foeData.enemyData = econtext
    else
        context.enemyData = data.enemyData
    end
    local uinfo = data.uinfo
    data.info = {uinfo[1],0,0,0,0,uinfo[6],0,0,1,0,0,0,uinfo[13]}
    data.properties = {}
    data.bexts = data.exts
    data.layouts = {}
    for i, build in ipairs(data.builds) do
        build[2], build[3] = build[3], build[2]
        data.layouts[i] = {build[1], build[4], build[5], 0, 0, 0, 0}
    end
    data.wlist = {}
    data.armors = {}
    data.hbskills = {}
    data.equips = self:transEquipData(data.equips)
    if data.heros then
        data.hlayouts = {}
        --    1     2     3      4       5       6           7           8           9         10        11      12       13       14       15       16
        --{h.idx,h.hid,h.level,h.exp,h.starup,h.awakeup,h.mskilllevel,h.bskill1,h.bskill2,h.bskill3,h.sdlevel,h.sdsklv,h.hflag,h.htime,l.lstate,h.sdsklv2}
        for i, hero in ipairs(data.heros) do
            local lstate = hero[15]
            local newHero = {hero[1],hero[2],hero[3],hero[4],hero[5],
                hero[6],hero[7],hero[8],hero[9],hero[10],hero[11],
                hero[12],0,0,hero[16]
            }
            data.heros[i] = newHero
            table.insert(data.hlayouts,{hero[1],10,lstate})
        end
    end
    context:loadContext(data)
    GameLogic.setCurrentContext(context)
end

function Loading:getPvlOver()
    self.locked = false
    local data
    if self.params.isReplay then
        data=self.params.data
        self.scene.battleReplayData = json.encode({headid=data.uinfo[13],lv=data.uinfo[6],name=data.uinfo[1],rid=self.params.rid,data=data,bparams=self.params.bparams})
    else
        data= self.params.data.binfo
        self.scene.battleData.foeData = clone(data)
    end

    local context = GameLogic.newContext(data.uid)
    local uinfo = data.uinfo
    data.info = {uinfo[1],0,0,0,0,uinfo[6],0,0,1,0,0,0,uinfo[13]}
    data.properties = {}
    data.bexts = data.exts
    data.layouts = {}
    for i, build in ipairs(data.builds) do
        build[2], build[3] = build[3], build[2]
        data.layouts[i] = {build[1], build[4], build[5], 0, 0, 0, 0}
    end
    data.wlist = {}
    data.armors = {}
    data.hbskills = {}
    data.equips = self:transEquipData(data.equips)
    if data.heros then
        data.hlayouts = {}
        for i, hero in ipairs(data.heros) do
            local lstate = hero[15]
            local newHero = {hero[1],hero[2],hero[3],hero[4],hero[5],
                hero[6],hero[7],hero[8],hero[9],hero[10],hero[11],
                hero[12],0,0,hero[16]
            }
            data.heros[i] = newHero
            table.insert(data.hlayouts,{hero[1],10,lstate})
        end
    end
    context:loadContext(data)
    GameLogic.setCurrentContext(context)
    local scene = GMethod.loadScript("game.View.Scene")

    if self.params.isReplay then
        scene.battleData.allHpPct = scene.battleParams.allHpPct
    else
        scene.battleData.allHpPct = self.params.data.hp
        scene.battleParams.allHpPct = self.params.data.hp

        local ucontext = GameLogic.getUserContext()
        scene.battleParams.us={ucontext:getInfoItem(const.InfoName),ucontext:getInfoItem(const.InfoLevel),ucontext:getInfoItem(const.InfoHead),ucontext.heroData:getAllCombatData()}
        scene.battleParams.ts={uinfo[1],uinfo[6],uinfo[13],data.combat}
    end
end

function Loading:loading(diff)
    self.delayTime=(self.delayTime or 0)+diff
    if self.delayTime<3 then
        return
    end
    if self.locked then
        if self.lockedItem then
            if self.lockedItem == "builds" then
                if self.scene.loadBuildsThread then
                    coroutine.resume(self.scene.loadBuildsThread, self.scene)
                else
                    self.lockedItem = nil
                    self.locked = nil
                end
            elseif self.lockedItem == "res" then
                if self.asynctotal <= self.asyncfinish then
                    self.lockedItem = nil
                    self.locked = nil
                end
            end
        end
        return
    end
    local step = self.step+1
    local stepItem = self.loadSteps[step]
    if stepItem then
        self.step = step
        if stepItem[1]=="init" then
            local scene = GMethod.loadScript("game.View.Scene")
            if scene.sceneType=="operation" then
                scene.startTime = GameLogic.getSTime()
            end
            local focusItem = scene.controller.focusItem
            if focusItem then
                focusItem:setFocus(false)
            end

            if self.params and self.params.type == const.BattleTypePvt and not self.isPrepare then
                scene:clearAll(true)
            else
                scene:clearAll()
            end
            if GEngine.rawConfig.platform == "ios" then
                ui.clearReuseFrame()
            end
            if self.isExit then
                scene.sceneType = "operation"
                scene.isBattle = false
                scene.battleType = nil
                scene.battleParams = nil
                scene.haveSatrtBattleData = nil
            else
                if self.isPrepare then
                    scene.sceneType = "prepare"
                    scene.isBattle = false
                    scene.battleType = self.params.type
                    scene.battleParams = self.params.bparams or {}
                elseif self.params.type>100 then --参观
                    scene.sceneType = "visit"
                    scene.isBattle = false
                    scene.battleType = nil
                    scene.battleParams = nil
                else
                    scene.sceneType = "battle"
                    scene.isBattle = true
                    scene.battleType = self.params.type
                    scene.battleParams = self.params.bparams or {}
                end
                scene.battleData = GameLogic.newBattleData(scene)
            end
            self.scene = scene
        elseif stepItem[1]=="sheet" then
            memory.loadSpriteSheet(stepItem[2], stepItem[3])
        elseif stepItem[1]=="image" then
            memory.loadTexture(stepItem[2])
        elseif stepItem[1]=="scene" then
            local scene = GMethod.loadScript("game.View.Scene")
            if stepItem[2]=="ground" then
                if self.params and self.params.type == const.BattleTypePvt and scene.sceneType == "battle" then
                    self.scene.mapView.setSpecialLimitGrids(nil)
                else
                    self.scene:reloadGround()
                end
                if self.scene.replay and self.inPvpLog then
                    self.scene.replay.defHs = {}
                    self.scene.replay.atkHs = {}
                end
            elseif stepItem[2]=="menu" then
                if self.params and self.params.type == const.BattleTypePvt and scene.sceneType == "battle" then

                else
                    self.scene:reloadMenu()
                end
            elseif stepItem[2]=="builds" then
                if GEngine.rawConfig.platform == "ios" then
                    ui.clearReuseFrame()
                end
                if self.params and self.params.type == const.BattleTypePvt  and scene.sceneType == "battle" then
                    self.scene:clearAll(true)
                    self.scene.menu.battle:startBattle()
                else
                    -- 开战前要加
                    if self.scene.battleType and (self.scene.battleType == const.BattleTypePvp or
                        self.scene.battleType == const.BattleTypePve or self.scene.battleType == const.BattleTypePvb or
                        self.scene.battleType >= const.BattleTypePvj and self.scene.battleType <= const.BattleTypePvz) then

                        local atkContext = GameLogic.getUserContext()
                        local defContext = GameLogic.getCurrentContext()
                        if self.scene.battleType == const.BattleTypePvj then
                            atkContext, defContext = defContext, atkContext
                        end
                        local defBuff = {}
                        for k, build in pairs(defContext.buildData:getSceneBuilds()) do
                            build:addDefBuff(defBuff)
                        end
                        self.scene.battleData.preDefBuffs = defBuff
                        -- 僵尸来袭无攻方BUFF
                        if not self.scene.battleData.preAtkBuffs and self.scene.battleType ~= const.BattleTypePvj then
                            local atkBuff = {}
                            for k, build in pairs(atkContext.buildData:getSceneBuilds()) do
                                build:addAtkBuff(atkBuff)
                            end
                            self.scene.battleData.preAtkBuffs = atkBuff
                        end
                    end
                    self.scene:reloadBuilds()
                    self.locked = true
                    self.lockedItem = "builds"
                end
            end
        elseif stepItem[1]=="data" then
            if stepItem[2]=="udata" then
                if self.isExit then
                    local context = GameLogic.getUserContext()
                    GameLogic.setCurrentContext(context)
                else
                    if GameNetwork.checkRequest() then
                        self.step = self.step - 1
                        return
                    end
                    self.locked = true
                    GameLogic.dumpCmds(true)
                    if self.params then
                        if self.params.type==const.BattleTypePvp then
                            if self.params.isReplay then
                                self:getReplay()
                            else
                                if self.params.bparams and self.params.bparams.tryHids then
                                    self.scene.revenge=true
                                    self:getDataOver(self.loadingEntry, true)
                                elseif self.params.pvpData then            --复仇
                                    self.scene.revenge=true
                                    self:getDataOver(self.loadingEntry, true, self.params.pvpData)
                                else
                                    local ucontext = GameLogic.getUserContext()
                                    ucontext:changeRes(const.ResGold, -ucontext:getPvpCost())
                                    self.inPvpLog = true
                                    GameNetwork.request("pvpdata", {syn_id=ucontext:getLastSynId()}, self.getDataOver, self, self.loadingEntry)
                                end
                            end
                        elseif self.params.type==const.BattleTypePve then
                            local pType = self.params.ptype or false
                            local idx = self.params.idx
                            if not pType then
                                local sdata = SData.getData("pverewards", idx)
                                if sdata and sdata.map then
                                    idx = sdata.map
                                end
                            end
                            GameNetwork.request("pvedata", {questdata={idx}}, self.getDataOver, self, self.loadingEntry)
                        elseif self.params.type==const.BattleTypePvc then
                            if self.params.isReplay and self.params.battleReplayData then
                                self.scene.battleReplayData = self.params.battleReplayData
                                self:getArenaDataOver2(self.loadingEntry, true, self.params.battleReplayData)
                            else
                                if self.isPrepare then
                                    if self.params.havePvcData then
                                        self:getArenaDataOver(self.loadingEntry, true, self.params.havePvcData)
                                    else
                                        GameNetwork.request("pvcBeginBattle", {tid=self.params.bparams.uid,nrank=self.params.bparams.rank,force=0}, self.getArenaDataOver, self, self.loadingEntry)
                                    end
                                else
                                    self:loadArenaBattleData()
                                end
                            end
                        elseif self.params.type==const.BattleTypePvh then
                            if self.isPrepare then
                                GameNetwork.request("pvhdata", {getpvhplayer={self.params.bparams.stage,self.params.bparams.nightmare}}, self.getPvhDataOver, self, self.loadingEntry)
                            else
                                if self.params.bparams.tryHids then
                                    self:getPvhDataOver(self.loadingEntry, true, {hhp={{1,100},{2,100},{3,100},{4,100},{5,100}}})
                                end
                                self:loadArenaBattleData()
                            end
                        elseif self.params.type == const.BattleTypePvt then   --英雄试炼
                            if self.isPrepare then
                                self:preparePvt()
                            else
                                local id = GameLogic.getCurrentContext().pvtdata.idx
                                local context = GameLogic.getUserContext()
                                context:addCmd({const.CmdPvtBBat,id})
                                GameLogic.dumpCmds(true)
                                self.locked = false
                            end
                        elseif self.params.type == const.BattleTypeUPve then   --联盟副本
                            local idx = self.params.idx+200
                            GameNetwork.request("getquestdata",{questdata = {idx}},self.beginUnionPveOver,self, self.loadingEntry)
                        elseif self.params.type == const.BattleTypePvj then    --僵尸来袭
                            self:initPvj()
                        elseif self.params.type == const.BattleTypeUPvp then   --联盟战
                            self:getPvlOver()
                        elseif self.params.type == const.BattleTypePvz then   --淘汰赛
                            if self.params.isReplay then
                                self:getPvzReplay()
                            else
                                self:getPvzOver(self.params.data)
                            end
                        --参观
                        elseif self.params.type == const.BattleTypePvb then
                            self:loadPvbData()
                        elseif self.params.type == const.VisitTypeUn then
                            GameNetwork.request("playerdata",{tid = self.params.uid, cid = self.params.cid}, self.getUnVisitOver, self, self.loadingEntry)
                        end
                    end
                end
            end
        elseif stepItem[1]=="dealRes" then
            if stepItem[2] == "removeRes" then
                memory.releaseCacheFrame()
            elseif stepItem[2] == "addRes0" then
                local scene = GMethod.loadScript("game.View.Scene")
                local sc = ButtonHandler(self.onLoadPlistOver, self)
                local sv = self.loadingView.view
                if scene.bgPng then
                    self.asynctotal = self.asynctotal+12
                    --ResAsyncLoader:getInstance():addLuaTask(sv, nil, scene.bgPng, sc)
                    local blockNum = 0
                    for i = 1, 12 do
                        blockNum = blockNum+1
                        local name = string.sub(scene.bgPng, 1, string.len(scene.bgPng)-4)
                        ResAsyncLoader:getInstance():addLuaTask(sv, nil, name.."_"..blockNum..".png", sc)
                    end
                end
                if scene.sceneType == "battle" then
                    memory.loadSpriteSheet("effects/battleEffects.plist",nil,true,sv,sc)
                    memory.loadSpriteSheet("effects/effectsRes/heroRes/heroGenerelRes1.plist",nil,true, sv,sc)
                    memory.loadSpriteSheet("effects/effectsRes/heroRes/heroGenerelRes2.plist",nil,true, sv,sc)
                    memory.loadSpriteSheet("effects/effectsRes/heroRes/heroGenerelRes3.plist",nil,true, sv,sc)
                    self.asynctotal = self.asynctotal + 4
                end
                self.locked = true
                self.lockedItem = "res"
            elseif stepItem[2] == "addRes" then
                local scene = GMethod.loadScript("game.View.Scene")
                local sc = ButtonHandler(self.onLoadPlistOver, self)
                local sv = self.loadingView.view
                if scene.sceneType == "battle" then
                    if scene.battleData.groups[1].hitems then
                        local cfs = cc.FileUtils:getInstance()
                        local hitems = scene.battleData.groups[1].hitems
                        for _,hitem in ipairs(hitems) do
                            if hitem.hero then
                                if hitem.hid then
                                    if memory.loadSpriteSheetRelease(GetPersonPlist(hitem.hid, hitem.hero.level, hitem.hero.awakeUp), true, sv, sc) then
                                        self.asynctotal = self.asynctotal + 1
                                    end
                                    if hitem.hero.awakeUp>0 then
                                        self.asynctotal = self.asynctotal + 1
                                        local afile = GameUI.getHeroFeature(hitem.hid, false, 1)
                                        ResAsyncLoader:getInstance():addLuaTask(sv, nil, afile, sc)
                                    end
                                end
                                if scene.battleType~=const.BattleTypePvt and hitem.sid then
                                    if memory.loadSpriteSheetRelease(GetPersonPlist(hitem.sid, hitem.hero.soldierLevel, 0), true, sv, sc) then
                                        self.asynctotal = self.asynctotal + 1
                                    end
                                end
                            end
                        end
                    end
                    local battleHeroDatas=GameLogic.getBattleHeroId()

                    --回放从回放数据中取
                    if self.params.battleReplayData then
                        battleHeroDatas ={}
                        for i, v in ipairs(self.params.battleReplayData.foeData.heros) do
                            table.insert(battleHeroDatas,v[2])
                        end
                        for i, v in ipairs(self.params.battleReplayData.myData.heros) do
                            table.insert(battleHeroDatas,v[2])
                        end
                    end

                    for i,hid in ipairs (battleHeroDatas) do
                        if cc.FileUtils:getInstance():isFileExist("effects/effectsRes/heroRes/heroEffectRes_"..hid..".plist") then
                            memory.loadSpriteSheet("effects/effectsRes/heroRes/heroEffectRes_"..hid..".plist",nil,true, sv,sc)
                            self.asynctotal = self.asynctotal + 1
                        end
                    end
                    self.locked = true
                    self.lockedItem = "res"
                end
            end
        end
    end
    --self.loadingView:setPercent(self.step*100/self.loadMax)
    if self.step>=self.loadMax then
        self:loadingOver()
    end
end

function Loading:loadingOver()
    --战斗前准备的背景音乐
    music.setBgm("music/fight_ready.mp3")
    if self.scene.sceneType=="battle" and self.scene.battleType==const.BattleTypePvc then
        music.setBgm("music/battleDefence.mp3")
    end

    if self.asynctotal>self.asyncfinish then
        return
    end
    if self.loadingEntry then
        GMethod.unschedule(self.loadingEntry)
        self.loadingEntry = nil
    end
    self.loadingView:delete()
    self.scene.menu:onChangeOver()
    if self.scene.replay and self.scene.isBattle then
        self.scene.replay.isStartBattle = true
    end
    GameUI.setLoadingState(false)
end

function Loading:onLoadPlistOver(suc, plist)
    self.asyncfinish = self.asyncfinish+1
    if plist and plist:find(".png") and suc then
        memory.loadTexture(plist):retain()
    end
end

function Loading:startLoading()
    local scene = GMethod.loadScript("game.View.Scene")
    UnregTimeUpdate(scene.menu.view)
    scene.menu.inCount = nil
    scene.loadBuildsThread = nil

    GameUI.setLoadingState(true)
    local lview = self.loadingView
    --lview:setLoadingState("loading")
    --lview:setPercent(0)

    local loadSteps = {}
    table.insert(loadSteps, {"init"})
    table.insert(loadSteps, {"data", "udata"})
    table.insert(loadSteps, {"dealRes", "removeRes"})
    table.insert(loadSteps, {"dealRes", "addRes0"})
    table.insert(loadSteps, {"scene", "ground"})
    table.insert(loadSteps, {"scene", "builds"})
    table.insert(loadSteps, {"scene", "menu"})
    table.insert(loadSteps, {"dealRes", "addRes"})
    self.loadSteps = loadSteps
    self.loadMax = #loadSteps
    self.step = 0
    self.asynctotal = 0
    self.asyncfinish = 0
    self.locked = false
    self.lockedItem = nil
    self.inPvpLog = nil
    if self.loadingEntry then
        GMethod.unschedule(self.loadingEntry)
        self.loadingEntry = nil
    end
    self.loadingEntry = GMethod.schedule(Handler(self.loading, self),0,false)
    music.setBgm(nil)
end

return Loading
