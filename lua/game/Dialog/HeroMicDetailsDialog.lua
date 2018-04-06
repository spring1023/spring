local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
HeroMicDetailsDialog = class(DialogViewLayout)

function HeroMicDetailsDialog:onInitDialog()--英雄详细资料
    self.priority = display.getDialogPri()+1
    self:setLayout("HeroMicDetailsDialog.json")
    self:loadViewsTo()

    self.title:setString(Localize("btnHeroMic"))
    self.questionBut:setVisible(false)
    self.infos = {}
    local heroMsg = self.heroMsg
    for i=1, 3 do
        local stage = heroMsg:getMicStage(i)
        local rlabel = self["labelLevelRequire" .. i]
        if stage.alv==0 then
            rlabel:setVisible(false)
        end
        rlabel:setString(Localizef("labelMicLevelRequire",{level=stage.need,alv=Localize("dataAwakeLv"..stage.alv)}))
    end
    self.btnBuyMore:setScriptCallback(ButtonHandler(self.onBuyMore, self))
    self.btnBuyEff = ui.simpleCsbEffect("UICsb/heroMicAdd.csb")
    self.btnBuyEff:setPosition(65,65)
    self.btnBuyMore:addChild(self.btnBuyEff,10)
    return self.view
end

function HeroMicDetailsDialog:onEnter(upIdx)
    local context = self.context
    local heroMsg = self.heroMsg
    local ml = heroMsg:getMicLevel()
    local mc = context:getRes(const.ResMicCrystal)
    if mc<=0 then
        self.btnBuyEff:setVisible(true)
    else
        self.btnBuyEff:setVisible(false)
    end
    self.labelMicLevelValue:setString(Localizef("labelLevelFormat",{level=ml}))
    self.labelMicCrystalValue:setString(N2S(mc))
    local scene = GMethod.loadScript("game.View.Scene")
    self.scene = scene
    if scene.sceneType == "visit" then
        self.labelMicCrystalValue:setVisible(false)
        self.labelMicCrystal:setVisible(false)
        self.tipsHeroMic2:setVisible(false)
        self.btnBuyMore:setVisible(false)
    end
    local infos = self.infos
    local info
    for i=1, 7 do
        if not infos[i] then
            info = {}
            infos[i] = info
            info.viewLayout = self:addLayout("SkillCell", self["nodeSkill" .. i].view)
            info.viewLayout:loadViewsTo(info)
            info.btnInfo:setScriptCallback(ButtonHandler(self.onSkillInfo, self, i))
            info.btnSkill:setScriptCallback(ButtonHandler(self.onUpgradeSkill, self, i))
            info.btnSkill.view:setAutoHoldTime(0.5)
            info.btnSkill.view:setAutoHoldTimeTemp(0.1)
        else
            info = infos[i]
        end
        if not info.skill then
            info.skill = heroMsg:getMicSkill(i)
            if info.skill.level==0 then
                info.skill.desc=""
            end
            if info.skill.level<info.skill.max then
                info.skill.desc2=Localizef("dataSkillInfo6_" .. info.skill.id, {value=SData.getData("hmicsdatas",info.skill.id,info.skill.level+1)})
            else
                info.skill.desc2=""
            end
            if info.skill.id~=info.displaySid then
                info.nodeSkillBack:removeAllChildren(true)
                info.displaySid = info.skill.id
                info.icon = GameUI.addSkillIcon(info.nodeSkillBack, 6, info.displaySid, 1, 0, 28, 0)
            end
            info.labelName:setString(info.skill.name)
            info.labelLevel:setString(Localizef("labelHeroLevel",{max=info.skill.max, num=info.skill.level}))
            if info.skill.nextExp==0 then
                info.labelExp:setString(Localize("labelLevelMax"))
                info.nodeProcess:setSize(293, 47)
            else
                info.labelExp:setString(Localizef("labelExpFormat",{max=info.skill.nextExp, num=info.skill.exp}))
                info.nodeProcess:setSize(math.floor(293*info.skill.exp/info.skill.nextExp), 47)
            end
        end
        if ml<info.skill.need or heroMsg.awakeUp<info.skill.alv then
            info.icon:setSValue(-100)
        else
            info.icon:setSValue(0)
        end
        if upIdx and i==upIdx and info.skill.exp==0 then
            local efNode = ui.simpleCsbEffect("UICsb/heroMicCell.csb")
            self["nodeSkill" .. i].view:addChild(efNode,100)
            efNode:setPosition(0,49)
            music.play("sounds/heroMicSucUp.mp3")
        end
    end
    if not self.eid then
        self.eid = true
        GameEvent.registerEvent("refreshDialog", self, self.onEnter)
    end
    self:onMicInfo()
    --刷新英雄信息对话框中的英雄属性
    local grandFather = self.grandFather
    if grandFather and not grandFather:getDialog().deleted and grandFather.reloadHeroData then
        grandFather:reloadHeroData()
    end
end

function HeroMicDetailsDialog:onSkillInfo(i)
    self.selectedIdx = i
    self.labelSkillDesc:setString(self.infos[i].skill.desc)
    self.labelSkillDesc2:setString(self.infos[i].skill.desc2)
    self:onMicInfo()
end

function HeroMicDetailsDialog:onMicInfo()
    for i=1,7 do
        self["lbAdd" .. i]:setString(self.infos[i].skill.addPro)
    end
end

function HeroMicDetailsDialog:onUpgradeSkill(i)
    if self.scene.sceneType == "visit" then
        return
    end
    local context = self.context
    local heroMsg = self.heroMsg
    local ml = heroMsg:getMicLevel()
    local mc = context:getRes(const.ResMicCrystal)
    local skill = self.infos[i].skill
    --增加觉醒等级限制
    if skill.alv and skill.alv>heroMsg.awakeUp then

    else
        if skill.need>ml then
            -- display.pushNotice(Localizef("labelMicLevelRequire",{level=skill.need}))
        elseif skill.level>=skill.max then
            display.pushNotice(Localize("noticeHeroMic2"))
        elseif mc<=0 then
            display.pushNotice(Localize("noticeHeroMic1"))
        else
            context.heroData:micHero(heroMsg, i)
            self.infos[i].skill = nil
            self:onEnter(i)
        end
    end
    self:onSkillInfo(i)
end

function HeroMicDetailsDialog:onBuyMore()
    StoreDialog.new({stype="equip",idx=3,pri=display.getDialogPri()+1})
end

function HeroMicDetailsDialog:onExit()
    local parent = self.parent
    if parent and not parent:getDialog().deleted then
        if parent.reloadData then
            parent:reloadData()
        end
    end
    if self.eid then
        self.eid = nil
        GameEvent.unregisterEvent("refreshDialog", self)
    end
end
