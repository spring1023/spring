local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local HeroImageTab = class(DialogTab)

-- local _heroImageTabHValues = {0, 111, 180, -65, 220}--绿\蓝\紫\肉\粉
local _heroImageTabHValues = {162, -47, -102, 105}
local _heroImageTabSValues = {32, 58, 61, 60}
local _heroImageTabLValues = {-6, -15, -34, -34}

local function _sortHeroImages(a, b)
    local context = GameLogic.getUserContext()
    local aNum = context:getItem(const.ItemFragment, a[1])
    local bNum = context:getItem(const.ItemFragment, b[1])
    if aNum > 0 and aNum >= a[2].fragNum then
        a[2].order = 9
    end
    if bNum > 0 and bNum >= b[2].fragNum then
        b[2].order = 9
    end
    local _orderA = (a[2].order or 0) * 100000 + (a[2].displayColor or a[2].color) * 10000 + a[2].rating * 1000
    local _orderB = (b[2].order or 0) * 100000 + (b[2].displayColor or b[2].color) * 10000 + b[2].rating * 1000
    if _orderA ~= _orderB then
        return _orderA > _orderB
    elseif a[2].fragNum~=b[2].fragNum then
        return a[2].fragNum>b[2].fragNum
    else
        return a[1]>b[1]
    end
end

local function _sortHeroImages2(a, b)
    local aNum = GameLogic.getUserContext():getItem(const.ItemEquipFrag, a.eid)
    local bNum = GameLogic.getUserContext():getItem(const.ItemEquipFrag, b.eid)
    local aOrder = a.equip.order
    local bOrder = b.equip.order
    if aNum > 0 and aNum >= a.equip.fragNum then
        aOrder = a.equip.order/10
    end
    if bNum > 0 and bNum >= b.equip.fragNum then
        bOrder = b.equip.order/10
    end
    return aOrder < bOrder
end

function HeroImageTab:create()
    local dialog = self:getDialog()
    dialog.title:setString(StringManager.getString("btnHeroImage"))
    dialog.title:setVisible(true)
    dialog.questionBut:setVisible(true)

    local hinfos = SData.getData("hinfos")
    self.tabHids = {{},{},{},{}}
    for hid, hinfo in pairs(hinfos) do
        if hid<=6000 then
            if hid%1000==0 then
--           -- table.insert(self.tabHids[5], {hid,hinfo})
            else
                if hinfo.color <= 3 then                         --N英雄
                    table.insert(self.tabHids[1], {hid,hinfo})
                elseif hinfo.displayColor and hinfo.displayColor == 5 then              --UR英雄
                    table.insert(self.tabHids[3], {hid,hinfo})
                else                                             --R\SR\SSR英雄
                    table.insert(self.tabHids[2], {hid,hinfo})
                end
            end
        end
    end

    local edata = self:getContext().equipData
    for eid=2001,2009 do
        if eid~=2004 then
            local equip = edata:makeEquip(eid)
            local infoNew = SData.getData("equipInfoNew", eid)
            local mfrag = SData.getData("elevels",eid,1).mfrag
            equip.order = infoNew.order
            equip.fragNum = mfrag
            table.insert(self.tabHids[4], {eid=eid, equip=equip})
        end
    end

    for i, hids in ipairs(self.tabHids) do
        if i~=4 then
            table.sort(hids, _sortHeroImages)
        else
            table.sort(hids, _sortHeroImages2)
        end
    end
    local bg = ui.node(nil, true)
    self.view = bg
    local temp
    local tabNode = ui.node(nil, true)
    self.tabNode = tabNode
    bg:addChild(tabNode)
    self.tabButs = {}
    self.tabLabels = {}
    for i=1, 4 do
        temp = ui.button({414, 129}, self.changeTab, {cp1=self, cp2=i, anchor=GConst.Anchor.Bottom, actionType=1})
        display.adapt(temp, 351*i-96, 1220, GConst.Anchor.Bottom)
        tabNode:addChild(temp, i)
        temp:setBackgroundSound("sounds/switch.mp3")
        self.tabButs[i] = temp
        temp = ui.label(StringManager.getString("dataHeroImageLv" .. i), General.font1, 45)
        display.adapt(temp, 207, 95+12, GConst.Anchor.Top)
        self.tabButs[i]:getDrawNode():addChild(temp,2)
        self.tabLabels[i] = {temp, temp:getScaleY()}
        temp = ui.sprite("images/dialogTabBack4_1.png", {414, 129})
        display.adapt(temp, 0, 0)
        self.tabButs[i]:getDrawNode():addChild(temp, -1)
        temp:setHValue(_heroImageTabHValues[i])--色相(相对于temp)
        temp:setSValue(_heroImageTabSValues[i])--饱和度(相对于temp)
        temp:setLValue(_heroImageTabLValues[i])--明度(相对于temp)
    end
    temp = ui.sprite("images/dialogBackHero2.png",{1944,1206})
    display.adapt(temp, 48, 58)
    bg:addChild(temp, 1)

    self:changeTab(dialog.imgIdx or 3)
    self:resetFragTabNotice()
    self:getDialog().questionTag = "dataQuestionHeroImage"
end

function HeroImageTab:resetFragTabNotice()
    if not self.fristTabNotice then
        self.fristTabNotice = true
        self.redTab = {}
        self.fragTab = {}
        self.fragNum = {}
        for k=2,4 do
            local temp
            local node = ui.node({70,70}, true)
            display.adapt(node, 60, 100, GConst.Anchor.Center)
            self.tabButs[k]:getDrawNode():addChild(node, 2)
            temp = ui.sprite("images/noticeBackRed.png",{70,70})
            display.adapt(temp, 0, 0)
            node:addChild(temp)
            temp = ui.label("",General.font2,48)
            display.adapt(temp, 35, 35, GConst.Anchor.Center)
            node:addChild(temp)
            self.redTab[k] = temp
            self.fragTab[k] = node
        end
    end
    local canGet = 0
    local context = self:getContext()
    for _, hinfo in ipairs(self.tabHids[2]) do
        if hinfo[2].fragNum>0 and hinfo[2].fragNum<=context:getItem(const.ItemFragment, hinfo[1]) then
            canGet = canGet+1
        end
    end
    if canGet>0 then
        self.fragTab[2]:setVisible(true)
        self.redTab[2]:setString(N2S(canGet))
    else
        self.fragTab[2]:setVisible(false)
    end
    canGet = 0
    for _, hinfo in ipairs(self.tabHids[3]) do
        if hinfo[2].fragNum>0 and hinfo[2].fragNum<=context:getItem(const.ItemFragment, hinfo[1]) then
            canGet = canGet+1
        end
    end
    if canGet>0 then
        self.fragTab[3]:setVisible(true)
        self.redTab[3]:setString(N2S(canGet))
    else
        self.fragTab[3]:setVisible(false)
    end
    canGet = 0
    for _, einfo in ipairs(self.tabHids[4]) do
        local _,mnum = einfo.equip:getFragNum()
        if mnum>0 and mnum<=context:getItem(const.ItemEquipFrag, einfo.eid) then
            canGet = canGet+1
        end
    end
    if canGet>0 then
        self.fragTab[4]:setVisible(true)
        self.redTab[4]:setString(N2S(canGet))
    else
        self.fragTab[4]:setVisible(false)
    end
end

function HeroImageTab:changeTab(idx)
    if idx==self.curTab then
        return
    end
    local buts = self.tabButs
    local labels = self.tabLabels
    local curTab = self.curTab
    if curTab and buts[curTab] then
        buts[curTab]:setEnable(true)
        self.tabNode:reorderChild(buts[curTab],curTab)
        buts[curTab]:setPositionY(1220)
        labels[curTab][1]:setScale(labels[curTab][2])
    end
    self.curTab = idx
    if buts[idx] then
        buts[idx]:setEnable(false)
        self.tabNode:reorderChild(buts[idx],#buts+1)
        buts[idx]:setPositionY(1252)
        labels[idx][1]:setScale(labels[idx][2]*1.3)
        self:resetScrollTables(idx)
    end
end



function HeroImageTab:resetScrollTables(idx)
    local hids = self.tabHids[idx]
    local infos = {}
    if idx == 4 then
        for k,v in ipairs(hids) do
            infos[k] = {eid = v.eid,equip = v.equip}
        end
    else
        for i,v in ipairs(hids) do
            infos[i] = {id=v[1],info=v[2]}
        end
    end
    if self.heroTable then
        self.heroTable.view:removeFromParent(true)
        self.heroTable = nil
    end
    if idx == 4 then
        self.heroTable = ui.createTableView({1944,1236}, true, {size=cc.size(612, 1206), offx=18, offy=30, disx=36, disy=0, rowmax=1, infos=infos, cellUpdate=Handler(self.onUpdateEquipImage, self), cellActionType=0})
    else
        self.heroTable = ui.createTableView({1944,1236}, true, {size=cc.size(612, 1206), offx=18, offy=30, disx=36, disy=0, rowmax=1, infos=infos, cellUpdate=Handler(self.onUpdateHeroImage, self), cellActionType=0})
    end
    display.adapt(self.heroTable.view, 52, 30)
    self.view:addChild(self.heroTable.view, 2)
end

local function _updateFlipCell(info, isBack2)
    if info.id then
        local hero = GameLogic.getUserContext().heroData:makeHero(info.id)
        display.showDialog(HeroInfoNewDialog.new({hero=hero}))
    else
        local equip = GameLogic.getUserContext().equipData:makeEquip(info.eid)
        display.showDialog(EquipInfoNewDialog.new({equip = equip}))
    end

    -- local back1, back2
    -- if isBack2 then
    --     back1, back2 = info.back.view, info.back2.view
    -- else
    --     back2, back1 = info.back.view, info.back2.view
    -- end
    -- back1:stopAllActions()
    -- back2:stopAllActions()
    -- back1:setVisible(true)
    -- back1:setScaleX(1)
    -- back1:runAction(ui.action.sequence({{"scaleTo",0.1,0,1},"hide"}))
    -- back2:setVisible(false)
    -- back2:setScaleX(0)
    -- back2:runAction(ui.action.sequence({{"delay",0.1},"show",{"scaleTo",0.1,1,1}}))
end
function HeroImageTab:onUpdateEquipImage(cell, tableView, info)
    --品阶 1,2,3,4
    local bg, temp = cell:getDrawNode()
    local context = self:getContext()
    if not info.viewLayout then
        info.viewLayout = ViewLayout.new()
        info.viewLayout:setView(bg, {612, 1206})
        info.viewLayout:setInScroll(true)
        info.viewLayout:addLayout("HeroImageCell.json")
        info.viewLayout:loadViewsTo(info)
    end
    --dump(info)
    info.btnImageInfo:setScriptCallback(ButtonHandler(_updateFlipCell, info,nil))
    info.btnImageInfo.view:setPosition(406,1016)
    info.btnImageQuality.view:setVisible(false)
    info.btnFlipBack.view:setVisible(false)

    local data = SData.getData("elevels",info.eid,215).effect
    local num = SData.getData("einstalls",info.eid,1).equipParamsSet
    info.imageHeroBottom:setVisible(true)
    info.nodeData:setVisible(true)
    info.lbData1:setString(Localizef("dataItemEffect"..num[1],{value=data[1]}))
    info.lbData2:setString(Localizef("dataItemEffect"..num[2],{value=data[2]}))
    info.labelDps:setString("")
    info.labelHp:setString("")
    info.labelAwakeOpen:setVisible(false)
    info.labelImageDetails:setVisible(false)

    GameUI.addEquipFeature(info.nodeFeature, info.eid, 0.7, 0, 200)
    local tnode = ui.node()
    if info.eid==2001 then
        UIeffectsManage:showEffect_leiting(tnode,0,-7,0.85)
    elseif info.eid==2002 then
        UIeffectsManage:showEffect_julongzhixin(tnode,0,13,0.85)
    elseif info.eid==2003 then
        UIeffectsManage:showEffect_xueguangzhishu(tnode,0,-1,0.85)
    elseif info.eid==2005 then
        UIeffectsManage:showEffect_busizhixin(tnode,70,10,0.85)
    elseif info.eid==2006 then
        UIeffectsManage:showEffect_zhanzhengwange(tnode,60,0,1)
    elseif info.eid==2007 then
        UIeffectsManage:showEffect_kuangbao(tnode,80,65,1)
    elseif info.eid==2008 then
        UIeffectsManage:showEffect_rock(tnode,0,35)
    elseif info.eid==2009 then
        UIeffectsManage:showEffect_wand(tnode,19,0)
    end
    display.adapt(tnode, 0, 200)
    tnode:setScale(0.7/0.85)
    info.nodeFeature:addChild(tnode)
    info.nodeJobIcon:setVisible(false)
    info.labelHeroName:setString(Localize("dataEquipName"..info.eid))
    GameUI.setHeroNameColor(info.labelHeroName, 1)
    local _,mnum = info.equip:getFragNum()
    if mnum>0 then
        info.nodeFrag:setVisible(true)
        local cnum = context:getItem(const.ItemEquipFrag, info.eid)
        if cnum<0 then
            cnum=0
        end

        if cnum>=mnum then
            info.labelFragNum:setColor(GConst.Color.Green)
            info.btnMergeFrag:setVisible(true)
        else
            info.labelFragNum:setColor(GConst.Color.White)
            info.btnMergeFrag:setVisible(false)
        end
        info.btnMergeFrag:setScriptCallback(ButtonHandler(self.mergeEquipFrag, self, info))
        info.labelFragNum:setString(cnum .. "/" .. mnum)
        GameUI.addItemIcon(info.nodeFragBack,const.ItemEquipFrag,info.eid,0.9,30,30)
    else
        info.nodeFrag:setVisible(false)
    end
end

function HeroImageTab:onUpdateHeroImage(cell, tableView, info)
    --品阶 1,2,3,4
    local bg, temp = cell:getDrawNode()
    local context = self:getContext()
    local rating = info.info.rating
    if not info.viewLayout then
        info.viewLayout = ViewLayout.new()
        info.viewLayout:setView(bg, {612, 1206})
        info.viewLayout:setInScroll(true)
        info.viewLayout:addLayout("HeroImageCell.json")
        info.viewLayout:loadViewsTo(info)
    end
    info.btnImageInfo:setScriptCallback(ButtonHandler(_updateFlipCell, info, true))
    if self.curTab<=3 and ((GameLogic.useTalentMatch and rating>=3) or (not GameLogic.useTalentMatch and info.info.color >= 4)) then
        info.btnImageInfo.view:setPosition(406,1016)
        info.btnImageQuality.view:setPositionY(1150)
        info.btnImageQuality.view:setScale(0.327)
    else
        info.btnImageInfo.view:setPositionX(206)
    end
    if self.curTab<4 and rating>0 then
        if info.info.displayColor and info.info.displayColor >= 5 then
            rating = 5
            info.btnImageQuality.view:setScale(0.4)
            info.btnImageQuality.view:setPositionY(1130)
        end
        ui.setFrame(info.btnImageQuality.view,"images/btnImageQuality"..rating..".png")
    else
        info.btnImageQuality.view:setVisible(false)
    end
    info.btnFlipBack:setScriptCallback(ButtonHandler(_updateFlipCell, info, false))
    local hero = context.heroData:makeHero(info.id)
    if hero.info.job==0 then
        info.imageHeroBottom:setVisible(false)
        info.nodeData:setVisible(false)

        info.labelImageDetails:setString(hero:getSkillDesc())
        GameUI.setHeroNameColor(info.labelImageDetails, hero.info.displayColor or hero.info.color)
    else
        info.imageHeroBottom:setVisible(true)
        info.nodeData:setVisible(true)
        if hero.info.inithp then
            info.labelDps:setString(N2S(hero.info.initatk))
            info.labelHp:setString(N2S(hero.info.inithp))
        else
            info.labelDps:setString("0")
            info.labelHp:setString("0")
        end
        info.labelAwakeOpen:setVisible(hero.info.awake>0)

        local word1, word2, word3
        if hero.info.range>10 then
            word1 = Localize("enumRType2")
        else
            word1 = Localize("enumRType1")
        end
        word2 = Localize("enumUType" .. hero.info.utype)
        word3 = Localize("dataHeroType" .. (hero.info.htype or hero.info.job or 6))
        info.labelImageDetails:setString(word1 .. "\n" .. word2 .. "\n" .. word3 .. "\n" .. hero:getSkillDesc(1, true))
        info.labelImageDetails:setColor(GConst.Color.White)
    end
    GameUI.addHeroFeature(info.nodeFeature, hero.hid, 0.7, 0, 0, 0, nil, hero.awakeUp)
    GameUI.addHeroJobIcon(info.nodeJobIcon, hero.info.job, 1, 46, 46)
    info.labelHeroName:setString(hero:getName())
    GameUI.setHeroNameColor(info.labelHeroName, hero.info.displayColor or hero.info.color)
    if (hero.info.fragNum or 0)>0 then
        info.nodeFrag:setVisible(true)
        local cnum = context:getItem(const.ItemFragment, hero.hid)
        if cnum<0 then
            cnum=0
        end
        local mnum = hero.info.fragNum
        if cnum>=mnum then
            info.labelFragNum:setColor(GConst.Color.Green)
            info.btnMergeFrag:setVisible(true)
        else
            info.labelFragNum:setColor(GConst.Color.White)
            info.btnMergeFrag:setVisible(false)
        end
        info.btnMergeFrag:setScriptCallback(ButtonHandler(self.mergeHeroFrag, self, info))
        info.labelFragNum:setString(cnum .. "/" .. mnum)
        GameUI.addItemIcon(info.nodeFragBack,const.ItemFragment,hero.hid,0.9,30,30)
    else
        info.nodeFrag:setVisible(false)
    end
end

function HeroImageTab:mergeHeroFrag(info)
    local hid = info.id
    local hinfo = info.info
    local context = self:getContext()
    local heroData = context.heroData
    if heroData:getHeroNum()>=heroData:getHeroMax() then
        display.pushNotice(Localize("noticeHeroPlaceFull"))
        return
    end
    if hinfo.fragNum>0 and hinfo.fragNum<=context:getItem(const.ItemFragment, hid) then
        local rate = hinfo.displayColor and hinfo.displayColor >=5 and 5 or hinfo.rating
        context.heroData:mergeHero(hid,rate)
        display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(const.ItemHero, hid)}))
        local cnum = context:getItem(const.ItemFragment, hid)
        local mnum = hinfo.fragNum
        if cnum>=mnum then
            info.labelFragNum:setColor(GConst.Color.Green)
            info.btnMergeFrag:setVisible(true)
        else
            info.labelFragNum:setColor(GConst.Color.White)
            info.btnMergeFrag:setVisible(false)
        end
        info.labelFragNum:setString(cnum .. "/" .. mnum)
        local _hero = context.heroData:makeHero(info.id)
        NewShowHeroDialog.new({rhero=_hero,shareIdx = _hero.info.rating})
    end
    self:resetFragTabNotice()
end

function HeroImageTab:mergeEquipFrag(info)
    local eid = info.eid
    local _,_fNum = info.equip:getFragNum()
    local context = self:getContext()
    local equipData = context.equipData
    if equipData:getEquipNum()>=equipData:getEquipMax() then
        display.pushNotice(Localize("noticeEquipPlaceFull"))
        return
    end
    local cnum = context:getItem(const.ItemEquipFrag, eid)
    if _fNum <= cnum then
        local _equip = context.equipData:makeEquip(eid)
        context.equipData:mergeEquip(eid)
        display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(const.ItemEquip, eid)}))
        _equip.info = {rating = 4}
        _equip.hid = _equip.eid
        NewShowHeroDialog.new({rhero=_equip,rtype = const.ItemEquip, shareIdx=6})
        cnum = context:getItem(const.ItemEquipFrag, eid)
        if cnum>=_fNum then
            info.labelFragNum:setColor(GConst.Color.Green)
            info.btnMergeFrag:setVisible(true)
        else
            info.labelFragNum:setColor(GConst.Color.White)
            info.btnMergeFrag:setVisible(false)
        end
        info.labelFragNum:setString(cnum .. "/" .. _fNum)
        self:resetFragTabNotice()
    end
end

return HeroImageTab
