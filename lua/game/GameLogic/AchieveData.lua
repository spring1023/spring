local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local AchieveData = class()


local achieveType = {const.ActTypeBuildLevelUp,
                    const.ActTypeHeroLevelUp,
                    const.ActTypeHeroAuto,
                    const.ActTypeMercenaryLevels,
                    const.ActTypePveGK,
                    const.ActTypePVPCup,
                    const.ActTypeShareInfo,
                    const.ActTypeSRHeroGet,
                    const.ActTypeSSRHeroGet,
                    const.ActTypeHeroPassive,
                    const.ActStatUserLevel,
                    const.ActTypeRename
                }
function AchieveData:ctor(data)
    self.config = SData.getData("achieves")
    self.rcd = {}
    for i,v in ipairs(data.rcd) do
        self.rcd[v[1]] = v
    end
    self.spd = {}
    for i,v in ipairs(data.spd) do
        self.spd[v[1]] = v
    end
    --每个类型的初始id
    self.initId = {}
    for id,v in ipairs(self.config) do
        if v.bfid == 0 then
            self.initId[v.type] = id
        end
    end
    self:initData()
end

function AchieveData:initData()
    local context = GameLogic.getUserContext()
    local ddata = {}
    -- for type=1,12 do
    for i,v in ipairs(achieveType) do
        local type = v
        local data = nil
        local id,cfg
        local rcd = self.rcd[type]
        if rcd then
            id = rcd[2]
            cfg = self.config[id]
            if cfg then
                local glv
                -- if type == 1 then
                if type == const.ActTypeBuildLevelUp then
                    glv = context.buildData:getMaxLevel(cfg.tid)
                -- elseif type == 5 then
                elseif type == const.ActStatUserLevel then
                    glv = context:getInfoItem(const.InfoLevel)
                else
                    glv = self.spd[type] and self.spd[type][3] or 0
                end
                data = {type = type, id = id, glv = glv, tlv = cfg.tlv, tid = cfg.tid, isget = rcd[3]}
            end
        else
            id = self.initId[type]
            if id then
                cfg = self.config[id]
                local glv = 0
                -- if type == 1 then
                if type == const.ActTypeBuildLevelUp then
                    glv = context.buildData:getMaxLevel(cfg.tid)
                -- elseif type == 5 then
                elseif type == const.ActStatUserLevel then
                    glv = context:getInfoItem(const.InfoLevel)
                else
                    glv = self.spd[type] and self.spd[type][3] or 0
                end
                data = {type = type, id = id, glv = glv, tlv = cfg.tlv, tid = cfg.tid, isget = 0}
            end
        end
        if data then
            local reward = {}
            for i=1,5 do
                if cfg["gtype"..i] and cfg["gtype"..i]~=0 then
                    reward[i] = {cfg["gtype"..i],cfg["gid"..i],cfg["gnum"..i]}
                end
            end
            data.reward = reward
            ddata[type] = data
        end
    end
    self.ddata = ddata
end


function AchieveData:getReward(id)
    local context = GameLogic.getUserContext()
    local cfg = self.config[id]
    local type = cfg.type
    local ncfg = self.config[cfg.afid]

    local reward = self.ddata[type].reward
    GameLogic.addRewards(reward)
    GameLogic.statCrystalRewards("成就奖励",reward)
    GameLogic.showGet(reward)
    Plugins:onFacebookStat("PreAchievement", "Achievement" .. id)
    if ncfg then
        local glv
        -- if type == 1 then
        if type == const.ActTypeBuildLevelUp then
            glv = context.buildData:getMaxLevel(ncfg.tid)
        -- elseif type == 5 then
        elseif type == const.ActStatUserLevel then
            glv = context:getInfoItem(const.InfoLevel)
        else
            glv = self.spd[type] and self.spd[type][3] or 0
        end
        local data = {type = type, id = cfg.afid, glv = glv, tlv = ncfg.tlv, tid = ncfg.tid, isget = 0}
        local reward = {}
        for i=1,5 do
            if ncfg["gtype"..i] and ncfg["gtype"..i]~=0 then
                reward[i] = {ncfg["gtype"..i],ncfg["gid"..i],ncfg["gnum"..i]}
            end
        end
        data.reward = reward
        self.ddata[type] = data
        self.rcd[type] = {type,cfg.afid,0}
    else
        self.ddata[type].isget = 1
        --8，成就只有一个
        if not self.rcd[type] then
            self.rcd[type] = {type,self.ddata[type].id,1}
        end
        self.rcd[type][3] = 1
    end
    GameEvent.sendEvent("refreshTaskRedNum")
end

function AchieveData:getNotReward()
    local num = 0
    for i,v in pairs(self.ddata) do
        if v.glv>=v.tlv and v.isget == 0 then
            num = num+1
        end
    end
    return num
end

function AchieveData:finish(type,lv)
    -- if type == 9 or type == 10 or type == 11 then
    if type == const.ActTypeShareInfo or type == const.ActTypeSRHeroGet or type == const.ActTypeSSRHeroGet then
        if self.spd[type] then
            self.spd[type][3] = self.spd[type][3] + lv
        else
            self.spd[type] = {type,1,lv}
        end
    -- elseif type~=1 and type~=5 then
    elseif type~=const.ActTypeBuildLevelUp and type~=const.ActStatUserLevel then
        if self.spd[type] then
            if self.spd[type][3]<lv then
                self.spd[type][3] = lv
            end
        else
            self.spd[type] = {type,1,lv}
        end
    end
    self:initData()
    GameEvent.sendEvent("refreshTaskRedNum")
    GameEvent.sendEvent("refreshAchievementDialog")
end


return AchieveData
