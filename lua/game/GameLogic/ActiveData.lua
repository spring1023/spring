


--每日任务ID
--1，分享游戏  2，挑战pvj  3，挑战pvt  4，月卡  7，挑战upve  8，挑战pvp  9，掠夺金币  10远征  11竞技场 12每日登陆  13每日福利任务

--限时活动
--101每日寻宝  102季度礼包  103抽取英雄 104英雄礼包  105拜访英雄  106限时兑换 108冲榜活动 109内测充值返还活动 110评论有奖

--热门
--51首充  52加入联盟  53联盟战  54使用3连抽10次  56绑定账号  57推广码  58邀请好友开宝箱  59互赠黑晶 60觉醒活动

--300:情人节活动
--子活动类型
--1001:购买特定数量的特定礼包,1002:购买特定数量的特定道具,1003:竞技场胜利特定场次
--1004:掠夺战胜利特定场次,1005:闯关战胜利特定场次,1006:完成特定的子活动集合

local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local gameSetting=GMethod.loadScript("game.GameSetting")
local ActiveData = class()

function ActiveData:ctor()
    self.dhActive = {}      --所有
    self.limitActive = {}   --限时
    self.dailyData = {}     --每日 1-50
    self.hotData = {}       --热门 51-100

    -- 可配置化活动
    self._configableActs = {}
    self._configableRwds = {}
    self._configableTriggles = {}
    self._configableGroups = {}
    self._configableGroupsByType = {}
    self._monitors = {}
    self._myRecords = {}
    self._myRwds = {}
    self._myTriggles = {}

    self._myAcidStat = {}
end

function ActiveData:loadData(data)
    local params = {}
    for i,v in ipairs(data.actinfo) do
        params[v[2]] = v
    end
    self.dhActive = params
    self:loadWelfare(data.dailytask)
    self:testOther()
    self:initHotData()
    self:initDailyData()
end

-- 根据用户数据加载记录和奖励
function ActiveData:loadConfigableRecords(records, rewards,triggles)
    local _records = {}
    local _rewards = {}
    local _triggles = {}
    local temp
    if records then
        for _, record in ipairs(records) do
            temp = _records[record[1]]
            if not temp then
                temp = {}
                _records[record[1]] = temp
            end
            temp[record[2]] = {record[3], record[4]}
        end
    end
    if rewards then
        for _, reward in ipairs(rewards) do
            temp = _rewards[reward[1]]
            if not temp then
                temp = {}
                _rewards[reward[1]] = temp
            end
            temp[reward[2]] = {reward[3], reward[4]}
        end
    end
    if triggles then
        local _actTriggles = self:getConfigableTriggles()
        for _,data in pairs(triggles) do
            local dTrigger = _actTriggles[data[1]]
            if dTrigger and next(dTrigger) then
                dTrigger.actStartTime = data[3]
                dTrigger.actEndTime = data[4]
                dTrigger.actExtends = data[5]
                self:copyTriggerToActs(self:deleteTrigger(dTrigger,false))
            end
        end
    end

    self._myRecords = _records
    self._myRwds = _rewards
    self:refreshLoginAct()
end

function ActiveData:deleteTrigger(tiggers,ttype)
    local data = {}
    if tiggers and next(tiggers) then
        for k,v in pairs(tiggers) do
            if k~="triggles" then
                data[k] = v
            end
        end
        if ttype then
            data.actStartTime = GameLogic.getSTime()
            data.actEndTime = GameLogic.getSTime()+tiggers.triggles.actLimitTime
            data.actExtends = {}
            GameLogic.getUserContext():addCmd({const.CmdActTriggle,data.actId,data.actId,data.actStartTime,data.actEndTime,data.actExtends})
        end
    end
    return data
end

function ActiveData:copyTriggerToActs(tiggers)
    --这里还要确定添加的字段
    local myTiggers = tiggers
    local data = {}
    if not self._configableActs[myTiggers.actId] and next(myTiggers) then
        table.insert(data,myTiggers)
        self:initConfigable(data)
    end
end

function ActiveData:fixActTime(act)
    local a1 = act.actStartTime
    local a2 = act.actServerStartTime
    if a2 then
        a2 = a2 + self.serverInit
        if not a1 then
            a1 = a2
        else
            local rule = act.actSelectRule or "max"
            if rule == "max" then
                if a1 < a2 then
                    a1 = a2
                end
            else
                if a1 > a2 then
                    a1 = a2
                end
            end
        end
    elseif not a1 then
        a1 = self.serverInit
    end
    if act.actFixTime then
        local fixTime = act.actFixTime
        if a1 < fixTime[1] then
            a1 = fixTime[1]
        end
        a2 = fixTime[1] + math.floor((time1-fixTime[1])/fixTime[2])*fixTime[2] + fixTime[3]
        if a2 >= a1 then
            a1 = a2
        else
            a1 = a2 + fixTime[2]
        end
    end
    act.actStartTime = a1
    if act.actSustainTime and not act.actRegSplit then
        act.actEndTime = a1 + act.actSustainTime
    elseif act.actServerEndTime then
        act.actEndTime = act.actServerEndTime + self.serverInit
    end
end

--将act的映射提出来了，触发型活动可以共同复用
function ActiveData:initConfigable(data)
    local _tempActMap
    local _tempActBuff
    local allActs = data
    if allActs then
        for _, act in ipairs(allActs) do
            self:fixActTime(act)
            if act.actRegTime then
                act.actEndTime = GameLogic.getUserContext():getInfoItem(const.InfoRegTime) + act.actRegTime
            end
            local skip = not self:checkVisible(act.actId, act)
            if not skip then
                if act.actRegSplit then
                    local rtime = GameLogic.getUserContext():getInfoItem(const.InfoRegTime)
                    if rtime < act.actStartTime or (act.actEndTime > 0 and rtime > act.actEndTime) then
                        skip = true
                    else
                        local atime = rtime - act.actStartTime
                        atime = math.floor(atime/act.actRegSplit) * act.actRegSplit + act.actStartTime
                        act.actRankIdx = math.floor((atime - act.actStartTime) / act.actRegSplit) % math.floor(act.actSustainTime / act.actRegSplit + 2)
                        act.actStartTime = atime
                        act.actEndTime = atime + act.actSustainTime
                    end
                end
            end
            if not skip then
                self._configableActs[act.actId] = act
                _tempActMap = {}
                _tempActBuff = {}
                for _, rwdId in ipairs(act.rwds) do
                    local rwd = self._configableRwds[rwdId]
                    if rwd then
                        for _, condition in ipairs(rwd.conditions) do
                            if condition[1] >= 1100 and condition[1] < 1150 then
                                if not self._configBuffs[condition[1]] then
                                    self._configBuffs[condition[1]] = {}
                                end
                                if not _tempActBuff[condition[1]] then
                                    _tempActBuff[condition[1]] = 1
                                    table.insert(self._configBuffs[condition[1]], {act.actId, condition[2]})
                                end
                            end
                            if not self._monitors[condition[1]] then
                                self._monitors[condition[1]] = {}
                            end
                            if not _tempActMap[condition[1]] then
                                _tempActMap[condition[1]] = 1
                                table.insert(self._monitors[condition[1]], act.actId)
                            end
                        end
                    else
                        print ("error!", rwdId)
                    end
                end
            end
        end
    end
end


-- 先按照原本的格式简单做一下修改，参数可读，数据配置为1；
-- 之后尽量做成可以直接用工具导出的格式
function ActiveData:initConfigableActs(actsData)
    local myActs = {}
    self._configableActs = myActs
    local myRwds = {}
    self._configableRwds = myRwds
    local myTriggles = {}
    self._configableTriggles =myTriggles
    local myConditions = {}
    self._monitors = myConditions
    local myBuffs = {}
    self._configBuffs = myBuffs
    if actsData then
        if actsData.dataVersion < 1 then
            local allRwds = actsData.rwds
            if allRwds then
                for _, rwd in ipairs(allRwds) do
                    myRwds[rwd.rwdId] = rwd
                end
            end

            local allTriggles = actsData.triggles
            if allTriggles then
                for _, trig in ipairs(allTriggles) do
                    self:fixActTime(trig)
                    local skip = not self:checkVisible(trig.actId, trig)
                    if not skip then
                        local conditions = trig.triggles and trig.triggles.conditions
                        if conditions and type(conditions) == "table" and type(conditions[1]) == "table" then
                            myTriggles[trig.actId] = trig
                            -- 特别的给自己加一份触发活动条件索引表，免得遍历
                            local taid = conditions[1][1]
                            if taid >= 20000 then
                                if not self._myTriggles[taid] then
                                    self._myTriggles[taid] = {}
                                end
                                table.insert(self._myTriggles[taid], trig)
                            end
                        end
                    end
                end
            end

            local allActs = actsData.acts
            if allActs then
                self:initConfigable(allActs)
            end

            -- 活动“组”
            local actGroups = actsData.actGroups
            self:initConfigableActGroups(actGroups)
        end
    end
end

-- @brief 初始化默认组
function ActiveData:initConfigableActGroups(actGroups)
    if actGroups then
        for _, group in ipairs(actGroups) do
            if group.menuActId then
                self._configableGroups[group.menuActId] = group
            end
            self._configableGroupsByType[group.actGroup] = group
        end
    end
    -- 默认增加40000 普通活动组
    if not self._configableGroups[40000] then
        self._configableGroups[40000] = {actGroup=1, menuOrder=1, menuActId=40000,
            menuIcon="images/otherIcon/iconActivity40000.png", menuIconEffect=1,
            menuIconSize={150,150}, hiddenTime=true}
        self._configableGroupsByType[1] = self._configableGroups[40000]
    end
    -- 默认增加50000 触发活动组
    if not self._configableGroups[50000] then
        self._configableGroups[50000] = {actGroup=2, menuOrder=2, menuActId=50000,
            menuIcon="images/otherIcon/iconActivity50000.png", menuIconEffect=1,
            menuIconSize={150,150}}
        self._configableGroupsByType[2] = self._configableGroups[50000]
    end
end

-- @brief 获取活动组
function ActiveData:getConfigableGroups()
    return self._configableGroups
end

-- @brief 获取活动组-按groupType取的那种
function ActiveData:getConfigableGroupsByType()
    return self._configableGroupsByType
end

function ActiveData:getConfigableTriggles()
    return self._configableTriggles
end

-- 获取所有可配置的活动信息，此时会对所有会循环的活动进行时间刷新
function ActiveData:getConfigableActs()
    local stime = GameLogic.getSTime()
    for actId, act in pairs(self._configableActs) do
        if act.actRollTime then
            while act.actEndTime <= stime and act.actEndTime < act.actRollMax do
                act.actStartTime = act.actStartTime + act.actRollTime
                act.actEndTime = act.actEndTime + act.actRollTime
                if act.actEndTime > act.actRollMax then
                    act.actEndTime = act.actRollMax
                end
                if act.actRollAutoIncr then
                    act.actId = act.actId + 1
                end
            end
            act.actRealId = actId
        end
    end
    return self._configableActs
end

-- 显示在排行榜的活动 actType = 5
function ActiveData:getRankData()
    local allActs = self:getConfigableActs()
    local actRank = {}
    for aid, act in pairs(allActs) do
        if act.actType == 55 and self:checkActState(act.actRealId or act.actId) ~= GameLogic.States.Close
            and self:checkVisible(act.actRealId or act.actId, act) then
            table.insert(actRank, {actId=aid, actData=act, __order=act.actOrder or 10000})
        end
    end
    GameLogic.mySort(actRank, "__order")
    return actRank
end

-- 获取可配置的奖励数值
function ActiveData:getConfigableRwds(actId, rwdIdx)
    local act = self._configableActs[actId]
    if act then
        return self._configableRwds[act.rwds[rwdIdx]]
    end
end

-- 获取活动进度
function ActiveData:getActRecord(actId, conditionId)
    local act = self._configableActs[actId]
    if not act then
        return {0, 0}
    end
    actId = act.actId
    local record = self._myRecords[actId]
    if not record then
        record = {}
        self._myRecords[actId] = record
    end
    if not record[conditionId] then
        record[conditionId] = {0, 0}
    end
    record = record[conditionId]
    if record[2] < act.actStartTime then
        record[1] = 0
        record[2] = 0
    end
    if conditionId == const.ActTypeContinuousBuy and record[1]>0 then
        local dayDis = math.floor((GameLogic.getSTime()-const.InitTime)/86400) - math.floor((record[2] - const.InitTime)/86400)
        if dayDis>=2 then
            record[1] = 0
        end
    end
    return record
end

-- 获取活动奖励
function ActiveData:getActRwd(actId, rwdId)
    local act = self._configableActs[actId]
    if not act then
        return {0, 0}
    end
    actId = act.actId
    local rwd = self._myRwds[actId]
    if not rwd then
        rwd = {}
        self._myRwds[actId] = rwd
    end
    if not rwd[rwdId] then
        rwd[rwdId] = {0, 0}
    end
    rwd = rwd[rwdId]
    if rwd[2] < act.actStartTime then
        rwd[1] = 0
        rwd[2] = 0
    end
    return rwd
end

function ActiveData:setMultiControlGift(actId, rwdIdx)
    local rwdbase = self:getConfigableRwds(actId, 1)
    local rwd = self:getActRwd(actId, rwdbase.rwdId)
    if rwd[1] == 0 then
        local rwdcost = self:getConfigableRwds(actId, rwdIdx)
        GameLogic.getUserContext():changeProperty(const.ProCrystal, -rwdcost.exchange)
        GameLogic.getUserContext():addCmd({const.CmdActExchange, actId, rwdIdx})
        rwd[1] = (rwdIdx+1)/3
        rwd[2] = GameLogic.getSTime()
    end
end

-- 检查活动状态
function ActiveData:checkActState(actId)
    local act = self._configableActs[actId]
    if not act then
        return GameLogic.States.Close
    end
    local stime = GameLogic.getSTime()
    if (act.actPreTime and act.actPreTime > stime or act.actStartTime > stime) or (act.actEndTime ~= 0 and act.actEndTime <= stime) then
        return GameLogic.States.Close
    elseif act.actStartTime > stime then
        return GameLogic.States.NotOpen
    else
        local rwds = act.rwds
        for rwdIdx, rwdId in ipairs(rwds) do
            local rwd = self:getConfigableRwds(actId, rwdIdx)
            if rwd.multiControl then
                local rewardIdx = self:getActRwd(actId, rwdId)[1]
                if rewardIdx == 0 then
                    rewardIdx = 1
                end
                for rwdIdx2 = (rewardIdx * 3 - 1), (rewardIdx * 3 + 1) do
                    if self:checkActRewardState(actId, rwdIdx2) ~= GameLogic.States.Close then
                        return GameLogic.States.Open
                    end
                end
                break
            end
            if self:checkActRewardState(actId, rwdIdx) ~= GameLogic.States.Close then
                return GameLogic.States.Open
            end
        end
        if act.autoClose then
            return GameLogic.States.Close
        else
            return GameLogic.States.Finished
        end
    end
end

-- 检查奖励状态
function ActiveData:checkActRewardState(actId, rwdIdx)
    local act = self._configableActs[actId]
    if act then
        local rwdId = act.rwds[rwdIdx]
        local rwd = self._configableRwds[rwdId]
        if rwd then
            local reward = self:getActRwd(actId, rwdId)
            if reward[1] >= (rwd.max or 1) then
                return GameLogic.States.Close
            else
                local conditions = rwd.conditions
                if rwd.atype == const.ActActionContinuous then
                    local record1 = self:getActRecord(actId, conditions[1][1])
                    local record2 = self:getActRecord(actId, const.ActTypeContinuousBuy)
                    local canGetNum = math.floor((record1[1] % (10^conditions[2][2])) / (10^(conditions[2][2]-1)))
                    canGetNum = canGetNum - reward[1]
                    return canGetNum > 0 and GameLogic.States.Finished or GameLogic.States.Open
                elseif rwd.atype == const.ActActionSpecial then
                    -- if self:getActRecord(actId, conditions[1][1])[1]
                    return GameLogic.States.Open
                else
                    for _, condition in ipairs(conditions) do
                        local crecord = self:getActRecord(actId, condition[1])
                        if type(condition[2]) == "table" then
                            return GameLogic.States.Open
                        elseif condition[3] then
                            if condition[1]>4000 then
                                if condition[3] == const.ActsConditionTime then
                                    local rTime = self:getActRecord(actId, condition[1])[2]
                                    local dayDis = math.floor((GameLogic.getSTime()-const.InitTime)/86400) - math.floor((rTime - const.InitTime)/86400)
                                    local canGetNum = crecord[1] - condition[2]
                                    if canGetNum>=0 and dayDis>0 then
                                        return GameLogic.States.Finished
                                    else
                                        return GameLogic.States.Open
                                    end
                                end
                            end
                            if bit.band(crecord[1], condition[3]) < condition[3] then
                                return GameLogic.States.Open
                            end
                        elseif crecord[1] < condition[2] then
                            return GameLogic.States.Open
                        end
                    end
                    if rwd.atype == const.ActActionBuy and conditions[1][2] == 1 then
                        if reward[1] >= self:getActRecord(actId, conditions[1][1])[1] then
                            return GameLogic.States.Open
                        end
                    end
                end
                return GameLogic.States.Finished
            end
        end
    end
    return GameLogic.States.Close
end

-- 特别的，检查每日限购一次礼包的限制
function ActiveData:checkPurchaseLimit(actId, rwdIdx)
    local act = self._configableActs[actId]
    if act then
        local rwdId = act.rwds[rwdIdx]
        local rwd = self._configableRwds[rwdId]
        if rwd then
            local reward = self:getActRwd(actId, rwdId)
            if reward[1] >= (rwd.max or 1) then
                return true
            else
                local conditions = rwd.conditions
                if rwd.atype == const.ActActionBuy and conditions[1][2] == 1 then
                    if math.floor((reward[2]-const.InitTime)/86400) == math.floor((GameLogic.getSTime()-const.InitTime)/86400) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

-- buff类统计，返回buff的总次数和剩余次数
function ActiveData:getBuffInfo(conditionId, stime)
    if self._configBuffs then
        local buff = self._configBuffs[conditionId]
        if buff then
            if not stime then
                stime = GameLogic.getSTime()
            end
            local myActs = self:getConfigableActs()
            for _, actItem in ipairs(buff) do
                local act = myActs[actItem[1]]
                if act.actStartTime <= stime and (act.actEndTime == 0 or stime < act.actEndTime) then
                    local record = self:getActRecord(actItem[1], conditionId)
                    return {act.actId,act.actStartTime,act.actEndTime,actItem[2],record[1]}
                end
            end
        end
    end
    return {0,0,0,0,0}
end

-- 检查某条件是否显示的逻辑
function ActiveData:checkVisible(actId, visibleData)
    if visibleData.hidden then
        local cids = visibleData.hidden
        local cvalues = visibleData.showNeed
        if type(cids) == "number" then
            cids = {cids}
            cvalues = {cvalues}
        end
        for idx, cid in ipairs(cids) do
            if self:getActRecord(actId, cid)[1] < (cvalues[idx] or 1) then
                return false
            end
        end
    end
    if visibleData.actTargetCondition then
        for _, condition in ipairs(visibleData.actTargetCondition) do
            local skip
            local compareValue = nil
            -- 注册时间条件
            if condition[1] == "regTime" then
                compareValue = GameLogic.getUserContext():getInfoItem(const.InfoRegTime)
            elseif condition[1] == "channel" then
                compareValue = GEngine.rawConfig.channel
            elseif condition[1] == "vip" then
                compareValue = GameLogic.getUserContext():getInfoItem(const.InfoVIPlv)
            elseif condition[1] == "ulevel" then
                compareValue = GameLogic.getUserContext():getInfoItem(const.InfoLevel)
            elseif condition[1] == "tlevel" then
                compareValue = GameLogic.getUserContext().buildData:getTownLevel()
            end
            if compareValue then
                if condition[2] == "big" then
                    skip = (compareValue < condition[3])
                elseif condition[2] == "small" then
                    skip = (compareValue >= condition[3])
                elseif condition[2] == "equal" then
                    local tskip = true
                    for ci=3, #condition do
                        if condition[ci] == compareValue then
                            tskip = false
                            break
                        end
                    end
                    skip = tskip
                elseif condition[2] == "notequal" then
                    skip = (compareValue == condition[3])
                end
            end
            if skip then
                return false
            end
        end
    end
    return true
end

-- 特殊的接口，指定刷新某个数据；一般用于服务器同步的数据，避免时序紊乱
function ActiveData:setActRecord(actId, conditionId, ctime, cnum)
    if not cnum then
        cnum = 1
    end
    if cnum <= 0 then
        return
    end
    local record = self:getActRecord(actId, conditionId)
    record[1] = cnum
    record[2] = ctime
end

-- 特殊的接口，指定刷新某个数据；一般用于服务器同步的数据，避免时序紊乱
function ActiveData:updateActRecord(actId, conditionId, ctime, cnum)
    if not cnum then
        cnum = 1
    end
    if cnum <= 0 then
        return
    end
    local record = self:getActRecord(actId, conditionId)
    record[1] = record[1] + cnum
    record[2] = ctime
end

-- 普通操作完成后，统计相关活动的接口
function ActiveData:finishActCondition(conditionId, num)
    self:finishDailyTask(conditionId, num)
    if not num then
        num = 1
    end
    if num <= 0 then
        return
    end
    local monitor = self._monitors[conditionId]
    local hasChange = false
    local hasChangeDict = {}
    if monitor then
        local myActs = self:getConfigableActs()
        local stime = GameLogic.getSTime()
        for _, actId in ipairs(monitor) do
            local act = myActs[actId]
            if act.actStartTime <= stime and (act.actEndTime == 0 or stime < act.actEndTime) then
                local id = act.rwds[1]
                local rwd = self._configableRwds[id]
                if rwd and rwd.atype == const.ActActionContinuous then
                    self:checkSpecificCondition(actId,conditionId)
                else
                    local record = self:getActRecord(actId, conditionId)
                    record[1] = record[1] + num
                    record[2] = stime
                    -- 月卡模板奖励悄悄领悄悄关
                    if act.actTemplate == "monthCard" then
                        local reward = self:getActRwd(actId, rwd.rwdId)
                        reward[1] = reward[1] + 1
                        reward[2] = stime
                        GameNetwork.request("actrwds", {actId=actId, num=1, rwdIdx=1, rtime=GameLogic.getSTime()},
                            GameLogic.onReceivedActRwd, GameLogic.getUserContext())
                        -- 那就顺便触发一下下次活动吧
                        self:checkAndTrigger(2)
                    end
                end
                hasChange = true
                hasChangeDict[actId] = 1
            end
        end
    end
    if hasChange then
        GameEvent.sendEvent("refreshEggDialog", {"actChange", hasChangeDict})
    end
    if self.dailyWelfare and self.dailyWelfare[3] == conditionId then
        if self.dailyWelfare[5] < self.dailyWelfare[4] then
            self.dailyWelfare[6] = GameLogic.getSTime()
        end
        self.dailyWelfare[5] = self.dailyWelfare[5] + num
    end
    self._myAcidStat[conditionId] = 1
    self:checkTriggerBag()
end

-- 普通操作完成后，统计邀请码活动的接口
function ActiveData:finishActConditionTlist(tlist)
    if not tlist or KTLen(tlist) <= 0 then
        return
    end
    local conditionId = const.ActTypeInviteCode
    local monitor = self._monitors[conditionId]
    local hasChange = false
    local hasChangeDict = {}
    if monitor then
        local myActs = self:getConfigableActs()
        local stime = GameLogic.getSTime()
        for _, actId in ipairs(monitor) do
            local act = myActs[actId]
            if act.actStartTime <= stime and (act.actEndTime == 0 or stime < act.actEndTime) then
                local times = 0
                for _,v in ipairs(tlist) do
                    local insertTime = v[9] or 0
                    if insertTime >= act.actStartTime and insertTime <= act.actEndTime then
                        times = times + 1
                    end
                end
                for _,rwdid in ipairs(act.rwds) do
                    local rwd = self._configableRwds[rwdid]
                    if rwd.conditions[1][1] == conditionId then
                        local record = self:getActRecord(actId, conditionId)
                        if times > record[1] then
                            record[1] = times
                            record[2] = stime
                            hasChange = true
                            hasChangeDict[actId] = 1
                        end
                    end
                end
                GameLogic.getUserContext():addCmd({const.CmdActStat, conditionId, times})
            end
        end
    end
    if hasChange then
        GameEvent.sendEvent("refreshEggDialog", {"actChange", hasChangeDict})
    end
    self._myAcidStat[conditionId] = 1
    self:checkTriggerBag()
end

function ActiveData:checkSpecificCondition(actId,condition)
    local stime = GameLogic.getSTime()
    local curRecord1 = self:getActRecord(actId, condition)
    local curRecord2 = self:getActRecord(actId, const.ActTypeContinuousBuy)
    local td = math.floor((stime-const.InitTime)/86400)
    local bd = math.floor((curRecord2[2]-const.InitTime)/86400)
    if td > bd then
        if td == bd + 1 then
            curRecord1[1] = curRecord1[1] + (10^curRecord2[1])
            curRecord2[1] = curRecord2[1] + 1
        else
            curRecord1[1] = curRecord1[1] + 1
            curRecord2[1] = 1
        end
        curRecord1[2] = stime
        curRecord2[2] = stime
    end
end


function ActiveData:finishActConditionOnce(conditionId, num)
    self:finishDailyTask(conditionId, num)
    if not num then
        num = 0
    end
    if num < 0 then
        return
    end
    local monitor = self._monitors[conditionId]
    local hasChange = false
    local hasChangeDict = {}
    if monitor then
        local myActs = self:getConfigableActs()
        local stime = GameLogic.getSTime()
        for _, actId in ipairs(monitor) do

            local act = myActs[actId]
            if act.actStartTime <= stime and (act.actEndTime == 0 or stime < act.actEndTime) then
                local id = act.rwds[1]
                local rwd = self._configableRwds[id]
                if rwd and rwd.atype == const.ActActionContinuous then
                    self:checkSpecificCondition(actId,conditionId)
                else
                    local record = self:getActRecord(actId, conditionId)
                    if num > record[1] then
                        record[1] =  num
                        record[2] = stime
                    end
                end
                hasChange = true
                hasChangeDict[actId] = 1
            end
        end
    end
    if hasChange then
        GameEvent.sendEvent("refreshEggDialog", {"actChange", hasChangeDict})
    end
    if self.dailyWelfare and self.dailyWelfare[3] == conditionId then
        if self.dailyWelfare[5] < self.dailyWelfare[4] then
            self.dailyWelfare[6] = GameLogic.getSTime()
        end
        if num > self.dailyWelfare[5] then
            self.dailyWelfare[5] = num
        else
            self.dailyWelfare[5] = self.dailyWelfare[5]
        end
    end
    if not self._myAcidStat[conditionId] or self._myAcidStat[conditionId] < num then
        self._myAcidStat[conditionId] = num
    end
    self:checkTriggerBag()
end

-- 登录活动的统计不在登录接口中进行处理，改走批量接口；保证用户在跨天的时候能够自然刷新
function ActiveData:refreshLoginAct()
    local conditionId = const.ActTypeLogin
    local monitors = self._monitors[conditionId]
    if monitors then
        local stime = GameLogic.getSTime()
        local acts = self:getConfigableActs()
        local hasChange = false
        for _, actId in ipairs(monitors) do
            local act = acts[actId]
            if act.actStartTime <= stime and (act.actEndTime == 0 or stime < act.actEndTime) then
                local record = self:getActRecord(actId, conditionId)
                local dayDis = math.floor((stime-const.InitTime)/86400) - math.floor((record[2] - const.InitTime)/86400)
                if dayDis > 0 then
                    record[1] = record[1] + 1
                    record[2] = stime
                    -- 增加指定天数的登录逻辑，最多30天
                    local dayIdx = math.floor((stime-const.InitTime)/86400) - math.floor((act.actStartTime-const.InitTime)/86400)
                    if dayIdx > 30 then
                        dayIdx = 30
                    end
                    self:finishActCondition(conditionId*10+1, 2^dayIdx)
                    -- 增加连续登录天数的登录逻辑
                    local record2 = self:getActRecord(actId, conditionId*10+2)
                    if dayDis == 1 then
                        record2[1] = 1
                    else
                        record2[1] = record2[1] + 1
                    end
                    record2[2] = stime
                    hasChange = true
                end
            end
        end
        if hasChange then
            GameLogic.getUserContext():addCmd({const.CmdActLogin, conditionId, stime})
        end
    end
    self:refreshWelfare()
end

function ActiveData:finishActRwd(actId, rwdIdx, num)
    local myRwd = self:getConfigableRwds(actId, rwdIdx)
    if myRwd then
        local act = self._configableActs[actId]
        if act and act.actExtends then
            local context = GameLogic.getUserContext()
            local vip = context:getInfoItem(const.InfoVIPlv)
            local userLv = context:getInfoItem(const.InfoLevel)
            GameLogic.addStatLog(11303,vip,userLv,actId)
        end
        local reward = self:getActRwd(actId, myRwd.rwdId)
        local stime = GameLogic.getSTime()
        reward[1] = reward[1] + (num or 1)
        reward[2] = stime
        if myRwd.acid then
            self:finishActCondition(myRwd.acid, num)
        end
        if myRwd.ftid then
            -- 那就顺便触发一下下次活动吧
            self:checkAndTrigger(myRwd.ftid)
        end
    end
end

-- sorry 英文不好之前拼错了
function ActiveData:checkAndTrigger(ftIdx)
    local context = GameLogic.getUserContext()
    local lastState = context:getProperty(const.ProSpecialNewState)
    if bit.band(lastState, bit.lshift(1, ftIdx-1)) == 0 then
        local triggerAct = self:forceTriggerAct(const.ProSpecialNewState, ftIdx)
        if triggerAct then
            lastState = bit.bor(lastState, bit.lshift(1, ftIdx-1))
            context:setProperty(const.ProSpecialNewState, lastState)
            context:setProperty(const.ProSpecialNewAct, triggerAct.actId)
            context:addCmd({const.CmdActTriggleInit, const.ProSpecialNewState, lastState})
            context:addCmd({const.CmdActTriggleInit, const.ProSpecialNewAct, triggerAct.actId})
        end
    end
end

--提醒红点
function ActiveData:getRedNum(actId, withNew)
    --print("actId=",actId)
    if self._configableGroups[actId] then
        local tnum = 0
        local atype = self._configableGroups[actId].actGroup
        for aid, act in pairs(self._configableActs) do
            if ActivityLogic.menuActType(act) == atype then
                tnum = tnum + self:getRedNum(aid, true)
            end
        end
        tnum = tnum>99 and 99 or tnum
        return tnum
    end
    local act = self._configableActs[actId]
    if not act then
        return 0
    end
    if act.actId == 170710 then
        return 0
    end
    if act.actId == 170712 then
        --月卡的红点
        local item = GameLogic.getMonthCardData()[1].item
        if item.isget == 0 and item.gnum>=item.anum then
            local remain2 = GameLogic.getUserContext().vips[5][2]-GameLogic.getSTime()
            if remain2>0 then
                return 1
            end
        end
        return 0
    end

    local stime = GameLogic.getSTime()
    if self:checkActState(actId) ~= GameLogic.States.Close then
        local rwds = act.rwds
        local num = 0
        if withNew and ActivityLogic.checkActNew(actId, act) then
            num = num + 1
        end
        for rwdIdx, _ in ipairs(rwds) do
            local rwd = self:getConfigableRwds(actId, rwdIdx)
            if rwd.atype == 5 then
                local boxNum = self:getSpecialNum(actId, rwd)
                if boxNum < 0 then
                    --print("WTF?", boxNum)
                    boxNum = 0
                end
                num = num + boxNum
            elseif rwd.multiControl then
                -- 这种活动肯定不可能有红点计数所以懒得算了
                break
            elseif self:checkActRewardState(actId, rwdIdx) == GameLogic.States.Finished then
                num = num + 1
            end
        end
        num = num>99 and 99 or num
        return num
    end
    return 0
end

-- 特殊活动的剩余领取次数
function ActiveData:getSpecialNum(actId, myRwd)
    local record = self:getActRecord(actId, myRwd.conditions[1][1])
    local reward = self:getActRwd(actId, myRwd.rwdId)
    local boxMax = math.floor(record[1]/myRwd.conditions[1][2])
    if boxMax > (myRwd.max or 1) then
        boxMax = (myRwd.max or 1)
    end
    local boxNum = boxMax - reward[1]
    return boxNum
end

function ActiveData:initDailyData()
    self:initHotData(true)
end

function ActiveData:testOther()
    if GameLogic.getUserContext().union then
        if not self.dhActive[52] then
            self.dhActive[52] = {1,52,1,0,GameLogic.getTime()}
        end
    end
end

function ActiveData:initHotData(isDaily)
    -- 以前的每日任务ID是1-13
    local dhActive = self.dhActive
    local hotData = {}

    local sindex = isDaily and 1 or 51

    for i=sindex,sindex+49 do
        local v = SData.getData("actdy",i)
        if v then
            local oid = 1   -- 活动的 活动阶段  基本都是1  也有几个阶段的就是1，2，3.。。
            local hot = dhActive[i]
            local data = {}
            if hot then
                if hot[4] == 0 then
                    oid = hot[1]
                    data = {atype = i, aid = oid, gnum = hot[3], anum = v[oid], isget = 0}
                else
                    if v[hot[1]+1] then
                        oid = hot[1]+1
                        data = {atype = i, aid = oid, gnum = hot[3], anum = v[oid], isget = 0}
                    else
                        oid = hot[1]
                        data = {atype = i, aid = oid, gnum = hot[3], anum = v[oid], isget = hot[4]}
                    end
                end
            else
                data = {atype = i, aid = oid, gnum = 0, anum = v[1], isget = 0}
            end
            --每日掠夺条件
            if i == 9 then
                data.anum = const.DailyRobSet[GameLogic.getUserContext().buildData:getMaxLevel(const.Town)]
            elseif i == 4 then --月卡
                local context = GameLogic.getUserContext()
                if context.vips[5][2]>GameLogic.getSTime() then
                    data.gnum = 1
                end
            end

            local reward = {}       --奖励
            for j,v in ipairs(SData.getData("activeReward")) do
                if v.atype == i and v.aid == oid then
                    table.insert(reward,v)
                end
            end
            data.reward = reward
            if data.atype == 56 then
                if not Plugins.singleSdk and gameSetting.shareConfig==1 then
                    table.insert(hotData,data)
                end
            else
                table.insert(hotData,data)
            end
        end
    end
    if isDaily then
        self.dailyData = hotData
        if self.dailyWelfare then
            local fix = 1
            if self.dailyWelfare[7] >= self.dailyWelfare[6] then
                fix = 0
            end
            table.insert(hotData, {atype = 13, aid = 1, gnum = self.dailyWelfare[5], anum = self.dailyWelfare[4], isget = 1-fix})
        end
    else
        self.hotData = hotData
    end

    self:sortHotData(isDaily)  --排序
end

function ActiveData:getNotRewardDaily()
    local num = 0
    for i,v in ipairs(self.dailyData) do
        --  or v.atype == 4 注释掉月卡的
        if (v.atype==12 or v.atype==13) and v.gnum>=v.anum and v.isget == 0 then
            num = num+1
        end
    end
    return num
end

function ActiveData:getNotRewardHot()
    if GameLogic.useTalentMatch then
        return 0
    end
    local num = 0
    for i,v in ipairs(self.hotData) do
        if v.gnum>=v.anum and v.isget == 0 then
            num = num+1
        end
    end
    return num
end

function ActiveData:getNotRewardLimit101()
    --每日寻宝次数
    local params = self.limitActive[101]
    if not params or GameLogic.useTalentMatch then
        return 0
    end
    local shakeNum = params[3]
    local useGem = params[5]
    local allNum = 1
    local needGem = 500
    if 500<=useGem and useGem<1000 then
        allNum = 2
        needGem = 1000
    elseif useGem>=1000 then
        allNum = math.floor((useGem-1000)/1000)+3
        needGem = (allNum-2)*1000+1000
    end
    --vip
    allNum = allNum+GameLogic.getUserContext():getVipPermission("fbox")[2]
    local remainNum = allNum-shakeNum
    local num = 0
    for k,v in pairs(params[7]) do
        num = num+1
    end
    local maxNum = 20
    if num >= maxNum or remainNum == 0 then
        return 0
    end
    if remainNum + num > maxNum then
        return maxNum - num
    else
        return remainNum
    end
end

function ActiveData:getNotRewardLimit102()
    --季度礼包领取
    local num = 0
    local params = self.limitActive[102]
    if not params then
        return 0
    end
    local mun = 0
    if params[3] == 0 then
        num = num+1
    end
    local nowIdx = 0
    for i,v in ipairs(const.Qgiftset) do
        if params[5]>= v then
            nowIdx = i
        end
    end
    if params[4]<nowIdx then
        num = num+1
    end
    return num>0 and 1 or 0
end

function ActiveData:sortHotData(isDaily)
    local hotData = isDaily and self.dailyData or self.hotData
    if isDaily then
        --排序
        local tempMap = {}
        for i,v in ipairs(hotData) do
            tempMap[v.atype] = v
        end
        hotData = {}
        local cfg = GEngine.getSetting("dailyTask")
        for i,v in ipairs(cfg) do
            table.insert(hotData,tempMap[v])
        end
        self.dailyData = hotData
    end

    --完成的插到最后
    local didx = 1
    local len = #hotData
    while didx<=len do
        local v = hotData[didx]
        if v.isget == 1 then
            table.insert(hotData,table.remove(hotData,didx))
            len = len - 1
        else
            if v.isget == 0 and v.gnum>=v.anum then
                table.insert(hotData,1,table.remove(hotData,didx))
            end
            didx = didx+1
        end
    end
end

function ActiveData:getReward(atype,aid)
    if self.dhActive[atype] then
        self.dhActive[atype][4] = 1
        self.dhActive[atype][1] = aid or self.dhActive[atype][1]
        if atype==57 then
            if self.dhActive[atype][1]<KTLen(SData.getData("actdy",57)) then
                self.dhActive[atype][1] = self.dhActive[atype][1]+1
                self.dhActive[atype][4] = 0
            else
                self.dhActive[atype][4] = 1
            end
        end

    else
        self.dhActive[atype] = {1,atype,1,1,GameLogic.getTime()}
    end

    if atype<=50 then
        self:initDailyData()
    elseif atype<=100 then
        self:initHotData()
    end
    GameEvent.sendEvent("refreshTaskRedNum")
end

function ActiveData:finishAct(atype,num)
    num = num or 1
    if atype<=100 then
        if not self.dhActive[atype] then
            self.dhActive[atype] = {1,atype,num,0,GameLogic.getTime()}
        else
            self.dhActive[atype][3] = self.dhActive[atype][3]+num
        end
        if atype<=50 then
            self:initDailyData()
        else
            self:initHotData()
        end
    else
        if self.limitActive[atype] then
            self.limitActive[atype][5] = self.limitActive[atype][5]+num
        end
    end
    GameEvent.sendEvent("refreshTaskRedNum")
end

-- 完全看不懂以前的月卡逻辑了，重新写一下
function ActiveData:refreshMonthCard()
    local stime = GameLogic.getSTime()
    if self.__lockMCTime and self.__lockMCTime > stime then
        return
    end
    if GameLogic.getUserContext().vips[5][2] <= stime then
        self.__lockMCTime = stime + 30
        return
    end
    local dailyData = self.dailyData
    for k,v in pairs(dailyData) do
        if v.atype == 4 then
            if v.isget == 0 and v.gnum >= v.anum then
                self.__lockMCTime = stime + 30
                GameLogic.getactreward(4, 1, Handler(self.onRefreshMCBack, self), 1)
            else
                self.__lockMCTime = GameLogic.getToday() + 86400
            end
        end
    end
end

function ActiveData:onRefreshMCBack()
    local dailyData = self.dailyData
    -- 判断是否有领到月卡
    for k,v in pairs(dailyData) do
        if v.atype == 4 then
            if v.isget ~= 0 or v.gnum < v.anum then
                self.__lockMCTime = GameLogic.getToday() + 86400
                GameLogic.getUserContext().logData:getEmailDatas()
            end
        end
    end
end

function ActiveData:loadLimit(data)
    --每日寻宝
    local params = data["101"]
    if params then
        params[7] = string.split(params[7],",")
        for i,v in ipairs(params[7]) do
            if v == "" then
                table.remove(params[7],i)
            end
        end
        for i,v in ipairs(params[7]) do
            params[7][i] = tonumber(v)
        end
    end
    local temp ={}
    for k,v in pairs(data) do
        if v[1]>GameLogic.getTime() then
        else
            temp[tonumber(k)] = v
        end
    end
    self.limitActive = temp
    if temp[110] then
        if GameLogic.getUserContext():getProperty(const.ProFollowTime) >= temp[110][1] then
            temp[110] = nil
        end
    end
end

-- 每日福利任务
function ActiveData:loadWelfare(data)
--[[
    DTVersion    玩家每日任务版本号；在DailyId为1的时候刷新
    DTDailyId    玩家上一条已领取的任务天数id
    DTConditionId   当前任务条件ID
    DTConditionNeed   当前任务条件数量
    DTCount      任务完成情况统计
    DTRefreshTime 任务刷新时间
    DTRewardTime  领取当日任务奖励时间
--]]
    self.dailyWelfare = data
    self:refreshWelfare()
end

function ActiveData:refreshWelfare()
    local stime = GameLogic.getSTime()
    local dt = self.dailyWelfare
    if not dt then
        return
    end
    if dt[7] >= dt[6] then
        if math.floor((dt[6]-const.InitTime)/86400) < math.floor((stime-const.InitTime)/86400) then
            dt[2] = (dt[2] % const.DTDayMax) + 1
            if dt[2] == 1 then
                dt[1] = const.DTVersion
            end
            local condition = SData.getData("dailytask", dt[1], dt[2])
            if not condition then
                self.dailyWelfare = nil
                return
            end
            dt[3] = condition["conditionId"]
            dt[4] = condition["count"]
            dt[5] = 0
            if stime <= dt[7] then
                stime = dt[7]+1
            end
            dt[6] = stime
            GameLogic.getUserContext():addCmd({const.CmdDTRefresh, stime, dt[1]})
        end
    end
    local condition = SData.getData("dailytask", dt[1], dt[2])
    if not condition then
        self.dailyWelfare = nil
        return
    end
end

function ActiveData:finishWelfare()
    local stime = GameLogic.getSTime()
    local dt = self.dailyWelfare
    if not dt then
        return
    end
    dt[7] = stime
    self:refreshWelfare()
    self:initDailyData()
end

-- @brief 检测是否可以弹评分
-- @params checkType 检查类型的字符串
-- @params cp 检查类型对应的参数
function ActiveData:isInRateAct(checkType, cp)
    -- 以后就和活动无关了
    -- local actId = 110
    -- local act = self.limitActive and self.limitActive[actId]
    -- pve时检查关数
    local ltime = GEngine.getConfig("rateTime"..checkType)
    if ltime and type(ltime) == "number" and ltime > GameLogic.getSTime()-86400 then
        return false
    end
    if checkType == "pve" then
        return cp == 5 or cp == 20 or cp == 40 or cp == 60 or cp == 180
    elseif checkType == "extract" then
        return cp == 4010 or cp == 4009 or cp == 4012 or cp == 4014
    elseif checkType == "pvh" then
        return cp == 6
    elseif checkType == "goldSkill" then
        return cp == 7
    end
    GEngine.setConfig("rateTime" .. checkType, GameLogic.getSTime(), true)
    -- self.limitActive[actId] = nil
    return false
end

function ActiveData:beginRateAct()
    GEngine.setConfig("followed", os.time(), true)
    GEngine.saveConfig()
end

function ActiveData:finishRateAct()
    local ltime = GEngine.getConfig("followed")
    local ret = false
    if ltime and type(ltime)=="number" and ltime > 0 then
        -- local ctime = os.time()
        -- local act = self.limitActive and self.limitActive[110]
        -- if ctime - ltime >= 10 and act then
        --     local context = GameLogic.getUserContext()
        --     if context:getProperty(const.ProFollowTime) < act[1] then
        --         context:changeProperty(const.ProCrystal, 100)
        --         context:addCmd({const.CmdActFollow, GameLogic.getSTime()})
        --         context:setProperty(const.ProFollowTime, GameLogic.getSTime())
        --         GameLogic.addShowGetList({{10, 4, 100}})
        --     end
        --     self.limitActive[110] = nil
        --     ret = true
        -- end
        GEngine.setConfig("followed", nil, true)
        GEngine.saveConfig()
    end
    return ret
end

function ActiveData:beginTcodeAct(actId)
    local act = self:getConfigableActs()[actId]
    local info = json.encode({actId=actId, time=GameLogic.getSTime(), isDaoLiang = act and act.isDaoLiang})
    GEngine.setConfig("openUrlAndGetReward", info, true)
    GEngine.saveConfig()
end

function ActiveData:finishTcodeAct()
    local lastAct = GEngine.getConfig("openUrlAndGetReward")
    if lastAct then
        lastAct = json.decode(lastAct)
    end
    if lastAct then
        GEngine.setConfig("openUrlAndGetReward", nil, true)
        GEngine.saveConfig()
        if GameLogic.getSTime() - lastAct.time >= 5 then
            if self:checkActState(lastAct.actId) ~= GameLogic.States.Close and
                self:checkActRewardState(lastAct.actId, 1) ~= GameLogic.States.Close then
                local context = GameLogic.getUserContext()
                if lastAct.isDaoLiang then
                    local myRwd = self:getConfigableRwds(lastAct.actId, 1)
                    GameLogic.getUserContext().activeData:finishActCondition(myRwd.conditions[1][1], 1)
                    GameLogic.getUserContext():addCmd({const.CmdActStat, myRwd.conditions[1][1], lastAct.actId, 1})
                else
                    GameNetwork.request("actrwds", {actId=lastAct.actId, num=1,rwdIdx=1, rtime=GameLogic.getSTime()},
                    GameLogic.onReceivedActRwd, context)
                end

                if lastAct.actId == 171262 then--短线分享领奖
                    GameLogic.addStatLog(11604, GameLogic.getLanguageType(), 1, 1)
                elseif lastAct.actId == 201712074 then--长线评论领奖
                    GameLogic.addStatLog(11615, GameLogic.getLanguageType(), 1, 1)
                elseif lastAct.actId == 201712072 then--长线关注领奖
                    GameLogic.addStatLog(11612, GameLogic.getLanguageType(), 1, 1)
                end
            end
        end
    end
end

--内测充值活动
function ActiveData:addBuyedCrystal(num)
    if self.limitActive[109] then
        self.limitActive[109][3] = self.limitActive[109][3]+num
    end
    -- 累计充值宝石统计
    self:finishActCondition(const.ActTypePurchase, num)
    -- 单笔充值宝石统计
    self:finishActConditionOnce(const.ActTypePurchaseSingle, num)
end

-- 初始化日常任务
function ActiveData:initDailyTaskData( data )
    local dtinfo,dtdatas
    if data and data[1] then
        dtinfo = data[1]
        self._configDailydtInfo = dtinfo
    else
        dtinfo = self:getDailyTaskDtinfo()
    end
    if data and data[2] then
        dtdatas = data[2]
        self._configDailyDtdata = dtdatas
    else
        dtdatas = self:getDailyTaskDtdata()
    end
    local typeTask = {}
    local idTask = {}
    for i,v in ipairs(dtdatas) do
        typeTask[v[3]]=v
        idTask[v[2]]=v
    end
    self._typeTask = typeTask
    self._idTask = idTask
    self:sortDailyTask()
    GameEvent.sendEvent("refreshAchievementDialogEveryday")
    GameEvent.sendEvent("refreshTaskRedNum")

end

-- 任务排序
function ActiveData:sortDailyTask()
    local dailyId = {}
    local info1 = {}
    local info2 = {}
    local info3 = {}
    local ntype = "task"
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffTask)
    if buffInfo[4]~=0 then
        ntype = "task2"
    end

    for i,v in pairs(self._idTask) do
        local taskinfos = SData.getData(ntype,i)
        local ratings = {id=i,rating=taskinfos.duty_type,state=v[6],progres=v[4],duty_max=v[5],type=v[3]}
        if v[4]>=v[5] and v[6]<=0 then
            table.insert(info1,ratings)
        elseif v[4]<v[5] and v[6] == 0 then
            table.insert(info2,ratings)
        elseif v[6]>0 then
            table.insert(info3,ratings)
        end
    end
    GameLogic.mySort(info1,"rating")
    GameLogic.mySort(info2,"rating")
    GameLogic.mySort(info3,"rating")
    self._notRewd = info1
    for i=#info1,1,-1 do
        table.insert(dailyId,{type=info1[i].type,id=info1[i].id,state=info1[i].state,progres=info1[i].progres,duty_max=info1[i].duty_max})
    end
    for i=#info2,1,-1 do
        table.insert(dailyId,{type=info2[i].type,id=info2[i].id,state=info2[i].state,progres=info2[i].progres,duty_max=info2[i].duty_max})
    end
    for i=#info3,1,-1 do
        table.insert(dailyId,{type=info3[i].type,id=info3[i].id,state=info3[i].state,progres=info3[i].progres,duty_max=info3[i].duty_max})
    end
    return dailyId
end

-- 获取每日任务数据
function ActiveData:getDailyTaskDtdata(  )
    return self._configDailyDtdata
end

function ActiveData:getDailyTaskDtinfo(  )
    return self._configDailydtInfo
end

-- 未领取的每日任务红点数
function ActiveData:getNotRewardDailyTask(  )
    if GameLogic.useTalentMatch then
        return 0
    end
    local rewdTimes = GameLogic.getUserContext():getProperty(const.ProDutyNum)
    if rewdTimes >= const.MaxRewardTimes then
        return 0
    else
        return #self._notRewd
    end
end

-- 日常任务统计
function ActiveData:finishDailyTask(tasktype, num)
    if not num then
        num = 1
    end
    if num <= 0 then
        return
    end
    local dailytask = self._typeTask and self._typeTask[tasktype]
    if dailytask then
        dailytask[4] = dailytask[4] + num
        self:initDailyTaskData()
    end
end

-- 刷新每日任务
function ActiveData:refreshDailyTask(  )
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("dailyRefresh",{uid=GameLogic.getUserContext().uid, stime = GameLogic.getSTime()},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            local context = GameLogic.getUserContext()
            context:changeRes(const.ResCrystal, -data.cost)
            GameLogic.statCrystalCost("刷新每日任务的消耗",const.ResCrystal, -data.cost)
            self:initDailyTaskData({data.dtinfo,data.dtdatas})
        end
    end)
end

-- 每日任务领取奖励
function ActiveData:getDailyReward( taskId )
    if not GameNetwork.lockRequest() then
        return
    end
    local ntype = "task"
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffTask)
    if buffInfo[4]~=0 then
        ntype = "task2"
    end

    local blv = SData.getData(ntype,taskId).blv
    _G["GameNetwork"].request("dailyGetReward",{uid=GameLogic.getUserContext().uid,dutyId=taskId,blv=blv,stime = GameLogic.getSTime()},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            GameLogic.showHeroRewsUieffect(data.rwds)
            GameLogic.getUserContext():changeProperty(const.ProDutyNum,1)
            GameLogic.addRewards(data.rwds)
            self._idTask[taskId][6]=1
            for i,v in ipairs(data.rwds) do
                display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(v[1],v[2]) .. "x" .. v[3]}))
            end
            self:initDailyTaskData({data.dtinfo})
        end
    end)
end

function ActiveData:initTriggerBag()
    local context = GameLogic.getUserContext()
    local tlevel = context.buildData:getTownLevel()
    context:addCmd({const.CmdActTriggleInit,10000+const.ProCityLevelAct,tlevel})
    context:setProperty(10000+const.ProCityLevelAct,tlevel)
    local pNum = context:getProperty(const.ProPopular)
    context:addCmd({const.CmdActTriggleInit,10000+const.ProPrestigeAct,pNum})
    context:setProperty(10000+const.ProPrestigeAct,pNum)

    local heros = context.heroData:getAllHeros()
    local herosData = {}
    for _,hero in pairs(heros) do
        if hero.info.awake==1 then
            if not herosData[hero.hid] then
                herosData[hero.hid] = 0
            end
            herosData[hero.hid] = self:getLv(herosData[hero.hid],hero.awakeUp)
        end
    end
    for hid,maxLv in pairs(herosData) do
        context:addCmd({const.CmdActTriggleInit,10000+hid,maxLv})
        context:setProperty(10000+hid,maxLv)
    end
end

-- @brief 强制触发活动；基本和触发逻辑相同，但是没有触发对话框弹出/没有特殊逻辑
function ActiveData:forceTriggerAct(triggerType, triggerValue)
    local context = GameLogic.getUserContext()
    local actsData = self:getConfigableActs()
    local triggersData = self._myTriggles[triggerType]
    if triggersData then
        for _,v in ipairs(triggersData) do
            if v.actId and actsData[v.actId] == nil then
                local isTimeShow = self:checkTriggerTimes(v.actStartTime, v.actEndTime)
                local isShow = false
                if isTimeShow then
                    for _, condition in ipairs(v.triggles.conditions) do
                        if condition[1] == triggerType and condition[2] == triggerValue then
                            isShow = true
                        end
                    end
                end
                if isShow then
                    local data = self:deleteTrigger(v, true)
                    self:copyTriggerToActs(data)
                    return data
                end
            end
        end
    end
end

function ActiveData:checkTriggerBag()
    local tiggers ={}
    local context = GameLogic.getUserContext()
    local actsData = self:getConfigableActs()
    local triggersData = self:getConfigableTriggles()
    local myTriggle2Num = GEngine.getConfig(tostring("myTriggle2_"..context.uid))
    myTriggle2Num = myTriggle2Num and tonumber(myTriggle2Num) or 0
    if triggersData then
        for _,v in pairs(triggersData) do
            if v.actId and actsData[v.actId]==nil then
                if v.triggles and type(v.triggles.conditions) == "table" and next(v.triggles.conditions) then
                    local isTimeShow = self:checkTriggerTimes(v.actStartTime,v.actEndTime)
                    local isShow,isTTFAct = false, false
                    if isTimeShow then
                        isShow,isTTFAct = self:checkTriggerConditions(v.triggles.conditions)
                    end
                    -- if v.actId == 1801035 then
                    --     print(isShow,isTTFAct,isTimeShow,v.actStartTime,v.actEndTime)
                    -- end
                    if isShow and isTimeShow then
                        if not isTTFAct then
                            GEngine.setConfig(tostring("myTriggle2_"..context.uid),myTriggle2Num+1,true)
                        end
                        local data = self:deleteTrigger(v,true)
                        self:copyTriggerToActs(data)
                        self:checkTriggersCondtiion(v.rwds)
                        if not isTTFAct then
                            GEngine.setConfig(tostring("myTriggle1_"..context.uid),v.actId)
                        end
                        for _, v2 in pairs(v.triggles.conditions) do
                            if v2[1] == const.ActStatPrestigeValue then
                                local context = GameLogic.getUserContext()
                                local vip = context:getInfoItem(const.InfoVIPlv)
                                local userLv = context:getInfoItem(const.InfoLevel)
                                GameLogic.addStatLog(11301,vip,userLv,v2[2])
                                break
                            end
                        end
                        break
                   end
                end
            end
        end
    end
end

function ActiveData:checkTriggerTimes(startTime,endTime)
    if startTime <= GameLogic.getSTime() and (endTime >= GameLogic.getSTime() or endTime == 0) then
        return true
    end
    return false
end

function ActiveData:checkTriggerConditions(conditions)
    local isTure,isTTFAct = true,false
    local context = GameLogic.getUserContext()
    for _,v in pairs(conditions) do
        if v[1] then
            if v[1] == const.ActStatPrestigeValue then
                local pNum = context:getProperty(const.ProPopular)
                if pNum >= v[2] and v[2]>context:getProperty(10000+const.ProPrestigeAct) then
                    context:setProperty(10000+const.ProPrestigeAct,v[2])
                else
                    isTure = false
                    break
                end
            elseif v[1]==const.ActStatCityLevel then
                local tLevel = context.buildData:getTownLevel()
                if tLevel >= v[2] and v[2] > context:getProperty(10000+const.ProCityLevelAct) then
                    context:setProperty(10000+const.ProCityLevelAct, v[2])
                else
                    if not v[3] or tLevel<v[2] then
                        isTure = false
                        break
                    end
                end
            elseif v[1]==const.ActTypeHeroAwake then
                local awakeLv = self:getMaxHeroAwakeLevel(v[2])
                if awakeLv>=v[3] and v[3]>context:getProperty(10000+v[2]) then
                    context:setProperty(10000+v[2],v[3])
                else
                    isTure = false
                    break
                end
            elseif v[1] >= 1000*10000 and v[1] <= 1001*10000 then
                if self._myAcidStat[v[1]] and self._myAcidStat[v[1]] >= v[2]  and v[2] > context:getProperty(v[1]) then
                    context:setProperty(v[1], v[2])
                else
                    isTure = false
                    break
                end
            elseif v[1]==const.FirstFlushGiftBag then
                local active = context.activeData
                local data = active.dhActive[51]
                local isReceive = (data and data[3]>=1 or false)
                if isReceive and (data[4]==1) and (context:getProperty(10000+const.ProTwoFirstFlushAct)==0) then
                    context:setProperty(10000+const.ProTwoFirstFlushAct,1)
                    isTTFAct = true
                else
                    isTure = false
                    break
                end
            elseif v[1] >= 4400 and v[1] < 4500 then
                local data = self._myAcidStat[v[1]]
                if data then
                    isTure = true
                    self._myAcidStat[v[1]] = nil
                else
                    isTure = false
                    break
                end
            elseif v[1] == const.ActTypeHeroLevelUp then
                local hLevel = self._myAcidStat[v[2] * 10000 + const.ActTypeHeroLevelUp] or 0
                if hLevel >= v[3] and v[3] > context:getProperty(20000+v[2]) then
                    context:setProperty(20000+v[2], v[3])
                else
                    isTure = false
                    break
                end
            elseif v[1] == const.ActTypeEquipLevel then
                local eLevel = self._myAcidStat[v[2] * 10000 + const.ActTypeEquipLevel] or 0
                if eLevel >= v[3] and v[3] > context:getProperty(30000+v[2]) then
                    context:setProperty(30000+v[2], v[3])
                else
                    isTure = false
                    break
                end
            elseif v[1] == const.ActStatLeaveDays then
                local data = self._myAcidStat[const.ActStatLeaveDays]
                if data then
                    isTure = true
                    self._myAcidStat[const.ActStatLeaveDays] = nil
                else
                    isTure = false
                end
                break
            elseif v[1] == const.ActStatUserVip then
                if v[5] then--vip等级和玩家等级双触发活动
                    local userLv = context:getInfoItem(const.InfoLevel)
                    if self._myAcidStat[const.ActStatUserVip] and self._myAcidStat[const.ActStatUserVip] >= v[2][1] and self._myAcidStat[const.ActStatUserVip] <= v[2][2] and
                        userLv >= v[5][1] and userLv <= v[5][2] and v[4] > context:getProperty(v[3]) then
                        isTure = true
                        context:setProperty(v[3], v[4])
                    else
                        isTure = false
                        break
                    end
                else--vip单触发活动
                    if self._myAcidStat[const.ActStatUserVip] and self._myAcidStat[const.ActStatUserVip] >= v[2][1] and self._myAcidStat[const.ActStatUserVip] <= v[2][2] and v[4] > context:getProperty(v[3]) then
                        isTure = true
                        context:setProperty(v[3], v[4])
                    else
                        isTure = false
                        break
                    end
                end
            elseif v[1] == const.ActStatUserLevel then
                if self._myAcidStat[const.ActStatUserLevel] and self._myAcidStat[const.ActStatUserLevel] >= v[2][1] and self._myAcidStat[const.ActStatUserLevel] <= v[2][2] and v[4] > context:getProperty(v[3]) then
                    isTure = true
                    context:setProperty(v[3], v[4])
                else
                    isTure = false
                    break
                end
            else
                isTure = false
                break
            end
        end
    end
    return isTure,isTTFAct
end

function ActiveData:getLv(m,n)
    if m>n then
        return m
    else
        return n
    end
end

function ActiveData:getMaxLv(hero,tType)
    local lastMaxLv = 0
    local maxLv = 0
    local heroIdx = 0
    if not GameLogic.isEmptyTable(hero) then
        for k, v in pairs(hero) do
            if tType == const.ActTypeHeroAwake then
                if v.info.awake==1 then
                    maxLv = self:getLv(maxLv,v.awakeUp)
                end
            elseif tType == const.ActTypeMercenaryLevels then
                maxLv = self:getLv(maxLv,v.soldierLevel)
            elseif tType == const.ActTypeHeroLevelUp then
                maxLv = self:getLv(maxLv,v.level)
            elseif tType == const.ActTypeHeroStarUp then
                if v.info.color > 2 then
                    maxLv = self:getLv(maxLv,v.starUp)
                end
            elseif tType == const.ActTypeHeroAuto then
                maxLv = self:getLv(maxLv,v.mSkillLevel)
            end
            if maxLv~=lastMaxLv then
                lastMaxLv = maxLv
                heroIdx = v.idx
            end
        end
    end
    return maxLv,heroIdx
end

function ActiveData:getMaxHeroAwakeLevel(hid,htype)
    if htype==nil then
        htype = const.ActTypeHeroAwake
    end
    local hero = GameLogic.getUserContext().heroData:getHeroByHid(hid)
    local maxLv,heroIdx = self:getMaxLv(hero,htype)
    return maxLv,heroIdx
end

function ActiveData:checkTriggersCondtiion(rwds)
    if not GameLogic.isEmptyTable(rwds) then
        for key,value in pairs(rwds) do
            local _rwdsAll = self._configableRwds[value]
            if _rwdsAll then
                local condition = _rwdsAll.conditions
                for _,v in pairs (condition) do
                    if v[1]>10000 and ((v[1]%10000==const.ActTypeHeroAwake) or (v[1]%10000==const.ActTypeMercenaryLevels) or(v[1]%10000==const.ActTypeHeroLevelUp) or(v[1]%10000==const.ActTypeHeroStarUp) or(v[1]%10000==const.ActTypeHeroAuto)) then
                        local curMax,heroIdx = self:getMaxHeroAwakeLevel(math.floor(v[1]/10000),v[1]%10000)
                        GameLogic.getUserContext():addCmd({const.CmdActStat, v[1],curMax, heroIdx})
                        self:finishActConditionOnce(v[1],curMax)
                    end
                end
            end
        end
    end
end
return ActiveData
