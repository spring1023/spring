GMethod.setConfigMode(GEngine.rawConfig.DEBUG_CONFIG)

GMethod.loadScript("game.ProgressBar")
GEngine.lockG(false)
GMethod.loadScript("game.FlyObject")

GEngine.lockG(true)
GMethod.loadScript("game.Build.Build")
GMethod.loadScript("game.GameNetwork")
GMethod.loadScript("game.GameLogic")
GMethod.loadScript("game.GameLogic.BuffUtil")
GMethod.loadScript("game.GameLogic.BattleUtil")

GEngine.lockG(false)
GMethod.loadScript("game.GameUI")
GMethod.loadScript("game.GameEvent")
GameUI.initLoadingEffects()

--GMethod.loadScript("game.GameEffect.GameEffect")
GMethod.loadScript("game.GameEffect.LogicEffects")
GMethod.loadScript("game.Person.PersonUtil")
GMethod.loadScript("game.Dialog.Dialog")
GMethod.loadScript("game.UI.dialog.DialogManage")
GMethod.loadScript("game.GameLogic.DataCache")
_G.LGBT = GMethod.loadScript("game.GameLogic.LogicTemplates.BaseTemplate")
GMethod.loadScript("support.Spnum")
GEngine.lockG(true)
GMethod.loadScript("support.Clone")
GMethod.loadScript("support.bit")

local lsynTime = 0
local enum = 0
local function gameTrack(msg)
    if os.time()-lsynTime<=10 then
        return
    end
    lsynTime = os.time()
    log.e("----------------------------------------")
    log.e("LUA ERROR: " .. tostring(msg) .. "\n")
    log.e(debug.traceback())
    local estr = "LUA ERROR: " .. tostring(msg) .. "\n" .. debug.traceback()
    enum = enum+1
    if enum <= 3 then
        GameNetwork.request("error",{error=estr, other=GameLogic.otherGlobalInfo},GMethod.doNothing)
        GameLogic.otherGlobalInfo = nil
        if buglyReportLuaException then
            buglyReportLuaException(tostring(msg), debug.traceback())
        end
        -- local alertTable = {title="Error", msg=debug.traceback(), buttons={"Ok"}}
        -- NativeAlert:createAlert(ButtonHandler(GMethod.doNothing), json.encode(alertTable)):show()
    elseif enum > 100 then
        enum = 0
    end
    log.e("----------------------------------------")
end
_G.__G__TRACKBACK__ = gameTrack


-- 重写系统事件；
local EngineEvents = { Create = 0, Destroy = 1, Pause = 2, Resume = 3, KeyDown = 4,
                            Notification = 5, MemoryWarning = 6, SystemLog = 7}

local function doQuitHandler(code)
    if GMethod._tempEntry then
        GMethod.unschedule(GMethod._tempEntry)
        GMethod._tempEntry = nil
    end
    if code == -1 then
        return
    else
        xpcall(GameLogic.push, gameTrack)
        GEngine.quitGame()
    end
end

local function engineEventHandler(event, intParam, otherParam)
    if event == EngineEvents.KeyDown then
        if intParam == 6 then
            if GEngine.rawConfig.singleExit and Plugins.singleSdk then
                local function innerExit(code)
                    if code == 0 then
                        GMethod._tempEntry = GMethod.schedule(Handler(doQuitHandler, 1), 0.1, false)
                    else
                        return
                    end
                end
                Plugins.singleSdk:sendCommand(Plugins.slot:getPluginRequestCode(Script.createCallbackHandler(innerExit)), 5, json.encode({view="exit"}))
                return
            end
            local alertTable = {title=Localize("labelQuitGame"), msg=Localize("textQuitGame"), buttons={Localize("btnCancel"), Localize("btnYes")}}
            NativeAlert:createAlert(ButtonHandler(doQuitHandler), json.encode(alertTable)):show()
        end
    elseif event == EngineEvents.Pause then
        GameLogic.dumpCmds(true)
        xpcall(GameLogic.push, gameTrack)
    elseif event == EngineEvents.Resume then
        Native:clearLocalNotification()
        local ad = GameLogic.getUserContext()
        if ad then
            ad = ad.activeData
            if ad then
                ad:finishTcodeAct()
            end
        end
    elseif event == EngineEvents.Notification then
        if intParam == 2 then
            if otherParam == "LogoutInSdk" then
                local loginType = GEngine.getConfig("lastLoginMsg")[2]
                Plugins:logoutWithSdk(loginType)
                GEngine.setConfig("lastLoginMsg","",true)
                GEngine.restart()
            elseif otherParam == "PaySuccess" then
                if GameLogic.tempCancelParams then
                    GameLogic.purchaseLock = true
                    GameLogic.forReloadRewardsTime = 0
                    GameLogic.forReloadRewardsTimeAll = 0
                    GameLogic.needReloadRewards = true
                    if GameLogic.tempCancelParams.callback then
                        GameLogic.tempCancelParams.callback(0)
                    end
                    GameLogic.tempCancelParams = nil
                end
            elseif otherParam == "PayFail" then
                if GameLogic.tempCancelParams then
                    GameLogic.tempCancelParams = nil
                    Plugins:onFacebookStat("PrePaymentInfo", 0)
                end
            elseif otherParam == "ExitGame" then
                GMethod._tempEntry = GMethod.schedule(Handler(doQuitHandler, 1), 0.1, false)
            end
        end
    elseif event == EngineEvents.Destroy then
        if music.setState then
            music.setState(false)
        end
    end
end

local engine = GEngine.engine
if engine.registerLuaEventHandler then
    engine:registerLuaEventHandler(ButtonHandler(engineEventHandler))
end

-- 因为String也是引擎层的代码，因此先将该部分代码重写一遍
if not StringManager.addStrings then
    local rawGetString = StringManager.getString
    local formatString = StringManager.formatString
    local _ext_cache = {}

    local function getString(key)
        return _ext_cache[key] or rawGetString(key)
    end

    local function getFormatString(key, param)
        return formatString(getString(key), param)
    end

    StringManager.rawGetString = rawGetString
    StringManager.getString = getString
    StringManager.getFormatString = getFormatString
    function StringManager.addStrings(tb)
        if tb then
            for k, v in pairs(tb) do
                _ext_cache[k] = v
            end
        end
    end
    Localize = getString
    Localizef = getFormatString
    SG = getString
end
