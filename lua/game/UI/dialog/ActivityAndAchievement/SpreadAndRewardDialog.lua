
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
--推广码和奖励对话框
local SpreadAndRewardDialog = class2("SpreadAndRewardDialog",function()
    return BaseView.new("SpreadAndRewardDialog.json")
end)

function SpreadAndRewardDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
    self:getfinfo()
end

function SpreadAndRewardDialog:initUI()
    self.actData = GameLogic.getUserContext().activeData.dhActive[57] or {0,57,0,0,GameLogic.getTime()}
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))

    self:addTabView({Localize("labelNewWelfare"),Localize("labelReward2"),Localize("labelEdefenceCode")}, {543,149,480,1370,156,"images/dialogTabBack3_",55,271,69,1540,57,43,1324})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.inviteCode,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.rewardViews,self)})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.spreadViews,self)})
    self:changeTabIdx(1)
end

function SpreadAndRewardDialog:spreadViews(tab)
    local bg, temp
    bg = ui.node({0,0},true)
    self:loadView("Spread_upViews",bg)
    self:loadView("Spread_centerViews",bg)
    self:insertViewTo()
    self.labelYourCodeValue:setString(GameLogic.getTCodeString())
    self.lab_desc:setString(Localize("facebookDesc"))
    --暂且关闭
    --self.butShare:setVisible(false)
    -- if General.language ~= "CN" then
    --     ui.setFrame(self.btnShareBack,"images/iconFacebook1.png")
    --     self.btnShareBack:setScale(2)
    -- end
    -- ui.setFrame(self.btnShareBack,"images/iconFacebook1.png")
    --self.btnShareBack:setScale(2)
    if General.language == "CN" and Plugins.wechat and Plugins.wechat:checkPluginFunc(1) then
        self.butShare:setBackgroundImage(nil, 0)
        temp = ui.scale9("images/btnBigGreen.9.png", 40, {300, 125})
        temp:setScale(2)
        display.adapt(temp, 300, 125, GConst.Anchor.Center)
        self.butShare:getDrawNode():addChild(temp, -1)
        temp = ui.sprite("images/btnShareWechat.png", {150, 150})
        display.adapt(temp, 110, 135, GConst.Anchor.Center)
        self.butShare:getDrawNode():addChild(temp)
        self.lab_desc:setVisible(false)
    end
    self.butShare:setListener(function()
        GameLogic.doShare("code")
    end)
    self.butCopy:setListener(function()
        if Native.pasteBoardString then
            Native:pasteBoardString(GameLogic.getTCodeString())
            display.pushNotice(Localize("noticeSpreadCodeCopy"))
        end
    end)
    if not Native.pasteBoardString then
        self.butCopy:setVisible(false)
    end

    local infos = {{"images/otherIcon/iconActivity106_1.png","stringSpreadDes"},{"images/otherIcon/iconActivity109.png","stringSpread3"}}
    self:addTableViewProperty("Spread_downNewTableView",infos,Script.createBasicHandler(self.updateInfoCell,self))
    self:loadView("Spread_downNewTableView",bg)
    return bg
end

function SpreadAndRewardDialog:updateInfoCell(cell,tableView,info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    self:loadView("Spread_downNewViews",bg)
    self:insertViewTo()
    self.spreadDownIcon:setTexture(info[1])
    self.spreadDownInfo:setString(Localize(info[2]))
end

function SpreadAndRewardDialog:reloadBottom()
    local _lv = GameLogic.getUserContext():getInfoItem(const.InfoTownLv)
    if (GameLogic.tcodeUsed == 1) or (_lv > 6) or (GameLogic.tcodeUsed ~= 1 and _lv > 6) then
        if self.butReceive then
            self.butReceive:setVisible(false)
        end
        self.textBox:setVisible(false)
        --self.insertImg:setVisible(false)
        --self.stringSpread5:setString(Localize("labelHaveInsertCode"))
        --self.stringSpread5:setPosition(300,350)
        -- self.rewardNode:setVisible(false)
        self.rewardTip:setVisible(true)
        self.rewardTip:setString(Localize("labelHaveInsertCode"))
        if (_lv > 6) or (GameLogic.tcodeUsed ~= 1 and _lv > 6) then
            self.rewardTip:setString(Localize("labelInviteLimit1"))
        end
    end
end

function SpreadAndRewardDialog:rewardViews(tab)
    local bg, temp
    bg = ui.node({0,0},true)
    self:loadView("rewUpInfoView",bg)
    self:insertViewTo()
    self.rewLabelInfo:setString(Localize("labelRewUpInfo"))
    self.labelRew:setString(Localize("labelRewDiamond"))
    self.butRew:setScriptCallback(Script.createCallbackHandler(function ()
        -- body
        display.showDialog(GemPoolDialog.new())
    end))
    local infos = GameLogic.getSpreadAndRewardData()
    self:addTableViewProperty("infoTableView",infos,Script.createBasicHandler(self.rewardCallCell,self))
    self:loadView("infoTableView",bg)
    return bg
end


function SpreadAndRewardDialog:rewardCallCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    info.bg = bg
    local awd = info.awd
    cell:setEnable(false)
    self:loadView("cellNodeViews",bg)
    self:insertViewTo()
    local need = info.townLv
    self.canGetReward:setString(Localizef("stringCanGetRewardWithTownLv",{a = need}))

    for i, v in ipairs(awd.rwds) do
        local itemNode=ui.node()
        display.adapt(itemNode,46+(i-1)*275,41,GConst.Anchor.LeftBottom,{scale=0.85})
        bg:addChild(itemNode)
        GameUI.addItemIcon(itemNode,v[1],v[2],1,100,100,true)
        self:loadView("itemNodeViews",itemNode)
        self:insertViewTo()
        self.rnum:setString(v[3])
    end
    local num = awd.maxNum - info.getedPackNum
    self.labelPackNum:setString(Localizef("labelPackNum",{num=num}))
    if num<=0 then
       GameUI.addHaveGet(bg,Localize("labelAlreadyReceive"),1,1606,180,1)
       self.labelPackNum:setVisible(false)
       self.butPack:setVisible(false)
    elseif info.getedPackNum>=(info.havePack or awd.maxNum) then
        self.butPack:setSValue(-100)
        self.butPack:setEnable(false)
    end
    self.butPack:setListener(function ()
        self:getfreward(0,info)
        GameEvent.sendEvent("spreadAndRewardRedNum")
    end)
    self.butPack:setTouchThrowProperty(true, true)
    info.labelPackNum =self.labelPackNum
    info.butPack = self.butPack
end

function SpreadAndRewardDialog:refreahCell(info)
    local awd = info.awd
    local bg = info.bg
    local num = awd.maxNum - info.getedPackNum
    info.labelPackNum:setString(Localizef("labelPackNum",{num=num}))
    if num<=0 then
       GameUI.addHaveGet(bg,Localize("labelAlreadyReceive"),1,1606,180,1)
       info.labelPackNum:setVisible(false)
       info.butPack:setVisible(false)
    elseif info.getedPackNum>=(info.havePack or awd.maxNum) then
        info.butPack:setSValue(-100)
        info.butPack:setEnable(false)
    end
    info.butPack:setListener(function ()
        self:getfreward(0,info)
    end)
end

function SpreadAndRewardDialog:getfreward(mtype,info)
    if not GameNetwork.lockRequest() then
        return
    end
    local context =GameLogic.getUserContext()
    local item
    local uid
    local townLv = nil
    if mtype == 0 then
        townLv = info.townLv
        uid = context.uid
    elseif mtype == 1 then
        item = info.item
        uid = item[1]
    end
    GameNetwork.request("getCodeRewards",{mtype=mtype,ucodeid=uid,tid=context.uid,sid=context.sid,lv=townLv},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code ==0 then
                local rwds =data.rwds
                GameLogic.addRewards(rwds)
                GameLogic.statCrystalRewards("推广码奖励",rwds)
                GameLogic.showGet(rwds)
                if mtype==0 then
                    GameLogic.getUserContext():changeProperty(info.constIdx,1)
                    info.getedPackNum =info.getedPackNum +1
                    if self.refreahCell then
                        self:refreahCell(info)
                    end
                end
            end
        end
    end)
end

function SpreadAndRewardDialog:inviteCode()
    -- body
    local bg = ui.node({0,0})
    self:loadView("inviteCode",bg)
    --self:loadView("Spread_downViews",bg)
    self:insertViewTo()
    self.inviteLimit:setString(Localize("labelInviteLimit"))
    self.inviteTitle:setString(Localize("labelInviteTitle"))
    self.inviteInfo:setString(Localize("labelInviteInfo"))
    GameUI.addHeroFeature(self.imgFerture,4009,1.5,400,200,1)
    local spreadRewards = SData.getData("spreadCodeRewards")[0].rwds
    for i,v in ipairs(spreadRewards) do
        local itemNode=ui.node()
        display.adapt(itemNode,((i-1)%3)*200,math.floor((i-1)/3)*(-200),GConst.Anchor.LeftBottom)
        self.rewardNode:addChild(itemNode)
        self.rewardTip:setVisible(false)
        GameUI.addItemIcon(itemNode,v[1],v[2],0.7,200,250,true,false,{itemNum=v[3]})
    end
    local textBox = ui.textBox({880,150}, Localize("labelInputPlaceHolder"), General.font6, 55, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
    display.adapt(textBox, 700.5,190.0, GConst.Anchor.LeftBottom)
    bg:addChild(textBox)
    self.textBox = textBox
    self.butReceive:setListener(function()
        self:insertfcode(textBox:getText())
    end)
    self:reload()
    return bg
end

function SpreadAndRewardDialog:reload()
    self:insertViewTo()
    self:reloadBottom()
end

function SpreadAndRewardDialog:getfinfo()
    _G["GameNetwork"].request("sCodeList",nil,function(isSuc, data)
        if isSuc then
            GameLogic.tlist=data.tlist
        end
    end)
end
------------------------------------------------------------------------------------

function SpreadAndRewardDialog:insertfcode(code)
    if GameLogic.tcodeUsed == 1 then
        display.pushNotice(Localize("stringHaveInsertCode"))
        return
    end
    if #code<9 then
        display.pushNotice(Localize("noticeSpreadCode"))
        return
    end
    code = tonumber(code)
    if GameLogic.tcode == code then
        display.pushNotice(Localize("labelCantInsertYourself"))
        return
    end
    _G["GameNetwork"].request("sendCode",{code =code,blv=GameLogic.getUserContext().buildData:getMaxLevel(const.Town)},function(isSuc, data)
        if isSuc then
            if data.code==0 then
                GameLogic.tcodeUsed = 1
                GameLogic.addRewards(data.rwds)
                GameLogic.statCrystalRewards("邀请码奖励",data.rwds)
                GameLogic.showGet(data.rwds)
                if self.initUI then
                    self:reloadBottom()
                end
            elseif data.code==1 then
                display.pushNotice(Localize("labelNotInviteCode"))
            elseif data.code==2 then
                display.pushNotice(Localize("stringHaveInsertCode"))
            end
        end
    end)
end
return SpreadAndRewardDialog














