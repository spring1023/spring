--联盟战详细战报对话框
local UnionBattleDetailLogDialog = class2("UnionBattleDetailLogDialog",function()
    return BaseView.new("UnionBattleDetailLogDialog.json")
end)
function UnionBattleDetailLogDialog:ctor(params)
    self.params = params
    self.dialogDepth=display.getDialogPri()+1
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
    self.priority=self.dialogDepth
    
    self:getPvlDesc()

    display.showDialog(self)
end

function UnionBattleDetailLogDialog:initUI()
    -- local bg = ui.node()
    local infos={}
    for i,v in ipairs (self.detailLogData) do
        table.insert(infos,{idx=i,data=v})
    end
    if #infos<1 then
        self:loadView("notAttendUnionWarView")
    else
        self:addTableViewProperty("logTableview",infos,Script.createBasicHandler(self.callLogCell,self))
        self:loadView("logTableview")
    end
    -- return bg
end

function UnionBattleDetailLogDialog:getCityName(idx)
    if idx==1 then
        return Localize("label_castle"..1)
    elseif idx<=5 then
        return Localize("label_castle"..2)
    elseif idx<=10 then
        return Localize("label_castle"..3)
    elseif idx<=20 then
        return Localize("label_castle"..4)
    elseif idx<=30 then
        return Localize("label_castle"..5)
    end
end

function UnionBattleDetailLogDialog:callLogCell(cell, tableView, info)
    local bg = cell:getDrawNode()
    cell:setEnable(false)
    local data = info.data
    self:loadView("logInfoViews",bg)
    self:insertViewTo()
    self.labBattleTile:setString(Localizef("labBattleTile",{a=info.idx}))
    GameUI.addPlayHead(bg,{id=data.headid1,scale=0.62,x=80,y=350,z=0,blackBack=true})
    GameUI.addPlayHead(bg,{id=data.headid2,scale=0.62,x=800,y=350,z=0,blackBack=true})
    
    self:showBattleHeros(data.thls1,bg,18)
    self:showBattleHeros(data.thls2,bg,750)
    self.name1:setString("lv:"..data.lv1.."  "..data.name1)
    self.power1:setString(Localize("propertyComb")..(data.power1 or 0))
    self.name2:setString("lv:"..data.lv2.."  "..data.name2)
    self.power2:setString(Localize("propertyComb")..(data.power2 or 0))
    self.labStartBattleTime:setString(Localizef("labStartBattleTime",{time=GameLogic.getTimeFormat3(data.time)}))
    self.labBattleTotal:setString(Localizef("labBattleTotal",{t=Localizet(data.total)}))
    self.label_hpshengyu:setString(Localize("label_hpshengyu")..(data.hp/100).."%")
    self.labGetScore:setString(Localizef("labGetScore",{a=data.getScore}))

    self.butBackPaly:setScriptCallback(Script.createCallbackHandler(self.getPvlRepData,self,data.rid))
end

function UnionBattleDetailLogDialog:getPvlRepData(rid)
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getPvlRep",{bid=self.params.bid,cid=rid},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if data.code==0 and data.rep[1]~="" then
                local reData=json.decode(data.rep[1])
                local battleParams = reData.battleParams
                battleParams.isReplay = data.rep[1]
                GameEvent.sendEvent(GameEvent.EventBattleBegin,{rid=rid,isReplay=true,type = 8, data=reData.foeData,bparams=battleParams})
            end
        end
    end)
end
function UnionBattleDetailLogDialog:showBattleHeros(thls,bg,x)
    if not thls then
        return
    end
    thls= json.decode(thls)
    for i, v in ipairs(thls) do
        local hid=v[1]
        local lv=v[2]
        local alv=v[3]
        local heroNode=ui.node()
        display.adapt(heroNode, x+(i-1)*126, 117, GConst.Anchor.Center)
        bg:addChild(heroNode)
        self:loadView("heroNodeBack",heroNode)
        GameUI.addHeroHead(heroNode,hid,{x=3,y=0,size={115,160},lv=alv})
        local lvBack=ui.colorNode({113,27},{0,0,0,127})
        display.adapt(lvBack, 60, 17, GConst.Anchor.Center)
        heroNode:addChild(lvBack)
        local labelLv=ui.label("Lv"..lv, General.font1, 25, {color={255,255,255}})
        display.adapt(labelLv, 60, 2, GConst.Anchor.Bottom)
        heroNode:addChild(labelLv)
    end
end

function UnionBattleDetailLogDialog:initData(data)
    self.detailLogData = {}
    --reps [[进攻方id，防守方id，进攻方信息，进攻方英雄，防守方信息，防守方英雄，战报id，开始时间，持续时间，攻打的血量，分数]]
    for i,v in ipairs(data.reps) do
        local uinfo=json.decode(v[3])
        local dinfo=json.decode(v[5])
        table.insert(self.detailLogData,{rid=v[7],headid1=uinfo[3],headid2=dinfo[3],thls1=v[4],thls2=v[6],lv1=uinfo[2],lv2=dinfo[2],name1=uinfo[1],name2=dinfo[1],power1=uinfo[4],power2=dinfo[4],time=v[8],total=v[9],hp=v[10],getScore=v[11]})
    end
    if self.initUI then
        self:initUI()
    end
end
function UnionBattleDetailLogDialog:getPvlDesc()
    if not GameNetwork.lockRequest() then
        return
    end
    _G["GameNetwork"].request("getPvlDesc",{bid=self.params.bid,tid=self.params.tid,atk=self.params.atk},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if self.initData then
                self:initData(data)
            end
        end
    end)
end

return UnionBattleDetailLogDialog