local _timeUpdates = {}
--local _timeStat = {}

local _timeDelta = 10
local _statUpdateInfo
local function _updateTimes(diff)
    for _, update in pairs(_timeUpdates) do
        update[3] = update[3] + diff
        if update[3] >= update[2] then
            update[1](update[3])
            update[3] = 0
            --_timeStat[update[4]] = (_timeStat[update[4]] or 0) + socket.gettime() - sstime
        end
    end
    -- _timeDelta = _timeDelta - diff
    -- if _timeDelta < 0 then
    --     _timeDelta = 10
    --     _statUpdateInfo()
    -- end
end

UpdateEntry = _updateTimes

--function DumpTimeStat()
--    for k, v in pairs(_timeStat) do
--        print(k, v)
--    end
--end

local function _regTimeUpdateEntry(view, callback, distance)
    -- local debugTexts = string.split(debug.traceback(), "\n")
    -- for _, debugText in ipairs(debugTexts) do
    --     if not debugText:find("Update.lua") then
    --         debugTexts = debugText
    --         break
    --     end
    -- end
    _timeUpdates[view] = {callback, distance, 0}
    --, debugTexts}
end

local function _unregTimeUpdateEntry(view)
    local value = _timeUpdates[view]
    if value then
        _timeUpdates[view] = nil
        value[3] = nil
        value[2] = nil
        value[1] = nil
    end
end

RegTimeUpdateEntry = _regTimeUpdateEntry
UnregTimeUpdateEntry = _unregTimeUpdateEntry

function RegTimeUpdate(view, callback, distance)
    local function timeUpdateLife(event)
        if event == "enter" then
            _regTimeUpdateEntry(view, callback, distance)
        elseif event == "exit" then
            _unregTimeUpdateEntry(view)
        end
    end
    view:registerScriptHandler(timeUpdateLife)
    if view:getParent() then
        _regTimeUpdateEntry(view, callback, distance)
    end
end

function UnregTimeUpdate(view)
    view:unregisterScriptHandler()
    _unregTimeUpdateEntry(view)
end

local _updateActionTemplate = {"repeat", {"sequence", {{"call", 0}, {"delay", 0}}}}
local _updateSeqs = _updateActionTemplate[2][2]
local _minActionDistance = 0.025
local _actionTag = 201

local _actionStats = {}
function RegActionUpdate(view, callback, distance)
    if distance < _minActionDistance then
        log.d("Warning! The update distance time %f is less than %f", distance, _minActionDistance)
        distance = _minActionDistance
    end
    local action = view:getActionByTag(_actionTag)
    if action then
        view:stopAction(action)
    end
    _updateSeqs[1][2] = callback
    _updateSeqs[2][2] = distance
    action = ui.action.action(_updateActionTemplate)
    action:setTag(_actionTag)
    view:runAction(action)

    -- local path = string.split(debug.traceback(), "\n")[3]
    -- print(path)
    view.updateAction = 1
    _actionStats[view] = 1
end

function UnregActionUpdate(view)
    local action = view:getActionByTag(_actionTag)
    if action then
        view:stopAction(action)
    end
    view.updateAction = nil
    _actionStats[view] = nil
end

function statUpdateInfo()
    local la = 0
    for action, _ in pairs(_actionStats) do
        if action.updateAction then
            la = la + 1
        else
            _actionStats[action] = nil
        end
    end
    print("Dump Action Updates:", la)
    local lt = 0
    for view, _ in pairs(_timeUpdates) do
        lt = lt + 1
    end
    print("Dump Time Updates:", lt)
end
_statUpdateInfo = statUpdateInfo
