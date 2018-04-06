local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local WeaponData = class()

function WeaponData:ctor(udata)
    self.produceList = {}
    self.weaponLevels = {}
    self.weaponNums = {}
    self.produceTime = 0
    self.udata = udata
    self.wspace = 0
end

function WeaponData:destroy()
    self.produceList = nil
    self.weaponLevels = nil
    self.weaponNums = nil
    self.produceTime = nil
    self.udata = nil
    self.wspace = nil
end

function WeaponData:loadData(data)
    if data.wlevels then
        for _, item in ipairs(data.wlevels) do
            self.weaponLevels[item[1]] = item[2]
        end
    end
    if data.wnums then
        for _, item in ipairs(data.wnums) do
            self.weaponNums[item[1]] = item[2]
            self.wspace = self.wspace+item[2]
        end
    end
    if data.wstime then
        self.produceTime = data.wstime
    end
    if data.wplist then
        self.produceList = data.wplist
        self.wspace = self.wspace+#(self.produceList)
    end
end

function WeaponData:dload()
    local data = {wlevels={}, wnums={},  wplist={}}
    for k,v in pairs(self.weaponLevels) do
        table.insert(data.wlevels,{k,v})
    end
    for k,v in pairs(self.weaponNums) do
        table.insert(data.wnums,{k,v})
    end
    data.wstime = self.produceTime
    data.wplist = self.produceList
    return data
end

function WeaponData:isWeaponFull()
    return self.wspace>=const.MaxWeaponNum
end

function WeaponData:getProduceList()
    return self.produceList
end

function WeaponData:getProduceStartTime()
    return self.produceTime
end

function WeaponData:getWeaponNum(wid)
    return self.weaponNums[wid] or 0
end

local function sortById(a, b)
    return a[1]<b[1]
end

function WeaponData:getAllWeapons()
    local ret = {}
    for wid, num in pairs(self.weaponNums) do
        if num>0 then
            table.insert(ret, {wid, num})
        end
    end
    table.sort(ret, sortById)
    return ret
end

function WeaponData:getProduceNum()
    return #(self.produceList)
end

function WeaponData:getProduceCost(wid)
    local wlv = self:getWeaponLevel(wid)
    local winfo = SData.getData("swinfos", wid)
    local cost = SData.getData("swlevels",wid,wlv).cost
    local rmid = winfo.subitems[2]
    local rmlv = self:getWeaponLevel(rmid)
    if rmlv>0 then
        cost = math.floor(cost*(100-SData.getData("swlevels",rmid,rmlv).effect)/100)
    end
    return cost
end

function WeaponData:getAvailableWeapons()
    local ret = {}
    for i=1, 6 do
        local mid = 1000+i
        local winfo = SData.getData("swinfos", mid)
        if winfo and winfo.wtype==1 then
            local mlv = self:getWeaponLevel(mid)
            local item = {id=mid, level=mlv, name=Localize("dataWeaponName" .. mid)}
            if mlv>0 then
                item.cost = self:getProduceCost(mid)
            else
                item.unlockLevel = SData.getData("swlevels",mid,1).needLevel
            end
            table.insert(ret, item)
        end
    end
    return ret
end

function WeaponData:getWeaponLevel(wid)
    return self.weaponLevels[wid] or 0
end

function WeaponData:getNextUseTime()
    if #(self.produceList)>0 then
        return SData.getData("swinfos",self.produceList[1]).ctime
    end
    return 0
end

function WeaponData:getAllUseTime()
    local total = 0
    for _, wid in ipairs(self.produceList) do
        total = total+SData.getData("swinfos",wid).ctime
    end
    return total
end

function WeaponData:computeCostByTime(t)
    if t<=0 then
        return 0
    end
    return math.ceil(t/150)*2
end

local _weaponPropertyTypes = {
    {"propertyEffectRange",0},
    {"propertyInterval",1},
    {"propertyEffectValue",0},
    {"propertyTargetNum",0},
    {"propertyTime",1},
    {"propertySale",2},
    {"propertyAtkUp",2},
    {"propertyASpeedUp",2},
    {"propertyMSpeedUp",2},
    {"propertyHpUp",2},
    {"propertyDefUp",2}
}
local _weaponPropertyTypeMap = {[0]={[1001]=3,[1002]=3,[1003]={8,9},[1004]=7,[1005]=8,[1006]=8},[1]={1,6,4,5},[2]={7,9,10,11},[3]={8}}
local _weaponPropertyIdxMap = {[0]={[1001]=3,[1002]=3,[1003]={3,2},[1004]=1,[1005]=2,[1006]=2},[1]={1,6,4,5},[2]={1,3,4,5},[3]={2}}

function WeaponData:getWeaponAllDatasByIdx(idx)
    local wid = 1000+idx
    local winfo = SData.getData("swinfos", wid)
    local ret = {desc=Localize("dataWeaponInfo" .. wid), subnames={0,0,0,0}, subitems={0,0,0,0}, sublevels={0,0,0,0}, properties={0,0,0,0,0}, wtype=winfo.wtype}
    ret.subitems[0] = wid
    ret.sublevels[0] = self:getWeaponLevel(wid)
    ret.subnames[0] = Localize("dataWeaponName" .. wid)
    local wdata = nil
    if ret.sublevels[0]>0 then
        wdata = SData.getData("swlevels",wid,ret.sublevels[0])
    end
    local ptypes = {}
    local pvalue = {0,0,0,0,0}
    local ptype = _weaponPropertyTypeMap[0][wid]
    local pidx = _weaponPropertyIdxMap[0][wid]
    if type(pidx)=="table" then
        for i, idx in ipairs(pidx) do
            ptypes[idx] = _weaponPropertyTypes[ptype[i]]
            if wdata then
                pvalue[idx] = wdata.effect[i]
            end
        end
    else
        ptypes[pidx] = _weaponPropertyTypes[ptype]
        if wdata then
            pvalue[pidx] = wdata.effect
        end
    end
    if idx<=3 then
        pvalue[6] = 0
        if idx<3 then
            ptypes[2] = _weaponPropertyTypes[2]
        end
        if wdata then
            pvalue[1] = winfo.range
            pvalue[4] = winfo.num
            pvalue[5] = winfo.time
            if idx<3 then
                pvalue[2] = 0.5
            end
        end
    end
    for i, swid in ipairs(winfo.subitems) do
        ret.subitems[i] = swid
        ret.sublevels[i] = self:getWeaponLevel(swid)
        local wtype = winfo.wtype
        if wtype==3 and i>1 then
            wtype = 2
        end
        ret.subnames[i] = Localize("dataWeaponName" .. wtype .. "_" .. i)
        ptype = _weaponPropertyTypeMap[wtype][i]
        pidx = _weaponPropertyIdxMap[wtype][i]
        ptypes[pidx] = _weaponPropertyTypes[ptype]
        if ret.sublevels[i]>0 then
            local swdata = SData.getData("swlevels",swid,ret.sublevels[i])
            pvalue[pidx] = swdata.effect
        end
    end
    for idx, value in ipairs(pvalue) do
        ret.properties[idx] = {Localize(ptypes[idx][1]), ptypes[idx][2], value}
    end
    return ret
end

--获取进攻武器数值
function WeaponData:getBattleWeaponData(wid)
    local winfo = SData.getData("swinfos", wid)
    local wdata = SData.getData("swlevels",wid,self:getWeaponLevel(wid))
    local pvalue = {0,0.5,0,0,0}
    local pidx = _weaponPropertyIdxMap[0][wid]
    if type(pidx)=="table" then
        for i, idx in ipairs(pidx) do
            if wdata then
                pvalue[idx] = wdata.effect[i]
            end
        end
    else
        if wdata then
            pvalue[pidx] = wdata.effect
        end
    end
    pvalue[1] = winfo.range
    pvalue[4] = winfo.num
    pvalue[5] = winfo.time
    for i, swid in ipairs(winfo.subitems) do
        local swlv = self:getWeaponLevel(swid)
        pidx = _weaponPropertyIdxMap[1][i]
        if swlv>0 and pidx<6 then
            local swdata = SData.getData("swlevels",swid,swlv)
            pvalue[pidx] = swdata.effect
        end
    end
    return pvalue
end

--获取被动武器数值
function WeaponData:getBoostWeaponData()
    local wboosts = {}
    for wid=1004, 1006 do
        local winfo = SData.getData("swinfos", wid)
        local wlevel = self:getWeaponLevel(wid)
        if wlevel>0 then
            local wdata = SData.getData("swlevels",wid,self:getWeaponLevel(wid))
            local pvalue = {0,0,0,0,0}
            local pidx = _weaponPropertyIdxMap[0][wid]
            if type(pidx)=="table" then
                for i, idx in ipairs(pidx) do
                    if wdata then
                        pvalue[idx] = wdata.effect[i]
                    end
                end
            else
                if wdata then
                    pvalue[pidx] = wdata.effect
                end
            end
            for i, swid in ipairs(winfo.subitems) do
                local wtype = winfo.wtype
                if wtype==3 and i>1 then
                    wtype = 2
                end
                local ptype = _weaponPropertyTypeMap[wtype][i]
                local swlv = self:getWeaponLevel(swid)
                pidx = _weaponPropertyIdxMap[wtype][i]
                if swlv>0 then
                    local swdata = SData.getData("swlevels",swid,swlv)
                    pvalue[pidx] = swdata.effect
                end
            end
            if wid==1004 then
                wboosts[100] = pvalue
                wboosts[200] = pvalue
                wboosts[700] = pvalue
            elseif wid==1005 then
                wboosts[300] = pvalue
                wboosts[400] = pvalue
            else
                wboosts[500] = pvalue
                wboosts[600] = pvalue
            end
        end
    end
    return wboosts
end

function WeaponData:getWeaponProperty(wtype, subIdx, wid, wlevel)
    local data = SData.getData("swlevels",wid,wlevel)
    if not data then
        return
    end
    local ret = {properties={}, cost=data.cvalue, needLevel=data.needLevel, level=wlevel, id=wid}
    if wtype==3 and subIdx>1 then
        wtype = 2
    end
    local pidx = _weaponPropertyIdxMap[wtype][subIdx]
    if type(pidx)=="table" then
        for i, idx in ipairs(pidx) do
            ret.properties[idx] = data.effect[i]
        end
    else
        ret.properties[pidx] = data.effect
    end

    if wtype==0 and wlevel==1 and subIdx<=1003 then
        local winfo = SData.getData("swinfos", wid)
        ret.properties[1] = winfo.range
        ret.properties[4] = winfo.num
        ret.properties[5] = winfo.time
        if subIdx<=1002 then
            ret.properties[2] = 0.5
        end
    end
    return ret
end

function WeaponData:upgradeWeapon(wid, cost)
    local level=self.weaponLevels[wid] or 0
    if level<self:getWeaponMaxLevel(wid) then
        self.weaponLevels[wid] = level+1
        self.udata:changeRes(const.ResMagic, -cost)
        self.udata:addCmd({const.CmdUpgradeWeapon, wid})
    end
end

function WeaponData:produceWeapon(wid, stime)
    local cost = self:getProduceCost(wid)
    if cost>self.udata:getRes(const.ResGold) then
        return false
    end
    if #(self.produceList)==0 then
        self.produceTime = stime
    end
    table.insert(self.produceList, wid)
    self.wspace = self.wspace+1
    self.udata:changeRes(const.ResGold, -cost)
    self.udata:addCmd({const.CmdProduceWeapon, wid, stime})
    return true
end

function WeaponData:cancelProduce(widx, wid)
    if self.produceList[widx]==wid then
        table.remove(self.produceList, widx)
        self.wspace = self.wspace-1
        local cost = self:getProduceCost(wid)
        self.udata:changeResWithMax(const.ResGold, math.floor(cost/2))
        self.udata:addCmd({const.CmdCancelWeapon, widx})
        return true
    end
    return false
end

function WeaponData:updateProduces(stime)
    while #(self.produceList)>0 do
        local nu = self:getNextUseTime()
        if stime>=self.produceTime+nu then
            self.produceTime = self.produceTime+nu
            local wid = table.remove(self.produceList, 1)
            self.weaponNums[wid] = (self.weaponNums[wid] or 0)+1
            self.udata:addCmd({const.CmdFinishWeapon, stime})
        else
            return
        end
    end
end

function WeaponData:finishProduceAtOnce(stime, cost)
    local atime = self:getAllUseTime()+self.produceTime-stime
    self.produceTime = self.produceTime-atime
    self.udata:changeRes(const.ResCrystal, -cost)
    GameLogic.statCrystalCost("武器制造立即完成消耗",const.ResCrystal, -cost)
    self.udata:addCmd({const.CmdAccWeapon, stime})
    self:updateProduces(stime)
end

function WeaponData:costWeapons(weapons)
    for _, weapon in ipairs(weapons) do
        self.wspace = self.wspace-weapon[2]
        self.weaponNums[weapon[1]] = (self.weaponNums[weapon[1]] or 0)-weapon[2]
        if self.weaponNums[weapon[1]]<0 then
            print("error! the weapon number cannot be less than zero!",weapon[1])
            self.wspace = self.wspace-self.weaponNums[weapon[1]]
            self.weaponNums[weapon[1]] = 0
        end
    end
end

function WeaponData:getWeaponMaxLevel(wid)
    local data = SData.getData("swlevels",wid)
    return KTLen(data)
end

return WeaponData
