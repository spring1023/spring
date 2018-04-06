
GMethod.loadScript("game.GameLogic.HeroTrialSkill")
local const = GMethod.loadScript("game.GameLogic.Const")
--英雄试炼战斗界面
local HeroTrialBattleInterface = class2("HeroTrialBattleInterface",function()
    return BaseView.new("HeroTrialBattleInterface.json")
end)

function HeroTrialBattleInterface:ctor(menu)
    self.menu = menu
    menu.view:addChild(self)
    self:initBattle()
    self:initUI()
end
function HeroTrialBattleInterface:initNode()
    local bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.LeftTop, {datum = GConst.Anchor.LeftTop,scale=ui.getUIScale2()})
    self:addChild(bg)
    self.LeftTopNode=bg

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.Top, {datum = GConst.Anchor.Top,scale=ui.getUIScale2()})
    self:addChild(bg)
    self.TopNode=bg

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.RightTop, {datum = GConst.Anchor.RightTop,scale=ui.getUIScale2()})
    self:addChild(bg)
    self.RightTopNode=bg

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.LeftBottom, {datum = GConst.Anchor.LeftBottom,scale=ui.getUIScale2()})
    self:addChild(bg)
    self.LeftBottomNode=bg

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.Bottom, {datum = GConst.Anchor.Bottom,scale=ui.getUIScale2()})
    self:addChild(bg)
    self.BottomNode=bg

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.RightBottom, {datum = GConst.Anchor.RightBottom,scale=ui.getUIScale2()})
    self:addChild(bg)
    self.RightBottomNode=bg

    bg=ui.node()
    display.adapt(bg, 0, 0, GConst.Anchor.Left, {datum = GConst.Anchor.Left,scale=ui.getUIScale2()})
    self:addChild(bg)
    self.LeftNode=bg

    bg=ui.node()
    display.adapt(bg, 0, -100, GConst.Anchor.Right, {datum = GConst.Anchor.Right,scale=ui.getUIScale2()})
    self:addChild(bg)
    self.RightNode=bg
end
function HeroTrialBattleInterface:initUI()
    self:initNode()

    self:loadView("leftTopViews",self.LeftTopNode)
    self:loadView("topViews",self.TopNode)
    self:loadView("rightTopViews",self.RightTopNode)
    self:insertViewTo()


    --我数据
    local mcontext = GameLogic.getCurrentContext()
    --对手数据
    local econtext = GameLogic.getCurrentContext().enemy

    local pvtdata = mcontext.pvtdata
    self.pvtdata = pvtdata
    --我
    --玩家名字
    local name = GameLogic.getUserContext():getInfoItem(const.InfoName)
    if name=="" then
        name = "TEST" .. (mcontext.uid or 0)
    end
    self.labelHeroTrialPlayerName:setString(name)
    --现有积分
    self.labelPlayerIntegralValue:setString(pvtdata.sc)

    --敌方
    --玩家名称
    local dplay = mcontext.dplay
    local name = dplay.uinfo[2]
    if name=="" then
        name = "TEST" .. (mcontext.uid or 0)
    end
    self.labelHeroTrialOpponentdeName:setString(name)
    --现有积分
    self.labelOpponentIntegral:setString2(dplay.uinfo[5])
    --胜利
    self.labelOpponentdeWinIntegral:setString2(dplay.getscore .. Localize("labelSc"))
    --失败
    self.labelOpponentdeFailIntegral:setString2(dplay.lostscore .. Localize("labelSc"))
    self.winSc,self.loseSc = dplay.getscore,dplay.lostscore
    --未出场英雄
    self.labelNoHeroNumTips:setVisible(false)
    self.labelNoHeroNum:setVisible(false)
    self.labelNoHeroNum:setString2("0")


    self:battleBefor()
end

function HeroTrialBattleInterface:battleBefor()
    self:loadView("battleBefor_LeftBottomViews",self.LeftBottomNode)
    self:loadView("battleBefor_RightBottomViews",self.RightBottomNode)
    self:insertViewTo()

    --设置阵容
    self.butSetLineup:setListener(function()
        HeroTrialLineupDialog.new(function()
        end)
    end)
    --开始战斗
    self.butBattleStart:setListener(function()
        self:readyToStart()
    end)

    --结束战斗
    self.butRed:setListener(function()
        print("结束战斗")
        if self.menu.scene.battleData.state~= 0 then
            self:pvtafterbattle()
        else
            local loading = GMethod.loadScript("game.Controller.ChangeController")
            loading:startExit(1)
        end
    end)
end

function HeroTrialBattleInterface:readyToStart()
    --设置英雄位置
    self.minitPos = {}
    self.einitPos = {}

    local builds = GameLogic.getCurrentContext().buildData:getSceneBuilds()
    for i,v in ipairs(builds) do
        GameLogic.getCurrentContext().heroData:changeHeroLayoutPos(const.LayoutPvtAtk,v.id,v.vstate.bgx,v.vstate.bgy)
        self.minitPos[v.id] = {v.vstate.bgx,v.vstate.bgy}
    end

    local builds = GameLogic.getCurrentContext().enemy.buildData:getSceneBuilds()
    local bnum=0
    for i,v in pairs(builds) do
        if v.id then
            self.einitPos[v.id] = {v.vstate.bgx,v.vstate.bgy}
            bnum=bnum+1
        end
    end
    --不足三个，重给位置
    if bnum<3 then
        local pos={{24,34},{18,34},{12,34}}
        for i=1,3 do
            self.einitPos[i] = pos[i]
        end
    end


    GameEvent.sendEvent(GameEvent.EventBattleBegin, {type=5})
end

function HeroTrialBattleInterface:battleAfder()
    local bdata = self.menu.scene.battleData
    self.dheroShow = {}
    local temp

    local hnum = bdata.dhNum
    hnum = hnum>3 and 3 or hnum
    for i=1,hnum do
        local bg=ui.node()
        display.adapt(bg, 1862-2048, 962-(i-1)*215-768, GConst.Anchor.Right)
        self.RightNode:addChild(bg)
        self:loadView("bttleAfter_RightNodeViews",bg)
        self:insertViewTo()
        self.dheroShow[i] = {headBg=bg, head = GameUI.addHeroHead(bg,3001,{size={112,114},x=17,y=49})}
        self.dheroShow[i].hp = self.dheroHp
        self.dheroShow[i].ag = self.dheroAngerPro
    end
    self.heroShow = {}
    for i=1, 3 do
        local bg=ui.node()
        display.adapt(bg, 36+(i-1)*200, 76, GConst.Anchor.LeftBottom)
        self.LeftBottomNode:addChild(bg)

        local skillBut=ui.button({178, 245},nil, {})
        display.adapt(skillBut,0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(skillBut)

        --自动战斗提示
        skillBut:setListener(function()
            display.pushNotice(Localize("stringTrialBattle1"))
        end)

        local upNode = ui.node()
        bg:addChild(upNode)
        self:loadView("bttleAfter_LeftBottomNodeViews",upNode)
        self.heroShow[i]= {headBg=upNode, heroUpNode = upNode, skillBg=skillBut:getDrawNode(), smHead = GameUI.addHeadIcon(upNode,3001,0.22,8,278)}
        self:loadView("bttleAfter_LeftBottomNodeButtonViews",skillBut:getDrawNode())
        self:insertViewTo()
        self.heroShow[i].hp = self.heroHp

        self.heroShow[i].needAnger = self.labelNeedAnger
        self.heroShow[i].angerNode = {self.labelNeedAnger,self.labelNeedAnger3}
        --技能图标
        self.heroShow[i].skill = GameUI.addSkillIcon2(skillBut:getDrawNode(), 1, 4101, 158,216,10,21)

        --冷却node
        self.heroShow[i].cold = self.codeNode

        --助战英雄

        for j=1,3 do
            temp = ui.sprite("images/bgWhite.9.png")
            ui.setColor(temp, GConst.Color.Black)
            display.adapt(temp,-9+(j-1)*63, -62, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            if bdata.tbHero[i][j] then
                local hero = bdata.tbHero[i][j]
                GameUI.addHeadIcon(bg,hero.hid,0.22,-5+(j-1)*63+225*0.11,-58+225*0.11,{lv = hero.awakeUp})
            end
        end
    end

    --试炼 技能 各种令
    local skillNode = ui.node({591,195})
    display.adapt(skillNode,67,-511, GConst.Anchor.LeftBottom)
    self.LeftTopNode:addChild(skillNode)
    local skillImg = ui.scale9("images/heroTrialSkillBack.png",60,{591,195})
    display.adapt(skillImg,0,0, GConst.Anchor.LeftBottom)
    skillNode:addChild(skillImg)


    -- local skillNode=ui.node()
    -- display.adapt(skillNode,0,-768, GConst.Anchor.LeftBottom)
    -- self.LeftNode:addChild(skillNode)

    local mcontext = GameLogic.getCurrentContext()
    local skilL = mcontext.pvtdata.skills
    local canUse = {}
    for i,v in ipairs(skilL) do
        if GameLogic.getUserContext():getItem(12,v)>0 then
            table.insert(canUse,v)
        end
    end
    if #canUse == 0  then
        skillNode:setVisible(false)
    end

    self.usedSkill = {}
    local skNum=0
    for i=1,#canUse do
        local htSkillBut = ui.button({158,158},nil,{})
        display.adapt(htSkillBut, 10+168*(i-1),24, GConst.Anchor.LeftBottom)
        skillNode:addChild(htSkillBut)
        htSkillBut.icon = GameUI.addItemIcon(htSkillBut:getDrawNode(),12,canUse[i],158/198,79,79)

        htSkillBut:setListener(function()
            if htSkillBut.used then
                display.pushNotice(Localize("stringTrialBattle2"))
            else
                htSkillBut.used = true
                htSkillBut.icon:setSValue(-100)
                GameLogic.getUserContext():changeItem(12,canUse[i],-1)
                HeroTrialSkill.new(canUse[i])
                table.insert(self.usedSkill,canUse[i])
            end

        end)
        skNum = i
    end
    local w = skNum*168+87
    skillImg:setContentSize(cc.size(w,195))

    local butSanJiao = ui.button({60,195}, nil, {})
    display.adapt(butSanJiao, w-46, 97, GConst.Anchor.Center)
    skillNode:addChild(butSanJiao)
    local temp = ui.sprite("images/chatRoomBtn.png", {35, 75})
    display.adapt(temp, 30, 97, GConst.Anchor.Center)
    butSanJiao:getDrawNode():addChild(temp)

    butSanJiao.ishide = false
    local moveX = w-16
    butSanJiao:setListener(function()
        if butSanJiao.ishide then
            butSanJiao.ishide = false
            temp:setFlippedX(false)
            skillNode:runAction(ui.action.action({"moveBy",0.2,moveX,0}))
        else
            butSanJiao.ishide = true
            temp:setFlippedX(true)
            skillNode:runAction(ui.action.action({"moveBy",0.2,-moveX,0}))
        end
    end)


    self:reloadTbHero()
end

function HeroTrialBattleInterface:reloadTbHero()
    local bdata = self.menu.scene.battleData
    if not self.tbHeroNode then
        self.tbHeroNode = ui.node()
        self.BottomNode:addChild(self.tbHeroNode)
    end
    self.tbHeroNode:removeAllChildren(true)

    --替补英雄
    self:loadView("bttleAfter_BottomViews",self.tbHeroNode)
    local heroNode1=ui.button({178, 245},nil, {})
    display.adapt(heroNode1,777-1024, 76, GConst.Anchor.LeftBottom)
    self.tbHeroNode:addChild(heroNode1)

    self:loadView("bttleAfter_HeroNodeViews1",heroNode1:getDrawNode())

    self:insertViewTo()
    --自动战斗
    self.butAutoBattle:setListener(function()
        display.pushNotice(Localize("stringTrialBattle1"))
    end)

    local hero4 = bdata.heros[4] and bdata.heros[4].hero
    if hero4 then
        if bdata.heros[4].role and bdata.heros[4].role.deleted then
            self.lvColor:setVisible(false)
            self.lvNum:setVisible(false)
            local temp = ui.sprite("images/iconDeath.png",{158, 216})
            display.adapt(temp, 12,20, GConst.Anchor.LeftBottom)
            heroNode1:getDrawNode():addChild(temp)
        else
            GameUI.addHeroHead(heroNode1:getDrawNode(),hero4.hid,{size={158,216},x=10,y=20})
            --等级
            local _heroColorSet = {180, -57, 0, 111, 57}
            self.lvColor:setHValue(_heroColorSet[hero4.info.color])
            self.lvNum:setString(hero4.level)
            local pos=hero4.layouts[const.LayoutPvtAtk].pos
            self.labelReleaseSkillTips:setString(Localize("dataHeroTrialLine"..(pos-2)))
        end
    else
        self.lvColor:setVisible(false)
        self.lvNum:setVisible(false)
        self.labelReleaseSkillTips:setVisible(false)
    end


    for i=1,5 do
        local heroNode2=ui.button({160, 221},nil, {})
        display.adapt(heroNode2,999-1024+(i-1)*180, 76, GConst.Anchor.LeftBottom)
        self.tbHeroNode:addChild(heroNode2)
        self:loadView("bttleAfter_HeroNodeViews2",heroNode2:getDrawNode())
        heroNode2:setListener(function()
            if bdata.heros[4+i].hero and not bdata.heros[4+i].role then
                bdata.heros[4+i],bdata.heros[4] = bdata.heros[4],bdata.heros[4+i]

                self:reloadTbHero()
            end
        end)
        self:loadView("bttleAfter_HeroNodeViews2Lv",heroNode2:getDrawNode())
        self:insertViewTo()
        local heroOr = bdata.heros[i+4] and bdata.heros[i+4].hero
        if heroOr then
            if bdata.heros[i+4].role and bdata.heros[i+4].role.deleted then
                self.lvColor:setVisible(false)
                self.lvNum:setVisible(false)
                local temp = ui.sprite("images/iconDeath.png",{138, 189})
                display.adapt(temp, 12,20, GConst.Anchor.LeftBottom)
                heroNode2:getDrawNode():addChild(temp)
            else
                GameUI.addHeroHead(heroNode2:getDrawNode(),heroOr.hid,{size={138,189},x=10,y=20})
                --等级
                local _heroColorSet = {180, -57, 0, 111, 57}
                self.lvColor:setHValue(_heroColorSet[heroOr.info.color])
                self.lvNum:setString(heroOr.level)
            end
        else
            self.lvColor:setVisible(false)
            self.lvNum:setVisible(false)
        end

    end
end


function HeroTrialBattleInterface:initBattle()
    RegUpdate(self,function(diff)
        if self.menu.scene.replay then
            self.menu.scene.replay:update(diff)
        end
    end,0)

    self.menu.scene.replay:addUpdateObj(self)
    self.menu.scene.replay.isStartBattle = true
    self:initBattleData()
end

function HeroTrialBattleInterface:initBattleData()
    local bdata = self.menu.scene.battleData



    bdata.time = 600
    bdata.state = 0

    --英雄试炼冷却到了就放技能 怒气设置充足
    bdata.anger = 100
    bdata.eanger = 100
end

function HeroTrialBattleInterface:startBattle()
    music.setBgm("music/battleAttack.mp3")
    self.LeftBottomNode:removeAllChildren(true)
    self.BottomNode:removeAllChildren(true)
    self.RightBottomNode:removeAllChildren(true)


    local bdata = self.menu.scene.battleData
    local scene = self.menu.scene

    bdata.heros = {}
    bdata.dheros= {}
    bdata.dhNum = 0
    bdata.tbHero = {{},{},{}}
    bdata.dtbHero = {{},{},{}}

    local allHeros={}
    local alldHeros={}

    for i=1,9 do
        local hero =GameLogic.getCurrentContext().heroData:getHeroByLayout(const.LayoutPvtAtk,i,1)
        if hero then
            table.insert(allHeros,{hero=hero,sinfo=hero:getSoldierInfo(),sdata=hero:getSoldierData()})
        end
        local hero = GameLogic.getCurrentContext().enemy.heroData:getHeroByLayout(const.LayoutPvtDef,i,1)
        if hero then
            table.insert(alldHeros,{hero=hero,sinfo=hero:getSoldierInfo(),sdata=hero:getSoldierData()})
        end
    end

    for i=1,9 do
        if allHeros[i] then
            bdata.heros[i]=allHeros[i]
        else
            bdata.heros[i] = {}
        end
        if i<=3 then
            for j=2,4 do
                local hero = GameLogic.getCurrentContext().heroData:getHeroByLayout(const.LayoutPvtAtk,i,j)
                if hero then
                    bdata.tbHero[i][j-1] = hero
                end
                local hero = GameLogic.getCurrentContext().enemy.heroData:getHeroByLayout(const.LayoutPvtDef,i,j)
                if hero then
                    bdata.dtbHero[i][j-1] = hero
                end
            end
        end

        if alldHeros[i] then
             bdata.dheros[i]=alldHeros[i]
             bdata.dhNum = bdata.dhNum+1
        else
            bdata.dheros[i] = {}
        end
    end

    if bdata.state == 0 then
        bdata.state = 1
        bdata.time = 180
        --文字 结束倒计时
        self.labelBattleStart:setString(Localize("labelBattleEnd"))
        self.btnEndBattle:setString(Localize("btnGiveup"))
    end

    --加英雄
    for i=1,3 do
        local item = bdata.heros[i]
        if item.hero then
            local person = item.hero:getControlData()
            GameLogic.addSpecialBattleBuff(item.hero, person, 1, self.menu.scene)
            local params = {person = person, state=AvtControlerState.BATTLE, group=1, hpos=i}
            item.role = PersonUtil.C(params)
            item.role.assistHero = bdata.tbHero[i]
            local initPos = self.minitPos[i]
            item.role:addToScene(self.menu.scene,initPos[1],initPos[2],3)
            self:addEffectCS(initPos)
        end

        local item = bdata.dheros[i]
        if item.hero then
            local person = item.hero:getControlData()
            GameLogic.addSpecialBattleBuff(item.hero, person, 2, self.menu.scene)
            local params = {person = person, state=AvtControlerState.BATTLE, group=2, hpos=i}
            item.role = PersonUtil.C(params)
            item.role.assistHero = bdata.dtbHero[i]
            local initPos = self.einitPos[i]
            item.role:addToScene(self.menu.scene,initPos[1],initPos[2],6)

            self:addEffectCS(initPos)
        end
    end

    self:battleAfder()
end

function HeroTrialBattleInterface:addEffectCS(p)
    local p = clone(p)
    p[1],p[2] = self.menu.scene.map.convertToPosition(p[1],p[2])
    p[2]=p[2]+69*4/2
    local effectManager=GameEffect.new("HeroTrialCS.json")
    local views=effectManager.views
    local bg = self.menu.scene.bottom
    local viewNode = ui.node()
    bg:addChild(viewNode, 100)
    viewNode:setScaleY(3/4)
    viewNode:setPosition(p[1],p[2])
    effectManager:addEffect("views1_delay0",viewNode)
    local temp = views.base_exe_9
    temp:runAction(ui.action.arepeat({"rotateBy",5,360}))
    temp = views.zhaohuan2_1
    temp:runAction(ui.action.arepeat({"rotateBy",4,-360}))
end

function HeroTrialBattleInterface:checkNoBattle(heros)
    for i,v in ipairs(heros) do
        if v.hero and not v.role then
            return true
        end
    end
    return false
end

function HeroTrialBattleInterface:moveHeroList(heros,idx,group)
    local temp = {}
    for i,v in ipairs(heros) do
        temp[i] = v
    end

    heros[9] = temp[idx]
    local addIdx
    for i=4,9 do
        if temp[i].hero and not temp[i].role then
            heros[idx] = temp[i]

            local item = heros[idx]
            local person = item.hero:getControlData()
            GameLogic.addSpecialBattleBuff(item.hero, person, group, self.menu.scene)
            local params = {person = person, state=AvtControlerState.BATTLE, group=group, hpos=idx}
            local pos
            if group==1 then
                pos=item.hero.layouts[const.LayoutPvtAtk].pos
            else
                pos=item.hero.layouts[const.LayoutPvtDef].pos
            end
            --主动技
            if pos==6 then
                params.quickPlaySkill=true
            end
            item.role = PersonUtil.C(params)
            local initPos = group == 1 and self.minitPos[idx] or self.einitPos[idx]
            item.role:addToScene(self.menu.scene,initPos[1],initPos[2],3*group)
            --天神技
            if pos==9 and item.hero and item.hero.awakeUp>=5 then
                item.role:ppexeGodSkill()
            end
            addIdx = i
            break
        end
    end

    for i=4,8 do
        for j=addIdx+1,9 do
            if temp[j] then
                heros[i] = temp[j]
                addIdx = j
                break
            end
        end
    end
    self:reloadTbHero()
end

function HeroTrialBattleInterface:update(diff)
    if not self.menu.inCount then
        return
    end
    local bdata = self.menu.scene.battleData
    local scene = self.menu.scene
    bdata.time = bdata.time - diff
    if bdata.time then
        if bdata.time<=0 then
            if bdata.state == 0 then
                self:readyToStart()
            else
                self:pvtafterbattle(true)
            end
        end
        --时间
        self.labelBattleTime1:setString(Localizet(bdata.time))
    end
    --怒气永远够
    bdata.anger = 100
    bdata.eanger = 100

    if bdata.state == 1 then
        --界面显示
        if self.heroShow then
            for i,v in ipairs(self.heroShow) do
                local role = bdata.heros[i] and bdata.heros[i].role
                local hero  = bdata.heros[i] and bdata.heros[i].hero
                if role and not role.deleted then
                    --血条
                    v.hp:setProcess(true,role.avtInfo.nowHp/role.avtInfo.maxHp)
                    v.hp:setVisible(true)
                    v.heroUpNode:setVisible(true)
                    --小头像
                    if v.headId ~= role.sid then
                        local bg = v.headBg
                        v.headId = role.sid
                        v.smHead:removeFromParent(true)
                        v.smHead = GameUI.addHeadIcon(bg,role.sid,0.22,8,278,{lv = hero.awakeUp})

                        v.skill:removeFromParent(true)
                        v.skillId = role.sid+100
                        v.skill = GameUI.addSkillIcon2(v.skillBg, 1, role.sid+100, 158,216,10,21)
                    end
                    --需要怒气
                    self.heroShow[i].needAnger:setString(role.avtInfo.person.actSkillParams.x/10)

                    for i2,v2 in ipairs(v.angerNode) do
                        v2:setVisible(false)
                    end
                    --冷却
                    if role.coldTime2 and role.coldTime2>0 then
                        v.cold:setVisible(true)
                        v.cold:setProcess(true,role.coldTime2 and role.coldTime2/role.allColdTime2)
                    else
                        v.cold:setVisible(false)
                    end
                else
                    --血条
                    v.hp:setVisible(false)
                    --小头像
                    v.heroUpNode:setVisible(false)
                    --冷却
                    v.cold:setVisible(false)
                end
                if role and role.deleted then
                    if self:checkNoBattle(bdata.heros) then
                        self:moveHeroList(bdata.heros,i,1)
                    else
                        if v.skillId ~= 0 then
                            v.skillId = 0
                            v.skill:removeFromParent(true)
                            v.skill = ui.sprite("images/iconDeath.png", {158, 216})
                            display.adapt(v.skill, 10, 21, GConst.Anchor.LeftBottom)
                            v.skillBg:addChild(v.skill)
                            v.headId = 0

                            for i2,v2 in ipairs(v.angerNode) do
                                v2:setVisible(false)
                            end
                        end
                    end
                end
            end
        end

        if self.dheroShow then
            for i,v in ipairs(self.dheroShow) do
                local role = bdata.dheros[i] and bdata.dheros[i].role
                if role and not role.deleted then
                    v.hp:setProcess(true,role.avtInfo.nowHp/role.avtInfo.maxHp)
                    v.ag:setProcess(true,role.coldTime2 and (1-role.coldTime2/role.allColdTime2) or 0)

                    if v.headId ~= role.sid then
                        local bg = v.headBg
                        v.head:removeFromParent(true)
                        v.headId = role.sid
                        v.head = GameUI.addHeroHead(bg, role.sid, {size={112,114},x=17,y=49})
                    end
                end

                if role and role.deleted then
                    if self:checkNoBattle(bdata.dheros) then
                        self:moveHeroList(bdata.dheros,i,2)
                    else
                        local bg = v.headBg
                        if v.headId ~= 0 then
                            v.head:removeFromParent(true)
                            v.head = ui.sprite("images/iconDeath.png", {112,114})
                            v.headId = 0
                            display.adapt(v.head, 17, 49)
                            bg:addChild(v.head, 0)

                            v.hp:setProcess(true,0)
                            v.ag:setProcess(true,0)
                        end

                    end
                end


            end
        end

        --敌方未出战英雄
        local notToNum = 0
        if bdata.dheros then
            for i,v in ipairs(bdata.dheros) do
                if v.hero and not v.role then
                    notToNum = notToNum+1
                end
            end
        end
        self.labelNoHeroNum:setString2(notToNum)
        self.labelNoHeroNumTips:setVisible(true)
        self.labelNoHeroNum:setVisible(true)

        --判断战斗结束
        if bdata.heros then
            local isLose = bdata.groups[1].totalTroops <= bdata.groups[1].deadTroops and bdata.groups[1].tempTroops == 0
            for i,v in ipairs(bdata.heros) do
                if v.hero then
                    if v.role and v.role.deleted then

                    else
                        isLose = false
                    end
                end
            end

            local isWin = bdata.groups[2].totalTroops <= bdata.groups[2].deadTroops and bdata.groups[2].tempTroops == 0
            for i,v in ipairs(bdata.dheros) do
                if v.hero then
                    if v.role and v.role.deleted then

                    else
                        isWin = false
                    end
                end
            end

            if isLose or isWin then
                self.isWin = isWin
                self:pvtafterbattle(true)
            end
        end
    end
end

------------------------------------------------------
--pvt
function HeroTrialBattleInterface:pvtafterbattle(isAffirm)
    if isAffirm then
        local bdata = self.menu.scene.battleData
        self.menu.scene.replay:init()
        bdata.getScore = self.isWin and self.winSc or -self.loseSc
        bdata.isWin = self.isWin
        bdata.index = self.pvtdata.idx
        bdata.usedSkill = self.usedSkill
        self:setVisible(false)
        bdata.state = 2
        bdata.time = nil
        display.showDialog(BattleResultDialog.new({battleData = bdata}))
    else
        local title = Localize("alertTitleNormal")
        local text = Localizef("alertTextExitBattle")
        display.showDialog(AlertDialog.new(4,title,text,{callback=function()
            self:pvtafterbattle(true)
        end}))
    end
end

return HeroTrialBattleInterface








