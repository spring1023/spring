

local SData = GMethod.loadScript("data.StaticData")
--添加英雄熔炼对话框
local MeltingAddHeroDialog = class2("MeltingAddHeroDialog",function()
    return BaseView.new("MeltingAddHeroDialog.json",true)
end)

function MeltingAddHeroDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
end

function MeltingAddHeroDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))

    self:loadView("rightViews")

    self:loadView("leftBack")

    --选中的英雄
    self.heros = {}
    self.context = GameLogic.getUserContext()
    self.meltData = self.context.meltData
    self:reloadTableView()
    RegActionUpdate(self, Handler(self.updateMy, self, 0.2), 0.2)
end

function MeltingAddHeroDialog:reloadTableView()
    local infos={}
    for i=1,#self.heros do
        infos[i]={id=i,hero = self.heros[i]}
    end
    infos[#infos+1] = {id = #infos+1}

    if self.tableViewNode then
        self.tableViewNode:removeFromParent(true)
        self.tableViewNode = nil
    end
    self.tableViewNode = ui.node()
    self:addChild(self.tableViewNode)

    self:addTableViewProperty("heroTableViews",infos,Script.createBasicHandler(self.callCell,self))
    self:loadView("heroTableViews",self.tableViewNode)
    self:reloadOther()
end

function MeltingAddHeroDialog:reloadOther()
    local meltData = self.meltData
    local gaEnery = self.context:getProperty(const.ProGaEnery)
    self:insertViewTo()
    self.labelGaEneryRestore:setString(Localizef("labelGaEneryRestore",{a = self.meltData.gaEnerySpeed}))
    self.gaEneryProcess:setProcess(true,gaEnery/meltData.gaEneryMax)
    self.gaEneryProcessValue:setString(gaEnery .. "/" .. meltData.gaEneryMax)
    local value = 0
    --特定英雄炼金翻倍活动
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffAlchemyCrit)

    for i,v in ipairs(self.heros) do
        local alcosts = SData.getData("alcosts")
        local onev = alcosts[1][v.hid].get + alcosts[2][v.level].get + alcosts[3][v.soldierLevel].get
        + alcosts[4][v.mSkillLevel].get + (alcosts[5][v.starUp] and alcosts[5][v.starUp].get or 0)
        + (alcosts[6][v.awakeUp] and alcosts[6][v.awakeUp].get or 0)

        if buffInfo[4] == v.hid then
            value = value * alcosts[1][v.hid].crit
        end

        value = value+onev
    end

    self.get = value
    self.canGet:setString(Localize("labelSemltCanGet") .. value)
    local value = 0
    for i,v in ipairs(self.heros) do
        local alcosts = SData.getData("alcosts")
        local onev = alcosts[1][v.hid].cost + alcosts[2][v.level].cost + alcosts[3][v.soldierLevel].cost
        + alcosts[4][v.mSkillLevel].cost + (alcosts[5][v.starUp] and alcosts[5][v.starUp].cost or 0)
        + (alcosts[6][v.awakeUp] and alcosts[6][v.awakeUp].cost or 0)
        value = value+onev
    end
    self.cost = value
    self.consume:setString(Localize("labelConsumeGaEney") .. value)
    local gaStone = self.context:getProperty(const.ProGaStone)
    self.labelNowHaveValue:setString(gaStone)
    self.butMelting:setListener(function()
        if not self.runAnimate then
            if #self.heros<=0 then
                display.pushNotice(Localize("labelNoSemltHero"))
            elseif self.cost>gaEnery then
                display.pushNotice(Localize("labelGaEneryNo"))
            else
                self:beginsmelt()
            end
        end
    end)
    if #self.heros<=0 then
        self.butMelting:setGray(true)
    else
        self.butMelting:setGray(false)
    end
end

function MeltingAddHeroDialog:callCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    if info.id>#self.heros then
        self:loadView("heroCellBack2",bg)
        ui.setListener(cell,function()
            if #self.heros>=20 then
                display.pushNotice(Localize("labelSemltMore"))
            else
                MeltingChoseHeroDialog.new(self.heros,function(heros)
                    for i,v in ipairs(heros) do
                        table.insert(self.heros,v)
                    end
                    self:reloadTableView()
                end)
            end
        end)
    else
        self.heros[info.id].cell=cell

        GameUI.updateHeroTemplate(bg, info, info.hero)
        local tempImage = ui.sprite("images/btnClose4.png",{92,92})
        local temp = ui.button({92,92},function()
            table.remove(self.heros,info.id)
            self:reloadTableView()
        end,{})
        display.adapt(tempImage, 41, 41, GConst.Anchor.Center)
        temp:addChild(tempImage)
        display.adapt(temp, 212, 201, GConst.Anchor.Center)
        tempImage:setGlobalZOrder(3)
        bg:addChild(temp)
    end
end

function MeltingAddHeroDialog:updateMy(diff)
    local meltData = self.meltData
    local gaEnery = self.context:getProperty(const.ProGaEnery)
    meltData:initGaEnery()
    self.gaEneryProcess:setProcess(true,gaEnery/meltData.gaEneryMax)
    self.gaEneryProcessValue:setString(gaEnery .. "/" .. meltData.gaEneryMax)
end
------------------------------------------------------------------------
function MeltingAddHeroDialog:beginsmelt()
    self.runAnimate=true
    local idxArr = {}
    for i,v in ipairs(self.heros) do
        table.insert(idxArr,v.idx)
    end
    local meltData = self.meltData
    local context = self.context
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("beginsmelt",{beginsmelt = {idxArr}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            --print(data.hstone,self.get)
            --print_r(data)
            if data.hstone/self.get == 2 then
                display.pushNotice(Localizef("labelMeltSucceed2",{a = data.hstone}))
            else
                display.pushNotice(Localizef("labelMeltSucceed",{a = data.hstone}))
            end
            context:changeProperty(const.ProGaStone,data.hstone)
            context:setProperty(const.ProGaEnery,data.tenery)
            context:setProperty(const.ProGaTime,data.rgtime)
            for i,v in ipairs(idxArr) do
                context.heroData:removeHero(v)
            end
            if self.reloadTableView then
                --播放特效后移除
                for i,v in ipairs(self.heros) do
                    if cell then
                        local cell=v.cell
                        local bg=cell:getDrawNode()
                        bg:removeAllChildren(true)
                        UIeffectsManage:showEffect_melting(bg,119,114)
                    end
                end
                local function callRemove()
                    self.runAnimate=nil
                    self.heros = {}
                    self:reloadTableView()
                end
                self:runAction(ui.action.sequence({{"delay",0.7},{"call",callRemove}}))
            end
        end
    end)
end


return MeltingAddHeroDialog










