local const = GMethod.loadScript("game.GameLogic.Const")
local GuideData = class()

function GuideData:ctor(udata)
    self.udata = udata
end

local steps = {
    {type="comic",id=1},             --1
    {type="story",id=1},             --2
    {type="putHero",id=1},           --3

    {type="pauseForSkill",id=1},     --4
    {type="pauseForGodSkill",id=1},  --5

    {type="buyBuild",num=2, btype=9, id=13, storys={103, 104, 106}},         --6
    {type="buyBuild",num=1, btype=2, id=21, storys={105, nil, 106}},        --7
    {type="pvj",story=107},         --8

    {type="exHero1",storys={108, 109}}, --9`
    {type="selectHero", story=110, id=3004, bid=3},        --10
    {type="pve", story=111, id=1},             --11

    {type="upgradeHero", story=112, hid=3004, id=1},     --12
    {type="upgradeTown", story=113, level=2, id=1},     --13

    {type="task", story=114, id=1},            --14
    {type="finish",id=1},            --15
}

function GuideData:getCurrentState()
    return self.udata:getInfoItem(const.InfoNewer)
end

function GuideData:initGuideStep(loading)
    if not self.loading then
        self.loading = loading
    else
        loading = self.loading
    end
    if GEngine.rawConfig.DEBUG_BATTLE then
        self.udata:setInfoItem(const.InfoNewer,1)
    end
    self.sstate = 0
    if self:getCurrentState()<6 then
        local scene = loading.scene
        scene.sceneType = "battle"
        scene.isBattle = true
        scene.battleType = const.BattleTypePve
        scene.battleParams = {stage=0, story1=101, story2=102}
        self.scene = scene
        if self:getCurrentState()<=1 then
            scene.battleParams.comics = {7, 8, 9}
            if self:getCurrentState() == 0 then
                self:addStep()
            end
        end
        scene.battleData = GameLogic.newBattleData(scene)
        scene.startTime = GameLogic.getSTime()
        loading.locked = true
        GameNetwork.request("pvedata", {questdata={(GEngine.rawConfig.DEBUG_BATTLE and GEngine.rawConfig.DEBUG_STAGE) or
            GEngine.getSetting("guidePveStage") or 50}}, self.getDataOver, self, loading)
    end
end

function GuideData:getStep()
    local idx = self:getCurrentState()
    local step = steps[idx] or steps[15]
    return step
end

function GuideData:getStepState()
    return self.sstate
end

function GuideData:setStepState(state)
    self.sstate = state
end

function GuideData:addStep()
    if GEngine.rawConfig.DEBUG_BATTLE then
        return
    end
    self.sstate = 0
    self.buyBuildShow = nil
    self.udata:changeInfoItem(const.InfoNewer,1)
    local idx = self:getCurrentState()
    Plugins:onFacebookStat("PreTutorial", idx)
    GameLogic.statForSnowfish("postNewcomerData")
    if idx==2 then
        --self:initGuideStep()
        self.udata:addCmd({const.CmdAddGuideStep,2})
        GameLogic.dumpCmds()
    elseif idx>=6 and idx<=15 and idx~=10 then
        self.udata:addCmd({const.CmdAddGuideStep, idx})
    end
    if self:getStep().type == "finish" then
        GameLogic.statForSnowfish("tutorialcompletes")
    end
end

function GuideData:getDataOver(loading, suc, data)
    if suc then
        local context = GameLogic.newContext(data.uid)
        local uinfo = data.uinfo
        data.info = {uinfo[1],0,0,0,0,uinfo[2],0,0,1,0,1,1,uinfo[4],uinfo[5]}
        data.properties = {}
        data.bexts = data.exts
        data.layouts = {}
        for i, build in ipairs(data.builds) do
            build[2], build[3] = build[3], build[2]
            data.layouts[i] = {build[1], build[4], build[5], 0, 0, 0, 0}
        end
        data.wlist = {}
        data.armors = {}
        data.hbskills = {}
        if data.heros then
            data.hlayouts = {}
            for i, hero in ipairs(data.heros) do
                local lstate = hero[13]
                local newHero = {hero[1],hero[2],hero[3],hero[4],hero[5],
                    hero[6],hero[7],hero[8],hero[9],hero[10],hero[11],
                    hero[12],0,0,hero[14]
                }
                data.heros[i] = newHero
                table.insert(data.hlayouts,{hero[1],10,lstate})
            end
        end
        if data.equips then
            data.equips = nil
        end
        context:loadContext(data)
        GameLogic.setCurrentContext(context)

        local ucontext = GameLogic.getUserContext()
        ucontext.bheroData = ucontext.heroData
        ucontext:makeTempHeroData()
        local hids
        if GEngine.rawConfig.DEBUG_BATTLE then
            hids = GEngine.rawConfig.DEBUG_BATTLEARR
            for i=1, #hids do
                local hero = ucontext.heroData:addNewHero(i, hids[i])
                hero.level = 100
                if GEngine.rawConfig.DEBUG_GODSKILL and hero.info.awake>0 then
                    hero.awakeUp = 5
                end
                hero.mSkillLevel = const.MaxMainSkillLevel
                ucontext.heroData:setHeroLayout(hero, const.LayoutPvp, i, 1)
            end
        else
            hids = {}
            local heros = GMethod.loadConfig("configs/settings.json").guideHeros
            for i, hdata in ipairs(heros) do
                local hero = ucontext.heroData:addNewHero(i, hdata[1])
                hids[i] = hdata[1]
                hero.level = hdata[2]
                hero.mSkillLevel = hdata[3]
                hero.awakeUp = hdata[4]
                hero.soldierLevel = hdata[5]
                ucontext.heroData:setHeroLayout(hero, const.LayoutPvp, i, 1)
            end
        end
        self.guideHids = hids
    end
    loading.locked = nil
end

return GuideData
