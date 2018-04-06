--2017-3-3 弃用HeroExtractTab，使用新的抽英雄界面HeroExtractNewTab
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local ShowHeroMainDialog = GMethod.loadScript("game.Dialog.ShowHeroMainDialog")
local HeroExtractNewTabAction = GMethod.loadScript("game.Dialog.HeroExtractNewTabAction")

local HeroExtractNewTab = class(DialogTab)

local _viewCellX, _viewCellY = 337, 507
function HeroExtractNewTab:addArrow()
    local context = GameLogic.getUserContext()
    self.guideHand=context.guideHand:showArrow(self.butEx1,175,142,0)
    ui.setColor(self.costLabels[1][2], GConst.Color.White)
end
function HeroExtractNewTab:create()
    ShowHeroMainDialog.inAnimate = false
    local context = GameLogic.getUserContext()
    if math.floor((context:getProperty(const.ProLTBoxTime) - const.InitTime)/86400) < math.floor((GameLogic.getSTime() - const.InitTime)/86400) then
        context:setProperty(const.ProLTBoxTime, GameLogic.getSTime())
        context:setProperty(const.ProLTBoxRate, 0)
    end
    self.Game_hot_hero = {
        Crtical_strike = context:getProperty(const.ProLTBoxRate),    --当前暴击值107,需要加10
        Ten = context:getProperty(const.ProLTNum),    --十连抽的次数101
    }

    --引导
    local gstep = context.guide:getStep()
    if gstep.type == "exHero1" then
        display.showDialog(StoryDialog.new({context=context,storyIdx=gstep.storys[2],callback=Handler(self.addArrow, self)}),false,true)
    end

    local dialog = self:getDialog()
    dialog.title:setString(StringManager.getString("btnExtracthero"))
    dialog.title:setVisible(true)
    dialog.questionBut:setVisible(true)

    local bg = ui.node(nil, true)
    self.view = bg
    local temp

    temp = ui.csbNode("UICsb/e_0.csb")
    display.adapt(temp,1024,768,GConst.Anchor.Center)
    bg:addChild(temp)

    temp = ui.sprite("images/proBack4.png", {450, 46})
    display.adapt(temp, 1510, 1256)
    bg:addChild(temp)
    temp = ui.sprite("images/proFillerYellow.png",{446,40})
    display.adapt(temp,1512,1259)
    bg:addChild(temp)
    self.luckyProcess = temp

    --幸运大转盘
    temp = ui.button({137, 137}, self.onLuckyMethod, {cp1=self, image="images/dialogItemLucky1.png"})
    display.adapt(temp, 1392, 1210)
    bg:addChild(temp)
    self.luckyBut = temp

    temp = ui.particle("images/dialogs/xingpao1.plist")
    temp:setPosition(1420,1210)
    temp:setPositionType(cc.POSITION_TYPE_RELATIVE)
    bg:addChild(temp)
    temp:runAction(ui.action.arepeat(ui.action.sequence({{"moveTo",0.2,1380,1256},{"moveTo",0.2,1420,1340},{"moveTo",0.2,1500,1340},{"moveTo",0.2,1540,1256},{"moveTo",0.2,1500,1210},{"moveTo",0.2,1420,1210}})))
    self.luckyEffect = temp
    self.luckyEffect:setVisible(false)
    --显示幸运值
    temp = ui.label("", General.font1, 60)
    display.adapt(temp, 1744, 1277, GConst.Anchor.Center)
    bg:addChild(temp)
    self.luckyLabel = temp

    self:refreshLuck()

    local cells = {}
    self.cells = cells
    local x,y = _viewCellX, _viewCellY
    local item
    self.costLabels = {}
    for i=1,3 do
        local nd=ui.node({683,1536}, true)
        nd:setPosition(653*(i-1)+10,0)
        bg:addChild(nd)
        item = {view=nd}
        cells[i] = item
        local node2=ui.node(nil, true)
        node2:setPosition(341, 507)
        nd:addChild(node2)

        if i == 3 then
            temp = ShowHeroMainDialog.HotHero(node2,0,193,i)
            --神秘召唤的框
            self.hotTemp = temp
            self.hotNode = node2
            --锁
            -- local lock = ui.button({370,475}, self.onExtractMethod, {cp1=self, cp2=4, image="images/lockIcon.png"})
            -- display.adapt(lock, 0, 193,GConst.Anchor.Center)
            -- node2:addChild(lock)
            -- self.soulBox = lock
            --self.soulBox:setVisible(false)
            --num = 暴击率的值
            local crit = math.floor(self.Game_hot_hero.Crtical_strike/10)+10
            local vcrit = ui.label(Localizef("critProbability",{num=crit}), General.font1, 36)
            display.adapt(vcrit, 335, 280, GConst.Anchor.Center)
            temp:addChild(vcrit)
            self.critValue = vcrit
        else
            --守护者召唤和王者召唤框
            temp = ShowHeroMainDialog.HotHero(node2,0,180,i)
        end

        local j = i
        if context:getProperty(const.ProFreeTime)>GameLogic.getSTime() then  --还在倒计时
            j= j + 1
        else
            if j ~= 1 then j=j+1 end
        end
        local lsetting = SData.getData("hlsetting", j)
        local colors = {1,3}
        --神秘召唤的前往按钮
        temp = ui.button({351,142}, self.onExtractMethod, {cp1=self, cp2=j, image="images/btnGreen.png"})
        display.adapt(temp, 341, 220, GConst.Anchor.Center)
        nd:addChild(temp)
        --守护者召唤和王者召唤的抽奖按钮
        self["butEx" .. i] = temp
        local but = temp:getDrawNode()
        if i==1 then
            --单抽UI
            local nd_one = ui.node()
            display.adapt(nd_one, 0, 0, GConst.Anchor.Center)
            but:addChild(nd_one)
            nd_one:setVisible(false)
            self.one_raffle = nd_one

            temp = ui.label(tostring(const.OneRaffleTicket), General.font1, 60, {fontW = 360, fontH = 90})
            display.adapt(temp, 145, 86, GConst.Anchor.Center)
            nd_one:addChild(temp)
            temp = ui.sprite("images/items/itemIcon23_1.png",{86,86})
            display.adapt(temp, 331, 86, GConst.Anchor.Right)
            nd_one:addChild(temp)

            self.freeBut = temp
            temp = ui.label("", General.font1, 36)
            display.adapt(temp, 341, 450, GConst.Anchor.Center)
            nd:addChild(temp)
            self.freeChanceLabel = temp
            temp = GameUI.addResourceIcon(but, const.ResCrystal, 0.88, 285, 86)
            self.freeIcon = temp
            --单抽价格
            temp = ui.label(tostring(lsetting.cvalue), General.font1, 60, {fontW = 360, fontH = 90})
            display.adapt(temp, 175, 86, GConst.Anchor.Center)
            but:addChild(temp)
            table.insert(self.costLabels, {lsetting.cvalue, temp, true})
            self.freeBtnlabel = temp
        elseif i == 3 then
            --神秘召唤的前往按钮
            temp = ui.label("", General.font1, 60)
            display.adapt(temp, 175, 86, GConst.Anchor.Center)
            but:addChild(temp)
            temp:setString(Localize("buttonGo"))
        else
            --十连抽的抽奖券UI
            local nd_ten = ui.node()
            display.adapt(nd_ten, 0, 0, GConst.Anchor.Center)
            but:addChild(nd_ten)
            nd_ten:setVisible(false)
            self.ten_raffle = nd_ten

            temp = ui.label(tostring(const.TenRaffleTicket), General.font1, 60, {fontW = 360, fontH = 90})
            display.adapt(temp, 145, 86, GConst.Anchor.Center)
            nd_ten:addChild(temp)
            temp = ui.sprite("images/items/itemIcon23_2.png",{86,86})
            display.adapt(temp, 331, 86, GConst.Anchor.Right)
            nd_ten:addChild(temp)
            --钻石图标
            local nd_diamond = ui.node()
            display.adapt(nd_diamond, 0, 0, GConst.Anchor.Center)
            but:addChild(nd_diamond)
            nd_diamond:setVisible(true)
            self.nd_diamond = nd_diamond

            GameUI.addResourceIcon(nd_diamond, const.ResCrystal, 0.88, 285, 86)
            --价格
            temp = ui.label(tostring(lsetting.cvalue), General.font1, 60)
            display.adapt(temp, 238, 86, GConst.Anchor.Right)
            nd_diamond:addChild(temp)
            -- 这里要传的是要变色的label
            table.insert(self.costLabels, {lsetting.cvalue, temp, true})
            colors[1], colors[2] = 2, 4
            if i == 2 then
                --我要变强引导
                GameLogic.getJumpGuide(const.JumpTypeWish,but,175,91)
            end
            local nodeDisCount=ui.node()
            --价格1
            local temp = ui.label(tostring(lsetting.cvalue), General.font1, 35)
            display.adapt(temp, 208, 110, GConst.Anchor.Right)
            nodeDisCount:addChild(temp)
            GameUI.addResourceIcon(nodeDisCount, const.ResCrystal, 0.88, 285, 86)
            --价格2
            local price = (GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWishDiscount)[4] or 1)*lsetting.cvalue
            temp = ui.label(tostring(price), General.font1, 45)
            display.adapt(temp, 208, 60, GConst.Anchor.Right)
            table.insert(self.costLabels,{price,temp,true})
            nodeDisCount:addChild(temp)
            --划线
            local node=ui.node()
            node.size={100,20}
            display.adapt(node,110,98,GConst.Anchor.Center)
            nodeDisCount:addChild(node)
            but:addChild(nodeDisCount)
            self.nodeDiscount=nodeDisCount
            GameUI.addRedLine(node, true)
        end
        --再见神秘召唤
        if GameLogic.useTalentMatch then
            nd:setPosition(653*i+25,0)
            if i==2 then
                local labelMustGet = ui.label("", General.font1, 32)
                display.adapt(labelMustGet, 348, 136, GConst.Anchor.Center)
                nd:addChild(labelMustGet)
                local labelMustGet2 = ui.label("", General.font1, 32)
                display.adapt(labelMustGet2, 0, -30, GConst.Anchor.Left)
                labelMustGet:addChild(labelMustGet2)
                GameEvent.bindEvent(labelMustGet,"EventFreshMustGet", labelMustGet, function()
                    local value=10-(context:getProperty(const.ProLTNum)-context:getProperty(const.ProLTCurNum))
                    if value < 1 then
                        value = 1
                    end
                    local valueUr=50-(context:getProperty(const.ProLTNum)-context:getProperty(const.ProLTUrCurNum))%50
                    local str1=Localizef("canGetSSRMain",{a = value})
                    local str2=Localizef("canGetURMain",{b = valueUr})
                    labelMustGet:setString(str1)
                    labelMustGet2:setString(str2)
                end)
                GameEvent.sendEvent("EventFreshMustGet")
                --金币单抽和金币十连
                local nd=ui.node({683,1536}, true)
                nd:setPosition(25,0)
                bg:addChild(nd)
                item = {view=nd}
                cells[i] = item
                local node2=ui.node(nil, true)
                node2:setPosition(341, 507)
                nd:addChild(node2)
                temp = ShowHeroMainDialog.HotHero(node2,0,180,4)
                --金币单抽按钮
                temp = ui.button({221,112}, self.onExtractMethod, {cp1=self, cp2=6, image="images/btnGreen.png"})
                display.adapt(temp, 221, 210, GConst.Anchor.Center)
                nd:addChild(temp)
                self.butEx6=temp

                temp = ui.label(Localize("GoldExtractSingle"), General.font1, 40)
                display.adapt(temp, 110.5, 56, GConst.Anchor.Center)
                self.butEx6:addChild(temp)
                --金币连抽按钮
                temp = ui.button({221,112}, self.onExtractMethod, {cp1=self, cp2=7, image="images/btnGreen.png"})
                display.adapt(temp, 461, 210, GConst.Anchor.Center)
                nd:addChild(temp)
                self.butEx7=temp

                temp = ui.label(Localize("GoldExtractDozen"), General.font1, 40)
                display.adapt(temp, 110.5, 56, GConst.Anchor.Center)
                self.butEx7:addChild(temp)
                --
                temp = ui.label("", General.font1, 36)
                display.adapt(temp, 341, 450, GConst.Anchor.Center)
                nd:addChild(temp)
                self.goldChanceLabel = temp
                self.goldChanceLabel:setString(Localizef("remainExtractTimes",{a=(const.GoldExtractLimit-GameLogic:getGoldExtractChance()).."/"..const.GoldExtractLimit}))
                break
            end    
        end

    end
    --倒計時的
    self:updateExtractButs()
    RegTimeUpdate(self.freeChanceLabel, Handler(self.updateExtractButs, self), 0.2)
    --背景啊
    local viewLayout = ViewLayout.new()
    viewLayout:setView(bg, {2048, 1536})
    viewLayout:addLayout("HeroExtractNewTab.json")
    viewLayout:loadViewsTo(self)

    local hdata = self:getContext().heroData

    self:refreshHeros()
    self:getDialog().questionTag = "dataQuestionHeroExtract"

    local bNode=ui.node()
    self.view:addChild(bNode)
    GameEvent.bindEvent(bNode,"addHtoHero", self, self.refreshEggDialog)

    local context = GameLogic.getUserContext()
    local vip = context:getInfoItem(const.InfoVIPlv)
    local userLv = context:getInfoItem(const.InfoLevel)
    local ProCombat = context:getProperty(const.ProCombat)
    GameLogic.addStatLog(11201,vip,userLv,ProCombat)
    return self.view
end

--幸运大转盘
function HeroExtractNewTab:onLuckyMethod()
    local num = self:getContext():getProperty(const.ProLuck)
    if num >= 100 then
        display.showDialog(LuckyLotteryDialog.new({parent=self, context=self:getContext()}))
    else
        display.pushNotice(Localize("LuckyLess"))
    end
end
--刷新资源数量
function HeroExtractNewTab:refreshHeros()
    local context = self:getContext()
    local hdata = context.heroData
    self.heroNumLabel:setString(tostring(hdata:getHeroNum()).."/"..tostring(hdata:getHeroMax()))
    self.specialLabel:setString(tostring(context:getRes(const.ResSpecial)))
    self.silverLabel:setString(context:getItem(const.ItemTicket, const.TicketOne))
    self.goldLabel:setString(context:getItem(const.ItemTicket, const.TicketTen))
    if self.getSpecial then
        display.pushNotice(Localize("dataResName" .. const.ResSpecial) .. "+" .. self.getSpecial)
        self.getSpecial = nil
    end
end

--获取抽奖券pid并获取抽奖券的数量
function HeroExtractNewTab:checkRaffle(flag)
    local context = GameLogic.getUserContext()
    return context:getItem(const.ItemTicket, flag) > 0
end

function HeroExtractNewTab:updateExtractButs(diff)
    local context = GameLogic.getUserContext()
    local stime = GameLogic.getSTime()
    local ctime = context:getProperty(const.ProFreeTime)
    local chance = GameLogic:getGoldExtractChance()
    local flag1 = self:checkRaffle(1)
    local flag2 = self:checkRaffle(2)
    local flag3 = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWishDiscount)
    if not flag2 and flag3[4]~=0 and flag3[4]~=1 then
        self.ten_raffle:setVisible(false)
        self.nd_diamond:setVisible(false)
        self.nodeDiscount:setVisible(true)
    else
        self.nodeDiscount:setVisible(false)
        self.ten_raffle:setVisible(flag2)
        self.nd_diamond:setVisible(not flag2)
    end
    --金币抽取
    if self.goldChanceLabel then
        self.goldChanceLabel:setString(Localizef("remainExtractTimes",{a=(const.GoldExtractLimit-GameLogic:getGoldExtractChance()).."/"..const.GoldExtractLimit}))
    end
    if GameLogic.useTalentMatch then
        if (const.GoldExtractLimit-chance)>=10 then
            self.butEx6:setGray(false)
            self.butEx7:setGray(false)
        elseif  (const.GoldExtractLimit-chance)<10 and (const.GoldExtractLimit-chance)>0 then
            self.butEx6:setGray(false)
            self.butEx7:setGray(true)
        else
            self.butEx6:setGray(true)
            self.butEx7:setGray(true)
        end
    end
    --十连抽
    if ctime>stime then --倒计时中
        self.freeChanceLabel:setString(Localizef("afterfree",{time=StringManager.getTimeString(ctime-stime)}))
        self.freeIcon:setVisible(true)
        self.freeBtnlabel:setString(tostring(SData.getData("hlsetting", 2).cvalue))
        --单抽
        self.freeIcon:setVisible(not flag1)
        self.freeBtnlabel:setVisible(not flag1)
        self.one_raffle:setVisible(flag1)
    else
        self.freeChanceLabel:setString(StringManager.getFormatString("labelFreeChance",{num=1}))
        self.freeIcon:setVisible(false)
        self.freeBtnlabel:setString(StringManager.getString("btnFreeExtract"))
        self.one_raffle:setVisible(false)
    end
    if context.guide:getStep().type ~= "finish" then
        self.butEx2:setGray(true)
        self.butEx2:setEnable(false)
        if self.butEx3 then
            self.butEx3:setGray(true)
            self.butEx3:setEnable(false)
        end
        if self.butEx6 then
            self.butEx6:setGray(true)
            self.butEx6:setEnable(false)
            self.butEx7:setGray(true)
            self.butEx7:setEnable(false)
        end
        if context.guide:getStep().type ~= "exHero1" then
            self.butEx1:setGray(true)
            self.butEx1:setEnable(false)
        else
            self.butEx1:setGray(false)
            self.butEx1:setEnable(true)
        end
    end
    --钻石不足变成红色
    for _, clabel in ipairs(self.costLabels) do
        local ok = clabel[1]<=context:getRes(const.ResCrystal)
        if clabel[3]~=ok then
            clabel[3] = ok
            if ok then
                ui.setColor(clabel[2], GConst.Color.White)
            else
                ui.setColor(clabel[2], GConst.Color.Red)
            end
        end
    end
    if context.guide:getStep().type == "exHero1" then
        ui.setColor(self.costLabels[1][2], GConst.Color.White)
    end
end
--刷新幸运值
function HeroExtractNewTab:refreshLuck()
    local num = self:getContext():getProperty(const.ProLuck)
    local butShow = false
    if num>=100 then
        num = 100
        butShow = true
    end
    self.luckyEffect:setVisible(butShow)
    self.luckyProcess:setProcess(true, num/100)
    self.luckyLabel:setString(num .. "%")
end

function HeroExtractNewTab:onExtractMethod(rtype)
    local context = GameLogic.getUserContext()
    if rtype == 1 then
        if context:getProperty(const.ProFreeTime)>GameLogic.getSTime() then  --还在倒计时
            rtype = 2
        end
    end
    local cstate = ShowHeroMainDialog.checkExtractMethod(rtype, true)
    if cstate < 0 then
        return
    end
    if rtype == 1 or rtype == 2 then
        --免费单抽和付费单抽和抽奖券单抽
        local vip = context:getInfoItem(const.InfoVIPlv)
        local userLv = context:getInfoItem(const.InfoLevel)
        local ResCrystal = context:getProperty(const.ResCrystal)
        GameLogic.addStatLog(11202,vip,userLv,ResCrystal)
    elseif rtype == 3 then
        --十连抽
        local vip = context:getInfoItem(const.InfoVIPlv)
        local userLv = context:getInfoItem(const.InfoLevel)
        local ResCrystal = context:getProperty(const.ResCrystal)
        GameLogic.addStatLog(11203,vip,userLv,ResCrystal)
    end
    --引导
    if context.guide:getStep().type == "exHero1" then
        if GameNetwork.lockRequest() then
            self["butEx1"]:setGray(true)
            self["butEx2"]:setGray(true)
            ShowHeroMainDialog.inAnimate = true
            GameLogic.dumpCmds(true)
            GameNetwork.request("extract", {rtype=5,isHaveItem=true}, ShowHeroMainDialog.onExtractMethodOver, self)
        end
        if self.guideHand then
            self.guideHand:removeFromParent(true)
            self.guideHand=nil
        end
        return
    else
        local btnTab
        local resMax=context:getResMax(const.ResGold)
        local lsetting = SData.getData("hlsetting")
        if GameLogic.useTalentMatch then
            btnTab={self["butEx1"],self["butEx2"],self["butEx6"],self["butEx7"]}
        else
            btnTab = {self["butEx1"],self["butEx2"]}
        end
        if rtype == 3 then
            --我要变强引导remove
            GameLogic.removeJumpGuide(const.JumpTypeWish)
        end
        if rtype == 4 then
            display.showDialog(PrestigeDialog.new({params={callback=Handler(self.refreshInit, self),callback1=Handler(self.refreshBomb,self),callback2=Handler(self.refreshHot,self)}}))
        elseif rtype == 6 then
            local cost=math.floor(lsetting[6].cvalue*resMax/100)
            display.showDialog(AlertDialog.new(3,Localize("GoldExtractSingle"),Localizef("EnsureDesSinge",{a=cost}),{yesBut="btnYes", callback=function()
                if context:getRes(const.ResGold)<cost then
                    display.showDialog(AlertDialog.new({ctype=const.ResGold, cvalue=cost, callback=function ()
                        ShowHeroMainDialog.onExtractMethod(6,btnTab,self)
                    end}))
                else
                    ShowHeroMainDialog.onExtractMethod(6,btnTab,self)
                end
            end}))
        elseif rtype == 7 then
            local cost=math.floor(lsetting[7].cvalue*resMax/100)
            display.showDialog(AlertDialog.new(3,Localize("GoldExtractDozen"),Localizef("EnsureDesDozen",{a=cost}),{yesBut="btnYes", callback=function()
                if context:getRes(const.ResGold)<cost then
                    display.showDialog(AlertDialog.new({ctype=const.ResGold, cvalue=cost, callback=function ()
                        ShowHeroMainDialog.onExtractMethod(7,btnTab,self)
                    end}))
                else
                    ShowHeroMainDialog.onExtractMethod(7,btnTab,self)
                end
            end}))
        else 
            ShowHeroMainDialog.onExtractMethod(rtype, btnTab, self)
        end
    end
end

function HeroExtractNewTab:onExtractMethodOverBack(data)
    local context = GameLogic.getUserContext()
    local hnum = #data.heros
    --刷新暴击值
    if data.bomb then
        local crit = math.floor(data.bomb/10)+10
        self.critValue:setString(Localizef("critProbability",{num=crit}))
    end
    --刷新十连抽次数
    if data.rtype==4 then
        self.Game_hot_hero.Ten = self.Game_hot_hero.Ten+1
        context:setProperty(const.ProLTNum, self.Game_hot_hero.Ten)
        self:refreshMaxLTNum(data.heros)
        GameEvent.sendEvent("EventFreshMustGet")
    end
    if not self:getDialog().deleted then
        music.play("sounds/heroExt_music.wav")
        local params={heros=data,callback=Handler(self.refreshInit, self),callback1=Handler(self.refreshBomb,self),callFunc=Handler(self.guide,self),rtype=data.rtype}
        HeroExtractNewTabAction.new(params)
    end
end

--刷新界面
function HeroExtractNewTab:refreshInit( special )
    if self:getDialog().deleted then
        return
    end
    self["butEx1"]:setGray(false)
    self["butEx2"]:setGray(false)
    if self["butEx3"] then
        self["butEx3"]:setGray(false)
    end
    if self.butEx6 then
        self.butEx6:setGray(false)
        self.butEx7:setGray(false)
    end
    ShowHeroMainDialog.inAnimate = nil
    if special then
        self.getSpecial = special
    end
    --刷新单抽和十连抽的抽奖券数量
    self:refreshLuck()
    self:refreshHeros()
    -- local hxset = SData.getData("hlsetting", 4)
    -- if self.Game_hot_hero.Ten>=hxset.limit then
    --     --self.soulBox:setVisible(false)
    --     self["butEx3"]:setGray(false)
    -- else
    --     --self.soulBox:setVisible(true)
    --     self["butEx3"]:setGray(true)
    -- end
end
--回调刷新
function HeroExtractNewTab:refreshHot()
    if self.hotTemp then
        self.hotTemp:removeFromParent(true)
    end
    self.hotTemp = ShowHeroMainDialog.HotHero(self.hotNode,0,193,3)
    local crit = math.floor(self.Game_hot_hero.Crtical_strike/10)+10
    local vcrit = ui.label(Localizef("critProbability",{num=crit}), General.font1, 36)
    display.adapt(vcrit, 335, 280, GConst.Anchor.Center)
    self.hotTemp:addChild(vcrit)
    self.critValue = vcrit
end
--回调刷新暴击值和十连抽次数
function HeroExtractNewTab:refreshBomb(hero)
    if GameLogic.useTalentMatch then

    else
        self:refreshHot()
    end
    if hero.bomb then
        local crit = math.floor(hero.bomb/10)+10
        self.critValue:setString(Localizef("critProbability",{num=crit}))
    end
    if #hero.heros == 10 then
        self.Game_hot_hero.Ten = self.Game_hot_hero.Ten+1
        GameLogic.getUserContext():setProperty(const.ProLTNum, self.Game_hot_hero.Ten)
        self:refreshMaxLTNum(hero.heros)
        GameEvent.sendEvent("EventFreshMustGet")
    end
end

function HeroExtractNewTab:refreshMaxLTNum(heros)
    local maxRating = 1
    for k,v in ipairs(heros) do
        if not v[3] then
            local hero=GameLogic.getUserContext().heroData:getHero(v[1])
            if hero.info.rating==4 then
                if hero.info.displayColor == 5 then
                    maxRating = 5
                elseif maxRating < 5 then
                    maxRating = 4
                end
            end
        end
    end
    local curTimes=GameLogic.getUserContext():getProperty(const.ProLTNum)
    if maxRating == 5 then
        GameLogic.getUserContext():setProperty(const.ProLTUrCurNum, curTimes)
    elseif maxRating == 4 then
        GameLogic.getUserContext():setProperty(const.ProLTCurNum, curTimes)
    end
end

function HeroExtractNewTab:guide()
     --引导
    local context = GameLogic.getUserContext()
    local gtype = context.guide:getStep().type
    if gtype ~= "finish" and gtype ~= "extHero1" then
        local x,y = self:getDialog().closeBut:getPosition()
        local arrow = context.guideHand:showArrow(self:getDialog().view,x,y-70,100)
        arrow:setScaleY(-1)
    end
end
return HeroExtractNewTab
