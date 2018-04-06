local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

-- 选择
local EquipHeroSelectDialog = class(DialogViewLayout)

function EquipHeroSelectDialog:onInitDialog()
    self:setLayout("EquipHeroSelectDialog.json")
    self:loadViewsTo()

    self.hero = self.context.equipData:getHeroByEquip(self.equip)
    self.questionBut:setVisible(false)
    self.title:setString(Localize("titleHeroSelect"))
    self.btnEnsureChoose:setScriptCallback(ButtonHandler(self.onEnsureChoose, self))
end

local function sortFuncInEquip(h1, h2)
    local hero1 = h1.hero
    local hero2 = h2.hero
    local hasEquip1 = (hero1.equip ~= nil)
    local hasEquip2 = (hero2.equip ~= nil)
    if hasEquip1~=hasEquip2 then
        return hasEquip1
    else
        return GameLogic.sortExpHero(hero1, hero2)
    end
end

function EquipHeroSelectDialog:onEnter()
    self.nodeHeroTable:removeAllChildren(true)
    local infos = {}
    local heros = self.context.heroData:getAllHeros()
    for _, hero in pairs(heros) do
        if hero.info.job>0 then
            table.insert(infos, {hero=hero})
        end
    end
    table.sort(infos, sortFuncInEquip)
    local ts = self.nodeHeroTable:getSetting("tableSetting")
    local size = self.nodeHeroTable.size
    local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=infos, cellUpdate=Handler(self.updateHeroCell, self)})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
    self.nodeHeroTable.view:addChild(tableView.view)
    self.infos = infos
    self.tableView = tableView
end

local _heroSetting = {flagState=true, flagEquip=true}

function EquipHeroSelectDialog:updateHeroCell(cell, tableView, info)
    if not info.hinfo then
        info.cell = cell
        info.hinfo = {}
        if info.hero==self.hero then
            info.hinfo.selected = true
            self.selectedInfo = info
        end
        cell:setScriptCallback(ButtonHandler(self.onHeroSelect, self, info))
        cell:setBackgroundSound("sounds/heroSelected.mp3")
    end
    GameUI.updateHeroTemplate(cell:getDrawNode(), info.hinfo, info.hero, _heroSetting)
end

function EquipHeroSelectDialog:onHeroSelect(info)
    local oinfo = self.selectedInfo
    if info~=oinfo then
        if oinfo then
            oinfo.hinfo.selected = nil
            self:updateHeroCell(oinfo.cell, self.tableView, oinfo)
        end
        self.selectedInfo = info
        if info then
            info.hinfo.selected = true
            self:updateHeroCell(info.cell, self.tableView, info)
        end
    end
end

function EquipHeroSelectDialog:onEnsureChoose(force)
    local sinfo = self.selectedInfo
    if sinfo and sinfo.hero~=self.hero then
        local equip = self.equip
        local hero = sinfo.hero
        if hero.equip and not force then
            display.showDialog(AlertDialog.new(3, Localize("alertTitleNormal"),Localize("alertTextEquipAdded"),{callback=Handler(self.onEnsureChoose, self, true)}))
            return
        end
        self.context.equipData:changeEquipHero(equip, hero)
        if self.parent and not self.parent.deleted then
            self.parent:refreshInfos()
        end
        display.pushNotice(Localize("noticeEquipAdd"))
    end
    display.closeDialog(0)
end

local EquipPartGetDialog = class(DialogViewLayout)

function EquipPartGetDialog:onInitDialog()--左侧装备
    self:setLayout("EquipPartGetDialog.json")
    self:loadViewsTo()
    self.title:setString(Localize("titleEquipPartGet"))--获取部件
    self.btnBuyInStore:setScriptCallback(ButtonHandler(self.onOpenStore, self))
end

function EquipPartGetDialog:onEnter()
    local context = self.context
    local pid = self.pid
    local allStages = context.pvj:getStagesByEquipPart(pid)
    self.infos = allStages
    self.nodePvjTable:removeAllChildren(true)
    local size = self.nodePvjTable.size
    local ts = self.nodePvjTable:getSetting("tableSetting")
    local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=allStages, cellUpdate=Handler(self.updateStageCell, self)})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
    self.nodePvjTable.view:addChild(tableView.view)
    self.tableView = tableView
    tableView.view:setScrollEnable(false)
end

local _stageSetting = {flagLockIcon=true}
function EquipPartGetDialog:updateStageCell(cell, tableView, info)
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("PvjCell", cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        cell:setScriptCallback(ButtonHandler(self.onChoosePvjStage, self, info))
    end
    info.labelStageName:setString(info.name)
    GameUI.updateStageTemplate(info.nodeStageBack.view, info, _stageSetting)
end

function EquipPartGetDialog:onOpenStore()
    StoreDialog.new({stype="equip",idx=2,pri=display.getDialogPri()+1})
end

function EquipPartGetDialog:onChoosePvjStage(info)
    if info.lock then
        display.pushNotice(Localizef("noticeStageLock",{name=info.name}))
    else
        zombieIncomingDialog.new(nil,info.sid)
    end
end

local EquipPartDialog = class(DialogViewLayout)

function EquipPartDialog:onInitDialog()--右侧部件镶嵌选中时，跳出的部件界面
    self:setLayout("EquipPartDialog.json")
    self:loadViewsTo()
    self.title:setString(Localize("titleEquipPart"))--部件
    self.btnInstallPart:setScriptCallback(ButtonHandler(self.onInstall, self))
end

function EquipPartDialog:onEnter()
    local pidx = self.partId
    local equip = self.equip
    local pid, _, needNum,needLevel = equip:getPart(pidx)
    if pid~=self.displayPid then
        self.nodeItemBack:removeAllChildren(true)
        local setting = GameUI.itemIconConfig[const.ItemEquipPart .. "_" .. pid]
        GameUI.addItemBack2(self.nodeItemBack, setting[1], 1, 0, 0, 0)
        GameUI.addItemIcon(self.nodeItemBack, const.ItemEquipPart, pid, 0.6, 0, 0, false, false)
        self.displayPid = pid
        self.labelItemName:setString(GameLogic.getItemName(const.ItemEquipPart, pid))
        local itemKey=const.ItemEquipPart .. "_" .. pid
        local cr=GameUI.itemNameColor[GameUI.itemIconConfig[itemKey][1]]
        self.labelItemName:setColor(cr[1],cr[2],cr[3])
    end
    local canInstall = true
    self.labelItemEffect:setString(equip:getPartEffect(pidx))
    local cnum = self.context:getItem(const.ItemEquipPart, pid)
    self.labelCurrentNum:setString(N2S(cnum))
    self.btnInstallPart:setGray(false)
    if cnum>=needNum then
        self.labelCurrentNum:setColor(GConst.Color.White)
        self.labelBtnWord:setString(Localize("btnInstallPart"))--嵌入
    else
        self.labelCurrentNum:setColor(GConst.Color.Red)
        self.labelBtnWord:setString(Localize("titleEquipPartGet"))--获取部件
        canInstall = false
    end
    self.labelNeedNum:setString(N2S(needNum))
    if equip.level<needLevel then
        if canInstall then
            self.btnInstallPart:setGray(true)
            canInstall = false
        end
        self.labelErrorNotice:setString(Localizef("noticeEquipLevel",{level=needLevel}))--需要装备等级
    elseif canInstall then
        self.labelErrorNotice:setString("")
    else
        self.labelErrorNotice:setString(Localize("noticePartNotEnough"))--部件数量不足
    end
end

function EquipPartDialog:onInstall()
    local pidx = self.partId
    local equip = self.equip
    local pid, _, needNum,needLevel = equip:getPart(pidx)
    local cnum = self.context:getItem(const.ItemEquipPart, pid)
    if cnum<needNum then
        display.showDialog(EquipPartGetDialog.new({parent=self.parent, context=self.context, pid=pid}))
    elseif equip.level<needLevel then
        display.pushNotice(Localizef("noticeEquipLevel",{level=needLevel}))--装备等级
    else
        self.context.equipData:installEquipPart(equip, pidx)
        if self.parent and not self.parent.deleted then
            self.parent:onEnter()
            self.parent:refreshMainParts()
        end
        if equip.hidx and equip.hidx>0 then
            local hero = self.context.heroData:getHero(equip.hidx)
            self.context.heroData:setCombatData(hero)
        end
        display.closeDialog(0)
    end
end

local EquipDetailsDialog = class(DialogViewLayout)

function EquipDetailsDialog:onInitDialog()--装备右侧加成属性按钮界面
    self:setLayout("EquipDetailsDialog.json")
    self:loadViewsTo()

    self.centerInfo = {}
    self.title:setString(Localize("titleEquipDetails"))--装备加成属性
end

function EquipDetailsDialog:onEnter()
    GameUI.updateEquipTemplate(self.nodeEquipCenter.view, self.centerInfo, self.equip)
    self.labelName:setString(GameLogic.getItemName(const.ItemEquip, self.equip.eid))
    GameUI.setHeroNameColor(self.labelName, self.equip.color)
    local infos = self.equip:getDetailInfos()
    for i, info in ipairs(infos) do
        self["labelEquipEffect" .. i]:setString(info)
    end
end

local EquipUpgradeDialog = class(DialogViewLayout)

function EquipUpgradeDialog:onInitDialog()--装备升级按钮
    self:setLayout("EquipUpgradeDialog.json")
    self:loadViewsTo()

    self.centerInfo = {}
    self.title:setString(Localize("titleEquipUpgrade"))
    self.questionBut:setVisible(false)
    self.btnBuyInStore:setScriptCallback(ButtonHandler(self.onBuyInStore, self))
    self.btnChallengePvj:setScriptCallback(ButtonHandler(self.onChallengePvj, self))
end

function EquipUpgradeDialog:onChallengePvj()
    zombieIncomingDialog.new()
end

function EquipUpgradeDialog:onBuyInStore()
    StoreDialog.new({stype="equip",idx=2})
end

function EquipUpgradeDialog:onEnter()
    self.labelName:setString(GameLogic.getItemName(const.ItemEquip, self.equip.eid))
    GameUI.setHeroNameColor(self.labelName, self.equip.color)
    self:reloadLevelData()
    self:reloadExpData()
    self:reloadStones()
end

function EquipUpgradeDialog:reloadLevelData()
    local infos = self.equip:getDetailInfos()
    GameUI.updateEquipTemplate(self.nodeEquipCenter.view, self.centerInfo, self.equip)
    for i, info in ipairs(infos) do
        self["labelEquipEffect" .. i]:setString(info)
    end
end

function EquipUpgradeDialog:reloadExpData()
    local exp, max = self.equip:getExpInfos()
    if max==0 then
        self.imgProcess:setProcess(true, 1)
        self.labelProcess:setString(Localize("labelLevelMax"))
    else
        self.imgProcess:setProcess(true, exp/max)
        self.labelProcess:setString(exp .. "/" .. max)
    end
end

function EquipUpgradeDialog:reloadStones()
    if not self.infos then
        self.infos = {}
        for i=1, 4 do
            self.infos[i] = {}
        end
    end
    local idx = 0
    for i=1, 4 do
        local num = self.context:getItem(const.ItemEquipStone, i)
        if num>0 then
            idx = idx+1
            self.infos[idx].id = i
            self.infos[idx].num = num
        end
    end
    if idx==0 then
        self.nodeMyStones1:setVisible(false)
        self.nodeMyStones2:setVisible(true)
    else
        for i=idx+1, 4 do
            self.infos[i].num = 0
        end
        self.nodeMyStones1:setVisible(true)
        self.nodeMyStones2:setVisible(false)
        if not self.tableView then
            local size = self.nodeStonesTable.size
            local ts = self.nodeStonesTable:getSetting("tableSetting")
            local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, sizeChange=ts.sizeChange, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=self.infos, cellUpdate=Handler(self.updateStoneCell, self)})
            display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
            self.nodeStonesTable.view:addChild(tableView.view)
            tableView.view:setScrollEnable(false)
            self.tableView = tableView
        else
            for _,info in ipairs(self.infos) do
                self:updateStoneCell(info.cell, self.tableView, info)
            end
        end
    end
end

function EquipUpgradeDialog:updateStoneCell(cell, tableView, info)
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("StoneCell", cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        cell:setScriptCallback(ButtonHandler(self.onStoneAction, self, info))
        cell:setAutoHoldTime(0.5)
        cell:setAutoHoldTimeTemp(0.1)
    end
    if info.num==0 then
        cell:setVisible(false)
    else
        if info.id~=info.displayId then
            info.nodeItemBack:removeAllChildren(true)
            info.displayId = info.id
            info.nameLabel:setString(StringManager.getString("dataItemName" .. const.ItemEquipStone .. "_" .. info.id))
            local _, numLabel = GameUI.addItemIcon(info.nodeItemBack, const.ItemEquipStone, info.id,  0.934, 92, 92, true, false, {itemNum=info.num})
            info.numLabel=numLabel
        end
        info.numLabel:setString(info.num)
        cell:setVisible(true)
    end
end

function EquipUpgradeDialog:onStoneAction(info)
    if info.num>0 and info.id>0 then
        local edata = self.context.equipData
        local result = edata:upgradeEquip(self.equip, info.id)
        if result==-1 then
            display.pushNotice(Localize("noticeEquipLevelMax"))
        elseif result>=0 then
            info.num = info.num-1
            self:reloadStones()
            self:reloadExpData()
            display.pushNotice(Localize("noticeUseStone"))
            music.play("sounds/eqStoneUse.mp3")
            if result==1 then
                self:reloadLevelData()
                if self.parent and not self.parent.deleted then
                    self.parent:onEnter()
                    self.parent:refreshMainParts()
                end
                local hidx = self.equip.hidx
                if hidx and hidx>0 then
                    local hero = self.context.heroData:getHero(hidx)
                    self.context.heroData:setCombatData(hero)
                end
                -- 日常任务装备升级
                GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroEqLevelUp,1)
                UIeffectsManage:showEffect_yonbingshenji(1,self.nodeEquipCenter.view,119,114,3,1.5)
                music.play("sounds/eqUpgrade.mp3")
            end
        end
    end
end

local EquipLvupDialog = class(DialogViewLayout)

function EquipLvupDialog:onInitDialog()--装备进阶
    self:setLayout("EquipLvupDialog.json")
    self:loadViewsTo()

    self.title:setString(Localize("btnAdvanced"))--进阶
    self.btnLvupEquip:setScriptCallback(ButtonHandler(self.onLvupEquip, self))
end

function EquipLvupDialog:onEnter()
    local equip = self.equip
    local lvupData = equip:getLvupDatas()
    local name = GameLogic.getItemName(const.ItemEquip, equip.eid)
    self.labelCostNotice:setString(Localizef("noticeLvupEquip",{name=name, num=self.context:getItem(const.ItemEquipFrag, equip.eid), cost=lvupData.cost}))
    if self.context:getItem(const.ItemEquipFrag, equip.eid)<lvupData.cost then
        self.labelCostNotice:setColor(255,57,57)
    else
        self.labelCostNotice:setColor(81,255,28)
    end
    self.nodeLvupTable:removeAllChildren(true)
    self.needNum = lvupData.cost
    self.needLevel = lvupData.needLevel
    local size = self.nodeLvupTable.size
    local ts = self.nodeLvupTable:getSetting("tableSetting")
    local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, sizeChange=ts.sizeChange, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=lvupData.infos, cellUpdate=Handler(self.updateLvupEquipCell, self)})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
    self.nodeLvupTable.view:addChild(tableView.view)
    self.tableView = tableView
end

function EquipLvupDialog:updateLvupEquipCell(cell, tableView, info)
    if not info.viewLayout then
        info.viewLayout = self:addLayout("InfoCell", cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
    end
    local x, y, h, oy
    info.labelLeft:setString(info.left)
    info.labelLeftAdd:setString(info.leftAdd)
    h = info.labelLeft.size[2]
    info.labelRight:setString(info.right)
    info.labelRightAdd:setString(info.rightAdd)
    if info.labelRight.size[2]>h then
        h = info.labelRight.size[2]
    end
    oy = 0
    if h<72 then
        oy = (72-h)/2
        h = 72
    end
    x, y = info.imgPointer:getPosition()
    if info.type==1 then
        info.imgPointer:setSize(95, 62)
        info.imgPointer:setPosition(x, h/2)
    else
        local eprefix = Localize("labelEquipSkill")--装备特殊技能
        info.labelLeft2:setString(eprefix)
        info.labelRight2:setString(eprefix)
        h = h+72
        info.imgPointer:setSize(101, 72)
        info.imgPointer:setPosition(x, h-80)
        x, y = info.labelLeft2:getPosition()
        info.labelLeft2:setPosition(x, h-oy)
        x, y = info.labelRight2:getPosition()
        info.labelRight2:setPosition(x, h-oy)
        oy = oy+72

        info.labelLeft:setSize(440,0)
        info.labelRight:setSize(440,0)
    end

    x, y = info.labelLeft:getPosition()
    info.labelLeft:setPosition(x, h-oy)
    info.labelLeftAdd:setPosition(x+140, h-oy)
    x, y = info.labelRight:getPosition()
    info.labelRight:setPosition(x, h-oy)
    info.labelRightAdd:setPosition(x+400, h-oy)
    cell:setContentSize(cc.size(1317, h))
end

function EquipLvupDialog:onLvupEquip()--升级或进阶装备条件
    local equip = self.equip
    for i=1, 5 do
        local _, curNum = equip:getPart(i)
        if curNum==0 then
            display.pushNotice(Localize("noticeLvupError1"))--还有部件未激活，无法进阶
            music.play("sounds/eqLvUpDef.mp3")
            return
        end
    end
    if self.needNum>self.context:getItem(const.ItemEquipFrag, equip.eid) then
        display.pushNotice(Localizef("noticeLvupError2",{name=GameLogic.getItemName(const.ItemEquip, equip.eid)}))
        music.play("sounds/eqLvUpDef.mp3")
        return
    end
    if equip.level<self.needLevel then
        display.pushNotice(Localize("noticeLvupError3"))--装备未达到最高等级，无法进阶
        music.play("sounds/eqLvUpDef.mp3")
        return
    end
    self.context.equipData:lvupEquip(equip)
    music.play("sounds/eqLvUpSuc.mp3")
    if self.parent and not self.parent.deleted then
        self.parent:onEnter()
        self.parent:refreshMainParts()
    end
    local hidx = self.equip.hidx
    if hidx and hidx>0 then
        local hero = self.context.heroData:getHero(hidx)
        self.context.heroData:setCombatData(hero)
    end
    display.closeDialog(0)
end

EquipDialog = class(DialogViewLayout)

function EquipDialog:onInitDialog()--装备工厂
    if self.parent then
        self.priority = display.getDialogPri()+1
    else
        --self.priority = 1
    end

    self:setLayout("EquipDialog.json")
    self:loadViewsTo()
    local equipParts = {}
    self.centerInfo = {}
    self.equipParts = equipParts
    for i=1, 5 do
        equipParts[i] = {button=self["btnEquipPart" .. i], state=0}
        equipParts[i].button:setScriptCallback(ButtonHandler(self.onEquipPart, self, i))
    end
    self.title:setString(BU.getBuildName(const.EquipBase))
    self.btnAddition:setScriptCallback(ButtonHandler(self.onDetails, self))
    self.btnUpgrade:setScriptCallback(ButtonHandler(self.onUpgrade, self))
    self.btnAdvanced:setScriptCallback(ButtonHandler(self.onLvupEquip, self))
    self.btnOneKeyLevelUp:setVisible(false)
    if GameLogic.useTalentMatch then
        self.btnOneKeyLevelUp:setVisible(true)
        self.btnOneKeyLevelUp:setScriptCallback(ButtonHandler(self.oneKeyLvupEquip, self))
    end
    self.btnExplain:setScriptCallback(ButtonHandler(self.onExplainEquip, self))
end

function EquipDialog:onDetails()
    if self.selectedEquip then
        display.showDialog(EquipDetailsDialog.new({context=self.context, parent=self, equip=self.selectedEquip}))
    end
end

function EquipDialog:onUpgrade()
    if self.selectedEquip then
        display.showDialog(EquipUpgradeDialog.new({context=self.context, parent=self, equip=self.selectedEquip}))
    end
end

function EquipDialog:onLvupEquip()
    if self.selectedEquip then
        display.showDialog(EquipLvupDialog.new({context=self.context, parent=self, equip=self.selectedEquip}))
    end
end

function EquipDialog:oneKeyLvupEquip()
    if self.selectedEquip then
        local equip = self.selectedEquip
        local lvupData = equip:getLvupDatas()
        local needLv = lvupData.needLevel--进阶所需等级
        local needFrag = lvupData.cost--进阶所需碎片
        local curFrag = self.context:getItem(const.ItemEquipFrag, equip.eid)--当前拥有碎片数量
        local curLv = equip.level--当前等级
        local cureLvup = equip.elvup--当前升阶数(未升为0)
        local needExp = 0--进阶需要的经验
        local needCrystal = 0--进阶需要的宝石
        local useRes = {}--进阶需要消耗的资源
        if curLv < needLv then--等级不足
            local eData = SData.getData("elevels", equip.eid)
            local startIdx = curLv + cureLvup
            local endIdx = needLv + cureLvup
            for i=startIdx,endIdx-1 do
                needExp = needExp + eData[i].exp
            end
            needCrystal = needCrystal + needExp/60
            self.upLv = needLv - curLv
        end
        if curFrag < needFrag then--碎片不足
            local rating = SData.getData("equipInfoNew", equip.eid).rating
            local price = {100, 200, 400}
            needCrystal = needCrystal + (needFrag-curFrag)*price[rating]
            self.delFrag = curFrag
            table.insert(useRes, {const.ItemEquipFrag, equip.eid, curFrag})
        else
            self.delFrag = needFrag
            table.insert(useRes, {const.ItemEquipFrag, equip.eid, needFrag})
        end
        for i=1,5 do--部件不足
            local pid, setedNum, needNum,needLevel = equip:getPart(i)--3001(材料ID) 10(已镶嵌) 10(要求数量) 3(要求等级)
            local cnum = self.context:getItem(const.ItemEquipPart, pid)--当前库存数量(未镶嵌)
            if setedNum == 0 then--未镶嵌
                if cnum < needNum then--存货不足
                    local rating = SData.getData("property", const.ItemEquipPart, pid).value
                    local price = {9, 12, 100, 120}
                    needCrystal = needCrystal + (needNum-cnum)*price[rating]
                    table.insert(useRes, {const.ItemEquipPart, pid, cnum})
                else--存货充足
                    table.insert(useRes, {const.ItemEquipPart, pid, needNum})
                end
            else--已镶嵌
                --前后端都直接清除掉已镶嵌的
            end
        end
        needCrystal = math.ceil(needCrystal)
        self.needCrystal = needCrystal
        table.insert(useRes, {const.ResCrystal, equip.eid, needCrystal})
        self.useRes = useRes

        display.showDialog(AlertDialog.new(1,Localize("labOneKeyLevelUp"),Localizef("alertTextOneKeyLevelUp", {n = needCrystal}),
        {ctype=const.ResCrystal, cvalue=needCrystal, callback=Handler(self.oneKeyLevelUp, self, true)}))
    end
end

function EquipDialog:oneKeyLevelUp()
    local equip = self.selectedEquip
    self.context.equipData:upgradeEquip(equip, 0, {type = "oneKey", lv=self.upLv or 0})
    self.context.equipData:lvupEquip(equip, {type="oneKey", useRes = self.useRes, frag = self.delFrag, lv=self.upLv or 0, needCrystal = self.needCrystal})
    music.play("sounds/eqLvUpSuc.mp3")
    UIeffectsManage:showEffect_yonbingshenji(1,self.nodeEquipCenter.view,119,114,3,3)
    self:onEnter()
    self:refreshMainParts()
    local hidx = equip.hidx
    if hidx and hidx>0 then
        local hero = self.context.heroData:getHero(hidx)
        self.context.heroData:setCombatData(hero)
    end
end

local function _sortEquip(e1, e2)
    local equip1 = e1.equip
    local equip2 = e2.equip

    local eh1 = equip1.hidx>0
    local eh2 = equip2.hidx>0
    if eh1 ~= eh2 then
        return eh1
    end
    if equip1.color~=equip2.color then
        return equip1.color>equip2.color
    elseif equip1.level~=equip2.level then
        return equip1.level>equip2.level
    else
        return equip1.eid<equip2.eid
    end
end

function EquipDialog:onExit()
    if self.parent and not self.parent.deleted then
        if self.parent.reloadAll then
            self.parent:reloadAll()
        end
    end
end

function EquipDialog:onEnter()
    local eventNode = ui.node()
    self.view:addChild(eventNode)
    GameEvent.bindEvent(eventNode,"refreshDialog",self,function()
        self:refreshMainParts()
    end)
    self.nodeEquipTable:removeAllChildren(true)
    self.questionTag = "dataQuestionEquip"
    local equips = self.context.equipData:getAllEquips()
    local infos = {}
    local emap = {}
    local selectedEidx = self.selectedEidx
    local eitem
    local selectedEquip = nil
    for i, equip in pairs(equips) do
        eitem = {equip=equip, einfo={}, hinfo={}}
        if equip.idx==selectedEidx then
            eitem.einfo.selected = true
            selectedEquip = eitem
        end
        table.insert(infos,eitem)
        emap[equip.idx] = eitem
    end
    table.sort(infos, _sortEquip)
    local enum = #infos
    if not selectedEidx and enum>0 then
        selectedEidx = infos[1].equip.idx
        self.selectedEidx = selectedEidx
        infos[1].einfo.selected = true
        selectedEquip = infos[1]
    end
    for i, eitem in ipairs(infos) do
        eitem.idx = i
    end
    infos[enum+1] = {idx=enum+1, einfo={type="add"}, hinfo={}}
    self.infos = infos
    self.emapInfos = emap
    local size = self.nodeEquipTable.size
    local ts = self.nodeEquipTable:getSetting("tableSetting")
    local tableView = ui.createTableView(size, ts.isX, {cellActionType=ts.actionType, size=cc.size(ts.sx,ts.sy), offx=ts.ox, offy=ts.oy, disx=ts.dx, disy=ts.dy, rowmax=ts.rowmax, infos=infos, cellUpdate=Handler(self.updateEquipCell, self)})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
    self.nodeEquipTable.view:addChild(tableView.view)
    self.tableView = tableView
    self:onChooseEquip(selectedEquip)
end

function EquipDialog:refreshInfos()
    self:onEnter()
end

function EquipDialog:updateEquipCell(cell, tableView, info)
    if not cell then
        return
    end
    if not info.viewLayout then
        info.viewLayout = self:addLayout("EquipCell",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        info.btnChooseEquip:setScriptCallback(ButtonHandler(self.onChooseEquip, self, info))
        info.btnChooseHero:setScriptCallback(ButtonHandler(self.onChooseHero, self, info))
        info.btnCancelEquip:setScriptCallback(ButtonHandler(self.onCancelEquip, self, info))
    end
    local equip = info.equip
    local hero = self.context.equipData:getHeroByEquip(equip)
    GameUI.updateEquipTemplate(info.btnChooseEquip, info.einfo, equip)
    GameUI.updateHeroTemplate(info.btnChooseHero, info.hinfo, hero)
    if not hero then
        info.btnCancelEquip:setVisible(false)
    else
        info.btnCancelEquip:setVisible(true)
    end
    local parts = info.einfo.parts
    if not parts then
        parts = {}
        for i=1, 5 do
            parts[i] = {pid=0}
        end
        info.einfo.parts = parts
    end
    for i,part in ipairs(parts) do
        local state = 0
        local pid,curNum,needNum,needLevel = 0,0,0,0
        if equip then
            pid,curNum,needNum,needLevel = equip:getPart(i)
            if curNum>0 then
                state = pid
            elseif needNum==0 or equip.level<needLevel then
                state = 1
            elseif self.context:getItem(const.ItemEquipPart, pid)>=needNum then
                state = 2
            else
                state = 3
            end
        end
        if not part.viewNode then
            part.viewNode = ui.shlNode()
            info["nodeEquipPart" .. i].view:addChild(part.viewNode)
        end

        if state~=part.state then
            part.state = state
            if state==0 then
                part.viewNode:setVisible(false)
            else
                part.viewNode:setVisible(true)
                part.viewNode:removeAllChildren(true)
                GameUI.addItemIcon(part.viewNode, const.ItemEquipPart, pid, 0.9, 0, -10,false,true,{itemBackScale=1.25})
                if state<10 then
                    local temp = ui.sprite("images/btnAddNum.png")
                    display.adapt(temp, 0, -10, GConst.Anchor.Center)
                    part.viewNode:addChild(temp)
                    if state==2 then
                        temp:setHValue(90)
                    end
                    temp:setScale(1.2)
                end
                if state==1 then
                    part.viewNode:setSValue(-100)
                else
                    part.viewNode:setSValue(0)
                end
            end
        end
    end
end

function EquipDialog:onChooseEquip(info)
    local newEidx = nil
    if info then
        if info.equip then
            newEidx = info.equip.idx
        else
            local function refreshDialog()
                self:onEnter()
            end
            StoreDialog.new({idx=1,stype="equip",closeDialogCallback=refreshDialog})
            return
        end
    end
    local reuse = nil
    if self.selectedEidx then
        local oinfo = self.emapInfos[self.selectedEidx]
        oinfo.einfo.selected = nil
        if oinfo.btnChooseEquip then
            reuse = GameUI.resetTemplateSelect(oinfo.btnChooseEquip.view, oinfo.einfo, true)
        else
            print("old select")
        end
    end
    self.selectedEidx = newEidx
    self.selectedEquip = info and info.equip

    if self.selectedEquip and self.selectedEquip.level <= 1 and self.selectedEquip:getExpInfos() <= 0 then
        self.btnExplain:setVisible(true)
    else
        self.btnExplain:setVisible(false)
    end

    local showAll
    if newEidx then
        self.nodeEquipInfo:setVisible(true)
        info.einfo.selected = true
        if info.btnChooseEquip then
            GameUI.resetTemplateSelect(info.btnChooseEquip.view, info.einfo, reuse)
        end
        self.btnAddition:setVisible(true)
        self.btnUpgrade:setVisible(true)
        self.btnAdvanced:setVisible(true)
        self.labelEquipName:setString(info.equip:getName())
        GameUI.setHeroNameColor(self.labelEquipName, info.equip.color)
        self.labelEquipSkillTips:setString(info.equip:getDesc())
    else
        self.nodeEquipInfo:setVisible(false)
    end
    self:refreshMainParts()
end

function EquipDialog:refreshMainParts()
    local equip = self.selectedEquip
    if equip then
        local einfo = self.emapInfos[self.selectedEidx]
        if einfo then
            self:updateEquipCell(einfo.view, self.tableView, einfo)
        end
    end
    GameUI.updateEquipTemplate(self.nodeEquipCenter.view, self.centerInfo, equip)
    if equip then
        self.btnAdvanced:setVisible(equip.elvup<15)
        if GameLogic.useTalentMatch then
            self.btnOneKeyLevelUp:setVisible(equip.elvup<15)
        end
    end
    for idx,part in ipairs(self.equipParts) do
        local state = 0
        local pid,curNum,needNum,needLevel = 0,0,0,0
        if equip then
            pid,curNum,needNum,needLevel = equip:getPart(idx)
            if curNum>0 then
                state = pid
            elseif needNum==0 or equip.level<needLevel then
                state = 1
            elseif self.context:getItem(const.ItemEquipPart, pid)>=needNum then
                state = 2
            else
                state = 3
            end
        end
        if state~=part.state then
            part.state = state
            if state==0 then
                part.button:setVisible(false)
            else
                part.button:setVisible(true)
                part.button:removeAllChildren(true)
                --GameUI.addItemIcon(part.button, const.ItemEquipPart, pid, 0.6, 80, 80,false,true,{itemBackScale=1.6})
                if state<10 then
                    local temp = ui.sprite("images/btnAddNum.png")
                    display.adapt(temp, 80, 80, GConst.Anchor.Center)
                    part.button:addChild(temp,2)
                    if state==2 then
                        temp:setHValue(90)
                    end
                end
                if state==1 then
                    part.button:setGray(true)
                else
                    part.button:setGray(false)
                end
            end
        end
        if state~=0 then
            GameUI.addItemIcon(part.button, const.ItemEquipPart, pid, 0.6, 80, 80,false,true,{itemBackScale=1.6})
        end
    end
end

function EquipDialog:onChooseHero(info)
    if info.equip then
        display.showDialog(EquipHeroSelectDialog.new({parent=self,context=self.context,equip=info.equip}))
    end
end

function EquipDialog:onCancelEquip(info)
    if info.equip and info.equip.hidx>0 then
        self.context.equipData:changeEquipHero(info.equip, nil)
        self:updateEquipCell(info.view, self.tableView, info)
        display.pushNotice(Localize("noticeEquipCancel"))
        self:onEnter()
    end
end

function EquipDialog:onEquipPart(i)
    local part = self.equipParts[i]
    local equip = self.selectedEquip
    if part.state<10 and equip then
        display.showDialog(EquipPartDialog.new({parent=self, context=self.context, equip=equip, partId=i}))
    end
end

--装备分解
function EquipDialog:onExplainEquip(force)
    local equip = self.selectedEquip
    if not equip then
        display.pushNotice(Localize("noiceNotEquip"))
        return
    end
    local exp = equip:getExpInfos()
    local _lv = equip.level
    if exp>0 or _lv>1 then
        display.pushNotice(Localize("noiceEquipHaveExp"))
        return
    end
    if not force then
        display.showDialog(AlertDialog.new(3, Localize("btnEquipFragCollect"), Localizef("alertTextEquipFrag",{name=equip:getName(), num=equip:getFragNum()}),{callback=Handler(self.onExplainEquip, self, true)}))
    else
        self.context:addCmd({const.CmdEquipAnalysis, equip.idx})
        local rewards={{const.ItemEquipFrag,equip.eid,equip:getFragNum()}}
        GameLogic.addRewards(rewards)
        GameLogic.showGet(rewards)
        self.context.equipData:changeEquipHero(equip, nil)
        self.context.equipData:removeEquip(equip.idx)
        self.selectedEidx = nil
        self.selectedEquip = nil
        self:refreshInfos()
    end
end
