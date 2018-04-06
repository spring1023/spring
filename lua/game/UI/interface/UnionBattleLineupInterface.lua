
local const = GMethod.loadScript("game.GameLogic.Const")
--联盟战斗布阵界面
local UnionBattleLineupInterface = class2("UnionBattleLineupInterface",function()
    return BaseView.new("UnionBattleLineupInterface.json")
end)

local function _sendMsg()
    local ug = {unionArray = true,lv = GameLogic.getUserContext():getInfoItem(const.InfoLevel),headIcon=GameLogic.getUserContext():getInfoItem(const.InfoHead)}
    local cid = GameLogic.getUserContext().union and GameLogic.getUserContext().union.id
    local msg = {uid=GameLogic.getUserContext().uid,cid=cid,text="1234",name=GameLogic.getUserContext():getInfoItem(const.InfoName),
            ug=json.encode(ug),mtype=1}
    local scene = GMethod.loadScript("game.View.Scene")
    scene.menu.chatRoom:send(msg)
end

function UnionBattleLineupInterface:ctor(data)
    local scrollNode = ui.scrollNode(display.winSize, 0, true, true, {scroll=true, inertia=true, clip=true})
    self:addChild(scrollNode)
    self.scroll = scrollNode
    local sizeX,sizeY = display.winSize[1],display.winSize[2]
    local smin = 1
    local smax = 2
    ui.setRectAndScale(self.scroll, {0,0,sizeX,sizeY}, {smin, smax, smin, smax})
    self.scroll:moveAndScaleToCenter(smin, sizeX/2, sizeY/2,0.5)
    self.base = scrollNode:getScrollNode()
    self.priority = display.getDialogPri() + 1
    --self:getDataOver(true,data)
    if data.isTruce then
        --休战时间
        self.isTruce = true
        self.state = 2
        self:intopvllayout()
    else
        self.state = 3
        self.battleData = data
        self:initBattleData(data)
    end

    display.showDialog(self,true,true)
end
function UnionBattleLineupInterface:initNode()
    local bg,temp
    if self.TopNode then
        self.TopNode:removeAllChildren(true)
    else
        bg=ui.node()
        display.adapt(bg, 0, 0, GConst.Anchor.Top, {datum = GConst.Anchor.Top,scale=ui.getUIScale2()})
        self:addChild(bg,1)

        temp=ui.node()
        display.adapt(temp, -1024, -1536, GConst.Anchor.Top)
        bg:addChild(temp)
        self.TopNode=temp
    end
    if self.RightTopNode then
        self.RightTopNode:removeAllChildren(true)
    else
        temp=ui.node()
        display.adapt(temp, -1024, -1536, GConst.Anchor.Top)
        bg:addChild(temp)
        self.TopNode2=temp

        bg=ui.node()
        display.adapt(bg, 0, 0, GConst.Anchor.RightTop, {datum = GConst.Anchor.RightTop,scale=ui.getUIScale2()})
        self:addChild(bg,1)
        temp=ui.node()
        display.adapt(temp, -2048, -1536, GConst.Anchor.RightTop)
        bg:addChild(temp)
        self.RightTopNode=temp
    end
    if self.LeftBottomNode and self.LeftBottomNode3 then
        self.LeftBottomNode:removeAllChildren(true)
        self.LeftBottomNode3:removeAllChildren(true)
    else
        bg=ui.node()
        local scalePolicy = display.getScalePolicy(2732,1536)
        display.adapt(bg, 0, 0, GConst.Anchor.LeftBottom, {datum = GConst.Anchor.Bottom,scale=scalePolicy[GConst.Scale.Big]})
        self.base:addChild(bg)
        temp=ui.node()
        display.adapt(temp, -1024, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        self.LeftBottomNode=temp
        temp=ui.node()
        display.adapt(temp, -1024, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        self.LeftBottomNode3=temp
    end
    if self.LeftBottomNode2 then
        self.LeftBottomNode2:removeAllChildren(true)
    else
        bg=ui.node()
        display.adapt(bg, 0, 0, GConst.Anchor.LeftBottom, {datum = GConst.Anchor.LeftBottom,scale=ui.getUIScale2()})
        self:addChild(bg,2)
        temp=ui.node()
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp,1)
        self.LeftBottomNode2=temp
    end
    if self.RightBottomNode then
        self.RightBottomNode:removeAllChildren(true)
    else
        bg=ui.node()
        display.adapt(bg, 0, 0, GConst.Anchor.RightBottom, {datum = GConst.Anchor.RightBottom,scale=ui.getUIScale2()})
        self:addChild(bg,1)
        temp=ui.node()
        display.adapt(temp, -2048, 0, GConst.Anchor.RightBottom)
        bg:addChild(temp)
        self.RightBottomNode=temp
    end
    if self.RightNode then
        self.RightNode:removeAllChildren(true)
    else
        bg=ui.node()
        display.adapt(bg, 0, 0, GConst.Anchor.RightBottom, {datum = GConst.Anchor.Right,scale=ui.getUIScale2()})
        self:addChild(bg,1)
        temp=ui.node()
        display.adapt(temp, 0, 0, GConst.Anchor.RightBottom)
        bg:addChild(temp)
        self.RightNode=temp
    end
    if self.LeftTopNode then
        self.LeftTopNode:removeAllChildren(true)
    else
        bg=ui.node()
        display.adapt(bg, 0, 0, GConst.Anchor.RightBottom, {datum = GConst.Anchor.LeftTop,scale=ui.getUIScale2()})
        self:addChild(bg,1)
        temp=ui.node()
        display.adapt(temp, 0, 0, GConst.Anchor.RightBottom)
        bg:addChild(temp)
        self.LeftTopNode=temp
    end
    self:setNilNode()
end
function UnionBattleLineupInterface:setNilNode()
    self.closeNode = nil
    self.choseState=nil
    self.clickCityNode = nil
    self.setNode = nil
end
function UnionBattleLineupInterface:initUI()

    if not self.addUpdate then
        RegActionUpdate(self, Handler(self.update, self, 0.25), 0.25)
        self.addUpdate = true
    end

    self:initNode()
    self:loadView("topViews",self.TopNode)
    self:insertViewTo()
    local unionInfos = self.unionInfos
    --联盟名字，联盟旗帜
    self.leagueNameMy:setString(unionInfos.name1)
    --本方旗帜
    local temp = GameUI.addUnionFlag(unionInfos.flag1)
    self.TopNode:addChild(temp)
    temp:setScale(0.64)
    temp:setPosition(450+76,1327+80)
    local flag1 = temp

    if self.state==3 then
        self.leagueNameHe:setString(unionInfos.name2)
        --敌方旗帜
        temp = GameUI.addUnionFlag(unionInfos.flag2)
        self.TopNode:addChild(temp)
        temp:setScale(0.64)
        temp:setPosition(1422+76,1327+80)
    else
        self.leagueNameHe:setVisible(false)
        flag1:setPositionX(1010)
        self.leagueNameMy:setPositionX(1010)
        self.iconVS:setVisible(false)
    end

    --当前阵营标志,战斗状态
    self.nowFlag = nil
    if self.state == 3 then
        local temp = ui.sprite("images/nowFlag.png")
        display.adapt(temp,450+180,1327,GConst.Anchor.LeftBottom)
        self.TopNode:addChild(temp)
        self.nowFlag = temp
    end
    self:loadView("rightTopViews",self.RightTopNode)
    self.viewTab=self:getViewTab()
    local function removeSelf()
        display.closeDialog(self.priority)
    end
    self.viewTab.butClose:setScriptCallback(Script.createCallbackHandler(removeSelf))
    self.viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))
    self:initMapViews()
    self:showStateViews()
end
function UnionBattleLineupInterface:onQuestion()
    local key = "dataQuestionUnBatLine2"
    if self.state==2 then
        key="dataQuestionUnBatLine"
    end
    HelpDialog.new(key)
end
function UnionBattleLineupInterface:setDialogCallcell(cell, tableView, info)
    local data = info.data
    local id = info.butid
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    self:loadView("setDialogInfoViews",bg)

    self:insertViewTo()
    --序号
    self.label_idx:setString(info.id)
    --等级
    self.label_lv:setString(data.lv)
    --名字
    self.label_name:setString(data.name)
    --职位
    self.label_job:setString(SG("labelCellJob"..data.job))
    self.butArr[id] = {self.viewTab.butPlace,self.btnInsertTo,data}
    if data.pos>0 then
        self.viewTab.butPlace:setHValue(-81)
        self.viewTab.butPlace:setSValue(10)
        self.btnInsertTo:setString(SG("btnRevoke"))
    end

    local function checkKeepState()
        local num = self.knum
        if num > 30 then
            num = 30
        end
        for i,v in ipairs(self.battlePlays) do
            if v.pos>0 then
                num = num-1
            end
        end
        if num <= 0 then
            self.butKeep:setGray(false)
        else
            self.butKeep:setGray(true)
        end
    end

    self.butPlace:setListener(function()
        if data.pos>0 then
            print("撤销")
            self.itemLv[self.nowItemIdx]:setString("")
            self.itemName[self.nowItemIdx]:setString("")

            data.pos = 0
            self.butArr[id][1]:setHValue(0)
            self.butArr[id][1]:setSValue(0)
            self.butArr[id][2]:setString(SG("btnInsertTo"))
            checkKeepState()
        else
            print("置入")
            for i,v in pairs(self.butArr) do
                self.butArr[i][1]:setHValue(0)
                self.butArr[i][1]:setSValue(0)
                self.butArr[i][2]:setString(SG("btnInsertTo"))
                self.butArr[i][3].pos = 0
            end

            data.pos = self.nowItemIdx
            self.itemLv[self.nowItemIdx]:setString("Lv"..data.lv)
            self.itemName[self.nowItemIdx]:setString(data.name)

            self.butArr[id][1]:setHValue(-81)
            self.butArr[id][1]:setSValue(10)
            self.butArr[id][2]:setString(SG("btnRevoke"))
            checkKeepState()
        end
    end)

    self.butSeeInfo:setListener(function()
        GameEvent.sendEvent(GameEvent.EventVisitBegin,{type = const.VisitTypeUn, uid = data.uid, inBattle=true})
    end)
end

function UnionBattleLineupInterface:clickCity(i,pos)
    --当前选中的营地
    self.nowItemIdx = i
    if self.choseState then
        self.choseState:removeFromParent(true)
        self.choseState=nil
    end
    local choseState = ui.sprite("images/pvePoint.png", {96, 60})
    display.adapt(choseState, pos[1], pos[2]-15, GConst.Anchor.Center)
    self.LeftBottomNode:addChild(choseState)
    self.choseState=choseState
    if i==1 then
        choseState:setPosition(pos[1], pos[2]-32)
        choseState:setScale(1.2)
    end

    if self.closeNode then
        self.closeNode:removeFromParent(true)
        self.closeNode = nil
    end

    if self.clickCityNode then
        self.clickCityNode:removeFromParent(true)
        self.clickCityNode = nil
    end
    if self.setNode then
        self.setNode:removeFromParent(true)
        self.setNode = nil
    end

    self.closeNode = ui.button({display.winSize[1]/ui.getUIScale2(),display.winSize[2]/ui.getUIScale2()},nil,{})
    self.LeftBottomNode3:addChild(self.closeNode)

    self.clickCityNode=ui.node()
    display.adapt(self.clickCityNode, pos[1], pos[2], GConst.Anchor.Center)
    self.LeftBottomNode3:addChild(self.clickCityNode)
    local bg=self.clickCityNode
    self.setNode = ui.node()
    display.adapt(self.setNode, 0, 0, GConst.Anchor.LeftBottom)
    self.RightNode:addChild(self.setNode)

    self.closeNode:setListener(function()
        self.closeNode:removeFromParent(true)
        self.closeNode = nil

        self.choseState:removeFromParent(true)
        self.choseState=nil

        self.clickCityNode:removeFromParent(true)
        self.clickCityNode = nil

        self.setNode:removeFromParent(true)
        self.setNode = nil
    end)
    self.closeNode:setTouchThrowProperty(true, true)


    local temp
    local oy=116
    if i==1 then
        oy=136
    end

    if self.state==2 then
        local setNode=ui.node()
        display.adapt(setNode, 0, 0, GConst.Anchor.LeftBottom)
        self.setNode:addChild(setNode)
        setNode:removeAllChildren(true)
        local setDialogNode=ui.touchNode({766,588}, -1, true)
        setDialogNode:setScale(1.2)
        display.adapt(setDialogNode, -20,0, GConst.Anchor.Right)
        setNode:addChild(setDialogNode)
        self:loadView("setDialogViews",setDialogNode)

        local plays = self.battlePlays
        local infos={}
        self.butArr = {}

        local idx = 0
        for i=1,#plays do
            if plays[i].pos == 0 or plays[i].pos == self.nowItemIdx then
                idx = idx+1
                infos[idx]={id=idx,data = plays[i],butid = i}
            end
        end

        self:addTableViewProperty("setDialogTableview",infos,Script.createBasicHandler(self.setDialogCallcell,self))
        self:loadView("setDialogTableview",setDialogNode)
        local function removeSetNode()
            self.setNode:removeFromParent(true)
            self.setNode = nil

            self.closeNode:removeFromParent(true)
            self.closeNode = nil

            self.choseState:removeFromParent(true)
            self.choseState=nil

            self.clickCityNode:removeFromParent(true)
            self.clickCityNode = nil
        end
        self.viewTab.butClose2:setScriptCallback(Script.createCallbackHandler(removeSetNode))
    elseif self.state==3 then
        --未置入
        if not self.battleArr[self.nowItemIdx] then
            return
        end
        local spyNode=ui.node()
        display.adapt(spyNode, 80, oy-256, GConst.Anchor.Center)
        bg:addChild(spyNode)
        if pos[1]>1024 then
            spyNode:setPosition(-576, oy-256)
        end
        spyNode:removeAllChildren(true)
        self:loadView("spyViews",spyNode)
        self:insertViewTo()
        local idx = self.nowItemIdx
        local b = self.battleArr[idx]
        self.label_castle:setString(self:getCityName(idx))
        self.label_defendName:setString(SG("label_defenddajiang")..b.name)
        self.label_surplusHp:setString(SG("label_hpshengyu").. b.hp/100 .."%")

        local config = const.UnionPvlData[i]
        local str1 = Localizef("stringUnionAddDes1",{a = config[1],b = config[2],c = config[3]})
        local str2 = ""
        if i == 1 then
            str2 = Localizef("stringUnionAddDes2",{a = config[4]})
        elseif 1<i and i<=5 then
            str2 = Localizef("stringUnionAddDes3",{a = config[4]})
        end
        self.lookPlayString:setString(str1..str2)


        if self.isMy then
            local butSpy=ui.button({144,57},nil,{image="images/btnGreen.png",priority=-1})
            display.adapt(butSpy, 0, oy-34, GConst.Anchor.Center)
            bg:addChild(butSpy)
            butSpy:setListener(function()
                local uid = self.battleArr[self.nowItemIdx].uid
                local unionId = self.battleArr[self.nowItemIdx].unionId
                GameEvent.sendEvent(GameEvent.EventVisitBegin,{type = const.VisitTypeUn, uid = uid, cid=unionId, inBattle=true})
            end)

            temp = ui.label(StringManager.getString("btnlooklook"), General.font1, 24, {color={255,255,255}})
            display.adapt(temp, 72, 32, GConst.Anchor.Center)
            butSpy:getDrawNode():addChild(temp)
        else
            local butSpy=ui.button({144,57},nil,{image="images/btnGreen.png",priority=-1})
            display.adapt(butSpy, 0, oy+34, GConst.Anchor.Center)
            bg:addChild(butSpy)
            butSpy:setListener(function()
                local uid = self.battleArr[self.nowItemIdx].uid
                local unionId = self.battleArr[self.nowItemIdx].unionId
                local atknum =self.atknum
                local haveSatrtBattleData={}
                --检测已死亡数量
                local deathNum = 0
                for i,v in ipairs(self.battleArr) do
                    if v.hp==0 then
                        deathNum=deathNum+1
                    end
                end
                haveSatrtBattleData.jionTime = self.jionTime
                haveSatrtBattleData.atknum = atknum
                haveSatrtBattleData.deathNum=deathNum
                haveSatrtBattleData.nowItemIdx=self.nowItemIdx
                haveSatrtBattleData.uid = uid
                haveSatrtBattleData.unionId = unionId
                haveSatrtBattleData.addlv=self.addlv
                local destroyDebuffs={atk=0,hp=0}
                for i,v in ipairs(self.battlePlays2) do
                    if v.pos == 1 and v.hp == 0 then
                        destroyDebuffs.atk = const.UnionPvlData[v.pos][4]
                    elseif 2<=v.pos and v.pos<=5 and v.hp == 0 then
                        destroyDebuffs.hp = const.UnionPvlData[v.pos][4]
                    end
                end
                haveSatrtBattleData.destroyDebuffs = destroyDebuffs
                GameEvent.sendEvent(GameEvent.EventVisitBegin,{type = const.VisitTypeUn, uid = uid, cid = unionId,haveSatrtBattleData=haveSatrtBattleData, inBattle=true})
            end)

            temp = ui.label(StringManager.getString("btnlooklook"), General.font1, 24, {color={255,255,255}})
            display.adapt(temp, 72, 32, GConst.Anchor.Center)
            butSpy:getDrawNode():addChild(temp)

            local butCrusade=ui.button({144,57},nil,{image="images/btnGreen.png",priority=-1})
            display.adapt(butCrusade, 0, oy-34, GConst.Anchor.Center)
            bg:addChild(butCrusade)
            temp = ui.label(StringManager.getString("btnPvhAttack"), General.font1, 24, {color={255,255,255}, fontW = 140, fontH = 36})
            display.adapt(temp, 72, 32, GConst.Anchor.Center)
            butCrusade:getDrawNode():addChild(temp)
            butCrusade:setListener(function()
                --入盟时间不足一天
                if GameLogic.getToday()<self.jionTime then
                    display.pushNotice(Localize("noiceTimeNotEnough"))
                else
                    print("讨伐")
                    self:beginpvlatk()
                end
            end)

            butCrusade:setVisible(false)
            --是否在战斗阵型上
            -- local sign = false
            -- for i,v in ipairs(self.battlePlays1) do
            --     if v.uid == GameLogic.getUserContext().uid then
            --         sign = true
            --     end
            -- end

            local sign = true
            if sign then
                butCrusade:setVisible(true)
                if GameLogic.getToday()<self.jionTime then
                    butCrusade:setGray(true)
                end
            else
                butSpy:setPosition(0, oy-34)
            end
        end

    end
end

function UnionBattleLineupInterface:initMapViews()
    self.LeftBottomNode:removeAllChildren(true)
    if self.state == 2 then--布阵
        self:initMapViews2()
    elseif self.state == 3 then--战斗中
        self:initMapViews3()
    end
end

function UnionBattleLineupInterface:getCityName(idx)
    if idx==1 then
        return Localize("label_castle"..1)
    elseif idx<=5 then
        return Localize("label_castle"..2)
    elseif idx<=10 then
        return Localize("label_castle"..3)
    elseif idx<=20 then
        return Localize("label_castle"..4)
    elseif idx<=30 then
        return Localize("label_castle"..5)
    end
end
function UnionBattleLineupInterface:initMapViews2()
    self:loadView("lineupMapViews",self.LeftBottomNode)
    local cityPos=self:readConfig("cityPos")
    self.itemLv = {}
    self.itemName = {}

    for i,pos in ipairs(cityPos) do
        local butCity,temp
        if i==1 then
            butCity=ui.button({116,116},nil,{image="images/UnionBattleIconBoss.png"})
        elseif i<=5 then
            butCity=ui.button({87,76},nil,{image="images/UnionBattleIconCityRed.png"})
        elseif i<=10 then
            butCity=ui.button({87,76},nil,{image="images/UnionBattleIconCityPurple.png"})
        elseif i<=20 then
            butCity=ui.button({87,76},nil,{image="images/UnionBattleIconCityBlue.png"})
        elseif i<=30 then
            butCity=ui.button({87,76},nil,{image="images/UnionBattleIconCityGreen.png"})
        end

        display.adapt(butCity, pos[1],  pos[2], GConst.Anchor.Center)
        self.LeftBottomNode:addChild(butCity,2+1536-pos[2])
        butCity:setTouchThrowProperty(true, true)

        if i > self.knum then
            butCity:setGray(true)
            butCity:setEnable(false)
        end

        local size1,size2=15,18
        local ox,oy,oyy=43,64,22
        if i==1 then
            size1,size2=19,23
            ox,oy,oyy=58,84,40
        end

        --等级
        temp = ui.label("", General.font1, size1, {color={255,255,255}})
        display.adapt(temp, ox, oy, GConst.Anchor.Center)
        butCity:getDrawNode():addChild(temp)
        self.itemLv[i] = temp
        --玩家名字
        temp = ui.label("", General.font5, size2, {color={255,255,255}})
        display.adapt(temp, ox, oy+oyy, GConst.Anchor.Center)
        butCity:getDrawNode():addChild(temp)
        self.itemName[i] = temp

        for j,v in ipairs(self.battlePlays) do
            if i==v.pos then
                self.itemLv[i]:setString("Lv"..v.lv)
                self.itemName[i]:setString(v.name)
            end
        end

        local function callClickCity()
            self:clickCity(i,pos)
        end
        butCity:setScriptCallback(Script.createCallbackHandler(callClickCity))
    end
end

function UnionBattleLineupInterface:initMapViews3()
    self:loadView("lineupMapViews",self.LeftBottomNode)
    local cityPos=self:readConfig("cityPos")
    local plays = self.battlePlays2
    if self.isMy then
        plays = self.battlePlays1
    end
    self.battleArr = plays
    for i,pos in ipairs(cityPos) do
        local butCity,temp
        local w = 43
        if i==1 then
            w = 58
            butCity=ui.button({116,116},nil,{image="images/UnionBattleIconBoss.png"})
        elseif i<=5 then
            butCity=ui.button({87,76},nil,{image="images/UnionBattleIconCityRed.png"})
        elseif i<=10 then
            butCity=ui.button({87,76},nil,{image="images/UnionBattleIconCityPurple.png"})
        elseif i<=20 then
            butCity=ui.button({87,76},nil,{image="images/UnionBattleIconCityBlue.png"})
        elseif i<=30 then
            butCity=ui.button({87,76},nil,{image="images/UnionBattleIconCityGreen.png"})
        end

        display.adapt(butCity, pos[1],  pos[2], GConst.Anchor.Center)
        self.LeftBottomNode:addChild(butCity,2+1536-pos[2])
        butCity:setTouchThrowProperty(true, true)

        local but=butCity:getDrawNode()

        local b=plays[i]
        if b then
            local hpPct = b.hp/10000
            if hpPct<=0 then
                butCity:setVisible(false)
                temp = ui.sprite("images/UnionBattleIconCityDeath.png")
                display.adapt(temp, pos[1],  pos[2], GConst.Anchor.Center)
                self.LeftBottomNode:addChild(temp,2)
            else
                if hpPct<1 then
                    UIeffectsManage:showEffect_lianmenzhan(but,w,20)
                end
                temp = ui.sprite("images/proBack4.png",{77, 14})
                display.adapt(temp, 10, -10+6, GConst.Anchor.LeftBottom)
                but:addChild(temp)
                temp = ui.sprite("images/proFillerGreen.png",{75, 11})
                display.adapt(temp, 11, -9+6, GConst.Anchor.LeftBottom)
                temp:setHValue(-79)
                but:addChild(temp)
                temp:setProcess(true,hpPct)
                temp = ui.sprite("images/hp2.png",{22, 21})
                display.adapt(temp, -2, -12+6, GConst.Anchor.LeftBottom)
                but:addChild(temp)
            end
        end
        local size1,size2=15,18
        local ox,oy,oyy=43,64,22
        if i==1 then
            size1,size2=19,23
            ox,oy,oyy=58,84,40
        end

        --等级
        temp = ui.label("", General.font1, size1, {color={255,255,255}})
        display.adapt(temp, ox, oy, GConst.Anchor.Center)
        butCity:getDrawNode():addChild(temp)
        local itemLv = temp
        --玩家名字
        temp = ui.label("", General.font5, size2, {color={255,255,255}})
        display.adapt(temp, ox, oy+oyy, GConst.Anchor.Center)
        butCity:getDrawNode():addChild(temp)
        local itemName = temp
        for j,v in pairs(plays) do
            if i==v.pos then
                itemLv:setString("Lv"..v.lv)
                itemName:setString(v.name)
            end
        end
        local function callClickCity()
            self:clickCity(i,pos)
        end
        butCity:setScriptCallback(Script.createCallbackHandler(callClickCity))
    end
end

function UnionBattleLineupInterface:showStateViews()
    if self.nowFlag then
        if self.isMy then
            self.nowFlag:setPosition(450+180,1327)
        else
            self.nowFlag:setPosition(1422+180,1327)
        end
    end

    self.TopNode2:removeAllChildren(true)
    self.LeftBottomNode2:removeAllChildren(true)
    self.RightBottomNode:removeAllChildren(true)
    self.LeftTopNode:removeAllChildren(true)
    if  self.clickCityNode then
        self.clickCityNode:removeFromParent(true)
        self.clickCityNode=nil
    end
    if  self.closeNode then
        self.closeNode:removeFromParent(true)
        self.closeNode=nil
    end
    if self.choseState then
        self.choseState:removeFromParent(true)
        self.choseState=nil
    end
    if self.setNode then
        self.setNode:removeFromParent(true)
        self.setNode = nil
    end

    if self.state==2 then       --布阵 进入布阵状态
        self.butKeep = nil
        self:loadView("leftBottomViews2",self.LeftBottomNode2)
        self:loadView("rightBottomViews2",self.RightBottomNode)
        self:insertViewTo()
        self.viewTab.butKeep:setListener(function()
            print("保存")
            self:setpvllayout()
        end)
        local num = self.knum
        if num > 30 then
            num = 30
        end
        for i,v in ipairs(self.battlePlays) do
            if v.pos > 0 then
                num = num-1
            end
        end
        if num <= 0 then
            self.butKeep:setGray(false)
        else
            self.butKeep:setGray(true)
        end

        self.viewTab.butCancel:setListener(function()
            print("取消")
            if self.isTruce then
                display.closeDialog(self.priority)
            else
                self.state=3
                self:initBattleData(self.battleData)
            end
        end)
        self.viewTab.butAutoLineup:setListener(function()
            print("自动布阵")
            self:autopvllayout()
        end)
    elseif self.state==3 then                         --战斗中
        self:loadView("topViews3",self.TopNode2)
        self:loadView("leftBottomViews3",self.LeftBottomNode2)
        self:loadView("rightBottomViews3",self.RightBottomNode)
        self:loadView("leftTopViews",self.LeftTopNode)
        self:insertViewTo()
        --布阵
        self.butLayout:setListener(function()
            GameLogic.unionBattle(1)
        end)
        --前往本方
        self.butBackBase:setListener(function()
            if self.isMy then
                self.isMy = nil
            else
                self.isMy = true
            end
            self:showStateViews()
            self:initMapViews()
        end)
        --积分
        local scoreMy,scoreHe = 0,0
        for i,v in ipairs(self.allBattlePlays1) do
            scoreMy = scoreMy+v.score
        end
        for i,v in ipairs(self.allBattlePlays2) do
            scoreHe = scoreHe+v.score
        end

        --addHP addDmg
        local add = {self.unionInfos.hpAdd1,self.unionInfos.atkAdd1,self.unionInfos.hpAdd2,self.unionInfos.atkAdd2}
        local addlv = {0,0,0,0}
        self.addlv =addlv
        local max = {0,0,0,0}

        for i,v in ipairs(add) do
            while true do
                max[i] = 2000+addlv[i]*250
                if v>max[i] then
                    addlv[i] = addlv[i]+1
                    add[i] = add[i]-max[i]
                    v = v-max[i]
                else
                    break
                end
            end
        end

        self.label_scoreMy:setString(scoreMy)
        self.label_scoreHe:setString(scoreHe)
        self.label_battleTimeValue:setString(const.UPvpTimes-self.atknum .."/".. const.UPvpTimes)
        self.label_addHpMyValue:setString(SG("label_addHp")..":+"..addlv[1]*5 .. "%")
        self.label_addDmgMyValue:setString(SG("label_addDmg")..":+"..addlv[2]*5 .. "%")
        self.label_addHpHeValue:setString(SG("label_addHp")..":+"..addlv[3]*5 .. "%")
        self.label_addDmgHeValue:setString(SG("label_addDmg")..":+"..addlv[4]*5 .. "%")
        --self.params.addlv = addlv   --1我们hp  2dmg   3敌方hp  4dmg


        --讨伐次数显示
        local sign = true
        for i,v in ipairs(self.battlePlays1) do
            if v.uid == GameLogic.getUserContext().uid then
                sign = true
            end
        end
        if sign then
            self.label_battleTimeValue:setVisible(true)
            self.label_battleTime:setVisible(true)
        else
            self.label_battleTimeValue:setVisible(false)
            self.label_battleTime:setVisible(false)
        end


        local a,b,idx = 0,0
        if self.isMy then
            a,b = addlv[1],addlv[2]
            idx = 1
        else
            a,b = addlv[3],addlv[4]
            idx = 3
        end
        self.label_moraleHp:setString(Localizef("labelMoraleLv",{a=a}))
        self.label_moraleDmg:setString(Localizef("labelMoraleLv",{a=b}))
        self.label_hpValue:setString("+".. a*5 .."%")
        self.label_dmgValue:setString("+".. b*5 .."%")

        --进度条
        local pro = {0,0}
        for i=idx,idx+1 do
            pro[i] = add[i]/max[i]
        end
        self.pro1:setProcess(true,a/10)
        self.pro2:setProcess(true,b/10)
        --伤害
        self.btAdd1:setListener(function()
            UnionBattleInspireDialog.new(self.unionInfos,2,function()
                self.battleData.u_clan[5]=self.unionInfos.atkAdd1
                self:showStateViews()
            end)
        end)
        --血量
        self.btAdd2:setListener(function()
            UnionBattleInspireDialog.new(self.unionInfos,1,function()
                self.battleData.u_clan[4]=self.unionInfos.hpAdd1
                self:showStateViews()
            end)
        end)


        if self.isMy then
            self.btAdd1:setVisible(true)
            self.btAdd2:setVisible(true)
            self.btnGoMy:setString(SG("label_goFoe"))
            self.butBackBase:setListener(function()
                self.isMy = nil
                self:showStateViews()
                self:initMapViews()
            end)
        else
            self.btAdd1:setVisible(false)
            self.btAdd2:setVisible(false)
            self.butBackBase:setListener(function()
                self.isMy = true
                self:showStateViews()
                self:initMapViews()
            end)
        end
    end
end

function UnionBattleLineupInterface:update(diff)
    if self.state == 3 then
        local time = GameLogic.getSTime()
        local uTime = GameLogic.getUnionBattleTime()
        if time>=uTime[1] and time<=uTime[2] then
            display.pushNotice(Localize("labelBattleEnd2"))
            display.closeDialog(self.priority)
        end
    end
end

-----------------------------------------------------------------------------------------------------------------------
function UnionBattleLineupInterface:initBattleData(data)
    --user:用户Id，联盟Id，联盟职位，用户信息[name，elv]，位置(正常1-30，31-50正常补位，51未设置出战位补位)，分数，血量，最后进攻时间，攻击次数
    --clan：联盟Id，开战时间，对手联盟Id，血量加成，攻击加成，对手联盟名，对手联盟图标，最后一次攻击人员
    self.params = data
    local unionInfos={name1=data.t_clan[6],flag1=data.t_clan[7],name2=data.u_clan[6],flag2=data.u_clan[7],hpAdd1=data.u_clan[4],atkAdd1=data.u_clan[5],hpAdd2=data.t_clan[4],atkAdd2=data.t_clan[5]}
    self.unionInfos = unionInfos
    self.state = 3

    --参战总人数
    self.knum = 30
    --参战状态
    self.fstate = data.fstate
    --加入联盟时间
    self.jionTime = data.ctime
    self.atknum = 3
    --我方
    local battlePlays1={}
    if data.u_user then
        for i,v in ipairs(data.u_user) do
            local tab={unionId=v[2],uid=v[1],job=v[3],name=v[4],lv=v[5],pos=v[6],score=v[7],hp=v[8],atkTime=v[9],atkNum=v[10],power=v[11],reliveNum=v[12],jionTime=v[15]}
            table.insert(battlePlays1,tab)
            if tab.uid==GameLogic.getUserContext().uid then
                self.atknum =tab.atkNum
            end
        end
        self.allBattlePlays1 = battlePlays1
        self.battlePlays1=self:sortByPlayPos(battlePlays1)
    end
    --敌方
    local battlePlays2={}
    if data.t_user then
        for i,v in ipairs(data.t_user) do
            local tab={unionId=v[2],uid=v[1],job=v[3],name=v[4],lv=v[5],pos=v[6],score=v[7],hp=v[8],atkTime=v[9],atkNum=v[10],power=v[11],reliveNum=v[12]}
            table.insert(battlePlays2,tab)
        end
        self.allBattlePlays2 = battlePlays2
        self.battlePlays2=self:sortByPlayPos(battlePlays2)
    end
    if self.initUI then
        self:initUI()
    end

end
--根据位置对应排序，部署规则，1-30，按正常位置出站，31-51.先按战力出站，战力相同根据uid大小出站，52.以上条件都不能满足30个出站的情况，则用52补足，规则与上面一致
function UnionBattleLineupInterface:sortByPlayPos(tab)
    table.sort(tab,function (a,b)
        if a.power==b.power then
            return a.uid<b.uid
        else
            return a.power>b.power
        end
    end)
    local rTab={}
    for i,v in ipairs(tab) do
        if v.pos>0 and v.pos<=30 then
            rTab[v.pos] = v
            v.inToBattle = true
        end
    end
    for i=1,30 do
        if not rTab[i] then
            for j,v in ipairs(tab) do
                if v.pos>=31 and v.pos<=51 and not v.inToBattle then
                    rTab[i] = v
                    v.pos = i
                    v.inToBattle = true
                    break
                end
            end
        end
    end
    for i=1,30 do
        if not rTab[i] then
            for j,v in ipairs(tab) do
                if v.pos>=52 and not v.inToBattle then
                    rTab[i] = v
                    v.pos = i
                    v.inToBattle = true
                    break
                end
            end
        end
    end
    return rTab
end

function UnionBattleLineupInterface:initLayoutData(data)
    local context = GameLogic.getUserContext()
    local unionInfos={name1="",flag1=1101}
    if context.union then
        unionInfos.name1 = context.union.name
        unionInfos.flag1 = context.union.flag
    end
    self.unionInfos = unionInfos
    if data.plays then
        --参战总人数
        self.knum = #data.plays
        --所有参战玩家
        self.battlePlays={}
        for i,v in ipairs (data.plays) do
            local tab = {unionId=v[1],uid=v[2],name=v[3],lv=v[4],pos=v[5],job=v[6]}
            if tab.pos>30 or tab.pos<0 then
                tab.pos = 0
            end
            table.insert(self.battlePlays,tab)
        end
        --根据等级排序
        table.sort(self.battlePlays,function (a,b)
            return a.lv>b.lv
        end)
    end

    if self.initUI then
        self:initUI()
    end
end


function UnionBattleLineupInterface:getDataOver(isSuc,data)
    if isSuc then
        self.params = data
        local plays

        if data.state == 2 then
            if data.puser == GameLogic.getUserContext().uid then
                self.sitime = data.ptime
                if self.sitime+5*60-GameLogic.getTime()>0 then
                    self.isInLineup = true
                end
                self.bplays = clone(self.params.plays)
            end
            plays = self.params.plays
        elseif data.state == 3 then
            plays = self.params.play1
        end

        --根据规模确定坑位
        local knum = 10
        if 16<#plays and #plays<26 then
            knum = 20
        elseif 25<#plays then
            knum = 30
        end
        self.knum = knum

        if self.initUI then
            self:initUI()
        end
    end
end


function UnionBattleLineupInterface:getpvlinfo()
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getpvlinfo",{},function(isSuc,data)
        GameNetwork.unlockRequest()
        self:getDataOver(isSuc,data)
    end)
end

function UnionBattleLineupInterface:intopvllayout()
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("intopvllayout",{},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code == 2 then
                display.pushNotice(SG("string_intopvllayout2"))
                if self.isTruce then
                    display.closeDialog(self.priority)
                end
            elseif data.code == 21 then
                display.pushNotice(SG("string_intopvllayout"))
                if self.isTruce then
                    display.closeDialog(self.priority)
                end
            else
                self.state=2
                if self.initLayoutData then
                    self:initLayoutData(data)
                end
            end
        end
    end)
end

function UnionBattleLineupInterface:setpvllayout()
    local result = {}
    local _haveMask = {}
    for i,v in ipairs(self.battlePlays) do
        -- if v.pos> 0 then
            if _haveMask[v.pos] then
                v.pos = 51
            else
                _haveMask[v.pos] = 1
            end
            table.insert(result,{v.pos,v.unionId,v.uid})
        -- end
    end

    local max = self.knum
    if max > 30 then
        max = 30
    end
    if #result<max then
        display.pushNotice(Localize("stringCantSave"))
        return
    end
    local context = GameLogic.getUserContext()
    context:addCmd({const.CmdPvlLSet,result})
    display.pushNotice(Localize("labelSaveSucceed"))
    _sendMsg()
    if self.isTruce then
        display.closeDialog(self.priority)
    else
        self.state=3
        self:initBattleData(self.battleData)
    end
end

function UnionBattleLineupInterface:autopvllayout()
    _G["GameNetwork"].request("autopvllayout",{},function(isSuc,data)
        if isSuc then
            display.pushNotice(Localize("stringAutoSucceed"))
            _sendMsg()
            if self.isTruce then
                display.closeDialog(self.priority)
            elseif self.initBattleData then
                self.state=3
                self:initBattleData(self.battleData)
            end
        end
    end)
end

function UnionBattleLineupInterface:beginpvlatk()
    --发送请求
    local battleArr = self.battleArr
    local nowItemIdx = self.nowItemIdx
    local uid = battleArr[nowItemIdx].uid
    local cid = battleArr[nowItemIdx].unionId
    local atknum = self.atknum
    if atknum>=const.UPvpTimes then
        display.pushNotice(Localize("stringUPvpNotEnough"))
        return
    end
    --检测已死亡数量
    local deathNum = 0
    for i,v in ipairs(battleArr) do
        if v.hp==0 then
            deathNum=deathNum+1
        end
    end
    GameLogic.checkCanGoBattle(const.BattleTypeUPvp,function()
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("beginpvlbt", {lid=cid,tid=uid},function(isSuc,data)
            GameNetwork.unlockRequest()
            if isSuc then
                --code 10.有盟友在战斗中 11.未设置参战状态不允许攻打 12.你已经被退出该联盟
                if data.code == 10 then
                    display.pushNotice(Localize("stringcantUnionMap"))
                elseif data.code == 11 then

                elseif data.code == 12 then

                else
                    local destroyDebuffs={atk=0,hp=0}
                    for i,v in ipairs(self.battlePlays2) do
                        if v.pos == 1 and v.hp == 0 then
                            destroyDebuffs.atk = const.UnionPvlData[v.pos][4]
                        elseif 2<=v.pos and v.pos<=5 and v.hp == 0 then
                            destroyDebuffs.hp = const.UnionPvlData[v.pos][4]
                        end
                    end

                    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=8,data = data,bparams = {deathNum=deathNum,index = nowItemIdx,pvldata = {lmid=cid,duid=uid,addlv=self.addlv,destroyDebuffs=destroyDebuffs}}})
                    display.closeDialog()
                end
            else

            end
        end)
    end)
end

function UnionBattleLineupInterface:setpvlstate(t)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("setpvlstate",{setpvlstate={t}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if data.code==0 then
            print("设置成功")
            if not self.deleted then
                self.fstate = t
            end
        end
    end)
end

return UnionBattleLineupInterface












