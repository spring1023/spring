local NightmareDialog = class(DialogViewLayout)
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local _pvhMap = GMethod.loadConfig("configs/maps/PvhMap.json")
function NightmareDialog:onInitDialog()
    self:setLayout("NightmareDialog.json")
    self:loadViewsTo()
    self.contextMode=self.context.npvh
    self.context.nightmare=true
    self.myStage=self.contextMode.stage
    self.idx=1
    --远征剩余挑战次数/噩梦远征关卡进度
    self.labelPvhChance:setVisible(false)
    self.title:setString(Localize("titleMatch103"))
    self.heroNum:setPosition(220,1125)

    local survivalHeroNum=0
    local numAll=0
    local levelAll=0
    local levelList={}
    for i=1,15 do
        local hero = self.context.heroData:getHeroByLayout(const.LayoutnPvh, i, 1)
        if hero and hero.layouts[const.LayoutnPvh].hp>0 then
            survivalHeroNum=survivalHeroNum+1
        end
    end
    self.avgLevel = self.context.heroData:getTopAvgLevel(5)
    local tmpAvgLevel = self.context.heroData:getTopAvgLevel(1)
    if tmpAvgLevel * 0.75 > self.avgLevel then
        self.avgLevel = tmpAvgLevel
    end
    self.survivalHeroNum = survivalHeroNum
    --存活英雄数目
    self.labelSurvivalHeroNum:setString(survivalHeroNum .. "/15")
    if self.myStage<18 then
        self.idx=1
    elseif self.myStage<36 then
        self.idx=2
    elseif self.myStage<=54 then
        self.idx=3
    end
end

function NightmareDialog:changeBtnType()
    self.btnAttack:setScriptCallback(ButtonHandler(self.onAttack, self))
end

function NightmareDialog:onEnter()
    self:reloadMapView()
    self.questionTag = "dataQuestionPvhMap"
end

function NightmareDialog:reloadMapView()
    local bg = self.nodeMapBack.view
    local temp
    local map = ui.scrollNode({1873-60*2,825},1,true,true,
                    {scroll=true,clip=true,setInertia=true,scale={1,1,1,1},rect={0,0,6820,825}})
    display.adapt(map,31+60,244, GConst.Anchor.LeftBottom)
    bg:addChild(map)
    self.map = map
    bg=map:getScrollNode()
    local mapNumber=3
    self.mapbg={}
    --6820,825  背景大地图是由3张地图拼接而成
    for i=1,3 do
        temp = ui.sprite("images/dialogBattleMap"..i..".png",{6820/3, 825})
        display.adapt(temp,6820/3*(i-1),0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        self.mapbg[i]=temp
    end
    --关卡和宝藏之间的白点
    local whiteDot = _pvhMap.dot
    for i,tab in ipairs(whiteDot) do
        temp = ui.sprite("images/pvePoint.png",{34, 34})
        display.adapt(temp,tab[1],825-tab[2], GConst.Anchor.Center)
        bg:addChild(temp)
        --连接到商店的白点是蓝色的
        if i>63 then
            ui.setColor(temp, 29, 230, 228)
        end
    end
    local levelPoint = _pvhMap.guanKa
    local pstage = 0
    local stageButs = {}   --关卡按钮
    local stagePoses = {}  --关卡位置
    local storeIdx = 0
    self.stageButs = stageButs
    self.stagePoses = stagePoses
    for i,tab in ipairs(levelPoint) do
        if tab[3]~=6 then  --tab[3]==6表示商店 1,2表示宝箱
            pstage = pstage+1
            stagePoses[pstage] = {tab[1], tab[2], tab[3]<3}
            temp=ui.button({154, 154}, nil, {})
        else
            storeIdx = storeIdx+1
            temp=ui.button({154, 154}, self.onChooseStage, {cp1=self, cp2=storeIdx})
        end
        temp:setBackgroundSound("sounds/checkpoint.mp3")
        display.adapt(temp, tab[1], 825-tab[2], GConst.Anchor.Center)
        bg:addChild(temp)
        local stageItem = {stage=tab[3], stype=2, button = temp}
        stageButs[i] = stageItem
    end

    self.stageIdx2:setScriptCallback(ButtonHandler(self.onChangepage,self,2))
    self.stageIdx1:setScriptCallback(ButtonHandler(self.onChangepage,self,1))
    if self.idx==1 then
        self.stageIdx1:setVisible(false)
        self.stageIdx2:setVisible(true)
    elseif self.idx==3 then
        self.stageIdx1:setVisible(true)
        self.stageIdx2:setVisible(false)
    elseif self.idx==2 then
        self.stageIdx1:setVisible(true)
        self.stageIdx2:setVisible(true)
    end
    self:refreshMapUI()
end

function NightmareDialog:refreshMapUI()
    local stage = self.myStage+1
    if stage>18 and stage<55 then stage=(stage-1)%18+1 end
    if stage==55 then stage=18 end
    local gkpos = self.stagePoses[stage] or self.stagePoses[stage-1]
    self.map:moveAndScaleToCenter(1, gkpos[1], 825-gkpos[2], 0.1)
    self:reloadMapStages()
end

function NightmareDialog:reloadMapStages()

    self.progressNode:setVisible(true)
    if not self._stagePointSeted then
        self._stagePointSeted = true
        self.stagePoint:setPosition(-129+(self.myStage/54)*960,110)
        self.stagePoint:runAction(ui.action.arepeat(ui.action.sequence{{"moveBy", 0.42, 0, 18},{"moveBy", 0.25, 0, 5},{"moveBy", 0.25, 0, -23}}))
    end
    --普通远征通关条件下进入噩梦远征调整地图
    if self.idx==3 then
        for i=1,3 do
            self.mapbg[i]:setColor(cc.c3b(255,0,0))
            self.mapbg[i]:setLValue(40)
        end
    elseif self.idx==2 then
          for i=1,3 do
            self.mapbg[i]:setHValue(57)
        end
    end
    local pvh = self.contextMode
    local mystage=self.myStage
    if mystage>=18 and mystage<54 then mystage=mystage%18 end
    if mystage==54 then mystage=18 end
    if math.floor(self.myStage/18+1)>self.idx then
        mystage=18
    elseif math.floor(self.myStage/18+1)<self.idx then
        mystage=-1
    end
    local dir1={Localize("nightmareStage1"),Localize("nightmareStage2"),Localize("nightmareStage3")}
    local dir2={0,0,1,1,2,2,3,4,4,5,5,6,6,7,7,8,8,9,10,10}
    self.lableRTDes:setString(Localizef("labelPvhProcess", {a=dir1[self.idx],b=dir2[mystage+2].. "/" ..10}))
    local pstage = 0
    local storeidx=0
    self.storeEffect={}
    for i,stageItem in ipairs(self.stageButs) do
        --pstage是除了商店以外的关卡的计数 settingStage下一个遍历的关切卡（会包括商店）
        local settingStage = pstage+1
        if stageItem.stage~=6 then
            pstage = pstage+1
        end
        --没有达到的关卡不可点击
        if settingStage>(mystage+1) then
            stageItem.lock = true
            stageItem.state = nil
            stageItem.button:setEnable(false)
        else
            stageItem.lock = nil
            if settingStage==(mystage+1) or stageItem.stage==6 then
                --state==2表示可以点击
                stageItem.state = 2
            else
                stageItem.state = nil
            end
            --关卡特效
            if settingStage==(mystage+1) then
                if self.guankaEffect then
                    self.guankaEffect:removeFromParent(true)
                end
                self.guankaEffect=UIeffectsManage:showEffect_guangka(stageItem.button:getDrawNode(),77,77,2)
            end
            if stageItem.stage==6 then
                storeidx=storeidx+1
                if self.guankaEffect and self.storeEffect[storeidx] then
                    self.storeEffect[storeidx]:removeFromParent(true)
                end
                self.storeEffect[storeidx]=UIeffectsManage:showEffect_guangka(stageItem.button:getDrawNode(),77,77,1)
            end
            stageItem.button:setEnable(true)
        end
        GameUI.updateStageTemplate(stageItem.button:getDrawNode(), stageItem)
    end

    local isBox = self.stagePoses[mystage+1]
    --设置文本 领取奖励/进攻
    if isBox and isBox[3] then
        self.btnAttackWord:setString(Localize("btnRewardBox"))
    else
        self.btnAttackWord:setString(Localize("btnPvhAttack"))
    end

    --设置按钮文本 放弃远征和通过结算
    self.btnSettlement:setScriptCallback(function ()
        display.closeDialog(0)
    end)
    self.btnSettlementWord:setString(Localize("labBack"))
    if isBox==nil or self.myStage >= 54 then
        self.btnAttack:setGray(true)
        self.btnAttack:setEnable(false)
    else
        self.btnAttack:setGray(false)
        self.btnAttack:setEnable(true)
    end
    self:changeBtnType()
end

function NightmareDialog:onChooseStage(storeIdx)
    if self.idx==3 then
        storeIdx=storeIdx+6
    elseif self.idx==2 then
        storeIdx=storeIdx+3
    end
    display.showDialog(PvhStoreDialog.new({parent=self,context=self.context,storeIdx=storeIdx,nightmare=true}))
end

--进攻p讨伐
function NightmareDialog:onAttack()
    local stage = self.myStage+1
    if stage>18 then stage=(stage-1)%18+1 end
    local isBox = self.stagePoses[stage]
    if not isBox then
        return
    elseif not isBox[3] then
        if self.lock then
            return
        end
        --增加检测，如果不在此检测中取下一关卡
        local allBattleStage = {1,3,5,6,8,10,12,14,16,17}
        for _,v in ipairs(allBattleStage) do
            if v==stage then
                break
            elseif v>stage then
                stage = v
                break
            end
        end
        --所有英雄已阵亡，提示已无可出战英雄
        if self.survivalHeroNum<=0 then
            display.pushNotice(Localize("stringAllDieCantGoWar"))
        else
            self.lock = true
            GameEvent.sendEvent(GameEvent.EventBattleBegin,{type=const.BattleTypePvh, isPrepare=true, bparams={stage=self.myStage+1,nightmare=true,avgLevel=self.avgLevel}})
        end
    else
        --向服务器请求获取宝箱奖励
        if GameNetwork.lockRequest() then
            GameNetwork.request("pvhbox",{stage=self.myStage+1,nightmare=true},self.onResponsePvhReward,self)
        end
    end
end

function NightmareDialog:onPvhSweepCallback(suc,data)
    GameNetwork.unlockRequest()
    if suc then
        if data ~= -1 then
            local rwds = data.rwds
            local infos = {}
            for _,v in pairs(rwds) do
                table.insert(infos,{v[2],v[3],v[4]})
            end
            self:refreshDataAndUI(infos,data.qid)
        end
    end
end

function NightmareDialog:onResponsePvhReward(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        if (self.myStage+1)%18==0 and (self.myStage+1)<54 then
            for i=1,3 do
                if self.storeEffect[i] then
                    self.storeEffect[i]:removeFromParent(true)
                end
            end
            self:flogClose(1.5)
            self.idx=self.idx+1
            if self.idx==1 then
                self.stageIdx1:setVisible(false)
                self.stageIdx2:setVisible(true)
            elseif self.idx==3 then
                self.stageIdx1:setVisible(true)
                self.stageIdx2:setVisible(false)
            elseif self.idx==2 then
                self.stageIdx1:setVisible(true)
                self.stageIdx2:setVisible(true)
            end
        end
        self:refreshDataAndUI(data,self.myStage+1)
    else
        log.d(json.encode(data))
    end
end

function NightmareDialog:refreshDataAndUI(list,stage)
    GameLogic.addRewards(list)
    GameLogic.statCrystalRewards("pvh宝箱奖励",list)
    GameLogic.showGet(list,0,true,true,const.BattleTypePvh)
    local pvh = self.contextMode
    pvh.stage = stage
    self.context.talentMatch:saveTalentMatchPvh()
    self.myStage=stage
    self:refreshMapUI()
end

function NightmareDialog:onChangepage(flag)
    local idx=self.idx
    if flag==1 then
        idx=idx-1
    elseif flag==2 then
        idx=idx+1
    end
    if idx==self.idx then
        print("that's imposible")
        return
    end
    if idx==2 and self.myStage<18 then
        display.pushNotice(Localize"bidEnter2")
    elseif idx==3 and self.myStage<36 then
        display.pushNotice(Localize"bidEnter3")
    end
    self.idx=idx
    self:reloadMapView()

end
--==============================--
--desc:云聚拢的特效
--time:2018-01-23 05:24:58
--@return
--==============================--
function NightmareDialog:flogClose(t)
    local fogs = {}

    local batch = ui.node({1024, 768})
    local sprite
    sprite = ui.sprite("images/talentMatch/fogItem1.png", {1843,1382})
    sprite:setRotation(56)
    sprite:setPosition(1273,1024)
    sprite:runAction(ui.action.easeSineOut({"moveTo", t, 586, 560}))
    batch:addChild(sprite)
    fogs[1] = sprite
    sprite = ui.sprite("images/talentMatch/fogItem1.png", {1843,1382})
    sprite:setRotation(-115)
    sprite:setPosition(-336,-47)
    sprite:runAction(ui.action.easeSineOut({"moveTo", t, 504, 335}))
    batch:addChild(sprite)
    fogs[2] = sprite
    sprite = ui.sprite("images/talentMatch/fogItem2.png", {1536,1152})
    sprite:setPosition(1402,1136)
    sprite:runAction(ui.action.sequence{{"delay",t/3.2},{"moveTo",t/3.2,743,496}})
    batch:addChild(sprite)
    fogs[3] = sprite
    sprite = ui.sprite("images/talentMatch/fogItem2.png", {1536,1152})
    sprite:setPosition(-693,84)
    sprite:runAction(ui.action.sequence{{"delay",t/3.2},{"moveTo",t/3.2,331,359}})
    batch:addChild(sprite)
    fogs[4] = sprite
    sprite = ui.sprite("images/talentMatch/fogItem3.png", {1536,1152})
    sprite:setRotation(36)
    sprite:setPosition(1042,1354)
    sprite:setOpacity(153)
    sprite:runAction(ui.action.easeSineOut({"moveTo", t, 659, 510}))
    batch:addChild(sprite)
    fogs[5] = sprite
    sprite = ui.sprite("images/talentMatch/fogItem3.png", {1536,1152})
    sprite:setRotation(-164)
    sprite:setOpacity(153)
    sprite:setPosition(-448,61)
    sprite:runAction(ui.action.easeSineOut({"moveTo", t, 463, 365}))
    batch:addChild(sprite)
    fogs[6] = sprite
    sprite = ui.sprite("images/talentMatch/fogItem4.png", {1536,1152})
    sprite:setPosition(-481,391)
    sprite:runAction(ui.action.sequence{{"delay",t*0.43},{"moveTo",t*0.375,34,390}})
    batch:addChild(sprite)
    fogs[7] = sprite
    sprite = ui.sprite("images/talentMatch/fogItem4.png", {1536,1152})
    sprite:runAction(ui.action.sequence{{"delay",t*0.43},{"moveTo",t*0.375,1083,390}})
    sprite:setPosition(1493,365)
    sprite:setFlippedX(true)
    batch:runAction(ui.action.sequence{{"delay",t},{"call",function ()
        self:flogApart(t)
    end}})
    display.adapt(batch,824,420,GConst.Anchor.Center)
    batch:addChild(sprite)
    fogs[8] = sprite
    self.fogs = fogs
    self.map:addChild(batch)

end
--==============================--
--desc:云散开的特效
--time:2018-01-23 05:28:02
--@return
--==============================--
function NightmareDialog:flogApart(t)
    local fogs = self.fogs
    fogs[1]:runAction(ui.action.sequence{{"easeSineIn",{"moveTo",t,1273,1024}},{"fadeOut",1},"remove"})
    fogs[2]:runAction(ui.action.sequence{{"easeSineIn",{"moveTo",t,-336,-47}},{"fadeOut",1},"remove"})
    fogs[3]:runAction(ui.action.sequence{{"delay",t*0.375},{"moveTo",t/3.2,1402,1136},{"fadeOut",1},"remove"})
    fogs[4]:runAction(ui.action.sequence{{"delay",t*0.375},{"moveTo",t/3.2,-693,84},{"fadeOut",1},"remove"})
    fogs[5]:runAction(ui.action.sequence{{"delay",t*0.375},{"easeSineIn",{"moveTo",t*0.625,1042,1354}},{"fadeOut",1},"remove"})
    fogs[6]:runAction(ui.action.sequence{{"delay",t*0.375},{"easeSineIn",{"moveTo",t*0.625,-448,61}},{"fadeOut",1},"remove"})
    fogs[7]:runAction(ui.action.sequence{{"delay",t*0.2},{"moveTo",t*0.375,-481,391},{"fadeOut",1},"remove"})
    fogs[8]:runAction(ui.action.sequence{{"delay",t*0.2},{"moveTo",t*0.375,1493,365},{"fadeOut",1},"remove"})
end

return NightmareDialog
