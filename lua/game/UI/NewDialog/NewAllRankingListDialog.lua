local SData = GMethod.loadScript("data.StaticData")

local rankType = {player = 1,unioncup = 2,fight = 3,pvc = 4}
local rank = {first = 1, second = 2,third = 3,other = 4}

--排行榜
local AllRankingListDialog = class(DialogViewLayout)

function AllRankingListDialog:ctor(params)
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth

    self.rankInfos={    
                        [1]={id="labTopPlayer",name="PvPScore",name2="pvprk",timeKey="pvp", timeId=181,datas={}},    --顶级玩家榜
                        [2]={id="labUnionCup",name="PvlRank",name2="pvlrk", timeKey="pvl", timeId=182,datas={}},      --联盟金杯榜
                        [3]={id="labCombat", name="CombRank", name2="combrk",datas = {}},  --战斗力榜
                        [4]={},
                        [5]={id="labArena",name="PvcRankNew",name2="pvcrk", timeKey="pvc", timeId=185,datas={}}       --竞技场榜
                    }

    self.uid=GameLogic.uid
    self.context = GameLogic.getUserContext();
    self.sid = self.context:getInfoItem(const.InfoSVid);
    -- self.sid=GameLogic.getUserContext().sid or 1
    if  GameLogic.getUserContext().union then
        self.cid=GameLogic.getUserContext().union.id--联盟id
    else
        self.cid=0
    end

     --显示对应的排行榜,主界面默认进入“顶级玩家榜”
    if params then
        self.idx = params.idx
    else
        self.idx = 1
    end
    self:getRankRewardTime()  
    display.showDialog(self)
end

function AllRankingListDialog:onCreate()
    self:setLayout("rank_dialog.json")
    self:loadViewsTo()
end


--排行榜奖励时间刷新，如果已经有时间就不要重新去拉了
function AllRankingListDialog:getRankRewardTime()
    local skipRequest = true
    local stime = GameLogic.getSTime()
    local _rankInfos = self.rankInfos
    local rankList = GameLogic.getUserContext().rankList
    for _, rankInfo in pairs(_rankInfos) do
        if rankInfo.timeKey then
            if rankList and rankList[rankInfo.timeId] then
                rankInfo.rewardTime = rankList[rankInfo.timeId][2]
            end
            if not rankInfo.rewardTime or rankInfo.rewardTime < stime then
                skipRequest = false
                break
            end
        end
    end
    if skipRequest then
        self:initUI()
        return
    end
    GameUI.setLoadingShow("wifi", true, 0)
    local context = GameLogic.getUserContext()
    local sid = context.mergeSid or context.sid or 1
    _G["GameNetwork"].request("getRankList2",{uid=self.uid, sid = sid},function(isSuc,data)
        GameUI.setLoadingShow("wifi", false, 0)
        if isSuc then
            for _, rankInfo in pairs(_rankInfos) do
                if rankInfo.timeKey and data[rankInfo.timeKey] then
                    rankInfo.rewardTime = data[rankInfo.timeKey][2]
                    if rankList then
                        rankList[rankInfo.timeId] = data[rankInfo.timeKey]
                    end
                end
            end
            if self.initUI then
                self:initUI()
            end
        end
    end)
end

function AllRankingListDialog:initUI( ... )
    self.btn_close:setScriptCallback(ButtonHandler(display.closeDialog,self.priority))
    self.btn_rule:setScriptCallback(ButtonHandler(self.onQuestion,self))
    
    self.cell_pvlMy:setVisible(false)
    self.cell_pvlNone:setVisible(false)
    
    local infos={}
    for i=1,#self.rankInfos do
        infos[i]={id=i,name=self.rankInfos[i].id}
    end
   
    local scroll = self.scroll_tag
    scroll:setDatas({datas = infos,cellUpdate = self.tabCallCell, target = self})
    for i,v in ipairs(infos) do
        local cell = scroll:createItem(1)
        scroll:addCell(cell)
    end
    self:selectRankPages(self.idx)
    RegTimeUpdate(self.view, Handler(self.update, self), 0.2)
end

function AllRankingListDialog:onQuestion()
    HelpDialog.new("dataQuestionRank")
end

function AllRankingListDialog:tabCallCell( cell,scroll,info )
    cell.btn_rank_click:setVisible(self.idx == info.id)
    cell.btn_rank_clickEffect:setVisible(self.idx == info.id)
    cell.lb_rankName:setString(Localize(info.name))
    cell:setScriptCallback(ButtonHandler(self.selectRankPages,self,info.id))
end

function AllRankingListDialog:selectRankPages(idx)
    local scroll = self.scroll_tag
    local selCell = scroll.children[self.idx]

    if self.idx ~= idx then
        selCell.btn_rank_click:setVisible(false)
        selCell.btn_rank_clickEffect:setVisible(false)
        self.idx = idx
    end
   
    selCell = scroll.children[idx]
    selCell.btn_rank_click:setVisible(true)
    selCell.btn_rank_clickEffect:setVisible(true)

    if not self.rankInfos[self.idx].datas["region"] then
        self:getRankData(self.idx,"region")--区域榜
    else   
        self:refreshRankList("region")
    end
end

function AllRankingListDialog:refreshRankList(rwName)    
    -- 加入联盟
    self.cell_pvlMy:setVisible(false)
    self.cell_pvlNone:setVisible(false)
    local infos=self.rankInfos[self.idx].datas[rwName] or {}
    local union = GameLogic.getUserContext().union

     -- 是否上榜
    local flag = false
    local myInfo = {}
    if self.idx == rankType.unioncup then       
        for i,v in ipairs(infos) do
            if v[6] == self.uid then
                if v[1] <= 200 then
                    flag = true
                    myInfo = v
                else
                    flag = false
                    myInfo = v
                    table.remove(infos,201)
                end
            end
        end
    end

    if flag then -- 上榜
        if self.idx == rankType.unioncup then
            -- 聯盟排行榜
            self.cell_pvlNone:setVisible(self.cid == 0)
            self.img_myLeagueFlag:setVisible(self.cid == 0)
            self.cell_pvlMy:setVisible(self.cid ~= 0)
            if self.cid == 0 then
                self.btn_pvlNone:setScriptCallback(ButtonHandler(
                    -- 加入聯盟
                    ))
            else
                local flag = GameUI.addUnionFlag(tonumber(info[2]))
                flag:setScale(0.3)
                self.img_myLeagueFlag:addChild(flag)
                local s = self.img_myLeagueFlag:getContentSize()
                flag:setPosition(s[1]/2,s[2]/2)
                self.cell_pvlMy:setVisible(true)
                self.lb_myUnionName:setString(Localize(myInfo[1]))
                self.lb_myUnionPeopleNum:setString(Localize(myInfo[5].."/"..myInfo[4]))
                self.lb_myRankPvlScore:setString(Localize(Localize(myInfo[6])))
            end
        else
        -- 不是聯盟排行榜  
        end
        
    else 
        -- 沒上榜
        self.cell_pvlNone:setVisible(false)
        self.cell_pvlMy:setVisible(false)
    end
    
    local scroll = self.scroll_rankList

    scroll:setLazyTableData(infos,Handler(self.rankCallCell,self),0)
    scroll:setScrollCallback(function()
        if self.selCell then
            self.selCell.tips:setVisible(false)
            self.selCell = nil
            self.selCellId = nil
        end
    end)

end

function AllRankingListDialog:rankCallCell( cell,scroll,info )
    if not cell then 
        cell = scroll:createItem(1)
        cell:loadViewsTo()
    end
    
    local idx = self.idx

    cell.fight:setVisible(idx == rankType.fight)
    cell.pvc:setVisible(idx == rankType.pvc)
    cell.pvp:setVisible(idx == rankType.player)
    cell.pvl:setVisible(idx == rankType.unioncup)
    
    cell.img_cellRank_first:setVisible(info[1] == rank.first)
    cell.img_cellRank_second:setVisible(info[1] == rank.second)
    cell.img_cellRank_third:setVisible(info[1] == rank.third)
    cell.img_cellRank_all:setVisible(info[1] >= rank.other)

    cell.img_levelRank_first:setVisible(info[1] == rank.first)
    cell.img_levelRank_second:setVisible(info[1] == rank.second)
    cell.img_levelRank_third:setVisible(info[1] == rank.third)

    cell.userHead:setVisible(idx ~= rankType.unioncup)
    cell.img_leagueFlag:setVisible(idx == rankType.unioncup)

    -- 公共部分
    
    -- 玩家名次
    cell.lb_rankNum:setString(Localize(info[1]))
    local s = cell.userHead:getContentSize()
    if idx == rankType.unioncup then
        cell.img_leagueFlag:setVisible(true)

         -- 联盟旗帜
        local flag = GameUI.addUnionFlag(tonumber(info[2]))
        flag:setScale(0.3)
        cell.img_leagueFlag:addChild(flag)
        local s = cell.img_leagueFlag:getContentSize()
        flag:setPosition(s[1]/2,s[2]/2)
    else
        cell.img_userHead:setVisible(true)
        local s = cell.img_userHead:getContentSize()
        -- 玩家头像
        -- local headInfo = {headScale=1, isLeft=true, notBlack=true}

        -- local head = GameUI.addHeroHead(cell.img_userHead, info[6], {size=s,x=s[1]/2,y=s[2]/2})
        -- head:setPosition(s[1]/2,s[2]/2)
    end

    -- 玩家头像框
    -- GameUI.setHeadBackIcon(frame, headBackId, false)

    -- 玩家等级
    cell.lb_userRank:setString(Localize(info[2]))
    -- 玩家昵称
    cell.lb_userName:setString(idx == rankType.unioncup  and Localize(info[3]) or Localizef("UserName",{a = info[3]}))


    --战力榜
    if idx == rankType.fight then
        -- 玩家分数
        cell.lb_rankFightScore:setString(Localize(info[4])) 
    end

    if idx == rankType.unioncup then
        cell.lb_peopleNum:setString(Localize(info[5].."/"..info[4]))
        cell.lb_rankPvlScore:setString(Localize(info[6]))
    end

    if idx == rankType.pvc then
        local lv 
        local pvcData = SData.getData("pvcData");

        for i,v in ipairs(pvcData) do
            local value = ( (v.maxRank == 0) and v.maxRank+1 ) or v.maxRank;
            if info[1] >= v.minRank and info[1] <= value then
                lv = v.realStage
                break
            end
        end

        -- 竞技场段位标识
        -- cell.img_rankPvc:setImage("")
    end

    -- 顶级玩家榜
    if idx == rankType.player then
        -- 金杯数量
        cell.lb_rankPvpScore:setString(Localize(info[4]))
    end

    cell.btn_rankList:setScriptCallback(ButtonHandler(function () 
        if self.selCell and self.selCellId then
            self.selCell.tips:setVisible(false)
            self.selCell = nil
            if self.selCellId == info[1] then
                return
            end
        end

        if info[6] == self.uid then
            return
        end

        cell.tips:setVisible(true)
        cell.bg_tip.view:setGlobalZOrder(10)
        cell.layout_tips.view:setGlobalZOrder(10)
        cell.img_btnBlue.view:setGlobalZOrder(10)
        cell.lb_visit.view:setGlobalZOrder(10)
        cell.lb_visit:setString(Localize(idx == rankType.unioncup and "labelLookUnion" or "btnVisit"))
        self.selCell = cell
        self.selCellId = info[1]

        cell.btn_visit:changePriority(-1)
      
        cell.btn_visit:setScriptCallback(ButtonHandler(function()
            if idx == rankType.unioncup then
                self:showUnion(info[7])
            else
                GameEvent.sendEvent(GameEvent.EventVisitBegin,{type = const.VisitTypeUn, uid = info[6]})
            end
        end))

    end))

    return cell
end

function AllRankingListDialog:showUnion(lid)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getleagueinfo",{getleagueinfo={lid}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==2 then
                display.pushNotice(Localize("stringNOUnion"))
                return
            else
                UnionInfoDialog.new(data)
            end
        end
    end)
end
-- 获取排行榜区域榜数据
function AllRankingListDialog:getRankData(index,rwName)
    local tpe=1;--区域榜
    if rwName=="world" then--世界榜
        tpe=2;
    end
    local aName="getRankData";
    local param={};
    if index==2 or index==4 then--联盟
        aName="getRankData_union";
        if tpe==2 then
            param={mode = self.rankInfos[index].name..0,cid=self.cid,grm=self.rankInfos[index].name2..0};
        else
            param={mode = self.rankInfos[index].name..self.sid,cid=self.cid,grm=self.rankInfos[index].name2..self.sid};
        end
    else
        param={mode = self.rankInfos[index].name..self.sid,uid=self.uid,grm=self.rankInfos[index].name2..self.sid};
    end
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request(aName,param,function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            self.rankInfos[index].datas[rwName]=data;
            self:refreshRankList(rwName)
        end
    end)
end

-- -- 更新时间
function AllRankingListDialog:update()
    self.lb_rankTime:setVisible(false)
    if self.rankInfos[self.idx].rewardTime then
        self.lb_rankTime:setVisible(true)
        local dt,timeStr
        dt=self.rankInfos[self.idx].rewardTime-GameLogic.getSTime()
        self.lb_rankTime:setString(Localize("labelTimeCount")..Localizet(dt))
    end
end


return AllRankingListDialog
