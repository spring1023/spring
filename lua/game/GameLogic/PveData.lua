local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local PveData = class()

function PveData:ctor(udata)
    self.inited = false
    self.udata = udata
end

function PveData:destroy()
    self.inited = nil
    self.udata = nil
end

function PveData:isInited()
    return self.inited
end

function PveData:loadPveData(data)
    self.inited = true
    self.etime = data.etime     -- 体力恢复时间
    self.pact = data.pact       -- 当前体力
    self.rtime = data.rtime     -- 刷新时间
    self.rcount = data.rcount   -- 购买次数
    self.stars = {}
    local maxIdx = 0
    for _,data in ipairs(data.allwar) do
        self.stars[data[1]] = data[2]
        if data[1]>maxIdx then
            maxIdx = data[1]
        end
    end
    for i=1, maxIdx do
        if not self.stars[i] then
            self.stars[i] = 3
        end
    end
    if maxIdx==0 or (self.stars[maxIdx]>0 and maxIdx<self:getPveMaxStage()) then
        maxIdx = maxIdx+1
    end
    self.maxIdx = maxIdx
end

function PveData:initBattleTime(stime)
    local h2 = 7200
    local battleTime = (stime-self.etime)/h2
    if battleTime<5 then
        self.battleTime = math.floor(battleTime)
    else
        self.battleTime = 5
    end
end

function PveData:getDetail(idx)
    local ret = {stage=idx, star=0, attacked=false, canAttack=(idx<=self.maxIdx)}
    if self.stars[idx] and (not GameLogic.useTalentMatch or self.stars[idx] > 0) then
        ret.attacked = true
        ret.star = self.stars[idx]
    end
    local data = SData.getData("pverewards", idx)
    if data then
        if data.story1 then
            ret.isSpecial = data.story2/2
        end
        if data.special then
            ret.special = data.special
        end
        if not ret.attacked then
            ret.story1 = data.story1
        end
        ret.box = data.box
        ret.gold = data.gold or 0
        ret.needlv = data.needlv
        if ret.star==3 then
            -- ret.fbeercup = 0
            -- ret.fexp = 0
            -- ret.fzhanhun = 0
            -- ret.isSpecial = nil
        else
            -- ret.fbeercup = data.fbeercup
            -- ret.fexp = data.fexp
            -- ret.fzhanhun = data.fzhanhun
            -- ret.slist = data.slist
            -- ret.story2 = data.story2
            ret.firstRwds = data.firstRwds
        end
    end
    return ret
end

function PveData:getPveMaxStage()
    return 180
end

function PveData:getMyMaxStage()
    return self.maxIdx
end

function PveData:getMyNowStage()
    return self.nowIdx or self.maxIdx
end
-- 剩余体力
function PveData:getBattleChance(stime)
    if not stime then
        stime = GameLogic.getSTime()
    end
    local chance = self.pact
    local t = stime-self.etime
    local max = self:getMaxChance()
    local h2 = const.PveTime
    if GameLogic.useTalentMatch then
        h2 = const.PveTime * 2
    end
    if chance < max then
        if t <= 0 then
            t = 0
        end
        chance = chance + math.floor(t/h2)
        if chance >= max then
            chance = max
        end
    end
    return chance
end
-- 增加体力
function PveData:changeChance(point, stime)
    if not stime then
        stime = GameLogic.getSTime()
    end
    local oldAp = self:getBattleChance(stime)
    local ap = oldAp + point
    local max = self:getMaxChance()
    local h2 = const.PveTime
    if GameLogic.useTalentMatch then
        h2 = const.PveTime * 2
    end
    if ap<0 then
        return false
    else
        if ap >= max then
            self.pact = ap
        else
            if oldAp >= max then
                self.etime = stime
                self.pact = ap
            else
                self.pact = self.pact + point
            end
        end
    end
end


-- function PveData:getNextTime(stime)
--     local h2 = const.PveTime
--     local chance = (stime-self.etime)/h2
--     if chance>=const.MaxPveChance then
--         return
--     end
--     return h2-(stime-self.etime)%h2
-- end

-- 购买过的次数，剩余购买次数，购买花费,增加次数
function PveData:getBuyedChance()
    local bchance = self.rcount
    local max = GameLogic.getUserContext():getVipPermission("pvebuy")[2]
    local data = SData.getData("buyChanceNum", 2)[bchance+1]
    -- local cost = const.PveChancePrice[bchance+1]{addNum=10,ctype=4,cvalue=100},
    local cost = data.cvalue
    local addNum = data.addNum
    return bchance, max-bchance, cost ,addNum
end

function PveData:resetChance()
    self.rcount = self.rcount+1
end

-- pve体力默认最大次数
function PveData:getMaxChance()
--需求变更，根据vip等级来觉得pve挑战最大值
    if GameLogic.useTalentMatch then
        return const.MaxPveChance / 2
    end
    return SData.getData("vippower",GameLogic.getUserContext():getInfoItem(const.InfoVIPlv)).pvetimes --const.MaxPveChance
end

-- 下次体力恢复时间
function PveData:getRecoveryTime( stime )
    if not stime then
        stime = GameLogic.getSTime()
    end
    if stime < self.etime then
        return 0
    end
    local h2 = const.PveTime
    if GameLogic.useTalentMatch then
        h2 = const.PveTime * 2
    end
    local recTime = (stime-self.etime)%h2
    return h2 - recTime
end

-- 免费扫荡次数--扫荡次数的计算走vip的接口，所以这里不用计算，重新分装一次就好
function PveData:getFreeSweepTimes()
    local context = GameLogic.getUserContext()
    local sweepVip = context:getVipPermission("pvesweep")[2]
    return sweepVip
end

return PveData
