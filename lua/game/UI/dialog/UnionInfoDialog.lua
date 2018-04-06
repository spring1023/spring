local requestJionTimes={}

local const = GMethod.loadScript("game.GameLogic.Const")
--联盟信息对话框
local UnionInfoDialog = class2("UnionInfoDialog",function()
    return BaseView.new("UnionInfoDialog.json")
end)

function UnionInfoDialog:ctor(uid)
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initBack()
    self:getleagueinfo(uid)

    display.showDialog(self)

    GameEvent.bindEvent(self,"applyUnion","",function(event,id)
        self:getleagueinfo(id)
    end)
end


function UnionInfoDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
end

    GameEvent.sendEvent("EventFreshUnionMenu")
function UnionInfoDialog:canExit()
    return true
end

function UnionInfoDialog:initUI(params)

    self.unionOperationNode = nil
    self.nodeTouchRemoveBut=nil
    self:removeAllChildren(true)
    self:initBack()

    self:loadView("upViews")
    self:insertViewTo()
    --旗帜
    local item = self.params.leaguedata
    local temp = GameUI.addUnionFlag(item.ps1,item.ps2,item.ps3)
    self:addChild(temp)
    temp:setScale(0.46)
    temp:setPosition(174+55,1193+58)
    if GameLogic.getUserContext().union and (not self.params.isChatRoom) then
        if GameLogic.getUserContext().union.id == item.uid then
            self:loadView("twoButtonViews")
            self:insertViewTo()
            self.btnEdit:setListener(function()
                print("编辑")
                UnionDialog.new(self.params,function()
                    if self.initUI then
                        self:initUI()
                        -- print("联盟公告输入完成调用")
                    end
                end)
            end)
            self.btnApply:setListener(function()
                    display.showDialog(UnionApplyLogDialog.new({params=self.params.applyList}))
                end)
            self.btnUnionWelfare:setListener(function()
                display.showDialog(UnionWelfareLogDialog.new())
            end)
            self.btnUnionWelfare1:setListener(function()
                display.showDialog(UnionWelfareLogDialog.new())
            end)
            self.btnDonationLog:setListener(function ()
                display.showDialog(UnionDonationLogDialog.new({params = self.params.memberdata}))
            end)
            self.btnDonationLog1:setListener(function ()
                display.showDialog(UnionDonationLogDialog.new({params = self.params.memberdata}))
            end)
            self.btnRewardLog:setListener(function ()
                UnionBattleAssignRewardsDialog.new()
            end)
            if GameLogic.getUserContext().union.job<4 then
                self.btnEdit:setVisible(false)
                self.btnApply:setVisible(false)
                self.btnDonationLog:setVisible(false)
                self.btnDonationLog1:setVisible(true)
                self.btnUnionWelfare:setVisible(false)
                self.btnUnionWelfare1:setVisible(true)
            else
                self.btnDonationLog1:setVisible(false)
                self.btnUnionWelfare1:setVisible(false)
                local redNum = GameUI.addRedNum(self.btnApply,-20,90,0,0.8,100)
                redNum:setNum(#self.params.applyList)
            end

        end
    elseif (not GameLogic.getUserContext().union) then
        self:loadView("oneButtonViews")
        self:insertViewTo()
        self.butJoin:setListener(function()
            local uid=item.uid
            if not requestJionTimes[uid] then
                self:jionleague()
            else
                local dtime=requestJionTimes[uid]-GameLogic.getSTime()
                if dtime>0 then
                    display.pushNotice(Localizef("noticeRequestJionTime",{a=math.ceil(dtime/60)}))
                else
                    self:jionleague()
                    requestJionTimes[uid]=nil
                end
            end
        end)
    elseif GameLogic.getUserContext().union and (not self.params.isChatRoom) then
        --什么都不显示
    end

    --总积分
    self.labelAllScoreValue:setString(item.allscore)
    --上面字
    self.labelUnionName:setString(item.name)
    --战争胜利
    self.labelWarWinValue:setString(item.winValue)
    --加入方式
    self.labelJoinMethodValue:setString(StringManager.getString("labelJoinMethodValue"..item.state))
    --金杯限制
    self.labelTrophyLimitValue:setString(item.minCup)
    --成员
    self.labelMembersValue:setString(item.member.."/"..item.maxMember)
    --公告
    self.labelUnionNoticeValue:setString(item.notice)
    --联盟ID
    self.labelUnionIDValue:setString(item.uid)
    --语言
    self.labelUnionLanguage:setString(Localize("labelLanguage"..item.language))
    --退出
    self.butQuit:setVisible(false)
    if GameLogic.getUserContext().union and GameLogic.getUserContext().union.id == item.uid then
        -- if not GameLogic.getUserContext().union.fstate or GameLogic.getUserContext().union.fstate == 0 then
        --     self.butQuit:setVisible(true)
        -- end
        self.butQuit:setVisible(true)
        self.butQuit:setListener(function()
            local otherSettings = {callback = function()
                self:leaveleague()
            end}
            local dialog = AlertDialog.new(3,Localize("unionInfoNotice1"),Localize("unionInfoNotice2"),otherSettings)
            display.showDialog(dialog)
        end)
    end


    local infos={}
    for i=1,#self.params.memberdata do
        infos[i]={item = self.params.memberdata[i]}
    end
    self:sortInfos(infos)
    for i=1,#infos do
        infos[i].id=i
    end
    self:addTableViewProperty("infoTableview",infos,Script.createBasicHandler(self.callcell,self))
    self:addTableViewProperty2("infoTableview",infos,Script.createBasicHandler(self.scrollTo,self))
    self:loadView("infoTableview")
end

--显示排序：先按照福利，其次按照 职位高低，再按照贡献点，再按照等级，最后的随机
function UnionInfoDialog:sortInfos(infos)
    table.sort(infos,function(a, b)
        if a.item.welfare == b.item.welfare then
            if a.item.job == b.item.job then
                if a.item.contribute== b.item.contribute then
                    return a.item.lv > b.item.lv
                else
                    return a.item.contribute > b.item.contribute
                end
            else
                return a.item.job > b.item.job
            end
        else
            return a.item.welfare > b.item.welfare
        end
    end)
end

function UnionInfoDialog:callcell(cell, tableView, info)
    local item = info.item
    local bg = cell:getDrawNode()
    cell:setEnable(true)
    self:loadView("infoViewsBack",bg)
    if GameLogic.getUserContext().uid == item.unid then
        self:loadView("infoViewsBackBlue",bg)
    end
    self:loadView("infoViews",bg)
    self:insertViewTo(info)

    --icon
    local head = GameUI.addPlayHead(info.iconNode,{viplv=nil,id=item.icon,scale=1,x=50,y=35,z=1,blackBack = true})
    head:setTouchThrowProperty(true, true)
    --VIP
    GameUI.addVip(info.imgVIP,item.vip,0,0)

    --入盟不足一天不能领取福利
    info.labelCellTrophyNume:setVisible(false)
    info.trophyBack:setVisible(false)
    info.resScore:setVisible(false)
    info.butWorship:setVisible(false)
    if GameLogic.getUserContext().union and GameLogic.getUserContext().union.id == item.uid and GameLogic.getUserContext().union.joinTime and GameLogic.getToday()>GameLogic.getUserContext().union.joinTime then
        info.labelCellTrophyNume:setVisible(true)
        info.trophyBack:setVisible(true)
        info.resScore:setVisible(true)
        info.butWorship:setVisible(true)
    end
    --福利
    local function refreshWelfare()
        -- print("item.welfare,",item.welfare)
        -- print("item.alreadyReceive",item.alreadyReceive)
        -- print("canGet",item.welfare-item.alreadyReceive)
        if item.welfare-item.alreadyReceive>0 then
            local canGet = item.welfare-item.alreadyReceive
            if item.alreadyReceive>0 then
                info.labelCellTrophyNume:setString("+"..canGet)
            else
                info.labelCellTrophyNume:setString(canGet)
            end
            info.labelRecive:setString(Localize("labelRecive"))
            if GameLogic.getUserContext().union and GameLogic.getUserContext().union.id == item.uid and GameLogic.getUserContext().union.joinTime and GameLogic.getToday()<GameLogic.getUserContext().union.joinTime then
                info.labelCellTrophyNume:setVisible(true)
                info.trophyBack:setVisible(true)
                info.resScore:setVisible(true)
                info.butWorship:setVisible(true)
                info.butWorship:setGray(true)
                self.timeNotEnough = true
            end
        elseif item.alreadyReceive>0 then
            info.labelCellTrophyNume:setString(item.alreadyReceive)
            info.butWorship:setGray(true)
            info.butWorship:setEnable(false)
            info.labelRecive:setString(Localize("labelRecived"))
        else
            info.labelCellTrophyNume:setString(0)
            info.labelCellTrophyNume:setVisible(false)
            info.trophyBack:setVisible(false)
            info.resScore:setVisible(false)
            info.butWorship:setVisible(false)
        end
    end
    refreshWelfare()

    --领取福利
    local lockRecive =false
    info.butWorship:setListener(function()
        if self.timeNotEnough then
            display.pushNotice(Localize("noiceTimeNotEnough2"))
            return
        end
        if lockRecive then
            return
        end
        lockRecive =true
        _G["GameNetwork"].request("clanWelfare",{tid=item.unid},function(isSuc,data)
            lockRecive =false
            if isSuc then
                if data.crystal==0 then
                    --过时的奖励
                    display.pushNotice(Localize("noticeOutdatedReward"))
                else
                    local cryNum = data.crystal
                    local reward={{10,4,cryNum}}
                    GameLogic.addRewards(reward)
                    GameLogic.showGet(reward)
                    if cryNum<(item.welfare-item.alreadyReceive) then
                        --部分过时的奖励
                        display.pushNotice(Localizef("noticeOutdatedReward2",{a=item.welfare-item.alreadyReceive-cryNum}))
                    end
                    item.alreadyReceive = item.alreadyReceive +cryNum
                end
                item.welfare = item.alreadyReceive
                refreshWelfare()
            end
        end)
    end)

    --名字
    --self.labelCellName:setString(item.name.."XXXXXXXXXXX")
    info.labelCellName:setString("Lv:"..item.lv.." "..item.name)
    --职位
    info.labelCellJob:setString(StringManager.getString("labelCellJob"..item.job))
    --贡献
    info.labelContributionValue:setString(item.contribute)
    --最后登录
    local time = GameLogic.getTime()-item.lastLogin-1800
    if time>0 then
        info.labelLastLandTime:setString(Localizef("labelLastLogin", {a = Localizet(time)}))
    else
        print("在线")
        --self.rankNumberBox:setSValue(0)
        info.labelLastLandTime:setString(Localize("labelOnLine"))
    end

    local myJob = GameLogic.getUserContext().union and GameLogic.getUserContext().union.job
    local heJob = item.job
    local butContent = {}

    --权限判断
    if GameLogic.getUserContext().union and GameLogic.getUserContext().union.id == item.uid then  --同一个联盟的
        if item.unid ~= GameLogic.getUserContext().uid then --不是自己
            if myJob == 5 then
                if heJob>2 then
                    butContent = {{"visit"},{"up",heJob+1},{"down",heJob-1},{"out",0},}
                else
                    butContent = {{"visit"},{"up",heJob+1},{"out",0},}
                end
            elseif myJob == 4 then
                if heJob == 3 then
                    butContent = {{"visit"},{"down",heJob-1},{"out",0}}
                elseif heJob == 2 then
                    butContent = {{"visit"},{"up",heJob+1},{"out",0},}
                else
                    butContent = {{"visit"}}
                end
            elseif myJob == 3 then
                if heJob == 2 then
                    butContent = {{"visit"},{"out",0}}
                else
                    butContent = {{"visit"}}
                end
            else
                butContent = {{"visit"}}
            end
        end
    else
        butContent = {{"visit"}}
    end
    if false then            --是否是好友
        table.insert(butContent,{"add"})
    end

    local rtime = item.cardTime-GameLogic.getSTime()
    local isGive=false
    if rtime/86400<3 then            --是否可以赠送
        isGive=true
    end
    table.insert(butContent,{"give",nil,isGive})

    local butContentR = {}
    for i,v in ipairs(butContent) do
        butContentR[#butContent+1-i] = v
    end

    local function showUnionOperation()
        local pos=cell:convertToWorldSpace(cc.p(0,100))
        local pos2=self:convertToNodeSpace(pos)
        self:unionOperationViews(info.id,pos2.y,butContentR,item)
    end
    if GameLogic.getUserContext().union and GameLogic.getUserContext().union.id == self.params.leaguedata.uid then
        cell:setScriptCallback(Script.createCallbackHandler(showUnionOperation))
    end
end

--滚动就删除联盟操作的节点
function UnionInfoDialog:scrollTo(px,py)
   if self.unionOperationNode then
        self.unionOperationNode:removeFromParent(true)
        self.unionOperationNode=nil
   end
end

function UnionInfoDialog:unionOperationViews(i,posH,butContent,item)
    local butNum = #butContent  --172   860  144
    local upLimitH=630 + (720-144*butNum)/2
    local downLimitH=430 - (720-144*butNum)/2
    local cursorH=0
    if posH<downLimitH then
        cursorH=posH-downLimitH
        posH=downLimitH
    elseif posH>upLimitH then
        cursorH=posH-upLimitH
        posH=upLimitH
    end

    local sizeH=144*butNum+140
    cursorH=cursorH+sizeH/2
    if cursorH>sizeH-48 then
        cursorH=sizeH-48
    elseif cursorH<64 then
        cursorH=64
    end
    local operation=true
    if self.unionOperationNode then
        self.unionOperationNode:removeFromParent(true)
        self.unionOperationNode=nil
        operation=false
        if self.seeIdx==i then
            self.seeIdx=nil
            return
        end
    end
    self.seeIdx=i
    if item.unid == GameLogic.getUserContext().uid then
        return
    end

    if not self.operationI or self.operationI~=i or operation then
        self.operationI=i
        local temp=ui.button({443,sizeH},nil,{image = "images/unionOperationBack.png",priority=-3,actionType=0})
        display.adapt(temp,818 ,posH, GConst.Anchor.Left)
        self:loadView("unionOperationNodeViews",temp)

        for i=1,butNum do
            self:loadView("butView",temp)
            self:insertViewTo()
            self.butVisit:setPosition(210,139+144*(i-1))

            local str = SG("power_"..butContent[i][1])
            if butContent[i][2] and butContent[i][2]~=0 then
                str = str..SG("labelCellJob"..butContent[i][2])
            end
            self.btnVisit:setString(str)
            if butContent[i][1] == "visit" then
                self.butVisit:setListener(function()
                    -- print("参观")
                    GameEvent.sendEvent(GameEvent.EventVisitBegin,{type = const.VisitTypeUn, uid = item.unid})
                end)
            elseif butContent[i][1] == "up" or butContent[i][1] == "down" or butContent[i][1] == "out" then
                self.butVisit:setListener(function()
                    self:managelmember(butContent[i][2],item)
                end)
            elseif butContent[i][1] == "add" then
                self.butVisit:setListener(function()
                    -- print("加为好友")
                end)
            elseif butContent[i][1] == "give" then
                if not butContent[i][3] then
                    self.butVisit:setGray(true)
                end
                self.butVisit:setListener(function()
                    if butContent[i][3] then--可赠送
                        local context = GameLogic.getUserContext()
                        local num = context:getProperty(const.ProMonthCard)
                        if num<=0 then
                            local otherSettings = {callback = function()
                                StoreDialog.new(1)
                            end}
                            local dl = AlertDialog.new(3,Localize("alertTitleNormal"),Localize("stringNoMonthCardSend"),otherSettings)
                            display.showDialog(dl)
                        else
                            local otherSettings = {callback = function()
                                print("赠送月卡")
                                self:givemonthcard(item.unid)
                            end}
                            local dl = AlertDialog.new(3,Localize("labelAffirm"),Localize("stringAffiremSend"),otherSettings)
                            display.showDialog(dl)
                        end
                    else
                        display.pushNotice(Localize("noticeNotGiveCard"))
                    end
                end)
            end
        end

        self.unionOperationNode=temp
        display.setNodeTouchRemove(self,"unionOperationNode")
        self:addChild(temp,3)
        self.viewTab.imaCursor:setPositionY(cursorH)
    end
end
------------------------------------------------------------------------------------------------------------
function UnionInfoDialog:getleagueinfo(uid)
    if type(uid) == "table" then
        self:dealData(uid)
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getleagueinfo",{getleagueinfo={uid or 0}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==2 then
                GameLogic.getUserContext().union = nil
                GameLogic.getUserContext().unionPets = nil
                display.pushNotice(Localize("noticeOutLeague"))--你被移除联盟
                display.closeDialog(display.getDialogPri())
                if self.canExit then
                    self:canExit()
                end
                return
            end
            if type(data)=="table" then
                if self.dealData then
                    self:dealData(data)
                end
            end
        end
    end)
end

function UnionInfoDialog:dealData(data)
    local params = {}
    local v = data.cinfo
    --更新联盟信息
    local context = GameLogic.getUserContext()
    params.isChatRoom = data.isChatRoom
    params.applyList = data.applylist
    params.leaguedata = {
        uid = v[1],
        name = v[2],
        state = v[3],
        maxMember = v[4],
        member = v[5],
        allscore = v[6],
        ps1 = math.floor(v[7]/10000),
        ps2 = math.floor((v[7]%10000)/100),
        ps3 = v[7]%10000%100,
        notice = v[8],
        minCup = v[9],
        winValue = v[15],
        flag = v[7],
        language = v[16]
    }
    local isTure,isSelf,chamId = false,false
    params.memberdata = {}
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWelfare)
    local wNum = 1
    if buffInfo[4]~=0 then
        wNum = buffInfo[4]/20
    end
    for i,v in ipairs(data.plays) do
        local weNum = math.floor(wNum*v[8])
        local wtNum = math.floor(wNum*v[12])
        local info = {
            uid = params.leaguedata.uid,         --联盟id
            unid = v[11],        --人id
            icon = v[1],
            lv = v[2],
            name = v[3],
            vip = v[4],
            job = v[5],
            power = v[6],
            donate = v[13],
            contribute = v[7],

            lastLogin = v[9],
            cardTime = v[10],
            welfare = weNum,--总福利
            alreadyReceive= wtNum,--已领取福利
            fstate = v[14],--参战状态
            joinTime = v[15]
        }
        table.insert(params.memberdata,info)

        if info.job==5 then
            if GameLogic.getSTime() - info.lastLogin > 14*60*60*24 then
                isTure = true
                chamId = info.unid
            end
        end

        --给自己的职位赋值
        if context.union and context.union.id == info.uid and context.uid == info.unid then
            context.union.job = info.job
            if info.job < 5 then
                isSelf = true
            end
            --加入时间
            context.union.joinTime = info.joinTime
            --参战状态
            context.union.fstate = info.fstate
        end
    end
    if isTure and isSelf then
        if not GameNetwork.lockRequest() then
            return
        end
        _G["GameNetwork"].request("clanLeader",{tid=chamId},function(isSuc,data)
            GameNetwork.unlockRequest()
        end)
    end

    if context.union and context.union.id == params.leaguedata.uid then
        context.union.flag = params.leaguedata.flag
        context.union.cup = params.leaguedata.allscore
    end

    self.params = params
    if self.initUI then
        self:initUI()
    end
end

function UnionInfoDialog:leaveleague()
    local cid = self.params.leaguedata.uid
    _G["GameNetwork"].request("leaveleague",{},function(isSuc,data)
        if isSuc then
            GameLogic.getUserContext():changeProperty(const.ResGXun,data.gxun or 0)
            local name = GameLogic.getUserContext():getInfoItem(const.InfoName)
            local uid = GameLogic.getUserContext().uid
            local ug = {lv = GameLogic.getUserContext():getInfoItem(const.InfoLevel)}
            ug.isOut = true
            local msg = {uid=uid,cid=cid,text="加加加",name=name,ug=json.encode(ug),mtype=1,headIcon=GameLogic.getUserContext():getInfoItem(const.InfoHead)}
            local scene = GMethod.loadScript("game.View.Scene")
            scene.menu.chatRoom:send(msg)
            display.pushNotice(Localize("unionInfoNotice3"))
            GameLogic.getUserContext().union = nil
            GameLogic.getUserContext().unionPets = nil
            display.closeDialog(display.getDialogPri())

            --联盟月卡
            local context = GameLogic.getUserContext()
            if context.vips[4][2]>GameLogic.getSTime() then
                local rtime = context.vips[4][2] - GameLogic.getSTime()
                rtime = math.floor(rtime/86400)
                context.vips[5][2] = context.vips[5][2]-86400*rtime
            end
        end
    end)
end

function UnionInfoDialog:jionleague()
    local params = self.params
    --战力限制
    if params.leaguedata.minCup > GameLogic.getUserContext():getProperty(const.ProCombat) then
         display.pushNotice(Localize("stringPowerNotEnough"))
        return
    end

    local context = GameLogic.getUserContext()
    if params.leaguedata.state == 1 then
        if not GameNetwork.lockRequest() then
            return
        end
        _G["GameNetwork"].request("jionleague",{jionleague={params.leaguedata.uid,context.uid,1}},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                if data.code==2 then
                    context.union = nil
                    display.pushNotice(Localize("noticeOutLeague"))
                    display.closeDialog(display.getDialogPri())
                    return
                elseif data.code==11 then
                    display.pushNotice(Localize("labelJoinUnionFail11"))
                    return
                elseif data.code==10 then
                    display.pushNotice(Localize("labelJoinUnionFail101"))
                    self:dealData(data)
                    self:changeUnionData(data)
                    self:canExit()
                    display.closeDialog(1)
                    return
                end
                local activeData = context.activeData
                activeData:finishAct(52)
                display.pushNotice(Localize("labelAddSucceed"))
                if self.changeUnionData then
                    self:changeUnionData(data)
                end
                if self.initUI then
                    self:initUI()
                end
                local ug = {lv = context:getInfoItem(const.InfoLevel),headIcon=GameLogic.getUserContext():getInfoItem(const.InfoHead)}
                local msg = {uid=context.uid,cid=params.leaguedata.uid,text="1234",name=context:getInfoItem(const.InfoName),
                ug=json.encode(ug),mtype=1}
                local scene = GMethod.loadScript("game.View.Scene")
                scene.menu.chatRoom:send(msg)
                GameEvent.sendEvent("EventJoinClan")
            end
        end)
    elseif params.leaguedata.state == 3 then
        display.pushNotice(Localize("labelJoinMethodValue3"))
    elseif params.leaguedata.state == 2 then
        local tuid = params.leaguedata.uid
        _G["GameNetwork"].request("jionleague",{jionleague={tuid,context.uid,4}},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                if data.code == 11 then
                    display.pushNotice(Localize("labelJoinUnionFail11"))
                else
                    if data.code == 12 then
                        display.pushNotice(Localize("labelJoinMethodValue12"))
                        return
                    end
                    local name = context:getInfoItem(const.InfoName)
                    local uid = context.uid

                    local ug = {lv = context:getInfoItem(const.InfoLevel),headIcon=GameLogic.getUserContext():getInfoItem(const.InfoHead)}
                    local msg = {uid=uid,cid=params.leaguedata.uid,text="加加加",name=name,ug=json.encode(ug),mtype=2}
                    local scene = GMethod.loadScript("game.View.Scene")
                    scene.menu.chatRoom:send(msg)
                    requestJionTimes[tuid]=GameLogic.getSTime()+30*60
                end
            end
        end)
    end
end

function UnionInfoDialog:changeUnionData(data)
    local context = GameLogic.getUserContext()
    local ld = self.params.leaguedata
    local linfo = data.cinfo
    local pinfo = data.plays
    context.unionPets = {skill=data.psk or {1,1,1,1,1,1}, pets=data.pids, curPid=linfo[14], level=linfo[12], exp=linfo[13], pbead=linfo[11] or 0}
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWelfare)
    local wNum = 1
    if buffInfo[4]~=0 then
        wNum = buffInfo[4]/20
    end
    for k,v in ipairs(pinfo) do
        if v[11] == context.uid then
            local weNum = math.floor(wNum*v[8])
            local wtNum = math.floor(wNum*v[12])
            local info = {
                uid = self.params.leaguedata.uid,         --联盟id
                unid = v[11],        --人id
                icon = v[1],
                lv = v[2],
                name = v[3],
                vip = v[4],
                job = v[5],
                power = v[6],
                donate = v[13],
                contribute = v[7],

                lastLogin = v[9],
                cardTime = v[10],
                welfare = weNum,--总福利
                alreadyReceive= wtNum,--已领取福利
                fstate = v[14],--参战状态
                joinTime = v[15]
            }

            table.insert(self.params.memberdata,info)
            self.params.leaguedata.member = self.params.leaguedata.member+1
            context.union = {id=info.uid,job=info.job,name=linfo[2], flag=linfo[7], enterTime=GameLogic.getTime(), cup = linfo[6],language = linfo[16],joinTime=info.joinTime,fstate = info.fstate}
        end
    end
end




function UnionInfoDialog:managelmember(job,item,sure,str)
    local mode
    if job == 0 then
        mode = 0
    elseif item.job<job then
        mode = 1
    else
        mode = 2
    end

    if not sure then
        local dialog
        if mode == 0 then
            local otherSettings = {callback=function(str)
                self:managelmember(job,item,true,str)
            end}
            dialog = AlertDialog.new(10,Localizef("labelTiChuXXX",{a = item.name}),Localize("stringOutUnion"),otherSettings)
        else
            local title,text
            if mode == 1 then
                title = Localize("labelSureUp")
                text = Localizef("stringSureUp",{a=item.name, b=Localize("labelCellJob"..job)})
            elseif mode == 2 then
                title = Localize("labelSureDown")
                text = Localizef("stringSureDown",{a=item.name, b=Localize("labelCellJob"..job)})
            end
            dialog = AlertDialog.new(3,title,text,{callback=function()
                self:managelmember(job,item,true)
            end})
        end
        display.showDialog(dialog)
        return
    end

    _G["GameNetwork"].request("managelmember",{managelmember={job,item.unid,str or ""}},function(isSuc,data)
        if not isSuc then
            return
        end
        if data.code == 0 then
            print("设置成功")
            if job == 0 then
                display.pushNotice(Localize("labelKickOutSucceed"))
            else
                if mode == 1 then
                    display.pushNotice(Localize("labelAppointSucceed"))
                elseif mode == 2 then
                    display.pushNotice(Localize("stringDownSucceed"))
                end
            end
            if job~=0 then
                item.job = job
            else
                if self.params then
                    for i,v in ipairs(self.params.memberdata) do
                        if v == item then
                            table.remove(self.params.memberdata,i)
                            self.params.leaguedata.member = self.params.leaguedata.member - 1
                        end
                    end
                end
            end
            GameLogic.sendChat({mtype=4, mode=mode, uid=item.unid, cid=item.uid, job=item.job, lv=item.lv, name=item.name})
            if self.initUI then
                self:initUI()
            end
        elseif data.code == 10 then
            display.pushNotice(Localize("labelCantManagelmember1"))
            if self.initUI then
                self:initUI()
            end
        elseif data.code == 20 then
            display.pushNotice(Localize("labelCantManagelmember2"))
            if self.params then
                for i,v in ipairs(self.params.memberdata) do
                    if v == item then
                        table.remove(self.params.memberdata,i)
                        self.params.leaguedata.member = self.params.leaguedata.member - 1
                    end
                end
            end
            if self.initUI then
                self:initUI()
            end
        end
    end)
end

function UnionInfoDialog:givemonthcard(uid)
    local function callback()
        if self.initUI then
            for i,v in ipairs(self.params.memberdata) do
                if v.unid == uid then
                    v.cardTime = v.cardTime+30*86400+GameLogic.getSTime()
                end
            end
            self:initUI()
        end
    end
    GameLogic.givemonthcard(uid, {callback = callback})
end

return UnionInfoDialog









