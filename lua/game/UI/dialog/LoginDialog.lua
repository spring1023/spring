GMethod.loadScript("game.UI.BaseView")
local LoginDialog = class2("LoginDialog",function()
    return BaseView.new("LoginDialog.json",true)
end)

function LoginDialog:ctor(ldv)
    ldv.view:addChild(self)
    self.ldv = ldv
    self.ldc = GMethod.loadScript("game.Controller.LoadingController")
    self.ldc.others = self
    self.dialogDepth = display.getDialogPri()+1
    self.priority = self.dialogDepth
    self:initUI()
    RegTimeUpdate(self.processNode, Handler(self.updateLoading, self), 0.025)
    if GEngine.rawConfig.platform == "ios" then
        ui.clearReuseFrame()
    end
end

function LoginDialog:initUI()
    self.lbnode = ui.node()
    display.adapt(self.lbnode,0,0,GConst.Anchor.LeftBottom,{scale=ui.getUIScale2()})
    self:addChild(self.lbnode)

    self.bnode = ui.node()
    display.adapt(self.bnode,0,0,GConst.Anchor.Bottom,{scale=ui.getUIScale2()})
    self:addChild(self.bnode)

    self.rbnode = ui.node()
    display.adapt(self.rbnode,0,0,GConst.Anchor.RightBottom,{scale=ui.getUIScale2()})
    self:addChild(self.rbnode)

    --进度条   self.processScale   self.upStr   self.downStr
    self.processNode = ui.node()
    self.processNode:setPositionY(50)
    self.processNode:setVisible(false)
    self:loadView("processNode",self.processNode)
    self.bnode:addChild(self.processNode)
    self:insertViewTo()
    local function cgStr()
        local id = self:randomTips()
        self.downStr:setString(Localize("tips_" .. id))
    end
    cgStr()
    local allTime = 0
    RegTimeUpdate(self.downStr, function(diff)
        allTime = allTime+diff
        if allTime>=10 then
            allTime = 0
            cgStr()
        end
    end, 1)

    --提交问题 self.butSendQuest
    self.questNode = ui.node()
    self.questNode:setVisible(false)
    self:loadView("questNode",self.questNode)
    self.lbnode:addChild(self.questNode)
    self:insertViewTo()
    self.butSendQuest:setListener(function()
        print("提交问题")
        --Plugins:feedback()
        self:sendHelpUrl()
    end)

    --当前版本  self.nowVersion
    self.versionNode = ui.node()
    self.versionNode:setVisible(false)
    self:loadView("versionNode",self.versionNode)
    self.rbnode:addChild(self.versionNode)

    --登录    self.butGc  self.butFb  self.butTourist
    self.loginNode = ui.node()
    self.loginNode:setVisible(false)
    self:loadView("loginNode",self.loginNode)
    self.bnode:addChild(self.loginNode)

    --登录后   self.butService  self.butBack  self.butChoseServer  self.serverName self.butLand
    --self.butBindGc   self.butBindFb
    self.loginAfNode2 = ui.node()
    self.loginAfNode2:setVisible(false)
    self:loadView("loginAfNode2",self.loginAfNode2)
    self.bnode:addChild(self.loginAfNode2)
    self:insertViewTo()

    if GEngine.getPlatform()==GEngine.platforms[4] then
        self.imaGc:setVisible(false)
        self.labelGcLogin:setString(Localize("labelGgLogin"))
    else
        self.imaGg:setVisible(false)
        self.labelGcLogin:setString(Localize("labelGcLogin"))
    end

    if self.butQx then
        if (GEngine.rawConfig.loginType or 1) == 1 then
            self.butGc:setVisible(true)
            self.butFb:setVisible(true)
            self.butQx:setVisible(false)
        elseif GEngine.rawConfig.loginType == 2 then
            self.butTourist:setVisible(false)
            self.butGc:setVisible(false)
            self.butFb:setVisible(false)
            self.butQx:setVisible(true)
            self.labelQxLogin:setString(Localize("labelLoginGame"))
        end
    end
    --3个按钮跟两个按钮布局不一样

end

function LoginDialog:sendHelpUrl()
    local url = "http://www.moyuplay.com/gamepage/coz2/faq.html"
    local deviceInfo = json.decode(Native:getDeviceInfo())
    local language = General.language
    if language ~= "CN" and language ~= "HK" and language ~= "EN" and language ~= "IR" and language ~= "AR" then
        language = "EN"
    end
    local tab = os.date("*t",GameLogic.getSTime())
    local time=tab.year.."/"..tab.month.."/"..tab.day.."/"..tab.hour.."/"..tab.min.."/"..tab.sec
    local params = {rd=math.random(1, 999999), fte=time, game=Localize("GameName")}
    params.gvn = GEngine.rawConfig.version
    -- params.sne = ""
    -- params.uid = GameLogic.getUserContext().uid
    -- params.une = GameLogic.getUserContext():getInfoItem(const.InfoName)
    -- params.uvl = GameLogic.getUserContext():getInfoItem(const.InfoVIPlv)
    -- params.upe = (GameLogic.getUserContext().info[20] or 0)
    params.language = language
    params.dv = deviceInfo.model
    params.did = deviceInfo.deviceId
    params.sym = deviceInfo.version
    params.cty = deviceInfo.country
    Native:openURL(url .. "?" .. GameLogic.urlencode(params))
end

function LoginDialog:randomTips()
    local key = "tips"
    local info = {}
    if GEngine.getConfig(key) then
        info = json.decode(GEngine.getConfig(key))
    else
        info.lv = 1
        info.list = {}
    end
    local SData = GMethod.loadScript("data.StaticData")
    local ids = SData.getData("tipsConfig", info.lv)

    local id
    local nids = {}
    local excepts = {}
    for _, oid in ipairs(info.list) do
        excepts[oid] = 1
    end
    for _, nid in KTIPairs(ids) do
        if not excepts[nid] then
            table.insert(nids, nid)
        end
    end
    id = nids[math.random(#nids)]
    table.insert(info.list, id)
    if #info.list > 3 then
        table.remove(info.list, 1)
    end
    GEngine.setConfig(key, json.encode(info), true)
    return id
end

function LoginDialog:changeViewState(state)
    self.processNode:setVisible(false)
    self.questNode:setVisible(false)
    self.versionNode:setVisible(false)
    self.loginNode:setVisible(false)
    self.loginAfNode2:setVisible(false)
    if state == 1 then
        self.processNode:setVisible(true)
        self.versionNode:setVisible(true)
    elseif state == 2 then
        local autoLogin = GEngine.rawConfig.autoLogin
        self.loginNode:setVisible(true)
        if autoLogin then
            self:autoLogin()
        end
    elseif state == 3 then
        self.loginAfNode2:setVisible(true)
        self.versionNode:setVisible(true)
        self.questNode:setVisible(true)
    end
end

function LoginDialog:loadVersion()
    self:changeViewState(1)
    self.upStr:setString(Localize("labelCheckVersion"))
    GEngine.rawConfig.version = "2.5.0"
    self.nowVersion:setString(Localizef("labelNowVersion", {a = GEngine.rawConfig.version}))

    local size = {self.nowVersion:getContentSize().width, self.nowVersion:getContentSize().height}
    --local debugNode = ui.colorNode(size, {255, 0, 0, 100})
    --display.adapt(debugNode, 0, 0, GConst.Anchor.LeftBottom)
    --self.nowVersion:addChild(debugNode, 100)
    self.processScale:setProcess(true,0)
end

function LoginDialog:loadLogin()
    self:changeViewState(2)
    local function setConfig(lgmsg)
        GEngine.setConfig("lastLoginMsg", json.encode(lgmsg),true)
        self.ldc.step = self.ldc.step-1
        self.ldc.locked = false
        self.processNode:setVisible(true)
        self.versionNode:setVisible(true)
        self.loginNode:setVisible(false)
    end

    local slot=GEngine.engine:getPluginSlot()

    self.butTourist:setListener(function()
        local params={callback=function(id)
            local lgmsg = {id,1}
            setConfig(lgmsg)
        end}
        Plugins:loginWithSdk(1,params)
    end)
    self.butGc:setListener(function()
        GameUI.setLoadingShow("loading", true, 0)
        local params={callback=function(id)
            if id then
                local lgmsg = {id,2}
                setConfig(lgmsg)
            end
            GameUI.setLoadingShow("loading", false, 0)
        end}
        Plugins:loginWithSdk(2,params)
    end)
    self.butFb:setListener(function()
        GameUI.setLoadingShow("loading", true, 0)
        local params={callback=function(id)
            if id then
                local lgmsg = {id,3}
                setConfig(lgmsg)
            end
            GameUI.setLoadingShow("loading", false, 0)
        end}
        Plugins:loginWithSdk(3,params)
    end)
    if self.butQx then
        self.butQx:setListener(function()
            GameUI.setLoadingShow("loading", true, 0)
            local params={callback=function(id)
                if id then
                    local lgmsg = {id, GEngine.rawConfig.loginChannel}
                    setConfig(lgmsg)
                end
                GameUI.setLoadingShow("loading", false, 0)
            end}
            Plugins:loginWithSdk(GEngine.rawConfig.loginChannel, params)
        end)
    end
end


function LoginDialog:autoLogin()
    local function setConfig(lgmsg)
        GEngine.setConfig("lastLoginMsg", json.encode(lgmsg),true)
        self.ldc.step = self.ldc.step-1
        self.ldc.locked = false
        self.processNode:setVisible(true)
        self.versionNode:setVisible(true)
        self.loginNode:setVisible(false)
    end
    GameUI.setLoadingShow("loading", true, 0)
    local params={callback=function(id)
        if id then
            local lgmsg = {id, GEngine.rawConfig.loginChannel}
            setConfig(lgmsg)
        end
        GameUI.setLoadingShow("loading", false, 0)
    end}
    Plugins:loginWithSdk(GEngine.rawConfig.loginChannel, params)
end

function LoginDialog:loadLoginAf()
    local loginData = self.ldc.loginData
    local sver = loginData.sver
    local setSv
    local gmcenter = loginData.gmcenter
    local facebook = loginData.facebook
    GEngine.setConfig("haveBindGc",gmcenter)
    GEngine.setConfig("haveBindFb",facebook)

    self:changeViewState(3)
    self.butChoseServer:setListener(function()
        log.d("选择服务器")
        ServerDialog.new(loginData,function(sv)
            setSv = sv
            self.serverName:setString(Localize("dataServerName" .. setSv[1]))
            GameLogic.setServerColor(self.serverName,setSv[5])
        end)
    end)
    self.serverName:setString(Localize("dataServerName" .. sver[1]))
    GameLogic.setServerColor(self.serverName,sver[5])
    self.butLand:setListener(function()
        local lgmsg = GEngine.getConfig("lastLoginMsg")
        local lgmsg = json.decode(lgmsg)
        local sv = setSv or sver
        self.ldc.enterData = {lgmsg[1],lgmsg[2],sv}
        self.ldc.locked = false
    end)
    if loginData.ainfo then
        GameLogic.setVersionData("GVNotice" .. General.language, loginData.ainfo)
    end
    local ainfo = GameLogic.getVersionData("GVNotice" .. General.language)
    if not GEngine.getConfig("sawAnnouncement") and ainfo.title and ainfo.text and (ainfo.e == 0 or ainfo.s and ainfo.e and ainfo.s <= GameLogic.getSTime() and ainfo.e >= GameLogic.getSTime()) then
        GameAnnouncement.new()
        GEngine.setConfig("sawAnnouncement", 1)
    end
end

function LoginDialog:updateLoading()
    local ld = self.ldv
    local percent = ld.percent
    if ld.dstate~=ld.lstate then
        local lstate = ld.lstate
        ld.dstate = lstate
        if lstate == "version" or lstate == "download" then
            self:loadVersion()
        elseif lstate == "loginOnLast" then
            self.upStr:setString(Localize("labelLoginAccount"))
        elseif lstate == "login" then
            self:loadLogin()
        elseif lstate == "autoLogin" then
            self:autoLogin()
        elseif lstate == "loginAf" then
            self:loadLoginAf()
        elseif lstate == "enter" then
            self:changeViewState(1)
        end
    end
    local str
    if ld.lstate == "version" then
        str = Localize("labelCheckVersion")
        if percent > 0 and percent < 100 then
            self.upStr:setString(str .. " " .. percent .. "%")
            self.processScale:setProcess(true,percent/100)
        else
            self.upStr:setString(str)
            self.processScale:setProcess(true, percent >= 100 and 1 or 0)
        end
    elseif ld.lstate == "download" then
        str = Localize("labelDownloadPc")
        self.upStr:setString(str .. percent .. "%")
        self.processScale:setProcess(true,percent/100)
    elseif ld.lstate=="enter" then
        str = Localize("labelEnterPc")
        --local loadPercent=percent
        local loadPercent=self.loadPercent or 0
        loadPercent=loadPercent+1
        if loadPercent > percent then
            loadPercent = percent
        end
        self.loadPercent=loadPercent
        self.upStr:setString(str .. loadPercent .. "%")
        self.processScale:setProcess(true,loadPercent/100)
        if loadPercent == 100 then
            self.ldc:loadingOver()
        end
    end
end

return LoginDialog
