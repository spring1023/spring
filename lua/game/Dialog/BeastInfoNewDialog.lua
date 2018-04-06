BeastInfoNewDialog = class(DialogViewLayout)
local SData = GMethod.loadScript("data.StaticData")
function BeastInfoNewDialog:onInitDialog()
    self:setLayout("BeastInfoNewDialog.json")
    self:loadViewsTo()
    self.backBut:setVisible(true)
    self.backBut:setScriptCallback(ButtonHandler(self.backCallBack,self))
    self.questionTag = "dataHeroInfoNewHelp"
    self.title:setString(Localize(""))
    self.bgImage:setTexture("images/dialogBackHero2.png")
    self.currentHero = self.hero or {}
    self.context = GameLogic.getUserContext()
    self:conversionData(self.currentHero)
    self:initUI()
end

function BeastInfoNewDialog:backCallBack()
    display.closeDialog(self.priority)
end

function BeastInfoNewDialog:conversionData(hero)
    local heroData = hero
    self.heroData = {}
    local info = {
        id = heroData.hid,
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


function BeastInfoNewDialog:initUI()
    --神兽名字
    self.labelName:setString(Localize("dataHeroName"..self.heroData.id))
    GameUI.setHeroNameColor(self.labelName, self.heroData.color)
    --背景故事
    self.labelBGStory:setString(Localize("labelInfoBgStory"))
    self.labelBGStoryInfo:setString(Localize(SData.getData("heroInfoNew",self.heroData.id).bgStory) or "")
    --神兽图片
    GameUI.addHeroFeature(self.imgHeroFeature,self.heroData.id,1.1,0,0,0,nil,1)
    --技能
    GameUI.addSkillIcon(self.skillNode, 1, self.heroData.id+100, 0.81, 130, 87)
    self.labelSkill:setString(Localize("btnMainSkill"))
    self.lab_skillInfo:setString(self.currentHero:getSkillName().."\n"..self.currentHero:getSkillDesc(1))
    --职业负加成
    local path = self.path
    for i=1,#path do
        local temp = ui.sprite(path[i], {92, 92})
        display.adapt(temp, i*100, 0, GConst.Anchor.LeftBottom)
        self.node_jobDamageUp:addChild(temp)
    end
    self.lab_jobDamageUp:setString(self.text)
    --基础属性
    local info = SData.getData("godBeastBoss",self.aid,self.nowIdx)
    self.labelSX:setString(Localize("labelBossLvAttribute"))
    self.labelSM:setString(Localize("labelLifeHP")..info.hp)
    self.labelGJL:setString(Localize("labelATK")..info.atk)
    self.labelGJPH:setString(Localize("labelATKPreference").."："..StringManager.getString("enumBType" .. (self.heroData.fav or 0)))
end



