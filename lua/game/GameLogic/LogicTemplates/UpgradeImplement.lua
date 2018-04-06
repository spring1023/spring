local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local _set = Base.sset
local _setReader = Base.ssetReader

do
    -- 升级中间件；一定是和升级计数/物品组件、升级花费组件、条件组件一起用的
    local UpgradeImplement = {}
    Base.registerImplement("Upgrade", UpgradeImplement)

    function UpgradeImplement:_static_load(config)
    end

    -- 获取某个物品的升级消耗/限制
    function UpgradeImplement:getUpgradeCost(upgradeId)
        local level = self:getValue(upgradeId) + 1
        local costItem = self:getCostItem(upgradeId, level)
        if costItem then
            costItem.conditions = self:getConditions(upgradeId, level)
        end
        return costItem
    end

    -- 获取某个物品最大等级
    function UpgradeImplement:getUpgradeMax(upgradeId)
        local items = self.conditionTable:getItem(upgradeId)
        return #items
    end

    -- 执行一次升级操作，花费、并将对应数据+1
    function UpgradeImplement:upgradeItem(upgradeId)
        local level = self:getValue(upgradeId) + 1
        self:useCostItem(upgradeId, level)
        self:changeValue(upgradeId, 1)
    end
end

do
    -- 条件控制器
    local ConditionImplement = {}
    Base.registerImplement("Condition", ConditionImplement)

    function ConditionImplement:_static_load(config)
        -- 有关条件判断
        _setReader(self, "conditionTable", config["conditionTable"])
        _set(self, "conditionSetting", config["conditionSetting"])
    end

    -- 获取某个物品的条件限制
    function ConditionImplement:getConditions(...)
        local conditions = {}
        local conditionItem = self.conditionTable:getReadItem(...)
        for _, condition in ipairs(self.conditionSetting) do
            local temp = {condition[1], condition[2], condition[3]}
            local skip = false
            for i=1, 3 do
                -- 加载那些需要动态从数据里取的值
                if type(temp[i]) == "table" and temp[i][1] == "key" then
                    temp[i] = conditionItem[temp[i][2]]
                    if not temp[i] or temp[i] == "" then
                        skip = true
                        break
                    end
                end
            end
            if not skip then
                temp[4] = self._weak_ref.context:getNormalItem(temp[1], temp[2])
                table.insert(conditions, temp)
            end
        end
        return conditions
    end
end
