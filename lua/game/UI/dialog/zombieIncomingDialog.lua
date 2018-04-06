local SData = GMethod.loadScript("data.StaticData")

--僵尸来袭对话框
local zombieIncomingDialog = class2("zombieIncomingDialog",function()
    return BaseView.new("zombieIncomingDialog.json")
end)

function zombieIncomingDialog:ctor(bindex,opId,index)
    if index and index>0 then
        self.index = index
    end
    self.bindex = bindex
    self.opId = opId
    if self.opId then
        self.bindex = math.floor(opId/8)
    end
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    display.showDialog(self)
    self:initBack()
    self:getallpvj()
end

function zombieIncomingDialog:initBack()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestrion,self))
end
function zombieIncomingDialog:onQuestrion()
    HelpDialog.new("dataQuestionZomIn")
end
function zombieIncomingDialog:initUI()
    self:initMapView()
    self:initDownViews()
    self:updateMy(0)
    if self.opId then
        zombieIncomingChallengeDialog.new(self.opId, self.params)
    end
end

function zombieIncomingDialog:initMapView()
    local temp
    temp = ui.sprite("images/mapZheZhao.png",{1873, 850})
    display.adapt(temp, 31, 250, GConst.Anchor.LeftBottom)
    self:addChild(temp,2)

    local map = ScrollNode:create(cc.size(1873-60*2,825), 1, true, false)
    map:setScrollEnable(true)
    map:setInertia(true)
    map:setClip(true)
    map:setScaleEnable(true,1,1,1,1)

    map:setScrollContentRect(cc.rect(0,0,1873-60*2,0))
    display.adapt(map,31+60,250, GConst.Anchor.LeftBottom)
    self:addChild(map)
    local bg=map:getScrollNode()

    for i=1,3 do
        temp = ui.sprite("images/dialogBattleMap"..i..".png",{1546, 825})
        display.adapt(temp,1546*(i-1),0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
    end

    temp = ui.node()
    display.adapt(temp,-57,250, GConst.Anchor.LeftBottom)
    self:addChild(temp,3)
    self.passView=temp
end

function zombieIncomingDialog:initDownViews()
    local downNode=ui.node()
    display.adapt(downNode, 0, 0, GConst.Anchor.LeftBottom)
    self:addChild(downNode,6)
    self:loadView("downViews",downNode)
    self:insertViewTo()

    local switchDot={}
    for i=1,7 do
        local temp = ui.sprite("images/switchDot.png",{41,41})
        display.adapt(temp,808+(i-1)*64, 237, GConst.Anchor.Center)
        downNode:addChild(temp)
        temp:setScale(34/41)
        temp:setSValue(-100)
        switchDot[i]=temp
    end
    --默认为第一章节
    local chapterIndex=self.itemIdx
    if chapterIndex==1 then
        self.viewTab.butLeftNext:setVisible(false)
    elseif chapterIndex==7 then
        self.viewTab.butRightNext:setVisible(false)
    end
    switchDot[chapterIndex]:setScale(1)
    switchDot[chapterIndex]:setSValue(0)
    self:initZombieIncomingPass(chapterIndex)

    local function switchChapter(dir)
        switchDot[chapterIndex]:setScale(34/41)
        switchDot[chapterIndex]:setSValue(-100)
        chapterIndex=chapterIndex+dir
        if chapterIndex==1 then
            self.viewTab.butLeftNext:setVisible(false)
        else
            self.viewTab.butLeftNext:setVisible(true)
        end
        if chapterIndex==7 then
            self.viewTab.butRightNext:setVisible(false)
        else
            self.viewTab.butRightNext:setVisible(true)
        end
        switchDot[chapterIndex]:setScale(1)
        switchDot[chapterIndex]:setSValue(0)
        self:initZombieIncomingPass(chapterIndex)
    end
    self.viewTab.butLeftNext:setScriptCallback(Script.createCallbackHandler(switchChapter,-1))
    self.viewTab.butRightNext:setScriptCallback(Script.createCallbackHandler(switchChapter,1))
end
function zombieIncomingDialog:initZombieIncomingPass(idx)
    self.itemIdx = idx
    self.labelPassName:setString(Localize("dataPvjBPassName" .. idx))
    local params = self.params  --数据

    local bg = self.passView
    bg:removeAllChildren(true)
    local passConfig = SData.getData("pvjmap")
    local dotPoint=passConfig["dot"][idx]
    local temp
    for i,tab in ipairs(dotPoint) do
        temp = ui.sprite("images/pvePoint.png",{34,34})
        if tab[3] then
            ui.setColor(temp, 29, 230, 228)
            local id = (idx-1)*8+8
            if params.quests[id] and params.quests[id][2]>0 then
            else
                temp:setVisible(false)
            end
        end
        display.adapt(temp,tab[1],tab[2], GConst.Anchor.Center)
        bg:addChild(temp)
    end
    local Guankapoint=passConfig["guanKa"][idx]
    for i,tab in ipairs(Guankapoint) do
        local id = (idx-1)*8+i

        temp=ui.button({154, 154},nil,{image=nil})
        display.adapt(temp, tab[1],tab[2]+6, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setBackgroundSound("sounds/checkpoint.mp3")
        local button=temp
        local but=temp:getDrawNode()
        if i<=8 then
            temp = ui.sprite("images/guankaBack.png",{154, 154})
            display.adapt(temp,0,0, GConst.Anchor.LeftBottom)
            but:addChild(temp)
        end
        if i<=7 then
            temp = ui.sprite("images/unionCity" ..tab[3]..".png")
        elseif i==8 then
            temp = ui.sprite("images/pveCheckState3_1.png")
            local boss = ui.sprite("images/zombieIncomingBoss.png",{174, 89})
            display.adapt(boss,154/2+5,8, GConst.Anchor.Center)
            but:addChild(boss,1)
        elseif i==9 then
            temp = ui.sprite("images/guankaDianLiang.png",{440, 450})
            display.adapt(temp,154/2-10,154/2+6, GConst.Anchor.Center)
            but:addChild(temp)
            temp = ui.sprite("images/guankatubiao6.png")
        end
        local tubiao = temp
        display.adapt(temp,154/2,154/2, GConst.Anchor.Center)
        but:addChild(temp,2)

        if i<9 then
            if not params.quests[id] then
                button:setEnable(false)
                tubiao:setSValue(-100)
            else
                local starSate={1,1,1}
                local _isCurrentBtn = true
                for j=1,3 do
                    if j>params.quests[id][2] then
                        starSate[j]=2
                    else
                        _isCurrentBtn = false
                    end
                end

                if _isCurrentBtn then
                    GameLogic.getJumpGuide(const.BattleTypePvj,button,77,110)
                end
                local starArr = {}
                local star=ui.sprite("images/dialogStar2_" ..starSate[1]..".png",{50,54})
                display.adapt(star,154/2-53,144, GConst.Anchor.Center)
                star:setRotation(-15)
                but:addChild(star,3)
                star=ui.sprite("images/dialogStar1_" ..starSate[2]..".png",{57,61})
                display.adapt(star,154/2,164, GConst.Anchor.Center)
                but:addChild(star,3)
                star=ui.sprite("images/dialogStar2_" ..starSate[3]..".png",{50,54})
                display.adapt(star,154/2+53,144, GConst.Anchor.Center)
                star:setFlippedX(true)
                star:setRotation(15)
                but:addChild(star,3)

            end
            button:setListener(function()
                GameLogic.removeJumpGuide(const.BattleTypePvj)
                zombieIncomingChallengeDialog.new(id, self.params)
            end)
        else
            if params.quests[id-1] and params.quests[id-1][2]>0 then

            else
                button:setVisible(false)
            end
            local callback=function ()
                if self.params.shops[idx] and self.params.shops[idx][3] == 1 then
                    button:setGray(true)
                    local ygm = GameUI.addHaveGet(bg,Localize("labelAlreadyBuy"),0.5,tab[1],tab[2]+10,100)
                end
            end
            button:setListener(function()
                ChapterShopDialog.new(idx,self.params,callback)
            end)
            callback()
        end
    end

    self:initOther(idx)
end

function zombieIncomingDialog:initOther(idx)
    self.butBuy:setListener(function()
        UsePhysicalAgentsDialog.new(self.params)
    end)

    --礼包
    local sign
    if self.params.gift[idx] and self.params.gift[idx][3]==1 then
        self.labelAlreadyReceive:setVisible(true)
        sign = true
    else
        self.labelAlreadyReceive:setVisible(false)
        sign = false
    end

    local up = (idx-1)*8+1
    local stars = 0
    for i=up,up+7 do
        if self.params.quests[i] then
            stars = stars+self.params.quests[i][2]
        end
    end
    local sign2 = true
    if stars==24 then
        sign2 = false
    end
    self.butrewardBox:setListener(function()
        PerfectChestDialog.new({sign,sign2,idx,self.params},function()
            self.labelAlreadyReceive:setVisible(true)
        end)
    end)
end
--更新行动点
function zombieIncomingDialog:updateMy(diff)
    --剩余行动点
    self.labelHpAddValue:setString(self.params:getAP() .. "/240")
    --挑战次数刷新
    local dtime = GameLogic.getRtime()
    for i,v in ipairs(self.params.quests) do
        if v[6]+dtime<GameLogic.getTime() then
            v[4] = 0
            v[5] = 0
        end
    end
    --刷新已领取
end

-----------------------------------------------------------------
function zombieIncomingDialog:getallpvj()
    local params = {}
    _G["GameNetwork"].request("getallpvj",nil,function(isSuc,data)
        if isSuc then
            self.params = GameLogic.getUserContext():loadPvj(data)
            self.bindex = #self.params.quests
            if self.index then
                self.itemIdx = math.ceil(self.index/8) or 1
            else
                self.itemIdx = 1
            end
            if self.initUI then
                self:initUI()
                RegActionUpdate(self, Handler(self.updateMy, self, 0.025), 0.025)
            end
        end
    end)
end

return zombieIncomingDialog
