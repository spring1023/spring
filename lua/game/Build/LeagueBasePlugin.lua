local LeagueBasePlugin = {}

function LeagueBasePlugin:addMenuButs(buts, item)
    GameEvent.bindEvent(self.vstate.view,"EventFreshUnionMenu", self.vstate.view, function()
        if self.vstate and self.vstate.focus then
            BU.showBuildMenu(self)
        end
    end)

    if item=="league" then
        table.insert(buts, {key="league", callback = function()
            if GameLogic.getUserContext().union then
                UnionInfoDialog.new()
            else
                UnionDialog.new()
            end
            local context = GameLogic.getUserContext()
            local step = context.guideOr:getStep()
            if step == 15 then
                context.guideOr:setStep(step+1)
                context.guideHand:removeHand("guideOrBuildBtn")
            end
        end})
    elseif item=="leagueBoss" and GameLogic.getUserContext().union then
        table.insert(buts, {key="boss", callback=self.openBeastDialog, cp1=self})
    elseif item=="leagueWar" and GameLogic.getUserContext().union then
        table.insert(buts, {key="lwar", callback=function()
            GameLogic.unionBattle()
        end})
    elseif item=="leaguePve" and GameLogic.getUserContext().union then
        table.insert(buts, {key="leaguePve", callback=function()
            UnionMapDialog.new()
        end})         
    end
end

function LeagueBasePlugin:openBeastDialog()
    local pets = self.context:getUnionPets()
    if pets then
        display.showDialog(UnionPetsDialog.new({context=self.context, pets=pets, initTag="info"}))
    end
end

function LeagueBasePlugin:readyToBattle()
    self:updateOperation()
    local scene = self.vstate.scene
    --加联盟神兽
    if scene.battleType and (scene.battleType == const.BattleTypePvp or scene.battleType == const.BattleTypeUPvp) then
        self:addPetToScene(AvtControlerState.BATTLE)
    end
end

function LeagueBasePlugin:readyToVisit()
    self:updateOperation()
    self:addPetToScene(AvtControlerState.Operation)
end

function LeagueBasePlugin:addPetToScene(state)
    local context = self.context
    local pets = self.context:getUnionPets()
    local vstate = self.vstate
    if pets then
        local hero = context.heroData:makePet(pets,0)
        local gx,gy,gsize = vstate.gx,vstate.gy,vstate.gsize
        local person = hero:getControlData()
        if state == AvtControlerState.BATTLE then
            GameLogic.addSpecialBattleBuff(hero, person, self.group, vstate.scene)
        end
        local rhero = PersonUtil.C({person=person, state=state, group=self.group})
        rhero:addToScene(vstate.scene, gx, gy)
        if state == AvtControlerState.BATTLE then
            table.insert(rhero.groupData.heros,rhero)
            self.vstate.rhero = rhero
        else
            rhero.target = self
        end
    end
end

function LeagueBasePlugin:updateOperation(diff)
    local context = self.context
    if not self.vstate.bflagCode then
        if context.union then
            self:reloadFlag()
        end
    else
        if context.union and context.union.flag~=self.vstate.bflagCode then
            self:reloadFlag()
        end
    end

    if self.vstate.unionFlag and not context.union then
        if not tolua.isnull(self.vstate.unionFlag) then
            self.vstate.unionFlag:removeFromParent(true)
        end
        self.vstate.bflagCode = nil
        self.vstate.unionFlag = nil
        if not tolua.isnull(self.vstate.unionName) then
            self.vstate.unionName:removeFromParent(true)
        end
        self.vstate.unionName = nil
    end
end

function LeagueBasePlugin:reloadFlag()
    if self.vstate.unionFlag then
        if not tolua.isnull(self.vstate.unionFlag) then
            self.vstate.unionFlag:removeFromParent(true)
        end
        self.vstate.unionFlag = nil
        if not tolua.isnull(self.vstate.unionName) then
            self.vstate.unionName:removeFromParent(true)
        end
        self.vstate.unionName = nil
    end
    local context = self.context
    self.vstate.unionFlag = GameUI.addUnionFlag(context.union.flag)
    self.vstate.unionFlag:setScale(0.22)
    local size = self.vstate.build:getContentSize()
    local x,y = size.width/2,size.height
    self.vstate.unionFlag:setPosition(x,y)
    self.vstate.build:addChild(self.vstate.unionFlag)
    self.vstate.bflagCode = context.union.flag

    local unionName=ui.label(Localize(context.union.name),General.font5,35)
    display.adapt(unionName, x, y-20, GConst.Anchor.Top)
    self.vstate.build:addChild(unionName,2)
    self.vstate.unionName=unionName
end

return LeagueBasePlugin
