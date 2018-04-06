
local const = GMethod.loadScript("game.GameLogic.Const")
local gameSetting=GMethod.loadScript("game.GameSetting")
--系统设置对话框
local SystemSetDialog = class2("SystemSetDialog",function()
    return BaseView.new("SystemSetDialog.json",true)
end)

function SystemSetDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()

    display.showDialog(self)
end

function SystemSetDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))

    self:loadView("upViews")
    self:loadView("downViews")
    self:insertViewTo()

    if GEngine.getPlatform()==GEngine.platforms[4] then
        self.imaGc:setVisible(false)
    else
        self.imaGg:setVisible(false)
    end

    self.butSetGSK:setListener(function()
        gameSetting.setSetting(gameSetting.GskEffect,not gameSetting.getSetting(gameSetting.GskEffect))
        self:reload()
    end)

    self.butSetVoice:setListener(function()
        music.changeSoundState(not music.getSoundState())
        self:reload()
    end)
    self.butSetMusic:setListener(function()
        music.changeBgmState(not music.getBgmState())
        self:reload()
    end)
    self.butSetLanguage:setListener(function()
        LanguageSetDialog.new()
    end)
    self.butESQ:setListener(function()
        GameLogic.addStatLog(3002, 1, 0, 0)
        if Plugins.helpShift then
            Plugins.helpShift:sendCommand(-1, 5, json.encode({rtype=1}))
            return
        end
        local url = "http://coz1vn.moyuplay.com:8081/All_game_page/Coz2/faq.html"
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
        Native:openURL(url .. "?" .. GameLogic.urlencode(params))
        --Plugins:feedback()
    end)

    --礼品码
    self.labGiftCode:setString(Localize("labelPackCode"))
    self.butGiftCode:setListener(function()
        local giftCode = GMethod.loadScript("game.UI.dialog.giftCode")
        display.showDialog(giftCode.new())
    end)
    --play800渠道添加qq群
    if GEngine.rawConfig.channel == "com.dmw.cnyx_ios3" or GEngine.rawConfig.channel == "com.sslm.eliver_ios3"
        or GEngine.rawConfig.channel == "com.cnyx" or GEngine.rawConfig.channel == "com.ssylm.elver_ios3" then
        self.butSetFacebook:setVisible(false)
        self.butPlatform:setVisible(false)
        local id=12007
        local url="https://jq.qq.com/?_wv=1027&k=53Ox1kc"
        self.butQQGroup:setScriptCallback(ButtonHandler(function (url,id)
            GameLogic.addStatLog(id,1,0,0)
            Plugins:openUrl(url)
        end,url,id))
    else
        self.butQQGroup:setVisible(false)
    end

    if Plugins.singleSdk then
        self.butSetFacebook:setVisible(false)
        self.butPlatform:setVisible(false)
    else
        self.butSetFacebook:setListener(function()
            if not GEngine.getConfig("haveBindFb") or GEngine.getConfig("haveBindFb") == 0 then
                local params={callback=function(id)
                    if self.bindacc and id then
                        self:bindacc(id,3)
                    else
                        display.pushNotice(Localize("labelBindCancelError"))--绑定中途取消，绑定失败
                    end
                end}
                Plugins:loginWithSdk(3,params)
            end
        end)
        self.butPlatform:setListener(function()
            if not GEngine.getConfig("haveBindGc") or GEngine.getConfig("haveBindGc") == 0 then
                local params={callback=function(id)
                    if self.bindacc and id then
                        self:bindacc(id,2)
                    else
                        display.pushNotice(Localize("labelBindError"))
                    end
                end}
                Plugins:loginWithSdk(2,params)
            end
        end)
    end


    local infos={}
    --第一条显示
    for i=2,const.pushNum do
        -- 不显示联盟战推送
        if i ~= 3 then
            table.insert(infos,{id=i})
        end
    end
    self.butArr = {}
    -- 1-6
    local code = GameLogic.getUserContext():getInfoItem(const.InfoPush)
    self.tab = GameLogic.dnumber(code,const.pushNum)
    self:addTableViewProperty("pushTableView",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("pushTableView")
    self:reload()
    if gameSetting.shareConfig==0 then
        self.butGiftCode:setVisible(false)
        self.butSetGSK:setPosition(648,931)
        self.butQQGroup:setVisible(false)
    end
end
function SystemSetDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    --关闭状态按钮用黄色
    self:loadView("cellViews",bg)
    self.viewTab.butOC:setListener(function()
        if self.tab[info.id] == 1 then
            self.tab[info.id] = 0
        else
            self.tab[info.id] = 1
        end

        self:reload()
    end)
    self:insertViewTo()
    if info.id == 4 then
        self.pushTime:setString(Localize("labelPushTime1"))
    else
        self.pushTime:setString(Localize("labelPushTime2"))
    end
    self.pushTime:setVisible(false)
    self.pushName:setString(Localize("dataPushName" .. info.id))
    self.butArr[info.id] = {self.butOC,self.labOC}
    self:reload()
end
function SystemSetDialog:reload()
    --声音
    local img = {"images/btnGreen.png","images/btnOrange.png"}
    local str = {"labelOpen","labelClose"}
    local state
    if music.getSoundState() then
        state = 1
    else
        state = 2
    end
    self.butSetVoice:setBackgroundImage(img[state],0)
    self.btnSetVoice:setString(Localize("labelVoice") .. "" ..Localize(str[state]))

    --天神技释放动画
    if gameSetting.getSetting(gameSetting.GskEffect) then
        state = 2
    else
        state = 1
    end
    self.butSetGSK:setBackgroundImage(img[state],0)
    self.btnSetGSK:setString(Localize("labelGSKSwitch")..""..Localize(str[state]))
    --音乐
    if music.getBgmState() then
        state = 1
    else
        state = 2
    end
    self.butSetMusic:setBackgroundImage(img[state],0)
    self.btnSetMusic:setString(Localize("labelMusic") .. "" ..Localize(str[state]))
    --语言
    local language = General.language
    local lconf = GEngine.lanConfig.languages[language]
    self.btnSetLanguage:setString(Localizef("Language", {a=lconf[4]}))
    --facebook
    if 1 == GEngine.getConfig("haveBindFb") then
        self.btnSetFacebook:setString(Localize("labelPlatform2"))
        self.butSetFacebook:setHValue(0)
    else
        self.btnSetFacebook:setString(Localize("labelPlatform1"))
        self.butSetFacebook:setHValue(-78)
    end

    --GC
    if 1 == GEngine.getConfig("haveBindGc") then
        self.labelPlatform:setString(Localize("labelPlatform2"))
        self.butPlatform:setHValue(0)
    else
        self.labelPlatform:setString(Localize("labelPlatform1"))
        self.butPlatform:setHValue(-78)
    end

    local tab = self.tab
    for i,v in pairs(self.butArr) do
        if tab[i] >= 1 then
            tab[i] = 1
        else
            tab[i] = 0
        end
        v[1]:setBackgroundImage(img[2-tab[i]], 0)
        v[2]:setString(Localize(str[2-tab[i]] .. "1"))
    end
end

function SystemSetDialog:canExit()
    local context = GameLogic.getUserContext()
    local code = GameLogic.enumber(self.tab)
    if code ~= context:getInfoItem(const.InfoPush) then
        self:changesetting(code)
        context:setInfoItem(const.InfoPush,code)
    end
    return true
end
------------------------------------------------------------------
function SystemSetDialog:changesetting(code)
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdSetChange,code})
end

function SystemSetDialog:bindacc(account2,mode2)
    if not GameNetwork.lockRequest() then
        return
    end
    local lgmsg = GEngine.getConfig("lastLoginMsg")
    local lgmsg = json.decode(lgmsg)
    GameNetwork.request("bindacc",{uid=GameLogic.getUserContext().uid,sid=GameLogic.getUserContext().sid,account1=lgmsg[1],mode1=lgmsg[2],account2=account2,mode2=mode2},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc and data==1 then
            GameNetwork.lockRequest()
            GameNetwork.request("setBinds",{uid=GameLogic.getUserContext().uid,sid=GameLogic.getUserContext().sid,account1=lgmsg[1],mode1=lgmsg[2],account2=account2,mode2=mode2},function(isSuc,data)
                GameNetwork.unlockRequest()
                if data == 1 then
                    display.pushNotice(Localize("labelBindSucceed"))
                    if mode2 == 2 then
                        local lgmsg = {account2,2}
                        GEngine.setConfig("lastLoginMsg", json.encode(lgmsg),true)
                        GEngine.setConfig("haveBindGc",1)
                    elseif mode2 == 3 then
                        local lgmsg = {account2,3}
                        GEngine.setConfig("lastLoginMsg", json.encode(lgmsg),true)
                        GEngine.setConfig("haveBindFb",1)
                        GameLogic.getUserContext().activeData:finishAct(56)
                    end
                    if self.bindacc then
                        self:reload()
                    end
                else
                    display.pushNotice(Localize("labelBindAgainError"))--已绑定其它账号
                end
            end)
        else
            display.pushNotice(Localize("labelBindAgainError"))
        end
    end)
end
return SystemSetDialog
