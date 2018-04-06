require "support.heapq"

local scriptResourceCache = {}
local deleteHeap = {}
local maxResId = 0
local deleteNum = 0

local function addResource(res)
    local resId
    if deleteNum>0 then
        resId = heapq.heappop(deleteHeap, deleteNum)
        deleteNum = deleteNum-1
    else
        maxResId = maxResId+1
        resId = maxResId
    end
    scriptResourceCache[resId] = res
    return resId
end

local function removeResource(resId)
    scriptResourceCache[resId] = 0
    if resId==maxResId then
        maxResId = maxResId-1
    else
        deleteNum = deleteNum+1
        heapq.heappush(deleteHeap, resId, deleteNum)
    end
end

local _t_unpack = table.unpack or unpack
if not _t_unpack then
    print("error in unpack function, cannot find it")
end

local function _callp(func, op, np)
    local ap = {}
    for _, p in ipairs(op) do
        table.insert(ap, p)
    end
    for _, p in ipairs(np) do
        table.insert(ap, p)
    end
    return func(_t_unpack(ap))
end

Script = {}

function Script.executeCObjectCallback(resId, funcName, ...)
    local resource = scriptResourceCache[resId]
    if resource~=0 then
        return _callp(resource[1][funcName], resource, {...})
    end
end

function Script.executeCallback(resId, ...)
    local resource = scriptResourceCache[resId]
    if resource~=0 then
        return _callp(resource[1], resource[2], {...})
    end
end

--注意，在C里的下标是从0开始，而lua是从1开始
function Script.executeTableViewCallback(resId, eventType, idx)
    local resource = scriptResourceCache[resId]
    if resource~=0 then
        if eventType==0 then
            return resource[1](resource[2]:getCellNode(idx), resource[2], resource[3][idx+1])
        else
            if eventType==1 and resource[4] then
                resource[4](resource[2]:getCellNode(idx), resource[2], resource[3][idx+1])
            end
            return 0
        end
    end
end

function Script.createCObjectHandler(luaTable, cobject)
    local resId = addResource({luaTable, cobject})
    local handler = ScriptCallback:create(1, 0, resId)
    return handler
end

function Script.getScriptObject(cobject)
    return scriptResourceCache[cobject:getScriptHandler():getScriptRes()][1]
end

--一般来说回调函数只需要最多1个参数就够了；多存一个是为了支持Class:callback这样的回调;当然也可以用2个参数的回调
function Script.createCallbackHandler(callbackFunc, ...)
    local resId = addResource({callbackFunc, {...}})
    local handler = ScriptCallback:create(2, 0, resId)
    return handler
end

--不提供Class:callback这样的支持，原因是构造界面尽可能和逻辑无关，也就是无关上下文的。touchCallback可能为空
function Script.createTableViewHandler(callbackFunc, tableView, infos, touchCallback)
    local resId = addResource({callbackFunc, tableView, infos, touchCallback})
    local handler = ScriptCallback:create(3, 0, resId)
    return handler
end

function Script.init()
    scriptResourceCache = {}
    deleteHeap = {}
    maxResId = 0
    deleteNum = 0
    ScriptCallback:registerScriptFunc(0, removeResource)
    ScriptCallback:registerScriptFunc(1, Script.executeCObjectCallback)
    ScriptCallback:registerScriptFunc(2, Script.executeCallback)
    ScriptCallback:registerScriptFunc(3, Script.executeTableViewCallback)
end

function Script.createBasicHandler(callbackFunc, ...)
    if callbackFunc==nil then
        a = 1/nil
    end
    local op = {...}
    local function localCallback(...)
        return _callp(callbackFunc, op, {...})
    end
    return localCallback
end

function Script.executeBasicCallback(callback, cps, ...)
    return _callp(callback, cps, {...})
end