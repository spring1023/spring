local const = GMethod.loadScript("game.GameLogic.Const")

PlanDialog = class()

function PlanDialog:ctor(scene)
    self.scene = scene
    scene.onlineReward:setVisible(false)
    local context = GameLogic.getUserContext()
    self.context = context
    self.scene = scene
    self.clid = context:getInfoItem(const.InfoLayout)
    self.lid = self.clid
    self.mode = 0
    self.swallow = true
    self.priority = 0
    self.selectedItem = nil
    self.changed = false

    GameEvent.registerEvent({GameEvent.EventPlanSeted, GameEvent.EventPlanRecovery}, self, self.onPlanControl)
    GameEvent.sendEvent(GameEvent.EventStartPlan, self)
    GameEvent.sendEvent(GameEvent.EventPlanMode, self.mode)
    self:reloadView()
end

local planHOffs = {-146, 116, -72}
function PlanDialog:reloadView()
    if not self.view then
        local bg, temp = nil
        bg = ui.touchNode(display.winSize, 0, false)
        self.view = bg
        display.adapt(bg, 0, 0, GConst.Anchor.Center, {scale=1})
        local scale = ui.getUIScale2()
        local tc = ui.node()
        display.adapt(tc, 0, 0, GConst.Anchor.Top, {scale=scale})
        bg:addChild(tc)
        local but, bnode
        local buts = {}
        for i=1,3 do
            but = ui.button({210, 201}, self.onChangeLayout, {cp1=self, cp2=i})
            display.adapt(but, 269*(i-2), -113, GConst.Anchor.Center)
            tc:addChild(but)
            bnode = but:getDrawNode()
            temp = ui.sprite("images/btnMenuPlan.png",{210, 201})
            temp:setHValue(planHOffs[i])
            display.adapt(temp, 0, 0)
            bnode:addChild(temp)
            temp = ui.sprite("images/dialogItemPlanTown.png",{104, 120})
            display.adapt(temp, 108, 114, GConst.Anchor.Center)
            bnode:addChild(temp)
            temp = ui.label(tostring(i), General.font1, 60, {color={255,255,255}})
            display.adapt(temp, 149, 171, GConst.Anchor.Left)
            bnode:addChild(temp)
            buts[i] = bnode
        end
        self.buts = buts
        local bc = ui.node()
        display.adapt(bc, 0, 0, GConst.Anchor.Bottom, {scale=scale})
        bg:addChild(bc)

        but = ui.button({325, 126}, self.onSave, {cp1=self, image="images/btnGreen.png"})
        display.adapt(but, -440, 362, GConst.Anchor.Center)
        but:setHValue(114)
        bc:addChild(but)
        temp = ui.sprite("images/dialogItemConserve.png",{66, 67})
        display.adapt(temp, 62, 73, GConst.Anchor.Center)
        but:getDrawNode():addChild(temp)
        temp = ui.label(StringManager.getString("btnPlanSave"), General.font1, 40, {color={255,255,255}})
        display.adapt(temp, 200, 77, GConst.Anchor.Center)
        but:getDrawNode():addChild(temp)
        self.saveBut = but

        but = ui.button({325, 126},self.onExit, {cp1=self, image="images/btnGreen.png"})
        display.adapt(but, -440, 98, GConst.Anchor.Center)
        but:setHValue(114)
        bc:addChild(but)
        temp = ui.sprite("images/dialogItemQuit.png",{84, 71})
        display.adapt(temp, 62, 73, GConst.Anchor.Center)
        but:getDrawNode():addChild(temp)
        temp = ui.label(StringManager.getString("btnExit"), General.font1, 40, {color={255,255,255}})
        display.adapt(temp, 200, 77, GConst.Anchor.Center)
        but:getDrawNode():addChild(temp)

        but = ui.button({325, 126}, self.onChangeMode, {cp1=self, image="images/btnGreen.png"})
        display.adapt(but, 440, 362, GConst.Anchor.Center)
        but:setHValue(114)
        bc:addChild(but)
        bnode = but:getDrawNode()
        temp = ui.sprite("images/dialogItemRecovery.png",{118, 80})
        display.adapt(temp, 69, 72, GConst.Anchor.Center)
        bnode:addChild(temp)
        temp = ui.label(StringManager.getString("btnPlanMode" .. self.mode), General.font1, 40, {color={255,255,255}})
        display.adapt(temp, 217, 77, GConst.Anchor.Center)
        bnode:addChild(temp)
        self.modeLabel = temp

        but = ui.button({325, 126}, self.onRecoveryAll, {cp1=self, image="images/btnGreen.png"})
        display.adapt(but, 440, 98, GConst.Anchor.Center)
        but:setHValue(114)
        bc:addChild(but)
        bnode=but:getDrawNode()
        temp = ui.sprite("images/dialogItemRecoveryAll.png",{72, 72})
        display.adapt(temp, 62, 77, GConst.Anchor.Center)
        bnode:addChild(temp)
        temp = ui.label(StringManager.getString("btnPlanRecoveryAll"), General.font1, 40, {color={255,255,255}})
        display.adapt(temp, 207, 77, GConst.Anchor.Center)
        bnode:addChild(temp)
        
        local lc = ui.node({0,1536})
        display.adapt(lc, 0, 0, GConst.Anchor.Left, {scale=display.winSize[2]/1536})
        bg:addChild(lc)
        self.lc = lc
        temp = ui.sprite("images/dialogBackLeft.png",{325, 1536})
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        lc:addChild(temp)
        temp = ui.button({207, 156}, self.scrollUp, {cp1=self, image="images/btnUp.png"})
        display.adapt(temp, 154, 1449, GConst.Anchor.Center)
        lc:addChild(temp)
        temp = ui.button({207, 165}, self.scrollDown, {cp1=self, image="images/btnDown.png"})
        display.adapt(temp, 143, 110, GConst.Anchor.Center)
        lc:addChild(temp)
    end
    if not self.selectIcon then
        self.selectIcon = ui.sprite("images/dialogItemYes.png",{72, 86})
        display.adapt(self.selectIcon, 160, 81, GConst.Anchor.Center)
        self.buts[self.lid]:addChild(self.selectIcon)
    end
    if not self.selectBack then
        self.selectBack = ui.sprite("images/btnMenuPlan.png",{252, 241})
        ui.setBlend(self.selectBack, 768, 1)
        display.adapt(self.selectBack, 105, 100, GConst.Anchor.Center)
        self.selectBack:runAction(ui.action.arepeat({"sequence",{{"scaleTo",0.1,1.3,1.3},{"scaleTo",0.1,1.2,1.2},{"delay",1.3}}}))
        self.buts[self.lid]:addChild(self.selectBack, -1)
    end
    self:reloadScrollView()
end

function PlanDialog:scrollUp()
    self.tableView:moveViewTo(-1)
end

function PlanDialog:scrollDown()
    self.tableView:moveViewTo(1)
end

function PlanDialog:onExit(force)
    if not self.changed or force then
        GameEvent.sendEvent(GameEvent.EventPlanMode, 0)
        GameEvent.sendEvent(GameEvent.EventEndPlan, self)
        GameEvent.unregisterAllEvents(self)
        local scene = self.scene
        local builds = scene.builds
        for _, build in pairs(builds) do
            build:removeFromScene()
        end
        local lid = self.clid
        for id, layout in pairs(self.context.buildData.blayouts[lid]) do
            builds[id]:addToScene(scene, layout[1], layout[2])
        end
        display.closeDialog(0)
        scene.onlineReward:setVisible(true)
    else
        display.showDialog(AlertDialog.new(3,StringManager.getString("alertTitleNormal"),StringManager.getString("alertTextSaveBase2"),{callback=Handler(self.onExit, self, true)}))
    end
end

local function updatePlanBuildCell(cell,tableView,info)
    local bg=cell:getDrawNode()
    cell:setScriptCallback(Script.createCallbackHandler(info.dialog.selectCell, info.dialog, info))
    local temp
    info.cell = cell
    if not info.back then
        temp = ui.sprite("images/dialogItemPlanCell.png",{231,220})
        display.adapt(temp, 0, -6, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        info.back = temp
        temp = ui.label("", General.font1, 42, {color={255,255,255}})
        display.adapt(temp, 220, 220, GConst.Anchor.RightTop)
        bg:addChild(temp,1)
        info.numLabel = temp
        temp = ui.label("", General.font1, 42, {color={255,255,255}})
        display.adapt(temp, 115, 3, GConst.Anchor.Bottom)
        bg:addChild(temp,1)
        info.levelLabel = temp
    end
    if info.build then
        info.build:removeFromParent(true)
        info.build = nil
    end
    local newBuild = Build.new(info.bid,info.level)
    info.build = newBuild:addBuildView(bg, 115, 110, 231, 220, 1)
    info.numLabel:setString("x" .. info.num)
    info.levelLabel:setString(StringManager.getFormatString("labelLevelFormat", {level=info.level}))
    if info.selected then
        local reuseGrid = info.grid
        if not reuseGrid then
            reuseGrid = ui.sprite("images/dialogItemSelectGrid.png", {231,220})
            display.adapt(reuseGrid, 0, 0)
            bg:addChild(reuseGrid)
            info.grid = reuseGrid
        end
    else
        if info.grid then
            info.grid:removeFromParent(true)
            info.grid = nil
        end
    end
end

function PlanDialog:reloadScrollView()
    local scene = self.scene
    local builds = scene.builds
    for _, build in pairs(builds) do
        build:removeFromScene()
    end
    local lid = self.lid
    local cbuilds = self.context.buildData
    local layouts = self.forceLayouts
    local noAdds = {}
    local layout, gx, gy
    if not layouts then
        layouts = {}
        for id, build in pairs(builds) do
            if build.info.btype ~= 6 then
                layout = cbuilds:getBuildLayout(lid, build)
            else
                layout = cbuilds:getBuildLayout(self.clid, build)
            end
            gx, gy = layout[1], layout[2]
            layouts[id] = {gx, gy}
        end
        self.forceLayouts = layouts
    end
    --先加障碍物，再加建筑
    for id, build in pairs(builds) do
        if build.info.btype == 6 then
            layout = layouts[id]
            gx, gy = layout[1], layout[2]
            if (gx ~= 0 or gy ~= 0) and not scene.map.checkGridUse(gx, gy, build.info.size) then
                build:addToScene(scene, gx, gy)
            else
                noAdds[id] = build
            end
        end
    end
    for id, build in pairs(builds) do
        if build.info.btype ~= 6 then
            layout = layouts[id]
            gx, gy = layout[1], layout[2]
            if (gx ~= 0 or gy ~= 0) and not scene.map.checkGridUse(gx, gy, build.info.size) then
                build:addToScene(scene, gx, gy)
            else
                noAdds[id] = build
            end
        end
    end
    local infos = {}
    local infoMap = {}
    for id, build in pairs(noAdds) do
        local k = build.bid*10000 + build.level
        if infoMap[k] then
            infoMap[k].num = infoMap[k].num+1
            table.insert(infoMap[k].items, build)
        else
            local newInfo = {num=1, items={build}, bid=build.bid, level=build.level, dialog=self}
            table.insert(infos, newInfo)
            infoMap[k] = newInfo
        end
    end
    if self.tableView then
        self.tableView.view:removeFromParent(true)
        self.tableView = nil
    end
    if self.toPlanBuild then
        if self.toPlanBuild.removed then
            local k = self.toPlanBuild.bid*10000 + self.toPlanBuild.level
            self.selectedItem = infoMap[k]
            self.selectedItem.selected = true
        else
            self.toPlanBuild = nil
            self.selectedItem = nil
            GameEvent.sendEvent(GameEvent.EventPlanItem, nil)
        end
    end
    local tableView = ui.createTableView({325, 1088}, false, {size=cc.size(231,220), offx=28, offy=0, disx=0, disy=21, rowmax=1, infos=infos, cellUpdate=updatePlanBuildCell})
    display.adapt(tableView.view, 0, 236, GConst.Anchor.LeftBottom)
    self.lc:addChild(tableView.view)
    self.tableView=tableView
    self.infos = infos
    self.infoMap = infoMap
    self:refreshSaveBut()
end

function PlanDialog:selectCell(info)
    if self.selectedItem~=info then
        local reuseGrid = nil
        if self.selectedItem then
            if self.selectedItem.back then
                reuseGrid = self.selectedItem.grid
                reuseGrid:removeFromParent(false)
                reuseGrid = nil
                self.selectedItem.grid = nil
            end
            self.selectedItem.selected = nil
        end
        self.selectedItem = info
        if info then
            self.toPlanBuild = info.items[1]
            info.selected = true
            if info.back then
                if not reuseGrid then
                    reuseGrid = ui.sprite("images/dialogItemSelectGrid.png", {231,220})
                    display.adapt(reuseGrid, 0, 0)
                end
                info.cell:getDrawNode():addChild(reuseGrid)
                info.grid = reuseGrid
            end
        else
            self.toPlanBuild = nil
        end
        GameEvent.sendEvent(GameEvent.EventPlanItem, self.toPlanBuild)
    end
end

function PlanDialog:onChangeMode()
    self.mode = 1-self.mode
    if self.mode == 1 then
        display.pushNotice(Localize("stringGoPlayMode"))
    end
    self.modeLabel:setString(StringManager.getString("btnPlanMode" .. self.mode))
    GameEvent.sendEvent(GameEvent.EventPlanMode, self.mode)
end

function PlanDialog:refreshSaveBut()
    if self.infos  then
        if #(self.infos)==0 then
            if self.changed then
                self.saveBut:setSValue(0)
            else
                self.saveBut:setSValue(-100)
            end
        else
            self.saveBut:setSValue(0)
        end
    else
        if self.changed then
            self.saveBut:setSValue(0)
        else
            self.saveBut:setSValue(-100)
        end
    end
end

function PlanDialog:onSave()
    if #(self.infos)==0 and (self.changed or self.lid~=self.clid) then
        local context = self.context
        --将障碍物加上
        local forceLayouts = self.forceLayouts
        local scene = self.scene
        local builds = scene.builds
        local cbuilds = context.buildData
        context:changeLayout(self.lid, forceLayouts)
        self.changed = false
        display.pushNotice(StringManager.getString("noticeSaveSuccess"), {color=GConst.Anchor.White})
        self.clid = self.lid
        if self.selectIcon then
            self.selectIcon:retain()
            self.selectIcon:removeFromParent(false)
            self.buts[self.clid]:addChild(self.selectIcon)
            self.selectIcon:release()
        end
        self:refreshSaveBut()
    elseif #(self.infos) ~= 0 then
        display.pushNotice(Localize("stringNowHaveBuildNoSet"))
    end
end

function PlanDialog:onChangeLayout(lid, force)
    if lid~=self.lid then
        if not self.changed or force then
            self.lid = lid
            self.forceLayouts = nil
            self:reloadScrollView()
            self.changed = false
            if self.selectBack then
                self.selectBack:retain()
                self.selectBack:removeFromParent(false)
                self.buts[self.lid]:addChild(self.selectBack, -1)
                self.selectBack:release()
            end
        else
            display.showDialog(AlertDialog.new(3, StringManager.getString("alertTitleNormal"), StringManager.getFormatString("alertTextSaveBase", {num=lid}), {callback=Handler(self.onChangeLayout, self, lid, true)}))
        end
    end
end

function PlanDialog:onRecoveryAll()
    self.changed = true
    local layouts = self.forceLayouts
    local builds = self.scene.builds
    for id, build in pairs(builds) do
        local layout = layouts[id]
        if build.info.btype ~= 6 and layout then
            layout[1],layout[2] = 0,0
        end
    end
    self.selectedItem = nil
    self:reloadScrollView()
end

function PlanDialog:changeBuildLayout(idx, x, y)
    self.forceLayouts[idx][1], self.forceLayouts[idx][2] = x, y
    self.changed = true
    self:refreshSaveBut()
end

function PlanDialog:onPlanControl(event, build)
    local k = build.bid*10000 + build.level
    local item = self.infoMap[k]
    local layout = self.forceLayouts[build.id]
    self.changed = true
    if event==GameEvent.EventPlanSeted then
        if self.mode==1 then
            self:onChangeMode()
        end
        layout[1], layout[2] = build.vstate.gx, build.vstate.gy
        if not item then
            return
        end
        item.num = item.num-1
        table.remove(item.items, 1)
        if item.num==0 then
            local myidx = 0
            for i, item2 in ipairs(self.infos) do
                if item2==item then
                    myidx = i
                    break
                end
            end
            self:selectCell(self.infos[myidx+1] or self.infos[myidx-1])
            self.tableView:removeCell(myidx)
            self.infoMap[k] = nil
        else
            self.toPlanBuild = item.items[1]
            if item.numLabel then
                item.numLabel:setString("x" .. item.num)
            end
            GameEvent.sendEvent(GameEvent.EventPlanItem, self.toPlanBuild)
        end
    else
        layout[1], layout[2] = 0, 0
        if not item then
            item = {num=1, items={build}, bid=build.bid, level=build.level, dialog=self}
            self.tableView:addCell(item)
            self.infoMap[k] = item
        else
            item.num = item.num+1
            table.insert(item.items, build)
            if item.numLabel then
                item.numLabel:setString("x" .. item.num)
            end
        end
    end
    self:refreshSaveBut()
end
