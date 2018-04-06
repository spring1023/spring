--每日寻宝对话框
local SData = GMethod.loadScript("data.StaticData")

local EverydayTreasureDialog = class2("EverydayTreasureDialog",function()
    return BaseView.new("EverydayTreasureDialog.json")
end)
function EverydayTreasureDialog:ctor()
    memory.loadSpriteSheet("images/otherIcon/xunbaosezi.plist")
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end
function EverydayTreasureDialog:initUI()
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    viewTab.butHelp:setScriptCallback(Script.createCallbackHandler(self.onQuestion,self))

    self:loadView("centerViews")
    self:insertViewTo()
    local itemPos={{207,1091},{449,1091},{690,1091},{932,1091},{1173,1091},{1415,1091},{1656,1091},
                   {1656,859},{1656,626},{1656,394},
                   {1656,162},{1415,162},{1173,162},{932,162},{690,162},{449,162},{207,162},
                   {207,394},{207,626},{207,859}}
    self.itemPos = itemPos
    self.itemArr = {}
    for i,pos in ipairs(itemPos) do
        local idx = i - 1
        local item = SData.getData("fdboxes",idx)
        local icon,label,iconInfos = GameUI.addItemIcon(self,item.gtype,item.gid,185/200,pos[1]+92, pos[2]+92,true,false,{itemNum=item.gnum})
        self.itemArr[i] = icon
        local temp = ui.button({185, 185}, nil, {})
        display.adapt(temp, pos[1]+92, pos[2]+92, GConst.Anchor.Center)
        self:addChild(temp)
        temp:setListener(function()
            self:changeChecked(item,pos)
        end)
    end
    RegActionUpdate(self, Handler(self.updateMy, self, 0.2), 0.2)
    self:reload()
    self.imgShadow:setVisible(true)
    ui.setFrame(self.imgDice, "saimian" .. math.random(6) .. ".png")
end

function EverydayTreasureDialog:changeChecked(item,pos)
    if not self.checkedXuanzhong then
        local temp = ui.sprite("images/xuanzhongdt.png",{243, 241})
        display.adapt(temp, pos[1]+92, pos[2]+92, GConst.Anchor.Center)
        self:addChild(temp)
        self.checkedXuanzhong = temp
    else
        self.checkedXuanzhong:setPosition(pos[1]+92, pos[2]+92)
    end
    self.rewardDes:setVisible(true)
    local str1 = Localize("unionCupReward") .. "：  "
    local name
    if item.gtype == 0 then
        if item.gid == 1 then
            name = Localize("labelDTTime")
        elseif item.gid == 2 then
            name = Localize("labelBeiReward")
        end
    else
        name = GameLogic.getItemName(item.gtype,item.gid)
    end
    self.rewardDes:setString(str1 .. name .. "X" .. item.gnum)
end

function EverydayTreasureDialog:onQuestion()
    HelpDialog.new("dataQuestionEverydt")
end

function EverydayTreasureDialog:reload()
    self.params = GameLogic.getUserContext().activeData.limitActive[101]
    self.haveReward = {}
    for i,v in ipairs(self.itemArr) do
        self.itemArr[i]:setSValue(0)
    end
    for i,v in ipairs(self.params[7]) do
        local idx = v+1
        self.haveReward[idx] = true
        self.itemArr[idx]:setSValue(-100)
    end
    local idx = self.params[4]+1
    self:changeIndex(idx)
    local shakeNum = self.params[3]              
    local useGem = self.params[5]                
    local allNum = 1
    local needGem = 500
    if 500<=useGem and useGem<1000 then
        allNum = 2
        needGem = 1000
    elseif useGem>=1000 then
        allNum = math.floor((useGem-1000)/1000)+3
        needGem = (allNum-2)*1000+1000
    end
    --vip
    allNum = allNum+GameLogic.getUserContext():getVipPermission("fbox")[2]
    self.remainNum = allNum-shakeNum
    self.canGetShakeNum:setString(Localize("stringUseCrystalCanGet") .. useGem .. "/" .. needGem)

    self.butDice:setListener(function()
        self:randomfindbox()
    end)
end

function EverydayTreasureDialog:changeIndex(idx)
    local pos = self.itemPos[idx]
    if self.checkedNow then
        self.checkedNow[1]:removeFromParent(true)
        self.checkedNow[2]:removeFromParent(true)
    end
    local temp = ui.sprite("images/xuanzhong5.png",{243, 241})
    display.adapt(temp, pos[1]+92, pos[2]+92, GConst.Anchor.Center)
    self:addChild(temp)

    local temp2 = GameLogic.getUserContext().guideHand:createArrow()
    display.adapt(temp2, pos[1]+92, pos[2]+112, GConst.Anchor.Bottom)
    self:addChild(temp2,2)

    self.checkedNow = {temp,temp2}
end

function EverydayTreasureDialog:arrowAction()
    local count = 0
    local idx = self.bpoint+1
    local actionArr = {}
    while count<self.diceData.point do
        idx = idx+1
        if idx>20 then
            idx = 1
        end
        if not self.haveReward[idx] then
            table.insert(actionArr,idx)
            count = count+1
        end
    end

    local function moveArrow()
        local idx = table.remove(actionArr,1)
        self:changeIndex(idx)
        if next(actionArr) then
            self:runAction(ui.action.sequence({{"delay",0.3},{"call",moveArrow}}))
        else
            self:reload()
            self.butDice:setEnable(true)
        end
    end
    moveArrow()
end

function EverydayTreasureDialog:shakeDice()
    self.butDice:setVisible(false)
    self.imgShadow:setVisible(true)
    local animate = ui.animateSprite(5/6, "sai", 10, {isRepeat = true})
    animate:setPosition(1020,804)
    self:addChild(animate)
    self.diceAnimate = animate
    self.isInShake = true
    self.inHttp = true
    self.shakeTime = 0
end

function EverydayTreasureDialog:updateMy(diff)
    if self.labelResetTimeValue then
        local rtime = 86400-GameLogic.getRtime()
        self.labelResetTimeValue:setString(Localizet(rtime))

        local stime = GameLogic.getSTime()
        local dtime = self.params[8] or 0
        -- print(stime,dtime,math.floor((stime-const.InitTime)/86400),math.floor((dtime-const.InitTime)/86400))
        if (math.floor((stime-const.InitTime)/86400) > math.floor((dtime-const.InitTime)/86400)) then
            if stime >= self.params[2] then
                self.params[1] = self.params[2]
                self.params[2] = self.params[2] + 86400*7
            end
            self.params[3] = 0
            self.params[4] = 0
            self.params[5] = 0
            self.params[6] = 1
            self.params[7] = {}
            self.params[8] = stime
            self:reload()
        end
    end
    if self.remainNum then
        --local num = 20 - #self.params[7]
        --local shakeNum = self.remainNum>num and num or self.remainNum
        local shakeNum = self.remainNum
        self.remainNumValue:setString(Localize("labelTodaySurplus") .. shakeNum)
    end

    if self.isInShake then
        self.shakeTime = self.shakeTime+diff
        if self.shakeTime>1 and not self.inHttp then
            self.isInShake = false
            self.diceAnimate:removeFromParent(true)
            if self.diceId then
                music.stop(self.diceId)
                self.diceId=nil
            end
            self.butDice:setVisible(true)
            self.imgShadow:setVisible(true)
            ui.setFrame(self.imgDice, "saimian" .. self.diceData.point .. ".png")
            self:arrowAction()
        end
    end
end
----------------------------------------------------------------------------------------------------------------
function EverydayTreasureDialog:randomfindbox()
    if self.remainNum<=0 then
        display.pushNotice(Localize("stringNoRemainTimes"))
        return
    end
    local num = 0
    for k,v in pairs(self.haveReward) do
        num = num+1
    end

    if num>=20 then
        display.pushNotice(Localize("stringGetAllReward"))
        return
    end
    self.diceId=music.play("sounds/dice.mp3")
    if GameNetwork.lockRequest() then
        self.butDice:setEnable(false)
        self:shakeDice()
        GameNetwork.request("randomfindbox",nil,function(isSuc, data)
            GameNetwork.unlockRequest()
            if isSuc then
                if self.priority then
                    self.inHttp = false
                    self.diceData = data
                    self.bpoint = self.params[4]
                    self.params[4] = data.order
                    self.params[3] = self.params[3]+1
                    table.insert(self.params[7],data.order)
                    local agls = data.agls[1]
                    if agls[1] == 0 then
                        if agls[2] == 1 then
                            self.params[3] = self.params[3] - agls[3]
                            self:runAction(ui.action.sequence({{"delay",data.point*0.3+1},{"call",function()
                                display.pushNotice(Localizef("stringAgainTreasure",{n=agls[3]}))
                            end}}))
                        else
                            self:runAction(ui.action.sequence({{"delay",data.point*0.3+1},{"call",function()
                                display.pushNotice(Localize("stringX3"))
                            end}}))
                        end
                    else
                        GameLogic.showGet(data.agls,data.point*0.3+1,true)
                        GameLogic.addRewards(data.agls)
                        GameLogic.statCrystalRewards("每日寻宝奖励",data.agls)
                    end
                    GameEvent.sendEvent("refreshTaskRedNum")
                else
                    local params = GameLogic.getUserContext().activeData.limitActive[101]
                    self.inHttp = false
                    self.diceData = data
                    self.bpoint = params[4]
                    params[4] = data.order
                    params[3] = params[3]+1
                    table.insert(params[7],data.order)
                    local agls = data.agls[1]
                    if agls[1] == 0 then
                        if agls[2] == 1 then
                            params[3] = params[3] - agls[3]
                            local del = nil
                            local function delay()
                                GMethod.unschedule(del)
                                display.pushNotice(Localizef("stringAgainTreasure",{n=agls[3]}))
                            end
                            del = GMethod.schedule(delay, data.point*0.3+1)
                        else
                            local del = nil
                            local function delay()
                                GMethod.unschedule(del)
                                display.pushNotice(Localizef("stringX3"))
                            end
                            del = GMethod.schedule(delay, data.point*0.3+1)
                        end
                    else
                        GameLogic.showGet(data.agls,data.point*0.3+1,true)
                        GameLogic.addRewards(data.agls)
                        GameLogic.statCrystalRewards("每日寻宝奖励",data.agls)
                    end
                    GameEvent.sendEvent("refreshTaskRedNum") 
                end
            end
        end)
    end
end

return EverydayTreasureDialog














