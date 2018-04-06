local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

--成就任务对话框

local pages = {task = 1,achievement = 2}
local AchievementDialog = class(DialogViewLayout)

function AchievementDialog:ctor(tabId)
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    display.showDialog(self)

    -- self.tabId = tabId or 1
    self:initUI()
    
    --引导
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "task" then
        context.guideHand:removeHand()
        context.guide:addStep()
    end
end
-- function AchievementDialog:canChangeTab(call,idx)
--     if call then
--         call()
--         GEngine.setConfig("taskId",idx)
--     end
-- end

function AchievementDialog:onCreate( ... )
    self:setLayout("task_dialog.json")
    self:loadViewsTo()
end
function AchievementDialog:initUI()
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog,self.priority))

    local btnTitle = {"titleDailyTask","titleAchievement"}
    self.pageBtns = {}
    local layout = self.layout_titleBtn
    layout:removeAllChildren()
    for k,v in pairs(pages) do
        local pageBtn = layout:createItem(1)
        pageBtn:loadViewsTo()
        layout:addChild(pageBtn)
        pageBtn.lb_taskTitle:setString(Localize(btnTitle[v]))
        pageBtn.btn_title:setScriptCallback(ButtonHandler(self.selectPage,self,v))
        self.pageBtns[v] = pageBtn
    end

    local btn_task = self.pageBtns[1]
    local s = btn_task:getContentSize()
    --提示角标
    local redNum1 = GameUI.addRedNum(btn_task.view,s[1]/2,s[2]/2,0,1,10)
    GameEvent.bindEvent(redNum1,"refreshTaskRedNum",redNum1,function()
        local context = GameLogic.getUserContext()
        local num = context.achieveData:getNotReward()
        redNum1:setNum(num)
    end)
    local context = GameLogic.getUserContext()
    local num = context.achieveData:getNotReward()
    redNum1:setNum(num)

    if not GameLogic.useTalentMatch then
        local redNum2 = GameUI.addRedNum(btn_task.view,s[1]-70,s[2]/2,0,1,10)
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
    GameEvent.sendEvent("refreshTaskRedNum")

    self:selectPage(pages.task)
end

function AchievementDialog:selectPage( idx )
    if self.pageIdx == idx then 
        return 
    else
        if self.pageIdx then
            self.pageBtns[self.pageIdx].img_Lable_Light:setVisible(false)
            self.pageBtns[self.pageIdx].img_Lable_Dark:setVisible(true)
        end
        self.pageIdx = idx   
        self.pageBtns[idx].img_Lable_Light:setVisible(true)  
        self.pageBtns[self.pageIdx].img_Lable_Dark:setVisible(false)  
        self:scrollView(idx)
    end
end

function AchievementDialog:scrollView( idx )
    self.scroll_bg1:setVisible(idx == pages.task)
    self.scroll1:setVisible(idx == pages.task)
    self.scroll_bg2:setVisible(idx == pages.achievement)
    self.scroll2:setVisible(idx == pages.achievement)

    if idx == pages.task then
        self:task()       
    else
        self:achievement()
    end 
end

function AchievementDialog:task( ... )
    if not self.taskLoaded then 
        self.taskLoaded = true
        local infos = self:initTaskInfos()
        self.scroll1:setLazyTableData(infos, Handler(self.taskCallCell, self), 0)
        self:vility()
    end
end

function AchievementDialog:initTaskInfos()
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
    return infos
end

function AchievementDialog:taskCallCell(cell, scroll, info)
    if not cell then
        cell = scroll:createItem(1)
        cell:loadViewsTo()
    end

    local taskinfo = info.taskinfos
    local dailyid = info.dailyid
    local context = GameLogic.getUserContext()

    cell.img_taskType.view:removeAllChildren()
    local s = cell.img_taskType:getContentSize()
    GameUI.addActiveImg(cell.img_taskType.view,taskinfo.duty_mode,s[1],s[2],s[1]/2,s[2]/2,0)

    cell.lb_titleTask:setString(Localize(""))
    cell.lb_taskDes:setString(Localizef(taskinfo.wkey or ("dailyTask"..taskinfo.duty_mode),{num=dailyid.duty_max,a=dailyid.duty_max}))
    
    local layout = cell.layout_res
    layout:removeAllChildren()
    for i,v in ipairs(taskinfo.rwds) do
        local rwdCell = layout:createItem(1)
        rwdCell:loadViewsTo()
        layout:addChild(rwdCell)
        rwdCell["img_resIcon"..i]:setVisible(true)
        rwdCell.lb_resNum:setString(N2S(v[3]))
    end

    local canGet = dailyid.state == 0 and dailyid.progres>= dailyid.duty_max
    local canGo = dailyid.state == 0 and dailyid.progres < dailyid.duty_max

    if canGet then
        cell.lb_get:setString(Localize("btnReceive"))
        cell.btn_task:setScriptCallback(ButtonHandler(function ()
            context.activeData:getDailyReward(dailyid.id,self)
            local vip = context:getInfoItem(const.InfoVIPlv)
            local userLv = context:getInfoItem(const.InfoLevel)
            local actId = dailyid.id
            GameLogic.addStatLog(11102,actId,vip,userLv)
        end))
        dailyid.progres = dailyid.duty_max
    elseif canGo then
        cell.lb_get:setString(Localize("buttonGo"))
        cell.btn_task:setScriptCallback(ButtonHandler(function ()
            local stime = self.btnActTime or 0
            local stime2 = socket.gettime()
            if stime2 - stime > 0.5 then
                self.btnActTime = stime2
            else
                return
            end
            GameLogic.doCondition(context, taskinfo.duty_mode)
        end))
    elseif dailyid.state > 0 then
        cell.lb_get:setString(Localize("labelAlreadyReceive"))
        dailyid.progres = dailyid.duty_max
    end

    cell.btn_task:setEnable(dailyid.state <= 0)
    cell.img_btnGet:setVisible(canGet or dailyid.state > 0)
    cell.img_btnGo:setVisible(canGo)
    cell.btn_task:setGray(dailyid.state > 0)

    cell.lb_taskProgress:setString(dailyid.progres.."/"..dailyid.duty_max)
    return cell
end

function AchievementDialog:achievement( ... )
    if not self.achievementLoaded then
        self.achievementLoaded = true
        local infos = self:initAchievementInfos()
        self.scroll2:setLazyTableData(infos, Handler(self.achievementCallCell, self), 0)
        self:vility()
    end
end

function AchievementDialog:initAchievementInfos()
    local ddata = GameLogic.getUserContext().achieveData.ddata
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

    return infos  
end

function AchievementDialog:achievementCallCell(cell, scroll, info)
    print("----------------achievementCallCell------------------------")
    if not cell then
        cell = scroll:createItem(1)
        cell:loadViewsTo()
    end

    local item = info.item
    cell:setEnable(false)
    local i=info.id

    if i == 1 then
        GameUI.addBuildHead(bg,item.tid,262,245,34+131,41+122,2,item.tlv)
    else
        GameUI.addActiveImg(bg,item.type+200,262,245,34+131,41+122,0)
    end

    cell.achieveName:setString(Localizef("dataAchieveName" .. i,{a = BU.getBuildName(item.tid), b = item.tlv}))
    -- if i == 1 then
    --     local aname = BU.getBuildName(item.tid)
    --     if item.tlv==1 then
    --         cell.lb_achievementDes:setString(Localizef("dataActiveDes201f0",{name=aname}) .. Localize("dataActiveDes201_" .. item.tid))
    --     else
    --         cell.lb_achievementDes:setString(Localizef("dataActiveDes201f1",{name=aname, level=item.tlv}) .. Localize("dataActiveDes201_" .. item.tid))
    --     end
    -- elseif i == 9 then
    --     cell.lb_achievementDes:setString(Localizef("dataActiveDes9",{num = item.tlv}))
    -- elseif i == 10 then
    --     cell.lb_achievementDes:setString(Localizef("dataActiveDes10_1",{num = item.tlv}))
    -- elseif i == 11 then
    --     cell.lb_achievementDes:setString(Localizef("dataActiveDes10_2",{num = item.tlv}))
    -- else
    --     cell.lb_achievementDes:setString(Localizef("dataActiveDes20" .. i,{a = item.tlv}))
    -- end

    cell.lb_progress:setString(item.glv .. "/" .. item.tlv)
    cell.process:setProcess(true,item.glv .. "/" .. item.tlv)

    local layout = cell.layout_achievementRes
     for i,v in ipairs(item.reward) do
        local rwdCell =layout:createItem(1)
        rwdCell:loadViewsTo()
        layout:addChild(rwdCell)
        rwdCell["img_resIcon"..i]:setVisible(true)
        rwdCell.lb_resNum:setString(N2S(v[3]))
    end

    cell.btn_achieveRwds:setScriptCallback(ButtonHandler(function()
        if info.id == 12 and item.isget == 0 and item.glv < item.tlv then
            local dialog = RenameDialog.new()
            dialog.priority = self.priority + 1
            display.showDialog(dialog)
            return
        end
        self:getachieve(item.id)
    end))
    if item.isget == 0 then
        if info.id == 12 and item.glv < item.tlv then
            -- self.labelCompleteNoSgin:setVisible(false)
            cell.processNum:setVisible(false)
            cell.processBack:setVisible(false)
            cell.process:setVisible(false)
            cell.btnReceiveText:setString(Localize("buttonGo"))
        elseif item.glv>=item.tlv then
            cell.labelCompleteNoSgin:setVisible(false)
            cell.processNum:setVisible(false)
            cell.processBack:setVisible(false)
            cell.process:setVisible(false)
            cell.btnReceiveText:setString(Localize("btnReceive"))
        else
            --完成
            cell.labelCompleteNoSgin:setVisible(false)
            cell.butReceive:setVisible(false)
        end
    else
        cell.butReceive:setVisible(false)
        cell.processNum:setVisible(false)
        cell.processBack:setVisible(false)
        cell.process:setVisible(false)
    end
    return cell
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

function AchievementDialog:vility( ... )
    -- 活跃度
    local context = GameLogic.getUserContext()
    local active = context:getAchsData()
    self.lb_dVitality:setString(Localizef("dailyActiveWord"))
    self.lb_dVitalityNum:setString(Localizef("dailyActive", {num = active[1][3]}))
    self.lb_wkVitality:setString(Localizef("weekActive", {num = active[2][3]}))

    self.dBoxState = {}   --日活跃度宝箱状态, 1不可领取 2可领但未领 3已领取
    local dRwds = SData.getData("activerwds", 1)
    local wRwds = SData.getData("activerwds", 2)
    local dailyData = active[1]

    local pro = active[1][3]/dRwds[5].active
    local av = active[1][3]
    local proD = {{dRwds[1].active, 16}, {dRwds[2].active, 36}, {dRwds[3].active, 56}, {dRwds[4].active, 76}, {dRwds[5].active, 100}}
    local lastD = {0,0}
    for i, d in ipairs(proD) do
        if d[1] >= av then
            -- pro = ((av - lastD[1])/(d[1]-lastD[1]) * (d[2] - lastD[2]) + lastD[2])/100
            break
        else
            lastD = d
        end
    end
    if pro > 1 then
        pro = 1
    end
    self.img_dVitalityProgress:setProcess(true,pro)

    -- 宝箱状态
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
    end

     -- 可不可领
    for i,v in ipairs(self.dBoxState) do
        local box = self["btn_box"..i]
        if v == 1 then 
            -- self["btn_box5"]:setVisible(true)
            -- self["btn_box5"]:setVisible(false)
        else
            self:frazeAction(box,v == 2)
        end
        self["btn_box"..i]:setScriptCallback(ButtonHandler(self.showDailyReward, self, i, 0))
        self["lb_vitalityNum"..i]:setString(dRwds[i].active)
    end  

    self.wkBoxState = {}   --周活跃度宝箱状态, 1不可领取 2可领但未领 3已领取
    local weekData = active[2]
    for i=1, KTLen(wRwds) do
        if bit.band(bit.lshift(1, i-1),  weekData[5]) > 0 then
            self.wkBoxState[i] = 3
        else
            if wRwds[i].active <= weekData[3] then
                self.wkBoxState[i] = 2
            else
                self.wkBoxState[i] = 1
            end
        end
    end

    for i,v in ipairs(self.wkBoxState) do
        if v == 1 then 
            -- self["btn_box5"]:setVisible(true)
            -- self["btn_box5"]:setVisible(false)
        else
            self:frazeAction(i,v == 2)
        end
        self["btn_wkBox"..i]:setScriptCallback(ButtonHandler(self.showDailyReward, self, i, 0))
        self["lb_canGetNum"..i]:setString(N2S(wRwds[i].active))
    end  
    GameEvent.bindEvent(self.view,"refreshAchievementDialogEveryday",self,self.task)
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

function AchievementDialog:frazeAction(box, state)
    box:stopAllActions()
    box:runAction(ui.action.rotateTo(0, 0))
    
    if state then
        local action = ui.action.arepeat(ui.action.easeSineIn(ui.action.sequence({
            {"delay",1},{"rotateBy",0.1,-30},{"rotateBy",0.1,30},{"rotateBy",0.1,30},{"rotateBy",0.1,-30}
            ,{"rotateBy",0.1,-15},{"rotateBy",0.1,15},{"rotateBy",0.1,15},{"rotateBy",0.1,-15}
            })))
        box:runAction(action)
    end
end

return AchievementDialog