local const = GMethod.loadScript("game.GameLogic.Const")

local UnionPetsUpgradeDialog = class(DialogViewLayout)

function UnionPetsUpgradeDialog:onInitDialog()
    self:setLayout("UnionPetsUpgradeDialog.json")
    self:loadViewsTo()
    self.title:setString(Localize("titleUnionPets"))
    GameUI.addAngerUp(self.nodeBoxProcessUp.view, self.nodeBoxProcessUp.size[1], self.nodeBoxProcessUp.size[2], 0, 0)

    self.btnFeedByGold:setScriptCallback(ButtonHandler(self.onFeedPets, self, 1))
    self.btnFeedByCrystal:setScriptCallback(ButtonHandler(self.onFeedPets, self, 0))
    self.btnBoxReward:setScriptCallback(ButtonHandler(self.onBoxReward, self))
end

function UnionPetsUpgradeDialog:onEnter()
    self.labelContributionGold:setString(Localizef("labelGetContributionValue",{num=const.UPGetByGold}))
    self.labelContributionCrystal:setString(Localizef("labelGetContributionValue",{num=const.UPGetByCrystal}))
    self.labelUseCrystalValue:setString(N2S(const.PriceUPCrystal))
    self:reloadRes()
end

function UnionPetsUpgradeDialog:onFeedPets(mode)
    if GameNetwork.checkRequest() then
        return
    end
    local ctype
    local cvalue
    if mode==1 then
        local chance = self.context:getProperty(const.ProPetNum)
        local ptime = self.context:getProperty(const.ProPetTime)
        if ptime<GameLogic.getToday() then
            chance = 0
        end
        cvalue = 0
        if chance<const.MaxUPGoldChance then
            cvalue = (chance+1)*const.PriceUPGold
        else
            display.pushNotice(Localize("noticeFeedNoChance"))
            return
        end
        ctype = const.ResGold
    else
        ctype = const.ResCrystal
        cvalue = const.PriceUPCrystal
    end
    if cvalue>self.context:getRes(ctype) then
        local dialog = AlertDialog.new({ctype=ctype, cvalue=cvalue, callback=Handler(self.onFeedPets, self, mode)})
        if not dialog.deleted then
            display.showDialog(dialog)
        end
        return
    end
    if GameNetwork.lockRequest() then
        --提前扣免得其他逻辑出错
        self.context:changeRes(ctype, -cvalue)
        GameLogic.statCrystalCost("神兽喂养消耗",ctype, -cvalue)
        GameNetwork.request("upetsfeed", {petslvup={mode, 0}}, self.onResponseFeedPets, self, mode)
    end
end

function UnionPetsUpgradeDialog:onResponseFeedPets(mode, suc, data)
    GameNetwork.unlockRequest()
    if suc then
        --被踢出联盟
        if data.code and data.code==3 then
            display.pushNotice(Localize("noticeOutLeague"))
            return
        end
        --达到等级上限
        if data.code and data.code==2 then
            display.pushNotice(Localize("labelLevelMax"))
            return
        end
        local boxGet
        local gxGet
        if mode==1 then
            boxGet = const.UPBoxByGold
            gxGet = const.UPGetByGold
            local ptime = self.context:getProperty(const.ProPetTime)
            if ptime<GameLogic.getToday() then
                self.context:setProperty(const.ProPetNum, 1)
            else
                self.context:changeProperty(const.ProPetNum, 1)
            end
            self.context:setProperty(const.ProPetTime, GameLogic.getSTime())
        else
            boxGet = const.UPBoxByCrystal
            gxGet = const.UPGetByCrystal
        end
        self.context:changeProperty(const.ProLBox, boxGet)
        self.context:changeProperty(const.ProGXun, gxGet)
        self.pets.level = data.plv
        self.pets.exp = data.pexp
        if not self.deleted then
            self:reloadRes()
        end
        if self.parent and not self.parent:getDialog().deleted then
            self.parent:reloadPetsInfo()
        end
        display.pushNotice(Localizef("noticeFeedSecess",{num=gxGet}))
        music.play("sounds/heroExt_music.wav")
        --日常任务喂养神兽
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeFeedPet,1)
    else
        --如果失败了，把花掉的加回来
        local ctype
        local cvalue
        if mode==1 then
            local chance = self.context:getProperty(const.ProPetNum)
            local ptime = self.context:getProperty(const.ProPetTime)
            if ptime<GameLogic.getToday() then
                chance = 0
            end
            cvalue = (chance+1)*const.PriceUPGold
            ctype = const.ResGold
        else
            ctype = const.ResCrystal
            cvalue = const.PriceUPCrystal
        end
        self.context:changeRes(ctype, cvalue)
        GameLogic.statCrystalCost("神兽喂养消耗",ctype, -cvalue)
    end
end

function UnionPetsUpgradeDialog:reloadRes()
    self.labelGoldNum:setString(N2S(self.context:getRes(const.ResGold)))
    self.labelCrystalNum:setString(N2S(self.context:getRes(const.ResCrystal)))
    
    local hero = self.context.heroData:makeHero(8010)
    hero.level = self.pets.level
    hero.exp = self.pets.exp
    local nexp = hero:getNextExp()
    local exp = hero.exp
    self.labelUnionPetsLv:setString(hero.level .. "/" .. hero.maxLv)
    if nexp<=exp then
        nexp = exp
        if nexp==0 then
            nexp = 1
            exp = 1
        end
        self.expLabel:setString(Localize("labelLevelMax"))
    else
        self.expLabel:setString(exp .. "/" .. nexp)
    end
    self.expProcess:setProcess(true, exp/nexp)
    local chance = self.context:getProperty(const.ProPetNum)
    local ptime = self.context:getProperty(const.ProPetTime)
    if ptime<GameLogic.getToday() then
        chance = 0
    end
    local price = 0
    if chance<const.MaxUPGoldChance then
        price = (chance+1)*const.PriceUPGold
        self.btnFeedByGold:setGray(false)
    else
        self.btnFeedByGold:setGray(true)
    end
    self.labelUseGoldValue1:setString(N2S(price))
    self.labelUseGoldValue2:setString(chance .. "/" .. const.MaxUPGoldChance)
    local box = self.context:getProperty(const.ProLBox)
    local bmax = const.MaxUPBoxExp
    local bnmax = const.MaxUPBoxNum
    local bexp, bnum = 0, 0
    if box>=bmax*bnmax then
        bexp = bmax
        bnum = bnmax
    else
        bexp = box%bmax
        bnum = (box-bexp)/bmax
    end
    self.boxProcess:setProcess(true, bexp/bmax)
    self.labelBoxsNum:setString("x" .. bnum)
    if self.effNode_up and self.effNode_down then
        self.effNode_up:removeFromParent(true)
        self.effNode_down:removeFromParent(true)
        self.effNode_up=nil
        self.effNode_down=nil
    end
    if bnum>0 then
        self.effNode_up,self.effNode_down=UIeffectsManage:showEffect_BaoXiangT(self.view,1067+72,27+70)
    end
end

function UnionPetsUpgradeDialog:onBoxReward()
    local box = self.context:getProperty(const.ProLBox)
    local bmax = const.MaxUPBoxExp
    local bnmax = const.MaxUPBoxNum
    local bexp, bnum = 0, 0
    if box>=bmax*bnmax then
        bexp = bmax
        bnum = bnmax
    else
        bexp = box%bmax
        bnum = (box-bexp)/bmax
    end
    if bnum==0 then
        display.pushNotice(Localize("noticeBoxEmpty"))
    elseif GameNetwork.lockRequest() then
        GameNetwork.request("upetsbox",nil,self.onResponseBoxReward, self)
    end
end

function UnionPetsUpgradeDialog:onResponseBoxReward(suc, data)
    GameNetwork.unlockRequest()
    if suc then
        GameLogic.addRewards(data)
        GameLogic.statCrystalRewards("神兽升级宝箱奖励",data)
        local box = self.context:getProperty(const.ProLBox)
        self.context:setProperty(const.ProLBox, box%const.MaxUPBoxExp)
        if not self.deleted then
            self:reloadRes()
        end
        display.showDialog(RewardDialog.new({rewards=data}),false,true)
    end
end
return UnionPetsUpgradeDialog
