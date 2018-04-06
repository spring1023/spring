--邮件奖励对话框
local EmailDialog = class2("EmailDialog",function()
    return BaseView.new("EmailDialog.json",true)
end)


function EmailDialog:ctor(LogDialog,data)
    self.LogDialog=LogDialog
    self.data=data
    -- self.data.inbox[4] = {cont = {25, icon = 5, id = 516790, isSeed = false, recevice = 0, rid = 21, time = 00000, title = "", tname = "", uid = 103411,}}
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    local uid=GameLogic.uid
    local sid=GameLogic.getUserContext().sid or 1
    self.eKey="email_" .. uid .."_".. sid
    self:initUI()
    display.showDialog(self)
end

function EmailDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab

    local temp
    local data=self.data
    self.dataId=data.id
    local str
    if data.isPackCodeEmail then
        str=data.title[1]
    else
        str=StringManager.getFormatString(data.rid.."_title",{a=data.title[1],b=data.title[2],c=data.title[3],d=data.title[4],e=data.title[5],f=data.title[6]})
    end
    viewTab.title:setString(str)--标题

    local rewardInfos=data.reward--奖励物品
    local rewardInfosLength=#rewardInfos

    local scNode=ScrollNode:create(cc.size(1210,1000), -self.dialogDepth, false, true)
    scNode:setScrollEnable(true)
    scNode:setInertia(true)
    scNode:setElastic(true)
    scNode:setClip(true)
    scNode:setScaleEnable(true, 1, 1, 1, 1)
    display.adapt(scNode, 43, 205, GConst.Anchor.LeftBottom)
    self:addChild(scNode,1)

    local viewsNode=ui.node()
    display.adapt(viewsNode, 0, 1000)
    scNode:getScrollNode():addChild(viewsNode,1)
    self.viewsNode=viewsNode

    local oy=0
    --邮件文本内容
    local str
    if data.isPackCodeEmail then
        str=data.cont[1]
    elseif data.isKnockOutReward then
        local a = data.cont[1]
        local b = data.cont[2]
        str=StringManager.getFormatString(data.rid.."_cont",{a=b, b = a})
    elseif data.isKnockOutGamble then
        str=StringManager.getFormatString(data.rid.."_cont")
    else
        local a,b
        local akey = data.rid .. "_cont"
        if data.rid==4 or data.rid==7 or data.rid==8 or data.rid==10 or data.rid==13 then
            a=tonumber(data.cont[1])+1
        elseif data.rid==5 or data.rid==6 or data.rid==11 then
            a=tonumber(data.cont[2])+1
            b=tonumber(data.cont[1])+1
        elseif data.rid==9 then
            a=data.cont[1]
        elseif data.rid==16 then
            a=math.floor(data.cont[2]/10)
        elseif data.rid==17 then
            a=math.floor(data.cont[1])
        elseif data.rid >= 32 and data.rid <= 34 then
            a = data.cont[1]
            b = data.cont[2]
            if b < 100 then
                akey = "32_cont"
            else
                akey = "31_cont"
            end
        else
            a = data.cont[1]
            b = data.cont[2]
        end
        str = Localizef(akey, {a=a or "",b=b or "",c=data.cont[3] or "",d=data.cont[4] or "",e=data.cont[5] or "",f=data.cont[6] or ""})
    end
    local cont = ui.label(str, General.font1, 50, {color={255,255,255},width=1150,align=GConst.Align.Left})
    display.adapt(cont, 30, -oy, GConst.Anchor.LeftTop)
    viewsNode:addChild(cont)
    oy=oy+cont:getContentSize().height+40

    --发件人
    local str
    if data.isKnockOutGamble then
        str = ""
    elseif data.tname=="" then
        if data.rid >= 30 then
            str = Localize("1_sender")
        else
            str = Localize(data.rid .. "_sender")
        end
    else
        str=data.tname
    end
    local sendNamer=ui.label(str, General.font1, 50, {color={255,70,70}})
    display.adapt(sendNamer, 1200, -oy, GConst.Anchor.RightTop)
    viewsNode:addChild(sendNamer)

    if data.isKnockOutGamble then
        oy = oy + 134
        --淘汰赛
        -- cont = {{name, lv, head, socre, isWin}}
        -- local _cont = json.decode(data.cont)
        local _cont = data.cont
        local gamBleNum = #_cont
        local gamBleNode = ui.node()
        display.adapt(gamBleNode, 0, -oy)
        viewsNode:addChild(gamBleNode)

        for i=1, gamBleNum do
            local bg = ui.node()
            self:loadView("butKnockOutGambleCell",bg)
            display.adapt(bg, 0, -oy, GConst.Anchor.LeftBottom)

            local _info = _cont[i]
            local uinfo = json.decode(_info.uinfo)
            local uscore = _info.uscore
            local uname = uinfo[1]
            local ulv = uinfo[2]
            local uhead = uinfo[3]
            local ucombat = uinfo[4]
            local usid = uinfo[5]

            local tinfo = json.decode(_info.tinfo)
            local tscore = _info.tscore
            local viewTab=self:getViewTab()
            local wins = _info.wins
            if wins == 0 then
                viewTab.img_win:setTexture("images/pvz/imgPvzEmailWin.png")
            else
                viewTab.img_win:setTexture("images/pvz/imgPvzEmailLose.png")
            end
            -- viewTab.img_pbrBg1:setScaleX(0.6)
            viewTab.img_pbrBg1:setLocalZOrder(-1)
            viewTab.nd_playerModel1:setScale(0.7)

            viewTab.lb_name1:setString(uname)
            viewTab.lb_lv1:setString(ulv)
            viewTab.lb_score1:setString(uscore)
            GameUI.addPlayHead(viewTab.nd_playerModel1, {id=uhead, scale = 1, x=0,y=0,z=-1,blackBack=true, noBlackBack = false})
            -- viewTab.img_pbrBg2:setScaleX(0.4)

            if not GameLogic.isEmptyTable(tinfo) then
                viewTab.img_pbrBg2:setLocalZOrder(-1)
                viewTab.nd_playerModel2:setScale(0.7)

                local tname = tinfo[1]
                local tlv = tinfo[2]
                local thead = tinfo[3]
                local tcombat = tinfo[4]
                local tsid = tinfo[5]

                viewTab.nd_playerModel2:setVisible(true)
                viewTab.lb_noEnemy:setVisible(false)
                viewTab.lb_name2:setString(tname)
                viewTab.lb_lv2:setString(tlv)
                viewTab.lb_score2:setString(tscore)
                GameUI.addPlayHead(viewTab.nd_playerModel2, {id=thead, scale = 1, x=0,y=0,z=-1,blackBack=true, noBlackBack = false})
            else
                viewTab.nd_playerModel2:setVisible(false)
                viewTab.lb_noEnemy:setVisible(true)
            end
            oy = oy + 144
            viewsNode:addChild(bg)
        end
        oy = oy - 144
    end

    local rewardNode=ui.node()
    display.adapt(rewardNode, 0, -oy)
    viewsNode:addChild(rewardNode)
    local sH=320*math.ceil(rewardInfosLength/4)+100
    oy=oy+sH+40
    if (data.icon==1 or data.icon==4) and rewardInfosLength>0 then --附件
        local ooy=60
        local temp=ui.label(StringManager.getString("labEnclosure"), General.font1, 50, {color={255,255,255}})
        display.adapt(temp, 40, -40, GConst.Anchor.LeftTop)
        rewardNode:addChild(temp,2)
        ooy=ooy+temp:getContentSize().height
        oy=oy+temp:getContentSize().height

        temp = ui.scale9("images/bgWhiteEdgeGray.9.png", 10, {1210,sH})
        display.adapt(temp, 0, -ooy, GConst.Anchor.LeftTop)
        rewardNode:addChild(temp)
        --显示奖励
        ooy=ooy+270
        local index=0
        for i=1,math.ceil(#rewardInfos/4) do
            local cell=ui.node()
            display.adapt(cell, 30, -ooy-320*(i-1))
            rewardNode:addChild(cell,2)
            for j=1,4 do
                index=index+1
                if index>#rewardInfos then
                    break
                end
                local info=rewardInfos[index]
                GameUI.addItemIcon(cell,info[1],info[2],1,150+282*(j-1),86,true,false,{itemNum=info[3]})
                local itemName = ui.label("", General.font1, 45,{fontW=260,fontH=80})
                display.adapt(itemName, 150+282*(j-1), -60, GConst.Anchor.Center)
                cell:addChild(itemName)
                itemName:setString(GameLogic.getItemName(info[1],info[2]))
            end
        end
    end
    if oy>1000 then
        scNode:setScrollContentRect(cc.rect(0,1000-oy,0,oy))
    end
    local  backpack=false--背包数量不足
    local heroNum=0
    local equipNum=0
    for i,reward in ipairs(rewardInfos) do
        if reward[1]==const.ItemHero then--英雄
            heroNum=heroNum+reward[3]
        elseif reward[1]==const.ItemEquip then--装备
            equipNum=equipNum+reward[3]
        end
    end
    if heroNum>(GameLogic.getUserContext().heroData:getHeroMax()-GameLogic.getUserContext().heroData:getHeroNum()) then
        backpack=true
    end
    if equipNum>(GameLogic.getUserContext().equipData:getEquipMax()-GameLogic.getUserContext().equipData:getEquipNum()) then
        backpack=true
    end
    local function callRevceive()
        if self.deleted then
            return
        end
        --防止连点
        if self.inReceive then
            return
        end
        if backpack then --背包数量不足
            display.pushNotice(StringManager.getString("labPromotePack"))
        else
            self.inReceive = true
            self:showReceive(data)

            self:sendReceived(data)
            if data.icon==4 then
                self:sendDeleteEmail()
            end
        end
    end
    local function closeDialog()
        if self.deleted then
            return
        end
        local showId=0
        if self.LogDialog.getEmailShowId then
            showId=self.LogDialog:getEmailShowId(data)
        end
        if data.icon==2 then
            data.icon=3
            if self.LogDialog.Inbox then
                self.LogDialog:getEmailDatas(data)
                self.LogDialog.inboxTableView:removeCell(showId)
                local tab={id=self.LogDialog.inboxTableView.dataLength,datas=data}
                self.LogDialog.inboxTableView:addCell(tab)
            end
        elseif data.icon==4 then--特殊邮件
            if rewardInfosLength==0 then
                self:sendDeleteEmail()
                data.icon=0--被移除
                if self.LogDialog.Inbox then
                    local datas=self.LogDialog:getEmailDatas(data)
                    self.LogDialog.inboxTableView:removeCell(showId)
                    if #datas==0 then
                        self.LogDialog:Inbox()
                    end
                end
            end
        end
        display.closeDialog(self.priority)
    end

    local function shareEmail()
        local KnockOutShareDialog = GMethod.loadScript("game.Dialog.KnockOutShareDialog")
        display.showDialog(KnockOutShareDialog.new({cont = data.cont}))
        viewTab.butShare:setHValue(114)
    end
    if data.icon==1 then
        self:loadView("butReceiveView")
        viewTab.butReceive:setScriptCallback(Script.createCallbackHandler(callRevceive))
    elseif data.icon==2 or data.icon==3 then
        self:loadView("butCloseView")
        viewTab.butClose2:setScriptCallback(Script.createCallbackHandler(closeDialog))
    elseif data.icon==4 then
        if rewardInfosLength>0 then
            if data.isKnockOutReward then
                self:loadView("butKnockOutRewardView")
                viewTab.butReceive:setScriptCallback(Script.createCallbackHandler(callRevceive))
                viewTab.butShare:setScriptCallback(Script.createCallbackHandler(shareEmail))
            else
                self:loadView("butReceiveView")
                viewTab.butReceive:setScriptCallback(Script.createCallbackHandler(callRevceive))
            end
        else
            self:loadView("butCloseView")
            viewTab.butClose2:setScriptCallback(Script.createCallbackHandler(closeDialog))
        end
    end
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(closeDialog))
end
function EmailDialog:showReceive(data)
    local showId=0
    if self.LogDialog.getEmailShowId then
        showId=self.LogDialog:getEmailShowId(data)
    end
    if data.icon==1 then
        data.icon=3
    elseif data.icon==4 then
        data.icon=0
    end
    if self.LogDialog.Inbox then
        local datas=self.LogDialog:getEmailDatas(data)
        self.LogDialog.inboxTableView:removeCell(showId)
        if data.icon==3 then
            local tab={id=self.LogDialog.inboxTableView.dataLength,datas=data}
            self.LogDialog.inboxTableView:addCell(tab)
        elseif data.icon==0 and #datas==0 then
            self.LogDialog:Inbox()
        end
    end
    display.closeDialog(self.priority)
end
function EmailDialog:sendReceived(da)
    GameLogic.dumpCmds(true)
    GameNetwork.request("sendReceive",{getemailreward={self.dataId}},function(isSuc,data)
        if isSuc then
            GameLogic.addRewards(data)
            GameLogic.statCrystalRewards("邮件奖励",data)
            GameLogic.showGet(data)
        end
    end)
end

function EmailDialog:sendDeleteEmail()
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdEmailDel,self.dataId})
end

return EmailDialog
