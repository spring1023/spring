local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local _set = Base.sset
local _setReader = Base.ssetReader

do
    -- 通用单个花费子模块
    -- 用于在数据表里从1-n连续，花费数值为一个{costType=10,costId=1,costValue=5000}这种类型配置的花费模块
    -- 或用于花费类型固定，数值在常量表中配置的类型
    local CostNormalImplement = {}
    Base.registerImplement("CostNormal", CostNormalImplement)

    function CostNormalImplement:_static_load(config)
        self._useMax = config.flagUseMax
        _set(self, "costConst", config["costConst"])
        _setReader(self, "costTable", config["costTable"])
    end

    -- 获取消费数量
    function CostNormalImplement:getCostItem(idx)
        if not idx then
            idx = self:getValue()
        end
        if self.costConst then
            local costItems = self.costConst[1]
            if idx > #costItems then
                if not self._useMax then
                    return
                end
                idx = #costItems
            end
            return {costType=self.costConst[2], costId=self.costConst[3], costValue=costItems[idx]}
        else
            local costItems = self.costTable:getItem()
            if idx > #costItems then
                if not self._useMax then
                    return
                end
                idx = #costItems
            end
            local ret = self.costTable:readItem(costItems[idx])
            return ret
        end
    end

    -- 进行一次消费
    function CostNormalImplement:useCostItem(idx)
        local costItem = self:getCostItem(idx)
        if not costItem then
            return
        end
        self._weak_ref.context:costNormalItem(costItem)
    end
end

do
    -- 通用固定花费子模块
    -- 用于固定单价不会变化的花费，例如扫荡花费=100*次数
    local CostOneItemImplement = {}
    Base.registerImplement("CostOneItem", CostOneItemImplement)

    function CostOneItemImplement:_static_load(config)
        _set(self, "costItem", config["costItem"])
    end

    -- 获取消费数量
    function CostOneItemImplement:getCostItem(num)
        return {costType = self.costItem[1], costId=self.costItem[2], costValue=self.costItem[3] * num}
    end

    -- 进行一次消费
    function CostOneItemImplement:useCostItem(num)
        local costItem = self:getCostItem(num)
        self._weak_ref.context:costNormalItem(costItem)
    end
end

do
    -- 通用单个类型花费子模块
    -- 用于在数据表里从1-n连续，花费数值为一个{10,1,5000}这种类型配置的花费模块
    local CostOneTypeImplement = {}
    Base.registerImplement("CostOneType", CostOneTypeImplement)

    function CostOneTypeImplement:_static_load(config)
        self._useMax = config.flagUseMax
        _setReader(self, "costTable", config["costTable"])
    end

    -- 获取消费数量
    function CostOneTypeImplement:getCostItem(idx)
        local costItems = self.costTable:getItem()
        if idx > #costItems then
            if not self._useMax then
                return
            end
            idx = #costItems
        end
        local ret = self.costTable:readItem(costItems[idx])
        ret["costType"] = ret["costItem"][1]
        ret["costId"] = ret["costItem"][2]
        ret["costValue"] = ret["costItem"][3]
        return ret
    end

    -- 进行一次消费
    function CostOneTypeImplement:useCostItem(idx)
        local costItem = self:getCostItem(idx)
        self._weak_ref.context:costNormalItem(costItem)
    end
end

do
    -- 通用批量花费子模块；因为是批量所以一般都是配在数据表里的。
    local BatchCostNormalImplement = {}
    Base.registerImplement("BatchCostNormal", BatchCostNormalImplement)

    function BatchCostNormalImplement:_static_load(config)
        _setReader(self, "costTable", config["costTable"])
    end

    function BatchCostNormalImplement:getCostItem(...)
        return self.costTable:getReadItem(...)
    end

    function BatchCostNormalImplement:useCostItem(...)
        local item = self.costTable:getReadItem(...)
        if item.costValue then
            self._weak_ref.context:costNormalItem(item)
        end
        if item.costItems then
            self._weak_ref.context:costNormalItems(item.costItems)
        end
    end
end

do
    -- 通用离散花费子模块
    -- 用于key非连续的价位花费，例如{[1002]={costType=1},[2005]={costType=2}}
    -- 因为是离散的所以数值肯定不是放const里的
    local CostSeperateImplement = {}
    Base.registerImplement("CostSeperate", CostSeperateImplement)

    function CostSeperateImplement:_static_load(config)
        _set(self, "costType", config["costType"])
        _set(self, "costId", config["costId"])
        _setReader(self, "costTable", config["costTable"])
    end

    -- 获取卖出价格
    function CostSeperateImplement:getCostItem(idx)
        if not idx then
            idx = self:getValue()
        end
        local ret = self.costTable:getReadItem(idx)
        if self.costType then
            ret.costType = self.costType
        end
        if self.costId then
            ret.costId = self.costId
        end
        return ret
    end

    -- 进行一次卖出
    function CostSeperateImplement:useCostItem(idx)
        local costItem = self:getCostItem(idx)
        if not costItem then
            return
        end
        self._weak_ref.context:costNormalItem(costItem)
    end
end
