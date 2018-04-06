local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local Base = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")

local _set = Base.sset
local _setReader = Base.ssetReader

do
    -- 单个物品的读取器，目的是把属性值模块化
    local ProImplement = {}
    Base.registerImplement("Pro", ProImplement)

    function ProImplement:_static_load(config)
        _set(self, "valuePro", config["property"])
    end

    function ProImplement:getValue()
        return self._weak_ref.context:getProperty(self.valuePro)
    end

    function ProImplement:setValue(v)
        self._weak_ref.context:setProperty(self.valuePro, v)
    end

    function ProImplement:changeValue(v)
        self._weak_ref.context:changeProperty(self.valuePro, v)
    end
end

do
    -- 连续一组的队列列表
    local ProListImplement = {}
    Base.registerImplement("ProList", ProListImplement)

    function ProListImplement:_static_load(config)
        _set(self, "queuePros", config["property"])
        self.maxValue = #self.queuePros
    end

    -- 队列形式增加一个物品
    function ProListImplement:addItem(item)
        for i=1, self.maxValue do
            if self._weak_ref.context:getProperty(self.queuePros[i]) == 0 then
                self._weak_ref.context:setProperty(self.queuePros[i], item)
                return
            end
        end
    end

    -- 队列形式移除队列中的一个物品
    function ProListImplement:removeItem(item)
        for i=1, self.maxValue do
            if self._weak_ref.context:getProperty(self.queuePros[i]) == item then
                self._weak_ref.context:setProperty(self.queuePros[i], 0)
                return
            end
        end
    end

    -- 获取作为列表的数值
    function ProListImplement:getList()
        local ret = {}
        for i=1, self.maxValue do
            ret[i] = self._weak_ref.context:getProperty(self.queuePros[i])
        end
        return ret
    end

    -- 序列化（？）数据
    function ProListImplement:getUserData()
        local ps = {}
        for i=1, self.maxValue do
            ps[self.queuePros[i]] = self._weak_ref.context:getProperty(self.queuePros[i])
        end
        return ps
    end

    -- 按列表项的形式设置数据
    function ProListImplement:setValue(idx, value)
        self._weak_ref.context:setProperty(self.queuePros[idx], value)
    end

    -- 按列表项的形式读取数据
    function ProListImplement:getValue(idx)
        return self._weak_ref.context:getProperty(self.queuePros[idx])
    end

    -- 获取列表长度
    function ProListImplement:getListNum()
        local count = 0
        for i=1, self.maxValue do
            if self._weak_ref.context:getProperty(self.queuePros[i]) > 0 then
                count = count + 1
            end
        end
        return count
    end

    -- 获取列表长度
    function ProListImplement:getListMax()
        return #(self.queuePros)
    end
end

do
    -- 把数据伪装成property的调用方式
    local ProMapImplement = {}
    Base.registerImplement("pro.map.virtual", ProMapImplement)

    function ProMapImplement:_static_load(config)
        self.dataList = config["dataList"]
        self.keyList = config["keyList"]
        _set(self, "proList", config["proList"])
    end

    -- 加载用户数据
    function ProMapImplement:loadUserData(data)
        self._keyMap = {}
        local context = self._weak_ref.context
        for i, v in ipairs(self.dataList) do
            context:setProperty(self.proList[i], data[v])
            self._keyMap[self.keyList[i]] = self.proList[i]
        end
    end

    function ProMapImplement:getValue(key)
        local pid = self._keyMap[key]
        return self._weak_ref.context:getProperty(pid)
    end

    function ProMapImplement:changeValue(key, value)
        local pid = self._keyMap[key]
        return self._weak_ref.context:changeProperty(pid, value)
    end

    function ProMapImplement:setValue(key, value)
        local pid = self._keyMap[key]
        return self._weak_ref.context:setProperty(pid, value)
    end
end
