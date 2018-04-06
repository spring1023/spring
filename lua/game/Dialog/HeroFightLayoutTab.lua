local const = GMethod.loadScript("game.GameLogic.Const")
local HeroFightLayoutTab = class(DialogTabLayout)

function HeroFightLayoutTab:create()
    self:setLayout("HeroFightLayoutTab.json")
    self:loadViewsTo()

    local dialog = self:getDialog()
    local context = self:getContext()

    dialog:initStars(self, self.nodeHeroInfo.view)
    self.btnLeft:setScriptCallback(ButtonHandler(self.onChangePos, self, -1))
    self.btnRight:setScriptCallback(ButtonHandler(self.onChangePos, self, 1))
    self.btnEquip:setScriptCallback(ButtonHandler(self.onEquipAction, self))
    self.btnHeroInfo:setScriptCallback(ButtonHandler(self.onHeroInfo, self))
    return self.view
end

function HeroFightLayoutTab:onEnter()
    self:onChangePos(0)
    self:reloadHero()
    self.parent:reloadHelpNum()
    self:getDialog().questionTag = "dataQuestionHeroFight"
end

function HeroFightLayoutTab:onChangePos(dir)
    local layoutParam = self:getDialog().layoutParam
    local context = self:getContext()
    local posStart, posEnd
    if layoutParam.posStart then
        posStart, posEnd = layoutParam.posStart, layoutParam.posEnd
    else
        posStart, posEnd = 1, context.heroData.baseNum
    end
    local newPos = layoutParam.pos
    while true do
        newPos = newPos+dir
        if newPos<posStart then
            newPos = posEnd
        elseif newPos>posEnd then
            newPos = posStart
        end
        if newPos==layoutParam.pos then
            break
        elseif layoutParam.forceLayouts then
            break
        elseif context.heroData.bases[newPos].level>0 then
            break
        end
    end
    -- self.btnLeft:setVisible(newPos>posStart)
    -- self.btnRight:setVisible(newPos<posEnd)
    if newPos~=layoutParam.pos then
        layoutParam.pos = newPos
        self:reloadHero()
        self.parent:reloadHelpNum()
    end
end

function HeroFightLayoutTab:onEquipAction()
end

function HeroFightLayoutTab:onHeroInfo()
    local hero = self.heroMsg
    if hero and hero.idx>0 then
        local dialog = self:getDialog()
        dialog:pushTab("info", hero.idx)
    end
end

function HeroFightLayoutTab:reloadHero()
    local dialog = self:getDialog()
    local layoutParam = dialog.layoutParam
    local context = dialog.context
    local hero
    if layoutParam.forceLayouts then
        hero = layoutParam.forceLayouts:getHeroByLayout(layoutParam.pos, 1)
    else
        hero = context.heroData:getHeroByLayout(layoutParam.lid, layoutParam.pos, 1)
    end
    self.heroMsg = hero
    if hero then
        self.nodeHeroInfo:setVisible(true)
        dialog:reloadStars(self, hero.info.maxStar, hero.starUp)
        self.levelLabel:setString(StringManager.getFormatString("labelHeroLevel", {num=hero.level, max=hero.maxLv}))
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
        self.expProcess:setScaleProcess(true, exp/nextExp)
        if self.roleFeature then
            self.roleFeature:removeFromParent(true)
            self.roleFeature = nil
        end
        self.roleFeature = GameUI.addHeroFeature(self.nodeHeroFeature.view, hero.hid, 1, 0, 0, 0, nil,hero.awakeUp)
        if self.roleJob then
            self.roleJob:removeFromParent(true)
            self.roleJob = nil
        end
        self.roleJob = GameUI.addHeroJobIcon(self.nodeJobIcon, hero.info.job, 0.95, 44, 44)
        self.nameLabel:setString(hero:getName())
        GameUI.setHeroNameColor(self.nameLabel, hero.info.displayColor or hero.info.color)

        local hdata = hero:getHeroData()
        self.infoLabels1:setString(tostring(hdata.hp))
        self.infoLabels2:setString(tostring(hdata.atk))
        self.infoLabels3:setString(StringManager.getString("enumBType" .. (hero.info.fav or 0)))

        self.nodeSoldierHead:removeAllChildren(true)
        GameUI.addHeadIcon(self.nodeSoldierHead,hero.info.sid,0.833,99,95,{lv = hero.soldierLevel})
        self.nodeSkills:removeAllChildren(true)
        local temp = ui.sprite("images/skillBack_out.png",{131, 131})
        display.adapt(temp, 63, 63, GConst.Anchor.Center)
        self.nodeSkills:addChild(temp)
        GameUI.addSkillIcon(self.nodeSkills, 1, hero.info.mid, 0.53, 63, 63)
        local ox = 216
        for i=1, 3 do
            if hero.bskills[i].id>0 then
                local temp = ui.sprite("images/skillBack_out.png",{131, 131})
                display.adapt(temp, ox, 63, GConst.Anchor.Center)
                self.nodeSkills:addChild(temp)
                GameUI.addSkillIcon(self.nodeSkills, 3, hero.bskills[i].id, 0.53, ox, 63)
                ox = ox + 151
            else
                break
            end
        end
    else
        self.nodeHeroInfo:setVisible(false)
    end
    self:loadOtherHeroBlock()
end

function HeroFightLayoutTab:loadOtherHeroBlock()
    local dialog = self:getDialog()
    local layoutParam = dialog.layoutParam
    local context = self:getContext()
    local canUseHero = {}
    local heros
    if layoutParam.forceLayouts and layoutParam.forceLayouts.getAllHeros then
        heros = layoutParam.forceLayouts:getAllHeros()
    else
        heros = context.heroData:getAllHeros()
    end

    --重复id判断
    local forceLayouts = layoutParam.forceLayouts
    local cantId = {}
    local ltb = {}
    if forceLayouts then
        ltb = forceLayouts:getLayouts() or {}
    else
        ltb = context.heroData:getHeroByLayout(layoutParam.lid) or {}
    end
    for k,v in pairs(ltb) do
        if v[1] then
            local id,idx = v[1].hero and v[1].hero.hid or v[1].hid,v[1].hero and v[1].hero.idx or v[1].idx
            cantId[id] = true
        end
    end
    for _, hero in pairs(heros) do
        if (hero.info.job or 0)>0 and hero.info.aspeed>0 then
            if not cantId[hero.hid] or (self.heroMsg and self.heroMsg.hid == hero.hid) then
                local posAndType
                if layoutParam.forceLayouts then
                    posAndType = layoutParam.forceLayouts:getLayout(hero)
                else
                    posAndType = hero.layouts[layoutParam.lid]
                end
                if not posAndType or posAndType.pos==layoutParam.pos and posAndType.type==1 then
                    table.insert(canUseHero, hero)
                end
            end
        end
    end
    table.sort(canUseHero, GameLogic.sortExpHero)
    local infos={}
    for i, hero in ipairs(canUseHero) do
        infos[i]={index=i, type="hero", heroKey=hero.idx, lid=layoutParam.lid, forceLayouts=layoutParam.forceLayouts}
        if layoutParam.lid==const.LayoutPvp then
            infos[i].deadTime = hero.recoverTime
        end
    end
    if self.tableView then
        self.tableView.view:removeFromParent(true)
        self.tableView = nil
    end
    local tableView = ui.createTableView({930, 1286}, false, {size=cc.size(238,229), offx=20, offy=32, disx=70, disy=52, rowmax=3, infos=infos, cellUpdate=Handler(self.updateHeroCell, self)})
    display.adapt(tableView.view, 1096, 54, GConst.Anchor.LeftBottom)
    self.view:addChild(tableView.view)
    self.infos = infos
    self.tableView = tableView

    local gstep = context.guide:getStep()
    if gstep.type == "selectHero" then
        for _, info in ipairs(self.infos) do
            if info.displayHid == gstep.id then
                local view = info.view:getParent()
                local x,y = info.view:getPosition()
                info.guideIcon = context.guideHand:showArrow(view,x,y-50,100)
                info.guideIcon:setScaleY(-1)
            end
        end
    end
end

local _cellSetting = {flagState=true}
function HeroFightLayoutTab:updateHeroCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    if not info.view then
        info.view = cell
        cell:setScriptCallback(ButtonHandler(self.onHeroCellAction, self, info))
        cell:setBackgroundSound("sounds/heroSelected.mp3")
    end
    GameUI.updateHeroTemplate(bg, info, self:getContext().heroData:getHero(info.heroKey), _cellSetting)
end

function HeroFightLayoutTab:onHeroCellAction(info)
    local hidx = info.heroKey
    local dialog = self:getDialog()
    local layoutParam = dialog.layoutParam
    local context = dialog.context

    local gstep = context.guide:getStep()
    if gstep.type ~= "finish" and gstep.type ~= "selectHero" then
        GameLogic.lockInGuide()
        return
    end
    local hero = context.heroData:getHero(hidx)
    if hero then
        if layoutParam.forceLayouts then
            local lpos, ltype = layoutParam.pos, 1
            local hlayout = layoutParam.forceLayouts:getLayout(hero)
            if hlayout and hlayout.pos==lpos and hlayout.type==ltype then
                layoutParam.forceLayouts:changeHeroLayout(hero, 0, 0)
            else
                layoutParam.forceLayouts:changeHeroLayout(hero, lpos, ltype)
            end
            if layoutParam.lid and (layoutParam.lid==const.LayoutPvh or layoutParam.lid==const.LayoutnPvh) then
                layoutParam.forceLayouts:save()
            end
        else
            if hero.layouts[layoutParam.lid] then
                context.heroData:changeHeroLayout(hero, layoutParam.lid, 0, 0)
            else
                context.heroData:changeHeroLayout(hero, layoutParam.lid, layoutParam.pos, 1)
            end
        end
        if gstep.type == "selectHero" then
            context.guide:addStep()
            local x,y = self:getDialog().closeBut:getPosition()
            local arrow = context.guideHand:showArrow(self:getDialog().view,x,y-70,100)
            arrow:setScaleY(-1)
        end
        self:reloadHero()
        -- 上阵英雄检查战斗力
        context.heroData:setCombatData(hero)
    end
end

return HeroFightLayoutTab
