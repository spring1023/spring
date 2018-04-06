local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local PvjData = class()
--因为要用到地图信息所以在此处加载
SData.setData("pvjmap", GMethod.loadConfig("configs/maps/PvjMap.json"))

--预先计算好所有僵尸来袭关卡的部件掉落情况
local pvjitem = SData.getData("pvjitem")
local partStages = {}
for sid, rewards in pairs(pvjitem) do
    for _, reward in pairs(rewards) do
        if reward.itemtype==1 then
            local pid = reward.itemid
            if not partStages[pid] then
                partStages[pid] = {}
            end
            partStages[pid][sid] = reward.itemnum
        end
    end
end

function PvjData:ctor(data)
    for k, v in pairs(data) do
        self[k] = v
    end
    local quests = self.quests
    if #quests<56 then
        quests[#quests+1] = {#quests,0,0,0,0,0}
    end
    local shops = {}
    for i,v in ipairs(data.shops) do
        shops[v[1]] = v
    end
    self.shops = shops
    local gift = {}
    for i,v in ipairs(data.gift) do
        gift[v[1]] = v
    end
    self.gift = gift
end

function PvjData:getStagesByEquipPart(pid)
    local stages = partStages[pid]
    local ret = {}
    if stages then
        for k, _ in pairs(stages) do
            local stageItem = {sid=k, name=Localize("dataPvjPassName" .. k)}
            local bigStage = math.ceil(k/8)
            local smallStage = (k-1)%8+1
            local mapData = SData.getData("pvjmap","guanKa",bigStage,smallStage)
            if smallStage==8 then
                stageItem.isBoss = true
            end
            stageItem.stype = 1
            stageItem.stage = mapData[3]
            print(k,bigStage,smallStage,mapData[3])
            if not self.quests[k] then
                stageItem.lock = true
            end
            table.insert(ret, stageItem)
        end
        GameLogic.mySort(ret, "sid")
    end
    return ret
end

function PvjData:getAP(stime)
    if not stime then
        stime = GameLogic.getSTime()
    end
    local actnum = self.actnum
    local t = stime-self.ctime
    if actnum<const.MaxPvjPoint then
        if t<=0 then
            t = 0
        end
        actnum = actnum + math.floor(t/const.PvjPointTime)
        if actnum>=const.MaxPvjPoint then
            actnum = const.MaxPvjPoint
        end
    end
    return actnum
end

function PvjData:changeAP(point, stime)
    if not stime then
        stime = GameLogic.getSTime()
    end
    local oldAp = self:getAP(stime)
    local ap = oldAp + point
    if ap<0 then
        return false
    else
        if ap>=const.MaxPvjPoint then
            self.actnum = ap
        else
            if oldAp>=const.MaxPvjPoint then
                self.ctime = stime
                self.actnum = ap
            else
                self.actnum = self.actnum+point
            end
        end
    end
end

-- @brief 根据攻击模式和关卡，计算对应的扫荡次数
-- @params stageId 关卡ID = （大关ID-1）* 8 + 小关ID
-- @return 是否BOSS关卡, 是否可扫荡, 单关体力, 剩余次数
-- @return 剩余免费次数, 基础次数, 体力次数
function PvjData:computeBattleInfo(stageId)
    local isBossStage = (stageId % 8) == 0
    local costBase = const.MaxPvjCommonNum
    if isBossStage then
        costBase = const.MaxPvjBossNum
    end

    --僵尸来袭消耗减半buff start
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffPvjCostReduce)
    if buffInfo[4]~=0 then
        costBase = math.floor(costBase*(buffInfo[4]/100))
    end
    --僵尸来袭消耗减半buff end
    local context = GameLogic.getUserContext()
    -- 普通关卡最多能一次性打10次，BOSS关卡每天只能打3次
    local baseChance = 10
    if isBossStage then
        baseChance = 3 - self.quests[stageId][4]
    end
    local leftChance = baseChance
    if leftChance == 0 then
        leftChance = 3
    end
    -- 体力能打几次
    local maxAPChance = math.floor(self:getAP() / costBase)
    if maxAPChance > 0 and maxAPChance < leftChance then
        leftChance = maxAPChance
    end
    -- 最大免费次数 - 今日用过的免费次数
    local maxFreeChance = SData.getData("vippower", context:getInfoItem(const.InfoVIPlv)).pvjcr
    if context:getProperty(const.ProPvjSwpTime) < GameLogic.getToday() then
        context:setProperty(const.ProPvjSwpTime, GameLogic.getSTime())
        context:setProperty(const.ProPvjSwpNum, 0)
    end
    maxFreeChance = maxFreeChance - context:getProperty(const.ProPvjSwpNum)
    -- 免费次数按剩余免费次数算，付费按宝石数算
    if maxFreeChance > 0 then
        if maxFreeChance < leftChance then
            leftChance = maxFreeChance
        end
    else
        maxFreeChance = 0
        local maxCrystalChance = math.floor(context:getRes(const.ResCrystal) / const.PvjSwpBuyNeed)
        if maxCrystalChance > 0 and maxCrystalChance < leftChance then
            leftChance = maxCrystalChance
        end
    end
    return isBossStage, self.quests[stageId][2] >= 3, costBase, leftChance,
        maxFreeChance, baseChance, maxAPChance
end

return PvjData
