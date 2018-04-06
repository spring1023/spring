local CommunityDialog = class2("CommunityDialog",function()
    return BaseView.new("CommunityDialog.json")
end)
local const = GMethod.loadScript("game.GameLogic.Const")
function CommunityDialog:ctor(tabId)
    self.dialogDepth=display.getDialogPri()+1
    self.tabId = tabId or 1
    self.priority=self.dialogDepth
    self:initData()
    self:initUI()
    display.showDialog(self)

    local lNum = 3
    if General.language == "CN" then
        lNum = 1
    elseif General.language == "HK" then
        lNum = 2
    end
    GameLogic.addStatLog(12003, lNum,0, 0)
end


function CommunityDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    self.viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:addTabView({Localize("tabLabelFormation"),Localize("tabLabelPlatform"),Localize("tabLabelGroup")}, {543,149,450,1370,166,"images/dialogTabBack3_",55,271,69,1870,57,23,1324})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.intelligence,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.platformAndGameGroup,self,1)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.platformAndGameGroup,self,2)})
    self:changeTabIdx(self.tabId)
end

function CommunityDialog:initData()
    self.platFormData = {}
    self.gameGroupData = {}
    local infos = {
        {logid=12004,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblPlatFromName1",url="https://www.facebook.com/ZombiesClashII/"},
        {logid=12006,imgIcon = "images/otherIcon/iconWeibo.png",name="laeblPlatFromName2",url="https://m.weibo.cn/p/1006066017892633/home"},
        {logid=12005,imgIcon = "images/otherIcon/iconTube.png",name="laeblPlatFromName3",url="https://www.youtube.com/channel/UC_yQL1qDuWbP1vtOgSLHSBQ"}
    }
    self.platFormData = infos
    infos = {
        {logid=12007,imgIcon = "images/otherIcon/iconQq.png",name="laeblGameGroupName1",url="https://jq.qq.com/?_wv=1027&k=4A8JbCI"},
        {logid=12008,imgIcon = "images/otherIcon/iconWhats.png",name="laeblGameGroupName2",url="https://chat.whatsapp.com/9ib7KgGXUJT4TEPb4qyE3E"},
        {logid=12009,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName3",url="https://www.facebook.com/groups/313012075821039/"},

        {logid=12010,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName4",url="https://www.facebook.com/groups/1694074230896937/"},
        {logid=12011,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName5",url="https://www.facebook.com/groups/225697434603311/"},
        {logid=12012,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName6",url="https://www.facebook.com/groups/640007596209860/"},

        {logid=12013,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName7",url="https://www.facebook.com/groups/1907335139546364/"},
        {logid=12014,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName8",url="https://www.facebook.com/groups/271156259998033/"},
        {logid=12015,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName9",url="https://www.facebook.com/groups/1865528360387242/"},
        {logid=12016,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName10",url="https://www.facebook.com/groups/751078048393483/"},

        {logid=12017,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName11",url="https://www.facebook.com/groups/1753672551629183/"},
        {logid=12018,imgIcon = "images/otherIcon/iconFacebook.png",name="laeblGameGroupName12",url="https://www.facebook.com/groups/137928813432420/"}
    }
    self.gameGroupData = infos
end

function CommunityDialog:canChangeTab(call,tab)
    self:changeTabIdx(tab)
    if tab>=2 then
        self:platformAndGameGroup(tab-1)
    else
        self:intelligence()
    end
end

function CommunityDialog:intelligence(tab)

    if not self.platNode then
        self.platNode = ui.node({0,0},true)
    end
    local bg = self.platNode
    self.platNode:removeAllChildren(true)
    if ccexp.WebView then
        local webView = ccexp.WebView:create()
        webView:setContentSize(cc.size(2002,1352))
        display.adapt(webView, 23, 24)
        self.platNode:addChild(webView)
        local url = "http://coz1vn.moyuplay.com:8081/All_game_page/Coz2/ac1.html"
        local deviceInfo = json.decode(Native:getDeviceInfo())
        local language = General.language
        if language ~= "CN" and language ~= "HK" and language ~= "EN" and language ~= "IR" and language ~= "AR" then
            language = "EN"
        end
        local tab = os.date("*t",GameLogic.getSTime())
        local time=tab.year.."/"..tab.month.."/"..tab.day.."/"..tab.hour.."/"..tab.min.."/"..tab.sec
        local params = {rd=math.random(1, 999999), fte=time, game=Localize("GameName")}
        params.gvn = GEngine.rawConfig.version
        params.sne = Localize("dataServerName"..GameLogic.getUserContext().sid)
        params.uid = GameLogic.getUserContext().uid
        params.une = GameLogic.getUserContext():getInfoItem(const.InfoName)
        params.uvl = GameLogic.getUserContext():getInfoItem(const.InfoVIPlv)
        params.upe = (GameLogic.getUserContext().info[20] or 0)
        params.language = language
        params.dv = deviceInfo.model
        params.did = deviceInfo.deviceId
        params.sym = deviceInfo.version
        params.cty = deviceInfo.country
        webView:loadURL(url .. "?" .. GameLogic.urlencode(params))
        webView:setScalesPageToFit(true)
        webView:setOnShouldStartLoading(Handler(self.onShouldStartLoading, self))
    end
    return bg
end

function CommunityDialog:enterAnimate()
    return 0
end

function CommunityDialog:exitAnimate()
    return 0
end

function CommunityDialog:onShouldStartLoading(webView, url)
    if url:find("usebrowse=1") then
        Native:openURL(url)
        return false
    elseif url:find("sendemail=1") then
        Plugins:feedback()
        return false
    end
    return true
end

function CommunityDialog:platformAndGameGroup(idx)
    local infos = {}
    if idx==1 then
        GameLogic.addStatLog(12019, 1, 0, 0)
        infos = self.platFormData
    else
        GameLogic.addStatLog(12020, 1, 0, 0)
        infos = self.gameGroupData
    end
    if not self.platNode then
        self.platNode = ui.node({0,0},true)
    end
    local bg = self.platNode
    bg:removeAllChildren(true)
    self:addTableViewProperty("infoTableView",infos,Script.createBasicHandler(self.updateCell,self))
    self:loadView("infoTableView",bg)
    return bg
end

function CommunityDialog:updateCell(cell, tableView, info)

    if not info.viewLayout then
        cell:setEnable(false)
        self:loadView("platforAndGameGroupView",cell:getDrawNode())
        self:insertViewTo()
        self.imgIcon:setTexture(info.imgIcon)
        self.imgIcon:setScaleContentSize(200, 200, true)
        self.infoName:setString(Localize(info.name))
        self.butGoto:setScriptCallback(ButtonHandler(function (url,id)
            -- body
            GameLogic.addStatLog(id,1,0,0)
            Plugins:openUrl(url)
        end,info.url,info.logid))
    end
end

return CommunityDialog

