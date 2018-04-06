HeroInfoNewDialog = class(DialogViewLayout)
local SData = GMethod.loadScript("data.StaticData")
function HeroInfoNewDialog:onInitDialog()
    self:setLayout("HeroInfoNewDialog.json")
    self:loadViewsTo()
    self.backBut:setVisible(true)
    self.backBut:setScriptCallback(ButtonHandler(self.backCallBack,self))
    self.questionTag = "dataHeroInfoNewHelp"
    self.title:setString(Localize(""))
    self.bgImage:setTexture("images/dialogBackHero2.png")
    self.currentHero = self.hero or {}
    self.context = GameLogic.getUserContext()
    self.feature = false
    self:conversionData(self.currentHero)
    self.data = self:getAllInfoData()
    self:initUI()
end

function HeroInfoNewDialog:backCallBack()
    display.closeDialog(self.priority)
end

function HeroInfoNewDialog:conversionData(hero)
    local heroData = hero
    self.heroData = {}
    local info = {
        id = heroData.hid,
        rating = heroData.info.displayColor and heroData.info.displayColor >=5 and 5 or heroData.info.rating,
        color = heroData.info.displayColor or heroData.info.color,
        job = heroData.info.job,
        mid = heroData.info.mid,
        isAwake = heroData.info.awake,
        sid = heroData.info.sid,
        fav = heroData.info.fav,
        atk = heroData.info.initatk,
        hp = heroData.info.inithp,
        lvhp = heroData.info.lvhp,
        lvatk = heroData.info.lvatk,
        hsid = heroData.info.hsid
    }
    self.heroData = info
end



function HeroInfoNewDialog:getAllInfoData()
    local allData = SData.getData("heroInfoNew")
    local data = {}
    for k,v in KTPairs(allData) do
        if not data[k] then
            data[k] = {}
        end
        data[k] = v
    end
    return data
end


function HeroInfoNewDialog:initOther()
    self.labelName:setString(Localize("dataHeroName"..self.heroData.id))
    GameUI.setHeroNameColor(self.labelName, self.heroData.color)
    self.labelClickDemo:setString(Localize("labelClickTry"))
    self:changeFeature()
    ui.setFrame(self.imgStarLv.view,"images/btnImageQuality"..self.heroData.rating..".png")
    GameUI.addHeroJobIcon(self.heroJob.view, self.heroData.job, 1, 46, 46)
    if self.heroData.sid>0 then
        local temp = ui.scale9("images/bgWhite.9.png", 20, {152, 153})
        temp:setColor(cc.c3b(0,0,0))
        temp:setOpacity(79)
        temp:setCustomPoint(0,0.025,0,0,0)
        temp:setCustomPoint(1,0,0.945,0,1)
        temp:setCustomPoint(2,1,0.029,1,0)
        temp:setCustomPoint(3,0.935,1,1,1)
        display.adapt(temp, 0, 0, GConst.Anchor.Center)
        self.heroSoldierIcon:addChild(temp)

        temp = ui.scale9("images/bgDarkEdgeWhite.9.png", 20, {142,143})
        temp:setColor(cc.c3b(57,89,99))
        temp:setCustomPoint(1,0,0.975,0,1)
        temp:setCustomPoint(3,0.962,1,1,1)
        display.adapt(temp, 0, 0, GConst.Anchor.Center)
        self.heroSoldierIcon:addChild(temp)

        GameUI.addHeadIcon(self.heroSoldierIcon.view, self.heroData.sid, 0.5, 0, -5)
    end
    self.clickDemo:setScriptCallback(ButtonHandler(self.clickTryCallback, self))
    self.changeFeatureNode:setScriptCallback(ButtonHandler(self.changeFeature,self))
end

function HeroInfoNewDialog:changeFeature()
    if self.heroData.isAwake~=1 or self.heroData.id >= 4014 and self.heroData.id <= 4016 or self.heroData.id == 4019 or self.heroData.id == 4008 then
        self.labelNormal:setVisible(false)
        self.labelNormal:setVisible(false)
        self.changeFeatureNode:setVisible(false)
        self.changeFeatureNode:setEnable(false)
    end
    self.feature = not self.feature
    self.imgHeroFeature:removeAllChildren(true)
    if self.feature then
        if self.heroData.id == 4031 then--人形态
            self.currentHero.heroState = 0
            self.labelNormal:setString(Localize("dataSkillName1_4131"))
            GameUI.addHeroFeature(self.imgHeroFeature,4031,1.1,0,0,0)--加图时把图片名字弄反了,将错就错
            if self.tableInfos then
                self.tableInfos[4].id = 4031202
                self.tableInfos[1].tip = Localize("dataSkillName1_4131").."\n"..self.currentHero:getSkillDesc(1)
                self.tableInfos[4].tip = Localize("dataSkillName5_4031202").."\n"..self.currentHero:getAwakeSkill(5).info
                self:updateSkillScorllNode(self.tableInfos[4].cell, self.tableView, self.tableInfos[4])
                self:updateSkillScorllNode(self.tableInfos[1].cell, self.tableView, self.tableInfos[1])
            end
        else
            self.labelNormal:setString(Localize("labelNormal"))
            GameUI.addHeroFeature(self.imgHeroFeature,self.heroData.id,1.1,0,0,0)
        end
    else
        if self.heroData.id == 4031 then--兽形态
            self.currentHero.heroState = 1
            self.labelNormal:setString(Localize("dataSkillName1_4131"))
            GameUI.addHeroFeature(self.imgHeroFeature,40312,1.1,0,0,0)--加图时把图片名字弄反了,将错就错
            if self.tableInfos then
                self.tableInfos[4].id = 403102
                self.tableInfos[1].tip = Localize("dataSkillName1_4131").."\n"..self.currentHero:getSkillDesc(1)
                self.tableInfos[4].tip = Localize("dataSkillName5_403102").."\n"..self.currentHero:getAwakeSkill(5).info
                self:updateSkillScorllNode(self.tableInfos[4].cell, self.tableView, self.tableInfos[4])
                self:updateSkillScorllNode(self.tableInfos[1].cell, self.tableView, self.tableInfos[1])
            end
        else
            self.labelNormal:setString(Localize("btnAwake"))
            GameUI.addHeroFeature(self.imgHeroFeature,self.heroData.id,1.1,0,0,0,nil,1)
        end
    end
end

function HeroInfoNewDialog:clickTryCallback()
    --点击试玩
    local guankaId=self.data[self.heroData.id].guankaId
     GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=2,ptype=true,idx=guankaId,bparams={stage = const.HeroInfoNewTry,id = self.heroData.id}})
end

function HeroInfoNewDialog:initUI()
    self:initOther()
    self:bgStory()
    self:initUISkill()
    self:initFullLVAttribute()
    self:initAccessTo()
end
function HeroInfoNewDialog:bgStory()
    -- body
    self.labelBGStory:setString(Localize("labelInfoBgStory"))
    self.labelBGStoryInfo:setString(Localize(self.data[self.heroData.id].bgStory or ""))
end
function HeroInfoNewDialog:initUISkill()
    self.scrollNode:removeAllChildren(true)
    local data = self.data[self.heroData.id]
    local labelStr = {"btnMainSkill","btnHelpSkill","btnProtectSkill","btnGodsSkill"}
    local heroIds = {self.heroData.mid}
    local iconIdx = {1,4,5,5}
    local tipInfo = {self.currentHero:getSkillName().."\n"..self.currentHero:getSkillDesc(1)}
    local infos = {}
    local max = 1
    if self.heroData.hsid ~= 0 then
        max = 2
        heroIds[2] = self.heroData.hsid
        tipInfo[2] = self.currentHero:getHelpSkillName().."\n"..self.currentHero:getHelpSkillDesc(self.currentHero:getHelpSkill())
    end
    if self.heroData.isAwake == 1 then
        local awakeInfo3 = self.currentHero:getAwakeSkill(3)
        local awakeInfo5 = self.currentHero:getAwakeSkill(5)
        max = 4
        heroIds[3] = awakeInfo3.id
        heroIds[4] = awakeInfo5.id
        tipInfo[3] = awakeInfo3.name.."\n"..awakeInfo3.info
        tipInfo[4] = awakeInfo5.name.."\n"..awakeInfo5.info
    end
    for k=1,max do
        infos[k] = {str = labelStr[k],id = heroIds[k],idx = iconIdx[k],tip = tipInfo[k]}
    end
    self.tableInfos = infos
    self.tableView = GameUI.helpLoadTableView(self.scrollNode,infos,Handler(self.updateSkillScorllNode,self))
    if self.heroData.color >= 5 then
        self.extSkills:setVisible(true)
        self.labelExtSkill:setString(Localize("btnExtSkill"))
        GameUI.addSkillIcon(self.extSkillNode, 6, self.heroData.id+300, 0.81, 130, 87)
        local extTip = self.currentHero:getExtSkillName() .. "\n" .. self.currentHero:getExtSkillDesc()
        self.extSkills.view:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self.view, self.extSkills.view:getDrawNode(), -300, 300, extTip}))
    else
        self.extSkills:setVisible(false)
    end
    self:changeFeature()
end

function HeroInfoNewDialog:updateSkillScorllNode(cell,tableView,info)
    if not info.viewLayout then
        info.cell = cell
        info.viewLayout = self:addLayout("skillScrollNode",cell:getDrawNode())
        info.viewLayout:loadViewsTo(info)
    end
    info.labelSkill:setString(Localize(info.str))
    if info.skillImage then
        info.skillImage:removeFromParent(true)
        info.skillImage = nil
    end
    info.skillImage = GameUI.addSkillIcon(info.skillNode, info.idx, info.id, 0.81, 130, 87)
    local cellSize = cell:getContentSize()
    info.cell:setControlHandler(ButtonHandler(GameUI.tipsTouchHandler, {self.view, info.cell, -300, 300, Localize(info.tip)}))
end

function HeroInfoNewDialog:initFullLVAttribute()

    local info = SData.getData("hinfos",self.heroData.hid)
    self.labelSX:setString(Localize("labelFullLvAttribute"))
    self.labelSM:setString(Localize("labelLifeHP")..self.heroData.hp)
    self.labelGJL:setString(Localize("labelATK")..self.heroData.atk)
    self.labelAddSM:setString("(+"..self.heroData.lvhp.."/Lv)")
    self.labelAddGJL:setString("(+"..self.heroData.lvatk.."/Lv)")
    self.labelGJPH:setString(Localize("labelATKPreference").."："..StringManager.getString("enumBType" .. (self.heroData.fav or 0)))

    self.labelBF:setString(Localize("labelOutBreak"))
    self.lableSC:setString(Localize("labelOutPut"))

    self.labelFY:setString(Localize("labelDefense"))
    self.labelKZ:setString(Localize("labelControl"))

    --爆发
    local info = self.data[self.heroData.id]
    local pro = info.bnum/100
    self.imgPBar1:setProcess(true,pro)
    --输出
    pro = info.onum/100
    self.imgPBar2:setProcess(true,pro)
    --防护
    pro = info.dnum/100
    self.imgPBar3:setProcess(true,pro)
    --控制
    pro = info.cnum/100
    self.imgPBar4:setProcess(true,pro)
end

function HeroInfoNewDialog:initAccessTo()
    self.labelHD:setString(Localize("labelAccessTo"))
    self.labelHDTJ:setString(Localize(self.data[self.heroData.id].getWay or ""))
end

