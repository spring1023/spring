local const = GMethod.loadScript("game.GameLogic.Const")
local LanguageSetDialog=GMethod.loadScript("game.UI.NewDialog.NewLanguageSetDialog")
local PushInfoDialog=GMethod.loadScript("game.UI.NewDialog.NewPushInfoDialog")
local gameSetting=GMethod.loadScript("game.GameSetting")

--系统设置对话框
local SystemSetDialog = class(DialogViewLayout);

function SystemSetDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function SystemSetDialog:onCreate()
    self:setLayout("userInfo_system_dialog.json")
    self:loadViewsTo()
end

function SystemSetDialog:initUI()
    -- 关闭按钮
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))

    -- local loginType = Plugins:getChannelCode() or DEBUG.channelType
    -- if GEngine.IOS_MAJIA_FLAG or loginType ~= 3 and not DEBUG.LANGUAGE_SET_OPEN then
    --     self.hideNode:setVisible(false);
    -- end

    -- 判断机器平台 显示GameCenter 或者GooglePlay
    -- local deviceInfo = json.decode(Native:getDeviceInfo());
    -- if deviceInfo.platform == "ios" then
    --     self.btn_appleLogin:setVisible(true);   -- mac
    --     self.btn_androidLogin:setVisible(false);
    --     self.btn_pluginLogin = self.btn_appleLogin;
    -- else
    --     self.btn_androidLogin:setVisible(true); -- android
    --     self.btn_appleLogin:setVisible(false);
    --     self.btn_pluginLogin = self.btn_androidLogin;
    -- end

    -- 设置声音按钮状态
    self:initVoiceBtn()
    -- 设置按钮监听事件
    self.btn_voice:setScriptCallback(function()
        -- log.d("声音")
        music.changeSoundState(not music.getSoundState())
        self:initVoiceBtn()
    end)

    -- 初始化音乐按钮
    self:initMusicBtn()
    self.btn_music:setScriptCallback(function()
        -- log.d("音乐");
        music.changeBgmState(not music.getBgmState());
        self:initMusicBtn()
    end)

    self.btn_btn1:setScriptCallback(function()
        -- log.d("推送")
        PushInfoDialog.new()
    end)

    -- 设置语言按钮 点击跳出语言选择界面
    self.btn_btn2:setScriptCallback(function()
        -- display.pushNotice("此功能暂未开放!")
        -- return
        -- log.d("语言")
        LanguageSetDialog.new({callback = function(languageName)
            self.lb_language:setString(languageName);
        end})
    end)
    -- 设置客服帮助发送邮件
    self.btn_btn3:setScriptCallback(function()
        self:sendHelpUrl();
        -- log.d("客服帮助")
        -- Plugins:feedback()
    end)

    -- 礼品码
    self.btn_btn4:setScriptCallback(function()
        local giftCode = GMethod.loadScript("game.UI.dialog.giftCode")
        display.showDialog(giftCode.new())
    end)

    -- 天神技动画
    self:initGSK()
    self.btn_btn5:setScriptCallback(function()
        gameSetting.setSetting(gameSetting.GskEffect,not gameSetting.getSetting(gameSetting.GskEffect))
        self:initGSK()
    end)
  
    -- 设置facebook绑定按钮
    self.btn_facebook:setScriptCallback(function()
        -- log.d("facebook")
        if not GEngine.getConfig("haveBindFb") or GEngine.getConfig("haveBindFb") == 0 then
            local params={callback=function(id)
                if self.bindacc and id then
                    local channelCode, loginType = self:getChannelCodeAndLoginType(const.LoginTypeFacebook)
                    self:bindacc(id,loginType)
                else
                    -- Plugins:logoutWithSdk(3);
                    display.pushNotice(Localize("labelBindError"));
                end
            end}
            Plugins:loginWithSdk(3,params)
        else
            display.pushNotice(Localize("labelAccountBound2"));
        end
    end)
    -- 设置平台按钮
    self.btn_gs:setScriptCallback(function()
        if not GEngine.getConfig("haveBindGc") or GEngine.getConfig("haveBindGc") == 0 then
            local params={callback=function(id)
                GameNetwork.unlockRequest();
                if self.bindacc and id then
                    local channelCode, loginType = self:getChannelCodeAndLoginType(const.LoginTypeGCOrGP)
                    self:bindacc(id,loginType)
                else
                    -- Plugins:logoutWithSdk(2);
                    display.pushNotice(Localize("labelBindError"))
                end
            end}
            Plugins:loginWithSdk(2,params)
        else
            display.pushNotice(Localize("labelAccountBound1"));
        end
    end)

    self:reload()
end

function SystemSetDialog:sendHelpUrl()
    local url = "http://coz1vn.moyuplay.com:8081/All_game_page/Coz2/faq.html"
    local deviceInfo = json.decode(Native:getDeviceInfo())
    local language = General.language
    if language ~= "CN" and language ~= "HK" and language ~= "EN" then
        language = "EN"
    end
    local tab = os.date("*t",GameLogic.getSTime())
    local time=tab.year.."/"..tab.month.."/"..tab.day.."/"..tab.hour.."/"..tab.min.."/"..tab.sec
    local params = {rd=math.random(1, 999999), fte=time, gameName=Localize("GameName")}
    params.gvn = DEBUG.version
    params.game = "cod";
    params.sne = Localize("dataServerName"..GameLogic.getUserContext():getInfoItem(const.InfoSVid));
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
end

--  声音按钮回调
function SystemSetDialog:initVoiceBtn()
    local state = music.getSoundState();
    self.voice_open:setVisible(state)
    self.voice_close:setVisible(not state)   
end

-- 音乐按钮
function SystemSetDialog:initMusicBtn()
    local state = music.getBgmState();
    self.music_open:setVisible(state)
    self.music_close:setVisible(not state)
end

function SystemSetDialog:initGSK( ... )
    local str = {"labelOpen","labelClose"}
    local state
    if gameSetting.getSetting(gameSetting.GskEffect) then
        state = 2
    else
        state = 1
    end
    self.img_openGSK:setVisible(state == 1)
    self.img_closeGSK:setVisible(state ~= 1)
    self.lb_cartoon:setString(Localize("labelGSKSwitch")..""..Localize(str[state]))
end

function SystemSetDialog:reload(fcId, ggId)
    --语言
    local language = General.language
    local lconf = GEngine.lanConfig.languages[language]
    local confStr = ""
    for k, v in ipairs(lconf) do
        confStr = v
    end

    self.lb_language:setString(Localize(confStr))
    --facebook
    local facebookId = fcId or GEngine.getConfig("haveBindFb");
    local googleId = ggId or GEngine.getConfig("haveBindGc");
    self.img_fbBtnGreen:setVisible(1 == facebookId)
    self.img_fbBtnBlue:setVisible(1 ~= facebookId)
    -- if 1 == facebookId then
    --     self.logOut1:setVisible(false);
    --     self.login2:setVisible(true);
    -- else
    --     self.logOut1:setVisible(true);
    --     self.login2:setVisible(false);
    -- end

    -- --GC
    self.img_gpBtnGreen:setVisible(1 == googleId)
    self.img_gpBtnBlue:setVisible(1 ~= googleId)
    -- if 1 == googleId then
        -- self.logOut2:setVisible(false);
        -- self.login2:setVisible(true);
        -- self.logOut3:setVisible(false);
        -- self.login3:setVisible(true);
    -- else
        -- self.logOut2:setVisible(true);
        -- self.login2:setVisible(false);
        -- self.logOut3:setVisible(true);
        -- self.login3:setVisible(false);
    -- end
end

function SystemSetDialog:canExit()
    return true
end

function SystemSetDialog:bindacc(account2,mode2)
    if not GameNetwork.lockRequest() then
        return
    end
    local lgmsg = GEngine.getConfig("lastLoginMsg")
    local lgmsg = json.decode(lgmsg)
    GameNetwork.request("bindacc",{uid=GameLogic.getUserContext().uid,account1=lgmsg[1],mode1=lgmsg[2],account2=account2,mode2=mode2},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc and data==1 then
            if data == 1 then
                local fcId, ggId;
                display.pushNotice(Localize("labelBindSucceed"))
                local mode = mode2%100;
                if mode == 2 then
                    ggId = 1;
                    local channelCode, loginType = self:getChannelCodeAndLoginType(const.LoginTypeGCOrGP)
                    local lgmsg = {account2,loginType}
                    GEngine.setConfig("lastLoginMsg", json.encode(lgmsg),true)
                    GEngine.setConfig("haveBindGc",1)
                elseif mode == 3 then
                    fcId = 1;
                    local channelCode, loginType = self:getChannelCodeAndLoginType(const.LoginTypeFacebook)
                    local lgmsg = {account2,loginType}
                    GEngine.setConfig("lastLoginMsg", json.encode(lgmsg),true)
                    GEngine.setConfig("haveBindFb",1)
                    GameLogic.hottask(const.HActBindAccount)
                end
                if self.reload then
                    self:reload(fcId, ggId);
                end
            end
        elseif data == 5 then
            Plugins:logoutWithSdk(mode2);
            display.pushNotice(Localize("labelAccountBound4"));
        else
            Plugins:logoutWithSdk(mode2);
            display.pushNotice(Localize("labelBindError"));
        end
    end)
end

function SystemSetDialog:getChannelCodeAndLoginType(loginMode)
    local channelCode = Plugins:getChannelCode() or DEBUG.channelType

    if loginMode then
        local loginType = channelCode * 100 + loginMode
        return channelCode, loginType
    else
        return channelCode
    end
end



return SystemSetDialog