local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local ResData = GMethod.loadScript("game.GameLogic.ResData")
local BuildData = GMethod.loadScript("game.GameLogic.BuildData")
local HeroData = GMethod.loadScript("game.GameLogic.HeroData")
local EquipData = GMethod.loadScript("game.GameLogic.EquipData")
local WeaponData = GMethod.loadScript("game.GameLogic.WeaponData")
local PveData = GMethod.loadScript("game.GameLogic.PveData")
local ArenaData = GMethod.loadScript("game.GameLogic.ArenaData")
local PvjData = GMethod.loadScript("game.GameLogic.PvjData")
local PvhData = GMethod.loadScript("game.GameLogic.PvhData")
local GuideData = GMethod.loadScript("game.GameLogic.GuideData")
local GuideOrData = GMethod.loadScript("game.GameLogic.GuideOrData")

local ResSetting = {}
ResSetting[const.ResGold] = {1, const.ProGold, const.ProGoldMax}
ResSetting[const.ResBuilder] = {1, const.ProBuilder, const.ProBuilderMax}
ResSetting[const.ResCrystal] = {1, const.ProCrystal}
ResSetting[const.ResSpecial] = {1, const.ProSpecial}
ResSetting[const.ResExp] = {0, const.InfoExp}
ResSetting[const.ResScore] = {0, const.InfoScore}
ResSetting[const.ResZhanhun] = {1, const.ProZhanhun}
ResSetting[const.ResMagic] = {1, const.ProMagic}
ResSetting[const.ResMedicine] = {1, const.ProMedicine}
ResSetting[const.ResBeercup] = {1, const.ProBeercup}
ResSetting[const.ResEventMoney] = {1, const.ProEventMoney}
ResSetting[const.ResMicCrystal] = {1, const.ProMicCrystal}
ResSetting[const.ResTrials] = {1, const.ProTrials}
ResSetting[const.ResPBead] = {1, const.ProPBead}
ResSetting[const.ResGXun] = {1, const.ProGXun}
ResSetting[const.ResGaStone] = {1, const.ProGaStone}
ResSetting[const.ProPopular] = {1, const.ProPopular}
-- 用来包装数据模块的地方
local TimeRefreshData = class()

-- 一个自动刷新的值需要有：时间ID、数量ID，以及对应的上限、刷新初始时间、刷新间隔时间
-- 该模块满足的逻辑是，需要随着时间进行重置的值，直接通过该值进行重新获取
function TimeRefreshData:ctor(udata, timeId, pvId, max, refreshTime, distance)
    self.udata = udata
    self.timeId = timeId
    self.pvId = pvId
    self.max = max
    self.initTime = refreshTime or const.InitTime
    self.distance = distance or 86400
end

-- 重置数量；考虑到后续扩展之类的做法，次数都从0开始记，然后以max-value来返回剩余次数
-- 这样以后需要动态修改max的时候就不会出现剩余次数更多的情况了
function TimeRefreshData:resetValue(stime)
    local udata = self.udata
    udata:setProperty(self.timeId, self.initTime)
    udata:setProperty(self.pvId, 0)
    if self.buyId then
        udata:setProperty(self.buyId, 0)
        udata:setProperty(self.buyCountId, 0)
    end
end

function TimeRefreshData:refreshTime(stime)
    local stime = stime or GameLogic.getSTime()
    while stime < self.initTime do
        self.initTime = self.initTime - self.distance
    end
    if stime >= self.initTime + self.distance then
        self.initTime = self.initTime + math.floor((stime-self.initTime)/self.distance)*self.distance
    end
    if self.initTime > self.udata:getProperty(self.timeId) then
        self:resetValue(stime)
    end
end

function TimeRefreshData:getValue(stime)
    self:refreshTime(stime)
    local ret = self.max - self.udata:getProperty(self.pvId)
    if self.buyId then
        ret = ret + self.udata:getProperty(self.buyCountId)
    end
    return ret
end

function TimeRefreshData:getNormalValue(stime)
    self:refreshTime(stime)
    return self.udata:getProperty(self.pvId)
end

function TimeRefreshData:changeValue(num, stime)
    self:refreshTime(stime)
    self.udata:setProperty(self.timeId, stime)
    self.udata:changeProperty(self.pvId, -num)
end

function TimeRefreshData:getMax(stime)
    return self.max
end

-- 增加可购买逻辑扩展
function TimeRefreshData:setBuyTemplates(buyId, buyCountId, buyType)
    self.buyId = buyId
    self.buyCountId = buyCountId
    self.buyType = buyType
end

-- 按可购买逻辑 完成一次购买
function TimeRefreshData:buyChance(stime)
    self:refreshTime(stime)
    local canBuySetting = self:getCanBuyChance(self.udata:getProperty(self.buyId)+1)
    self.udata:changeProperty(self.buyId, 1)
    self.udata:changeProperty(self.buyCountId, canBuySetting.addNum or 1)
    self.udata:addCmd({const.CmdBuyPvp, GameLogic.getSTime(), self.buyType})
end

-- 按可购买逻辑 返回已购买的次数，已购买的挑战次数
function TimeRefreshData:getBuyedChance(stime)
    self:refreshTime(stime)
    return self.udata:getProperty(self.buyId), self.udata:getProperty(self.buyCountId)
end

-- 按可购买逻辑 返回可购买的最大次数
function TimeRefreshData:getBuyedChanceMax()
    local allBuys = SData.getData("buyChanceNum", self.buyType)
    local ret = KTLen(allBuys)
    return ret
end

-- 按可购买逻辑 返回可购买的最大次数
function TimeRefreshData:getCanBuyChance(idx)
    return SData.getData("buyChanceNum", self.buyType, idx)
end

--context用来做所有用户有关的数值逻辑
local UContext = class()

function UContext:ctor(uid)
    self.uid = uid
    self.resData = ResData.new(self)
    self.buildData = BuildData.new(self)
    self.heroData = HeroData.new(self)
    self.equipData = EquipData.new(self)
    self.weaponData = WeaponData.new(self)
    self.pve = PveData.new(self)
    self.arena = ArenaData.new(self)

    local TalentMatch = GMethod.loadScript("game.GameLogic.TalentMatch")
    self.talentMatch = TalentMatch.new(self)
end

function UContext:loadContext(data)
    self.cmds = {}
    self.info = data.info or {}
    for i=1,20 do
        if not self.info[i] then
            self.info[i] = 0
        end
    end
    if GameLogic.useTalentMatch then
        self:setInfoItem(const.InfoVIPlv, 0)
        self:setInfoItem(const.InfoVIPexp, 0)
    end
    local pd = KT({})
    data.properties = data.properties or {}
    for _, pair in ipairs(data.properties) do
        pd[pair[1]] = pair[2]
    end
    self.ps = pd
    local midx = self:getProperty(const.ProCmdIdx)
    self.cmdStat = {lastIdx = midx, sendedIdx = midx, maxIdx = midx, cachedCmds={}, goldStat={self:getRes(const.ResGold)}}

    self.pvpChance = TimeRefreshData.new(self, const.ProPvpChanceTime, const.ProPvpChanceNum, const.MaxPvpChance)
    self.pvpChance:setBuyTemplates(const.ProPvpBuyCount, const.ProPvpBuyNum, const.BattleTypePvp)
    if data.builds then
        self.buildData:loadData(data)
    end
    if data.heros then
        self.heroData:loadData(data)
    end
    if data.equips then
        self.equipData:loadData(data)
    end
    self.weaponData:loadData(data)
    if data.pvjdata then
        self.pvj = PvjData.new(data.pvjdata)
    end
    if data.pvzData then
        self.pvzData = data.pvzData
    end
    if data.mRank then
        self.mRank = data.mRank
    end
    if data.gRank then
        self.gRank = data.gRank
    end
    if data.MatchInitTime then
        self.MatchInitTime = data.MatchInitTime
    end
    self.achsData = {{0,0,0,1504915200,0}, {0,1,0,1504915200,0}}
    if data.achs then
        for _, ach in ipairs(data.achs) do
            self.achsData[ach[2] + 1] = ach
        end
    end
    --联盟有关逻辑
    if data.linfo and next(data.linfo) then
        local linfo = data.linfo
        self.union = {id=linfo[1], job=linfo[2], name=linfo[3], flag=linfo[4], enterTime=linfo[5], cup = linfo[6],language = linfo[11]}
        self.unionPets = {skill=data.psk or {1,1,1,1,1,1}, pets=data.pids, curPid=linfo[9], level=linfo[7], exp=linfo[8], pbead=linfo[10] or 0}
    end
    --VIPS 1.建筑cd，2.资源加速， 3.炼金加速 ，4.工会月卡，5.个人月卡, 6.pve
    local t = GameLogic.getTime()
    self.vips = {{1,t,0},{1,t,0},{1,t,0},{1,t,0},{1,t,0},{1,t,0}} --{idx,time,生效/失效}
    if data.vips then
        for i,v in ipairs(data.vips) do
            if not self.vips[v[1]] then
                self.vips[v[1]]={1,t,0}
            end
            self.vips[v[1]][2] = v[2]
            self.vips[v[1]][3] = v[3]
            local rtime = GameLogic.getRtime()
            --结束了
            if GameLogic.getTime()-self.vips[v[1]][2]>rtime then
                self.vips[v[1]][3] = 0
            end
        end
    end
    self.sid = self:getInfoItem(const.InfoSVid)
    self.guide = GuideData.new(self)
    self.guideOr = GuideOrData.new(self)
    self.guideHand = GuideHand.new()
    --活动 任务 成就  rep等信息
    if data.actinfo then
        local activeData = GMethod.loadScript("game.GameLogic.ActiveData").new()
        activeData:loadData(data)
        self.activeData = activeData
    end
    if data.taskinfo then
        local activeData = self.activeData
        activeData:loadLimit(data.taskinfo)
    end
    if data.achinfo then
        local achieveData = GMethod.loadScript("game.GameLogic.AchieveData").new(data.achinfo)
        self.achieveData = achieveData
    end

    self.lastSynTime = data.lastSynTime or 0

    if data.gainfo then
        local meltData = GMethod.loadScript("game.GameLogic.MeltData").new(data.gainfo)
        self.meltData = meltData
    end
    if data.rep then
        self.enterData = data.rep
        --replays 被攻打   --ustate 1保护时间 2攻打时间  3 一天护盾  4 三天   5一周   6 vip   除了1保存的都是购买时间
        self.enterData.ustate = self.enterData.ustate or {0,0,0,0,0,0}
        local us = self.enterData.ustate
        local a,b,c,d = us[3],us[4],us[5],us[6]
        local s = const.ShieldSetting
        us[3],us[4],us[5],us[6] = d+s[1][3] ,a+s[2][3],b+s[3][3],c+s[4][3]
        if next(data.rep.replays) then
            --WarReportOut.new(data.rep.replays)
            self.replays=data.rep.replays
        end
    end
    if data.ranklist then
        local set = {pvp=181,pvl=182,pvt=183,pvb=184,pvc=185, pvzg = 187, pvzk = 186}
        self.rankList = {}
        for k,v in pairs(data.ranklist) do
            local id = set[k]
            self.rankList[id] = v
        end
        self.syncRankListTime = GameLogic.getSTime()
    end
    self:addExp(0)
    self:changeProperty(const.ProPopular, 0)

    if self.activeData then
        self.activeData:finishRateAct()
        self.activeData:finishTcodeAct()
    end

    --芯片更改：适配原来版本，将老芯片换成新的芯片道具
    local chip = SData.getData("property",const.ItemChip)
    local chipTable = {}
    for i,chip in KTIPairs(chip) do
        table.insert(chipTable, 1, {idx=i, exp=chip.value})
    end
    -- GameLogic.mySort()

    if self.activeData then
        for i,hero in pairs(self.heroData:getAllHeros()) do
            if hero.info.job == 0 then
                local exp = hero:getAddExp()
                for i=1, #chipTable do
                    if exp > chipTable[i].exp then
                        self:changeItem(const.ItemChip, chipTable[i].idx, math.floor(exp/chipTable[i].exp))
                        exp = exp % chipTable[i].exp
                    end
                end
                self.heroData:removeHero(hero.idx)
                --告诉后台换了那些英雄
                self:addCmd({const.CmdTallSeverChangeChip, hero.idx})
            end
        end
    end
end

-- 根据pvp剩余次数计算倍率
function UContext:computePvpRate(pnum)
    local rates = const.PvpBoxRates
    local ret
    for _, rate in KTIPairs(rates) do
        ret = rate[2]
        if pnum <= rate[1] then
            break
        end
    end
    return ret
end

-- 获取网络请求的唯一标识ID，防止重复提交数据；由于比较担心服务器性能，先只在确定的一些接口上增加该功能
function UContext:getLastSynId()
    local synId = self.synId
    local newSynId = synId
    while synId == newSynId do
        newSynId = ((GameLogic.getSTime() - const.InitTime) % 86400) * 10000 + math.random(10000)
    end
    self.synId = newSynId
    return newSynId
end

--时间跨日，刷新数据
function UContext:refreshContext(data)
    if data.actinfo then
        local activeData = GMethod.loadScript("game.GameLogic.ActiveData").new()
        activeData:loadData(data.actinfo)
        self.activeData = activeData
    end
    if data.taskinfo then
        local activeData = self.activeData
        activeData:loadLimit(data.taskinfo)
    end
    local pd = KT({})
    if data.properties then
        for _, pair in ipairs(data.properties) do
            pd[pair[1]] = pair[2]
        end
        self.ps = pd
    end
end

function UContext:makeTempHeroData(data)
    self.heroData = HeroData.new(self)
    self.heroData.__isTemp = true
    self.heroData:loadData(data or {heros={}, hlayouts={}, hbskills={}})
end

function UContext:getBattleBuff()
    local params = {}
    --获取pvz 重生对应的buff
    if self.pvzData then
        params.hpPct = (self.pvzData.hpPct or 0)-1
        params.atkPct = (self.pvzData.atkPct or 0)-1
        --战斗的时候是按照没有基础值算的，其他界面显示是按照有基础值算的，这里把基础值减掉
        params.hpPct = (params.hpPct>0) and params.hpPct or 0
        params.atkPct = (params.atkPct>0) and params.atkPct or 0
    end
    return params
end

--获取联盟宠物信息
function UContext:getUnionPets()
    if self.union and self.union.id>0 then
        return self.unionPets
    end
end

--查询自己是否有权限；目前统一检查
function UContext:hasUnionPermission(ptype)
    local myjob = self.union and self.union.job
    local needJob = 4
    if myjob and myjob>=needJob then
        return true
    end
    return false
end

function UContext:loadPvj(data)
    self.pvj = PvjData.new(data)
    return self.pvj
end

function UContext:loadPvh(data)
    self.pvh = PvhData.new(data)
    return self.pvh
end
--==============================--
--desc:噩梦远征
--time:2018-01-18 05:51:26
--@return
--==============================--
function UContext:loadNightWarePvh(data)
    self.npvh=PvhData.new(data)
    return self.npvh
end
function UContext:destroy()
    self.uid = nil
    self.info = nil
    self.properties = nil
    self.resData:destroy()
    self.resData = nil
    self.buildData:destroy()
    self.buildData = nil
    self.weaponData:destroy()
    self.weaponData = nil
    self.talentMatch:destroy()
    self.talentMatch = nil
end

function UContext:getInfoItem(k)
    return self.info[k+1] or 0
end

function UContext:setInfoItem(k, v)
    self.info[k+1] = v
    return v
end

function UContext:changeInfoItem(k, v)
    self.info[k+1] = self.info[k+1]+v
    return self.info[k+1]
end

function UContext:nextRandom(mod)
    local seed = self:getInfoItem(const.InfoRandom)
    seed = (seed*const.RdA+const.RdB)%const.RdM
    self:setInfoItem(const.InfoRandom, seed)
    return seed%mod
end

function UContext:getProperty(k)
    return self.ps[k] or 0
end

function UContext:setProperty(k, v)
    if k == const.ProPopular then
        --取声望最大值
        local popunlockData= SData.getData("popunlock")
        local maxPopular = popunlockData[#popunlockData].pNum
        if v>maxPopular then
            v = maxPopular
        end
        local _curLevel = self:getProperty(const.ProPopLevel)
        local _oldLevel = _curLevel
        while _curLevel > 0 and SData.getData("popunlock", _curLevel + const.FreePopIdx).pNum > v do
            _curLevel = _curLevel - 1
        end
        local nextLv = SData.getData("popunlock", _curLevel + const.FreePopIdx + 1)
        while nextLv and nextLv.pNum <= v do
            _curLevel = _curLevel + 1
            nextLv = SData.getData("popunlock", _curLevel + const.FreePopIdx + 1)
        end
        if _curLevel ~= _oldLevel then
            self:setProperty(const.ProPopLevel, _curLevel)
            self:addCmd({const.CmdUpgradePopLevel, _curLevel})
        end
        if self.activeData then
            self.activeData:finishActConditionOnce(const.ActStatPrestigeValue, v)
        end
    end
    self.ps[k] = v
    return v
end

function UContext:changeProperty(k, v)
    local r = (self.ps[k] or 0)+v
    self.ps[k] = r
    if k == const.ProGold and self._lockGold then
        if v > self._lockGold then
            v = self._lockGold
        end
        self._lockGold = self._lockGold - v
    end
    if k == const.ProCrystal and v < 0 then
        if self.activeData then
            --消耗宝石 寻宝数值增加
            local tresure = self.activeData.limitActive[101]
            if tresure then
                tresure[5] = tresure[5]-v
            end
            -- 日常任务消耗宝石
            self.activeData:finishActCondition(const.ActTypeCrystal, -v)
            self.activeData:finishActConditionOnce(const.ActTypeCrystalSingle, -v)
        end
    end
    return self:setProperty(k, r)
end

function UContext:getRes(resId)
    local rs = ResSetting[resId]
    if rs[1]==0 then
        return self:getInfoItem(rs[2])
    else
        return self:getProperty(rs[2])
    end
end

function UContext:setRes(resId, value)
    local rs = ResSetting[resId]
    if rs[1]==0 then
        return self:setInfoItem(rs[2], value)
    else
        local ret = self:setProperty(rs[2], value)
        if rs[3] and self.resData then
            local r2 = self.resData:getNum(resId)
            self.resData:changeNum(resId, ret-r2)
        end
        return ret
    end
end

function UContext:changeRes(resId, value)
    local rs = ResSetting[resId]
    if resId == const.ResExp then
        self:addExp(value)
    elseif rs[1]==0 then
        return self:changeInfoItem(rs[2], value)
    else
        local ret = self:changeProperty(rs[2], value)
        if rs[3] and self.resData then
            local r2 = self.resData:getNum(resId)
            self.resData:changeNum(resId, ret-r2)
        end
        return ret
    end
end

function UContext:getResMax(resId)
    local rs = ResSetting[resId]
    if rs[3] then
        return self:getProperty(rs[3])
    elseif resId==const.ResExp then
        local lv = self:getInfoItem(const.InfoLevel)
        local exp = SData.getData("ulevels", lv)
        if exp then
            return exp
        end
    end
    return 0
end

function UContext:changeResMax(resId, value)
    local rs = ResSetting[resId]
    if rs[3] then
        return self:changeProperty(rs[3], value)
    end
end

function UContext:changeResWithMax(resId, value)
    if resId==const.ResGold then
        if self._lockGold then
            if value > self._lockGold then
                value = self._lockGold
            end
            self._lockGold = self._lockGold - value
        end
        local max = self:getResMax(resId)
        local res = self:getRes(resId)
        if res+value>max then
            self:setRes(resId, max)
            return max-res
        else
            self:setRes(resId, res+value)
            return value
        end
    else
        return self:changeRes(resId, value)
    end
end

-- 思路：在发请求未返回时，保存此时的剩余可增加数值；在请求返回时，将该值设置给请求本身，然后进行处理
function UContext:getLockGold()
    local _emptySpace = self:getResMax(const.ResGold) - self:getRes(const.ResGold)
    return _emptySpace
end

function UContext:getItemPid(itemType, itemId)
    local pid = SData.getData("property", itemType, itemId)
    if not pid then
        if itemType==const.ItemFragment then
            pid = itemId-4000+200
        elseif itemType==const.ItemEquipFrag then
            pid = itemId-2000+300
        else
            pid = itemId
        end
    else
        pid = pid.pid
    end
    return pid
end

function UContext:getItem(itemType, itemId)
    return self:getProperty(self:getItemPid(itemType, itemId))
end

function UContext:getAchsData()
    local stime = GameLogic.getSTime()
    local adata = self.achsData
    if (math.floor((stime-const.InitTime)/86400) > math.floor((adata[1][4]-const.InitTime)/86400)) then
        adata[1][4] = stime
        adata[1][3] = 0
        adata[1][5] = 0
    end
    if math.floor((stime-const.InitTime)/(7*86400)) > math.floor((adata[2][4]-const.InitTime)/(7*86400)) then
        adata[2][4] = stime
        adata[2][3] = 0
        adata[2][5] = 0
    end
    return adata
end

function UContext:setItem(itemType, itemId, value)
    return self:setProperty(self:getItemPid(itemType, itemId), value)
end

function UContext:changeItem(itemType, itemId, value)
    if itemType == 22 then
        local adata = self:getAchsData()
        adata[1][3] = adata[1][3] + value
        adata[2][3] = adata[2][3] + value
    else
        if GameLogic.useTalentMatch and itemType == const.ItemFragment then
            local cnum = self:getItem(const.ItemFragment, itemId)
            local flag=true
            local heroAll=self.heroData:getAllHeros()
            for k,v in pairs(heroAll) do
                if v.hid==itemId then
                    flag=false
                    break
                end
            end
            if cnum+value>=1500 and cnum<1500 and flag then
                display.showDialog(AlertDialog.new({ctype = 16, title = Localize("btnCollectHero"), text = Localizef("alertFusion", {a =Localize("dataHeroName" .. itemId)}), value = Localize("btnPetsSynthesis"), callback = function()
                        local hid = itemId
                        local context = GameLogic.getUserContext()
                        local heroData = context.heroData
                        local hinfo = SData.getData("hinfos",hid)
                        if heroData:getHeroNum()>=heroData:getHeroMax() then
                            display.pushNotice(Localize("noticeHeroPlaceFull"))
                            return
                        end
                        if hinfo.fragNum>0 and hinfo.fragNum<=context:getItem(const.ItemFragment, hid) then
                            local rate = hinfo.displayColor and hinfo.displayColor >=5 and 5 or hinfo.rating
                            context.heroData:mergeHero(hid,rate)
                            display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(const.ItemHero, hid)}))
                            local cnum = context:getItem(const.ItemFragment, hid)
                            local mnum = hinfo.fragNum
                            local _hero = context.heroData:makeHero(hid)
                            NewShowHeroDialog.new({rhero=_hero,shareIdx = _hero.info.rating})
                        end
                end} ))
            end
        end
        return self:changeProperty(self:getItemPid(itemType, itemId), value)
    end
end

local canMerge = {
    [const.CmdUpgradeUlv] = 0,
    [const.CmdChangeLayout] = 0,
    [const.CmdBuyHeroPlace] = 1,
    [const.CmdHeroMic] = 1,
    [const.CmdEquipUpgrade] = 1,
    [const.CmdUseOrSellItem] = 1
}
function UContext:addCmd(cmd)
    local cmds = self.cmds
    local cl = #cmds
    local ms = canMerge[cmd[1]]
    if ms then
        if cl>0 then
            local lcmd = cmds[cl]
            if lcmd[1]==cmd[1] then
                if ms==0 then
                    local idx = #lcmd
                    for j=2, idx do
                        lcmd[j] = cmd[j]
                    end
                elseif ms==1 then
                    local idx = #lcmd
                    for j=2, idx-1 do
                        if lcmd[j]~=cmd[j] then
                            cmds[cl+1] = cmd

                            local cstat = self:getCmdStat()
                            cstat.maxIdx = cstat.maxIdx + 1
                            table.insert(cstat.cachedCmds, cmd)
                            table.insert(cstat.goldStat, self:getRes(const.ResGold))
                            self:saveCmdStat()
                            return
                        end
                    end
                    lcmd[idx] = lcmd[idx]+cmd[idx]
                end
                self:saveCmdStat()
                return
            end
        end
    end
    cmds[cl+1]  = cmd

    local cstat = self:getCmdStat()
    cstat.maxIdx = cstat.maxIdx + 1
    table.insert(cstat.cachedCmds, cmd)
    table.insert(cstat.goldStat, self:getRes(const.ResGold))
    self:saveCmdStat()
end

function UContext:getCmdStat()
    if not self.cmdStat then
        self.cmdStat = {lastIdx = 0, sendedIdx = 0, maxIdx = 0, cachedCmds={}, goldStat={self:getRes(const.ResGold)}}
    end
    return self.cmdStat
end

function UContext:saveCmdStat()
    self:getCmdStat().dirty = true
end

function UContext:dumpCmds()
    self.buildData:dumpLayoutChanges()
    self.resData:dumpExtChanges()
    if self.comChanged then
        local allCombat = self:getProperty(const.ProCombat)
        self:addCmd({const.CmdAllCombat,GameLogic.getSTime(),allCombat})
    end
    local rcmds = self.cmds
    if #rcmds>0 then
        self.cmds = {}
        return rcmds
    end
    return nil
end

function UContext:getFreeHeroChance(stime)
    if not stime then
        stime = GameLogic.getSTime()
    end
    local t = self:getProperty(const.ProFreeTime)
    local setting = SData.getData("hlsetting", 1)
    local dtime = stime-t
    local max = setting.max-1
    --local vnum = self:getVipPermission("lottery")[2]
    --max = max+vnum
    if dtime>=setting.rtime*max then
        return max+1
    else
        if dtime<=0 then
            dtime = 0
        end
        return math.floor(dtime/setting.rtime), (setting.rtime*max-dtime)%setting.rtime
    end
end

function UContext:getFragHero()
    local hinfos = SData.getData("hinfos")
    local hids = {}
    local canGet = 0
    for hid, hinfo in pairs(hids) do
        if hid>4000 and hid<5000 then
            if hinfo[2].fragNum>0 and hinfo[2].fragNum<=self:getItem(const.ItemFragment, hinfo[1]) then
                canGet = canGet+1
            end
        end
    end
    return canGet
end

function UContext:addExp(exp)
    local exp = self:changeInfoItem(const.InfoExp, exp)
    local nextExp = self:getResMax(const.ResExp)
    local upgraded = false
    while nextExp>0 and exp>=nextExp do
        upgraded = true
        exp = self:changeInfoItem(const.InfoExp, -nextExp)
        self:changeInfoItem(const.InfoLevel, 1)
        nextExp = self:getResMax(const.ResExp)
    end
    if upgraded then
        --玩家升级时调用(做统计用)
        local ucontext = GameLogic.getUserContext()
        if ucontext == self then
            GameLogic.statForSnowfish("levelup", {roleLevelMTime=tostring(GameLogic.getSTime())})
        end
        local achieveData = self.achieveData
        if achieveData then
            -- achieveData:finish(1)
            achieveData:finish(const.ActTypeBuildLevelUp)
            Plugins:onFacebookStat("PreUserLevel", self:getInfoItem(const.InfoLevel))
        end
        self:addCmd({const.CmdUpgradeUlv})
        if achieveData then  --考虑参观的情况
            self.activeData:finishActConditionOnce(const.ActStatUserLevel,self:getInfoItem(const.InfoLevel))
            self.activeData:finishActConditionOnce(const.ActStatUserVip,self:getInfoItem(const.InfoVIPlv))--vip等级与玩家等级双触发活动
        end
    end
end

function UContext:changeLayout(lid, newLayouts)
    local olid = self:getInfoItem(const.InfoLayout)
    if lid>=1 and lid<=3 then
        local bdata = self.buildData
        if olid ~= lid then
            bdata:dumpLayoutChanges()
            self:setInfoItem(const.InfoLayout, lid)
            self:addCmd({const.CmdChangeLayout, lid})
        end
        for idx, layout in pairs(newLayouts) do
            bdata:changeBuildLayout(idx, layout[1], layout[2])
        end
        bdata:dumpLayoutChanges()
    end
end

function UContext:buyHeroPlace(num)
    local cost = const.PriceHeroNum * num
    self:changeRes(const.ResCrystal, -cost)
    GameLogic.statCrystalCost("购买英雄背包消耗",const.ResCrystal, -cost)
    self:changeProperty(const.ProHeroNum, num)
    self:addCmd({const.CmdBuyHeroPlace, num})
end

function UContext:buyRes(ctype, cvalue, cost, buyIdx)
    self:changeRes(const.ResCrystal, -cost)
    if type(ctype) == "table" then
        self:changeItem(ctype[1], ctype[2], cvalue)
        ctype = {ctype[1], ctype[2]}
    else
        self:changeResWithMax(ctype, cvalue)
    end
    self:addCmd({const.CmdBuyRes, ctype, cvalue, buyIdx})
end

local _lotteryPercents1 = {450,500,45,5}
local _lotteryRates = {1,2,4,10}
function UContext:lotterySpecial()
    local count = self:getProperty(const.ProLuckCount)
    local ccost = SData.getData("constsNew", const.LuckyLotteryCostKey).data[count+1]
    local mbase = SData.getData("constsNew", const.LuckyLotteryBaseKey).data[count+1]

    local seed = self:nextRandom(1000)
    local rate
    local percent = 0
    local ps = _lotteryPercents1
    for i,r in ipairs(_lotteryRates) do
        percent = percent+ps[i]
        if percent>seed then
            rate = r
            break
        end
    end

    self:changeRes(const.ResCrystal, -ccost)
    GameLogic.statCrystalCost("转盘消耗",const.ResCrystal, -ccost)
    self:changeProperty(const.ProLuckReward, mbase*rate)
    self:changeProperty(const.ProLuckCount, 1)
    self:addCmd({const.CmdLuckyLottery})
    return rate
end

function UContext:getLotteryReward()
    self:changeRes(const.ResSpecial, self:getProperty(const.ProLuckReward))
    self:setProperty(const.ProLuckCount, 0)
    self:setProperty(const.ProLuckReward, 0)
    self:setProperty(const.ProLuck, 0)
    self:addCmd({const.CmdLuckyReward})
end

function UContext:addTestBuyCrystal(get,mode)
    self:changeRes(const.ResCrystal, get)
    self:addCmd({const.CmdTestBuyCrystal, get, mode})
end

function UContext:getPvpCost()
    local tlv = self.buildData:getMaxLevel(const.Town)
    local pvpCost = const.PvpCost
    if pvpCost[tlv] then
        return pvpCost[tlv]
    else
        return pvpCost[KTLen(pvpCost)]
    end
end

function UContext:useOrSellItem(itemtype, itemid, itemnum)
    if self:getItem(itemtype, itemid)>=itemnum then
        self:changeItem(itemtype, itemid, -itemnum)
        local property = SData.getData("property",itemtype,itemid)
        if itemtype==const.ItemResBox then
            self:changeResWithMax(property.rtype, property.value*itemnum)
            local rname = Localize("dataResName" .. property.rtype)
            local name = Localizef("labelPriceFormat",{num=property.value*itemnum, name=rname})
            display.pushNotice(Localizef("noticeGetItem",{name=name}))
        elseif itemtype==const.ItemHWater then
            self.pvj:changeAP(itemnum*property.value)
            local rname = Localize("dataResItemName5")
            local name = Localizef("labelPriceFormat", {num=itemnum*property.value, name=rname})
            display.pushNotice(Localizef("noticeGetItem",{name=name}))
        elseif property.price and property.price>0 then
            self:changeResWithMax(const.ResGold, property.price*itemnum)
            local rname = Localize("dataResName" .. const.ResGold)
            local name = Localizef("labelPriceFormat",{num=property.price*itemnum, name=rname})
            display.pushNotice(Localizef("noticeGetItem",{name=name}))
        elseif itemtype==const.ItemWelfare then
            display.pushNotice(Localizef("labelUseItemFormat",{num=itemnum,name=GameLogic.getItemName(itemtype, itemid)}))
        else
            return
        end
        self:addCmd({const.CmdUseOrSellItem, itemtype, itemid, itemnum})
    end
end

local ShopData = class()

function ShopData:ctor(tag, data, stime)
    self.items = data.items
    self.refreshCount = data.refreshCount
    self.tag = tag
    if tag=="epart" then
        self.refreshTime = self:getNextTime(stime, 6*3600)
    else
        self.refreshTime = self:getNextTime(stime, 24*3600)
    end
end

function ShopData:getNextTime(stime, distance)
    local todayTime = const.InitTime
    while todayTime<stime do
        todayTime = todayTime+distance
    end
    return todayTime
end

function ShopData:getItems()
    return self.items
end

function ShopData:getRefreshCount()
    return self.refreshCount
end

function ShopData:getRefreshType()
    if self.tag=="epart" then
        return const.ResCrystal
    elseif self.tag=="trials" then
        return const.ResTrials
    end
end

function ShopData:getRefreshCost()
    local costs
    if self.tag=="epart" then
        costs = const.PriceEpartRefresh
    elseif self.tag=="trials" then
        costs = const.PriceTrialsRefresh
    end
    local idx = self.refreshCount+1
    if idx>KTLen(costs) then
        idx = KTLen(costs)
    end
    return costs[idx]
end

function ShopData:getRefreshTime()
    return self.refreshTime
end

function UContext:getShopData(tag, stime)
    if not self.shops then
        self.shops = {}
    end
    local shop = self.shops[tag]
    if not shop or shop.refreshTime and shop.refreshTime>=stime then
        return shop
    end
end

function UContext:loadShopData(tag, data, stime)
    if not self.shops then
        self.shops = {}
    end
    self.shops[tag] = ShopData.new(tag, data, stime)
end

function UContext:addShopAction(tag, idx)
    if tag=="epart" then
        self:addCmd({const.CmdShopEpart, idx})
    elseif tag=="trials" then
        self:addCmd({const.CmdShopPvt, idx})
    end
end

--  relbuild 建筑减免   accres 资源加速  pvcs 竞技场次数    tobeer 对酒      pvts英雄试炼     lottery 英雄抽取
--    accga 炼金加速   propect VIP防护盾     luck 天运值翻倍
--  pvjcr 僵尸来袭扫荡     fbox 每日寻宝    pvjcr10 10连扫荡     chat 聊天    pvhs 远征次数加一    pvhbox 宝箱翻倍
local vipKeySet = {["relbuild"]=1,["accres"]=2,["accga"]=3,["pvesweep"]=6}
function UContext:getVipPermission(type)
    local num = SData.getData("vippower",self:getInfoItem(const.InfoVIPlv),type)
    local lock = 0
    if not GameLogic.useTalentMatch then
        if num<=0 then
            for i,v in ipairs(SData.getData("vippower")) do
                if v[type]>0 then
                    lock = i
                    break
                end
            end
        end
    end

    local stype = vipKeySet[type]
    if stype then
        num = num - self.vips[stype][3]
    end
    return {lock,num}  -- lock 0是已解锁  否则是解锁vip等级      num对应的数值
end

function UContext:setVipPermission(type,num)
    local stype = vipKeySet[type]
    self.vips[stype][3] = self.vips[stype][3]+num
end
-- 获取热点数据
function UContext:getHotItems()
    local _time = self:getProperty(const.ProNewBoxTime)
    local _wdItem = self:getProperty(const.ProNewBoxItems)
    -- 周热点不刷新；且为0时使用默认英雄
    local _weekId = _wdItem%100
    if _weekId == 0 then
        _weekId = const.DefaultHotPopIdx
    end
    -- 日热点刷新功能
    local _dayIds = {}
    if _time < GameLogic.getToday() then
        local stime = GameLogic.getSTime()
        local _randomLevel = self:getProperty(const.ProPopLevel) + const.FreePopIdx - 2

        -- 使用固定的随机序列随机日热点
        local _dayIdMap = {}
        local rd = RdUtil.new(_time + self.uid + GameLogic.getToday())
        while #_dayIds < 3 do
            local _id = rd:random(1, _randomLevel)
            if not _dayIdMap[_id] then
                _dayIdMap[_id] = true
                table.insert(_dayIds, _id)
            end
        end
        self:setProperty(const.ProNewBoxTime, stime)
        self:setProperty(const.ProNewBoxItems, _weekId + _dayIds[1] * 100 + _dayIds[2]*10000 + _dayIds[3]*1000000)
        self:addCmd({const.CmdRefreshNewBoxHot, stime, _dayIds[1], _dayIds[2], _dayIds[3]})
    else
        _dayIds[1] = math.floor(_wdItem/100) % 100
        _dayIds[2] = math.floor(_wdItem/10000) % 100
        _dayIds[3] = math.floor(_wdItem/1000000)
    end
    return _weekId, _dayIds
end

-- 膜拜次数的隔日刷新
function UContext:refreshWorshipTime()
    local lastWorTime = self:getProperty(const.ProHficTime)
    if lastWorTime < GameLogic.getToday() then
        local stime = GameLogic.getSTime()
        self:setProperty(const.ProHficNum, 0)
        self:setProperty(const.ProHficTime, stime)
    end
end

-- 免费的扫荡次数隔日刷新
function UContext:refreshSweepFree()
    local lastSweepTime = self:getProperty(const.ProPvjSwpTime)
    if lastSweepTime < GameLogic.getToday() then
        local stime = GameLogic.getSTime()
        local vipLv = self:getInfoItem(const.InfoVIPlv)
        self:setProperty(const.ProPvjSwpNum, 0)
        self:setProperty(const.ProPvjSwpTime, stime)
    end
end


return UContext
