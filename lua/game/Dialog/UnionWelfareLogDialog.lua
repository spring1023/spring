--联盟福利查看
local const = GMethod.loadScript("game.GameLogic.Const")
local SData = GMethod.loadScript("data.StaticData")
UnionWelfareLogDialog = class(DialogViewLayout)
function UnionWelfareLogDialog:onInitDialog()
	self:setLayout("UnionWelfareLogDialog.json")
    self:loadViewsTo()
    --帮助的文本
    self.questionTag = Localize("labelUnionWelfareHelp")
    self.title:setString(Localize("btnUnionWelfareLabel"))
    self.butHelp:setScriptCallback(ButtonHandler(function ()
        HelpDialog.new(self.questionTag)
    end))
    self.unionShow:setString(Localize("labelUnionWelfareShow"))
    self.infoUp:setString(Localize("labelWelfareTopInfo"))
    self.infoUp2:setString(Localize("labelWelfareTopInfo2"))
    self:showScrollUI()
end

function UnionWelfareLogDialog:showScrollUI()
	-- body
	local info = {}
	self.diamondNum = 0
	if not GameNetwork.lockRequest() then
        return
    end
    local buffInfo = GameLogic.getUserContext().activeData:getBuffInfo(const.ActTypeBuffWelfare)
    local wNum = 1
    if buffInfo[4]~=0 then
        wNum = buffInfo[4]/20
    end

    _G["GameNetwork"].request("clanbuffs",{lid = self.context.union.id},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            if self.deleted then
                return
            end
            if GameLogic.useTalentMatch then
                self.sumnum:setVisible(false)
                self.resIconCrystal:setVisible(false)
                self.day:setVisible(false)
            else
                for k,v in ipairs(data.obuff) do
                    table.insert(info, {num = v[4]*wNum,time = v[2],name = v[1], type=2})
                    self.diamondNum = self.diamondNum+v[4]*wNum
                end
                self.sumnum:setString(Localize("labelAddUp")..self.diamondNum)
                self.day:setString("/" .. Localize("tmDay"))
            end
            table.insert(info, {weekExp=data.nbuff[1] or 0, getedNum=data.nbuff[2] or 0,
                weekTime=data.nbuff[3] or (1508897021+86400*30), curWeeekExp=data.nbuff[4] or 0,
                curWeektime=data.nbuff[5] or 0, time=1798736461, type=1})
            table.sort(info, function (a,b)
                return a.time>b.time
            end)
            GameUI.helpLoadTableView(self.sNode,info,Handler(self.cellCallBack,self))
        end
    end)
end

function UnionWelfareLogDialog:cellCallBack(cell, tableView, info)
	-- body
	 if not info.viewLayout then
        if info.type == 2 then
            info.viewLayout = self:addLayout("scrollNode",cell:getDrawNode())
            info.viewLayout:loadViewsTo(info)
            info.view = cell
            self:updateUI(info)
        else
            info.viewLayout = self:addLayout("scrollNode2",cell:getDrawNode())
            info.viewLayout:loadViewsTo(info)
            info.view = cell
            self:updateUI2(info)
        end
    end
end

function UnionWelfareLogDialog:updateUI(info)
	-- body
	--联盟补给包
	info.nameinfo:setString(Localize("unionWelfareTips"))

	--头像
	GameUI.addItemIcon(info.iconNode,18,1,1,0,0)

	--钻石数量
	info.diamondNum:setString("+"..info.num)
	--天
	info.sDay:setString(tostring("/"..Localize("tmDay")))
	--最后登录时间
	info.restTime:setString(Localize("labelTimeCount")..Localizet(info.time-GameLogic.getSTime()))
	info.byName:setString("By".."  "..info.name)
end

function UnionWelfareLogDialog:updateUI2(info)
    info.btnReceive:setString(Localize("btnReceive"))
    GameUI.addItemIcon(info.iconNode,18,1,1,0,0)
    local weekPackData = SData.getData("UnionWeekPack")
    local weekLv = 1
    self.rewdLv = 1
    if info.weekExp>=weekPackData[KTLen(weekPackData)].endexp then
        weekLv = KTLen(weekPackData)
        self.rewdLv = KTLen(weekPackData)
    else
        for i,v in ipairs(weekPackData) do
            if info.weekExp>=v.endexp then
                weekLv = weekLv+1
            end
            if (info.weekExp-info.curWeeekExp)>=v.endexp then
                self.rewdLv = self.rewdLv + 1
            end
        end
    end
    info.lab_weekGift:setString(Localizef("weekGift",{n=self.rewdLv}))
    info.lab_curLv:setString("Lv."..weekLv)
    local wData = SData.getData("UnionWeekPack",weekLv)
    local processValue = 0
    processValue = (info.weekExp)/wData.endexp
    info.topupProcess:setProcess(true,processValue)
    if info.weekExp>=weekPackData[KTLen(weekPackData)].endexp then
        info.topupProcessValue:setString(info.weekExp.."/Max")
        info.lab_nextLv:setString("Lv.Max")
    else
        info.topupProcessValue:setString(info.weekExp.."/"..wData.endexp)
        info.lab_nextLv:setString("Lv."..weekLv+1)
    end
    local stime = GameLogic.getSTime()
    local dtime = info.weekTime
    if (math.floor((stime-const.InitTime)/(86400*7)) > math.floor((dtime-const.InitTime)/(86400*7))) then
        info.getedNum = 0
    end
    local restTime = 86400*7-(stime-const.InitTime)%(86400*7)
    info.restTime:setString(Localize("labelTimeCount")..Localizet(restTime))
    if info.getedNum<wData.rnum1 then
        info.btn_receive:setEnable(true)
        info.btn_receive:setGray(false)
    else
        info.btn_receive:setEnable(false)
        info.btn_receive:setGray(true)
    end
    info.btn_receive:setScriptCallback(ButtonHandler(self.OnRecieveClick, self))
end

function UnionWelfareLogDialog:OnRecieveClick()
    local context = GameLogic.getUserContext()
    local wData = SData.getData("UnionWeekPack",self.rewdLv)
    local rwds = wData.rwds1
    GameLogic.addRewards(rwds)
    for i,v in ipairs(rwds) do
        display.pushNotice(Localizef("noticeGetItem",{name=GameLogic.getItemName(v[1],v[2]) .. "x" .. v[3]}))
    end
    self.context:addCmd({const.CmdGetWeekPackReward, GameLogic.getSTime()})
    self:showScrollUI()
end
