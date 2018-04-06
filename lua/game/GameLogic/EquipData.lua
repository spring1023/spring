local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local EquipModel = class()

function EquipModel:ctor(eidx, data)
    self.idx = eidx

    self.eid = data[1]
    self.hidx = data[2]
    self.level = data[3]
    self.exp = data[4]
    self.elvup = data[5]
    self.eparts = {}
    for i=1, 5 do
        self.eparts[i] = data[5+i]
    end
    self.color = math.floor(self.elvup/4)+1
end

function EquipModel:dctor()
    local eidx = self.idx
    local data = {self.eid,self.hidx,self.level,self.exp,self.elvup}
    for i=1,5 do
        data[5+i] = self.eparts[i]
    end
    return eidx,data
end

function EquipModel:getPart(idx)
    local install = SData.getData("einstalls",self.eid,self.elvup+1)
    local pitem = install["unit" .. idx]
    return pitem[1], self.eparts[idx], pitem[2], pitem[3]
end

function EquipModel:getName()
    return Localize("dataEquipName" .. self.eid)
end

--兼容方法，回头考虑一下改数值。
function EquipModel:getSkillParams(elv)
    if not elv then
        elv = self.elvup
    end
    local params = {}
    local rparams = SData.getData("einstalls",self.eid,elv+1).effect
    if self.eid==2001 then
        params.m = rparams[1]
        params.a = rparams[2]
    elseif self.eid==2002 then
        params.a = rparams[1]
        params.b = rparams[2]
        params.c = rparams[3]
    elseif self.eid==2003 then
        params.m = rparams[1]
        params.a = rparams[2]
        params.b = rparams[3]
        params.c = rparams[4]
        params.t = rparams[5]
    elseif self.eid==2004 then
        params.a = rparams[1]
        params.b = rparams[2]
        params.c = rparams[3]
        params.d = rparams[4]
        params.e = rparams[5]
    elseif self.eid == 2005 then
        params.a = rparams[1]
        params.b = rparams[2]
        params.c = rparams[3]
        params.d = rparams[4]
    elseif self.eid == 2006 then
        params.a = rparams[1]
        params.b = rparams[2]
        params.c = rparams[3]
    elseif self.eid == 2007 then
        params.a = rparams[1]
        params.b = rparams[2]
        params.c = rparams[3]
        params.d = rparams[4]
        params.n = rparams[5]
    elseif self.eid == 2008 then
        params.a = rparams[1]
    elseif self.eid == 2009 then
        params.a = rparams[1]
    end
    return params
end

function EquipModel:getDesc(mode)
    local params = self:getSkillParams()
    if mode==2 then
        return Localizef("dataEquipSkill" .. self.eid.."_2", params)
    end
    return Localizef("dataEquipSkill" .. self.eid, params)
end

function EquipModel:getExpInfos()
    local install = SData.getData("einstalls",self.eid,self.elvup+1)
    local max = 0
    if install and install.maxLv>self.level then
        local nexp = SData.getData("elevels",self.eid,self.level+self.elvup)
        max = nexp.exp
    end
    return self.exp, max
end
--获取分解后的碎片
function EquipModel:getFragNum()
    local install = SData.getData("elevels",self.eid,1)
    return install.afrag or 0,install.mfrag or 0
end

-- local addParamsSet = {
--     [2001] = {1,3,10,5,6},
--     [2002] = {2,3,11,4,6},
--     [2003] = {1,3,10,5,7},
--     [2004] = {1,3,10,5,7},
--     [2005] = {1,3,10,5,6},
--     [2006] = {2,3,11,4,6},
--     [2007] = {},
-- }
-- local equipParamsSet = {
--     [2001] = {1,2,10,3,5,6},
--     [2002] = {2,9,11,3,4,6},
--     [2003] = {1,8,10,3,5,7},
--     [2004] = {1,8,10,3,5,7},
--     [2005] = {1,2,10,3,5,6},
--     [2006] = {2,9,11,3,4,6},
--     [2007] = {1,8,10,3,5,7},
-- }

function EquipModel:getPartEffect(idx)
    local install = SData.getData("einstalls",self.eid,self.elvup+1)
    local pitem = install["unit" .. idx]
    return Localizef("dataItemEffect" .. install.addParamsSet[idx], {value=pitem[4]})
end

--获取装备所有加成属性的方法
function EquipModel:getDetailParams(lv, elvup, eparts)

    if not lv then
        lv = self.level
    end
    if not elvup then
        elvup = self.elvup
    end
    if not eparts then
        eparts = self.eparts
    end
    local ret = {}
    local baseData = SData.getData("elevels",self.eid,lv+elvup)
    local installsData = SData.getData("einstalls",self.eid,elvup+1)
    for i,effectId in ipairs(installsData.equipParamsSet) do
        ret[effectId] = baseData.effect[i]
    end
    for i,v in ipairs(eparts) do
        if v>0 then
            local effectId = installsData.addParamsSet[i]
            ret[effectId] = ret[effectId]+installsData["unit" .. i][4]
        end
    end
    return ret
end

function EquipModel:getDetailInfos()
    local params = self:getDetailParams()
    local infos = {}
    for effectId=1, 30 do
        if params[effectId] then
            table.insert(infos, Localizef("dataItemEffect" .. effectId, {value=params[effectId]}))
        end
    end
    return infos
end

function EquipModel:getSellPrice()
    local install = SData.getData("einstalls",self.eid,self.elvup+1)
    return install.price
end

function EquipModel:addValueIsPercent(id)
    if id > 2 then
        return true
    end
    return false
end

function EquipModel:getLvupDatas()
    local ret = {}

    local install = SData.getData("einstalls",self.eid,self.elvup+1)
    local maxLv = install.maxLv
    ret.cost = install.cvalue
    ret.needLevel = maxLv
    ret.infos = {}
    local d0 = self:getDetailParams(maxLv, self.elvup, {0,0,0,0,0})
    local d1 = self:getDetailParams(maxLv, self.elvup, {1,1,1,1,1})
    local d2 = self:getDetailParams(maxLv, self.elvup+1, {0,0,0,0,0})
    for effectId=1, 30 do
        if d1[effectId] then
            local ekey = "dataItemEffect" .. effectId
            local leftAdd = "+"..(d1[effectId]-d0[effectId])
            if self:addValueIsPercent(effectId) then
                leftAdd = leftAdd.."%"
            end
            local rightAdd = "+"..0
            table.insert(ret.infos, {type=1, left=Localizef(ekey, {value=d0[effectId]}), leftAdd = leftAdd, right=Localizef(ekey, {value=d2[effectId]}), rightAdd = rightAdd })
        end
    end
    local ekey = "dataEquipSkill" .. self.eid
    table.insert(ret.infos, {type=2, left=Localizef(ekey, self:getSkillParams(self.elvup)), right=Localizef(ekey, self:getSkillParams(self.elvup+1))})
    return ret
end

function EquipModel:upgradeEquip(stoneId)
    local install = SData.getData("einstalls",self.eid,self.elvup+1)
    if self.level>=install.maxLv then
        return -1
    end
    self.exp = self.exp + SData.getData("property",const.ItemEquipStone, stoneId).value
    local ret = 0
    while self.level<install.maxLv do
        local nextLevel = SData.getData("elevels",self.eid,self.level+self.elvup)
        if nextLevel.exp<=self.exp then
            self.exp = self.exp-nextLevel.exp
            self.level = self.level+1
            ret = 1
        else
            break
        end
    end
    return ret
end


function EquipModel:getMaxLv()
    local level = self.elvup + 1
    local install = SData.getData("einstalls",self.eid,level)
    if install then
        return install.maxLv or 0
    else
        return 0
    end
end

function EquipModel:lvupEquip()
    local install = SData.getData("einstalls",self.eid,self.elvup+1)
    self.elvup = self.elvup+1
    for i=1, 5 do
        self.eparts[i] = 0
    end
    self.color = math.floor(self.elvup/4)+1
    return install.cvalue
end

local EquipData = class()

function EquipData:ctor(udata)
    self.udata = udata
    self.maxIdx = 0
    self.equipNum = 0
end

function EquipData:loadData(data)
    local equips = {}
    local maxIdx = 0
    local num = 0
    if data.equips then
        for eidx, e in pairs(data.equips) do
            eidx = tonumber(eidx)
            equips[eidx] = EquipModel.new(eidx, e)
            if eidx>maxIdx then
                maxIdx = eidx
            end
            if equips[eidx].hidx>0 then
                local hero = self.udata.heroData:getHero(equips[eidx].hidx)
                if hero then
                    hero:setEquip(equips[eidx])
                else
                    local equip = equips[eidx]
                    print("dump equip data", eidx, equip.hidx, equip.eid, equip.elvup, equip.level)
                end
            end
            num = num+1
        end
    end
    self.maxIdx = maxIdx
    self.equipNum = num
    self.equips = equips
end

function EquipData:makeEquip(eid)
    return EquipModel.new(0, {eid, 0,1,0,0, 0,0,0,0,0})
end

function EquipData:getEquip(idx)
    return self.equips[idx]
end

function EquipData:getHeroByEid(eid)
    local equips = self:getAllEquips()
    local equipDatas = {}
    if equips then
        for _,equip in pairs(equips) do
            if equip.eid == eid then
                table.insert(equipDatas,equip)
            end
        end
    end
    return equipDatas
end

function EquipData:getAllEquips()
    return self.equips
end

function EquipData:getHeroByEquip(equip)
    if equip and equip.hidx>0 then
        return self.udata.heroData:getHero(equip.hidx)
    end
end

function EquipData:removeEquip(idx)
    self.equips[idx] = nil
    self.equipNum = self.equipNum-1
end

function EquipData:addNewEquip(idx, eid)
    local newEquip = self:makeEquip(eid)
    newEquip.idx = idx
    if idx>self.maxIdx then
        self.maxIdx = idx
    end
    self.equips[idx] = newEquip
    self.equipNum = self.equipNum+1
end

function EquipData:buyNewEquip(eid)
    local idx = self.maxIdx+1
    self:addNewEquip(idx, eid)

    self.udata:addCmd({const.CmdEquipBuy, idx, eid})
end

function EquipData:changeEquipHero(equip, hero)
    local hidx = equip.hidx
    local hero2,equip2 = nil
    if hidx>0 then
        hero2 = self.udata.heroData:getHero(hidx)
    end
    if hero2==hero then
        return
    end
    local h1,e1,h2,e2 = 0,equip.idx,0,0
    if hero then
        equip2 = hero.equip
        h1 = hero.idx
        hero:setEquip(equip)
    end
    equip.hidx = h1
    if hero2 then
        h2 = hero2.idx
        hero2:setEquip(equip2)
    end
    if equip2 then
        e2 = equip2.idx
        equip2.hidx = h2
    end
    if hero2 then
        self.udata.heroData:setCombatData(hero2)
    end
    if hero then
        self.udata.heroData:setCombatData(hero)
    end
    self.udata:addCmd({const.CmdEquipChange,h2,e1,h1,e2})
end

function EquipData:upgradeEquip(equip, itemId, params)
    if params and params.type == "oneKey" then
        --为了后端方便,一键升阶里情况下的升级放到升阶接口里一起处理
        equip.exp = 0
        equip.level = equip.level+params.lv
        -- 日常任务装备升级
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeHeroEqLevelUp, params.lv)
        --触发活动装备等级
        GameLogic.getUserContext().activeData:finishActConditionOnce(equip.eid*10000+const.ActTypeHeroEqLevelUp, equip.level)
        GameLogic.getUserContext().activeData:finishActConditionOnce(1000*10000+const.ActTypeHeroEqLevelUp, equip.level)
    else
        if self.udata:getItem(const.ItemEquipStone, itemId)<=0 then
            return -2
        else
            local result = equip:upgradeEquip(itemId)
            if result>=0 then
                self.udata:changeItem(const.ItemEquipStone, itemId, -1)
                self.udata:addCmd({const.CmdEquipUpgrade, equip.idx, itemId, 1})
                --触发活动装备等级
                GameLogic.getUserContext().activeData:finishActConditionOnce(equip.eid*10000+const.ActTypeHeroEqLevelUp, equip.level)
                GameLogic.getUserContext().activeData:finishActConditionOnce(1000*10000+const.ActTypeHeroEqLevelUp, equip.level)
            end
            return result
        end
    end
end

function EquipData:installEquipPart(equip, pidx)
    local pid, _, needNum,needLevel = equip:getPart(pidx)
    self.udata:changeItem(const.ItemEquipPart, pid, -needNum)
    equip.eparts[pidx] = needNum
    self.udata:addCmd({const.CmdEquipInstall, equip.idx, pidx})
end

function EquipData:lvupEquip(equip, params)
    local cost = equip:lvupEquip()
    local useRes = {}
    local lv = 0
    if params and params.type == "oneKey" then
        cost = params.frag
        useRes = params.useRes
        lv = params.lv
        self.udata:changeRes(const.ResCrystal, -params.needCrystal)
    end
    self.udata:changeItem(const.ItemEquipFrag, equip.eid, -cost)
    self.udata:addCmd({const.CmdEquipLvup, equip.idx, useRes, lv})
end

function EquipData:getEquipNum()
    return self.equipNum
end

function EquipData:getEquipMax()
    return const.MaxEquipNum
end

function EquipData:sellEquip(equip)
    if equip.hidx>0 then
        self:changeEquipHero(equip, nil)
    end
    self.udata:changeResWithMax(const.ResGold, equip:getSellPrice())
    self:removeEquip(equip.idx)
    self.udata:addCmd({const.CmdEquipSell, equip.idx})
end

function EquipData:mergeEquip(eid)
    local _equip = self:makeEquip(eid)
    local _,_f1 = _equip:getFragNum()

    if self.udata:getItem(const.ItemEquipFrag, eid)>=_f1 then
        self.maxIdx = self.maxIdx+1
        self:addNewEquip(self.maxIdx, eid)
        self.udata:changeItem(const.ItemEquipFrag, eid, -_f1)
        self.udata:addCmd({const.CmdEquipMerge, self.maxIdx, eid})
    end
end

return EquipData
