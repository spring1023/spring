--我要变强
local SData = GMethod.loadScript("data.StaticData")

StrongerDialog = class(DialogViewLayout)

local PromoTion = class(DialogTabLayout)  --变强跳转页
local GetResources = class(DialogTabLayout) --资源跳转页

function PromoTion:create()
    self:setLayout("StrongerPromotionTab.json")
    self:loadViewsTo()
    self.context = GameLogic.getUserContext()
    self.MyTitle:setString(Localize("dataProNumTable"))
    self:updateMyPowerNum()
    self:initScrollUI()
    return self.view
end
function PromoTion:updateMyPowerNum()
    local _property = GameLogic.getUserContext():getProperty(const.ProCombat)
    self.MyTitleNum:setString(tostring(_property))
end
function PromoTion:initScrollUI()
    self:loadData()
    self:initSortAct()
    self:addLeftActNode()
    self:leftActCallBack(self.actLeftData[1])
end

function PromoTion:reloadUI()
    local leftInfo = self.leftInfos
    self:loadData()
    self:initSortAct()
    if self._leftTableView then
        self._leftTableView.view:removeFromParent(true)
        self._leftTableView = nil
    end
    self:addLeftActNode()
    local item = self.actLeftData[1]
    local idx = 1
    for _idx, info in ipairs(self.actLeftData) do
        if info.powerId == leftInfo.powerId then
            item = info
            idx = _idx
            break
        end
    end
    self._leftTableView.view:moveAndScaleToCenter(1, 156, 1000-idx*200, 0.01)
    self:leftActCallBack(item)
end

function PromoTion:loadData()
    self.allData = self:getAllData() or {}
    self.actLeftData = self:getActData() or {}
    self.heroData = self:getHeroData() or {}
    self.equipData = self:getEquipData() or {}
    self.weaponData = self:getSuperWeapons() or {}
    self.accpSortData = self:getAllMyAccpData() or {}
    self.accpFightData = self:getAllAccpFightData() or {}
end

function PromoTion:initSortAct()
    local _info = self.actLeftData
    local _sortData = {}
    local _num = 0
    for k,v in pairs(_info) do
        _num = self:getActCellData(v.powerId,v.arr,true).sortNum
        -- if _num == 0 then
        --    v.isLock = false
        -- end
        -- if v.powerId == const.ActTypeHeroAuto or v.powerId == const.ActTypeHeroPassive then
        --     v.isLock = true
        -- end
        v.sortSum = _num
        table.insert(_sortData,v)
    end

    self:sortLeft(_info)
    self.actLeftData = _info
end

--获取全部的Data，因为里面的Josn是静态的
function PromoTion:getAllData()
    local _actData = {}
    local _getData = SData.getData("PowerCondition")
    for k ,v in pairs(_getData) do
        if type(v) == "table"  then
            table.insert(_actData,{powerId = v["powerId"],name = v["name"],icon = v["icon"],desc=v["desc"],desc1=v["desc1"],classId = v["classId"],condtionId = v["condtionId"],arr = v["arrSort"]})
        end
    end
    return _actData
end

--获取侧边的Data
function PromoTion:getActData()
    local _getData = {}
    local _actData = self.allData or {}

    for k, v in pairs(_actData) do
        local _tId = v["powerId"]
        local _isLock = GameLogic.checkConditionUnlock({},_tId)
        -- if _tId == const.ActTypeHeroEqLevelUp then
        --     -- print("_isLock",_isLock)
        -- end
        if #_getData ~= 0 then
            local len = true
            for k1,v1 in pairs(_getData) do
                if _tId == v1["powerId"]then
                    len = false
                end
            end
            if len then
                table.insert(_getData,{powerId = _tId,name = v["name"],desc= v["desc"],desc1=v["desc1"],condtionId = v["condtionId"],arr = v["arr"],isLock = _isLock})
            end
        else
            table.insert(_getData,{powerId = _tId,name = v["name"],desc= v["desc"],desc1=v["desc1"],condtionId = v["condtionId"],arr = v["arr"],isLock = _isLock})
        end
    end
    return _getData
end


function  PromoTion:getAllMyAccpData()
    local _accpData = {}
    local _getData = SData.getData("myAccp") or {}
    for k,v in pairs(_getData) do
        if type(v) == "table" then
            _accpData[k] = {coef1 = v["coef1"],coef2 = v["coef2"]}
        end
    end
    return _accpData
end


function  PromoTion:getAllAccpFightData()
    local _accpFightData = {}
    local _getData = SData.getData("accpfight") or {}
    for k,v in pairs(_getData) do
        if type(v) == "table" then
            _accpFightData[k] = {qualiynum = v["qualiynum"],qualiys = v["qualiys"]}
        end
    end
    return _accpFightData
end


function PromoTion:getHeroData()
    local _heroData = {}
    local _content = self.context
    for k=1,5 do
        for v=1,4 do
            local _hero = _content.heroData:getHeroByLayout(const.LayoutPvp, k, v)
            if _hero ~= nil then
                table.insert(_heroData,{hero = _hero})
            end
        end
    end
    return _heroData
end

function PromoTion:getEquipData()
    local _heroEquip = {}
    local _heroData = self.context.heroData:getAllHeros()
    for k,v in pairs(_heroData) do
            local _equip = v.equip
            if _equip then
                -- print("_equip.id",_equip.eid)
                table.insert(_heroEquip,{hero = v,equip = _equip})
            end
        --end
    end
    return _heroEquip
end

function PromoTion:getSuperWeapons()
    local _heroWeapons = {}
    local _context = self.context.weaponData
    for k= 1,6 do
        local _weapons = _context:getWeaponAllDatasByIdx(k)
        local _maxLevel = _context:getWeaponMaxLevel(tonumber("100"..k))
        local _micLevel = 0
        for k=1,4 do
            _micLevel = _micLevel+_weapons.sublevels[k]
        end
        table.insert(_heroWeapons,{id = tonumber("100"..k),desc = _weapons.subnames[0],level = _weapons.sublevels[0],maxlevel = _maxLevel,micLevel = _micLevel})
    end
    return _heroWeapons
end

--获取分类里data
function PromoTion:getActCellData(powerId,arrLabel,typeId)
    local _getData = {}
    local _allData = self.allData or {}
    local _heroData = self.heroData or {}
    local _heroEquip = self.equipData or {}
    local _heroWeapons = self.weaponData or {}
    local _arrLabel = arrLabel or {}
    local typeId = typeId or false
    --self.awakeIsLock = true

    for k,v in pairs(_allData) do
        local _tPd = v["powerId"]
        local _tCd = v["classId"]
        if _tPd and powerId == _tPd then
            --这里要区分，装备，英雄，超级武器的添加可能不止一个，依据classId
            if _tCd == 1 and _heroData then
                for k1,v1 in pairs(_heroData) do
                    local _hero = v1["hero"]
                    if self:checkHeroState(_hero,_tPd) then
                        local _table = {hero = _hero,icon = v["icon"] ,powerId = _tPd,classId = _tCd,desc = v["desc"],desc1=v["desc1"],condtionId = v["condtionId"]}
                        table.insert(_getData,_table)
                    end
                end
            elseif _tCd == 2  and _heroEquip then
                for k1,v1 in pairs(_heroEquip) do
                    local _equip = v1["equip"]
                    local _hero = v1["hero"]
                    if self:checkEquipState(_hero,_equip) then
                        table.insert(_getData,{hero = _hero,id = _equip.eid,classId = _tCd,powerId = v["powerId"],desc = v["desc"],desc1=v["desc1"],icon = v["icon"],condtionId = v["condtionId"]})
                    end
                end
            elseif _tCd == 3 and  _heroWeapons then
                for k1,v1 in pairs(_heroWeapons) do
                    local _lv = v1["level"]
                    local _mlv = v1["maxlevel"]
                    if self:checkOtherState(_lv,_mlv) then
                        table.insert(_getData,{classId = _tCd,powerId = v["powerId"],id = v1["id"],icon = v["icon"],desc = v1["desc"],desc1=v["desc1"],level = _lv,miclevel = v1["micLevel"],maxlevel = _mlv,condtionId = v["condtionId"]})
                    end
                end
            else
                table.insert(_getData,{classId = _tCd,powerId = v["powerId"],id = 0,icon = v["icon"],desc = v["desc"],desc1=v["desc1"],condtionId = v["condtionId"]})
            end
        end
    end
    self:sortRight(_getData,powerId,_arrLabel,typeId)
    return _getData
end




function PromoTion:sortRight(obj,pId,aLabel,typeId)
    local _powerId = pId or 0
    local _objData = obj or {}
    local _aLabel = aLabel or {}
    local _typeId = typeId or false
    local _myAccpData = self.accpSortData or {}
    local _myFightData = self.accpFightData or {}
    local _sSum = 0

    if not next(_objData) then
        _objData.sortNum = 0
        return
    end
    -- if not next(_objData) or (_powerId == const.ActTypeHeroAwake and self.awakeIsLock == true) then
    --     _objData.sortNum = 0
    --     return
    -- end
    if _powerId == const.ActTypeHeroGet then
        local _heros = self.context.heroData:getAllHeros()
        for k ,v in pairs(_heros) do
            if v.info.rating and v.info.rating >= 2 then
                local _num1 = _myAccpData[_powerId].coef1
                local _num2 = (v.starUp+1) * _myFightData[v.hid].qualiynum
                local sortCoef = self:countFormula(_num1,_num2)
                if _typeId then
                    local _addSort = self:countFormulaSum(_aLabel,sortCoef)
                    _sSum = _sSum + _addSort
                end
            end
        end
        if _typeId then
            _objData.sortNum = _sSum
        end
        return
    else
        for k,v in pairs(_objData) do
            _sSum = self:conditionCount(_powerId,v,_aLabel,_typeId,_sSum)
        end
    end

    if _typeId then
        _objData.sortNum = _sSum
    else
        self:sortMax(_objData,"sortNum")
    end
end


function PromoTion:countFormulaSum(adata,snum)
    if next(adata) == nil then
        return snum
    end
    local _countsum = 0
    for k,v in pairs(adata) do
        if v and v~=0 then
            _countsum = _countsum + snum * v
        end
    end
    return _countsum
end



function PromoTion:conditionCount(pId,obj,alabel,tId,ssum)
    local _powerId = pId
    local v = obj
    local _typeId = tId or false
    local _aLabel = alabel or {}
    local _sSum = ssum or 0
    local _num1,_num2,sortCoef = 0,1,0
    local _myAccpData = self.accpSortData or {}
    local _myFightData = self.accpFightData or {}
    local _isFormula = true
    local _addSort = 0

    local _heroData = v.hero
    if _powerId == const.ActTypeHeroLevelUp then
        _num1 = _myAccpData[v.powerId].coef1 * _myFightData[_heroData.hid].qualiynum
        _num2 = _heroData.level ^ _myAccpData[v.powerId].coef2
    elseif _powerId == const.ActTypeHeroStarUp then        --升星
        if  _heroData.starUp < _heroData.info.maxStar then
            _num1 = _myAccpData[v.powerId].coef1 * _myFightData[_heroData.hid].qualiynum
            _num2 = _heroData.starUp + _myAccpData[v.powerId].coef2
        end
    elseif _powerId == const.ActTypeHeroAwake then      --觉醒
         _num1 = _myAccpData[v.powerId].coef1 * 12 * _myFightData[_heroData.hid].qualiynum
         _num2 = _heroData.info.awake
    elseif _powerId == const.ActTypeHeroAuto then  --主动技能
        if _heroData.mSkillLevel < const.MaxMainSkillLevel then
            _num1 = _myAccpData[v.powerId].coef1 * 20 * _myFightData[_heroData.hid].qualiynum
            _num2 = _heroData.mSkillLevel
        end
    elseif _powerId == const.ActTypeHeroPassive then  --被动技能
        local _hBskill = 0
        local _hisMax = true
        local _hMaxBskill = 8
        local _sortnum = 0
        for k=1,3 do
            if _heroData.bskills[k].id ~= 0 then
                _num1 = _myAccpData[v.powerId].coef1 * _heroData.maxBskill
                _num2 = _heroData.bskill
                local sortCoef = self:countFormula(_num1,_num2)
                _sortnum = _sortnum + sortCoef
            end
        end
        v.sortNum = _sortnum
        if _typeId then
            _addSort = self:countFormulaSum(_aLabel,_sortnum)
            _sSum = _sSum + _addSort
        end
        return _sSum
    elseif _powerId == const.ActTypeHeroInten then --英雄强化
         _num1 = _myAccpData[v.powerId].coef1 * 90 * _myFightData[_heroData.hid].qualiynum
         _num2 = _heroData:getMicLevel()
    elseif _powerId == const.ActTypeMercenarySkills then --佣兵
        --佣兵等级排序系数=佣兵等级系数*英雄品质系数*50/佣兵当前等级
        if _heroData.soldierLevel < const.MaxSoldierLevel then
             _num1 = _myAccpData[v.powerId].coef1 *_myFightData[_heroData.hid].qualiynum * 50
             _num2 = _heroData.soldierLevel
        end
        sortCoef = self:countFormula(_num1,_num2)
    elseif _powerId == const.ActTypeHeroEqLevelUp then  --装备升级和装备进阶
        if _heroData and _heroData.equip then
             _num1 = self:countFormula(_myAccpData[v.powerId].coef1 * 200,_heroData.equip.level)
             _num2 = self:countFormula(_myAccpData[v.powerId].coef2 * 16,_heroData.equip.elvup)
             _isFormula = false
        end
    elseif _powerId == const.ActTypeSuperWeapons then --超级武器
         _num1 = self:countFormula(_myAccpData[v.powerId].coef1 * 30,v.level)
         _num2 = self:countFormula(_myAccpData[v.powerId].coef2 * 800,v.miclevel)
         _isFormula = false
    end

    if _isFormula then
        sortCoef = self:countFormula(_num1,_num2)
    else
        sortCoef = _num1 + _num2
    end

    v.sortNum = sortCoef
    if _typeId then
        _addSort = self:countFormulaSum(_aLabel,sortCoef)
        _sSum = _sSum + _addSort
    end

    return _sSum
end

function PromoTion:countFormula(num1,num2)
    if num2 <= 0 then
        num2 = 1
    end
    return num1 / num2
end

function PromoTion:sortLeft(obj)
    local _data = obj
    for k = 1, #_data - 1 do
        for k1 = k + 1, #_data do
            if (not _data[k].sortSum) or (not _data[k].isLock) then
                _data[k].sortSum = 0
            end

            if (not _data[k1].sortSum) or (not _data[k1].isLock) then
                _data[k1].sortSum = 0
            end
            local _isLock = _data[k].isLock
            --超级武器特殊处理(置于最下边)
            local c1, c2 = 0, 0
            if _data[k].powerId == const.ActTypeSuperWeapons then
                c1 = -99999999
            end
            if _data[k1].powerId == const.ActTypeSuperWeapons then
                c2 = -99999999
            end
            if _data[k].sortSum + c1 < _data[k1].sortSum + c2 then
               _data[k], _data[k1] = _data[k1], _data[k]
            end
        end
    end
end


function PromoTion:sortMax(obj,typeId)
    --根据传入的类型去排序
    table.sort(obj,function(a,b)
        return a[typeId] > b[typeId]
    end)
end


function PromoTion:checkOtherState(level,mlevel)
    if level>=mlevel then
        return false
    end
    return true
end


function PromoTion:checkEquipState(obj,equip)
    if not next(obj) then
        return false
    end

    if equip then
        local level = equip["level"]
        local maxlv = equip:getMaxLv()
        if level>= maxlv or maxlv == 0 then
            return false
        end
        return true
    end
    return false
end

function PromoTion:checkHeroState(hero,pId)
    local _hero = hero
    if _hero then
        local _hMaxStar = _hero.info.maxStar
        local _hStarUp = _hero.starUp
        local _hWake = _hero.awakeUp
        local _infoWake = _hero.info.awake
        --print("_infoWake_infoWake_infoWake",_infoWake)
        local _hMainskill = _hero.mSkillLevel
        local _hSolierLv = _hero.soldierLevel
        local _hBskill = 0
        local _hisMax = true
        local _hMaxBskill = 8
        for k=1,3 do
            if _hero.bskills[k].id then
                if _hisMax then
                    _hisMax = false
                    _hMaxBskill = 0
                end
                _hBskill = _hBskill + _hero.bskills[k].level
                local max = _hero:getTalentSkillMax(_hero.bskills[k].id)
                if max then
                    _hMaxBskill = _hMaxBskill + max
                end
            end
        end
        _hero.maxmskill = const.MaxMainSkillLevel
        _hero.maxawake = const.MaxAwakeLevel
        _hero.maxBskill = _hMaxBskill
        _hero.bskill = _hBskill
        -- if pId == const.ActTypeHeroStarUp and _hStarUp >= _hMaxStar then
        --     return false
        -- end

        if pId == const.ActTypeHeroAwake then
            if _infoWake <= 0 then
                return false
            end

            -- if _hWake>= const.MaxAwakeLevel or _infoWake <= 0 then
            --     return false
            -- else
            --     self.awakeIsLock = false
            -- end
        end

        if pId == const.ActTypeHeroInten then
            return GameLogic.checkConditionUnlock(_hero,pId)
        end
        -- if pId == const.ActTypeHeroAuto and _hMainskill>=const.MaxMainSkillLevel then
        --     return false
        -- end

        -- if pId == const.ActTypeHeroPassive and _hBskill>=_hMaxBskill then
        --     return false
        -- end

        -- if pId == const.ActTypeMercenarySkills and _hSolierLv>=const.MaxSoldierLevel then
        --     return false
        -- end
    else
        return false
    end
    return true
end

function PromoTion:updateLeftActNode(info)
    local _info = info
    if self.selectBtnBg then
        self.selectBtnBg:removeFromParent(true)
    end
    local btnLayout = _info.viewLayout
    local chosed = ui.scale9("images/bgWhite.9.png", 20, {btnLayout.size[1]+20, btnLayout.size[2]+14})
    chosed:setCustomPoint(3,0.984,1,1,1)
    display.adapt(chosed, -10, -10, GConst.Anchor.LeftBottom)
    _info.butBackNode:addChild(chosed, 1)
    self.selectBtnBg = chosed
end

function PromoTion:addLeftActNode()
    local _info = self.actLeftData
    self.selectBtnBg = nil
    self._leftTableView = self.nodeLeftTable:loadTableView(_info,Handler(self.updateLeftCell,self))
end

function PromoTion:updateLeftCell(cell, tableView, info)
    if not info.viewLayout then
        if info.isLock then
            info.view = cell
            info.viewLayout = self:addLayout("leftScrollCell",cell:getDrawNode())
            info.viewLayout:loadViewsTo(info)
            cell:setScriptCallback(ButtonHandler(self.leftActCallBack,self,info))
            info.rankName:setString(Localize(info.name))
        else
            info.view = cell
            info.viewLayout = self:addLayout("leftScrollLockCell",cell:getDrawNode())
            info.viewLayout:loadViewsTo(info)
            cell:setScriptCallback(ButtonHandler(self.btnTip,self,info))
            info.rankName:setString(Localize(info.name))
        end
    end
end

function PromoTion:btnTip(info)
    local id = info.powerId
    if id == const.ActTypeHeroAwake then
        --您没有可以觉醒的英雄
        display.pushNotice(Localize("notHaveAwakenHero"))
    elseif id == const.ActTypeHeroEqLevelUp then
        --装备
        display.pushNotice(Localizef("dataEuqipTip"))
    elseif id == const.ActTypeSuperWeapons then
        --超级武器
        display.pushNotice(Localizef("stringHaveNotBuildEquip"))
    else
        display.pushNotice(Localize("labelNotOpen"))
    end
end


--点击侧边滑动框里面的cell节点响应
function PromoTion:leftActCallBack(info)
    self.leftInfos = info
    self:updateLeftActNode(info)
    self:addRightCell(info)
end

function  PromoTion:addRightCell(info)
    self.nodeRightTable:removeAllChildren(true)
    local _pId = info.powerId
    local infos={}
    if _pId ~= const.ActTypeHeroGet then
        table.insert(infos,{tile=true,desc=info.desc})
    end
    local _info = self:getActCellData(_pId,{},false)
    for i=1,#_info do
        table.insert(infos,_info[i])
    end
    --要改变其中一个node的时候，可以使用这个，里面sizeChange是true的
    GameUI.helpLoadTableView(self.nodeRightTable,infos,Handler(self.updateRightCell,self))
end

function PromoTion:updateRightCell(cell,tableView,info)
    --这里处理了滑动栏的标题
    if info.tile then
        if not info.viewLayout then
            info.viewLayout = self:addLayout("rightTitle",cell:getDrawNode())
            info.viewLayout:loadViewsTo(info)
            info.PageInfo1:setString(Localize(info.desc))
            info.view = cell
            self:updateRightTitle(tableView,info)
        end
    else
        if not info.viewLayout then
            info.viewLayout = self:addLayout("rightScrollCell",cell:getDrawNode())
            info.viewLayout:loadViewsTo(info)
            self:updateRightCellUI(info)
        end
    end
end

function PromoTion:updateRightTitle(tableView,info)
    local h1 = info.PageInfo1.view:getPositionY() + info.PageInfo1.view:getContentSize().height * info.PageInfo1.view:getScaleY() + 40
    local _cellViewWH = info.view:getContentSize()
    info.view:setContentSize(cc.size(_cellViewWH.width, h1))
    GameUI.fixSizeChangeLength(tableView, info)
end

function PromoTion:updateRightCellUI(idx)

    local _infos = idx
        --这里根据classId区别icon的显示，1为英雄和佣兵，2为装备，3为武器
    if _infos.ScrollBg then
        _infos.ScrollBg.view:removeAllChildren(true)
        local _setting = _infos.ScrollBg._setting
        if _infos.classId == 1 then
            GameUI.addHeadIcon(_infos.ScrollBg.view,_infos.hero.hid,0.8,0,0)
        elseif _infos.classId == 2 then
            GameUI.addEquipIcon(_infos.ScrollBg.view,_infos.id,0.8,0,0,0)
        elseif _infos.classId == 3 then
            GameUI.addWeaponIcon(_infos.ScrollBg.view,0,_infos.id,0.8,0,0)
        else
            local sp = ui.sprite(_infos.icon,{200,190})
            display.adapt(sp,0,0,GConst.Anchor.Center)
            _infos.ScrollBg:addChild(sp)
        end
    end

    local _name = ""
    if _infos.powerId then
        local _powerId = _infos.powerId
        --print("_powerId_powerId_powerId_powerId",_powerId)
        if _powerId ~= const.ActTypeHeroGet then
                local _percent = 0
                local num,maxnum = 0,1
                if _infos.classId == 1 then--英雄
                    --dump(_infos)
                    if _powerId == const.ActTypeHeroStarUp then --升星
                        num = _infos.hero.starUp
                        maxnum = _infos.hero.info.maxStar
                    elseif _powerId == const.ActTypeHeroAwake then--觉醒
                        num = _infos.hero.awakeUp
                        maxnum = _infos.hero.maxawake
                    elseif _powerId == const.ActTypeHeroAuto then--主动技能
                        num = _infos.hero.mSkillLevel
                        maxnum = _infos.hero.maxmskill
                    elseif _powerId == const.ActTypeHeroPassive then--被动技能
                        num = _infos.hero.bskill
                        maxnum = _infos.hero.maxBskill
                    elseif _powerId == const.ActTypeHeroInten then --强化
                        num = _infos.hero:getMicLevel()
                        maxnum = _infos.hero:getMaxMicLevel()
                    elseif _powerId == const.ActTypeMercenarySkills then --佣兵
                        num = _infos.hero.soldierLevel
                        maxnum = const.MaxSoldierLevel
                    else
                        num = _infos.hero.level
                        maxnum = _infos.hero.maxLv
                    end
                    _name = "dataHeroName".._infos.hero.hid
                elseif _infos.classId == 2  then--装备
                    if const.ActTypeHeroEqLevelUp then
                        num = _infos.hero.equip.level
                        maxnum = _infos.hero.equip:getMaxLv()
                        _name = "dataEquipName".._infos.id
                    end
                else --武器
                    num = _infos.level
                    maxnum = _infos.maxlevel
                    _name = "dataWeaponName".._infos.id
                end
                _percent = self:countFormula(num,maxnum)
                if _infos.BarNum then
                   _infos.BarNum:setString(Localize(_infos.desc1)..num.."/"..maxnum)
                   --_infos.BarNum:setString(_infos.sortNum)
                end

                if _infos.BarImageBg then
                   _infos.BarImageBg.view:setProcess(true,_percent)
                end
        else
            _infos.BarImageBg:setVisible(false)
            _infos.BarNum:setVisible(false)
            _infos.BarBg:setVisible(false)
            _name = _infos.desc
        end
    end

    if _name ~= "" and _infos.desc then
        _infos.ScrollNodeInfo:setString(Localize(_name))
    end

    if _infos.Button then
        _infos.BtnLabel:setString(Localize("buttonGo"))
        _infos.Button:setScriptCallback(ButtonHandler(self.onGetReward, self, _infos))
        _infos.Button.view:setTouchThrowProperty(true, true)
    end
end


function PromoTion:onGetReward(info)
    --这里是跳转的，根据conditionId
    local _jumpId = info.condtionId
    if info then
        info.jump = true
        local bNode=ui.node()
        self.view:addChild(bNode)
        GameEvent.bindEvent(bNode, Event.EventDialogClose, self, self.refreshPromoCellDialog)
        GameLogic.jumpCondition(_jumpId,info)
    end
end

function PromoTion:refreshPromoCellDialog(isClose)
    if not isClose then
        return
    end
    local info =  self.leftInfos or {}
    local conditionId = info.condtionId
    self:updateMyPowerNum()
    GameLogic.removeJumpGuide(conditionId)
    if conditionId and conditionId == const.JumpTypeEquipDeve then
        local _equipData = self:getEquipData()
        if not next(_equipData) then
           self:initScrollUI()
           return
        else
            self.equipData = _equipData
        end
    end
    if conditionId and conditionId == const.JumpTypeSuperWeapons then
        self.weaponData = self:getSuperWeapons() or {}
    end
    self:leftActCallBack(info)
end


function GetResources:create()
    self:setLayout("StrongerResTab.json")
    self:loadViewsTo()
    self.context =  GameLogic.getUserContext()
    self._ActData = self:getActData()
    self:sortLeft(self._ActData)
    self:addLeftActNode()
    local _moveTo = self.parent.mvToId
    local _jumpId = 1
    if _moveTo and next(_moveTo) then
        _jumpId = self:getJumpData(_moveTo[1],_moveTo[2])
    end
    self.tableView.view:moveAndScaleToCenter(1,100,1200-(_jumpId*162),0.0)
    self:leftActCallBack(self._ActData[_jumpId])
    return self.view
end

function GetResources:getJumpData(resType,resId)
    for k ,v in pairs(self._ActData) do
        if resType == v.resType and resId == v.resId and v.isRes then
            return k
        end
    end
    return 1
end

--获取全部的Data，因为里面的Josn是静态的
function GetResources:getAllData()
    local _actData = {}
    local _getData = SData.getData("ResConditions")
    for k ,v in pairs(_getData) do
        if type(v) == "table"  then
            table.insert(_actData,{resType = v["resType"],resId = v["resId"],name = v["name"],icon = v["icon"],star = v["star"],desc=v["desc"],condtionId = v["condtionId"]})
        end
    end
    return _actData
end

--获取侧边的Data
function GetResources:getActData()
    local _getData = {}
    local _actData = self:getAllData() or {}

    for k, v in pairs(_actData) do
        local _tId = v["resId"]
        local _tType = v["resType"]
        local _isRes = GameLogic.checkResUnlock(_tType, _tId)
            -- print("_tType,_tId,_isRes=",_tType,_tId,_isRes)
            if #_getData ~= 0 then
                local len = 0
                for k1,v1 in pairs(_getData) do
                    if _tId == v1["resId"] and _tType == v1["resType"]then
                        len = 1
                    end
                end
                if len == 0 then
                    table.insert(_getData,{resType = _tType,resId = _tId,name = v["name"],isRes = _isRes})
                end
            else
                table.insert(_getData,{resType = _tType,resId = _tId,name = v["name"],isRes = _isRes})
            end
    end
    return _getData
end


--排序，依据类型
function GetResources:sortData(data,type)

    table.sort(data,function (a,b)
        return a[type] > b[type]
    end)

end

--根据resType和resId去获取中间部分的ScrollNode
function GetResources:getCellData(actType,actId)
    local _getData = self:getAllData() or {}
    local _cellData = {}

    for k,v in pairs(_getData) do
        if type(v) == "table" and actType == v["resType"] and actId == v["resId"]then
            table.insert(_cellData, {icon = v["icon"],star=v["star"], desc=v["desc"], conditionId=v["condtionId"]})
        end
    end
    self:sortData(_cellData,"star")
    return _cellData
end



--加载侧边滑动框
function GetResources:addLeftActNode()
    local _info = self._ActData
    self.selectBtnBg = nil
    self.tableView = self.nodeLeftTable:loadTableView(_info,Handler(self.updateLeftCell,self))
end



function GetResources:updateLeftActNode(idx)
    local _info = idx
    if self.selectBtnBg then
        self.selectBtnBg:removeFromParent(true)
    end
    local btnLayout = _info.viewLayout
    local chosed = ui.scale9("images/bgWhite.9.png", 20, {btnLayout.size[1]+20, btnLayout.size[2]+20})
    chosed:setCustomPoint(3,0.984,1,1,1)
    display.adapt(chosed, -10, -10, GConst.Anchor.LeftBottom)
    _info.butBackNode:addChild(chosed, 1)
    self.selectBtnBg = chosed
end

function GetResources:sortLeft(obj)
    local _data = obj
    for k = 1, #_data - 1 do
        for k1 = k + 1, #_data do
            if not _data[k].isRes then
               _data[k],_data[k1] = _data[k1],_data[k]
            end
        end
    end
end




--加载侧边滑动框里面的cell节点
function GetResources:updateLeftCell(cell, tableView, info)
    if not info.viewLayout then
        if info.isRes then
            info.view = cell
            info.viewLayout = self:addLayout("leftScrollCell",cell:getDrawNode())
            info.viewLayout:loadViewsTo(info)
            cell:setScriptCallback(ButtonHandler(self.leftActCallBack,self,info))
            info.rankName:setString(Localize(info.name))
        else
            info.view = cell
            info.viewLayout = self:addLayout("leftScrollLockCell",cell:getDrawNode())
            info.viewLayout:loadViewsTo(info)
            cell:setScriptCallback(ButtonHandler(self.btnTip,self,info))
            info.rankName:setString(Localize(info.name))
        end
    end
end
function GetResources:btnTip(info)
    local id = info.resId
    if id == const.ResGXun then
        --联盟功勋
        display.pushNotice(Localizef("noticeBuilderNotEnough",{name = Localize("dataBuildName40200")}))
    elseif id == const.ResTrials then
        --8级解锁
        display.pushNotice(Localizef("noticeNeedLevel2",{name = Localize("dataBuildName10000"),level = 8}))
    elseif id == const.ResMagic then
            --远征
        display.pushNotice(Localizef("noticeBuilderNotEnough",{name = Localize("dataBuildName40500")}))
    elseif id == 1 then
            --装备
        display.pushNotice(Localizef("noticeBuilderNotEnough",{name = Localize("dataBuildName40400")}))
    else
        display.pushNotice(Localize("labelNotOpen"))
    end
end

--点击侧边滑动框里面的cell节点响应
function GetResources:leftActCallBack(idx)
    self:updateLeftActNode(idx)
    self:addRightCell(idx)
end


--加载右边的滑动框
function  GetResources:addRightCell(idx)
    self.nodeRightTable:removeAllChildren(true)
    local _info = self:getCellData(idx.resType,idx.resId)
    GameUI.helpLoadTableView(self.nodeRightTable,_info,Handler(self.updateRightCell,self))

end


--加载右边的滑动框的cell节点
function GetResources:updateRightCell(cell, tableView, info)
    if not info.viewLayout then
        info.viewLayout = self:addLayout("rightScrollCell",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        info.BtnOk:setScriptCallback(ButtonHandler(self.btnOkCallBack, self, info))
        info.BtnOk.view:setTouchThrowProperty(true, true)
        info.view = cell
        self:updateRightCellUI(info, tableView)
    end
end

function GetResources:btnOkCallBack(info)
    if info then
        local _condition = info.conditionId
        self.cbCondition = _condition
        local bNode=ui.node()
        self.view:addChild(bNode)
        GameEvent.bindEvent(bNode,Event.EventDialogClose, self, self.refreshPromoCellDialog)
        info.jump = true
        GameLogic.jumpCondition(_condition,info)
    end
end

function GetResources:refreshPromoCellDialog(isClose)
    if not isClose then
        return
    end
    GameLogic.removeJumpGuide(self.cbCondition)
end

--加载右边滑动框cell节点里面的各个UI
function GetResources:updateRightCellUI(info, tableView)

    local starNum = info.star
    local stat = {info.ImgStar1,info.ImgStar2,info.ImgStar3,info.ImgStar4,info.ImgStar5}
    for k = 1,5 do
        stat[k]:setVisible(false)
        if k <= starNum then
            stat[k]:setVisible(true)
        end
    end

    if info.desc then
        info.CellInfo:setString(Localize(info.desc))
    end

    if info.conditionId == 0 then
        info.BtnOk:setVisible(false)
    end

    local h2 = info.CellInfo.view:getPositionY() + info.CellInfo.view:getContentSize().height * info.CellInfo.view:getScaleY() + 40
    local _cellViewWH = info.view:getContentSize()
    info.view:setContentSize(cc.size(_cellViewWH.width, h2))
    info.colorNode.view:setContentSize(cc.size(_cellViewWH.width, h2))
    GameUI.fixSizeChangeLength(tableView, info)


    if info.icon then
        local iPath = info.icon
        info.CellBg:removeAllChildren(true)
        local temp = ui.sprite(iPath, info.CellBg.size, true)
        if temp then
            display.adapt(temp, info.CellBg.size[1]/2, info.CellBg.size[2]/2, GConst.Anchor.Center)
            info.CellBg:addChild(temp)
        end
        info.CellBg.view:setPositionY(h2/2)
    end

    local _btnX = info.BtnOk.view:getPositionX()
    local _btnY = info.BtnOk.view:getPositionY()
    info.BtnOk.view:setPosition(_btnX, h2/2)
end


function StrongerDialog:onInitDialog()
    self:setLayout("StrongerLayout.json")
    self:loadViewsTo()
    --帮助的文本
    local setting = self.setting or nil
    if setting then
        self._changerId = setting.change or 1
        self.mvToId = setting.mvto or {}
    end

    self.questionTag = "dataStrongerHelp"
    self._curTabs = {PromoTion.new(self), GetResources.new(self)}
    -- TODO 临时把事件放在这里，之后改到PromoTion里去
    -- 现在不改是优先保证BUG解决，这个1是上面PromoTion是第几个tab的意思
    self._promoTab = 1
    local tab = DialogTemplates.createTabView(self.nodeRewardTab.view, {Localize("tabPromotionDialog"), Localize("tabResDialog")}, self._curTabs, self.nodeRewardTab:getSetting("tabSetting"), {viewBg=self.view})
    tab:changeTab(self._changerId or 1)
    self.tab = tab

    GameEvent.bindEvent(self.nodeRewardTab.view, "BattleHeroChange", self, self.onRefreshDialog)
end

function StrongerDialog:onRefreshDialog(event, params)
    if self.tab.curIndex == self._promoTab then
        if event == "BattleHeroChange" and params then
            for _, hero in ipairs(self._curTabs[self._promoTab].heroData) do
                if hero.hero == params then
                    self._curTabs[self._promoTab]:reloadUI()
                    break
                end
            end
        end
    end
end
