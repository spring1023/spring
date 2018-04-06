-- Module ID：coz2_1
-- Depiction：通用活动标准模板
-- Author：Lion
-- Create Date：2017-3-14
local ViewTemplates = GMethod.loadScript("game.UI.dialog.ViewTemplates.Init")
local SData = GMethod.loadScript("data.StaticData")

ActivityLogic = {}

function ActivityLogic.checkActVisible(act)
    local context = GameLogic.getUserContext()
    if context.activeData:checkActState(act.actRealId or act.actId) ~= GameLogic.States.Close then
        if context.activeData:checkVisible(act.actRealId or act.actId, act) then
            return true
        end
    end
    return false
end

function ActivityLogic.menuActType(act)
    if act.actGroup then
        return act.actGroup
    elseif act.actExtends and not act.actTemplate then
        return 2
    elseif act.actType == 4 or act.actType == 55 then
        return 1
    end
end

-- function ActivityLogic.isTriggleAct(act)
--     if act.actExtends then
--         return true
--     end
--     return false
-- end

-- function ActivityLogic.isCarnivalAct(act)
--     if act.Carnival then
--         return true
--     end
--     return false
-- end

function ActivityLogic.checkActNew(actId, actData, setFlag)
    local actKey = "actSawTime" .. actId
    local kdata = 0
    -- 单独模板咋搞？
    if actData.actTemplate then
        actKey = "actSawTimeNew" .. actId
    end
    kdata = GEngine.getConfig(actKey)
    if type(kdata) ~= "number" then
        GEngine.setConfig(actKey, 0)
        kdata = 0
    end
    if actData.actStartTime and actData.actStartTime >= 1503849600 and actData.actStartTime >= kdata then
        if setFlag then
            if actData.actTemplate then
                GEngine.setConfig(actKey, actData.actStartTime+1, false)
            else
                GEngine.setConfig(actKey, actData.actStartTime+1, true)
                GEngine.saveConfig()
            end
        end
        return true
    end
    return false
end

function ActivityLogic.loadPageViewTemplates(bgView, dialog, viewLayout, templates)
    local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
    local tempLayout
    if not templates then
        return
    end
    local myRwd = dialog.context.activeData:getConfigableRwds(dialog.actId, dialog.pageId)
    local got = dialog.context.activeData:getActRwd(dialog.actId, myRwd.rwdId)[1]
    local cumNum = dialog.context.activeData:getActRecord(dialog.actId, myRwd.conditions[1][1])[1]--条件1的次数
    local gota = cumNum
    local condiNumTwo = myRwd.conditions[1][2]
    if myRwd.conditions[2] and myRwd.conditions[2][1] == const.ActTypeContinuousBuy then
        --当有第二个条件，并且第二个条件为连续充值的时候，获取连续充值多少次(天)
        gota = dialog.context.activeData:getActRecord(dialog.actId, myRwd.conditions[2][1])[1]
    end
    local gotMax = myRwd.max or 1
    local drecord = dialog.context.activeData:getActRecord(dialog.actId, const.ActTypePurchase)[1]
    --刮刮卡
    if templates.specialTemplate then
        tempLayout = dialog:addLayout(_allTemplates["templateScratch"..templates.specialTemplate], dialog.nodePageView.view)
        tempLayout:loadViewsTo(viewLayout)
        local index = dialog.context.activeData:getActRecord(dialog.actId, const.ActTypeScratch)[1]+1
        dialog:initScratch(index)
    end

    if templates.rotaryTableTemplate then
        local context = GameLogic.getUserContext()
        local vip = context:getInfoItem(const.InfoVIPlv)
        local userLv = context:getInfoItem(const.InfoLevel)
        GameLogic.addStatLog(31001,vip,userLv,1)
        tempLayout = dialog:addLayout(_allTemplates["templateRotaryTable"..templates.rotaryTableTemplate], dialog.nodePageView.view)
        tempLayout:loadViewsTo(viewLayout)
        local items = myRwd
        dialog:initRotary(viewLayout,items)
    end

    if templates.layout then
        local layoutSetting = _allTemplates["templateLayout" .. templates.layout]
        if not layoutSetting then
            layoutSetting = GMethod.loadConfig("configs/ui/templates/layout" .. templates.layout .. ".json").views[1].views
        end
        tempLayout = dialog:addLayout(layoutSetting, bgView)
        tempLayout:loadViewsTo(viewLayout)
        -- 这里加一些特殊活动的逻辑
        -- 如果是推广码类型
        if viewLayout.nodeSpecialSpreadList then
            if Native.pasteBoardString then
                viewLayout.btnSpecialCopy:setScriptCallback(ButtonHandler(GameLogic.doCopyPaste))
            else
                viewLayout.btnSpecialCopy:setVisible(false)
            end
            local function share()
                GameLogic.doShare("code")
                if dialog.actId == 201712073 then
                    GameLogic.addStatLog(11616, GameLogic.getLanguageType(), 1, 1)
                end
            end
            viewLayout.btnSpecialShare:setScriptCallback(share)
            viewLayout.btnSpecialReward:setScriptCallback(ButtonHandler(display.showDialog, GemPoolDialog))
            viewLayout.InviteValue:setString(GameLogic.getTCodeString())
            local infos = GameLogic.getSpreadAndRewardData()
            viewLayout.nodeSpecialSpreadList:setLazyTableData(infos, Handler(dialog.onUpdateCellSpread, dialog), 0)
        elseif viewLayout.nodeSpecialSpreadList2 then
            local spreadRewards = SData.getData("spreadCodeRewards")[0].rwds
            viewLayout.nodeSpecialSpreadList2:setLazyTableData(spreadRewards, Handler(dialog.onUpdateNormalItem, dialog), 0)

            -- 输入框
            local node = ui.textBox(viewLayout.inputNodeBack.size, Localize("labelInputPlaceHolder"),
            General.font6, 55, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
            display.adapt(node, 0, 0, GConst.Anchor.LeftBottom)
            viewLayout.inputNodeBack:addChild(node)
            viewLayout.inputNodeBack.textBox = node
            -- 按钮
            viewLayout.butReceive:setScriptCallback(ButtonHandler(dialog.onSendSpreadCode, dialog))
            dialog:refreshSpreadCodeState()
        end
    end

    if templates.titleBg then
        local path = templates.titleBg.path
        dialog.titleBg:setImage(path)
    end

    if templates.title then
        dialog.title:setString(Localizef(templates.title.key or ("titleName" .. dialog.actId), {a=got, b=gotMax}))
        if templates.title.color then
            ui.setColor(dialog.title, templates.title.color)
        end
    elseif not dialog.act.actTemplate then
        dialog.title:setString("")
    end

    if dialog.btnQuestion then
        if templates.question then
            dialog.btnQuestion:setScriptCallback(HelpDialog.new, templates.question)
            dialog.btnQuestion:setVisible(true)
        else
            dialog.btnQuestion:setVisible(false)
        end
    end

    if templates.percent then
        tempLayout = dialog:addLayout(_allTemplates["templatePercent" .. (templates.percent.type or 1)], bgView)
        tempLayout:loadViewsTo(viewLayout)
        if type(templates.percent.value) == "number" then
            viewLayout.labelPercentNum:setString(templates.percent.value .. "%")
        else
            viewLayout.labelPercentNum:setString(tostring(templates.percent.value))
        end
    end
    if templates.items then
        if not viewLayout.nodeTableView then
            tempLayout = dialog:addLayout(_allTemplates["templateItems" .. (templates.items.type or 1)], bgView)
            tempLayout:loadViewsTo(viewLayout)
        end
        -- 区分是列出所有奖励或者列出奖励物品，1表示物品
        if (templates.items.valueType or 1) == 1 then
            local infos = {}
            for i, item in KTIPairs(myRwd.items) do
                infos[i] = {idx=i, item=item}
            end
            viewLayout.nodeTableView:loadTableView(infos, Handler(dialog["onUpdateCell" .. (templates.items.cellType or 1)], dialog))
        else
            dialog:reloadScrollList()
        end
    -- 只有一个奖励的类型
    elseif viewLayout.singleRewardNode then
        local info = myRwd.items[1]
        GameUI.registerTipsAction(viewLayout.singleRewardNode, dialog.view, info[1], info[2])

        viewLayout.singleIcon:removeAllChildren(true)
        local size = viewLayout.singleIcon.size
        GameUI.addItemIcon(viewLayout.singleIcon, info[1], info[2], size[1]/200, size[1]/2, size[2]/2, true)

        viewLayout.singleNumberLabel:setString(tostring(info[3]))
    end
    if templates.action then
        local state = dialog.context.activeData:checkActRewardState(dialog.actId, dialog.pageId)
        local btype = templates.action.type or 1
        if state == GameLogic.States.Close then
            -- 是否应该显示已领取
        else
            if state == GameLogic.States.Finished and (btype==1 or btype==2 or btype==11 or btype==13) then
                btype = 1
            end
            tempLayout = dialog:addLayout(_allTemplates["templateBtns" .. btype], bgView)
            tempLayout:loadViewsTo(viewLayout)
            if viewLayout.btnReward then
                if myRwd.needTip then
                    viewLayout.btnReward:setScriptCallback(ButtonHandler(function ()
                                display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"), Localizef("alertTitleUnlockPrestige",{num = myRwd.costs[1][3],str = Localize("dataResName4"),stra = Localize("actName170416")}),{cvalue = myRwd.costs[1][3],ctype = myRwd.costs[1][2],yesBut="btnYes",callback = function()
                                        dialog:onAction({idx=dialog.pageId})
                                end}))
                    end,dialog))
                else
                    viewLayout.btnReward:setScriptCallback(ButtonHandler(dialog.onAction, dialog, {idx=dialog.pageId}))
                end
                -- if self.hv then
                --     viewLayout.btnRewardBack.view:setHValue(self.hv)
                -- end
                if state == GameLogic.States.Finished or (myRwd.atype == const.ActActionSpecial and dialog.context.activeData:getSpecialNum(dialog.actId, myRwd) > 0) then
                    viewLayout.btnRewardText:setString(Localize("btnReceive"))
                elseif templates.action.key then
                    viewLayout.btnRewardText:setString(Localize(myPage.action.key))
                elseif myRwd.atype == const.ActActionExchange then
                    if viewLayout.buttonGoBuy then
                        GameUI.addResourceIcon(viewLayout.nodeResIcon.view, myRwd.costs[1][2], 0.9, 0, 15)
                        viewLayout.labelResText:setString(tostring(myRwd.costs[1][3]))
                    else
                        GameUI.addResourceIcon(viewLayout.nodeCostIcon.view, myRwd.costs[1][2], 0.4, 33, 33)
                        viewLayout.btnRewardText:setString(tostring(myRwd.costs[1][3]))
                    end
                elseif myRwd.atype == const.ActActionBuy then
                    viewLayout.btnRewardText:setString(Plugins.storeItems[Plugins.storeKeys[myRwd.goodsid]])
                    if GameLogic.purchaseLock or dialog.context.activeData:checkPurchaseLimit(dialog.actId, dialog.pageId) then
                        viewLayout.btnReward:setGray(true)
                    end
                elseif myRwd.conditions[1][1] == const.ActTypeLeagueMC then
                    viewLayout.btnRewardText:setString(Localize("labelGotoTopUp"))
                elseif myRwd.atype == const.ActActionAuto then
                    viewLayout.btnRewardText:setString(Localize("labelAffirm"))
                elseif myRwd.atype == const.ActActionShare then
                    viewLayout.btnRewardText:setString(Localize("btnShare"))
                else
                    viewLayout.btnRewardText:setString(Localize("labelGo"))
                    if viewLayout.btnRewardBack then
                        viewLayout.btnRewardBack.view:setHValue(114)
                    end
                end
            end
        end
    end
    if templates.btnRefactor then
        --考虑到有些but是特殊的，譬如月卡按钮，以后可能也会有很多不一样的，所以特殊处理一下
        --只有在领取的时候有些不同规则，其他前往没有做重构
        for k, v in pairs(templates.btnRefactor) do
            if viewLayout[k] then
                local vaction = v
                if type(v) == "table" then
                    vaction = v.action
                    if v.key then
                        viewLayout[k .. "Text"]:setString(Localize(v.key))
                    end
                end
                if vaction == "reward" then
                    --礼品码已移至设置页面
                    -- if v.actId and v.actId == 2017071201 then
                    --     dialog:updateGiftCodeUI(viewLayout)
                    if v.actId and v.actId == 20170712 then
                        dialog:checkCard(viewLayout, viewLayout[k])
                    elseif v.keyQuestion then
                        viewLayout[k]:setScriptCallback(ButtonHandler(HelpDialog.new, v.keyQuestion))
                    elseif v.urlType then
                        --跳转链接都走这里的逻辑
                        --v.urlType[1]:区分跳链接后是否有奖励(0:无奖励, 1:有奖励)
                        --v.urlType[2]:链接类型(1:单纯跳链接, 2:前往应用商店评价, 3:分享推广)
                        --v.urlType[3]:链接
                        local urlRwd = v.urlType[1] < 1 and nil or myRwd
                        dialog:openUrlAndAction(viewLayout[k], urlRwd, v.urlType)
                    end
                end
            end
        end
    end
    -- 所有逻辑通过模板进行配置，而不是走默认逻辑
    if templates.actions then
        for k, v in pairs(templates.actions) do
            if viewLayout[k] then
                local vaction = v
                if type(v) == "table" then
                    vaction = v.action
                    if v.key then
                        viewLayout[k .. "Text"]:setString(Localize(v.key))
                    end
                end
                if vaction == "go" then
                    local function go()
                        GameLogic.doCondition(dialog.context, myRwd.conditions[1][1], nil, dialog.actId)
                    end
                    viewLayout[k]:setScriptCallback(go)
                elseif vaction == "reward" then
                    viewLayout[k]:setScriptCallback(ButtonHandler(dialog.onAction, dialog, {idx=dialog.pageId}))
                    if dialog.context.activeData:getSpecialNum(dialog.actId, myRwd) <= 0 then
                        viewLayout[k]:setGray(true)
                        viewLayout[k]:setEnable(false)
                    end
                elseif vaction == "rank" then
                    local rankActId = type(v) == "table" and v.actId or dialog.actId
                    local act = dialog.context.activeData:getConfigableActs()[rankActId]
                    if act and ActivityLogic.checkActVisible(act) then
                        viewLayout[k]:setVisible(true)
                        viewLayout[k]:setScriptCallback(ButtonHandler(function()
                            AllRankingListDialog.new(6, rankActId)
                        end))
                    else
                        viewLayout[k]:setVisible(false)
                    end
                    if viewLayout["labelMyRank"] then
                        if act.actRank then
                            viewLayout["labelMyRank"]:setString(Localize("labelMyRanking") .. act.actRank)
                        else
                            --异步加？
                            local uid = GameLogic.getUserContext().uid
                            local sid = GameLogic.getUserContext().sid
                            local param={
                                mode = "ActRank" .. sid .. "_" .. act.actId .. "_" .. act.actRankIdx,
                                grm = "actrk" .. sid .. "_" .. act.actId .. "_" .. act.actRankIdx,
                                uid = uid, num=1
                            }
                            GameNetwork.request("getRankData", param, function(suc, datas)
                                if not suc then
                                    return
                                end
                                for i=1,#datas do
                                    if datas[i][6] == uid then
                                        act.actRank = datas[i][1]
                                        if not dialog.deleted and dialog.pageViewLayout and dialog.pageViewLayout.labelMyRank then
                                            dialog.pageViewLayout.labelMyRank:setString(Localize("labelMyRanking") .. act.actRank)
                                        end
                                    end
                                end
                            end)
                        end
                    end
                else
                    viewLayout[k]:setScriptCallback(ButtonHandler(GameLogic.doCondition, dialog.context, vaction))
                end
            end
        end
    end
    if templates.richViews then
        for k, v in pairs(templates.richViews) do
            if viewLayout[k] then
                local infos = {{viewLayouts=v}}
                local tableView = viewLayout[k]:loadTableView({}, Handler(dialog.onUpdateRichView, dialog, viewLayout))
                tableView.cellSetting.sizeChange = true
                tableView.cellSetting.infos = infos
                tableView:setDatas(tableView.cellSetting)
                tableView:prepare()
                viewLayout[k]._actTableView = tableView
            end
        end
    end
    if templates.texts then
        for k, v in pairs(templates.texts) do
            if viewLayout[k] then
                if type(v) == "table" then
                    if v.color then
                        ui.setColor(viewLayout[k], v.color)
                    end
                    if v.key then
                        viewLayout[k]:setString(Localizef(v.key, {a=got, b=gotMax, c=gotMax-got, dnum=drecord,enum=myRwd.costs[1][3],anum = gota,bnum = cumNum,f=condiNumTwo}))
                    end
                else
                    viewLayout[k]:setString(Localizef(tostring(v), {a=got, b=gotMax, c=gotMax-got, dnum=drecord,enum=myRwd.items[1][3],anum = gota,bnum = cumNum,f=condiNumTwo}))
                end
            end
        end
    end
    if templates.actEndTime then
        if viewLayout.labelLeftTime and not dialog.act.actTemplate then
            if templates.actEndTime <=0 then
                viewLayout.labelLeftTime:setVisible(false)
            else
                RegActionUpdate(viewLayout.labelLeftTime.view, Handler(dialog.updateLeftTime, dialog, viewLayout.labelLeftTime, templates), 0.2)
                dialog:updateLeftTime(viewLayout.labelLeftTime, templates)
            end
        end
    else
        if viewLayout.labelLeftTime and not dialog.act.actTemplate then
            if dialog.act.actEndTime <=0 then
                viewLayout.labelLeftTime:setVisible(false)
            else
                RegActionUpdate(viewLayout.labelLeftTime.view, Handler(dialog.updateLeftTime, dialog, viewLayout.labelLeftTime, dialog.act), 0.2)
                dialog:updateLeftTime(viewLayout.labelLeftTime, dialog.act)
            end
        end
    end
    if templates.richViews then
        for k, v in pairs(templates.richViews) do
            if viewLayout[k] then
                local tableView = viewLayout[k]._actTableView
                dialog:onUpdateRichView(viewLayout, tableView.cellSetting.infos[1].view, tableView, tableView.cellSetting.infos[1])
                local h = viewLayout[k].size[2]
                local h2 = tableView.cellSetting.infos[1].view:getContentSize().height + 40
                if h2 > h then
                    h = h2
                end
                tableView.view:setScrollContentRect(cc.rect(0,viewLayout[k].size[2]-h,viewLayout[k].size[1],h))
            end
        end
    end
end

ActivityListDialog = class(DialogViewLayout2)
-- 加载父文本滚动框的内容（单个scrollNode，手动设置每个cell大小）
function ActivityListDialog:onUpdateRichView(viewLayout, cell, tableView, info)
    --公告站走这里
    if not info.view then
        info.view = cell
        local tmpView = ui.node()
        info.layout = self:addLayout(info.viewLayouts, tmpView)
        info.layout:loadViewsTo(viewLayout)
        cell:addChild(tmpView)
        info._realBg = tmpView
    end
    local item = viewLayout.lastItem
    local w, oh = cell:getContentSize().width, cell:getContentSize().height
    local x, y = item:getPosition()
    local h = -(y - item.size[2])
    -- 如果有父节点表示刷新了高度
    if cell:getParent() then
        cell:setPositionY(cell:getPositionY() + (oh - h) / 2)
        tableView.items[1].length = h
        -- {off = off, length = length, endoff = endoff, view = node}
    end
    cell:setContentSize(cc.size(w, h))
    display.adapt(info._realBg, 0, h)
end

function ActivityListDialog:onInitDialog()
    local act, layouts, templates
    -- 获取所有活动并筛选出需要显示在该界面的类型;actType为4的显示在该界面
    local context = self.context
    local actType = self.actType or 4
    -- if actType == 5 then
    --     GEngine.setConfig(tostring("myTriggle2_"..context.uid), 0, true)
    --     GEngine.saveConfig()
    -- end

    local allActs = context.activeData:getConfigableActs()
    local acts = {}
    local stime = GameLogic.getSTime()
    local menuActType = self.menuActType or 1
    if self.actId then
        menuActType = ActivityLogic.menuActType(allActs[self.actId])
        self.menuActType = menuActType
    end
    for aid, act in pairs(allActs) do
        if ActivityLogic.checkActVisible(act) or (act.actPreTime and act.actPreTime <= stime and act.actStartTime > stime) then
            if (menuActType and menuActType == ActivityLogic.menuActType(act)) or aid == self.actId then
                table.insert(acts, {actId=aid, actData=act, __order=act.actOrder or 10000, selected=false})
            end
        end
    end
    -- 如果没有可显示的活动，进入该界面应该是不可能的
    if #acts == 0 then
        self.deleted = true
        return
    end
    -- 排序，并选择对应的活动
    GameLogic.mySort(acts, "__order")
    local defaultActId = self.actId
    local defaultActIdx = 1
    if not defaultActId then
        defaultActId = acts[1].actId
    end
    self.actId = nil
    for idx, act in ipairs(acts) do
        act.idx = idx
        if act.actId == defaultActId then
            defaultActIdx = idx
        end
    end
    self.actInfos = acts

    local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
    -- 如果只有1个是不是就不要左边了比较好？
    if #acts == 1 then
        self:setLayout(_allTemplates["ActivitySingleListDialog"])
        self.view:setScale(1)
        self.view:setContentSize(cc.size(2057, 1280))
        display.adapt(self.view, 0, 0, GConst.Anchor.Center, {scaleType=GConst.Scale.Dialog})
        self.view:setContentSize(cc.size(1721, 1280))
    else
        self:setLayout(_allTemplates["ActivityListDialog"])
    end
    self:loadViewsTo()
    self.btnQuestion:setScriptCallback(ButtonHandler(self.onQuestion, self))
    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.title:setString("")

    if self.nodeActsTable then
        self.nodeActsTableView = self.nodeActsTable:loadTableView(acts, Handler(self.onUpdateLeftAct, self))
        if defaultActIdx > 1 then
            self.nodeActsTableView.view:moveAndScaleToCenter(1, 156, 1225-defaultActIdx*251, 0.01)
        end
    end
    if self.menuActType == 3 then--嘉年华入口埋点
        GameLogic.addStatLog(11601, GameLogic.getLanguageType(), 1, 1)
    elseif self.menuActType == 5 then--长线入口埋点
        GameLogic.addStatLog(11608, GameLogic.getLanguageType(), 1, 1)
    end
    self:chooseAct(defaultActIdx)

    local bNode=ui.node()
    self.view:addChild(bNode)
    GameEvent.bindEvent(bNode,"refreshEggDialog", self, self.refreshMyDialog)
end

function ActivityListDialog:onEnter()

end

--侧边滚动条
function ActivityListDialog:onUpdateLeftAct(cell, scrollView, info)
    if not info.viewLayout then
        local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
        info.viewLayout = self:addLayout(_allTemplates["ActivityListCell"], cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        info.view = cell
        cell:setScriptCallback(ButtonHandler(self.chooseAct, self, info.idx))
        info.redNum = GameUI.addRedNum(info.view:getDrawNode(), 10,120,0,0.8,10000)
    end
    if info.selected then
        info.imgSelected:setVisible(true)
        --ui.setColor(info.imgActBack, {255,242,213})
        info.imgActBack:setVisible(false)
    else
        info.imgSelected:setVisible(false)
        --ui.setColor(info.imgActBack, {81,186,231})
        info.imgActBack:setVisible(true)
    end
    info.curNum = GameLogic.getUserContext().activeData:getRedNum(info.actId)
    info.redNum:setNum(info.curNum)
    info.nodeNew:setVisible(ActivityLogic.checkActNew(info.actId, info.actData))
    if info.displayActId ~= info.actId then
        info.displayActId = info.actId
        info.labelActLeftTitle:setString(Localize(info.actData.menuName or info.actData.actLeftTitle or info.actData.actTitle or ("actName" .. info.actId)))
        --info.nodeActImg:removeAllChildren(true)
        -- local icons = info.actData.actLeftIcons
        -- if not icons then
        --     icons = {{name=info.actData.menuIcon or ("images/otherIcon/iconActivity".. info.actId ..".png"), size=info.actData.menuIconSize}}
        -- end
        -- for _, icon in ipairs(icons) do
        --     local temp = ui.sprite(icon.name, icon.size or {200,200}, true)
        --     display.adapt(temp, icon.x or 0, icon.y or 0, GConst.Anchor.Center)
        --     info.nodeActImg:addChild(temp, icon.z or 0)
        -- end
    end
end

--这里是点击左侧选择活动页面
function ActivityListDialog:chooseAct(idx)
    --在左侧列表中的位置
    local act = self.actInfos[idx]
    if not act then
        return
    end
    --self.actInfos[idx]里面存储活动的属性
    if act.actId ~= self.actId then
        if self.selectedInfo then
            self.selectedInfo.selected = false
            self:onUpdateLeftAct(self.selectedInfo.view, self.nodeActsTableView, self.selectedInfo)
        end
        -- 支持一下转盘的奖励显示
        if self.rotaryLayout then
            self:refreshRotaryData()
            self.rotaryLayout = nil
        end
        self.selectedInfo = act
        self.selectedInfo.selected = true
        if self.selectedInfo.view then
            self:onUpdateLeftAct(self.selectedInfo.view, self.nodeActsTableView, self.selectedInfo)
        end
        self.actId = act.actId
        self.act = act.actData
        if self.actId == 2017072601 then
            GameLogic.addStatLog(21002, 1, 0, 0)
        end
        self.pageId = 1
        self:reloadPageView()
        if act.actData and act.actData.actExtends then
            local context = GameLogic.getUserContext()
            local vip = context:getInfoItem(const.InfoVIPlv)
            local userLv = context:getInfoItem(const.InfoLevel)
            GameLogic.addStatLog(11302,vip,userLv,act.actId)
        end
        if act.nodeNew then
            act.nodeNew:setVisible(false)
        end
        ActivityLogic.checkActNew(act.actId, act.actData, true)
    end
end


--刷新翻页滑动框的处理
function ActivityListDialog:reloadPageView()
    self.nodePageView:removeAllChildren(true)
    --活动的属性
    local act = self.act
    local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
    local tempLayout
    local templates = act.viewTemplates
    local scNode = ui.scrollNode(self.nodePageView.size, 5, false, false, {clip=true})
    display.adapt(scNode, 0, 0, GConst.Anchor.LeftBottom)
    self.nodePageView.view:addChild(scNode)
    local clipBg = scNode:getScrollNode()

    self.pageViewLayout = self:addLayout(act.viewLayouts, clipBg)
    self.pageViewLayout:loadViewsTo()

    ActivityLogic.loadPageViewTemplates(clipBg, self, self.pageViewLayout, templates)

    --处理pages
    if act.pageTitles or act.pages then
        local newLayout = self:addLayout(_allTemplates["templatePages"..(act.pagesNum or 2)], self.nodePageView.view)
        newLayout:loadViewsTo(self.pageViewLayout)
        if act.pageTitles then
            --这里是整合了公告类型模板，标记是pageTitles
            self:initPageTitles(act)
        elseif act.pages then
            --这里是之前翻页模板
            self:initPageTurning(act)
        end
    end
end


function ActivityListDialog:initPageTurning(acts)
    local act = acts
    local pagePoints = {}
    local temp
    local pageInfos = {}
    for i, v in ipairs(act.pages) do
        if self.context.activeData:checkVisible(act.actId, v) then
            table.insert(pageInfos, {idx=i, page=v})
        end
    end
    self._pageInfos = pageInfos
    self._pageInfoId = 1
    for i, _ in ipairs(pageInfos) do
        temp = ui.sprite("images/switchDot.png",{41,41})
        display.adapt(temp,(i-1)*64-200, 0, GConst.Anchor.Center)
        self.pageViewLayout.nodePagePoints:addChild(temp)
        pagePoints[i] = temp
    end
    self.pageViewLayout.pagePoints = pagePoints
    self.pageViewLayout.btnNext:setScriptCallback(ButtonHandler(self.onPageChange, self, 1))
    self.pageViewLayout.btnPrevious:setScriptCallback(ButtonHandler(self.onPageChange, self, -1))
    self:onPageChange(0)
end

function ActivityListDialog:initPageTitles(acts)
    local act = acts
    local infos = {}
    self.pageBtnBg = nil
    self.pagesBtnNum = act.pagesBtn or 20170710
    local _tmap = {}
    if act.pagesItemType then
        for k,v in ipairs(act.pagesItemType) do
            _tmap[k] = v
        end
    end
    for k,v in ipairs(act.pages) do
        if self:checkVisible(v.actStartTime,v.actEndTime) and self.context.activeData:checkVisible(act.actId, v) then
            table.insert(infos,{pageItem = _tmap[k] or {}, actOrder = v.actOrder, idx = k, title = act.pageTitles[k]})
        end
    end
    table.sort(infos, function (a,b)
        return a.actOrder < b.actOrder
    end )
    local idx = 1
    if self.pageViewLayout.progressbarUp then
        local _count = #infos
        local num = self.context.activeData:getActRecord(self.actId, 4003)[1]
        self.pageViewLayout.progressbarUp:setProcess(true,num/_count)
        if num >= 0 and num< _count then
            num = num+1
        end
        idx = num
    end
    local nodeView = self.pageViewLayout.nodeTableView:loadTableView(infos,Handler(self.updateInstructionCell,self))
    if act.scrollElastic~=nil and not act.scrollElastic then
        nodeView.view:setElastic(false)
    end
    self:onPageChangeCallback(infos[idx],true)
end

function ActivityListDialog:updateInstructionCell(cell, tableView, info)
    if not info.viewLayout then
        local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
        info.viewLayout = self:addLayout(_allTemplates["templateBtns"..self.pagesBtnNum],cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        self:updateInstructionCellUI(info)
    end
end

function ActivityListDialog:updateInstructionCellUI(info)
    -- body
    local btnNode
    if info.btnLabel then
        info.btnLabel:setString(Localize(info.title))
    end
    if info.btnInstruction then
        if not GameLogic.isEmptyTable(info.pageItem) then
            --头像七日登录
            info.isSelectBtn = true
            if info.pageItem.iType == const.ItemHero then
                local _scale = 1.0
                if info.idx==2 or info.idx==7 then
                    _scale = 1.2
                end
                GameUI.addPlayHead(info.btnInstruction,{viplv=nil,id=info.pageItem.iId,scale=_scale,x=100,y=110,z=1,noBut = true,anchor="Center",blackBack = false})
            else
                --加个圈
                local bk = ui.sprite("images/iconBack1_2.png")
                display.adapt(bk,105,100,GConst.Anchor.Center)
                info.btnInstruction:addChild(bk)
                local _scale = 0.8
                if info.idx==2 or info.idx==7 then
                    _scale = 0.96
                end
                bk:setScale(_scale*1.25)
                GameUI.addItemIcon(info.btnInstruction, info.pageItem.iType, info.pageItem.iId, _scale*0.9, 100, 110)
            end
        end
        info.btnInstruction:setScriptCallback(ButtonHandler(self.onPageChangeCallback,self,info,false))
        info.btnInstruction.view:setTouchThrowProperty(true,true)
    end
    if info.btnLabelNode then
        info.btnLabelNode:setVisible(false)
        local act = self.context.activeData:getConfigableActs()[self.actId]
        if self.context.activeData:checkVisible(self.actId, act) then
            local state = self.context.activeData:checkActRewardState(self.actId, info.idx)
            if state == GameLogic.States.Close then
                info.btnLabelNode:setVisible(true)
            end
        end
    end
end

function ActivityListDialog:checkVisible(sTime,eTime)
    if sTime and eTime then
        return sTime <= GameLogic.getSTime() and  (eTime==0 or (eTime > GameLogic.getSTime())) or false
    end
    return false
end

function ActivityListDialog:onPageChangeCallback(info,isOne)
   if isOne or self.pageId ~= info.idx then
        --因为这里之前page是从1开始的，为了兼容也为了现在可以重用，所以这种pages下用isOne作为标识
        self.pageId = info.idx
        if self.pageBtnBg then
            self.pageBtnBg:removeFromParent(true)
        end
        local size = info.btnInstruction.view:getContentSize()
        local chosed = ui.sprite("images/acts/actBtnOrange.png",{size.width,size.height})
        display.adapt(chosed, 0, 0, GConst.Anchor.LeftBottom)
        info.btnInstruction:addChild(chosed, 0)
        self.pageBtnBg = chosed
        if info.isSelectBtn then
            chosed:setVisible(false)
            self.pageBtnBg:setVisible(false)
        end
        self:reloadSubPage()
   end
end

--翻页滑动框的切换页面
function ActivityListDialog:onPageChange(dir)
    local m1 = 1
    local m2 = KTLen(self._pageInfos)
    local m3 = self._pageInfoId + dir
    if m3 <= m1 then
        m3 = m1
    end
    if m3 >= m2 then
        m3 = m2
    end
    if self.pageViewLayout.pagePoints then
        self.pageViewLayout.btnPreviousImg:setVisible(m3 > m1)
        self.pageViewLayout.btnNextImg:setVisible(m3 < m2)
        for i, view in ipairs(self.pageViewLayout.pagePoints) do
            if i == m3 then
                view:setSValue(0)
                view:setScale(1)
            else
                view:setSValue(-100)
                view:setScale(34/41)
            end
        end
    end
    if dir == 0 or self._pageInfoId ~= m3 then
        self._pageInfoId = m3
        self.pageId = self._pageInfos[self._pageInfoId].idx
        self:reloadSubPage()
    end
end

function ActivityListDialog:reloadSubPage()
    self.pageViewLayout.nodeSubPageView:removeAllChildren(true)
    local act = self.act
    local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")

    local page = act.pages[self.pageId]
    local pageViewLayout = self:addLayout(page.viewLayouts, self.pageViewLayout.nodeSubPageView.view)
    pageViewLayout:loadViewsTo()
    self.pageViewLayout.subPageLayout = pageViewLayout
   -- dump(page)
    ActivityLogic.loadPageViewTemplates(self.pageViewLayout.nodeSubPageView.view, self, pageViewLayout, page)
end


--时间都是这么整体刷新的
function ActivityListDialog:updateLeftTime(label, act)
    local stime = GameLogic.getSTime()
    if label then
        if act.actStartTime > stime then
            label:setString(Localize("labelTimeCount") .. Localizet(act.actStartTime-stime))
        else
            label:setString(Localize("labelTimeCount") .. Localizet(act.actEndTime-stime))
        end
    end
end

function ActivityListDialog:onUpdateItemInner(cell, tableView, info)
    local view = cell:getDrawNode()
    view:removeAllChildren(true)
    local cellSize = cell:getContentSize()
    GameUI.addItemIcon(view,info[1],info[2],cellSize.height/230,cellSize.width/2,cellSize.height/2,true,false)
    local bNum=ui.label("X"..info[3], General.font1, math.ceil(36*cellSize.height/230), {color={255,255,255}})
    display.adapt(bNum, cellSize.width/2+90*cellSize.height/230, 40*cellSize.height/230, GConst.Anchor.Right)
    view:addChild(bNum)
    GameUI.registerTipsAction(cell, self.view, info[1], info[2])
end

function ActivityListDialog:onUpdateExchangeCell(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(info.type or 1)
        reuseCell:loadViewsTo()
    end
    if info.type == 1 then
        GameUI.setNormalIcon(reuseCell.itemIcon, info.item)
        GameUI.registerTipsAction(reuseCell.itemIcon, self.view, info.item[1], info.item[2])
        reuseCell.labelNum:setString(Localizef("labelFormatX", {num=info.item[3]}))
    end
    return reuseCell
end

--获取物品信息
function ActivityListDialog:onUpdateNewCell0(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
    end
    local rwd = self.context.activeData:getConfigableRwds(self.actId, info.idx)

    local condition = rwd.conditions[1]
    local b = rwd.max
    local a = self.context.activeData:getActRwd(self.actId, self.act.rwds[info.idx])[1]
    if a > b then
        a = b
    end
    local c = b - a
    local tipKey = info.page.key or ("activeTips" .. self.actId .. "_" .. info.idx)
    reuseCell.activeTips:setString(Localizef(tipKey, {a=a, b=b, c=c}))

    local resOk = true
    -- reuseCell.ScrollView2:clearAll()

    -- 带左边百分比的版本
    if reuseCell.itemIconLeft then
        local costItem = rwd.costs[1]
        local oldPrice = costItem[3]
        if rwd.percent then
            reuseCell.nodePercent:setVisible(true)
            reuseCell.labelPercent:setString("+" .. (rwd.percent-100) .. "%")
            oldPrice = math.floor(oldPrice * rwd.percent / 100 + 0.5)
        elseif rwd.discount then
            reuseCell.nodePercent:setVisible(true)
            reuseCell.labelPercent:setString(Localizef("labelSaleOff", {percent=100-rwd.discount}))
            oldPrice = math.floor(oldPrice * 100 / rwd.discount + 0.5)
        else
            reuseCell.nodePercent:setVisible(false)
        end
        GameUI.setNormalIcon(reuseCell.itemIconLeft, costItem)
        GameUI.registerTipsAction(reuseCell.itemIconLeft, self.view, costItem[1], costItem[2])
        reuseCell.labelLeftPrice:setString(tostring(oldPrice))
        reuseCell.labelRightPrice:setString(tostring(costItem[3]))
        GameUI.addRedLine(reuseCell.nodeLeftPrice, true)

        resOk = (GameLogic.getItemNum(costItem[1], costItem[2]) >= costItem[3])
        local exinfos = {}
        for i, item in ipairs(rwd.items) do
            if i > 1 then
                table.insert(exinfos, {type=2})
            end
            table.insert(exinfos, {type=1, item=item})
        end
        reuseCell.ScrollView2:setBusyTableData(exinfos, Handler(self.onUpdateExchangeCell, self))
    else
        reuseCell.ScrollView2:clearAll()
        local exinfos = {}
        for i, item in ipairs(rwd.items) do
            if i > 1 then
                table.insert(exinfos, {type=4})
            end
            table.insert(exinfos, {type=3, item=item})
        end
        table.insert(exinfos, {type=2})
        for i, cost in ipairs(rwd.costs) do
            if i > 1 then
                table.insert(exinfos, {type=4})
            end
            table.insert(exinfos, {type=1, item=cost})
        end
        for _, extItem in ipairs(exinfos) do
            local newItem = reuseCell.ScrollView2:createItem(extItem.type)
            newItem:loadViewsTo()
            reuseCell.ScrollView2:addChild(newItem)
            --添加物品UI
            if extItem.type == 1 or extItem.type == 3 then
                GameUI.addItemIcon(newItem.yello, extItem.item[1], extItem.item[2], 1, 103, 103, true)
                GameUI.registerTipsAction(newItem.yello, self.view, extItem.item[1], extItem.item[2])
                if extItem.type == 1 then
                    if GameLogic.getItemNum(extItem.item[1], extItem.item[2]) < extItem.item[3] then
                        resOk = true
                    end
                    newItem.label1:setString(GameLogic.getItemNum(extItem.item[1], extItem.item[2]) .. "/" .. extItem.item[3])
                else
                    newItem.label2:setString("X" .. extItem.item[3])
                end
            end
        end
    end

    reuseCell.btn:setScriptCallback(ButtonHandler(self.onAction, self, info))
    reuseCell.btn.view:setTouchThrowProperty(true, true)
    if a<b then
        reuseCell.btn:setGray(false)
    else
        reuseCell.btn:setGray(true)
    end
    return reuseCell
end

function ActivityListDialog:onUpdateNormalItem(reuseCell, layoutView, info)
    if not reuseCell then
        reuseCell = layoutView:createItem(1)
        reuseCell:loadViewsTo()
    end
    GameUI.registerTipsAction(reuseCell, self.view, info[1], info[2])
    reuseCell.bgOne:removeAllChildren(true)
    local size = reuseCell.bgOne.size
    GameUI.addItemIcon(reuseCell.bgOne, info[1], info[2], size[1]/200, size[1]/2, size[2]/2, true)
    reuseCell.labOne:setString(Localizef("labelFormatX", {num=info[3]}))
    return reuseCell
end

-- 推广码礼包显示
function ActivityListDialog:onUpdateCellSpread(reuseCell, tableView, info)
    if not reuseCell then
        reuseCell = tableView:createItem(1)
        reuseCell:loadViewsTo()
        reuseCell.btnInviteOne.view:setTouchThrowProperty(true, true)
        ViewTemplates.setImplements(reuseCell.rewds, "LayoutImplement", {callback=Handler(self.onUpdateNormalItem, self), withIdx=false})
    end
    local need = info.townLv
    reuseCell.inviteLabel:setString(Localizef("stringCanGetRewardWithTownLv",{a = need}))
    local awd = info.awd
    reuseCell.rewds:setLayoutDatas(awd.rwds)
    local num = awd.maxNum - info.getedPackNum
    reuseCell.labelPackNum:setString(Localizef("labelPackNum",{num=num}))
    if num <= 0 then
        if not reuseCell.gotNode then
            local _x, _y = reuseCell.btnInviteOne.view:getPosition()
            reuseCell.gotNode = GameUI.addHaveGet(reuseCell.btnInviteOne.view:getParent(),
                Localize("labelAlreadyReceive"), 1, _x, _y, 1)
        else
            reuseCell.gotNode:setVisible(true)
        end
        reuseCell.labelPackNum:setVisible(false)
        reuseCell.btnInviteOne:setVisible(false)
    else
        if reuseCell.gotNode then
            reuseCell.gotNode:setVisible(false)
        end
        reuseCell.labelPackNum:setVisible(true)
        reuseCell.btnInviteOne:setVisible(true)
        if info.getedPackNum >= (info.havePack or awd.maxNum) then
            reuseCell.sprInviteOne:setSValue(-100)
            reuseCell.btnInviteOne:setEnable(false)
        else
            reuseCell.sprInviteOne:setSValue(0)
            reuseCell.btnInviteOne:setEnable(true)
        end
        reuseCell.btnInviteOne:setScriptCallback(ButtonHandler(self.onGetSpreadCodeReward, self, info))
    end
    info.reuseCell = reuseCell
    return reuseCell
end

function ActivityListDialog:onGetSpreadCodeReward(info)
    if not GameNetwork.lockRequest() then
        return
    end
    local context = GameLogic.getUserContext()
    local item
    local uid = context.uid
    local townLv = info.townLv
    GameNetwork.request("getCodeRewards",{mtype=0,ucodeid=uid,tid=context.uid,sid=context.sid,lv=townLv},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code == 0 then
                local rwds = data.rwds
                GameLogic.addRewards(rwds)
                GameLogic.statCrystalRewards("推广码奖励",rwds)
                GameLogic.showGet(rwds)
                GameLogic.getUserContext():changeProperty(info.constIdx, 1)
                info.getedPackNum = info.getedPackNum + 1

                if not self.deleted and self.pageViewLayout and self.pageViewLayout.nodeSpecialSpreadList then
                    self.pageViewLayout.nodeSpecialSpreadList:refreshLazyTable()
                end
                GameEvent.sendEvent("spreadAndRewardRedNum")
            end
        end
    end)
end

function ActivityListDialog:onSendSpreadCode()
    local isGetRwd = 0
    local viewLayout = self.pageViewLayout
    local isNew, code
    if viewLayout and viewLayout.nodeSpecialSpreadList2 then
        code = viewLayout.inputNodeBack.textBox:getText()
    else
        GameLogic.addStatLog(11613, 0, GameLogic.getLanguageType(), 1)
        return
    end
    if GameLogic.tcodeUsed == 1 then
        display.pushNotice(Localize("stringHaveInsertCode"))
        GameLogic.addStatLog(11613, 0, GameLogic.getLanguageType(), 1)
        return
    end
    isNew, code = GameLogic.getTCodeNumber(code)
    if not code then
        display.pushNotice(Localize("noticeSpreadCode"))
        GameLogic.addStatLog(11613, 0, GameLogic.getLanguageType(), 1)
        return
    end
    if (not isNew and GameLogic.tcode == code) or (isNew and GameLogic.getUserContext().uid == code) then
        display.pushNotice(Localize("labelCantInsertYourself"))
        GameLogic.addStatLog(11613, 0, GameLogic.getLanguageType(), 1)
        return
    end
    if not GameNetwork.lockRequest() then
        GameLogic.addStatLog(11613, 0, GameLogic.getLanguageType(), 1)
        return
    end
    _G["GameNetwork"].request("sendCode",{code = code, isNew = isNew and 1 or 0, blv=GameLogic.getUserContext().buildData:getMaxLevel(const.Town)},function(isSuc, data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code == 0 then
                GameLogic.tcodeUsed = 1
                GameLogic.addRewards(data.rwds)
                GameLogic.statCrystalRewards("邀请码奖励",data.rwds)
                GameLogic.showGet(data.rwds)
                if not self.deleted then
                    self:refreshSpreadCodeState()
                end
                GameLogic.addStatLog(11613, 1, GameLogic.getLanguageType(), 1)--长线填码埋点
            elseif data.code==1 then
                display.pushNotice(Localize("labelNotInviteCode"))
                GameLogic.addStatLog(11613, 0, GameLogic.getLanguageType(), 1)
            elseif data.code==2 then
                display.pushNotice(Localize("stringHaveInsertCode"))
                GameLogic.addStatLog(11613, 0, GameLogic.getLanguageType(), 1)
            end
        end
    end)
end

function ActivityListDialog:refreshSpreadCodeState()
    local viewLayout = self.pageViewLayout
    if viewLayout and viewLayout.nodeSpecialSpreadList2 then
        if GameLogic.tcodeUsed == 1 then
            viewLayout.butReceive:setVisible(false)
            viewLayout.inputNodeBack:setVisible(false)
        else
            viewLayout.butReceive:setVisible(true)
            viewLayout.inputNodeBack:setVisible(true)
        end
    end
end

function ActivityListDialog:onUpdateCell0(cell, tableView, info)
    local bg = cell:getDrawNode()
    local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
    if not info.viewLayout then
        info.view = cell
        info.viewLayout = self:addLayout(_allTemplates["templateActCell"..(self.act["viewTemplates"].items.viewType or 11)], bg)
        if self.act.hiddenView then
            if type(self.act.hiddenView) == "table" then
                info.viewLayout:_addViews(self.act.hiddenView)
            else
                info.viewLayout:_addViews(_allTemplates[self.act.hiddenView])
            end
        end
        info.viewLayout:loadViewsTo(info)
    end

    if info.idx ~= info.showedIdx then
        info.showedIdx = info.idx
        info.btnGo:setScriptCallback(ButtonHandler(self.onAction, self, info))
        info.btnGo.view:setTouchThrowProperty(true, true)
        info.itemsNode.view:removeAllChildren(true)
        local items = self.context.activeData:getConfigableRwds(self.actId, info.idx).items
        local tv = info.itemsNode:loadTableView(items, Handler(self.onUpdateItemInner, self))
        tv.view:setTouchThrowProperty(true, true)
        tv.view:setElastic(false)
    end

    -- 什么时候不显示内容，显示隐藏的东西，方案未定
    if false then
        info.hiddenNode:setVisible(true)
        info.labelNode:setVisible(false)
        info.btnGo:setVisible(false)
        info.itemsNode:setVisible(false)
        info.activeTips:setString("???")
    else
        if info.hiddenNode then
            info.hiddenNode:setVisible(false)
        end
        info.itemsNode:setVisible(true)
        local tipKey = info.page.key or ("activeTips" .. self.actId .. "_" .. info.idx)
        local rwd = self.context.activeData:getConfigableRwds(self.actId, info.idx)
        local condition = rwd.conditions[1]
        local b = condition[2]
        local a = self.context.activeData:getActRecord(self.actId, condition[1])[1]
        if a > b then
            a = b
        end
        info.activeTips:setString(Localizef(tipKey, {a=a, b=b}))
        if info._order == 2 then
            info.labelNode:setVisible(true)
            info.btnGo:setVisible(false)
        else
            info.labelNode:setVisible(false)
            info.btnGo:setVisible(true)
            info.btnGo:setEnable(true)
            info.btnBack.view:setSValue(0)
            info.btnBack.view:setHValue(0)
            local width = info.btnGo.size[1]
            local height = info.btnGo.size[2]
            info.btnLabel:setPosition(width/2, height*0.6)
            if info.btnIcon then
                info.btnIcon:removeFromParent(true)
                info.btnIcon = nil
            end
            if info._order == 0 then
                info.btnLabel:setString(Localize("labelRecive"))
            elseif info._order == 1 then
                -- 表示该任务属于自动计数，无法手动完成
                if rwd.atype == const.ActActionBuy then
                    info.btnLabel:setString(Plugins.storeItems[Plugins.storeKeys[rwd.goodsid]])
                    if GameLogic.purchaseLock or self.context.activeData:checkPurchaseLimit(self.actId, info.idx) then
                        info.btnGo:setGray(true)
                    end
                elseif rwd.atype == const.ActActionExchange then
                    info.btnLabel:setString(tostring(rwd.costs[1][3]))
                    info.btnLabel:setPosition(width/2-40, height*0.6)
                    info.btnIcon = GameUI.addResourceIcon(info.btnGo.view:getDrawNode(), rwd.costs[1][2], 0.8, width/2+info.btnLabel.size[1]/2, height*0.6)
                elseif rwd.atype == const.ActActionAuto then
                    -- info.btnGo:setVisible(false)
                    info.btnGo:setEnable(false)
                    info.btnBack.view:setSValue(-100)
                    info.btnLabel:setString(Localize("labelRecive"))
                else
                    info.btnBack.view:setHValue(114)
                    info.btnLabel:setString(Localize("buttonGo"))
                end
            end
        end
    end
end

function ActivityListDialog:onUpdateCell1(cell, tableView, info)
    local bg = cell:getDrawNode()
    local temp = ui.sprite("images/energyBlockBack.png", {233, 233})
    display.adapt(temp, 150, 150, GConst.Anchor.Center)
    bg:addChild(temp)
    GameUI.addItemIcon(bg,info.item[1],info.item[2],1,150,150,true,false)
    local bName=ui.label(GameLogic.getItemName(info.item[1],info.item[2]),General.font1, 36, {color={255,255,255},fontW=200,fontH=70})
    display.adapt(bName, 150, 10, GConst.Anchor.Center)
    bg:addChild(bName)
    local bNum=ui.label("X "..info.item[3],General.font1, 36, {color={255,255,255}})
    display.adapt(bNum, 150, -50, GConst.Anchor.Center)
    bg:addChild(bNum)
    self:onUpdateItemInner(cell, tableView, info.item)
end

function ActivityListDialog:onUpdateCell2(cell, tableView, info)
    local bg = cell:getDrawNode()
    local cellSize= cell:getContentSize()
    local temp = ui.sprite("images/energyBlockBack.png", {233, 233})
    display.adapt(temp, 150, 150, GConst.Anchor.Center)
    bg:addChild(temp)
    GameUI.addItemIcon(bg,info.item[1],info.item[2],1,150,150,true,false)
    local bName=ui.label(GameLogic.getItemName(info.item[1],info.item[2]),General.font1, 36, {color={255,255,255},fontW=180,fontH=150,align=GConst.Align.Left})
    display.adapt(bName, 270, 120, GConst.Anchor.LeftBottom)
    bg:addChild(bName)
    local bNum=ui.label("X "..info.item[3],General.font1, 36, {color={255,255,255}})
    display.adapt(bNum, 270, 80, GConst.Anchor.Left)
    bg:addChild(bNum)
    GameUI.registerTipsAction(cell, self.view, info.item[1], info.item[2])
end


function ActivityListDialog:onUpdateCell3(cell, tableView, info)
    local bg = cell:getDrawNode()
    GameUI.addItemIcon(bg,info.item[1],info.item[2],1,100,150)
    local bNum=ui.label("X"..info.item[3],General.font1, 36, {color={255,255,255}})
    display.adapt(bNum, 200, 70, GConst.Anchor.Left)
    bg:addChild(bNum)
    self:onUpdateItemInner(cell, tableView, info.item)
end

function ActivityListDialog:onUpdateCell4(cell, tableView, info)
    local bg = cell:getDrawNode()
    local cellSize = cell:getContentSize()
    GameUI.addItemIcon(bg,info.item[1],info.item[2],1,100,150,true)
end

function ActivityListDialog:onUpdateCell5(cell, tableView, info)
    self:onUpdateItemInner(cell, tableView, info.item)
end

function ActivityListDialog:onUpdateCell6(cell, tableView, info)
    local bg = cell:getDrawNode()
    local cellSize= cell:getContentSize()
    local temp = ui.sprite("images/energyBlockBack.png", {233, 233})
    display.adapt(temp, 150, 150, GConst.Anchor.Center)
    bg:addChild(temp)
    GameUI.addItemIcon(bg,info.item[1],info.item[2],1,150,150,true,false)
    local bNum=ui.label("X "..info.item[3],General.font1, 36, {color={255,255,255}})
    display.adapt(bNum, 250, 70, GConst.Anchor.Right)
    bg:addChild(bNum)
    bg:setScale(1.15)
    GameUI.registerTipsAction(cell, self.view, info.item[1], info.item[2])
end

function ActivityListDialog:onUpdateCell10(cell, tableView, info)
    local _atemplates = GMethod.loadConfig("configs/ui/templates.json")
    local scrollnode = _atemplates["templateActCell"..(self.act["viewTemplates"].items.viewType or 11)]

    local tempLayout = self:addLayout(scrollnode, cell:getDrawNode())
    tempLayout:loadViewsTo()

    local _myRwd = self.context.activeData:getConfigableRwds(self.actId, info.idx)

    local tipKey = info.page.key or ("activeTips" .. self.actId)
    local condition = _myRwd.conditions[1]
    tempLayout.activeTips:setString(Localizef(tipKey,{a=condition[2],b = condition[3]}))

    local tableView2 = tempLayout.nodeTableView:loadTableView(_myRwd.items,Handler(self.onUpdateItemInner, self)).view
    tableView2:setTouchThrowProperty(true, true)
    tableView2:setElastic(false)
end

function ActivityListDialog:onUpdateCell12(cell,tableView,info)
    --
    local _atemplates = GMethod.loadConfig("configs/ui/templates.json")
    local scrollnode = _atemplates["templateActCell"..(self.act["viewTemplates"].items.viewType or 11)]
    local tempLayout = self:addLayout(scrollnode, cell:getDrawNode())
    tempLayout:loadViewsTo()
    self:showWCKingBox(tempLayout,self,info)
end

function ActivityListDialog:onAction(info)
    if not info then
        local info = {}
        info.idx = self.pageId
    end

    if self.actId == 171264 then--短线友谊的力量--兑换
        GameLogic.addStatLog(11602, info.idx, GameLogic.getLanguageType(), 1)
    elseif self.actId == 171261 then--短线友谊的见证
        local rwd = self.context.activeData:getConfigableRwds(self.actId, info.idx)
        local codeTimes = rwd.conditions[1][2]
        GameLogic.addStatLog(11607, GameLogic.getLanguageType(), codeTimes, 1)
    elseif self.actId == 18012001 then--导量领奖
        GameLogic.addStatLog(11703, GameLogic.getLanguageType(), 1, 1)
    end

    GameLogic.doActAction(self.context, self.actId, info.idx, self)
end

-- 加载scroll list
function ActivityListDialog:reloadScrollList()
    local templates = self.act.viewTemplates
    local infos = {}
    for i,v in KTIPairs(templates.pages) do
        -- 如果该项奖励属于会隐藏，则必然存在隐藏条件，则根据隐藏ID去检查该隐藏条件是否完成
        if self.context.activeData:checkVisible(self.actId, v) then
            --活动ID
            local state = self.context.activeData:checkActRewardState(self.actId, i)
            local order = 1
            if state == GameLogic.States.Finished then
                order = 0
            elseif state == GameLogic.States.Close then
                order = 2
            end
            table.insert(infos, {page=v, idx=i, _order=order})
        end
    end
    if templates.sortPage then
        GameLogic.mySort(infos, "_order")
    end
    local viewLayout = self.pageViewLayout
    if not viewLayout.pageInfos or KTLen(viewLayout.pageInfos) ~= KTLen(infos) then
        if viewLayout.nodeTableView.setLazyTableData then
            viewLayout.nodeTableView:setLazyTableData(infos, Handler(self["onUpdateNewCell" .. (templates.items.cellType or 0)], self), 0)
        else
            viewLayout.nodeTableView.view:removeAllChildren(true)
            viewLayout.pageScrollView = viewLayout.nodeTableView:loadTableView(infos, Handler(self["onUpdateCell" .. (templates.items.cellType or 0)], self))
        end
        viewLayout.pageInfos = infos
    else
        if viewLayout.nodeTableView.setLazyTableData then
            viewLayout.nodeTableView:refreshLazyTable()
        else
            for idx, pageInfo in ipairs(viewLayout.pageInfos) do
                pageInfo.page = infos[idx].page
                pageInfo._order = infos[idx]._order
                pageInfo.idx = infos[idx].idx
                if pageInfo.view then
                    self["onUpdateCell" .. (templates.items.cellType or 0)](self, pageInfo.view, viewLayout.pageScrollView, pageInfo)
                end
            end
        end
    end
end

function ActivityListDialog:onPurchaseOver(code)
    if not GameLogic.purchaseLock then
        local viewLayout = self.pageViewLayout
        if viewLayout.subPageLayout then
            viewLayout = viewLayout.subPageLayout
        end
        if viewLayout.btnReward then
            viewLayout.btnReward:setGray(false)
        end
    end
end

function ActivityListDialog:onTreasureAction(pageId)
    local params = {}
    local data = self.context.activeData:getConfigableRwds(self.actId, pageId)
    params.product = Plugins.storeKeys[data.goodsid] --产品ID
    params.callback = Handler(self.onPurchaseOver, self)
    local viewLayout = self.pageViewLayout
    if viewLayout.subPageLayout then
        viewLayout = viewLayout.subPageLayout
    end
    if viewLayout.btnReward then
        viewLayout.btnReward:setGray(true)
    end
    -- 特别的，充值活动考虑其复用性，即万一哪天策划突然想开两个9.99的礼包，光传bidx是不够的，还要传用户当前活动的条件
    GameUI.setLoadingShow("loading", true, 0)
    GameLogic.purchaseLock = true
    params["ext"] = "3_" .. self.actId .. "_" .. pageId
    _G["GameNetwork"].request("prebuy",{bidx=data.goodsid, mc=3, actId=self.actId, rwdIdx=pageId},function(isSuc,data)
        GameUI.setLoadingShow("loading", false, 0)
        GameLogic.purchaseLock = nil
        if isSuc then
            if data.code==0 then
                Plugins:purchase(params)
            elseif data.code == 3 then
                display.pushNotice(Localize("activeTimeOver"))
            else
                display.pushNotice(Localize("noticePrebuyFail" .. data.code))
            end
        end
    end)
end

function ActivityListDialog:refreshMyDialog(event, params)
    if not self.deleted then
        local changedDict = {}
        for i, info in ipairs(self.actInfos) do
            if info.view then
                local oldNum = info.curNum
                self:onUpdateLeftAct(info.view, self.nodeActsTableView, info)
                if info.curNum ~= oldNum then
                    changedDict[info.actId] = 1
                end
            end
        end
        if params and params[1] == "actChange" then
            for k, v in pairs(params[2]) do
                changedDict[k] = v
            end
        end
        if changedDict[self.actId] or (params and params[1] == "receiveOver") then
            local tm = self.act.viewTemplates
            if tm and tm.items and tm.items.valueType == 2 then
                self:reloadScrollList()
            elseif tm and tm.specialTemplate and params and params[3] then
                self:refreshScratch(params[3])
                local data = params[3]
                local reward = self.context.activeData:getConfigableRwds(data.actId, data.rwdIdx)
                -- 实际增加的资源
                local addRes = params[3].rwds
                -- 显示增加数量 = 实际+消耗
                local rnum = addRes[1][3]+reward.costs[1][3]
                local function func()
                    -- 发公告
                    self:sendNotice(rnum)
                end
                local scene = GMethod.loadScript("game.View.Scene")
                scene.menu.view:runAction(ui.action.sequence({{"delay",3.0},{"call",func}}))
                params[2] = true
            elseif tm and tm.rotaryTableTemplate and params and params[3] and self.rotateAnimate then
                self.rotateAnimate.tidx = params[3].randIdx
                self.luckyBackData.sIdx = params[3].randIdx
                self.luckyBackData.data = params[3]
                params[2] = true
                if self.luckyBackData.data.rwds and #self.luckyBackData.data.rwds>1 then
                    self:refreshRotaryData()
                end
            elseif params and params[3] and (params[3].actId == 170309) then
                --万磁王的活动
                GameLogic.showGet(params[3].rwds, 0, true, true)
                params[2] = true
                self:reloadPageView()
            elseif changedDict[self.actId] or (params[3] and params[3].actId == self.actId and params[3].rwdIdx == self.pageId) then
                local temp
                if params[3] and params[3].rwdIdx then
                    temp = params[3].rwdIdx
                else
                    temp = self.pageId
                end
                local myRwd = self.context.activeData:getConfigableRwds(self.actId, temp)
                if myRwd and myRwd.isLottery then
                    if myRwd.atype==1 then
                        params[2] = true
                        self.luckyBackData.data = params[3]
                        self:refreshRotaryData()
                    end
                    return
                end
                self:reloadPageView()
            end
        end
    end
end


--转盘，现在只能开8个内容……
function ActivityListDialog:initRotary(layout,rwd)
    -- body
    if rwd then
        local temp,labelStr,btnStart,btnCell,_scale
        for k,v in ipairs(rwd.items) do
            temp = layout["node"..k]
            labelStr = layout["rwdlabel"..k]
            if temp and labelStr then
                temp:removeAllChildren(true)
                btnCell = ui.button({150,144},nil,{})
                temp:addChild(btnCell)
                _scale = 0.7
                if v[1] == const.ItemHero then
                    UIeffectsManage:showEffect_ShiLianChou(3,btnCell,75,72,3,{},0.5)
                    _scale = 0.6
                    labelStr:setVisible(false)
                end
                GameUI.addItemIcon(btnCell,v[1],v[2],_scale,75,75,true)
                labelStr:setString("X"..v[3])
                GameUI.registerTipsAction(btnCell, self.view, v[1], v[2])
            end
        end
        layout.labelPercent.view:setRotation(45)
        self.point = layout.pointUI.view
        self:updateButLabel(layout)
        self.rotaryLayout = layout
        local mR = #(rwd.items)
        if not self.luckyBackData then
            self.luckyBackData = {sIdx = 0, cSum = 0, mR=mR}
        else
            local curIdx = math.ceil(self.luckyBackData.cSum / (360/mR)) % mR
            if curIdx == 0 then
                curIdx = mR
            end
            self.luckyBackData.sIdx = curIdx
            self.luckyBackData.mR = mR
            self.point:setRotation(self.luckyBackData.cSum)
        end
        self.nowRatary = nil
        self.rotaryTable = {}
        local bNode=ui.node()
        self.pageViewLayout.chatTableView:addChild(bNode)
        RegTimeUpdate(bNode, Handler(self.updateRotary, self), 1)
    end
end

function ActivityListDialog:updateRotary( diff )
    if not self.rotaryTable.pollTime then
        self.rotaryTable.pollTime = 0
        self.rotaryTable.dtime = 0
    end

    self.rotaryTable.pollTime = self.rotaryTable.pollTime+diff
    if self.rotaryTable.pollTime>=self.rotaryTable.dtime and not self.rotaryTable.notReceive then
        self.rotaryTable.dtime = 3
        self.rotaryTable.pollTime = 0
        self:startRotarySever()
    end
end

function ActivityListDialog:startRotarySever()
    local since = self.rotaryTable.since or 0
    local cid = -2
    self.rotaryTable.notReceive = true
    _G["GameNetwork"].request("recv",{cid = cid,since = since},function(isSuc,data)
        if isSuc then
            --dump(data)
            self.rotaryTable.notReceive = false
            if self.deleted or not self.pageViewLayout.chatTableView then
                return
            end
            local infos,k,_cinfo = {},0,{}
            for i,v in ipairs(data.messages) do
                -- if not infos[v[1]] then
                    infos[v[1]] = {v[2],v[3],v[6]}
                -- end
                -- self.scratch.since = v[4]
            end
            for i,v in pairs(infos) do
                if #_cinfo<=5 then
                    table.insert(_cinfo,{v[1],v[2],v[3].rate or 4,v[3].hid or 4031})
                end
            end
            local chInfo = GEngine.getConfig("rotaryInfo")
            if not chInfo then
                GEngine.setConfig("rotaryInfo",json.encode(_cinfo))
                if self.updateRotaryNotice then
                    self:updateRotaryNotice(_cinfo)
                end
            elseif #_cinfo>0 then
                chInfo = json.decode(chInfo)
                for i,v in pairs(_cinfo) do
                    table.insert(chInfo,{v[1],v[2],v[3],v[4]})
                    if #chInfo>=5 then
                        table.remove(chInfo,1)
                    end
                end
                GEngine.setConfig("rotaryInfo",json.encode(chInfo))
                if self.updateRotaryNotice then
                    self:updateRotaryNotice(chInfo)
                end
            end
        end
    end)
end

function ActivityListDialog:getInfosLength(info)
    -- body
    if info then
        return #info
    end
    return
end

function ActivityListDialog:updateButLabel(layout)

    local myRwd = self.context.activeData:getConfigableRwds(self.actId, self.pageId)
    local got = self.context.activeData:getActRwd(self.actId, myRwd.rwdId)[1] + 1
    local infos,tinfos,binfos = {},{},{}
    local str
    local _arr = {}
    for k=2,5 do
        local _rwd = self.context.activeData:getConfigableRwds(self.actId, k)
        table.insert(_arr, _rwd.conditions[1][2])
    end
    infos.gotNum = got
    tinfos.gotNum = got
    if got > #(myRwd.costs) then
        got = #(myRwd.costs)
    end
    local num = myRwd.costs[got]
    if num[3] == 0 then
        str = Localize("labelFree")
    else
        str = tostring(num[3])
    end
    infos.type = num[1]
    infos.id = num[2]
    infos.num = num[3]
    infos.index = self.pageId
    infos.maxNum = myRwd.max
    infos.isTen = false

    tinfos.type = num[1]
    tinfos.id = num[2]
    tinfos.index = self.pageId
    tinfos.maxNum = myRwd.max
    local temp = got-3
    if temp > 0 then
        temp = 0
    end

    tinfos.num = math.floor(200*(10+temp)*0.9)
    tinfos.isTen = true
    layout.btnOnce:setScriptCallback(Script.createCallbackHandler(self.btnRotaryCallback, self, infos))
    layout.labelPriceNum1:setString(str)
    layout.btnTen:setScriptCallback(Script.createCallbackHandler(self.btnRotaryCallback, self, tinfos))
    layout.labelPriceNum2:setString(tinfos.num)
    layout.btnlabel1:setString(Localize("labelRotaryNum1"))
    layout.btnlabel2:setString(Localize("labelRotaryNum10"))
    local _p = self:getProgressNum(infos.gotNum-1,_arr)
    layout.rotaryProgress:setProcess(true,_p)
    layout.labelSubRotaryNum:setString(Localizef("labelSubRotaryTitle",{a = infos.gotNum-1}))


    local _img,_openImg,_other = "",{}
    for k=1,4 do
        local _rwd = self.context.activeData:getConfigableRwds(self.actId, k+1)
        num = self.context.activeData:getActRecord(self.actId, _rwd.conditions[1][1])[1]
        if self.context.activeData:checkActRewardState(self.actId, k+1) == GameLogic.States.Close then
            num = -1
        end
        if k~=4 then
            _img = "images/box" .. k .. "_1.png"
            _openImg = "images/box" .. k .. "_2.png"
        else
            _other = _rwd.items[1] or 4010
        end
        table.insert(binfos,{id = k,img = _img,openImg=_openImg,num=_arr[k],curNum = num,getNum = _rwd.conditions[1][2],pageId = k+1,other = _other})
    end
    self.pageViewLayout.buttonTableView:loadTableView(binfos, Handler(self.createRotaryNumBotton, self))
end

function ActivityListDialog:getProgressNum(num,arr)
    local _num,a = 0,0
    local _arr = {0,0.33,0.66,0.99}
    if num>=arr[4] then
        return 1
    end
    for k,i in ipairs(arr) do
        if num < i then
            a = k-1
            if a <=0 then
                _num = _arr[k]
            else
                _num = _arr[a]
            end
            return _num
        end
    end
    return _num
end

function ActivityListDialog:createRotaryNumBotton(cell,tableView,info)
    if not info.viewLayout then
        local bg = cell:getDrawNode()
        local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
        info.viewLayout = self:addLayout(_allTemplates["templateBtns2017081001"], bg)
        info.viewLayout:loadViewsTo(info)
        info.labelDesc:setString(Localizef("labelCurRotaryNum",{a=info.num}))
        if not GameLogic.isEmptyTable(info.other) then
            info.btnImg:setVisible(false)
            info.btnImg1:setVisible(false)
            GameUI.addPlayHead(info.btnInstruction,{viplv=nil,id=info.other[2]*100+1,scale=0.9,x=75,y=75,z=1,noBut = true,anchor="Center",blackBack = false})
        else
            info.btnImg:setImage(info.img)
        end
        if info.curNum < 0 then
            info.btnImg:setImage(info.openImg)
        elseif info.curNum >= info.getNum then
            local act = ui.action.arepeat(ui.action.sequence({{"scaleTo", 0.5, 1.1, 1.1}, {"scaleTo", 0.5, 1, 1}, {"delay", 1} }))
            info.btnInstruction.view:runAction(act)
        end
        info.btnInstruction:setScriptCallback(ButtonHandler(function ()
            -- body
            if self.nowRatary then
                return
            end
            if info.curNum >= info.getNum then
                self:onAction({idx=info.pageId})
            else
                --display.pushNotice(Localize("notEnouchBox"))
            end
        end))
        info.btnInstruction.view:setTouchThrowProperty(true, true)
    end
end



function ActivityListDialog:updateRotaryNotice(data)
    local viewLayout = self.pageViewLayout
    local infos,k = {},1
    for i,v in pairs(data) do
        infos[k] = v
        k = k+1
    end
    if not self.deleted and viewLayout and viewLayout.chatTableView then
        viewLayout.chatTableView:loadTableView(infos, Handler(self.createRotaryNotice, self))
    end
end
function ActivityListDialog:createRotaryNotice(cell,tableView,info)
    -- body
    if not info.tableView then
        local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
        info.viewLayout = self:addLayout(_allTemplates["templateActLab"..(self.act["viewTemplates"].labType or 1)], cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        local rate, hName
        if info[3] == 5 then
            rate = Localize("UR")
        else
            rate = Localize("SSR")
        end
        hName = Localize("dataHeroName"..info[4])
        info.labelDesc:setString(info[1]..Localizef("labelRotaryNotice"..info[2], {rate = rate, hName = hName}))
    end
end

function ActivityListDialog:btnRotaryCallback(info)
    -- body
    if self.nowRatary then
        return
    end
    if info.gotNum > info.maxNum then
        display.pushNotice(Localize("labelActLuckyRotaryFull"))
        return
    end
    if info.num > self.context:getRes(info.id) then
        display.showDialog(AlertDialog.new({ctype=info.id, cvalue=info.num}))
        return
    end
    -- 先开始放动画
    self.nowRatary = true
    self.rotateAnimate = {cur=self.luckyBackData.sIdx, ct=0, spd=0, tt=0}
    if info.isTen then
        local context = GameLogic.getUserContext()
        local vip = context:getInfoItem(const.InfoVIPlv)
        local userLv = context:getInfoItem(const.InfoLevel)
        GameLogic.addStatLog(31003,vip,userLv,1)
        GameLogic.doActAction(self.context, self.actId, info.index, self,{num = 10})
    else
         local context = GameLogic.getUserContext()
        local vip = context:getInfoItem(const.InfoVIPlv)
        local userLv = context:getInfoItem(const.InfoLevel)
        GameLogic.addStatLog(31002,vip,userLv,1)
        RegUpdate(self.point, Handler(self.onRotateStep, self), 0)
        -- 然后发请求
        self:onAction({idx=info.index})
    end
end

--一个初始加速，然后匀速，然后减速，最后严重减速的动画
function ActivityListDialog:onRotateStep(diff)
    local r = self.rotateAnimate
    local l = self.luckyBackData
    if not r then
        UnregUpdate(self.point)
        return
    end
    r.tt = r.tt + diff
    -- 1s加速到1圈/s
    if r.tt <= 1.5 then
        r.spd = r.spd + 960*diff
    elseif r.tt > 2 then
        -- 开始减速
        if r.tidx then
            if not r.lt then
                r.lt = (r.tidx - 0.15 - math.random()*0.7) * 360 / l.mR + 360 * math.random(8, 12)
                l.cSum = l.cSum % 360
                r.lt0 = l.cSum
                local s = r.lt - l.cSum
                r.ltt = s * 2 / r.spd
                r.lt1 = 0
            end
            r.lt1 = r.lt1 + diff
            if r.lt1 >= r.ltt then
                r.lt1 = r.ltt
                self:refreshRotaryData()
            end
            -- local delta = 1 - (r.lt1 / r.ltt)
            -- delta = 1 - delta * delta
            local delta = r.lt1 / r.ltt
            delta = math.sin(delta * math.rad(90))
            l.cSum = r.lt0 + (r.lt - r.lt0) * delta
            self.point:setRotation(l.cSum)
            return
        end
    end
    l.cSum = l.cSum + r.spd * diff
    self.point:setRotation(l.cSum)
end

function ActivityListDialog:refreshRotaryData()
    --这里走的是gamelogin公共的逻辑，所以这里只需要延迟处理显示的就可以
    if self.rotaryLayout then
        self:updateButLabel(self.rotaryLayout)
    end
    if not GameLogic.isEmptyTable(self.luckyBackData) and (self.luckyBackData.data) then
        self.nowRatary = nil
        self.rotateAnimate = nil
        local items = self.luckyBackData.data.rwds
        local num = #items
        if num>1 then
            GameLogic.showGet(items,0,true,true)
        else
            GameLogic.showGet(items)
            GameLogic.showHeroRewsUieffect(items)
        end
        self.luckyBackData.data = nil
        local idx = 1
        for i=1, KTLen(items) do
            local v = items[idx]
            if v[1] == const.ItemHero then
                self:sendRotaryNotice(#items, v[2])
                 break
            end
            idx = idx +1
        end
    end
end

--guaguaka
function ActivityListDialog:initScratch(index)
    if self.pageViewLayout.scratchBg then
        self.pageViewLayout.scratchBg:removeFromParent(true)
    end
    local viewLayout = self.pageViewLayout
    if index then
        self.index = index
    end
    local len = #self.act.rwds
    self.scratch = {}
    if self.index > len then
        viewLayout.btnReward:setGray(true)
        self.scratch.btnGray = true
        self.index = len
    end
    local reward = self.context.activeData:getConfigableRwds(self.actId, self.index)
    local bg = ui.node(self.nodePageView.size,true)
    display.adapt(bg,0,0,GConst.Anchor.LeftBottom)
    self.nodePageView.view:addChild(bg)
    self.pageViewLayout.scratchBg = bg
    -- 判断消耗的资源是否足够
    for i,v in KTIPairs(reward.costs) do
        --本次花费 v[3]
        GameUI.addItemIcon(bg,v[1],v[2],0.45,1180+150*i,420)
        local costs=ui.label(v[3],General.font1, 32, {color={255,255,255}})
        display.adapt(costs, 1230+150*i, 420, GConst.Anchor.Left)
        bg:addChild(costs)
        -- 剩余资源
        GameUI.addItemIcon(bg,v[1],v[2],0.45,1180+150*i,290)
        local surplus=ui.label(GameLogic.getUserContext():getRes(v[2]),General.font1, 32, {color={255,255,255}})
        display.adapt(surplus, 1230+150*i, 290, GConst.Anchor.Left)
        bg:addChild(surplus)

        if GameLogic.getUserContext():getRes(v[2])<v[3] then
            viewLayout.btnReward:setGray(true)
        else
            viewLayout.btnReward:setGray(false)
        end

        viewLayout.btnReward:setScriptCallback(ButtonHandler(function ()
            if self.scratch.btnGray then
                display.pushNotice(Localize("scratchTimesOver"))
            else
                if self.scratch.actRuning then
                    return
                --剩余资源 GameLogic.getUserContext():getRes(v[2])
                elseif GameLogic.getUserContext():getRes(v[2])<v[3] then
                    display.showDialog(AlertDialog.new({ctype=v[2], cvalue=v[3]}))
                else
                    self:onAction({idx=self.index})
                end
            end
        end))
    end
    -- 最高奖励
    for i, item in KTIPairs(reward.items) do
        GameUI.addItemIcon(bg,item[1],item[2],0.6,720,470-100*i)
        local maxNum=ui.label(item[4],General.font1, 38, {color={255,255,255}})
        display.adapt(maxNum, 800, 470-100*i, GConst.Anchor.Left)
        bg:addChild(maxNum)
    end
    self:createScratchNum()
    local infos = GEngine.getConfig("scratchInfo")
    if infos then
        self:updateNotice(json.decode(infos))
    end
    RegTimeUpdate(bg, Handler(self.update, self), 1)
end

function ActivityListDialog:refreshScratch( data )
    self.scratch.actRuning = true
    local reward = self.context.activeData:getConfigableRwds(data.actId, data.rwdIdx)
    -- 实际增加的资源
    local addRes = data.rwds
    -- 显示增加数量 = 实际+消耗
    local rnum = addRes[1][3]+reward.costs[1][3]
    self.index = self.context.activeData:getActRecord(self.actId, const.ActTypeScratch)[1]+1
    self:runActionScratch(rnum)
end
-- 那几个数字
function ActivityListDialog:createScratchNum()
    local bg = self.pageViewLayout.scratchBg
    local scNode = ui.scrollNode({730,200}, 0, false, false, {clip=true})
    display.adapt(scNode, 727, 600, GConst.Anchor.LeftBottom)
    bg:addChild(scNode)
    local clipBg = scNode:getScrollNode()
    local tabNums = {}
    for i=1,7 do
        local start0=1
        if self.rnum then
            start0 = math.floor(self.rnum/(10^(i-1))%10)+1
        end
        local number1=ui.label(start0-1,General.font1, 110, {color={255,255,255}})
        display.adapt(number1, 805-110*i, 103, GConst.Anchor.Center)
        clipBg:addChild(number1)
        local number2=ui.label(start0,General.font1, 110, {color={255,255,255}})
        display.adapt(number2, 805-110*i, -122, GConst.Anchor.Center)
        clipBg:addChild(number2)
        table.insert(tabNums,{number1,number2})
    end
    local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
    local tempLayout = self:addLayout(_allTemplates["templateScratch2"], bg)
    tempLayout:loadViewsTo(bg)
    self.scratch.actionNum = tabNums

    local scratchNode = ui.csbNode("UICsb/scratch_1.csb")
    display.adapt(scratchNode,680,625,GConst.Anchor.LeftBottom)
    bg:addChild(scratchNode,1)
    self.scratch.scrNode = scratchNode
    self.scratch.scrNode:setVisible(false)
    local nodeAction = ui.csbTimeLine("UICsb/scratch_1.csb")
    scratchNode:runAction(nodeAction)
    nodeAction:gotoFrameAndPlay(0,true)
end

--播放动作
function ActivityListDialog:runActionScratch(rnum)
    local goldNum = 12345
    if rnum then
        goldNum = rnum
    end
    self.rnum = goldNum
    local bg = self.pageViewLayout.scratchBg
    if self.scratch.actionNum then
        for i=1,#self.scratch.actionNum do
            local __time = 0.01+0.0001*i
            local start0 = i
            local number1,number2 = self.scratch.actionNum[i][1],self.scratch.actionNum[i][2]
            local __randomNums = {5,1,7,2,9,0,8,3,6,4}
            local changeNum = function ( number )
                start0 = start0%10+1
                number:setString(tostring(__randomNums[start0]))
            end
            number1:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",__time,0,225},{"moveBy",0,0,-225*2},{"call",Handler(changeNum,number1)},{"moveBy",__time,0,225}})))
            number2:runAction(ui.action.arepeat(ui.action.sequence({{"moveBy",__time,0,225},{"moveBy",__time,0,225},{"moveBy",0,0,-225*2},{"call",Handler(changeNum,number2)}})))
            self.scratch.scrNode:setVisible(true)
        end

        for i=1,#self.scratch.actionNum do
            local t = 3
            local number1,number2 = self.scratch.actionNum[i][1],self.scratch.actionNum[i][2]
            local stop = function(number)
                number:stopAllActions()
                self.scratch.actRuning = false
                local num = math.floor(goldNum/(10^(i-1))%10)
                number:setString(tostring(num))
                local function stopTexiao( ... )
                    self.scratch.scrNode:setVisible(false)
                end
                number1:runAction(ui.action.sequence({{"moveBy",0.2,0,80},{"moveBy",0.1,0,-80},{"delay",0.15},{"call",stopTexiao}}))
                if i == #self.scratch.actionNum then
                    self:initScratch()
                end
            end
            number1:runAction(ui.action.sequence({{"delay",t},{"call",Handler(stop,number1)},{"moveTo",0,797-145*i, 103}}))
            number2:runAction(ui.action.sequence({{"delay",t},{"call",Handler(stop,number2)},{"moveTo",0,797-145*i, -122}}))
        end
    end
end

-- activity award notice
function ActivityListDialog:updateNotice(data)
    local viewLayout = self.pageViewLayout
    local infos = data
    for i=1,#infos do
        infos[i].id = i
    end
    if not self.deleted and viewLayout and viewLayout.chatTableView then
        viewLayout.chatTableView:loadTableView(infos, Handler(self.createChat, self))
    end
end

function ActivityListDialog:createChat(cell, tableView, info)
    local bg = cell:getDrawNode()
    local _allTemplates = GMethod.loadConfig("configs/ui/templates.json")
    if not info.viewLayout then
        info.viewLayout = self:addLayout(_allTemplates["templateActLab"..(self.act["viewTemplates"].labType or 1)], bg)
        info.viewLayout:loadViewsTo(info)
        info.labNum:setString(tostring(info[2]))
        info.labCell:setString(info[1])
    end
    local index = self.index
    if index>#self.act.rwds then
        index = #self.act.rwds
    end
    local reward = self.context.activeData:getConfigableRwds(self.actId, index)
    local item = reward.items[1]
    GameUI.addItemIcon(bg,item[1],item[2],0.3,243,10)
end

function ActivityListDialog:update( diff )
    if not self.scratch.pollTime then
        self.scratch.pollTime = 0
        self.scratch.dtime = 0
    end

    self.scratch.pollTime = self.scratch.pollTime+diff
    if self.scratch.pollTime>=self.scratch.dtime and not self.scratch.notReceive then
        self.scratch.dtime = 3
        self.scratch.pollTime = 0
        self:helloSever()
    end
end

function ActivityListDialog:helloSever()
    local since = self.scratch.since or 0
    local cid = -1
    self.scratch.notReceive = true
    local _viewLayout = self.pageViewLayout
    _G["GameNetwork"].request("recv",{cid = cid,since = since},function(isSuc,data)
        if isSuc then
            self.scratch.notReceive = false
            local viewLayout = self.pageViewLayout
            if self.deleted or not viewLayout.chatTableView or _viewLayout ~= viewLayout then
                return
            end
            local infos = {}
            for i,v in ipairs(data.messages) do
                table.insert(infos,{v[2],v[3],v[4]})
                if #infos>5 then
                    table.remove(infos,1)
                end
                self.scratch.since = v[4]
            end
            local chInfo = GEngine.getConfig("scratchInfo")
            if not chInfo then
                GEngine.setConfig("scratchInfo",json.encode(infos))
                self:updateNotice(infos)
            elseif #infos>0 then
                chInfo = json.decode(chInfo)
                for i,v in ipairs(infos) do
                    if v[1] ~= self.context:getInfoItem(const.InfoName) and self.scratch.inone then
                        table.insert(chInfo,{v[1],v[2]})
                        if #chInfo>5 then
                            table.remove(chInfo,1)
                        end
                    end
                end
                GEngine.setConfig("scratchInfo",json.encode(chInfo))
                self:updateNotice(chInfo)
            end
        end
    end)
end

function ActivityListDialog:sendNotice(rnum)
    local ug = {lv = GameLogic.getUserContext():getInfoItem(const.InfoLevel),
                        flag = self.context.union and self.context.union.flag,
                        uname = self.context.union and self.context.union.name}
    local msg = {uid = self.context.uid,name = self.context:getInfoItem(const.InfoName),
            text = tostring(rnum),ug = json.encode(ug),mtype = 4,cid = -1}
    self:send(msg)
end

function ActivityListDialog:sendRotaryNotice(snum, hid)
    local _n = 1
    if snum>1 then
        _n = 10
    end
    local rate
    local heroRate = SData.getData("hinfos", hid).displayColor
    if heroRate then
        rate = 5
    else
        rate = 4
    end

    local ug = {lv = GameLogic.getUserContext():getInfoItem(const.InfoLevel),
                        flag = self.context.union and self.context.union.flag,
                        uname = self.context.union and self.context.union.name, rate = rate, hid = hid}
    local msg = {uid = self.context.uid,name = self.context:getInfoItem(const.InfoName),
            text = tostring(_n),ug = json.encode(ug),mtype = 5,cid = -2}
    self:sendRotary(msg)
end

function ActivityListDialog:sendRotary(msg)
    msg.text = filterSensitiveWords(msg.text)
    msg.chatRoom=true
    local _viewLayout = self.pageViewLayout
    _G["GameNetwork"].request("send",msg,function(isSuc,data)
        if isSuc then
            local viewLayout = self.pageViewLayout
            if self.deleted or _viewLayout ~= viewLayout then
                return
            end
            local roInfo = GEngine.getConfig("rotaryInfo")
            if roInfo then
                roInfo = json.decode(roInfo)
                if not roInfo[msg.uid] then
                    roInfo[msg.uid] = {msg.name,msg.text,json.decode(msg.ug).rate or 4,json.decode(msg.ug).hid or 4031}
                    if #roInfo>5 then
                        table.remove(roInfo,1)
                    end
                end
                --self.rotaryTable.inone = true
                GEngine.setConfig("rotaryInfo",json.encode(roInfo))
                self:updateRotaryNotice(roInfo)
            end
        end
    end)
end

function ActivityListDialog:send(msg)
    msg.text = filterSensitiveWords(msg.text)
    msg.chatRoom=true
    _G["GameNetwork"].request("send",msg,function(isSuc,data)
        if isSuc then
            local chInfo = GEngine.getConfig("scratchInfo")
            if chInfo then
                chInfo = json.decode(chInfo)
                table.insert(chInfo,{msg.name,msg.text})
                self.scratch.inone = true
                if #chInfo>5 then
                    table.remove(chInfo,1)
                end
                GEngine.setConfig("scratchInfo",json.encode(chInfo))
                self:updateNotice(chInfo)
            end
        end
    end)
end

function ActivityListDialog:createInfo()
    local _myRwd = self.context.activeData:getConfigableRwds(self.actId, self.pageId)
    local infos = {}
    for i, item in KTIPairs(_myRwd.items) do
        infos[i] = {idx=i, item=item}
    end
    return infos
end

function ActivityListDialog:showWCKingBox(layout,dialog,info)
    if layout and dialog then
        local _myRwd = dialog.context.activeData:getConfigableRwds(dialog.actId, info.idx)
        local tipKey = info.page.key or "activityDesc"
        local condition = _myRwd.conditions[1]
        layout.activeTips:setString(Localizef(tipKey,{a=condition[2]}))
        local sumNum = dialog.context.activeData:getActRecord(self.actId, condition[1])[1]
        layout.labelBoxCurNum:setString(sumNum%condition[2].."/"..condition[2])
        local _process = (sumNum%condition[2])/condition[2]
        layout.progressUp:setProcess(true,_process)
        local _num = dialog.context.activeData:getSpecialNum(dialog.actId, _myRwd)
        layout.labelBoxNum:setString("X".._num)
        if _num > 0 then
            local act = ui.action.arepeat(ui.action.sequence({{"scaleTo", 0.5, 1.1, 1.1}, {"scaleTo", 0.5, 1, 1}, {"delay", 1} }))
            layout.btnReward.view:runAction(act)
        end
        layout.btnBack:setImage("images/box" .. info.idx .. "_1.png")
        layout.btnReward:setScriptCallback(ButtonHandler(function ()
            -- body
            if _num > 0 then
                GameLogic.doActAction(self.context, self.actId, info.idx, self, {num = _num})
                local csbPathbj = "UICsb/wcAct"..info.idx..".csb"
                local node = ui.csbNode(csbPathbj)
                local size = layout.btnReward.size
                display.adapt(node,size[1]/2,size[2]/2+60,GConst.Anchor.Center)
                layout.btnReward:addChild(node)
                local action = ui.csbTimeLine(csbPathbj)
                node:runAction(action)
                action:gotoFrameAndPlay(0,true)
            else
                display.pushNotice(Localize("notEnouchBox"))
            end
        end))
    end
end

function ActivityListDialog:checkCard(viewLayout, goBut)
    local stime = GameLogic.getSTime()
    --这里复用之前的代码，基本数据结构不改
    local item = GameLogic.getMonthCardData()[1].item
    if viewLayout and item then
        local isBuy = false
        local str
        if item.isget == 0 then
            if item.gnum>=item.anum then
                local remain2 = self.context.vips[5][2]-stime
                if remain2>0 then
                    local day = math.ceil(remain2/86400)
                    str = Localizef("labelRemainDay",{a=day})
                    viewLayout.btnRewardText:setString(Localize("labelRecive"))
                --强制逻辑,根据返回时间再次确定是否完成
                else isBuy = true
                    viewLayout.btnRewardText:setString(Localize("buttonGoBuy"))
                end
            else
                isBuy = true
                viewLayout.btnRewardText:setString(Localize("buttonGoBuy"))
            end
        else
            local remain2 = self.context.vips[5][2]-stime
            local day2 = math.ceil(remain2/86400)-1
            if day2>0 then
                str = Localize("labelAlreadyReceive") .. "，" .. Localizef("labelRemainDay",{a=day2})
                viewLayout.btnRewardText:setString(Localize("labelRenew"))
            else
                viewLayout.btnRewardText:setString(Localize("buttonGoBuy"))
            end
            isBuy = true
        end

        GameEvent.bindEvent(goBut.view,"TreasureChange",viewLayout,function ()
            if self.reloadPageView then
                self.selectedInfo.selected = false
                self:onUpdateLeftAct(self.selectedInfo.view, self.nodeActsTableView, self.selectedInfo)
                self:reloadPageView()
            end
        end)
        viewLayout.labelSubTime:setString(str)
        if isBuy then
            viewLayout.btnReward.view:setHValue(114)
            viewLayout.btnReward:setScriptCallback(Script.createCallbackHandler(function ()
            -- body
                if GameLogic.useTalentMatch then
                else
                    StoreDialog.new({id=1})
                end
            end,self))
        else
            viewLayout.btnReward:setScriptCallback(Script.createCallbackHandler(function ()
            -- body
                GameLogic.getactreward(item.atype,item.aid,function ()
                    -- body
                    GameEvent.sendEvent("TreasureChange")
                end)
            end,self))
        end
    end
end

function ActivityListDialog:openUrlAndAction(viewLayoutButton, urlRwd, urlType)
    local uType = {openUrl = 1, evaluate = 2, share = 3, daoliang = 4}
    if viewLayoutButton then
        if GameLogic.getUserContext().lockRate and urlType[2] == uType.evaluate then
            viewLayoutButton:setGray(true)
        end
        viewLayoutButton:setScriptCallback(Script.createCallbackHandler(function ()
            if GameLogic.getUserContext().lockRate and urlType[2] == uType.evaluate then
                return
            end
            if (urlRwd and urlRwd.conditions[1][1] == const.ActTypeOpenUrlAndGetReward) or urlType[2] == uType.daoliang then
                GameLogic.getUserContext().activeData:beginTcodeAct(self.act.actId)
            end

            if self.act.actId == 171260 then--短线关注
                GameLogic.addStatLog(11606, GameLogic.getLanguageType(), 1, 1)
            elseif self.act.actId == 171262 then--短线分享
                GameLogic.addStatLog(11603, GameLogic.getLanguageType(), 1, 1)
            elseif self.act.actId == 171263 then--短线评论
                GameLogic.addStatLog(11605, GameLogic.getLanguageType(), 1, 1)
            elseif self.act.actId == 201712074 then--长线评论
                GameLogic.addStatLog(11614, GameLogic.getLanguageType(), 1, 1)
            elseif self.act.actId == 201712072 then--长线关注
                GameLogic.addStatLog(11611, GameLogic.getLanguageType(), 1, 1)
            end

            if urlType[2] == uType.openUrl then
                local url = "https://www.facebook.com/ZombiesClashII"
                if self.act then
                    if self.act[General.language.."openUrl"] then
                        url = self.act[General.language.."openUrl"]
                    end
                end
                Plugins:openUrl(url)
                GameLogic.addStatLog(21003, 1, 0, 0)
            elseif urlType[2] == uType.evaluate then
                GameLogic.doRateAction(self.act.actGroup ~= 5)
                viewLayoutButton:setGray(true)
            elseif urlType[2] == uType.share then
                GameLogic.doShare("code")
            elseif urlType[2] == uType.daoliang then
                local statId
                local pm = GEngine.getPlatform()
                if pm ~= cc.PLATFORM_OS_ANDROID then
                    statId = 11702
                else
                    statId = 11701
                end
                Plugins:openUrl(urlType[3])
                GameLogic.addStatLog(statId, GameLogic.getLanguageType(), 1, 1)
            end
        end,self))
    end
end

--礼品码移至设置页面
-- function ActivityListDialog:updateGiftCodeUI(view)
--     local textBox = ui.textBox({809, 90}, Localize("labelInputPlaceHolder"), General.font6, 45, {align=cc.TEXT_ALIGNMENT_LEFT, back="images/inputBack.png"})
--     display.adapt(textBox, 0, 0, GConst.Anchor.Center)
--     view.activityInputCode:addChild(textBox)
--     self.textBox = textBox
--     view.btnRewardText:setString(Localize("btnReceive"))
--     view.btnReward:setScriptCallback(Script.createCallbackHandler(self.sendGiftCode,self))
-- end

-- function ActivityListDialog:sendGiftCode()
--     local str = self.textBox:getText()
--     if GameLogic.getStringLen(str)<=0 then
--         display.pushNotice(Localize("labelCantSendNothing"))
--         return
--     end
--     if not GameNetwork.lockRequest() then
--         return
--     end
--     _G["GameNetwork"].request("packCode",{code=str,language=General.language,uid=GameLogic.getUserContext().uid,zid=GameLogic.zid},function(isSuc,data)
--         GameNetwork.unlockRequest()
--         if isSuc then
--             if data.code==0 then
--                 display.pushNotice(Localize("noticePackCode0"))
--             elseif data.code==1 then
--                 display.pushNotice(Localize("noticePackCode1"))
--                 --刷新邮件
--                 GameLogic.getUserContext().logData:getEmailDatas()
--             elseif data.code==2 then
--                 display.pushNotice(Localize("noticePackCode2"))
--             elseif data.code==3 then
--                 display.pushNotice(Localize("noticePackCode3"))
--             end
--         end
--     end)
-- end

function ActivityListDialog:canExit()
    local myRwd = self.context.activeData:getConfigableRwds(self.actId, self.pageId)
    if myRwd and myRwd.isLottery then
        if self.refreshRotaryData then
            self:refreshRotaryData()
        end
    end
    return true
end
