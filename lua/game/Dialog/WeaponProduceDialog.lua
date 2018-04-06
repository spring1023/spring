local const = GMethod.loadScript("game.GameLogic.Const")

WeaponProduceDialog = class(DialogViewLayout)

function WeaponProduceDialog:onInitDialog()
    self.priority = 1
    self.questionTag = "dataQuestionWeaponProduce"
    self:setLayout("WeaponProduceDialog.json")
    self:loadViewsTo()

    self.title:setString(Localize("titleWeaponProduce"))
    self.btnFinish:setScriptCallback(ButtonHandler(self.onFinish, self))
    GameUI.addResourceIcon(self.nodeFinishCost.view, const.ResCrystal, 1, 0, 0)
    RegActionUpdate(self.view, Handler(self.onUpdate, self, 0.2), 0.2)
end

function WeaponProduceDialog:onUpdate(diff)
    self:updateProduceTime()
    self:updatePriceLabels()
end

function WeaponProduceDialog:onFinish()
    local weaponData = self.context.weaponData
    local stime = GameLogic.getSTime()
    local btime = weaponData:getProduceStartTime()
    local atime = weaponData:getAllUseTime()
    local cost = weaponData:computeCostByTime(atime+btime-stime)
    if cost==0 then
        return false
    end
    if cost>self.context:getRes(const.ResCrystal) then
        display.showDialog(AlertDialog.new({ctype=const.ResCrystal}))
    else
        music.play("sounds/buy.mp3")
        weaponData:finishProduceAtOnce(stime, cost)
    end
end

function WeaponProduceDialog:onCancelWeapon(cinfo, force)
    local idx = 1
    for i, info in ipairs(self.produceInfos) do
        if info==cinfo then
            if not force then
                display.showDialog(AlertDialog.new(4,Localize("alertTitleCancelWeapon"),Localize("alertTextCancelWeapon"),{callback=Handler(self.onCancelWeapon, self, cinfo, true)}))
            else
                if self.context.weaponData:cancelProduce(idx, info.id) then
                    self:reloadProduceList()
                end
            end
            break
        else
            idx = idx+info.num
        end
    end
end

function WeaponProduceDialog:onProduceWeapon(cinfo)
    if cinfo.id==0 or cinfo.level==0 then
        display.pushNotice(Localize("noticeNotWeapon"))
        return
    end
    for i, info in ipairs(self.availableInfos) do
        if info==cinfo then
            if self.context.weaponData:isWeaponFull() then
                display.pushNotice(Localize("noticeWeaponFull"))
            elseif info.cost then
                if info.cost>self.context:getRes(const.ResGold) then
                    display.showDialog(AlertDialog.new({ctype=const.ResGold, cvalue=info.cost, callback=Handler(self.onProduceWeapon, self, cinfo)}))
                else
                    if self.context.weaponData:produceWeapon(cinfo.id, GameLogic.getSTime()) then
                        self:reloadProduceList()
                    end
                end
            end
            return
        end
    end
end

function WeaponProduceDialog:onEnter()
    self:reloadProduceList()
    self:reloadAvailableList()
    self:reloadReadyList()
end

function WeaponProduceDialog:reloadProduceList()
    local weaponData = self.context.weaponData
    local produceInfos = self.produceInfos or {}
    self.produceInfos = produceInfos
    local pids = weaponData:getProduceList()
    self.labelProduceList:setString(#pids .. "/" .. const.MaxWeaponNum)
    local idx, wid = 0, 0
    for _, pid in ipairs(pids) do
        if pid~=wid then
            wid = pid
            idx = idx+1
            if not produceInfos[idx] then
                produceInfos[idx] = {}
            end
            produceInfos[idx].id = wid
            produceInfos[idx].num = 1
            produceInfos[idx].idx = idx
        else
            produceInfos[idx].num = produceInfos[idx].num+1
        end
    end
    self.pnum = #pids
    idx = idx+1
    while produceInfos[idx] do
        if produceInfos[idx].view then
            produceInfos[idx].view:removeFromParent(true)
        end
        table.remove(produceInfos,idx)
    end
    if #produceInfos>0 then
        self.nodeFinishBlock:setVisible(true)
        for _, info in ipairs(produceInfos) do
            if not info.view then
                info.view = ui.node({200, 200}, true)
                info.viewLayout = self:addLayout("WeaponProduceCell",info.view)
                info.viewLayout:loadViewsTo(info)
                self.nodeProduceList:addChild(info.view)
                info.btnMinus:setScriptCallback(ButtonHandler(self.onCancelWeapon, self, info))
            end
            info.nodeProcess:setVisible(info.idx==1)
            if info.viewId~=info.id then
                info.viewId = info.id
                info.nodeIconBack:removeAllChildren(true)
                GameUI.addWeaponIcon(info.nodeIconBack, 0, info.id, 296/226, 0, 0)
            end
            info.labelNum:setString(info.num .. "x")
            display.adapt(info.view, 1250-250*info.idx, 13)
        end
    else
        self.nodeFinishBlock:setVisible(false)
    end
    self:updateProduceTime()
end

function WeaponProduceDialog:updateProduceTime()
    if #(self.produceInfos)>0 then
        local weaponData = self.context.weaponData
        local pnum = weaponData:getProduceNum()
        if pnum~=self.pnum then
            self:reloadProduceList()
            self:reloadReadyList()
            return
        end
        local stime = GameLogic.getSFloatTime()
        local btime = weaponData:getProduceStartTime()
        local ntime = weaponData:getNextUseTime()
        local atime = weaponData:getAllUseTime()
        self.produceInfos[1].processFiller:setProcess(true, (stime-btime)/ntime)
        self.produceInfos[1].labelTime:setString(Localizet(ntime+btime-stime))
        self.labelTotalTime:setString(Localizet(atime+btime-stime))
        self.labelFinishCost:setString(weaponData:computeCostByTime(atime+btime-stime))
    end
end

function WeaponProduceDialog:updatePriceLabels()
    local current = self.context:getRes(const.ResGold)
    if self.availableInfos then
        for _, aitem in ipairs(self.availableInfos) do
            if aitem.id>0 and aitem.cost and aitem.labelCostNum then
                if aitem.cost>current then
                    aitem.labelCostNum:setColor(GConst.Color.Red)
                else
                    aitem.labelCostNum:setColor(GConst.Color.White)
                end
            end
        end
    end
end

function WeaponProduceDialog:reloadAvailableList()
    local weaponData = self.context.weaponData
    local availableInfos = self.availableInfos or {}
    self.availableInfos = availableInfos

    local allitems = weaponData:getAvailableWeapons()
    for i=1, 5 do
        if not availableInfos[i] then
            availableInfos[i] = {}
        end
        local item = allitems[i]
        if item then
            availableInfos[i].id = item.id
            availableInfos[i].level = item.level
            availableInfos[i].cost = item.cost
            availableInfos[i].unlockLevel = item.unlockLevel
            availableInfos[i].name = item.name
        else
            availableInfos[i].id = 0
        end
    end

    for idx, info in ipairs(availableInfos) do
        if not info.view then
            info.view = ui.button({368, 330}, self.onProduceWeapon, {cp1=self, cp2=info})
            info.viewLayout = self:addLayout("WeaponAvailableCell",info.view:getDrawNode())
            info.viewLayout:loadViewsTo(info)
            self.nodeAvailableList:addChild(info.view)
            GameUI.addResourceIcon(info.nodeCostIcon, const.ResGold, 0.66, 33, 33)
        end
        if info.id==0 then
            info.nodeBack1:setVisible(false)
            info.nodeBack2:setVisible(true)
            info.view:setEnable(false)
        else
            info.nodeBack1:setVisible(true)
            info.nodeBack2:setVisible(false)
            if info.viewId~=info.id then
                info.viewId = info.id
                info.nodeIconBack:removeAllChildren(true)
                info.icon = GameUI.addWeaponIcon(info.nodeIconBack, 0, info.id, 296/226, 0, 0)
                info.labelName:setString(info.name)
                if info.unlockLevel and info.unlockLevel>self.context.buildData:getBuild(const.WeaponBase).level then
                    info.labelStudyLevel:setString(info.name.."\n"..Localizef("labelStudyLevel",{a=info.unlockLevel}))
                else
                    info.labelStudyLevel:setString("")
                end
            end
            if info.level==0 then
                info.nodeLevels:setVisible(false)
                info.icon:setSValue(-100)
                info.labelStudyLevel:setVisible(true)
            else
                info.nodeLevels:setVisible(true)
                info.labelLevel:setString(info.level)
                info.labelCostNum:setString(tostring(info.cost))
                info.icon:setSValue(0)
                info.labelStudyLevel:setVisible(false)
            end
        end
        display.adapt(info.view, 10+388*(idx-1), 0)
    end
end

function WeaponProduceDialog:reloadReadyList()
    local weaponData = self.context.weaponData
    local readyInfos = self.readyInfos or {}
    self.readyInfos = readyInfos
    local allNums = weaponData:getAllWeapons()
    local totalReady = 0
    for i=1, 9 do
        if not readyInfos[i] then
            readyInfos[i] = {}
        end
        local numItem = allNums[i]
        if numItem then
            readyInfos[i].id = numItem[1]
            readyInfos[i].num = numItem[2]
            totalReady = totalReady+numItem[2]
        else
            readyInfos[i].id = 0
        end
    end

    self.labelWeaponReady:setString(totalReady .. "/" .. const.MaxWeaponNum)
    for idx, info in ipairs(readyInfos) do
        if not info.view then
            info.view = ui.node({160, 220}, true)
            info.viewLayout = self:addLayout("WeaponReadyCell",info.view)
            info.viewLayout:loadViewsTo(info)
            self.nodeReadyList:addChild(info.view)
        end
        if info.id==0 then
            info.nodeBack:setVisible(false)
        else
            info.nodeBack:setVisible(true)
            if info.viewId~=info.id then
                info.viewId = info.id
                info.nodeIconBack:removeAllChildren(true)
                info.icon = GameUI.addWeaponIcon2(info.nodeIconBack, info.id, 1, 0, 0)
            end
            info.labelNum:setString("x" .. info.num)
        end
        display.adapt(info.view, 50+210*(idx-1), 0)
    end
end
