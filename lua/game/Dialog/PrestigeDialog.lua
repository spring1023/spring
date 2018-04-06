-- 声望
PrestigeDialog = class(DialogViewLayout)

local SData = GMethod.loadScript("data.StaticData")
local ShowHeroMainDialog = GMethod.loadScript("game.Dialog.ShowHeroMainDialog")

function PrestigeDialog:onInitDialog()
    self:setLayout("PrestigeLayout.json")
    self:loadViewsTo()
    self.context = GameLogic.getUserContext()
    self.context:changeProperty(const.ProPopular,0)
    self.infoTable = {}
    self.allPrestigeData = self:allPrestigeData()
    
    local _count = #self.allPrestigeData
    self.maxPrestigeNum = self.allPrestigeData[_count].pNum
    self:initPublicNode()
    self:initLeftNode()
    self:moveToView()
    self:initRightNode(self)

    local bNode=ui.node()
    self.view:addChild(bNode)
    GameEvent.bindEvent(bNode, Event.EventDialogClose, self, self.eventBack)

    local context = self.context
    local vip = context:getInfoItem(const.InfoVIPlv)
    local userLv = context:getInfoItem(const.InfoLevel)
    local ProCombat = context:getProperty(const.ProCombat)
    GameLogic.addStatLog(11204,vip,userLv,ProCombat)
end

function PrestigeDialog:reachEffects()
    local maxIdx = self.context:getProperty(const.ProPopLevel)+const.FreePopIdx
    if self.setting then
        local startIdx = self.setting.redNum+const.FreePopIdx+1
        for k=startIdx,maxIdx do
            if self.infoTable[k].unLockType==const.ItemHero then
                self.infoTable[k].icon:setGlobalZOrder(0)
                UIeffectsManage:showEffect_prestigeReach(self.infoTable[k].content,118,110,0,1.2)
            else
                UIeffectsManage:showEffect_prestigeReach(self.infoTable[k].CellIcon,118,110,1,1.2)
            end
        end
    end
end

function PrestigeDialog:moveToView()
    -- 移动到最大可以解锁的位置
    local _moveTo = self.context:getProperty(const.ProPopLevel)+const.FreePopIdx
    self.tableView.view:moveAndScaleToCenter(1,100,1300-(_moveTo*330),0.0)
    self:reachEffects()
end

function PrestigeDialog:allPrestigeData()
    local _pData = SData.getData("popunlock")
    local _allPrestigeData = {}
    if _pData then
        for k,v in ipairs(_pData) do
            table.insert(_allPrestigeData,{id = k,pNum = v.pNum,unLockType = v.unLockType,unLockId = v.unLockId,hotCons = v.hotCons})
        end
    end
    return _allPrestigeData
end

function PrestigeDialog:loadScrollData()
    local _allData = self.allPrestigeData or {}
    local _scrollData = {}
    if _allData then
        for k,v in pairs(_allData) do
            --if v.pNum~=0 then
                table.insert(_scrollData,{id = k,pNum = v.pNum,unLockType = v.unLockType,unLockId = v.unLockId,hotCons = v.hotCons})
            --end
        end
    end
    return _scrollData
end

function PrestigeDialog:initLeftNode()
    self.leftNode:removeAllChildren(true)
    self.prestigeData = self:loadScrollData()--左侧的物品信息
    local infos = self.prestigeData  or {}
    self.tableView = GameUI.helpLoadTableView(self.leftNode,infos,Handler(self.updateLeftNode,self))
end

function PrestigeDialog:initRightNode(info)
    local _infos = info

    if _infos.RIghtNode and _infos.RIghtNode.view then
        _infos.RIghtNode:removeAllChildren(true)
    end
    ShowHeroMainDialog.HotHero(_infos.RIghtNode.view,358.5,532.0,3)

    if math.floor((self.context:getProperty(const.ProLTBoxTime) - const.InitTime)/86400) < math.floor((GameLogic.getSTime() - const.InitTime)/86400) then
        self.context:setProperty(const.ProLTBoxTime, GameLogic.getSTime())
        self.context:setProperty(const.ProLTBoxRate, 0)
    end
    local crit = math.floor(self.context:getProperty(const.ProLTBoxRate)/10)+10
    local vcrit = ui.label(Localizef("critProbability",{num=crit}), General.font1, 36)
    display.adapt(vcrit, 357.5, 288.0, GConst.Anchor.Center)
    _infos.RIghtNode:addChild(vcrit,10)
    self.vcrit = vcrit
end

function PrestigeDialog:updateCurrentPestigeNum()--刷新当前的声望值
	local lsetting = SData.getData("hlsetting", 4)
	self.BtnGetHeroLabel:setColor(255,255,255)
	if self.context:getProperty(const.ProCrystal) <  lsetting.cvalue then
		self.BtnGetHeroLabel:setColor(255,57,57)
	end
    self.prestigeNum = self.context:getProperty(const.ProPopular)--当前声望值
    self.CurrentNum:setString(self.prestigeNum or 0)
    self.fullLabel:setVisible(false)
    if self.prestigeNum >= self.maxPrestigeNum then
        --声望状态为满
        self.fullLabel:setString(Localize("labelFull"))
        self.fullLabel:setVisible(true)
    end
end

function PrestigeDialog:judgeStates(info)
    --判断当前状态，分为装备和英雄
    local _unlock = 0
    local v = info
    local k = info.id
    if v.pNum == 0 then
        _unlock = 2 --已解锁(分为设置热点和当前热点)
        return _unlock
    end

    local _mask = self.context:getProperty(const.ProPopUnlockMask1)
    _mask = bit.band(_mask,bit.lshift(1,k-const.FreePopIdx-1))
    if v.pNum > self.prestigeNum then
        _unlock = 0 --不可以解锁
    elseif v.pNum <= self.prestigeNum then
        if _mask==0 then
            _unlock = 1 --可以解锁(还没有解锁)
        else
            _unlock = 2 --已解锁(分为设置热点和当前热点)
        end
    end
    return _unlock
end

function PrestigeDialog:initPublicNode()
    self.questionTag = Localizef("prestigeHelp",{n=self.maxPrestigeNum})
    self.title:setString(Localize("dataResName1040"))
    self.labelGetPre:setString(Localize("getPrestige"))
    self.BtnGetPre:setScriptCallback(ButtonHandler(self.jumpBtnCallBack,self))
    local lsetting = SData.getData("hlsetting", 4)
    self.BtnGetHeroLabel:setString(tostring(lsetting.cvalue))
    self.BtnGetHero:setScriptCallback(ButtonHandler(self.extractBtnCallBack,self,lsetting.cvalue))
    self.CurrentLabel:setString(Localize("dataResName1040"))
end

function PrestigeDialog:extractBtnCallBack(num)
    local cstate = ShowHeroMainDialog.checkExtractMethod(4)
    if cstate >= 0 then
        ShowHeroMainDialog.onExtractMethod(4, {}, self)
    end
end

function PrestigeDialog:onExtractMethodOverBack(data)
    local hnum = #data.heros
    --刷新暴击值
    if data.bomb then
        local crit = math.floor(data.bomb/10)+10
        self.vcrit:setString(Localizef("critProbability",{num=crit}))
    end
    local HeroExtractNewTabAction = GMethod.loadScript("game.Dialog.HeroExtractNewTabAction")
    local params={heros=data,callback=Handler(self.refreshInit, self),callback1=Handler(self.refreshBomb,self)}
    HeroExtractNewTabAction.new(params)
end




function PrestigeDialog:updateLeftNode(cell,tableView,info)
    -- body
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("leftCellNode",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
        info.cell:setEnable(false)
        self:loadCellIconName(info)--因为icon模板的问题，IconUI放在了这里
        local _id = info.id
        if not self.infoTable[_id] then
            self.infoTable[_id]=info
        end
    end
    self:updateLeftNodeUI(info)
end

function PrestigeDialog:updateAllUI()
    for k,v in pairs(self.infoTable) do
        self:updateLeftNodeUI(v)
    end
end

function PrestigeDialog:updateLeftNodeUI(info)
    --根据信息更新UI显示使用了显隐的方式，整个刷新都可以放在这里
    local _infos = info
    self:updateCurrentPestigeNum()
    self:initUIVisible(_infos)
    local _isLock = self:judgeStates(_infos)
    if _isLock == 0 then--不可以解锁
        self:notUnlock(_infos)
        self:updatePrestigeNum(_infos)
    elseif _isLock == 1 then--可以解锁
        self:alreadyUnlock(_infos)
        self:canUnlock(_infos)
    elseif _isLock == 2 then--已经解锁
        self:alreadyUnlock(_infos)
        local _currentHot = self.context:getProperty(const.ProNewBoxHot)
        if _currentHot == 0 then
        	local _data = SData.getData("popunlock")
        	_currentHot = _data[const.FreePopIdx].unLockId
        	self:weekHotSetting(const.FreePopIdx)
        end
        if _infos.id == _currentHot then--当前热点
            _infos.imgSelect:setVisible(true)
            _infos.CellCurrentLabel:setVisible(true)
            _infos.CellCurrentLabel:setString(Localize("prestigeCurrentHot"))
        else--设置热点
            _infos.CellBtn:setVisible(true)
            _infos.CellBtnBgGreen.view:setHValue(111)
            _infos.CellBtnLabel:setString(Localize("prestigeSetHot"))
            _infos.CellBtn:setScriptCallback(ButtonHandler(self.btnHotCallBack,self,info))
            _infos.CellBtn.view:setTouchThrowProperty(true, true)
        end
    end
end

function PrestigeDialog:alreadyUnlock(info)
    info.CellHeroDesc:setVisible(true)
    local _boxN = self:getBoxOrder(info.id)
    if _boxN == 1 then
        info.CellHeroDesc:setString(Localizef("prestigeDesc1"))
    else
        info.CellHeroDesc:setString(Localizef("prestigeDesc",{num = _boxN}))
    end
end

function PrestigeDialog:notUnlock(info)
    local _infos = info
    _infos.CellBtnNeed:setVisible(true)
    _infos.CellProgress:setVisible(true)
    _infos.CellIconColor:setSValue(-100)
    _infos.CellNeedNum:setString(_infos.pNum)
    _infos.CellNeedLabel:setString(Localize("unlockNeedPrestige"))

end

function PrestigeDialog:canUnlock(info)
    local _infos = info
    GameEvent.sendEvent("prestigeBtnRedNum")
    _infos.CellNeedImgNode:setVisible(true)
    GameUI.addResourceIcon(_infos.CellNeedImgNode.view,_infos.hotCons[2],0.8,260.5,45.0)
    _infos.CellIconColor:setSValue(0)
    _infos.CellBtn:setVisible(true)
    _infos.CellBtnBgGreen:setVisible(true)
    _infos.CellBtnLabel:setString(Localize("labelExc"))

    _infos.CellNeedResNum:setColor(255,255,255)
	if self.context:getProperty(const.ProCrystal) <  _infos.hotCons[3] then
		_infos.CellNeedResNum:setColor(255,57,57)
	end

    _infos.CellNeedResNum:setString(_infos.hotCons[3])
    _infos.CellBtn:setScriptCallback(ButtonHandler(self.unlockCallBack,self,_infos))
    _infos.CellBtn.view:setTouchThrowProperty(true, true)
end

function PrestigeDialog:loadCellIconName(info)
    local _infos = info
    _infos.noLv = true
    local _id = _infos.unLockId
    self:setColorNode(_infos)

    if _infos.unLockType == const.ItemHero then
        _infos.CellHeroName:setString(Localize("dataHeroName".._id))
        GameUI.updateHeroTemplate(_infos.CellIconColor, _infos, self.context.heroData:makeHero(_id))
    elseif _infos.unLockType == const.ItemEquip then
        _infos.CellHeroName:setString(Localize("dataEquipName".._id))
        GameUI.updateEquipTemplate(_infos.CellIconColor, _infos, self.context.equipData:makeEquip(_id))
    end
end

function PrestigeDialog:setColorNode(info)
    if info.CellIconColor then
        info.CellIconColor:removeFromParent(true)
    end
    local _color=ui.shlNode({info.CellIcon.size[1],info.CellIcon.size[2]})
    display.adapt(_color, 115, 110, GConst.Anchor.Center)
    info.CellIcon:addChild(_color)
    info.CellIconColor = _color
end

function PrestigeDialog:showInfoLayout(info)
    --这里是点击头像回调
    if next(info) then
        local _id = info.unLockId
        local _type = info.unLockType
        if _type == const.ItemHero then
            local hero = self.context.heroData:makeHero(_id)
            display.showDialog(HeroInfoNewDialog.new({hero = hero}))
        elseif _type == const.ItemEquip then
            local equip = self.context.equipData:makeEquip(_id)
            display.showDialog(EquipInfoNewDialog.new({equip = equip}))
        end
    end
end



function PrestigeDialog:unlockCallBack(info)
    local _infos = info
    local _unlockIdx = info.unLockType
    local _itemIdx = info.unLockId
    local _resId = info.hotCons[2]
    local _num = info.hotCons[3]
    local _id = info.id
    display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"), Localizef("alertTitleUnlockPrestige",{num = _num,str = Localize("dataResName".._resId),stra = Localize("dataResType".._unlockIdx)}),{cvalue = _num,ctype = _resId,yesBut="btnYes",callback = function()
                               if self:addResSetting(_unlockIdx,_itemIdx,_id) then
	                                GameEvent.sendEvent("prestigeBtnRedNum")
	                                self.context:changeProperty(_resId, -_num)
	                                self:updateLeftNode(_infos.cell, self.tableView, _infos)
	                                self:loadEffects(_infos)
                               end
    end}))
end


function PrestigeDialog:loadEffects(info)
    if info.unLockType == const.ItemHero then
        local _hero = self.context.heroData:makeHero(info.unLockId)
        _hero.name = _hero:getName()
        NewShowHeroDialog.new({rhero=_hero,rtype = const.ItemHero, shareIdx=7})
    elseif info.unLockType == const.ItemEquip then
        local _equip = self.context.equipData:makeEquip(info.unLockId)
        _equip.info = {rating = 4}
        _equip.hid = _equip.eid
        NewShowHeroDialog.new({rhero=_equip,rtype = const.ItemEquip, shareIdx=6})
    end
end



function PrestigeDialog:btnHotCallBack(info)
    local _id = info.id
    self:weekHotSetting(_id)
    self:initRightNode(self)
    self:updateAllUI()
    self:refreshWishHot()
end



--刷新周热点
function PrestigeDialog:weekHotSetting(weekId)
    local _wdItem = self.context:getProperty(const.ProNewBoxItems)
    local _dayId1 = math.floor(_wdItem/100%100)
    local _dayId2 = math.floor(_wdItem/10000%100)
    local _dayId3 = math.floor(_wdItem/1000000)
    local _newBoxItems = weekId+_dayId1*100+_dayId2*10000+_dayId3*1000000
    self.context:setProperty(const.ProNewBoxItems,_newBoxItems)
    self.context:addCmd({const.CmdSetNewBoxHot,weekId})
    self.context:setProperty(const.ProNewBoxHot,weekId)
end

function PrestigeDialog:addResSetting(resType,resId,id)
    local idx = 0
    if resType == const.ItemHero then
        local heroData = self.context.heroData
        if heroData:getHeroNum() >= heroData:getHeroMax() then
            display.pushNotice(Localize("noticeHeroPlaceFull"))
            return false
        end
        idx = heroData.maxIdx+1
        heroData:addNewHero(idx, resId)
    elseif resType == const.ItemEquip then

        if self.context.buildData:getBuildNum(const.EquipBase) <= 0 then
            display.pushNotice(Localize("stringHaveNotBuildEquip"))
            return false
        end
        local equipData = self.context.equipData
        idx = equipData.maxIdx+1
        equipData:addNewEquip(idx, resId)
    end
    self:changeUnLockStates(id,idx)
    return true
end

function PrestigeDialog:changeUnLockStates(idx,items)
    local t = self.context:getProperty(const.ProPopUnlockMask1)
    t = bit.bor(t, bit.lshift(1, idx-const.FreePopIdx-1))
    self.context:setProperty(const.ProPopUnlockMask1, t)
    self.context:addCmd({const.CmdExchangePop,idx,items})--这里要确定参数
end



function PrestigeDialog:checkResNum(resId,num)
    local _getNum = self.context:getProperty(resId)
    return _getNum >= num
end

function PrestigeDialog:updatePrestigeNum(info)
	if info then
		info.progressLabel:setString(Localize(self.prestigeNum.."/"..info.pNum))
		local _parent = self.prestigeNum/info.pNum 
		info.progressImg:setProcess(true,_parent)
	end
end

function PrestigeDialog:getBoxOrder(id)
    -- body+
    local _level = self.context:getProperty(const.ProPopLevel)
    local _boxN = _level - (id-const.FreePopIdx-1)
    if _boxN and _boxN >= const.MaxArenaBox then
        _boxN = const.MaxArenaBox
    end
    return _boxN
end

function PrestigeDialog:initUIVisible(info)
    -- body
    info.ShowInfoLayout:setScriptCallback(ButtonHandler(self.showInfoLayout,self,info))
    info.ShowInfoLayout.view:setTouchThrowProperty(true, true)
    info.CellNeedImgNode:setVisible(false)
    info.CellProgress:setVisible(false)
    info.CellBtnNeed:setVisible(false)
    info.CellBtn:setVisible(false)
    info.imgSelect:setVisible(false)
    info.CellHeroDesc:setVisible(false)
    info.CellCurrentLabel:setVisible(false)
end

function PrestigeDialog:refreshWishHot()
    if self.params and self.params.callback2 then
        self.params.callback2()
    end
end

function PrestigeDialog:refreshInit( special )
    if self.params and self.params.callback then
        self.params.callback(special or self.getSpecial)
    else
        ShowHeroMainDialog.inAnimate = false
        display.pushNotice(Localize("dataResName" .. const.ResSpecial) .. "+" .. (special or self.getSpecial))
    end
end

function PrestigeDialog:refreshBomb(hero)
    if hero and hero.bomb then
        local crit = math.floor(hero.bomb/10)+10
        self.vcrit:setString(Localizef("critProbability",{num=crit}))
    end
    if self.params and self.params.callback1 then
        self.params.callback1(hero)
    end
end

function PrestigeDialog:jumpBtnCallBack(info)
    --跳转到我要变强声望的界面
    local _setting = {change = 2,mvto = {0,0}}
    local stronger = StrongerDialog.new({setting = _setting})
    display.showDialog(stronger)
end

function PrestigeDialog:eventBack()
    --每次回到页面的时候都会刷新声望值和UI页面
    self:updateCurrentPestigeNum()
    self:updateAllUI()
end
