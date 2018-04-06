local const = GMethod.loadScript("game.GameLogic.Const")

local PvhData = class()

function PvhData:ctor(data)
    self.anger = data.sp/10
    self.maxLv = data.maxlv
    self.finished = data.exits==1
    self.inum = data.inum
    self.heroLv = data.hlv
    self.stage = data.pid
    self.startTime = data.htime
    self.hnum = data.hnum
    self.items = {}
end

function PvhData:startNewBattle(stime)
    self.finished = false
    self.startTime = stime
    self.hnum = self.hnum+1
    self.stage = 0
    self.inum = 0
    self.items = {}
    self.anger = const.InitPvhAnger
end

function PvhData:endBattle()
    self.finished = true
    self.stage = 0
    self.inum = 0
    self.items = {}
end
function PvhData:changeAnger(anger)
    self.anger = anger/10
end
function PvhData:isInBattle()
    return self.startTime>0 and not self.finished
end

function PvhData:isInNightmareBattle()
    return not self.finished
end

function PvhData:getStoreItems(idx)
    return self.items[idx]
end

function PvhData:setStoreItems(idx, data)
    local data2 = {}
    for _, d in ipairs(data) do
        table.insert(data2, {itemType=d[1], itemId=d[2], itemNum=d[3], ctype=d[4], cvalue=d[5], buyed=d[6]==1, storeIdx=d[7], itemIdx=d[8]})
    end
    self.items[idx] = data2
end

function PvhData:refreshToday(stime)
    if not self.today then
        self.today = const.InitTime
    end
    while (self.today+86400)<stime do
        self.today = self.today+86400
    end
    return self.today
end

function PvhData:getChance(stime)
    self:refreshToday(stime)
    local num = GameLogic.getUserContext():getVipPermission("pvhs")[2]
    local maxTimes = const.PvhMaxTimes+num
    if self.startTime<self.today then
        self.hnum = 0
    end
    return maxTimes-self.hnum
end

function PvhData:getMaxChance()
    local num = GameLogic.getUserContext():getVipPermission("pvhs")[2]
    local maxTimes = const.PvhMaxTimes+num
    return maxTimes
end

function PvhData:getInspireData(single)
    local inum = self.inum
    local cost = const.PriceInspire
    if inum>=const.MaxInspireNum then
        cost = 0
    end
    local percent = inum*const.InspireEffect
    if single then
        return percent
    else
        return inum, cost, percent
    end
end

return PvhData
