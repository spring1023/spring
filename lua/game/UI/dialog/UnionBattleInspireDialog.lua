--联盟战鼓舞士气对话框
local selfCallback
local UnionBattleInspireDialog = class2("UnionBattleInspireDialog",function()
    return BaseView.new("UnionBattleInspireDialog.json")
end)
function UnionBattleInspireDialog:ctor(params,type,callback)
    self.params,self.type,selfCallback = params,type,callback
    self.dialogDepth=display.getDialogPri()+1
    self:initUI()
    self.priority=self.dialogDepth
    display.showDialog(self)
end
function UnionBattleInspireDialog:initUI()
    self:removeAllChildren(true)
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    self.viewTab=viewTab
    viewTab.butClose:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.dialogDepth))
	self:loadView("centerViews")
    self:loadView("bottomViews")
    self:insertViewTo()
    --addHP addDmg
    local add = {self.params.hpAdd1,self.params.atkAdd1}
    local addlv = {0,0}
    local max = {0,0}
    local max2 = {0,0}
    for i,v in ipairs(add) do
        while true do
            max[i] = 2000+addlv[i]*250
            max2[i] = max2[i]+max[i]
            if v>max[i] then
                addlv[i] = addlv[i]+1
                add[i] = add[i]-max[i]
                v = v-max[i]
            else
                break
            end
        end
    end

    --进度条
    local pro = {0,0}
    for i=1,2 do
        pro[i] = add[i]/max[i]
    end


    --士气等级
    self.label_moraleLvValue:setString(SG("label_moraleLv") .. addlv[self.type] .. "/10")
    --全军伤害
    local str = SG("label_addHp")
    if self.type == 2 then
        str = SG("label_addDmg")
    end
    self.label_addValue:setString(str.."+" .. addlv[self.type]*5 .."%")

    --鼓舞点
    local spirtValue = self.params.hpAdd1
    if self.type==2 then
        spirtValue= self.params.atkAdd1
    end
    self.label_inspirtValue:setString(SG("label_inspirt") .. spirtValue .. "/" .. max2[self.type])

    local proValue = pro[self.type]
    if addlv[self.type]>=10 then
        proValue = 1
    end
    self.process:setProcess(true,proValue)
    local cvalues={50,100,250}
    for i=1,3 do
        local idx = i
        self["but"..i]:setListener(function()
            if addlv[self.type]>=10 then
                display.pushNotice(Localize("noticeMaxMoraleLv"))
            else
                local ctype = const.ResCrystal
                local cvalue =cvalues[idx]
                if GameLogic.getUserContext():getRes(ctype)<cvalue then
                    display.showDialog(AlertDialog.new({ctype=ctype, cvalue=cvalue}))
                else
                    self:inspirepvl(idx,ctype,cvalue)
                end
            end
        end)
    end
end

------------------------------------------------------------------------
function UnionBattleInspireDialog:inspirepvl(i,ctype,cvalue)
    if not GameNetwork.lockRequest() then
        return
    end
    GameLogic.getUserContext():changeProperty(ctype,-cvalue)
    _G["GameNetwork"].request("inspirepvl",{inspirepvl = {self.type,i}},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            print("加成成功")
            local set = {100,250,750}
            if self.type==1 then
                self.params.hpAdd1 = self.params.hpAdd1+set[i]
            else
                self.params.atkAdd1 = self.params.atkAdd1+set[i]
            end
            if self.initUI then
                self:initUI()
            end
            if selfCallback then
                selfCallback()
            end
        end
    end)
end


return UnionBattleInspireDialog
