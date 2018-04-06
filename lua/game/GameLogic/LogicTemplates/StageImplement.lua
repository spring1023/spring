local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local _set = Base.sset
local _setReader = Base.ssetReader

-- 关卡非通用实现
local StageImplement = {}
Base.registerImplement("Stage", StageImplement)

function StageImplement:_static_load(config)
    _set(self, "stageMaxStar", config["stageMaxStar"])
    _setReader(self, "stageDataTable", config["stageData"])
    _setReader(self, "stageRewardTable", config["stageReward"])
    self.stageStartIdx = config.stageStartIdx or 1
    self.stageMaxIdx = config.stageMaxIdx
    if not self.stageMaxIdx then
        local max = self.stageStartIdx
        while self.stageDataTable:getItem(max) do
            max = max + 1
        end
        self.stageMaxIdx = max - 1
    end
end

function StageImplement:getStageCount()
    return self.stageMaxIdx - self.stageStartIdx + 1
end

function StageImplement:getStageStaticInfo(stageId)
    local realStageId = stageId + self.stageStartIdx - 1
    local ret = self.stageDataTable:getReadItem(realStageId, 1)
    return {id=stageId, bg=ret["chapterBg"], name=ret["chapterName"]}
end

function StageImplement:getLevelStaticInfo(stageId, levelId)
    local realStageId = stageId + self.stageStartIdx - 1
    return self.stageDataTable:getReadItem(realStageId, levelId)
end

function StageImplement:loadStageData(stageDatas, levelDatas)
    self._myStages = {}
    local _maxStage = 0
    for _, stage in ipairs(stageDatas) do
        if stage[1] > _maxStage and stage[2] > 0 then
            _maxStage = stage[1]
        end
        local stageData = {maxProcess=stage[2], totalStar=stage[3], box={}, levels={}}
        self._myStages[stage[1]] = stageData
        local mask = stage[4]
        local idx = 1
        while mask > 0 do
            stageData.box[idx] = mask%2
            mask = math.floor(mask/2)
            idx = idx + 1
        end
    end
    for _, level in ipairs(levelDatas) do
        local stageIdx = level[1]
        local levelIdx = level[2]
        self._myStages[stageIdx].levels[levelIdx] = {maxStar=level[3], attackedCount=level[4], buyedChance=level[5], buyedTime=level[6]}
        -- 兼容后台已计算好的值
        if not self._myStages[stageIdx].levels[levelIdx].buyedTime or self._myStages[stageIdx].levels[levelIdx].buyedTime == 0 then
            self._myStages[stageIdx].levels[levelIdx].buyedTime = GameLogic.getSTime()
        end
    end
    self._maxStageIdx = _maxStage
end

-- checkLevel表示把等级考虑进去
function StageImplement:getMaxProcess(checkLevel)
    local stageIdx = self._maxStageIdx
    local _curStage = self._myStages[stageIdx]
    local levelIdx = 0
    if _curStage then
        levelIdx = _curStage.maxProcess
    end
    --测试下一关是否解锁
    local stageOff = self.stageStartIdx - 1
    local tmpStageIdx = stageIdx
    local tmpLevelIdx = levelIdx + 1
    local nextStage = self.stageDataTable:getReadItem(tmpStageIdx + stageOff, tmpLevelIdx)
    if not nextStage or nextStage.type == 4 then
        tmpStageIdx = stageIdx + 1
        tmpLevelIdx = 1
        nextStage = self.stageDataTable:getReadItem(tmpStageIdx + stageOff, tmpLevelIdx)
    end
    if nextStage and not ( checkLevel and self._weak_ref.context:checkLimit({level=nextStage["needLevel"]})) then
        stageIdx = tmpStageIdx
        levelIdx = tmpLevelIdx
    end
    return stageIdx, levelIdx
end

-- 获取关卡通用数据
function StageImplement:getStageUserData(stageId)
    local realStageId = stageId + self.stageStartIdx - 1
    local _curStage = self._myStages[stageId]
    local ret = {totalStar=0, maxStar=0, levels={}, rewards={}}
    if _curStage then
        ret.totalStar = _curStage.totalStar
    end
    local unlockStageIdx, unlockLevelIdx = self:getMaxProcess()
    for levelId, level in pairs(self.stageDataTable:getItem(realStageId)) do
        local levelData = self.stageDataTable:readItem(level)
        levelData.chapter = stageId
        levelData.id = levelId
        levelData.star = 0
        levelData.locked = true
        levelData.levelLocked = false
        ret.levels[levelId] = levelData
        if self._weak_ref.context:checkLimit({level=levelData.needLevel}) then
            levelData.levelLocked = true
        end
        if levelData.type == 1 then
            if _curStage and _curStage.maxProcess >= levelId then
                levelData.star = 3
            end
        else
            if _curStage and _curStage.levels[levelId] then
                levelData.star = _curStage.levels[levelId].maxStar
                levelData.attackedCount = _curStage.levels[levelId].attackedCount
                levelData.buyedChance = _curStage.levels[levelId].buyedChance
                levelData.buyedTime = _curStage.levels[levelId].buyedTime
            end
            ret.maxStar = ret.maxStar + 3
        end
        if levelData.type == 4 then
            levelData.locked = unlockStageIdx < stageId or (unlockStageIdx == stageId and levelData["needStar"] > ret.totalStar)
        else
            levelData.locked = unlockStageIdx < stageId or (unlockStageIdx == stageId and unlockLevelIdx < levelId)
        end
    end
    for rwdId, rwd in pairs(self.stageRewardTable:getItem(realStageId)) do
        local rewardData = self.stageRewardTable:readItem(rwd)
        rewardData["chapter"] = stageId
        rewardData["id"] = rwdId
        rewardData["state"] = 0
        ret.rewards[rwdId] = rewardData
        if rewardData.needStar <= ret.totalStar then
            if _curStage and (_curStage.box[rwdId] or 0) > 0 then
                ret.rewards[rwdId].state = 2
            else
                ret.rewards[rwdId].state = 1
            end
        end
    end
    return ret
end

-- 获取单关卡通用数据
function StageImplement:getLevelUserData(stageIdx, levelIdx)
    local _curStage = self:getInnerStage(stageIdx)
    local unlockStageIdx, unlockLevelIdx = self:getMaxProcess()
    local sinfo = self:getLevelStaticInfo(stageIdx, levelIdx)

    sinfo.chapter = stageIdx
    sinfo.id = levelIdx
    if self._weak_ref.context:checkLimit({level=sinfo.needLevel}) then
        sinfo.levelLocked = true
    end

    sinfo.star = 0
    if sinfo.type == 1 then
        if _curStage.maxProcess >= levelIdx then
            sinfo.star = 3
        end
    else
        if _curStage.levels[levelIdx] then
            sinfo.star = _curStage.levels[levelIdx].maxStar
            sinfo.attackedCount = _curStage.levels[levelIdx].attackedCount
            sinfo.buyedChance = _curStage.levels[levelIdx].buyedChance
            sinfo.buyedTime = _curStage.levels[levelIdx].buyedTime
        end
    end
    if sinfo.type == 4 then
        sinfo.locked = unlockStageIdx < stageIdx or (unlockStageIdx == stageIdx and sinfo["needStar"] > _curStage.totalStar)
    else
        sinfo.locked = unlockStageIdx < stageIdx or (unlockStageIdx == stageIdx and unlockLevelIdx < levelIdx)
    end
    return sinfo
end

function StageImplement:getInnerStage(stageId)
    local _stage = self._myStages[stageId]
    if not _stage then
        _stage = {maxProcess=0, totalStar=0, box={}, levels={}}
        self._myStages[stageId] = _stage
    end
    return _stage
end

function StageImplement:getInnerLevel(stageId, levelId, stime)
    local realStageId = stageId + self.stageStartIdx - 1
    local levelSetting = self.stageDataTable:getReadItem(realStageId, levelId)
    if levelSetting and levelSetting["type"] > 1 then
        local _stage = self:getInnerStage(stageId)
        local _level = _stage.levels[levelId]
        if not _level then
            _level = {maxStar=0, attackedCount=0, buyedChance=0, buyedTime=0}
            _stage.levels[levelId] = _level
        end
        if levelSetting["type"] >= 3 then
            if Base.checkDailyTime(_level.buyedTime, stime) then
                _level.attackedCount = 0
                _level.buyedChance = 0
            end
            _level.maxChance = levelSetting["maxChance"]
        end
        return _level
    end
end

function StageImplement:setMaxProcess(stageId, levelId)
    local _stage = self:getInnerStage(stageId)
    if levelId > _stage.maxProcess then
        _stage.maxProcess = levelId
        if self._maxStageIdx < stageId then
            self._maxStageIdx = stageId
        end
    end
end

function StageImplement:refreshMaxStar(stageId, levelId, star, stime)
    local _level = self:getInnerLevel(stageId, levelId, stime)
    if _level then
        if _level.maxStar > 0 then
            _level.attackedCount = _level.attackedCount + 1
        end
        if star > _level.maxStar then
            local _stage = self:getInnerStage(stageId)
            _stage.totalStar = _stage.totalStar + (star - _level.maxStar)
            _level.maxStar = star
        end
        _level.buyedTime = stime
    end
end

function StageImplement:getStageReward(stageId, rwdId)
    local _stage = self:getInnerStage(stageId)
    _stage.box[rwdId] = 1
    local realStageId = stageId + self.stageStartIdx - 1
    local rwd = self.stageRewardTable:getReadItem(realStageId, rwdId)
    GameLogic.addRewards(rwd["rewards"])
end

function StageImplement:getLevelChance(stageIdx, levelIdx, stime)
    if not stime then
        stime = GameLogic.getSTime()
    end
    local _level = self:getInnerLevel(stageIdx, levelIdx, stime)
    if _level and _level.maxChance then
        return _level.maxChance + _level.buyedChance - _level.attackedCount, _level.maxChance
    end
end

-- 检查关卡是否未被攻打过
function StageImplement:isNewLevel(stageIdx, levelIdx)
    local _stage = self:getInnerStage(stageIdx)
    local realStageId = stageIdx + self.stageStartIdx - 1
    local levelSetting = self.stageDataTable:getReadItem(realStageId, levelIdx)
    if levelSetting.type == 1 then
        return _stage.maxProcess < levelIdx
    else
        return (not _stage.levels[levelIdx]) or _stage.levels[levelIdx].maxStar == 0
    end
end

function StageImplement:getRedPointNum(stageIdx)
    local _stage = self:getInnerStage(stageIdx)
    local count = 0

    local realStageId = stageIdx + self.stageStartIdx - 1
    for rwdId, rwd in pairs(self.stageRewardTable:getItem(realStageId)) do
        local rewardData = self.stageRewardTable:readItem(rwd)
        if rewardData.needStar <= _stage.totalStar then
            if (_stage.box[rwdId] or 0) == 0 then
                count = count + 1
            end
        end
    end
    return count
end
