local SData = GMethod.loadScript("data.StaticData")
local BU = GMethod.loadScript("game.Build.Util")
local Build = GMethod.loadScript("game.Build.Build")
local const = GMethod.loadScript("game.GameLogic.Const")
local YouthDayData = GMethod.loadScript("game.GameLogic.YouthDayData")
local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")

StoreDialog = class(ViewLayout)

--这是一个自动显示的对话框
function StoreDialog:onCreate()
    local params = self._setting
    if type(params) == "number" then
        params = {id=params}
    end

    self.params = params
    local context = GameLogic.getUserContext()
    self.context = context
    local gstep = context.guide:getStep()
    if gstep.type == "buyBuild" and not params and not context.guide.buyBuildShow then
        context.guideHand:removeHand("buyBuild")
        self.storyIdx = gstep.storys[2]
    elseif gstep.type ~= "finish" then
        GameLogic.lockInGuide()
        return
    end

    self:setLayout("StoreDialog.json")
    self.config = GMethod.loadConfig("configs/store.json")
    self:loadViewsTo()
    self.priority = display.getDialogPri()+1
    self.isFullColor = true

    self.btnBack:setScriptCallback(ButtonHandler(self.showMainTab, self))
    --暂且不用
    self.btnFree:setVisible(false)
    self.btnFree:setScriptCallback(ButtonHandler(self.onFreeAction, self))
    local function closeDialog()
       if params and type(params)=="table" and params.closeDialogCallback then
            params.closeDialogCallback()
        end
        display.closeDialog(self.priority)
    end
    self.btnClose:setScriptCallback(ButtonHandler(closeDialog))

    if not params then
        self:showMainTab()
    elseif type(params)=="string" then
        self:showStoreTab({stype=params})
    elseif type(params)=="number" then
        self:showStoreTab({id=params})
    elseif type(params)=="table" then
        self:showStoreTab(params)
        if params.pri then
            self.priority = params.pri
        end
    end
    display.showDialog(self, false, true)
    if self.storyIdx then
        display.showDialog(StoryDialog.new({context=context, storyIdx=self.storyIdx, callback=Handler(function()
            context.guideHand:showArrow(self.showArrowBg,295,400,0)
        end)}),false,true)
    elseif self.showArrowBg then
        context.guideHand:showArrow(self.showArrowBg,295,400,0)
    end

    local tmpView = ui.node()
    self.view:addChild(tmpView)
    GameEvent.bindEvent(tmpView, "TreasureChange", self, self.onReloadTreasure)

    --青年节活动引导
    local step = YouthDayData:getGuideStep()
    if step == 1 then
        YouthDayData:setGuideStep(2)
        GameEvent.sendEvent(GameEvent.DelYouthDayGuide)
    end
end

function StoreDialog:onFreeAction()
    Plugins:goAds()
end

function StoreDialog:getResValue(ctype)
    if ctype==const.ResPBead and self.sparams.pets then
        return self.sparams.pets.pbead
    else
        return self.context:getRes(ctype)
    end
end

function StoreDialog:resetBottoms(res, withHero, withEquip,withPet)
    local bg = self.nodeBottom.view
    bg:removeAllChildren(true)
    self.resLabels = nil
    self.heroLabel = nil
    self.equipLabel = nil
    if res or withHero or withEquip or withPet then
        local temp = ui.node(nil, true)
        local w = 0
        display.adapt(temp, 1024, 87, GConst.Anchor.Center)
        bg:addChild(temp)
        bg = temp
        local disw = 100
        if res then
            local resLabels = {}
            for _, resItem in ipairs(res) do
                if resItem[2]==1 then
                    temp = ui.scale9("images/proBack1_2.png", 27, {318, 60})
                else
                    temp = ui.sprite("images/storeItemBack2.png",{318, 60})
                end
                display.adapt(temp, w, -30)
                bg:addChild(temp)
                temp = ui.label("",General.font1,44,{color={255,255,255},fontW=260,fontH=58})
                display.adapt(temp, w+217, 0, GConst.Anchor.Right)
                bg:addChild(temp)
                resLabels[resItem[1]] = temp
                GameUI.addResourceIcon(bg, resItem[1], 1, w+308,7,1,2)
                w = w+362+disw
            end
            self.resLabels = resLabels
        end
        if withHero then
            if withPet then
                --GameUI.addHeroHeadCircle(bg,8093,1,w+60,1)
                temp = ui.sprite("images/btnMenuLHero.png",{148, 141})
                display.adapt(temp, w-30, -70, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
            else
                temp = ui.sprite("images/btnMBattle1.png",{121, 117})
                display.adapt(temp, w, -57, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
            end
            temp = ui.label("", General.font1, 44, {color={255,255,255}})
            display.adapt(temp, w+117, 0, GConst.Anchor.Left)
            bg:addChild(temp)
            self.heroLabel = temp
            w = w+265+disw
        end
        if withEquip then
            temp = ui.sprite("images/btnMBattle1.png",{121, 117})
            display.adapt(temp, w, -57, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            temp = ui.label("", General.font1, 44, {color={255,255,255}})
            display.adapt(temp, w+117, 0, GConst.Anchor.Left)
            bg:addChild(temp)
            self.equipLabel = temp
            w = w+265+disw
        end

        if w > 0 then
            w = w-disw
            bg:setContentSize(cc.size(w, 0))
        end
        self:reloadBottomValues()
    end
end
function StoreDialog:resetOrnaShops(idx)
    if not self.ornaButtons then
        local bg = ui.node(self.size)
        self.view:addChild(bg,10)
        self.ornaButtons = self:addLayout("ornaButs", bg)
        self.ornaButtons:loadViewsTo()
        for i=1, 4 do
            self.ornaButtons["btnOrnaButton" .. i]:setScriptCallback(ButtonHandler(self.showStoreTab, self, {id=7,idx=i,needBack=true}))
        end
    end
    self.ornaIdx=idx
    local but
    local butBack
    for i=1, 4 do
        but = self.ornaButtons["btnOrnaButton" .. i]
        but:setEnable(i~=idx)
        butBack = self.ornaButtons["btnOrnaButtonBack" .. i].view
        if i==idx then
            butBack:setHValue(111)
        else
            butBack:setHValue(0)
        end
    end
    but = self.ornaButtons["btnOrnaButton" .. idx]
    local x, y = but:getPosition()
    self.ornaButtons.imgBtnSelected:setPosition(x, y+2)
end
function StoreDialog:reloadBottomValues()
    local context = self.context
    if self.resLabels then
        for resId, label in pairs(self.resLabels) do
            label:setString(N2S(self:getResValue(resId)))
        end
    end
    if self.heroLabel then
        if self.sparams.pets then
            self.heroLabel:setString(#(self.sparams.pets.pets) .. "/" .. 10)
        else
            self.heroLabel:setString(context.heroData:getHeroNum() .. "/" .. context.heroData:getHeroMax())
        end
    end
    if self.equipLabel then
        self.equipLabel:setString(context.equipData:getEquipNum() .. "/" .. context.equipData:getEquipMax())
    end
end

function StoreDialog:refreshHonorShop()
    local _cPresitageLv = GameLogic.getUserContext():getProperty(const.ProPopLevel)
    local _lastPrestigeLv = GEngine.getConfig("lastPrestigeLv") or 0
    if _lastPrestigeLv ~= _cPresitageLv then
        self.moveInfos = nil
        self:showStoreTab({stype="honor"})
        return
    end
    if not self.honorUpViews or not self.moveInfos then
        return
    end
    local honorInfos = GameLogic.getUserContext().arena:getHonorInfos()
    local a=honorInfos.honorHave
    local b=honorInfos.honorMax
    self.honorUpViews.labHonorcoinHave:setString(Localizef("labHonorcoinHave",{a=a,b=b}))
    self.honorUpViews.labelFull:setString(Localize("labelFull"))
    if a>=b then
        self.honorUpViews.labelFull:setVisible(true)
    else
        self.honorUpViews.labelFull:setVisible(false)
    end
    for i,info in ipairs(self.moveInfos) do
        self:updateHonorCell(info.cell, self.tableView, info)
    end
end

function StoreDialog:resetHonorShops(infos)
    if not self.honorUpViews then
        local bg = ui.node(self.size)
        self.view:addChild(bg,10)
        self.honorUpViews = self:addLayout("honorUpViews", bg)
        self.honorUpViews:loadViewsTo()
        self.honorUpViews.btnRank:setScriptCallback(ButtonHandler(function ()
            --self.dback:removeAllChildren(true)
            --self.dback:setVisible(false)
            display.closeDialog(1)
            AllRankingListDialog.new(8)
        end))
        self.honorUpViews.btnRank:setVisible(false)
        self.honorUpViews.btnExplain:setScriptCallback(ButtonHandler(HelpDialog.new,"honorShopExplain"))
        GameEvent.bindEvent(bg,"refreshHonorShop",self,self.refreshHonorShop)
    end
    if GameLogic.useTalentMatch then
        self.honorUpViews.btnExplain:setVisible(false)
    end
    local arenaData = SData.getData("arenaData")
    local ntype = "honorStoreData"
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffAreneBox)
    if buffInfo[4]~=0 then
        ntype = "honorStoreData2"
    end
    local honorStoreData = SData.getData(ntype)
    local popunlock = SData.getData("popunlock")

    local honorInfos = GameLogic.getUserContext().arena:getHonorInfos()
    local a=honorInfos.honorHave
    local b=honorInfos.honorMax
    self.honorUpViews.labHonorcoinHave:setString(Localizef("labHonorcoinHave",{a=a,b=b}))
    self.honorUpViews.labelFull:setString(Localize("labelFull"))
    if a>=b then
        self.honorUpViews.labelFull:setVisible(true)
    else
        self.honorUpViews.labelFull:setVisible(false)
    end
    local prestigeValue = GameLogic.getUserContext():getProperty(const.ProPopular)
    local _lastPrestigeLv = GEngine.getConfig("lastPrestigeLv") or 0
    local pInfos={}
    for i,v in ipairs(popunlock) do
        if i <= _lastPrestigeLv+12 then
            table.insert(pInfos,1,v)
        end
    end

    for i,v in ipairs(honorStoreData) do
        table.insert(infos,1,{adata=arenaData[i],hdata=v,pdata=pInfos[i],idx = i})
    end
    self.honorCellInfos = infos
    return {size=cc.size(605, 796), offx=56, offy=192, disx=31, disy=0, rowmax=1, cellUpdate=Handler(self.updateHonorCell, self)},100
end


--荣誉商店的
function StoreDialog:updateHonorCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local temp
    if not info.viewLayout then
        info.viewLayout = ViewLayout.new()
        info.viewLayout:setView(bg, {605, 796})
        info.viewLayout:addLayout("StoreDialogHonorCell.json")
        info.viewLayout:loadViewsTo(info)
        info.cell = cell
    end
    local adata = info.adata
    local hdata = info.hdata
    local hid = info.pdata.unLockId
    if not info.heroFeature then
        local heroFeature
        if info.pdata.unLockType==const.ItemEquip then
            heroFeature = GameUI.addEquipFeature(info.nodeContent, hid, 0.8, 230, 260)
        else
            heroFeature= GameUI.addHeroFeature(info.nodeContent, hid, 0.56, 230, 50, 0)
        end
        heroFeature:setColor(cc.c3b(0,0,0))
        heroFeature:setOpacity(255*0.5)
        info.heroFeature = heroFeature
    end
    if not info.arenaBox then
        local arenaBox = GameUI.addArenaBoxIcon(info.nodeContent, hdata.stage, 1, 230,170,0)
        info.arenaBox = arenaBox
    end
    info.labArenaStage:setString(Localizef("labArenaStage",{n=hdata.stage}))
    -- if adata.maxRank>0 then
    --     info.labelRanking3:setString(Localizef("labelRanking3",{a=adata.minRank,b=adata.maxRank}))
    -- else
    --     info.labelRanking3:setString(Localizef("labelRanking2",{a=adata.minRank}))
    -- end
    --info.labHonorMax:setString(Localizef("labHonorMax",{a=adata.honorMax}))
    if GameLogic.useTalentMatch then
        info.labGetPrestige:setVisible(false)
    else
        info.labGetPrestige:setString(Localizef("labGetPrestige",{a=hdata.canGetHonor}))
    end
    info.labHonorValue:setString(hdata.price)

    if GameLogic.getUserContext().arena:getHonorInfos().honorHave<hdata.price then
        info.bBack.view:setSValue(-100)
        info.labHonorValue:setColor(GConst.Color.Red)
    end
    cell:setScriptCallback(ButtonHandler(function ()
        display.showDialog(ArenaHonorExcDialog.new({params=hdata,pdata=info.pdata}))
    end))

    if not self.moveInfos then
        self.moveInfos = {}
    end
    if #self.moveInfos<12 then
        table.insert(self.moveInfos,1,info)
    end
end

function StoreDialog:addEffect(info,num,step)
    local _info = info[num]

    local popunlock = SData.getData("popunlock")
    local hid = 0
    local htype = const.ItemEquip
    for i,v in ipairs(popunlock) do
        if i == self.lastPrestigeLv+num+12 then
            hid = v.unLockId
            htype = v.unLockType
        end
    end
    _info = info[1-num+step]
    if htype==const.ItemEquip then
        _info.heroFeature = GameUI.addEquipFeature(_info.nodeContent, hid, 0.8, 230, 260)
    else
        _info.heroFeature= GameUI.addHeroFeature(_info.nodeContent, hid, 0.56, 230, 50, 0)
    end

    _info.heroFeature:setVisible(false)
    _info.heroFeature:runAction(ui.action.sequence({{"delay",0.5},"show",ui.action.spawn({{"tintto",0.5,{0,0,0}},{"fadeTo",0.5,255*0.5}})}))
    UIeffectsManage:showEffect_arenabox(_info.nodeContent,230,210,1,2.1)
end

function StoreDialog:moveAction(info,step)
    self.tableView.view:setScrollEnable(false)
    for i = step,1,-1 do
        self.view:runAction(ui.action.sequence({{"delay",0.5*i},{"call",function ()
            self:addEffect(info,step-i+1,step)
        end}}))
    end
    for k ,v in ipairs(info) do
        info[k].cell:setEnable(false)
        if k + step <= #info then
            info[k].heroFeature:runAction(ui.action.sequence({{"moveBy",0.5*step,-(628*step),0}}))
        else
            info[k].heroFeature:removeFromParent(true)
        end
    end
end


function StoreDialog:resetEquipShops(idx, infos)
    if not self.equipButtons then
        local bg = ui.node(self.size)
        self.view:addChild(bg,10)
        self.equipButtons = self:addLayout("equipButs", bg)
        self.equipButtons:loadViewsTo()
        for i=1, 3 do
            self.equipButtons["btnEquipButton" .. i]:setScriptCallback(ButtonHandler(self.showStoreTab, self, {stype="equip",idx=i}))
            if i==3 and self.context.buildData:getMaxLevel(const.Town) < const.HeroTrialLimit then
                self.equipButtons["btnEquipButton" .. i]:setVisible(false)
            end
        end
        self.equipButtons.btnRefresh:setScriptCallback(ButtonHandler(self.onRefreshEquip, self))
    end
    self.equipIdx = idx
    local but
    local butBack
    for i=1, 3 do
        but = self.equipButtons["btnEquipButton" .. i]
        but:setEnable(i~=idx)
        butBack = self.equipButtons["btnEquipButtonBack" .. i].view
        if i==idx then
            butBack:setHValue(111)
        else
            butBack:setHValue(0)
        end
    end
    but = self.equipButtons["btnEquipButton" .. idx]
    local x, y = but:getPosition()
    self.equipButtons.imgBtnSelected:setPosition(x, y+3)
    self.equipButtons.nodeRefreshItems:setVisible(false)
    self.shopTag = nil
    if idx==1 then
        self:resetBottoms({{const.ResCrystal,2}},nil,true)
        self:addEquipInfos(infos)
    else
        local shopTag
        if idx==2 then
            shopTag = "epart"
            self:resetBottoms({{const.ResCrystal,2},{const.ResGold,1}})
        elseif idx==3 then
            shopTag = "trials"
            self:resetBottoms({{const.ResTrials,1}})
        end
        local shopData = self.context:getShopData(shopTag, GameLogic.getSTime())
        if not shopData then
            self.shopTag = shopTag
            self:requestEquipShop(shopTag)
            return
        else
            self.equipShopData = shopData
            self:reloadEquipShop(infos, shopData)
        end
    end
    if #infos>0 then
        local ts = but:getSetting("tableSetting")
        if ts.row==1 then
            return nil, ts.oy , idx
        else
            return {size=cc.size(562, 394), offx=64, offy=12, disx=ts.dx or 61, disy=ts.dy or 134, rowmax=2, cellUpdate=Handler(self.updateItemsCell, self)}, ts.oy ,idx
        end
    end
end
function StoreDialog:onRefreshEquip(force)
    local idx = self.equipIdx
    local shopData = self.equipShopData
    if not GameNetwork.lockRequest() then
        return
    end
    if not force then
        GameNetwork.unlockRequest()
        local name
        if shopData.tag=="epart" then
            name = Localize("titleEquipPartShop")
        elseif shopData.tag=="trials" then
            name = Localize("titleTrialsShop")
        end
        display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"), Localizef("alertTextRefreshItem",{name=name}), {ctype=shopData:getRefreshType(), cvalue=shopData:getRefreshCost(), callback=Handler(self.onRefreshEquip, self, true)}))
    else
        if shopData.tag=="epart" then
            GameNetwork.request("epartshop", {equipshop={1}}, self.onResponseRefreshShop, self, shopData)
        else
            GameNetwork.request("pvtshopitems", nil, self.onResponseRefreshShop, self, shopData)
        end
    end
end


function StoreDialog:onResponseRefreshShop(shopData, suc, data)
    GameNetwork.unlockRequest()
    if suc and shopData then
        local items = {}
        self.context:changeRes(shopData:getRefreshType(), -shopData:getRefreshCost())
        GameLogic.statCrystalCost("商店刷新商品消耗",shopData:getRefreshType(), -shopData:getRefreshCost())
        shopData.refreshCount = shopData.refreshCount+1
        shopData.items = items
        if shopData.tag=="epart" then
            for k, v in pairs(data.materlt) do
                items[tonumber(k)] = {idx=tonumber(k),itemtype=v[1], itemid=v[2], itemnum=v[3], ctype=v[4], cvalue=v[5], left=1-v[6]}
            end
        elseif shopData.tag=="trials" then
            for k, v in pairs(data) do
                items[tonumber(k)] = {idx=tonumber(k),itemtype=v[3], itemid=v[4], itemnum=v[5], ctype=v[6], cvalue=v[7], left=v[1]-v[2]}
            end
        end
        if not self.deleted and self.equipShopData==shopData then
            self:showStoreTab({stype="equip", idx=self.equipIdx})
        end
    end
end


function StoreDialog:reloadEquipShop(infos, shopData)
    local eb = self.equipButtons
    eb.nodeRefreshItems:setVisible(true)
    local items = shopData.items
    for k,v in pairs(items) do
        table.insert(infos, {ctype=v.ctype, cvalue=v.cvalue, chance=v.left, get={itype=v.itemtype, item=v.itemid, value=v.itemnum}, shopItem=v})
    end
    GameUI.registerCountDownAction(eb.labelRefreshTime, shopData:getRefreshTime())
    local refreshType = shopData:getRefreshType()
    if refreshType~=self.refreshType then
        eb.nodeRefreshIcon:removeAllChildren(true)
        GameUI.addResourceIcon(eb.nodeRefreshIcon, refreshType, 0.50, 33, 33)
    end
    local cvalue = shopData:getRefreshCost()
    eb.labelRefreshNum:setString(N2S(cvalue))
    if cvalue>self.context:getRes(refreshType) then
        eb.labelRefreshNum:setColor(GConst.Color.Red)
    else
        eb.labelRefreshNum:setColor(GConst.Color.White)
    end
end

function StoreDialog:onResponseEquipShop(tag, suc, data)
    GameNetwork.unlockRequest()
    if suc and type(data)=="table" then
        local newData = {items={}}
        if tag=="epart" then
            newData.refreshCount = data.retnum
            for k, v in pairs(data.materlt) do
                newData.items[tonumber(k)] = {idx=tonumber(k),itemtype=v[1], itemid=v[2], itemnum=v[3], ctype=v[4], cvalue=v[5], left=1-v[6]}
            end
        elseif tag=="trials" then
            newData.refreshCount = data.ct-1
            for k, v in pairs(data.sinfo) do
                newData.items[tonumber(k)] = {idx=tonumber(k),itemtype=v[3], itemid=v[4], itemnum=v[5], ctype=v[6], cvalue=v[7], left=v[1]-v[2]}
            end
        end
        self.context:loadShopData(tag, newData, GameLogic.getSTime())
        if not self.deleted and self.shopTag==tag then
            self:showStoreTab({stype="equip",idx=self.equipIdx})
        end
    end
end

function StoreDialog:requestEquipShop(tag)
    if GameNetwork.lockRequest() then
        local params = nil
        if tag=="epart" then
            params = {equipshop={0}}
            GameNetwork.request("epartshop", params, self.onResponseEquipShop, self, tag)
        elseif tag=="trials" then
            GameNetwork.request("trialsshop", params, self.onResponseEquipShop, self, tag)
        end
    end
end

function StoreDialog:showMainTab()
    self.title:setString(StringManager.getString("titleStore"))
    self.btnFree:setVisible(false)
    self.btnBack:setVisible(false)
    self.labelSpecialNotice:setVisible(false)
    if self.ornaButtons then
        self.ornaButtons.view:removeFromParent()
        self.ornaButtons=nil
    end
    for i=181,185 do
        if i~=184 then
            self["rankNode" .. i]:setVisible(false)
        end
    end
    self:resetBottoms()
    if self.tableView then
        self.tableView.view:removeFromParent(true)
        self.tableView = nil
    end
    local tableView

    local infos = {}
    --1资源  2防御  3功能  4事件币   5护盾   6英雄  7装饰物   8神像
    local idcf = self.config.mainOrder
    for i = 1, #idcf do
        if not GameLogic.useTalentMatch or idcf[i] ~= 8 then
            table.insert(infos, {id=idcf[i], needBack=true})
        end
    end
    local winSize = display.winSize
    local scale = ui.getUIScale2()
    local scale2 = (winSize[2]-346*scale)/1190
    if scale>scale2 then
        scale = scale2
    end
    scale2 = winSize[1]/scale
    local leng=math.ceil(#infos/2)
    local ox=(scale2-(leng*590+(leng-1)*48))/2
    if ox<50 then
        ox=50
    end
    local tableView = ui.createTableView({scale2, 1190}, true, {size=cc.size(590, 494), offx=ox, offy=80, disx=48, disy=40, rowmax=2, infos=infos, cellUpdate=Handler(self.updateMainTabCell, self)})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.Center, {scale=scale})
    self.view:addChild(tableView.view,5)
    self.tableView = tableView
    if not self.storyIdx and self.showArrowBg then
        self.context.guideHand:showArrow(self.showArrowBg,295,400,0)
    end
end

function StoreDialog:showStoreTab(params)
    self.sparams = params
    self.btnFree:setVisible(false)
    self.labelSpecialNotice:setVisible(false)
    for i=181,185 do
        if i~=184 then
            self["rankNode" .. i]:setVisible(false)
        end
    end
    if params.needBack then
        self.btnBack:setVisible(true)
        if params.callBack then
            self.btnBack:setScriptCallback(ButtonHandler(display.closeDialog, 0))
        end
    else
        self.btnBack:setVisible(false)
    end
    if self.tableView then
        self.tableView.view:removeFromParent(true)
        self.tableView = nil
    end
    local infos = {}
    local tableView
    local tableViewSetting = nil
    local oy = 0
    local equipIdx
    if not params.stype and params.id then
        self.title:setString(StringManager.getString("titleStoreItem" .. params.id))
        if params.id==1 then
            self:addTreasureInfos(infos)
            tableViewSetting = {size=cc.size(562, 394), offx=64, offy=152, disx=61, disy=134, rowmax=2, cellUpdate=Handler(self.updateTreasureCell, self)}
            self:resetBottoms({{const.ResGold,1},{const.ResCrystal,2},{const.ResSpecial,1}})
        elseif params.id==4 then
            self:addEventInfos(infos)
            self.labelSpecialNotice:setVisible(true)
            self.labelSpecialNotice:setString(StringManager.getString("labelEventDesc"))
            oy = 150
            self:resetBottoms({{const.ResEventMoney,1}})
            tableViewSetting = {size=cc.size(562, 394), offx=64, offy=12, disx=61, disy=134, rowmax=2, cellUpdate=Handler(self.updateItemsCell, self)}
        else
            if params.id==5 then
                self:addShieldInfos(infos)
                self:resetBottoms({{const.ResCrystal,2}})
            elseif params.id==6 then
                self:addHeroInfos(infos)
                self:resetBottoms({{const.ResSpecial,1},{const.ResCrystal,2}},true)
            else
                local bidsC = self.config.bids
                local bids = bidsC[tostring(params.id)]
                if params.id==8 then
                    for i=181,185 do
                        if i~=184 then
                            self["rankNode" .. i]:setVisible(true)
                            local rank = self.context.rankList[i][1]
                            self["labelRankValue" .. i]:setString(rank and rank+1 or Localize("labelNotRank"))
                        end
                    end
                end
                if params.id==7 then
                    oy=80
                    self:resetOrnaShops(params.idx or 1)
                    self:addBuildInfos(infos, bids[self.ornaIdx])
                else
                    self:addBuildInfos(infos, bids)
                end
                self:resetBottoms({{const.ResGold,1},{const.ResCrystal,2}})
            end
        end
    elseif params.stype=="builder" then
        local bid = 11
        self.title:setString(BU.getBuildName(bid))
        self:addBuildInfos(infos, {bid})
        self:resetBottoms({{const.ResCrystal,2}})
    elseif params.stype=="equip" then
        self.title:setString(Localize("titleStore"))
        tableViewSetting, oy, equipIdx = self:resetEquipShops(params.idx or 1, infos)
        if #infos==0 then
            return
        end
    elseif params.stype=="upets" then
        self.title:setString(Localize("labelUnionPetsShop"))
        self:addUPetsInfos(infos)
        self:resetBottoms({{const.ResPBead,2}},true,false,true)
    elseif params.stype=="honor" then
        self.title:setString(Localize("labelHonorShop"))
        tableViewSetting,oy = self:resetHonorShops(infos)
    end
    self.storeInfos = infos
    local scale = ui.getUIScale2()
    local winSize = display.winSize
    local scale2 = (winSize[2]-346*scale-oy*scale)/(1190-oy)
    if scale>scale2 then
        scale = scale2
    end
    scale2 = winSize[1]/scale

    if not tableViewSetting then
        tableViewSetting = {size=cc.size(605, 796), offx=56, offy=192, disx=31, disy=0, rowmax=1, cellUpdate=Handler(self.updateNormalCell, self)}
    end
    tableViewSetting.infos = infos
    tableView = ui.createTableView({scale2, 1190-oy}, true, tableViewSetting)
    display.adapt(tableView.view, 0, -oy/2, GConst.Anchor.Center, {scale=scale})
    self.view:addChild(tableView.view,5)
    self.tableView = tableView
    if params.stype=="honor" then
        tableView.view:moveAndScaleToCenter(1,(605*12)/scale-scale2,0, 0.0)
        local _cPresitageLv = GameLogic.getUserContext():getProperty(const.ProPopLevel)
        local _lastPrestigeLv = GEngine.getConfig("lastPrestigeLv") or 0
        if _lastPrestigeLv ~= _cPresitageLv then
           self.lastPrestigeLv = _lastPrestigeLv
           GEngine.setConfig("lastPrestigeLv",_cPresitageLv,true)
           self:moveAction(self.moveInfos,_cPresitageLv - _lastPrestigeLv)
           tableView.view:runAction(ui.action.sequence({{"delay",0.5*(_cPresitageLv - _lastPrestigeLv)+0.5},{"call",function()
                self.moveInfos=nil
                self:showStoreTab({stype="honor"})
           end}}))
        end
    end

    --指引买芯片
    if self.params and type(self.params)=="table" then
        if self.params.guideBuyExp then
            self:moveToCenter(tableView, 16005)
        elseif self.params.guideBuyMedicine then
            self:moveToCenter(tableView, 10)
        elseif self.params.guideBuyBlack then
            self:moveToCenter(tableView, 5)
        elseif self.params.guideBuyZhanhun then
            self:moveToCenter(tableView, 8)
        elseif self.params.guideBuyGold then
            self:moveToCenter(tableView, 1)
        elseif self.params.guideBuyDamond then
            self:moveToCenter(tableView, 4)
        end
    end

    --其他引导移动
    if not params.stype and params.id and params.id == 3 then
        local context = GameLogic.getUserContext()
        local step = context.guideOr:getStep()
        if (math.floor(step/10) ~= 5 and step%10 == 2) or (step%10 == 3 and self.shouldMoveCenter) then
            local bidset = {[1] = 2,[2] = 5, [3] = 4,[4] = 6, [6] = 8}
            local tbid = bidset[math.floor(step/10)]
            --移动
            local bidsC = self.config.bids
            local bids = bidsC[tostring(params.id)]
            if tbid then
                local idx = 0
                for i,v in ipairs(bids) do
                    if v == tbid then
                        idx = i
                    end
                end
                tableView:moveToCenter(idx)
            end
        end
    end
end

function StoreDialog:refreshAllPrices()
    self:reloadBottomValues()
    local context = self.context
    if self.storeInfos then
        for _, info in ipairs(self.storeInfos) do
            if info.labelCostNum and not info.buyed then
                if self:getResValue(info.ctype)<info.cvalue then
                    info.labelCostNum:setColor(GConst.Color.Red)
                else
                    info.labelCostNum:setColor(GConst.Color.White)
                end
            end
        end
    end
    if self.equipShopData then
        local eb = self.equipButtons
        local ctype = self.equipShopData:getRefreshType()
        local cvalue = self.equipShopData:getRefreshCost()
        eb.labelRefreshNum:setString(N2S(cvalue))
        if cvalue>self.context:getRes(ctype) then
            eb.labelRefreshNum:setColor(GConst.Color.Red)
        else
            eb.labelRefreshNum:setColor(GConst.Color.White)
        end
    end
end

function StoreDialog:updateMainTabCell(cell, tableView, info)
    local context = self.context
    local bg = cell:getDrawNode()
    local temp
    if not info.viewLayout then
        info.viewLayout = ViewLayout.new()
        info.viewLayout:setView(bg, {590, 494})
        info.viewLayout:addLayout("StoreDialogMainCell.json")
        info.viewLayout:loadViewsTo(info)
        cell:setScriptCallback(ButtonHandler(self.showStoreTab, self, info))
    end
    info.nodeContent:removeAllChildren(true)
    local cf = self.config["mainItem"][info.id]
    local temp = ui.sprite("images/storeIconItem" .. info.id .. ".png")
    display.adapt(temp, cf[1], cf[2], GConst.Anchor.Center)
    temp:setScale(cf[3])
    info.nodeContent:addChild(temp)
    info.labelCellTitle:setString(StringManager.getString("titleStoreItem" .. info.id))
    info.nodeNotice:setVisible(false)

    --红点
    local needRedNum = {[2]=1,[3]=1,[8]=1,[9]=1,}
    if needRedNum[info.id] then
        local redNum = GameUI.addRedNum(info.nodeContent,190,170,1,0.8,1000)
        local num = context.buildData:getCanBuildNum(info.id)
        redNum:setNum(num)
    end

    if info.id == 5 then
        local redNum = GameUI.addRedNum(info.nodeContent,190,170,1,0.8,1000)
        GameEvent.bindEvent(redNum,"refreshStoreRedNum",redNum,function()
            local num = GameLogic.checkVipSheild()
            redNum:setNum(num)
        end)
        GameEvent.sendEvent("refreshStoreRedNum")
    end

    --引导
    local gstep = context.guide:getStep()
    if gstep.type == "buyBuild" then
        if info.id == gstep.btype then
            self.showArrowBg = bg
        else
            cell:setEnable(false)
            cell:setGray(true)
        end
    end
    --其他引导
    local step = context.guideOr:getStep()
    if math.floor(step/10)~=5 and step%10 == 2 and info.id == 3 then
        context.guideHand:showHandSmall(bg,295,300,0)
    end
    --青年节活动引导
    if YouthDayData:checkGuide(2) and (info.id == 8) then
        context.guideHand:showArrow(bg,295,300,20, "youthDayStatueGuide")
        YouthDayData:setGuideStep(2)
    end
end

function StoreDialog:updateTreasureCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local temp
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = ViewLayout.new()
        info.viewLayout:setView(bg, {562, 394})
        info.viewLayout:addLayout("StoreDialogTreasureCell.json")
        info.viewLayout:loadViewsTo(info)
        cell:setScriptCallback(ButtonHandler(self.onTreasureAction, self, info,cell,tableView))
    end
    if self.params and type(self.params)=="table" then
        if self.params.guideBuyExp and type(info.resource) == "table" and info.resource[1] == const.ItemChip then
            GameLogic.getUserContext().guideHand:showArrow(bg,562/2,300,20,"guideBuyExp")
        elseif self.params.guideBuyMedicine and info.resource==const.ResMedicine and info.get==100 then
            GameLogic.getUserContext().guideHand:showArrow(bg,562/2,300,20,"guideBuyMedicine")
        elseif self.params.guideBuyGold and info.type==3 and info.resource == const.ResGold then
            GameLogic.getJumpGuide(const.JumpTypeGoldStore,bg,562/2,300)
        elseif self.params.guideBuyBlack and info.resource == const.ResSpecial then
            GameLogic.getJumpGuide(const.JumpTypeBlackStore,bg,562/2,300)
        elseif self.params.guideBuyDamond and info.type == 6 and info.resource == const.ResCrystal then
            GameLogic.getJumpGuide(const.JumpTypeDiamondStore,bg,562/2,300)
        end
    end
    local context = self.context
    info.nodeContent:removeAllChildren(true)
    if info.img then
        temp = ui.sprite(info.img)
        if temp then
            temp:setScale(info.imgs or 1)
            display.adapt(temp, info.imgx or 0, info.imgy or 0, GConst.Anchor.Center)
            info.nodeContent:addChild(temp)
        end
    end
    if info.resource==const.ResCrystal or info.contract then  --购买宝石或者月卡
        info.nodeCostIcon:setVisible(false)
        info.labelCostNum:setString(info.cost)
        --额外赠送联盟福利包
        if info.giveWelfare then
            temp = ui.label(Localize("storeGemExtra"), General.font1, 40, {color={255,255,255}, width = 300, align=GConst.Align.Left})
            display.adapt(temp, 10, 180, GConst.Anchor.Left)
            bg:addChild(temp)
        end
    else
        info.nodeCostIcon:setVisible(true)
        info.nodeCostIcon:removeAllChildren(true)
        GameUI.addResourceIcon(info.nodeCostIcon, const.ResCrystal, 0.66, 33, 33)
        info.labelCostNum:setString(N2S(info.cost))
        if self:getResValue(const.ResCrystal)<info.cost then
            info.labelCostNum:setColor(GConst.Color.Red)
        else
            info.labelCostNum:setColor(GConst.Color.White)
        end
    end
    if info.resource then
        info.nodeGetIcon:setVisible(true)
        info.labelGetNum:setVisible(true)
        info.labelGetNum:setString(N2S(info.get))
        info.nodeGetIcon:removeAllChildren(true)
        if type(info.resource) == "table" then
            GameUI.addItemIcon(info.nodeGetIcon, info.resource[1], info.resource[2], 66/200,33,33)
        else
            GameUI.addResourceIcon(info.nodeGetIcon, info.resource, 0.66, 33, 33)
        end
    else
        info.nodeGetIcon:setVisible(false)
        info.labelGetNum:setVisible(false)
    end
    --愿未来在此填坑之人不要陷入一重又一重的if循环之中
    if GameLogic.useTalentMatch then
        info.CustomGetNum:setVisible(false)
        info.CustomGetLine:setVisible(false)
        info.labelName:setVisible(true)
        info.labelSale:setVisible(false)
        info.labelName:setString(info.text or "")
        info.nodeTimeBlock:setVisible(false)
    else
        if info.sale and info.sale > 0 then
            info.labelGetNum:setVisible(true)
            local realGetNum = math.floor(info.get*(1+info.sale/100))
            info.labelGetNum:setString(N2S(info.get))
            info.CustomGetNum:setVisible(false)
            local CustomGetNum = math.floor(info.get)
            info.CustomGetNum:setString(CustomGetNum)
            info.CustomGetLine:setVisible(false)
            info.labelName:setVisible(false)
            info.labelSale:setVisible(true)
            local text="labelStoreSend2"
            if GameLogic.getBuyedCrystalNum(info.gemIdx)>=1 then
                text="labelStoreSend"
            end
            info.labelSale:setString(Localizef(text,{a=math.floor(info.get*info.sale/100)}))
            info.nodeTimeBlock:setVisible(true)
        else
            info.CustomGetNum:setVisible(false)
            info.CustomGetLine:setVisible(false)
            info.labelName:setVisible(true)
            info.labelSale:setVisible(false)
            info.labelName:setString(info.text or "")
            info.nodeTimeBlock:setVisible(false)
        end
    end
    if info.inAct then
        info.labelActInfo:setVisible(true)
        info.labelActInfo:setString(StringManager.getFormatString("labelTreasureAct1",{num=300}))
        info.labelActInfo:setVisible(false)--事件币暂时关闭
    else
        info.labelActInfo:setVisible(false)
    end

    --月卡
    if info.contract and info.contract == 1 then
        local context = self.context
        local rtime = context.vips[5][2] - GameLogic.getSTime()
        local day = math.ceil(rtime/86400)
        local dailyData = GameLogic.getUserContext().activeData.dailyData
        local monthData = {isget=0}
        for k,v in pairs(dailyData) do
            if v.atype == 4 then
                monthData = v
            end
        end
        day = day-monthData.isget

        local temp
        if info.cardDes then
            info.cardDes:removeFromParent(true)
            info.cardDes = nil
        end
        if day<=0 then
            info.labelGetNum:setString(N2S(info.get))
            info.labelName:setVisible(true)
            temp = ui.label("", General.font1, 30, {color={255,255,255}, width = 180, align=GConst.Align.Left})
            display.adapt(temp, 10, 230, GConst.Anchor.LeftTop)
            bg:addChild(temp)
            temp:setString(Localize("stringMonthDes"))
        else
            temp = ui.label("", General.font1, 50, {color={255,255,255}})
            display.adapt(temp, 10, 280, GConst.Anchor.LeftTop)
            bg:addChild(temp)
            temp:setString(Localizef("labelRemainDay",{a = day}))
        end
        info.cardDes = temp
    end
end

function StoreDialog:updateItemsCell(cell, tableView, info)
    local temp
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = ViewLayout.new()
        info.viewLayout:setView(cell:getDrawNode(), {562, 394})
        info.viewLayout:addLayout("StoreDialogItemsCell.json")
        info.viewLayout:loadViewsTo(info)
        cell:setScriptCallback(ButtonHandler(self.onItemsAction, self, info))
    end
    local context = self.context
    local get = info.get
    if get.res then
        info.labelName:setString(StringManager.getString("dataResName" .. get.res) .. "x" .. get.value)
    else
        info.labelName:setString(GameLogic.getItemName(get.itype,get.item) .. "x" .. get.value)
    end
    info.nodeContent:removeAllChildren(true)
    GameUI.addItemBack(info.nodeContent,4,1.08,0,0):setLValue(100)

    if get.res then
        GameUI.addItemBack(info.nodeContent,4,1,0,0)
        info.itemNode=GameUI.addResourceIcon(info.nodeContent,get.res,1.15,0,0)
    else
        info.itemNode=GameUI.addItemIcon(info.nodeContent,get.itype,get.item,1,0,0,true)
    end
    info.nodeExtendImg:removeAllChildren(true)
    if info.sale then
        temp = ui.sprite("images/storeTagSale.png",{148, 151})
        display.adapt(temp, 0, 0, GConst.Anchor.RightBottom)
        info.nodeExtendImg:addChild(temp)
    end
    if (get.itype == const.ItemHWater and get.item == 3)or get.itype == const.ItemFragment or (get.itype == const.ItemRes and get.item == 26) then
        local temp = ui.sprite("images/storeHot.png")
        display.adapt(temp, -17, -2, GConst.Anchor.RightBottom)
        info.nodeExtendImg:addChild(temp)
    end
    info.nodeCostIcon:removeAllChildren(true)
    GameUI.addResourceIcon(info.nodeCostIcon, info.ctype, 0.66, 33, 33)
    info.labelCostNum:setString(N2S(info.cvalue))
    if self:getResValue(info.ctype)<info.cvalue then
        info.labelCostNum:setColor(GConst.Color.Red)
    else
        info.labelCostNum:setColor(GConst.Color.White)
    end

    info.labelActInfo:setString(StringManager.getFormatString("labelBuyChancesLeft",{num=info.chance}))

    if info.chance<=0 then
        cell:setGray(true)
        info.itemNode:setSValue(-100)
        local selled=GameUI.addHaveGet(cell:getDrawNode(),Localize("labelItemSelled"),1.14,562/2,394/2+10,2)
        selled:setSValue(0)
    else
        info.itemNode:setSValue(0)
        cell:setGray(false)
    end
end

local function _updateFlipCell(info, isBack2)
    if info.hid and info.hid < 8000 then
        local hero = GameLogic.getUserContext().heroData:makeHero(info.hid)
        display.showDialog(HeroInfoNewDialog.new({hero = hero}))
    elseif info.eid then
        local equip = GameLogic.getUserContext().equipData:makeEquip(info.eid)
        display.showDialog(EquipInfoNewDialog.new({equip = equip}))
    else
        if info.isBack2==isBack2 then
            return
        end
        local back1, back2
        if isBack2 then
            back1, back2 = info.back1.view, info.back2.view
        else
            back2, back1 = info.back1.view, info.back2.view
        end
        local back = info.viewLayout.view
        back:stopAllActions()
        back1:stopAllActions()
        back2:stopAllActions()
        back1:setVisible(true)
        back2:setVisible(false)
        back:runAction(ui.action.sequence({{"scaleTo",0.1,0,1},{"scaleTo",0.1,1,1}}))
        back1:runAction(ui.action.sequence({{"delay",0.1},"hide"}))
        back2:runAction(ui.action.sequence({{"delay",0.1},"show"}))
        info.isBack2 = isBack2
    end
end

function StoreDialog:updateOrnamentCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local temp
    if not info.viewLayout then
        info.viewLayout = ViewLayout.new()
        info.viewLayout:setView(bg, {562, 394})
        info.viewLayout:addLayout("StoreDialogOrnamentCell.json")
        info.viewLayout:loadViewsTo(info)

        cell:setScriptCallback(ButtonHandler(self.onNormalAction, self, info))
        info.btnInfo:setScriptCallback(ButtonHandler(_updateFlipCell, info, true))
        info.isBack2 = false
        info.cell = cell
    end

    local context = self.context
    info.labelName:setString(info.name)

    if info.info then
        info.labelName2:setString(info.name)
        info.labelInfo:setString(info.info)
        info.btnInfo:setVisible(true)
    else
        info.btnInfo:setVisible(false)
        info.isBack2 = false
    end
    info.nodeContent:removeAllChildren(true)
    local csize = info.nodeContent.size
    info.nodeBuildNum1:setVisible(false)
    info.nodeBuildNum2:setVisible(false)
    if info.bid then
        local newBuild = Build.new(info.bid, info.blevel or 1)
        local vs = 1.5
        newBuild:addBuildView(info.nodeContent.view, csize[1]/2, csize[2]/2, csize[1], csize[2], vs)
        info.labelName:setColor({255,255,205})
        local esTF=true
        if info.buyed or (info.num and info.max and info.num>=info.max) then
            esTF=false
        end
        if info.max>0 then
            if info.num==0 then
                info.nodeBuildNum1:setVisible(true)
                info.labelBuildNum1:setString(N2S(info.max))
            else
                info.nodeBuildNum2:setVisible(true)
                info.labelBuildNum2:setString(info.num .. "/" .. info.max)
            end
        end

        --引导
        local context = GameLogic.getUserContext()
        local gstep = context.guide:getStep()
        if gstep.type == "buyBuild" then
            if info.bid == gstep.id then
                context.guideHand:showArrow(bg,302,700,0)
            else
                cell:setEnable(false)
                cell:setGray(true)
            end
        end
        --其他引导
        local step = context.guideOr:getStep()
        if math.floor(step/10) ~= 5 and step%10 == 2 then
            local bidset = {[1] = 2,[2] = 5, [3] = 4,[4] = 6, [6] = 8}
            local tbid = bidset[math.floor(step/10)]
            if info.bid == tbid then
                context.guideHand:showHandSmall(bg,302,400,0)
                self.shouldMoveCenter = true
                context.guideOr:setStep(step+1)
            end
        end
    end
    if info.time and (not info.max or info.max>0) then
        info.nodeTimeNeed:setVisible(true)
        info.labelTimeNeed:setString(StringManager.getTimeString(info.time))
        if info.time>=1 then
            info.labelTimeNeed:setColor({109,250,255})
        else
            info.labelTimeNeed:setColor({245,245,197})
        end
    else
        info.nodeTimeNeed:setVisible(false)
    end
    if info.cdtime then
        info.nodeTimeCold:setVisible(true)
        info.labelTimeCold:setString(StringManager.getTimeString(info.cdtime))
    else
        info.nodeTimeCold:setVisible(false)
    end
    if info.buyed then
        info.nodeCostIcon:setVisible(false)
        info.labelCostNum:setString(Localize("labelAlreadyBuy"))
        info.labelCostNum:setColor(GConst.Color.White)
    else
        info.nodeCostIcon:setVisible(true)
        info.nodeCostIcon:removeAllChildren(true)
        GameUI.addResourceIcon(info.nodeCostIcon, info.ctype, 0.66, 33, 33)
        info.labelCostNum:setString(N2S(info.cvalue))
        if info.cvalue==0 then
            info.labelCostNum:setString(Localize("labelFree"))
            info.nodeCostIcon:setVisible(false)
        end
        if self:getResValue(info.ctype)<info.cvalue then
            info.labelCostNum:setColor(GConst.Color.Red)
        else
            info.labelCostNum:setColor(GConst.Color.White)
        end
    end
    info.labelNotice1:setVisible(false)
    info.labelNotice2:setVisible(false)
    info.labelActInfo:setVisible(true)
    if info.buyed or (info.num and info.max and info.num>=info.max) then
        cell:setGray(true)
        CaeHSLNode:recurSetHSL(info.nodeContent.view,0,-100,0,2)
        info.labelActInfo:setVisible(false)
        if not info.buyed then
            if info.max==0 then
                info.labelNotice1:setVisible(true)
                info.labelNotice1:setString(StringManager.getFormatString("labelNeedLevel1",{level=info.nextUnlock}))
            else
                info.labelNotice2:setVisible(true)
                if info.nextUnlock==0 then
                    info.labelNotice2:setString("")
                else
                    info.labelNotice2:setString(StringManager.getFormatString("labelNeedLevel2",{level=info.nextUnlock}))
                end
            end
        end
    else
        cell:setGray(false)
        CaeHSLNode:recurSetHSL(info.nodeContent.view,0,0,0,2)
    end
    info.back1:setVisible(not info.isBack2)
    info.back2:setVisible(info.isBack2)
end

function StoreDialog:canExit()
    --引导
    local context = GameLogic.getUserContext()
    local menu = GMethod.loadScript("game.View.Scene").menu
    if context.guide:getStep().type == "buyBuild" then
        menu:buyBuildShow()
    end
    GameEvent.sendEvent("refreshDialog")
    return true
end


function StoreDialog:updateNormalCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    local temp
    if not info.viewLayout then
        info.viewLayout = ViewLayout.new()
        info.viewLayout:setView(bg, {605, 796})
        info.viewLayout:addLayout("StoreDialogNormalCell.json")
        info.viewLayout:loadViewsTo(info)
        cell:setScriptCallback(ButtonHandler(self.onNormalAction, self, info))
        info.btnInfo:setScriptCallback(ButtonHandler(_updateFlipCell, info, true))
        info.isBack2 = false
        info.cell = cell
    end
    local context = self.context
    info.labelName:setString(info.name)
    if info.info then
        info.labelName2:setString(info.name)

        info.labelInfo:setString(info.info)
        info.btnInfo:setVisible(true)
    else
        info.btnInfo:setVisible(false)
        info.isBack2 = false
    end
    info.nodeContent:removeAllChildren(true)
    local csize = info.nodeContent.size
    info.nodeBuildNum1:setVisible(false)
    info.nodeBuildNum2:setVisible(false)
    if info.bid then
        --info.labelActInfo:setString(StringManager.getFormatString("labelBuyActScore",{num=100}))

        local newBuild = Build.new(info.bid, info.blevel or 1)
        local vs = 1.8
        if 100<=info.bid and info.bid<=180 then
            vs = 1.8
        elseif info.bid==50 then
            vs = 1.8
        end
        newBuild:addBuildView(info.nodeContent.view, csize[1]/2, csize[2]/2, csize[1], csize[2], vs)
        info.labelName:setColor({255,255,205})
        local esTF=true
        if info.buyed or (info.num and info.max and info.num>=info.max) then
            esTF=false
        end
        if info.bid==28 then --粒子塔特效
            newBuild.tvstate.bviews[1]:setVisible(esTF)
            newBuild.tvstate.bviews[2]:setVisible(esTF)
            newBuild.tvstate.bviews[3]:setVisible(esTF)
        elseif info.bid==4 then --遗迹特效
            newBuild.tvstate.bviews[1]:setVisible(esTF)
            newBuild.tvstate.bviews[2]:setVisible(esTF)
            newBuild.tvstate.bviews[4]:setVisible(esTF)
            newBuild.tvstate.bviews[5]:setVisible(esTF)
            if newBuild.tvstate.bviews[3] then
                newBuild.tvstate.bviews[3]:setVisible(esTF)
                newBuild.tvstate.bviews[6]:setVisible(esTF)
            end
        elseif info.bid==5 then --竞技场特效
            newBuild.tvstate.bviews[1]:setVisible(esTF)
            newBuild.tvstate.bviews[2]:setVisible(esTF)
            newBuild.tvstate.bviews[3]:setVisible(esTF)
            newBuild.tvstate.bviews[4]:setVisible(esTF)
            newBuild.tvstate.bviews[5]:setVisible(esTF)
            newBuild.tvstate.bviews[6]:setVisible(esTF)
        end

        if info.max>0 then
            if info.num==0 then
                info.nodeBuildNum1:setVisible(true)
                info.labelBuildNum1:setString(N2S(info.max))
            else
                info.nodeBuildNum2:setVisible(true)
                info.labelBuildNum2:setString(info.num .. "/" .. info.max)
            end
        end

        --引导
        local context = GameLogic.getUserContext()
        local gstep = context.guide:getStep()
        if gstep.type == "buyBuild" then
            if info.bid == gstep.id then
                context.guideHand:showArrow(bg,302,700,0)
            else
                cell:setEnable(false)
                cell:setGray(true)
                info.btnInfo:setEnable(false)
            end
        end
        --其他引导
        local step = context.guideOr:getStep()
        if math.floor(step/10) ~= 5 and step%10 == 2 then
            local bidset = {[1] = 2,[2] = 5, [3] = 4,[4] = 6, [6] = 8}
            local tbid = bidset[math.floor(step/10)]
            if info.bid == tbid then
                context.guideHand:showHandSmall(bg,302,400,0)
                self.shouldMoveCenter = true
                context.guideOr:setStep(step+1)
            end
        end
    elseif info.img then
        local temp = ui.sprite(info.img)
        temp:setScale(info.imgs or 1)
        display.adapt(temp, csize[1]/2+(info.imgx or 0), csize[2]/2+(info.imgy or 0), GConst.Anchor.Center)
        info.nodeContent:addChild(temp)
    elseif info.hid then
        GameUI.addHeroFeature(info.nodeContent, info.hid, 0.7, csize[1]/2, csize[2]/2, 0, true)
    else
        GameUI.addEquipFeature(info.nodeContent, info.eid, 0.85, csize[1]/2, csize[2]/2, 0)

        --装备特效
        --510,530,516
        if info.eid==2001 then
            UIeffectsManage:showEffect_leiting(info.back1,302,csize[2]/2+100+93,0.85)
        elseif info.eid==2002 then
            UIeffectsManage:showEffect_julongzhixin(info.back1,302,csize[2]/2+100+113,0.85)
        elseif info.eid==2003 then
            UIeffectsManage:showEffect_xueguangzhishu(info.back1,302,csize[2]/2+100+99,0.85)
        elseif info.eid==2005 then
            UIeffectsManage:showEffect_busizhixin(info.back1,365,csize[2]/2+100+120)
        elseif info.eid==2006  then
            UIeffectsManage:showEffect_zhanzhengwange(info.back1,365,csize[2]/2+100+110)
        elseif info.eid==2007 then
            UIeffectsManage:showEffect_kuangbao(info.back1,380,csize[2]/2+100+165)
        elseif info.eid==2008 then
            UIeffectsManage:showEffect_rock(info.back1,307,csize[2]/2+100+144)
        elseif info.eid==2009 then
            UIeffectsManage:showEffect_wand(info.back1,321,csize[2]/2+100+102)
        end
    end
    if info.time and (not info.max or info.max>0) then
        info.nodeTimeNeed:setVisible(true)
        info.labelTimeNeed:setString(StringManager.getTimeString(info.time))
        if info.time>=1 then
            info.labelTimeNeed:setColor({109,250,255})
        else
            info.labelTimeNeed:setColor({245,245,197})
        end
    else
        info.nodeTimeNeed:setVisible(false)
    end
    if info.cdtime then
        info.nodeTimeCold:setVisible(true)
        info.labelTimeCold:setString(StringManager.getTimeString(info.cdtime))
    else
        info.nodeTimeCold:setVisible(false)
    end

    if info.buttonGo then
        info.buttonGo:setVisible(false)
    end

    if info.eid and info.cvalue == 0 then
        info.colorNode:setVisible(false)
        info.buyNode:setVisible(false)
        if info.buttonGo then
            info.buttonGo:setVisible(true)
            info.buttonGo:setScriptCallback(ButtonHandler(function ()
                display.showDialog(PrestigeDialog.new())
            end),self)
            info.buttonGoLabel:setString(Localize("buttonGo"))
        end
    end


    if info.buyed then
        info.nodeCostIcon:setVisible(false)
        info.labelCostNum:setString(Localize("labelAlreadyBuy"))
        info.labelCostNum:setColor(GConst.Color.White)
    else
        info.nodeCostIcon:setVisible(true)
        info.nodeCostIcon:removeAllChildren(true)
        GameUI.addResourceIcon(info.nodeCostIcon, info.ctype, 0.66, 33, 33)
        info.labelCostNum:setString(N2S(info.cvalue))
        if info.cvalue==0 and not info.eid then
            info.labelCostNum:setString(Localize("labelFree"))
            info.nodeCostIcon:setVisible(false)
            if info.shieldId then
                info.labelCostNum:setString(Localize("labelVip1Free"))
                local lock = context:getVipPermission("propect")[1]
                if lock == 0 then
                    info.labelCostNum:setString(Localize("labelFree"))
                end
            end
        end
        if self:getResValue(info.ctype)<info.cvalue then
            info.labelCostNum:setColor(GConst.Color.Red)
        else
            info.labelCostNum:setColor(GConst.Color.White)
        end
    end
    info.labelNotice1:setVisible(false)
    info.labelNotice2:setVisible(false)
    info.labelActInfo:setVisible(true)
    if info.buyed or (info.num and info.max and info.num>=info.max) then
        cell:setGray(true)
        CaeHSLNode:recurSetHSL(info.nodeContent.view,0,-100,0,2)
        info.labelActInfo:setVisible(false)
        if not info.buyed then
            if info.max==0 then
                info.labelNotice1:setVisible(true)
                info.labelNotice1:setString(StringManager.getFormatString("labelNeedLevel1",{level=info.nextUnlock}))
            else
                info.labelNotice2:setVisible(true)
                if info.nextUnlock==0 then
                    info.labelNotice2:setString("")
                else
                    info.labelNotice2:setString(StringManager.getFormatString("labelNeedLevel2",{level=info.nextUnlock}))
                end
            end
        end
    else
        cell:setGray(false)
        CaeHSLNode:recurSetHSL(info.nodeContent.view,0,0,0,2)
    end
    info.back1:setVisible(not info.isBack2)
    info.back2:setVisible(info.isBack2)

    --护盾
    if info.shieldId then
        local sid = info.shieldId
        local sdata = self.context.enterData.ustate
        local function updateCD()
            local remainCD = sdata[sid+2]-GameLogic.getSTime()
            if remainCD>0 then
                info.remainCD = remainCD
                cell:setGray(true)
                CaeHSLNode:recurSetHSL(info.nodeContent.view,0,-100,0,2)
                info.labelTimeCold:setString(Localizet(remainCD))
                ui.setColor(info.labelTimeCold,255,255,0)
            else
                cell:setGray(false)
                CaeHSLNode:recurSetHSL(info.nodeContent.view,0,0,0,2)
                info.remainCD = remainCD
                info.labelTimeCold:setString(Localizet(info.cdtime))
                ui.setColor(info.labelTimeCold.view,255,255,255)
            end
        end
        RegTimeUpdate(info.labelTimeCold.view, updateCD, 0.2)
        updateCD()
    end
    if info.isSX then       --神像
        info.nodeBuildNum1:setVisible(false)
        info.nodeBuildNum2:setVisible(false)
        if info.canBuild then
            if info.num == 1 then
                info.nodeBuildNum2:setVisible(true)
                info.labelBuildNum2:setString(info.num .. "/" .. info.max)
            else
                info.nodeBuildNum1:setVisible(true)
                info.labelBuildNum1:setString(N2S(info.max))
            end
        elseif BU.inServerCalTime(info.bid) or GameLogic.isEmptyTable(info.buildNeed) then   --不能建造的两种情况：1、条件不满足；2、处于服务器结算时间
            cell:setGray(true)
            CaeHSLNode:recurSetHSL(info.nodeContent.view,0,-100,0,2)
        else
            cell:setGray(true)
            CaeHSLNode:recurSetHSL(info.nodeContent.view,0,-100,0,2)
            local str
            if info.buildNeed[1] == info.buildNeed[2] then
                str = info.buildNeed[1]
            else
                str = info.buildNeed[1] .. "-" .. info.buildNeed[2]
            end
            info.labelNotice2:setVisible(true)
            info.labelNotice2:setString(Localizef("dataRankNeed" .. info.bid,{a = str}))
            if info.buildNeed[3] then
                info.labelNotice2:setString(Localizef("dataRankNeed"..str))
            end
        end
    end
end

function StoreDialog:addTreasureInfos(infos)
    local context = self.context
    local cf = self.config["treasure"]
    local idx = 0
    local storePrices = Plugins.storeItems
    -- 这里搞成配置吧，要加啥商品策划有数
    local i = 1
    local idx = 0
    local maxG = context:getProperty(const.ProGoldMax)
    local nowG = context:getProperty(const.ProGold)
    local guideCenter = {}
    while true do
        local storeItem = SData.getData("storeItems", 1, i)
        if not storeItem then
            break
        end
        local buyValue = storeItem.gvalue
        local costValue = storeItem.cvalue
        if storeItem.gtype == const.ResGold then
            if buyValue >= 100 then
                buyValue = maxG - nowG
            else
                -- 上次少写了一个0，通过数值去做临时处理
                if buyValue <= 5 then
                    buyValue = maxG * buyValue / 10
                else
                    buyValue = math.floor(maxG * buyValue / 100)
                end
                if buyValue + nowG > maxG then
                    buyValue = 0
                end
            end
        end
        if not buyValue or buyValue > 0 then
            local info = {
                contract = storeItem.contract, resource = storeItem.gtype, get = buyValue,
                type = storeItem.innerIdx,
                img = storeItem.img, imgx = storeItem.imgx, imgy = storeItem.imgy,
                imgs = storeItem.imgs, buyIdx = i
            }
            if type(storeItem.nameKey) == "table" then
                info.text = GameLogic.getItemName(storeItem.nameKey[1], storeItem.nameKey[2])
            else
                info.text = Localize(storeItem.nameKey)
            end
            if storeItem.storeIdx then
                info.gemIdx = storeItem.storeIdx - 1
                info.product = Plugins.storeKeys[storeItem.storeIdx]
                info.cost = Plugins.storeItems[info.product]
            else
                if costValue == 0 then
                    costValue = GameLogic.computeCostByRes(storeItem.gtype, buyValue)
                end
                info.ctype = storeItem.ctype or const.ResCrystal
                info.cost = costValue
            end
            -- 首充/次充翻倍之类的逻辑；
            if storeItem.sale then
                local sca = storeItem.sale
                if GameLogic.getBuyedCrystalNum(info.gemIdx) < 1 then
                    sca = 100
                end
                info.sale = sca
            end
            if storeItem.specialTag then
                info[storeItem.specialTag] = true
            end
            table.insert(infos, info)
            idx = idx + 1

            -- 定位
            if storeItem.innerIdx and storeItem.gtype then
                local temp = storeItem.gtype
                if type(temp) == "table" then
                    temp = temp[1] * 1000 + temp[2]
                end
                if not guideCenter[temp] then
                    guideCenter[temp] = {0, 0}
                end
                temp = guideCenter[temp]
                temp[1] = temp[1] + 1
                temp[2] = temp[2] + idx
            end
        end
        i = i + 1
    end
    self.__guideCenter = guideCenter
end

function StoreDialog:moveToCenter(tableView, gtype)
    local minfo = self.__guideCenter and self.__guideCenter[gtype]
    if minfo then
        local aidx = math.floor(minfo[2] / minfo[1] / 2 + 0.5)
        if aidx < 1 then
            aidx = 1
        end
        tableView:moveToCenter(aidx)
    end
end

function StoreDialog:addShieldInfos(infos)
    local cf = self.config["shield"]
    for i,shield in ipairs(const.ShieldSetting) do
        table.insert(infos, {ctype=const.ResCrystal, cvalue=shield[1], cdtime=shield[3], shieldId=i, name=StringManager.getString("storeItemShieldName" .. i),
        img="images/storeIconShield" .. i .. ".png", info=StringManager.getString("storeItemShieldInfo"),
        imgx = cf[i][1],imgy = cf[i][2],imgs = cf[i][3]})
    end
end

function StoreDialog:addEventInfos(infos)
    table.insert(infos, {ctype=const.ResEventMoney, cvalue=250, chance=99, get={res=const.ResGold, value=30000}})
    table.insert(infos, {ctype=const.ResEventMoney, cvalue=250, chance=1, get={res=const.ResGold, value=300000}})
    table.insert(infos, {ctype=const.ResEventMoney, cvalue=250, chance=99, get={res=const.ResSpecial, value=3000}})
    table.insert(infos, {ctype=const.ResEventMoney, cvalue=250, chance=2, get={res=const.ResMedicine, value=300}})
    table.insert(infos, {ctype=const.ResEventMoney, cvalue=250, chance=99, get={itype=const.ItemAccObj, item=1, value=1}})
    table.insert(infos, {ctype=const.ResEventMoney, cvalue=250, chance=1, get={itype=const.ItemAccObj, item=1, value=10}})
    table.insert(infos, {ctype=const.ResEventMoney, cvalue=250, chance=10, get={itype=const.ItemAccObj, item=2, value=1}})
    table.insert(infos, {ctype=const.ResEventMoney, cvalue=250, chance=5, get={itype=const.ItemAccObj, item=3, value=1}})
end

local function _sortHeroImages(a, b)
    if a.hinfo.price~=b.hinfo.price then
        return a.hinfo.price>b.hinfo.price
    else
        return a.hid>b.hid
    end
end

function StoreDialog:addHeroInfos(infos)
    local hinfos = SData.getData("hinfos")
    for hid, hinfo in pairs(hinfos) do
        if hid%1000>0 and hid<5000 and hinfo.price > 0 then

            local word1, word2, word3
            if hinfo.range>10 then
                word1 = Localize("enumRType2")
            else
                word1 = Localize("enumRType1")
            end
            word2 = Localize("enumUType" .. hinfo.utype)
            word3 = Localize("dataHeroType" .. (hinfo.htype or hinfo.job or 6))
            local hm = self.context.heroData:makeHero(hid)
            local skillDes = hm:getSkillDesc(1,true)
            local text = word1 .. "\n" .. word2 .. "\n" .. word3 .. "\n" .. skillDes
            table.insert(infos, {ctype=const.ResSpecial,cvalue=hinfo.price, hid=hid, hinfo=hinfo,
            name=GameLogic.getItemName(const.ItemHero, hid), info = text})
        end
    end
    table.sort(infos, _sortHeroImages)
end

function StoreDialog:addUPetsInfos(infos)
    local idxMap = {}
    for _, pid in ipairs(self.sparams.pets.pets) do
        idxMap[pid] = true
    end
    for i=1, 9 do
        local hid = 8000+i*10
        local hm = self.context.heroData:makeHero(hid)
        local descData = hm:getSkillData(1)
        local hinfo = SData.getData("hinfos",hid)
        local hitem = {ctype=const.ResPBead, cvalue=hinfo.price,hid=hid,pid=i,hinfo=hinfo, name=GameLogic.getItemName(const.ItemHero, hid), buyed=idxMap[i],info=Localizef("dataUPetSkill"..i,descData)}
        table.insert(infos, hitem)
    end
end

function StoreDialog:addEquipInfos(infos)
    for eid=2001,2009 do
        if eid~=2004 then
            local equip = self.context.equipData:makeEquip(eid)
            local infoNew = SData.getData("equipInfoNew", eid)
            table.insert(infos, {ctype=const.ResCrystal, cvalue = infoNew.price, order = infoNew.order or eid,
                eid=eid,name=GameLogic.getItemName(const.ItemEquip, eid),info=equip:getDesc()})
        end
        table.sort( infos, function (a,b)
            return a.order<b.order
        end )
    end
end

function StoreDialog:addBuildInfos(infos, bids)
    local bdata, binfo, sinfo, blv, bnum
    local context = self.context
    local cbuilds = context.buildData
    local tid = 1
    local tlevel = cbuilds:getMaxLevel(tid)
    local tmax = SData.getData("binfos", BU.getBSetting(tid).bdid).maxLv
    local bsetting

    for _, bid in ipairs(bids) do
        blv = 1
        bnum = cbuilds:getBuildNum(bid)
        bsetting = BU.getBSetting(bid)
        binfo = SData.getData("binfos", bsetting.bdid)
        if bsetting.numAsLevel then
            blv = bnum+1
            if blv>binfo.maxNum then
                blv = binfo.maxNum
            end
        end
        bdata = SData.getData("bdatas", bsetting.bdid, blv)
        if bid>=181 and bid<=185 then--神像按10个等级配置的
            local config = SData.getData("AllRankConfig",bid-180)
            if context.rankList[bid][2]<GameLogic.getSTime() then
                context.rankList[bid][1] = nil
            end
            local rank = context.rankList[bid][1]
            rank = rank and (rank+1)
            local blv = 0
            for i,v in ipairs(config) do
                if rank and v.minrk<=rank and rank<=v.maxrk then
                    blv = v.build
                end
            end

            local newConfig = {}
            for i, v in ipairs(config) do
                if v.build and v.build > 0 then
                    if newConfig[v.build] then
                        newConfig[v.build][1] = newConfig[v.build][1] < v.minrk and newConfig[v.build][1] or v.minrk
                        newConfig[v.build][2] = newConfig[v.build][2] > v.maxrk and newConfig[v.build][2] or v.maxrk
                    else
                        newConfig[v.build] = {v.minrk, v.maxrk}
                    end
                end
            end

            for i=1,10 do
                sinfo = {bid=bid,blevel=i,max=binfo.levels[tlevel], num=bnum, nextUnlock=0, time=bdata.ctime, name=BU.getBuildName(bid,i), info=BU.getBuildInfo(bid,i), ctype=bdata.ctype, cvalue=bdata.cvalue}
                sinfo.isSX = true
                if i == blv then
                    sinfo.canBuild = not BU.inServerCalTime(bid)
                else
                    sinfo.buildNeed = {newConfig[i][1], newConfig[i][2]}
                end
                if sinfo.max<binfo.maxNum then
                    for j=tlevel+1, tmax do
                        if binfo.levels[j]>sinfo.max then
                            sinfo.nextUnlock = j
                            break
                        end
                    end
                end
                table.insert(infos, sinfo)
            end
        elseif bid == 186 or bid == 187 then
            local kind = KnockMatchData:getStatueKind(bid)
            local _bdata = SData.getData("bdatas", bsetting.bdid, kind)
            sinfo = {bid=bid,blevel=kind,max=binfo.levels[tlevel], num=bnum, nextUnlock=0, time=_bdata.ctime, name=BU.getBuildName(bid,kind), info=BU.getBuildInfo(bid,kind, {a = _bdata.hpRate.."%"}), ctype=_bdata.ctype, cvalue=_bdata.cvalue}
            sinfo.isSX = true
            sinfo.canBuild = (KnockMatchData:canBuildStatue(bid) and (sinfo.num < sinfo.max) )
            if not sinfo.canBuild then
                sinfo.buildNeed = {bid.."_"..(kind), bid.."_"..(kind), true}
            end
            sinfo.canBuild = (sinfo.canBuild and (not BU.inServerCalTime(bid)) )
            if KnockMatchData:canShowInStore(bid) then
                table.insert(infos, sinfo)
            end
        elseif bid == 188 then
            local YouthDayData = GMethod.loadScript("game.GameLogic.YouthDayData")
            sinfo = {bid=bid,max=binfo.levels[tlevel], num=bnum, nextUnlock=0, time=bdata.ctime, name=BU.getBuildName(bid), info=BU.getBuildInfo(bid), ctype=bdata.ctype, cvalue=bdata.cvalue}
            sinfo.canBuild = YouthDayData:checkFinishAct() and (sinfo.num < sinfo.max)
            sinfo.isFirst = true
            sinfo.isSX = true
            if not sinfo.canBuild then
                sinfo.buildNeed = {bid, bid}
            end
            table.insert(infos, sinfo)
            context.guideHand:removeHand("youthDayStatueGuide")
            YouthDayData:setGuideStep(100)
        else
            sinfo = {bid=bid,max=binfo.levels[tlevel], num=bnum, nextUnlock=0, time=bdata.ctime, name=BU.getBuildName(bid), info=BU.getBuildInfo(bid), ctype=bdata.ctype, cvalue=bdata.cvalue}
            if 100<= bid and bid<=180 then
                sinfo.info = nil
            end
            if sinfo.max<binfo.maxNum then
                for j=tlevel+1, tmax do
                    if binfo.levels[j]>sinfo.max then
                        sinfo.nextUnlock = j
                        break
                    end
                end
            end
            table.insert(infos, sinfo)
        end
    end

    --神像排序
    if infos[1].isSX then
        for i,v in ipairs(infos) do
            if v.canBuild then
                local b = table.remove(infos,i)
                table.insert(infos,1,b)
            end
        end
        for i, v in ipairs(infos) do
            if v.canBuild and v.isFirst then
                local b = table.remove(infos, i)
                table.insert(infos, 1, b)
                break
            end
        end
    end
end

function StoreDialog:onReloadTreasure()
    if not self.deleted then
        if self.sparams and self.sparams.id == 1 then
            self:resetBottoms({{const.ResGold,1},{const.ResCrystal,2},{const.ResSpecial,1}})
            self:updateTreasureTableView()
        end
    end
end

function StoreDialog:updateTreasureTableView()
    if self.view and self.tableView then
        self.tableView.view:removeFromParent(true)
        local infos={}
        self:addTreasureInfos(infos)
        local oy=0
        local tableViewSetting = {size=cc.size(562, 394), offx=64, offy=152, disx=61, disy=134, rowmax=2, cellUpdate=Handler(self.updateTreasureCell, self)}
        local scale = ui.getUIScale2()
        local winSize = display.winSize
        local scale2 = (winSize[2]-346*scale-oy*scale)/(1190-oy)
        if scale>scale2 then
            scale = scale2
        end
        scale2 = winSize[1]/scale
        tableViewSetting.infos = infos
        local tableView = ui.createTableView({scale2, 1190-oy}, true, tableViewSetting)
        display.adapt(tableView.view, 0, -oy/2, GConst.Anchor.Center, {scale=scale})
        self.view:addChild(tableView.view,5)
        self.tableView = tableView
        self.storeInfos = infos
    end
end

function StoreDialog:onTreasureAction(info,cell,tableView)
    local context = self.context
    if info.resource and not info.contract then
        if info.resource==const.ResCrystal then
            if info.type == 6 then
                GameLogic.removeJumpGuide(const.JumpTypeDiamondStore)
            end
            for i,info in ipairs(self.storeInfos) do
                if info.cell then
                    info.cell:setGray(true)
                    info.cell:setEnable(false)
                end
            end
            if GameLogic.purchaseLock then
                display.pushNotice(Localize("noticePaying"))
                return
            end
            local params={callback = function (code)
                for i,info in ipairs(self.storeInfos) do
                    if info.cell then
                        info.cell:setGray(false)
                        info.cell:setEnable(true)
                    end
                end
            end}
            params.product = info.product
            --此接口用于区别礼包购买
            local bidx = 1
            local mc = 0
            local actId = 0
            if info.gemIdx then
                bidx = info.gemIdx + 1
            end
            GameUI.setLoadingShow("loading", true, 0)
            params["ext"] = ""
            GameLogic.purchaseLock = true
            GameNetwork.request("prebuy",{bidx=bidx,mc=mc,actId=actId}, function(isSuc,data)
                GameLogic.purchaseLock = nil
                GameUI.setLoadingShow("loading", false, 0)
                if isSuc then
                    Plugins:purchase(params)
                end
            end)
        elseif info.resource==const.ResGold then
            if info.type == 3 then
                GameLogic.removeJumpGuide(const.JumpTypeGoldStore)
            end
            local otherSettings = {cvalue = info.cost,ctype = const.ResCrystal,callback = function()
                context:buyRes(info.resource, info.get, info.cost)
                --context:changeRes(const.ResCrystal,-info.cost)
                GameLogic.statCrystalCost("商店购买资源消耗",const.ResCrystal,-info.cost)
                music.play("sounds/buy.mp3")
                display.pushNotice(Localize("noticeBuySuccess")..Localize(info.text))
                self:resetBottoms({{const.ResGold,1},{const.ResCrystal,2},{const.ResSpecial,1}})
                self:updateTreasureTableView()
            end}
            local dl = AlertDialog.new(1,Localize("buttonGoBuy"),Localizef("labelAffirmBuy",{a = info.text}),otherSettings)
            display.showDialog(dl)
        else
            if type(info.resource) == "table" then
                local otherSettings = {cvalue = info.cost,ctype = const.ResCrystal,callback = function()
                    context.guideHand:removeHand("guideBuyExp")
                    context:buyRes(info.resource, info.get, info.cost, info.buyIdx)
                    GameLogic.statCrystalCost("商店购买资源消耗",const.ResCrystal,-info.cost)
                    music.play("sounds/buy.mp3")
                    display.pushNotice(Localize("noticeBuySuccess")..Localize(info.text))
                    self:resetBottoms({{const.ResGold,1},{const.ResCrystal,2},{const.ResSpecial,1}})
                    GameEvent.sendEvent("refreshOtherHeroBlock")
                end}
                local dl = AlertDialog.new(1,Localize("buttonGoBuy"),Localizef("labelAffirmBuy",{a = info.text}),otherSettings)
                display.showDialog(dl)
            else
                GameLogic.removeJumpGuide(const.JumpTypeBlackStore)
                local otherSettings = {cvalue = info.cost,ctype = const.ResCrystal,callback = function()
                    GameLogic.getUserContext().guideHand:removeHand("guideBuyMedicine")
                    context:buyRes(info.resource, info.get, info.cost, info.buyIdx)
                    GameLogic.statCrystalCost("商店购买资源消耗",const.ResCrystal,-info.cost)
                    music.play("sounds/buy.mp3")
                    display.pushNotice(Localize("noticeBuySuccess")..Localize(info.text))
                    self:resetBottoms({{const.ResGold,1},{const.ResCrystal,2},{const.ResSpecial,1}})
                    if info.resource==const.ResMedicine and self.params and type(self.params)=="table" and self.params.labelMedicineNum then
                        self.params.labelMedicineNum:setString(N2S(context:getRes(const.ResMedicine)))
                    end
                    GameEvent.sendEvent("refreshHeroAwakeEnsureDialog")
                end}
                local dl = AlertDialog.new(1,Localize("buttonGoBuy"),Localizef("labelAffirmBuy",{a = info.text}),otherSettings)
                display.showDialog(dl)
            end
        end
    elseif info.contract then
        if info.isWelfare then
            local context = GameLogic.getUserContext()
            local vip = context:getInfoItem(const.InfoVIPlv)
            local userLv = context:getInfoItem(const.InfoLevel)
            local zhiwei = context.union and context.union.job or 0
            GameLogic.addStatLog(11401,vip,userLv,zhiwei)
        end
        local ctype = info.contract
        local params = {callback = function(code)
            for i,info in ipairs(self.storeInfos) do
                if info.cell then
                    info.cell:setGray(false)
                    info.cell:setEnable(true)
                end
            end
        end}
        local otherSettings = {callback = function()
            params.product = info.product
            local bidx = info.contract + 6
            for i,info in ipairs(self.storeInfos) do
                if info.cell then
                    info.cell:setGray(true)
                    info.cell:setEnable(false)
                end
            end
            if GameLogic.purchaseLock then
                display.pushNotice(Localize("noticePaying"))
                return
            end
            local mc = 0
            params["ext"] = ""
            if info.isWelfare then
                bidx = info.gemIdx+1
                mc = -1
                params["ext"] = "-1"
            end
            GameLogic.purchaseLock = true
            GameUI.setLoadingShow("loading", true, 0)
            _G["GameNetwork"].request("prebuy",{bidx=bidx,mc=mc,actId=0},function(isSuc,data)
                GameLogic.purchaseLock = nil
                GameUI.setLoadingShow("loading", false, 0)
                if isSuc then
                    Plugins:purchase(params)
                end
            end)
        end}
        if info.isWelfare then
            ctype=3
        end
        local dl = AlertDialog.new(3,Localize("storeItemContract" .. ctype),Localizef("storeItemContractDes"..ctype,{a = info.text}),otherSettings)
        display.showDialog(dl)
    else
        display.pushNotice(StringManager.getString("noticeNotSupport"))
    end
end

function StoreDialog:onFinishBuyItem(info)
    info.shopItem.left = info.shopItem.left-1
    info.chance = info.chance-1
    self.context:changeRes(info.ctype, -info.cvalue)
    GameLogic.statCrystalCost("商店购买物品消耗",info.ctype, -info.cvalue)
    local get = info.get
    self.context:changeItem(get.itype, get.item, get.value)
    display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(get.itype,get.item) .. "x" .. get.value}))
    if not self.deleted and info.viewLayout and not info.viewLayout.deleted then
        music.play("sounds/buy.mp3")
        self:updateItemsCell(info.cell, self.tableView, info)
        self:refreshAllPrices()
    end
end

function StoreDialog:onItemsAction(info, force)
    local shopData = self.equipShopData
    if shopData then
        if info.chance<=0 then
            display.pushNotice(Localize("noticeItemSelled"))
            music.play("sounds/buyDef.mp3")
            return
        end
        if GameNetwork.lockRequest() then
            if not force then
                GameNetwork.unlockRequest()
                display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"),Localizef("alertTextBuyItem",{name=GameLogic.getItemName(info.get.itype, info.get.item) .. "x" .. info.get.value}), {ctype=info.ctype, cvalue=info.cvalue, callback=Handler(self.onItemsAction, self, info, true)}))
            else
                if shopData.tag=="epart" then
                    GameNetwork.unlockRequest()
                    self:onFinishBuyItem(info)
                    self.context:addShopAction(shopData.tag, info.shopItem.idx)
                else
                    GameNetwork.request("pvtshopbuy",{pvtshopbuy={info.shopItem.idx}},self.onResponseBuyEquipItem,self,info)
                end
            end
        end
    else
        display.pushNotice(StringManager.getString("noticeNotSupport"))
    end
end

function StoreDialog:onResponseBuyEquipItem(info, suc, data)
    GameNetwork.unlockRequest()
    if suc and not (type(data)=="number" and data<0) then
        self:onFinishBuyItem(info)
    end
end

function StoreDialog:onNormalAction(info)

    if info.isBack2 then
        _updateFlipCell(info, false)
    else
        if info.bid then
            if info.isSX then                --神像
                if not info.canBuild then
                    if BU.inServerCalTime(info.bid) or GameLogic.isEmptyTable(info.buildNeed) then
                        display.pushNotice(Localize("stringCantBuildInServerCalTime"))
                    elseif info.num >= info.max then
                        display.pushNotice(Localize("noticeBuildFull"))
                    else
                        display.pushNotice(Localize("stringCantBuild"..info.bid))
                    end
                    return
                end
            end
            if info.max>info.num then
                GameEvent.sendEvent(GameEvent.EventBuyBuild, {bid=info.bid, blevel=info.blevel})
            elseif info.nextUnlock>0 then
                if info.max==0 then
                    display.pushNotice(Localizef("noticeUnlockByTown1",{level=info.nextUnlock}))
                else
                    display.pushNotice(Localizef("noticeUnlockByTown2",{level=info.nextUnlock}))
                end
            else
                display.pushNotice(Localize("noticeBuildFull"))
            end
        elseif info.pid then
            if info.buyed then
                display.pushNotice(Localize("noticeItemSelled"))
                music.play("sounds/buyDef.mp3")
            elseif self:getResValue(info.ctype)<info.cvalue then
                display.pushNotice(Localize("noticePBeadNotEnough"))
            else
                display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"),Localizef("alertTextBuyItem",{name=info.name}), {ctype=info.ctype, cvalue=info.cvalue, skipRes=true, callback=Handler(self.onBuyItem, self, info)}))
            end
        else
            --新装备走声望
            if info.eid and info.cvalue == 0 then
                --display.showDialog(PrestigeDialog.new())
                return
            end
            if info.shieldId then
                if info.remainCD>0 then
                    display.pushNotice(Localize("noticeBuyShieldCold"))
                    return
                end
                if info.shieldId == 1 then      --vip
                    local lock = self.context:getVipPermission("propect")[1]
                    if lock == 0 then

                    else
                        display.pushNotice(Localizef("labelVipCanUnlock",{a = lock}))
                        return
                    end
                end
            end
            if info.hid and GameLogic.getUserContext().heroData:getHeroNum()==GameLogic.getUserContext().heroData:getHeroMax() then
                display.pushNotice(StringManager.getString("labPromotePack"))
                return
            end
            display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"),Localizef("alertTextBuyItem",{name=info.name}), {ctype=info.ctype, cvalue=info.cvalue, callback=Handler(self.onBuyItem, self, info)}))
        end
    end
end

function StoreDialog:onBuyItem(item)
    local context = self.context
    if self:getResValue(item.ctype)>=item.cvalue then
        if item.pid then
            if GameNetwork.lockRequest() then
                GameNetwork.request("upetsbuy",{petsexchange={item.pid}},self.onResponseBuyUPets, self, item)
            end
            return
        elseif item.hid then
            context.heroData:buyNewHero(item.hid)
            --购买英雄加了SR以上的分享特效
            GameLogic.showHeroRewsUieffect({{9,item.hid,1}})
        elseif item.eid then
            context.equipData:buyNewEquip(item.eid)
        elseif item.shieldId then
            local idset = {4,1,2,3}
            context:addCmd({const.CmdBShield,idset[item.shieldId],context.uid})
            self.context:changeRes(item.ctype, -item.cvalue)
            GameLogic.statCrystalCost("购买保护盾消耗",item.ctype, -item.cvalue)
            local sdata = self.context.enterData.ustate
            local stime = GameLogic.getSTime()
            local ctime = sdata[1]
            if stime>ctime then
                ctime = stime
            end
            sdata[1]=ctime+const.ShieldSetting[item.shieldId][2]
            sdata[2+item.shieldId] = stime+const.ShieldSetting[item.shieldId][3]
            GameEvent.sendEvent("refreshStoreRedNum")
            if not self.deleted then
                self:refreshAllPrices()
            end
            display.pushNotice(Localizef("noticeGetItem",{name=item.name}))
            return
        end
        display.pushNotice(Localizef("noticeGetItem",{name=item.name}))
        context:changeRes(item.ctype, -item.cvalue)
        GameLogic.statCrystalCost("购买装饰物消耗",item.ctype, -item.cvalue)
        self:refreshAllPrices()
        music.play("sounds/buy.mp3")
    end
end



function StoreDialog:onResponseBuyUPets(item, suc, data)
    GameNetwork.unlockRequest()
    if suc and data>0 then
        self.sparams.pets.pbead = self.sparams.pets.pbead-item.cvalue
        table.insert(self.sparams.pets.pets, item.pid)
        item.buyed = true
        if not self.deleted then
            self:updateNormalCell(item.cell, self.tableView, item)
            self:refreshAllPrices()
        end
    end
end


