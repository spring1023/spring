local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local _set = Base.sset
local _setReader = Base.ssetReader

do
    -- 单个物品队列的实现，一般用于需要按时间进行完成且相同物品不叠加的项目，例如生产武器队列等
    local QueueImplement = {}
    Base.registerImplement("Queue", QueueImplement)

    function QueueImplement:_static_load(config)
        _setReader(self, "timeTable", config["timeTable"])
        _set(self, "maxValue", config["max"])

        self._queue = {}
        self._firstTime = 0
    end

    function QueueImplement:loadUserData(queueList, firstTime)
        self._queue = queueList
        self._firstTime = firstTime
    end

    -- 增加一个物品生产
    function QueueImplement:addToQueue(item, stime)
        if #(self._queue) == 0 then
            if not stime then
                stime = GameLogic.getSTime()
            end
            self._firstTime = stime
        end
        table.insert(self._queue, item)
        self._cachedFlag = nil
    end

    -- 获取队列中的物品生产时间
    function QueueImplement:getQueueItemTime(itemId)
        return self.timeTable:getReadItem(itemId).costTime
    end

    -- 完成队列中的一个物品生产
    function QueueImplement:finishQueue()
        local itemId = table.remove(self._queue, 1)
        self._firstTime = self._firstTime + self:getQueueItemTime(itemId)
        self._cachedFlag = nil
    end

    -- 移除队列中的一个物品
    function QueueImplement:removeQueue(idx, stime)
        -- 移除第一个则重新开始计时
        if idx == 1 then
            if not stime then
                stime = GameLogic.getSTime()
            end
            self._firstTime = stime
        end
        table.remove(self._queue, idx)
        self._cachedFlag = nil
    end

    -- 加速队列时间
    function QueueImplement:accQueueTime(accTime)
        self._firstTime = self._firstTime - accTime
        self._cachedFlag = nil
    end

    -- 由于队列大部分数值都不会变，所以做个缓存
    function QueueImplement:_innerCacheAll()
        if not self._cachedFlag then
            self._cachedFlag = true
            local t = self._firstTime
            if self._queue[1] then
                self._cachedNextMax = self:getQueueItemTime(self._queue[1])
                self._cachedNextTime = t + self._cachedNextMax
            end
            for _, itemId in ipairs(self._queue) do
                t = t + self:getQueueItemTime(itemId)
            end
            self._cachedFinishTime = t
        end
    end

    -- 获取队列中的物品数
    function QueueImplement:getQueueNum()
        return #(self._queue)
    end

    -- 获取队列长度限制
    function QueueImplement:getQueueMax()
        return self.maxValue
    end

    -- 获取队列全部完成的时间
    function QueueImplement:getQueueFinishTime()
        self:_innerCacheAll()
        return self._cachedFinishTime
    end

    -- 获取队列单个完成的时间
    function QueueImplement:getQueueNextTime()
        self:_innerCacheAll()
        return self._cachedNextTime
    end

    -- 获取队列首个物品总时间
    function QueueImplement:getQueueNextMaxTime()
        self:_innerCacheAll()
        return self._cachedNextMax
    end

    -- 获取队列单个开始的时间
    function QueueImplement:getQueueStartTime()
        return self._firstTime
    end

    -- 获取队列的所有物品列表
    function QueueImplement:getQueueList()
        return self._queue
    end
end
