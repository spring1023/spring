if not _G["unpack"] then
    _G["unpack"] = table.unpack
end

_G["Handler"] = Script.createBasicHandler
_G["ButtonHandler"] = Script.createCallbackHandler

RegLife = cc.Node.registerScriptHandler
RegUpdate = cc.Node.scheduleUpdateWithPriorityLua
UnregUpdate = cc.Node.unscheduleUpdate

N2S = StringManager.getNumberString
Localize = StringManager.getString
SG = StringManager.getString
Localizef = StringManager.getFormatString
Localizet = StringManager.getTimeString
