local const = GMethod.loadScript("game.GameLogic.Const")
--推广码领取宝石对话框
local SpreadReceiveGemstoneDialog = class2("SpreadReceiveGemstoneDialog",function()
    return BaseView.new("SpreadReceiveGemstoneDialog.json")
end)
function SpreadReceiveGemstoneDialog:ctor(params,callback)
    self.plays = params.users
    self.params = params
    self.callback = callback
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end

function SpreadReceiveGemstoneDialog:onQuestion()
    HelpDialog.new("dataQuestionTGM")
end

function SpreadReceiveGemstoneDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self:loadView("leftTopViews")
    self:loadView("rightTopViews")
    self:loadView("downViews")

    local infos={}
    local plays = self.plays
    for i=1,#plays do
        infos[i] = {id = i,item = plays[i]}
    end
    self:addTableViewProperty("rewardsTableView",infos,Script.createBasicHandler(self.callcell,self))
    self:loadView("rewardsTableView")

    self:insertViewTo()
    self.canGetCrystal:setString(self.params.getcrystal)
    self.butSeeReward:setListener(function()
        self:getfreward(infos,true)
    end)
    if self.params.getcrystal<=0 then
        self.butSeeReward:setGray(true)
    end
end
function SpreadReceiveGemstoneDialog:callcell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    local item = info.item
    self:loadView("rewardsCellViews",bg)
    GameUI.addPlayHead(bg,{id=item[5],scale=1,x=136,y=104,z=1,scale=0.875,blackBack = true})
    GameUI.addResourceIcon(bg, 4, 0.85, 489+44, 31+40)
    GameUI.addResourceIcon(bg, 4, 0.85, 1397+44, 161+40)
    self:insertViewTo()
    self.labelName:setString(item[2] .. " Lv" .. item[4])
    self.labelServer:setString(Localizef("labelServerArea",{n=item[6]}))
    self.labelHistoryTopupValue:setString(item[3])
    self.labelNowCanReceiveValue:setString(item[1])
    info.label = self.labelNowCanReceiveValue
    self.butRevice:setListener(function()
        if item[1]<=0 then
            display.pushNotice(Localize("stringNoCrystalCanRwd"))
        else
            self:getfreward(info)
        end
    end)
    if item[1]<=0 then
        self.butRevice:setGray(true)
    end
    info.but = self.butRevice
end
----------------------------------------------------
function SpreadReceiveGemstoneDialog:getfreward(info,isAll)
    if isAll then
        self:getfrewardAll(info)
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    local item = info.item
    local params = self.params
    local callback = self.callback
    GameNetwork.request("getfreward",{fid = item[7]},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            local rwd = {{10,const.ResCrystal,data.getcry}}
            GameLogic.addRewards(rwd)
            GameLogic.statCrystalRewards("推广码奖励",rwd)
            GameLogic.showGet(rwd)
            item[1] = 0
            params.getcrystal = params.getcrystal - data.getcry
            callback()
            if self.initUI then
                info.label:setString(0)
                self.canGetCrystal:setString(params.getcrystal)
                info.but:setGray(true)
                if params.getcrystal<= 0 then
                    self.butSeeReward:setGray(true)
                end 
            end
        end
    end)
end
function SpreadReceiveGemstoneDialog:getfrewardAll(infos)
    local params = self.params
    if params.getcrystal<=0 then
        display.pushNotice(Localize("stringNoCrystalCanRwd"))
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    local infos = infos
    local callback = self.callback
    GameNetwork.request("getfreward",{fid = 0},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            local rwd = {{10,const.ResCrystal,data.getcry}}
            GameLogic.addRewards(rwd)
            GameLogic.showGet(rwd)
            for i,v in ipairs(infos) do
                v.item[1] = 0
            end
            params.getcrystal = 0
            callback()
            if self.initUI then
                for i,info in ipairs(infos) do
                    if info.label then
                        info.label:setString(0)
                        info.but:setGray(true)
                    end
                end
                self.canGetCrystal:setString(params.getcrystal)
                self.butSeeReward:setGray(true)
            end
        end
    end)
end
return SpreadReceiveGemstoneDialog












