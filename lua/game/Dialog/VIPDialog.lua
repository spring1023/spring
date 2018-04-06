local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
--VIP特权对话框
VIPDialog = class(DialogViewLayout)

function VIPDialog:onInitDialog()
    self:setLayout("VIPDialog.json")
    self:loadViewsTo()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self.questionTag = Localizef("prestigeHelp",{n=self.maxPrestigeNum})
    self.context = GameLogic.getUserContext()
    self.selectBut = 1
    self:initUI()
    local bgNode = ui.node()
    self.view:addChild(bgNode)
    GameEvent.bindEvent(bgNode,"refreshDialog",self,function()
        self:initBottom()
    end)
end

function VIPDialog:initUI()
    self.butNextLeft:setScriptCallback(ButtonHandler(function()
        if self.idx>1 then
            self.idx = self.idx-1
            self:reload()
            self:butNextShow()
        end
    end))

    self.butNextRight:setScriptCallback(ButtonHandler(function()
        if self.idx<10 then
            self.idx = self.idx+1
            self:reload()
            self:butNextShow()
        end
    end))

    self.butVipInfo:setScriptCallback(ButtonHandler(function ()
        -- body
        if self.selectBut ~= 1 then
            self.selectBut = 1
            self:reload()
        end
    end))

    self.butVipGift:setScriptCallback(ButtonHandler(function ()
        -- body
        if self.selectBut ~= 2 then
            self.selectBut = 2
            self:reload()
        end
    end))

    self.vipCode = GameUI.addRedNum(self.butVipGift,330,60,0,0.2,99)
    self:initBottom()
    self:reload()
    self:butNextShow()
end

function VIPDialog:butNextShow()
    if self.idx==1 then
        self.butNextLeft:setVisible(false)
    elseif self.idx==10 then
        self.butNextRight:setVisible(false)
    else
        self.butNextLeft:setVisible(true)
        self.butNextRight:setVisible(true)
    end
end

--出于需求改动,将进度条和VIP图片移到reload中,不再在此中初始化
function VIPDialog:initBottom()
    if self.bottomNode then
        self.bottomNode:removeFromParent(true)
        self.bottomNode = nil
    end
    self.bottomNode = ui.node()
    self:addChild(self.bottomNode)
    local topupNum = self.context:getInfoItem(const.InfoVIPexp)
    local vip = 0
    local nvip = 0
    local vippower = SData.getData("vippower")
    local topupNum = topupNum
    for i,v in ipairs(vippower) do
        if topupNum>=v.crynum then
            vip = i
            if i<10 and topupNum<vippower[i+1].crynum then
                nvip = i+1
            end
        end
    end
    if vip == 0 then
        nvip = 1
    end
    self.vip = vip
    self.nvip = nvip
    self.idx = (vip == 0 and 1 or vip)

    local w = self.topupNumA.view:getContentSize().width
    local h = self.topupNumA.view:getPositionY()
    local vipNode = GameUI.addVip(self.bottomNode,vip,226+15,h-20,3,{withBack=true})
    vipNode:setScale(1.3)
    self.iconCrystal:setPosition(870+w,h-50)
    self.labelCanBe:setPosition(800+w,h)

    self.setButLis = true
    self.butRecharge:setScriptCallback(ButtonHandler(function()
        StoreDialog.new({id = 1, pri = self.priority+1})
    end))
    self.btnCharge:setString(Localize("btnCharge"))
    self.labelVipPrivilege:setString(Localize("labelVipPrivilege"))
    self.labelVipPreGift:setString(Localize("labelVipPreGift"))
end

function VIPDialog:reload()
    if self.idx >= self.vip then
        if self.bottomNode2 then
            self.bottomNode2:removeFromParent(true)
            self.bottomNode2 = nil
        end
        self.bottomNode2 = ui.node()
        self:addChild(self.bottomNode2)

        local topupNum = self.context:getInfoItem(const.InfoVIPexp)
        local vippower = SData.getData("vippower")
        local topupNum = topupNum
        local vip = self.vip
        local nvip = self.nvip

        local processValue = 0
        local nextValue = vippower[self.idx].crynum
        local all = vippower[self.idx].crynum
        if self.idx <= vip then
            nextValue = vippower[nvip].crynum
            all = vippower[nvip].crynum
        end
        processValue = (topupNum)/all
        print(topupNum,vippower[self.idx].crynum,vippower[vip].crynum)
        print(processValue,topupNum-vippower[vip].crynum,all)
        self.topupProcess:setProcess(true,processValue)
        self.topupProcessValue:setString(topupNum.."/"..nextValue)

        local topupA = vippower[self.idx].crynum-topupNum
        local str
        if topupA>0 then
            str = Localizef("labelTopupA",{a = topupA})
            self.labelCanBe:setVisible(true)
        elseif self.idx == KTLen(vippower) then
            str = Localize("labelGetTopVip")
            self.labelCanBe:setVisible(false)
            self.iconCrystal:setVisible(false)
        else
            topupA = vippower[nvip].crynum-topupNum
            str = Localizef("labelTopupA",{a = topupA})
            self.labelCanBe:setVisible(true)
        end
        self.topupNumA:setString(str)


        local w = self.topupNumA.view:getContentSize().width
        local h = self.topupNumA.view:getPositionY()
        local a = self.idx
        if self.idx <= vip then
            a = nvip
        end
        GameUI.addVip(self.bottomNode2,a,818+w,h-15,3)
    end

    self.titleVip:setString(Localizef("labelVipX",{a = self.idx}))
    self.titleVip2:setString(Localizef("titleVipPrivilege",{a = self.idx}))
    self.vipCode:setNum(0)
    if (self.context:getProperty(const.ProBuyVipPkg1)==0) and (self.context:getInfoItem(const.InfoVIPlv)>0) then
        self.vipCode:setNum(1)
    end
    self:dVipDes(self.selectBut)
end

function VIPDialog:dVipDes(type)
   if self.selectBut == 1 then
        self.vipInfoImg:setImage("images/dialogTabBack4_3.png")
        self.vipGiftImg:setImage("images/dialogTabBack4_1.png")
        self:getCellViewsData()
   else
        self.vipGiftImg:setImage("images/dialogTabBack4_3.png")
        self.vipInfoImg:setImage("images/dialogTabBack4_1.png")
        self:getGiftViewsData()
   end
end

function VIPDialog:getItemsData(data)--特惠礼包界面
    -- body
    local infos = {}
    local cType = const.ProBuyVipPkg1
    local cTime = const.ProBuyVipPkgTime1
    for k=1,3 do
        table.insert(infos,{id = k-1,rwds = data["rwds"..k],xgnum = data["rnum"..k],price=data["cost"..k],ctype = cType+k-1,ctime = cTime+k-1})
    end
    return infos
end

function VIPDialog:getGiftViewsData()
    -- body
    self.leftNode:removeAllChildren(true)
    local infos = {}
    local vipgift = SData.getData("vipPkgRwds",self.idx)
    infos = self:getItemsData(vipgift)
    if self.tableNode then
        self.tableNode:setVisible(false)
    end
    self.giftNode = GameUI.helpLoadTableView(self.leftNode,infos,Handler(self.showGiftViews,self))
    self.giftNode.view:setVisible(true)
end

function VIPDialog:showGiftViews(cell, tableView, info)
    if not info.viewLayout then
        local items = info
        local bg  = cell:getDrawNode()
        info.viewLayout = self:addLayout("cellView",bg)
        info.viewLayout:loadViewsTo(info)
        info.labelCellTitle:setString(Localizef("labelVipDailyGiftNum"..items.id,{n = self.idx}))
        local str,str1,butType,btnCell = "","",0
        for k,v in pairs(items.rwds) do
            btnCell = ui.button({180,180},nil,{})
            display.adapt(btnCell,((k-1)%2)*200+50,235-(math.floor((k-1)/2))*200,GConst.Anchor.LeftBottom)
            info.cellItemNode:addChild(btnCell,1)
            GameUI.addItemIcon(btnCell,v[1],v[2],0.8,90,90,true)
            local bNum=ui.label("X"..v[3], General.font1, 30)
            display.adapt(bNum, 170,30,GConst.Anchor.Right)
            btnCell:addChild(bNum)
            GameUI.registerTipsAction(btnCell, self.view, v[1], v[2])
        end
        self:checkVIPGiftType(items.xgnum,items.ctype,items.ctime)
        local cVipType = self:checkVIPGiftBuyType(items.xgnum,items.ctype,items.ctime)
        if items.ctype == const.ProBuyVipPkg1 then
            if cVipType then
                butType = 1
            end
            info.btnCrystal:setVisible(false)
            local x = info.labelButBuy._setting.x
            info.labelButBuy:setPositionX(x+20)
            str = Localize("btnReceive")
        else
            if cVipType then
                butType = 1
            end
            str = items.price
            info.labelCellTip:setString(Localizef("labelVipWeeksNum"..items.id,{n=items.xgnum}))
        end

        if butType == 1 then
            info.butBuy:setScriptCallback(ButtonHandler(self.onRequestVipReward, self, items))
        elseif butType == 0 then
            info.butBuy:setGray(true)
        end
        info.labelButBuy:setString(str)
    end
end

function VIPDialog:onRequestVipReward(items)
    if items.price > self.context:getRes(const.ResCrystal) then
        display.showDialog(AlertDialog.new({ctype=const.ResCrystal, cvalue=items.price}))
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("vipreward", {pid=items.id, vlv=self.idx}, Handler(self.onResponseVipReward, self, items, self.idx))
end

function VIPDialog:onResponseVipReward(items, vlv, suc, data)
    GameNetwork.unlockRequest()
    if suc then
        if type(data) == "number" then
            return
        end
        local num = 1
        if items.ctype == const.ProBuyVipPkg3 then
            num = math.pow(10, vlv-1)+self.context:getProperty(items.ctype)
        elseif items.ctype == const.ProBuyVipPkg2 then
            num = self.context:getProperty(items.ctype)+1
        end
        self.context:setProperty(items.ctime, GameLogic.getSTime())
        self.context:setProperty(items.ctype, num)
        self.context:changeProperty(const.ResCrystal, -items.price)
        GameLogic.addRewards(data.agls)
        GameLogic.showGet(data.agls)
        if not self.deleted then
            self:reload()
        end
    end
end

function VIPDialog:checkVIPGiftType(cgNum,ctype,ctime)
    -- body
    --判断每一个vip礼包的状态。刷新或者不刷新
    local curNum,curTime,curVIP = self.context:getProperty(ctype),self.context:getProperty(ctime),self.context:getInfoItem(const.InfoVIPlv)
    if self.idx<=curVIP then
        if ctype == const.ProBuyVipPkg1 then
            if GameLogic.isTomorrow(curTime) then
                GameLogic.reVIPGiftData(3)
            end
        elseif ctype == const.ProBuyVipPkg2 then
            local day = math.ceil(math.ceil((GameLogic.getSTime()-const.InitTime)/86400)/7) - math.ceil(math.ceil((curTime-const.InitTime)/86400)/7)
            if day>0 then
                GameLogic.reVIPGiftData(2)
            end
        end
    end
end

function VIPDialog:checkVIPGiftBuyType(cgNum,ctype,ctime)
    -- body
    local curNum,curTime,curVIP = self.context:getProperty(ctype),self.context:getProperty(ctime),self.context:getInfoItem(const.InfoVIPlv)
    if ctype ~= const.ProBuyVipPkg3 then
        if self.idx~=curVIP then
            return false
        end
    else
        if self.idx>curVIP then
            return false
        end
    end
    if ctype == const.ProBuyVipPkg1 then
        if curNum>0 then
            return false
        end
    elseif ctype == const.ProBuyVipPkg2 then
        if curNum>=cgNum then
            return false
        end
    elseif ctype == const.ProBuyVipPkg3 then
        local num = math.pow(10,self.idx)
        local num1 = math.pow(10,self.idx-1)
        num = math.floor(curNum%num/num1)
        if num>0 then
            return false
        end
    end
    return true
end

function VIPDialog:getCellViewsData()
    local set = {
        {"relbuild","dataVipDes_relbuild"},{"accres","dataVipDes_accres"},{"pvcs","dataVipDes_pvcs"},
        {"djtimes","dataVipDes_beerNum"},{"pvts","dataVipDes_pvts"},{"lottery","dataVipDes_lottery"},
        {"accga","dataVipDes_accga"},{"propect","dataVipDes_propect"},{"luck","dataVipDes_luck"},
        {"pvjcr","dataVipDes_pvjcr"},{"fbox","dataVipDes_fbox"},
        {"chat","dataVipDes_chat"},{"pvhs","dataVipDes_pvhs"},{"pvhbox","dataVipDes_pvhbox"},
        {"pvesweep","dataVipDes_pvesweep"},{"pvebuy","dataVipDes_pvebuy"},{"pvetimes","dataVipDes_pvetimes"},
        {"pvhpass","dataVipDes_pvhsweep"}
    }
    local infos  = {}
    local power = SData.getData("vippower",self.idx)
    for i,v in ipairs(set) do
        if v[1] == "pvhbox" then
            power[v[1]]=power[v[1]]-1
        end
        if v[1] == "dataVipDes_pvjcr" then
            power[v[1]]=power.pvjcr
        end
        if power[v[1]]>0 then
            table.insert(infos,{id=#infos+1, str=Localizef(v[2],{a=power[v[1]]})})
        end
    end
    if self.tableNode then
        self.tableNode:removeAllChildren(true)
    else
        self.tableNode = ui.node()
        self:addChild(self.tableNode,100)
    end
    if self.giftNode then
        self.giftNode.view:setVisible(false)
    end
    self.tableNode:setVisible(true)
    self:showCellViews(infos)
end

function VIPDialog:showCellViews(infos)
    local scNode=ScrollNode:create(cc.size(1652,668), -self.dialogDepth, false, true)
    scNode:setScrollEnable(true)
    scNode:setInertia(true)
    scNode:setElastic(true)
    scNode:setClip(true)
    scNode:setScaleEnable(true, 1, 1, 1, 1)
    display.adapt(scNode, 173, 90, GConst.Anchor.LeftBottom)
    self.tableNode:addChild(scNode,1)

    local viewsNode=ui.node()
    display.adapt(viewsNode, 0, 668)
    scNode:getScrollNode():addChild(viewsNode,1)

    local oy=16
    for i=1,#infos do
        local info=infos[i]
        local star = ui.sprite("images/dialogStar1_1.png",{57,61})
        display.adapt(star,100,-oy,GConst.Anchor.LeftTop)
        viewsNode:addChild(star)
        local lb = ui.label(info.str,General.font1,50,{color={255,255,255}, width=1400, align=GConst.Align.Left})
        display.adapt(lb,150,-oy,GConst.Anchor.LeftTop)
        viewsNode:addChild(lb)
        oy=oy+lb:getContentSize().height+20
    end
    if oy>668 then
        scNode:setScrollContentRect(cc.rect(0,668-oy,0,oy))
    end
end










