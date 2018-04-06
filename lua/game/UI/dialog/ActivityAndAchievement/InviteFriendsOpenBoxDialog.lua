local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
--邀请好友开宝箱对话框
local InviteFriendsOpenBoxDialog = class2("InviteFriendsOpenBoxDialog",function()
    return BaseView.new("InviteFriendsOpenBoxDialog.json")
end)
function InviteFriendsOpenBoxDialog:ctor()
    self.scene = GMethod.loadScript("game.View.Scene")
    self.dialogDepth=display.getDialogPri()+1
    --self:getfriendhelp()
    self:getFriends()
    self.priority=self.dialogDepth
    display.showDialog(self)
    self:loadView("backAndupViews")
    self:insertViewTo()
    self.butHelp:setListener(Handler(self.onQuestion, self))
    self.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
end

function InviteFriendsOpenBoxDialog:onQuestion()
    HelpDialog.new("dataQuestionOpenBox")
end

function InviteFriendsOpenBoxDialog:initUI()
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    self:loadView("leftViews")
    --宝箱下特效
    UIeffectsManage:showEffect_haoyoubaoxiang(self,746,642)

    for i=1,10 do
        if i>1 and i<10 then
            local temp=ui.colorNode({3,60},{0,0,0})
            display.adapt(temp,143+(i-1)*134,152,GConst.Anchor.LeftBottom)
            self:addChild(temp)
        end

        local lvNum = ui.label(StringManager.getString("Lv."..i), General.font1,30)
        display.adapt(lvNum, 143+(i-1)*134,134, GConst.Anchor.Center)
        self:addChild(lvNum)
        if i==10 then
            lvNum:setString("Max")
        end
    end

    local allExp = 0
    for k,v in pairs(self.params.help) do
        if v[1] == 1 then
            allExp = allExp+v[3]
        end
    end
    local nextExp = 2
    local nowExp = 0
    local readylv = 0
    for i,v in ipairs(const.FacebookBoxSet) do
        if allExp<0 then
            break
        else
            readylv = i-1
        end
        nowExp = allExp
        nextExp = v
        allExp = allExp - v
    end
    if allExp>0 then
        nowExp = const.FacebookBoxSet[9]
        nextExp = nowExp
        readylv = 9
    end
    self.readylv = readylv
    self:insertViewTo()
    self.expProcess:setProcess(true,nowExp/nextExp)
    self.expProcessValue:setString(nowExp.."/"..nextExp)
    self.lvProcess:setProcess(true,readylv/9)
    self.lvNum:setString(readylv)
    self.expNum:setString("(Exp:" .. nowExp .."/" .. nextExp .. ")")
    self.butSeeReward:setListener(function()
        InviteFriendsRewardDialog.new(self.rewardInfos)
    end)


    self:loadView("rightViews")
    local context = GameLogic.getUserContext()
    self.context = context

    self:reloadBox()
    self:reloadTab()
end

--奖励列表
function InviteFriendsOpenBoxDialog:initRewardInfos()
    local infos={}
    local hotData = GameLogic.getUserContext().activeData.hotData
    local rewards={}
    for j,v in ipairs(SData.getData("activeReward")) do
        if v.atype ==58 then
            table.insert(rewards,v)
        end
    end
    for i=1,10 do--10个宝箱
        local cState=false
        local rState=false
        if i<=self.readylv then--达成状态
            cState=true
        end
        if i<=self.hdata.isget then--已领取
            rState=true
        end
        local info={id=i,rState=rState,cState=cState,rewards={}}
        for j,reward in ipairs(rewards) do
            if reward.aid==i then
                table.insert(info.rewards,reward)
            end
        end
        infos[i]=info
    end
    self.rewardInfos=infos
end

function InviteFriendsOpenBoxDialog:reloadBox()
    local context = self.context
    local hotData = context.activeData.hotData
    for i,v in ipairs(hotData) do
        if v.atype == 58 then
            self.hdata = v
        end
    end
    local readylv = self.readylv
    if readylv>self.hdata.isget then
        self.stringClickBoxInvite:setString(Localize("stringClickBoxReceive"))
        self.butOpenOrReceive:setListener(function()
            GameLogic.getactreward(58,self.hdata.isget+1,function()
                self.hdata.isget = self.hdata.isget+1
                if self.initUI then
                    self.reloadBox()
                end
            end)
        end)
    else
        self.stringClickBoxInvite:setString(Localize("stringClickBoxInvite"))
        self.butOpenOrReceive:setListener(function()
            self:sendhelp()
        end)
    end
    self:initRewardInfos()
end

function InviteFriendsOpenBoxDialog:reloadTab()
    --测试用好友id
    local context = self.context
    local friends = context.fbFriends or {}
    self.friends = friends

    for i,v in ipairs(friends) do
        if self.params.behelp[v[1]] and self.params.behelp[v[1]][2] == 0 then
            table.remove(friends,i)
            table.insert(friends,1,v)
        end
    end

    local infos={}
    for i=1,#friends do
        infos[i]={id=i,item = friends[i]}
    end

    if self.tabNode then
        self.tabNode:removeFromParent(true)
        self.tabNode = nil
    end
    self.tabNode = ui.node()
    self:addChild(self.tabNode)
    self:addTableViewProperty("rightTableView",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("rightTableView",self.tabNode)
end

function InviteFriendsOpenBoxDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local item = info.item
    self:loadView("rightCellViews",bg)
    --GameUI.addHeroHead(bg,4001,{x=0,y=0,size = {200,200}})
    GameUI.addFacebookHead(bg,info.item[4],{size={227,222}})
    self:insertViewTo()
    self.uname:setString(item[2])
    if self.params.behelp[item[1]] and self.params.behelp[item[1]][2] == 0 then
        local redNum = GameUI.addRedNum(bg,-10,180,0,1,1)
        redNum:setNum(1)
        ui.setListener(cell,function()
            self:helpfriends(item[1])
        end)
    end
end

---------------------------------------------------------------
function InviteFriendsOpenBoxDialog:getfriendhelp()
    _G["GameNetwork"].request("getfriendhelp",nil,function(isSuc,data)
        if isSuc then
            self.params = {help = {},behelp = {}}
            for k,v in pairs(data) do
                for i,value in ipairs(v) do
                    self.params[k][value[1]] = value
                end
            end

            if self.initUI then
                self:initUI()
            end
        end
    end)
end

function InviteFriendsOpenBoxDialog:sendhelp()
    InviteFriendsDialog.new(self.params,self.friends)
end

function InviteFriendsOpenBoxDialog:helpfriends(id)
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdActFHelp,id})
    display.pushNotice(Localize("labelHelpSucceed"))
    if self.initUI then
        self.params.behelp[id][2] = 1
        self:reloadTab()
    end
end

function InviteFriendsOpenBoxDialog:getFriends()
   self.scene.menu:initFacebooFriends(function ()
        if self.getfriendhelp then
            self:getfriendhelp()
        end
   end)
end

return InviteFriendsOpenBoxDialog





















