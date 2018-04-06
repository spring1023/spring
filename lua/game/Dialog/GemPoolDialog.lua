-- 宝石池
GemPoolDialog = class(DialogViewLayout)

function GemPoolDialog:onInitDialog()
    self:setLayout("GemPoolDialog.json")
    self:loadViewsTo()
    self.title:setString(Localize("labelCrystal"))
    self.context = GameLogic.getUserContext()
    self.getcrystal = 0
    self:getfinfo()
    self:initUI()
end

function GemPoolDialog:getfinfo()
    _G["GameNetwork"].request("sCodeList",nil,function(isSuc, data)
        if isSuc then
            GameLogic.tlist=data.tlist
        end
    end)
    --self:reload()
end

function GemPoolDialog:initUI()
    self.labelOneButReceive:setString(Localize("labelOneButReceive"))
    self.stringHaveAllCrystal:setString(Localize("stringHaveAllCrystal"))
    self.stringSpreadDes:setString(Localize("stringSpreadDes"))

    self.rewardsTableView:removeAllChildren(true)
    local infos={}
    -- local plays = GameLogic.tlist
    -- self.getcrystal = 0
    -- for i=1,#plays do
    --     infos[i] = {id = i,item = plays[i]}
    --     self.getcrystal = self.getcrystal + math.floor(infos[i].item[6]*0.2)
    -- end
    infos,self.getcrystal = self:getCrystalData()
    self.canGetCrystal2:setString(self.getcrystal)
    self.butSeeReward:setScriptCallback(ButtonHandler(function()
        self:getfreward(1,infos,true)
    end))
    if self.getcrystal<=0 then
        self.butSeeReward:setGray(true)
        --self.butSeeReward:setEnable(false)
    end
    self.tableView = GameUI.helpLoadTableView(self.rewardsTableView,infos,Handler(self.updateCell,self))
end

function GemPoolDialog:getCrystalData()
    local infos={}
    local plays = GameLogic.tlist
    local crystal = 0
    for i=1,#plays do
        infos[i] = {id = i,item = plays[i]}
        crystal = crystal + math.floor(infos[i].item[6]*0.2)
    end
    return infos,crystal
end

function GemPoolDialog:updateCell(cell,tableView,info)
    -- body
    if not info.tableView then
        local bg = cell:getDrawNode()
        info.viewLayout = self:addLayout("crystal_rewardsTableView",bg)
        info.viewLayout:loadViewsTo(info)
        local item = info.item
        GameUI.addPlayHead(bg,{id=item[5],scale=1,x=136,y=104,z=1,scale=0.875,blackBack = true})
        GameUI.addResourceIcon(bg, 4, 0.85, 489+44, 31+40)
        GameUI.addResourceIcon(bg, 4, 0.85, 1397+44, 161+40)
        info.labelName:setString(item[4])
        info.labelServer:setString(Localizef("labelServerArea",{n=item[7]}).."  "..Localizef("labelTownLv",{a=item[3]}))
        info.labelHistoryTopupValue:setString(item[8])
        info.labelNowCanReceiveValue:setString(math.floor(item[6]*0.2))
        self.label = info.labelNowCanReceiveValue
        info.butRevice:setScriptCallback(function()
            if item[6]<=0 then
                display.pushNotice(Localize("stringNoCrystalCanRwd"))
            else
                self:getfreward(1,info)
                GameEvent.sendEvent("spreadAndRewardRedNum")
            end
        end)
        info.btnReceive:setString(Localize("btnReceive"))
        if item[6]<=0 then
            info.butRevice:setGray(true)
        end
    end
end

function GemPoolDialog:getfreward(mtype,info,isAll)
    if isAll then
        self:getfrewardAll(info)
        return
    end
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
                if mtype==1 then
                    self.getcrystal = self.getcrystal - rwds[1][3]
                    GameLogic.CacheGemPoolData(self.getcrystal)
                    item[6] = 0
                    if self.initUI then
                        self.label:setString(0)
                        self.canGetCrystal2:setString(self.getcrystal)
                        info.butRevice:setGray(true)
                        if self.getcrystal<= 0 then
                            self.butSeeReward:setGray(true)
                        end
                    end
                end
            end
        end
    end)
end

function GemPoolDialog:getfrewardAll(infos)
    if self.getcrystal<=0 then
        display.pushNotice(Localize("stringNoCrystalCanRwd"))
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    local infos = infos
    local context =GameLogic.getUserContext()
    GameNetwork.request("getCodeRewards",{mtype=1,ucodeid=0,tid=context.uid,sid=context.sid},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code ==0 then
                local rwds =data.rwds
                GameLogic.addRewards(rwds)
                GameLogic.statCrystalRewards("推广码奖励",rwds)
                GameLogic.showGet(rwds)
                for i,v in ipairs(infos) do
                    v.item[6] = 0
                end
                self.getcrystal = 0
                GameLogic.CacheGemPoolData(self.getcrystal)
                if self.initUI then
                    for i,info in ipairs(infos) do
                        if self.label and info.butRevice then
                            self.label:setString(0)
                            info.butRevice:setGray(true)
                        end
                    end
                    self.canGetCrystal2:setString(self.getcrystal)
                    self.butSeeReward:setGray(true)
                end
            end
        end
    end)
end
