local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local GameSetting = GMethod.loadScript("game.GameSetting")

local TalentMatch = class()

function TalentMatch:ctor(data)
    self.udata = data
    self._stages = {}
    self._matchs = {}
    self._matchCallbacks = {}
    self._ranks = {}
    self._stageRanks = {}
end

function TalentMatch:destroy()
    self.udata = nil
    self._stages = nil
    self._matchs = nil
    self._ranks = nil
    self._matchCallbacks = nil
end

function TalentMatch:getStage(stageId)
    if true then
        return 0
    end
    if not self._stages[1] then
        local v = self.udata:getProperty(const.ProTalentMatchStage)
        for i=1, 5 do
            local vm = v % 100
            self._stages[i] = vm
            v = (v - vm) / 100
        end
    end
    return self._stages[stageId] + 1
end

-- @brief 获取某场比赛的段位
function TalentMatch:getStageByMatch(matchId)
    if true then
        return 0
    end
    local mdata = SData.getData("tmInfos", matchId)
    if mdata and mdata["stage"] > 0 then
        return self:getStage(mdata["stage"])
    else
        return 0
    end
end

-- @brief 获取当前比赛
function TalentMatch:getMatchNow(matchId, callback)
    local match = self._matchs[matchId]
    local matchInfo = self:getMatchInfo(matchId)
    -- 如果不在比赛期间则直接返回
    if not matchInfo.inMatch then
        if callback then
            callback()
        end
        return
    end
    if not match or (match and matchInfo.stime > match.ltime) then
        if callback then
            if self._matchCallbacks[matchId] then
                table.insert(self._matchCallbacks[matchId], callback)
            else
                self._matchCallbacks[matchId] = {callback}
                if not GameNetwork.lockRequest() then
                    return
                end
                GameNetwork.request("tmdata", {aid=matchId}, self.onGetMatchData, self, matchId)
            end
        end
        return
    end
    if callback then
        callback(match)
    end
    return match
end

function TalentMatch:onGetMatchData(matchId, suc, data)
    local callbacks = self._matchCallbacks[matchId]
    self._matchCallbacks[matchId] = nil
    GameNetwork.unlockRequest()
    if suc then
        if not data[1] then
            self._matchs[matchId] = nil
        else
            self._matchs[matchId] = {
                ltime=data[1], triggleActId=data[2], avalue=data[3], avalue2=data[4],
                chance=data[5], group=data[6], aflag=data[7], actEndTime=data[8], actBuyMask=data[9]
            }
            -- TODO 感觉上在拉数据的时候顺便拉一下段位会比较好
            local p = self.udata:getProperty(const.ProTalentMatchStage)
            if data[10] and p ~= data[10] then
                self.udata:setProperty(const.ProTalentMatchStage, data[10])
                self._stages = {}
            end
        end
        for _, callback in ipairs(callbacks) do
            callback(self._matchs[matchId])
        end
    end
end

-- @brief 获取全局排行榜信息
function TalentMatch:getRankDataForStage(stageId, curStage, callback)
    local rdata = self._stageRanks[stageId]
    if rdata then
        rdata = rdata[curStage]
        if rdata then
            if rdata.expire > GameLogic.getSTime() then
                callback(rdata)
                return
            end
        end
    end
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("tmrankstage", {sid=stageId, slevel=curStage}, self.onGetStageRankData, self, {stageId, curStage, callback})
end

function TalentMatch:onGetStageRankData(rinfo, suc, data)
    GameNetwork.unlockRequest()
    if suc then
        local stageId = rinfo[1]
        local curStage = rinfo[2]
        local rdata = self._stageRanks[stageId]
        if not rdata then
            rdata = {}
            self._stageRanks[stageId] = rdata
        end
        rdata[curStage] = {expire = GameLogic.getSTime() + 3600}
        local newData = {}
        local newLine = true
        if data.openMax then
            rdata[curStage].openMax = data.openMax
            data = data.ranks
        end
        for i, nd in ipairs(data) do
            local nd2 = {
                rank=nd[1], id=nd[2], head=nd[3], level=nd[4], name=nd[5],
                score = nd[6], stage = nd[7]
            }
            if newLine and i ~= nd[1] then
                newLine = false
                nd2.isNewLine = true
            end
            table.insert(newData, nd2)
        end
        rdata[curStage].rankData = newData
        rinfo[3](rdata[curStage])
    end
end

-- @brief 获取排行榜信息
function TalentMatch:getMatchRank(matchId, groupId, callback)
    local matchInfo = self:getMatchInfo(matchId)
    if not self._ranks[matchId] or self._ranks[matchId].expire <= GameLogic.getSTime() then
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("tmrank", {aid=matchId, gid=groupId, stime=matchInfo.stime}, self.onGetRankData, self, {matchId, callback})
    else
        callback(self._ranks[matchId])
    end
end

local function sortRankNormal(a, b)
    if a.avalue ~= b.avalue then
        return a.avalue > b.avalue
    else
        return a.ltime < b.ltime
    end
end

function TalentMatch:onGetRankData(rinfo, suc, data)
    GameNetwork.unlockRequest()
    if suc then
        local newData = {}
        self._ranks[rinfo[1]] = {expire=GameLogic.getSTime() + 300}
        for i, nd in ipairs(data) do
            local nd2 = {
                rank=0, id=nd[1], head=nd[2], vip=nd[3], level=nd[4], name=nd[5],
                avalue = nd[6], avalue2 = nd[7], ltime = nd[8], rewardId=0
            }
            table.insert(newData, nd2)
        end
        self:reorderRanks(rinfo[1], newData)
        self._ranks[rinfo[1]].rankData = newData
        rinfo[2](self._ranks[rinfo[1]])
    end
end

function TalentMatch:reorderRanks(aid, newData)
    table.sort(newData, sortRankNormal)
    for i, nd in ipairs(newData) do
        nd.rank = i
        nd.rewardId = 0
        nd.rewards = nil
        if nd.id == self.udata.uid then
            self._ranks[aid].myRankData = nd
        end
    end
    local l = #newData
    local myStage = self:getStageByMatch(aid)
    local minfo = self:getMatchInfo(aid)
    if myStage > 0 then
        for rid, rdata in ipairs(SData.getData("tmRewards", aid * 100 + self:getStageByMatch(aid))) do
            local f, t = rdata.rankFrom, rdata.rankTo
            if f == 0 then
                f = 1
            end
            if t > l or t == 0 then
                t = l
            end
            local otherRwd
            local buffInfo = self.udata.activeData:getBuffInfo(const.ActTypeBuffTalentMatch, minfo.stime)
            if buffInfo[4] > 0 then
                local rwd = self.udata.activeData:getConfigableRwds(buffInfo[1], rid)
                if rwd then
                    otherRwd = rwd.items[1]
                end
            end
            for i=f, t do
                if newData[i].avalue > 0 then
                    newData[i].rewardId = rid
                    newData[i].rewards = rdata.rewards
                    newData[i].otherReward = otherRwd
                end
            end
        end
    end
end

-- @brief 获取某场比赛信息
function TalentMatch:getMatchInfo(matchId, stime)
    local adata = SData.getData("tmInfos", matchId)
    local ainfo = {aid = matchId, adata = adata}
    if not stime then
        stime = GameLogic.getSTime()
    end

    local astime = adata.startTime
    local aetime = adata.endTime
    if aetime > 0 and aetime <= stime and adata.disTime > 0 then
        local d = math.ceil((stime - aetime + 1) / adata.disTime)
        astime = astime + adata.disTime * d
        aetime = aetime + adata.disTime * d
        -- 如果有特殊间隔 做特殊处理
        if adata.disTime2 then
            local atmp = aetime
            for i=1, KTLen(adata.disTime2) do
                local atmp2 = aetime - (adata.disTime - adata.disTime2[i])
                if atmp2 > stime and atmp2 < atmp then
                    atmp = atmp2
                end
            end
            astime = astime - (aetime - atmp)
            aetime = atmp
        end
    end
    ainfo.stime = astime
    ainfo.etime = aetime
    ainfo.inMatch = (astime <= stime and (aetime == 0 or aetime > stime))
    ainfo.endMatch = (aetime > 0 and aetime < stime)
    return ainfo
end

-- @brief 获取所有比赛的信息
function TalentMatch:getAllMatchInfos()
    local ret = {}
    for aid, adata in pairs(SData.getData("tmInfos")) do
        local ainfo = self:getMatchInfo(aid)
        if adata.needLevel > self.udata.buildData:getTownLevel() then
            ainfo.bidEnter = true
        end
        if not ainfo.endMatch then
            table.insert(ret, ainfo)
        end
    end
    return ret
end

local _dir={0,1,1,2,2,3,4,4,5,5,6,6,7,7,8,8,9,10,10,11,11,12,12,13,14,14,15,15,16,16,17,17,18,18,19,20,20,21,21,22,22,23,24,24,25,25,26,26,27,27,28,28,29,30,30}

function TalentMatch:getDisplayTMPvhStage(displayId)
    return _dir[displayId]
end

-- @brief 修改达人赛进度
-- @params matchId, const.TalentMatchXXX
-- @params avalue 累计值，例如金币累计、僵尸击杀累计，主要用这个排序
-- @params avalue2 设置值，例如远征的怒气之类的，具体情况具体分析
function TalentMatch:updateTalentMatch(matchId, avalue, avalue2)
    local matchData = self:getMatchNow(matchId)
    if matchData then
        matchData.avalue = matchData.avalue + avalue
        -- 打过了才记
        if matchData.avalue > 0 then
            local atype = matchId
            if atype >= 104 then
                atype = 104
            end
            local matchInfo = self:getMatchInfo(matchId)
            if matchInfo.adata.stage > 0 then
                local sdata = GameSetting.getLocalData(self.udata.uid, "PreMatchInfo" .. atype) or {}
                if sdata[1] ~= matchInfo.etime then
                    sdata[1] = matchInfo.etime
                    sdata[2] = matchData.group
                    GameSetting.setLocalData(self.udata.uid, "PreMatchInfo" .. atype, sdata)
                end
            end
        end
        if avalue2 then
            matchData.avalue2 = avalue2
        end
        matchData.ltime = GameLogic.getSTime()
        -- 是否需要强制刷新排行榜呢？如果需要的话就直接删掉self._ranks[matchId]即可
        local rankData = self._ranks[matchId]
        if rankData and rankData.myRankData then
            rankData.myRankData.avalue = matchData.avalue
            rankData.myRankData.avalue2 = matchData.avalue2
            rankData.myRankData.ltime = matchData.ltime
            self:reorderRanks(matchId, rankData.rankData)
        end
    end
end

function TalentMatch:updateMatchPurchase(matchId, giftId)
    local matchData = self:getMatchNow(matchId)
    if matchData then
        local idx = giftId % 100
        matchData.actBuyMask = matchData.actBuyMask + 10^(idx-1)
    end
end

function TalentMatch:saveTalentMatchPvh()
    local npvh = self.udata.npvh
    local matchData = self:getMatchNow(const.TalentMatchPvh)
    if npvh and matchData then
        self:updateTalentMatch(const.TalentMatchPvh, npvh.stage-matchData.avalue, (npvh.finished and 0 or 1) + (npvh.inum * 10) + npvh.anger * 1000)
    end
end

function TalentMatch:getRecommendData(aid)
    local hlist3 = SData.getData("tmHeros", aid, 4).hids
    local _map = {}
    for i, hid in ipairs(hlist3) do
        _map[hid] = 1
    end
    local _map2 = {}
    local hasSSR = 0
    local hasSSR2 = 0
    for _, hero in pairs(self.udata.heroData:getAllHeros()) do
        if _map[hero.hid] then
            hasSSR = hasSSR + 1
            _map[hero.hid] = nil
        end
        _map2[hero.hid] = 1
        if hero.info.rating and hero.info.rating >= 4 then
            hasSSR2 = hasSSR2 + 1
        end
    end
    local showGroup
    if hasSSR == 0 then
        showGroup = 1
    elseif hasSSR < 3 and hasSSR2 < 5 then
        showGroup = 2
    elseif hasSSR < 5 then
        showGroup = 3
    else
        showGroup = 4
    end
    local showData = SData.getData("tmHeros", aid, showGroup)
    return showData, _map2
end

function TalentMatch:addTriggerGift(aid, actId)
    local matchData = self:getMatchNow(aid)
    local ainfo = self:getMatchInfo(aid)
    -- 没有礼包就触发一个
    if not actId then
        local showData, _map2 = self:getRecommendData(aid)
        local _randoms = {}
        local _randoms2 = {}
        for _, hid in ipairs(showData.hids) do
            local rating = SData.getData("hinfos", hid).rating
            -- local pack = SData.getData("tmPack", hid, 2)
            -- if pack and pack.isOpen == 1 and _map2[hid] then
            --     table.insert(_randoms2, hid)
            -- end
            local pack = SData.getData("tmPack", hid, 3)
            if pack and pack.isOpen == 1 then
                if not _map2[hid] then
                    table.insert(_randoms, hid)
                end
                table.insert(_randoms2, hid)
            end
        end
        local _rdType = 3
        if #_randoms == 0 then
            _randoms = _randoms2
        end
        local rlen = #_randoms
        local rnum = self.udata:nextRandom(rlen) + 1
        local randomHid = _randoms[rnum]
        matchData.triggleActId = randomHid * 10 + _rdType
        -- local actEndTime = GameLogic.getSTime() + SData.getData("tmPack", randomHid, _rdType).time
        -- if actEndTime > self.ainfo.etime then
        --     actEndTime = self.ainfo.etime
        -- end
        matchData.actEndTime = ainfo.etime
        matchData.actBuyMask = 0
        self.udata:addCmd({const.CmdTMGiftInit, rlen, rnum, aid, matchData.triggleActId, matchData.actEndTime})
    elseif matchData.actBuyMask == 0 then
        matchData.triggleActId = actId
        matchData.actBuyMask = matchData.actBuyMask + 100000000
        local hid = math.floor(actId / 10)
        local htype = actId % 10
        local sdata = SData.getData("tmPack", hid, htype)
        self.udata:changeRes(const.ResCrystal, -sdata.exchange)
        self.udata:addCmd({const.CmdTMGiftInit, 0, 0, aid, matchData.triggleActId, matchData.actEndTime})
    end
end

function TalentMatch:showRedTip(matchId)
    if not matchId then
        for i=101, 106 do
            if self:showRedTip(i) then
                return true
            end
        end
        return false
    end
    local matchInfo = self:getMatchInfo(matchId)
    local atype = matchId
    if atype >= 104 then
        atype = 104
    end
    local stime = GameLogic.getSTime()
    local sdata = GameSetting.getLocalData(self.udata.uid, "PreMatchInfo" .. atype) or {}
    if sdata[1] and sdata[1] + 10*60 <= stime then
        return true
    elseif sdata[1] then
        return false
    end
    sdata = GameSetting.getLocalData(self.udata.uid, "RedNums") or {}
    if matchInfo.inMatch and matchInfo.adata.needLevel <= self.udata.buildData:getTownLevel()
        and (sdata["TMMatch" .. matchId] or 0) < stime then
        return true
    else
        return false
    end
end

GMethod.loadScript("game.GameUI.TalentMatchUI")

return TalentMatch
