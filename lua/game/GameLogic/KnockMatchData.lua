local SData = GMethod.loadScript("data.StaticData")

local KnockMatchData = {
    num = 0,
    zoroTime = nil,
    startOutWeekNum = 1,
    lastUpdateDataTime = 0,
    dinfo = {
        dFlag = 1,      --分组赛报名标志, 1.未报名 2.已报名但无对手 3.有对手
        dEnemy = {},    --对手信息
        dScore = 0,     --积分
        dRank = 0,      --排名
        dStage = 1,     --段位
        haveAtk = false, --今日是否攻击
        nReport = {},   --今日战报
        yReport = {},   --昨日战报
        rwds = {},      --奖励
    },
    oinfo = {
        oFlag = 0,      --淘汰赛报名标志, 1.未进入淘汰赛 2.有对手 3.已被淘汰
        oEnemy = {},    --对手信息
        players = {},   --所有参赛选手
        mReport = {},   --自己的战报
        eReport = {},   --对手的战报
        oScore = 0,     --积分
        fMan = {},      --名人堂
        oRank = 1,      --排名
        groupId = 0,      --小组Id
        noEnemy = true,   --是否轮空
        haveAtk = false, --今日是否攻击
        selectGroupId = nil, --当前所在人头界面id
    }
}
--1：分组赛拉取信息；2、分组赛拉取所有对手信息; 3、 分组赛获取今日战报;4、分组赛获取昨日战报； 10、淘汰赛拉取所有信息, 11、淘汰赛战报
local nextRefreshTime = {[1] = 0, [2] = 0,[3] = 0, [4] = 0, [10] = 0, [11] = 0}
local DEFAULT_SCORE = 3000
local ONE_DAY = 86400
local self = KnockMatchData

function KnockMatchData:initData(params)
    -- self.time = GameLogic.getSTime()
    local function callback()
        for k, v in pairs(nextRefreshTime) do
            self:updateNeedRefreshData(k, true)
        end
    end
    GameEvent.registerEvent(GameEvent.openKnockGetInfo, self, callback)

    local ucontext = GameLogic.getUserContext()
    self.zoroTime = ucontext.MatchInitTime
    local KnockMainDialog = GMethod.loadScript("game.Dialog.KnockMainDialog")
    display.showDialog(KnockMainDialog.new())
    -- self:initDivideDataWithServer()
end

local function getdEnemy(uid, flag)
    local _dEnemy = self.dinfo.dEnemy
    for i=1, 5 do
        local _uid =  _dEnemy[i].uid
        if _uid and _uid == uid then
            return _dEnemy[i]
        end
    end
    for i=1, 5 do
        local _uid = _dEnemy[i].uid
        if not _uid then
            return _dEnemy[i]
        end
    end
end

--服务端同步数据
function KnockMatchData:initDivideDataWithServer(data)
    self:initRewardInfo(data.rwds)
    self.dinfo.dStage = 0
    self.dinfo.dScore = 0
    self.dinfo.dFlag = data.zcode
    local _dEnemy = self.dinfo.dEnemy
    if self.dinfo.dFlag == 3 then
        --1、休战期，清空数据；2、判断是不是同步过一次数据，然后跨状态在线
        if self:isDivideStart() == 3 or self:checkOnLineWithTwoState() then
            for i=1, 5 do
                _dEnemy[i] = {}
            end
        end
        for i=1, 5 do
            if GameLogic.isEmptyTable(_dEnemy[i]) then
                _dEnemy[i] = {}
                _dEnemy[i].atk = {}
                _dEnemy[i].def = {}
                _dEnemy[i].def.destroy = 0
                _dEnemy[i].def.reborn = 0
                _dEnemy[i].def.star = 0
            end
        end
        if not GameLogic.isEmptyTable(data.players) then
            for k, v in pairs(data.players) do
                local tid = v[4]
                local context = GameLogic.getUserContext()
                local uid = context.uid
                if tid ~= uid then
                    local _info = getdEnemy(tid)
                    _info.uid = tid
                    _info.pos = v[5]
                    _info.def.uid = v[1]
                    _info.def.score = v[3]
                    _info.def.tid = v[4]
                    _info.def.pos = v[5]
                    _info.def.star = v[6]
                    _info.def.reborn = v[2]
                    _info.def.destroy = v[7]
                end
            end
        end
        self:resetReborn()
        self.dinfo.dScore = data.score or DEFAULT_SCORE
        self.dinfo.dStage = 1
    end
    self.dinfo.dRank = data.rank
    if self.dinfo.dRank then
        self.dinfo.dRank = self.dinfo.dRank + 1
    end
    self.oinfo.oFlag = data.kcode
    self.oinfo.groupId = data.groupId
    self.oinfo.tid = data.tid
    self.oinfo.oRank = data.krank
    if self.oinfo.oFlag == 2 and (not GameLogic.isEmptyTable(data.player)) then
        local _data = data.player[1]
        local _oEnemy = self.oinfo.oEnemy
        _oEnemy.name = _data[1]
        _oEnemy.lv = checknumber(_data[2])
        _oEnemy.head = checknumber(_data[3])
        _oEnemy.score = checknumber(_data[4])
        _oEnemy.uid= checknumber(_data[5])
        _oEnemy.star = 0
        _oEnemy.destroy = 0
        _oEnemy.reborn = 0
    end
    if GameLogic.isEmptyTable(self.oinfo.oEnemy) then
        self.oinfo.noEnemy = true
    else
        self.oinfo.noEnemy = false
    end
    self:updateDataTime()
end

function KnockMatchData:getSortEnemy()
    local dEnemy = {}
    for k, v in pairs(self.dinfo.dEnemy) do
        -- local
        if not GameLogic.isEmptyTable(v) then
            table.insert(dEnemy, v)
        end
    end
    table.sort(dEnemy, function(a, b)
        return a.pos < b.pos
    end)
end

--判断是否需要重新获取数据
function KnockMatchData:checkNeedRefreshData(idx)
    local flag = true
    local sTime = GameLogic.getSTime()
    flag = (sTime >= nextRefreshTime[idx]+180)
    if flag then
        nextRefreshTime[idx] = sTime
    end
    return flag
end

function KnockMatchData:updateNeedRefreshData(idx, flag)
    local sTime = GameLogic.getSTime()
    if flag then
        nextRefreshTime[idx] = sTime - 180
    else
        nextRefreshTime[idx] = sTime + 180
    end
end

--最后一次同步数据时间
function KnockMatchData:updateDataTime()
    self.lastUpdateDataTime = GameLogic.getSTime()
end

--判断是不是同步过一次数据，然后跨状态在线
function KnockMatchData:checkOnLineWithTwoState()
    local week = self:getWeek(self.lastUpdateDataTime)
    local _week = self:getWeek()
    if week < _week then
        return true
    end
end

--flag:1、未开赛 2、对战 3、休战
function KnockMatchData:isDivideStart()
    local flag = 1
    local startTime = self:getTimeConfigs()
    local nowTime = GameLogic.getSTime()
    local _startTime = GameLogic.getUnionBattleTime()[1]
    local _endTime = GameLogic.getUnionBattleTime()[2]
    local leftTime = nowTime - startTime
    if leftTime >= 0 then
        if (nowTime>=_startTime) and (nowTime<=_endTime) then
            flag = 3
        else
            flag = 2
        end
    else
        leftTime = -leftTime
    end
    return flag, leftTime
end

--报名
function KnockMatchData:joindMatch()
    self.dinfo.dFlag = 2
end

--开战
function KnockMatchData:fightEnemy()

end

--获取所有对手信息
-- uid,score,oder,name,head,combat] 成员Id，积分，位置号，昵称，头像，战力
function KnockMatchData:setdEnemys(data)
    local dEnemy = self.dinfo.dEnemy
    local players = data.players
    local reps = data.reps
    for k, v in pairs(players) do
        local _uid = v[1]
        local uid = GameLogic.getUserContext().uid
        if _uid ~= uid then          --排除自己
            local _dEnemy = getdEnemy(_uid)
            _dEnemy.uid = v[1]
            _dEnemy.score = v[2]
            _dEnemy.pos = v[3]
            _dEnemy.name = v[4]
            _dEnemy.head = v[5]
            _dEnemy.combat = v[6]
        end
    end
-- 对对手的进度记录信息，格式 [uid,bagain,score,tid,oder,star,destroy] 攻方Id,重生值，攻打积分，守方Id，位置号
    if not GameLogic.isEmptyTable(reps) then
        for k, v in pairs(reps) do
            local _uid = v[1]
            local tid = v[4]
            local uid = GameLogic.getUserContext().uid

            local _dEnemy
            if _uid == uid then   --自己是攻方
                _dEnemy = getdEnemy(tid)
                _dEnemy.def.uid = v[1]
                _dEnemy.def.reborn = v[2]
                _dEnemy.def.score = v[3]
                _dEnemy.def.tid = v[4]
                _dEnemy.def.pos = v[5]
                _dEnemy.def.star = v[6]
                _dEnemy.def.destroy = v[7]

            else --自己是守方
                _dEnemy = getdEnemy(_uid, true)
                _dEnemy.atk.uid = v[1]
                _dEnemy.atk.reborn = v[2]
                _dEnemy.atk.score = v[3]
                _dEnemy.atk.tid = v[4]
                _dEnemy.atk.pos = v[5]
                _dEnemy.atk.star = v[6]
                _dEnemy.atk.destroy = v[7]
            end
        end
    end
    self:resetReborn()
end

function KnockMatchData:resetReborn()
    local dEnemy = self.dinfo.dEnemy
    local flag = true
    local minReborn = 3
    local maxReborn = 0
    for k, v in pairs(dEnemy) do
        if v.uid then
            if v.def.reborn > maxReborn then
                maxReborn = v.def.reborn
            end
            if v.def.reborn < minReborn then
                minReborn = v.def.reborn
            end
            if v.def.destroy < 100 then
                flag = false
            end
        end
    end
    if (minReborn == maxReborn) then
        if flag and (not self:reachMaxReborn(minReborn))then
            for k, v in pairs(dEnemy) do
                if v.uid then
                    v.def.reborn = minReborn+1
                    v.def.destroy = 0
                    v.def.star = 0
                end
            end
        end
    else
        for k, v in pairs(dEnemy) do
            if v.uid and (v.def.reborn < maxReborn) then
                v.def.reborn = maxReborn
                v.def.destroy = 0
                v.def.star = 0
            end
        end
    end
end

function KnockMatchData:reachMaxReborn(reborn)
    if reborn >= const.KnockDivideMaxReborn then
        return true
    end
end


function KnockMatchData:getdEnemys()
    return self:getSortdEnemys()
end

function KnockMatchData:getSortdEnemys()
    local dEnemy = self.dinfo.dEnemy
    local _dEnemy = {}
    for i=1, 5 do
        if dEnemy[i].uid and dEnemy[i].pos then
            table.insert(_dEnemy, dEnemy[i])
        end
    end
    table.sort(_dEnemy, function(a, b)
        return a.pos < b.pos
    end)
    return _dEnemy
end

local dEnemyAfterBattle = {1, 2, 3, 4, 5}
local dEnemyAfterBattleInfo = {}
function KnockMatchData:getdEnemysAfterBattle(idx)
    if not idx then
        dEnemyAfterBattleInfo = self:getSortdEnemys()
        dEnemyAfterBattle = {1, 2, 3, 4, 5}
    end
    if GameLogic.isEmptyTable(dEnemyAfterBattleInfo) then
        dEnemyAfterBattleInfo = self:getSortdEnemys()
    end
    if idx then
        dEnemyAfterBattle[idx] = 3
        dEnemyAfterBattle[3] = idx
        for i=2, 1, -1 do
            local temp = idx - (3-i)
            temp = (temp>0) and temp or (temp+5)
            dEnemyAfterBattle[i] = temp
        end
        for i=4, 5 do
            local temp = idx + (i-3)
            temp = (temp<=5) and temp or (temp-5)
            dEnemyAfterBattle[i] = temp
        end
    end
    local _dEnemy = {}
    for i=1, 5 do
        _dEnemy[i] = dEnemyAfterBattleInfo[dEnemyAfterBattle[i]]

    end
    dEnemyAfterBattleInfo = _dEnemy
    return dEnemyAfterBattleInfo
end

function KnockMatchData:getdEnemyByIdx(idx)
    return self.dinfo.dEnemy[idx]
end

function KnockMatchData:getdEnemyByUid(uid)
    local dEnemy = self.dinfo.dEnemy
    for i=1, 5 do
        if dEnemy[i].uid and (dEnemy[i].uid == uid) then
            return dEnemy[i]
        end
    end
end

function KnockMatchData:getdEnemyByPos(pos)
    local dEnemy = self.dinfo.dEnemy
    for i=1, 5 do
        if dEnemy[i].pos and (dEnemy[i].pos == pos) then
            return dEnemy[i]
        end
    end
end

--获取单个对手信息
function KnockMatchData:getdEnemyById(tid)
    local function callback(isSuc, data)
        -- self.dinfo = data.binfo
    end
    GameNetwork.request("beginPvzBattle", {tid = tid}, callback)
end

-- @brief 添加徽章图片
function KnockMatchData:changeStageIcon(back, lv)
    if not lv or (lv > 13) then
        lv = 1
    end
    local path = "images/pvz/"
    local name = {"imgPvzBronze1", "imgPvzBronze2", "imgPvzBronze3",
                "impPvzSilver1", "impPvzSilver2", "impPvzSilver3",
                "imgPvzGold1", "imgPvzGold2", "imgPvzGold3",
                "imgPvzDiamond1", "imgPvzDiamond2", "imgPvzDiamond3",
                "imgPvzEmperor"}
    path = path..name[lv]..".png"
    back:removeAllChildren(true)
    local size
    if type(back) == "table" then
        size = back.size
    else
        size = {back:getContentSize().width, back:getContentSize().height}
    end
    if cc.FileUtils:getInstance():isFileExist(path) then
        local sprite = ui.sprite(path, size)
        display.adapt(sprite, size[1]/2, size[2]/2, GConst.Anchor.Center)
        back:addChild(sprite)
    else
        local node = KnockMatchData:newImageStatusStage(lv)
        display.adapt(node, size[1]/2, size[2]/2, GConst.Anchor.Center)
        node:setScale(size[1]/214)
        back:addChild(node)
    end
end

function KnockMatchData:newImageStatusStage(blv)
    local node = ui.node({214, 214})
    local stage = 1
    local path = "images/pvz/"
    local levels = {[1]={1,2,3}, [2]={4,5,6}, [3]={7,8,9}, [4]={10,11,12}}
    local bgPvz = {[1]="imgPvzBronze.png", [2]="imgPvzSilver.png", [3]="imgPvzGold.png", [4]="imgPvzDiamondB.png"}
    local arrOff = 21
    local sprNumIcon = {[1] = "imgPvz1.png", [2] = "imgPvz2.png"}
    for k,v in ipairs(levels) do
        for _, _v in ipairs(v) do
            if _v == blv then
                stage = k
                break
            end
        end
    end
    local idx = (blv%3 == 0) and 3 or (blv%3)
    --添加青铜、白银、黄金、白金的Icon
    local newBgPvz = path .. bgPvz[stage]
    local newSprBgPvz = ui.sprite(newBgPvz)
    display.adapt(newSprBgPvz,107,107,GConst.Anchor.Center)
    node:addChild(newSprBgPvz)
    --确定杠的颜色(白色或者黄色)用1和2作区分
    local sprIcon
    if 1 < stage and stage < 4 then
        sprIcon = path .. sprNumIcon[1]
    else
        sprIcon = path .. sprNumIcon[2]
    end
    for i=1, idx do
        local stageIcon = ui.sprite(sprIcon)
        display.adapt(stageIcon, arrOff * (i-1) + 107 - (idx-1)*arrOff/2, 50, GConst.Anchor.Center)
        node:addChild(stageIcon)
    end
    return node
end
--积分换算成段位
function KnockMatchData:getStageByScore(score)
    local stage = 1
    local name = "1001"
    local data = SData.getData("KnockDivideStage")
    local len = #data
    for k, v in pairs(data) do
        if v.min <= score and v.max >= score then
            if v.stage > stage then
                stage = v.stage
                name = k
            end
        end
    end
    name = Localize("labKnockStage"..name)
    return stage, name
end

function KnockMatchData:updatedInfoWithBattleEnd(data)
    local dinfo = self.dinfo
    dinfo.dRank = data.rank
    dinfo.score = data.score
end

--战绩查询
function KnockMatchData:getAchievement()

end

--更新战报
function KnockMatchData:updateReport(needUpdate, data, type)
    if not needUpdate then
        return
    end
    if type == 1 then
        self.dinfo.nReport = {}
    elseif type == 2 then
        self.dinfo.yReport = {}
    end
    for k, v in pairs(data.reps) do
        if type==1 then
            table.insert(self.dinfo.nReport, v)
        elseif type==2 then
            table.insert(self.dinfo.yReport, v)
        end
    end
    if not GameLogic.isEmptyTable(self.dinfo.nReport) then
        table.sort(self.dinfo.nReport, function(a, b)
            return a[14] > b[14]
        end)
    end
    if not GameLogic.isEmptyTable(self.dinfo.yReport) then
        table.sort(self.dinfo.yReport, function(a, b)
            return a[14] > b[14]
        end)
    end
end

--战报查看
function KnockMatchData:getReport()
    local report = {nReport = {}, yReport = {}}
    local len = #self.dinfo.nReport
    for i=len, 1, -1 do
        table.insert(report.nReport, self.dinfo.nReport[i])
    end
    len = #self.dinfo.yReport
    for i=len, 1, -1 do
        table.insert(report.yReport, self.dinfo.yReport[i])
    end
    return report
end

--淘汰赛战报
-- uid,bagain,score,tid,oder,uheros,theros,uinfos,tinfos,star,destroy,rid]
function KnockMatchData:updateOutReport(needUpdate, data, type)
    if not needUpdate then
        return
    end
    if type == 1 then
        self.oinfo.mReport = {}
    elseif type == 2 then
        self.oinfo.eReport = {}
    end
    for k, v in pairs(data.reps) do
        local info = {}
        info.uid = v[1]
        info.reborn = v[2]
        info.score = v[3]
        info.tid = v[4]
        info.pos = v[5]
        info.uheros = json.decode(v[6])
        info.theros = json.decode(v[7])
        info.uinfo = json.decode(v[8])
        info.tinfo = json.decode(v[9])
        info.star = v[10]
        info.destroy = v[11]
        info.rid = v[12]
        info.gidx = v[13]
        info.time = v[14]
        if type == 1 then
            table.insert(self.oinfo.mReport, info)
        elseif type == 2 then
            table.insert(self.oinfo.eReport, info)
        end
    end
    if not GameLogic.isEmptyTable(self.oinfo.mReport) then
        table.sort(self.oinfo.mReport, function(a, b)
            return a.time > b.time
        end)
    end
    if not GameLogic.isEmptyTable(self.oinfo.eReport) then
        table.sort(self.oinfo.eReport, function(a, b)
            return a.time > b.time
        end)
    end
end

function KnockMatchData:getOutReport(type)
    if type == 1 then
        return self.oinfo.mReport
    elseif type == 2 then
        return self.oinfo.eReport
    end

end

function KnockMatchData:updateSelectGroupId(id)
    self.selectGroupId = id
end

function KnockMatchData:initRewardInfo(rwds)
    self.dinfo.rwds = {}
    local idx = 1
    for k, v in pairs(rwds) do
        v.idx = idx
        table.insert(self.dinfo.rwds, v)
        idx = idx + 1
    end
end

function KnockMatchData:getRewardByIdx(idx)
    for k, v in pairs(self.dinfo.rwds) do
        if v.idx == idx then
            return v
        end
    end
end
function KnockMatchData:getdRewardInfo()
    local rwds = {}
    for k, v in pairs(self.dinfo.rwds) do
        local flag = v[8]
        local gnum = v[9]
        local sid = checknumber(v[3])
        local week = self:getMatchWeek()
        if (week - sid <= 2) then
            table.insert(rwds, v)
        end
    end
    table.sort(rwds, function(a, b)
        local flag = false
        if a[8] == b[8] then
            if a[7] > b[7] then
                flag = true
            end
        else
            if a[8] < b[8] then
                flag = true
            end
        end
        return flag
    end)
    return rwds
end

function KnockMatchData:canGetDivideReward()
    if GameLogic.useTalentMatch then
        return false
    end
    local rwds = self:getdRewardInfo()
    local flag = false
    for k, v in pairs(rwds) do
        if v[8] == 0 then
            flag = true
        end
    end
    return flag
end

--根据积分获取数据表中的奖励
function KnockMatchData:getdRewardByScore(score)
    local data = clone(SData.getData("KnockDivideStage"))
    local rwds = {}
    for k, v in pairs(data) do
        if v.min <= score and score <= v.max then
            rwds = v.rewards
        end
    end
    return rwds
end

function KnockMatchData:getAlldReward()
    local data = clone(SData.getData("KnockDivideStage"))
    -- dump(data)
    local rwds = {}
    for k, v in pairs(data) do
        table.insert(rwds, v)
    end
    table.sort(rwds, function(a, b)
        return a.stage < b.stage
    end)
    return rwds
end

function KnockMatchData:getOutRewardConfig()
    local data = clone(SData.getData("KnockOutReward"))
    local rwds = {}
    for k, v in pairs(data) do
        v.rank = k
        table.insert(rwds, v)
    end
    table.sort(rwds, function(a, b)
        return a.rank < b.rank
    end)
    return rwds
end

--领取奖励
function KnockMatchData:doReward()
    local rwds = self:getdRewardInfo()
    if GameLogic.isEmptyTable(rwds) then
        GameEvent.sendEvent(GameEvent.showKnockTip)
    end
end

--获取开赛时间
function KnockMatchData:getTimeConfigs()
    local ucontext = GameLogic.getUserContext()
    local startTime = self.zoroTime or ucontext.MatchInitTime
    local rollTime = const.KnockRollTime
    local roundTime = const.KnockRoundTime
    if GameLogic.useTalentMatch then
        local buff = ucontext.activeData:getBuffInfo(const.ActTypeBuffKnockMatch)
        if buff[4] > 0 then
            return buff[2], rollTime, roundTime
        end
    end

    return startTime, rollTime, roundTime
end

--测试用
function KnockMatchData:getUnionBattleTime()
    local startTime, endTime = GameLogic.getUnionBattleTime()
    startTime = self.time + 10
    endTime = self.time + 20
    return {startTime, endTime}
end

--小组赛赛季结束剩余时间
function KnockMatchData:getDivideLeftTime(time)
    local startTime, rollTime = KnockMatchData:getTimeConfigs()
    local nowTime = time or GameLogic.getSTime()

    if GameLogic.useTalentMatch then
        return startTime + rollTime * ONE_DAY - nowTime
    end
    local wk = self:getMatchWeek(nowTime)
    local disTime = startTime + wk*(rollTime*ONE_DAY)- nowTime
    return disTime
end

--小组赛指定赛季结束时间
function KnockMatchData:getDivideEndTime(sid)
    local _sid = sid or (self:getMatchWeek()-1)
    local startTime, rollTime = KnockMatchData:getTimeConfigs()
    if GameLogic.useTalentMatch then
        _sid = 1
    end

    local endTime = startTime + _sid*(rollTime*ONE_DAY) -10
    return endTime
end

--淘汰赛开赛时间
function KnockMatchData:getOutStartTime()
    local startTime, rollTime = self:getTimeConfigs()
    startTime = startTime + rollTime*ONE_DAY
    return startTime
end

--获取赛季
function KnockMatchData:getMatchWeek(time)
    local nowTime = time or GameLogic.getSTime()
    local startTime, rollTime = self:getTimeConfigs()

    local week = math.floor((nowTime - startTime)/(rollTime*ONE_DAY)) + 1
    if GameLogic.useTalentMatch then
        local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffKnockMatch)
        if buffInfo[4]~=0 then
            week=buffInfo[4]
        end
    end
    return week
end

function KnockMatchData:getWeek(time)
    local _time = time or GameLogic.getSTime()
    local startTime, rollTime = self:getTimeConfigs()
    local week = math.floor( ((_time-startTime)%(ONE_DAY*rollTime))/ONE_DAY )+1
    local arr = {1, 2, 3, 4, 5, 6, 0}
    return arr[week]
end

--获取当前轮数
function KnockMatchData:getMatchNumber()
    local num = self:getWeek()
    num = (num==0) and 7 or num
    return num
end

--type:1、今日；2、昨日
function KnockMatchData:haveDivideAtkReport(type)
    local report = self:getReport()
    local _report
    if type == 1 then
        _report = report.nReport
    elseif type == 2 then
        _report = report.yReport
    end
    return (not GameLogic.isEmptyTable(_report))
end

function KnockMatchData:haveOutAtkReport()
    local report = self.oinfo.mReport
    return (not GameLogic.isEmptyTable(report))
end

-- 红点提示：
-- 1、小组赛可参赛但是未报名
-- 2、小组赛有段位奖励未领取
-- 3、小组赛有对手，但是没有进攻日志或者今日没打；淘汰赛有对手，但是没有进攻日志或者今日没打
function KnockMatchData:showRedTip()
    local flag = false
    local rwds = self:getdRewardInfo()
    local ucontext = GameLogic.getUserContext()
    if self:checkCanJoinDivide() then  --可参赛但是未报名
        if self.dinfo.dFlag == 1 then
            if (not ucontext.gRank) or (ucontext.gRank==0) then
                flag = true
            end
        end
    elseif not GameLogic.isEmptyTable(rwds) then   --有段位奖励未领取
        flag = true
    elseif ( ((self.dinfo.dFlag == 3) and (not self:haveDivideAtkReport(1) or (not self.dinfo.haveAtk))) or ((self.oinfo.oFlag == 2) and (not self:haveOutAtkReport() or (not self.oinfo.haveAtk) )) )   then  --报名成功，当天一场未打，用进攻战报来判断
        flag = true
    end
    return flag
end

function KnockMatchData:getDivideReborn()
    local _dEnemy = self.dinfo.dEnemy
    local reborn = 10
    for k, v in pairs(_dEnemy) do
        if v.def.reborn < reborn then
            reborn = v.def.reborn
        end
    end
    if reborn > 2 then
        reborn = 2
    end
    return reborn
end

function KnockMatchData:getOutReborn()

end

function KnockMatchData:getRebornBuff(reborn, type)
    local hpPct = 0
    local atkPct = 0
    if type == 3 then
        -- 试玩没有加成
    else
        local data = SData.getData("KnockRebornAddData")
        local _data = data[type][reborn]
        for k, v in pairs(_data) do
            if v[1] == 1 then
                hpPct = v[2]/100
            elseif v[1] == 2 then
                atkPct = v[2]/100
            end
        end
    end
    return hpPct, atkPct
end

function KnockMatchData:getRebornAddScore(reborn, score)
    if (not reborn) or (not score) then
        return
    end
    local num = {0, 400, 320, 240, 160, 80}
    local rate = {1, 0.8, 0.6, 0.4, 0.2}
    local ans = 0
    for i=1, reborn+1 do
        local add
        if i > 5 then
            add = 80
        else
            add = num[i]
        end
        ans = add + ans
    end
    local _rate
    if reborn >= 5 then
        _rate = 0.2
    else
        _rate = rate[reborn+1]
    end
    ans = ans + score*_rate
    return math.floor(ans)
end

function KnockMatchData:checkInEight()
    local flag = false
    local week = self:getWeek()
    week = (week > 0) and week or 7
    if week >= 5 then
        flag = true
    end
    return flag
end

function KnockMatchData:getDinfo()
    return self.dinfo
end

function KnockMatchData:getOinfo()
    return self.oinfo
end

function KnockMatchData:resetInfoAfterBattle(params)
    if params.type == 0 then
        self:resetDivideInfoAfterBattle(params)
    elseif params.type == 1 then
        self:resetOutInfoAfterBattle(params)
    end
end

function KnockMatchData:resetDivideInfoAfterBattle(params)
    self.dinfo.dScore = params.score
    self.dinfo.dRank = params.rank
    if self.dinfo.dRank then
        self.dinfo.dRank = self.dinfo.dRank + 1
    end
    self.dinfo.haveAtk = true
end

function KnockMatchData:resetOutInfoAfterBattle(params)
    self.oinfo.oScore = params.score
    self.oinfo.oEnemy.star = params.star
    self.oinfo.oEnemy.destroy = params.destroy
    self.oinfo.oEnemy.reborn = params.reborn
    self.oinfo.haveAtk = true
end

--检测是否能参加小组赛:1、主城等级大于等于5；2、小组赛开赛
function KnockMatchData:checkCanJoinDivide()
    local flag = false
    local ucontext = GameLogic.getUserContext()
    local lv = ucontext.buildData:getMaxLevel(const.Town)
    if (lv>=5) then
        flag = true
    end
    if GameLogic.useTalentMatch then
        local buff = ucontext.activeData:getBuffInfo(const.ActTypeBuffKnockMatch)
        if buff[4] > 0 then
            if GameLogic.getSTime() > (buff[2] + buff[3])/2 then
                flag = false
            end
        end
    end
    return flag
end

function KnockMatchData:checkCanStartFight()
    local flag = false
    local nowTime = GameLogic.getSTime()
    local time = self:getCanStartFightTime()
    if nowTime >= time then
        flag = true
    end
    return flag
end

function KnockMatchData:getCanStartFightTime(time)
    local _time = time or GameLogic.getSTime()
    local startTime, rollTime = self:getTimeConfigs()
    local endTime
    if _time < startTime then
        endTime = startTime
    else
        endTime = (ONE_DAY - _time%ONE_DAY) + _time
    end
    return endTime
end

--1、比赛开始；2、玩家属于参赛选手并且没有被淘汰；3、重新登录游戏
function KnockMatchData:checkOutGuide()
    local ucontext = GameLogic.getUserContext()
    local mRank = ucontext.mRank
    if mRank and mRank ~= 0 and (not self.showOutGuide) then
        self.showOutGuide = true
        local KnockOutInviteDialog = GMethod.loadScript("game.Dialog.KnockOutInviteDialog")
        display.showDialog(KnockOutInviteDialog.new({mRank = mRank}))
    end
end

function KnockMatchData:checkDivideGuide()
    --加载完数据，添加小组赛引导判断
    local context = GameLogic.getUserContext()
    local step = self:getDivideGuideStep(true)
    local lv = context.buildData:getMaxLevel(const.Town)

    local function callback()
        self.showDivideGuide = true
        GameEvent.sendEvent(GameEvent.addKncokGuide, self)
    end
    local function _callback()
        self:setDivideGuideStep(1)
        callback()
    end
    if lv >= 5 and not step then
        display.showDialog(StoryDialog.new({context=context,storyIdx=306,callback=_callback}),false,true)
    elseif step and step==1 and (not self.showDivideGuide) then
        callback()
    end
end

function KnockMatchData:getDivideGuideStep(needUpdate)
    -- dump({needUpdate, self.divideGuideStep})
    local context = GameLogic.getUserContext()
    if needUpdate then
        self.divideGuideStep = context.guideOr:getStepByKey("isKnockDivide")
    end
    return self.divideGuideStep
end

function KnockMatchData:setDivideGuideStep(step)
    self.divideGuideStep = step
    local context = GameLogic.getUserContext()
    context.guideOr:setStepByKey("isKnockDivide", step)
end

function KnockMatchData:setDivideGuideTime(time)
    if self.divideGuideTime then
        return
    end
    self.divideGuideTime = time
    local context = GameLogic.getUserContext()
    context.guideOr:setStepByKey("isKnockDivideTime", time)
end

function KnockMatchData:getDivideGuideTime()
    local time
    if not self.divideGuideTime then
        time =context.guideOr:getStepByKey("isKnockDivideTime")
    else
        time = self.divideGuideTime
    end
end

function KnockMatchData:checkDivideFlagEffect()
    local _dEnemy = self.dinfo.dEnemy
    local reborn = self:getDivideReborn()
    local flag = true
    for k, v in pairs(_dEnemy) do
        if reborn <= 0 then
            flag = false
            break
        end
        if v.def.reborn ~= reborn then
            flag = false
            break
        end
        if v.def.star > 0 then
            flag = false
            break
        end
        if v.def.destroy > 0 then
            flag = false
            break
        end
    end
    if flag then
        if not self:getDivideFlagEffectStep(true) then
            self:setDivideFlagEffectStep(true)
        else
            flag = false
        end
    end
    return flag
end

function KnockMatchData:setDivideFlagEffectStep(step)
    self.divideFlagStep = step
    local context = GameLogic.getUserContext()
    context.guideOr:setStepByKey("divideFlagStep", step)
end

function KnockMatchData:getDivideFlagEffectStep(needUpdate)
    local context = GameLogic.getUserContext()
    if needUpdate then
        self.divideGuideStep = context.guideOr:getStepByKey("divideFlagStep")
    end
    return self.divideGuideStep
end

function KnockMatchData:getStatueLvByRank(rank)
    local knockDivide = {[99] = 1, [64]=2, [32]=3, [16]=4, [8]=5, [4]=6, [2]=7, [1]=8}
    return knockDivide[rank]
end

function KnockMatchData:getStatueKind(bid)
    local kind = 1
    local knockDivide = {[99] = 1, [64]=2, [32]=3, [16]=4, [8]=5, [4]=6, [2]=7, [1]=8}

    local rank = self:getRankListInfo(bid)[1]
    if bid == 186 then
        kind = knockDivide[rank]
    elseif bid == 187 and rank then   --小组赛可能rank 不存在
        kind = self:getStageByScore(rank)
    end
    kind = kind or 1
    return kind
end

--淘汰赛执行计算脚本的时间
function KnockMatchData:isStartOutWeekNum()
	local weekNum = self:getWeek()
	if weekNum == self.startOutWeekNum then
		return true
	end
	return false
end

--服务端计算脚本执行时间
function KnockMatchData:inServerCalTime(bid)
    if bid ~= 186 then
        return false
    end
    local flag = false
    local nowTime = GameLogic.getSTime()
    if self:isStartOutWeekNum() and (nowTime <= GameLogic.getServerCalTime()) then
        flag = true
    end
    return flag
end

function KnockMatchData:canBuildStatue(bid)
    local context = GameLogic.getUserContext()
    local step = context.guideOr:getStepByKey("isKnockDivide")
    local lv = context.buildData:getMaxLevel(const.Town)
    local season = self:getMatchWeek()
    local rankList = context.rankList[bid]
    local flag = false
    if bid == 186 then   --1、主城大于5级；2、第二节淘汰赛
        if lv >= 5 and season > 2 then
            flag = true
        end
        --建筑里面有统一接口，这里先屏蔽掉
        -- if self:inServerCalTime(bid) then
        --     flag = false
        -- end
    elseif bid == 187 then
        local score = rankList[1]
        if (lv>= 5) and score then
            flag = true
        end
    end
    return flag
end

function KnockMatchData:canAddStatue(bid)
    local ucontext = GameLogic.getUserContext()
    local cbuilds = ucontext.buildData
    local bnum = cbuilds:getBuildNum(bid)
    --主城等级
    local tlevel = cbuilds:getMaxLevel(1)
    local bsetting = BU.getBSetting(bid)
    local binfo = SData.getData("binfos", bsetting.bdid)
    local max = binfo.levels[tlevel]

    local flag = false
    if self:canBuildStatue(bid) and (bnum<max) then
         flag = true
    end
    return flag
end

function KnockMatchData:canShowInStore(bid)
    local rankList = self:getRankListInfo(bid)
    local flag = false
    local season = self:getMatchWeek()
    if bid == 186 then
        if season > 2 then
            flag = true
        end
    elseif bid == 187 then
        flag = true
    end
    return flag
end

function KnockMatchData:getRankListInfo(bid)
    local context = GameLogic.getUserContext()
    local rankList = context.rankList[bid]
    return rankList
end
return KnockMatchData
