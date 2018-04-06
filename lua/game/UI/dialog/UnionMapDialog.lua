local const = GMethod.loadScript("game.GameLogic.Const")
--联盟副本对话框
local UnionMapDialog = class2("UnionMapDialog",function()
    return BaseView.new("UnionMapDialog.json")
end)

function UnionMapDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self:initBack()
    self:getpvldata()
    
    self.priority=self.dialogDepth
    display.showDialog(self)
    RegActionUpdate(self, Handler(self.updateMy, self, 0.25), 0.25)
end

function UnionMapDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))
end
function UnionMapDialog:onQuestion()
    HelpDialog.new("dataQuestionUnMap")
end

function UnionMapDialog:initUI()
    if self.reloadNode then
        self.reloadNode:removeFromParent(true)
        self.reloadNode = nil
    end
    self.reloadNode = ui.node()
    self:addChild(self.reloadNode)

    self:loadView("allViews",self.reloadNode)
    self:insertViewTo()
    self.butUnionProgressRank:setListener(function()
        AllRankingListDialog.new(4)
    end)
    --剩余次数
    local remainNum = 2-self.params.attackNum+self.params.pvl_buy
    if remainNum<0 then
        remainNum = 0
    end
    self.remainTimes:setString(remainNum.."/2")
    if remainNum>0 then
        ui.setColor(self.remainTimes,"white")
    else
        ui.setColor(self.remainTimes,"red")
    end
    if remainNum<=0 and self.params.pvl_buy<3 then
        self.butBuy:setVisible(true)
        self.butBuy:setListener(function()
            local otherSetting = {ctype = const.ResCrystal,cvalue = 200*self.params.pvl_buy+100, callback = function()
                self:buypvltimes(200*self.params.pvl_buy+100)
            end}
            local dl = AlertDialog.new(1,Localize("alertTitleNormal"),Localize("stirngNormalAlert"),otherSetting)
            display.showDialog(dl)
        end)
    end

    if not self.params.pvl_cyc then
        self.butUpdate:setVisible(true)
        self.labelResetTime:setVisible(false)
        self.labelResetTimeNume:setVisible(false)
        self.butUpdate:setListener(function()
            self:resetpvldate()
        end)
    else
        self.labelResetTime:setVisible(true)
        self.labelResetTimeNume:setVisible(true)
    end 

    --副本重置时间
    local value = self.params.endtime-GameLogic.getTime()
    local str = GameLogic.getTimeFormat(value)
    if value<=0 then
        str = "labelPvbIsRefresh"
    end
    self.labelResetTimeNume:setString(Localize(str))
    self.butFriendHelp:setListener(function()
        UnionFriendAssistant.new()
    end)
    self:initMapView()
end

function UnionMapDialog:initMapView()
    local union = self.params  --数据

    local bg=self.reloadNode
    local temp
    temp = ui.sprite("images/mapZheZhao.png",{1873, 890})
    display.adapt(temp, 31, 233-68, GConst.Anchor.LeftBottom)
    bg:addChild(temp,2)
    local map = ScrollNode:create(cc.size(1873-60*2,825), 1, true, false)
    map:setScrollEnable(true)
    map:setInertia(true)
    map:setClip(true)
    map:setScaleEnable(true,1,1,1,1)

    map:setScrollContentRect(cc.rect(0,0,6820,825))
    display.adapt(map,31+60,274-68, GConst.Anchor.LeftBottom)
    bg:addChild(map)
    local bg=map:getScrollNode()
    --6820,825
    for i=1,3 do
        temp = ui.sprite("images/dialogBattleMap"..i..".png",{6820/3, 825})
        display.adapt(temp,6820/3*(i-1),0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
    end
    local Dianpoint=GMethod.loadConfig("configs/ui/dialogViewsConfig/UnionMapDot.json")
    for i,tab in ipairs(Dianpoint) do
        temp = ui.sprite("images/pvePoint.png",{34,34})
        display.adapt(temp,tab[1]+50,tab[2], GConst.Anchor.Center)
        bg:addChild(temp)
    end
    local Guankapoint=GMethod.loadConfig("configs/ui/dialogViewsConfig/UnionMapGuanKa.json")
    --把当前关卡移动到中间
    local tabX = Guankapoint[union.index] and Guankapoint[union.index][1] or Guankapoint[#Guankapoint][1]
    map:moveAndScaleToCenter(1, tabX,50, 0.01)
    self.rewardPoint = {}
    for i,tab in ipairs(Guankapoint) do
        temp=ui.button({154, 154},nil,{image=nil})
        display.adapt(temp, tab[1]+50,tab[2], GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/checkpoint.mp3")
        local button=temp
        local but=temp:getDrawNode()
        temp = ui.sprite("images/guankaBack.png",{154, 154})
        display.adapt(temp,0,0, GConst.Anchor.LeftBottom)
        but:addChild(temp)
        temp = ui.sprite("images/unionCity" ..tab[3]..".png")
        display.adapt(temp,154/2,154/2, GConst.Anchor.Center)
        but:addChild(temp,2)

        
        local canReward = false
        local tubiao=temp
        if i == union.index then    --点亮状态
            temp = ui.sprite("images/guankaDianLiang.png",{440, 450})
            display.adapt(temp,154/2-10,154/2+10, GConst.Anchor.Center)
            but:addChild(temp,-1)
            temp:setHValue(-125)
            temp:setSValue(29)
            temp:setLValue(27)
        elseif i>union.index then         --不可点状态
            button:setEnable(false)
            tubiao:setSValue(-100)
        end
        if i<union.index then
            temp = ui.label(StringManager.getString("labelStageOver"), General.font1, 50, {color={30,255,0}})
            display.adapt(temp,77,70, GConst.Anchor.Center)
            but:addChild(temp,10)
            temp:setRotation(-15)
            --可以领奖
            temp = ui.sprite("images/redgantang.png",{64, 62})
            display.adapt(temp,108,104, GConst.Anchor.LeftBottom)
            but:addChild(temp,2)
            --temp:setVisible(false)
            self.rewardPoint[i] = temp

            if union.rewards[i] then
                if union.rewards[i][1]>0 or union.rewards[i][2]>0 or union.rewards[i][3]>0 then
                    temp:setVisible(true)
                    canReward = true
                end
            end
        end

        button:setListener(function()
            UnionBattleDialog.new(i,self.params,canReward)
        end)
        button:setTouchThrowProperty(true,true)
    end
    for i,tab in ipairs(Guankapoint) do
        temp = ui.label(StringManager.getString("dataPvlPassName" .. i), General.font1, 47, {color={255,255,255}})
        display.adapt(temp, tab[1]+48, tab[2]-116, GConst.Anchor.Center)
        bg:addChild(temp,2)
    end
end

function UnionMapDialog:updateMy(diff)
    if self.labelResetTimeNume then
        local value = self.params.endtime-GameLogic.getTime()
        local str = GameLogic.getTimeFormat(value)
        if value<=0 then
            str = "labelPvbIsRefresh"
        end
        self.labelResetTimeNume:setString(Localize(str))
    end
    if self.rewardPoint then
        for i,v in ipairs(self.rewardPoint) do
            local union = self.params
            if union.rewards[i] then
                if union.rewards[i][1]>0 or union.rewards[i][2]>0 or union.rewards[i][3]>0 then
                    v:setVisible(true)
                else
                    v:setVisible(false)
                end
            else
                v:setVisible(false)
            end
        end
    end
end

function UnionMapDialog:getpvldata()
    -- self.params = dataCache:get("unionData")
    -- if self.params then
    --     self:initUI()
    --     return
    -- end
    local params = {}
    _G["GameNetwork"].request("getpvldata",nil,function(isSuc,data)
        if isSuc then
            --print_r(data)
            params = {
                attackNum = data.pvl_rts,
                index = data.pvl_data[1],
                bosslist = data.pvl_data[2],
                pvl_cyc = data.pvl_cyc,
                pvl_buy = data.pvl_buy,
                endtime = data.endtime
            }
            local bosslist = data.pvl_data[2]
            if bosslist:find("/") then
                bosslist = string.split(bosslist,",")
                for i,v in ipairs(bosslist) do
                    bosslist[i] = string.split(v,"/")
                end
                params.bosslist = bosslist
            else
                params.bosslist = {}
                if bosslist~="" then
                    for i,v in pairs (json.decode(bosslist)) do
                        params.bosslist[v[1]] = {v[2],v[3]}
                    end
                end
            end
            GameLogic.getUserContext().bosslist=params.bosslist
            local rewards = {}
            for i,v in ipairs(data.awards) do
                table.insert(rewards,v[tostring(i)])
            end
            params.rewards = rewards
            self.params = params            
            --dataCache:add("unionData",self.params,1800)
            if self.initUI then
                self:initUI()
            end
        end
    end)
end

function UnionMapDialog:buypvltimes(cost)
    local context =GameLogic.getUserContext()
    context:addCmd({const.CmdPvbBTimes})
    self.params.pvl_buy = self.params.pvl_buy+1
    GameLogic.getUserContext():changeRes(const.ResCrystal,-cost)
    GameLogic.statCrystalCost("联盟副本购买次数消耗",const.ResCrystal,-cost)
    local remainNum = 2-self.params.attackNum+self.params.pvl_buy
    if remainNum<0 then
        remainNum = 0
    end
    if self.remainTimes then
        self.remainTimes:setString(remainNum.."/2")
        self.butBuy:setVisible(false)
        if remainNum>0 then
            ui.setColor(self.remainTimes,"white")
        else
            ui.setColor(self.remainTimes,"red")
        end
    end
end

function UnionMapDialog:resetpvldate()
    _G["GameNetwork"].request("resetpvldate",nil,function(isSuc,data)
        if isSuc then
            if self.getpvldata then
                self:getpvldata()
            end
        end
    end)
end

return UnionMapDialog












