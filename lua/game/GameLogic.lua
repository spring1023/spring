local Context = GMethod.loadScript("game.GameLogic.Context")
local const = GMethod.loadScript("game.GameLogic.Const")
local BattleData = GMethod.loadScript("game.GameLogic.BattleData")
local RewardCommonDialog = GMethod.loadScript("game.UI.NewDialog.NewRewardCommonDialog")
local SData = GMethod.loadScript("data.StaticData")
local GameLogic = {}
--游戏逻辑
function GameLogic.newContext(uid)
    local context = Context.new(uid)
    return context
end

function GameLogic.newBattleData(scene)
    local bd = BattleData.new(scene)
    return bd
end

local _userContext = nil
local _currentContext = nil
function GameLogic.setUserContext(context)
    if _userContext then
        _userContext:destroy()
    end
    _userContext = context
end
function GameLogic.getUserContext()
    return _userContext
end
function GameLogic.setCurrentContext(context)
    _currentContext = context
end
function GameLogic.getCurrentContext()
    return _currentContext
end

function GameLogic.getGameName()
    return "COZ II TEST"
end

function GameLogic.feedback(otherSetting)
    local title = StringManager.getString("feedbackTitle")
    local feedbackMail = "21024851@qq.com"
    if otherSetting then
        if otherSetting.title then
            title = otherSetting.title
        end
        if otherSetting.mail then
            feedbackMail = otherSetting.mail
        end
    end
    display.closeDialog()
    local t = os.time() .. " " .. os.date("%Y-%m-%d %H:%M:%S")
    local language = General.language
    local gengine = GEngine
    local gameName = GameLogic.getGameName()
    local version = "Inner Test"
    local context = GameLogic.getUserContext()
    --default:getStringForKey("localVersion") .. "(" .. default:getIntegerForKey("siversion") .. ")"
    --version = version .. "(" .. StringManager.getString("labelServerName" .. network.curServerId) .. ")"
    if feedbackMail==nil or feedbackMail=="" then
        feedbackMail = "feedback@caesarsgame.com"
    end
    if version=="" then version="1" end
    local content = "\n\n------" .. StringManager.getString("feedbackNotice") .. "------\n" .. StringManager.getString("feedbackTime") .. t
    content = content .. "\n" .. StringManager.getString("feedbackName") .. gameName
    content = content .. "\n" .. StringManager.getString("feedbackVersion") .. version
    content = content .. "\n" .. StringManager.getString("feedbackUId") .. (8000000+context:getValue("id"))
    local uname = context:getValue("name")
    if uname and uname~="" then
        content = content .. "\n" .. StringManager.getString("feedbackUName") .. uname
    end
    local upurchase = context:getValue("purchase")
    if upurchase and upurchase>0 then
        content = content .. "\n" .. StringManager.getString("feedbackUCrystal") .. upurchase
    end
    content = content .. "\n" .. StringManager.getString("feedbackLanguage") .. GEngine.lanConfig.languages[language][4]
    content = content .. "\n" .. StringManager.getString("feedbackModel") .. (gengine.getConfig("deviceModel") or "windows asus")
    content = content .. "\n" .. StringManager.getString("feedbackSys") .. (gengine.getConfig("sysVersion") or "win8")
    content = content .. "\n-------------------"
    Native:sendEmail(feedbackMail, title .. gameName, content)
end

function GameLogic.openUrl(url)
    if not url then
        url = "http://www.baidu.com"
    end
    Native:openURL(url)
end

--这里用于处理服务器时间和当前时间

local _offTime = 0
function GameLogic.setSTime(stime)
    _offTime = stime-socket.gettime()
end

function GameLogic.getSFloatTime()
    return socket.gettime()+_offTime
end

function GameLogic.getSTime()
    return math.floor(GameLogic.getSFloatTime())
end

function GameLogic.getToday()
    local _todayTime = GameLogic._todayTime or const.InitTime
    if (_todayTime - const.InitTime) % 86400 ~= 0 then
        _todayTime = const.InitTime
    end
    local stime = GameLogic.getSTime()
    while _todayTime+86400 <= stime do
        _todayTime = _todayTime + 86400
    end
    while _todayTime > stime do
        _todayTime = _todayTime - 86400
    end
    GameLogic._todayTime = _todayTime
    return _todayTime
end

--获取服务器的周几
function GameLogic.getWeek(time)
    local _time = time or GameLogic.getSTime()
    local startTime = const.InitTime
    local week = math.floor( ((_time-startTime)%(86400*7))/86400 )+1
    return week % 7
end

--获取服务器执行脚本时间,预设30分钟，目前只用于神像
function GameLogic.getServerCalTime()
    local time = GameLogic.getToday() + 1800
    return time
end

function GameLogic.isTomorrow(stime,num)
    -- body
    local cNum = num or 0
    local ctime = GameLogic.getSTime()
    local numDay = math.floor((ctime-const.InitTime)/86400) - math.floor((stime - const.InitTime)/86400)
    if numDay>cNum then
        return true
    end
    return false
end

--获取联盟战布阵时间,--晚上23.30--00.30
function GameLogic.getUnionBattleTime()
    local stime = GameLogic.getSTime()
    local today = GameLogic.getToday()
    local startTime = today-30*60
    local endTime = today+30*60
    if stime > endTime then
        startTime = startTime + 86400
        endTime = endTime + 86400
    end
    return {startTime,endTime}
end

function GameLogic.computeCostByRes(ctype, value)
    if ctype==const.ResGold then
        if value>10000000 then
            return math.floor(value/10000000*3000)
        elseif value>1000000 then
            return math.floor(600+(3000-600)/9000000*(value-1000000))
        elseif value>100000 then
            return math.floor(125+(600-125)/900000*(value-100000))
        elseif value>10000 then
            return math.floor(25+(125-25)/90000*(value-10000))
        elseif value>1000 then
            return math.floor(5+(25-5)/9000*(value-1000))
        elseif value>100 then
            return math.floor(1+(5-1)/900*(value-100))
        else
            return 1
        end
    elseif ctype==const.ResSpecial then
        return math.floor(value*1000/400)
    elseif ctype==const.ResZhanhun then
        return math.floor(value/20)
    elseif ctype==const.ResMedicine then
        return math.floor(value*10)
    else
        return 10
    end
end

function GameLogic.computeCostByTime(timeInSecond)
    if timeInSecond<60 then
        return 1
    elseif timeInSecond<3600 then
        return 1+math.floor((20-1)*(timeInSecond-60)/(3600-60))
    elseif timeInSecond<86400 then
        return 20+math.floor((260-20)*(timeInSecond-3600)/(86400-3600))
    else
        return 260+math.floor((1000-260)*(timeInSecond-86400)/(604800-86400))
    end
end

function GameLogic.buyRes(ctype, cvalue)
    local cost = GameLogic.computeCostByRes(ctype, cvalue)
    local cctype = const.ResCrystal
    local context = GameLogic.getUserContext()
    if context:getRes(cctype)<cost then
        display.showDialog(AlertDialog.new({ctype=cctype, cvalue=cost}))
        return false
    else
        context:buyRes(ctype, cvalue, cost)
        if ctype==const.ResGold then
            GameLogic.statCrystalCost("补充金币消耗",const.ResCrystal,-cost)
        elseif ctype==const.Special then
            GameLogic.statCrystalCost("补充黑晶消耗",const.ResCrystal,-cost)
        elseif ctype==const.ResZhanHun then
            GameLogic.statCrystalCost("补充战魂消耗",const.ResCrystal,-cost)
        elseif ctype==const.ResMedicine then
            GameLogic.statCrystalCost("补充基因药水消耗",const.ResCrystal,-cost)
        end
        return true
    end
end

function GameLogic.buyResAndCallback(ctype, cvalue, callback)
    if GameLogic.buyRes(ctype, cvalue) and callback then
        callback()
    end
end

local _dumpLock = false
function GameLogic.onSendCmdsOver(sidx, eidx, suc, data)
    _dumpLock = false
    if not suc or data.code == 1 then
        GameLogic.doErrorHandler(3, "Error in \"GameLogic.onSendCmdsOver\", type 0, Request Network Error or Code=1:" .. tostring(suc))
        return
    end
    local context = _userContext
    if not context then
        return
    end
    local cstat = context:getCmdStat()
    local nsidx = cstat.lastIdx + 1
    if nsidx < sidx then
        --出错了，因为开始IDX比当前的第一条还靠后，即出现了指令跳跃；这是有问题的
        GameLogic.doErrorHandler(3, "Error in \"GameLogic.onSendCmdsOver\", type 1, nsidx=" .. nsidx .. ", sidx=" .. sidx)
        return
    end
    local neidx = cstat.maxIdx
    if eidx > neidx then
        --出错了，因为结束IDX比当前的最后一条还靠后
        GameLogic.doErrorHandler(3, "Error in \"GameLogic.onSendCmdsOver\", type 2, neidx=" .. neidx .. ", eidx=" .. eidx)
        return
    end
    if cstat.lastIdx < eidx then
        cstat.lastIdx = eidx
        for i = nsidx, eidx do
            table.remove(cstat.cachedCmds, 1)
            table.remove(cstat.goldStat, 1)
        end
    end
    cstat.lastResponseTime = GameLogic.getSTime()
    cstat.dirty = true
end

function GameLogic.dumpCmds(force)
    if not _dumpLock or force then
        local context = _userContext
        if not context then
            return
        end
        local cmds = context:dumpCmds()
        local cstat = context:getCmdStat()
        if cmds or cstat.maxIdx > cstat.lastIdx then
            _dumpLock = true
            cstat.lastTryTime = GameLogic.getSTime()
            GameNetwork.request("cmds", {cmds=cstat.cachedCmds, rtime=cstat.lastTryTime, sidx=cstat.lastIdx+1, eidx=cstat.maxIdx, gs=cstat.goldStat}, GameLogic.onSendCmdsOver, cstat.lastIdx+1, cstat.maxIdx)
            cstat.sendedIdx = cstat.maxIdx
        end
    end
end

function GameLogic.sortExpHero(hero1, hero2)
    local isExp1 = (hero1.hid%1000==0)
    local isExp2 = (hero2.hid%1000==0)
    if isExp1~=isExp2 then
        return isExp1
    elseif (hero1.info.displayColor or hero1.info.color) ~= (hero2.info.displayColor or hero2.info.color) then                     -- 品阶
        return (hero1.info.displayColor or hero1.info.color) > (hero2.info.displayColor or hero2.info.color)
    elseif hero1.info.exp ~= hero2.info.exp then
        return hero1.info.exp > hero2.info.exp
    elseif hero1.level~=hero2.level then
        return hero1.level>hero2.level
    elseif hero1.exp~=hero2.exp then
        return hero1.exp>hero2.exp
    else
        return hero1.hid<hero2.hid
    end
end

function GameLogic.sortExpHero2(hero1, hero2)
    local isExp1 = (hero1.hid%1000==0)
    local isExp2 = (hero2.hid%1000==0)
    if isExp1~=isExp2 then
        return isExp2
    elseif (hero1.info.displayColor or hero1.info.color) ~= (hero2.info.displayColor or hero2.info.color) then                     -- 品阶
        return (hero1.info.displayColor or hero1.info.color) > (hero2.info.displayColor or hero2.info.color)
    elseif hero1.info.exp ~= hero2.info.exp then
        return hero1.info.exp > hero2.info.exp
    elseif hero1.level~=hero2.level then
        return hero1.level>hero2.level
    elseif hero1.exp~=hero2.exp then
        return hero1.exp>hero2.exp
    else
        return hero1.hid<hero2.hid
    end
end

function GameLogic.addRewards(rewards)
    if not rewards or KTLen(rewards) == 0 then
        return
    end
    log.d(json.encode(rewards))
    local context = GameLogic.getUserContext()
    local isOverflow = false
    for _, reward in KTIPairs(rewards) do
        if reward[1]==const.ItemRes then
            context:changeResWithMax(reward[2], reward[3])
        elseif reward[1]==const.ItemHero then
            if type(reward[3]) == "table" then
                for _, idx in KTIPairs(reward[3]) do
                    if idx>0 then
                        context.heroData:addNewHero(idx, reward[2])
                    else --溢出
                        isOverflow = true
                    end
                end
            else
                if reward[3]>0 then
                    context.heroData:addNewHero(reward[3], reward[2])
                else --溢出
                    isOverflow = true
                end
            end
        elseif reward[1]==const.ItemEquip then
            if type(reward[3]) == "table" then
                for _, idx in KTIPairs(reward[3]) do
                    if idx>0 then
                        context.equipData:addNewEquip(idx, reward[2])
                    else   --溢出
                        isOverflow = true
                    end
                end
            else
                if reward[3]>0 then
                    context.equipData:addNewEquip(reward[3], reward[2])
                else   --溢出
                    isOverflow = true
                end
            end
        else
            context:changeItem(reward[1], reward[2], reward[3])
        end
    end
    if isOverflow then
        GameLogic.getUserContext().logData:getEmailDatas()
    end
    context.heroData:checkHeroNum()
end

function GameLogic.addShowGetList(list)
    if not GameLogic._toShowRwds then
        GameLogic._toShowRwds = {}
    end
    table.insert(GameLogic._toShowRwds, list)
end

function GameLogic.showGetList()
    if GameLogic._toShowRwds then
        for _, rwds in ipairs(GameLogic._toShowRwds) do
            GameLogic.showGet(rwds)
        end
        GameLogic._toShowRwds = nil
    end
end

--统计水晶奖励
function GameLogic.statCrystalRewards(reason,rewards)
    if not rewards or KTLen(rewards) == 0 then
        return
    end
    local num=0
    for _, reward in ipairs(rewards) do
        if reward[1]==const.ItemRes and reward[2]==const.ResCrystal then
            num=num+reward[3]
        end
    end
    if num>0 then
        Plugins:onStat({callKey=1,reason=reason,number=num})
    end
end

--统计水晶消耗
function GameLogic.statCrystalCost(reason,resId,num)
    if resId~=const.ResCrystal or num>=0 then
        return
    end
    Plugins:onStat({callKey=2,item=reason,itemNumber=1,itemPrice=-num})
end

local _myMsgId = {0, 0}
-- 自己的数据统计
function GameLogic.addStatLog(actionType, stat1, stat2, stat3)
    local stime = GameLogic.getSTime()
    if stime > _myMsgId[1] then
        _myMsgId[1] = stime
        _myMsgId[2] = 0
    end
    local msgId = (stime - const.InitTime) * 1024 + _myMsgId[2]
    _myMsgId[2] = _myMsgId[2] + 1
    local statLog = {const.CmdStat, msgId, stime, actionType, stat1, stat2, stat3}
    GameLogic.getUserContext():addCmd(statLog)
end

function GameLogic.getTime()
    return GameLogic.getSTime()
end

function GameLogic.getRtime()
    --return (GameLogic.getSTime()-GameLogic.getAdjustTime()-3600*8)%86400
    return (GameLogic.getSTime()-const.InitTime)%86400
end

function GameLogic.getTimeFormat(value)
    return StringManager.getTimeString(value)
end

--整型时间与字符型比较
function GameLogic.compareTime(intTime,strTime)
    local time=string.split(strTime," ")
    local time1=string.split(time[1],"-")
    local time2=string.split(time[2],":")
    local year=tonumber(time1[1])
    local month=tonumber(time1[2])
    local day=tonumber(time1[3])
    local hour=tonumber(time2[1])
    local min=tonumber(time2[2])
    local sec=tonumber(time2[3])
    local tab=os.date("*t",intTime)
    if tab.year>year then
        return 1
    elseif tab.year<year then
        return -1
    end
    if tab.month>month then
        return 1
    elseif tab.month<month then
        return -1
    end
    if tab.day>day then
        return 1
    elseif tab.day<day then
        return -1
    end
    if tab.hour>hour then
        return 1
    elseif tab.hour<hour then
        return -1
    end
    if tab.min>min then
        return 1
    elseif tab.min<min then
        return -1
    end
    if tab.sec>sec then
        return 1
    elseif tab.sec<sec then
        return -1
    end
    return 0
end
--格式化时间戳
function GameLogic.getTimeFormat2(value)
    local t = (value - const.InitTime)%86400
    return string.format("%02d:%02d:%02d", math.floor(t/3600), math.floor((t%3600)/60), math.floor(t%60))
end
function GameLogic.getTimeFormat3(value)
    local tab=os.date("*t",value)
    return tab.year.."/"..tab.month.."/"..tab.day
end
function GameLogic.getTimeFormat4(value)
    local tab = os.date("*t", value)
    return tab.year..":"..tab.month..":"..tab.day
end
--排序
function GameLogic.mySort(tb,key,down)
    for i=1,#tb do
        for j=1,#tb-i do
            local b
            if key then
                b = down and tb[j][key]<tb[j+1][key] or not down and tb[j][key]>tb[j+1][key]
            else
                b = down and tb[j]<tb[j+1] or not down and tb[j]>tb[j+1]
            end
            if b then
                tb[j],tb[j+1] = tb[j+1],tb[j]
            end
        end
    end
    return tb
end
--最大
function GameLogic.getMax(tb,key)
    local temp = -10000000
    local rt
    for k,v in pairs(tb) do
        if v[key]>temp then
            rt = v
            temp = v[key]
        end
    end
    return rt
end
--最小
function GameLogic.getMin(tb,key)
    local temp = 10000000
    local rt
    for k,v in pairs(tb) do
        if v[key]<temp then
            rt = v
            temp = v[key]
        end
    end
    return rt
end
function GameLogic.getItemName(resMode,resID)
    local name
    if not resID then           --是资源
        if resMode==const.ItemWelfare then
            return Localize("dataResName4")
        end
        name = Localize("dataResName" .. resMode)
    elseif resMode==const.ItemRes then
        --是资源
        name = Localize("dataResName" .. resID)
    elseif resMode==const.ItemHero then
        local info = SData.getData("hinfos", resID)
        if info and info.name then
            name = Localize(info.name)
        else
            name = Localize("dataHeroName" .. resID)
        end
    elseif resMode==const.ItemEquip then
        name = Localize("dataEquipName" .. resID)
    elseif resMode==const.ItemFragment then
        name = Localizef("dataFragFormat",{name=GameLogic.getItemName(const.ItemHero, resID)})
    elseif resMode==const.ItemEquipFrag then
        name = Localizef("dataFragFormat",{name=GameLogic.getItemName(const.ItemEquip, resID)})
    elseif resMode == const.ItemOther then
        if resID == const.ProMonthCard then
            return Localize("storeItemContract2")
        end
    else
        local info = SData.getData("property", resMode, resID)
        if info and info.name then
            name = Localize(info.name)
        else
            name = Localize("dataItemName" .. resMode .. "_" .. resID)
        end
    end
    return name
end

function GameLogic.getItemNum(resMode,resID)
    local context = GameLogic.getUserContext()
    if resMode==const.ItemRes then
        return context:getProperty(resID)
    else
        return context:getItem(resMode, resID)
    end
end

function GameLogic.getItemDesc(resMode,resID)
    local name
    if not resID then           --是资源
        name = Localize("dataResName" .. resMode)
    elseif resMode==const.ItemRes then
        --是资源
        local nkey = "dataItemInfo" .. resMode .. "_" .. resID
        name = Localize(nkey)
        if name == nkey then
            name = Localize("dataResName" .. resID)
        end
    elseif resMode==const.ItemHero then
        local info = SData.getData("hinfos", resID)
        if info.name then
            name = Localize(info.name)
        elseif info.job == 0 then
            name = Localizef("dataSkillInfo1_0", {a=info.exp})
        else
            name = Localize("dataHeroName" .. resID)
        end
    elseif resMode==const.ItemEquip then
        name = Localize("dataEquipName" .. resID)
    elseif resMode==const.ItemFragment then
        name = Localizef("dataFragFormat",{name=GameLogic.getItemName(const.ItemHero, resID)})
    elseif resMode==const.ItemEquipFrag then
        name = Localizef("dataFragFormat",{name=GameLogic.getItemName(const.ItemEquip, resID)})
    elseif resMode == const.ItemOther then
        name = ""
    else
        local info = SData.getData("property", resMode, resID)
        if info and info.desc then
            name = Localizef(info.desc, {a=info.value})
        else
            name = Localizef("dataItemInfo" .. resMode .. "_" .. resID, {a=info and info.value})
        end
    end
    return name
end

-- function GameLogic.getItemsNameByGroup(resMode, resID)
--     local itemInfo = SData.getData("property", resMode, resID)
--     if itemInfo.key then
--         return Localize(itemInfo.key)
--     end
--     local newboxGroups = SData.getData("newboxGroup", itemInfo.value)
--     local nameDict = {}
--     for _, groupItem in KTPairs(newboxGroups) do
--         local name = GameLogic.getItemName(groupItem.gtype, groupItem.gid)
--         if not nameDict[name] or nameDict[name] < groupItem.rate then
--             nameDict[name] = groupItem.rate
--         end
--     end
--     local nameList = {}
--     for k, v in pairs(nameDict) do
--         table.insert(nameList, {k, v})
--     end
--     GameLogic.mySort(nameList, 2)
--     for i = 1, #nameList do
--         nameList[i] = nameList[i][1]
--     end
--     return table.concat(nameList, Localize("lanSplitMark"))
-- end

function GameLogic.getStringLen(name)
    local charNum,c = 0,0
    --name = string.gsub(name, "^%s*(.-)%s*$", "%1")
    name = string.gsub(name, "^%s$", "%1")
    local i, l = 1, name:len()
    local cn,wn = 0,0
    while i<=l do
        c = name:byte(i)
        if c<0x80 then
            i = i+1
            wn = wn+1
        elseif c>=192 and c<=223 then
            i = i+2
            wn = wn+1
        else
            wn = wn+2
            if c>=224 and c<=239 then
                i = i+3
            elseif c>=240 and c<=247 then
                i = i+4

            elseif c>=248 and c<=251 then
                i = i+5
            elseif c>=252 and c<=253 then
                i = i+6
            else
                break
            end
        end
        cn = cn+1
    end

    return wn,cn,l
end

function GameLogic.getActiveDes(id,anum)
    return Localizef("dataActiveDes" .. id,{a = anum})
end

function GameLogic.getactreward(atype, aid, callback, noError)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getactreward",{getactreward = {atype, aid, noError}},function(isSuc, data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.stime then
                if data.stime < GameLogic.getToday() then
                    GameLogic.setSTime(data.stime)
                end
                callback()
                return
            end
            --print_r(data)
            if atype == 103 then
                local limitActive = GameLogic.getUserContext().activeData.limitActive
                limitActive[103][6] = 1
            else
                local activeData = GameLogic.getUserContext().activeData
                activeData:getReward(atype)
            end
            GameLogic.addRewards(data)
            GameLogic.showGet(data)
            callback()
            GameLogic.showHeroRewsUieffect(data)
        end
    end)
end

function GameLogic.dnumber(code,num)
    local tab = {}
    for i=1,num do
        local n = code%10
        code = (code-n)/10
        tab[i] = math.floor(n)
    end
    return tab
end

function GameLogic.enumber(tab)
    local num = 0
    for i,v in ipairs(tab) do
        num = num+v*10^(i-1)
    end
    return math.floor(num)
end

function GameLogic.checkHero(hero)      --出战 助战 锁定
    local louts = hero.layouts
    local isFight = false
    for lid, l in pairs(louts) do
        if l.type>0 then
            isFight = true
            break
        end
    end
    if hero.lock==1 or isFight then
        return false
    else
        return true
    end
end

function GameLogic.checkHeroDv(hero)       --是否养成过
    if hero.starUp>0 or hero.awakeUp>0 or hero.mSkillLevel>1 or hero.soldierLevel>1
        or hero.soldierSkillLevel1>0 or hero.soldierSkillLevel2>0 then
        return false
    else
        return true
    end
end
--rewards:{{type, id, num}, {} } delayTime:延迟时间， showResDl:, notShowNotice:,getType:从哪里获得的
function GameLogic.showGet(rewards,delayTime,showResDl,notShowNotice,getType,callback)
    local scene = GMethod.loadScript("game.View.Scene")
    local rewards = clone(rewards)
    local temp = {}
    local temp2 = {}
    local isUpOut = false
    local idx = 1
    for i=1, KTLen(rewards) do
        local v = rewards[idx]
        if v[1] == const.ItemHero then
            -- if v[3] == 0 then
            --     table.remove(rewards,idx)
            --     isUpOut = true
            -- else
                if not temp[v[2]] then
                    temp[v[2]] = {v[1],v[2],1}
                else
                    temp[v[2]][3] = temp[v[2]][3]+1
                end
                table.remove(rewards,idx)
            -- end
        elseif v[1] == const.ItemEquip then
                if not temp2[v[2]] then
                    temp2[v[2]] = {v[1],v[2],1}
                else
                    temp2[v[2]][3] = temp2[v[2]][3]+1
                end
                table.remove(rewards,idx)
        elseif v[1] == const.ItemRes and v[2] == const.ResExp then
            table.remove(rewards,idx)
        else
            idx = idx+1
        end
    end
    for k,v in pairs(temp) do
        table.insert(rewards,v)
    end
    for k,v in pairs(temp2) do
        table.insert(rewards,v)
    end
    scene.view:runAction(ui.action.sequence({{"delay",delayTime or 0},{"call",function()
        if not notShowNotice then
            for i, reward in ipairs(rewards) do
                scene.view:runAction(ui.action.sequence({{"delay",0.1*i},{"call",function()
                    local str = Localize("labelGet")
                    str = str .. GameLogic.getItemName(reward[1],reward[2])
                    str = str .. "x" .. reward[3]
                    display.pushNotice(str)
                end}}))
            end
        end
        if showResDl then
            local rdialog = RewardCommonDialog.new({rewards = rewards,callback = callback})
            display.showDialog(rdialog,true)
        end
    end}}))
end

function GameLogic.addVipExp(topupNum)
    if GameLogic.useTalentMatch then
        return
    end
    local vippower = SData.getData("vippower")
    local context = GameLogic.getUserContext()
    local topupNum = context:getInfoItem(const.InfoVIPexp)+topupNum
    local vip = 0
    for i,v in KTIPairs(vippower) do
        if topupNum>=v.crynum then
            vip = i
        end
    end
    if vip ~= context:getInfoItem(const.InfoVIPlv) then
        GameLogic.reVIPGiftData(1)
    end
    context:setInfoItem(const.InfoVIPexp,topupNum)
    context:setInfoItem(const.InfoVIPlv,vip)
    --vip等级单条件触发活动
    context.activeData:finishActConditionOnce(const.ActStatUserVip,vip)
end
function GameLogic.reVIPGiftData(typeNum)
    -- 因为vip产生了变化，所以vip里面的礼包要重置
    --整合：1，vip产生变化(全部重置) 2, 每周刷新的时候(只有第2个礼包刷新) 3，第一个礼包的领取的每日刷新
    --第三个礼包不要管他
    local context = GameLogic.getUserContext()
    local time = GameLogic.getSTime()
    if typeNum==1 then
        context:setProperty(const.ProBuyVipPkg1,0)
        context:setProperty(const.ProBuyVipPkgTime1,time)
        context:setProperty(const.ProBuyVipPkg2,0)
        context:setProperty(const.ProBuyVipPkgTime2,time)
    elseif typeNum == 2 then
        context:setProperty(const.ProBuyVipPkg2,0)
        context:setProperty(const.ProBuyVipPkgTime2,time)
    elseif typeNum == 3 then
        context:setProperty(const.ProBuyVipPkg1,0)
        context:setProperty(const.ProBuyVipPkgTime1,time)
    end
end
--购买宝石次数
function GameLogic.getBuyedCrystalNum(gemIdx)
    if GameLogic.useTalentMatch then
        return 0
    end
    local context = GameLogic.getUserContext()
    local num=context:getProperty(const["ProBuyedCrystal_gem"..gemIdx]) or 0
    return num
end

function GameLogic.addBuyedCrystalNum(gemIdx)
    if GameLogic.useTalentMatch then
        return
    end
    local num = GameLogic.getBuyedCrystalNum(gemIdx)+1
    local context = GameLogic.getUserContext()
    context:setProperty(const["ProBuyedCrystal_gem"..gemIdx],num)
end

function GameLogic.getBitSgin(sgin,idx)
    return bit.band(sgin, bit.lshift(1, idx))>0
end

function GameLogic.setBitSgin(sgin,idx)
    local num = bit.bor(sgin, bit.lshift(1, idx))
    return num
end

function GameLogic.getGc()
    return GEngine.rawConfig.testGc
end

function GameLogic.getFb()
    return GEngine.rawConfig.testFb
end

function GameLogic.setServerColor(sp,state)
    if state == 0 then
        ui.setColor(sp,255,64,44)
    elseif state == 1 then
        ui.setColor(sp,59,255,44 )
    elseif state == 2 then
        ui.setColor(sp,196,196,196)
    end
end

function GameLogic.getRandom(min,max)
    local scene = GMethod.loadScript("game.View.Scene")
    local rd = scene and scene.replay and scene.replay.rd
    if rd then
        local num = rd:random(min,max)
        scene.replay:addDebugText("random" .. num)
        --print("$$$$$",num,tostring(debug.traceback()))
        return num
    else
        if max then
            return math.random(min,max)
        elseif min then
            return math.random(min)
        else
            return math.random()
        end
    end
end

function GameLogic.getBattleHeroId()
    local scene = GMethod.loadScript("game.View.Scene")
    local herosId = {}
    local haveInsert = {}
    --英雄台 和 联盟建筑上的英雄或者神兽
    for k,build in pairs(scene.builds) do
        local rhero = build.vstate and build.vstate.rhero or build.__ehero
        if rhero then
            local id = rhero.sid
            if id>8000 and id<9000 then
                id = math.floor(id/10)*10+3
            end
            haveInsert[id] = true
        end
    end
    if scene.context.enemy and scene.context.enemy.buildData then
        for k,build in pairs(scene.context.enemy.buildData:getSceneBuilds()) do
            local rhero = build.vstate and build.vstate.rhero or build.__ehero
            if rhero then
                local id = rhero.sid
                if id>8000 and id<9000 then
                    id = math.floor(id/10)*10+3
                end
                haveInsert[id] = true
            end
        end
    end
    --hitems
    for i,group in ipairs(scene.battleData.groups or {}) do
        for j,hitem in pairs(group.hitems or {}) do
            if hitem.hid then
                haveInsert[hitem.hid] = true
            end
        end
    end
    if scene.battleType == const.BattleTypePvj then
        for i,hitems in ipairs(scene.battleData.readyHeros) do
            for j,hitem in ipairs(hitems) do
                local id = hitem.hero.hid
                if id>8000 and id<9000 then
                    id = math.floor(id/10)*10+3
                end
                haveInsert[id] = true
            end
        end
    elseif scene.battleType == const.BattleTypePvt then
        local groups = {scene.battleData.heros,scene.battleData.dheros}
        for i,group in ipairs(groups) do
            for j=1,9 do
                local hitem = group[j]
                if hitem and hitem.hero then
                    haveInsert[hitem.hero.hid] = true
                end
            end
        end
    end
    for k,v in pairs(haveInsert) do
        table.insert(herosId,k)
    end
    table.insert(herosId,4024)
    return herosId
end

function GameLogic.checkLayout(lid)
    for i=1,5 do
        local hero = GameLogic.getUserContext().heroData:getHeroByLayout(lid,i,1)
        if hero then
            return true
        end
    end
end

function GameLogic.getRebirthCost(lid)
    local cost = 0
    local stime = GameLogic.getSTime()
    local allDie = true
    local heroTab = {}
    for i=1,5 do
        local hero = GameLogic.getUserContext().heroData:getHeroByLayout(lid,i,1)
        if hero then
            if not hero:isAlive(stime) then
                local c = GameLogic.computeCostByTime(hero.recoverTime-stime)
                cost = cost+c
                table.insert(heroTab,hero)
            else
                allDie = false
            end
        end
    end
    return cost,allDie,heroTab
end

function GameLogic._realGo(allDie, callback)
    if allDie then
        display.pushNotice(Localize("stringAllDieCantGoWar"))
    else
        callback()
    end
end

function GameLogic._checkCanGoBattle(lid,aliveCheck,callback)
    if GameLogic.checkLayout(lid) then
        if aliveCheck then
            local cost,allDie,heroTab= GameLogic.getRebirthCost(lid)
            local ncall = Handler(GameLogic._realGo, allDie, callback)

            if cost>0 then
                local otherSettings = {ctype = const.ResCrystal, cvalue = cost, noCallback = ncall, callback = function()
                    local stime = GameLogic.getSTime()
                    for i,hero in ipairs(heroTab) do
                        if hero and hero.recoverTime>stime then
                            local cost = GameLogic.computeCostByTime(hero.recoverTime-stime)
                            hero.recoverTime = 0
                            GameLogic.getUserContext().heroData:healHero(hero, stime, cost)
                        end
                    end
                    callback()
                end}
                local alert = AlertDialog.new(5,Localize("alertTitleNormal"),Localize("stringIsRebirthAllHero"),otherSettings)
                display.showDialog(alert)
            else
                ncall()
            end
        else
            callback()
        end
    else
        display.pushNotice(Localize("stringNoHeroCantWar"))
    end
end

function GameLogic.checkCanGoBattle(battleType, callback, matchId)
    local sign = GameLogic.getUserContext():getProperty(const.ProUseLayout)
    sign = GameLogic.dnumber(sign, 6)
    local lid = const.LayoutPvp
    local aliveCheck = false
    if battleType == const.BattleTypePvp or battleType == const.BattleTypePve or battleType == const.BattleTypeUPvp then
        if sign[1]>0 then
            lid = const.LayoutPve
        end
        if battleType ~= const.BattleTypeUPvp then
            aliveCheck = true
        end
    elseif battleType == const.BattleTypePvc then
        if sign[2]>0 then
            lid = const.LayoutPvc
        end
    elseif battleType == const.BattleTypeUPve then
        if sign[3]>0 then
            lid = const.LayoutUPve
        end
    elseif battleType == const.BattleTypePvb then
        if sign[matchId-100]>0 then
            lid = const.LayoutUPve + matchId - 103
        end
    end
    GameLogic._checkCanGoBattle(lid,aliveCheck,callback)
end

function GameLogic.checkPvpAttack(checkMap, setKey)
    if setKey then
        checkMap[setKey] = true
    end
    local context = GameLogic.getUserContext()
    if context.pvpChance:getValue() <= 0 then
        display.pushNotice(Localize("noticePvpChanceEmpty"))
        return
    end
    -- if context.heroData:getHeroMax() < context.heroData:getHeroNum() + 3 then
    --     display.pushNotice(Localize("noticeHeroSpaceFull"))
    --     return
    -- end
    setKey = "goldChecked"
    if not checkMap[setKey] then
        if context:getRes(const.ResGold) >= context:getResMax(const.ResGold) then
            display.showDialog(AlertDialog.new(3,Localize("labelGoldFull"), Localize("stringGoldFull"), {callback=Handler(GameLogic.checkPvpAttack, checkMap, setKey)}))
            return
        end
    end
    setKey = "shieldChecked"
    if not checkMap[setKey] then
        if context.enterData.ustate[1] > GameLogic.getSTime() then
            display.showDialog(AlertDialog.new(3,Localize("alertTitleNormal"),Localize("alertTextShieldPvp"), {callback=Handler(GameLogic.checkPvpAttack, checkMap, setKey)}))
            return
        end
    end
    setKey = "goldCost"
    if not checkMap[setKey] then
        local cost = context:getPvpCost()
        if cost > context:getRes(const.ResGold) then
            display.showDialog(AlertDialog.new({ctype=const.ResGold, cvalue=cost, callback=Handler(GameLogic.checkPvpAttack, checkMap)}))
            return
        end
    end
    local function onReadyToPvp()
        if context.enterData.ustate[1] > GameLogic.getSTime() then
            context.enterData.ustate[1] = 0
        end
        checkMap.callback()
    end
    GameLogic.checkCanGoBattle(const.BattleTypePvp, onReadyToPvp)
end

function GameLogic.lockInGuide()
    display.pushNotice(Localize("stringPleaseGuideFirst"))
end

function GameLogic.sendChat(params)
    local scene = GMethod.loadScript("game.View.Scene")
    local chatRoom = scene.menu.chatRoom
    local msg = {}
    local ucontext = GameLogic.getUserContext()
    if params.mtype == 4 then
        if params.mode then
            if params.mode == 3 then
                local ug = {lv=ucontext:getInfoItem(const.InfoLevel), job=ucontext.union.job, mode=3}
                msg = {mtype=4, uid=ucontext.uid, cid=ucontext.union.id, name=ucontext:getInfoItem(const.InfoName)
                ,ug=json.encode(ug)}
            else
                local ug = {lv=params.lv, job=params.job, mode=params.mode}
                msg = {mtype=params.mtype, uid=params.uid, cid=params.cid, name=params.name, ug=json.encode(ug),
                infoName=ucontext:getInfoItem(const.InfoName)}
            end
        end
    end
    chatRoom:send(msg)
end

function GameLogic.checkVipSheild()
    local remainCD = GameLogic.getUserContext().enterData.ustate[3]-GameLogic.getSTime()
    local lock = GameLogic.getUserContext():getVipPermission("propect")[1]
    return (remainCD<0 and lock == 0) and 1 or 0
end

function GameLogic.transEquipData(eq)
    local ret = {}
    if eq then
        for _, edata in ipairs(eq) do
            ret[edata[1]] = {edata[2],edata[10],edata[3],0,edata[4],edata[5],edata[6],edata[7],edata[8],edata[9]}
        end
    end
    return ret
end

function GameLogic.dtransEquipData(eq)
    local ret = {}
    if eq then
        for k,v in pairs(eq) do
            local ed = {}
            local a
            ed[1],ed[2],ed[10],ed[3],a,ed[4],ed[5],ed[6],ed[7],ed[8],ed[9]=
            k,v[1],v[2],v[3],v[4],v[5],v[6],v[7],v[8],v[9],v[10]
            table.insert(ret,ed)
        end
    end
    return ret
end

function GameLogic.saveReplay(name,data)
    local context = GameLogic.getUserContext()
    local uid = context.uid
    local sid = context.sid
    local key = sid .. "_" .. uid .."allRp"
    local allRp = GEngine.getConfig(key) or "[]"
    allRp = json.decode(allRp)
    local fu = cc.FileUtils:getInstance()
    local rp = fu:getWritablePath()
    name = rp .. name
    if #allRp>50 then
        table.remove(allRp,1)
        os.remove(name)
    end
    table.insert(allRp,name)
    cc.FileUtils:getInstance():writeStringToFile(data, name)
end

function GameLogic.getReplay(name)
    local fu = cc.FileUtils:getInstance()
    local rp = fu:getWritablePath()
    name = rp .. name

    if fu:isFileExist(name) then
        return fu:getStringFromFile(name)
    end
    return false
end

function GameLogic.setSchedulerScale(sc)
    cc.Director:getInstance():getScheduler():setTimeScale(sc)
end

function GameLogic.checkWrong(name)
    if name:find("\n") or name:find("\r") then
        return true
    end
    local str,code = string.trim(name)
    if code == 1 then
        return true
    end
    return filterSensitiveWords(name,true)
end

local signLimit = {
    {33,47},
}
function GameLogic.checkSign(name)
    --获取每一个字符
    local wordlist = {}
    for w in string.gmatch(name, ".[\128-\191]*") do
        local code = string.byte(w)
        for i,v in ipairs(signLimit) do
            if v[1]<=code and code<=v[2] then
                return true
            end
        end
    end
end

function GameLogic.checkName(name,ntype)
    local wn,cn,l = GameLogic.getStringLen(name)
    local limit
    local context = GameLogic.getUserContext()
    if ntype == const.InfoName then
        limit = 10
        local curName = context:getInfoItem(const.InfoName)
        if name==curName then
            return -3
        end
    else
        limit = 14
    end
    if wn>limit then
        return -1
    end
    if GameLogic.checkWrong(name) then
        return -2
    end
    if GameLogic.checkSign(name) then
        return -2
    end
    return 1
end

function GameLogic.givemonthcard(uid, params)
    local _params = params or {}
    local _callback = _params.callback
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("givemonthcard",{tid = uid},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data == 10 then
                display.pushNotice(Localize("labelMonthCardCantGive"))
            elseif data == 11 then
                display.pushNotice(Localize("labelCantManagelmember2"))
            else
                display.pushNotice(Localize("labelGiveSucceed"))

                local context = GameLogic.getUserContext()
                context:setProperty(const.ProMonthCard,context:getProperty(const.ProMonthCard)-1)
                context.activeData:finishActCondition(const.ActTypeGiveMC,1)

                local name = context:getInfoItem(const.InfoName)
                local ug = {uid = uid}
                local muid = context.uid
                local msg = {uid=muid,cid=context.union.id,text="加加加",name=name,mtype=11,ug = json.encode(ug)}
                local scene = GMethod.loadScript("game.View.Scene")
                scene.menu.chatRoom:send(msg)
                if _callback then
                    _callback()
                end
            end
        end
    end)
end

function GameLogic.unionBattle(ptype)
    local p = ptype or 0        -- ptype = 1 时强跳到非战斗状态
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getpvlinfo",{ptype=p},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==1 then
                UnionBattleOpenDialog.new(data)
            elseif data.code==2 then
                data.isStopBattle = true
                UnionBattleOpenDialog.new(data)
            elseif data.code==0 then
                UnionBattleLineupInterface.new(data)
            elseif data.code==20 then
                display.pushNotice(Localize("labelCantManagelmember2"))
            end
        end
    end)
end

function GameLogic.fnum(num,n)
    num = tonumber(string.format("%." .. n .. "f",num))
    return num
end

function GameLogic.doErrorHandler(etype, other)
    if GameLogic.inError then
        return
    end
    print("do error handler!", debug.traceback())
    GameLogic.inError = true
    if etype == 1 then
        local otherSettings = {callback = GameLogic.restart, noCloseBut = true}
        local text2 = Localize("labelPleaseLoginAgain")
        if GameLogic.inTest and other then
            text2 = text2 .. other
        end
        local dl = AlertDialog.new(4,Localize("labelNetError2"),text2,otherSettings)
        display.showDialog(dl,false)
    elseif etype == 2 then
        GameLogic.restart()
    elseif etype ==3 then
        -- 出错之后重启不要重发上次的命令
        GEngine.setConfig("cmds_data_" .. GameLogic.uid, "", true)
        GEngine.setConfig("last_syn_uid", 0, true)

        local otherSettings = {callback = GameLogic.restart, noCloseBut = true}
        local text2 = Localize("labelPleaseLoginAgain2")
        if GameLogic.inTest and other then
            text2 = text2 .. other
        end
        local dl = AlertDialog.new(4,Localize("labelNetError"),text2,otherSettings)
        display.showDialog(dl,false)
    end
end

function GameLogic.restart()
    if GameLogic.lockReplayItems then
        local lri = GameLogic.lockReplayItems
        local s, a, ns, na, sid = lri[1], lri[2], lri[3], lri[4], lri[5]
        local director = cc.Director:getInstance()
        ns:unscheduleScriptEntry(sid)
        director:setScheduler(s)
        director:setActionManager(a)
        a:release()
        s:release()
        GameLogic.lockReplayItems = nil
    end
    pairs = GMethod.rawPairs
    ipairs = GMethod.rawIPairs
    GEngine.restart()
end

local usdDict = {1.99, 4.99, 9.99, 24.99, 49.99, 99.99}
function GameLogic.addBuyedRes(data)
    --[[82312,10,4,500,'']]
    local context = GameLogic.getUserContext()
    local rewards={}
    local act={}
    for i, v in ipairs(data) do
        local actId, rwdIdx, addToRwd, statAmount = 0, 0, true, 0
        for _, da in ipairs(v) do
            --水晶，月卡，联盟月卡
            if da[2]==10 and da[3]==4 then
                context:changeProperty(const.ResCrystal,da[4])
                display.pushNotice(Localize("noticeBuySuccess")..Localize("dataResName4"))
                GameLogic.statCrystalRewards("购买水晶获得",{{10,4,da[4]}})
                statAmount = da[4] - da[6]
                --增加购买次数
                local idMap = {230,600,1400,3800,7800,16800,18,110}
                local idMap2 = {}
                for i,v in ipairs(idMap) do
                    idMap2[v] = i
                end
                local gemIdx = (idMap2[statAmount] or 0)-1
                if gemIdx >= 0 then
                    if not GameLogic.useTalentMatch then
                        GameLogic.addBuyedCrystalNum(gemIdx)
                    end
                    GameEvent.sendEvent("TreasureChange")
                    GameEvent.sendEvent("refreshAchievementDialogEveryday")
                    Plugins:onFacebookStat("PrePurchase", {price=usdDict[gemIdx+1], currency="USD", itemId="StoreItem" .. (gemIdx+1)})
                end
            elseif da[2]==30 and da[3]==1 then
                context:changeRes(const.ResCrystal, da[6])
                context.activeData:finishActCondition(const.ActTypeMC, 1)
                statAmount = da[6]
                GameLogic.statCrystalRewards("购买月卡获得",{{10,4,da[6]}})
                if context.vips[5][2]>GameLogic.getSTime() then
                    context.vips[5][2] = context.vips[5][2]+30*86400
                else
                    context.vips[5][2] = GameLogic.getSTime()+30*86400
                end
                context.activeData:finishAct(4)
                display.pushNotice(Localize("noticeBuySuccess")..Localize("storeItemContract1"))
                GameEvent.sendEvent("TreasureChange")
                Plugins:onFacebookStat("PrePurchase", {price=usdDict[3], currency="USD", itemId="StoreItem7"})
            elseif da[2]==30 and da[3]==2 then
                context:changeProperty(const.ProMonthCard,da[4])
                context.activeData:finishActCondition(const.ActTypeLeagueMC,1)
                display.pushNotice(Localize("noticeBuySuccess")..Localize("storeItemContract2"))
                Plugins:onFacebookStat("PrePurchase", {price=usdDict[3], currency="USD", itemId="StoreItem8"})
            -- 如果以后购买的方式改成先买再领，则应走此逻辑
            elseif da[2]==30 and da[3]==3 then
                actId = da[5]
                rwdIdx = da[6]
                statAmount = da[7]
                addToRwd = false
            elseif da[2] == 40 then
                statAmount = 0
                context.activeData:finishAct(51)
                Plugins:onStat({callKey=5,eventId="activity_51",params={personNum=1}})
                GameEvent.sendEvent("FirstPackage")
            elseif da[2] == 50 then
                local minfo = json.decode(da[5])
                context.talentMatch:updateMatchPurchase(minfo.matchId, minfo.giftId)
                GameEvent.sendEvent("TalentMatchGift")
            elseif da[2]==18 and da[3]==1 then
                context:changeItem(18, 1, da[4])
                display.pushNotice(Localize("noticeBuySuccess")..Localize("storeItemContract3"))
                Plugins:onFacebookStat("PrePurchase", {price=usdDict[3], currency="USD", itemId="ExtItem3.-1"})
                local vip = context:getInfoItem(const.InfoVIPlv)
                local userLv = context:getInfoItem(const.InfoLevel)
                local zhiwei = context.union and context.union.job or 0
                GameLogic.addStatLog(11402, vip, userLv, zhiwei)
            else
                table.insert(rewards,{da[2],da[3],da[4]})
                if da[1] == 0 and da[7] then
                    actId = da[5]
                    rwdIdx = da[6]
                    statAmount = da[7]
                end
            end
        end
        --统计首充礼包
        music.play("sounds/buy.mp3")
        Plugins:onFacebookStat("PrePaymentInfo", 1)
        GameLogic.getUserContext().activeData:finishActCondition(const.ActTypeBuyAll,1)
        if statAmount and statAmount > 0 then
            context.activeData:addBuyedCrystal(statAmount)
            --加vip
            GameLogic.addVipExp(statAmount)
            --季度礼包
            context.activeData:finishAct(102, statAmount)
            context:changeInfoItem(const.InfoCryNum, statAmount)
        end
        if actId > 0 and rwdIdx > 0 then
            if addToRwd then
                context.activeData:finishActRwd(actId, rwdIdx)
            end
            local rwd = context.activeData:getConfigableRwds(actId, rwdIdx)
            if rwd.guideTag == "YouthDay" then --青年节活动
                local YouthDayData = GMethod.loadScript("game.GameLogic.YouthDayData")
                YouthDayData:finishAct()
            end
            if rwd then
                context.activeData:finishActCondition(rwd.conditions[1][1], 1)
                Plugins:onFacebookStat("PrePurchase", {price=usdDict[rwd.goodsid], currency="USD", itemId="ExtItem" .. rwd.goodsid .. ".3_" .. actId .. "_" .. rwdIdx})
            end
        end
    end
    GameLogic.addRewards(rewards)
    GameLogic.showGet(rewards)
    GameLogic.showHeroRewsUieffect(rewards)
end

--检查是否是城墙或佣兵
function GameLogic.checkWallorSoldier(v)
    local isTF = false
    if (v.vstate and v.bid == 50) or (v.avater and v.sid>=100 and v.sid<1000) then
        isTF = true
    end
    return isTF
end

local _versionCache = {}
-- 通用检测有版本号的数值, vkey为default中的key值
function GameLogic.getVersionData(vkey)
    if _versionCache[vkey] then
        return _versionCache[vkey]
    end
    local cfs = cc.FileUtils:getInstance()
    local fpath = cfs:getWritablePath() .. vkey .. ".cfg"
    local vdata = GMethod.loadConfig(fpath)
    if type(vdata) ~= "table" then
        vdata = {}
    end
    if not vdata.v then
        vdata.v = 0
    end
    _versionCache[vkey] = vdata
    return vdata
end
-- 设置有版本号的数值
function GameLogic.setVersionData(vkey, vdata)
    _versionCache[vkey] = vdata
    local cfs = cc.FileUtils:getInstance()
    local fpath = cfs:getWritablePath() .. vkey .. ".cfg"
    cfs:writeStringToFile(json.encode(vdata), fpath)
end

-- 领到奖励之后的逻辑处理
function GameLogic.onReceivedActRwd(context, suc, data)
    GameNetwork.unlockRequest()
    if suc then
        if data.code == 0 then
            if data.rwds then
                GameLogic.addRewards(data.costs)
                GameLogic.addRewards(data.rwds)
                context.activeData:finishActRwd(data.actId, data.rwdIdx, data.num or 1)
                -- 发送事件，如果有对话框接收并处理了显示逻辑则调过自己的显示逻辑
                local eparams = {"receiveOver", false, data}
                GameEvent.sendEvent("refreshEggDialog", eparams)

                if not eparams[2] then
                    GameLogic.showHeroRewsUieffect(data.rwds)
                    GameLogic.showGet(data.rwds)
                end
            end
            GameEvent.sendEvent("refreshActivityDialog")
        elseif data.code == 3 then
            display.pushNotice(Localize("activeTimeOver"))
            -- 显示错误提示
        else
            display.pushNotice(Localize("noticeReceiveFail" .. data.code))
        end
    end
end

-- 养成系统的跳转
function GameLogic.jumpCondition(conditionId, info)
    local context = GameLogic.getUserContext()
    local _info = info or nil
    if conditionId == const.ActTypeLeagueMC or conditionId == const.ActTypePurchase or conditionId == const.ActTypePurchaseSingle or conditionId == const.ActTypeMC then
        StoreDialog.new(1)
    elseif conditionId == const.ActTypePVC then
        if GameLogic.checkResUnlock(const.ItemRes,const.ActTypePVC) then
            display.showDialog(ArenaDialog.new())
        else
            display.pushNotice(Localizef("noticeBuilderNotEnough",{name = Localize("titleArenaMain")}))
        end
    elseif conditionId == const.ActTypePVP or conditionId == const.ActTypePVT or conditionId==const.ActTypePVPGold then

        GameLogic.addJumpGuide(conditionId,"getJumpPVP")
        display.showDialog(PlayInterfaceDialog.new({source = "talentMatch"}))
    elseif conditionId == const.ActTypePVE then
        GameLogic.addJumpGuide(conditionId,"getJumpPVE")
        display.showDialog(PlayInterfaceDialog.new())
    elseif conditionId == const.ActTypePVLE or conditionId == const.BattleTypeUPve then
        if context.union then
            UnionMapDialog.new()
        else
            display.pushNotice(Localize("stringNotJoin"))
        end
    elseif conditionId == const.BattleTypeUPvp then
            GameLogic.unionBattle()
    elseif conditionId == const.ActTypeSignIn then    -- 每日签到
        SignRewardDialog.new()
    elseif conditionId == const.ActTypeGiveMC then    -- 赠送联盟月卡，跳转到我的联盟界面
        if context.union then
            UnionInfoDialog.new()
        else
            display.pushNotice(Localize("stringNotJoin"))
        end
    --这里开始是新加的
    elseif conditionId == const.JumpTypeStore then--商店主页面
        StoreDialog.new()
    elseif conditionId == const.JumpTypeHeroStore then--英雄商店
        StoreDialog.new({id=6})
    elseif conditionId == const.JumpTypeGoldStore then--金币商店
        if not GameLogic.checkConditionUnlock({},conditionId) then
            GameLogic.addJumpGuide(conditionId,"JumpGoldStore")
            StoreDialog.new({id=1,guideBuyGold = true})
        else
            display.pushNotice(Localize("labelGoldFull"))
        end
    elseif conditionId == const.JumpTypeDiamondStore then--宝石商店
        GameLogic.addJumpGuide(conditionId,"JumpDiamondStore")
        StoreDialog.new({id=1,guideBuyDamond = true})
    elseif conditionId == const.JumpTypeEquipStore then--装备商店
        StoreDialog.new({idx=1,stype="equip"})
    elseif conditionId == const.JumpTypeMater then--材料商店
        StoreDialog.new({idx=2,stype="equip"})
    elseif conditionId == const.JumpTypeBlackStore then--黑晶商店
        GameLogic.addJumpGuide(conditionId,"JumpBlackStore")
        StoreDialog.new({id=1,guideBuyBlack=true})
    elseif conditionId == const.JumpTypeExpStore then--经验商店
        StoreDialog.new({id=1,guideBuyExp=true})
    elseif conditionId == const.JumpTypeGeneStore then--基因药水
        StoreDialog.new({id=1,guideBuyMedicine=true})
    elseif conditionId == const.LayoutPvh then
        local b = context.buildData:getBuild(4)
        if b then
            b:showPvhDialog()
        else
            display.pushNotice(StringManager.getFormatString("noticeBuilderNotEnough", {name=BU.getBuildName(const.WeaponBase)}))
        end
    elseif conditionId == const.JumpTypeAccp then
        AchievementDialog.new()
    elseif conditionId == const.JumpTypeTask then
        AchievementDialog.new(2)
    elseif conditionId == const.BattleTypePvt then
        HeroTrialDialog.new()
    elseif conditionId == const.JumpTypeList then
        AllRankingListDialog.new(1)
    elseif conditionId == const.JumpTypeBarSpecial then
        BeercupDialog.new({rtype=const.ResSpecial})
    elseif conditionId == const.JumpTypeBarZhanhun then
        BeercupDialog.new({rtype=const.ResZhanhun})
    elseif conditionId == const.BattleTypePvj then
        if GameLogic.checkResUnlock(const.ItemEquip) then
            GameLogic.addJumpGuide(conditionId,"heroJumpPvj")
            zombieIncomingDialog.new()
        end
    elseif conditionId == const.JumpTypeGodBaest then
        --if GameLogic.checkResUnlock(0,conditionId) then
            GameLogic.addJumpGuide(conditionId,"godBaestJump")
            display.showDialog(UnionPetsDialog.new({context=context, pets=context.unionPets, initTag="info"}))
        --else
        --   display.pushNotice(Localizef("noticeUnionPermission"))
        --end
    elseif conditionId == const.JumpTypeOrb then
            GameLogic.addJumpGuide(conditionId,"godBaesOrbJump")
            display.showDialog(UnionPetsDialog.new({context=context, pets=context.unionPets, initTag="storage"}))
    elseif conditionId == const.JumpTypeHeroInfo then
        GameLogic.addJumpGuide(conditionId,"heroJumpUpgrade")
        display.showDialog(HeroMainDialog.new({initTag="info",dialogParam=_info.hero.idx}))
    elseif conditionId == const.JumpTypeWish then
        GameLogic.addJumpGuide(conditionId,"wishJumpGuide")
        display.showDialog(HeroMainDialog.new({initTag="extract",hero = _info.hero}))
    elseif conditionId == const.JumpTypeChip then
        display.showDialog(HeroMainDialog.new({initTag="image",hero = _info.hero,imgIdx = 4}))
    elseif conditionId == const.JumpTypePass then
        GameLogic.addJumpGuide(conditionId,"heroJumpPass")
        display.showDialog(HeroMainDialog.new({initTag="info",dialogParam = _info.hero.idx,skillIdx=2}))
    elseif conditionId == const.JumpTypeMain then
        GameLogic.addJumpGuide(conditionId,"heroJumpMain")
        display.showDialog(HeroMainDialog.new({initTag="info",dialogParam = _info.hero.idx}))
    elseif conditionId == const.JumpTypeMercenary then
        GameLogic.addJumpGuide(conditionId,"heroJumpMercenary")
        display.showDialog(HeroMainDialog.new({initTag="info",dialogParam = _info.hero.idx}))
    elseif conditionId == const.JumpTypeWake then
        if GameLogic.checkConditionUnlock(_info,conditionId) then
            GameLogic.addJumpGuide(conditionId,"awakeJumpGuide")
            display.showDialog(HeroAwakeDialog.new({heroMsg=_info.hero}))
        end
    elseif conditionId == const.JumpTypeInten then
        display.showDialog(HeroMicDetailsDialog.new({initTag="image",heroMsg = _info.hero}))
    elseif conditionId == const.JumpTypeEquipDeve then
        if GameLogic.checkConditionUnlock(_info,conditionId) then
            GameLogic.addJumpGuide(conditionId,"heroJumpEquipDeve")
            display.showDialog(EquipDialog.new({}))
        end
    elseif conditionId == const.JumpTypeSuperWeapons then
        if GameLogic.checkResUnlock(_info.powerId) then
            GameLogic.addJumpGuide(conditionId,"heroJumpSuperWeapons")
            display.showDialog(WeaponUpgradeDialog.new({weaponIdx=_info.id%1000}))
        end
    elseif conditionId == const.JumpTypeGoldOre then
        local _hand = GameLogic.getUserContext().guideHand
        if not _hand.handArr["JumpGoldOre"] then
            if context.buildData:getBuild(13) then
               local _node = context.buildData:getBuild(13).vstate
               if _node.upNode then
                    _node.isJumpGuide = true
                    local view = context.buildData:getBuild(13).vstate.view
                    _hand:showArrow(_node.upNode,view:getContentSize().width/2,view:getContentSize().height+40,0,"JumpGoldOre")
               end
            end
        end
        display.closeDialog(0)
    elseif conditionId==const.JumpTypeArenaBox then
        GameLogic.getUserContext().arena:initData(function ()
            StoreDialog.new({stype="honor"})
        end)
    elseif conditionId==const.ActTypeMobai then
        AllRankingListDialog.new(10)
    elseif conditionId >= 1200 and conditionId < 1500 then
        display.showDialog(HeroMainDialog.new()) --{initTag="extract"}
    elseif conditionId == const.JumTypeTalentMatch then--达人赛
        display.sendIntent({class="game.Dialog.TalentMatchDialog"})
    end
end

-- 所有活动的跳转动作走这里
function GameLogic.doCondition(context, conditionId, info, actId)
    local _info = info or nil
    if conditionId == const.ActTypeBuyAll or conditionId == const.ActTypeLeagueMC or conditionId == const.ActTypePurchase or conditionId == const.ActTypePurchaseSingle or conditionId == const.ActTypeMC then
        StoreDialog.new(1)
    elseif conditionId == const.ActTypePVC then
        if GameLogic.checkResUnlock(const.ItemRes,const.ActTypePVC) then
            display.showDialog(ArenaDialog.new())
        else
            display.pushNotice(Localizef("noticeBuilderNotEnough",{name = Localize("titleArenaMain")}))
        end
    elseif conditionId == const.ActTypePVE or conditionId == const.ActTypePVP or conditionId == const.ActTypePVT or conditionId==const.ActTypePVPGold then
        display.showDialog(PlayInterfaceDialog.new())
    elseif conditionId == const.ActTypePVLE or conditionId == const.BattleTypeUPve then
        if context.union then
            UnionMapDialog.new()
        else
            display.pushNotice(Localize("stringNotJoin"))
        end
    elseif conditionId == const.ActTypeKnockDivide then
        local KnockMatchData = GMethod.loadScript("game.GameLogic.KnockMatchData")
        KnockMatchData:initData()
    elseif conditionId == const.BattleTypeUPvp then
            GameLogic.unionBattle()
    elseif conditionId == const.ActTypeSignIn then    -- 每日签到
            SignRewardDialog.new()
    elseif conditionId == const.ActTypePVH then   --英雄远征
        local b = context.buildData:getBuild(4)
        if b then
            b:showPvhDialog()
        else
           display.pushNotice(StringManager.getFormatString("noticeBuilderNotEnough", {name=BU.getBuildName(const.WeaponBase)}))
        end
    elseif conditionId == const.ActTypePVJ then  --僵尸来袭
        if not GameLogic.checkResUnlock(const.ItemEquip) then
            display.pushNotice(StringManager.getFormatString("noticeBuilderNotEnough", {name=BU.getBuildName(const.EquipBase)}))
            return
        end
        zombieIncomingDialog.new()
    elseif conditionId == const.ActTypeHuanSpecial then  -- 黑晶对酒
        BeercupDialog.new({rtype=const.ResSpecial})
    elseif conditionId == const.ActTypeHuanZhanhun then   --勋章对酒
        BeercupDialog.new({rtype=const.ResZhanhun})
    elseif conditionId == const.ActTypeFeedPet then       --喂养神兽
        if not context.union then
            display.pushNotice(Localize("stringNotJoin"))
            return
        end
        display.showDialog(UnionPetsDialog.new({context=context, pets=context.unionPets, initTag="info"}))
    elseif conditionId == const.ActTypeWishGet or (conditionId%10000 == const.ActTypeHeroGet) then        -- 英雄抽卡
        display.showDialog(HeroMainDialog.new({initTag="extract"}))
    elseif conditionId == const.ActTypeGoldChange then      --炼金
        if not context.buildData:getBuild(const.Alchemy) then
            display.pushNotice(StringManager.getFormatString("noticeBuilderNotEnough", {name=BU.getBuildName(const.Alchemy)}))
            return
        end
        MeltingDialog.new()
    elseif conditionId == const.ActTypeSuperWeapons then     --超级武器研究
        if not GameLogic.checkConditionUnlock({},conditionId) then
            display.pushNotice(StringManager.getFormatString("noticeBuilderNotEnough", {name=BU.getBuildName(const.WeaponBase)}))
            return
        end
        display.showDialog(WeaponUpgradeDialog.new())
    elseif conditionId == const.ActTypeHeroEqLevelUp then     --装备升级
        display.showDialog(HeroMainDialog.new({initTag="storage",curIdx=2}))
    elseif conditionId == const.ActTypeGiveMC then    -- 赠送联盟月卡，跳转到我的联盟界面
        if context.union then
            UnionInfoDialog.new()
        else
            display.pushNotice(Localize("stringNotJoin"))
        end
    elseif conditionId == const.ActTypeMobai then
        AllRankingListDialog.new(10)
    elseif (conditionId >= 1200 and conditionId < 1500) or (conditionId >= 1014 and conditionId < 1021) or conditionId==1023 then
        display.showDialog(HeroMainDialog.new()) --{initTag="extract"}
    elseif (conditionId%10000 == const.ActTypeHeroAuto) or(conditionId%10000 == const.ActTypeHeroStarUp) or(conditionId%10000 == const.ActTypeHeroLevelUp) or (conditionId%10000 == const.ActTypeHeroAwake) or (conditionId%10000 == const.ActTypeMercenaryLevels) then
        --指定英雄的觉醒、升级、升星还有佣兵升级
        display.showDialog(HeroMainDialog.new())
    elseif conditionId == const.ActTypeHunXia then
        --魂匣抽取（前两个不算）
        display.showDialog(HeroMainDialog.new({initTag="extract"}))
    elseif conditionId == const.ActTypeShareInfo then
        if actId and actId == 201712071 then--长线分享游戏分享
            GameLogic.addStatLog(11609, GameLogic.getLanguageType(), 1, 1)
        end
        GameLogic.doShare("code")
    elseif math.floor(conditionId/10000) == const.ActTypeHeroInfoNew then--英雄预告类活动跳转图鉴英雄详细信息界面(示例:10634032)
        local hero = GameLogic.getUserContext().heroData:makeHero(conditionId%10000)
        display.showDialog(HeroInfoNewDialog.new({hero=hero}))
    end
end

function GameLogic.checkConditionCanGo(conditionId)
    if conditionId ~= const.ActTypeCrystal then
        return true
    end
end

-- 所有活动跳转逻辑都走这里
function GameLogic.doActAction(context, actId, rwdIdx, fromGeneralDialog, params)
    local state = context.activeData:checkActRewardState(actId, rwdIdx)
    local myRwd = context.activeData:getConfigableRwds(actId, rwdIdx)
    if state == GameLogic.States.Close then
        if myRwd.atype == 3 then
            display.pushNotice(Localize("labelExNotEnough"))
            return
        end
        display.pushNotice(Localize("activeTimeOver"))
        return
    end
    if state == GameLogic.States.Finished then
        if not GameNetwork.lockRequest() then
            return
        end
        if actId == 201712071 then--长线分享游戏领奖
            GameLogic.addStatLog(11610, GameLogic.getLanguageType(), 1, 1)
        end
        GameNetwork.request("actrwds", {actId=actId, rwdIdx=rwdIdx, rtime=GameLogic.getSTime()}, GameLogic.onReceivedActRwd, context)
    -- 充值固定类型必须用特殊的方式
    elseif myRwd.atype == 2 then
        if fromGeneralDialog then
            if GameLogic.purchaseLock then
                display.pushNotice(Localize("noticePaying"))
                return
            end
            if GameLogic.getUserContext().activeData:checkPurchaseLimit(actId, rwdIdx) then
                display.pushNotice(Localize("noticePrebuyFail1"))
                return
            end
            fromGeneralDialog:onTreasureAction(rwdIdx)
        end
    -- 花费钻石购买道具，同样必须用特殊方式
    elseif myRwd.atype == 3 then
        if not myRwd.isLottery then
            for k,v in pairs(myRwd.costs) do
                if GameLogic.getItemNum(v[1], v[2]) < v[3] then
                    if v[1] == const.ItemRes and v[2] ~= const.ProEventMoney then
                        local max = context:getResMax(v[2])
                        if max>0 and v[3]>max then
                            local bid = const.GoldStorage
                            display.pushNotice(StringManager.getFormatString("noticeStorageFull", {name=BU.getBuildName(bid)}))
                        else
                            local dialog = AlertDialog.new({ctype=v[2], cvalue=v[3], callback=Handler(GameLogic.doActAction, context, actId, rwdIdx, fromGeneralDialog)})
                            if not dialog.deleted then
                                display.showDialog(dialog)
                            end
                        end
                    else
                        display.pushNotice(Localize("CannotExchange"))
                    end
                    return
                end
            end
        end
        local num = 1
        if params then
            num = params.num
        end
        if not myRwd.isLottery and (not params or not params.force) and myRwd.costs[1][1] == const.ItemRes and myRwd.costs[1][2] == const.ResCrystal then
            if myRwd.items[1] and (myRwd.items[1][1] ~= const.ItemRes or myRwd.items[1][2] ~= const.ResCrystal) then
                if not params then
                    params = {force=true}
                else
                    params.force = true
                end
                display.showDialog(AlertDialog.new(1, Localize("alertTitleNormal"), Localize("alertTextBuyGift"),
                    {cvalue = myRwd.costs[1][3],ctype = myRwd.costs[1][2],
                    callback = Handler(GameLogic.doActAction, context, actId, rwdIdx, fromGeneralDialog or false, params)
                }))
                return
            end
        end
        if not GameNetwork.lockRequest() then
            return
        end
        GameNetwork.request("actrwds", {actId=actId, num = num,rwdIdx=rwdIdx, rtime=GameLogic.getSTime()}, GameLogic.onReceivedActRwd, context)
    -- 说明该类型任务是自动计数完成的，例如登录、终极彩蛋等
    elseif myRwd.atype == 4 then
        if type(fromGeneralDialog) == "table" then
            display.closeDialog(fromGeneralDialog.priority)
        end
    elseif myRwd.atype == 5 then
        local num
        if params then
            num = params.num
        end

        local boxNum = context.activeData:getSpecialNum(actId, myRwd)
        if (num or 1) <= boxNum then
            num = num or 1
        else
            GameLogic.doCondition(context, myRwd.conditions[1][1])
            return
        end

        if not GameNetwork.lockRequest() then
            return
        end
        GameUI.setLoadingShow("loading", false, 0)
        GameNetwork.request("actrwds", {actId=actId, num = num, rwdIdx=rwdIdx, rtime=GameLogic.getSTime()}, GameLogic.onReceivedActRwd, context)
    elseif myRwd.atype == 6 then --分享
        local callback = function ()
            GameLogic.getUserContext().activeData:finishActCondition(myRwd.conditions[1][1], 1)
            GameLogic.getUserContext():addCmd({const.CmdActStat, myRwd.conditions[1][1], GameLogic.getSTime(), 1})

            GameEvent.sendEvent("refreshEggDialog", {"shareOver"})
        end
        local shareData = myRwd.shareData
        if shareData then
            local shareParams = {}
            shareParams.image = shareData.image and Localize(shareData.image)
            shareParams.url = shareData.url and Localize(shareData.url)
            shareParams.callback = callback
            Plugins:share(shareParams)
            -- callback()
        end
    else
        local conditionId = myRwd.conditions[1][1]
        GameLogic.doCondition(context, conditionId)
    end
end

function GameLogic.isEmptyTable(table)
    return table == nil or next(table) == nil
end

function GameLogic.keepOnline()
    if not GameLogic.lastNetworkTime then
        GameLogic.lastNetworkTime = GameLogic.getSTime()
    end
end

function GameLogic.checkResUnlock(resType, resId)
    local context = GameLogic.getUserContext()
    if resType == const.ItemRes then
        if resId == const.ResMagic then
            return context.buildData:getMaxLevel(const.WeaponBase) >= 1
        elseif resId ==  const.ResGXun then
            if context.union and context.buildData:getMaxLevel(const.Union) >= 1 then
                return true
            else
                return false
            end
        elseif resId == const.ResTrials then
            --8级解锁,英雄试炼--试炼币
            return context.buildData:getMaxLevel(const.Town) >= 8
        elseif resId == const.ActTypePVC then
            return context.buildData:getMaxLevel(const.ArenaBase) >= 1
        end
    else
        if resType == const.ItemEquip then
            return context.buildData:getMaxLevel(const.EquipBase) >= 1
        end
        if resId == const.JumpTypeOrb then
            return context:getRes(const.ResPBead)>0 and true or false
        end
    end
    return true
end

function GameLogic.checkConditionUnlock(obj,conditionId)
    --确定conditionId在哪里可以找到对应的是否解锁
    local context = GameLogic.getUserContext()
    local _info = obj
    if next(_info) then
        if conditionId == const.ActTypeHeroInten then
            if (not _info.info.notStreng or _info.info.notStreng > 0)and _info.info.job>0 and _info.info.color>=4 and context.buildData:getMaxLevel(const.Town)>=const.HeroTrialLimit then
                return true
            else
                return false
            end
        end
        -- elseif conditionId == const.JumpTypeWake then
        --     if _info["hero"]["info"] and _info["hero"]["info"].awake > 0 then
        --         return true
        --     end
        -- elseif conditionId == const.JumpTypeEquipDeve then
        --     if _info["hero"]["info"] and _info["hero"]["info"].job then
        --         return true
        --     end
        -- end
    else
        if conditionId == const.ActTypeSuperWeapons or conditionId == const.ActTypePVH then
            return context.buildData:getMaxLevel(const.WeaponBase) >= 1
        elseif conditionId == const.ActTypeHeroEqLevelUp then
            return context.buildData:getMaxLevel(const.EquipBase) >= 1
        elseif conditionId == const.JumpTypeGoldStore then
            return context:getRes(const.ResGold) >= context:getResMax(const.ResGold)
        end
    end

    return true
end

function GameLogic.getConditionProgress(obj,type,maxType)
    local _object = obj
    if _object then
        return  _object[type],_object[maxType]
    end
    return 0,0
end

GameLogic.States = {Close=3, NotOpen=0, Open=1, Finished=2}

GEngine.export("const",const)
GEngine.export("GameLogic",GameLogic)
GEngine.export("LG",GameLogic)

function GameLogic.push()
    -- 文本还没配
    local context = GameLogic.getUserContext()
    if not context then
        return
    end
    --这里把所有推送都清空了一遍
    Native:clearLocalNotification()
    local code = context:getInfoItem(const.InfoPush)
    local tab = GameLogic.dnumber(code,const.pushNum)
    --建筑建造/升级完成,id=4
    local key = 4
    --开启推送的状态
    if tab[key] == 1 then
        for k,v in pairs(context.buildData:getBuildWorkList()) do
            local build = context.buildData.bbuilds[k]
            local duration = v[4]-GameLogic.getSTime()
            local content = Localizef("dataPushContent"..key,{b=BU.getBuildName(build[1])})
            Native:postNotification(duration,content)
        end
    end
    --保护盾时间结束,id=5
    key = 5
    if tab[key] == 1 then
        if context.enterData.ustate[1] > GameLogic.getSTime() then
            local duration = context.enterData.ustate[1]-GameLogic.getSTime()
            local content = Localize("dataPushContent"..key)
            Native:postNotification(duration,content)
        end
    end
    --僵尸来袭行动力满,id=6
    key = 6
    local pvjData=GameLogic.getUserContext().pvj
    if pvjData then
        GEngine.setConfig("pushPvjNeed",json.encode({pvjData.ctime,pvjData.actnum}),true)
    end
    if tab[key] == 1 then
        local info = json.decode(GEngine.getConfig("pushPvjNeed"))
        if info then
            local duration = 1
            local t = GameLogic.getSTime() - (info[1] or 0)
            local actnum = math.floor(t/360+(info[2] or 0))
            duration = (240 - actnum)*360
            if duration > 0 then
                local content = Localize("dataPushContent"..key)
                Native:postNotification(duration,content)
            end
        end
    end
    --闯关挑战次数满,id=7
    key = 7
    if tab[key] == 1 then
        if context.pvpChance.initTime+86400 > GameLogic.getSTime() then
            local duration = context.pvpChance.initTime+86400-GameLogic.getSTime()
            local content = Localize("dataPushContent"..key)
            Native:postNotification(duration,content)
        end
    end
    --竞技场挑战次数满.id=8
    key = 8
    if tab[key] == 1 then
        local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffPVC)
        local arena = GameLogic.getUserContext().arena
        local num = 5 - arena:getCurrentChance()+buffInfo[4]-buffInfo[5]
        if num >0 then
            local duration = GameLogic.getSTime()-arena:getHonorInfos().lastChallengeTime
            if duration>0 then
               duration = 7200-duration%7200
               duration = duration+(num-1)*7200
            else
               duration = duration+num*7200
            end
            local content = Localize("dataPushContent"..key)
            Native:postNotification(duration,content)
        end
    end
    if GameLogic.useTalentMatch then
        --首冲推送
        local stime = GameLogic.getSTime()
        local active = context.activeData
        local data = active.dhActive[51]
        local isReceive = (data and data[3]>=1 or false)
        if not isReceive then
            local timeparams1 = GameLogic.getUserContext():getInfoItem(const.InfoRegTime)
            --注册时间
            local duration = timeparams1 + 86400 - stime
            if duration>0 then
                Native:postNotification(duration, Localize("dataPushName100"))
            end
        end
        --月卡
        local act = GameLogic.getUserContext().activeData:getConfigableActs()
        for k,v in pairs(act) do
            if v.actTemplate == "monthCard" then
                if ActivityLogic.checkActVisible(v) then
                    local duration = v.actStartTime + 43200 - stime
                    if duration > 0 then
                        Native:postNotification(duration, Localize("dataPushName101"))
                    end
                    duration = duration + 43200
                    if duration > 0 then
                        Native:postNotification(duration, Localize("dataPushName102"))
                    end
                end
            elseif v.pushKey and v.actRollTime and v.actRollMax then
                local nextPushTime = v.actStartTime
                if nextPushTime < stime then
                    nextPushTime = nextPushTime + math.floor((stime-nextPushTime)/v.actRollTime + 1) * v.actRollTime
                    if nextPushTime > v.actRollMax then
                        nextPushTime = 0
                    end
                end
                if nextPushTime > stime then
                    Native:postNotification(nextPushTime - stime, Localize(v.pushKey))
                end
            end
        end
        -- 推送
        local GameSetting = GMethod.loadScript("game.GameSetting")
        local pushDup = {}
        for aid=101, 106 do
            local matchInfo = context.talentMatch:getMatchInfo(aid, stime)
            if matchInfo.stime <= stime then
                matchInfo = context.talentMatch:getMatchInfo(aid, matchInfo.etime + 10*60)
            end
            -- 超时太多不予预约防BUG
            if matchInfo.stime > stime and matchInfo.stime - stime < 14*86400 then
                if not pushDup[matchInfo.stime] then
                    pushDup[matchInfo.stime] = 1
                    Native:postNotification(matchInfo.stime - stime, Localize("dataPushName200"))
                end
            end
            if aid <= 104 then
                local sdata = GameSetting.getLocalData(context.uid, "PreMatchInfo" .. aid) or {}
                if sdata[1] and sdata[1] + 10*60 > stime and sdata[1] + 10*60 < stime+14*86400 then
                    if not pushDup[sdata[1] + 10*60] then
                        pushDup[sdata[1] + 10*60] = 1
                        Native:postNotification(sdata[1] + 10*60 - stime, Localize("dataPushName201"))
                    end
                end
            end
        end
    end
    --这里是加了长期没登录游戏就发推送24,72,168
    local tip = Localize("dataPushContent20")
    local pushTime = 86400*1
    Native:postNotification(pushTime,tip)

    pushTime = 86400*3
    tip = Localize("dataPushContent21")
    Native:postNotification(pushTime,tip)

    pushTime = 86400*7
    tip = Localize("dataPushContent22")
    Native:postNotification(pushTime,tip)

end

function GameLogic.addJumpGuide(condition,key)
    if not GameLogic.guideArr then
        GameLogic.guideArr={}
    end

    GameLogic.guideArr[condition]=key
end

function GameLogic.getJumpGuide(condition,bgNode,px,py)
    if GameLogic.guideArr and GameLogic.guideArr[condition] and bgNode then
        local key = GameLogic.guideArr[condition]
        GameLogic.getUserContext().guideHand:showArrow(bgNode,px or 0,py or 20,0,key)
        return true
    end
    return
end



function GameLogic.removeJumpGuide(condition)
    if GameLogic.guideArr and GameLogic.guideArr[condition] then
        local key = GameLogic.guideArr[condition]
        GameLogic.getUserContext().guideHand:removeHand(key)
        GameLogic.guideArr[condition] = nil
    end
    return
end

function GameLogic.urlencode(params)
    local ret = {}
    local isFirst = true
    local c, l, n
    for k, v in pairs(params) do
        if not isFirst then
            table.insert(ret, "&")
        else
            isFirst = false
        end
        table.insert(ret, k)
        table.insert(ret, "=")
        v = tostring(v)
        l = v:len()
        for i=1, l do
            c = v:byte(i)
            if c >= 48 and c <= 57 or c >= 65 and c <= 90 or c >= 97 and c <= 122 then
                table.insert(ret, string.char(c))
            elseif c >= 45 and c <= 46 or c == 95 or c == 126 then
                table.insert(ret, string.char(c))
            else
                table.insert(ret, "%25")
                n = math.floor(c/16)
                if n < 10 then
                    table.insert(ret, string.char(48+n))
                else
                    table.insert(ret, string.char(55+n))
                end
                n = c % 16
                if n < 10 then
                    table.insert(ret, string.char(48+n))
                else
                    table.insert(ret, string.char(55+n))
                end
            end
        end
    end
    return table.concat(ret)
end

function GameLogic.showHeroRewsUieffect(data)
    -- body
    local context = GameLogic.getUserContext()
    local info = data or {}
    if info then
        for _, reward in KTIPairs(info) do
            --dump(reward)
            if reward[1]==const.ItemHero then
                if type(reward[3]) == "table" then
                    for _, idx in KTIPairs(reward[3]) do
                        if idx>0 then
                            local _hero = context.heroData:makeHero(reward[2])
                            if _hero.info.rating >=3 then
                                NewShowHeroDialog.new({rhero=_hero,shareIdx = _hero.info.rating})
                            end
                            break
                        end
                    end
                else
                    if reward[3]>0 then
                        local _hero = context.heroData:makeHero(reward[2])
                        --dump(_hero)
                        if _hero.info.rating >=3 then
                            NewShowHeroDialog.new({rhero=_hero,shareIdx = _hero.info.rating})
                        end
                        break
                    end
                end
            end
        end
    end
end

function GameLogic.getPrestigeRedNum()
    local _pData = SData.getData("popunlock")
    local _pNum = GameLogic.getUserContext():getProperty(const.ProPopular) or 0
    local _mask = GameLogic.getUserContext():getProperty(const.ProPopUnlockMask1)
    local _num = 0
    for k = const.FreePopIdx + 1,#_pData do
        local _mm = 1
        _mm = bit.band(_mask,bit.lshift(1,k-const.FreePopIdx-1))
        if _pData[k] and (_pData[k].pNum <= _pNum and _mm==0) then
            _num = _num + 1
        end
    end
    return _num
end

do
    local _encodeString = "abcdefghjkmnpqrstuvwxyz23456789"
    local _encodeString2 = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"
    local _decodeMap = {}
    local _elen = _encodeString:len()
    for i=1, _elen do
        _decodeMap[_encodeString:sub(i,i)] = i-1
        _decodeMap[_encodeString2:sub(i,i)] = i-1
    end
    -- @brief 获取推广码字符串
    function GameLogic.getTCodeString()
        local tnum = GameLogic.getUserContext().uid
        local tb = {}
        local tidx = 0
        while tidx < 6 do
            tidx = tidx + 1
            local tmod = tnum % _elen
            tb[tidx] = _encodeString2:sub(tmod+1, tmod+1)
            tnum = (tnum - tmod) / _elen
        end
        return table.concat(tb)
    end

    -- @brief 获取推广码数字
    function GameLogic.getTCodeNumber(tstr)
        if not tstr or tstr:len() < 6 then
            return
        end
        local tnum = tonumber(tstr)
        if tnum and tnum >= 100000000 then
            return false, tnum
        end
        tnum = 0
        local tmode = 1
        for i=1, 6 do
            local c = tstr:sub(i, i)
            if not _decodeMap[c] then
                return
            end
            tnum = tnum + _decodeMap[c] * tmode
            tmode = tmode * _elen
        end
        return true, tnum
    end
end

function GameLogic.getSpreadAndRewardData()
    local spreadCodeRewards = SData.getData("spreadCodeRewards")
    --获取各个等级的可领取的礼包数
    local lvs = {}
    local havePacks={}
    local _list = GameLogic.CacheSplitData() or {}
    for k,v in pairs(spreadCodeRewards) do
        local key = k
        if k>0 then
            table.insert(lvs,key)
            if not havePacks[key] then
                havePacks[key]=0
            end
            for i,v in ipairs(_list) do
                if v[3]>= key then
                    havePacks[key]=havePacks[key]+1
                end
            end
        end
    end
    table.sort(lvs, function(a, b)
        return a < b
    end)
    local infos = {}
    local idx = const.ProCodeState
    for i,k in ipairs(lvs) do
        local v = spreadCodeRewards[k]
        idx = const.ProCodeState + k
        infos[i] = {id = i,awd = v, constIdx=idx, townLv=k}
        infos[i].getedPackNum = GameLogic.getUserContext():getProperty(idx) or 0
        infos[i].havePack = havePacks[k] or 0
    end
    return infos
end

function GameLogic.CacheGemPoolData(data)
    if data then
        GameLogic.getUserContext().gemCrystalNum = data
    else
        return GameLogic.getUserContext().gemCrystalNum or 0
    end
end

function GameLogic.CacheSplitData(data)
    -- body
    if data then
        GameLogic.getUserContext().splitData = data
    else
        return GameLogic.getUserContext().splitData or {}
    end
end

function GameLogic.getSpreadAndRewardRedNum()
    local redNum = 0
    local infos = GameLogic:getSpreadAndRewardData()
    for k,v in ipairs(infos) do
        local num = v.awd.maxNum - v.getedPackNum
        if num<=0 then
           redNum = 0
        elseif v.getedPackNum>=(v.havePack or v.awd.maxNum) then
            redNum = 0
        else
            redNum = 1
            break
        end
    end
    if redNum == 0 then
        redNum = 0
        local num = GameLogic.CacheGemPoolData()
        if num>0 then
            redNum = 1
        end
    end
    return redNum
end

function GameLogic.getMonthCardData()
    -- body
    local context = GameLogic.getUserContext()
    local limitActive = context.activeData.limitActive
    local infos = {}
    for k, act in pairs(limitActive) do
        if k == 4 then
           local item = {atype = k, aid = 1,gnum = 0,anum = 10,isget = 0,time = act[2]-GameLogic.getTime()}
           table.insert(infos,{item = item, _order=k})
           break
        end
    end

    local dailyData = context.activeData.dailyData
    for k,v in pairs(dailyData) do
        if v.atype == 4 then
            local _order = k
            if v.isget > 0 then
               _order = 1000+k
            end
            table.insert(infos,{_order=_order,item=v})
        end
    end
    return infos
end

function GameLogic.getVipRedNum()
    -- body
    local num = GameLogic.getUserContext():getProperty(const.ProBuyVipPkg1)
    return num
end

function GameLogic.statForSnowfish(ename, eparams)
    if not (Plugins.singleSdk and Plugins.singleSdk:checkPluginFunc(3)) then
        return
    end
    local statTable = {}
    statTable.callKey = 101
    statTable.eventName = ename
    if not eparams then
        eparams = {}
    end
    local ucontext = GameLogic.getUserContext()
    eparams.roleId = tostring(ucontext.uid)
    eparams.roleName = GameLogic.doSaveEncode(ucontext:getInfoItem(const.InfoName))
    eparams.roleLevel = tostring(ucontext:getInfoItem(const.InfoLevel))
    eparams.zoneId = tostring(ucontext.sid)
    eparams.zoneName = Localize("dataServerName" .. ucontext.sid)
    eparams.balance = tostring(ucontext:getRes(const.ResCrystal))
    eparams.vip = tostring(ucontext:getInfoItem(const.InfoVIPlv))
    eparams.partyName = (ucontext.union and ucontext.union.name or "无联盟")
    eparams.roleCTime = tostring(ucontext:getInfoItem(const.InfoRegTime))
    statTable.eventParams = json.encode(eparams)

    Plugins.singleSdk:sendCommand(-1, 3, json.encode(statTable))
end

function GameLogic.doFollowAction()
    local context = GameLogic.getUserContext()
    GameLogic.addStatLog(12002, 1, 0, 0)
    Plugins:openUrl("https://www.facebook.com/ZombiesClashII")
    if context:getProperty(const.ProFBFollow) ~= 1 then
        context:addCmd({const.CmdFollowUs})
        context:setProperty(const.ProFBFollow,1)
        local rewards={{const.ItemRes, const.ResCrystal, 100}}
        GameLogic.addRewards(rewards)
        GameLogic.statCrystalRewards("关注Facebook奖励",rewards)
        display.pushNotice(Localizef("labelGetFacebookRwd",{num = rewards[1][3]}))
    end
end

-- @brief 跳转漫画逻辑
-- @params comicId 漫画ID，无则是总的
function GameLogic.doComicJump(comicId)
    if not cc.FileUtils:getInstance():isFileExist("images/comic11back.png") then
        if cc.FileUtils:getInstance():isFileExist("comic.pkg") then
            GEngine.engine:getPackageManager():loadPackage("comic.pkg")
            return GameLogic.doComicJump(comicId)
        end
        local dialog = AlertDialog.new(const.AlertDownload, Localize("alertTitleNormal"),
            {"comic.pkg", "http://coz1vn.moyuplay.com/comic.pkg", 2565076, "1ac6ab9d51d79256588c934e4682f7c0"},
            {callback=Handler(GameLogic.doComicJump, comicId), noCloseBut=true})
        display.showDialog(dialog)
        return
    end
    if comicId then
        display.showDialog(ComicDialog.new(comicId))
    else
        CartoonDialog.new()
    end
end

do
    -- @brief 安全的encode方式
    function GameLogic.doSaveEncode(s)
        local cs = {}
        local a, b, c, d
        local value
        local i, l = 1, s:len()
        local il = 0
        while i <= l do
            a = s:byte(i)
            b = s:byte(i+1) or 0
            c = s:byte(i+2) or 0
            d = s:byte(i+3) or 0
            if a <= 0x7f then
                value = a
                il = 1
            elseif 0xc0 <= a and a <= 0xdf and b >= 0x80 then
                value = (a - 0xc0) * 0x40 + b - 0x80
                il = 2
            elseif 0xe0 <= a and a <= 0xef and b >= 0x80 and c >= 0x80 then
                value = ((a - 0xe0) * 0x40 + b - 0x80) * 0x40 + c - 0x80
                il = 3
            elseif 0xf0 <= a and a <= 0xf7 and b >= 0x80 and c >= 0x80 and d >= 0x80 then
                value = (((a - 0xf0) * 0x40 + b - 0x80) * 0x40 + c - 0x80) * 0x40 + d - 0x80
                il = 4
            else
                value = 0
                il = 1
            end
            if value > 0 then
                if value <= 0xffff then
                    table.insert(cs, s:sub(i, i+il-1))
                elseif value <= 0x10ffff then
                    -- encode as UTF-16 surrogate pair
                    value = value - 0x10000
                    local highsur, lowsur = 0xD800 + math.floor (value/0x400), 0xDC00 + (value % 0x400)
                    table.insert(cs, string.format ("\\u%.4x\\u%.4x", highsur, lowsur))
                end
            end
            i = i + il
        end
        return table.concat(cs, "")
    end
end

do
    -- @brief 评分活动有关逻辑
    -- @params checkType 检查类型
    -- @params checkParams 检查类型有关参数
    -- @params callback 评论完回调
    function GameLogic.doRateGuide(checkType, checkParams, callback)
        local context = GameLogic.getUserContext()
        if context.activeData:isInRateAct(checkType, checkParams) then
            local isIos = false
            local pm = GEngine.getPlatform()
            if pm ~= cc.PLATFORM_OS_ANDROID then
                isIos = true
            end
            if isIos and Native.showLocalRate then
                -- 如果是苹果且调用自动评分可以成功的话
                Native:showLocalRate()
                local pinfo = GEngine.getConfig("localRate")
                if pinfo then
                    pinfo = json.decode(pinfo)
                end
                if not pinfo then
                    pinfo = {t=GameLogic.getSTime(), n=1}
                else
                    pinfo.t = GameLogic.getSTime()
                    pinfo.n = (pinfo.n or 0)+1
                end
                GEngine.setConfig("localRate", json.encode(pinfo), true)
                GEngine.saveConfig()
                if callback then
                    callback()
                end
                return
            end
            -- 给老版本苹果做个链接修补
            if isIos and GEngine.rawConfig.purpleUrl == "" and
                GEngine.rawConfig.channel:find("com.bettergame.heroclash") then
                GEngine.rawConfig.purpleUrl = "itms-apps://itunes.apple.com/app/id1168563046"
            end
            -- 如果有评分链接或有默认链接的话
            if GEngine.rawConfig.purpleUrl and GEngine.rawConfig.purpleUrl ~= "" then
                EvaluateDialog.new({checkType=checkType, callback=callback})
                return
            end
        end
        if callback then
            callback()
        end
    end

    function GameLogic.doRateAction(useIosSpecial)
        local isIos = false
        local pm = GEngine.getPlatform()
        if pm ~= cc.PLATFORM_OS_ANDROID then
            isIos = true
        end
        if useIosSpecial and isIos and Native.showLocalRate then
            if GameLogic.getUserContext():getInfoItem(const.InfoLevel) <= 30 then
                -- 如果是苹果且调用自动评分可以成功的话
                GameLogic.getUserContext().lockRate = GameLogic.getSTime() + 10
                Native:showLocalRate()
                return
            end
        end
        -- 给老版本苹果做个链接修补
        if isIos and GEngine.rawConfig.purpleUrl == "" and
            GEngine.rawConfig.channel:find("com.bettergame.heroclash") then
            GEngine.rawConfig.purpleUrl = "itms-apps://itunes.apple.com/app/id1168563046"
        end
        local url = GEngine.rawConfig.purpleUrl
        -- 苹果链接中可以直接追加后缀参数
        if url:find("itms-apps") then
            if url:find("?") then
                url = url .. "&action=write-review"
            else
                url = url .. "?action=write-review"
            end
        end
        if url and url ~= "" then
            Native:openURL(url)
        end
    end
end

do
    -- 推广码图片
    local function _saveSpreadCodeImage()
        local cf = cc.FileUtils:getInstance()
        local filePath = "fbShareImgSpread.jpg"
        if cf:isFileExist(cf:getWritablePath() .. filePath) then
            cf:removeFile(cf:getWritablePath() .. filePath)
        end
        local render = cc.RenderTexture:create(900, 472)
        local bg = ui.node()
        local spriteName
        if General.language~="CN" and General.language ~= "HK" and General.language ~= "EN" then
            spriteName="images/fbshareEN.png"
        else
            spriteName="images/fbshare"..General.language..".png"
            if General.language == "HK" and not cf:isFileExist(spriteName) then
                spriteName="images/fbshareCN.png"
            end
        end
        local temp
        local useNew = false
        local channel = string.gsub(GEngine.rawConfig.channel, "(.-)%d*$", "%1")
        if cf:isFileExist("images/shares/fbShareSpringBg.png") and (channel == "com.bettergame.heroclash_our"
            or channel == "com.bettergame.heroclash_ios" or channel == "com.bettergame.heroclash_google") then
            useNew = true
            temp = ui.sprite("images/shares/fbShareSpringBg.png")
            display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            GameUI.addLogo(bg, 0.3, 4, 472, GConst.Anchor.LeftTop)
            local ox, oy, ox2 = 0, 14, 0
            temp = ui.sprite("images/shares/fbOur2DCodeSpring.png")
            display.adapt(temp, 900, 0, GConst.Anchor.RightBottom)
            bg:addChild(temp)
            ox = 0
            ox2 = 53
            if cf:isFileExist("images/shares/fbShareAndroidNew.png") then
                temp = ui.sprite("images/shares/fbShareAndroidNew.png", {89, 27})
                display.adapt(temp, 4 + ox, 4, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
                ox = ox + 93
                oy = 28
            end
            if cf:isFileExist("images/shares/fbShareIosNew.png") then
                temp = ui.sprite("images/shares/fbShareIosNew.png", {89, 27})
                display.adapt(temp, 4 + ox, 4, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
                ox = ox + 93
                oy = 28
            end
            local lan = "EN"
            if General.language == "CN" or General.language == "HK" then
                lan = "CN"
            end
            temp = ui.sprite("images/shares/fbShareBanner" .. lan .. ".png")
            display.adapt(temp, 768, 0, GConst.Anchor.RightBottom)
            bg:addChild(temp)
            local name = GameLogic.getUserContext():getInfoItem(const.InfoName)
            temp = ui.label(name,General.font6,24,{color={0,0,0}})
            display.adapt(temp, 393+ox2, oy, GConst.Anchor.Center)
            bg:addChild(temp)
            local code = Localize("labelInviteCode")..":"..GameLogic.getTCodeString()
            temp = ui.label(code, General.font1, 24, {color={255,255,255}, fontW=184, fontH=37})
            display.adapt(temp, 590+ox2, oy, GConst.Anchor.Center)
            bg:addChild(temp)
        elseif cf:isFileExist("images/shares/fbShareBg.png") then
            useNew = true
            temp = ui.sprite("images/shares/fbShareBg.png")
            display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            GameUI.addLogo(bg, 0.3, 890, 10, GConst.Anchor.RightBottom)
            local ox, oy, ox2 = 0, 14, 0
            -- 自己版本用二维码
            if channel == "com.bettergame.heroclash_our" or channel == "com.bettergame.heroclash_ios"
                or channel == "com.bettergame.heroclash_google" then
                temp = ui.sprite("images/shares/fbOur2DCode.png")
                display.adapt(temp, 4, 4, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
                ox = 133
                ox2 = 133
            else
                -- 先空着好了？
            end
            -- 如果有内置google图
            if cf:isFileExist("images/fbShareNewGoogle.png") then
                temp = ui.sprite("images/fbShareNewGoogle.png", {89, 27})
                display.adapt(temp, 4 + ox, 4, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
                ox = ox + 93
                oy = 28
            end
            if cf:isFileExist("images/fbShareNewApple.png") then
                temp = ui.sprite("images/fbShareNewApple.png", {89, 27})
                display.adapt(temp, 4 + ox, 4, GConst.Anchor.LeftBottom)
                bg:addChild(temp)
                ox = ox + 93
                oy = 28
            end
            temp = ui.sprite("images/shares/fbShareBanner.png")
            display.adapt(temp, 4 + ox2, 4 + oy, GConst.Anchor.LeftBottom)
            bg:addChild(temp)

            local headId = GameLogic.getUserContext():getInfoItem(const.InfoHead)
            GameUI.addPlayHead(bg,{viplv=0,id=headId,scale=0.36,x=40+ox2,y=37+oy,z=1,blackBack = false})
            local name = GameLogic.getUserContext():getInfoItem(const.InfoName)
            temp = ui.label(name,General.font6,24,{color={0,0,0}})
            display.adapt(temp, 128+ox2, 34+oy, GConst.Anchor.Center)
            bg:addChild(temp)
            local code = Localize("labelInviteCode")..":"..GameLogic.getTCodeString()
            temp = ui.label(code, General.font1, 24, {color={255,255,255}, fontW=184, fontH=37})
            display.adapt(temp, 280+ox2, 34+oy, GConst.Anchor.Center)
            bg:addChild(temp)

            local lan = "EN"
            if General.language == "CN" or General.language == "HK" then
                lan = "CN"
            end
            temp = ui.sprite("images/shares/fbShareText" .. lan .. "1.png")
            display.adapt(temp, 4, 134, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            temp = ui.sprite("images/shares/fbShareText" .. lan .. "2.png")
            display.adapt(temp, 64+ox2, 84, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
        elseif cf:isFileExist(spriteName) then
            temp = ui.sprite(spriteName)
            display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
        else
            temp = ui.sprite("images/fbShareNewBase.png", {900, 472})
            display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
            bg:addChild(temp)
            -- 只能为Google/Apple/其他，加到右下角；否则统一添加google+apple
            if GEngine.rawConfig.shareChannel then
                spriteName = "images/fbShareNew" .. GEngine.rawConfig.shareChannel .. ".png"
                if cf:isFileExist(spriteName) then
                    temp = ui.sprite(spriteName)
                    display.adapt(temp, 893, 6, GConst.Anchor.RightBottom)
                    bg:addChild(temp)
                end
            else
                temp = ui.sprite("images/fbShareNewApple.png")
                display.adapt(temp, 893, 6, GConst.Anchor.RightBottom)
                bg:addChild(temp)
                temp = ui.sprite("images/fbShareNewGoogle.png")
                display.adapt(temp, 893, 44, GConst.Anchor.RightBottom)
                bg:addChild(temp)
            end
            -- 分享文字部分
            spriteName = "images/fbShareNew" .. General.language .. ".png"
            if not cf:isFileExist(spriteName) then
                spriteName = "images/fbShareNewEN.png"
            end
            temp = ui.sprite(spriteName)
            display.adapt(temp, 729, 298, GConst.Anchor.Top)
            bg:addChild(temp)
            GameUI.addLogo(bg, 0.23, 890, 467, GConst.Anchor.RightTop)
        end
        if not useNew then
            temp = ui.node({120,120})
            display.adapt(temp, 0, 0, GConst.Anchor.Center)
            bg:addChild(temp)
            local headId = GameLogic.getUserContext():getInfoItem(const.InfoHead)
            GameUI.addPlayHead(temp,{viplv=0,id=headId,scale=0.6,x=600,y=150,z=1,blackBack = false})

            local name = GameLogic.getUserContext():getInfoItem(const.InfoName)
            temp = ui.label(name,General.font5,30,{color={255,255,255}})
            display.adapt(temp,700,80,GConst.Anchor.Center)
            bg:addChild(temp)

            local code = Localize("labelInviteCode")..":"..GameLogic.getTCodeString()
            temp = ui.label(code,General.font5,30,{color={255,255,255}})
            display.adapt(temp,770,30,GConst.Anchor.Right)
            bg:addChild(temp)
        end

        render:begin()
        bg:visit()
        render:endToLua()
        render:saveToFile(filePath, cc.IMAGE_FORMAT_JPEG, false)

        return cf:getWritablePath() .. filePath
    end

    -- @brief 英雄/装备分享图
    local function _saveHeroImages(shareIdx, itemID)
        local cf = cc.FileUtils:getInstance()
        local filePath = "fbShareImgHero.jpg"
        if cf:isFileExist(cf:getWritablePath() .. filePath) then
            cf:removeFile(cf:getWritablePath() .. filePath)
        end
        local render = cc.RenderTexture:create(900, 472)
        local bg = ui.node()
        local spriteName
        local temp
        temp = ui.sprite("images/bgAct17101101.png", {931, 488})
        display.adapt(temp, -8, -4, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        if itemID < 3000 then
            GameUI.addEquipFeature(bg, itemID, 0.5, 220, 236)
        else
            GameUI.addHeroFeature(bg, itemID, 0.5, 220, 236, 0, true)
        end


        if cf:isFileExist("images/fbShareNewEN.png") then
            -- 只能为Google/Apple/其他，加到右下角；否则统一添加google+apple
            if GEngine.rawConfig.shareChannel then
                spriteName = "images/fbShareNew" .. GEngine.rawConfig.shareChannel .. ".png"
                if cf:isFileExist(spriteName) then
                    temp = ui.sprite(spriteName)
                    display.adapt(temp, 893, 6, GConst.Anchor.RightBottom)
                    bg:addChild(temp)
                end
            else
                temp = ui.sprite("images/fbShareNewApple.png")
                display.adapt(temp, 893, 6, GConst.Anchor.RightBottom)
                bg:addChild(temp)
                temp = ui.sprite("images/fbShareNewGoogle.png")
                display.adapt(temp, 893, 44, GConst.Anchor.RightBottom)
                bg:addChild(temp)
            end
            -- 分享文字部分
            spriteName = "images/fbShareNew" .. General.language .. ".png"
            if not cf:isFileExist(spriteName) then
                spriteName = "images/fbShareNewEN.png"
            end
            temp = ui.sprite(spriteName)
            display.adapt(temp, 729, 298, GConst.Anchor.Top)
            bg:addChild(temp)
        end
        GameUI.addLogo(bg, 0.23, 890, 467, GConst.Anchor.RightTop)
        temp = ui.node({120,120})
        display.adapt(temp, 0, 0, GConst.Anchor.Center)
        bg:addChild(temp)
        local headId = GameLogic.getUserContext():getInfoItem(const.InfoHead)
        GameUI.addPlayHead(temp,{viplv=0,id=headId,scale=0.6,x=600,y=150,z=1,blackBack = false})

        local name = GameLogic.getUserContext():getInfoItem(const.InfoName)
        temp = ui.label(name,General.font5,30,{color={255,255,255}})
        display.adapt(temp,700,80,GConst.Anchor.Center)
        bg:addChild(temp)

        local code = Localize("labelInviteCode")..":"..GameLogic.getTCodeString()
        temp = ui.label(code,General.font5,30,{color={255,255,255}})
        display.adapt(temp,770,30,GConst.Anchor.Right)
        bg:addChild(temp)

        render:begin()
        bg:visit()
        render:endToLua()
        render:saveToFile(filePath, cc.IMAGE_FORMAT_JPEG, false)

        return cf:getWritablePath() .. filePath
    end

    -- @brief 英雄/装备分享图
    local function _saveKnockImages(stage)
        local cf = cc.FileUtils:getInstance()
        local filePath = "fbShareImgKnock.jpg"
        if cf:isFileExist(cf:getWritablePath() .. filePath) then
            cf:removeFile(cf:getWritablePath() .. filePath)
        end
        local render = cc.RenderTexture:create(900, 507)
        local bg = ui.node()
        bg:setScale(900/1136)
        local spriteName
        local temp
        temp = ui.sprite("images/pvz/imgPvzShareBg.png")
        display.adapt(temp, 0, 0, GConst.Anchor.LeftBottom)
        bg:addChild(temp)

        local platform = GEngine.getPlatform()
        if platform == cc.PLATFORM_OS_ANDROID then
            spriteName = "images/pvz/imgPvzAndroid.png"
        else
            spriteName = "images/pvz/imgPvzIos.png"
        end
        local img_download = ui.sprite(spriteName)
        display.adapt(img_download, 102, 105, GConst.Anchor.Center)
        bg:addChild(img_download)

        spriteName = "images/pvz/imgPvzShare" .. stage .. "_EN.png"
        local img_stage = ui.sprite(spriteName)
        display.adapt(img_stage, 579, 445, GConst.Anchor.Center)
        bg:addChild(img_stage)

        temp = ui.label(Localize("labPvzShareTitle"),General.font1,36,{color={255,255,255}, fontW=250, fontH=50})
        display.adapt(temp, 983, 601, GConst.Anchor.Center)
        temp:setRotation(-1)
        bg:addChild(temp)

        --添加玩家信息
        local ucontext = GameLogic.getUserContext()
        local nd_ownHero = ui.node()
        nd_ownHero:setScale(0.5)
        display.adapt(nd_ownHero, 413, 244, GConst.Anchor.Center)
        bg:addChild(nd_ownHero)

        spriteName = "images/pvz/imgPvzPbrBg.png"
        temp = ui.sprite(spriteName, {500, 64})
        display.adapt(temp, 72, 58, GConst.Anchor.LeftBottom)
        nd_ownHero:addChild(temp)

        temp = ui.label(ucontext:getInfoItem(const.InfoName),
            General.font5, 40, {color={255,255,255}})
        display.adapt(temp, 360, 90, GConst.Anchor.Center)
        nd_ownHero:addChild(temp)

        local nd_head = ui.node()
        display.adapt(nd_head, 0, 2, GConst.Anchor.Center)
        nd_ownHero:addChild(nd_head)

        local nd_ownHead = ui.node()
        display.adapt(nd_ownHead, 80, 59, GConst.Anchor.Center)
        nd_head:addChild(nd_ownHead)
        GameUI.addPlayHead(nd_ownHead, {id=ucontext:getInfoItem(const.InfoHead),
            scale = 1.1, x=0,y=0,z=0,blackBack=true, noBlackBack = false})

        spriteName = "images/pvz/imgPvzBg4.png"
        temp = ui.sprite(spriteName)
        display.adapt(temp, 175, 14, GConst.Anchor.Center)
        nd_head:addChild(temp)

        temp = ui.label(ucontext:getInfoItem(const.InfoLevel),
            General.font1, 40, {color={255,255,255}})
        display.adapt(temp, 175, 11, GConst.Anchor.Center)
        nd_head:addChild(temp)

        --联盟相关
        if not GameLogic.isEmptyTable(ucontext.union) then
            temp = ui.label(Localize("labelUnionBelongTo"), General.font1, 40,{color={255,255,255}})
            display.adapt(temp, 185.4, -89, GConst.Anchor.Right)
            nd_ownHero:addChild(temp)

            local _ps1 = math.floor(ucontext.union.flag / 10000)
            local _ps2 = math.floor((ucontext.union.flag % 10000) / 100)
            local _ps3 = ucontext.union.flag % 100
            local nd_flag = GameUI.addUnionFlag(_ps1, _ps2, _ps3)
            nd_flag:setScale(0.2)
            display.adapt(nd_flag, 240, -100)
            nd_head:addChild(nd_flag)

            temp = ui.label(ucontext.union.name, General.font5, 40, {color={255,255,255}})
            display.adapt(temp, 289.3, -89, GConst.Anchor.Left)
            nd_ownHero:addChild(temp)

            temp = ui.label(Localize("labelUnionID"), General.font1, 40, {color={255,255,255}})
            display.adapt(temp, 185.4, -194, GConst.Anchor.Right)
            nd_ownHero:addChild(temp)

            temp = ui.label(ucontext.union.id, General.font1, 40, {color={255,255,255}})
            display.adapt(temp, 289.3, -194, GConst.Anchor.Left)
            nd_ownHero:addChild(temp)
        end

        render:begin()
        bg:visit()
        render:endToLua()
        render:saveToFile(filePath, cc.IMAGE_FORMAT_JPEG, false)

        return cf:getWritablePath() .. filePath
    end

    local _shareLock = false
    -- @brief 延迟0.5秒分享图片
    local function _delayShare(params)
        local updateSid = nil
        updateSid = GMethod.schedule(function()
            if not updateSid then
                return
            end
            if not params or cc.FileUtils:getInstance():isFileExist(params.image) then
                GMethod.unschedule(updateSid)
                Plugins:share(params)
                _shareLock = false
            end
        end, 0.5)
    end

    -- @brief 统一分享逻辑
    -- @params shareType 表示分享类型
    function GameLogic.doShare(shareType, shareIdx, itemID)
        if _shareLock then
            return
        end
        _shareLock = true
        -- 使用新版本分享链接
        local shareLan = General.language
        if shareLan ~= "CN" and shareLan ~= "EN" and shareLan ~= "HK" then
            shareLan = "EN"
        end
        if shareType == "code" then
            if (GEngine.rawConfig.sdkVersion or 0) <= 1 then
                Plugins:share({url="http://coz2.moyuplay.com/share1.html", text = Localizef("shareTip03",{code=GameLogic.getTCodeString()})})
                _shareLock = false
            else
                local sharePath = _saveSpreadCodeImage()
                local params = {image=sharePath}
                params.backUrl = (GEngine.rawConfig.fbUrl and GEngine.rawConfig.fbUrl.fbUrl1 or
                    "http://coz2.moyuplay.com/shareOtherNew.php") .. "?language=" .. shareLan
                    .. "&shareIdx=" .. 3 .. "&lanparam=" .. GameLogic.getTCodeString()
                _delayShare(params)
            end
        elseif shareType == "hero" then
            local params = {}
            if (GEngine.rawConfig.sdkVersion or 0) <= 1 then
                params.text = Localize("shareContentRate" .. shareIdx)
                params.caption = Localize("shareTitleRate" .. shareIdx)
            end
            if (GEngine.rawConfig.versionCode >= 4 and (GEngine.rawConfig.sdkVersion or 0) <= 1) or
                (shareIdx ~= 5 and shareIdx ~= 6 and itemID <= 4000) then
                params.url = "http://coz2.moyuplay.com/shareNormal" .. shareLan .. ".html"
                params.image = "http://d2pkf9xf7unp5y.cloudfront.net/shareImg" .. shareLan .. "_" .. itemID .. ".jpg"
            else
                params.url = (GEngine.rawConfig.fbUrl and GEngine.rawConfig.fbUrl.fbUrl2
                    or "http://coz2.moyuplay.com/shareItemNew.php") .. "?language=" .. shareLan
                    .. "&shareIdx=" .. shareIdx .. "&itemId=" .. itemID
            end
            params.statTag = "content" .. shareIdx .. "_" .. itemID
            params.statTag2 = {shareIdx, itemID, 1}
            if itemID then
                params.hid = itemID
            end
            if (GEngine.rawConfig.sdkVersion or 0) <= 1 or
                not cc.FileUtils:getInstance():isFileExist("images/fbShareNewEN.png") then
                Plugins:share(params)
                _shareLock = false
            else
                params.image = _saveHeroImages(shareIdx, itemID)
                params.backUrl = params.url
                params.url = nil
                _delayShare(params)
            end
        elseif shareType == "knock" then
            if (GEngine.rawConfig.sdkVersion or 0) <= 1  then
                Plugins:share({url="http://coz2.moyuplay.com/share1.html", text = Localizef("shareTip03",{code=GameLogic.getTCodeString()})})
                _shareLock = false
            else
                local params = {}
                params.image = _saveKnockImages(shareIdx)
                params.backUrl = (GEngine.rawConfig.fbUrl and GEngine.rawConfig.fbUrl.fbUrl1
                    or "http://coz2.moyuplay.com/shareOtherNew.php") .. "?language=" .. shareLan
                    .. "&shareIdx=" .. 3 .. "&lanparam=" .. GameLogic.getTCodeString()
                _delayShare(params)
            end
        end
    end

    -- @brief 复制字符串，默认为推广码
    function GameLogic.doCopyPaste(content)
        if not content then
            Native:pasteBoardString(GameLogic.getTCodeString())
            display.pushNotice(Localize("noticeSpreadCodeCopy"))
        else
            Native:pasteBoardString(tostring(Gcontent))
        end
    end
end

-- @brief 临时写个方法获取最低价位购买项
function GameLogic.getFirstPurchase()
    local ret
    if (GEngine.rawConfig.innerScriptVersion or 0) >= 320 then
        if GEngine.rawConfig.channel:find("com.bettergame.heroclash_our") and Plugins.storeItems["pack0"] then
            return "pack0"
        end
        if GEngine.rawConfig.channel:find("com.bettergame.heroclash_ios") and Plugins.storeItems["gem7"] then
            return "gem7"
        end
        if GEngine.rawConfig.channel:find("com.sslm.eliver_ios") or GEngine.rawConfig.channel:find("com.dmw.cnyx_ios")
         or GEngine.rawConfig.channel:find("com.ssylm.elver_ios") or GEngine.rawConfig.channel:find("com.cnyx") then
            return "gem7"
        end
    end
    if not ret then
        return "gem0"
    end
end

function GameLogic.getOldPrice(s, percent, back)
    -- 有小数？
    local ns
    ns = string.match(s, "%d+%,%d+")
    if ns then
        local s2 = string.gsub(s, ",", "")
        ns = string.match(s2, "%d+")
        ns = tonumber(ns)
        if not ns then
            GameLogic.otherGlobalInfo = {"price", s}
            if back then
                return GameLogic.getOldPrice(back, percent)
            end
        end
        ns = math.floor(ns*percent/100+0.5)
        local s3 = ""
        if ns < 1000 then
            s3 = tostring(ns)
        else
            local num2
            while ns >= 1000 do
                num2 = ns % 1000
                s3 = "," .. string.format("%03d", num2) .. s3
                ns = (ns - num2) / 1000
            end
            s3 = tostring(ns) .. s3
        end
        return (string.gsub(s2, "%d+", s3))
    end
    ns = string.match(s, "%d+%.%d+")
    if not ns then
        ns = string.match(s, "%d+")
        ns = tonumber(ns)
        if not ns then
            GameLogic.otherGlobalInfo = {"price", s}
            if back then
                return GameLogic.getOldPrice(back, percent)
            end
        end
        return (string.gsub(s, "%d+", tostring(math.floor(ns*percent/100+0.5))))
    else
        ns = tonumber(ns)
        local pns = 100-(ns*100)%100
        if pns==100 then pns=0 end
        ns = math.floor(ns*percent/100+0.5)*100-pns
        return (string.gsub(s, "%d+%.%d+", string.format("%d.%02d",math.floor(ns/100), ns%100)))
    end
end

-- 通用支付调用；免得反复加同一个
function GameLogic.doPurchaseLogic(params)
    if GameLogic.purchaseLock then
        display.pushNotice(Localize("noticePaying"))
        return
    end
    local storeIdx = params.storeIdx
    local product = params.product
    if not storeIdx then
        storeIdx = Plugins.tmpPayFix[product]
    end
    if not product then
        product = Plugins.storeKeys[storeIdx]
    end
    local mc = params.preType
    local actId = params.actId or 0
    local rwdIdx = params.rwdIdx
    if params.button then
        params.button:setGray(true)
    end
    GameUI.setLoadingShow("loading", true, 0)

    local rparams = {}
    rparams.product = product
    rparams.callback = params.callback
    if mc == 3 or mc == 5 then
        rparams.ext = mc .. "_" .. actId .. "_" .. rwdIdx
    elseif mc ~= 0 then
        rparams.ext = tostring(mc)
    else
        rparams.ext = ""
    end
    GameLogic.purchaseLock = true
    GameNetwork.request("prebuy",{bidx=storeIdx, mc=mc, actId=actId, rwdIdx=rwdIdx}, function(isSuc,data)
        GameLogic.purchaseLock = nil
        GameUI.setLoadingShow("loading", false, 0)
        if isSuc then
            if data.code == 0 then
                Plugins:purchase(rparams)
            elseif data.code == 3 then
                display.pushNotice(Localize("activeTimeOver"))
            else
                display.pushNotice(Localize("noticePrebuyFail" .. data.code))
            end
        end
    end)
end

--埋点需要大量用到语种判断, 故封装到一个方法
function GameLogic.getLanguageType()
    local language = General.language
    local lType
    if language == "CN" then
        lType = 1
    elseif language == "EN" then
        lType = 2
    else
        lType = 3
    end
    return lType
end

do
    --专属玩法buff,输入battleType,输出专属玩法type
    function GameLogic.getSpeBuff(battleType)
        if battleType == const.BattleTypePvp or battleType == const.BattleTypePve then
            return 1
        elseif battleType == const.BattleTypePvc or battleType == const.BattleTypePvh then
            return 2
        elseif battleType == const.BattleTypePvj then
            return 3
        elseif battleType == const.BattleTypePvb then
            return 4
        end
    end

    function GameLogic.addBuffToPerson(person, buff)
        if buff.atk then
            person.atk = person.atk + person.atk_base * (buff.atk/100)
        end
        if buff.hp then
            person.hp = person.hp + person.hp_base * (buff.hp/100)
        end
        if buff.aspeed then
            person.ascale = person.ascale + buff.aspeed/100
        end
        if buff.dmg then
            person.hurtParam = person.hurtParam + buff.dmg/100
        end
    end

    function GameLogic.addSpecialBattleBuff(hero, person, group, scene)
        if not GameLogic.useTalentMatch then
            return
        end
        --英雄特定玩法buff
        local buffType = GameLogic.getSpeBuff(scene.battleType)  --大玩法类型
        if buffType and group == 1 then
            --英雄buff
            local speBuff = SData.getData("hbuff", buffType, hero.hid)
            if speBuff then
                GameLogic.addBuffToPerson(person, speBuff, person.atk, person.hp)
            end
            --神兽buff
            if buffType == 4 then
                local atkId = SData.getData("hbuff", 5, hero.hid).mid --表里配的本英雄所针对神兽的id
                if atkId == 1 then
                    atkId = 8013
                elseif atkId == 2 then
                    atkId = 8053
                elseif atkId == 3 then
                    atkId = 8073
                end
                local beastId = SData.getData("godBeastBoss", scene.battleParams.aid, scene.battleParams.stage).gbId  --神兽id
                if atkId == beastId then
                    speBuff = SData.getData("hbuff", 5, hero.hid)
                    if speBuff then
                        GameLogic.addBuffToPerson(person, speBuff)
                    end
                end
            end
        end
    end
end

--[输入]:作战单位
--[输出]:作战单位的类型(英雄,佣兵,建筑)
function GameLogic.getCombatUnitType(CombatUnit)
    local type
    if not CombatUnit.avater then
        type = "build"
    elseif CombatUnit.avtInfo.id>1000 and CombatUnit.avtInfo.id<10000 then
        type = "hero"
    else
        type = "soldier"
    end
    return type
end

function GameLogic:refreshToday()
    local stime=self.getSTime()--_userContext.getProperty(const.ProGoldExtractTimes)
    if not self.today then
        self.today = const.InitTime
    end
    while (self.today+86400)<stime do
        self.today = self.today+86400
    end
    return self.today
end

function GameLogic:getGoldExtractChance()
    self:refreshToday()
    local lastTime=_userContext:getProperty(const.ProGoldExtractTimes)--许愿池上次抽取时间
    if lastTime<self.today then
        return 0
    else
        return _userContext:getProperty(const.ProGoldExtractChance)
    end
end

function GameLogic.loadLanguage()
    local deviceInfo = json.decode(Native:getDeviceInfo())
    local deviceType = deviceInfo.platform or "Android"
    local cconfig = GMethod.loadConfig("configs/language_" .. deviceType .. ".json",true)
    local curLan = GEngine.getConfig("language")
    if GEngine.rawConfig.rawLanSetting then
        local rawLanSetting = GEngine.rawConfig.rawLanSetting
        local rightLanguage = false
        for _, lan in ipairs(rawLanSetting) do
            if curLan == lan then
                rightLanguage = true
                break
            end
        end
        if not rightLanguage then
            curLan = rawLanSetting[1]
        end
    elseif not curLan or (GEngine.getConfig("lversion") or 0)<(cconfig.lversion or 1) then
        local country = (deviceInfo.country or "CN"):upper()
        local slanguage = (deviceInfo.language or "ZH_CN"):upper()
        if slanguage:len()>1 then
            if cconfig.lanfix2[slanguage] then
                curLan = cconfig.lanfix2[slanguage]
            else
                curLan = cconfig.lanfix2.default
            end
        else
            if cconfig.languages[country] then
                curLan = country
            elseif cconfig.lanfix[country] then
                curLan = cconfig.lanfix[country]
            else
                curLan = cconfig.lanfix.default
            end
        end
    end
    GEngine.lanConfig = cconfig
    GameLogic.changeLanguage(curLan, true)
end

function GameLogic.changeLanguage(language, isInit)
    if language==General.language and not isInit then
        return
    end
    General.language = language

    local lconf = GEngine.lanConfig.languages[language]
    if not lconf then
        language = "CN"
        lconf = GEngine.lanConfig.languages[language]
        General.language = language
    end
    if StringManager.init2 then
        local lan=language
        if not cc.FileUtils:getInstance():isFileExist("data/"..lan..".lua") then
            lan="strings"
        end
        StringManager.init2("data." .. lan)
    else
        StringManager.init(lconf[1])
    end

    --不同字体
    -- local f1 = lconf[2]--数字字体
    -- local f2 = lconf[3]--汉字字体
    -- local f3 = lconf[4]--艺术字体
    -- local f4 = lconf[5]--系统字

    local allfonts = {}
    local fnames = {}
    local fontIdx = 1
    local tablen = table.nums(lconf)
    for i=2,tablen-1 do
        local f = lconf[i]
        allfonts[fontIdx] = {fontIdx,f,true}
        General["font"..fontIdx] = fontIdx  --字体枚举，通过setFont/getFont 与字体建立对应关系
        fontIdx = fontIdx + 1
        allfonts[fontIdx] = {fontIdx,f,false}
        General["font"..fontIdx] = fontIdx
        fontIdx = fontIdx + 1

        fnames[i-1] = lconf[i]
    end

    local fontCache = CaeLabelFont
    for _, font in ipairs(allfonts) do
        local i = font[1]
        local fname = font[2]
        local hasEdge = font[3]

        --做数字混编用的，ftype==0 需要混编，混编字体可自定义
        local ftype = 1
        if fname:find(".ttf") then
            ftype = 0
        end
        local cfont = fontCache:createFont(ftype, fname)
        fontCache:setFont(i, cfont)
        if ftype == 0 then
            cfont:setFontCharSetting(1, "fonts/Font8.ttf", 1, 0, 0)
            cfont:setFontOffset(0, 0.15)
        end
        --fontSizeBegin, fontSizeEnd, fontSizeUse, int outline, shadowX, shadowY, shadowBlur
        --font[4]自定义描边和阴影设置
        if font[4] then
            cfont:setFontSuitable(0, 999.9, font[4][1], font[4][2], 0, font[4][3], 0)
        --如果有描边则按以下规则进行
        elseif hasEdge then
            cfont:setFontSuitable(0, 19.9, 14, 1, 0, -1, 0)
            cfont:setFontSuitable(20, 29.9, 20, 1, 0, -2, 0)
            cfont:setFontSuitable(30, 59.9, 30, 2, 0, -4, 0)
            cfont:setFontSuitable(60, 999.9, 60, 2, 0, -5, 0)
        --没有描边自适应字号
        else
            cfont:setFontSuitable(0, 19.9, 14, 0, 0, 0, 0)
            cfont:setFontSuitable(20, 29.9, 20, 0, 0, 0, 0)
            cfont:setFontSuitable(30, 59.9, 30, 0, 0, 0, 0)
            cfont:setFontSuitable(60, 999.9, 60, 0, 0, 0, 0)
        end
    end
    if not isInit then
        GEngine.setConfig("language",language,true)
        GEngine.setConfig("lversion",GEngine.lanConfig.lversion or 1,true)
    end
end

return GameLogic
