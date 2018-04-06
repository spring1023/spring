local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

BeercupDialog = class(DialogViewLayout)

function BeercupDialog:onInitDialog()
    if self.context.guide:getStep().type ~= "finish" then
        display.pushNotice(Localize("stringPleaseGuideFirst"))
        return
    end
    self:refreshData()
    music.play("sounds/welcome.mp3")
    local bar2=music.play("sounds/bar2.mp3",true)
    self:setLayout("BeercupDialog.json")
    self:loadViewsTo()
    local function stopMusic()
        if bar2 then
            music.stop(bar2)
        end
    end
    self.autoCloseCallback=stopMusic
    local function closeDialog()
       display.closeDialog(0)
       stopMusic()
    end
    self.closeBut:setScriptCallback(closeDialog)
    self.questionBut:setScriptCallback(self.onQuestion, self)
    self.btnDJByBeercup:setScriptCallback(ButtonHandler(self.onDJ, self, false))
    self.btnDJByCrystal:setScriptCallback(ButtonHandler(self.onDJ, self, true))
    local p = self.context:getVipPermission("tobeer")
    --if p[1] == 0 then
        --self.lbVipGet:setString(Localizef("stringVipGetMoreCup",{a=self.context:getInfoItem(const.InfoVIPlv), b=p[2]}))
    --end
    display.showDialog(self)
end

function BeercupDialog:refreshData()
    local context = self.context
    self.maxTimes = SData.getData("vippower",context:getInfoItem(const.InfoVIPlv)).djtimes
    local proC,proT
    if self.rtype==const.ResSpecial then
        proC=const.ProDJCount
        proT=const.ProDJTime
    else
        proC=const.ProDJCount2
        proT=const.ProDJTime2
    end
    if GameLogic.getToday()>context:getProperty(proT) then
        context:setProperty(proT,GameLogic.getToday())
        context:setProperty(proC,0)
    end
end

function BeercupDialog:onQuestion()
    HelpDialog.new("dataQuestionBeercup")
end

function BeercupDialog:onEnter()
    local context = self.context
    self.labelDJByCrystal:setString(Localize("labelCrystalTip"))
    self.labelChatWord:setString(Localize("labelWelcome"))
    self.nodeRTypeIcon:setTemplateValue(self.rtype)
    self.nodeRTypeIcon1:setTemplateValue(self.rtype)
    if self.rtype==const.ResSpecial then
        self.rbase = const.BaseDJSpecial
    else
        self.rbase = const.BaseDJZhanhun
    end
    self.labelBeercupUseNum:setString("1")
    self.labelDJByBeercup:setString(Localizef("labelBeercupTip"..self.rtype,{a=self.rbase}))
    self:reloadDJCost()
end

function BeercupDialog:getDJCrystalInfo()
    self:refreshData()
    local context = self.context
    local count
    if self.rtype==const.ResSpecial then
        --黑晶
        count = context:getProperty(const.ProDJCount)
    else
        --勋章
        count = context:getProperty(const.ProDJCount2)
    end
    local cost = SData.getData("djpeizhi",count+1).costgem
    return count, cost
end

function BeercupDialog:getDJResInfo()
    local num1,num2 = 0,0
    local count = self:getDJCrystalInfo()
    local data = SData.getData("djpeizhi",count+1)
    num1,num2=data.gethj,data.getxz
    return num1,num2
end

function BeercupDialog:checkTimes()
    --1,默认次数上限（无vip）2，20次上限（有vip）3，除此之外的提示
    local context = self.context
    local curTimes = self:getDJCrystalInfo()
    if curTimes>=self.maxTimes then
        if self.maxTimes==11 then
            return 1
        elseif self.maxTimes==21 then
            return 2
        end
        return 3
    end
    return 0
end

function BeercupDialog:setDJResNum()
    local num1,num2 = self:getDJResInfo()
    if self.rtype==const.ResSpecial then
        self.resNum = num1
    else
        self.resNum = num2
    end
end


function BeercupDialog:onDJ(useCrystal)
    if useCrystal then
        local timesback = self:checkTimes()
        if timesback~=0 then
            display.pushNotice(Localize("tipBeerTimes"..timesback))
            return
        end
    end
    local context = self.context
    local ctype, cvalue, count
    if useCrystal then
        ctype = const.ResCrystal
        count, cvalue = self:getDJCrystalInfo()
        self.getNum = self.resNum
    else
        ctype = const.ResBeercup
        cvalue = 1
        self.getNum = self.rbase
    end

    if context:getRes(ctype)<cvalue then
        display.showDialog(AlertDialog.new({ctype=ctype, cvalue=cvalue}))
    else
        local sidx, eidx, erates,rateNum
        if useCrystal then
            local _rate = SData.getData("djpeizhi",count+1).rate
            local _randomNum = context:nextRandom(100)
            if _randomNum<=_rate then
                rateNum = 2
            else
                rateNum = 1
            end
            -- erates = const.RatesDJCrystal
            -- local egroups = const.RatesGroupDJCrystal
            -- local egidx = 0
            -- while egroups[egidx+1] do
            --     egidx = egidx+1
            --     if egroups[egidx][1]>count or egroups[egidx][1]==0 then
            --         break
            --     end
            -- end
            -- sidx = egroups[egidx][2]
            -- eidx = egroups[egidx][3]
        else
            rateNum = 1
            -- erates = const.RatesDJBeercup
            -- sidx = 1
            -- eidx = KTLen(erates)
        end
        -- local mrate = 0
        -- for i=sidx, eidx do
        --     mrate = mrate+erates[i]
        -- end
        -- local erand = context:nextRandom(mrate)
        -- mrate = 0
        -- for i=sidx, eidx do
        --     mrate = mrate+erates[i]
        --     if mrate>erand then
                context:changeRes(ctype, -cvalue)
                GameLogic.statCrystalCost("宝石对酒消耗", ctype, -cvalue)
                context:changeRes(self.rtype, self.getNum*rateNum)
                GameEvent.sendEvent("refreshHeroAwakeEnsureDialog")
                if useCrystal then
                    if self.rtype == const.ResSpecial then
                        context:changeProperty(const.ProDJCount, 1)
                        context.activeData:finishAct(20)
                        -- 日常任务黑晶
                        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHuanSpecial, 1)
                    else
                        context:changeProperty(const.ProDJCount2, 1)
                        context.activeData:finishAct(21)
                        -- 日常任务勋章
                        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHuanZhanhun, 1)
                    end
                end
                context:addCmd({const.CmdBeerGet, self.rtype, (useCrystal and 1) or 0, (self.rtype==const.ResZhanhun and 1) or 0, GameLogic.getSTime()})
                self:showGetReward(rateNum)
                self:reloadDJCost()
                --break
            --end
        --end
    end
end

local _rateChatConfig = {1,2,4,7,11,15,0}
function BeercupDialog:showGetReward(rate)
    local rateChat = 1
    for i=1, #_rateChatConfig do
        if _rateChatConfig[i]<rate then
            rateChat = rateChat+1
        else
            break
        end
    end
    self.labelChatWord:setString(Localize("dataBeerWord" .. rateChat))
    local noticeWord = Localize("dataResName" .. self.rtype) .. "+" .. (self.getNum*rate)
    local withAni = false
    if rate>1 then
        noticeWord = Localizef("noticeRateGet",{rate=rate, name=noticeWord})
        withAni = true
    end
    display.pushNotice(noticeWord, {withAni=withAni})
end

function BeercupDialog:reloadDJCost()
    local context = self.context
    local count,cnum = self:getDJCrystalInfo()
    self:setDJResNum()
    self.labelBeercupNum:setString(context:getRes(const.ResBeercup))
    self.labelCrystalNum:setString(N2S(context:getRes(const.ResCrystal)))
    self.labelBeercupRTypeNum:setString(N2S(self.rbase))
    self.labelCrystalRTypeNum:setString(N2S(self.resNum))
    self.lbVipGet:setString(Localizef("labelCrystalNum",{a=self.maxTimes-count}))
    if cnum>0 then
        self.labelCrystalUseNum:setString(N2S(cnum))
    else
        self.labelCrystalUseNum:setString(Localize("labelFree"))
    end
    if cnum>context:getRes(const.ResCrystal) then
        self.labelCrystalUseNum:setColor(GConst.Color.Red)
    else
        self.labelCrystalUseNum:setColor(GConst.Color.White)
    end
    if 1>context:getRes(const.ResBeercup) then
        self.labelBeercupUseNum:setColor(GConst.Color.Red)
    else
        self.labelBeercupUseNum:setColor(GConst.Color.White)
    end
end
