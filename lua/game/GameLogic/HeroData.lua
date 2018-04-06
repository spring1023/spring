local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
local combData = GMethod.loadConfig("configs/settings.json")["combConfig"]
local HeroModel = KTClass()


function HeroModel:ctor(data)
    --info代表英雄的属性表
    self.idx = data[1]              --编号
    self.hid = data[2]              --英雄ID
    self.level = data[3] or 1       --英雄等级
    self.exp = data[4] or 0         --英雄经验
    self.starUp = data[5] or 0      --英雄星级
    self.awakeUp = data[6] or 0     --英雄觉醒等级
    self.mSkillLevel = data[7] or 1 --英雄主动技能
    self.soldierLevel = data[11] or 1--佣兵等级
    self.soldierSkillLevel1 = data[12] or 0--佣兵技能等级第一天赋
    self.lock = data[13] or 0--加锁(不可被选中吞噬)
    self.recoverTime = data[14] or 0--恢复时间
    self.soldierSkillLevel2 = data[15] or 0--佣兵技能等级第二天赋

    self.layouts = {}--出站的位置(pvp位置或者pve位置。。。。)
    self.bskills = {}--被动技能表
    self.mics = {}--英雄强化
    self.assists = {}--助战英雄
    local temp
    for i=1, 3 do
        temp = data[i+7] or 0
        self.bskills[i] = {id=math.floor(temp/100), level=temp%100, lights={}, curLight=0}
    end
    self:loadDatas()
end

function HeroModel:dctor()
    local data = {}
    data = {
        self.idx, self.hid, self.level, self.exp, self.starUp,
        self.awakeUp, self.mSkillLevel, 0, 0, 0,
        self.soldierLevel, self.soldierSkillLevel1, self.lock, self.recoverTime,self.soldierSkillLevel2
    }
    for i=1,3 do
        local bs = self.bskills[i]
        local temp = bs.id*100+bs.level
        data[i+7] = temp
    end
    return data
end

function HeroModel:getControlData(otherSettings)
    local alv = 0
    if self.awakeUp<5 then

    elseif self.awakeUp<10 then
        alv = 5
    elseif self.awakeUp<12 then
        alv = 10
    else
        alv = 12
    end
    local alv2 = 0
    if self.awakeUp<3 then

    elseif self.awakeUp<8 then
        alv2 = 3
    elseif self.awakeUp<11 then
        alv2 = 8
    else
        alv2 = 11
    end

    local awakeData
    if alv>0 then
        local ret = self:getAwakeSkill(alv)
        awakeData = {id = ret.id,lv = ret.level,ps = ret.ps, skillLv=alv}
    end
    local awakeData2
    if alv2>0 then
        local ret = self:getAwakeSkill(alv2)
        awakeData2 = {id = ret.id,lv = ret.level,ps = ret.ps, skillLv=alv2}
    end

    local data = {id=self.hid, level=self.level, skillLv=self.mSkillLevel,
    actSkillParams=self:getSkillData(), idx=self.idx, awakeUp=self.awakeUp,
    skillId = self.info.mid, awakeData = awakeData, awakeData2 = awakeData2}

    if self.hid>1000 then
        local sdata = self:getSoldierData()
        data.soldierNum = sdata.num
        data.soldierId = self.info.sid
    end
    if self.isPet then
        data.skillId = math.floor(data.skillId/10)*10
        data.bskillData = {}
        for i=1,4 do
            local lv = self:getUPSkillDetail(i+2).lv
            if lv>0 then
                data.bskillData[i] = self:getTalentSkillData(i,lv)
            end
        end
        if self.hid==8103 then
            local ret = self:getAwakeSkill(self.awakeUp)
            data.awakeData = {id=ret.id, lv=ret.level, ps=ret.ps}
        end
        data.isPet = self.isPet
    end

    local hd = self:getHeroData(otherSettings)
    for k,v in KTPairs(hd) do
        data[k] = v
    end
    for k,v in KTPairs(self.info) do
        if k ~= "rating" then
            data[k] = v
        end
    end
    if self.forceData then
        data.forceData = self.forceData
        data.level = self.forceData.level
        data.atk = self.forceData.atk
        data.hp = self.forceData.hp
        data.atk_base = data.atk
        data.hp_base = data.hp
    end
    return data
end

function HeroModel:isAlive(stime)
    return stime>self.recoverTime
end

function HeroModel:setDead(stime)
    self.recoverTime = stime+SData.getData("hlevels", self.info.type, self.level).rtime
end

function HeroModel:getDeadState(stime)
    local dead, ltime, mtime
    dead = stime<=self.recoverTime
    ltime = 0
    mtime = 0
    if dead then
        ltime = self.recoverTime-stime
        mtime = SData.getData("hlevels", self.info.type, self.level).rtime
        if mtime<ltime then
            mtime = ltime
        end
    end
    return dead, ltime, mtime
end

function HeroModel:loadDatas()
    --神兽 id处理
    local hid = self.hid
    self.info = SData.getData("hinfos", hid)
    if not self.info then
        if math.floor(self.hid/1000) == 8 then
            hid = math.floor(hid/10)*10
            self.info = SData.getData("hinfos", hid)
        end
    end
    if not self.info then
        GameLogic.otherGlobalInfo = {"hero id", self.hid, hid}
    end
    self.info.awake = self.info.awake or 0

    if self.info.job==0 or hid>=5000 then
        self.maxLv = const.MaxHeroLevel
    else
        self.maxLv = const.InitHeroLevel+self.starUp*const.HeroStarLevel
        if self.info.awake>0 then
            self:resetAwakeSkills()
            if self.awakeUp>0 then
                self.maxLv = self.maxLv + SData.getData("awakes", self.awakeUp).addLevel
            end
        end
        self:statAllSkills()
    end
end

local _heroAwakeLvs = {1,1,1,1,1,2,2,2,2,2,3,3}
local _heroAwakeTypes = {const.ASkillHp,const.ASkillAtk,const.ASkillGuard,const.ASkillDef,const.ASkillGod,const.ASkillHp,const.ASkillAtk,const.ASkillGuard,const.ASkillDef,const.ASkillGod,const.ASkillGuard,const.ASkillGod}
function HeroModel:resetAwakeSkills()
    if self.info.awake>0 and (not self.awakeStat or self.awakeStat.level~=self.awakeUp) then
        local awakeStat = {level=self.awakeUp, skills={}}
        for i=1, self.awakeUp do
            awakeStat.skills[_heroAwakeTypes[i]] = {level=_heroAwakeLvs[i], dlv=i}
        end
        for i=1, 5 do
            if not awakeStat.skills[i] then
                awakeStat.skills[i] = {level=0}
            end
            local hid = self.hid
            if self.hid == 4031 and self.heroState == 0 then
                hid = 40312
            end
            awakeStat.skills[i].data = SData.getData("adatas", hid, awakeStat.skills[i].dlv or i)
        end
        self.awakeStat = awakeStat
    end
end

local _bskillEffectSetting = {[1001]="hp",[1002]="hpPercent",[1003]="atk",[1004]="atkPercent",[1005]="spd",[1006]="k",[1007]="def",[1008]="sHp",[1009]="sAtk",[1010]="sNum"}
local _micEffectSetting = {"atk","atkPercent","atkPercent","hp","hpPercent","hpPercent","rating","dodge","spd","k","ndef","sdef","sHp","critical","criticalNum","dscritical"}
local _equipEffectSetting = {"atk","hp","rating","dodge","critical","dscritical","criticalNum","k","def","sAtk","sHp"}

function HeroModel:statAllSkills()
    --[[英雄的atk=攻击，hp=生命值，atkPercent攻击百分比 hpPercent生命值百分比 spd=攻速百分比
    k=最终伤害百分比 def=减伤百分比]]
    --[[佣兵的sAtk=攻击百分比 sHp=生命百分比 sNum=数量 mAtk=攻击力 mHp=生命值 sDef=减伤百分比
    sDam=伤害百分比 sSpeed=攻速百分比]]
    local skillStat = {atk=0, hp=0, atkPercent=0, hpPercent=0, spd=0, k=0, def=0, mspd=0, dodge=0,
    sAtk=0, sHp=0, sNum=0, sDef=0, smAtk=0, smHp=0, smDef=0, sDam=0, sSpeed=0}
    if self.hid>=8000 then
    else
        local data = self:getSoldierTalentData(1, self.soldierSkillLevel1)
        if data then
            skillStat.sAtk = skillStat.sAtk + data.atk
            skillStat.sHp = skillStat.sHp + data.hp
        end
        data = self:getSoldierTalentData(2, self.soldierSkillLevel2)
        if data then
            skillStat.smHp = skillStat.smHp + (data.shp or 0)
            skillStat.smAtk = skillStat.smAtk + (data.satk or 0)
            skillStat.smDef = skillStat.smDef + (data.pdef or 0)
            skillStat.sDam = skillStat.sDam + (data.pdam or 0)
            skillStat.sSpeed = skillStat.sSpeed + (data.patkspeed or 0)
        end
        for i=1, 3 do
            local bskill = self.bskills[i]
            if bskill.id>0 then
                local effect = _bskillEffectSetting[bskill.id]
                skillStat[effect] = skillStat[effect]+self:getTalentSkillData(bskill.id, bskill.level)
            end
        end
        if self.mics then
            for sidx, mic in pairs(self.mics) do
                if mic.level>0 then
                    local skillId = SData.getData("hmicskills", self.hid)[sidx]
                    local value = SData.getData("hmicsdatas",skillId,mic.level)
                    local effect = _micEffectSetting[skillId]
                    skillStat[effect] = (skillStat[effect] or 0)+value
                end
            end
        end

        if self.equip then
            local eparams = self.equip:getDetailParams()
            for ek, value in KTPairs(eparams) do
                local effect = _equipEffectSetting[ek]
                skillStat[effect]= (skillStat[effect] or 0)+value
            end
        end
        if self.assists then
            for pos, hero in pairs(self.assists) do
                local hdata = hero:getNormalHelpValue(pos)
                if pos == 1 then
                    skillStat.hpPercent = skillStat.hpPercent + hdata
                elseif pos == 2 then
                    skillStat.atkPercent = skillStat.atkPercent + hdata
                else
                    skillStat.hpPercent = skillStat.hpPercent + hdata
                    skillStat.atkPercent = skillStat.atkPercent + hdata
                end
                hero:addHelpEffectTo(self, skillStat)
                local shd = SData.getData("SoldierHelp", hero.soldierLevel)
                if shd then
                    skillStat.smDef = skillStat.smDef + (shd.skilldef or 0)
                    skillStat.smHp = skillStat.smHp + (shd.shp or 0)
                end
            end
        end
        if self.awakeStat then
            local hpSkill = self.awakeStat.skills[const.ASkillHp]
            if hpSkill.level>0 then
                skillStat.hp = skillStat.hp+hpSkill.data.a
                skillStat.hpPercent = skillStat.hpPercent+hpSkill.data.x
            end
            local atkSkill = self.awakeStat.skills[const.ASkillAtk]
            if atkSkill.level>0 then
                skillStat.atk = skillStat.atk+atkSkill.data.a
                skillStat.atkPercent = skillStat.atkPercent+atkSkill.data.x
            end
        end
    end
    self.skillStat = skillStat
end

function HeroModel:setEquip(equip)
    self.equip = equip
end

function HeroModel:setBSkill(bidx, lidx, bskill, state)
    self.bskills[bidx].lights[lidx] = {id=math.floor(bskill/100), level=bskill%100, state=state}
    if state==2 then
        self.bskills[bidx].curLight = lidx
    end
end

--懒得拆表了，先达成目标；如果有必要，以后再拆表
function HeroModel:getMicStage(stage)
    local sidx = stage*2
    return SData.getData("hmicstages", sidx)
end

function HeroModel:setMicSkill(sidx, level, exp)
    self.mics[sidx] = {level=level, exp=exp}
end

function HeroModel:getMicSkill(sidx)
    local ret = {}
    local mySkill = self.mics[sidx]
    local lv, exp = 0, 0
    if mySkill then
        lv, exp = mySkill.level, mySkill.exp
    end
    ret.level = lv
    ret.exp = exp
    ret.nextExp = 0
    local stage = SData.getData("hmicstages", sidx)
    if lv<stage.max then
        ret.nextExp = SData.getData("hmiclevels", stage.stage, lv+1) or 0
    end
    local skillId = SData.getData("hmicskills", self.hid)[sidx]
    ret.id = skillId
    ret.max = stage.max
    ret.need = stage.need
    ret.alv = stage.alv
    ret.name = Localize("dataSkillName6_" .. skillId)
    local isZ = false
    if lv==0 then
        lv = 1
        isZ = true
    end
    ret.desc = Localizef("dataSkillInfo6_" .. skillId, {value=SData.getData("hmicsdatas",skillId,lv)})
    ret.addPro = Localizef("dataSkillInfo6Pro_" .. skillId, {value=isZ and 0 or SData.getData("hmicsdatas",skillId,lv)})
    return ret
end

--获取整个英雄强化上限
function HeroModel:getMaxMicLevel()
    local hmicKills = SData.getData("hmicstages")
    local maxSum = 0
    for k,v in pairs(hmicKills) do
        maxSum = maxSum + v.max
    end
    return maxSum
end

function HeroModel:getMicLevel()
    local ret = 0
    for _, mic in pairs(self.mics) do
        ret = ret+mic.level
    end
    return ret
end

function HeroModel:getNextExp()
    local hd = SData.getData("hlevels", self.info.type, self.level)
    if not hd then
        GameLogic.otherGlobalInfo = {"hlevels", self.info.type, self.level}
    end
    return hd.next
end

function HeroModel:setLayout(lid, pos, type, x, y, hp, isOut)
    if pos==0 then
        self.layouts[lid] = nil
    else
        self.layouts[lid] = {pos=pos, type=type, x=x, y=y, hp=hp, isOut=isOut}
    end
end

function HeroModel:getLayouts()
    return self.layouts
end

function HeroModel:getName()
    if self.info.name then
        return Localize(self.info.name)
    end
    return Localize("dataHeroName" .. self.hid)
end

function HeroModel:getSkillName()
    return Localize("dataSkillName1_" .. self.info.mid)
end

function HeroModel:getSkillDesc(lv, withoutSuffix)
    if not lv then
        lv = self.mSkillLevel
    end
    local sdata = self:getSkillData(lv)
    local descData = {}
    for k, v in KTPairs(sdata) do
        descData[k] = v
    end
    local mid = self.info.mid
    descData.x = math.floor(sdata.x or 0)/10
    if self.hid == 4031 then
        if self.heroState == 1 then
            mid = 4131
        else
            mid = 4531
        end
    end
    local str = StringManager.getFormatString("dataSkillInfo1_" .. mid, descData)
    local suffix1 = false
    if self.info.mid>0 and lv<const.MaxMainSkillLevel and not withoutSuffix then
        local curCost = sdata.x
        if curCost then
            for i=lv+1, const.MaxMainSkillLevel do
                sdata = self:getSkillData(i)
                if sdata and sdata.x then
                    if sdata.x<curCost then
                        suffix1 = true
                        str = str .. StringManager.getFormatString("dataSkillInfo1Suffix1", {level=i, num=sdata.x/10})
                        break
                    end
                else
                    break
                end
            end
        end
    end
    if not suffix1 then
        str = str .. Localize("dataSkillInfo1Suffix2")
    end
    return str
end

function HeroModel:getSkillData(lv)
    if not lv then
        lv = self.mSkillLevel
    end
    local mid = self.info.mid
    if self.hid>8000 and self.hid<9000 then
        mid = math.floor(mid/10)*10
    end
    if self.hid == 4031 then
        if self.heroState == 1 then
            mid = 4131
        else
            mid = 4531
        end
    end
    if self.info.mid>0 then
        return SData.getData("mskdatas", mid, lv) or {}
    else
        return {a=self.info.exp}
    end
end

function HeroModel:getMainSkillCost(lv)
    if not lv then
        lv = self.mSkillLevel+1
    end
    return SData.getData("mlevels", lv)
end

--获取联盟神兽技能详情
function HeroModel:getUPSkillDetail(upsid)
    local data = {ctype=const.ResGXun}
    local stype
    if upsid==1 then
        data.stype = 5
        data.sid = self.info.mid
        data.lv = self.awakeUp
        data.mlv = const.MaxUPTSkillLevel
        stype = 1
    elseif upsid==2 then
        data.stype = 1
        data.sid = self.info.mid
        data.lv = self.mSkillLevel
        data.mlv = const.MaxUPMSkillLevel
        stype = 2
    else
        data.stype = 3
        data.sid = self.bskills[upsid-2].id
        data.lv = self.bskills[upsid-2].level
        data.mlv = const.MaxUPBSkillLevel
        stype = 3
    end
    data.cvalue = SData.getData("pskills",stype,data.lv+1)
    return data
end

function HeroModel:upgradeUPSkill(upsid)
    if upsid==1 then
        self.awakeUp = self.awakeUp + 1
    elseif upsid==2 then
        self.mSkillLevel = self.mSkillLevel+1
    else
        self.bskills[upsid-2].level = self.bskills[upsid-2].level+1
    end
end

function HeroModel:getTalentSkillMax(skillId)
    return SData.getData("bskillopen", skillId)
end

function HeroModel:getTalentSkillData(skillId, skillLv)
    if skillId<1000 then
        local data = SData.getData("mskdatas",skillId+8300, skillLv)
        if type(data)=="table" then
            return data
        else
            return {c=data}
        end
    else
        return SData.getData("bskills",skillId,skillLv)
    end
end

function HeroModel:getTalentSkillName(skillId)
    return Localize("dataSkillName3_" .. skillId)
end

function HeroModel:getTalentSkillInfo(skillId, skillLv)
    if skillId<1000 then
        return StringManager.getFormatString("dataSkillInfo3_" .. skillId, self:getTalentSkillData(skillId,skillLv))
    else
        return StringManager.getFormatString("dataSkillInfo3_" .. skillId, {value=self:getTalentSkillData(skillId,skillLv)})
    end
end

function HeroModel:getHelpSkill()
    local hsid = self.info.hsid
    local msklv = self.mSkillLevel
    if hsid>0 then
        local lv = 1
        local hskdata = nil
        local mlv, clv, curData, nextData = nil
        while true do
            hskdata = SData.getData("hskdatas", hsid, lv)
            if hskdata then
                mlv = lv
                if hskdata.needLevel<=msklv then
                    curData = hskdata
                    clv = lv
                elseif not nextData then
                    nextData = hskdata
                end
            else
                break
            end
            lv = lv+1
        end
        local data = {max=mlv, level=clv, a=curData.a, b=curData.b, id=hsid}
        for k,v in KTPairs(curData) do
            data[k] = v
        end
        if nextData then
            data.nextLv = nextData.needLevel
        end
        return data
    end
end

function HeroModel:getHelpSkillName()
    return Localize("dataSkillName4_" .. self.info.hsid)
end
function HeroModel:getExtSkillName()
    return Localize("btnExtlusiveskills" .. (self.hid + 300))
end
function HeroModel:getExtSkillDesc(data)
    if not data then
        data = self:getExtSkillData()
    end
    local str = Localizef("dataSkillInfo1_" .. (self.hid + 300), data)
    return str
end
function HeroModel:getExtSkillData(lv)
    if not lv then
        lv = 1
    end
    local mid = self.hid + 300
    return SData.getData("mskdatas", mid, lv) or {}
end
--@brief助战
function HeroModel:getHelpSkillFormatName(withLevel)
    local name = self:getHelpSkillName()
    if withLevel then
        local data = self:getHelpSkill()
        return Localizef("dataSkillName4Format2",{name=name, level=data.level})
    else
        return Localizef("dataSkillName4Format", {name=name})
    end
end

function HeroModel:getHelpSkillDesc(data, noSuffix)
    if not data then
        data = self:getHelpSkill()
    end
    local str = StringManager.getFormatString("dataSkillInfo4_" .. self.info.hsid, data)
    if data.nextLv and not noSuffix then
        str = str .. StringManager.getFormatString("dataSkillInfo4Suffix1", {level=data.nextLv})
    else
        str = str .. Localize("dataSkillInfo1Suffix2")
    end
    return str
end
-- @brief助战佣兵提升出战佣兵的属性内容
function HeroModel:getHelpSoldierSkillDesc()
    local slv = self.soldierLevel
    local soldierData = SData.getData("SoldierHelp", slv)
    local str = Localizef("theTableSoldierHelp", soldierData)
    return str
end
local _helpCache = {}
local HelpSkillNormalEffect = class()

function HelpSkillNormalEffect:ctor(sids, params)
    if sids then
        self.sids = {}
        if type(sids) == "number" then
            self.sids[sids] = 1
        else
            for _, sid in ipairs(sids) do
                self.sids[sid] = 1
            end
        end
    end
    self.params = params
end

function HelpSkillNormalEffect:addHelpEffectTo(hero, stat, hskdata)
    if self.sids then
        if not self.sids[hero.info.sid] then
            return
        end
    end
    for k, v in pairs(self.params) do
        stat[k] = (stat[k] or 0) + hskdata[v]
    end
end

local HelpSkillMeleeEffect = class()

function HelpSkillMeleeEffect:ctor(params)
    self.params = params
end

function HelpSkillMeleeEffect:addHelpEffectTo(hero, stat, hskdata)
    if hero.info.range > 10 then
        return
    end
    for k, v in pairs(self.params) do
        stat[k] = (stat[k] or 0) + hskdata[v]
    end
end

local HelpSkillNormalEffects = class()
function HelpSkillNormalEffects:ctor(effects)
    self.effects = effects
end

function HelpSkillNormalEffects:addHelpEffectTo(hero, stat, hskdata)
    for _, effect in ipairs(self.effects) do
        effect:addHelpEffectTo(hero, stat, hskdata)
    end
end

_helpCache[3201] = HelpSkillNormalEffect.new(100, {sNum="a"})
_helpCache[3202] = HelpSkillNormalEffect.new(200, {sNum="a"})
_helpCache[3203] = HelpSkillNormalEffect.new(300, {sHp="a"})
_helpCache[3204] = HelpSkillNormalEffect.new(300, {sAtk="a"})
_helpCache[3205] = HelpSkillNormalEffect.new(400, {sAtk="a"})
_helpCache[3206] = HelpSkillNormalEffect.new(600, {sNum="a"})
_helpCache[3207] = HelpSkillNormalEffect.new(500, {sNum="a"})
_helpCache[3208] = HelpSkillNormalEffect.new(400, {sHp="a"})
_helpCache[4201] = HelpSkillNormalEffect.new(nil, {sAtk="a"})
_helpCache[4202] = HelpSkillNormalEffect.new(nil, {hpPercent="a"})
_helpCache[4203] = HelpSkillNormalEffect.new(nil, {hp="a"})
_helpCache[4204] = HelpSkillNormalEffect.new(nil, {atkPercent="a"})
_helpCache[4205] = HelpSkillNormalEffect.new(nil, {sHp="a"})
_helpCache[4206] = HelpSkillNormalEffect.new(nil, {spd="a"})
_helpCache[4207] = HelpSkillNormalEffect.new(nil, {sNum="a"})
_helpCache[4208] = HelpSkillNormalEffect.new(nil, {sHp="a", sAtk="b", sDef="c"})
_helpCache[4209] = HelpSkillNormalEffect.new(nil, {atkPercent="a", hpPercent="b"})
_helpCache[4210] = HelpSkillNormalEffect.new(700, {sAtk="a", sHp="b"})
_helpCache[4211] = HelpSkillNormalEffect.new(nil, {k="a", hpPercent="b"})
_helpCache[4218] = HelpSkillNormalEffect.new(nil, {atkPercent="a"})
_helpCache[4219] = HelpSkillNormalEffects.new({HelpSkillNormalEffect.new(nil, {hpPercent="a", atkPercent="a"}), HelpSkillNormalEffect.new({300, 400}, {sHp="a", sNum="a"})})
_helpCache[4221] = HelpSkillNormalEffect.new(300, {sAtk="a", sHp="b"})
_helpCache[4223] = HelpSkillNormalEffect.new(nil, {atkPercent="a", def="b"})
_helpCache[4232] = HelpSkillMeleeEffect.new({spd="a", rating="b"})
_helpCache[4233] = HelpSkillNormalEffect.new(nil, {mspd="a", dodge="b"})

function HeroModel:addHelpEffectTo(hero, stat)
    if self.info.hsid>0 then
        local help = _helpCache[self.info.hsid]
        if help then
            local hskdata = self:getHelpSkill()
            help:addHelpEffectTo(hero, stat, hskdata)
        end
    end
end

function HeroModel:getNormalHelpValue(pos)
    local data = SData.getData("hlevels",self.info.type,self.level)
    return data["hadd" .. pos]
end
--@brief获取佣兵name
function HeroModel:getSoldierName()
    return Localize("dataSoldierName" .. self.info.sid)
end

function HeroModel:getSoldierInfo()
    local sinfo = SData.getData("sinfos",self.info.sid)
    if not sinfo then
        sinfo = self.info
    end
    return sinfo
end
--@biref获取佣兵助战加成的表
function HeroModel:getHelpSoldierData(lv)
    local data = SData.getData("SoldierHelp",lv)
    return data
end
--获取佣兵信息
function HeroModel:getSoldierData(lv)
    if not lv then
        lv = self.soldierLevel
    end
    if lv<1 then
        lv = 1
    end
    self.info.type = self.info.type or 1
    local hd = SData.getData("hlevels",self.info.type,self.level)
    if not hd then
        GameLogic.otherGlobalInfo = {"hlevels", self.info.type, self.level}
    end
    self.info.sid = self.info.sid or 100
    local sd = SData.getData("sdatas",self.info.sid,lv)
    if not sd then
        sd = SData.getData("sdatas",100,lv)
    end
    local data = {num=hd.snum, atk=sd.atk, hp=sd.hp}
    if self.skillStat then
        data.num = data.num+self.skillStat.sNum
        data.atk = math.floor((100+self.skillStat.sAtk)*data.atk/100) + self.skillStat.smAtk
        data.hp = math.floor((100+self.skillStat.sHp)*data.hp/100) + self.skillStat.smHp
        data.defenseParam = 1 - (self.skillStat.sDef/100)
        data.sdefParam = 1 - (self.skillStat.smDef or 0)/100
        data.hurtParam = 1 + (self.skillStat.sDam or 0)/100
        data.ascale = (self.skillStat.sSpeed or 0)/100
    end
    return data
end

function HeroModel:getSoldierCost(lv)
    if not lv then
        lv = self.soldierLevel
    end
    return SData.getData("slevels", lv)
end

function HeroModel:getSoldierTalentCost(rtype, lv)
    if rtype == 1 then
        if not lv then
            lv = self.soldierSkillLevel1
        end
        if lv<const.MaxSoldierSkillLevel then
            lv = lv+1
        end
    elseif rtype == 2 then
        if not lv then
            lv = self.soldierSkillLevel2
        end
        if lv<const.MaxSoldierSkillLevel then
            lv = lv+1
        end
    end
    return SData.getData("sklevels", lv)
end

--返回值：攻击力，生命值加成 组成的一个表
function HeroModel:getSoldierTalentData(rtype, lv)
    if not rtype then
        rtype = const.HeroSoldierSkillTalent1
    end
    if rtype == const.HeroSoldierSkillTalent1 then
        if not lv then
            lv = self.soldierSkillLevel1
        end
    else
        if not lv then
            lv = self.soldierSkillLevel2
        end
    end
    return SData.getData("skdatas",self.info.sid+rtype-1,lv)
end

--天赋名称
function HeroModel:getSoldierTalentName(rtype)
    return Localize("dataSkillName2_" .. (self.info.sid+rtype-1))
end

function HeroModel:getSoldierTalentDesc(rtype, lv)
    if lv <= 0 then
        return
    end
    return Localizef("dataSkillInfo2_"..(self.info.sid+rtype-1), self:getSoldierTalentData(rtype, lv))
end

function HeroModel:getHeroData(otherSettings)
    local data = nil
    if self.info.job~=0 then
        data = {hp=self.info.inithp+math.ceil(self.info.lvhp*(self.level-1)), atk=self.info.initatk+math.ceil(self.info.lvatk*(self.level-1))}
        if data then
            if self.starUp>0 then
                data.hp = data.hp+self.starUp*self.info.starHp
                data.atk = data.atk+self.starUp*self.info.starDps
            end
            self:statAllSkills()
            local sst = self.skillStat
            if sst then
                data.hp = math.floor(data.hp*(100+sst.hpPercent)/100)+sst.hp
                data.atk = math.floor(data.atk*(100+sst.atkPercent)/100)+sst.atk

                data.rating = 1+(sst.rating or 0)/100
                data.dodge = (sst.dodge or 0)/100
                data.ascale = (sst.spd or 0)/100
                data.mscale = (sst.mspd or 0)/100
                data.hurtParam = 1+(sst.k or 0)/100
                data.defenseParam = 1-(sst.def or 0)/100
                data.ndefParam = 1-(sst.ndef or 0)/100
                data.sdefParam = 1-(sst.sdef or 0)/100
                data.critical = (sst.critical or 0)/100
                data.criticalNum = 2+(sst.criticalNum or 0)/100
                data.dscritical = (sst.dscritical or 0)/100
            end
            if self.equip then
                data.equip = {id=self.equip.eid, params=self.equip:getSkillParams(), color=self.equip.color, idx=self.equip.idx}
            end
            data.atk_base = data.atk
            data.hp_base = data.hp
            if otherSettings then
                if otherSettings.inBase then
                    if self.awakeStat then
                        local defSkill = self.awakeStat.skills[const.ASkillDef]
                        if defSkill.level>0 then
                            data.defenseParam = (data.defenseParam or 1)*(100-defSkill.data.x)/100
                        end
                    end
                end
                if otherSettings.atkPercent then
                    data.atk = math.floor(data.atk*(100+otherSettings.atkPercent)/100)
                end
                if otherSettings.hpPercent then
                    data.hp = math.floor(data.hp*(100+otherSettings.hpPercent)/100)
                end
            end
        end
    end
    if data then
        return data
    else
        return {hp=0, atk=0}
    end
end

function HeroModel:getHeroDataByLevel(lv, star)
    if self.info.job==0 then
        return {0,0,0}
    else
        local hl = SData.getData("hlevels",self.info.type,lv)
        if not hl then
            return {0,0,0}
        else
            local data = {self.info.inithp+math.ceil(self.info.lvhp*(lv-1))+star*self.info.starHp, self.info.initatk+math.ceil(self.info.lvatk*(lv-1))+star*self.info.starDps, hl.snum}
            if self.skillStat then
                data[1] = math.floor(data[1]*(100+self.skillStat.hpPercent)/100)+self.skillStat.hp
                data[2] = math.floor(data[2]*(100+self.skillStat.atkPercent)/100)+self.skillStat.atk
                data[3] = data[3]+self.skillStat.sNum
            end
            return data
        end
    end
end

function HeroModel:getAddExp()
    return SData.getData("hlevels",self.info.type,self.level).total + self.info.exp + self.exp
end

function HeroModel:computeAddExp(stat)
    local exp = self.exp
    local lv = self.level
    local star = self.starUp
    local mlv = self.maxLv
    exp = exp+stat.exp
    if stat.star>0 then
        star = star+stat.star
        if star>self.info.maxStar then
            star = self.info.maxStar
        end
        if star>self.starUp then
            mlv = mlv+(star-self.starUp)*5
        end
    end
    local nextExp = SData.getData("hlevels", self.info.type, lv).next
    while nextExp>0 and exp>=nextExp and lv<mlv do
        exp = exp-nextExp
        lv = lv+1
        nextExp = SData.getData("hlevels", self.info.type, lv).next
    end
    return lv, mlv, star, exp, nextExp
end

function HeroModel:upgradeWithHeros(stat)
    local olv = self.level
    self.level, self.maxLv, self.starUp, self.exp = self:computeAddExp(stat)
end

function HeroModel:getAwakeSkill(alv)
    local ret = {id=0, levelUp=0, level=1, name=0, info=0}
    local costData = SData.getData("awakes",alv)
    local d1 = costData.addLevel
    local ld = 0
    if alv>1 then
        ld = SData.getData("awakes",alv-1).addLevel
    end
    ret.levelUp = d1-ld
    ret.cost = costData
    local hid = self.hid
    if self.hid>8000 and self.hid<9000 then
        hid = 8100
    end
    if self.hid == 4031 then
        if self.heroState == 1 then
            hid = 4031
        else
            hid = 40312
        end
    end
    local ad = SData.getData("adatas",hid,alv)
    if not ad then
        print("error hero", self.hid, alv)
    end
    ret.id = ad.skill
    ret.level = _heroAwakeLvs[alv]
    ret.name = Localize("dataSkillName5_" .. ret.id)
    ret.info = StringManager.getFormatString("dataSkillInfo5_" .. ret.id, ad)
    ret.ps = ad
    return ret
end

function HeroModel:getAwakeCost(alv)
    return SData.getData("awakes",alv)
end

function HeroModel:getAwakedSkills()
    local ret = {}
    for i, askill in ipairs(self.awakeStat.skills) do
        ret[i] = {id=askill.data.skill, level=askill.level}
        ret[i].name = Localize("dataSkillName5_" .. ret[i].id)
        if ret[i].level>0 then
            ret[i].info = StringManager.getFormatString("dataSkillInfo5_" .. ret[i].id, askill.data)
        end
    end
    return ret
end

local HeroData = class()

function HeroData:ctor(udata)
    self.udata = udata
    self.maxIdx = 0
    self.heroNum = 0
    self.bases = {}
    self.baseMap = {}
    self.baseNum = 0
    self.layouts = {}
    self.layoutsPoses = {}
end

function HeroData:setHeroLayout(hero, lid, lpos, ltype, x, y, hp, isOut)
    local oldLayout = hero.layouts[lid]
    if not self.layouts[lid] then
        self.layouts[lid] = {}
    end
    local lss = self.layouts[lid]
    if oldLayout then
        lss[oldLayout.pos][oldLayout.type] = nil
    end
    if not hero.info or hero.info.job == 0 then
        hero.layouts[lid] = nil
        return
    end
    hero:setLayout(lid, lpos, ltype, x, y, hp, isOut)
    if lpos>0 then
        if not lss[lpos] then
            lss[lpos] = {}
        end
        lss = lss[lpos]
        if lss[ltype] and lss[ltype] ~= hero then
            lss[ltype]:setLayout(lid, 0, 0)
        end
        lss[ltype] = hero
    end
end

--以下为两个兼容逻辑
--如果英雄台上没有出战英雄，则不显示；
--如果没有任何一个英雄台，则显示一个英雄台
--如果当前英雄台数量小于新的英雄台，则默认放位置
function HeroData:getHVHLayouts(lid, num)
    local ret = {}
    local rnum = 0
    for lpos, hs in pairs(self.layoutsPoses[lid] or {}) do
        if num and lpos<=num then
            ret[lpos] = hs
            rnum = rnum+1
        end
    end
    if num and rnum<num then
        ret = {}
        for i=1, num do
            ret[i] = {x=6+6*((i-1)%3+1), y=math.ceil(i/3)*6}
        end
        rnum = num
    end
    if rnum==0 then
        ret[1] = {x=18, y=6}
    end
    return ret
end

function HeroData:changeHeroLayout(hero, lid, lpos, ltype, x, y, hp, isOut)
    if lpos>0 then
        local ohero = self:getHeroByLayout(lid, lpos, ltype)
        if ohero and ohero~=hero then
            self:changeHeroLayout(ohero, lid, 0, 0)
        end
        if ohero then
            self:setCombatData(ohero)
        end
    end
    if hero then
        self:setCombatData(hero)
    end
    if ltype==1 and lid~=const.LayoutPvp and not x then
        local posItem = self:getHeroLayoutPos(lid, lpos)
        if posItem then
            x = posItem.x
            y = posItem.y
        end
    end
    self:setHeroLayout(hero, lid, lpos, ltype, x, y, hp, isOut)
    if lpos==0 and ltype==0 then
        hero.assists = {}
    end
    hero:getHeroData()
    local lstate = 0
    if lid==const.LayoutPvc or lid==const.LayoutPvtAtk or lid==const.LayoutPvtDef then
        lstate = (lpos*10+ltype)*10000+(x or 0)*100+(y or 0)
    elseif lid==const.LayoutPvh or lid==const.LayoutnPvh then
        lstate = lpos*100000000+(hp or 100)*100000+(x or 0)*1000+(y or 0)*10+(isOut or 0)
    else
        lstate = lpos*10+ltype
    end
    self.udata:addCmd({const.CmdHeroLayout, hero.idx, lid, lstate})
end

function HeroData:loadData(data)
    local heros = {}
    local maxIdx = 0
    local num = 0
    for _, h in ipairs(data.heros) do
        heros[h[1]] = HeroModel.new(h)
        if h[1]>maxIdx then
            maxIdx = h[1]
        end
        num = num+1
    end
    for _, hl in ipairs(data.hlayouts) do
        local hid = hl[1]
        local lid = hl[2]
        local lpos,ltype,x,y,hp,isOut
        x, y = 0, 0
        if lid==const.LayoutPvc or lid==const.LayoutPvtAtk or lid==const.LayoutPvtDef then
            local hlid = math.floor(hl[3]/10000)
            lpos = math.floor(hlid/10)
            ltype = hlid%10
            local lother = hl[3]%10000
            y = lother%100
            x = (lother-y)/100
        elseif lid==const.LayoutPvh or lid==const.LayoutnPvh then
            lpos = math.floor(hl[3]/100000000)
            ltype = 1
            local lother = hl[3]%100000000
            isOut = lother%10                   --各位代表是否出战
            hp = math.floor(lother/100000)
            lother = ((lother-isOut)/10)%10000
            y = lother%100
            x = (lother-y)/100
        else
            lpos = math.floor(hl[3]/10)
            ltype = hl[3]%10
        end
        if ltype==1 and x>0 and y>0 then
            self:setHeroLayoutPos(lid, lpos, x, y)
        end
        if not heros[hid] or heros[hid].info.job == 0 then
            self.udata:addCmd({const.CmdHeroLayout, hid, lid, 0})
        else
            self:setHeroLayout(heros[hid], lid, lpos, ltype, x, y, hp, isOut)
        end
    end
    for _, hb in ipairs(data.hbskills) do
        if heros[hb[1]] then
            heros[hb[1]]:setBSkill(hb[2], hb[3], hb[4], hb[5])
        end
    end
    if data.hmics then
        for _, hm in ipairs(data.hmics) do
            if heros[hm[1]] then
                heros[hm[1]]:setMicSkill(hm[2], hm[3], hm[4])
            end
        end
    end
    self.maxIdx = maxIdx
    self.heroNum = num
    self.heros = heros
    self:checkHeroNum()
end

function HeroData:changeHeroLayoutPos(lid, lpos, x, y)
    self:setHeroLayoutPos(lid, lpos, x, y)
    local hero = self:getHeroByLayout(lid, lpos, 1)
    if hero then
        local hl = hero.layouts[lid]
        self:changeHeroLayout(hero, lid, lpos, 1, x, y, hl.hp, hl.isOut)
    end
end

function HeroData:getHero(idx)
    return self.heros[idx]
end

function HeroData:getAllHeros()
    return self.heros
end

function HeroData:getHeroByLayout(lid, lpos, ltype)
    local ret = self.layouts
    if lid then
        ret = ret[lid]
        if ret and lpos then
            ret = ret[lpos]
            if ret and ltype then
                ret = ret[ltype]
                if ret and ltype == 1 then
                    for j = 2, 4 do
                        ret.assists[j-1] = self:getHeroByLayout(lid, lpos, j)
                    end
                end
            end
        end
    end
    return ret
end

function HeroData:getHeroLayoutPos(lid, lpos)
    return self.layoutsPoses and self.layoutsPoses[lid] and self.layoutsPoses[lid][lpos]
end

function HeroData:setHeroLayoutPos(lid, pos, x, y)
    if not self.layoutsPoses[lid] then
        self.layoutsPoses[lid] = {}
    end
    self.layoutsPoses[lid][pos] = {x=x, y=y}
end

--新增一个批量管理layout的类，在调用save方法之前不会实际更改
local HeroForceLayout = class()

function HeroForceLayout:ctor(heroData, lid)
    self.hdata = heroData
    self.lid = lid
    self.layouts = {}
    self.nlayouts = {}
    self.poses = heroData.layoutsPoses[lid] or {}
    self.lmap = {}
    self.nlmap = {}
    if lid==const.LayoutPvtDef or lid==const.LayoutPvtAtk then
        local blevels = {}
        for _, base in ipairs(heroData.bases) do
            table.insert(blevels, {level=base.level})
        end
        GameLogic.mySort(blevels, "level", true)
        self.bases = blevels
        for i,base in ipairs(self.bases) do
            print(i, base.level)
        end
    else
        self.bases = heroData.bases
    end
    local layouts = heroData:getHeroByLayout(lid)
    if layouts then
        for lpos, layout in pairs(layouts) do
            self.layouts[lpos] = {}
            self.nlayouts[lpos] = {}
            for ltype, hero in pairs(layout) do
                self.layouts[lpos][ltype] = {hero=hero, pos=lpos, type=ltype}
                self.nlayouts[lpos][ltype] = {hero=hero, pos=lpos, type=ltype}
                self.lmap[hero] = self.layouts[lpos][ltype]
                self.nlmap[hero] = self.nlayouts[lpos][ltype]
            end
        end
    end
end

function HeroForceLayout:getBase(baseId)
    return self.bases[baseId]
end

function HeroForceLayout:changeHeroLayout(hero, lpos, ltype)
    if lpos>0 then
        local ohero = self:getHeroByLayout(lpos, ltype)
        if ohero and ohero~=hero then
            self:changeHeroLayout(ohero, 0, 0)
        end
    end
    local oldLayout = self.nlmap[hero]
    local lss = self.nlayouts
    if oldLayout then
        lss[oldLayout.pos][oldLayout.type] = nil
    end
    if lpos>0 then
        self.nlmap[hero] = {hero=hero, pos=lpos, type=ltype}
        if not lss[lpos] then
            lss[lpos] = {}
        end
        lss[lpos][ltype] = self.nlmap[hero]
    else
        self.nlmap[hero] = nil
    end
end

function HeroForceLayout:getLayouts()
    return self.nlayouts
end

function HeroForceLayout:getLayout(hero)
    return self.nlmap[hero]
end

function HeroForceLayout:getHeroByLayout(lpos, ltype)
    local lss = self.nlayouts
    local ret = lss[lpos] and lss[lpos][ltype] and lss[lpos][ltype].hero
    if ret and ltype == 1 then
        for j = 2, 4 do
            ret.assists[j-1] = self:getHeroByLayout(lpos, j)
        end
    end
    return ret
end

function HeroForceLayout:isChanged()
    local map1, map2 = self.lmap, self.nlmap
    for hero, l in pairs(map1) do
        if not map2[hero] or map2[hero].pos~=l.pos or map2[hero].type~=l.type then
            return true
        end
    end
    for hero, l in pairs(map2) do
        if not map1[hero] or map1[hero].pos~=l.pos or map1[hero].type~=l.type then
            return true
        end
    end
    return false
end

function HeroForceLayout:isRepeat()
    local map = self.nlmap
    local helpHero = {}
    local count = {}
    for _, v in pairs(map) do
        if v.type>1 then
            table.insert(helpHero, v.pos*10000 + v.hero.hid)
        end
    end
    for _,v in ipairs(helpHero) do
        if not count[v] then
            count[v] = 0
        end
        count[v] = count[v]+1
        if count[v]>1 then
            return true
        end
    end
    return false
end

function HeroForceLayout:save()
    if self:isChanged() then
        local map1, map2 = self.lmap, self.nlmap
        for hero, l in pairs(map1) do
            if not map2[hero] then
                self.hdata:changeHeroLayout(hero, self.lid, 0, 0)
            end
        end
        --如果初始化保存阵型时，没有阵型信息，则全部初始化
        for i=1, 3 do
            if not self.poses[i] or self.poses[i].x==0 or self.poses[i].y==0 then
                for j=1, 3 do
                    self.poses[j] = {x=6+6*((j-1)%3+1), y=math.ceil(j/3)*6}
                end
                break
            end
        end
        for hero, l in pairs(map2) do
            local x, y = 0, 0
            if self.poses[l.pos] and l.type==1 then
                x, y = self.poses[l.pos].x, self.poses[l.pos].y
            end
            if not map1[hero] or map1[hero].pos~=l.pos or map1[hero].type~=l.type then
                self.hdata:changeHeroLayout(hero, self.lid, l.pos, l.type, x, y)
            end
        end
        return true
    end
    return false
end

function HeroData:getForceLayouts(lid)
    return HeroForceLayout.new(self, lid)
end

function HeroData:getHeroNum()
    return self.heroNum
end

function HeroData:getHeroMax()
    return const.InitHeroNum+self.udata:getProperty(const.ProHeroNum)
end

function HeroData:addBase(base)
    if not self.baseMap[base] then
        self.baseNum = self.baseNum+1
        self.baseMap[base] = self.baseNum
        self.bases[self.baseNum] = base
        base.lidx = self.baseNum
    end
end

local _hlayoutTypes = {10,20,30}

function HeroData:removeBase(base)
    if self.baseMap[base] and base.lidx then
        for _,lid in ipairs(_hlayoutTypes) do
            local inBaseHeroes = self:getHeroByLayout(lid, base.lidx)
            if inBaseHeroes then
                for ltype, hero in pairs(inBaseHeroes) do
                    self:changeHeroLayout(hero, lid, 0, 0)
                end
            end
            for idx=base.lidx+1, self.baseNum do
                local otherBase = self.bases[idx]
                if otherBase then
                    self.bases[idx-1] = otherBase
                    otherBase.lidx = idx-1
                    self.baseMap[otherBase] = idx-1
                    inBaseHeroes = self:getHeroByLayout(lid, idx)
                    if inBaseHeroes then
                        for ltype, hero in pairs(inBaseHeroes) do
                            local hl = hero.layouts[lid]
                            self:changeHeroLayout(hero, lid, idx-1, ltype, hl.x, hl.y, hl.hp, hl.isOut)
                        end
                    end
                end
            end
        end
        self.baseMap[base] = nil
        self.bases[self.baseNum] = nil
        self.baseNum = self.baseNum-1
        base.lidx = nil
    end
end

--初始化远征布局信息
function HeroData:initPvhHeros(heros,isNightmare)
    local changeMap = {}
    local outNum = self.baseNum
    local lid = isNightmare and const.LayoutnPvh or const.LayoutPvh
    for i=1, 15 do
        local hero = self:getHeroByLayout(lid, i, 1)
        if hero then
            self:setHeroLayout(hero, lid, 0, 0)
            changeMap[hero.idx] = 0
        end
    end
    for i, hero in ipairs(heros) do
        local hpos = self:getHeroLayoutPos(lid, i)
        local x, y = 0, 0
        if hpos then
            x = hpos.x
            y = hpos.y
        end
        local isOut = i<=outNum and 1 or 0
        local hstate = isOut+y*10+x*1000+100*100000+i*100000000     --出战的英雄在heros中往前放   10^3~7 pos.x 10^3~7 10^1~2 pos.y 10^0是否出战
        self:setHeroLayout(hero, lid, i, 1, x, y, 100, isOut)
        changeMap[hero.idx] = hstate
    end
    local ret = {}
    for k, v in pairs(changeMap) do
        table.insert(ret, {k,v})
    end
    return ret
end

--应用于Pvh的布局类；行为和其他地方有所不同。
local PvhForceLayouts = class()

function PvhForceLayouts:ctor(hdata,isNightmare)
    local heros = {}
    local hmap = {}
    local hlayouts = {}
    local lid = isNightmare and const.LayoutnPvh or const.LayoutPvh
    local backPos = {}
    self.lid = lid
    for i=1, 15 do
        local hero = hdata:getHeroByLayout(lid, i, 1)
        if hero then
            heros[i] = hero
            hlayouts[i] = {hp=hero.layouts[lid].hp, isOut=hero.layouts[lid].isOut, pos=i, type=1, hero=hero}
            hmap[hero] = hlayouts[i]
        end
    end
    for i=1, 5 do
        local pos = hdata:getHeroLayoutPos(lid, i)
        if pos then
            backPos[i] = {x=pos.x or 0, y=pos.y or 0}
        else
            backPos[i] = {x=0, y=0}
        end
    end
    self.backPos = backPos
    self.heros = heros
    self.hlayouts = hlayouts
    self.heroMap = hmap
    self.hdata = hdata
end

function PvhForceLayouts:getBase(baseId)
    return self.hdata.bases[baseId]
end

function PvhForceLayouts:changeHeroLayout(hero, lpos)
    local olayout = self.heroMap[hero]
    if lpos>0 then
        if olayout.pos~=lpos then
            local ol = self.hlayouts[lpos]
            if ol then
                --交换
                local ohero = self.hlayouts[lpos].hero
                local nlayout = self.heroMap[ohero]
                olayout.pos, olayout.isOut, nlayout.pos, nlayout.isOut = nlayout.pos, nlayout.isOut, olayout.pos, olayout.isOut
                self.hlayouts[olayout.pos] = olayout
                self.hlayouts[nlayout.pos] = nlayout
            else
                self.hlayouts[olayout.pos] = nil
                olayout.pos = lpos
                self.hlayouts[olayout.pos] = olayout
            end
        end
        olayout.isOut = 1
    else
        olayout.isOut = 0
    end
end

function PvhForceLayouts:getLayout(hero)
    local layout = self.heroMap[hero]
    if layout and (layout.isOut==0 or layout.hp==0) then
        layout = nil
    end
    return layout
end

function PvhForceLayouts:getAllHeros()
    local ret = {}
    for h, hl in pairs(self.hlayouts) do
        if hl.hp>0 then
            ret[hl.hero.idx] = hl.hero
        end
    end
    return ret
end

function PvhForceLayouts:getHeroByLayout(lpos, ltype)
    local hl = self.hlayouts[lpos]
    if hl and hl.isOut==1 and hl.hp>0 then
        local ret = hl.hero
        ret.assists = {}
        return ret
    end
end

function PvhForceLayouts:getHeroLayout(lpos)
    return self.hlayouts[lpos]
end

function PvhForceLayouts:changeHeroLayoutPos(lpos, x, y)
    if not self.hdata.layoutsPoses[self.lid] then
        self.hdata.layoutsPoses[self.lid] = {}
    end
    self.hdata.layoutsPoses[self.lid][lpos] = {x=x, y=y}
end

function PvhForceLayouts:getLayouts()
    local ret = {}
    for i=1, 5 do
        local hl = self.hlayouts[i]
        if hl and hl.isOut==1 and hl.hp>0 then
            ret[i] = hl
        end
    end
    return ret
end

function PvhForceLayouts:save()
    local ret = {}
    self.hdata.layouts[self.lid] = {}
    for _, hl in pairs(self.hlayouts) do
        local hero = hl.hero
        local hl2 = hero.layouts[self.lid]
        local x, y = 0, 0
        local pos = self.backPos[hl.pos]
        if pos then
            x, y = pos.x, pos.y
        end
        local tx, ty = 0, 0
        pos = self.hdata:getHeroLayoutPos(self.lid, hl.pos)
        if pos then
            tx, ty = pos.x, pos.y
        end
        if tx~=x or ty~=y or hl.isOut~=hl2.isOut or hl.pos~=hl2.pos or hl.hp~=hl2.hp then
            hero:setLayout(self.lid, hl.pos, 1, tx, ty, hl.hp, hl.isOut)
            ret[hero.idx] = hl.pos*100000000+hl.hp*100000+tx*1000+ty*10+hl.isOut
        end
        self.hdata.layouts[self.lid][hl.pos] = {hero}
        self.hdata:changeHeroLayout(hero, self.lid, hl.pos, 1, tx, ty, hl.hp, hl.isOut)
    end
    return ret
end

function HeroData:getPvhForceLayouts()
    return PvhForceLayouts.new(self)
end

function HeroData:getnPvhForceLayouts()
    return PvhForceLayouts.new(self,true)
end

function HeroData:isSoldier(sid)
    return sid <= 1000
end

function HeroData:isHero(hid)
    return (hid%1000) ~= 0
end

function HeroData:getHeroByHid(hid)
    local heros = self:getAllHeros()
    local heroDatas = {}
    if heros then
        for _,hero in pairs(heros) do
            if hero.hid == hid and self:isHero(hid) then
                table.insert(heroDatas,hero)
            end
        end
    end
    return heroDatas
end

function HeroData:addNewHero(idx, hid)
    local hdata = {idx, hid}
    if idx>self.maxIdx then
        self.maxIdx = idx
    end
    self.heros[idx] = HeroModel.new(hdata)
    self.heroNum = self.heroNum+1
    -- 获得英雄的统计
    if not self.__isTemp then
        local rating = self.heros[idx].info.rating
        if rating and rating >= 2 then
            local star = self.heros[idx].starUp
            -- 怕以后能直接获取多星的英雄,连星级也算进去
            for i=0,star do
                local statId = 1000+rating*100+i
                GameLogic.getUserContext().activeData:finishActCondition(statId, 1)
            end
            if rating ==3 then
                -- GameLogic.getUserContext().achieveData:finish(10,1)
                GameLogic.getUserContext().achieveData:finish(const.ActTypeSRHeroGet,1)
            elseif rating == 4 then
                -- GameLogic.getUserContext().achieveData:finish(11,1)
                GameLogic.getUserContext().achieveData:finish(const.ActTypeSSRHeroGet,1)
            end
        end
        self:setCombatData(self.heros[idx])
        -- 日常任务获得英雄
        GameLogic.getUserContext().activeData:finishActCondition(hid*10000+const.ActTypeHeroGet, 1)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroGet, 1)
    end

    return self.heros[idx]
end
function HeroData:makeHero(hid)
    local hdata = {0, hid}
    return HeroModel.new(hdata)
end

function HeroData:getSoldierData(sid,lv)
    local sinfo = SData.getData("sinfos",sid)

    local sd = SData.getData("sdatas",sid,lv)
    local data = {atk=sd.atk, hp=sd.hp}
    return sinfo,data
end

function HeroData:makePet(pets,ptype)
    local pid = pets.curPid
    local hid = pid*10+8000+ptype
    local hero = self:makeHero(hid)
    hero.level = pets.level
    hero.exp = pets.exp
    for i=1, 4 do
        hero.bskills[i] = {id=i, level=pets.skill[i+2]}
    end
    --联盟神兽没有觉醒，用觉醒等级代替天神技等级
    hero.awakeUp = pets.skill[1]
    hero.mSkillLevel = pets.skill[2]
    if ptype == 0 then
        hero.hid = hero.hid+3
    end
    hero.isPet = true
    return hero
end

function HeroData:checkHeroNum()
    local num = self:getHeroNum()
    local max = self:getHeroMax()
    if num>max then
        local hidxs = {}
        for hidx, _ in pairs(self.heros) do
            table.insert(hidxs, hidx)
        end
        table.sort(hidxs)
        local cmd = {const.CmdHeroDelete}
        local idx = 2
        for i=num, max+1, -1 do
            self:removeHero(hidxs[i])
            cmd[idx] = hidxs[i]
            idx = idx+1
        end
        self.maxIdx = hidxs[max]
        self.heroNum = max
        self.udata:addCmd(cmd)
    end
end

function HeroData:changeHeroLock(hero)
    if hero and hero==self.heros[hero.idx] then
        hero.lock = 1-hero.lock
        self.udata:addCmd({const.CmdHeroLock, hero.idx, hero.lock})
        return true
    end
end

function HeroData:awakeHero(hero,params)
    if hero and hero==self.heros[hero.idx] then
        local vacancyRes = {}--需要通知后端扣除的资源
        if params and params.type == "oneKey" then
            vacancyRes = params.vacancyRes
        else
            local costData = hero:getAwakeCost(hero.awakeUp+1)
            self.udata:changeRes(const.ResSpecial, -costData.special)
            self.udata:changeRes(const.ResZhanhun, -costData.zhanhun)
            self.udata:changeRes(const.ResMedicine, -costData.medicine)
            self.udata:changeItem(const.ItemFragment, hero.hid, -costData.fragment)
        end
        hero.awakeUp = hero.awakeUp+1
        hero:loadDatas()
        self.udata:addCmd({const.CmdHeroAwake, hero.idx, vacancyRes})
        -- 英雄觉醒的战力提升
        self:setCombatData(hero)
        -- 日常任务英雄觉醒
        GameLogic.getUserContext().activeData:finishActConditionOnce(hero.hid*10000+const.ActTypeHeroAwake, hero.awakeUp)
        GameLogic.getUserContext().activeData:finishActConditionOnce(1000*10000+const.ActTypeHeroAwake, hero.awakeUp)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroAwake, 1)
        return true
    end
end

function HeroData:upgradeMainSkill(hero,params)
    if hero and hero==self.heros[hero.idx] then
        local type, lv = 0, 1
        if params and params.type == "oneKey" then
            type = 1
            lv = params.addMainSkillLv
        else
            local costData = hero:getMainSkillCost()
            self.udata:changeRes(const.ResSpecial, -costData.cvalue)
        end
        hero.mSkillLevel = hero.mSkillLevel+lv

        local achieveData = self.udata.achieveData
        -- achieveData:finish(7,hero.mSkillLevel)
        achieveData:finish(const.ActTypeHeroAuto,hero.mSkillLevel)

        self.udata:addCmd({const.CmdHeroUpgradeMain, hero.idx, type, lv})
        -- 升级主动技能的战力提升
        self:setCombatData(hero)
        -- 日常任务英雄技能升级
        GameLogic.getUserContext().activeData:finishActConditionOnce(hero.hid*10000+const.ActTypeHeroAuto, hero.mSkillLevel)
        GameLogic.getUserContext().activeData:finishActConditionOnce(1000*10000+const.ActTypeHeroAuto, hero.mSkillLevel)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroAuto,lv)
        return true
    end
end

function HeroData:upgradeSoldier(hero, params)
    if hero and hero==self.heros[hero.idx] then
        local type, lv = 0, 1
        if params and params.type == "oneKey" then
            lv = params.addSoliderLv
            type = 1
        else
            local costData = hero:getSoldierCost()
            self.udata:changeRes(const.ResZhanhun, -costData.next)
        end
        hero.soldierLevel = hero.soldierLevel+lv
        self.udata:addCmd({const.CmdHeroUpgradeSoldier, hero.idx, type, lv})

        --成就
        local achieveData = self.udata.achieveData
        -- achieveData:finish(2,hero.soldierLevel)
        achieveData:finish(const.ActTypeMercenaryLevels,hero.soldierLevel)

        GameLogic.getUserContext().activeData:finishActConditionOnce(hero.hid*10000+const.ActTypeMercenaryLevels, hero.soldierLevel)
        GameLogic.getUserContext().activeData:finishActConditionOnce(1000*10000+const.ActTypeMercenaryLevels, hero.soldierLevel)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeMercenaryLevels, lv)

        -- 佣兵升级的战力提升
        self:setCombatData(hero)
        return true
    end
end

function HeroData:upgradeSoldierSkill(hero, rtype, lv)
    if hero and hero==self.heros[hero.idx] then
        local costData = hero:getSoldierTalentCost(rtype, lv)
        self.udata:changeRes(const.ResZhanhun, -costData.cvalue)
        if rtype == const.HeroSoldierSkillTalent1 then
            hero.soldierSkillLevel1 = hero.soldierSkillLevel1+1
            self.udata:addCmd({const.CmdHeroUpgradeSSkill, hero.idx, const.HeroSoldierSkillTalent1 - 1})
        elseif rtype == const.HeroSoldierSkillTalent2 then
            hero.soldierSkillLevel2 = hero.soldierSkillLevel2+1
            self.udata:addCmd({const.CmdHeroUpgradeSSkill, hero.idx, const.HeroSoldierSkillTalent2 - 1})
        end
        hero:getHeroData()
        -- 佣兵技能升级的战力提升
        self:setCombatData(hero)
        -- 日常任务佣兵技能升级
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeMercenarySkills, 1)
        GameLogic.getUserContext().activeData:finishActConditionOnce(hero.hid*10000+const.ActTypeMercenarySkills,
         hero.soldierSkillLevel1)
        GameLogic.getUserContext().activeData:finishActConditionOnce(1000*10000+const.ActTypeMercenarySkills,
         hero.soldierSkillLevel1)
        GameLogic.getUserContext().activeData:finishActConditionOnce(hero.hid*10000+const.ActTypeMercenarySkills,
         hero.soldierSkillLevel2)
        GameLogic.getUserContext().activeData:finishActConditionOnce(1000*10000+const.ActTypeMercenarySkills,
         hero.soldierSkillLevel2)
        return true
    end
end

function HeroData:removeHero(hidx)
    local hero = self.heros[hidx]
    if hero.layouts then
        for lid, layout in pairs(hero.layouts) do
            self:changeHeroLayout(hero, lid, 0, 0)
        end
    end
    self.heros[hidx] = nil
    self.heroNum = self.heroNum-1
    GameEvent.sendEvent("BattleHeroChange", hero)
end

function HeroData:upgradeHero(hero, us, params)
    if hero and hero==self.heros[hero.idx] then
        local oldStar = hero.starUp
        local oldLevel = hero.level
        hero:upgradeWithHeros(us)

        local achieveData = self.udata.achieveData
        -- achieveData:finish(6,hero.level)
        achieveData:finish(const.ActTypeHeroLevelUp,hero.level)

        local cmd = {const.CmdHeroUpgrade, hero.idx}
        if params and params.type == "oneKey" then
            cmd[3] = -params.addExp
            cmd[4] = -params.addStar
        else
            local idx = 3
            for hidx,num in pairs(us.heros) do
                self:removeHero(hidx)
                cmd[idx] = hidx
                idx = idx+1
            end
            --消耗芯片
            for i,num in pairs(us.chips) do
                self.udata:changeItem(const.ItemChip, i, -num)
                cmd[idx] = {i,num}
                idx = idx + 1
            end
        end

        self.udata:addCmd(cmd)
        -- 英雄升级的战力提升
        self:setCombatData(hero)
        -- 英雄升星的统计
        local rating = hero.info.rating
        if rating and rating >= 2 and hero.starUp > oldStar then
            for i=oldStar+1, hero.starUp do
                local statId = 1000+rating*100+i
                GameLogic.getUserContext().activeData:finishActCondition(statId, 1)
            end
        end
        -- 触发活动英雄升级升星
        GameLogic.getUserContext().activeData:finishActConditionOnce(hero.hid*10000+const.ActTypeHeroLevelUp,hero.level)
        GameLogic.getUserContext().activeData:finishActConditionOnce(1000*10000+const.ActTypeHeroLevelUp,hero.level)
        GameLogic.getUserContext().activeData:finishActConditionOnce(hero.hid*10000+const.ActTypeHeroStarUp,hero.starUp)
        GameLogic.getUserContext().activeData:finishActConditionOnce(1000*10000+const.ActTypeHeroStarUp,hero.starUp)
        -- 日常任务英雄升级升星(finishActCondition里已添加)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroLevelUp,hero.level-oldLevel)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroStarUp,hero.starUp - oldStar)
        return true
    end
end

function HeroData:explainHero(hero)
    if hero and hero==self.heros[hero.idx] then
        local cmd = {const.CmdHeroExplain, hero.idx}
        self:removeHero(hero.idx)
        self.udata:changeItem(const.ItemFragment, hero.hid, math.floor(hero.info.fragNum*0.8))
        self.udata:addCmd(cmd)
        return true
    end
end
--发送英雄品质rating(1~5对应n r sr ssr ur)
function HeroData:mergeHero(hid,rating)
    local idx = self.maxIdx+1
    local newHero = self:addNewHero(idx, hid)
    self.udata:changeItem(const.ItemFragment, hid, -newHero.info.fragNum)
    self.udata:addCmd({const.CmdHeroMerge,idx, hid,rating})
end

function HeroData:receiveHero(hid)
    local idx = self.maxIdx+1
    local newHero = self:addNewHero(idx, hid)
    GameLogic.getUserContext():setProperty(const.ProGuideHero,1)
    self.udata:addCmd({const.CmdHeroPveGuide, idx, hid})
end

function HeroData:buyNewHero(hid)
    local idx = self.maxIdx+1
    local newHero = self:addNewHero(idx, hid)
    self.udata:addCmd({const.CmdHeroBuy, idx, hid})
end

function HeroData:changeHeroBSkill(hero, bidx, orderId)
    if hero and hero==self.heros[hero.idx] then
        local cmd = {const.CmdHeroChangeBSkill, hero.idx, bidx, orderId}
        local bskill = hero.bskills[bidx]
        if bskill.curLight>0 then
            bskill.lights[bskill.curLight].state = 1
        end
        bskill.curLight = orderId
        bskill.lights[orderId].state = 2
        bskill.id = bskill.lights[orderId].id
        bskill.level = bskill.lights[orderId].level
        hero:statAllSkills()
        self.udata:addCmd(cmd)
        return true
    end
end

function HeroData:changeSpecailHeroBSKill(hero, bidx, id,level)
    if hero and hero==self.heros[hero.idx] then
        local bskill = hero.bskills[bidx]
        if bskill.curLight>0 then
            bskill.lights[bskill.curLight].state = 1
        end
        bskill.curLight = 0
        bskill.id = id
        bskill.level = level
        hero:statAllSkills()
        return true
    end
end

function HeroData:micHero(hero, sidx)
    local skill = hero:getMicSkill(sidx)
    skill.exp = skill.exp+1
    if skill.exp>=skill.nextExp then
        skill.exp = 0
        skill.level = skill.level+1
    end
    hero:setMicSkill(sidx, skill.level, skill.exp)
    -- 英雄强化时战斗力提升
    self:setCombatData(hero)
    -- 日常任务英雄强化
    GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroInten,1)
    self.udata:changeRes(const.ResMicCrystal, -1)
    self.udata:addCmd({const.CmdHeroMic, hero.idx, sidx, 1})
end

function HeroData:costHeros(hids, stime)
    for _, hidx in ipairs(hids) do
        self.heros[hidx]:setDead(stime)
    end
end

function HeroData:healHero(hero, stime, cost)
    hero.recoverTime = 0
    self.udata:changeRes(const.ResCrystal, -cost)
    GameLogic.statCrystalCost("治疗英雄消耗",const.ResCrystal, -cost)
    self.udata:addCmd({const.CmdHeroHeal, hero.idx, stime})
end

--英雄战斗力=（英雄本体战斗力+佣兵战斗力+装备战斗力+助战英雄战力）*总系数
function HeroData:getCombatData(hero)
    local combat = 0
    local mComb = self:getHeroCombatData(hero)                    -- 本体
    local sComb = self:getSoldierCombatData(hero)                 -- 佣兵
    local eComb = self:getEquipCombatData(hero)                   -- 装备
    local hComb = 0                                               -- 助战
    if hero.assists then
        for i,v in ipairs(hero.assists) do
            hComb = hComb+self:getHelpCombatData(v)
        end
    end

    combat = (mComb+sComb+eComb+hComb)*combData.ratio[1]
    return math.floor(combat)
end

--英雄本体战斗力=英雄属性战力+(主动技能等级*m+觉醒技战斗力)*英雄品质系数
function HeroData:getHeroCombatData(hero)
    local heroInfo = SData.getData("accpfight", hero.hid)
    local combat = 0
    local combat1 = 0
    -- 英雄属性战力=(生命值*a*(1+抗暴击%*d)*(1+闪避%*g)*(1+英雄减伤%*h)*(1+技能伤害减免%*k)+攻击力*b*(1+暴击%*c*(1+暴击倍率%*e/2))*(1+命中%*f)*(1+英雄伤
    local hdata = hero:getHeroData()
    if hdata then
        --[[
        "combConfigDesc":{
        "chero":["攻击力","生命值","暴击率","抗暴击","暴击倍率","命中","闪避","普通攻击减伤","技能减伤","英雄伤害系数","速度"],
        "csoldier":["佣兵生命","佣兵攻击力","佣兵系数"],
        "cskill":["被动技能","主动技能","觉醒技能","装备技能"],
        "hskill":["助战技能"]
        ]]
        local sst = hero.skillStat
        combat = hdata.hp*combData.chero[2]*(1+(sst.dscritical or 0)/100*combData.chero[4])*(1+(sst.dodge or 0)/100*combData.chero[7])*(1+(sst.rating or 0)/100*combData.chero[9])
                *(1+(sst.ndef or 0)/100*combData.chero[8])+hdata.atk*combData.chero[1]*(1+((sst.criticalNum or 0)/100*combData.chero[5]/2)*(sst.critical or 0)/100*combData.chero[3])
                *(1+(sst.sdef or 0)/100*combData.chero[6])*(1+(sst.k or 0)/100*combData.chero[10])
    end
    -- 觉醒技能战斗力
    if hero.awakeStat and hero.awakeStat.skills then
        for i=1,#hero.awakeStat.skills do
            local skillLv = hero.awakeStat.skills[i].level
            if skillLv>0 then
                combat1 = combat1+heroInfo.awark[skillLv]
            end
        end
    end
    -- 主动技能战斗力
    if hero.mSkillLevel then
        combat1 = combat1+hero.mSkillLevel*combData.cskill[2]
    end
    return combat+combat1*heroInfo.qualiynum
end

-- 佣兵战斗力=佣兵战斗力系数*(单佣兵生命*佣兵生命系数+单佣兵攻击*佣兵攻击系数)*佣兵数
function HeroData:getSoldierCombatData(hero)
    local combat = 0
    local sdata = hero:getSoldierData()
    if sdata then
        combat = (sdata.atk*combData.csoldier[2]+sdata.hp*combData.csoldier[1])*sdata.num*combData.csoldier[3]
    end
    return combat
end

-- 装备战斗力
function HeroData:getEquipCombatData(hero)
    local combat = 0
    if hero.equip then
        combat = hero.equip.elvup*combData.cskill[4]
    end
    return combat
end

-- 助战英雄战力=助战技能等级*n*助战英雄品质系数
function HeroData:getHelpCombatData(hero)
    local heroInfo = SData.getData("accpfight", hero.hid)
    local combat = 0
    local hskill = hero:getHelpSkill()          -- 助战技能
    if hskill then
        combat = hskill.level*combData.hskill[1]*heroInfo.qualiynum
    end
    return combat
end

function HeroData:setCombatData(hero)
    if hero.info.job==0 or hero.hid>=5000 then
        return
    end
    local combat = self:getCombatData(hero)
    hero.combat = combat
    self.refreshCombatDirty = true
end

function HeroData:getAllCombatData()
    local hero
    local allCombat = 0
    for i=1,5 do
        hero = self:getHeroByLayout(const.LayoutPvp, i, 1)
        if hero then
            allCombat = allCombat+self:getCombatData(hero)
        end
    end
    return math.floor(allCombat)
end

function HeroData:refreshAllCombatData()
    if self.refreshCombatDirty then
        self:setAllCombatData()
        GameEvent.sendEvent("refreshHeroData")
        self.refreshCombatDirty = nil
        self.refreshPvtCombat()
        self.refreshPvcCombat()
    end
end

function HeroData:setAllCombatData()
    local newAllCombat = self:getAllCombatData()
    local allCombat = GameLogic.getUserContext():getProperty(const.ProCombat)
    if allCombat then
        if allCombat ~= newAllCombat then
            self.udata.comChanged = true
            GameLogic.getUserContext():setProperty(const.ProCombat,newAllCombat)

            local addCombat = newAllCombat-allCombat
            if addCombat>0 then
                addCombat = math.floor(addCombat)
                display.pushNotice(Localizef("upComtabAdd",{num=addCombat}),{color={0,255,0}})
            elseif addCombat<0 then
                addCombat = math.ceil(addCombat)
                display.pushNotice(Localizef("upComtabSub",{num=-addCombat}))
            end
        end
    else
        GameLogic.getUserContext():setProperty(const.ProCombat,newAllCombat)
    end
end

--用pvp阵型设置竞技场的默认阵型
function HeroData:setPvcForceLayouts()
    for i=1,5 do
        local hero = self:getHeroByLayout(const.LayoutPvp, i, 1)
        if hero then
            local layout = hero.layouts[const.LayoutPvp]
            self:changeHeroLayout(hero,const.LayoutPvc,i,1,layout.x or 0,layout.y or 0)
        end
    end
end

--试炼防守阵容战斗力
function HeroData:refreshPvtCombat()
    -- local context = GameLogic.getUserContext()
    -- local LineCom = 0
    -- local def = GameLogic.getUserContext().heroData:getForceLayouts(const.LayoutPvtDef)
    -- local ltb = def:getLayouts() or empty
    -- for i=1,9 do
    --     for j=1,4 do
    --         if j==1 then
    --             --出战以及替补
    --             if ltb[i] and ltb[i][j] then
    --                 LineCom = LineCom + GameLogic.getUserContext().heroData:getHeroCombatData(ltb[i][j].hero)
    --                 LineCom = LineCom + GameLogic.getUserContext().heroData:getEquipCombatData(ltb[i][j].hero)
    --             end
    --         else
    --             --助战
    --             if ltb[i] and ltb[i][j] then
    --                 LineCom = LineCom + GameLogic.getUserContext().heroData:getHelpCombatData(ltb[i][j].hero)
    --             end
    --         end
    --     end
    -- end
    -- local ProCombat = math.floor(LineCom*combData.ratio[1])
    -- context:setProperty(const.ProCombatPvt, ProCombat)
    -- context:addCmd({const.CmdAllCombat,GameLogic.getSTime(),ProCombat,2})
    -- print("试炼防守战斗力:",ProCombat)
end

--竞技场英雄战斗力
function HeroData:refreshPvcCombat()
    -- --计算上阵五个英雄的战斗力+5*3个辅助战斗力的综合
    -- --英雄战斗力包括英雄本体战斗力、佣兵战斗力、装备战斗力
    -- local pvc = GameLogic.getUserContext().heroData:getForceLayouts(const.LayoutPvc)
    -- local ltb = pvc:getLayouts() or {}
    -- local context = GameLogic.getUserContext()
    -- local LabCom = 0
    -- for i=1, 5 do
    --     for j=1,4 do
    --         if j==1 then
    --              --出战
    --             if ltb[i] and ltb[i][j] then
    --                 LabCom = LabCom+GameLogic.getUserContext().heroData:getHeroCombatData(ltb[i][j].hero)
    --                 LabCom = LabCom+GameLogic.getUserContext().heroData:getSoldierCombatData(ltb[i][j].hero)
    --                 LabCom = LabCom+GameLogic.getUserContext().heroData:getEquipCombatData(ltb[i][j].hero)
    --             end
    --         else
    --             --助战
    --             if ltb[i] and ltb[i][j] then
    --                 LabCom = LabCom+GameLogic.getUserContext().heroData:getHelpCombatData(ltb[i][j].hero)
    --             end
    --         end
    --     end
    -- end
    -- local ProCombat = math.floor(LabCom*combData.ratio[1])
    -- context:setProperty(const.ProCombatPvc,ProCombat)
    -- context:addCmd({const.CmdAllCombat,GameLogic.getSTime(),ProCombat,1})
    -- print("竞技场综合战斗力",ProCombat)
end

function HeroData:getTopAvgLevel(topN)
    local levelList = {}
    local allHeros = self:getAllHeros()
    for _, hero in pairs(allHeros) do
        if hero.info.job>0 then
            table.insert(levelList, hero.level)
        end
    end
    table.sort( levelList,function(a,b)
        return a>b
    end)
    local levelAll = 0
    local numAll = 0
    if topN > #levelList then
        topN = #levelList
    end
    for i=1, topN do
        if levelList[i] > 0 then
            levelAll = levelAll + levelList[i]
            numAll = numAll+1
        end
    end
    if numAll == 0 then
        numAll = 1
    end
    return math.floor(levelAll/numAll)
end

return HeroData
