local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

PvhMapDialog = class(DialogViewLayout)
local _pvhMap = GMethod.loadConfig("configs/maps/PvhMap.json")
function PvhMapDialog:onInitDialog()
    self:setLayout("PvhMapDialog.json")
    self:loadViewsTo()
    self.contextMode=self.context.pvh
    self.context.nightmare=self.nightmare
    self.myStage=self.contextMode.stage
    --远征剩余挑战次数
    self.labelPvhChance:setString(self.contextMode:getChance(GameLogic.getSTime()) .. "/" .. self.contextMode:getMaxChance())
    --远征币
    GameUI.addResourceIcon(self.view, 9, 0.77, 160, 1120,3)
        --远征币Value
    self.labelMagicNum:setString(N2S(self.context:getRes(const.ResMagic)))
    self.title:setString(Localize("wordExpedition"))

    local survivalHeroNum=0
    local numAll=0
    local levelAll=0
    local levelList={}
    for i=1,15 do
        local hero = self.context.heroData:getHeroByLayout(const.LayoutPvh, i, 1)
        if hero and hero.layouts[const.LayoutPvh].hp>0 then
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
    --通关结算/中途放弃
    self.btnSettlement:setScriptCallback(ButtonHandler(self.onSettlement, self))
end

function PvhMapDialog:changeBtnType()
    self.labelVipSweepNum:setVisible(false)
    local _data = SData.getData("vippower",self.context:getInfoItem(const.InfoVIPlv)).pvhpass
    if _data>0 and (self.contextMode.stage+1)<=_data then
        self.btnAttackWord:setString(Localize("labelBtnAttack"))
        self.labelVipSweepNum:setVisible(true)
        self.labelVipSweepNum:setString(Localizef("labelVipSweepNum",{a=_data}))
        self.btnAttack:setScriptCallback(ButtonHandler(self.onSweep, self))
    else
        self.btnAttack:setScriptCallback(ButtonHandler(self.onAttack, self))
    end
end


--==============================--
--desc:通过self.nightmare属性去区分和一般的英雄远征和达人赛的噩梦远征
--time:2018-01-18 02:43:54
--@return
--==============================--
function PvhMapDialog:onEnter()
    self:reloadMapView()
    self.questionTag = "dataQuestionPvhMap"
end

function PvhMapDialog:reloadMapView()
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
    self:refreshMapUI()
end

function PvhMapDialog:refreshMapUI()
    local stage = self.myStage+1
    local gkpos = self.stagePoses[stage] or self.stagePoses[stage-1]
    self.map:moveAndScaleToCenter(1, gkpos[1], 825-gkpos[2], 0.1)
    self:reloadMapStages()
end

function PvhMapDialog:reloadMapStages()
    --普通远征通关条件下进入噩梦远征调整地图
    local pvh = self.contextMode
    local mystage=self.myStage
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
    if isBox==nil then
        self.btnSettlementWord:setString(Localize("btnSettlement2"))
        self.btnAttack:setGray(true)
    else
        self.btnSettlementWord:setString(Localize("btnSettlement1"))
        self.btnAttack:setGray(false)
    end
    self:changeBtnType()
end

function PvhMapDialog:onChooseStage(storeIdx)
    display.showDialog(PvhStoreDialog.new({parent=self,context=self.context,storeIdx=storeIdx}))
end

--碾压
function PvhMapDialog:onSweep()
    -- body
    if GameNetwork.lockRequest() then
        GameNetwork.request("pvhsweep",nil,self.onPvhSweepCallback,self)
    end
end

--进攻p讨伐
function PvhMapDialog:onAttack()
    local stage = self.myStage+1
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
            -- 日常任务远征（挑战一次英雄远征）
            GameLogic.getUserContext().activeData:finishActCondition(const.ActTypePVH,1)
            --噩梦远征的逻辑走和英雄远征一样的逻辑 用self.nightmare参数去区分
            GameEvent.sendEvent(GameEvent.EventBattleBegin,{type=const.BattleTypePvh, isPrepare=true, bparams={stage=self.myStage+1,avgLevel=self.avgLevel}})
        end
    else
        --向服务器请求获取宝箱奖励
        if GameNetwork.lockRequest() then
            GameNetwork.request("pvhbox",{stage=self.myStage+1},self.onResponsePvhReward,self)
        end
    end
end

function PvhMapDialog:onPvhSweepCallback(suc,data)
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

function PvhMapDialog:onResponsePvhReward(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        self:refreshDataAndUI(data,self.myStage+1)
    else
        log.d(json.encode(data))
    end
end

function PvhMapDialog:refreshDataAndUI(list,stage)
    GameLogic.addRewards(list)
    GameLogic.statCrystalRewards("pvh宝箱奖励",list)
    GameLogic.showGet(list,0,true,true,const.BattleTypePvh)
    local pvh = self.contextMode
    pvh.stage = stage
    self.myStage=stage
    self:refreshMapUI()
end

--领取通关奖励
function PvhMapDialog:onSettlement()
    local canGetExp = 0
    local bidx = 0
    local stage = self.myStage
    local isAll = stage>=#(self.stagePoses)
    for i=1, stage do
        if not self.stagePoses[i][3] then
            bidx = bidx+1
            canGetExp = const.PvhExps[bidx]
        end
    end
    display.showDialog(PvhSettlementDialog.new({parent=self, context=self.context, canGetExp=canGetExp, finished=isAll}))
    
end
