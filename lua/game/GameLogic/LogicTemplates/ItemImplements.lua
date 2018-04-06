local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local _set = Base.sset
local _setReader = Base.ssetReader

do
    -- 通用详情查看模块
    local ItemDetailImplement = {}
    Base.registerImplement("ItemDetail", ItemDetailImplement)
    function ItemDetailImplement:_static_load(config)
        _setReader(self, "detailTable", config["detail"])
    end

    -- 获取单个物品详情
    function ItemDetailImplement:getDetail(...)
        return self.detailTable:getReadItem(...)
    end

    -- 获取物品详情列表
    function ItemDetailImplement:getDetails(...)
        local ret = {}
        local items = self.detailTable:getItem(...)
        for k, item in pairs(items) do
            ret[k] = self.detailTable:readItem(item)
        end
        return ret
    end

    -- 遍历那些数值配在2级目录但应该属于1级的值
    function ItemDetailImplement:findDetailsLevel1(searchParams, idx2)
        local items = self.detailTable:getItem()
        local ret = {}
        local searchKey = self.detailTable:getKey(searchParams.key)
        local searchValue = searchParams.value
        local item
        if idx2 then
            for idx1, idx2items in pairs(items) do
                if idx2items[idx2][searchKey] == searchValue then
                    item = self.detailTable:readItem(idx2items[idx2])
                    item.idx1 = idx1
                    item.idx2 = idx2
                    table.insert(ret, item)
                end
            end
        else
            for idx1, idx2items in pairs(items) do
                for idx2, idx2item in pairs(idx2items) do
                    if idx2item[searchKey] == searchValue then
                        item = self.detailTable:readItem(idx2item)
                        item.idx1 = idx1
                        item.idx2 = idx2
                        table.insert(ret, item)
                    end
                end
            end
        end
        return ret
    end
end

do
    -- 通用物品子模块
    local ItemNormalImplement = {}
    Base.registerImplement("ItemNormal", ItemNormalImplement)
    function ItemNormalImplement:_static_load(config)
        _set(self, "item", config["item"])
    end

    function ItemNormalImplement:getValue()
        return self._weak_ref.context:getNormalItem(self.item[1], self.item[2])
    end

    function ItemNormalImplement:changeValue(chance)
        self._weak_ref.context:changeNormalItem(self.item[1], self.item[2], chance)
    end
end

do
    -- 通用多物品-额外单表子模块；支持多键多值
    local BatchItemSingleImplement = {}
    Base.registerImplement("BatchSingle", BatchItemSingleImplement)

    function BatchItemSingleImplement:_static_load(config)
        -- self._mode = config.mode
        self._keyLen = config.keyLen or 1
        self._valueLen = config.valueLen or 1
        -- 如果没有设置过的话，认为数值是初始化过的这个数值
        self._initValue = config.initValue
        if self._valueLen > 1 then
            --多列结构的数值
            self._colsName = config.cols
        elseif not self._initValue then
            -- 如果没有初始数值且为单列值，那么初始化数值认为是0
            self._initValue = 0
        end
        self._datas = {}

        -- 是否有总容量限制
        _set(self, "maxValue", config.max)
    end

    -- 获取容量上限
    function BatchItemSingleImplement:getMax()
        if type(self.maxValue) == "number" then
            return self.maxValue
        else
            return self._weak_ref.context:getTemplateMax(self.maxValue)
        end
    end

    -- 获取总数量
    function BatchItemSingleImplement:getCountSum()
        return self._dataSum
    end

    -- 加载用户数据
    function BatchItemSingleImplement:loadUserData(data)
        if self.maxValue then
            self._dataSum = 0
        end
        for _, dataItem in ipairs(data) do
            local temp = self._datas
            for i=1, self._keyLen - 1 do
                if not temp[dataItem[i]] then
                    temp[dataItem[i]] = {}
                end
                temp = temp[dataItem[i]]
            end
            if self._valueLen == 1 then
                temp[dataItem[self._keyLen]] = dataItem[self._keyLen+1]
                if self.maxValue then
                    self._dataSum = self._dataSum + dataItem[self._keyLen+1]
                end
            else
                -- 如果长度不为1则做成dict的形式
                -- 为了方便用户使用，用dict比list好识别
                local newItem = {}
                for i=1, self._valueLen do
                    newItem[self._colsName[i]] = dataItem[self._keyLen+i]
                end
                temp[dataItem[self._keyLen]] = newItem
            end
        end
    end

    -- 序列化用户数据
    function BatchItemSingleImplement:getUserData()
        local ret = {}
        self:addUserData(ret, self._datas, {}, 0)
        return ret
    end

    -- 由于不清楚层级，所以做个递归
    function BatchItemSingleImplement:addUserData(ret, datas, keyarray, depth)
        depth = depth + 1
        for k, v in pairs(datas) do
            if depth == self._keyLen then
                local value = {}
                for i=1, self._keyLen - 1 do
                    value[i] = keyarray[i]
                end
                value[self._keyLen] = k
                if self._valueLen == 1 then
                    value[self._keyLen+1] = v
                else
                    for i=1, self._valueLen do
                        value[self._keyLen+i] = v[self._colsName[i]]
                    end
                end
                table.insert(ret, value)
            else
                keyarray[depth] = k
                self:addUserData(ret, v, keyarray, depth)
            end
        end
    end

    -- 获取用户数据
    function BatchItemSingleImplement:getValue(...)
        local temp = self._datas
        local params = {...}
        for i = 1, self._keyLen do
            temp = temp[params[i]]
        end
        return temp or self._initValue
    end

    -- 修改用户数据
    function BatchItemSingleImplement:setValue(...)
        local temp = self._datas
        local params = {...}
        for i = 1, self._keyLen-1 do
            temp = temp[params[i]]
        end
        if self.maxValue then
            self._dataSum = self._dataSum + params[self._keyLen+1] - (temp[params[self._keyLen]] or 0)
        end
        temp[params[self._keyLen]] = params[self._keyLen+1]
    end

    -- 修改用户数据；通常多列模式是不调用这个方法的，如果调用，则默认给最后一列加值
    function BatchItemSingleImplement:changeValue( ... )
        local temp = self._datas
        local params = {...}
        for i = 1, self._keyLen-1 do
            temp = temp[params[i]]
        end
        local tempValue = temp[params[self._keyLen]] or self._initValue
        if self._valueLen == 1 then
            temp[params[self._keyLen]] = tempValue + params[self._keyLen+1]
            if self.maxValue then
                self._dataSum = self._dataSum + params[self._keyLen+1]
            end
        else
            temp[params[self._keyLen]] = tempValue
            local lastCol = self._colsName[self._valueLen]
            tempValue[lastCol] = tempValue[lastCol] + params[self._keyLen+1]
        end
    end
end

do
    -- 通用物品子模块-批量，用于统一管理某一类物品的时候
    local ItemTypeImplement = {}
    Base.registerImplement("ItemType", ItemTypeImplement)
    function ItemTypeImplement:_static_load(config)
        _set(self, "itemType", config["itemType"])
        _set(self, "maxValue", config["max"])
    end

    function ItemTypeImplement:getMax()
        return self.maxValue
    end

    function ItemTypeImplement:getCountSum()
        if not self.maxValue then
            return 0
        end
        if not self._dataSum then
            local count = 0
            local items = SData.getData("property", self.itemType)
            for iid, item in pairs(items) do
                count = count + self:getValue(iid)
            end
            self._dataSum = count
        end
        return self._dataSum
    end

    function ItemTypeImplement:getValue(id)
        return self._weak_ref.context:getNormalItem(self.itemType, id)
    end

    function ItemTypeImplement:changeValue(id, value)
        if self.maxValue then
            self._dataSum = self:getCountSum() + value
        end
        self._weak_ref.context:changeNormalItem(self.itemType, id, value)
    end

    function ItemTypeImplement:getUserData()
        local ps = {}
        local items = SData.getData("property", self.itemType)
        for iid, item in pairs(items) do
            local v = self:getValue(iid)
            if v > 0 then
                ps[item.pid] = v
            end
        end
        return ps
    end
end
