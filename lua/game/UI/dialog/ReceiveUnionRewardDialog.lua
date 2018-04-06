--领取工会奖励对话框
local ReceiveUnionRewardDialog = class2("ReceiveUnionRewardDialog",function()
    return BaseView.new("ReceiveUnionRewardDialog.json")
end)

function ReceiveUnionRewardDialog:ctor(params)
    self.params = params
    self.dialogDepth = display.getDialogPri() + 1
    self:getbloginfo()
    self:initBack()
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function ReceiveUnionRewardDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    if self.params.isReceive == 1 then
        viewTab.titleReceiveUnionReward:setString(Localize("btnDetails"))
    end
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
end

function ReceiveUnionRewardDialog:initUI()
    self:loadView("upViews")
    self:insertViewTo()

    self.butReceive:setListener(function()
        print("领取")
        self:getPvlReward()
    end)
    local my = self.myData
    if my then
        --积分奖励数量
        self.labelGetRewardMultiple:setString(SG("labelGetRewardMultiple")..my[5])
        --基础奖励数量
        self.labelBaseRewardNume:setString(SG("labelBaseRewardNume")..my[4])
        --总奖励数量
        self.labelReceiveRewardNume:setString(SG("labelReceiveRewardNume")..my[5]+my[4])
        --算法
        --领取
        if my[8] == 1 then
            self.butReceive:setGray(true)
            self.butReceive:setEnable(false)
            self.btnReceive:setString(SG("labelAlreadyReceive"))
            ui.setFrame(self.imgBox, "images/rewardBox3_2.png")
            self.imgBox:setScale(3)
        end
    else
        self.labelGetRewardMultiple:setVisible(false)
        self.labelGetRewardMultiple:setVisible(false)
        self.labelReceiveRewardNume:setVisible(false)
        self.labelCanReceiveNume:setVisible(false)
        self.butReceive:setVisible(false)
    end

    local infos={}
    for i=1,#self.players do
         infos[i]={id=i,item = self.players[i]}
    end
    table.sort(infos,function(a,b)
        return a.item[7]>b.item[7]
    end)
    self:addTableViewProperty("infoTableview",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("infoTableview")
end
function ReceiveUnionRewardDialog:callcell(cell, tableView, info)
    local item = info.item
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    self:loadView("infoViewsBack",bg)
    if item[2]==GameLogic.getUserContext().uid then
        self:loadView("infoViewsBackBlue",bg)
    end
    self:loadView("infoViews",bg)
    self:insertViewTo()
    --等级
    self.labelExpLv:setString(item[3])
    --名字
    self.labelCellName:setString(item[1])
    --积分
    self.labelAttackValue:setString(item[7])
    --可获得
    self.labelCanGet:setString(Localize("labelCanGet")..(item[4]+item[5]) .. "x")
end

function ReceiveUnionRewardDialog:addRewardViews(data,startIdx)
    local node=ui.touchNode({2048,1536},-1)
    node:setPosition(0,0)
    self:addChild(node,2)
    self:loadView("rewardNodeBackandButton",node)
    for i=1,3 do
        for j=1,5 do
            local idx = (i-1)*5+j+startIdx
            if idx>#data then
                break
            end

            self:loadView("rewardNode",node)
            self:insertViewTo()
            local rewardEnergyNode=self.rewardEnergyNode
            rewardEnergyNode:setPosition(238+(j-1)*328,1102-(i-1)*321)
            local temp
            local dt = data[idx]
            
            local num = dt[1] == 9 and 1 or dt[3]
            self.labelRewardValue:setString(num)

            GameUI.addItemIcon(rewardEnergyNode,dt[1],dt[2],137/200,116,116,false)

        end
    end
    local function closeRewardViews() 
        node:removeFromParent(true)
        if #data>15 then
            startIdx = startIdx+15
            self:addRewardViews(data,startIdx)
            self.btnSure:setString(Localize("stirngNextPade"))
        else
            self.btnSure:setString(Localize("btnYes"))
            display.closeDialog(0)
        end
    end
    self.butSure:setScriptCallback(Script.createCallbackHandler(closeRewardViews))
end

------------------------------------------------------------------------------------------------------------
function ReceiveUnionRewardDialog:getbloginfo()
    _G["GameNetwork"].request("getPvlBoxesDesc",{bid=self.params.bid,lid=GameLogic.getUserContext().union.id},function(isSuc,data)
        if isSuc then
            if data.code==0 then
                self.players = {}
                if data.agls then
                    for i,v in ipairs(data.agls) do
                        if v[2] == GameLogic.getUserContext().uid then
                            self.myData=v
                        end
                        table.insert(self.players,v)
                    end
                end
                if self.initUI then
                    self:initUI()
                end
            end
        end
    end)
end

function ReceiveUnionRewardDialog:getPvlReward()
    if not GameLogic.getUserContext().union then
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getPvlReward",{lid=GameLogic.getUserContext().union.id,bid=self.params.bid},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==0 then
                if data.agls and #data.agls>0 then
                    GameLogic.showGet(data.agls,nil,true,true)
                    GameLogic.addRewards(data.agls)
                    GameLogic.statCrystalRewards("联盟战宝箱奖励",data.agls)
                    if self.butReceive then
                        self.butReceive:setGray(true)
                        self.butReceive:setEnable(false)
                        self.btnReceive:setString(SG("labelAlreadyReceive"))
                        ui.setFrame(self.imgBox, "images/rewardBox3_2.png")
                        self.imgBox:setScale(3)
                        if self.params.callback then
                            self.params.callback()
                        end
                    end
                end
            end
        end
    end)
end

return ReceiveUnionRewardDialog




