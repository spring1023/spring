local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")

local ArenaData = class()

function ArenaData:ctor(udata)
    self.udata = udata
    self.atkLogData={}
    self.desLogData={}
end

function ArenaData:destroy()

end

function ArenaData:isInited()
    return self.inited and #(self.enemys)==3
end

function ArenaData:loadArenaData(data)
    self.uid = GameLogic.getUserContext().uid
    self.rank = data.nrank
    self.oldRank = data.lrank
    self.avalue = data.avalue
    self.atime = data.atime

    self.heroShowId = data.hid
    self.lastChallengeTime = data.battime
    self.lastBuyTime = data.buytime
    self.bnum = data.bcount
    self.isMyBatting = false
    self.atkEndTime = data.atktime
    self.boxOpenNum = {0,0,0}
    self.stage = self:getStage(self.rank)
    self.lockEnemys = false
    if data.players then
        self.inited = true
        self.enemys = {}
        self:loadEnemys(data.players)
    end
    self:refresBuyNum()
    self:getLogData(data)
end

function ArenaData:loadEnemys(enemys)
    --[uid,当前名次，英雄显示ID，攻击状态，攻击预计结束时间，用户名，是否是复仇对象]
    for i, enemy in ipairs(enemys) do
        self.enemys[enemy[1]] = {uid=enemy[2],hid=enemy[3],rank=enemy[4],name=enemy[5],isRevenge=(enemy[6]>0),canGetHonor=enemy[6],isBattling=(enemy[7]>0),atkEndTime=enemy[8],batid=enemy[9], combat = enemy[10]}
    end
end
function ArenaData:refreshEnemys(data)
    self.lockEnemys = false
    if data.players then
        self.enemys = {}
        self:loadEnemys(data.players)
    end
end

function ArenaData:refreshEnemysState(s1,s2,s3)
    if self.enemys then
        self.enemys[1].isBattling = (s1>0)
        self.enemys[2].isBattling = (s2>0)
        self.enemys[3].isBattling = (s3>0)
    end
end

function ArenaData:getEnemysLockState()
    return self.lockEnemys
end

function ArenaData:refresBuyNum()
    if self.lastBuyTime<=GameLogic.getToday() then
        self.bnum = 0
    end
end

function ArenaData:refreshHonor(avalue,atime)
    self.avalue = avalue
    self.atime = atime
end

function ArenaData:refreshRank(rank)
    self.rank = rank
end

--当前排名
function ArenaData:getCurrentRank()
    return self.rank
end
--当前阶位
function ArenaData:getCurrentStage()
    return self.stage
end
--是否在被攻打
function ArenaData:getMyState()
    return self.isMyBatting
end
--荣誉币信息，生产速度，上限，当前拥有，达到上限的剩余时间,复仇可获得荣誉点，下一阶位的上限
function ArenaData:getHonorInfos()
    local datas = SData.getData("arenaData")
    local stage = self.stage
    local infos={}
    infos.speed = datas[stage].honorSpeed
    infos.honorMax = datas[stage].honorMax
    infos.honorHave = self.avalue
    if infos.honorMax>infos.honorHave then
        infos.time = math.ceil((infos.honorMax-infos.honorHave)/infos.speed)
    end
    infos.canGetHonor = datas[stage].canGetHonor
    if stage>1 then
        infos.honorNextMax = datas[stage-1].honorMax
    end
    infos.lastChallengeTime = self.lastChallengeTime
    return infos
end

function ArenaData:getStage(rank)
    if not rank then
        return 0
    end
    local data =SData.getData("arenaData")
    for i,v in ipairs(data) do
        if rank>=v.minRank and (rank<=v.maxRank or v.maxRank == 0) then
            return i
        end
    end
end

function ArenaData:getStageMinRank(stage)
    local data =SData.getData("arenaData")
    if stage>#data then
        stage = #data
    end
    return data[stage].maxRank
end

function ArenaData:getMaxStage()
    return #SData.getData("arenaData")
end

function ArenaData:resetChanceData(ltime)
    self.lastChallengeTime = ltime
end

function ArenaData:getCurrentChance()
    local maxNum = self:getMaxChance()
    local st=GameLogic.getSTime()
    if self.lastChallengeTime and st>self.lastChallengeTime then
        --2个小时恢复一次
        local num = math.floor((st-self.lastChallengeTime)/(2*60*60))
        if num>maxNum then
            num=maxNum
        end
        return num
    end
    return maxNum
end

function ArenaData:getMaxChance()
    return 5
end

function ArenaData:getBuyPrice()
    local num = GameLogic.getUserContext():getVipPermission("pvcs")[2]
    local cost = SData.getData("pvxcost", const.LayoutPvc, self.bnum+1)
    return cost.gid, cost.gnum, num-self.bnum
end

function ArenaData:finishBuyChance()
    local cost = SData.getData("pvxcost", const.LayoutPvc, self.bnum+1)
    self.udata:changeRes(cost.gid, -cost.gnum)
    self.bnum = self.bnum+1
    self.lastBuyTime = GameLogic.getSTime()
    self:refresBuyNum()
end

function ArenaData:getEnemyInfo(idx)
    return self.enemys[idx]
end

function ArenaData:computeBattleResult(isWin,enemy)
    local ret = {}
    ret.rank = self.rank
    ret.changeRank = 0
    if isWin then
        ret.rank = self.rank
        ret.changeRank = 0
        if self.rank>enemy.rank then
            ret.changeRank = self.rank - enemy.rank
            ret.rank = enemy.rank
        end
        if enemy.isRevenge then
            ret.canGetHonor = enemy.canGetHonor
        end
    --不用锁定对手
    --else
        --self.lockEnemys = true
    end
    return ret
end


function ArenaData:getLogData(data)
   --uid,tid,uinfo,uhls,tinfo,thls,cid,rev,urank,trank,uprank,btime,state
   --己方id，敌方id，己方信息，己方英雄，敌方信息，敌方英雄，战报id，是否复仇过，己方排名，敌方排名，上升排名，攻打时间，攻打状态,战斗输赢，获得荣誉点
    if data.atks then
        self.atkLogData={}
        for i,v in ipairs(data.atks) do
            table.insert(self.atkLogData,{uid=v[1],tid=v[2],uinfo=v[3],uhls=v[4],tinfo=v[5],thls=v[6],cid=v[7],rev=v[8],urank=v[9],trank=v[10],uprank=v[11],btime=v[12],state=v[13],isWin=v[14],canGetHonor=v[15]})
        end
    end

    if data.defs then
        self.desLogData={}
        --测试数据
        for i,v in ipairs(data.defs) do
            table.insert(self.desLogData,{uid=v[1],tid=v[2],uinfo=v[3],uhls=v[4],tinfo=v[5],thls=v[6],cid=v[7],rev=v[8],urank=v[9],trank=v[10],uprank=v[11],btime=v[12],state=v[13],isWin=v[14],canGetHonor=v[15]})
        end
    end
end

function ArenaData:initData(callback)
    if self:isInited() then
        if callback then
            callback()
        end
        return
    end
    if not GameLogic.getUserContext().buildData:getBuild(const.ArenaBase) then
        display.pushNotice(Localize("noticeNotArenaBuild"))
        return
    end
    GameNetwork.request("pvcGetAvalue", nil, function(isSuc,data)
        if isSuc then
            self.stage = self:getStage(data.nrank)
            self:refreshHonor(data.avalue,data.atime)
            if callback then
                callback()
            end
        end
    end)
end

return ArenaData
