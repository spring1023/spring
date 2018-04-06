local _requestConfs = 
{
    --["version"] = {"<url1>/download","GET",true,false},
    ["version"] = {"http://112.124.63.21:9983/download","GET",false,true},
    ["error"] = {"<url1>/v2/error","POST",false,true},

    ["data"] = {"<url1>/v2/user/<uid>/data","POST",true,false},
    --["cmds"] = {"http://112.124.63.21:9984/v2/user/<uid>/cmds","POST",true,false},
    ["cmds"] = {"<url1>/v2/user/<uid>/cmds","POST",true,false},
    
    ["rename"] = {"<url3>/v2/user/<uid>/name","POST",true,false},
    ["extract"] = {"<url3>/v2/hero/<uid>/extract","POST",true,false},
    ["bopen"] = {"<url3>/v2/hero/<uid>/bopen","POST",true,false},
    ["bchange"] = {"<url3>/v2/hero/<uid>/bchange","POST",true,false},
    ["blight"] = {"<url3>/v2/hero/<uid>/blight","POST",true,false},
    
    --pvp部分
    ["pvpdata"] = {"<url1>/v2/pvpdata/<uid>/pvpfind","POST",true,false},
    ["revengepvh"] = {"<url1>/v2/pvpdata/<uid>/revengepvh","POST",true,false},
    ["pvpresult"] = {"<url1>/v2/pvpdata/<uid>/afterpmbattle","POST",true,false},
    
    --竞技场部分
    ["pvcinfo"] = {"<url1>/v2/pvcdata/<uid>/getpvcinfo","GET",false,true},
    ["pvcreward"] = {"<url1>/v2/pvcdata/<uid>/getpvcreward","POST",true,false},
    ["buypvctimes"] = {"<url1>/v2/pvcdata/<uid>/buypvctimes","POST",true,false},
    ["pvcdata"] = {"<url1>/v2/pvcdata/<uid>/getpvcheros","GET",false,true},
    ["pvcresult"] = {"<url1>/v2/pvcdata/<uid>/afterpvcbattle","POST",true,false},
    ["pvcrefresh"] = {"<url1>/v2/pvcdata/<uid>/matchpvcscore","POST",true,false},
    
    ["epartshop"] = {"<url1>/v2/equip/<uid>/equipshop","POST",true,false},
    ["trialsshop"] = {"<url1>/v2/pvtdata/<uid>/getshopitems","POST",true,false},

    --远征部分
    ["pvhinfo"] = {"<url1>/v2/pvhdata/<uid>/getpvhinfo","GET",false,true},
    ["pvhstart"] = {"<url1>/v2/pvhdata/<uid>/setpvharmy","POST",true,false},
    ["pvhdata"] = {"<url1>/v2/pvhdata/<uid>/getpvhplayer","GET",true,false},
    ["pvhinspire"] = {"<url1>/v2/pvhdata/<uid>/inspirepvh","POST",true,false},
    ["pvhresult"] = {"<url1>/v2/pvhdata/<uid>/afterpvhbattle","POST",true,false},
    ["pvhbox"] = {"<url1>/v2/pvhdata/<uid>/getpvhboxes","POST",true,false},
    ["pvhstore"] = {"<url1>/v2/pvhdata/<uid>/getpvhshops","GET",false,true},
    ["pvhbuyitem"] = {"<url1>/v2/pvhdata/<uid>/buypvhshop","POST",true,false},
    ["pvhend"] = {"<url1>/v2/pvhdata/<uid>/leavepvh","POST",true,false},

    --联盟神兽
    ["upetsfeed"] = {"<url1>/v2/league/<uid>/petslvup","POST",true,false},
    ["upetsbox"] = {"<url1>/v2/league/<uid>/getboxesinfo","POST",true,false},
    ["upetskill"] = {"<url1>/v2/league/<uid>/petsskilllv","POST",true,false},
    ["upetsgive"] = {"<url1>/v2/league/<uid>/giveclanbead","POST",true,false},
    ["upetsbuy"] = {"<url1>/v2/league/<uid>/petsexchange","POST",true,false},
    ["upetschange"] = {"<url1>/v2/league/<uid>/changepets","POST",true,false},
    ["upetsmerge"] = {"<url1>/v2/league/<uid>/petsMerge","POST",true,false},
    
    --联盟部分
    ["randomleague"] = {"<url1>/v2/league/<uid>/randomleague","GET",false,true},
    ["searchleague"] = {"<url1>/v2/league/<uid>/searchleague","GET",false,true},
    ["createleague"] = {"<url1>/v2/league/<uid>/createleague","POST",true,false},
    ["jionleague"] = {"<url1>/v2/league/<uid>/jionleague","POST",true,false},
    ["leaveleague"] = {"<url1>/v2/league/<uid>/leaveleague","POST",true,false},
    ["managelmember"] = {"<url1>/v2/league/<uid>/managelmember","POST",true,false},
    ["manageleague"] = {"<url1>/v2/league/<uid>/manageleague","POST",true,false},
    ["getleagueinfo"] = {"<url1>/v2/league/<uid>/getleagueinfo","GET",false,true},
    ["getleaguepic"] = {"<url1>/v2/league/<uid>/getleaguepic","GET",false,true},
    ["claninfo"] = {"<url1>/v2/league/<uid>/claninfo","GET",false,true},

    --联盟副本
    ["getpvldata"] = {"<url1>/v2/league/<uid>/getpvldata","GET",true,false},
    ["getpvlaward"] = {"<url1>/v2/league/<uid>/getpvlaward","POST",true,false},
    ["beginpvlbattle"] = {"<url1>/v2/league/<uid>/beginpvlbattle","POST",true,false},
    ["afterpvlbattle"] = {"<url1>/v2/league/<uid>/afterpvlbattle","POST",true,false},
    ["getpvldamagelist"] = {"<url1>/v2/league/<uid>/getpvldamagelist","GET",true,false},
    ["getquestdata"] = {"<url1>/v2/getquestdata/<uid>/questdata","POST",true,false},
    ["buypvltimes"] = {"<url1>/v2/league/<uid>/buypvltimes","POST",true,false},
    ["resetpvldate"] = {"<url1>/v2/league/<uid>/resetpvldate","POST",true,false},
    --剧情PVE
    ["getpvedata"] = {"<url1>/v2/pvedata/<uid>/getpvedata","GET",false,true},
    ["pvedata"] = {"<url1>/v2/getquestdata/<uid>/questdata","GET",true,false},
    ["pvereset"] = {"<url1>/v2/pvedata/<uid>/resetpvetimes","POST",true,false},
    ["pveresult"] = {"<url1>/v2/pvedata/<uid>/afterpvebattle","POST",true,false},
    --PVJ
    ["getallpvj"] = {"<url1>/v2/pvjdata/<uid>/getallpvj","GET",true,false},
    ["afterpvjbattle"] = {"<url1>/v2/pvjdata/<uid>/afterpvjbattle","POST",true,false},
    ["cleanpvjbattle"] = {"<url1>/v2/pvjdata/<uid>/cleanpvjbattle","POST",true,false},
    --PVT
    ["getallpvt"] = {"<url1>/v2/pvtdata/<uid>/getallpvt","GET",true,false},
    ["pvtmatch"] = {"<url1>/v2/pvtdata/<uid>/pvtmatch","POST",true,false},
    ["pvtafterbattle"] = {"<url1>/v2/pvtdata/<uid>/pvtafterbattle","POST",true,false},
    ["pvtshopitems"] = {"<url1>/v2/pvtdata/<uid>/pvtshopitems","POST",true,false},
    ["pvtshopbuy"] = {"<url1>/v2/pvtdata/<uid>/pvtshopbuy","POST",true,false},
    ["getpvtreward"] = {"<url1>/v2/pvtdata/<uid>/getpvtreward","POST",true,false},

    --联盟战
    ["setpvlstate"] = {"<url1>/v2/pvldata/<uid>/setpvlstate","POST",true,false},
    ["getpvlinfo"] = {"<url1>/v2/pvldata/<uid>/getpvlinfo","GET",true,false},
    ["beginpvlbt"] = {"<url1>/v2/pvldata/<uid>/beginpvlbt","POST",true,false},
    ["lookplayinfo"] = {"<url1>/v2/pvldata/<uid>/lookplayinfo","GET",true,false},
    ["atkplayer"] = {"<url1>/v2/pvldata/<uid>/atkplayer","GET",true,false},
    ["inspirepvl"] = {"<url1>/v2/pvldata/<uid>/inspirepvl","POST",true,false},
    ["getbattlelog"] = {"<url1>/v2/pvldata/<uid>/getbattlelog","GET",true,false},
    ["getbloginfo"] = {"<url1>/v2/pvldata/<uid>/getbloginfo","GET",true,false},
    ["getboxes"] = {"<url1>/v2/pvldata/<uid>/getboxes","POST",true,false},
    ["autopvllayout"] = {"<url1>/v2/pvldata/<uid>/autopvllayout","POST",true,false},
    ["intopvllayout"] = {"<url1>/v2/pvldata/<uid>/intopvllayout","POST",true,false},
    ["setpvllayout"] = {"<url1>/v2/pvldata/<uid>/setpvllayout","POST",true,false},
    ["beginpvlatk"] = {"<url1>/v2/pvldata/<uid>/beginpvlatk","POST",true,false},

    --每日活动
    ["getactreward"] = {"<url1>/v2/actdata/<uid>/getactreward","POST",true,false},

    --成就 任务
    ["getachieve"] = {"<url1>/v2/achdata/<uid>/getachieve","POST",true,false},

    --推广码
    ["getfinfo"] = {"<url1>/v2/actdata/<uid>/getfinfo","GET",true,false},
    ["insertfcode"] = {"<url1>/v2/actdata/<uid>/insertfcode","GET",true,false},
    ["getfreward"] = {"<url1>/v2/actdata/<uid>/getfreward","GET",true,false},
    ["sendhelp"] = {"<url1>/v2/actdata/<uid>/sendhelp","GET",true,false},
    ["getfriendhelp"] = {"<url1>/v2/actdata/<uid>/getfriendhelp","GET",true,false},
    ["helpfriends"] = {"<url1>/v2/actdata/<uid>/helpfriends","GET",true,false},

    --限时活动
    ["randomfindbox"] = {"<url1>/v2/actdata/<uid>/randomfindbox","GET",true,false},
    ["gettaskinfo"] = {"<url1>/v2/actdata/<uid>/gettaskinfo","GET",true,false},    
    ["getqgiftinfo"] = {"<url1>/v2/actdata/<uid>/getqgiftinfo","GET",true,false},
    ["getqgiftreward"] = {"<url1>/v2/actdata/<uid>/getqgiftreward","GET",true,false},
    ["exchangeother"] = {"<url1>/v2/actdata/<uid>/exchangeother","GET",true,false},
    ["getvisithero"] = {"<url1>/v2/actdata/<uid>/getvisithero","GET",true,false},
    ["visitgeroreward"] = {"<url1>/v2/actdata/<uid>/visitgeroreward","GET",true,false},
    ["changehero"] = {"<url1>/v2/actdata/<uid>/changehero","GET",true,false},
    ["gethgiftreward"] = {"<url1>/v2/actdata/<uid>/gethgiftreward","GET",true,false},
    ["rechargeTest"] = {"<url1>/v2/actdata/<uid>/rechargeTest","GET",true,false},

    --聊天
    ["send"] = {"<url2>/send","GET",false,true},
    ["recv"] = {"<url2>/recv","GET",false,true},
    ["delete"] = {"<url2>/delete","GET",false,true},


    --排行榜
    ["getRankData"]={"<url1>/v2/rank","GET",true,false},
    ["getRankData_union"]={"<url1>/v2/rankClan","GET",true,false},
    ["getRankRewardTime"]={"<url1>/v2/getRankList","GET",true,false},

    --战报,邮件
    ["getPvpReport"]={"<url1>/v2/email/<uid>/getpvpreport","GET",false,true},
    
    ["getUserEmail"]={"<url1>/v2/email/<uid>/getuseremail","GET",false,true},
    --邮件奖励
    ["sendReceive"]={"<url1>/v2/email/<uid>/getemailreward","POST",true,false},
    ["sendDeleteEmail"]={"<url1>/v2/email/<uid>/deleteemail","POST",true,false},

    --炼金
    ["beginsmelt"] = {"<url1>/v2/gaalchemy/<uid>/beginsmelt","POST",true,false},
    ["getalchemyreward"] = {"<url1>/v2/gaalchemy/<uid>/getalchemyreward","POST",true,false},
    --在线奖励
    ["onlinerewards"] = {"<url1>/v2/online/<uid>/onlinerewards","onlinerewards",true,false},
    --膜拜
    ["commobaireward"] = {"<url1>/v2/mobai/<uid>/commobaireward","POST",true,false},
    ["getmobaireward"] = {"<url1>/v2/mobai/<uid>/getmobaireward","POST",true,false},
    ["visitlmember"] = {"<url1>/v2/mobai/<uid>/visitlmember","GET",false,true},
    ["givemonthcard"] = {"<url1>/v2/mcard/<uid>/givemonthcard","POST",true,false},
    ["fbfriends"] = {"http://112.124.63.21:9956/v2/fbfriends","GET",false,true},
    ["addclanfriend"] = {"<url1>/v2/league/1003/addclanfriend","POST",true,false},
    --引导 三连抽免费
    ["firstHeros"] = {"<url1>/v2/firstHeros/<uid>","POST",true,false},
    --排名
    ["getRankList"] = {"<url1>/v2/getRankList","GET",false,true},
    --登录
    ["getuser"] = {"http://112.124.63.21:9956/v2/getuser","GET",false,true},
    ["serverlist"] = {"http://112.124.63.21:9956/v2/serverlist","GET",false,true},
    ["getuserinfo"] = {"http://112.124.63.21:9956/v2/getuserinfo","GET",true,false},
    ["bindacc"] = {"http://112.124.63.21:9956/v2/bindacc","POST",true,false},
    --参观
    ["playerdata"] = {"<url1>/v2/play/<uid>/playerdata","GET",true,false},
    --获取replay数据
    ["replayinfo"] = {"<url1>/v2/pvpdata/<uid>/replayinfo","GET",true,false}
}

local network = GMethod.loadScript("engine.network")
local GameLogic = GMethod.loadScript("game.GameLogic")
local GameNetwork = {}

function GameNetwork.request(name, params, callback, ...)
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
    ps.randnum = GameLogic.randnum
    print_r(ps)

    local isChat = false
    if url:find("<url2>") then
        isChat = true
        url = url:gsub("<url2>", GameLogic.server[3])
    elseif url:find("<url1>") then
        url = url:gsub("<url1>", GameLogic.server[2])
    elseif url:find("<url3>") then
        url = url:gsub("<url3>", GameLogic.server[4])
    end
    log.d("发送请求%s",url)
    if not isChat and not url:find("cmds") and rsetting[3] and not GameNetwork.checkRequest() then
        log.e("network not lock:%s",name)
    end
    if name=="cmds" then
        print(json.encode(ps))
    end
    network.httpRequest(url, network[rsetting[2]], ps, {urlName = name, isChat = isChat,single=rsetting[3], multi=rsetting[4], callback=callback, callbackParams={...}, normal=true})
end

function GameNetwork.download(url, path, finishCallback, percentCallback, ...)
    local cp = {...}
    network.httpRequest(url, network.DOWNLOAD, {}, {path=path, single=false, multi=true, callback=finishCallback, callbackParams=cp, percentCallback=percentCallback, percentParams=cp})
end

function GameNetwork.lockRequest()
    if display.loadingVeiw then
        local view = display.loadingVeiw
        local atag = 11
        local action = view:getActionByTag(atag)
        if action then
            view:stopActionByTag(atag)
        end
        action = ui.action.sequence({{"delay",1},{"show"}})
        action:setTag(atag)
        view:runAction(action)
    end
    if GameNetwork.lock then
        return false
    else
        GameNetwork.lock = true
        GameLogic.dumpCmds(true)
        return true
    end
end

function GameNetwork.checkRequest()
    return GameNetwork.lock
end

function GameNetwork.unlockRequest()
    if display.loadingVeiw then
        local view = display.loadingVeiw
        local atag = 11
        local action = view:getActionByTag(atag)
        if action then
            view:stopActionByTag(atag)
        end
        view:setVisible(false)
    end
    if GameNetwork.lock then
        GameNetwork.lock = false
        return true
    else
        return false
    end
end

local alreadyShow = false
local function showError(luaRequest,jdata)
    
    if not luaRequest or not luaRequest.otherSettings.isChat then
        if alreadyShow then
            return
        end
        local loading = GMethod.loadScript("game.Controller.LoadingController")
        if loading.changeOver then
            alreadyShow = true
            local otherSettings = {callback = function()
                alreadyShow = false
                GEngine.restart()
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

            local dl = AlertDialog.new(4,text1,text2,otherSettings)
            display.showDialog(dl,false)
        else
            RelationDialog.new({title = Localize("labelNetError"),text=Localize("labelPleaseLoginAgain2"),mode=1},function()
                GEngine.restart()
            end)
        end
    end
end

GameNetwork.showError = showError

local function checkJsonResult(code, data,luaRequest)
    local urlName = luaRequest.otherSettings.urlName
    if luaRequest.otherSettings.isChat or urlName == "getUserEmail" then
    else
        GameLogic.operationTime = GameLogic.getTime()
    end
    log.d("完成请求")
    if code==200 then
        local jdata = json.decode(data)
        if type(jdata) == "number" then
            log.d("request",jdata)
        elseif jdata then
            log.d("request",jdata.code)
        end
        if jdata~=nil then
            if type(jdata)=="number" then
                if jdata == 20 then
                    showError(luaRequest,jdata)
                    return false, jdata
                end
                if jdata>=0 then
                    return true,jdata
                else
                    print("server return error1", jdata, urlName)
                    showError(luaRequest)
                    return false,jdata
                end
            end
            if type(jdata)=="table" and jdata.code and jdata.code<0 then
                print("server return error2", json.encode(jdata), urlName)
                showError(luaRequest)
                return false, jdata
            else
                return true, jdata
            end
        end
    else
        showError(luaRequest)
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
