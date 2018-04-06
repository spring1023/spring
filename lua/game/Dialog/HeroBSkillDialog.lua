local const = GMethod.loadScript("game.GameLogic.Const")

HeroBSkillDialog = class()

local skillButPos = {{721, 1038}, {452, 1038}, {265, 849}, {265, 586}, {452, 401}, {721, 401}, {904, 586}, {904, 849}}
function HeroBSkillDialog:ctor(parent, context, heroMsg, bskillIdx)--英雄技能对话框
    self.parent = parent
    self.context = context
    self.heroMsg = heroMsg
    self.bskillIdx = bskillIdx

    local dialogDepth = display.getDialogPri()+1
    DialogTemplates.loadDefaultTemplate(self, 4, dialogDepth)
    self.title:setString(Localize("titleHeroBSkill"))
    self.questionBut:setScriptCallback(ButtonHandler(self.onQuestion, self))

    local bg,temp=self.view
    local bNode=ui.node()
    bg:addChild(bNode)
    local bNode2=ui.node()
    bg:addChild(bNode2)

    RegLife(bNode, Handler(self.onLifeCycle, self))
    GameEvent.bindEvent(bNode2, "refreshBSkillUI", self, self.refreshUI)

    temp = ui.sprite("images/heroBSkillBack.png",{1087, 1269})
    display.adapt(temp, 48, 74, GConst.Anchor.LeftBottom)
    bg:addChild(temp, 1)

    local bskills = {}
    for i, pos in ipairs(skillButPos) do
        temp = ui.button({166, 166}, self.selectBSkill, {cp1=self, cp2=i, actionType=2})
        display.adapt(temp, pos[1], pos[2], GConst.Anchor.Center)
        bg:addChild(temp)
        bskills[i] = {but=temp, image=nil}
        temp = ui.label("", General.font1, 53, {color={255,255,255}})
        display.adapt(temp, pos[1], pos[2]-118, GConst.Anchor.Center)
        bg:addChild(temp, 3)
        bskills[i].label = temp
    end
    self.bskills = bskills
    temp = ui.button({223, 229}, self.onRandomLightBSkill, {cp1=self, actionType=2, image="images/btnHeroMethod.png", scale9edge={55,96,63,63}})
    display.adapt(temp, 584, 715, GConst.Anchor.Center)
    bg:addChild(temp,2)
    self.lightBut = temp
    local but=temp:getDrawNode()
    temp = ui.label(Localize("btnRandomLight"), General.font1, 40, {color={255,255,255},width=220,align=GConst.Align.Center})
    display.adapt(temp, 111, 174, GConst.Anchor.Center)
    but:addChild(temp)
    self.lightLabel=temp
    temp = ui.label("", General.font1, 50, {color={255,255,255}})
    display.adapt(temp, 131, 87, GConst.Anchor.Right)
    but:addChild(temp)
    self.lightPriceLabel = temp
    self.resIcon=GameUI.addResourceIcon(but, const.ResCrystal, 0.66, 174, 87)

    temp = ui.label(Localize("labelRefreshBSkills"), General.font1, 40, {color={255,255,255}})
    display.adapt(temp, 901, 296, GConst.Anchor.Bottom)
    bg:addChild(temp, 2)
    temp = ui.button({265, 104}, self.onRefreshBSkills, {cp1=self, image="images/btnOrange.png"})
    display.adapt(temp, 901, 241, GConst.Anchor.Center)
    bg:addChild(temp, 2)
    but=temp:getDrawNode()
    temp = ui.label("", General.font1, 50, {color={255,255,255}})
    display.adapt(temp, 130, 62, GConst.Anchor.Center)
    but:addChild(temp)
    self.btnStyle = but
    self.refreshPriceLabel = temp

    local banners = {}
    for i=1, 2 do
        local offx, offy = 1141, i*561-323
        local banner = {offx=offx, offy=offy}
        temp = ui.sprite("images/heroBackGrayAlpha.png",{866, 418})
        display.adapt(temp, offx+9, offy-2, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.sprite("images/dialogTabBackSmall1.png",{398, 114})
        display.adapt(temp, offx+9, offy+412, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.sprite("images/dialogBackSmallYellow.png",{855, 395})
        display.adapt(temp, offx+9, offy+19, GConst.Anchor.LeftBottom)
        bg:addChild(temp)
        temp = ui.label("", General.font2, 53, {color={49,48,49}, fontW=530, fontH = 80})
        display.adapt(temp, offx+287, offy+337, GConst.Anchor.LeftTop)
        bg:addChild(temp)
        banner.name = temp
        temp = ui.label("", General.font2, 30, {color={30,91,165},width=533,align=GConst.Align.Left})
        display.adapt(temp, offx+288, offy+247, GConst.Anchor.LeftTop)
        bg:addChild(temp)
        banner.info = temp
        temp = ui.label("", General.font1, 53, {color={255,255,255}})
        display.adapt(temp, offx+274, offy+128, GConst.Anchor.Right)
        bg:addChild(temp, 1)
        banner.level = temp
        temp = ui.label("", General.font1, 45, {color={255,255,255}, align=GConst.Align.Left, fontW = 340, fontH = 86})
        display.adapt(temp, offx+184, offy+467, GConst.Anchor.Center)
        bg:addChild(temp)
        banner.title = temp
        banners[i] = banner
    end
    self.banners = banners
    temp = ui.button({350, 142}, self.onChangeBSkill, {cp1=self, image="images/btnGreen.png"})
    display.adapt(temp, 1783, 146, GConst.Anchor.Center)
    bg:addChild(temp)
    self.changeBut = temp
    but=temp:getDrawNode()
    temp = ui.label(Localize("btnChangeBSkill"), General.font1, 40, {color={255,255,255}, fontW = 340, fontH = 76})
    display.adapt(temp, 175, 85, GConst.Anchor.Center)
    but:addChild(temp)

    temp = ui.button({350, 142},self.gotoSpecialSkill,{cp1=self,image="images/btnOrange.png"})
    display.adapt(temp, 1783, 725, GConst.Anchor.Center)
    bg:addChild(temp)
    but=temp:getDrawNode()
    temp = ui.label(Localize("btnSpecailSop"), General.font1, 40, {color={255,255,255}})
    display.adapt(temp, 175, 85, GConst.Anchor.Center)
    but:addChild(temp)

    banners[1].title:setString(Localize("labelSelectedBSkill"))
    banners[2].title:setString(Localize("labelCurrentBSkill"))
    
    self:changeBtnStyle()
    self:reloadAll()
end

function HeroBSkillDialog:changeBtnStyle()
    local _type,_num = self:checkRefreshStoneNum()
    self.refreshPriceLabel:setString(N2S(_num))
    if self.styleIcon then
        self.styleIcon:removeFromParent(true)
        self.styleIcon = nil
    end
    if _type == const.ResCrystal then
        self.styleIcon = GameUI.addResourceIcon(self.btnStyle, _type, 0.66, 219, 62)
    else
        self.styleIcon = GameUI.addItemIcon(self.btnStyle, _type, 1, 0.44, 219, 62, false, false)
    end
    if _type == const.ResCrystal then
        if _num>self.context:getRes(_type) then
            ui.setColor(self.refreshPriceLabel, GConst.Color.Red)
        else
            ui.setColor(self.refreshPriceLabel, GConst.Color.White)
        end
    end
end

function HeroBSkillDialog:checkRefreshStoneNum()

    local _rsNum = GameLogic.getUserContext():getItem(const.ItemRefreshStone,1)
    if _rsNum > 0 then
        return const.ItemRefreshStone,const.BSkillRefreshStone
    else
        return const.ResCrystal,const.BSkillRefreshCost
    end
end
function HeroBSkillDialog:gotoSpecialSkill()
    -- body
    display.showDialog(HeroSpecialWash.new({parent = self,hero =self.heroMsg,bskill = self.bskillIdx ,idx = self.curIdx}))
end

function HeroBSkillDialog:reloadSkillItem(hero, item, bskill)
    item.label:setString(bskill.level .. "/" .. hero:getTalentSkillMax(bskill.id))
    if item.image then
        item.image:removeFromParent(true)
        item.image = nil
    end
    item.image = GameUI.addSkillIcon(item.but:getDrawNode(), 3, bskill.id, 0.86, 83, 83)
    if bskill.state==0 then
        item.image:setSValue(-100)
    end
end

function HeroBSkillDialog:reloadBanner(hero, banner, bskill)
    banner.name:setString(hero:getTalentSkillName(bskill.id))
    banner.info:setString(hero:getTalentSkillInfo(bskill.id, bskill.level))
    banner.level:setString(bskill.level .. "/" .. hero:getTalentSkillMax(bskill.id))
    if banner.image then
        banner.image:removeFromParent(true)
        banner.image = nil
    end
    banner.image = GameUI.addSkillIcon(self.view, 3, bskill.id, 1.1, banner.offx+150, banner.offy+211)
    if bskill.state==0 then
        banner.image:setSValue(-100)
    end
end

function HeroBSkillDialog:selectBSkill(selectIdx)
    self.selectIdx = selectIdx
    local hero = self.heroMsg
    local bskill = hero.bskills[self.bskillIdx]
    local newBSkill = bskill.lights[selectIdx]
    self:reloadBanner(hero, self.banners[1], newBSkill)
    if not self.selectImage then
        self.selectImage = ui.sprite("images/heroBSkillSelect.png",{325, 325})
        self.view:addChild(self.selectImage, 2)
    end
    if newBSkill.state==0 then
        self.selectImage:setVisible(false)
        self.changeBut:setGray(true)
    else
        self.selectImage:setVisible(true)
        if selectIdx==bskill.curLight then
            self.changeBut:setGray(true)
        else
            self.changeBut:setGray(false)
        end
        display.adapt(self.selectImage, skillButPos[selectIdx][1], skillButPos[selectIdx][2], GConst.Anchor.Center)
    end
end

function HeroBSkillDialog:reloadAll()
    local hero = self.heroMsg
    local bskill = hero.bskills[self.bskillIdx]
    local lights = bskill.lights
    for i, skillItem in ipairs(self.bskills) do
        self:reloadSkillItem(hero, skillItem, lights[i])
    end
    self:reloadBanner(hero, self.banners[2], bskill)
    if not self.selectIdx then
        if bskill.curLight==0 then
            self.selectIdx = 1
        else
            self.selectIdx = bskill.curLight
        end
    end
    self.curIdx = self.selectIdx
    self:selectBSkill(self.selectIdx)
    self:refreshLightBut()
end

function HeroBSkillDialog:refreshLightBut()
    local lightNum = self:countLightNum()
    local lightCost
    if lightNum==8 then
        self.lightBut:setGray(true)
        self.lightPriceLabel:setVisible(false)
        self.resIcon:setVisible(false)
        self.lightLabel:setString(Localize("btnAllLight"))
        self.lightLabel:setPositionY(115)
    else
        self.lightBut:setGray(false)
        self.lightPriceLabel:setVisible(true)
        self.resIcon:setVisible(true)
        lightCost = const.BSkillLightCost[lightNum+1]
        self.lightPriceLabel:setString(N2S(lightCost))
        self.lightLabel:setString(Localize("btnRandomLight"))
        self.lightLabel:setPositionY(174)
    end
    self:refreshCost(lightCost)
end

function HeroBSkillDialog:refreshCost(lightCost)
    if not lightCost or lightCost>self.context:getRes(const.ResCrystal) then
        ui.setColor(self.lightPriceLabel, GConst.Color.Red)
    else
        ui.setColor(self.lightPriceLabel, GConst.Color.White)
    end
    self:changeBtnStyle()
    -- if const.BSkillRefreshCost>self.context:getRes(const.ResCrystal) then
    --     ui.setColor(self.refreshPriceLabel, GConst.Color.Red)
    -- else
    --     ui.setColor(self.refreshPriceLabel, GConst.Color.White)
    -- end
end

function HeroBSkillDialog:countLightNum()
    local hero = self.heroMsg
    local bskill = hero.bskills[self.bskillIdx]
    local lights = bskill.lights
    local lightNum = 0
    for i, skillItem in ipairs(self.bskills) do
        if lights[i].state>0 then
            lightNum = lightNum+1
        end
    end
    return lightNum
end
function HeroBSkillDialog:onRandomLightBSkill(force)
    if self.inRequest then
        return
    end
    local lightNum = self:countLightNum()
    if lightNum==8 then
        return
    else
        local cost = const.BSkillLightCost[lightNum+1]
        if not force then
            display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"), Localizef("alertTextLightBSkill",{num=cost}),{ctype=const.ResCrystal, cvalue=cost, callback=Handler(self.onRandomLightBSkill, self, true)}))
            return
        elseif cost>self.context:getRes(const.ResCrystal) then
            display.showDialog(AlertDialog.new({ctype=const.ResCrystal, cvalue=cost}))
        else
            if GameNetwork.lockRequest() then
                self.inRequest = true
                GameLogic.dumpCmds(true)
                GameNetwork.request("blight", {hidx=self.heroMsg.idx, bidx=self.bskillIdx}, self.onBSkillLightOver, self)
            end
        end
    end
end

function HeroBSkillDialog:onBSkillLightOver(suc, data)
    GameNetwork.unlockRequest()
    self.inRequest = nil
    if suc then
        local context = self.context
        context:changeRes(const.ResCrystal, -data.cost)
        GameLogic.statCrystalCost("英雄被动技能点亮消耗",const.ResCrystal, -data.cost)
        local hidx = data.hidx
        local bidx = data.bidx
        local hero = context.heroData:getHero(hidx)
        local orderId = data.bskill[1]
        local bskill = data.bskill[2]
        hero:setBSkill(bidx, orderId, bskill, 1)
        if not self.deleted and hero==self.heroMsg then
            local function callShow()
                self:reloadSkillItem(hero, self.bskills[orderId], hero.bskills[bidx].lights[orderId])
                self:selectBSkill(orderId)
                self:refreshLightBut()
            end
            --洗炼特效
            music.play("sounds/mrxbReward.wav")
            UIeffectsManage:showEffect_beidongxilian(1,self.view,584,715,orderId)
            self.view:runAction(ui.action.sequence({{"delay",0.3},{"call",callShow}}))
        end
    end
end

function HeroBSkillDialog:onRefreshBSkills(force)
    if self.inRequest then
        return
    end
    local _type,cost = self:checkRefreshStoneNum()
    self.curType = _type
    local _isStone = false
    if _type == const.ItemRefreshStone then
        _isStone = true
    end
    if (not force) and (not _isStone) then
        display.showDialog(AlertDialog.new(1, Localize("alertTitleRefreshBSkill"), Localizef("alertTextRefreshBSkill",{num=cost}),{ctype=_type, cvalue=cost, callback=Handler(self.onRefreshBSkills, self, true)}))
        return
    elseif (not _isStone) and (cost>self.context:getRes(_type)) then
        display.showDialog(AlertDialog.new({ctype=_type, cvalue=cost}))
    else
        if GameNetwork.lockRequest() then
            self.inRequest = true
            GameLogic.dumpCmds(true)
            GameNetwork.request("bchange", {hidx=self.heroMsg.idx, bidx=self.bskillIdx,isStone = _isStone}, self.onBSkillRefreshOver, self)
        end
    end
end

function HeroBSkillDialog:onBSkillRefreshOver(suc, data)
    GameNetwork.unlockRequest()
    self.inRequest = nil
    if suc then
        music.play("sounds/heroBkillFlash.mp3")
        UIeffectsManage:showEffect_beidongxilian(2,self.view,584,715,0)
        local context = self.context
        if self.curType == const.ResCrystal then
            --用钻石刷新
            context:changeRes(const.ResCrystal, -data.cost) 
            GameLogic.statCrystalCost("英雄被动技能刷新消耗",const.ResCrystal, -data.cost)
        else
            --用刷新石刷新
            context:changeItem(const.ItemRefreshStone,1,-data.cost) 
        end
        local hidx = data.hidx
        local bidx = data.bidx
        local hero = context.heroData:getHero(hidx)
        hero.bskills[bidx].curLight = 0
        for i, lightSkill in ipairs(data.bsList) do
            hero:setBSkill(bidx, i, lightSkill[1], lightSkill[2])
        end
        if not self.deleted and hero==self.heroMsg then
            local lights = hero.bskills[bidx].lights
            for i, bskillItem in ipairs(self.bskills) do
                self:reloadSkillItem(hero, bskillItem, lights[i])
            end
            self:selectBSkill(1)
            self:refreshLightBut()
            self.curIdx = 1
        end
    end
end

function HeroBSkillDialog:onChangeBSkill(force)
    if self.inRequest then
        return
    end
    local selectIdx = self.selectIdx
    local hero = self.heroMsg
    local bskill = hero.bskills[self.bskillIdx]
    if bskill.curLight==selectIdx or bskill.lights[selectIdx].state~=1 then
        return
    end
    if bskill.curLight==0 and not force then
        display.showDialog(AlertDialog.new(3, Localize("alertTitleNormal"), Localize("alertTextChangeBSkill"), {callback=Handler(self.onChangeBSkill, self, true)}))
        return
    end
    self.context.heroData:changeHeroBSkill(hero, self.bskillIdx, selectIdx)
    self:refreshUI()
    -- 洗练被动技能战斗力
    self.context.heroData:setCombatData(hero)
    -- 日常任务被动技能
    GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroPassive,1)
end
function HeroBSkillDialog:refreshUI()
    self:reloadBanner(self.heroMsg, self.banners[2], self.heroMsg.bskills[self.bskillIdx])
    self:selectBSkill(self.selectIdx)
    self.changed = true
end

function HeroBSkillDialog:onLifeCycle(event)
    if event=="exit" and self.changed then
        local parent = self.parent
        if not parent:getDialog().deleted then
            parent:reloadTalents(true)
            parent:reloadSoldierBlock()
            parent:reloadHeroData()
        end
    end
end
