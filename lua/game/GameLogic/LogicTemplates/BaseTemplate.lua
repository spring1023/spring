local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local _Impls = {}
local Base = {}

-- 添加组件方法
function Base.addComponentFunc(interface, comKey, callback)
    if type(interface[comKey]) ~= "table" then
        interface[comKey] = {}
    end
    table.insert(interface[comKey], callback)
end

-- 移除组件方法
function Base.removeComponentFunc(interface, comKey, callback)
    if type(interface[comKey]) ~= "table" then
        interface[comKey] = {}
    end
    for i=KTLen(interface[comKey]),1,-1 do
        if interface[comKey][i] == callback then
            table.remove(interface[comKey], i)
        end
    end
end

-- 添加组件
function Base.addComponent(interface, component)
    for k, v in pairs(component) do
        Base.addComponentFunc(interface, k, v)
    end
end

-- 调用组件方法
function Base.useComponent(interface, comKey, ...)
    if interface[comKey] then
        for _, callback in ipairs(interface[comKey]) do
            callback(interface, ...)
        end
    end
end

-- 设置模板实现；通过配置为一个模块加载多个可复用模块
function Base.setImplements(interface, implement)
    for k, v in pairs(implement) do
        -- 组件式方法，即该方法可能存在多个调用
        if type(v) == "function" and k:find("_component_") then
            k = k:sub(12)
            Base.addComponentFunc(interface, k, v)
        elseif k:find("_static_") then
            -- do nothing here.
        else
            interface[k] = v
        end
    end
end

-- 检查每日切换的数值逻辑
function Base.checkDailyTime(ntime, stime, disTime)
    if not disTime then
        disTime = 86400
    end
    return math.floor((ntime - const.InitTime) / disTime) ~= math.floor((stime - const.InitTime) / disTime)
end

-- 内置数据读取器，封装一下
local DataReader = class()

function DataReader:ctor(tableName, tableDict, tablePre)
    self.tableName = tableName
    self.tableDict = tableDict
    self.tablePre = tablePre
end

-- 根据格式确定的对象
function DataReader:readItem(item)
    if not item then
        return nil
    end
    local ret = {}
    for k, v in pairs(self.tableDict) do
        ret[k] = item[v]
    end
    return ret
end

-- 根据键值读取确定的对象
function DataReader:getReadItem(...)
    return self:readItem(self:getItem(...))
end

function DataReader:getItem(...)
    if self.tablePre then
        return SData.getData(self.tableName, self.tablePre, ...)
    else
        return SData.getData(self.tableName, ...)
    end
end

function DataReader:getKey(col)
    return self.tableDict[col]
end

-- 内部简写方法
local function _set(interface, k, v)
    local kt = type(v)
    if kt == "string" then
        interface[k] = const[v] or v
    elseif kt == "table" then
        if v[1] == "const" then
            interface[k] = const[v[2]]
        elseif v[1] == "SData" then
            interface[k] = SData.getData(v[2], v[3], v[4], v[5])
        elseif v[1] == "vip" or v[1] == "key" then
            interface[k] = v
        else
            local nv = {}
            for i, iv in ipairs(v) do
                _set(nv, i, iv)
            end
            interface[k] = nv
        end
    else
        interface[k] = v
    end
end

local function _setReader(interface, k, v)
    if v then
        interface[k] = DataReader.new(v[1], v[2], v[3])
    end
end

Base.sset = _set
Base.ssetReader = _setReader

function Base.registerImplement(key, impl)
    _Impls[key] = impl
end

-- 递归子模块的实现方式
local SubModelImplement = {}

function SubModelImplement:_component_reload()
    for _, sub in ipairs(self._subs) do
        Base.useComponent(sub, "reload")
    end
end

function SubModelImplement:_component_refreshDaily(stime)
    for _, sub in ipairs(self._subs) do
        Base.useComponent(sub, "refreshDaily", stime)
    end
end

local _allJson = GMethod.loadConfig("configs/models/all.json")
-- model所有配置分为两大部分，一部分是templates部分，用于表示某一块的逻辑使用的是哪个模板；
-- 另一部分是子model部分，子model部分按照model的形式执行
function Base.getModel(context, config, parent, timeParent)
    local model = {}
    -- 所有模块节点持有对上一级的弱引用；避免子节点持有父节点，父节点又持有子节点这种无限BUG
    model._weak_ref = {}
    setmetatable(model._weak_ref, {__mode = "v"})
    model._weak_ref["context"] = context
    model._weak_ref["raw"] = parent or model
    model._weak_ref["time"] = timeParent or model
    if type(config) == "string" then
        local configName = config
        config = _allJson[configName]
        if not config then
            GMethod.loadConfig("configs/models/" .. configName .. ".json")
        end
    end
    if config.templates and #(config.templates) > 0 then
        for _, template in ipairs(config.templates) do
            local impl = _Impls[template.name]
            if template.name == "DailyReset" then
                model._weak_ref["time"] = model
            end
            if impl then
                Base.setImplements(model, impl)
                impl._static_load(model, template.configs)
            else
                print("empty implement", template.name)
            end
        end
    end
    if config.subModels and #(config.subModels) > 0 then
        local subNum = 0
        model._subs = {}
        for _, subModel in ipairs(config.subModels) do
            subNum = subNum + 1
            model._subs[subNum] = Base.getModel(context, subModel, model._weak_ref["raw"], model._weak_ref["time"])
            if type(subModel) == "table" then
                model[subModel.name] = model._subs[subNum]
            else
                model[subModel] = model._subs[subNum]
            end
        end
        Base.setImplements(model, SubModelImplement)
    end
    return model
end

return Base
