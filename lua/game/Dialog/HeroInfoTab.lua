local const = GMethod.loadScript("game.GameLogic.Const")
--所有模块单独拆分可以有效对该部分的逻辑进行处理
--主动技能模块；
local HeroMainSkillTab = class(DialogTab)

function HeroMainSkillTab:create()--英雄主要的技能模块
    self.scene = GMethod.loadScript("game.View.Scene")
    self.heroMsg = self.parent.heroMsg
    local bg = ui.node({0,0},true)
    self.view = bg
    local temp

    local mid = self.heroMsg.info.mid
    GameUI.addSkillIcon(bg, 1, mid, 0.86, 1242, 602)
    if mid==0 then
        temp = ui.label(StringManager.getString("dataHeroName0"), General.font1, 40, {color={255,255,255},width=375})--dataHeroName0经验芯片
        GameUI.setHeroNameColor(temp, self.heroMsg.info.displayColor or self.heroMsg.info.color)
    else
        temp = ui.label(self.heroMsg:getSkillName(), General.font1, 40, {color={0,255,255},width=375})
    end
    display.adapt(temp, 1530, 661, GConst.Anchor.Center)
    bg:addChild(temp)
    temp = ui.label("", General.font1, 40, {color={255,255,255},width=375})
    display.adapt(temp, 1530, 559, GConst.Anchor.Center)
    bg:addChild(temp)
    self.levelLabel = temp

    temp=ui.button({208, 158}, self.showMainSkillUpgrade,{cp1=self, image="images/btnOrange.png"})
    display.adapt(temp, 1845, 605, GConst.Anchor.Center)
    bg:addChild(temp)
    self.upgradeBut = temp

    GameLogic.getJumpGuide(const.JumpTypeMain,temp,104,99)

    local but=temp:getDrawNode()
    temp = ui.sprite("images/btnUpgrade1.png",{90, 98})
    display.adapt(temp, 104, 96, GConst.Anchor.Center)
    but:addChild(temp)
    temp = ui.sprite("images/btnUpgrade2.png",{110, 122})
    display.adapt(temp, 118, 73, GConst.Anchor.LeftBottom)
    but:addChild(temp)
    temp = ui.label("", General.font2, 40, {color={30,91,165},width=840,align=GConst.Align.Left})
    display.adapt(temp, 1547, 449, GConst.Anchor.Top)
    bg:addChild(temp)
    self.descLabel = temp

    if self.heroMsg.hid == 4031 then
        GameEvent.bindEvent(self.descLabel, "ChangeChopperDesc", self, self.reloadAll)
    end
    self:reloadAll()
    return bg
end

function HeroMainSkillTab:reloadAll(animate)--重载所有
    local maxSkillLv = 1
    if self.heroMsg.info.mid>0 then
        maxSkillLv = const.MaxMainSkillLevel
    end
    self.levelLabel:setString(self.heroMsg.mSkillLevel .. "/" .. maxSkillLv)
    self.descLabel:setString(self.heroMsg:getSkillDesc())
    self.upgradeBut:setVisible(self.heroMsg.mSkillLevel<maxSkillLv)
    if self.scene.sceneType == "visit" then
        self.upgradeBut:setVisible(false)
    end
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type ~= "finish" then
        self.upgradeBut:setVisible(false)
    end
end

function HeroMainSkillTab:showMainSkillUpgrade()
    GameLogic.removeJumpGuide(const.JumpTypeMain)
    display.showDialog(HeroMainSkillDialog.new(self.parent, self:getContext(), self.heroMsg))
end

--被动技能模块
local HeroTalentSkillTab = class(DialogTab)

function HeroTalentSkillTab:create()
    self.scene = GMethod.loadScript("game.View.Scene")
    local bg = ui.node({0,0},true)
    local temp
    self.view = bg
    self:reloadAll()
    return self.view
end

function HeroTalentSkillTab:reloadAll()
    self.heroMsg = self.parent.heroMsg
    local bg = self.view
    local temp
    bg:removeAllChildren(true)
    self.guideHeroBskillArrow = nil
    local hero = self.heroMsg
    if hero.info.job>0 then
        if hero.level<const.BSkillMinHLevel then
            temp = ui.label(Localizef("labelBSkillLimit",{level=const.BSkillMinHLevel}), General.font1, 60, {color={255,255,255},width=800})
            display.adapt(temp, 1530, 559, GConst.Anchor.Center)
            bg:addChild(temp)
        else
            local context = GameLogic.getUserContext()
            for i=1,3 do
                local bskill = hero.bskills[i]
                local prefab = BaseView.new("HeroTalentSkillTab")
                display.adapt(prefab,1106, 516-231*(i-1),GConst.Anchor.LeftBottom)
                bg:addChild(prefab)
                if bskill.id>0 then
                    prefab:loadView("backView")
                    prefab:loadView("skView")
                    prefab:insertViewTo()
                    GameUI.addSkillIcon(prefab.skNode, 3, bskill.id, 0.86*164/192, 82, 82)
                    prefab.lbSkLv:setString(bskill.level .. "/" .. hero:getTalentSkillMax(bskill.id))
                    prefab.lbSkName:setString(hero:getTalentSkillName(bskill.id))
                    prefab.lbSkDes:setString(hero:getTalentSkillInfo(bskill.id, bskill.level))
                    if self.scene.sceneType == "visit" then
                        prefab.butSk:setVisible(false)
                    end
                else
                    if self.scene.sceneType == "visit" or context.guide:getStep().type ~= "finish" then
                        break
                    else
                        prefab:loadView("backView")
                        prefab:loadView("noSkView")
                        prefab:insertViewTo()
                        if context:getRes(const.ResCrystal) >=  300 then
                            ui.setColor(prefab.lbDes, 31, 114, 223)
                        end
                        prefab.lbDes:setString(Localize("stringPSkillOpen"))
                    end
                end
                prefab.butSk:setListener(function()
                    self:showTalentDialog(i)
                end)

                if i == 1 and GEngine.getConfig("isHeroBskillGuided"..context.sid..context.uid) then
                    GameLogic.getJumpGuide(const.JumpTypePass,prefab.butSk,100,70)
                end
                --引导
                if self.heroMsg.bskills[i].id>0 and not GEngine.getConfig("isHeroBskillGuided"..context.sid..context.uid) and not self.guideHeroBskillArrow then
                    self.guideHeroBskillArrow = context.guideHand:showArrow(prefab.butSk,100,100,20)
                end
                if context.guide:getStep().type ~= "finish" then
                    prefab.butSk:setEnable(false)
                end
            end
        end
    end
end

function HeroTalentSkillTab:showTalentDialog(bidx)
    if bidx == 1 then
       GameLogic.removeJumpGuide(const.JumpTypePass)
    end
    if self.inRequest then
        return
    end
    local hero = self.heroMsg
    local bskill = hero.bskills[bidx]
    if bskill.id==0 then
        display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"),Localize("alertTextNewBSkill"),{ctype=const.ResCrystal, cvalue=const.BSkillFirstCost, callback=Handler(self.onRequestBSkillOpen, self, bidx)}))
    else
        local haveGuide = false
        if self.guideHeroBskillArrow then
            haveGuide = true
            self.guideHeroBskillArrow:removeFromParent(true)
            self.guideHeroBskillArrow = nil
        end
        display.showDialog(HeroBSkillDialog.new(self.parent, self:getContext(), hero, bidx, haveGuide))
        if haveGuide then
            display.showDialog(StoryDialog.new({context=GameLogic.getUserContext(),storyIdx=305,callback=function()
                GEngine.setConfig("isHeroBskillGuided"..GameLogic.getUserContext().sid..GameLogic.getUserContext().uid,1,true)
            end}),false,true)
        end
    end
end

function HeroTalentSkillTab:onRequestBSkillOpen(bidx)
    if GameNetwork.lockRequest() then
        self.inRequest = true
        GameLogic.dumpCmds(true)
        GameNetwork.request("bopen", {hidx=self.heroMsg.idx, bidx=bidx}, self.onBSkillOpenOver, self)
    end
end

function HeroTalentSkillTab:onBSkillOpenOver(suc, data)
    GameNetwork.unlockRequest()
    self.inRequest = nil
    if suc then
        local context = self:getContext()
        local hidx = data.hidx
        local bidx = data.bidx
        local bskill = data.bskill
        local hero = context.heroData:getHero(hidx)
        hero.bskills[bidx].id = math.floor(bskill/100)
        hero.bskills[bidx].level = bskill%100
        hero.bskills[bidx].curLight = 0
        for i, lightSkill in ipairs(data.bsList) do
            hero:setBSkill(bidx, i, lightSkill[1], lightSkill[2])
        end
        context:changeRes(const.ResCrystal, -data.cost)
        GameLogic.statCrystalCost("英雄被动技能开启消耗",const.ResCrystal, -data.cost)
        -- 开启被动技能的战斗力提升
        context.heroData:setCombatData(hero)
        -- 日常任务被动技能
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroPassive,1)
        --成就
        local achieveData = GameLogic.getUserContext().achieveData
        achieveData:finish(8,1)
        if hero==self.heroMsg and not self:getDialog().deleted then
            self:reloadAll()
            self.parent:reloadTalentNum()
        end
    end
end
--辅助技能模块
local HeroHelpSkillTab = class(DialogTab)

function HeroHelpSkillTab:create()
    self.scene = GMethod.loadScript("game.View.Scene")
    self.heroMsg = self.parent.heroMsg
    local bg = ui.node({0,0},true)
    local temp

    self.view = bg
    local hero = self.heroMsg
    if hero.info.hsid>0 then
        GameUI.addSkillIcon(bg, 4, hero.info.hsid, 0.86, 1242, 602)
        temp = ui.label(hero:getHelpSkillFormatName(), General.font1, 40, {color={0,255,255},width=598})
        display.adapt(temp, 1641, 659, GConst.Anchor.Center)
        bg:addChild(temp)
        temp = ui.label("", General.font1, 40, {color={255,255,255},width=598})
        display.adapt(temp, 1641, 553, GConst.Anchor.Center)
        bg:addChild(temp)
        self.levelLabel = temp
        temp = ui.label("", General.font2, 40, {color={30,91,165},width=840,align=GConst.Align.Left})
        display.adapt(temp, 1547, 449, GConst.Anchor.Top)
        bg:addChild(temp)
        self.descLabel = temp
    end
    self:reloadAll()
    return bg
end

function HeroHelpSkillTab:reloadAll()
    local hero = self.heroMsg
    local hskill = hero:getHelpSkill()
    if hskill then
        self.levelLabel:setString(hskill.level .. "/" .. hskill.max)
        self.descLabel:setString(hero:getHelpSkillDesc(hskill))
    end
end

local HeroSoldierTab = class(DialogTab)

function HeroSoldierTab:create()--初始化佣兵
    self.scene = GMethod.loadScript("game.View.Scene")
    self.heroMsg = self.parent.heroMsg
    local bg = ui.node({0,0},true)
    self.soldierTalentIcon = {}
    local temp
    for i = 1, 2 do
        temp = ui.node(nil,true)
        display.adapt(temp,1452+180*(i-1), 942,GConst.Anchor.Center)
        bg:addChild(temp)
        table.insert(self.soldierTalentIcon, temp)
    end
    self.soldierTalentLabel = {}
    for i = 1, 2 do
        temp = ui.node(nil,true)
        display.adapt(temp,1452+240*(i-1), 942,GConst.Anchor.Center)
        bg:addChild(temp)
        table.insert(self.soldierTalentLabel, temp)
    end
    --右侧上方的UI(佣兵信息)
    self.view = bg
    temp = ui.scale9("images/bgWhite.9.png", 20, {232, 223})
    temp:setColor(cc.c3b(0,0,0))
    temp:setOpacity(79)
    temp:setCustomPoint(0,0.025,0,0,0)
    temp:setCustomPoint(1,0,0.945,0,1)
    temp:setCustomPoint(2,1,0.029,1,0)
    temp:setCustomPoint(3,0.935,1,1,1)
    display.adapt(temp, 1130, 994, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    temp = ui.scale9("images/bgDarkEdgeWhite.9.png", 20, {223,215})
    temp:setColor(cc.c3b(57,89,99))
    temp:setCustomPoint(1,0,0.975,0,1)
    temp:setCustomPoint(3,0.962,1,1,1)
    display.adapt(temp, 1126, 1007)
    bg:addChild(temp)
    --佣兵信息界面的佣兵等级
    temp = ui.label("", General.font1, 40, {color={255,255,255}})
    display.adapt(temp, 1236, 962, GConst.Anchor.Center)
    bg:addChild(temp)
    self.sLvLabel = temp
    --佣兵信息中的佣兵名称
    temp = ui.label("", General.font1, 40, {color={255,255,255},width=307})
    display.adapt(temp, 1520, 1197, GConst.Anchor.Center)
    bg:addChild(temp)
    self.sNameLabel = temp
    --生命值
    temp = ui.label(StringManager.getString("propertyHp"), General.font2, 32, {color={30,91,165}})
    display.adapt(temp, 1562-170, 1129, GConst.Anchor.Left)
    bg:addChild(temp)
    local ox1=temp:getContentSize().width+10
    --攻击力
    temp = ui.label(StringManager.getString("propertyDps"), General.font2, 32, {color={30,91,165}})
    display.adapt(temp, 1562-170, 1078, GConst.Anchor.Left)
    bg:addChild(temp)
    local ox2=temp:getContentSize().width+10
    --佣兵数目
    temp = ui.label(StringManager.getString("propertyTroops"), General.font2, 32, {color={30,91,165}})
    display.adapt(temp, 1562-170, 1026, GConst.Anchor.Left)
    bg:addChild(temp)
    local ox3=temp:getContentSize().width+10
    --生命值数值
    temp = ui.label("", General.font2, 40, {color={49,48,49}})
    display.adapt(temp, 1562-170+ox1, 1130, GConst.Anchor.Left)
    bg:addChild(temp)
    self.sHpLabel = temp
    --攻击力数值
    temp = ui.label("", General.font2, 40, {color={49,48,49}})
    display.adapt(temp, 1562-170+ox2, 1079, GConst.Anchor.Left)
    bg:addChild(temp)
    self.sAtkLabel = temp
    --佣兵数量
    temp = ui.label("", General.font2, 40, {color={49,48,49}})
    display.adapt(temp, 1562-170+ox3, 1025, GConst.Anchor.Left)
    bg:addChild(temp)
    self.sNumLabel = temp
    --强化天赋的数值
    temp = ui.label("", General.font1, 40, {color={255,255,255}})
    display.adapt(temp, 1509, 943, GConst.Anchor.Left)
    bg:addChild(temp)
    self.ssLvLabel1 = temp
    temp = ui.label("", General.font1, 40, {color={255,255,255}})
    display.adapt(temp, 1680, 943, GConst.Anchor.Left)
    bg:addChild(temp)
    self.ssLvLabel2 = temp
    --佣兵升级按钮
    temp=ui.button({208, 158},self.showUpgradeSoldier,{cp1=self, image="images/btnOrange.png"})
    display.adapt(temp, 1845, 1105, GConst.Anchor.Center)
    bg:addChild(temp)

    if self.scene.sceneType == "visit" then
        temp:setVisible(false)
    end

    local context = GameLogic.getUserContext()
    if context.guide:getStep().type ~= "finish" then
        temp:setVisible(false)
    end

    GameLogic.getJumpGuide(const.JumpTypeMercenary,temp,104,99)
    --蓝色的升级图标
    local but=temp:getDrawNode()
    temp = ui.sprite("images/btnUpgrade1.png",{90, 98})
    display.adapt(temp, 104, 96, GConst.Anchor.Center)
    but:addChild(temp)
    temp = ui.sprite("images/btnUpgrade2.png",{110, 122})
    display.adapt(temp, 118, 73, GConst.Anchor.LeftBottom)
    but:addChild(temp)
    self.upIcon = temp

    self:reloadSoldierBlock()

    return bg
end

function HeroSoldierTab:reloadSoldierBlock()--重载佣兵模块英雄强化专属技能
    local hero = self.heroMsg
    local parent = self.parent
    local bg = self.view
    if hero.info.sid>0 then
        parent.soldierBlock2:setVisible(true)
        parent.soldierTabView.tabLabels[1]:setVisible(true)
        parent.soldierTabView.tabBacks[1]:setSValue(0)
        if self.soldierIcon then
            self.soldierIcon:removeFromParent(true)
            self.soldierIcon = nil
        end
        self.soldierIcon = GameUI.addHeadIcon(bg, hero.info.sid, 0.96, 1237, 1116,{lv = hero.soldierLevel})
        self.sskillIcon = {}
        for i = 0, 1 do
            if self.sskillIcon[i+1] then
                self.sskillIcon[i+1]:removeFromParent(true)
                self.sskillIcon[i+1] = nil
            end
            --佣兵天赋的添加第一天赋
            self.sskillIcon[i+1] = GameUI.addSkillIcon(self.soldierTalentIcon[i+1], 2, hero.info.sid + i, 0.32, 0, 0)
        end
        --佣兵的天赋等级
        self.ssLvLabel = {self.ssLvLabel1,self.ssLvLabel2}
        local levels
        for i = 0, 1 do
            if i == 0 then
                levels = hero.soldierSkillLevel1
            else
                levels = hero.soldierSkillLevel2
            end
            self.ssLvLabel[i+1]:setString(StringManager.getFormatString("labelLevelFormat",{level=levels}))
        end
        --判断佣兵信息界面是否出现佣兵天赋的icon，第二佣兵天赋在这里添加
        if hero.soldierSkillLevel1==0 then
            self.sskillIcon[1]:setVisible(false)
            self.ssLvLabel[1]:setVisible(false)
        else
            self.sskillIcon[1]:setVisible(true)
            self.ssLvLabel[1]:setVisible(true)
        end
        if hero.soldierSkillLevel2==0 then
            self.sskillIcon[2]:setVisible(false)
            self.ssLvLabel[2]:setVisible(false)
        else
            self.sskillIcon[2]:setVisible(true)
            self.ssLvLabel[2]:setVisible(true)
        end
        --左侧的佣兵图片下方的佣兵等级
        self.sLvLabel:setString(hero.soldierLevel .. "/" .. const.MaxSoldierLevel)
        --self.upIcon有什么用？
        self.upIcon:setVisible(hero.soldierLevel<const.MaxSoldierLevel)
        --获取佣兵信息 hero是什么?heroData吗?heroModel?
        local sdata = hero:getSoldierData()
        --佣兵的名称
        self.sNameLabel:setString(hero:getSoldierName())
        --佣兵的生命值
        self.sHpLabel:setString(tostring(sdata.hp))
        --佣兵的攻击力
        self.sAtkLabel:setString(tostring(sdata.atk))
        --佣兵的数量
        self.sNumLabel:setString(tostring(sdata.num))
    else
        parent.soldierBlock2:setVisible(false)
        --parent.soldierTabView.tabLabels[1]:setVisible(false)
        --parent.soldierTabView.tabBacks[1]:setSValue(-100)
    end
end

function HeroSoldierTab:showUpgradeSoldier()--显示士兵等级
    GameLogic.removeJumpGuide(const.JumpTypeMercenary)
    display.showDialog(HeroSoldierDialog.new({params={parent=self, context=self:getContext(), heroMsg=self.heroMsg}}))
end

local HeroMicSkillTab = class(DialogTabLayout)

function HeroMicSkillTab:create()
    self.scene = GMethod.loadScript("game.View.Scene")
    self:setLayout("HeroInfoMicTab.json")
    self:loadViewsTo()
    self.btnUpgrade:setScriptCallback(ButtonHandler(self.onShowMic, self))
    if self.scene.sceneType == "visit" then
        self.btnUpgradeIcon:setVisible(false)
    end
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type ~= "finish" then
        self.btnUpgradeIcon:setVisible(false)
    end
    self:reloadData()
    return self.view
end

function HeroMicSkillTab:reloadData()--重载数据
    self.labelLevel:setString(Localizef("labelLevelFormat",{level=self.parent.heroMsg:getMicLevel()}))
end

function HeroMicSkillTab:onShowMic()
    display.showDialog(HeroMicDetailsDialog.new({parent=self, context=self:getContext(), heroMsg=self.parent.heroMsg,grandFather=self.parent}))
end

local HeroExtSkillTab = class(DialogTabLayout)
function HeroExtSkillTab:create()--专属技能初始化
    self.scene = GMethod.loadScript("game.View.Scene")
    self.heroMsg = self.parent.heroMsg

    local myJson = {type="tab", views={{id="descLabel", type="label", font="font1", size=40, width=520, align="Left", height=250, x=1680, y=1200, anchor="Top"}}}
    self:setLayout(myJson)
    self:loadViewsTo()
    local hero = self.heroMsg
    local id = hero.hid + 300
    GameUI.addSkillIcon(self.view, 6, id, 1.2, 1280, 1080)
    self.descLabel:setString(hero:getExtSkillDesc())
    return self.view
end

local HeroInfoTab = class(DialogTab)

function HeroInfoTab:create()
    self.scene = GMethod.loadScript("game.View.Scene")
    local dialog = self:getDialog()
    self.heroIdx = dialog.dialogParam
    self.skillIdx = dialog.skillIdx
    self.isAwakenActivity = dialog.isAwakenActivity
    self.callback = dialog.callback
    self.heroMsg = dialog.context.heroData:getHero(self.heroIdx)
    dialog.title:setString(StringManager.getString("titleHeroInfo"))
    dialog.title:setVisible(true)
    local bg = ui.node(nil, true)
    self.view = bg
    local hempty = true
    local hss = self.heroMsg.assists
    if hss then
        for i, hero in pairs(hss) do
            hempty = false
        end
    end
    self.hempty = hempty

    self:loadHeroBlock()
    self:loadSoldierBlock()
    self:loadSkillBlock()
    self:getDialog().questionTag = "dataQuestionHeroInfo"

    if self.heroMsg.hid == 4031 then
        self.heroMsg.heroState = 0
    end

    return self.view
end

function HeroInfoTab:reloadAll()--重载全部
    local dialog = self:getDialog()
    if dialog and not dialog.deleted then
        self:getDialog():reloadTab("info")
    end
end

function HeroInfoTab:loadHeroBlock()--载入英雄模块

    local bNode=ui.node()
    self.view:addChild(bNode)
    GameEvent.bindEvent(bNode,"refreshHeroData", self, self.reloadHeroData)

    local dialog = self:getDialog()
    local bg, temp = self.view
    temp = ui.sprite("images/dialogBackHeroInfo.png",{1019, 1317})
    display.adapt(temp, 40, 39, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    bg = ui.node(nil, true)
    self.view:addChild(bg, 1)
    self.heroBlock = bg
    temp = ui.label("", General.font1, 47)
    display.adapt(temp, 160, 1300, GConst.Anchor.Left)
    bg:addChild(temp)
    self.nameLabel = temp
    self:getDialog():initStars(self, bg)
    temp = ui.label("", General.font1, 47, {color={255,255,255}})
    display.adapt(temp, 71, 1103, GConst.Anchor.Left)
    bg:addChild(temp)
    self.levelLabel = temp
    temp = ui.sprite("images/proBack4.png",{582, 56})
    display.adapt(temp, 439, 1075, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    temp = ui.sprite("images/proFillerBlue.png",{574, 50})
    display.adapt(temp, 443, 1078, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    self.expProcess = temp
    temp = ui.label("", General.font1, 47, {color={255,255,255}})
    display.adapt(temp, 730, 1103, GConst.Anchor.Center)
    bg:addChild(temp)
    self.expLabel = temp


    local hero = self.heroMsg
    local id = hero.hid
    if id == 4031 then
        temp = ui.button({130, 160}, self.changeHeroState, {cp1=self})
        display.adapt(temp, 550, 950, GConst.Anchor.Center)
        bg:addChild(temp)
        local but = temp:getDrawNode()
        temp = ui.sprite("images/rotatingBg.png",{117,138})
        display.adapt(temp, 65, 80, GConst.Anchor.Center)
        but:addChild(temp)
        temp = ui.label(Localize("dataSkillName1_4131"), General.font1, 47)
        display.adapt(temp, 60, 80, GConst.Anchor.Center)
        but:addChild(temp)
    end

    temp = ui.button({130, 160}, self.changeHeroLock, {cp1=self})
    display.adapt(temp, 145, 159, GConst.Anchor.Center)
    bg:addChild(temp)
    local lockImages = {}
    local but = temp:getDrawNode()
    temp = ui.sprite("images/btnHeroLockOn.png",{117,138})
    display.adapt(temp, 65, 80, GConst.Anchor.Center)
    but:addChild(temp)
    lockImages[1] = temp
    temp = ui.sprite("images/btnHeroLockOff.png",{126,160})
    display.adapt(temp, 58, 68, GConst.Anchor.Center)
    but:addChild(temp)
    lockImages[2] = temp
    self.lockImages = lockImages
    if self.scene.sceneType == "visit" then
        for i,v in ipairs(lockImages) do
            v:setVisible(false)
        end
        but:setVisible(false)
    end

    temp = ui.button({147,139}, self.onHeroCollect, {cp1=self, image="images/btnHeroFrag.png"})--碎片,史诗级英雄有
    display.adapt(temp, 952, 140, GConst.Anchor.Center)
    bg:addChild(temp)
    self.fragBut = temp

    -- for i=1, 3 do
    --     temp = ui.colorNode({604, 2},{0,0,0})
    --     display.adapt(temp, 248, 50*i+30, GConst.Anchor.LeftBottom)
    --     bg:addChild(temp)
    -- end
    local infoLabels = {}--英雄信息左侧label
    temp = ui.label(StringManager.getString("propertyComb"), General.font1, 38, {color={255,120,0},align=GConst.Align.Right})
    display.adapt(temp, 516, 234, GConst.Anchor.RightBottom)
    bg:addChild(temp)
    temp = ui.label(StringManager.getString("propertyHp"), General.font2, 32, {color={255,255,255},width=268,align=GConst.Align.Right})
    display.adapt(temp, 516, 200, GConst.Anchor.RightBottom)
    bg:addChild(temp)
    temp = ui.label(StringManager.getString("propertyDps"), General.font1, 32, {color={255,255,255},width=268,align=GConst.Align.Right})
    display.adapt(temp, 516, 158, GConst.Anchor.RightBottom)
    bg:addChild(temp)
    temp = ui.label(StringManager.getString("propertyFavorite"), General.font2, 32, {color={255,255,255},width=268,align=GConst.Align.Right})--攻击偏好
    display.adapt(temp, 516, 80, GConst.Anchor.RightBottom)
    bg:addChild(temp)
    --old font size:36
    temp = ui.label("", General.font1, 38, {color={255,120,0},align=GConst.Align.Left})
    display.adapt(temp, 583, 234, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    infoLabels[4] = temp
    temp = ui.label("", General.font2, 32, {color={255,255,255},align=GConst.Align.Left})
    display.adapt(temp, 583, 200, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    infoLabels[1] = temp
    temp = ui.label("", General.font2, 32, {color={255,255,255},align=GConst.Align.Left})
    display.adapt(temp, 583, 158, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    infoLabels[2] = temp
    temp = ui.label("", General.font2, 32, {color={255,255,255},fontW=280,fontH=70,align=GConst.Align.Left})
    display.adapt(temp, 583, 80, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    infoLabels[3] = temp
    self.infoLabels = infoLabels
    local function upgradeHero()--英雄升级
        dialog.pushTab(dialog,"upgrade")
        GameLogic.removeJumpGuide(const.JumpTypeHeroInfo)
    end

    temp = ui.button({208, 158},upgradeHero,{cp1=dialog, cp2="upgrade", image="images/btnOrange.png"})
    display.adapt(temp, 940, 1231, GConst.Anchor.Center)
    bg:addChild(temp)
    self.upgradeBut = temp
    if self.scene.sceneType == "visit" then
        self.upgradeBut:setVisible(false)
    end
    --引导
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type == "upgradeHero" then
        context.guideHand:showArrow(temp,104,100)
    end

    GameLogic.getJumpGuide(const.JumpTypeHeroInfo,temp,104,79)


    local but=temp:getDrawNode()
    temp = ui.sprite("images/btnMBattle1.png",{121,117})
    display.adapt(temp, 104, 96, GConst.Anchor.Center)
    but:addChild(temp)
    temp = ui.sprite("images/btnUpgrade2.png",{110, 122})
    display.adapt(temp, 129, 76, GConst.Anchor.LeftBottom)
    but:addChild(temp)

    --参观神格又称觉醒
    if self.scene.sceneType == "visit" then
        temp = ui.button({291, 113} ,nil, {image="images/btnGreen.png"})
        display.adapt(temp, 207, 939, GConst.Anchor.Center)
        bg:addChild(temp)
        temp:setListener(function()
            display.showDialog(HeroAwakeDetailsDialog.new({parent=self, context=self:getContext(), heroMsg=self.heroMsg}))
        end)
        self.awakeBut = temp
        local but=temp:getDrawNode()
        temp = ui.label(StringManager.getString("labelAwakeOneSee"), General.font1, 45, {color={255,255,255}})
        display.adapt(temp, 145, 64, GConst.Anchor.Center)
        but:addChild(temp)
        temp = ui.label(StringManager.getString(""), General.font1, 44, {color={62,182,237}})
        display.adapt(temp, 121+72, 859, GConst.Anchor.Center)
        bg:addChild(temp)
        self.awakeLvLabel = temp

        local assistHero = {}
        local heros = self.heroMsg.assists
        for i=1,3 do
            if heros[i] then
                table.insert(assistHero, heros[i])
            end
        end
        if #assistHero>0 then
            temp = ui.button({291, 113} ,HeroAssistantDialog.new, {cp1 = assistHero,image="images/btnGreen.png"})
            display.adapt(temp, 889, 1260, GConst.Anchor.Center)
            bg:addChild(temp)
            local but=temp:getDrawNode()
            temp = ui.label(StringManager.getString("btnSeeHelp"), General.font1, 45, {color={255,255,255}})
            display.adapt(temp, 145, 64, GConst.Anchor.Center)
            but:addChild(temp)
        end
    else
        temp = ui.button({208, 158}, self.showAwakeDialog,{cp1=self, image="images/btnOrange.png"})
        display.adapt(temp, 193, 914, GConst.Anchor.Center)
        bg:addChild(temp)
        self.awakeBut = temp
        but=temp:getDrawNode()
        temp = ui.sprite("images/btnAwakeHero.png",{131, 111})
        display.adapt(temp, 32, 43, GConst.Anchor.LeftBottom)
        but:addChild(temp)
        temp = ui.sprite("images/btnUpgrade2.png",{110, 122})
        display.adapt(temp, 127, 71, GConst.Anchor.LeftBottom)
        but:addChild(temp)
        temp = ui.label("", General.font1, 44, {color={62,182,237}})
        display.adapt(temp, 193, 816, GConst.Anchor.Center)
        bg:addChild(temp)
        self.awakeLvLabel = temp

        --觉醒活动引导
        if self.isAwakenActivity then
            self.awakenActivityArrow=context.guideHand:showArrow(bg,193,1000,20)
        end
    end

    temp = ui.button({187, 179}, self.showEquipDialog,{cp1=self})
    display.adapt(temp, 914, 924, GConst.Anchor.Center)
    bg:addChild(temp)
    self.equipBut = {button=temp}
    but = temp:getDrawNode()
    temp = ui.node({238, 229})
    temp:setScale(0.786)
    temp:setVisible(true)
    but:addChild(temp)
    self.equipBut.backNode = temp

    local hero = self.heroMsg
    --刷新英雄的星星/荣耀
    self:getDialog():reloadStars(self, hero.info.maxStar, hero.starUp)
    --刷新英雄等级
    self.levelLabel:setString(StringManager.getFormatString("labelHeroLevel", {num=hero.level, max=hero.maxLv}))
    --刷新英雄经验
    local nextExp = hero:getNextExp()
    local exp = hero.exp
    if exp>=nextExp then
        self.expLabel:setString(tostring(exp))
        if nextExp==0 then
            nextExp = 1
            exp = 0
        else
            exp = nextExp
        end
    else
        self.expLabel:setString(exp .. "/" .. nextExp)
    end
    self.expProcess:setScaleX(574*exp/nextExp/self.expProcess:getContentSize().width)
    --显示英雄碎片按钮
    self.fragBut:setVisible((hero.info.fragNum or 0)>0 and hero.level==1)

    --刷新英雄图片
    if self.roleFeature then
        self.roleFeature:removeFromParent(true)
        self.roleFeature = nil
    end
    if hero.hid == 4031 then
        self.roleFeature = GameUI.addHeroFeature(self.view, 4031, 1, 540, 242, 0, nil, 0)
    else
        self.roleFeature = GameUI.addHeroFeature(self.view, hero.hid, 1, 540, 242, 0, nil, hero.awakeUp)
    end
    if self.roleJob then
        self.roleJob:removeFromParent(true)
        self.roleJob = nil
    end
    self.roleJob = GameUI.addHeroJobIcon(self.heroBlock, hero.info.job, 0.95, 95, 1300)
    self.nameLabel:setString(hero:getName())
    GameUI.setHeroNameColor(self.nameLabel, hero.info.displayColor or hero.info.color)
    --刷新英雄锁定状态
    self:refreshLock()
    self:reloadHeroData()
    self:reloadHeroAwake()

    if hero.info.job>0 then
        self.equipBut.button:setVisible(true)
        if hero.equip then
            self.equipBut.type = nil
        else
            self.equipBut.type = "add"
        end

        GameUI.updateEquipTemplate(self.equipBut.backNode, self.equipBut, hero.equip,{shadowAgin=true})
    else
        self.equipBut.button:setVisible(false)
    end
    --参观时装备
    if self.scene.sceneType == "visit" then
        if hero.equip then
            self.equipBut.button:setEnable(false)
        else
            self.equipBut.button:setVisible(false)
        end
    end
end

function HeroInfoTab:reloadHeroAwake()
    local hero = self.heroMsg
    if (hero.info.awake or 0)>0 then
        self.awakeBut:setVisible(true)
        self.awakeLvLabel:setVisible(true)
        local alv = hero.awakeUp
        if alv==0 then
            self.awakeLvLabel:setString("")
        else
            self.awakeLvLabel:setString(StringManager.getString("dataAwakeLv" .. alv))
        end
    else
        self.awakeBut:setVisible(false)
        self.awakeLvLabel:setVisible(false)
    end
end

function HeroInfoTab:reloadHeroData()
    local hero = self.heroMsg
    if self.hempty then
        hero.assists = {}
    end

    local hdata = hero:getHeroData()
    if not hero.combat then
        hero.combat = self:getContext().heroData:getCombatData(self.heroMsg)
    end
    self.infoLabels[1]:setString(tostring(hdata.hp))
    self.infoLabels[2]:setString(tostring(hdata.atk))
    self.infoLabels[3]:setString(StringManager.getString("enumBType" .. (hero.info.fav or 0)))
    self.infoLabels[4]:setString(tostring(hero.combat or 0))
end

function HeroInfoTab:loadSoldierBlock()--加载佣兵信息英雄强化专属技能
    local bg, temp

    bg = ui.node({0,0}, true)
    self.view:addChild(bg)
    self.soldierBlock = bg
    temp = ui.sprite("images/heroBackGrayAlpha.png",{908, 373})
    display.adapt(temp, 1098, 870, GConst.Anchor.LeftBottom)
    bg:addChild(temp)
    -- temp = ui.sprite("images/skill1_4316.png",{381, 114})
    -- display.adapt(temp, 1098, 1239, GConst.Anchor.LeftBottom)
    -- bg:addChild(temp)

    temp = ui.sprite("images/dialogBackSmallYellow.png",{897, 350})
    display.adapt(temp, 1098, 891, GConst.Anchor.LeftBottom)
    bg:addChild(temp,1)
    self.soldierBlock2 = ui.node({0,0}, true)
    self.soldierBlock:addChild(self.soldierBlock2,2)

    local tabTitles = {StringManager.getString("btnSoldierInfo")}--佣兵信息
    local tabs = {HeroSoldierTab.new(self)}
    if (not self.heroMsg.info.notStreng or self.heroMsg.info.notStreng>0) and self.heroMsg.info.job>0 and self.heroMsg.info.color>=4
        and self:getContext().buildData:getMaxLevel(const.Town) >= const.HeroTrialLimit then
        tabTitles[2] = StringManager.getString("btnHeroMic")--英雄强化
        tabs[2] = HeroMicSkillTab.new(self)
    end

    if (self.heroMsg.info.displayColor or self.heroMsg.info.color) >= 5 then
        table.insert(tabTitles, StringManager.getString("btnExtSkill"))--专属技能
        table.insert(tabs, HeroExtSkillTab.new(self))
    end

    local tab = DialogTemplates.createTabView(bg, tabTitles, tabs, {298,94,294,1239,-960,"images/dialogTabBackSmall1.png",40,122,46,0,0,0,0}, {actionType=2, tabType=2, viewBg=self.soldierBlock2})
    if self.heroMsg.info.job==0 then
        tab.tabLabels[1]:setString(Localize("btnSoldier"))--佣兵
        local temp = ui.label(Localize("notSoldierTips"), General.font1, 40, {color={255,255,255}})--经验芯片不携带佣兵
        display.adapt(temp, 1552, 1056, GConst.Anchor.Center)
        bg:addChild(temp,3)
    end
    if not self.soldierIdx then
        self.soldierIdx = 1
    end
    self.soldierTabs = tabs
    self.soldierTabView = tab--佣兵模块视图
    tab:changeTab(self.soldierIdx)
end
function HeroInfoTab:reloadSoldierBlock()--重载佣兵信息
    if self.soldierIdx == 1 then
        self.soldierTabs[1]:reloadSoldierBlock()
    end
end

function HeroInfoTab:showAwakeDialog()--觉醒对话框
    if self.awakenActivityArrow then
        GEngine.setConfig("isAwakenGuided"..GameLogic.getUserContext().sid..GameLogic.getUserContext().uid,1,true)--觉醒引导
        self.awakenActivityArrow:removeFromParent(true)
        self.awakenActivityArrow=nil
    end
    display.showDialog(HeroAwakeDialog.new({parent=self, context=self:getContext(), heroMsg=self.heroMsg,callback=self.callback}))
end

function HeroInfoTab:showEquipDialog()--展示装备对话框
    local context = GameLogic.getUserContext()
    local b = context.buildData:getBuild(6)
    if not b then
        display.pushNotice(Localize("stringHaveNotBuildEquip"))--如果没有建造装备工厂就提示跳出
        return
    end
    local equip = self.heroMsg.equip
    local dialog = EquipDialog.new({parent=self})
    if equip then
        dialog.selectedEidx = equip.idx
    end
    display.showDialog(dialog)
end

function HeroInfoTab:loadSkillBlock()--英雄技能模块
    local bg, temp
    bg = ui.node({0,0}, true)
    self.view:addChild(bg)
    self.skillBlock = bg

    local tabTitles = {StringManager.getString("btnMainSkill"), StringManager.getString("btnTalentSkill")}--主动技能,被动技能
    local tabs = {HeroMainSkillTab.new(self), HeroTalentSkillTab.new(self)}--助战技能
    if self.heroMsg.info.hsid>0 then
        tabTitles[3] = StringManager.getString("btnHelpSkill")--助战技能
        tabs[3] = HeroHelpSkillTab.new(self)
    end
    local tab = DialogTemplates.createTabView(bg, tabTitles, tabs, {298,94,294,742,-960,"images/dialogTabBackSmall1.png",40,122,46,0,0,0,0}, {actionType=2, tabType=2})
    if self.heroMsg.info.job==0 then
        self.skillIdx = 1
        tab.tabButs[2]:setVisible(false)
    end
    if not self.skillIdx then
        self.skillIdx = 1
    end

    self.skillTabs = tabs
    tab:changeTab(self.skillIdx)

    temp = ui.sprite("images/noticeBackRed.png",{55, 56})
    display.adapt(temp, 1608, 806, GConst.Anchor.LeftBottom)
    bg:addChild(temp,2)
    self.talentNumBack = temp
    temp = ui.label("", General.font2, 40, {color={255,255,255}})
    display.adapt(temp, 1635, 836, GConst.Anchor.Center)
    bg:addChild(temp,2)
    self.talentNumLabel = temp
    self:reloadTalentNum()
end

function HeroInfoTab:reloadTalentNum()--重载被动技能数目
    local talentNum = 3
    if self.heroMsg.info.job==0 or self.heroMsg.level<const.BSkillMinHLevel then
        talentNum = 0
    else
        for i=1, 3 do
            if self.heroMsg.bskills[i].id>0 then
                talentNum = talentNum-1
            end
        end
    end
    if talentNum>0 then
        self.talentNumBack:setVisible(true)
        self.talentNumLabel:setVisible(true)
        self.talentNumLabel:setString(tostring(talentNum))
    else
        self.talentNumBack:setVisible(false)
        self.talentNumLabel:setVisible(false)
    end
    if self.scene.sceneType == "visit" then
        self.talentNumBack:setVisible(false)
        self.talentNumLabel:setVisible(false)
    end
    local context = GameLogic.getUserContext()
    if context.guide:getStep().type ~= "finish" then
        self.talentNumBack:setVisible(false)
        self.talentNumLabel:setVisible(false)
    end
end

function HeroInfoTab:reloadMainSkills()--重载主动技能
    local tabs = self.skillTabs
    if tabs[1] and tabs[1].view then
        tabs[1]:reloadAll()
    end
    if tabs[3] and tabs[3].view then
        tabs[3]:reloadAll()
    end
end

function HeroInfoTab:reloadTalents()--重载被动技能
    local tabs = self.skillTabs
    if tabs[2] and tabs[2].view then
        tabs[2]:reloadAll()
    end
end
function HeroInfoTab:reloadETalents()--重载专属技能
    local tabExc = self.skillTabs
    if tabs[3] and tabs[3].view then
        tabs[3]:reloadAll()
    end
end
function HeroInfoTab:changeHeroLock()--改变英雄锁定状态
    self:getContext().heroData:changeHeroLock(self.heroMsg)
    self:refreshLock()
    display.pushNotice(Localize("noticeLockHero" .. self.heroMsg.lock))
end

function HeroInfoTab:changeHeroState()--改变乔巴英雄状态
    local hero = self.heroMsg
    hero.heroState = math.abs(hero.heroState-1)
    self.roleFeature:removeFromParent(true)
    if hero.heroState == 1 then
        self.roleFeature = GameUI.addHeroFeature(self.view, 40312, 1, 540, 242, 0, nil, 0)
    else
        self.roleFeature = GameUI.addHeroFeature(self.view, 4031, 1, 540, 242, 0, nil, 0)
    end
    GameEvent.sendEvent("ChangeChopperDesc")
end

function HeroInfoTab:refreshLock()
    local lockIdx = self.heroMsg.lock
    self.lockImages[2-lockIdx]:setVisible(true)
    self.lockImages[1+lockIdx]:setVisible(false)
end

function HeroInfoTab:onHeroCollect(force)
    local hero = self.heroMsg
    local louts = hero.layouts
    local isFight = false
    for lid, l in pairs(louts) do
        if l.type>0 then
            isFight = true
            break
        end
    end
    if hero.lock==1 then
        display.pushNotice(Localize("noticeLockHeroExplain"))--锁定英雄防止被分解
        return
    end
    if not force then
        local strKey="alertTextHeroFrag"--分解您的英雄将得到[num]个[name]碎片，但是这英雄将消失，继续吗
        if isFight then
            strKey="alertTextHeroFrag2"--该英雄已出战（或助战），是否要下阵并分解
        end
        display.showDialog(AlertDialog.new(3, Localize("btnHeroFragCollect"), Localizef(strKey,{name=hero:getName(), num=math.floor(hero.info.fragNum*0.8)}),{callback=Handler(self.onHeroCollect, self, true)}))--分解英雄
    else
        self:getContext().heroData:explainHero(hero)
        self:getDialog():popTab()
    end
end

return HeroInfoTab
