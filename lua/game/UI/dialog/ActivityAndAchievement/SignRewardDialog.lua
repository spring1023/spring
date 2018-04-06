
--每日签到对话框
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")


local SignRewardDialog = class2("SignRewardDialog",function()
    return BaseView.new("SignRewardDialog.json")
end)
function SignRewardDialog:ctor(aDialog)
    self.aDialog=aDialog
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end
function SignRewardDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))
    self:loadView("rightViews")
    self:loadView("downViews")

    local dhActive = GameLogic.getUserContext().activeData.dhActive
    self.params = dhActive[12] or {1,0,0,0}
    local infos={}
    local activeReward = SData.getData("activeReward")
    local rewardConfig = {}
    for i,v in ipairs(activeReward) do
        if v.atype == 12 then
            rewardConfig[v.aid] = v
        end
    end
    self.rewardConfig = rewardConfig
    for i=1,#self.rewardConfig do
        infos[i]={id=i, item = self.rewardConfig[i]}
    end
    self:addTableViewProperty("leftTableView",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("leftTableView")
end

function SignRewardDialog:onQuestion()
    HelpDialog.new("dataQuestionSign")
end

function SignRewardDialog:reload(isEffect)
    local dhActive = GameLogic.getUserContext().activeData.dhActive
    self.params = dhActive[12] or {1,0,0,0}
    local idx = self.params[3]
    local isget = self.params[4]
    if self.rightIcon then
        self.rightIcon:removeFromParent(true)
        self.rightIcon = nil
    end
    local rwd = self.rewardConfig[idx]
    if rwd.gtype==10 and rwd.gid==4 then
        self.rightIcon = GameUI.addResourceIcon(self, 4, 286/100, 1635+143-8,794+143,0,2)
    else
        self.rightIcon = GameUI.addItemIcon(self,rwd.gtype,rwd.gid,286/200,1635+143,794+143,false)
    end
    if isget == 0 then
        self.nowRedCircle:setVisible(false)
        if self.receivedSgin then
            self.receivedSgin:setVisible(false)
        end
        self.butReceive:setGray(false)
        self.butReceive:setListener(function()
            self:getactreward()
        end)
    else
        if isEffect then
            local x=self.nowRedCircle:getPositionX()
            local y=self.nowRedCircle:getPositionY()
            local p=self.nowRedCircle:getParent()
            UIeffectsManage:showEffect_meiriqiandao(2,p,x,y,8)
            UIeffectsManage:showEffect_meiriqiandao(1,self,1782,952,20)
            music.play("sounds/receive.mp3")
        else
            if not self.receivedSgin then
                self.receivedSgin = GameUI.addHaveGet(self,Localize("labelAlreadyReceive"),0.87,1775,950,2)
            end
            self.receivedSgin:setVisible(true)
            self.nowRedCircle:setVisible(true)
        end
        self.butReceive:setGray(true)
        self.butReceive:setListener(function()
            display.pushNotice(Localize("stringHaveGet"))
        end)
    end
end
function SignRewardDialog:callCell(cell, tableView, info)
    local item = info.item
    local bg = cell:getDrawNode()
    -- cell:setEnable(false)
    self:loadView("infoCellViews",bg)
    self:insertViewTo()
    local vip = GameLogic.getUserContext():getInfoItem(const.InfoVIPlv)
    local dvip = 0
    local lgd = 1
    if not GameLogic.useTalentMatch then
        lgd = SData.getData("viplgd",vip,info.id)
        for i,v in ipairs(SData.getData("viplgd")) do
            if v[info.id] == 2 then
                self:loadView("vipViews",bg)
                GameUI.addVip(bg,i,10,90,9,{scale=0.7,rMode=true,r=-40})
                dvip = i
                self.whatDay:setVisible(false)
                break
            end
        end
    end
    self:insertViewTo()
    self.whatDay:setString(info.id..Localize("day"))
    local idx = self.params[3]
    local isget = self.params[4]
    if item.gtype==10 and item.gid==4 then--钻石
        GameUI.addResourceIcon(bg, 4, 1, 75+22,75+19,1,3)
    else
        GameUI.addItemIcon(bg,item.gtype,item.gid,150/200,75+22,75+19,false)
    end
    self.rewardNum:setString(item.gnum)

    if info.id<idx then

    elseif info.id == idx then
        if isget == 0 then
            self.redCircle:setVisible(false)
        end
        self.nowRedCircle = self.redCircle
        self.rightRewardNum:setString("X" .. item.gnum)
        if lgd == 2 then
            GameUI.addVip(self,dvip,1646,638,0)
            local temp = ui.label(Localize("labelDouble2"),General.font1,40,{color = {255,255,255}})
            display.adapt(temp,1833,658,GConst.Anchor.Left)
            self:addChild(temp)
        end
        self:reload()
    else
        self.redCircle:setVisible(false)
    end
    GameUI.registerTipsAction(cell, self, item.gtype, item.gid)
end
------------------------------------------------------------------------------------------------
function SignRewardDialog:getactreward(atype,aid)
    if not GameNetwork.lockRequest() then
        return
    end
    local params = self.params
    _G["GameNetwork"].request("getactreward",{getactreward = {12,1}},function(isSuc, data)
        GameNetwork.unlockRequest()
        if isSuc then
            local activeData = GameLogic.getUserContext().activeData
            activeData:finishActCondition(const.ActTypeSignIn, 1)
            activeData:getReward(12)
            local vip = GameLogic.getUserContext():getInfoItem(const.InfoVIPlv)
            local lgd = SData.getData("viplgd",vip,params[3])
            local reward = data[1]
            if not GameLogic.useTalentMatch and lgd == 2 then
                local str = Localize("labelGet")
                str = str .. GameLogic.getItemName(reward[1],reward[2])
                if reward[1] == const.ItemHero or reward[1] == const.ItemEquip then
                    str = str .. "x" .. #data
                else
                    str = str .. "x" .. reward[3]/2
                end
                display.pushNotice(str)
                local str = Localizef("labelVipMoreGet",{a=vip})
                str = str .. GameLogic.getItemName(reward[1],reward[2])
                if reward[1] == const.ItemHero or reward[1] == const.ItemEquip then
                    str = str .. "x" .. #data
                else
                    str = str .. "x" .. reward[3]/2
                end
                display.pushNotice(str)
            else
                local str = Localize("labelGet")
                str = str .. GameLogic.getItemName(reward[1],reward[2])
                if reward[1] == const.ItemHero or reward[1] == const.ItemEquip then
                    str = str .. "x" .. #data
                else
                    str = str .. "x" .. reward[3]
                end
                display.pushNotice(str)
            end
            GameLogic.showHeroRewsUieffect(data)
            GameLogic.addRewards(data)
            GameLogic.statCrystalRewards("签到奖励",data)
            if self.reload then
                self:reload(true)
            end
            if self.aDialog and self.aDialog.timeLimitActivity then
                self.aDialog:timeLimitActivity()
            end
        end
    end)
end
return SignRewardDialog












