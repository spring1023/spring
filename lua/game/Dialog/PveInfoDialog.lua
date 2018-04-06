local SData = GMethod.loadScript("data.StaticData")

PveInfoDialog = class(DialogViewLayout)

function PveInfoDialog:onEnter( ... )
    local chapterId = math.ceil(self.idx/6)
    self.checkTitle:setString(Localize("dataPvePassName"..self.idx))
    local stars = {}
    stars[1] = self.star1
    stars[2] = self.star2
    stars[3] = self.star3
    stars[4] = self.star4
    stars[5] = self.star5
    stars[6] = self.star6
    for i=4,6 do
        stars[i]:setVisible(false)
    end
    self.stars = stars
    self.btnSweep:setVisible(false)
    self.btnSweepTen:setVisible(false)
    -- self.labConts:setVisible(false)
    self.labUnlock:setVisible(false)
    self.labUnlock:setString(Localize("labUnlock"))
    self.firstThreeStar:setVisible(false)
    self.labConts:setVisible(false)
    self.freePvetimes:setVisible(false)
    self.firstThreeStar:setString(Localize("firstThreeStar"))
    self.pverewards = SData.getData("pverewards",self.idx)
    self.btnAttack:setScriptCallback(ButtonHandler(self.onPveBattle, self))
    self.btnSweep:setScriptCallback(ButtonHandler(self.sweepPveBattle, self,1))
    self.btnSweepTen:setScriptCallback(ButtonHandler(self.sweepPveBattle, self,10))
    self.questionBut:setScriptCallback(ButtonHandler(self.onQuestion,self))
    self.selectedPveStage = self.idx
end

function PveInfoDialog:onInitDialog()
    self:setLayout("PveInfoDialog.json")
    self:loadViewsTo()
    local function closeDialog()
       display.closeDialog(0)
    end
    self.dialogDepth=display.getDialogPri()+1
    display.showDialog(self)
    self.sweepTimes = GameLogic.getUserContext().pve:getFreeSweepTimes()
    self:initViews()
    self:hahah()
end

function PveInfoDialog:initViews( ... )
     local context = GameLogic.getUserContext()
     local sweepTimes = self.sweepTimes
     self.sweepTimes = sweepTimes
     local chance = context.pve:getBattleChance()
    local maxChance = context.pve:getMaxChance()
    local buffInfo = self.context.activeData:getBuffInfo(const.ActTypeBuffPVE)
    self.pveTimes:setString(Localizef("labPveTimes",{a=chance+buffInfo[4]-buffInfo[5],b=maxChance+buffInfo[4]}))
     if sweepTimes>0 then
         self.bntSweep:setString(Localize("freeSweep"))
         local num = 10 -- 免费扫荡次数最大就是10次
         if sweepTimes<num then num=sweepTimes end
         if chance<num then num=chance end
         self.btnSweepNum:setString(Localizef("btnFreeSweepNum",{num=num}))
         self.labConts:setString(Localize("freeSweepTimes"))
         self.freePvetimes:setString(Localizef("freePvetimes",{num=sweepTimes}))
         self.btnSweepTen:setScriptCallback(ButtonHandler(self.sweepPveBattle, self,10))
     else
         local num = 10
         if chance<num then num=chance end
         self.bntSweep:setString(Localize("sweepWithRes"))
         self.btnSweepNum:setString(Localizef("btnSweepNum",{num=num}))
         self.labConts:setString(Localize("freeSweepTimes"))
         self.freePvetimes:setString(Localizef("freePvetimes",{num=0}))
         self.btnSweepTen:setScriptCallback(ButtonHandler(function()
             if num == 0 then
                 self:sweepPveBattle(10)
             else
                display.showDialog(AlertDialog.new(1, Localize("sweepWithRes"), Localizef("costsOfSweep",{num=num,cost=num*const.PricePveSweep}), {ctype=const.ResCrystal, cvalue=const.PricePveSweep*num, callback=Handler(self.sweepPveBattle, self,10)}))
            end
        end))
        self.btnSweep:setScriptCallback(ButtonHandler(function()
            display.showDialog(AlertDialog.new(1, Localize("sweepWithRes"), Localizef("costsOfSweep",{num=1,cost=const.PricePveSweep}), {ctype=const.ResCrystal, cvalue=const.PricePveSweep, callback=Handler(self.sweepPveBattle, self,1)}))
        end))
     end
    local states = self.states
    if states.attacked then
        for i=1,3 do
            self.stars[i]:setVisible(true)
        end
    end
    for i=1,states.star do
        self.stars[i+3]:setVisible(true)
    end
    if not states.canAttack then
        self.clock = true
        self.btnAttackbg.view:setSValue(-100)
        self.btnAttack:setScriptCallback(ButtonHandler(function ()
            display.pushNotice(Localize("pleasePassPerCustoms"))
        end))
    end
    if states.star >= 3 then
        self.btnSweep:setVisible(true)
        self.btnSweepTen:setVisible(true)
        self.labConts:setVisible(true)
        self.freePvetimes:setVisible(true)
        self.threeStar = true
    else
        self.labUnlock:setVisible(true)
    end
    if self.idx<=6 and self.idx==context.pve:getMyMaxStage() then
        --if context.guide:getStep().type == "pve" then
            local arrow = GameLogic.getUserContext().guideHand:showArrow(self.btnAttackbg.view, 165, 0, 50)
            arrow:setScaleY(-1)
        --end
    end
end

function PveInfoDialog:onQuestion()
    HelpDialog.new("PveInfoQuestion")
end

function PveInfoDialog:hahah( ... )
    local pverewards = self.pverewards
    local bossInfos = {}
    local rewInfos = {}
    local firstInfo = {}
    for i=1,#pverewards.boss do
        bossInfos[i] = {id=i,boss=pverewards.boss[i]}
    end
    for i=1,KTLen(pverewards.certainRwds)+2 do
        if i == 1 then
            rewInfos[i] = {id=i,boxLv = pverewards.box}
        elseif i == 2 and KTLen(pverewards.certainRwds) > 0 then
            rewInfos[i] = {id=i,addrews = "+"}
        else
            rewInfos[i] = {id=i,certainRwds = pverewards.certainRwds[i-2]}
        end
    end
    for i=1,#pverewards.firstRwds do
        firstInfo[i] = {id=i,firstRwds = pverewards.firstRwds[i]}
    end
    self.pveIconTableView:loadTableView(bossInfos, Handler(self.onUpdateCell, self))
    self.pveRewTableView:loadTableView(rewInfos, Handler(self.onUpdateCell, self))
    if not self.threeStar then
        self.firstThreeStar:setVisible(true)
        self.firstRewTableView:loadTableView(firstInfo, Handler(self.onUpdateCell, self))
    end
end

function PveInfoDialog:onUpdateCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local cellSize= cell:getContentSize()
    if info.boss then
        self:addLayout("pveheroIcon",bg)
        if info.boss[1] == 1 then
            local build = GameUI.addBuildHead(bg,info.boss[2],150,150,125,146,1,info.boss[3] or 1,21)
        end
        if info.boss[1] == 2 then
            local head = GameUI.addHeadIcon(bg, info.boss[2],0.6,130,156,0,{lv=6})
        end
        local temp
        temp = ui.colorNode({176,55}, {0,0,0,150})
        display.adapt(temp, 48, 58, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        temp = ui.label("LV"..tostring(info.boss[3] or 1), General.font1, 30, {color={255,255,255}})
        display.adapt(temp, 125, 89, GConst.Anchor.Center)
        bg:addChild(temp)
    end
    if info.boxLv then
        local box = ui.sprite("images/battleBox1.png",{201,178})
        display.adapt(box,125,146,GConst.Anchor.Center)
        bg:addChild(box)
        local lv = ui.label("X3",General.font1,45,{color={255,255,255}})
        display.adapt(lv,210,60,GConst.Anchor.RightBottom)
        bg:addChild(lv)
        local temp
        temp = ui.label("LV"..tostring(info.boxLv or 1), General.font1, 42, {color={255,255,255}})
        display.adapt(temp, 62, 89, GConst.Anchor.Center)
        bg:addChild(temp)
        cell:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self.view, box, cellSize.width/2, cellSize.height/2, Localize("infoPveBox")}))
    end
    if info.addrews then
        local lv = ui.label("+",General.font1,100,{color={238,221,190}})
        display.adapt(lv,145,60,GConst.Anchor.RightBottom)
        bg:addChild(lv)
    end
    if info.certainRwds then
        local item = info.certainRwds
        local rewd = GameUI.addItemIcon(bg,item[1],item[2],0.75,75,146,false,false,{itemNum=item[3] or 1})
        cell:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self.view, rewd, cellSize.width/2, cellSize.height/2, GameLogic.getItemDesc(item[1], item[2])}))
    end
    if info.firstRwds then
        local item = info.firstRwds
        GameUI.addItemIcon(bg,item[1],item[2],0.5,62,73,true,false,{itemNum=item[3] or 1})
        GameUI.registerTipsAction(cell, self.view, item[1], item[2])
    end
end

function PveInfoDialog:onPveBattle()
    local context = GameLogic.getUserContext()
    local pve = context.pve
    if context.heroData:getHeroMax() < context.heroData:getHeroNum() + 3 then
        display.pushNotice(Localize("noticeHeroSpaceFull"))
        return
    end
    if pve and pve:isInited() and self.selectedPveStage then
        local chance = pve:getBattleChance(GameLogic.getSTime())
        local detail = pve:getDetail(self.selectedPveStage)
        if chance<=0 and (not GameLogic.useTalentMatch or detail.attacked) then
            local bchance, left, cost,addNum = pve:getBuyedChance()
            if left>0 then
                if GameNetwork.lockRequest() then
                    GameNetwork.unlockRequest()
                    display.showDialog(AlertDialog.new(1, Localize("buyPveBatter"), Localizef("butPveSure",{num=left}), {ctype=const.ResCrystal, cvalue=cost, callback=Handler(self.onRequestBuyChance, self)}))
                end
            else
                display.pushNotice(Localize("noticePveChanceEmpty"))
            end
        elseif not self.locked then
            GameLogic.checkCanGoBattle(const.BattleTypePve,function()
                context:addCmd({const.CmdPveBBat,self.selectedPveStage})
                pve.nowIdx = self.selectedPveStage
                local params=context.pve:getDetail(self.selectedPveStage)
                local states = self.states
                if (self.selectedPveStage == 1 or self.selectedPveStage == 6) and states.star == 0 then
                    local group = {}
                    table.insert(group,{})
                    local ucontext = GameLogic.getUserContext()
                    local sign = ucontext:getProperty(const.ProUseLayout)
                    sign = GameLogic.dnumber(sign, 6)
                    local lid = const.LayoutPvp
                    if sign[1] > 0 then
                        lid = const.LayoutPve
                    end
                    for i=1, 5 do
                        local hero = ucontext.heroData:getHeroByLayout(lid, i, 1)
                        if hero then
                            table.insert(group, hero)
                        end
                    end
                    if #group > 5 then
                        table.remove( group, #group)
                    end
                    params.useSpecialHero = group
                    if self.selectedPveStage == 6 then
                        if GameLogic.useTalentMatch then
                            group[1] = {id = 3005, awake = 0, level = 120, eid = 2001, elv = 180 }
                        else
                            group[1] = {id = 4001,awake = 10,level = 120,eid = 2001, elv = 180}
                        end
                        params.from = "PveGuide"
                    elseif self.selectedPveStage == 1 then
                        if GameLogic.useTalentMatch then
                            group[1] = {id = 4010,awake = 10,level = 150}
                        else
                            group[1] = {id = 4014,awake = 10,level = 150}
                        end
                    end
                end
                GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=2,idx=self.selectedPveStage,bparams=params})
            end)
        end
    end
end

function PveInfoDialog:onRequestBuyChance()
    local context = GameLogic.getUserContext()
    local bchance,buyTimes,cost,addNum = context.pve:getBuyedChance()
    local info = {cost=cost,addNum=addNum}
    if buyTimes<=0 then
        print("购买次数不足")
        local viplv = context:getInfoItem(const.InfoVIPlv)
        if viplv>=const.MaxVipLV then
            display.pushNotice(Localize("pveBattleTimesNotBuyOver"))
        else
            display.pushNotice(Localizef("pveBattleTimesNotBuy",{num=bchance}))
        end
        return
    end
    -- 判断宝石是否足够
    local crystal = context:getRes(const.ResCrystal)
    if crystal<cost then
        display.showDialog(AlertDialog.new({ctype=const.ResCrystal}))
        return
    end
    if GameNetwork.lockRequest() then
        GameNetwork.request("pvereset",nil, self.onResponsePveReset, self,info)
    end
end

function PveInfoDialog:onResponsePveReset(info, isSuc, data)
    GameNetwork.unlockRequest()
    if isSuc then
        local context = GameLogic.getUserContext()
        context:changeRes(const.ResCrystal, -info.cost)
        context.pve:changeChance(info.addNum)
        context.pve:resetChance()
        if self.deleted then
            return
        end
        self:initViews()
    end
end

-- 扫荡
function PveInfoDialog:sweepPveBattle(num)
    local context = GameLogic.getUserContext()
    local pve = context.pve
    local sweepTimes = self.sweepTimes
    local chance = pve:getBattleChance()
    local free = 0
    if sweepTimes > 0 then
        free = 1
        if num > sweepTimes then
            num = sweepTimes
        end
        if num > chance then
            num = chance
        end
    else
        free = 0
        if num > chance then
            num = chance
        end
    end
    -- 仓库位置是否足够
    if context.heroData:getHeroMax() < context.heroData:getHeroNum() + 3 then
        display.pushNotice(Localize("noticeHeroSpaceFull"))
        return
    end
    -- 体力是否足够
    if chance <= 0 then
        local bchance, left, cost,addNum = pve:getBuyedChance()
        if left <=0 then
            display.pushNotice(Localize("noticePveChanceEmptyAndBuy"))
        else
            display.showDialog(AlertDialog.new(1, Localize("buyPveBatter"), Localizef("butPveSure",{num=left}), {ctype=const.ResCrystal, cvalue=cost, callback=Handler(self.onRequestBuyChance, self)}))
        end
        return
    end
    -- 判断宝石是否足够
    local crystal = context:getRes(const.ResCrystal)
    if crystal<const.PricePveSweep*num and free==0 then
        display.showDialog(AlertDialog.new({ctype=const.ResCrystal}))
        return
    end
    if not GameNetwork.lockRequest() and not self.threeStar then
        return
    end
    --参数swp=[idx,snum,free]  关卡id，扫荡次数，是否花费砖石
    --条件3星过关，若扫荡当前剩余的次数小于vip免费次数时，扫荡最大值为10，
    _G["GameNetwork"].request("sweepPveBattle",{uid=context.uid,swp={self.idx,num,free}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            self.sweepTimes = self.sweepTimes-num
            -- 任务统计
            context.activeData:finishActCondition(const.ActTypePVE,num)
            context:setVipPermission("pvesweep",num)
            context.pve:changeChance(-num)
            if free == 0 then
                context:changeRes(const.ResCrystal, -const.PricePveSweep*num)
            end
            local rewds ={}
            if data.agl then
                for i,vv in pairs(data.agl) do
                    for j,v in ipairs(vv) do
                        table.insert(rewds,{v[2],v[3],v[4]})
                    end
                end
            end
            GameLogic.addRewards(rewds)
            SweepOverDialog.new({data=data})
            context.logData:getEmailDatas()
            if self.deleted then
                return
            end
            self:initViews()
        end
    end)
        -- local data = {agl={{{1,10,4,10},{1,10,4,10},{1,10,4,10},{1,10,4,10}},{{1,10,4,10},{1,10,4,10},{1,10,4,10},{1,10,4,10}}}}
        -- SweepOverDialog.new({data=data})
end
SweepOverDialog = class(DialogViewLayout)

function SweepOverDialog:onEnter( ... )

end

function SweepOverDialog:onInitDialog()
    self:setLayout("SweepOverDialog.json")
    self:loadViewsTo()
    local function closeDialog()
       display.closeDialog(0)
    end
    self.dialogDepth=display.getDialogPri()+1
    display.showDialog(self)
    self:initViews()

end

function SweepOverDialog:initViews( ... )
    local infos = {}
    local data =self.data.agl
    local j = 1
    for i,v in pairs(data) do
        table.insert(infos,{id=j,items=v})
        j = j+1
    end
    table.insert(infos,{id=#infos+1,items="button"})
    self.dataLen = #infos
    self.tablecell = self.itemTableView:loadTableView(infos, Handler(self.onUpdateCellItem, self))
    self.cellid = 0
    local function loadCell()
        self.cellid = self.cellid + 1
        if self.dataLen <=2 and self.cellid<=self.dataLen then
            self.tablecell.Cell[self.cellid]:setPositionY(self.tablecell.Cell[self.cellid]:getPositionY()-150)
        end
        if self.cellid<self.dataLen then
            local function moveCell()
                self.tablecell.view:moveAndScaleToCenter(1, 156, 740-self.cellid*376, 0.3)
            end
            local itemid = 0
            local function loadItem()
                if self.tablecell.Cell[self.cellid].tableView then
                    itemid = itemid+1
                    if itemid<=#infos[self.cellid].items and self.tablecell.Cell[self.cellid].tableView.children[itemid] then
                        self.tablecell.Cell[self.cellid].tableView.children[itemid].view:runAction(ui.action.sequence({{"scaleTo",0.3,1,1},{"delay",0.1},{"call",loadItem}}))
                    else
                        self.tablecell.Cell[self.cellid]:getDrawNode():runAction(ui.action.sequence({{"call",moveCell},{"call",loadCell}}))
                    end
                end
            end
            self.tablecell.Cell[self.cellid]:getDrawNode():runAction(ui.action.sequence({{"moveBy",0.2,1210,0},{"delay",0.1},{"call",loadItem}}))
            self.tablecell.view:setScrollEnable(false)
        elseif self.cellid==self.dataLen then
            self.tablecell.Cell[self.cellid]:getDrawNode():runAction(ui.action.sequence({{"moveBy",0.01,1190,0},{"call",loadCell}}))
            self.tablecell.view:setScrollEnable(true)
        end
    end
    loadCell()
end

function SweepOverDialog:onUpdateCellItem(cell, tableView, info)
    local bg = cell:getDrawNode()
    bg:setPositionX(bg:getPositionX()-1210)
    local items = info.items
    if items == "button" then
         local bgView = self:addLayout("cellBtn",bg)
        bgView:loadViewsTo(info)
        info.btnYes:setScriptCallback(Handler(function ()
            display.closeDialog(self.dialogDepth)
        end))
    else
        local bgView = self:addLayout("cellView",bg)
        bgView:loadViewsTo(info)
        info.labPveSweepBatter:setString(Localizef("labPveSweepBatter",{num=info.id}))
        for _, item in ipairs(items) do
            local node = info.cellTableView:createItem(1)
            node.view:setTouchThrowProperty(true, true)
            info.cellTableView:addChild(node)
            self:onUpdateCellIcon(node, info.cellTableView, item)
        end
        cell.tableView = info.cellTableView
        -- cell.tableView = info.cellTableView:loadTableView(items, Handler(self.onUpdateCellIcon, self))
        -- cell.tableView.view:setTouchThrowProperty(true, true)
    end
end

function SweepOverDialog:onUpdateCellIcon(bg, tableView, info)
    local itemNum = 1
    if info[2] ~= const.ItemHero then
        itemNum = info[4]
    end
    GameUI.addItemIcon(bg,info[2],info[3],0.9,125,106,true,false,{itemNum=itemNum or 1})
    GameUI.registerTipsAction(bg, self.view, info[2], info[3])
    bg.view:setScale(0.01)
end
