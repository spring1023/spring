--用于更新游戏的Controller
local network = GMethod.loadScript("engine.network")
local Loading = {}

function Loading:startConnect()
    GEngine.lockG(true)
    GMethod.loadScript("game.GameLogic")
    GEngine.lockG(false)
    GameLogic.loadLanguage()
    local usid = nil
    local function innerLoading(diff)
        if usid then
            GMethod.unschedule(usid)
            usid = nil
            cc.Director:getInstance():getOpenGLView():setDesignResolutionSize(
                display.winSize[2] * 16/9, display.winSize[2], cc.ResolutionPolicy.SHOW_ALL)
            display.init(GEngine.rawConfig.designSize)
        elseif diff >= 0 then
            return
        end
        self.logoView = GMethod.loadScript("game.View.Logo")
        self.loadingView = GMethod.loadScript("game.View.Loading")
        self.loadingView:setLoadingState("init")
        self.loadingView:setPercent(0)
        if self.logoView then
            self.logoView:show(self.loadingView)
        else
            self.loadingView:show()
        end
        self:startLoading()
    end
    if display.winSize[2] / display.winSize[1] <= 9 / 16 - 0.1 and not GEngine.rawConfig.fixIphoneX then
        -- 原来的代码有点小BUG，所以延迟1秒再重启
        usid = GMethod.schedule(innerLoading, 0.1)
        return
    end
    innerLoading(-1)
end

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
    elseif event == EngineEvents.Notification then
        if intParam == 2 then
            if otherParam == "ExitGame" then
                GMethod._tempEntry = GMethod.schedule(Handler(doQuitHandler, 1), 0.1, false)
            end
        elseif intParam == 3 then
            Loading.loadingView:setPercent(tonumber(otherParam))
        elseif intParam == 4 then
            local jsonParam = json.decode(otherParam)
            Loading.loadingView:setPercent(math.floor(jsonParam.finish * 100 / jsonParam.total))
        end
    elseif event == EngineEvents.Destroy then
        if music.setState then
            music.setState(false)
        end
    end
end

function Loading:startLoading()
    --关联设备对话框
    GEngine.export("RelationDialog", GMethod.loadScript("game.UI.dialog.systemDialog.RelationDialog"))
    local engine = GEngine.engine
    if engine.registerLuaEventHandler then
        engine:registerLuaEventHandler(ButtonHandler(engineEventHandler))
    end
    self:startDownloadingRequest()
    self.timeEntry = GMethod.schedule(Handler(self.updateLoading, self), 0.1, false)
end

function Loading:startNewDownload()
    local rp = cc.FileUtils:getInstance():getWritablePath()
    local allFiles = GEngine.getConfig("newDownloadFiles")
    if type(allFiles) ~= "string" then
        allFiles = "[]"
    end
    allFiles = json.decode(allFiles)

    local __fileMap = {}
    for _, file in ipairs(allFiles) do
        __fileMap[file[1]] = file
    end
    self.__tryFileMap = __fileMap
    local cfs = cc.FileUtils:getInstance()
    local myPath = cfs:getWritablePath()
    for i=5, 30 do
        local fname = "data" .. i .. ".pkg"
        local dfilePath = myPath .. fname
        if cfs:isFileExist(dfilePath) and not __fileMap[fname] then
            GEngine.engine:getPackageManager():unloadPackage(fname)
            cfs:removeFile(dfilePath)
        end
    end
    -- 下载用的插件
    local engine = GameEngine:getInstance()
    local slot = engine:getPluginSlot()
    local plugin = slot:getPlugin("PluginFileDownloader")
    -- 检查本地文件是否可正常访问、是否有删除、是否要下载之类的
    plugin:sendCommand(slot:getPluginRequestCode(Script.createCallbackHandler(self.checkDownloadFiles, self)), 4, json.encode({rtype=1, files=allFiles, path=rp}))
end

function Loading:checkDownloadFiles(code, result)
    if code == 0 then
        result = json.decode(result)
        if result.downloadSize > 0 or result.files then
            -- 确认下载
            local function doRealDownload()
                -- 在这里取消加载所有需要处理或者删除的pkg
                for _, fname in ipairs(result.files) do
                    GEngine.engine:getPackageManager():unloadPackage(fname)
                end
                if result.downloadSize > 0 then
                    self.loadingView:setLoadingState("download")
                end
                self.__tryResult = result
                self.waitingForPlugin = true
            end
            if result.downloadSize > 10*1024*1024 then
                local size = math.floor(result.downloadSize * 100 / 1024 / 1024) / 100
                local otherSettings = {mode=3, title = Localize("alertTitleNormal"), text = Localizef("noticeMoreDownload", {a=size})}
                otherSettings.cancelCall = GEngine.quitGame
                RelationDialog.new(otherSettings, doRealDownload)
            else
                --要延迟一帧，错开回调
                doRealDownload()
            end
        else
            -- 没有需要下载的内容
            if result.okFiles then
                for _, fname in ipairs(result.okFiles) do
                    GEngine.engine:getPackageManager():loadPackage(fname)
                end
            end
            self.loadingOver = true
        end
    else
        -- 失败的时候是不是应该报错？
        local otherSettings = {mode=3, title = Localize("labelDownloadFailed"), text = Localize("labelDownloadFailedAndRetry")}
        otherSettings.cancelCall = GEngine.quitGame
        RelationDialog.new(otherSettings, Handler(self.startNewDownload, self))
    end
end

function Loading:checkVersionOver(isSuc, data)
    log.d("download result:%s",json.encode(data))
    if isSuc then
        data = json.decode(data)
        -- 先做个兼容吧，感觉不可能出这个问题才对
        if not data then
            self.retryError = true
            return
        end
        -- 增加新版功能支持
        if data.redirectUrl then
            GEngine.setConfig("EngineRedirectUrl", data.redirectUrl, true)
            GEngine.saveConfig()
            self:startDownloadingRequest()
            return
        end
        if data.ipCountry then
            GEngine.setConfig("EngineIpCountry", data.ipCountry, true)
            GEngine.saveConfig()
        end
        local alert = data.alert
        if alert then
            self.needAlert = alert
        end
        if data.dlist then
            if GEngine.rawConfig.useNewDownload and data.fmax then
                GEngine.setConfig("newDownloadFiles", json.encode(data.dlist), true)
                GEngine.setConfig("newScriptVersion", data.fmax, true)
                GEngine.saveConfig()
            end
            data = data.dlist
        end
        if GEngine.rawConfig.useNewDownload then
            self.waitingForDownloading = true
        else
            if #data>0 then
                self.dlist = data
                self.newMid = 0
                self.fdnum = 0
                self.waitingForDownloading = true
            else
                self.loadingOver = true
            end
        end
    else
        self.retryError = true
    end
end

function Loading:tryDownLoad()
    local engine = GameEngine:getInstance()
    local slot = engine:getPluginSlot()
    local plugin = slot:getPlugin("PluginApkObb")
    plugin:sendCommand(slot:getPluginRequestCode(Script.createCallbackHandler(self.loadObbResutl, self)), 5, json.encode({rtype=1}))
end

function Loading:quitGame()
    GEngine.quitGame()
end

-- 0、obb包完整，继续游戏；4、下载失败，弹出重新加载界面；
function Loading:loadObbResutl(code, result)
    local task = self.taskList[1]
    if code == 0 then
        task[2] = 100
        local _result = json.decode(result)
        for k, v in pairs(_result) do
            GameEngine:getInstance():getPackageManager():loadPackage(v)
        end
    elseif code == 4 then
        local otherSettings = {}
        otherSettings.cancelCall = self.quitGame
        local LoadObbDialog = GMethod.loadScript("game.Dialog.LoadObbDialog")
        display.showDialog(LoadObbDialog.new(otherSettings, Handler(self.tryDownLoad, self)), false)
    end
end

function Loading:finishDownloadFiles(code, result)
    if code == 0 then
        -- local okFiles = json.decode(result).okFiles
        -- for _, fname in ipairs(okFiles) do
        --     GEngine.engine:getPackageManager():loadPackage(fname)
        -- end
        -- self.newMid = nil
        -- self.fdnum = nil
        -- self.dlist = nil
        -- GameUpdateSuccess.new()
        GEngine.restart()
    else
        -- 可能出毛病了，做个临时处理试试？
        if not self.__tryOld then
            self.__tryOld = true
            self.__tryResult.downloadedSize = 0
            self.__tryResult.downloadedFile = 0
            self.__tryResult.dfiles = {}
            self.__doFixDownload = true
            return
        end
        local function doRealDownload()
            self.waitingForPlugin = true
        end
        local otherSettings = {mode=3, title = Localize("labelDownloadFailed"), text = Localize("labelDownloadFailedAndRetry")}
        otherSettings.cancelCall = GEngine.quitGame
        RelationDialog.new(otherSettings, doRealDownload)
    end
end

function Loading:onFixPercentDownload(percent)
    if not percent then
        log.e("error download?")
    else
        local file = self.__tryResult.files[self.__tryResult.downloadedFile + 1]
        local fileSetting = self.__tryFileMap[file]
        local dmax = self.__tryResult.downloadSize
        if dmax < 1 then
            dmax = 1
        end
        self.loadingView:setPercent(math.floor((self.__tryResult.downloadedSize*100 +
            fileSetting[4] * percent)/dmax))
    end
end

function Loading:onFixFinishDownload(suc)
    if suc then
        local file = self.__tryResult.files[self.__tryResult.downloadedFile + 1]
        local fileSetting = self.__tryFileMap[file]
        self.__tryResult.downloadedSize = self.__tryResult.downloadedSize + fileSetting[4]
        self.__tryResult.downloadedFile = self.__tryResult.downloadedFile + 1
        self.__doFixDownload = true
        local dmax = self.__tryResult.downloadSize
        if dmax < 1 then
            dmax = 1
        end
        self.loadingView:setPercent(math.floor(self.__tryResult.downloadedSize*100/dmax))
    else
        -- 这次特么是真失败了
        local function doRealDownload()
            GEngine.restart()
        end
        local otherSettings = {mode=3, title = Localize("labelDownloadFailed"), text = Localize("labelDownloadFailedAndRetry")}
        otherSettings.cancelCall = GEngine.quitGame
        RelationDialog.new(otherSettings, doRealDownload)
    end
end

function Loading:doFixDownload()
    local file = self.__tryResult.files[self.__tryResult.downloadedFile + 1]
    if not file then
        -- 都搞定了，再
        return self:startNewDownload()
    end
    local fileSetting = self.__tryFileMap[file]
    local fname = cc.FileUtils:getInstance():getWritablePath() .. file
    local cp = {self}
    network.httpRequest(fileSetting[2], network.DOWNLOAD, {},
        {path=fname .. ".fd", single=false, multi=true, callback=self.onFixFinishDownload,
        callbackParams=cp, percentCallback=self.onFixPercentDownload, percentParams=cp})
end

function Loading:updateLoading()
    if self.taskList then
        local task = self.taskList[1]
        if not task then
            self.taskList = nil
        elseif task[1] == "checkSum" then
            self:doCheckSum(task)
            if task[7] then
                table.remove(self.taskList, 1)
                if task[3] == "temp" then

                    local sum = task[7]
                    if self.dfileSum then
                        if self.dfileSum ~= sum then
                            --检查失败，重新下载
                            self.retry = (self.retry or 0)+1
                            print("check sum error, retry", self.retry, self.dfileSum, sum)
                            if self.retry >= 3 then
                                -- 失败3次了仍然有问题，则先当成成功予以通过
                                self.retry = 0
                            else
                                self:startDownload()
                                return
                            end
                        else
                            self.retry = 0
                        end
                    end
                    self.mySums[self.dfileKey] = sum
                    local cf = cc.FileUtils:getInstance()
                    cf:removeFile(self.dfileName)
                    cf:renameFile(self.dfileName .. ".fd", self.dfileName)
                    self.fdnum = self.fdnum+1

                    self.loadingView:setPercent(math.ceil(self.fdnum/(#self.dlist)*100))
                    self:startDownload()
                else
                    self.mySums[task[3]] = task[7]
                    self.myCheckNum = self.myCheckNum + 1
                    self.loadingView:setPercent(math.floor(self.myCheckNum/self.myCheckTotal*100))
                end
                GEngine.setConfig("EngineFileSums", json.encode(self.mySums), true)
                GEngine.saveConfig()
            else
                local dcheckNum = task[6]
                if dcheckNum > 30 then
                    dcheckNum = 30
                end
                if task[3] == "temp" then
                    local dtotal = #self.dlist
                    self.loadingView:setPercent(math.floor(dcheckNum*10/6/dtotal + (self.fdnum+0.5)/dtotal*100))
                else
                    self.loadingView:setPercent(math.floor(dcheckNum*10/3/self.myCheckTotal + self.myCheckNum/self.myCheckTotal*100))
                end
            end
        elseif task[1] == "download" then
            table.remove(self.taskList, 1)
            self:startRealRequest()
        elseif task[1] == "obb" then
            if (not task[2]) and self.logoView.loadingResOver then
                -- start download
                local engine = GameEngine:getInstance()
                local slot = engine:getPluginSlot()
                local plugin = slot:getPlugin("PluginApkObb")
                if plugin then
                    task[2] = 0
                    plugin:sendCommand(slot:getPluginRequestCode(Script.createCallbackHandler(self.loadObbResutl, self)), 5, json.encode({rtype=1}))
                else
                    task[2] = 100
                end
            elseif task[2] == 100 then
                table.remove(self.taskList, 1)
                self.loadingView:setLoadingState("version")
            end
        end
    end

    local logo = self.logoView
    if logo and logo.state~="cleanup" or self.locked then
        return
    end
    if self.needAlert then
        local alert = self.needAlert
        local function doSystemAlert(code)
            if code == -1 then
                if alert.action == "quit" then
                    GEngine.quitGame()
                elseif alert.action == "download" then
                    Native:openURL(alert.url)
                elseif alert.action == "mail" then
                    local mail = alert.mail
                    Native:sendEmail(mail.address, mail.title or "", mail.content or "")
                end
            end
            self.needAlert = nil
            self.locked = nil
        end
        if alert.useSystem then
            NativeAlert:createAlert(ButtonHandler(doSystemAlert), json.encode(alert.dialog)):show()
        else
            local otherSettings = alert.dialog
            if alert.force then
                otherSettings.cancelCall = Handler(doSystemAlert, -1)
            else
                otherSettings.cancelCall = Handler(doSystemAlert, -2)
            end
            RelationDialog.new(otherSettings, Handler(doSystemAlert, -1))
        end
        self.locked = true
        return
    end
    if self.waitingForDownloading then
        self.waitingForDownloading = nil
        if GEngine.rawConfig.useNewDownload then
            self:startNewDownload()
        else
            self:startDownload()
        end
    end
    if self.waitingForPlugin then
        -- 下载用的插件
        local engine = GameEngine:getInstance()
        local slot = engine:getPluginSlot()
        local plugin = slot:getPlugin("PluginFileDownloader")
        -- 检查本地文件是否可正常访问、是否有删除、是否要下载之类的
        plugin:sendCommand(slot:getPluginRequestCode(Script.createCallbackHandler(self.finishDownloadFiles, self)), 4, json.encode({rtype=2}))
        self.waitingForPlugin = nil
    end
    if self.__doFixDownload then
        self.__doFixDownload = nil
        self:doFixDownload()
        return
    end
    if self.retryError then
        self.retryError = nil

        local otherSettings = {mode=3, title = Localize("labelNetError"), text = Localize("labelPleaseRetry")}
        otherSettings.cancelCall = GEngine.quitGame
        RelationDialog.new(otherSettings, Handler(self.startDownloadingRequest, self))
        -- self.step = self.step-1
        -- self.locked = false
    elseif self.loadingOver then
        self.loadingOver = nil
        GMethod.unschedule(self.timeEntry)
        self.timeEntry = nil
        GEngine.engine:getPackageManager():unloadPackage("data7.pkg")
        local lc = GMethod.loadScript("game.Controller.LoadingGameController")
        self.others.ldc = lc
        lc:startConnect(self.logoView, self.loadingView)
    end
end

function Loading:doCheckSum(sumBatch)
    if not sumBatch[4] then
        sumBatch[4] = io.open(sumBatch[2], "rb")
        sumBatch[5] = {}
        sumBatch[6] = 0
        for i=1, 16 do
            sumBatch[5][i] = 0
        end
        return
    end
    if not sumBatch[7] then
        local chunk = sumBatch[4]:read(1024*64)
        if chunk then
            local cl = chunk:len()
            local j
            for i=1, cl do
                j = (i-1)%16+1
                sumBatch[5][j] = sumBatch[5][j] + chunk:byte(i)
            end
            if cl >= 1024*64 then
                sumBatch[6] = sumBatch[6] + 1
                return
            end
        end
        local sortedStr = ""
        for i=1, 16 do
            local c = sumBatch[5][i]
            c = math.floor(math.floor(c+0.5)%62+0.5)
            if c<10 then
                c = string.char(48+c)
            elseif c<36 then
                c = string.char(55+c)
            else
                c = string.char(61+c)
            end
            sortedStr = sortedStr .. c
        end
        sumBatch[7] = sortedStr
        sumBatch[4]:close()
    end
end

function Loading:startDownload()
    self.loadingView:setLoadingState("download")
    local dfile = self.dlist[self.fdnum+1]
    if not dfile then
        GEngine.setConfig("scriptVersion", self.newMid, true)
        GEngine.setConfig("EngineFileSums", json.encode(self.mySums), true)
        GEngine.saveConfig()
        self.newMid = nil
        self.fdnum = nil
        self.dlist = nil
        --GameUpdateSuccess.new()
        GEngine.restart()
    else
        local durl = dfile[1]
        local dversion = dfile[2]
        if dversion>self.newMid then
            self.newMid = dversion
        end
        --lua 文件放在data下；pkg直接放在目录下；
        local fname = durl
        local p = nil
        while true do
            p = fname:find("/")
            if p then
                fname = fname:sub(p+1)
            else
                break
            end
        end
        self.dfileKey = fname
        local rp = cc.FileUtils:getInstance():getWritablePath()
        if fname:find(".pkg") then
            GEngine.engine:getPackageManager():unloadPackage(fname)
        end
        if fname:find(".lua") then
            fname = rp .. "data/" .. fname
        else
            fname = rp .. fname
        end
        local cp = {self}
        self.dfileName = fname
        self.dfileSum = dfile[3]
        if durl == self.dfileKey then
            -- 下载链接和文件名相同，即不可下载，即需要删除该文件
            cc.FileUtils:getInstance():removeFile(self.dfileName)
            self.mySums[self.dfileKey] = nil
            self.fdnum = self.fdnum+1
            return self:startDownload()
        end
        network.httpRequest(durl, network.DOWNLOAD, {}, {path=fname .. ".fd", single=false, multi=true, callback=self.onFinishDownload, callbackParams=cp, percentCallback=self.onPercentDownload, percentParams=cp})
        --GameNetwork.download(durl, fname, self.onFinishDownload, self.onPercentDownload, self)
    end
end

function Loading:onFinishDownload(suc)
    if suc then
        -- 检查文件是否正确
        self.taskList = {{"checkSum", self.dfileName .. ".fd", "temp"}}
    else
        self.retryError = true
    end
end

function Loading:onPercentDownload(percent)
    if not percent then
        log.e("error download?")
    else
        local dtotal = 1
        if self.dlist and type(self.dlist) == "table" and #self.dlist > 0 then
            dtotal = #self.dlist
        end
        local dnow = self.fdnum or 0
        if dnow >= dtotal then
            dnow = dtotal - 1
        end
        self.loadingView:setPercent(math.floor(percent/dtotal/2 + dnow/dtotal*100))
    end
end

function Loading:startDownloadingRequest()
    local lview = self.loadingView
    lview:setPercent(0)
    self.retryError = false

    local toCheckList = {}
    --加入obb下载检测
    if GEngine.rawConfig.needCheckObb then
        lview:setLoadingState("loadObb")
        table.insert(toCheckList, {"obb"})
    else
        lview:setLoadingState("version")
    end
    local cfs = cc.FileUtils:getInstance()
    local myPath = cfs:getWritablePath()
    if GEngine.rawConfig.useNewDownload then
    else
        local mySums = GEngine.getConfig("EngineFileSums")
        if mySums then
            mySums = json.decode(mySums)
        else
            mySums = {}
        end
        for i=5, 30 do
            local dfilePath = myPath .. "data" .. i .. ".pkg"
            if cfs:isFileExist(dfilePath) and not mySums["data" .. i .. ".pkg"] then
                table.insert(toCheckList, {"checkSum", dfilePath,"data" .. i .. ".pkg"})
            end
        end
        self.mySums = mySums
        self.myCheckTotal = #toCheckList
        self.myCheckNum = 0
    end
    table.insert(toCheckList, {"download"})
    self.taskList = toCheckList
end

function Loading:startRealRequest()
    local maxid = GEngine.getConfig("scriptVersion") or GEngine.rawConfig.innerScriptVersion
    if GEngine.rawConfig.FORCE_UPDATE then
        maxid = 0
    end
    local deviceInfo = json.decode(Native:getDeviceInfo())
    local params = {rversion=1, maxid=maxid, cv=GEngine.rawConfig.version, cc=GEngine.rawConfig.versionCode, channel=GEngine.rawConfig.channel, platform=deviceInfo.platform, device=deviceInfo.deviceId}
    if GEngine.rawConfig.useNewDownload and not GEngine.rawConfig.inTest then
        -- 新版下载走另一套逻辑
        params.rversion = 2
        maxid = GEngine.getConfig("newScriptVersion") or 0
        if maxid < GEngine.rawConfig.innerScriptVersion then
            maxid = GEngine.rawConfig.innerScriptVersion
        end
        params.maxid = maxid
        params.innerId = GEngine.rawConfig.innerScriptVersion
    else
        params["sums"] = json.encode(self.mySums)
    end
    local rawUrl = GEngine.getConfig("EngineRedirectUrl")
    if type(rawUrl)~="string" or rawUrl == "" or not rawUrl:find("http") then
        rawUrl = GEngine.rawConfig.rawUrl
    end
    local country = GEngine.getConfig("EngineIpCountry")
    if type(country) == "string" and country ~= "" then
        params["ipCountry"] = country
    end
    params["country"] = deviceInfo.country
    params["language"] = General.language
    params["deviceLan"] = deviceInfo.language
    params["testNewCode"] = 1
    if GEngine.rawConfig.inTest then
        GEngine.rawConfig.useNewDownload = nil
        self:checkVersionOver(true, "[]")
    else
        network.httpRequest(rawUrl, network["POST"], params, {urlName = "version", isChat = false, retry=0, single=true, multi=false, callback=self.checkVersionOver, callbackParams={self}, normal=true})
    end
    if _G["jit"] then
        if GEngine.getPlatform() == cc.PLATFORM_OS_ANDROID then
            local status = jit.status()
            if status then
                jit.off()
            end
        end
    end
end

return Loading
