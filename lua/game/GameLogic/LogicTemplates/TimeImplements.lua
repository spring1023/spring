local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local _set = Base.sset
local _setReader = Base.ssetReader

-- 本文件实现时间有关滚动内容
do
    -- 根据时间滚动的内容；上限是常量，间隔是常量，动态是property
    local TimeRotateImplement = {}
    Base.registerImplement("time.rotate", TimeRotateImplement)

    function TimeRotateImplement:_static_load(config)
        _set(self, "maxValue", config["max"])
        _set(self, "disValue", config["distance"])
        _set(self, "timePro", config["time"])
    end

    -- 获取该模块基础数值最大值
    function TimeRotateImplement:getMax()
        return self.maxValue
    end

    -- 获取滚动时间
    function TimeRotateImplement:getDistance()
        return self.disValue
    end

    -- 获取该模块基础数值当前值，随时间更改
    function TimeRotateImplement:getValue(stime)
        local v = self._weak_ref.context:getProperty(self.timePro)
        if not stime then
            stime = GameLogic.getSTime()
        end
        local dis = self.disValue
        local max = self.maxValue
        v = math.floor((stime - v) / dis)
        if v > max then
            v = max
        end
        return v
    end

    -- 获取下一次次数的恢复时间
    function TimeRotateImplement:getNextTime(stime)
        local v = self._weak_ref.context:getProperty(self.timePro)
        if not stime then
            stime = GameLogic.getSTime()
        end
        if stime < v then
            return v + self.disValue - stime
        else
            return self.disValue - ((stime - v) % self.disValue)
        end
    end

    -- 更改该模块基础数值当前值，随时间更改
    function TimeRotateImplement:changeValue(change, stime)
        if not stime then
            stime = GameLogic.getSTime()
        end
        local ov = self:getValue(stime)
        local v = ov + change
        if ov >= self.maxValue then
            self._weak_ref.context:setProperty(self.timePro, stime - v * self.disValue)
        else
            if v < 0 then
                v = 0
                self._weak_ref.context:setProperty(self.timePro, stime)
            else
                self._weak_ref.context:changeProperty(self.timePro, -change * self.disValue)
            end
        end
        return v
    end
end

do
    -- 按时间重置的内容；和Sub模块组合使用，即一个负责滚动时间，一个负责改变次数
    -- 分两个模块组合主要是考虑可能会有多个值需要重置
    local DailyResetImplement = {}
    Base.registerImplement("DailyReset", DailyResetImplement)

    function DailyResetImplement:_static_load(config)
        _set(self, "disValue", config["distance"])
        _set(self, "timePro", config["time"])
    end

    -- 获取重置时间
    function DailyResetImplement:getDistance()
        return self.disValue
    end

    -- 刷新重置时间
    function DailyResetImplement:checkTime(stime)
        local v = self._weak_ref.context:getProperty(self.timePro)
        if not stime then
            stime = GameLogic.getSTime()
        end
        local dis = self.disValue
        if Base.checkDailyTime(v, stime, dis) then
            Base.useComponent(self, "refreshDaily", stime)
        end
    end

    -- 设置刷新时间；用于模块数据修改后的情况
    function DailyResetImplement:setTime(stime)
        self:checkTime(stime)
        self._weak_ref.context:setProperty(self.timePro, stime)
    end

    -- 获取下一次次数的重置时间
    function DailyResetImplement:getNextTime(stime)
        if not stime then
            stime = GameLogic.getSTime()
        end
        return self.disValue - ((stime - const.InitTime) % self.disValue)
    end

    -- 获取最后一次更新的时间
    function DailyResetImplement:getLastTime()
        return self._weak_ref.context:getProperty(self.timePro)
    end

    -- 按时间重置的倒计数子模块内容；动态是property，只能用作子模块
    local SubMinusDailyImplement = {}
    Base.registerImplement("SubMinusDaily", SubMinusDailyImplement)

    function SubMinusDailyImplement:_static_load(config)
        _set(self, "maxValue", config["max"])
        _set(self, "valuePro", config["value"])
    end

    -- 获取该模块基础数值最大值
    function SubMinusDailyImplement:getMax()
        return self.maxValue
    end

    -- 设置该模块基础数值最大值；虽然感觉不会用到，因为这种模块的上限应该是固定的
    function SubMinusDailyImplement:setMax(max)
        self.maxValue = max
    end

    -- 获取该模块基础数值当前值，随日期重置
    function SubMinusDailyImplement:getValue(stime)
        self._weak_ref.time:checkTime(stime)
        return self.maxValue - self._weak_ref.context:getProperty(self.valuePro)
    end

    -- 更改该模块基础数值当前值，当前时间
    function SubMinusDailyImplement:changeValue(change, stime)
        self._weak_ref.time:setTime(stime)
        return self._weak_ref.context:changeProperty(self.valuePro, -change)
    end

    -- 重置逻辑
    function SubMinusDailyImplement:_component_refreshDaily(stime)
        self._weak_ref.context:setProperty(self.valuePro, 0)
    end

    -- 按时间重置的子模块内容；动态是property，只能用作子模块
    local SubCountDailyImplement = {}
    Base.registerImplement("SubCountDaily", SubCountDailyImplement)

    function SubCountDailyImplement:_static_load(config)
        _set(self, "valuePro", config["value"])
        _set(self, "maxValue", config["max"])
    end

    function SubCountDailyImplement:getMax()
        if type(self.maxValue) == "number" then
            return self.maxValue
        else
            return self._weak_ref.context:getTemplateMax(self.maxValue)
        end
    end

    -- 获取该模块基础数值当前值，随日期重置
    function SubCountDailyImplement:getValue(stime)
        self._weak_ref.time:checkTime(stime)
        return self._weak_ref.context:getProperty(self.valuePro)
    end

    -- 更改该模块基础数值当前值，当前时间
    function SubCountDailyImplement:changeValue(change, stime)
        self._weak_ref.time:setTime(stime)
        return self._weak_ref.context:changeProperty(self.valuePro, change)
    end

    -- 重置逻辑
    function SubCountDailyImplement:_component_refreshDaily(stime)
        self._weak_ref.context:setProperty(self.valuePro, 0)
    end
end

do
    -- 根据时间产生输入的内容；上限是常量，间隔是常量，动态是property
    local TimeProduceImplement = {}
    Base.registerImplement("time.produce", TimeProduceImplement)

    function TimeProduceImplement:_static_load(config)
        _set(self, "maxValue", config["max"])
        _set(self, "produceValue", config["produce"])
        _set(self, "timeKey", config["time"])
        _set(self, "valueKey", config["value"])
        _set(self, "speedUnit", config["speedUnit"])
    end

    -- 获取该模块基础数值最大值
    function TimeProduceImplement:getMax()
        local mv = self.maxValue[2]
        local detail = self._weak_ref.raw:getCurrentData()
        return detail[mv]
    end

    -- 获取该模块生产速度
    function TimeProduceImplement:getProduce()
        local mv = self.produceValue[2]
        local detail = self._weak_ref.raw:getCurrentData()
        return detail[mv]
    end

    -- 获取该模块基础数值当前值，随时间更改
    function TimeProduceImplement:getValueAndTime(stime)
        if not stime then
            stime = GameLogic.getSTime()
        end
        local context = self._weak_ref.context
        local t = context:getProperty(self.timeKey)
        local v = context:getProperty(self.valueKey)
        local produce = self:getProduce()
        local max = self:getMax()
        local unit = self.speedUnit
        if max < v then
            max = v
        end
        local nv = v + math.floor(produce * (stime - t) / unit)
        t = t + math.floor((nv - v) * unit / produce)
        if nv > max then
            nv = max
        end
        v = nv
        -- context:setProperty(self.timeKey, t)
        -- context:setProperty(self.valueKey, v)
        return v, t
    end

    function TimeProduceImplement:getValue(stime)
        local v, _ = self:getValueAndTime(stime)
        return v
    end

    -- 获取下一次次数的恢复时间; 感觉上用不到吧……？
    function TimeProduceImplement:getNextTime(stime)
        if not stime then
            stime = GameLogic.getSTime()
        end
        local _, t = self:getValue(stime)
        local produce = self:getProduce()
        local unit = self.speedUnit
        return t + math.ceil(1*unit/produce) - stime
    end

    -- 更改该模块基础数值当前值，随时间更改
    function TimeProduceImplement:changeValue(change, stime)
        if not stime then
            stime = GameLogic.getSTime()
        end
        local ov, t = self:getValue(stime)
        local v = ov + change
        context:setProperty(self.timeKey, t)
        context:setProperty(self.valueKey, v)
        return v
    end
end
