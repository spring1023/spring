local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local HeroAwakeEnsureDialog = class(DialogViewLayout)

function HeroAwakeEnsureDialog:onInitDialog()
    self:setLayout("HeroAwakeEnsureDialog.json")
    self:loadViewsTo()

    self.title:setString(Localize("titleHeroAwaken"))
    self.btnAwake:setScriptCallback(ButtonHandler(self.onEnsureAwake, self))
    local bNode=ui.node()
    self.view:addChild(bNode)
    GameEvent.bindEvent(bNode,"refreshHeroAwakeEnsureDialog", self, self.refreshDialog)
end

function HeroAwakeEnsureDialog:refreshDialog()
    local parent = self.parent
    if parent and parent.onEnter then
        parent:onEnter()
    end
    self:onEnter()
end

function HeroAwakeEnsureDialog:onEnter()
    local hero = self.heroMsg
    local tlv = hero.awakeUp+1
    local awakeSkill = self.heroMsg:getAwakeSkill(tlv)
    self.labelLevel1:setString(Localizef("labelLevelFormat",{level=awakeSkill.level-1}))
    self.labelLevel2:setString(Localizef("labelLevelFormat",{level=awakeSkill.level}))
    local awakeSkill0 = awakeSkill
    -- if tlv>1 then
    --     awakeSkill0 = self.heroMsg:getAwakeSkill(tlv-1)
    -- end
    GameUI.addSkillIcon(self.nodeLevel1, 5, awakeSkill0.id, 1, 110, 109)
    GameUI.addSkillIcon(self.nodeLevel2, 5, awakeSkill.id, 1, 110, 109)
    self:reloadCosts()
end

local _heroNeed = {"hlv","ulv","star","mlv","slv"}
local _heroCost = {"special","zhanhun","medicine","fragment"}
function HeroAwakeEnsureDialog:reloadCosts()
    local context = self.context
    local hero = self.heroMsg
    local tlv = hero.awakeUp+1
    local cost = hero:getAwakeCost(tlv)
    if GameLogic.useTalentMatch then
        cost["ulv"] = 0
    end
    local canUpgrade = true
    local lvValue, maxValue, lvLabel, maxLabel
    local value1 = {hero.level,context:getInfoItem(const.InfoLevel),hero.starUp,hero.mSkillLevel,hero.soldierLevel}
    for idx, k in ipairs(_heroNeed) do
        lvValue, maxValue = value1[idx], cost[k]
        if maxValue==0 then
            self["nodeHeroNeed" .. idx]:setVisible(false)
        else
            self["nodeHeroNeed" .. idx]:setVisible(true)
            lvLabel, maxLabel = self["labelHeroNeed" .. idx], self["labelHeroNeedMax" .. idx]
            maxLabel:setString("/" .. tostring(maxValue))
            lvLabel:setString(tostring(lvValue))
            if lvValue<maxValue then
                lvLabel:setColor(GConst.Color.Red)
                canUpgrade = false
                if GameLogic.useTalentMatch then
                    --计算出所缺的英雄等级\星级\主动技能等级\佣兵等级, 并转化为宝石
                    self:reloadVacancy(k, lvValue, maxValue)
                end
            end
        end
    end
    local resIds = {const.ResSpecial, const.ResZhanhun, const.ResMedicine}
    for idx, k in ipairs(_heroCost) do
        --增加跳转
        if idx==1 then
            self["btnAdd" .. idx]:setScriptCallback(Script.createCallbackHandler(self.onBtnPlus,self,const.ResSpecial,cost[k]))
        elseif idx==2 then
            self["btnAdd" .. idx]:setScriptCallback(Script.createCallbackHandler(self.onBtnPlus,self,const.ResZhanhun,cost[k]))
        elseif idx==3 then
            self["btnAdd" .. idx]:setScriptCallback(Script.createCallbackHandler(self.onBtnPlus,self,const.ResMedicine,cost[k]))
        elseif idx==4 then
            self["btnAdd" .. idx]:setScriptCallback(function()
                display.showDialog(HeroMainDialog.new({initTag="extract"}))
            end)
        end
        maxValue = cost[k]
        if maxValue==0 then
            self["nodeHeroCost" .. idx]:setVisible(false)
        else
            self["nodeHeroCost" .. idx]:setVisible(true)
            lvLabel, maxLabel = self["labelHeroCost" .. idx], self["labelHeroCostMax" .. idx]
            if idx==4 then
                lvValue = context:getItem(const.ItemFragment, hero.hid)
                self.nodeHeroIcon:removeAllChildren(true)
                GameUI.addItemIcon(self.nodeHeroIcon,const.ItemFragment,hero.hid,3,0,0)
                -- GameUI.addHeadIcon(self.nodeHeroIcon,hero.hid,1,0,0,{lv = hero.awakeUp})
            else
                lvValue = context:getRes(resIds[idx])
            end
            maxLabel:setString("/" .. tostring(maxValue))
            lvLabel:setString(tostring(lvValue))
            if lvValue<maxValue then
                lvLabel:setColor(GConst.Color.Red)
                canUpgrade = false
            else
                lvLabel:setColor({49,48,49})
            end
            if GameLogic.useTalentMatch then
                --计算出所缺的黑晶\勋章\药水\碎片, 并转化为宝石(不缺则直接扣除)
                self:reloadVacancy(k, lvValue, maxValue)
            end
        end
    end
    if not canUpgrade and not GameLogic.useTalentMatch then
        self.btnAwake:setEnable(false)
        self.btnAwake:setGray(true)
    else
        self.btnAwake:setEnable(true)
        self.btnAwake:setGray(false)
    end
    self.canUpgrade = canUpgrade
end

function HeroAwakeEnsureDialog:reloadVacancy(vacancy, lvValue, maxValue)
    local price = 0
    local needNum = 0
    if not self.initOneKey then
        self.addHeroLv, self.addExp, self.addStar, self.addMainSkillLv, self.addSoliderLv,
        self.delSpecial, self.delZhanhun, self.delMedicine, self.delFragment, self.vacancy
        = 0,0,0,0,0,0,0,0,0,0
        self.initOneKey = true
    end
    if vacancy == "hlv" then
        price = 0.0444
        for i=lvValue,maxValue-1 do
            needNum = needNum + SData.getData("hlevels", 1, i).next
        end
        self.addHeroLv = maxValue - lvValue
        self.addExp = needNum
        self.vacancy = self.vacancy + needNum*price
    elseif vacancy == "star" then
        needNum = (maxValue - lvValue)*1500
        local rating = self.heroMsg.rating
        local displayColor = self.heroMsg.displayColor
        if rating == 3 then
            price = 1
        elseif rating == 4 and not displayColor then
            price = 10
        elseif rating == 4 and displayColor and displayColor == 5 then
            price = 50
        end
        self.addStar = maxValue - lvValue
        self.vacancy = self.vacancy + needNum*price
    elseif vacancy == "mlv" then
        price = 2.275
        needNum = SData.getData("mlevels", maxValue).total - SData.getData("mlevels", lvValue).total
        self.addMainSkillLv = maxValue - lvValue
        self.vacancy = self.vacancy + needNum*price
    elseif vacancy == "slv" then
        price = 0.0455
        needNum = SData.getData("slevels", maxValue).total - SData.getData("slevels", lvValue).total
        self.addSoliderLv = maxValue - lvValue
        self.vacancy = self.vacancy + needNum*price
    elseif vacancy == "special" then
        price = 2.275
        needNum = maxValue - lvValue
        if needNum > 0 then
            self.delSpecial = lvValue
            self.vacancy = self.vacancy + needNum*price
        else
            self.delSpecial = maxValue
        end
    elseif vacancy == "zhanhun" then
        price = 0.0455
        needNum = maxValue - lvValue
        if needNum > 0 then
            self.delZhanhun = lvValue
            self.vacancy = self.vacancy + needNum*price
        else
            self.delSpecial = maxValue
        end
    elseif vacancy == "medicine" then
        price = 10
        needNum = maxValue - lvValue
        if needNum > 0 then
            self.delMedicine = lvValue
            self.vacancy = self.vacancy + needNum*price
        else
            self.delMedicine = maxValue
        end
    elseif vacancy == "fragment" then
        needNum = maxValue - lvValue
        if needNum > 0 then
            self.delFragment = lvValue
            local rating = self.heroMsg.rating
            local displayColor = self.heroMsg.displayColor
            if rating == 3 then
                price = 1
            elseif rating == 4 and not displayColor then
                price = 10
            elseif rating == 4 and displayColor and displayColor == 5 then
                price = 50
            end
        else
            self.delFragment = maxValue
        end
    end
end

--[[
@brief: 觉醒时 + 按钮回调函数
@author: a0yu3@qq.com
@date: 2017 HappyChristmas
--]]
function HeroAwakeEnsureDialog:onBtnPlus(ctype,cvalue)
    local context = GameLogic.getUserContext()
    local userResource = context:getRes(ctype)
    if userResource < cvalue then
        display.showDialog(AlertDialog.new({ctype=ctype, cvalue=cvalue, callback=Handler(self.refreshDialog,self)}))
    elseif ctype == const.ResMedicine then
        StoreDialog.new({id=1,guideBuyMedicine=true})
    elseif ctype == const.ResZhanhun then
        StoreDialog.new({id=1,guideBuyZhanhun=true})
    elseif ctype == const.ResSpecial then
        StoreDialog.new({id=1,guideBuyBlack=true})
    else
        StoreDialog.new({id=1})
    end
end
function HeroAwakeEnsureDialog:onEnsureAwake()
    if self.canUpgrade then--直接觉醒
        local hero = self.heroMsg
        local context = self.context
        if context.heroData:awakeHero(hero) and not self.deleted then
            local parent = self.parent
            display.closeDialog(0)
            if parent and parent.onEnter then
                parent:onEnter(true)
            end
            if hero.awakeUp == 5 or hero.awakeUp == 10 or hero.awakeUp == 12 then
                GameLogic.doRateGuide("goldSkill", 7)
            end
        end
    elseif GameLogic.useTalentMatch then--需要用宝石补差额, 确认后再觉醒
        display.showDialog(AlertDialog.new(1,Localize("btnAwake"),Localizef("alertTextOneKeyAwake", {n = math.ceil(self.vacancy)}),
        {ctype=const.ResCrystal, cvalue=math.ceil(self.vacancy), callback=Handler(self.onEnsureAwake2, self, true)}))
    end
end

function HeroAwakeEnsureDialog:onEnsureAwake2()
    local hero = self.heroMsg
    local context = self.context
    --前端扣掉宝石,黑晶,勋章,基因药水,英雄碎片
    context:changeRes(const.ResCrystal, -math.ceil(self.vacancy))
    context:changeRes(const.ResSpecial, -self.delSpecial)
    context:changeRes(const.ResZhanhun, -self.delZhanhun)
    context:changeRes(const.ResMedicine, -self.delMedicine)
    context:changeItem(const.ItemFragment, hero.hid, -self.delFragment)
    --升级,升星,升技能,升佣兵
    context.heroData:upgradeSoldier(hero, {type = "oneKey", addSoliderLv = self.addSoliderLv})
    local us = {exp=self.addExp, num=0, star=self.addStar, heros={}}
    context.heroData:upgradeHero(hero, us, {type = "oneKey", addExp = self.addExp, addHeroLv = self.addHeroLv,
        addStar = self.addStar})
    context.heroData:upgradeMainSkill(hero, {type = "oneKey", addMainSkillLv = self.addMainSkillLv})
    if context.heroData:awakeHero(hero, {type = "oneKey", vacancyRes = {{const.ResCrystal, math.ceil(self.vacancy)},
        {const.ResSpecial, self.delSpecial}, {const.ResZhanhun, self.delZhanhun}, {const.ResMedicine, self.delMedicine},
        {const.ItemFragment, self.delFragment}}}) and not self.deleted then
        local parent = self.parent
        display.closeDialog(0)
        if parent and parent.onEnter then
            parent:onEnter(true)
        end
        if hero.awakeUp == 5 or hero.awakeUp == 10 or hero.awakeUp == 12 then
            GameLogic.doRateGuide("goldSkill", 7)
        end
    end
end

HeroAwakeDetailsDialog = class(DialogViewLayout)

function HeroAwakeDetailsDialog:onInitDialog()
    self:setLayout("HeroAwakeDetailsDialog.json")
    self:loadViewsTo()

    self.title:setString(Localize("titleAwakeDetails"))
    self.questionBut:setVisible(false)
end

function HeroAwakeDetailsDialog:onEnter()
    self.nodeScrollBack:removeAllChildren(true)
    local infos = self.heroMsg:getAwakedSkills()
    local tableView = ui.createTableView(self.nodeScrollBack.size, false, {cellActionType=0, size=cc.size(1765, 205), offx=10, offy=10, disx=0, disy=47, rowmax=1, infos=infos, cellUpdate=Handler(self.updateDetailsCell, self)})
    display.adapt(tableView.view, 0, 0, GConst.Anchor.LeftBottom)
    self.nodeScrollBack:addChild(tableView.view,5)
    self.tableView = tableView
end

function HeroAwakeDetailsDialog:updateDetailsCell(cell, tableView, info)
    if not info.viewLayout then
        info.viewLayout = self:addLayout("detailsCell", cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
    end
    info.nodeSkillIcon:removeAllChildren(true)
    if info.id == 403102 or info.id == 4031202 then
        if self.heroMsg.heroState == 0 then
            info.id = 4031202
        else
            info.id = 403102
        end
    end
    local temp = GameUI.addSkillIcon(info.nodeSkillIcon, 5, info.id, 0.98, 0, 6)
    if info.level==0 then
        info.labelNotLearn:setVisible(true)
        info.labelSkillName:setVisible(false)
        info.labelSkillDesc:setVisible(false)
        temp:setSValue(-100)
    else
        info.labelNotLearn:setVisible(false)
        info.labelSkillName:setVisible(true)
        info.labelSkillDesc:setVisible(true)
        info.labelSkillName:setString(info.name)
        if info.id == 403102 or info.id == 4031202 then
            if self.heroMsg.heroState == 0 then
                local ad = GMethod.loadScript("data.StaticData").getData("adatas", 40312, self.heroMsg.awakeUp)
                info.info = StringManager.getFormatString("dataSkillInfo5_4031202", ad)
            else
                local ad = GMethod.loadScript("data.StaticData").getData("adatas", 4031, self.heroMsg.awakeUp)
                info.info = StringManager.getFormatString("dataSkillInfo5_403102", ad)
            end
        end
        info.labelSkillDesc:setString(info.info)
    end
end

HeroAwakeDialog = class(DialogViewLayout)

local _awakeLvPos = {{379+43,713+43},{529+43, 846+43},{313+43, 1187+43},{581+43, 1146+43},{707+43, 993+43},{894+43, 1045+43},{923+43, 681+43},{1125+43, 976+43},{1216+43, 1111+43},{1503+43, 1189+43},{1394+43, 869+43},{1684+43, 687+43}}
function HeroAwakeDialog:onInitDialog()
    self:setLayout("HeroAwakeDialog.json")
    self:loadViewsTo()


    local bg, temp = self.view
    self.title:setString(Localize("titleHeroAwake"))
    temp = self.nodeResBack.view
    GameUI.addItemBack(temp,3,0.788,78,78)
    GameUI.addResourceIcon(temp,const.ResMedicine,1.3,78,78)

    self.lvIcons = {}
    for i=1, const.MaxAwakeLevel do
        local posx=_awakeLvPos[i][1]
        local posy=_awakeLvPos[i][2]
        temp = ui.button({109, 111}, Handler(self.selectAwakeLv, self, i), {image="images/heroAwakeLvBack.png",actionType=0})
        display.adapt(temp, posx, posy, GConst.Anchor.Center)
        bg:addChild(temp,1)
        temp = ui.sprite("images/heroAwakeLv" .. i .. ".png",{86, 86})
        display.adapt(temp, posx, posy+4, GConst.Anchor.Center)
        bg:addChild(temp,2)
        temp:setSValue(-100)
        self.lvIcons[i] = temp
        if i<const.MaxAwakeLevel then
            local endposx=_awakeLvPos[i+1][1]
            local endposy=_awakeLvPos[i+1][2]
            local ox=endposx-posx
            local oy=endposy-posy
            local leng=math.sqrt(ox^2+oy^2)
            local r=math.deg(math.atan2(oy,ox))
            temp = ui.sprite("images/heroAwakeLvLine.png",{leng, 74})
            display.adapt(temp, posx, posy, GConst.Anchor.Left)
            bg:addChild(temp)
            temp:setRotation(-r)
        end
    end
    GameLogic.getJumpGuide(const.JumpTypeWake,self.butAwake,140,80)
    self.butAwake:setScriptCallback(ButtonHandler(self.onAwake, self))
    self.butLeft:setScriptCallback(ButtonHandler(self.onChangeAwake, self, -1))
    self.butRight:setScriptCallback(ButtonHandler(self.onChangeAwake, self, 1))
    self.butAddNum:setScriptCallback(ButtonHandler(StoreDialog.new, {id=1,labelMedicineNum=self.labelNum}))
    self.butDetails:setScriptCallback(ButtonHandler(self.onDetails, self))
end

function HeroAwakeDialog:onDetails()
    display.showDialog(HeroAwakeDetailsDialog.new({parent=self, context=self.context, heroMsg=self.heroMsg}))
end

function HeroAwakeDialog:onEnter(isUp)
    if not self.heroMsg.heroState then
        self.heroMsg.heroState = 0
    end
    self:reloadMedicines()
    local alv = self.heroMsg.awakeUp+1
    for lv,icon in ipairs(self.lvIcons) do
        if lv<alv then
            icon:setSValue(0)
        else
            icon:setSValue(-100)
        end
    end
    if alv>const.MaxAwakeLevel then
        alv = const.MaxAwakeLevel
    end
    self:selectAwakeLv(alv)
    self:reloadAwakedSkills()
    if isUp then
        if self.parent and not self.parent:getDialog().deleted then
            self.parent:reloadHeroAwake()
            self.parent:reloadAll()
        end
        if not self.deleted then
            music.play("sounds/mercenary_upgrade.mp3")
            UIeffectsManage:showEffect_jinengshenji(self.nodeSkillIcon.view,96,76,0.9)
        end
    end
    self.questionTag = "dataQuestionHeroAwake"
end

function HeroAwakeDialog:reloadMedicines()
    self.labelNum:setString(N2S(self.context:getRes(const.ResMedicine)))
end

function HeroAwakeDialog:reloadAwakeLv()
    local lv = self.slv
    local clv = self.heroMsg.awakeUp
    self.labelAwakeLevel:setString(Localize("dataAwakeLv" .. lv))
    self.labelNoticeLock:setVisible(lv>clv)
    self.butAwake:setEnable(lv == clv+1)
    self.butAwake:setGray(lv ~= clv+1)
    self.butAwake:setVisible(lv>clv)
    local awakeSkill = self.heroMsg:getAwakeSkill(lv)
    if self.skillIcon then
        self.skillIcon:removeFromParent(true)
        self.skillIcon = nil
    end
    if self.heroMsg.hid == 4031 then
        if self.heroMsg.heroState == 0 then
            local ad = GMethod.loadScript("data.StaticData").getData("adatas",40312,lv)
            local info = StringManager.getFormatString("dataSkillInfo5_" .. ad.skill, ad)
            self.skillIcon = GameUI.addSkillIcon(self.nodeSkillIcon.view, 5, ad.skill, 0.81, 96, 96)
            self.textSkillDesc:setString(info)
        else
            local ad = GMethod.loadScript("data.StaticData").getData("adatas",4031,lv)
            local info = StringManager.getFormatString("dataSkillInfo5_" .. ad.skill, ad)
            self.skillIcon = GameUI.addSkillIcon(self.nodeSkillIcon.view, 5, ad.skill, 0.81, 96, 96)
            self.textSkillDesc:setString(info)
        end
    else
        self.skillIcon = GameUI.addSkillIcon(self.nodeSkillIcon.view, 5, awakeSkill.id, 0.81, 96, 96)
        self.textSkillDesc:setString(awakeSkill.info)
    end
    self.labelSkillName:setString(awakeSkill.name)
    self.labelSkillLv:setString(Localizef("labelLevelFormat",{level=awakeSkill.level}))
    if awakeSkill.levelUp>0 then
        self.labelSkillEffect:setString(Localizef("labelHeroLevelUp",{level=awakeSkill.levelUp}))
        self.labelSkillEffect:setVisible(true)
    else
        self.labelSkillEffect:setVisible(false)
    end
end

function HeroAwakeDialog:selectAwakeLv(lv)
    self.slv = lv
    self.butLeft:setVisible(lv>1)
    self.butRight:setVisible(lv<const.MaxAwakeLevel)
    self:reloadAwakeLv()
    if not self.selectedGrid then
        self.selectedGrid = ui.node(nil, true)
        local control = EffectControl.new("heroAwakeSelected.json")
        control:addEffect(self.selectedGrid)
        self.view:addChild(self.selectedGrid, 3)
    end
    local posx=_awakeLvPos[lv][1]
    local posy=_awakeLvPos[lv][2]
    self.selectedGrid:setPosition(posx, posy)
end

function HeroAwakeDialog:onChangeAwake(change)
    local slv = self.slv+change
    if slv>=1 and slv<=const.MaxAwakeLevel then
        self:selectAwakeLv(slv)
    end
end

function HeroAwakeDialog:reloadAwakedSkills()
    if self.awakedNode then
        self.awakedNode:removeFromParent(true)
        self.awakedNode = nil
    end
    local bg, temp = self.view
    self.awakedNode = ui.node(nil, true)
    bg:addChild(self.awakedNode)
    bg = self.awakedNode
    local awakedSkills = self.heroMsg:getAwakedSkills()
    for i, askill in ipairs(awakedSkills) do
        if askill.id == 403102 or askill.id == 4031202 then
            if self.heroMsg.heroState == 1 then
                askill.id = 403102
            else
                askill.id = 4031202
            end
        end
        temp = GameUI.addSkillIcon(bg, 5, askill.id, 0.81, 1219+212*((i-1)%4), 348-(math.ceil(i/4)-1)*192)
        if askill.level==0 then
            temp:setSValue(-100)
        end
        temp = ui.label(Localizef("labelLevelFormat",{level=askill.level}), General.font1, 44)
        display.adapt(temp, 1219+212*((i-1)%4), 290-(math.ceil(i/4)-1)*192, GConst.Anchor.Center)
        bg:addChild(temp)
    end
end

function HeroAwakeDialog:onAwake()
   GameLogic.removeJumpGuide(const.JumpTypeWake)
    local lv = self.slv
    local clv = self.heroMsg.awakeUp
    if lv == clv+1 then
        display.showDialog(HeroAwakeEnsureDialog.new({parent=self, context=self.context, heroMsg=self.heroMsg}))
    end
end

function HeroAwakeDialog:canExit()
    if self.callback then
        self.callback()
    end
    return true
end
