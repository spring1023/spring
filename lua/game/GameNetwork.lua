local function IP_FMT(ip,childUrl)
   return string.format("http://%s/%s",ip,childUrl)
end
local loginIp = "www.caesarsplay.com:9955" --登录端口

local _requestConfs =
{
    ["error"] = {"<url1>/v2/error","POST",true,false},

    ["data"] = {"<url1>/v2/user/<uid>/data","POST",true,false},
    ["config"] = {"<url1>/v2/user/<uid>/config","GET",false,true},
    --["cmds"] = {"http://54.82.108.143:9984/v2/user/<uid>/cmds","POST",true,false},
    ["cmds"] = {"<url1>/v2/user/<uid>/cmds","POST",true,false},

    ["rename"] = {"<url1>/v2/user/<uid>/name","POST",true,false},
    ["extract"] = {"<url1>/v2/hero/<uid>/newbox","POST",true,false},
    ["bopen"] = {"<url1>/v2/hero/<uid>/bopen","POST",true,false},
    ["bchange"] = {"<url1>/v2/hero/<uid>/bchange","POST",true,false},
    ["blight"] = {"<url1>/v2/hero/<uid>/blight","POST",true,false},

    --pvp部分
    ["pvpdata"] = {"<url1>/v2/pvpdata/<uid>/pvpfind","POST",true,false},
    ["revengepvh"] = {"<url1>/v2/pvpdata/<uid>/revengepvh","POST",true,false},
    ["pvpresult"] = {"<url1>/v2/pvpdata/<uid>/afterpmbattle","POST",true,false},

    --竞技场部分
    --["pvcinfo"] = {"<url1>/v2/pvcdata/<uid>/getpvcinfo","GET",true,false},
    ["pvcreward"] = {"<url1>/v2/pvcdata/<uid>/getpvcreward","POST",true,false},
    ["buypvctimes"] = {"<url1>/v2/pvcdata/<uid>/buypvctimes","POST",true,false},
    --["pvcdata"] = {"<url1>/v2/pvcdata/<uid>/getpvcheros","GET",true,false},
    ["pvcresult"] = {"<url1>/v2/pvcdata/<uid>/afterpvcbattle","POST",true,false},
    --["pvcrefresh"] = {"<url1>/v2/pvcdata/<uid>/matchpvcscore","POST",true,false},

    ["epartshop"] = {"<url1>/v2/equip/<uid>/equipshop","POST",true,false},
    ["trialsshop"] = {"<url1>/v2/pvtdata/<uid>/getshopitems","GET",true,false},

    --远征部分
    ["pvhinfo"] = {"<url1>/v2/pvhdata/<uid>/getpvhinfo","GET",true,false},
    ["pvhstart"] = {"<url1>/v2/pvhdata/<uid>/setpvharmy","POST",true,false},
    ["pvhdata"] = {"<url1>/v2/pvhdata/<uid>/getpvhplayer","GET",true,false},
    ["pvhinspire"] = {"<url1>/v2/pvhdata/<uid>/inspirepvh","POST",true,false},
    ["pvhresult"] = {"<url1>/v2/pvhdata/<uid>/afterpvhbattle","POST",true,false},
    ["pvhbox"] = {"<url1>/v2/pvhdata/<uid>/getpvhboxes","POST",true,false},
    ["pvhstore"] = {"<url1>/v2/pvhdata/<uid>/getpvhshops","GET",true,false},
    ["pvhbuyitem"] = {"<url1>/v2/pvhdata/<uid>/buypvhshop","POST",true,false},
    ["pvhend"] = {"<url1>/v2/pvhdata/<uid>/leavepvh","POST",true,false},
    ["pvhsweep"] = {"<url1>/v2/pvhdata/<uid>/sweeppvhbattle","GET",true,false},
    --联盟神兽
    ["upetsfeed"] = {"<url1>/v2/league/<uid>/petslvup","POST",true,false},
    ["upetsbox"] = {"<url1>/v2/league/<uid>/getboxesinfo","POST",true,false},
    ["upetskill"] = {"<url1>/v2/league/<uid>/petsskilllv","POST",true,false},
    ["upetsgive"] = {"<url1>/v2/league/<uid>/giveclanbead","POST",true,false},
    ["upetsbuy"] = {"<url1>/v2/league/<uid>/petsexchange","POST",true,false},
    ["upetschange"] = {"<url1>/v2/league/<uid>/changepets","POST",true,false},
    ["upetsmerge"] = {"<url1>/v2/league/<uid>/petsMerge","POST",true,false},

    --联盟部分
    ["randomleague"] = {"<url1>/v2/league/<uid>/randomleague","GET",true,false},
    ["searchleague"] = {"<url1>/v2/league/<uid>/searchleague","GET",true,false},
    ["getapplyuser"] = {"<url1>/v2/league/<uid>/getapplyuser","GET",true,false},
    ["createleague"] = {"<url1>/v2/league/<uid>/createleague","POST",true,false},
    ["jionleague"] = {"<url1>/v2/league/<uid>/jionleague","POST",true,false},
    ["leaveleague"] = {"<url1>/v2/league/<uid>/leaveleague","POST",true,false},
    ["managelmember"] = {"<url1>/v2/league/<uid>/managelmember","POST",true,false},
    ["manageleague"] = {"<url1>/v2/league/<uid>/manageleague","POST",true,false},
    ["getleagueinfo"] = {"<url1>/v2/league/<uid>/getleagueinfo","GET",true,false},
    ["applyleague"] = {"<url1>/v2/league/<uid>/applyleague","POST",true,false},
    ["getleaguepic"] = {"<url1>/v2/league/<uid>/getleaguepic","GET",true,false},
    ["claninfo"] = {"<url1>/v2/league/<uid>/claninfo","GET",true,false},
    ["clanbuffs"] = {"<url1>/v2/league/<uid>/getClanBuffs","GET",true,false},
    ["clanWelfare"] = {"<url1>/v2/league/<uid>/getClanWelfare","GET",true,false},
    ["clanLeader"] = {"<url1>/v2/league/<uid>/changeClanLeader","POST",true,false},


    --联盟副本
    ["getpvldata"] = {"<url1>/v2/league/<uid>/getpvldata","GET",true,false},
    ["getpvlaward"] = {"<url1>/v2/league/<uid>/getpvlaward","POST",true,false},
    ["beginpvlbattle"] = {"<url1>/v2/league/<uid>/beginpvlbattle","POST",true,false},
    ["afterpvlbattle"] = {"<url1>/v2/league/<uid>/afterpvlbattle","POST",true,false},
    ["getpvldamagelist"] = {"<url1>/v2/league/<uid>/getpvldamagelist","GET",true,false},
    ["getquestdata"] = {"<url1>/v2/getquestdata/<uid>/questdata","GET",true,false},
    ["buypvltimes"] = {"<url1>/v2/league/<uid>/buypvltimes","POST",true,false},
    ["resetpvldate"] = {"<url1>/v2/league/<uid>/resetpvldate","POST",true,false},
    --剧情PVE
    ["getpvedata"] = {"<url1>/v2/pvedata/<uid>/getpvedata","GET",true,false},
    ["pvedata"] = {"<url1>/v2/getquestdata/<uid>/questdata","GET",true,false},
    ["pvecheck"] = {"<url1>/v2/pvedata/<uid>/beginpvebattle","POST",true,false},
    ["pvereset"] = {"<url1>/v2/pvedata/<uid>/resetpvetimes","POST",true,false},
    ["pveresult"] = {"<url1>/v2/pvedata/<uid>/afterpvebattle","POST",true,false},
    --PVJ
    ["getallpvj"] = {"<url1>/v2/pvjdata/<uid>/getallpvj","GET",true,false},
    ["afterpvjbattle"] = {"<url1>/v2/pvjdata/<uid>/afterpvjbattle","POST",true,false},
    ["getpvjgift"] = {"<url1>/v2/pvjdata/<uid>/getpvjgift","POST",true,false},
    ["buypvjshop"] = {"<url1>/v2/pvjdata/<uid>/buypvjshop","POST",true,false},
    ["resetquesttimes"] = {"<url1>/v2/pvjdata/<uid>/resetquesttimes","POST",true,false},
    ["useoilbottle"] = {"<url1>/v2/pvjdata/<uid>/useoilbottle","POST",true,false},
    ["cleanpvjbattle"] = {"<url1>/v2/pvjdata/<uid>/cleanpvjbattle","POST",true,false},
    --PVT
    ["getallpvt"] = {"<url1>/v2/pvtdata/<uid>/getallpvt","GET",true,false},
    ["pvtmatch"] = {"<url1>/v2/pvtdata/<uid>/pvtmatch","POST",true,false},
    ["pvtsethero"] = {"<url1>/v2/pvtdata/<uid>/pvtsethero","POST",true,false},
    ["buypvttimes"] = {"<url1>/v2/pvtdata/<uid>/buypvttimes","POST",true,false},
    ["pvtbeginbattle"] = {"<url1>/v2/pvtdata/<uid>/pvtbeginbattle","POST",true,false},
    ["pvtafterbattle"] = {"<url1>/v2/pvtdata/<uid>/pvtafterbattle","POST",true,false},
    ["pvtshopitems"] = {"<url1>/v2/pvtdata/<uid>/pvtshopitems","POST",true,false},
    ["pvtshopbuy"] = {"<url1>/v2/pvtdata/<uid>/pvtshopbuy","POST",true,false},
    ["getpvtreward"] = {"<url1>/v2/pvtdata/<uid>/getpvtreward","POST",true,false},
    ["getshopitems"] = {"<url1>/v2/pvtdata/<uid>/getshopitems","GET",true,false},
    ["savepvtskill"] = {"<url1>/v2/pvtdata/<uid>/savepvtskill","POST",true,false},

    --联盟战
    ["setpvlstate"] = {"<url1>/v2/pvldata/<uid>/setpvlstate","POST",true,false},
    ["getpvlinfo"] = {"<url1>/v2/pvldata/<uid>/getpvlinfo","GET",true,false},
    ["beginpvlbt"] = {"<url1>/v2/pvldata/<uid>/beginpvlbt","POST",true,false},
    ["lookplayinfo"] = {"<url1>/v2/pvldata/<uid>/lookplayinfo","GET",true,false},
    ["atkplayer"] = {"<url1>/v2/pvldata/<uid>/atkplayer","POST",true,false},
    ["inspirepvl"] = {"<url1>/v2/pvldata/<uid>/inspirepvl","POST",true,false},
    ["getbattlelog"] = {"<url1>/v2/pvldata/<uid>/getbattlelog","GET",true,false},
    ["getPvlBoxesDesc"] = {"<url1>/v2/pvldata/<uid>/getPvlBoxesDesc","GET",true,false},
    ["getboxes"] = {"<url1>/v2/pvldata/<uid>/getboxes","POST",true,false},
    ["autopvllayout"] = {"<url1>/v2/pvldata/<uid>/autopvllayout","POST",true,false},
    ["intopvllayout"] = {"<url1>/v2/pvldata/<uid>/intopvllayout","POST",true,false},
    ["setpvllayout"] = {"<url1>/v2/pvldata/<uid>/setpvllayout","POST",true,false},
    ["beginpvlbt"] = {"<url1>/v2/pvldata/<uid>/beginpvlbt","POST",true,false},

    ["getPvlHistroy"] = {"<url1>/v2/pvldata/<uid>/getPvlHistroy","GET",true,false},
    ["getPvlReward"] = {"<url1>/v2/pvldata/<uid>/getPvlReward","GET",true,false},
    ["getPvlDesc"] = {"<url1>/v2/pvldata/<uid>/getPvlDesc","GET",true,false},
    ["getPvlRep"] = {"<url1>/v2/pvldata/<uid>/getPvlRep","GET",true,false},

    ["getShareClanBox"] = {"<url1>/v2/league/<uid>/getShareClanBox","GET",true,false},
    ["shareClanBox"] = {"<url1>/v2/league/<uid>/shareClanBox","GET",true,false},

    --每日活动
    ["getactinfo"] = {"<url1>/v2/actdata/<uid>/getactinfo","GET",true,false},
    ["updateact"] = {"<url1>/v2/actdata/<uid>/updateact","POST",true,false},
    ["getactreward"] = {"<url1>/v2/actdata/<uid>/getactreward","POST",true,false},

    --成就 任务
    ["getachieveinfo"] = {"<url1>/v2/achdata/<uid>/getachieveinfo","GET",true,false},
    ["getachieve"] = {"<url1>/v2/achdata/<uid>/getachieve","POST",true,false},

    --推广码
    ["getfinfo"] = {"<url1>/v2/actdata/<uid>/getfinfo","GET",true,false},
    ["insertfcode"] = {"<url1>/v2/actdata/<uid>/insertfcode","POST",true,false},
    ["getfreward"] = {"<url1>/v2/actdata/<uid>/getfreward","POST",true,false},
    ["sendhelp"] = {"<url1>/v2/actdata/<uid>/sendhelp","POST",true,false},
    ["getfriendhelp"] = {"<url1>/v2/actdata/<uid>/getfriendhelp","GET",true,false},
    ["helpfriends"] = {"<url1>/v2/actdata/<uid>/helpfriends","POST",true,false},

    ["sendCode"] = {"<url1>/v2/<uid>/sendCode","POST",true,false},
    ["sCodeList"] = {IP_FMT(loginIp,"global/sCodeList"),"GET",true,false},
    ["getCodeRewards"] = {"<url1>/v2/<uid>/getCodeRewards","POST",true,false},

    --限时活动
    ["randomfindbox"] = {"<url1>/v2/actdata/<uid>/randomfindbox","POST",true,false},
    ["gettaskinfo"] = {"<url1>/v2/actdata/<uid>/gettaskinfo","GET",true,false},
    ["getqgiftinfo"] = {"<url1>/v2/actdata/<uid>/getqgiftinfo","GET",true,false},
    ["getqgiftreward"] = {"<url1>/v2/actdata/<uid>/getqgiftreward","POST",true,false},
    ["exchangeother"] = {"<url1>/v2/actdata/<uid>/exchangeother","POST",true,false},
    ["getvisithero"] = {"<url1>/v2/actdata/<uid>/getvisithero","GET",true,false},
    ["visitgeroreward"] = {"<url1>/v2/actdata/<uid>/visitgeroreward","POST",true,false},
    ["changehero"] = {"<url1>/v2/actdata/<uid>/changehero","POST",true,false},
    ["gethgiftreward"] = {"<url1>/v2/actdata/<uid>/gethgiftreward","POST",true,false},
    ["rechargeTest"] = {"<url1>/v2/actdata/<uid>/rechargeTest","POST",true,false},

    --聊天
    ["send"] = {"<url2>/send","GET",false,true},
    ["recv"] = {"<url2>/recv","GET",false,true},
    ["delete"] = {"<url2>/delete","GET",false,true},


    --排行榜
    ["getRankData"]={"<url1>/v2/rank","GET",true,false},
    ["getRankData_union"]={"<url1>/v2/rankClan","GET",true,false},
    -- ["getRankRewardTime"]={"<url1>/v2/getRankList","GET",true,false},
    ["getRankList2"]={"<url1>/v2/getRankList2","GET",true,false}, --新增排行信息，取代旧接口
    ["getRankPopular"]={"<url1>/v2/rankPopular","GET",true,false},
    ["getClanPopular"]={"<url1>/v2/league/<uid>/getClanPopular","POST",true,false},




    --战报,邮件
    ["getPvpReport"]={"<url1>/v2/email/<uid>/getpvpreport","GET",true,false},
    ["getUserEmail"]={"<url1>/v2/email/<uid>/getuseremail","GET",true,false},
    --投诉
    ["getTipoffs"]={"<url1>/v2/tipoffs","POST",true,false},
    --邮件奖励
    ["sendReceive"]={"<url1>/v2/email/<uid>/getemailreward","POST",true,false},
    ["sendDeleteEmail"]={"<url1>/v2/email/<uid>/deleteemail","POST",true,false},


    --设置
    ["changehead"] = {"<url1>/v2/email/<uid>/changehead","POST",true,false},
    ["changesetting"] = {"<url1>/v2/email/<uid>/changesetting","POST",true,false},
    --炼金
    ["getalchemyinfo"] = {"<url1>/v2/gaalchemy/<uid>/getalchemyinfo","GET",true,false},
    ["beginsmelt"] = {"<url1>/v2/gaalchemy/<uid>/beginsmelt","POST",true,false},
    ["beginalchemy"] = {"<url1>/v2/gaalchemy/<uid>/beginalchemy","POST",true,false},
    ["chancealchemy"] = {"<url1>/v2/gaalchemy/<uid>/chancealchemy","POST",true,false},
    ["accalchemy"] = {"<url1>/v2/gaalchemy/<uid>/accalchemy","POST",true,false},
    ["getalchemyreward"] = {"<url1>/v2/gaalchemy/<uid>/getalchemyreward","POST",true,false},
    --在线奖励
    ["onlinerewards"] = {"<url1>/v2/online/<uid>/onlinerewards","POST",true,false},
    --膜拜
    ["commobaireward"] = {"<url1>/v2/mobai/<uid>/commobaireward","POST",true,false},
    ["getmobaireward"] = {"<url1>/v2/mobai/<uid>/getmobaireward","POST",true,false},
    ["visitlmember"] = {"<url1>/v2/mobai/<uid>/visitlmember","GET",true,false},
    ["givemonthcard"] = {"<url1>/v2/mcard/<uid>/givemonthcard","POST",true,false},
    ["fbfriends"] = {IP_FMT(loginIp,"v2/fbfriends"),"GET",true,false},
    ["addclanfriend"] = {"<url1>/v2/league/1003/addclanfriend","POST",true,false},
    --引导 三连抽免费
    ["firstHeros"] = {"<url1>/v2/firstHeros/<uid>","POST",true,false},
    --护盾时间
    ["getreplayinfo"] = {"<url1>/v2/pvpdata/<uid>/getreplayinfo","GET",true,false},
    ["buyshield"] = {"<url1>/v2/pvpdata/<uid>/buyshield","POST",true,false},
    --排名
    ["getRankList"] = {"<url1>/v2/getRankList","GET",true,false},
    --登录
    ["getuser"] = {IP_FMT(loginIp,"v2/getuser"),"GET",true,false},
    ["serverlist"] = {IP_FMT(loginIp,"v2/serverlist"),"GET",true,false},
    ["getuserinfo"] = {IP_FMT(loginIp,"v2/getuserinfo"),"GET",true,false},
    ["bindacc"] = {IP_FMT(loginIp,"v2/bindacc"),"POST",true,false},
    ["getRankData_union_world"]={"<url1>/v2/rankClan","GET",true,false},
    ["setBinds"] = {"<url1>/v2/setBinds","POST",true,false},
    ["getRandnum"] = {"<url1>/v2/getRandnum","POST",true,false},

    --参观
    ["playerdata"] = {"<url1>/v2/play/<uid>/playerdata","GET",true,false},
    --获取replay数据
    ["replayinfo"] = {"<url1>/v2/pvpdata/<uid>/replayinfo","GET",true,false},

    ["followUrl"]={"https://www.baidu.com/","GET",true,false},
    ["getRewards"]={"<url1>/getRewards","POST",false,true},
    --礼包码领取奖励
    ["packCode"]={"<url1>/v2/giftcode/<uid>/giftcode","POST",true,false},

    --隔天刷新
    ["refreshData"]={"<url1>/v2/play/<uid>/resettime","POST",true,false},

    --购买之前的接口
    ["prebuy"]={"<url1>/v2/<uid>/prebuy","POST",true,false},

    --彩蛋活动奖励领取/购买接口
    ["actrwds"]={"<url1>/v2/user/<uid>/actrwds","POST",true,false},
    ["dailyrwds"]={"<url1>/v2/task/<uid>/claim","POST",true,false},
    ["openbox"]={"<url1>/v2/user/<uid>/openbox","POST",true,false},

    --测试充值礼包
    ["verify"]={"http://139.196.194.74:9923/inner/verify","POST",true,false},


    -- 每日任务获取奖励
    ["dailyTask"]={"<url1>/v2/<uid>/dailytask/list","GET",true,false},
    -- 每日任务刷新奖励
    ["dailyRefresh"]={"<url1>/v2/<uid>/dailytask/refresh","POST",true,false},
    -- 每日任务领取任务奖励
    ["dailyGetReward"]={"<url1>/v2/<uid>/dailytask/reward","POST",true,false},
    -- pve扫荡
    ["sweepPveBattle"]={"<url1>/v2/pvedata/<uid>/sweeppvebattle","POST",true,false},

    ["pvcLog"]={"<url1>/v2/pvcdata/<uid>/history","GET",true,false},
    ["pvcBeginBattle"] = {"<url1>/v2/pvcdata/<uid>/beginbattle","POST",true,false},

    ["pvcinfo"] = {"<url1>/v2/pvcdata/<uid>/getpvcinfo","POST",true,false},
    ["pvcrefresh"] = {"<url1>/v2/pvcdata/<uid>/refreshPvcPlayers","POST",true,false},
    ["pvcheros"] = {"<url1>/v2/pvcdata/<uid>/pvcheros","POST",true,false},
    ["pvcresult"] = {"<url1>/v2/pvcdata/<uid>/afterbattle","POST",true,false},
    ["pvcbuy"] = {"<url1>/v2/pvcdata/<uid>/buypvctimes","POST",true,false},
    ["getpvcnow"] = {"<url1>/v2/pvcdata/<uid>/getpvcnow","POST",true,false},

    ["pvchistory"] = {"<url1>/v2/pvcdata/<uid>/pvchistory","POST",true,false},
    ["pvcGetAvalue"] = {"<url1>/v2/pvcdata/<uid>/getPvcAvalue","POST",true,false},
    ["pvcbuybox"] = {"<url1>/v2/pvcdata/<uid>/buyitem","POST",true,false},

    ["replaycheck"] = {"http://www.caesarsplay.com:4000/getReportDesc","GET",true,false},

    ["getPvzUInfos"] = {"<url1>/v2/pvzdata/<uid>/getPvzUInfos", "GET", true, false},
    ["joinPvzBattle"] = {"<url1>/v2/pvzdata/<uid>/joinPvzBattle", "GET", true, false},
    ["beginPvzBattle"] = {"<url1>/v2/pvzdata/<uid>/beginPvzBattle", "GET", true, false},
    ["getGroupPlayers"] = {"<url1>/v2/pvzdata/<uid>/getGroupPlayers", "POST", true, false},
    ["getPvzGReport"] = {"<url1>/v2/pvzdata/<uid>/getPvzGReport", "POST", true, false},
    ["openPvzGRewards"] = {"<url1>/v2/pvzdata/<uid>/openPvzGRewards", "GET", true, false},
    ["afterPvzBattle"] = {"<url1>/v2/pvzdata/<uid>/afterPvzBattle", "POST", true, false},
    ["pvzReplay"] = {"<url1>/v2/pvzdata/<uid>/pvzReplay", "POST", true, false},

    ["getKoutPlayers"] = {"<url1>/v2/pvzdata/<uid>/getKoutPlayers", "POST", true, false},
    ["getKoutPlayerDesc"] = {"<url1>/v2/pvzdata/<uid>/getKoutPlayerDesc", "POST", true, false},
    ["getHistroyCp"] = {"<url1>/v2/pvzdata/<uid>/getHistroyCp", "POST", true, false},
    ["pvzReplay"] = {"<url1>/v2/pvzdata/<uid>/pvzReplay", "POST", true, false},
    ["allinCrystal"] = {"<url1>/v2/pvzdata/<uid>/allinCrystal", "POST", true, false},

    ["vipreward"] = {"<url1>/v2/udata/<uid>/vipbuypkg", "POST", true, false},

    -- 达人赛; 因为会产生报名所以需要
    ["tmdata"] = {"<url1>/v2/tmdata/<uid>/tmdata","GET",true,false},
    ["tmrank"] = {"<url1>/v2/tmdata/<uid>/tmrank","GET",false,true},
    ["tmrankstage"] = {"<url1>/v2/tmdata/<uid>/tmstagerank","GET",false,true},
    ["tmgift"] = {"<url1>/v2/tmdata/<uid>/tmgift","POST",true,false},
    --噩梦远征部分
    ["npvhresult"]={"<url1>/v2/tmdata/<uid>/afterpvhbattle","POST",true,false},
    --僵尸来袭
    ["afterdrpvjbattle"] = {"<url1>/v2/tmdata/<uid>/afterpvjbattle","POST",true,false},
    --神兽战
    ["aftertpvbbattle"] = {"<url1>/v2/tmdata/<uid>/afterpvbbattle","POST",true,false}
}

local network = GMethod.loadScript("engine.network")
local GameLogic = GMethod.loadScript("game.GameLogic")
local GameNetwork = {}

local sortFunctionCache = {}

local function getSortFunction2(key, reverse)
    local fkey = tostring(key) .. ((reverse and 1) or 0)
    if not sortFunctionCache[fkey] then
        if reverse then
            sortFunctionCache[fkey] = function(a, b)
                return a[key]>b[key]
            end
        else
            sortFunctionCache[fkey] = function(a, b)
                return a[key]<b[key]
            end
        end
    end
    return sortFunctionCache[fkey]
end

function GameNetwork.request(name, params, callback, ...)
    if GameLogic.inError then
        return
    end
    local rsetting = _requestConfs[name]
    if not rsetting then
        return
    end
    local url = rsetting[1]
    local ps = params or {}
    if url:find("<uid>") then
        url = url:gsub("<uid>", tostring(params and params.uid or GameLogic.uid))
    end
    ps.zid = GameLogic.zid
    ps.randnum = GameLogic.randnum or 0
    ps.uid = params and params.chatRoom and params.uid or GameLogic.uid

    local isChat = false
    local retry = 0
    local lockGold = nil
    local lockContext = nil
    if url:find("<url2>") then
        isChat = true
        retry = 3
        url = url:gsub("<url2>", GameLogic.server[3])
    elseif url:find("<url1>") then
        url = url:gsub("<url1>", GameLogic.server[2])
    elseif url:find("<url3>") then
        url = url:gsub("<url3>", GameLogic.server[4])
    end
    if not isChat and not url:find("cmds") and rsetting[3] and not GameNetwork.checkRequest() then
        log.e("network not lock:%s",name)
    end
    if GameLogic.operationTime then
        if name == "cmds" then
            GameLogic.lastCmdTime = GameLogic.getSTime()
            GameLogic.lastNetworkTime = nil
        elseif not isChat and name ~= "getUserEmail" and name ~= "getPvpReport" and name ~= "getpvcnow" then
            if not GameLogic.lastNetworkTime then
                GameLogic.lastNetworkTime = GameLogic.getSTime()
            end
            if rsetting[2] == "POST" and not ps.syn_id then
                local uc = GameLogic.getUserContext()
                if uc then
                    ps.syn_id = uc:getLastSynId()
                    lockGold = uc:getLockGold()
                    lockContext = uc
                end
            end
        end
    end
    if not isChat and rsetting[3] then
        GameUI.setLoadingShow("wifi", true, 10)
    end

    local magicParams = {}
    local sortedItems = {}
    for key, value in pairs(ps) do
        if type(value)=="string" then
            --ok
        elseif type(value)=="table" then
            value = json.encode(value)
        else
            value = tostring(value)
        end
        magicParams[key] = value
        table.insert(sortedItems, {key, value})
    end
    table.sort(sortedItems, getSortFunction2(1))
    local sortedStr = ""
    for _, item in ipairs(sortedItems) do
        sortedStr = sortedStr .. item[2]
    end
    sortedStr = sortedStr .. "98RHFEJDW2394URH"
    local signTable = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
    for i=1, sortedStr:len() do
        signTable[(i-1)%16+1] = signTable[(i-1)%16+1]+sortedStr:byte(i)
    end
    sortedStr = ""
    local c
    for i,snum in ipairs(signTable) do
        c = math.floor(math.floor(snum+0.5)%62+0.5)
        if c<10 then
            c = string.char(48+c)
        elseif c<36 then
            c = string.char(55+c)
        else
            c = string.char(61+c)
        end
        sortedStr = sortedStr .. c
    end
    magicParams["lsign"] = sortedStr
    log.d("发送请求%s，参数：%s",url,json.encode(magicParams))

    local luaRequest = {urlName = name, isChat = isChat, retry=retry, single=rsetting[3], multi=rsetting[4], callback=callback, callbackParams={...}, normal=true}
    -- 修改回调以防万一
    if lockGold and lockContext and callback then
        luaRequest.callback = function(...)
            lockContext._lockGold = lockGold
            callback(...)
            lockContext._lockGold = nil
        end
    end
    network.httpRequest(url, network[rsetting[2]], magicParams, luaRequest)
end

function GameNetwork.download(url, path, finishCallback, percentCallback, ...)
    local cp = {...}
    network.httpRequest(url, network.DOWNLOAD, {}, {path=path, single=false, multi=true, callback=finishCallback, callbackParams=cp, percentCallback=percentCallback, percentParams=cp, retry=3})
end

function GameNetwork.lockRequest()
    if GameNetwork.lock then
        return false
    else
        GameUI.setLoadingShow("loading", true, 0)
        GameNetwork.lock = true
        GameLogic.dumpCmds(true)
        return true
    end
end

function GameNetwork.checkRequest()
    return GameNetwork.lock
end

function GameNetwork.unlockRequest()
    if GameNetwork.lock then
        GameNetwork.lock = false
        GameUI.setLoadingShow("loading", false)
        return true
    else
        return false
    end
end

local alreadyShow = false
local function showError(luaRequest,jdata,code)
    --竞技场的20秒刷新接口
    if luaRequest.otherSettings.urlName == "getpvcnow" or luaRequest.otherSettings.urlName == "getTipoffs" then -- and (code ~= 500)
        return
    end
    if not luaRequest or (not luaRequest.otherSettings.isChat and luaRequest.otherSettings.urlName ~= "getUserEmail" ) then
        GameLogic.inError = true
        log.e(debug.traceback())
        if alreadyShow then
            return
        end
        local loading = GMethod.loadScript("game.Controller.LoadingGameController")
        alreadyShow = true
        if loading.changeOver then
            local otherSettings = {callback = function()
                alreadyShow = false
                GameLogic.restart()
            end,noCloseBut = true}
            local text1 = Localize("labelNetError")
            local text2 = Localize("labelPleaseLoginAgain2")
            if jdata then
                if type(jdata)=="number" and jdata == 20 then
                    text2 = Localize("labelOtherLogin")
                elseif type(jdata) == "table" and jdata.code == -3 then
                    text2 = Localizef("stringSealAccount",{a=os.date("%Y-%m-%d %X", jdata.etime)})
                end
            end

            if GameLogic.inTest then
                text2 = text2 .. " The request is " .. luaRequest.url .. " and the other info is " .. json.encode(GameLogic.otherGlobalInfo)
            end
            local dl = AlertDialog.new(4,text1,text2,otherSettings)
            display.showDialog(dl,false)
        else
            local text2 = Localize("labelPleaseLoginAgain2")
            if GameLogic.inTest then
                text2 = text2 .. " The request is " .. luaRequest.url .. " and the other info is " .. json.encode(GameLogic.otherGlobalInfo)
            end
            RelationDialog.new({title = Localize("labelNetError"),text=text2,mode=1},function()
                alreadyShow = false
                GameLogic.restart()
            end)
        end
    end
end

GameNetwork.showError = showError

local function checkJsonResult(code, data,luaRequest)
    local urlName = luaRequest.otherSettings.urlName
    if luaRequest.otherSettings.isChat or urlName == "getUserEmail" then
    elseif GameLogic.operationTime then
        GameLogic.operationTime = GameLogic.getSTime()
    end
    if not luaRequest.otherSettings.isChat and luaRequest.otherSettings.single then
        GameUI.setLoadingShow("wifi", false, 0)
    end
    if code==200 then
        local jdata = json.decode(data)
        if type(jdata) == "number" then
            log.d("request result:%d",jdata)
        elseif jdata then
            log.d("request result:%d",jdata.code or 0)
        end
        if jdata~=nil then
            if type(jdata)=="table" and jdata.code and jdata.code==100 then
                GameLogic.inError = true
                alreadyShow = true
                if not GameNetwork.baned  then
                    GameNetwork.baned=true
                    local title = Localize("alertTitleNormal")
                    local reason = jdata.reason
                    local etime = jdata.etime

                    if etime then
                        local otherSettings ={time=etime,labelTimeDes=Localize("labelBattleEnd"),callback=function()
                            GEngine.quitGame()
                        end,noCloseBut=true}
                        local dl = AlertDialog.new(12,title,reason,otherSettings)
                        display.showDialog(dl,false)
                    else
                        RelationDialog.new({title=title, text=reason, mode=1},function()
                            GEngine.quitGame()
                        end)
                    end
                end
                return false, nil
            end
            if type(jdata)=="number" then
                if jdata == 20 then
                    showError(luaRequest,jdata)
                    return false, jdata
                end
                if jdata>=0 then
                    return true,jdata
                else
                    GameLogic.otherGlobalInfo ={"error1:data is number",jdata,urlName,GameLogic.getSTime(),GameLogic.getToday()}
                    log.d("server return error1:%d,%s", jdata, urlName)
                    showError(luaRequest)
                    return false,jdata
                end
            end
            if type(jdata)=="table" and jdata.code and jdata.code<0 then
                GameLogic.otherGlobalInfo ={"error2:data.code<0",json.encode(jdata),urlName,GameLogic.getSTime(),GameLogic.getToday()}
                log.d("server return error2:%s,%s", json.encode(jdata), urlName)
                showError(luaRequest)
                return false, jdata
            else
                return true, jdata
            end
        end
    else
        showError(luaRequest, nil, code)
        if not luaRequest.otherSettings.isChat then
            log.e("network error:%d,%s",code,luaRequest.otherSettings.urlName)
        end
        return false, nil
    end
    showError(luaRequest)
    return false, nil
end

network.registerNormalHandler("afterRequest", checkJsonResult)
GEngine.export("GameNetwork",GameNetwork)

return GameNetwork
