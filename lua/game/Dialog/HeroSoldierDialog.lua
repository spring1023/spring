local const = GMethod.loadScript("game.GameLogic.Const")
HeroSoldierDialog = class(DialogViewLayout)

function HeroSoldierDialog:onInitDialog()
    self.parent = self.params.parent
    self.context = self.params.context
    self.heroMsg = self.params.heroMsg
    self:initUI()
end

function HeroSoldierDialog:onLifeCycle(event)
    if event == "exit" then
        local parent = self.parent
        if parent and not parent:getDialog().deleted then
            parent:reloadSoldierBlock()
        end
    end
end
--@brief初始化界面时，在界面上左右添加两个colorNode
function HeroSoldierDialog:initUI()
    self:setLayout("HeroSoldierDialog.json")
    local temp1,temp2
    temp1 = ui.colorNode({920,1260},{222,199,148})
    display.adapt(temp1, -960, -700,GConst.Anchor.LeftBottom)
    temp1:setOpacity(0.7*255)
    temp2 = ui.colorNode({920,1260},{222,199,148})
    display.adapt(temp2, 38, -700, GConst.Anchor.LeftBottom)
    temp2:setOpacity(0.7*255)
    self.colorNode:addChild(temp1)
    self.colorNode:addChild(temp2)
    self:isHasShadowLeft()
    self:isHasShadowRight()

    self.btnClose:setScriptCallback(ButtonHandler(display.closeDialog, self.priority))
    self.leftBtnGreen:setScriptCallback(ButtonHandler(self.onUpgradeSoldier, self))
    self.rightTopBtnGreen:setScriptCallback(ButtonHandler(self.onUpgradeSoldierSkillTop, self))
    self.rightDowndBtnGreen:setScriptCallback(ButtonHandler(self.onUpgradeSoldierSkillDown, self))

    self:loadLevelBlock()
    self:loadSkillBlock1()
    self:loadSkillBlock2()
    RegLife(self.view, Handler(self.onLifeCycle, self))
    --标题 佣兵升级
    self.upSoldiergrade:setString(Localize("titleUpgradeSoldier"))
    --右侧的学习天赋
    self.stuTalent:setString(Localize("labelSoldierTalent"))
    --左侧的提升等级
    self.addgrade:setString(Localize("labelUpgradeLevel"))
    self:loadViewsTo()
end
--@brief加载等级模块，所有的佣兵等级逻辑在这里写
function HeroSoldierDialog:loadLevelBlock()
    local sid = self.heroMsg.info.sid
    local slv = self.heroMsg.soldierLevel
    local levels = {slv}
    local name = self.heroMsg:getSoldierName()
    local costData = self.heroMsg:getSoldierCost(levels[1])

    if slv < const.MaxSoldierLevel then
        levels[2] = levels[1]+1
        --需要勋章的数值
        self.btn1Label:setString(N2S(costData.next))
        if costData.next>self.context:getRes(const.ResZhanhun) then
            self.leftBtnGreen:setGray(true)
        else
            self.leftBtnGreen:setGray(false)
        end
        GameUI.addHeadIcon(self.sprSoldier1, sid, 1,115, 108,{lv = levels[1]})
        GameUI.addHeadIcon(self.sprSoldier2, sid, 1,115, 108,{lv = levels[2]})
        self.sprSoldierLab1:setString(levels[1] .. "/" .. const.MaxSoldierLevel)
        self.sprSoldierLab2:setString(levels[2] .. "/" .. const.MaxSoldierLevel)
        self.nameLevelLab1:setString(Localizef("dataSkillNameFormat",{name=name, level=levels[1]}))
        self.nameLevelLab2:setString(Localizef("dataSkillNameFormat",{name=name, level=levels[2]}))
        local sdata1 = self.heroMsg:getSoldierData(levels[1])
        local sdata2 = self.heroMsg:getSoldierData(levels[2])
        self.lifeValueLab1:setString(Localizef("propertyHp2",{num=sdata1.hp}))
        self.damageValueLab1:setString(Localizef("propertyDps2",{num=sdata1.atk}))
        self.lifeValueLab2:setString(Localizef("propertyHp2",{num=sdata2.hp}))
        self.damageValueLab2:setString(Localizef("propertyDps2",{num=sdata2.atk}))
    else
        local x = self.allLeftHpDps.view:getPositionX()
        x = x + 256
        self.allLeftHpDps.view:setPositionX(x)
        GameUI.addHeadIcon(self.sprSoldier1, sid, 1,115, 108,{lv = levels[1]})
        local sdata1 = self.heroMsg:getSoldierData(levels[1])
        self.lifeValueLab1:setString(Localizef("propertyHp2",{num=sdata1.hp}))
        self.damageValueLab1:setString(Localizef("propertyDps2",{num=sdata1.atk}))
        self.sprSoldierLab1:setString(levels[1] .. "/" .. const.MaxSoldierLevel)
        self.nameLevelLab1:setString(Localizef("dataSkillNameFormat",{name=name,level=levels[1]}))

        self.allRightHpDps:setVisible(false)
        self.leftGreenArrow:setVisible(false)
        self.leftBtnGreen:setVisible(false)
    end
    self:onUpgradeHelpSoldier(slv)
end
--@biref佣兵助战提升助战英雄佣兵属性
function HeroSoldierDialog:onUpgradeHelpSoldier(slv)
    local sdata = self.heroMsg:getHelpSoldierData(slv)
    self.helpAttributeList:setString(Localize("helpAttributeList"))
    self.helpReduceDamage:setString(Localizef("helpReduceDamage",{num=sdata.skilldef}))
    self.helpAddHp:setString(Localizef("helpAddHp",{num=sdata.shp}))
end
--@biref升级佣兵按钮上的逻辑在这里
function HeroSoldierDialog:onUpgradeSoldier()
    if self.heroMsg.soldierLevel >= const.MaxSoldierLevel then
        return
    end
    local hdata = self.context.heroData
    local slv = self.heroMsg.soldierLevel
    local costData = self.heroMsg:getSoldierCost(slv)
    if costData.next>self.context:getRes(const.ResZhanhun) then
        display.showDialog(AlertDialog.new({ctype=const.ResZhanhun,cvalue=costData.next,callback=Handler(self.onUpgradeSoldier,self)}))
    elseif hdata:upgradeSoldier(self.heroMsg) then
        self:loadLevelBlock()
        self:loadSkillBlock1()
        self:loadSkillBlock2()
        self.needReloadSoldier = true
        music.play("sounds/mercenary_upgrade.mp3")
        UIeffectsManage:showEffect_yonbingshenji(1,self.allNode,-262,320,3,1.4)
        UIeffectsManage:showEffect_yonbingshenji(2,self.leftBtnGreen,210,86,3,1.7)
    end
end
function HeroSoldierDialog:freshSkillBlock(node,params)
    if type(node) == "table" then
        for _, v in pairs(node) do
            if v:getDrawNode():getChildren() then
                v:getDrawNode():removeAllChildren()
            end
            GameUI.addSkillIcon(v:getDrawNode(),2,{id=params.sid, scale=params.scale
             or 1,x=params.x or 0,y=params.y or 0})
        end
    else
        if node:getDrawNode():getChildren() then
            node:getDrawNode():removeAllChildren()
        end
        GameUI.addSkillIcon(node:getDrawNode(),2,{id=params.sid, scale=params.scale
             or 1,x=params.x or 0,y=params.y or 0})
    end
end
--@brief载入第一天赋的佣兵技能,佣兵id/天赋技能等级/第一天赋名称/
function HeroSoldierDialog:loadSkillBlock1()
    local sid = self.heroMsg.info.sid
    local sklv = self.heroMsg.soldierSkillLevel1
    local levels = {sklv}
    local firstName = self.heroMsg:getSoldierTalentName(1)
    local size = self.btnSoldierSkill1_1.view:getContentSize()
    local costData = self.heroMsg:getSoldierTalentCost(1, levels[1])
    local flag = costData.needLevel>self.heroMsg.soldierLevel
    if levels[1] < const.MaxSoldierSkillLevel then
        levels[2] = levels[1]+1
        self.btnSoldierSkill1_1.view:setEnable(true)
        local text = self.heroMsg:getSoldierTalentDesc(1, levels[1])
        local text1 = self.heroMsg:getSoldierTalentDesc(1, levels[2])
        local x, y = self.btnSoldierSkill1_1.view:getPosition()
        local _x, _y = self.btnSoldierSkill1_2.view:getPosition()
        self.btnSoldierSkill1_1.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler,
            {self.view,self.btnSoldierSkill1_1.view,x/2,y/2,text}))
        self.btnSoldierSkill1_2.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler,
            {self.view,self.btnSoldierSkill1_2.view,_x/2,_y/2,text1}))

        self:freshSkillBlock({self.btnSoldierSkill1_1.view,self.btnSoldierSkill1_2.view},
            {sid=sid, scale=1,x=size.width/2,y=size.height/2})
        self.talentNum1_1:setString(Localizef(levels[1] .. "/" .. const.MaxSoldierSkillLevel))
        self.rightNameLevelLab1_1:setString(Localizef("dataSkillNameFormat",{name=firstName, level=levels[1]}))
        self.talentNum1_2:setString(Localizef(levels[2] .. "/" .. const.MaxSoldierSkillLevel))
        self.rightNameLevelLab1_2:setString(Localizef("dataSkillNameFormat",{name=firstName, level=levels[2]}))

        if levels[1]==0 then
            self.rightNameLevelLab1_1.view:setString(Localizef("labelTalentLevel0"))
            self.rightNameLevelLab1_2:setString(Localizef("dataSkillNameFormat",{name=firstName, level=levels[1]}))
            self.btnSoldierSkill1_1.view:setEnable(false)
        end
        if self.topConditions then
            if flag then
                ui.setColor(self.topConditions, GConst.Color.Red)
            else
                ui.setColor(self.topConditions, GConst.Color.White)
            end
            self.topConditions:setString(Localizef("labelNeedSoldierLevel",{level=costData.needLevel}))
        end
        if self.btn2Label then
            if costData.cvalue>self.context:getRes(const.ResZhanhun) then
                ui.setColor(self.btn2Label, GConst.Color.Red)
            else
                ui.setColor(self.btn2Label, GConst.Color.White)
            end
            self.btn2Label:setString(N2S(costData.cvalue))
        end
    else
        if not self.x1 then
            self.x1=self.allFirstTalent1.view:getPositionX()
        end
        self.allFirstTalent1.view:setPositionX(self.x1+256)
        self:freshSkillBlock(self.btnSoldierSkill1_1.view,{sid=sid, scale=1,x=size.width/2,y=size.height/2})
        self.talentNum1_1:setString(Localizef(levels[1] .. "/" .. const.MaxSoldierSkillLevel))
        self.rightNameLevelLab1_1:setString(Localizef("dataSkillNameFormat",{name=firstName, level=levels[1]}))
        local x, y = self.btnSoldierSkill1_1.view:getPosition()
        local text = self.heroMsg:getSoldierTalentDesc(1, levels[1])
        self.btnSoldierSkill1_1.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler,
            {self.view,self.btnSoldierSkill1_1.view,x/2,y/2,text}))

        self.allFirstTalent2.view:setVisible(false)
        self.rightFirstTop.view:setVisible(false)
    end
end
--@brief载入第二天赋的佣兵技能,sid/天赋技能等级/第二天赋名称/
function HeroSoldierDialog:loadSkillBlock2()
    local sid = self.heroMsg.info.sid
    local sklv = self.heroMsg.soldierSkillLevel2
    local levels = {sklv}
    local secondName = self.heroMsg:getSoldierTalentName(2)
    local size = self.btnSoldierSkill2_1.view:getContentSize()
    local costData = self.heroMsg:getSoldierTalentCost(2,levels[1])
    local flag = costData.needLevel>self.heroMsg.soldierLevel
    if sklv < const.MaxSoldierSkillLevel then
        levels[2] = levels[1]+1
        self.btnSoldierSkill2_1.view:setEnable(true)
        local text = self.heroMsg:getSoldierTalentDesc(2, levels[1])
        local text1 = self.heroMsg:getSoldierTalentDesc(2, levels[2])
        local x, y = self.btnSoldierSkill2_1.view:getPosition()
        local _x, _y = self.btnSoldierSkill2_2.view:getPosition()

        self.btnSoldierSkill2_1.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler,
            {self.view,self.btnSoldierSkill2_1.view,x/2,y/2,text}))
        self.btnSoldierSkill2_2.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler,
            {self.view,self.btnSoldierSkill2_1.view,_x/2,_y/2,text1}))

        self:freshSkillBlock({self.btnSoldierSkill2_1.view,self.btnSoldierSkill2_2.view},
            {sid=sid+1, scale=1,x=size.width/2,y=size.height/2})

        self.talentNum2_1:setString(Localizef(levels[1] .. "/" .. const.MaxSoldierSkillLevel))
        self.talentNum2_2:setString(Localizef(levels[2] .. "/" .. const.MaxSoldierSkillLevel))
        self.rightNameLevelLab2_1:setString(Localizef("dataSkillNameFormat",{name=secondName, level=levels[1]}))
        self.rightNameLevelLab2_2:setString(Localizef("dataSkillNameFormat",{name=secondName, level=levels[2]}))

        if levels[1]==0 then
            self.rightNameLevelLab2_1:setString(Localizef("labelTalentLevel0"))
            self.rightNameLevelLab2_2:setString(Localizef("dataSkillNameFormat",{name=secondName, level=levels[1]}))
            self.btnSoldierSkill2_1.view:setEnable(false)
        end
        if self.DownConditions then
            if flag then
                ui.setColor(self.DownConditions, GConst.Color.Red)
            else
                ui.setColor(self.DownConditions, GConst.Color.White)
            end
            self.DownConditions:setString(Localizef("labelNeedSoldierLevel",{level=costData.needLevel}))
        end
        if self.btn3Label then
            if costData.cvalue>self.context:getRes(const.ResZhanhun) then
                ui.setColor(self.btn3Label, GConst.Color.Red)
            else
                ui.setColor(self.btn3Label, GConst.Color.White)
            end
            self.btn3Label:setString(N2S(costData.cvalue))
        end
    else
        if not self.x1 then
            self.x1=self.allSecondTalent1.view:getPositionX()
        end
        self.allSecondTalent1.view:setPositionX(self.x1+256)
        local x, y = self.btnSoldierSkill2_1.view:getPosition()
        local text = self.heroMsg:getSoldierTalentDesc(2, levels[1])
        self.btnSoldierSkill2_1.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler,
            {self.view,self.btnSoldierSkill2_1.view,x/2,y/2,text}))
        self:freshSkillBlock(self.btnSoldierSkill2_1.view,{sid=sid+1, scale=1,x=size.width/2,y=size.height/2})

        self.talentNum2_1:setString(Localizef(levels[1] .. "/" .. const.MaxSoldierSkillLevel))
        self.rightNameLevelLab2_1:setString(Localizef("dataSkillNameFormat",{name=secondName, level=levels[1]}))
        self.allSecondTalent2.view:setVisible(false)
        self.rightSecondDown.view:setVisible(false)
    end
end
--@brief天赋升级
function HeroSoldierDialog:onUpgradeSoldierSkillTop()
    if self.heroMsg.soldierSkillLevel1>=const.MaxSoldierSkillLevel then
        return
    end
    local levels = self.heroMsg.soldierSkillLevel1
    local costData = self.heroMsg:getSoldierTalentCost(1,levels)
    if costData.needLevel>self.heroMsg.soldierLevel then
        display.pushNotice(Localizef("noticeNeedSoldierLevel",{level=costData.needLevel}))
    elseif costData.cvalue>self.context:getRes(const.ResZhanhun) then
        display.showDialog(AlertDialog.new({ctype=const.ResZhanhun,cvalue=costData.cvalue,callback=Handler(self.onUpgradeSoldierSkillTop,self)}))
    else self.context.heroData:upgradeSoldierSkill(self.heroMsg, const.HeroSoldierSkillTalent1,levels)
        self:loadSkillBlock1(1)
        self.needReloadSoldier = true
    end
end
--@biref升级第二天赋
function HeroSoldierDialog:onUpgradeSoldierSkillDown()
    if self.heroMsg.soldierSkillLevel2>=const.MaxSoldierSkillLevel then
        return
    end
    local levels = self.heroMsg.soldierSkillLevel2
    local costData = self.heroMsg:getSoldierTalentCost(2,levels)
    if costData.needLevel>self.heroMsg.soldierLevel then
        display.pushNotice(Localizef("noticeNeedSoldierLevel",{level=costData.needLevel}))
    elseif costData.cvalue>self.context:getRes(const.ResZhanhun) then
        display.showDialog(AlertDialog.new({ctype=const.ResZhanhun,cvalue=costData.cvalue,callback=Handler(self.onUpgradeSoldierSkillDown,self)}))
    else self.context.heroData:upgradeSoldierSkill(self.heroMsg, const.HeroSoldierSkillTalent2,levels)
        self:loadSkillBlock2(2)
        self.needReloadSoldier = true
    end
end
function HeroSoldierDialog:isHasShadowLeft()
    local temp2 = ui.scale9("images/bgWhite.9.png", 20, {240,240})
    temp2:setColor(cc.c3b(0,0,0))
    temp2:setOpacity(79)
    temp2:setCustomPoint(0,0.025,0,0,0)
    temp2:setCustomPoint(1,0,0.945,0,1)
    temp2:setCustomPoint(2,1,0.029,1,0)
    temp2:setCustomPoint(3,0.935,1,1,1)
    display.adapt(temp2, -110, -130, GConst.Anchor.LeftBottom)
    self.LeftHasShadow:addChild(temp2,-1)
end
function HeroSoldierDialog:isHasShadowRight()
    local temp2 = ui.scale9("images/bgWhite.9.png", 20, {240,240})
    temp2:setColor(cc.c3b(0,0,0))
    temp2:setOpacity(79)
    temp2:setCustomPoint(0,0.025,0,0,0)
    temp2:setCustomPoint(1,0,0.945,0,1)
    temp2:setCustomPoint(2,1,0.029,1,0)
    temp2:setCustomPoint(3,0.935,1,1,1)
    display.adapt(temp2, -110, -130, GConst.Anchor.LeftBottom)
    self.RightHasShadow:addChild(temp2,-1)
end
