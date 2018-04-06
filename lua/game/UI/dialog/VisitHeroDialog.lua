local const = GMethod.loadScript("game.GameLogic.Const")
--拜访英雄对话框
local VisitHeroDialog = class2("VisitHeroDialog",function()
    return BaseView.new("VisitHeroDialog.json",true)
end)

function VisitHeroDialog:ctor()
    self.dialogDepth=display.getDialogPri()+1
    self.priority=self.dialogDepth
    self:initUI()
    display.showDialog(self)
    RegActionUpdate(self, Handler(self.updateMy, self, 0.2), 0.2)
end
function VisitHeroDialog:onQuestrion()
    HelpDialog.new("dataQuestionVisitHero")
end

function VisitHeroDialog:initUI()
    self.context = GameLogic.getUserContext()
    self.params = self.context.activeData.limitActive[105]
    local params = self.params
    local context = self.context
    self:loadView("backAndupViews")
    local viewTab = self:getViewTab()
    local temp=viewTab.butClose
    temp:setScriptCallback(Script.createCallbackHandler(display.closeDialog,self.priority))
    self:loadView("upViews")

    self:loadView("downViews")
    self:insertViewTo()

    GameUI.addItemIcon(self,9,params[9],150/200,1318+75,1188+75,true)
    self.butReplace:setListener(function()
        print("更换英雄")
        self:changehero()
    end)
    self.butVisit:setListener(function()
        print("拜访英雄")
        self:visitgeroreward()
    end)

    for i=1,3 do
        self["butUnlock" .. i]:setListener(function()
            self.lockNum = i
            self:reloadLock()
            display.pushNotice(Localize("stringLockHeroSucceed"))
        end)
        self["butLock" .. i]:setListener(function()
            if self.lockNum == i then
                self.lockNum = 0
            end
            self:reloadLock()
        end)
    end
    self.lockNum = 0
    self:reloadLock()
    self:reloadHero()
    self:reloadCost()
end

function VisitHeroDialog:reloadCost()
    local params = self.params
    local cnum = params[3]
    local vnum = params[4]
    self.costc = 0
    self.costv = 0
    if cnum>0 then
        self.costc = 200
    end
    if vnum>0 then
        self.costv = math.ceil((vnum+1-2)/2)*250+500
    end
    self.costv = self.costv>1000 and 1000 or self.costv
    local context = self.context
    if self.costc>0 then
        self.labelFreechero:setVisible(false)
        self.labelcheroNum:setVisible(true)
        self.iconCrystalc:setVisible(true)
        self.labelcheroNum:setString(self.costc)
        if self.costc>context:getRes(const.ResCrystal) then
            ui.setColor(self.labelcheroNum,"red")
        end
    else
        self.labelFreechero:setVisible(true)
        self.labelcheroNum:setVisible(false)
        self.iconCrystalc:setVisible(false)
    end

    if self.costv>0 then
        self.labelFreevhero:setVisible(false)
        self.labelvheroNum:setVisible(true)
        self.iconCrystalv:setVisible(true)
        self.labelvheroNum:setString(self.costv)
        if self.costv>context:getRes(const.ResCrystal) then
            ui.setColor(self.labelvheroNum,"red")
        end
    else
        self.labelFreevhero:setVisible(true)
        self.labelvheroNum:setVisible(false)
        self.iconCrystalv:setVisible(false)
    end
end

function VisitHeroDialog:reloadLock()
    for i=1,3 do
        self["butLock" .. i]:setVisible(false)
        self["butUnlock" .. i]:setVisible(true)
    end
    if self.lockNum~=0 then
        self["butLock" .. self.lockNum]:setVisible(true)
        self["butUnlock" .. self.lockNum]:setVisible(false)
    end
end

function VisitHeroDialog:reloadHero()
    if self.heroNode then
        self.heroNode:removeFromParent(true)
        self.heroNode = nil
    end
    self.heroNode = ui.node()
    self:addChild(self.heroNode)
    local params = self.params
    GameUI.addHeroFeature(self.heroNode, params[6], 0.65, 338, 470,1)
    GameUI.addHeroFeature(self.heroNode, params[7], 0.65, 1012, 470,1)
    GameUI.addHeroFeature(self.heroNode, params[8], 0.65, 1648, 470,1)
end

function VisitHeroDialog:updateMy()
    if self.remainTime then
        local rtime = self.params[2]-GameLogic.getTime()
        if rtime<0 then
            if self.initUI then
                display.closeDialog(0)
            end
        else
            self.remainTime:setString(Localize("labelActRemainTime") .. Localizet(rtime))
        end
    end
end
------------------------------------------------------------------
function VisitHeroDialog:changehero()
    local lockNum = self.lockNum
    local params = self.params
    local context = self.context
    local costc = self.costc
    if costc>context:getRes(const.ResCrystal) then
        display.pushNotice(Localizef("noticeItemNotEnough",{name=Localize("dataResName" .. const.ResCrystal)}))
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("changehero",{changehero = {lockNum}},function(isSuc,data)
        GameNetwork.unlockRequest()
        print_r(data)
        if isSuc then
            for i=6,8 do
                params[i] = data["hid" .. (i-5)]
            end
            params[3] = params[3]+1
            context:changeRes(const.ResCrystal,-costc)
            GameLogic.statCrystalCost("更换拜访英雄消耗",const.ResCrystal,-costc)
            if self.reloadHero then
                self:reloadHero()
                self:reloadCost()
            end
        end
    end)
end

function VisitHeroDialog:visitgeroreward()
    local lockNum = self.lockNum
    local params = self.params
    local context = self.context
    local costv = self.costv
    if costv>context:getRes(const.ResCrystal) then
        display.pushNotice(Localizef("noticeItemNotEnough",{name=Localize("dataResName" .. const.ResCrystal)}))
        return
    end
    if not GameNetwork.lockRequest() then
        return
    end
    GameNetwork.request("visitgeroreward",{},function(isSuc,data)
        GameNetwork.unlockRequest()
        if isSuc then
            params[4] = params[4]+1
            GameLogic.addRewards(data)
            GameLogic.statCrystalRewards("拜访英雄奖励",data)
            GameLogic.showGet(data)
            context:changeRes(const.ResCrystal,-costv)
            GameLogic.statCrystalCost("拜访英雄消耗",const.ResCrystal,-costv)
            if self.reloadCost then
                self:reloadCost()
            end
        end
    end)
end
return VisitHeroDialog














