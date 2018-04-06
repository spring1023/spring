--用于实际加载游戏的Controller
local const = GMethod.loadScript("game.GameLogic.Const")
local Loading = {}

local ProductFix = {["card0"] = "newcard0", ["card1"] = "newcard1"}
-- 墨菲版本的支付项有点区别
if GEngine.rawConfig.channel:find("com.mofei.clash_mofei") then
    ProductFix.card0 = "card0"
    ProductFix.card1 = "card1"
end

function Loading:startConnect(logo, lv)
    self.logoView = logo
    self.loadingView = lv
    self:startLoading()
end

function Loading:getConfigOver(isSuc, data)
    -- 先临时写一个只下载不管三七二十一的玩意儿
    local DownloadUtil = GMethod.loadScript("game.GameLogic.DownloadUtil")
    local GameSetting = GMethod.loadScript("game.GameSetting")
    local sid = self.enterData[3][1]
    local allDownloads = GameSetting.getLocalData(0, "dfiles")
    local allDownloadUrls = GameSetting.getLocalData(0, "durls")
    self.lockDownload = 1
    if not allDownloadUrls then
        allDownloadUrls = {}
        GameSetting.setLocalData(0, "durls", allDownloadUrls)
    end
    local dkey = "texts" .. sid .. General.language
    if data.texts then
        allDownloads[dkey] = data.texts[2]
        allDownloadUrls[dkey] = data.texts[1]
    end
    if allDownloads[dkey] then
        self.lockDownload = self.lockDownload + 1
        DownloadUtil.addLittlePkgTask(allDownloadUrls[dkey], allDownloads[dkey],
            self, self.onFinishDownload)
    end
    dkey = "acts" .. sid
    if data.acts then
        allDownloads[dkey] = data.acts[2]
        allDownloadUrls[dkey] = data.acts[1]
    end
    if allDownloads[dkey] then
        self.lockDownload = self.lockDownload + 1
        DownloadUtil.addLittlePkgTask(allDownloadUrls[dkey], allDownloads[dkey],
            self, self.onFinishDownload)
    end
    dkey = "datas" .. sid
    if data.datas then
        allDownloads[dkey] = data.datas[2]
        allDownloadUrls[dkey] = data.datas[1]
    end
    if allDownloads[dkey] then
        self.lockDownload = self.lockDownload + 1
        DownloadUtil.addLittlePkgTask(allDownloadUrls[dkey], allDownloads[dkey],
            self, self.onFinishDownload)
    end
    GameSetting.setLocalData(0, "dfiles", allDownloads, true)
    self:onFinishDownload(true)
end

function Loading:onFinishDownload(suc)
    if suc then
        self.lockDownload = self.lockDownload - 1
        if self.lockDownload <= 0 then
            self.locked = false

            -- 删除无用文件
            local GameSetting = GMethod.loadScript("game.GameSetting")
            local allDownloads = GameSetting.getLocalData(0, "dfiles")
            local allFiles = GameSetting.getLocalData(0, "localfiles") or {}
            local _map = {}
            for k, v in pairs(allDownloads) do
                _map[v] = 1
            end
            for k, _ in pairs(allFiles) do
                if not _map[k] then
                    local cfs = cc.FileUtils:getInstance()
                    cfs:removeFile(cfs:getWritablePath() .. k .. ".pkg")
                end
            end
            GameSetting.setLocalData(0, "localfiles", _map, true)
        end
    else
        local otherSettings = {mode=3, title = Localize("labelNetError"), text = Localize("labelPleaseRetry")}
        otherSettings.cancelCall = GEngine.quitGame
        RelationDialog.new(otherSettings, Handler(self.onRetry, self))
    end
end

function Loading:onRetry()
    self.locked = false
    self.step = self.step-1
end

function Loading:getDataOver(isSuc, data)
    self.locked = false
    if isSuc then
        if data.code == 1 then
            data.atktime = data.atktime or 10--攻打剩余时间
            self.locked = true
            WarReportIn.new(data,function()
                self.step = self.step-1
                self.locked = false
            end)
            return
        end
        if data.initTime then
            const.InitTime = data.initTime
        end
        GameLogic.setSTime(data.stime)
        -- 达人赛逻辑开启；大概用服务端配置会好一点？先临时写死
        GameLogic.useTalentMatch = data.useTalentMatch

        --加载系统设置
        local GameSetting = GMethod.loadScript("game.GameSetting")
        GameSetting.shareConfig = data.shareConfig or 1
        GameSetting.init()
        local sid = self.enterData[3][1]
        local allDownloads = GameSetting.getLocalData(0, "dfiles")
        local packager = GEngine.engine:getPackageManager()

        -- 加载一些策划随时想改着玩的配置……因为这会放在客户端所以一定要做加密防修改
        local dkey = allDownloads["texts" .. sid .. General.language]
        if dkey then
            packager:loadPackage(dkey .. ".pkg")
            local ccstr = cc.FileUtils:getInstance():getStringFromFile("GVTexts.json")
            if ccstr then
                ccstr = json.decode(ccstr)
                if ccstr then
                    StringManager.addStrings(ccstr)
                end
            end
            packager:unloadPackage(dkey .. ".pkg")
        end
        dkey = allDownloads["datas" .. sid]
        if dkey then
            packager:loadPackage(dkey .. ".pkg")
            local ccstr = cc.FileUtils:getInstance():getStringFromFile("GVDatas.json")
            if ccstr then
                ccstr = json.decode(ccstr)
                if ccstr then
                    local StaticData = GMethod.loadScript("data.StaticData")
                    for tbname, tbdata in pairs(ccstr) do
                        local newData = {}
                        local keys = tbdata.keys
                        local cols = tbdata.cols
                        local kl = #keys
                        local vl = #cols
                        local tmp, tmp2
                        for _, data in ipairs(tbdata.datas) do
                            if data["1"] then
                                local tmpData = {}
                                for k, v in pairs(data) do
                                    tmpData[tonumber(k)] = v
                                end
                                data = tmpData
                            end
                            tmp = newData
                            for i = 1, kl do
                                tmp2 = {}
                                if i == kl then
                                    tmp2 = KT(tmp2)
                                end
                                if not tmp[data[i]] then
                                    tmp[data[i]] = tmp2
                                end
                                tmp = tmp[data[i]]
                            end
                            if vl == 1 then
                                if kl == 1 then
                                    newData[data[1]] = data[2]
                                else
                                    newData[data[1]][data[2]] = data[3]
                                end
                            else
                                for i = 1, vl do
                                    tmp[cols[i]] = data[i+kl]
                                end
                            end
                        end
                        KTFix(newData)
                        StaticData.setData(tbname, newData)
                    end
                end
            end
            packager:unloadPackage(dkey .. ".pkg")
        end

        local context = GameLogic.newContext(GameLogic.uid)
        data.id = context.uid
        GameLogic.setUserContext(context)
        context:loadContext(data)
        GameLogic.operationTime = data.stime
        context.guide:initGuideStep(self)
        dkey = allDownloads["acts" .. sid]
        if dkey then
            packager:loadPackage(dkey .. ".pkg")
            local ccstr = cc.FileUtils:getInstance():getStringFromFile("GVActs.json")
            if ccstr then
                ccstr = json.decode(ccstr)
                if ccstr then
                    if context.activeData then
                        context.activeData.serverInit = data.serverInit or 0
                        context.activeData:initConfigableActs(ccstr)
                    end
                end
            end
            packager:unloadPackage(dkey .. ".pkg")
        elseif context.activeData then
            context.activeData.serverInit = data.serverInit or 0
            context.activeData:initConfigableActs(GMethod.loadConfig("configs/acts.json"))
        end

        -- 初始化可配置活动
        if context.activeData then
            --初始化触发型配置活动
            if context:getProperty(const.ProTriggleNum) % 2 == 0 then
                context.activeData:initTriggerBag()
            end
            context.activeData:loadConfigableRecords(data.actsrecord, data.actsreward, data.actstriggle)
            if not GameLogic.useTalentMatch then
                context.activeData:initDailyTaskData({data.dtinfo, data.dtdatas})
            else
                -- 头像自动升阶处理
                local cprogress = context:getProperty(const.ProSpecialHeadFlag)
                local curValue = context:getInfoItem(const.InfoCryNum)
                local hasChange = false
                local StaticData = GMethod.loadScript("data.StaticData")
                local needValues = StaticData.getData("constsNew", 5).data
                local headId = context:getInfoItem(const.InfoHead)
                local backLv = headId % 10
                if backLv == 5 then
                    backLv = 3
                elseif backLv < 5 and backLv > 2 then
                    backLv = backLv + 1
                end
                while needValues[cprogress+2] and needValues[cprogress+2] <= curValue do
                    hasChange = true
                    cprogress = cprogress + 1
                end
                if hasChange then
                    context:setProperty(const.ProSpecialHeadFlag, cprogress)
                    context:addCmd({const.CmdActTriggleInit, const.ProSpecialHeadFlag, cprogress})
                    if backLv < cprogress + 1 then
                        if cprogress == 2 then
                            cprogress = 5
                        elseif cprogress < 2 or cprogress > 4 then
                            cprogress = cprogress + 1
                        end
                        headId = headId - (headId%10) + cprogress
                        context:setInfoItem(const.InfoHead, headId)
                        context:addCmd({const.CmdHeadChange, headId})
                    end
                end
            end
        end

        Plugins.inReview = data.inReview
        GameLogic.inTest = data.inTest
        if data.mergeServer then
            for _, v in ipairs(data.mergeServer[1]) do
                if v == context.sid then
                    context.mergeSid = data.mergeServer[2]
                end
            end
        end

        local lastLoginMsg = GEngine.getConfig("lastLoginMsg")
        if lastLoginMsg and lastLoginMsg~="" then
            local lgmsg = json.decode(lastLoginMsg)
            --统计账户基本信息
            local params={callKey=0,
                uid=tostring(context.uid),
                sid=tostring(context.sid),
                level=context.buildData:getTownLevel(),
                uname= GameLogic.doSaveEncode(context:getInfoItem(const.InfoName)),
                ulv=context:getInfoItem(const.InfoLevel),
                sname=Localize("dataServerName"..context.sid),
                gem=context:getRes(const.ResCrystal),
                viplv=context:getInfoItem(const.InfoVIPlv),
                ub=GameLogic.doSaveEncode(context.union and context.union.name or ""),
                balance=context:getProperty(const.ResCrystal),
                regtime=context:getInfoItem(const.InfoRegTime)
            }
            if lgmsg[2]==1 then
                params.aType="Anonymous"
            elseif lgmsg[2]==2 then
                params.aType="gamecenter"
            elseif lgmsg[2]==3 then
                params.aType="facebook"
            elseif lgmsg[2]==4 then--android下,暂定
                params.aType="type3"
            elseif lgmsg[2] > 6 and lgmsg[2] == GEngine.rawConfig.loginChannel then
                params.aType = "type" .. lgmsg[2]
            end
            Plugins:onStat(params)
        end
        local ucontext = GameLogic.getUserContext()
        if ucontext.guide:getCurrentState() <= 1 then
            GameLogic.statForSnowfish("createrole")
            GameLogic.statForSnowfish("postActivitionData")
        end
        GameLogic.statForSnowfish("enterServer")
        GameLogic.statForSnowfish("enterGame")
        GameLogic.statForSnowfish("postRoleLoginData")
    else
        self.step = self.step-1
    end
end

function Loading:loginOver(isSuc,data)
    if isSuc then
        self.loginData = data
        self.loadingView:setLoadingState("loginAf")
    else
        -- self.step = self.step-1
        -- self.locked = false
    end
end

function Loading:getuserinfoOver(isSuc,data)
    self.locked = false
    if isSuc then
        GameLogic.uid = data.uid
        if cc.FileUtils:getInstance():isFileExist("test.json") then
            GameLogic.uid = GMethod.loadConfig("test.json").uid
        end
        GameLogic.randnum = 0
        GameLogic.zid = data.zid
        local sv = self.enterData[3]
        GameLogic.server = sv

        --tcode是邀请码，tlist是被邀请列表,tlist=[[uid,tid,ulv,uname,uhead,ucrystal,sid]]
        GameLogic.tcode = data.tcode or 0
        GameLogic.tlist = data.tlist or {}
        GameLogic.tcodeUsed = data.tcodeUsed
        if data.isNew then
            local lastLoginMsg = GEngine.getConfig("lastLoginMsg")
            local lgmsg = (lastLoginMsg and lastLoginMsg~="") and json.decode(lastLoginMsg) or nil
            if lgmsg then
                Plugins:onFacebookStat("PreRegister", lgmsg[2])
            end
        end
    end
end

function Loading:onResyncCmdsOver(eidx, suc, data)
    if suc then
        GEngine.setConfig("cmds_data_" .. GameLogic.uid, "", true)
        GEngine.setConfig("last_syn_uid", 0, true)
        GEngine.saveConfig()
        self.locked = false
    else
        -- self.step = self.step-1
        -- self.locked = false
    end
end

function Loading:loading(diff)
    local logo = self.logoView
    if (logo and logo.state~="cleanup") or self.locked then
        if self.lockedItem then
            if self.lockedItem == "builds" then
                if self.scene.loadBuildsThread then
                    coroutine.resume(self.scene.loadBuildsThread, self.scene)
                    self.loadingView:setPercent(math.floor((self.step+self.scene.lbpercent-1)*100/self.loadMax))
                else
                    self.lockedItem = nil
                    self.locked = nil
                end
            elseif self.lockedItem == "res" then
                if self.asynctotal <= self.asyncfinish then
                    self.lockedItem = nil
                    self.locked = nil
                else
                    self.loadingView:setPercent(math.floor((self.step+self.asyncfinish/self.asynctotal-1)*100/self.loadMax))
                end
            end
        end
        return
    end
    local step = self.step+1
    self.step = step
    local stepItem = self.loadSteps[step]
    if stepItem then
    if stepItem[1] == "init" then
        local sv = GEngine.getConfig("scriptVersion") or GEngine.rawConfig.innerScriptVersion
        for i = 6, 30 do
            GEngine.engine:getPackageManager():unloadPackage("data" .. i .. ".pkg")
        end
        for i = 6, 30 do
            GEngine.engine:getPackageManager():loadPackage("data" .. i .. ".pkg")
        end
        -- 保护代码；似乎有些版本（不知道是什么原因）的代码是旧版的
        if not ui.reuseFrame then
            ui.reuseFrame = memory.getFrame
            ui.clearReuseFrame = GMethod.doNothing
        end
        GMethod.loadScript("game.GameInit")
        self.gameInit=true
        GameUI.setLoadingState(true)

        self.checkDataTimeEntry = GMethod.schedule(Handler(self.checkAndRefreshData, self),0,false)
        local scene = GMethod.loadScript("game.View.Scene")
        scene.sceneType = "operation"
        scene.battleType = nil
        scene.battleParams = nil
        scene:show()
        scene:clearAll()
        self.scene = scene
        local mc = GMethod.loadScript("game.Controller.SceneController")
        mc:setScene(scene)

        local plugins = _G["Plugins"]
        local storeItems = plugins.storeItems
        if not storeItems then
            storeItems = {}
            plugins.storeItems = storeItems
        end
        local storeItemsSafe = plugins.storeItemsSafe
        if not storeItemsSafe then
            storeItemsSafe = {}
            plugins.storeItemsSafe = storeItemsSafe
        end
        local keys = {"gem0", "gem1", "gem2", "gem3", "gem4", "gem5", "card0", "card1", "gem6", "gem7"}
        plugins.storeKeys = keys

        if not plugins.innerPrice or plugins.innerPrice < 2 then
            local language = General.language
            local values
            if language == "CN" or language == "HK" then
                values = {"12.00元", "30.00元", "68.00元", "163.00元", "328.00元", "648.00元", "68.00元", "68.00元", "1.00元", "6.00元"}
            else
                values = {"$1.99", "$4.99", "$9.99", "$24.99", "$49.99", "$99.99", "$9.99", "$9.99", "$0.99", "$0.99"}
            end
            for i=1, #keys do
                storeItems[keys[i]] = values[i]
                storeItemsSafe[keys[i]] = values[i]
            end
        end
        if (plugins.iap or plugins.iab) and not plugins.innerPrice then
            plugins.innerPrice = 1
            local function initInnerPrice(code, result)
                if code == 0 then
                    local jdata = json.decode(result)
                    local fix2 = {}
                    for k, v in pairs(ProductFix) do
                        fix2[v] = k
                    end
                    if (GEngine.rawConfig.innerScriptVersion or 0) >= 320 then
                        if GEngine.rawConfig.channel:find("com.bettergame.heroclash_ios") then
                            if jdata.pack7 then
                                fix2["pack7"] = "gem6"
                                fix2["gem6"] = "gem7"
                            end
                        end
                    end
                    for k, v in pairs(jdata) do
                        if v ~= "" then
                            plugins.storeItems[fix2[k] or k] = v
                        end
                    end
                    plugins.innerPrice = 2

                    if (GEngine.rawConfig.innerScriptVersion or 0) >= 320 then
                        if GEngine.rawConfig.channel:find("com.bettergame.heroclash_our") and plugins.storeItems["pack0"] then
                            keys[10] = "pack0"
                        end
                    end
                else
                    plugins.innerPrice = nil
                end
            end
            if plugins.iap then
                plugins.iap:sendCommand(plugins.slot:getPluginRequestCode(Script.createCallbackHandler(initInnerPrice)), 0, json.encode({rtype=1}))
            else
                plugins.iab:sendCommand(plugins.slot:getPluginRequestCode(Script.createCallbackHandler(initInnerPrice)), 3, json.encode({rtype=1}))
            end
        end

        -- 为以后增加后续翻译文本留个后手，如果只改data7的话就不用动原来的翻译了
        local deviceInfo = json.decode(Native:getDeviceInfo())
        local deviceType = deviceInfo.platform or "win32"
        local cconfig = GMethod.loadConfig("configs/language_" .. deviceType .. ".json")
        GEngine.lanConfig = cconfig
        if StringManager.init2 then
            local lan = General.language
            if cc.FileUtils:getInstance():isFileExist("data/"..lan.."2.lua") then
                StringManager.init2("data." .. lan .. "2")
            elseif lan ~= "CN" and lan ~= "EN" and lan ~= "HK" and lan ~= "IR" then
                if cc.FileUtils:getInstance():isFileExist("data/strings2.lua") then
                    if (lan == "DE" or lan == "FR") and GEngine.rawConfig.innerScriptVersion >= 320 then
                    else
                        StringManager.init2("data.strings2")
                    end
                end
            end
            if cc.FileUtils:getInstance():isFileExist("data/"..lan.."3.lua") then
                StringManager.init2("data." .. lan .. "3")
            end
        end
        -- 和登录无关的一些操作; 悄悄下载
        local DownloadUtil = GMethod.loadScript("game.GameLogic.DownloadUtil")
        -- 修复黑弓图片
        if GEngine.rawConfig.channel == "com.bettergame.heroclash_ios3" and GEngine.rawConfig.innerScriptVersion <= 355 then
            DownloadUtil.addNormalPkgTask("patchHG.pkg","patchs/0953a8fa088b618d7aa1af9149d9269c.pkg", "XiihmlAcVo3ydqfb")
        end
        local channel = string.gsub(GEngine.rawConfig.channel, "(.-)%d*$", "%1")
        -- 分享图片
        if (channel == "com.bettergame.heroclash_our" or channel == "com.bettergame.heroclash_ios" or channel == "com.bettergame.heroclash_google") then
            DownloadUtil.addNormalPkgTask("patchShare.pkg","patchs/b0a3d1f8d7ceac9cc2c820d06a68c0dd.pkg", "5eCin64UGNePbRJF")
        end
        if channel ~= "com.bettergame.heroclash_ir" and channel ~= "com.almuathir.zombies2_ios" and channel ~= "com.almuathir.zombies2" then
            -- GEngine.engine:getPackageManager():unloadPackage("patchLoading.pkg")
            -- local cfs = cc.FileUtils:getInstance()
            -- cfs:removeFile(cfs:getWritablePath() .. "patchLoading.pkg")
            DownloadUtil.addNormalPkgTask("patchLoading.pkg","patchs/4575e7945e66d8fc144d80cbb59842ca.pkg", "BAWb0lNbj1HhR8uN")
        end
    elseif stepItem[1] == "login" then
        self.locked = true
        local lastLoginMsg = GEngine.getConfig("lastLoginMsg")
        local lgmsg = (lastLoginMsg and lastLoginMsg~="") and json.decode(lastLoginMsg) or nil
        if lgmsg and lgmsg[1] and lgmsg[2] then
            if self.loadingView.lstate=="login" or GEngine.rawConfig.versionCode < 7 or (lgmsg[2] <= 3) then
                self.loadingView:setLoadingState("loginOnLast")
                local deviceInfo = json.decode(Native:getDeviceInfo())
                local noticeInfo = GameLogic.getVersionData("GVNotice" .. General.language)

                local params = {account=lgmsg[1], mode=lgmsg[2], cv=GEngine.rawConfig.version, cc=GEngine.rawConfig.versionCode, channel=GEngine.rawConfig.channel, platform=deviceInfo.platform, device=deviceInfo.deviceId, pushtoken=GEngine.getConfig("pushtoken"), language=General.language, av=noticeInfo.v, country=deviceInfo.country, ipcountry=GEngine.getConfig("EngineIpCountry") or ""}
                GameNetwork.request("getuser", params, self.loginOver, self)
            else
                local params={callback=function(id)
                    if id then
                        local lgmsg = {id, lgmsg[2]}
                        GEngine.setConfig("lastLoginMsg", json.encode(lgmsg), true)
                        self.step = self.step-1
                        self.locked = false
                        self.loadingView:setLoadingState("login")
                        self:loading(0)
                    else
                        self.loadingView:setLoadingState("login")
                    end
                end}
                Plugins:loginWithSdk(lgmsg[2], params)
            end
        else
            self.loadingView:setLoadingState("login")
        end
    elseif stepItem[1]=="sheet" then
        memory.loadSpriteSheet(stepItem[2], stepItem[3])
    elseif stepItem[1]=="image" then
        memory.loadTexture(stepItem[2])
    elseif stepItem[1]=="scene" then
        if stepItem[2]=="ground" then
            self.scene:reloadGround()
        elseif stepItem[2]=="menu" then
            self.scene:reloadMenu()
        elseif stepItem[2]=="chatRoom" then
            self.scene.menu:initChatRoom()
        elseif stepItem[2]=="builds" then
            self.scene:reloadBuilds()
            self.locked = true
            self.lockedItem = "builds"
            return
        end
    elseif stepItem[1]=="data" then
        if stepItem[2]=="enter" then
            self.locked = true
            local ed = self.enterData
            self.loadingView:setLoadingState("enter")
            log.d("account:%s",ed[1])
            log.d("mode:%d",ed[2])
            log.d("svid:%d",ed[3][1])
            GameLogic.uid = nil
            GameLogic.randnum = nil
            GameLogic.zid = nil

            local deviceInfo = json.decode(Native:getDeviceInfo())
            local params = {account=ed[1], mode=ed[2],svid=ed[3][1], cv=GEngine.rawConfig.version, cc=GEngine.rawConfig.versionCode, channel=GEngine.rawConfig.channel, platform=deviceInfo.platform, device=deviceInfo.deviceId, pushtoken=GEngine.getConfig("pushtoken"), language=General.language}
            GameNetwork.request("getuserinfo",params,self.getuserinfoOver, self)
        elseif stepItem[2] == "randnum" then
            self.locked = true
            GameNetwork.request("getRandnum",nil,function (isSuc,data)
                self.locked = false
                if isSuc then
                    GameLogic.randnum = data.randnum
                end
            end)
        elseif stepItem[2]=="resync" then
            local saved = GEngine.getConfig("cmds_data_" .. GameLogic.uid)
            if saved and saved ~= "" then
                saved = json.decode(saved)
                if saved and #saved.cmds > 0 then
                    self.locked = true
                    GameNetwork.request("cmds", {cmds=saved.cmds, gs=saved.gs, sidx=saved.sidx, eidx=saved.eidx, resync=saved.syntime}, self.onResyncCmdsOver, self, saved.eidx)
                    return
                end
            end
        -- 新的更新流程；走CDN，免得更新活动的时候把服务器挤爆了
        elseif stepItem[2] == "config" then
            if GameLogic.uid then
                self.locked =  true
                local GameSetting = GMethod.loadScript("game.GameSetting")
                local params = {}
                local sid = self.enterData[3][1]
                local allDownloads = GameSetting.getLocalData(0, "dfiles")
                if not allDownloads then
                    allDownloads = {}
                    GameSetting.setLocalData(0, "dfiles", allDownloads)
                end
                params["texts"] = {General.language, allDownloads["texts" .. sid .. General.language] or ""}
                params["acts"] = allDownloads["acts" .. sid] or ""
                params["datas"] = allDownloads["datas" .. sid] or ""

                GameNetwork.request("config", params, self.getConfigOver, self)
            else
                self.step = self.step - 1
            end
        elseif stepItem[2] == "udata" then
            if GameLogic.uid then
                self.locked = true
                local deviceInfo = json.decode(Native:getDeviceInfo())
                local params = {account=self.enterData[1], mode=self.enterData[2], svid = self.enterData[3][1], cv=GEngine.rawConfig.version, cc=GEngine.rawConfig.versionCode, channel=GEngine.rawConfig.channel, platform=deviceInfo.platform, device=deviceInfo.deviceId, pushtoken=GEngine.getConfig("pushtoken"), language=General.language}

                -- 以后下载走新流程
                params.newDownload = 1
                GameNetwork.request("data", params, self.getDataOver, self)
            else
                self.step = self.step - 1
            end
        end
    elseif stepItem[1] == "object" then
        if stepItem[2] == "logData" then
            if GameLogic.getUserContext() then
                local logData = GMethod.loadScript("game.GameLogic.LogData").new()
                GameLogic.getUserContext().logData = logData
                logData:getEmailDatas()--第一次获取邮件数据
            else
                self.step = self.step - 1
            end
        elseif stepItem[2] == "UIeffectsManage" then
            GEngine.export("UIeffectsManage",GMethod.loadScript("game.GameEffect.UIeffectsManage").new())
        end
    elseif stepItem[1]=="dealRes" then
        if stepItem[2] == "initRes2" then
            local sc = ButtonHandler(self.onLoadPlistOver, self)
            local sv = self.loadingView.view
            local loader = ResAsyncLoader:getInstance()
            self.asynctotal = 0
            self.asyncfinish = 0
            self.asynctotal = self.asynctotal + 2
            loader:addLuaTask(sv, "images/images_common.plist", nil, sc)
            loader:addLuaTask(sv, "images/background.plist", nil, sc)
        elseif stepItem[2] == "initRes" then
            local sc = ButtonHandler(self.onLoadPlistOver, self)
            local sv = self.loadingView.view
            local loader = ResAsyncLoader:getInstance()
            self.asynctotal = 0
            self.asyncfinish = 0
            self.asynctotal = self.asynctotal + 7
            loader:addLuaTask(sv, "images/builds1.plist", nil, sc)
            loader:addLuaTask(sv, "images/builds2.plist", nil, sc)
            loader:addLuaTask(sv, "images/builds3.plist", nil, sc)
            loader:addLuaTask(sv, "images/builds4.plist", nil, sc)
            loader:addLuaTask(sv, "effects/uiEffects.plist", nil, sc)
            loader:addLuaTask(sv, "CsbRes/cutscenes1.plist", nil, sc)
            loader:addLuaTask(sv, "CsbRes/cutscenes2.plist", nil, sc)
            self.locked = true
            self.lockedItem = "res"
            return
        elseif stepItem[2] == "removeRes" then
            memory.releaseCacheFrame()
        elseif stepItem[2] == "addRes" then
            local scene = GMethod.loadScript("game.View.Scene")
            local sc = ButtonHandler(self.onLoadPlistOver, self)
            local sv = self.loadingView.view
            local loader = ResAsyncLoader:getInstance()
            self.asynctotal = 0
            self.asyncfinish = 0
            if scene.bgPng then
                self.asynctotal = self.asynctotal + 12
                local blockNum=0
                for i=1,12 do
                    blockNum = blockNum + 1
                    local name = string.sub(scene.bgPng, 1, string.len(scene.bgPng)-4)
                    loader:addLuaTask(sv, nil, name .. "_" .. blockNum .. ".png", sc)
                end
            end
            if scene.sceneType == "battle" then
                if scene.battleData.groups[1].hitems then
                    local cfs = cc.FileUtils:getInstance()
                    local hitems = scene.battleData.groups[1].hitems
                    for _,hitem in ipairs(hitems) do
                        if hitem.hero then
                            if hitem.hid then
                                if memory.loadSpriteSheetRelease(GetPersonPlist(hitem.hid, hitem.hero.level, hitem.hero.awakeUp), true, sv, sc) then
                                    self.asynctotal = self.asynctotal + 1
                                end
                                if hitem.hero.awakeUp>0 then
                                    self.asynctotal = self.asynctotal + 1
                                    local afile = GameUI.getHeroFeature(hitem.hid, false, hitem.hero.awakeUp)
                                    ResAsyncLoader:getInstance():addLuaTask(sv, nil, afile, sc)
                                end
                            end
                            if scene.battleType~=const.BattleTypePvt and hitem.sid then
                                if memory.loadSpriteSheetRelease(GetPersonPlist(hitem.sid, hitem.hero.soldierLevel, 0), true, sv, sc) then
                                    self.asynctotal = self.asynctotal + 1
                                end
                            end
                        end
                    end
                end
                local battleHeroDatas=GameLogic.getBattleHeroId()
                self.asynctotal = self.asynctotal + 4
                memory.loadSpriteSheet("effects/battleEffects.plist",nil,true,sv,sc)
                memory.loadSpriteSheet("effects/effectsRes/heroRes/heroGenerelRes1.plist",nil,true, sv,sc)
                memory.loadSpriteSheet("effects/effectsRes/heroRes/heroGenerelRes2.plist",nil,true, sv,sc)
                memory.loadSpriteSheet("effects/effectsRes/heroRes/heroGenerelRes3.plist",nil,true, sv,sc)
                for i,hid in ipairs (battleHeroDatas) do
                    if cc.FileUtils:getInstance():isFileExist("effects/effectsRes/heroRes/heroEffectRes_"..hid..".plist") then
                        memory.loadSpriteSheet("effects/effectsRes/heroRes/heroEffectRes_"..hid..".plist",nil,true, sv,sc)
                        self.asynctotal = self.asynctotal + 1
                    end
                end
            elseif scene.sceneType == "operation" then
                self.asynctotal = self.asynctotal+11
                loader:addLuaTask(sv, nil, "images/btnBattlePVH.png", sc)
                loader:addLuaTask(sv, nil, "images/btnBattlePlunder.png", sc)
                --loader:addLuaTask(sv, nil, "images/dialogBackBattle.png", sc)
                loader:addLuaTask(sv, nil, "images/dialogBackBattle_1.png", sc)
                loader:addLuaTask(sv, nil, "images/dialogBackBattle_2.png", sc)
                loader:addLuaTask(sv, nil, "images/dialogBackBattle_3.png", sc)
                loader:addLuaTask(sv, nil, "images/dialogBackBattle_4.png", sc)
                loader:addLuaTask(sv, "effects/battleEffects.plist", nil, sc)
                loader:addLuaTask(sv, nil, "images/mapZheZhao.png", sc)
                loader:addLuaTask(sv, nil, "images/dialogBattleMap1.png", sc)
                loader:addLuaTask(sv, nil, "images/dialogBattleMap2.png", sc)
                loader:addLuaTask(sv, nil, "images/dialogBattleMap3.png", sc)
            end
            self.locked = true
            self.lockedItem = "res"
            return
        end
    end
    else
        self.step = self.step - 1
    end
    self.loadingView:setPercent(math.floor(self.step*100/self.loadMax))
    if self.step>=self.loadMax then
        GMethod.unschedule(self.loadingEntry)
        -- self.loadingView:delete()
        -- self.scene.menu:onChangeOver()
        -- if self.scene.replay and self.scene.isBattle then
        --     self.scene.replay.isStartBattle = true
        -- end
        -- self.changeOver = true
    end
end

function Loading:loadingOver()
    if self.scene.battleType==const.BattleTypePve then
        music.setBgm("music/battlePrepare.mp3")
    elseif self.scene.battleType==const.BattleTypePvc or self.scene.battleType==const.BattleTypePvh then
        music.setBgm("music/battleDefence.mp3")
    elseif self.scene.battleType==const.BattleTypePvt or self.scene.battleType==const.BattleTypePvb then
        music.setBgm("music/battlePrepare.mp3")
    end
    --GMethod.unschedule(self.loadingEntry)
    self.loadingView:delete()
    self.scene.menu:onChangeOver()
    if self.scene.replay and self.scene.isBattle then
        self.scene.replay.isStartBattle = true
    end
    GameLogic.statForSnowfish("gamestart")
    self.changeOver = true
    GameUI.setLoadingState(false)
end

function Loading:onLoadPlistOver(suc, plist)
    self.asyncfinish = self.asyncfinish + 1
    if plist and plist:find(".png") then
        memory.loadTexture(plist):retain()
    end
    if plist and plist:find(".png") then
        memory.loadTexture(plist):retain()
    end
end

function Loading:startLoading()
    self.changeOver = false
    math.randomseed(os.time())

    local lview = self.loadingView
    lview:setLoadingState("loading")
    lview:setPercent(0)
    local loadSteps = {}
    table.insert(loadSteps, {"init"})
    table.insert(loadSteps, {"dealRes", "initRes2"})
    table.insert(loadSteps, {"login"})
    table.insert(loadSteps, {"data", "enter"})
    table.insert(loadSteps, {"data", "randnum"})
    table.insert(loadSteps, {"data", "resync"})
    table.insert(loadSteps, {"dealRes", "initRes"})
    table.insert(loadSteps, {"object", "UIeffectsManage"})      --用来加UI特效的对象

    table.insert(loadSteps, {"data", "config"})
    table.insert(loadSteps, {"data", "udata"})
    table.insert(loadSteps, {"object", "logData"})      --获取日志数据的对象
    table.insert(loadSteps, {"scene", "ground"})
    table.insert(loadSteps, {"scene", "builds"})
    table.insert(loadSteps, {"scene", "menu"})
    table.insert(loadSteps, {"scene", "chatRoom"})
    table.insert(loadSteps, {"dealRes", "removeRes"})
    table.insert(loadSteps, {"dealRes", "addRes"})
    self.loadSteps = loadSteps
    self.loadMax = #loadSteps
    self.step = 0
    self.asynctotal = 0
    self.asyncfinish = 0
    self.locked = false

    self.loadingEntry = GMethod.schedule(Handler(self.loading, self),0,false)

    local function checkPushtoken()
        local token = cc.UserDefault:getInstance():getStringForKey("RemoteKeyToken")
        if token and token ~= "" then
            GEngine.setConfig("pushtoken", token)
        elseif Plugins.gamecenter then
            local pm = GEngine.getPlatform()
            if pm == cc.PLATFORM_OS_ANDROID then
                local function initPushToken(code, pushtoken)
                    if code == 0 then
                        GEngine.setConfig("pushtoken", pushtoken)
                        cc.UserDefault:getInstance():setStringForKey("RemoteKeyToken", pushtoken)
                    end
                end
                Plugins.gamecenter:sendCommand(Plugins.slot:getPluginRequestCode(Script.createCallbackHandler(initPushToken)), 3, json.encode({init=true}))
            end
        end
    end
    pcall(checkPushtoken)
end

--隔天刷新
function Loading:checkAndRefreshData(diff)
    if not self.gameInit or true then
        return
    end
    if not self.landTime then
        self.landTime= GameLogic.getToday()
    end
    --为了不同时发这个刷新接口
    if not self.randNum then
        self.randNum=GameLogic.getRandom(1,10)
    end
    self.cinNum=(self.cinNum or 0)+1
    if self.cinNum>10 then
        self.cinNum=0
    end
    if self.landTime and GameLogic.getSTime()>=self.landTime+86400 and self.cinNum==self.randNum then
        if not GameNetwork.lockRequest() then
            return
        end
        self.landTime=nil
        self.randNum=nil
        GameNetwork.request("refreshData",{},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                local context = GameLogic.getUserContext()
                context:refreshContext(data)
            end
        end)
    end
end

local Plugins = _G["Plugins"]

--登录SDK渠道的登录
function Plugins:loginWithSdk(loginType,params)
    local function initAccount(code, jsonStr)
        if params.callback then
            if code==0 then
                local ps=json.decode(jsonStr)
                params.callback(ps.id)
            else
                params.callback()
            end
        end
    end
    --根据SDk中的loginType的值选择
    if loginType==1 then--设备登录
        local id=Plugins:getDeviceId()
        -- if GEngine.getPlatform()==GEngine.platforms[1] then
        --     id=GEngine.getDevice()
        -- end
        if params.callback then
            params.callback(id)
        end
    elseif loginType==2 then--gamecenter
        if Plugins.gamecenter then
            Plugins.gamecenter:sendCommand(Plugins.slot:getPluginRequestCode(Script.createCallbackHandler(initAccount)), 4, json.encode({params=true}))
        end
    elseif loginType==3 then--facebook
        if Plugins.social then
            Plugins.social:sendCommand(Plugins.slot:getPluginRequestCode(Script.createCallbackHandler(initAccount)), 4, json.encode({rtype=1}))
        end
    elseif loginType >= 4 and loginType < 100 then --Qianxun or tutu
        if Plugins.singleSdk then
            Plugins.singleSdk:sendCommand(Plugins.slot:getPluginRequestCode(Script.createCallbackHandler(initAccount)), 4, json.encode({rtype = 1}))
        end
    end
end

--登出
function Plugins:logoutWithSdk(loginType,params)
    if Plugins.gamecenter then
        Plugins.gamecenter:sendCommand(-1, 4, json.encode({logout=true}))
    end
    if Plugins.social then
        Plugins.social:sendCommand(-1, 4, json.encode({logout=true}))
    end
    if Plugins.singleSdk then
        if params and params == "reset" then
            Plugins.singleSdk:sendCommand(-1, 4, json.encode({reset = true}))
        else
            Plugins.singleSdk:sendCommand(-1, 4, json.encode({logout = true}))
        end
    end
end

--获取设备id
function Plugins:getDeviceId()
    if not Plugins.deviceId then
        Plugins.deviceId=Native:getDeviceId()
    end
    return Plugins.deviceId
end

--支付
local _tmpPayFix = {card0=7, card1=8, newcard0=7, newcard1=8, gem0=1, gem1=2, gem2=3, gem3=4, gem4=5, gem5=6, gem6=9, gem7=10, pack0=10}
Plugins.tmpPayFix = _tmpPayFix
function Plugins:purchase(params)
    local context = GameLogic.getUserContext()
    local rparams = {}
    rparams.product = params.product
    rparams.uid = context.uid
    rparams.sid = context.sid
    rparams.lan = General.language
    rparams.ext = params.ext or ""
    rparams.userName = GameLogic.doSaveEncode(context:getInfoItem(const.InfoName))
    rparams.Grade = context:getInfoItem(const.InfoLevel)
    rparams.ServerName = Localize("dataServerName"..context.sid)
    local storeItem = "StoreItem" .. _tmpPayFix[params.product]
    if rparams.ext ~= "" then
        storeItem = "ExtItem" .. _tmpPayFix[params.product] .. "." .. rparams.ext
    end
    GameLogic.purchaseLock = true
    Plugins:onFacebookStat("ClickPay", {item=storeItem})

    local pm = GEngine.getPlatform()
    if pm == cc.PLATFORM_OS_ANDROID then
        rparams.plat = "android"
    elseif pm == cc.PLATFORM_OS_IPHONE or pm == cc.PLATFORM_OS_IPAD then
        rparams.plat = "ios"
    else
        rparams.plat = "desktop"
    end

    local plugins = {}
    local pluginNames = {}
    if Plugins.iab then
        table.insert(plugins, Plugins.iab)
        table.insert(pluginNames, Localize("labelFuncGoogle"))
    end
    if Plugins.iap then
        table.insert(plugins, Plugins.iap)
        table.insert(pluginNames, Localize("labelFuncApple"))
    end
    if Plugins.cafe then
        table.insert(plugins, Plugins.cafe)
        table.insert(pluginNames, Localize("labelFuncCafe"))
    end
    if not Plugins.inReview then
        if Plugins.alipay then
            table.insert(plugins, Plugins.alipay)
            table.insert(pluginNames, Localize("labelFuncAlipay"))
        end
        -- if Plugins.wechat then
        --     table.insert(plugins, Plugins.wechat)
        --     table.insert(pluginNames, Localize("labelFuncWechat"))
        -- end
        if Plugins.paypal then
            table.insert(plugins, Plugins.paypal)
            table.insert(pluginNames, Localize("labelFuncPaypal"))
        end
        if Plugins.paypal2 then
            table.insert(plugins, Plugins.paypal2)
            table.insert(pluginNames, Localize("labelFuncPaypal"))
        end
        if Plugins.mol then
            table.insert(plugins, Plugins.mol)
            table.insert(pluginNames, Localize("labelFuncMol"))
        end
        if Plugins.singleSdk then
            table.insert(plugins, Plugins.singleSdk)
            table.insert(pluginNames, Localize("labelFuncPay" .. GEngine.rawConfig.loginChannel))
        end
    end

    if #plugins > 0 then
        local isWeb = false
        local function buyOver(code, result)
            GameUI.setLoadingShow("loading", false, 0)
            GameLogic.purchaseLock = nil
            if code==0 then
                log.d("成功")
                GameLogic.statForSnowfish("postPostPayData")
                if Plugins.statAf then
                    local usdDict = {1.99, 4.99, 9.99, 24.99, 49.99, 99.99, 9.99, 9.99, 0.99, 0.99}
                    Plugins.statAf:sendCommand(-1, 3, json.encode({event="PrePurchase",
                        params={
                            price=usdDict[_tmpPayFix[params.product]],
                            currency="USD",
                            itemId=storeItem
                        }
                    }))
                end
                if Plugins.statPt then
                    local usdDict = {1.99, 4.99, 9.99, 24.99, 49.99, 99.99, 9.99, 9.99, 0.99, 0.99}
                    Plugins.statPt:sendCommand(-1, 3, json.encode({event="PrePurchase",
                        params={
                            price=usdDict[_tmpPayFix[params.product]],
                            currency="USD",
                            itemId=storeItem
                        }
                    }))
                end
                GameLogic.purchaseLock = true
            elseif code==1 then
                log.d("不支持")
            elseif code==2 then
                log.d("取消")
                if isWeb then
                    code = 0
                    GameLogic.purchaseLock = true
                    GameLogic.purchaseTry = true
                elseif result == "tempCancel" then
                    -- 某些支付不给回调，所以再异步一点去发通知
                    GameLogic.tempCancelParams = params
                end
            elseif code==3 then
                log.d("超时")
                Plugins:onFacebookStat("PrePaymentInfo", 0)
            elseif code==4 then
                log.d("失败")
                Plugins:onFacebookStat("PrePaymentInfo", 0)
            end
            if code == 0 then
                GameLogic.forReloadRewardsTime = 0
                GameLogic.forReloadRewardsTimeAll = 0
                GameLogic.needReloadRewards = true
            end
            if params.callback then
                params.callback(code)
            end
        end
        GameUI.setLoadingShow("loading", true, 0)
        if #plugins == 1 then
            if plugins[1] == Plugins.iap then
                if ProductFix[rparams.product] then
                    rparams.product = ProductFix[rparams.product]
                end
            end
            Plugins:onFacebookStat("ClickRealPay", {item=storeItem})
            plugins[1]:sendCommand(Plugins.slot:getPluginRequestCode(Script.createCallbackHandler(buyOver)), 0, json.encode(rparams))
        elseif #plugins > 1 then
            local function choosePayFunc(code)
                if code < 0 or code >= #plugins then
                    buyOver(2)
                else
                    Plugins:onFacebookStat("ClickRealPay", {item=storeItem})
                    if plugins[code+1] == Plugins.iap then
                        if ProductFix[rparams.product] then
                            rparams.product = ProductFix[rparams.product]
                        end
                    elseif plugins[code+1] == Plugins.paypal or plugins[code+1] == Plugins.mol then
                        isWeb = true
                    end
                    plugins[code+1]:sendCommand(Plugins.slot:getPluginRequestCode(Script.createCallbackHandler(buyOver)), 0, json.encode(rparams))
                end
            end
            local alertTable = {title=Localize("titleChooseMethod"), buttons={Localize("btnCancel")}, list=pluginNames}
            NativeAlert:createAlert(ButtonHandler(choosePayFunc), json.encode(alertTable)):show()
        end
    else
        log.d("支付sdk不存在:'ads'")
        -- params.callback()
        local sid = nil
        local function buyOver()
            GameUI.setLoadingShow("loading", false, 0)
            local code = 0
            GameLogic.purchaseLock = nil
            GameLogic.forReloadRewardsTime = 0
            GameLogic.forReloadRewardsTimeAll = 0
            GameLogic.needReloadRewards = true
            if params.callback then
                params.callback(code)
            end
        end
        local myMap = {gem0=230,gem1=600,gem2=1400,gem3=3800,gem4=7800,gem5=16800,gem6=18,gem7=110,card0=1,card1=2}
        local function testBuy()
            GMethod.unschedule(sid)
            buyOver()
            -- GameNetwork.request("verify", {pay="test", tid="TEST" .. GameLogic.getSTime(), sid=1, amount=myMap[params.product],platform="win32"}, buyOver)
        end
        GameUI.setLoadingShow("loading", true, 0)
        sid = GMethod.schedule(testBuy, 5)
    end
end

--反馈
function Plugins:feedback()
    local deviceInfo = json.decode(Native:getDeviceInfo())
    local title = Localize("feedbackTitle")
    local feedbackMail = "feedback@moyuplay.com"
    --请不要移除以下信息
    local content=Localize("contentTitle").."\n"
    --反馈时间
    local tab = os.date("*t",GameLogic.getSTime())
    local time=tab.year.."/"..tab.month.."/"..tab.day.."/"..tab.hour.."/"..tab.min.."/"..tab.sec
    content = content .. Localize("FeedbackTime")..time.."\n"
    --游戏名称
    content = content .. Localize("GameName").."\n"
    --版本号：
    content = content .. Localizef("GameVersion", {a = GEngine.rawConfig.version}).."\n"
    if GameLogic.getUserContext() then
        --服务器ID
        content = content .. Localizef("UserServerID", {a = GameLogic.getUserContext().sid}).."\n"
        --服务器名称
        content = content .. Localizef("UserServerName", {a = Localize("dataServerName"..GameLogic.getUserContext().sid)}).."\n"
        --用户ID：
        content = content .. Localizef("UserID", {a = GameLogic.getUserContext().uid}).."\n"
        --用户昵称：
        content = content .. Localizef("UserName", {a = GameLogic.getUserContext():getInfoItem(const.InfoName)}).."\n"
        --VIP等级：
        content = content .. Localizef("UserVipLv", {a = GameLogic.getUserContext():getInfoItem(const.InfoVIPlv)}).."\n"
        --购买水晶量：
        content = content .. Localizef("UserPurchase", {a = GameLogic.getUserContext().info[20] or 0}).."\n"
    end
    --国家
    content = content .. Localizef("Country", {a = deviceInfo.country}).."\n"
    --语言：
    content = content .. Localizef("Language", {a = GEngine.getConfig("language") or deviceInfo.language or "ZH_CN"}).."\n"
    --平台:
    content = content .. Localizef("Platform", {a = deviceInfo.platform}).."\n"
    --设备ID
    content = content .. Localizef("DeviceID", {a = deviceInfo.deviceId}).."\n"
    --设备型号：
    content = content .. Localizef("Device", {a = deviceInfo.model}).."\n"
    --设备版本：
    content = content .. Localizef("DeviceSystem", {a = deviceInfo.version}).."\n"

    Native:sendEmail(feedbackMail, title, content)
end

function Plugins:openUrl(url)
    Native:openURL(url)
end
--分享
function Plugins:share(params)
    local sharePlugin = nil
    if General.language == "CN" and Plugins.wechat and Plugins.wechat:checkPluginFunc(1) then
        sharePlugin = Plugins.wechat
    elseif Plugins.social then
        sharePlugin = Plugins.social
    end
    if sharePlugin then
        local function shareOver(code)
            self.shareDialog = false
            --老版IOS的分享“取消”先当作“成功”来做，否则分享任务无法进行
            if code == 0 or (code == 2 and GEngine.rawConfig.versionCode <= 2
                and GEngine.rawConfig.channel:find("com.bettergame.heroclash_ios"))
                or (code > 0 and not params.statTag and sharePlugin == Plugins.social) then
                GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeShareInfo,1)
                if params and params.hid then
                    GameLogic.getUserContext().activeData:finishActCondition(params.hid*10000 + const.ActTypeShareInfo, 1)
                    GameLogic.getUserContext().activeData:finishActCondition(1000*10000 + const.ActTypeShareInfo, 1)
                end
                -- GameLogic.getUserContext().achieveData:finish(9,1)
                GameLogic.getUserContext().achieveData:finish(const.ActTypeShareInfo,1)
                display.pushNotice(Localize("labelShareSucceed"))
                GameLogic.getUserContext():addCmd({const.CmdShareAction, 1, params and params.hid})
                if params.callback then
                    params.callback()
                end
                if params.statTag then
                    Plugins:onStat({callKey=5,eventId="shareBtnSuccess",params={[params.statTag]=1}})
                    GameLogic.addStatLog(1003, params.statTag2[1], params.statTag2[2], params.statTag2[3])
                end
            else
                display.pushNotice(Localize("labelShareFail"))
                if params.statTag then
                    Plugins:onStat({callKey=5,eventId="shareBtnFail",params={[params.statTag]=1}})
                    GameLogic.addStatLog(1004, params.statTag2[1], params.statTag2[2], params.statTag2[3])
                end
            end
        end
        if not self.shareDialog then
            self.shareDialog = true
            local rparam = {}
            rparam.image = params.image
            rparam.backUrl = params.backUrl
            if (GEngine.rawConfig.sdkVersion or 0) <= 1 then
                rparam.text = params.text
                rparam.caption = params.caption
            end
            rparam.url = params.url
            if params.statTag then
                Plugins:onStat({callKey=5,eventId="shareBtnClick",params={[params.statTag]=1}})
                GameLogic.addStatLog(1002, params.statTag2[1], params.statTag2[2], params.statTag2[3])
            end
            sharePlugin:sendCommand(Plugins.slot:getPluginRequestCode(Script.createCallbackHandler(shareOver)), 1, json.encode(rparam))
        end
    end
end

--广告
function Plugins:goAds(params)
    if Plugins.ads then
        GameLogic.openAds = true
        Plugins.ads:sendCommand(-1,2,json.encode({uid=tostring(GameLogic.getUserContext().uid)}))
        GameLogic.needReloadRewards = true
    end
end

--邀请
function Plugins:invite()

end

--facebook event
function Plugins:onFacebookStat(eventName, eventParams)
    if Plugins.social and (GEngine.rawConfig.sdkVersion or 0) > 1 then
        if eventName == "PreAchievement" and GEngine.getPlatform() ~= cc.PLATFORM_OS_ANDROID then
            Plugins.social:sendCommand(-1, 3, json.encode({event="PreArchieve", params=eventParams}))
        else
            Plugins.social:sendCommand(-1, 3, json.encode({event=eventName, params=eventParams}))
        end
    end
    if Plugins.singleSdk and Plugins.singleSdk:checkPluginFunc(3) then
        Plugins.singleSdk:sendCommand(-1, 3, json.encode({event=eventName, params=eventParams}))
    end
    if Plugins.statAf then
        if eventName ~= "PrePurchase" then
            Plugins.statAf:sendCommand(-1, 3, json.encode({event=eventName, params=eventParams}))
        end
    end
    if Plugins.statPt then
        if eventName ~= "PrePurchase" then
            Plugins.statPt:sendCommand(-1, 3, json.encode({event=eventName, params=eventParams}))
        end
    end
end
--初始化好友列表
function Plugins:initFriends(callback)
    local function initAccount(code, jsonStr)
        if code==0 then
            local fbfriends = {}
            if jsonStr then
                fbfriends = json.decode(jsonStr)
            end
            Plugins.facebookFriends = fbfriends

            local rp = cc.FileUtils:getInstance():getWritablePath()
            if rp:find(":") then
                rp = "./"
            end
            Plugins.fbHead={}
            for i,info in ipairs(fbfriends) do
                local url=info["picture"]["data"]["url"]
                local fname
                local ss=string.split(url,"/")
                for i,s in ipairs(ss) do
                    local _,b=string.find(s,".jpg",1)
                    if b then
                        fname=string.sub(s, 1, b)
                        break
                    end
                end

                fname = rp .. fname
                Plugins.fbHead[info.id]=fname
                if not cc.FileUtils:getInstance():isFileExist(fname) then
                    GameNetwork.download(url, fname, nil, nil)
                end
            end
            if callback then
                callback(Plugins.facebookFriends)
            end
        end
    end
    if Plugins.social then
        Plugins.social:sendCommand(Plugins.slot:getPluginRequestCode(Script.createCallbackHandler(initAccount)), 4, json.encode({getFriends=true}))
    end
end
--获取好友信息
function Plugins:getFriends(callback)
    if Plugins.facebookFriends then
        if callback then
            callback(Plugins.facebookFriends)
        end
    else
        Plugins:initFriends(callback)
    end
end

--统计
function Plugins:onStat(params)
    if Plugins.stat then
        Plugins.stat:sendCommand(-1, 3, json.encode(params))
    end
    if Plugins.singleSdk and Plugins.singleSdk:checkPluginFunc(3) and GEngine.rawConfig.singleStatNormal then
        Plugins.singleSdk:sendCommand(-1, 3, json.encode(params))
    end
    if Plugins.statAf then
        Plugins.statAf:sendCommand(-1, 3, json.encode(params))
    end
    if Plugins.statPt then
        Plugins.statPt:sendCommand(-1, 3, json.encode(params))
    end
end

--过滤敏感词（如果onlyKnowHas为true，表示只想知道是否存在敏感词，不会返回过滤后的敏感词，
--比如用户注册的时候，我们程序是只想知道用户取的姓名是否包含敏感词的(这样也能提高效率，检测到有一个敏感词就直接返回)，
--而聊天模块是要返回过滤之后的内容的，那么onlyKnowHas可以不设，但这需要遍历所有可能）
local mgcMap = {}
GMethod.setConfigMode(true)
GMethod.setConfigMode(false)
for i,v in ipairs(GMethod.loadConfig("configs/wordLimit.json")) do
    mgcMap[v] = true
end

local function filterSensitiveWords( content , onlyKnowHas)
    if content == nil or content == '' then
        return ''
    end

    --获取每一个字符
    local wordlist = {}
    local q = 1
    for w in string.gmatch(content, ".[\128-\191]*") do
        wordlist[q]= w
        q=q+1
    end

    --获取字符串中从起始位置到结束位置的字符
    local function findWord( wordTable, startpos,endpos )
        local result = ''
        for i=startpos,endpos do
            result = result..wordTable[i]
        end
        return result
    end

    local length = #(string.gsub(content, "[\128-\191]", ""))  --计算字符串的字符数（而不是字节数）
    local i,j = 1,1
    local replaceList={}
    local mgc = mgcMap
    local function check(  )
        local v = findWord(wordlist,i,j)
        local item = mgc[v]
        if item == true then
            if onlyKnowHas == true then
                return true
            end
            table.insert(replaceList,v)
            j = j+1
            i = j
        else
            j = j+1
        end
        local limit = (j-i) >= 15 and true or (j > length and true or false)
        if limit == true then --因为一个敏感词最多15个字，不会太长，目的提高效率
            i = i +1
            j = i
        end
        if i <= length then
            return check()
        end
    end
    if check() then
        return true
    end


    if onlyKnowHas == true then
       return false
    end

   --模式串中的特殊字符   ( ) . % + - * ? [ ^ $
    --  % 用作特殊字符的转义字符，比如%%匹配字符%     %[匹配字符[
    local specialChar = {['(']=true,[')']=true,['.']=true,['%']=true,['+']=true,['-']=true,['*']=true,['?']=true,['[']=true,['^']=true,['$']=true}
    --检测是否有特殊字符
    local function checkSpecialChar( msg )
        local tArray = string.gmatch(msg, ".[\128-\191]*")
        local contentArray = {}
        for w in tArray do
           table.insert(contentArray,w)
        end
        local ck = {}
        for i=1,#contentArray do
            local v = contentArray[i]
            if specialChar[v] == true then
                table.insert(ck,'%')
            end
            table.insert(ck,v)
        end
        local result=''
        for i,v in ipairs(ck) do
            result = result..v
        end
        return result
    end

    for i,v in ipairs(replaceList) do
        v = checkSpecialChar(v)
        content = string.gsub( content , v , '*' )
    end
    return content
end
GEngine.export("filterSensitiveWords", filterSensitiveWords)

return Loading
