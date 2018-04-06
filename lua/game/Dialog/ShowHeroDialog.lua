local SData = GMethod.loadScript("data.StaticData")
local const = GMethod.loadScript("game.GameLogic.Const")
local ShowHeroMainDialog = GMethod.loadScript("game.Dialog.ShowHeroMainDialog")
ShowHeroDialog = class(DialogViewLayout)

local _heroColorSettings2 = {-180,-32,0,131,131}
function ShowHeroDialog:onExit()
    if self.params.callFunc then
        self.params.callFunc()
    end
end
function ShowHeroDialog:canExit()
    if self.enterTime and socket.gettime()-self.enterTime > 1.5 then
        self.enterTime = nil
        local context = GameLogic.getUserContext()
        if context.guide:getStep().type == "exHero1" then
            context.guide:addStep()
        end
        return true
    end
end
function ShowHeroDialog:onInitDialog()
    self:setLayout("ShowHeroDialog.json")
    self:loadViewsTo()
    local function closeDialog()
       display.closeDialog(0)
    end
    self.dialogDepth=display.getDialogPri()+1
    self.closeBut:setScriptCallback(closeDialog)
    display.showDialog(self,false,true)
    self.iconTab = {}     --存放cell的表
    self.texiaoNode=nil      --特效
    self.heros = self.params.heros.heros
    self.callback1 = self.params.callback1

    local hnum = #self.heros
    for i=1, hnum do
        local j = math.random(1, hnum)
        self.heros[i], self.heros[j] = self.heros[j], self.heros[i]
    end
    self:refreshbomb(self.params.heros)

    self.againID = 0
    self.critbg.view:runAction(ui.action.arepeat({"rotateBy",5,360}))
    if #self.heros == 1 then
        --守护者召唤
        self.labeltitle:setString(Localize("temptitle1"))
        self.againID = 2
    elseif #self.heros == 10 then
        --王者召唤
        self.labeltitle:setString(Localize("temptitle2"))
        self.againID = 3
    elseif #self.heros == 6 then
        --神秘召唤
        self.labeltitle:setString(Localize("temptitle3"))
        self.againID = 4
    end
    if self.params.rtype == 6 then
        self.labeltitle:setString(Localize("temptitle4"))
        self.againID = 6
    elseif self.params.rtype == 7 then
        self.labeltitle:setString(Localize("temptitle4"))
        self.againID = 7
    end
    self:refreshPrice()
    self.btnagain:setScriptCallback(function()
        --新手引导
        local gtype = GameLogic.getUserContext().guide:getStep().type
        if gtype ~= "finish" and gtype == "exHero1" then
            display.pushNotice(Localize("stringPleaseGuideFirst"))
        else
            if not self.inAnimate then
                local btn={self.btnagain,self.btnleave}
                local chance
                if GameLogic.useTalentMatch then chance=GameLogic:getGoldExtractChance() end
                if self.againID == 6 or self.againID == 7 then
                    if (const.GoldExtractLimit-chance)>=10 then
                            
                    elseif  (const.GoldExtractLimit-chance)<10 and (const.GoldExtractLimit-chance)>0 then
                        if self.againID == 7 then
                            display.pushNotice(Localize("goldExtractChanceEmpty"))
                            return 
                        end
                    else
                        display.pushNotice(Localize("goldExtractChanceEmpty"))
                        return 
                    end
                end
                local hlsetting = SData.getData("hlsetting", self.againID)
                local cost=math.floor(hlsetting.cvalue*GameLogic.getUserContext():getResMax(const.ResGold)/100)
                if self.againID==6 or self.againID==7 then
                    if GameLogic.getUserContext():getRes(const.ResGold)<cost then
                        display.showDialog(AlertDialog.new({ctype=const.ResGold, cvalue=cost, callback=function ()
                            ShowHeroMainDialog.onExtractMethod(self.againID,btn,self)
                        end}))
                    else
                        ShowHeroMainDialog.onExtractMethod(self.againID,btn,self)
                    end
                    return
                end
                if ShowHeroMainDialog.checkExtractMethod(self.againID) == ShowHeroMainDialog.RESULT_ERROR then
                    return
                end
                self.inAnimate = true
                local hlsetting = SData.getData("hlsetting", self.againID)
                local cost=math.floor(hlsetting.cvalue*GameLogic.getUserContext():getResMax(const.ResGold)/100)
                ShowHeroMainDialog.onExtractMethod(self.againID, btn, self)
            end
        end
    end)
    --前往
    self.btnleave:setScriptCallback(function()
        if not self.inAnimate then
            display.closeDialog(0)
        end
    end)

    self.callback = self.params.callback

    self:playAction()
    local function inithero( ... )
        self:initHeroIcon()
    end
    self.getSpecial = nil
    self.view:runAction(ui.action.sequence({{"delay",0.35},{"call",inithero}}))
end

function ShowHeroDialog:refreshPrice()
    local context = self.context
    local temp
    local resType, resId, resValue
    if self.againID == 2 and context:getItem(const.ItemTicket, const.TicketOne) >= const.OneRaffleTicket then
        resType = const.ItemTicket
        resId = const.TicketOne
        resValue = const.OneRaffleTicket
    elseif self.againID == 3 and context:getItem(const.ItemTicket, const.TicketTen) >= const.TenRaffleTicket then
        resType = const.ItemTicket
        resId = const.TicketTen
        resValue = const.TenRaffleTicket
    else
        local hlsetting = SData.getData("hlsetting", self.againID)
        resType = const.ItemRes
        if self.againID == 6 or self.againID == 7 then
            resId = const.ResGold
            resValue = math.floor(hlsetting.cvalue*context:getResMax(const.ResGold)/100)
        else 
            resId = const.ResCrystal
            resValue = hlsetting.cvalue
        end
        if self.againID == 3 then
            local discount=GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWishDiscount)[4]
            if discount~=0 and  discount ~=1 then
                resValue=resValue*discount
            end
        end
    end
    if resType ~= self._displayCostType or resId ~= self._displayCostId then
        self._displayCostType = resType
        self._displayCostId = resId
        if self.costIcon then
            self.costIcon:removeFromParent()
            self.costIcon = nil
        end
        self.costIcon = GameUI.addItemIcon(self.view, resType, resId, 0.75, 1050, 210)
    end
    if not self.price then
        self.price = ui.label(" ", General.font1, 60)
        display.adapt(self.price, 970, 210, GConst.Anchor.Right)
        self.view:addChild(self.price)
    end
   
    self.price:setString(tostring(resValue))
    if resValue > GameLogic.getItemNum(resType, resId) then
        ui.setColor(self.price, GConst.Color.Red)
    else
        ui.setColor(self.price, GConst.Color.White)
    end
end

function ShowHeroDialog:refreshbomb( data )
    if data.bomb then
        self.critValue = data.bomb
        self.isCrit = data.isBomb
    end
end
function ShowHeroDialog:initHeroIcon( ... )
    local i = 0
    local context=GameLogic.getUserContext()
    if self.texiaoNode then
        self.texiaoNode:removeFromParent(true)
    end
    if self.isCrit==1 and #self.heros==6 then
        self.secondtitle:setVisible(true)
        self.baojilv:setVisible(false)
        self.baojizhi:setVisible(false)
        context:setProperty(const.ProLTBoxRate, self.critValue)
        self.texiaoNode = ui.csbNode("UICsb/f_1.csb")
        display.adapt(self.texiaoNode,1801,738,GConst.Anchor.Center)
        self.view:addChild(self.texiaoNode)
        local temp = ui.label(Localize("bomb"), General.font1, 60,{fontW=133,fontH=60,color={250,130,10}})
        display.adapt(temp, 25, 25, GConst.Anchor.Center)
        self.texiaoNode:getChildByName("Baozha01_4"):addChild(temp)
        local action = ui.csbTimeLine("UICsb/f_1.csb")
        self.texiaoNode:runAction(action)
        action:gotoFrameAndPlay(0,false)
    elseif self.isCrit==0 and #self.heros== 6 then
        self.secondtitle:setVisible(false)
        self.baojilv:setVisible(true)
        self.baojizhi:setVisible(true)
        self.baojilv:setString(Localize("bombValue"))
        -- 这里要改成当前暴击率
        local vcrit = math.floor(context:getProperty(const.ProLTBoxRate)/10)+10
        self.baojizhi:setString(vcrit.."%")
    end
    local cell,temp,rhero
    local heros = self.heros
    local function showHero()
        i=i+1
        local context = GameLogic.getUserContext()
        if i>#heros then
            if self.isCrit==0 and #self.heros==6 then
                context:setProperty(const.ProLTBoxRate, self.critValue)
                local crit = math.floor(self.critValue/10)+10
                self.baojizhi:setString(tostring(crit).."%")
                self.texiaoNode = ui.csbNode("UICsb/f_0.csb")
                display.adapt(self.texiaoNode,1801,738,GConst.Anchor.Center)
                self.view:addChild(self.texiaoNode)
                local action = ui.csbTimeLine("UICsb/f_0.csb")
                self.texiaoNode:runAction(action)
                action:gotoFrameAndPlay(0,false)
            end
            self.inAnimate = nil
            self.btnagain:setGray(false)
            self.btnleave:setGray(false)
            --引导
            local gtype = context.guide:getStep().type
            if gtype ~= "finish" and gtype == "exHero1" then
                local x,y =  self.closeBut.view:getPosition()
                local arrow = context.guideHand:showArrow(self.view,x,y-70,100)
                arrow:setScaleY(-1)
            end
            return
        end
        local x,y
        -------------------------------
        if #heros == 6 then
            x = ((i-1)%3)*284+900
            y = 1312-math.ceil(i/3)*358
            self.critbg:setVisible(true)
        elseif #heros == 10 then
            x = ((i-1)%5)*264+780
            --为新服的保底文字显示腾出位置
            if GameLogic.useTalentMatch then
                y = 1212-math.ceil(i/5)*358
            else
                y = 1312-math.ceil(i/5)*358
            end
            self.baoji:setVisible(false)
            self.baojilv:setVisible(false)
            self.baojizhi:setVisible(false)
        elseif #heros == 1 then
            x = 1280
            y = 768
            self.baoji:setVisible(false)
            self.baojilv:setVisible(false)
            self.baojizhi:setVisible(false)
        end
        -------------------------------
        local hero=heros[i]
        local hdata = context.heroData
        cell = ui.node({242, 240}, true)
        display.adapt(cell, x, y, GConst.Anchor.Center)
        self.view:addChild(cell)
        cell:setScale(0.8)
        self.iconTab[#self.iconTab+1] = cell
        temp = ui.sprite("images/dialogItemExtractCell.png",{242, 240})
        display.adapt(temp, 0, 0)
        cell:addChild(temp)
        if hero[1] == const.ItemHero and hero[3] then
            hero[1],hero[2],hero[3]=hero[3],hero[2],nil
        end
        if hero[3] then
            rhero={}
            rhero.info={color=2}
            if hero[1] == const.ItemEquip then
                rhero = context.equipData:makeEquip(hero[2])
                rhero.info = {color=4,rating=4}
                rhero.hid = rhero.eid
                rhero.rtype = const.ItemEquip
                GameUI.addItemIcon(cell,hero[1],hero[2],240/200,120,120,true,false)
            else
                GameUI.addItemIcon(cell,hero[1],hero[2],240/200,120,120,true,false,{itemNum=hero[3]})
            end
        else
            rhero = hdata:getHero(hero[1])
            rhero.rtype = const.ItemHero
            GameUI.addHeroFeature(cell, rhero.hid, 0.28, 121, 120, 2, true)
        end
        temp:setHValue(_heroColorSettings2[rhero.info.color])
        -- 十连抽添加SSR
        local rating = rhero.info.rating
        if rhero.info.displayColor then
            rating=rhero.info.displayColor
        end
        if rhero.rtype == const.ItemHero and rating and rating >= 2 then
            GameUI.addSSR(cell,rating,0.3,150,190,3)
        end
        local heroColor=nil
        if rhero.info.color<=2 then    --N 蓝和绿
            heroColor=2
        elseif rhero.info.color==3 then   --SR 紫色
            heroColor=1
        elseif rhero.info.color==4 or rhero.info.color==5 then  --SSR SR R
            heroColor=3
        end
        if heroColor then
            UIeffectsManage:showEffect_ShiLianChou(heroColor,cell,121,120,3)
        end
        local fontSize = 50
        if rhero.info.color==4 then
            temp = ui.sprite("images/heroColor4Light.png",{264, 262})
            display.adapt(temp, 121, 120, GConst.Anchor.Center)
            cell:addChild(temp,1)
            fontSize = 60
        end
        if hero[3] then
            temp = ui.label(GameLogic.getItemName(hero[1],hero[2]), General.font1, fontSize,{fontW=320,fontH=100})
        else
            temp = ui.label(rhero:getName(), General.font1, fontSize,{fontW=320,fontH=100})
            GameUI.setHeroNameColor(temp, rhero.info.displayColor or rhero.info.color)
        end
        display.adapt(temp, 121, -7, GConst.Anchor.Top)
        cell:addChild(temp)
        --这里判断装备特效 or rhero.info.type==1
        --新服旧服进行区分
        local show
        if GameLogic.useTalentMatch then
            show=rhero.info.color>=2
        else
            show=rhero.info.color==4
        end
        if  show and rhero.info.rating and rhero.info.rating>2 then
            local function closeFeatrue()
                GameLogic.doRateGuide("extract", rhero.hid, showHero)
            end
            local shareIdx = nil
            if rhero.rtype == const.ItemEquip then
                if rhero.hid >= 2005 then
                    shareIdx = 5
                end
            elseif rhero.info.rating == 3 then
                shareIdx = 3
            elseif rhero.info.rating == 4 then
                shareIdx = 4
                local curTimes=context:getProperty(const.ProLTNum)
                local value=(curTimes - context:getProperty(const.ProLTCurNum))
                if value > 9 then
                    value = 9
                end
                local valueUr=(curTimes - context:getProperty(const.ProLTUrCurNum))%50
                if GameLogic.useTalentMatch then
                    self.SSRGet:setString(Localizef("canGetSSR",{a = (10-value),b=(50-valueUr)}))
                end
            end
            NewShowHeroDialog.new({rhero=rhero,callfunc=closeFeatrue,rtype = rhero.rtype or nil, shareIdx=shareIdx})
            music.play("sounds/heroExtract.mp3")
        else
            cell:runAction(ui.action.sequence({{"delay",0.35},{"call",showHero}}))
        end
    end

    if self.callback then
        self.callback(self.getSpecial)
    end
    showHero()
    if GameLogic.useTalentMatch and self.againID==3 then
        local value=(context:getProperty(const.ProLTNum)-context:getProperty(const.ProLTCurNum))%10
        local valueUr=(context:getProperty(const.ProLTNum)-context:getProperty(const.ProLTUrCurNum))%50
        self.SSRGet:setVisible(true)
        self.SSRGet:setString(Localizef("canGetSSR",{a = (10-value),b=(50-valueUr)}))--"再抽"..(15-value).."次 必得SSR")-- Localizef("canGetSSR",{a = nlv})
    end
end
function ShowHeroDialog:onEnter( ... )
    --火焰粒子
    local node = ui.csbNode("UICsb/e_0.csb")
    display.adapt(node,1024,768,GConst.Anchor.Center)
    self.view:addChild(node)
    self.secondtitle:setString(Localize("secondtitle"))
    self.secondtitle:setVisible(false)
    self.again:setString(Localize("exCardAgain"))
    self.leave:setString(Localize("leaveCard"))
    self.inAnimate=true
    self.btnagain:setGray(true)
    self.btnleave:setGray(true)
    self.baoji:setVisible(false)
    self.baojilv:setVisible(false)
    self.baojizhi:setVisible(false)
    self.critbg:setVisible(false)
    self.enterTime = socket.gettime()
end
function ShowHeroDialog:playAction( ... )
    local node,action
    local csbTab = {
      [10] = {"UICsb/c_1.csb","UICsb/c_2.csb"},
      [1] = {"UICsb/b_1.csb","UICsb/b_2.csb"},
      [6] = {"UICsb/a_1.csb","UICsb/a_2.csb"},
    }
    node = ui.csbNode(csbTab[#self.heros][1])
    display.adapt(node,400,768,GConst.Anchor.Center)
    self.view:addChild(node)
    action = ui.csbTimeLine(csbTab[#self.heros][1])
    node:runAction(action)
    action:gotoFrameAndPlay(0,false)
    action:setFrameEventCallFunc(function(frame)
        if frame:getEvent() == "showCard" then
            node = ui.csbNode(csbTab[#self.heros][2])
            display.adapt(node,400,750,GConst.Anchor.Center)
            local kapai
            if self.againID == 6 or self.againID == 7 then
                ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),-5,10,4)
            elseif #self.heros == 1 then
                ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),-5,10,1)
            elseif #self.heros == 10 then
                ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),0,10,2)
            elseif #self.heros == 6 then
                ShowHeroMainDialog.HotHero(node:getChildByName("KaPian01_2"),72-51,0,3)
            end
            self.view:addChild(node)
            action = ui.csbTimeLine(csbTab[#self.heros][2])
            node:runAction(action)
            action:gotoFrameAndPlay(0,false)
        end
    end)
end
function ShowHeroDialog:onExtractMethodOverBack(data)
    for i=1,#self.iconTab do
      self.iconTab[i]:removeFromParent(true)
    end
    self.iconTab = {}
    local hnum = #data.heros
    for i=1, hnum do
        local j = math.random(1, hnum)
        data.heros[i], data.heros[j] = data.heros[j], data.heros[i]
    end
    self.heros = data.heros
    self.callback1(data)
    self:refreshbomb(data)
    self:initHeroIcon()
    self:refreshPrice()
end
