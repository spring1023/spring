
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local gameSetting=GMethod.loadScript("game.GameSetting")
--成就任务对话框
local AchievementDialog = class2("AchievementDialog",function()
    return BaseView.new("AchievementDialog.json")
end)
function AchievementDialog:ctor(tabId)
    self.dialogDepth=display.getDialogPri()+1
    self.tabId = tabId or 1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
    --引导
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "task" then
        context.guideHand:removeHand()
        context.guide:addStep()
    end
end
function AchievementDialog:canChangeTab(call,idx)
    if call then
        call()
        GEngine.setConfig("taskId",idx)
    end
end
function AchievementDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    local titles = {Localize("titleAchievement"),Localize("titleDailyTask"),Localize("stringLimitActive"), Localize("stringHotActive")}
    if GameLogic.useTalentMatch then
        titles = {Localize("titleAchievement"), Localize("stringLimitActive")}
    end
    self:addTabView(titles, {543,149,450,1370,166,"images/dialogTabBack3_",55,271,69,1870,57,23,1324})
    self.tab[3]:addTab({create=Script.createBasicHandler(self.achievement,self)})
    -- self.tab[3]:addTab({create=Script.createBasicHandler(self.achievementEveryday,self)})
    if not GameLogic.useTalentMatch then
        self.tab[3]:addTab({create=Script.createBasicHandler(self.refreshTask,self)})
    end
    self.tab[3]:addTab({create=Script.createBasicHandler(self.timeLimitActivity,self)})
    if not GameLogic.useTalentMatch then
        self.tab[3]:addTab({create=Script.createBasicHandler(self.hotActivity,self)})
    end
    self:changeTabIdx(self.tabId)

    local remindNode=ui.node()
    display.adapt(remindNode, 463,1450)
    self:addChild(remindNode)

    --提示角标
    local redNum1 = GameUI.addRedNum(self,420,1450,0,1,10)
    GameEvent.bindEvent(redNum1,"refreshTaskRedNum",redNum1,function()
        local context = GameLogic.getUserContext()
        local num = context.achieveData:getNotReward()
        redNum1:setNum(num)
    end)
    local context = GameLogic.getUserContext()
    local num = context.achieveData:getNotReward()
    redNum1:setNum(num)

    if not GameLogic.useTalentMatch then
        local redNum2 = GameUI.addRedNum(self,420+450,1450,0,1,10)
        GameEvent.bindEvent(redNum2,"refreshTaskRedNum",redNum2,function()
            local context = GameLogic.getUserContext()
            local num = context.activeData:getNotRewardDailyTask()
            local dtinfo = context.activeData:getDailyTaskDtinfo()
            local stime = GameLogic.getSTime()
            local dtime = dtinfo[1]
            if (math.floor((stime-const.InitTime)/86400) > math.floor((dtime-const.InitTime)/86400)) then
                num = 0
            end
            redNum2:setNum(num)
        end)
        local num = context.activeData:getNotRewardDailyTask()
        local dtinfo = context.activeData:getDailyTaskDtinfo()
        local stime = GameLogic.getSTime()
        local dtime = dtinfo[1]
        if (math.floor((stime-const.InitTime)/86400) > math.floor((dtime-const.InitTime)/86400)) then
            num = 0
        end
        redNum2:setNum(num)
    end
    self.context = context

    --提示角标
    local redNum1 = GameUI.addRedNum(self,420+(GameLogic.useTalentMatch and 450 or 900),1450,0,1,10)
    GameEvent.bindEvent(redNum1,"refreshTaskRedNum",redNum1,function()
        local context = GameLogic.getUserContext()
        local d = context.activeData
        local num = d:getNotRewardLimit101()+d:getNotRewardDaily()
        -- local num = d:getNotRewardDaily()
        redNum1:setNum(num)
    end)
    if not GameLogic.useTalentMatch then
        local redNum2 = GameUI.addRedNum(self,420+1350,1450,0,1,10)
        GameEvent.bindEvent(redNum2,"refreshTaskRedNum",redNum2,function()
            local context = GameLogic.getUserContext()
            local d = context.activeData
            local num = d:getNotRewardHot()
            redNum2:setNum(num)
        end)
    end
    GameEvent.sendEvent("refreshTaskRedNum")
end
function AchievementDialog:achievement(tab)
    local temp
    local ddata = GameLogic.getUserContext().achieveData.ddata
    dump(ddata)
    if not self.achieveNode then
        self.achieveNode = ui.node({0,0},true)
        GameEvent.bindEvent(self.achieveNode,"refreshAchievementDialog",self,self.achievement)
    end
    local bg = self.achieveNode
    bg:removeAllChildren(true)

    local infos={}
    for i=1,12 do
        if ddata[i] then
            local info = {id=i, item = ddata[i], __order=(SData.getData("achieves", ddata[i].id).order or 0) + i}
            table.insert(infos, info)
            if info.item.isget == 0 then
                if info.item.glv >= info.item.tlv then
                    info.__order = info.__order - 10000
                end
            else
                info.__order = info.__order + 10000
            end
        end
    end
    GameLogic.mySort(infos, "__order", false)
    for i,v in ipairs(infos) do
        v.idx = i
    end

    self:addTableViewProperty("infoTableView",infos,Script.createBasicHandler(self.achievementCallCell,self))
    self:loadView("infoTableView",bg)
    return bg
end
function AchievementDialog:achievementCallCell(cell, tableView, info)
    local item = info.item
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    local i=info.id
    if info.idx%2==1 then
        self:loadView("cellBackView",bg)
    end
    self:loadView("infoCellViews_achievement",bg)
    self:insertViewTo()
    --图片
    if i == 1 then
        GameUI.addBuildHead(bg,item.tid,262,245,34+131,41+122,2,item.tlv)
    else
        GameUI.addActiveImg(bg,item.type+200,262,245,34+131,41+122,0)
    end
    self.achieveName:setString(Localizef("dataAchieveName" .. i,{a = BU.getBuildName(item.tid), b = item.tlv}))
    if i == 1 then
        local aname = BU.getBuildName(item.tid)
        if item.tlv==1 then
            self.achieveDes:setString(Localizef("dataActiveDes201f0",{name=aname}) .. Localize("dataActiveDes201_" .. item.tid))
        else
            self.achieveDes:setString(Localizef("dataActiveDes201f1",{name=aname, level=item.tlv}) .. Localize("dataActiveDes201_" .. item.tid))
        end
    elseif i == 9 then
        self.achieveDes:setString(Localizef("dataActiveDes9",{num = item.tlv}))
    elseif i == 10 then
        self.achieveDes:setString(Localizef("dataActiveDes10_1",{num = item.tlv}))
    elseif i == 11 then
        self.achieveDes:setString(Localizef("dataActiveDes10_2",{num = item.tlv}))
    else
        self.achieveDes:setString(Localizef("dataActiveDes20" .. i,{a = item.tlv}))
    end
    self.processNum:setString(item.glv .. "/" .. item.tlv)
    self.process:setScaleX(item.glv/item.tlv*(328/449))
    --if item.glv<item.tlv then--完成不显示奖励
        for i,v in ipairs(item.reward) do
            GameUI.addItemIcon(bg,v[1],v[2],88/200,1620+44 -280*(i-1),32+44-6,false)
            local temp = ui.label(v[3],General.font1,45,{color = {255,255,255}})
            display.adapt(temp,1735-280*(i-1),72-6,GConst.Anchor.Left)
            bg:addChild(temp)
        end
    --end
    self.butReceive:setListener(function()
        if info.id == 12 and item.isget == 0 and item.glv < item.tlv then
            local dialog = RenameDialog.new()
            dialog.priority = self.priority + 1
            display.showDialog(dialog)
            return
        end
        self:getachieve(item.id)
    end)
    if item.isget == 0 then
        if info.id == 12 and item.glv < item.tlv then
            self.labelCompleteNoSgin:setVisible(false)
            self.processNum:setVisible(false)
            self.processBack:setVisible(false)
            self.process:setVisible(false)
            self.btnReceiveText:setString(Localize("buttonGo"))
        elseif item.glv>=item.tlv then
            self.labelCompleteNoSgin:setVisible(false)
            self.processNum:setVisible(false)
            self.processBack:setVisible(false)
            self.process:setVisible(false)
            self.btnReceiveText:setString(Localize("btnReceive"))
        else
            --完成
            self.labelCompleteNoSgin:setVisible(false)
            self.butReceive:setVisible(false)
        end
    else
        self.butReceive:setVisible(false)
        self.processNum:setVisible(false)
        self.processBack:setVisible(false)
        self.process:setVisible(false)
    end
    --漫画
    if i == 3 then
        if item.tlv<=20 then
            self.playImg:setVisible(true)
            self.playImg:setScriptCallback(ButtonHandler(GameLogic.doComicJump, 2))
        elseif 20<item.tlv and item.tlv<=35 then
            self.playImg:setVisible(true)
            self.playImg:setScriptCallback(ButtonHandler(GameLogic.doComicJump, 3))
        else
            self.playImg:setVisible(false)
        end
    else
        self.playImg:setVisible(false)
    end
end
function AchievementDialog:refreshTask( tab )
    local context = GameLogic.getUserContext()
    if not self.dailyNode then
        self.dailyNode = ui.node({0,0},true)
    end
    if not self.__firstShow then
        local vip = context:getInfoItem(const.InfoVIPlv)
        local userLv = context:getInfoItem(const.InfoLevel)
        GameLogic.addStatLog(11101,vip,userLv,1)
        self.__firstShow = true
    end
    local bg = self.dailyNode
    bg:removeAllChildren(true)
    self:loadView("dailytaskView",bg)
    local viewTab = self:getViewTab()

    local newView = ui.node()
    bg:addChild(newView)
    GameEvent.bindEvent(newView, "refreshAfterReceive", self, self.refreshTask)
    RegTimeUpdate(viewTab.bg_dailyActiveTop, Handler(self.refreshEveryday, self), 1)

    -- 活跃度
    local active = context:getAchsData()
    viewTab.lab_dailyActiveWord:setString(Localizef("dailyActiveWord"))
    viewTab.lab_dailyActive:setString(Localizef("dailyActive", {num = active[1][3]}))
    viewTab.lab_weekActive:setString(Localizef("weekActive", {num = active[2][3]}))

    self.dBoxItem = {viewTab.btn_box1, viewTab.btn_box2, viewTab.btn_box3, viewTab.btn_box4, viewTab.btn_box5}--日活跃宝箱
    self.wBoxItem = {viewTab.btn_box6, viewTab.btn_box7}--周活跃宝箱
    self.dBoxLab = {viewTab.lab_active1, viewTab.lab_active2, viewTab.lab_active3, viewTab.lab_active4, viewTab.lab_active5}--日活跃度标签
    self.wBoxLab = {viewTab.lab_active6, viewTab.lab_active7}--周活跃度标签
    self.dBoxImage = {viewTab.image_box1, viewTab.image_box2, viewTab.image_box3, viewTab.image_box4, viewTab.image_box5}--每日宝箱精灵
    self.wBoxImage = {viewTab.image_box6, viewTab.image_box7}--周宝箱精灵
    self.allImageOfBox = {[1] = {[1] = "images/box1_1.png", [2] = "images/box1_2.png"}, --所有的箱子图片,目前四种箱子,每种箱子开关两张图
                          [2] = {[1] = "images/box2_1.png", [2] = "images/box2_2.png"},
                          [3] = {[1] = "images/box3_1.png", [2] = "images/box3_2.png"},
                          [4] = {[1] = "images/battleBox1.png", [2] = "images/battleBox2.png"}
                         }
    self.dBoxState = {}   --日活跃度宝箱状态, 1不可领取 2可领但未领 3已领取
    local dRwds = SData.getData("activerwds", 1)
    local wRwds = SData.getData("activerwds", 2)
    local dailyData = active[1]

    local pro = active[1][3]/dRwds[5].active
    local av = active[1][3]
    local proD = {{dRwds[1].active, 16}, {dRwds[2].active, 36}, {dRwds[3].active, 56}, {dRwds[4].active, 76}, {dRwds[5].active, 100}}
    local lastD = {0,0}
    for _, d in ipairs(proD) do
    if d[1] >= av then
        pro = ((av - lastD[1])/(d[1]-lastD[1]) * (d[2] - lastD[2]) + lastD[2])/100
        break
    else
        lastD = d
    end
    end
    if pro > 1 then
        pro = 1
    end
    viewTab.imag_progressBar:setProcess(true,pro)

    for i=1, KTLen(dRwds) do
        if bit.band(bit.lshift(1, i-1),  dailyData[5]) > 0 then
            self.dBoxState[i] = 3
        else
            if dRwds[i].active <= dailyData[3] then
                self.dBoxState[i] = 2
            else
                self.dBoxState[i] = 1
            end
        end
        local v = self.dBoxState[i]
        if i == 1 or i == 2 then
            if v == 1 then
                ui.setFrame(self.dBoxImage[i], self.allImageOfBox[1][1])
            elseif v == 2 then
                self.dBoxImage[i]:runAction(ui.action.arepeat(ui.action.easeSineIn(ui.action.sequence({
                {"delay",1},{"rotateBy",0.1,-30},{"rotateBy",0.1,30},{"rotateBy",0.1,30},{"rotateBy",0.1,-30}
                ,{"rotateBy",0.1,-15},{"rotateBy",0.1,15},{"rotateBy",0.1,15},{"rotateBy",0.1,-15}
                }))))
            elseif v == 3 then
                ui.setFrame(self.dBoxImage[i], self.allImageOfBox[1][2])
                self.dBoxImage[i]:stopAllActions()
                self.dBoxImage[i]:setRotation(0)
            end
        elseif i == 3 or i == 4 then
            if v == 1 then
                ui.setFrame(self.dBoxImage[i], self.allImageOfBox[2][1])
            elseif v == 2 then
                self.dBoxImage[i]:runAction(ui.action.arepeat(ui.action.easeSineIn(ui.action.sequence({
                {"delay",1},{"rotateBy",0.1,-30},{"rotateBy",0.1,30},{"rotateBy",0.1,30},{"rotateBy",0.1,-30}
                ,{"rotateBy",0.1,-15},{"rotateBy",0.1,15},{"rotateBy",0.1,15},{"rotateBy",0.1,-15}
                }))))
            elseif v == 3 then
                ui.setFrame(self.dBoxImage[i], self.allImageOfBox[2][2])
                self.dBoxImage[i]:stopAllActions()
                self.dBoxImage[i]:setRotation(0)
            end
        elseif i == 5 then
            if v == 1 then
                ui.setFrame(self.dBoxImage[i], self.allImageOfBox[3][1])
            elseif v == 2 then
                self.dBoxImage[i]:runAction(ui.action.arepeat(ui.action.easeSineIn(ui.action.sequence({
                {"delay",1},{"rotateBy",0.1,-30},{"rotateBy",0.1,30},{"rotateBy",0.1,30},{"rotateBy",0.1,-30}
                ,{"rotateBy",0.1,-15},{"rotateBy",0.1,15},{"rotateBy",0.1,15},{"rotateBy",0.1,-15}
                }))))
            elseif v == 3 then
                ui.setFrame(self.dBoxImage[i], self.allImageOfBox[3][2])
                self.dBoxImage[i]:stopAllActions()
                self.dBoxImage[i]:setRotation(0)
            end
        end

        dump(self.dBoxState,"dBoxState")

        self.dBoxItem[i]:setScriptCallback(ButtonHandler(self.showDailyReward, self, i, 0))
        self.dBoxLab[i]:setString(N2S(dRwds[i].active))
    end

    self.wBoxState = {}   --周活跃度宝箱状态, 1不可领取 2可领但未领 3已领取
    local weekData = active[2]
    for i=1, KTLen(wRwds) do
        if bit.band(bit.lshift(1, i-1),  weekData[5]) > 0 then
            self.wBoxState[i] = 3
        else
            if wRwds[i].active <= weekData[3] then
                self.wBoxState[i] = 2
            else
                self.wBoxState[i] = 1
            end
        end
        local v2 = self.wBoxState[i]
        if v2 == 1 then
            ui.setFrame(self.wBoxImage[i], self.allImageOfBox[4][1])
        elseif v2 == 2 then
            self.wBoxImage[i]:runAction(ui.action.arepeat(ui.action.easeSineIn(ui.action.sequence({
            {"delay",1},{"rotateBy",0.1,-30},{"rotateBy",0.1,30},{"rotateBy",0.1,30},{"rotateBy",0.1,-30}
            ,{"rotateBy",0.1,-15},{"rotateBy",0.1,15},{"rotateBy",0.1,15},{"rotateBy",0.1,-15}
            }))))
        elseif v2 == 3 then
            ui.setFrame(self.wBoxImage[i], self.allImageOfBox[4][2])
            self.wBoxImage[i]:stopAllActions()
            self.wBoxImage[i]:setRotation(0)
        end
        self.wBoxItem[i]:setScriptCallback(ButtonHandler(self.showDailyReward, self, i, 1))
        self.wBoxLab[i]:setString(Localizef("weekReward",{num = wRwds[i].active}))
    end
    self:achievementEveryday()
    GameEvent.bindEvent(bg,"refreshAchievementDialogEveryday",self,self.refreshTask)
    return bg
end

function AchievementDialog:refreshEveryday()
    local context = GameLogic.getUserContext()
    local dtinfo = context.activeData:getDailyTaskDtinfo()
    local stime = GameLogic.getSTime()
    local dtime = dtinfo[1]
    if (math.floor((stime-const.InitTime)/86400) > math.floor((dtime-const.InitTime)/86400)) then
        context.activeData:refreshDailyTask()
    end
end

function AchievementDialog:showDailyReward( boxIndex, boxType )
    local DailyActiveReward = GMethod.loadScript("game.UI.dialog.ActivityAndAchievement.DailyActiveReward")
    if boxType == 0 then
        if self.dBoxState[boxIndex] == 3 then
            return
        end
        display.showDialog(DailyActiveReward.new({boxIndex = boxIndex, boxType = boxType, boxState = self.dBoxState[boxIndex]}))
    elseif boxType == 1 then
        if self.wBoxState[boxIndex] == 3 then
            return
        end
        display.showDialog(DailyActiveReward.new({boxIndex = boxIndex, boxType = boxType, boxState = self.wBoxState[boxIndex]}))
    end
end

function AchievementDialog:achievementEverydayCallCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local context = GameLogic.getUserContext()
    local taskinfos = info.taskinfos
    local dailyid = info.dailyid
    cell:setEnable(false)
    -- local i=taskinfos.id
    self:loadView("dailytaskcellView",bg)
    self:insertViewTo()
    local viewTab = self:getViewTab()
    local items = taskinfos.rwds
    for i=1,#items do
        GameUI.addItemIcon(bg,items[i][1],items[i][2],0.4,156+i*250,76)
        local itemNum = ui.label(tostring(items[i][3]),General.font1,45,{color={252,255,255}})
        display.adapt(itemNum,256+i*250,76,GConst.Anchor.Center)
        bg:addChild(itemNum)
    end
    -- 活动图标

    if taskinfos.icon then
        local icon = ui.sprite(taskinfos.icon,{256,248},true)
        if icon then
            display.adapt(icon,54+128,15+134,GConst.Anchor.Center)
            bg:addChild(icon)
        end
    else
        GameUI.addActiveImg(bg,taskinfos.duty_mode,256,248,54+128,15+134,0)
    end
    -- 边框
    local s=0
    local h=0
    if taskinfos.duty_type >= 100 then
        s = 0
        h = 0
        viewTab.stringActDes:setString(Localize("dailyActType1"))
        ui.setColor(viewTab.stringActDes, {255,0,0})
    elseif taskinfos.duty_type < 100 then
        s = -45
        h = 180
    end
    viewTab.outline:setSValue(s)
    viewTab.outline:setHValue(h)
    -- 按钮状态
    if dailyid.state == 0 and dailyid.progres>= dailyid.duty_max then   --领取
        viewTab.butReceive:setHValue(0)
        viewTab.btnReceive:setString(Localize("btnReceive"))
        viewTab.butReceive:setScriptCallback(ButtonHandler(function ()
            context.activeData:getDailyReward(dailyid.id,self)
            local vip = context:getInfoItem(const.InfoVIPlv)
            local userLv = context:getInfoItem(const.InfoLevel)
            local actId = dailyid.id
            GameLogic.addStatLog(11102,actId,vip,userLv)
        end))
        dailyid.progres = dailyid.duty_max
    elseif dailyid.state == 0 and dailyid.progres < dailyid.duty_max then   -- 前往
        viewTab.butReceive:setHValue(114)
        viewTab.btnReceive:setString(Localize("buttonGo"))
        viewTab.butReceive:setScriptCallback(ButtonHandler(function ()
            local stime = self.btnActTime or 0
            local stime2 = socket.gettime()
            if stime2 - stime > 0.5 then
                self.btnActTime = stime2
            else
                return
            end
            GameLogic.doCondition(context, taskinfos.duty_mode)
        end))
    elseif dailyid.state > 0 then       --已领取
        viewTab.butReceive:setSValue(-100)
        viewTab.btnReceive:setString(Localize("labelRecived"))
        dailyid.progres = dailyid.duty_max
    end
    viewTab.getProcessLb:setString(dailyid.progres.."/"..dailyid.duty_max)
    viewTab.stringActDes:setString(Localizef(taskinfos.wkey or ("dailyTask"..taskinfos.duty_mode),{num=dailyid.duty_max,a=dailyid.duty_max}))
    -- viewTab.stringActDes:setString(Localize("任务"..tostring(dailyid.type).."  前往"..tostring(taskinfos.duty_mode)))
    if taskinfos.jump and taskinfos.jump == 0 and dailyid.progres < dailyid.duty_max then
        viewTab.butReceive:setSValue(-100)
        viewTab.btnReceive:setString(Localize("labnotFinish"))
    end
    if self.allBtnGrey then
        viewTab.butReceive:setSValue(-100)
        viewTab.butReceive:setEnable(false)
    end
end
function AchievementDialog:initDailyIcon( ... )
    local ResConditions = SData.getData("ResConditions")
    local icons = {}
    for i,v in ipairs(ResConditions) do
        if not icons[v.condtionId] then
            icons[v.condtionId] = v.icon
        end
    end
    return icons
end
function AchievementDialog:achievementEveryday(tab)
    local bg = self.dailyNode
    local infos = {}
    local context = GameLogic.getUserContext()
    local dailyid = context.activeData:sortDailyTask()
    local ntype = "task"
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffTask)
    if buffInfo[4]~=0 then
        ntype = "task2"
    end
    for i,v in ipairs(dailyid) do
        local taskinfos = SData.getData(ntype,v.id)
        infos[#infos+1]={taskinfos=taskinfos,dailyid=v}
    end
    -- dump(infos,"achievementEveryday infos")
    self:addTableViewProperty("dailytaskTableView",infos,Script.createBasicHandler(self.achievementEverydayCallCell,self))
    self:loadView("dailytaskTableView",bg)
    return bg
end

------------------------------------------------------------------------------------------------
function AchievementDialog:getactreward(atype,aid)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getactreward",{getactreward = {atype,aid}},function(isSuc, data)
        GameNetwork.unlockRequest()
        if isSuc then
            local activeData = GameLogic.getUserContext().activeData
            activeData:getReward(atype,aid)
            GameLogic.showHeroRewsUieffect(data)
            GameLogic.addRewards(data)
            GameLogic.statCrystalRewards("每日任务奖励",data)
            GameLogic.showGet(data)
            if not self.deleted then
                self:timeLimitActivity()
            end
        end
    end)
end

function AchievementDialog:getachieve(id)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getachieve",{getachieve = {id}},function(isSuc, data)
        GameNetwork.unlockRequest()
        if isSuc then
            local achieveData = GameLogic.getUserContext().achieveData
            achieveData:getReward(id)
            if self.achievement then
                self:achievement()
            end
        end
    end)
end
----------------------------------------------------------------------------------------------
function AchievementDialog:timeLimitActivity(tab)
    local context = GameLogic.getUserContext()
    local limitActive = context.activeData.limitActive
    local dailyData = context.activeData.dailyData
    local keyArr = {}
    for k,v in pairs(limitActive) do
        table.insert(keyArr,k)
    end

    local infos = {}
    for k, act in pairs(limitActive) do
        local item = {atype = k, aid = 1,gnum = 0,anum = 10,isget = 0,time = act[2]-GameLogic.getTime()}
        if item.time>0 and item.atype~=107 and item.atype~=4 and item.atype~=102
            and item.atype ~= 110 and (not GameLogic.useTalentMatch or item.atype ~= 101) then
            table.insert(infos,{item = item, _order=k})
        end
    end

    local dhActive = GameLogic.getUserContext().activeData.dhActive
    local dt = context.activeData.dailyWelfare
    for k,v in pairs(dailyData) do
        local _order = k
        if v.atype~=4 and v.atype~=102 then
            if v.atype == 12 then
                local params = dhActive[v.atype] or {1,0,0,0}
                if params[4] ==1 then
                    _order = 1000+k
                end
                table.insert(infos,{_order=_order,item=v})
            elseif v.atype == 13 then
                if dt[7] >= dt[6] then
                   _order = 1000+k
                end
                table.insert(infos,{_order=_order,item=v})
            elseif v.atype == 4 then
                if v.isget > 0 then
                   _order = 1000+k
                end
                table.insert(infos,{_order=_order,item=v})
            end
        end
    end

    GameLogic.mySort(infos, "_order")

    for i, info in ipairs(infos) do
        info.id = i
    end

    if not self.limitNode then
        self.limitNode = ui.node({0,0},true)
    else
        if #infos == 0 then
            display.pushNotice("labelNoLimitAct")
        end
    end
    local bg = self.limitNode
    local temp
    bg:removeAllChildren(true)
    self:addTableViewProperty("infoTableView",infos,Script.createBasicHandler(self.timeLimitCallCell,self))
    self:loadView("infoTableView",bg)
    return bg
end

function AchievementDialog:timeLimitCallCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    local i=info.id
    if i%2==1 then
        self:loadView("cellBackView",bg)
    end

    self:loadView("infoCellViews_activity",bg)
    self:insertViewTo()
    local item = info.item
    GameUI.addActiveImg(bg,item.atype,256,268,54+128,35+134,0)

    local context = GameLogic.getUserContext()
    self.stringActDes:setString(GameLogic.getActiveDes(item.atype))
    local time = item.time
    self.stringSurplusTime:setString(Localize("labelTimeCount") .. Localizet(time))
    if not item.time then
        self.stringSurplusTime:setVisible(false)
    end
    --前往
    self.butGoto:setListener(function()
        if item.atype == 101 then
            EverydayTreasureDialog.new()
        elseif item.atype == 103 then
            display.showDialog(HeroMainDialog.new({initTag="extract"}))
        elseif item.atype == 104 then
            HeroPackageDialog.new()
        elseif item.atype == 105 then
            VisitHeroDialog.new()
        elseif item.atype == 12 then
            print("每日登陆")
            SignRewardDialog.new(self)
        elseif item.atype == 13 then
            print("每日福利任务")
            EveryDayWelfareDialog.new()
        elseif item.atype == 4 then
            local params={id=1, closeDialogCallback=function ()
                if not self.deleted then
                    self:timeLimitActivity()
                end
            end}
            StoreDialog.new(params)
        end
    end)
    --完成
    self.labelCompleteNoSgin:setVisible(false)
    --完成度  1/1
    self.getProcessLb:setVisible(false)
    if item.atype == 103 then
        self.getProcessLb:setVisible(true)
        local gnum=item.gnum
        if gnum>item.anum then
            gnum=item.anum
        end
        self.getProcessLb:setString(gnum .. "/" .. item.anum)
    end

    --领取
    self.butReceive:setListener(function()
        print("领取")
        if item.atype == 101 then
            EverydayTreasureDialog.new()
        elseif item.atype == 4 then
            self:getactreward(item.atype,item.aid)
        end
    end)

    self.labelCompleteNoSgin:setVisible(false)
    self.butReceive:setVisible(false)

    if item.atype == 101 or item.atype == 102 then
        local redNum2 = GameUI.addRedNum(self.butGoto:getDrawNode(),-26,90,0,1,30)
        GameEvent.bindEvent(redNum2,"refreshTaskRedNum",redNum2,function()
            local d = context.activeData
            local atype = item.atype
            local num
            if atype == 101 then
                num = d:getNotRewardLimit101()
            elseif atype == 102 then
                num = d:getNotRewardLimit102()
            end
            redNum2:setNum(num)
        end)
        GameEvent.sendEvent("refreshTaskRedNum")
    end

    --每日登陆
    if item.atype == 12 then
        self.labelCompleteNoSgin:setVisible(false)
        self.butReceive:setVisible(false)
        self.butGoto:setVisible(true)
        local redNum2 = GameUI.addRedNum(self.butGoto:getDrawNode(),-27,100,0,1,2)
        GameEvent.bindEvent(redNum2,"refreshTaskRedNum",redNum2,function()
            local dt = context.activeData.dhActive[12]
            local isget = dt and dt[4] or 0
            local num
            if isget ==0 then
                num = 1
            else
                num = 0
            end
            if redNum2.setNum then
                redNum2:setNum(num)
            end
        end)
        GameEvent.sendEvent("refreshTaskRedNum")
        local dhActive = context.activeData.dhActive
        local params = dhActive[12] or {1,0,0,0}
        if params[4] ==1 then
            local temp = ui.label(Localize("labelAlreadyReceive"),General.font1,45,{color={252,58,66}})
            display.adapt(temp,1672,280,GConst.Anchor.Center)
            bg:addChild(temp)
        end
    elseif item.atype == 13 then
        self.labelCompleteNoSgin:setVisible(false)
        self.butReceive:setVisible(false)
        self.butGoto:setVisible(true)
        local lb = self.getProcessLb
        local redNum2 = GameUI.addRedNum(self.butGoto:getDrawNode(),-27,100,0,1,1)
        local tempLb = ui.label(Localize("labelAlreadyReceive"),General.font1,45,{color={252,58,66}})
        display.adapt(tempLb,1672,280,GConst.Anchor.Center)
        bg:addChild(tempLb)
        GameEvent.bindEvent(redNum2,"refreshTaskRedNum",redNum2,function()
            local dt = context.activeData.dailyWelfare or {const.DTVersion, const.DTDayMax, 0,0,0, 0,1}
            local num
            if dt[7] < dt[6] and dt[5] >= dt[4] then
                num = 1
            else
                num = 0
            end
            if redNum2.setNum then
                redNum2:setNum(num)
            end
            tempLb:setVisible(dt[7] >= dt[6])
            local fix = 1
            if dt[7] >= dt[6] then
                fix = 0
            end
            lb:setString((dt[2]-fix) .. "/" .. const.DTDayMax)
        end)
        GameEvent.sendEvent("refreshTaskRedNum")
    elseif item.atype == 4 then
        local temp = ui.label("",General.font1,45,{color={252,58,66}})
        display.adapt(temp,1850,280,GConst.Anchor.Right)
        bg:addChild(temp)
        local str = ""
        local stime = GameLogic.getSTime()
        if item.isget == 0 then
            if item.gnum>=item.anum then
                self.labelCompleteNoSgin:setVisible(false)
                self.butGoto:setVisible(false)
                local remain1 = context.vips[4][2]-stime
                local remain2 = context.vips[5][2]-stime
                if remain1>0 then
                    if GameLogic.getUserContext().union then
                        local day = math.ceil(remain1/86400)
                        str = Localizef("labelUcardRemainDay",{a=day})
                        self.butReceive:setVisible(true)
                    else
                        remain2 = remain2 - remain1
                    end
                elseif remain2>0 then
                    local day = math.ceil(remain2/86400)
                    str = Localizef("labelRemainDay",{a=day})
                    self.butReceive:setVisible(true)
                --强制逻辑，根据返回时间再次确定是否完成
                else
                    self.getProcessLb:setString("0/1")
                    self.labelCompleteNoSgin:setVisible(false)
                    self.butReceive:setVisible(false)
                    self.buttonGo:setString(Localize("buttonGoBuy"))
                end
            else
                self.labelCompleteNoSgin:setVisible(false)
                self.butReceive:setVisible(false)
                self.buttonGo:setString(Localize("buttonGoBuy"))
            end
        else
            local remain1 = context.vips[4][2]-stime
            local remain2 = context.vips[5][2]-stime
            local day1 = math.ceil(remain1/86400)-1
            local day2 = math.ceil(remain2/86400)-1
            if day1>0 then
                str = Localize("labelAlreadyReceive") .. "，" .. Localizef("labelUcardRemainDay",{a=day1})
            elseif day2>0 then
                str = Localize("labelAlreadyReceive") .. "，" .. Localizef("labelRemainDay",{a=day2})
            end
            self.labelCompleteNoSgin:setVisible(false)
            self.butReceive:setVisible(false)
            self.buttonGo:setString(Localize("labelRenew"))
        end
        temp:setString(str)
    end
end

function AchievementDialog:hotActivity(tab)
    local temp
    GameLogic.getUserContext().activeData:initHotData()
    local hotData = GameLogic.getUserContext().activeData.hotData
    local infos = {}
    for i,v in pairs (hotData) do
        table.insert(infos,{id = #infos+1, item = v})
    end
    if not self.hotNode then
        self.hotNode = ui.node({0,0},true)
    end
    local bg = self.hotNode
    bg:removeAllChildren(true)
    self:addTableViewProperty("infoTableView",infos,Script.createBasicHandler(self.hotCallCell,self))
    self:loadView("infoTableView",bg)
    return bg
end
function AchievementDialog:hotCallCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    local i=info.id
    if i%2==1 then
        self:loadView("cellBackView",bg)
    end
    self:loadView("infoCellViews_activity",bg)
    self:insertViewTo()
    local item = info.item
    GameUI.addActiveImg(bg,item.atype,256,268,54+128,35+134,0)
    self.stringActDes:setString(GameLogic.getActiveDes(item.atype))
    self.stringSurplusTime:setVisible(false)
    --前往
    self.butGoto:setListener(function()
        print("前往")
        if item.atype == 51 then    --首充
            display.showDialog(FirstChargePackageDialog)
        elseif item.atype == 52 then    --加入联盟
            if  not GameLogic.getUserContext().buildData:getBuild(2)  then
                display.pushNotice(Localize("labelNotUnionBuild"))
            else
                UnionDialog.new()
            end
        elseif item.atype == 53 then    --参与一次联盟战
            if GameLogic.getUserContext().union then
                GameLogic.unionBattle()
            else
                display.pushNotice(Localize("stringNotJoin"))
            end
        elseif item.atype == 54 then    --英雄抽取
            display.showDialog(HeroMainDialog.new({initTag="extract",callback=function()
                if self.hotActivity then
                    self:hotActivity()
                end
            end}))
        elseif item.atype == 56 then    --绑定账号
            SystemSetDialog.new()
        elseif item.atype == 57 then    --推广码活动
            local dialog = ActivityListDialog.new({menuActType = 5, actType = 4})
            if dialog then
                display.showDialog(dialog)
            end
            -- SpreadAndRewardDialog.new()
        elseif item.atype == 58 then    --邀请好友开宝箱
            InviteFriendsOpenBoxDialog.new()
        elseif item.atype == 59 then    --好友互赠黑晶
            FriendExchanged.new()
        end
    end)

    --完成度
    local gnum=item.gnum
    if gnum>item.anum then
        gnum=item.anum
    end
    self.getProcessLb:setString(gnum .. "/" .. item.anum)
    if item.atype == 60 then
        self.getProcessLb:setString(item.anum .. "/6")
    end

    for i,v in ipairs(item.reward) do
        if v.gtype>0 and v.gid >0 then
            GameUI.addItemIcon(bg,v.gtype,v.gid,88/200,1620+44 -280*(i-1),63,false)
            local temp = ui.label(v.gnum,General.font1,45,{color = {255,255,255}})
            display.adapt(temp,1735-280*(i-1),63,GConst.Anchor.Left)
            bg:addChild(temp)
        end
    end

    --领取
    self.butReceive:setListener(function()
        print("领取")
        if item.atype == 51 then    --首冲
            display.showDialog(FirstChargePackageDialog.new({callback = function()
                self:hotActivity()
            end}))
        else
            self:getactreward2(item.atype,item.aid)
        end
    end)
    if item.isget == 1 then
        self.butReceive:setVisible(false)
        self.butGoto:setVisible(false)
    else
        if item.gnum>=item.anum then
            self.butGoto:setVisible(false)
            self.labelCompleteNoSgin:setVisible(false)
        else
            self.labelCompleteNoSgin:setVisible(false)
            self.butReceive:setVisible(false)
        end
    end

    if item.atype == 57 then
        self.butGoto:setVisible(true)
        self.labelCompleteNoSgin:setVisible(false)
        self.butReceive:setVisible(false)
    end
    if item.atype == 60 then
        self.butGoto:setVisible(true)
        self.labelCompleteNoSgin:setVisible(false)
        self.butReceive:setVisible(false)
        if item.gnum==item.anum and item.isget==1 then
            self.butGoto:setVisible(false)
            self.labelCompleteNoSgin:setVisible(true)
            self.butReceive:setVisible(false)
        end
        if item.gnum>=item.anum and item.isget==0 then
            local redNum2 = GameUI.addRedNum(self.butGoto:getDrawNode(),-26,90,0,1,1)
            redNum2:setNum(1)
        end
    end
end
------------------------------------------------------------------------------------------------
function AchievementDialog:getactreward2(atype,aid)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getactreward",{getactreward = {atype,aid}},function(isSuc, data)
        GameNetwork.unlockRequest()
        if isSuc then
            if atype == 103 then
                local limitActive = GameLogic.getUserContext().activeData.limitActive
                limitActive[103][6] = 1
            else
                local activeData = GameLogic.getUserContext().activeData
                activeData:getReward(atype)
            end
            GameLogic.showHeroRewsUieffect(data)
            GameLogic.addRewards(data)
            GameLogic.statCrystalRewards("热门活动奖励",data)
            GameLogic.showGet(data)
            if self.initUI then
                if atype>100 then
                    self:timeLimitActivity()
                else
                    self:hotActivity()
                end
            end
        end
    end)
end
return AchievementDialog










