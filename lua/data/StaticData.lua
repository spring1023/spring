-- 最下层数据加密用的class
local function ktclass()
    local class_type = {}
    class_type.ctor = false
    local class_tab = {}
    local class_cryptoMt = {}
    function class_cryptoMt.__index(tb,k)
        local rt
        local vtab = tb._vtab
        local v = vtab[k]
        if type(v) == "number" then
            rt = (v + 5) / -10
            if rt == 0 then
                rt = 0
            end
        else
            rt = v
            if rt == nil then
                return class_tab[k]
            end
        end
        return rt
    end
    function class_cryptoMt.__newindex(tb,k,v)
        local vtab = tb._vtab
        if type(v) == "number" then
            vtab[k] = (v * -10) - 5
        else
            vtab[k] = v
        end
    end

    class_type.new = function(...)
        local obj = {_vtab={}}
        setmetatable(obj, class_cryptoMt)
        do
            if class_type.ctor then
                class_type.ctor(obj, ...)
            end
        end
        return obj
    end

    setmetatable(class_type,{__newindex=
        function(t,k,v)
            class_tab[k]=v
        end
    })
    return class_type
end

local _cryptoMt = {}
function _cryptoMt.__index(tb,k)
    local rt
    local vtab = tb._vtab
    local v = vtab[k]
    if type(v) == "number" then
        rt = (v + 5) / -10
        if rt == 0 then
            rt = 0
        end
    else
        rt = v
    end
    return rt
end
function _cryptoMt.__newindex(tb,k,v)
    local vtab = tb._vtab
    if type(v) == "number" then
        vtab[k] = (v * -10) - 5
    else
        vtab[k] = v
    end
end

local function KT(userTab)
    if not userTab then
        print("error kt is nil")
        return
    elseif userTab._vtab then
        return userTab
    end
    local tab = {_vtab={}}
    setmetatable(tab, _cryptoMt)
    for k,v in pairs(userTab) do
        tab[k] = v
    end
    return tab
end

local function KTFix(userTab)
    if not userTab then
        return false
    end
    local hasValue = false
    for k, v in pairs(userTab) do
        local tv = type(v)
        if tv=="table" then
            if KTFix(v) then
                userTab[k] = KT(v)
            end
        elseif tv=="number" then
            hasValue = true
        end
    end
    return hasValue
end

local function KTNext(userTab, nk)
    local k, v = next(userTab._vtab, nk)
    return k, userTab[k]
end

local function KTLen(userTab)
    return #(userTab._vtab or userTab)
end

local rawPairs = GMethod.rawPairs
local rawIPairs = GMethod.rawIPairs
if not rawPairs or not rawIPairs then
    rawPairs = pairs
    rawIPairs = ipairs
    GMethod.rawPairs = rawPairs
    GMethod.rawIPairs = rawIPairs
end
local rawG = _G

local function KTPairs(userTab)
    if userTab ~= rawG and userTab._vtab then
        return KTNext, userTab, nil
    else
        return rawPairs(userTab)
    end
end

local function KTINext(userTab, nidx)
    local v = userTab[nidx+1]
    if v == nil then
        return nil
    else
        return nidx+1, v
    end
end

local function KTIPairs(userTab)
    if userTab._vtab then
        return KTINext, userTab, 0
    else
        return rawIPairs(userTab)
    end
end

GEngine.export("KTClass", ktclass)
GEngine.export("KT", KT)
GEngine.export("KTFix", KTFix)
GEngine.export("KTPairs", KTPairs)
GEngine.export("KTIPairs", KTIPairs)
GEngine.export("KTLen", KTLen)
GEngine.export("pairs", KTPairs)
GEngine.export("ipairs", KTIPairs)

local StaticData = {}

local datas = GMethod.execute("data.alldatas")
local const = GMethod.loadScript("game.GameLogic.Const")
KTFix(datas)
KTFix(const)
--need to do some crypto's work here.

function StaticData.checkSum()
    return StaticData.datas==datas
end

--可以用两种方式访问数据
function StaticData.getData(...)
    local keys = {...}
    local ret = datas
    if keys[1] and not ret[keys[1]] then
        StaticData.loadSubTable(keys[1])
    end
    for _, key in ipairs(keys) do
        ret = ret[key]
        if not ret then
            return ret
        end
    end
    return ret
end

for k, v in pairs(datas) do
    StaticData[k] = v
end

function StaticData.setData(k, v)
    StaticData[k] = v
    datas[k] = v
end

-- @brief 加载子表
-- @params tableName 子表的名字; 子表需存放在data/目录下，直接return子表的内容即可
function StaticData.loadSubTable(tableName)
    local tableData = GMethod.execute("data.alldatas." .. tableName)
    -- KTFix(tableData)
    datas[tableName] = tableData[tableName]
    StaticData[tableName] = tableData[tableName]
end

--全局变量表
function StaticData.getG(key)
    for _,v in ipairs(datas["global"]) do
        if key == v.globalKey then
            return v.globalValue
        end
    end
end

return StaticData
