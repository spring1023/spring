local _events = {}
local _eventId = 0
local _allEvents = {}

local Event = {}

function Event.addEvent(eventNames)
    if type(eventNames)~="table" then
        eventNames = {eventNames}
    end
    for _, eventName in ipairs(eventNames) do
        if not Event[eventName] then
            _eventId = _eventId+1
            _events[_eventId] = eventName
            Event[eventName] = _eventId
        end
    end
end

function Event.init()
    _allEvents = {}
end

function Event.registerEvent(events, target, callback)
    if type(events) ~= "table" then
        events = {events}
    end
    for _, event in ipairs(events) do
        if not _allEvents[event] then
            _allEvents[event] = {}
        end
        _allEvents[event][target] = callback
    end
end

function Event.unregisterAllEvents(target)
    for _, events in pairs(_allEvents) do
        if events[target] then
            events[target] = nil
        end
    end
end

function Event.unregisterEvent(events, target)
    if type(events) ~= "table" then
        events = {events}
    end
    for _, event in ipairs(events) do
        if _allEvents[event] and _allEvents[event][target] then
            _allEvents[event][target] = nil
        end
    end
end

function Event.bindEvent(node,events,target,callback)
    local function stateFunc(eventType)
        if eventType == "enter" then
            Event.registerEvent(events, target, callback)
        elseif eventType == "exit" then
            Event.unregisterEvent(events, target)
        end
    end
    node:registerScriptHandler(stateFunc)
    if node:getParent() then
        Event.registerEvent(events, target, callback)
    end
end

function Event.sendEvent(event,params)
    if _allEvents[event] then
        for k,v in pairs(_allEvents[event]) do
            if type(k) == "string" then
                local truncate = v(event,params)
                if truncate then
                    break
                end
            else
                local truncate = v(k,event,params)
                if truncate then
                    break
                end
            end
        end
    end
end

Event.addEvent({"EventDialogOpen","EventDialogClose"})

_G["Event"] = Event
return Event