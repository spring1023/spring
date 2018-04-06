local const = GMethod.loadScript("game.GameLogic.Const")
PvhSettlementDialog = class(DialogViewLayout)
function PvhSettlementDialog:onInitDialog()
    local lid = self.context.nightmare and const.LayoutnPvh or const.LayoutPvh
    self:setLayout("PvhSettlementDialog.json")
    self:loadViewsTo()
    self.questionBut:setVisible(false)
    self.title:setString(Localize("titleSettlement"))
    self.btnGetReward:setScriptCallback(ButtonHandler(self.onGetReward, self))
end

function PvhSettlementDialog:onEnter()
    local bg = self.view
    local infos={}
    local heroData = self.context.heroData
    local addExp = {exp=0, star=0}
    local lid = self.context.nightmare and const.LayoutnPvh or const.LayoutPvh
    self.addExp = addExp
    for i=1,15 do
        local hero = heroData:getHeroByLayout(lid, i, 1)
        if hero then
            table.insert(infos, {hinfo={lvRT=true}, hero=hero})
        end
    end
    local tableView = ui.createTableView({1844, 979}, false, {size=cc.size(238,229), offx=52, offy=46, disx=58, disy=70, rowmax=6, infos=infos, cellUpdate=Handler(self.updateItemCell, self)})
    display.adapt(tableView.view, 55, 40, GConst.Anchor.LeftBottom)
    bg:addChild(tableView.view)
    self.infos = infos
    self.tableView = tableView

    if self.finished then
        self.labelSettlementReward:setString(Localizef("labelSettlementReward2",{num=self.canGetExp}))
    else
        self.labelSettlementReward:setString(Localizef("labelSettlementReward1",{num=self.canGetExp}))
    end
    self.isFirstIn=true
    self:reloadAllExps()
end

function PvhSettlementDialog:updateItemCell(cell,tableView,info)
    if not info.viewLayout then
        info.viewLayout = self:addLayout("SettlementCell", cell:getDrawNode())
        info.cell = cell
        info.viewLayout:loadViewsTo(info)
        cell:setEnable(false)
    end
    GameUI.updateHeroTemplate(info.nodeHeroBack.view, info.hinfo, info.hero)
end

function PvhSettlementDialog:reloadAllExps()
    for i,info in ipairs(self.infos) do
        if info.cell then
            local lv, _, _, exp, nextExp = info.hero:computeAddExp(self.addExp)
            local startLv,_,_,_,_ = info.hero:computeAddExp({exp=0, star=0})
            info.hinfo.labelLevel:setString(N2S(lv))
            if lv>startLv  and not info.showedEffect then
                info.showedEffect=true
                UIeffectsManage:showEffect_yonbingshenji(1,info.cell:getDrawNode(),238/2,229/2,10,1.3)
            end
            if not self.isFirstIn and not info.ainOver then
                info.ainOver=true
                local addExp=ui.label("+"..self.canGetExp.."Exp",General.font1, 35, {color={250,222,66}})
                display.adapt(addExp, 238/2, 229/2-50, GConst.Anchor.Center)
                info.cell:getDrawNode():addChild(addExp,12)
                addExp:runAction(ui.action.fadeTo(1,0))
                addExp:runAction(ui.action.sequence({{"easeSineOut",ui.action.moveBy(1,0,150)},"remove"}))
            end
            if nextExp==0 then
                nextExp = 1
                exp = 0
            end
            info.imgProcess:setProcess(true, exp/nextExp)
        end
    end
    self.isFirstIn=false
end

function PvhSettlementDialog:onGetReward()
    if GameNetwork.lockRequest() then
        self.btnGetReward:setEnable(false)
        self.btnGetReward:setGray(true)
        self.addExp.delta = 0
        self.addExp.total = 3
        if self.context.nightmare then
            self.context.npvh:endBattle()
        else
            self.context.pvh:endBattle()
        end
        RegUpdate(self.view, Handler(self.onUpdateExpAni, self), 0)
        GameNetwork.request("pvhend",{nightmare=self.context.nightmare},self.onResponseEndPvh,self)
        self.isAddExp = true
        if self.finished then
            GameLogic.doRateGuide("pvh", 6)
        end
    end
end

function PvhSettlementDialog:onResponseEndPvh(suc, data)
    GameNetwork.unlockRequest()
    log.d("test end pvh",suc,json.encode(data))
end

function PvhSettlementDialog:onExit()
    --加经验
    if self.isAddExp then
        local addExp={star=0,exp=self.canGetExp}
        for i,info in ipairs(self.infos) do
            info.hero:upgradeWithHeros(addExp)
        end
    end
    if self.context.nightmare then
        if not self.context.npvh:isInNightmareBattle() then
            display.closeDialog(1)        
            display.showDialog(PvhDialog.new{nightmare=true})
        end 
    else
        if not self.context.pvh:isInBattle() then
            display.closeDialog(1)        
            display.showDialog(PvhDialog)
        end
    end
end

function PvhSettlementDialog:onUpdateExpAni(diff)
    self.addExp.delta = self.addExp.delta+diff
    if self.addExp.delta>=self.addExp.total then
        self.addExp.delta = self.addExp.total
        UnregUpdate(self.view)
    end
    self.addExp.exp = math.floor(self.addExp.delta*self.canGetExp/self.addExp.total)
    self:reloadAllExps()
end
